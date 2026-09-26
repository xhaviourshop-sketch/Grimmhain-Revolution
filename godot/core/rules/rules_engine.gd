class_name RulesEngine
extends RefCounted
## Befehlsverarbeitung: Command → Validierung → Events → neuer Zustand (03 §3).
## `apply` verändert den übergebenen Zustand nie. Abgelehnte Befehle liefern einen
## Fehlergrund, keine Ereignisse und keinen Zustand (A-13).

const MIN_PLAYERS := 6   ## DECISION-LOG: 6 bis 24 Personen
const MAX_PLAYERS := 24


static func apply(state: GameState, command: Command) -> CommandResult:
	var error := PhaseMachine.check_command(state, command.type)
	if error == &"":
		error = _validate(state, command)
	if error != &"":
		return CommandResult.rejected(error)

	var next := state.duplicate_state()
	var ctx := RuleContext.new(next, state.command_count)
	_execute(ctx, command)
	StepQueue.drop_unactionable(ctx)
	WinRules.finalize_if_ready(ctx)
	next.command_count += 1
	return CommandResult.accepted(next, ctx.events)


## Erwarteter nächster Regelschritt für BeginStep/SkipStep oder "" (siehe StepQueue).
static func next_step_id(state: GameState) -> String:
	return StepQueue.next_step_id(state)


## Wendet eine Befehlsliste auf einen frischen Zustand an (Replay, Laden).
static func replay(commands: Array[Command]) -> ReplayResult:
	var result := ReplayResult.new()
	var state := GameState.new()
	var events: Array[GameEvent] = []
	for i: int in commands.size():
		var r := apply(state, commands[i])
		if not r.ok:
			result.error = r.error
			result.failed_index = i
			result.state = state
			result.events = events
			return result
		state = r.state
		events.append_array(r.events)
	result.ok = true
	result.state = state
	result.events = events
	return result


# --- Validierung (nur lesend) -------------------------------------------------

static func _validate(s: GameState, c: Command) -> StringName:
	var p := c.payload
	match c.type:
		Command.START_GAME:
			return _validate_start_game(p)
		Command.ANSWER_PROMPT:
			return _validate_answer(s, p)
		Command.NOMINATE:
			return _validate_nominate(s, p)
		Command.DECIDE_EXECUTION:
			return _validate_execution(s, p)
		Command.BEGIN_STEP, Command.SKIP_STEP:
			return _validate_step(s, c)
		Command.CANCEL_PROMPT:
			if not DictRead.is_int_like(p.get("prompt_id")) or int(p["prompt_id"]) != s.pending_prompt.id:
				return &"prompt_mismatch"
			if not s.pending_prompt.cancellable:
				return &"prompt_not_cancellable"
			if DictRead.get_string(p, "reason").strip_edges() == "":
				return &"reason_required"
		Command.GM_CORRECTION:
			return GmCorrections.validate(s, p)
		Command.OVERRIDE_SHOWN_ROLE:
			return OracleStep.validate_override(s, p)
		Command.CONFIRM_WIN, Command.REJECT_WIN:
			if s.win_candidate == null:
				return &"no_open_win_candidate"
			if not DictRead.is_int_like(p.get("candidate_id")) or int(p["candidate_id"]) != s.win_candidate.id:
				return &"win_candidate_mismatch"
			if c.type == Command.REJECT_WIN and DictRead.get_string(p, "reason").strip_edges() == "":
				return &"reason_required"
	return &""


static func _validate_start_game(p: Dictionary) -> StringName:
	if not DictRead.is_int_like(p.get("seed")) or int(p["seed"]) < 0 or int(p["seed"]) > CanonicalJson.MAX_SAFE_INT:
		return &"invalid_seed"
	var players := DictRead.get_array(p, "players")
	if players.size() < MIN_PLAYERS or players.size() > MAX_PLAYERS:
		return &"player_count_out_of_range"
	var ids: Array[int] = []
	for item: Variant in players:
		if not item is Dictionary:
			return &"invalid_player"
		var entry: Dictionary = item
		if not DictRead.is_int_like(entry.get("id")) or int(entry["id"]) < 1 or DictRead.get_string(entry, "name").strip_edges() == "":
			return &"invalid_player"
		if ids.has(int(entry["id"])):
			return &"duplicate_player_id"
		ids.append(int(entry["id"]))
	ids.sort()

	var order: Variant = DictRead.to_int_array(DictRead.get_array(p, "seat_order"))
	if order == null:
		return &"invalid_seat_order"
	var sorted_order: Array[int] = (order as Array[int]).duplicate()
	sorted_order.sort()
	if sorted_order != ids:
		return &"invalid_seat_order"

	var collected: Variant = _setup_entries(p, ids)
	if collected is StringName:
		return collected
	var entries: Array = collected
	var counts := {}
	for entry: Dictionary in entries:
		var r: StringName = entry["role_id"]
		if not RoleCatalog.has_role(r):
			return &"unknown_role"
		counts[r] = int(counts.get(r, 0)) + 1
	# Scheinrolle je Rolleninstanz: Pflicht für den Trugbilderwolf, sonst unzulässig (DR-08).
	for entry: Dictionary in entries:
		if RoleCatalog.requires_appearance(entry["role_id"]):
			if not entry["has_appearance"]:
				return &"appearance_required"
			var value: Variant = entry["appears_as"]
			if not (value is String or value is StringName) or not RoleCatalog.is_valid_appearance(StringName(value)):
				return &"invalid_appearance"
		elif entry["has_appearance"]:
			return &"appearance_not_allowed"
	var has_wolf := false
	var has_village := false
	for r: StringName in counts:
		var limit := RoleCatalog.max_copies(r)
		if limit != RoleCatalog.UNLIMITED and int(counts[r]) > limit:
			return &"role_limit_exceeded"
		has_wolf = has_wolf or RoleCatalog.counts_as_wolf(r)
		has_village = has_village or RoleCatalog.faction_of(r) == Faction.VILLAGE
	# Pflicht einer Einzelsiegrolle (DECISION-LOG) ist im Core-Slice nicht erfüllbar,
	# weil keine solche Rolle existiert; sie folgt mit der Setup-Validierung in Phase 2.
	if not has_wolf:
		return &"missing_wolf_role"
	if not has_village:
		return &"missing_village_role"
	return &""


## Rolleninstanzen des Spielaufbaus als [{role_id, appears_as, has_appearance}]: manuell
## in aufsteigender Personen-ID (`roles` plus optional `appearances` {"<id>": Scheinrolle}),
## zufällig in Konfigurationsreihenfolge vor dem Mischen (`role_entries` [{role_id,
## appears_as?}] oder `role_pool` ohne Scheinrollen). Rolle und Scheinrolle bleiben eine
## Einheit, auch beim Mischen. Bei ungültiger Struktur ein Fehlergrund (StringName).
static func _setup_entries(p: Dictionary, ids: Array[int]) -> Variant:
	var entries: Array = []
	match DictRead.get_string(p, "assignment"):
		"manual":
			if p.has("role_entries") or p.has("role_pool") or (p.has("appearances") and not p["appearances"] is Dictionary):
				return &"invalid_assignment"
			var map := DictRead.get_dict(p, "roles")
			if map.size() != ids.size():
				return &"role_count_mismatch"
			var appearances := DictRead.get_dict(p, "appearances")
			for key: Variant in appearances:
				if not String(key).is_valid_int() or not ids.has(String(key).to_int()):
					return &"appearance_not_allowed"
			for id: int in ids:
				if not map.has(str(id)):
					return &"role_count_mismatch"
				entries.append({"role_id": StringName(str(map[str(id)])), "appears_as": appearances.get(str(id)), "has_appearance": appearances.has(str(id))})
		"random":
			if p.has("appearances") or (p.has("role_entries") and p.has("role_pool")):
				return &"invalid_assignment"
			if p.has("role_entries"):
				if not p["role_entries"] is Array:
					return &"invalid_role_entry"
				var list: Array = p["role_entries"]
				if list.size() != ids.size():
					return &"role_count_mismatch"
				for item: Variant in list:
					if not item is Dictionary or not ((item as Dictionary).get("role_id") is String):
						return &"invalid_role_entry"
					var e: Dictionary = item
					for key: Variant in e:
						if not ["role_id", "appears_as"].has(String(key)):
							return &"invalid_role_entry"
					entries.append({"role_id": StringName(e["role_id"]), "appears_as": e.get("appears_as"), "has_appearance": e.has("appears_as")})
			else:
				var pool := DictRead.get_array(p, "role_pool")
				if pool.size() != ids.size():
					return &"role_count_mismatch"
				for r: Variant in pool:
					entries.append({"role_id": StringName(str(r)), "appears_as": null, "has_appearance": false})
		_:
			return &"invalid_assignment"
	return entries


static func _validate_step(s: GameState, c: Command) -> StringName:
	var step_id := DictRead.get_string(c.payload, "step_id")
	var expected := StepQueue.next_step_id(s)
	if c.type == Command.BEGIN_STEP and s.pending_prompt != null:
		return &"step_already_active"
	if expected == "":
		return &"no_pending_step"
	if step_id != expected:
		return &"step_out_of_order"
	if c.type == Command.SKIP_STEP:
		# Überspringbarkeit ist je Schrittart zentral in StepQueue festgelegt.
		if not StepQueue.is_skippable(step_id):
			return &"step_not_skippable"
		if DictRead.get_string(c.payload, "reason").strip_edges() == "":
			return &"reason_required"
	return &""


static func _validate_answer(s: GameState, p: Dictionary) -> StringName:
	var prompt := s.pending_prompt
	if prompt == null:
		return &"no_open_prompt"
	if not DictRead.is_int_like(p.get("prompt_id")) or int(p["prompt_id"]) != prompt.id:
		return &"prompt_mismatch"
	if prompt.owner == PendingPrompt.OWNER_WITCH:
		return WitchStep.validate_answer(s, prompt, p)
	if prompt.owner == PendingPrompt.OWNER_ORACLE:
		return OracleStep.validate_answer(s, prompt, p)
	var targets: Variant = DictRead.to_int_array(DictRead.get_array(p, "targets"))
	if targets == null or not p.get("targets") is Array:
		return &"invalid_target"
	var list: Array[int] = targets
	if list.size() < prompt.min_count or list.size() > prompt.max_count:
		return &"invalid_target_count"
	var seen: Array[int] = []
	for t: int in list:
		# Nur zum Zeitpunkt der Antwort lebende Personen sind gültige Ziele.
		if not prompt.allowed_ids.has(t) or seen.has(t) or not s.players.has(t) or not s.players[t].alive:
			return &"invalid_target"
		seen.append(t)
	return &""


static func _validate_nominate(s: GameState, p: Dictionary) -> StringName:
	var nominator := DictRead.get_int(p, "nominator_id", GameState.NO_TARGET)
	var nominee := DictRead.get_int(p, "nominee_id", GameState.NO_TARGET)
	if not s.players.has(nominator) or not s.players.has(nominee):
		return &"unknown_player"
	if not s.players[nominator].alive or not s.players[nominee].alive:
		return &"player_dead"
	for n: Nomination in s.nominations_on_day(s.day_number):
		if n.nominator_id == nominator:
			return &"already_nominated_today"
	for n: Nomination in s.nominations_on_day(s.day_number):
		if n.nominee_id == nominee:
			return &"already_nominee_today"
	return &""


static func _validate_execution(s: GameState, p: Dictionary) -> StringName:
	if not DictRead.is_int_like(p.get("target_id")):
		return &"unknown_player"
	var target := int(p["target_id"])
	if target == GameState.NO_TARGET:
		return &""
	if not s.players.has(target):
		return &"unknown_player"
	if not s.players[target].alive:
		return &"player_dead"
	for n: Nomination in s.nominations_on_day(s.day_number):
		if n.nominee_id == target:
			return &""
	# DR-03: Hinrichtung ohne Nominierung nur als Spielleiter-Übersteuerung (GmCorrection, B-11).
	return &"not_nominated_today"


# --- Ausführung (auf der Zustandskopie) ----------------------------------------

static func _execute(ctx: RuleContext, c: Command) -> void:
	var s := ctx.state
	var p := c.payload
	match c.type:
		Command.START_GAME:
			_start_game(ctx, p)
		Command.START_NIGHT:
			_start_night(ctx)
		Command.ANSWER_PROMPT:
			if s.pending_prompt.owner == PendingPrompt.OWNER_WITCH:
				WitchStep.answer(ctx, p)
			elif s.pending_prompt.owner == PendingPrompt.OWNER_ORACLE:
				OracleStep.answer(ctx, p)
			else:
				_answer_prompt(ctx, DictRead.to_int_array(p["targets"]))
		Command.BEGIN_STEP:
			StepQueue.begin(ctx, DictRead.get_string(p, "step_id"))
		Command.SKIP_STEP:
			StepQueue.skip(ctx, DictRead.get_string(p, "step_id"), DictRead.get_string(p, "reason").strip_edges())
		Command.CANCEL_PROMPT:
			StepQueue.cancel_prompt(ctx, DictRead.get_string(p, "reason").strip_edges())
		Command.GM_CORRECTION:
			GmCorrections.execute(ctx, p)
		Command.OVERRIDE_SHOWN_ROLE:
			OracleStep.apply_override(ctx, p)
		Command.END_NIGHT:
			_resolve_dawn(ctx)
		Command.NOMINATE:
			var n := Nomination.new()
			n.nominator_id = int(p["nominator_id"])
			n.nominee_id = int(p["nominee_id"])
			n.day = s.day_number
			s.nominations.append(n)
			s.day_step = Phase.DAY_NOMINATION
			ctx.emit(GameEvent.NOMINATION_RECORDED, Visibility.PUBLIC, n.to_dict())
		Command.DECIDE_EXECUTION:
			var target := int(p["target_id"])
			s.day_step = Phase.DAY_EXECUTION_DECIDED
			if target == GameState.NO_TARGET:
				ctx.emit(GameEvent.NO_EXECUTION, Visibility.PUBLIC, {"day": s.day_number})
			else:
				ctx.emit(GameEvent.EXECUTION_CONFIRMED, Visibility.PUBLIC, {"target_id": target, "day": s.day_number, "gm_override": false})
				ExecutionRules.execute(ctx, target, KillEvent.SOURCE_VILLAGE)
		Command.END_DAY:
			s.day_step = Phase.DAY_ENDED
			ctx.emit(GameEvent.DAY_ENDED, Visibility.PUBLIC, {"day": s.day_number})
		Command.CONFIRM_WIN:
			var winner := s.win_candidate
			winner.status = WinCandidate.STATUS_CONFIRMED
			winner.resolved_at_command = ctx.command_index
			s.winner = winner
			s.win_candidate = null
			ctx.emit(GameEvent.WIN_CONFIRMED, Visibility.PUBLIC, {"winner": winner.to_dict()})
			PhaseMachine.enter(ctx, Phase.GAME_OVER)
		Command.REJECT_WIN:
			var rejected := s.win_candidate
			rejected.status = WinCandidate.STATUS_REJECTED
			rejected.resolved_at_command = ctx.command_index
			rejected.rejection_reason = DictRead.get_string(p, "reason").strip_edges()
			s.win_candidate = null
			ctx.emit(GameEvent.WIN_REJECTED, Visibility.GM, {"candidate": rejected.to_dict(), "reason": rejected.rejection_reason})


static func _start_game(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	s.round_id = DictRead.get_string(p, "round_id")
	s.rng = SeededRng.new(int(p["seed"]))

	var names := {}
	var ids: Array[int] = []
	for item: Variant in DictRead.get_array(p, "players"):
		var entry: Dictionary = item
		ids.append(int(entry["id"]))
		names[int(entry["id"])] = DictRead.get_string(entry, "name").strip_edges()
	ids.sort()

	# Zuordnung Person → Rolleninstanz (Rolle plus Scheinrolle). Zufall ausschließlich über
	# den gespeicherten Seed, Personen in aufsteigender ID-Reihenfolge (unabhängig von der
	# Sitzreihenfolge). Die Scheinrolle selbst wird nie zufällig bestimmt.
	var entries: Array = _setup_entries(p, ids)
	if DictRead.get_string(p, "assignment") == "random":
		entries = s.rng.shuffled(entries)

	for i: int in ids.size():
		var player := Player.new()
		player.id = ids[i]
		player.name = names[ids[i]]
		var entry: Dictionary = entries[i]
		player.role_id = entry["role_id"]
		player.original_role_id = player.role_id
		player.faction = RoleCatalog.faction_of(player.role_id)
		player.counts_as_wolf = RoleCatalog.counts_as_wolf(player.role_id)
		player.appears_as = StringName(str(entry["appears_as"])) if RoleCatalog.requires_appearance(player.role_id) else RoleCatalog.appears_as(player.role_id)
		s.players[player.id] = player
		if player.role_id == RoleCatalog.WOLFSKIND:
			WolfChildRules.create_bond(s, player.id)
	s.seat_order = DictRead.to_int_array(DictRead.get_array(p, "seat_order"))

	ctx.emit(GameEvent.GAME_STARTED, Visibility.GM, {
		"round_id": s.round_id,
		"seed": s.rng.seed_value,
		"rules_version": s.rules_version,
		"player_ids": ids,
		"seat_order": s.seat_order,
		"assignment": DictRead.get_string(p, "assignment"),
	})
	for id: int in ids:
		ctx.emit(GameEvent.ROLE_ASSIGNED, Visibility.ACTOR, {"player_id": id, "role_id": s.players[id].role_id}, id)


## Nacht beginnen: Nachtplan berechnen und den ersten Schritt selbst beginnen.
## Jeder weitere Schritt und jeder erneute Beginn nach CancelPrompt verlangt BeginStep.
static func _start_night(ctx: RuleContext) -> void:
	var s := ctx.state
	PhaseMachine.enter(ctx, Phase.NIGHT)
	s.pack_target_id = GameState.NO_TARGET
	s.night_plan = StepQueue.build_night_plan(s)
	s.next_night_step = 0
	s.night_step_status.clear()
	for _step: StringName in s.night_plan:
		s.night_step_status.append(StepQueue.STATUS_PENDING)
	s.protections.clear()
	s.witch_actions.clear()
	if s.night_plan.is_empty():
		ctx.emit(GameEvent.NIGHT_STEP_SKIPPED, Visibility.GM, {"step": StepQueue.PACK, "reason": "no_living_wolf"})
		return
	StepQueue.drop_unactionable(ctx)
	if s.next_night_step < s.night_plan.size():
		StepQueue.begin(ctx, StepQueue.night_step_id(s, s.next_night_step))


static func _answer_prompt(ctx: RuleContext, targets: Array[int]) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {
		"prompt_id": prompt.id, "owner": prompt.owner, "targets": targets,
	})
	var target := targets[0] if targets.size() == 1 else GameState.NO_TARGET
	match prompt.owner:
		PendingPrompt.OWNER_PACK:
			s.pack_target_id = target
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_GUARD:
			Protections.set_protection(s, prompt.actor_id, target)
			ctx.emit(GameEvent.PROTECTION_SET, Visibility.GM, {"guardian_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_WOLF_CHILD:
			WolfChildRules.bind(ctx, prompt.actor_id, target)
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_REACTION:
			var reaction: Reaction = s.reactions.pop_front()
			ctx.emit(GameEvent.REACTION_RESOLVED, Visibility.GM, {
				"reaction_id": reaction.id, "owner_id": reaction.owner_id, "target_id": target,
				"outcome": "declined" if target == GameState.NO_TARGET else "cursed",
			})
			if target != GameState.NO_TARGET:
				KillPipeline.request_kill(ctx, target, KillEvent.CAUSE_HUNTER_SHOT, KillEvent.SOURCE_PLAYER, reaction.owner_id)
			_finish_dawn_if_ready(ctx)


## Morgenauflösung (vertical-slice-flow.md §4, ohne Schutz):
## NIGHT → DAWN_RESOLUTION → Wolfsopfer stirbt (NIGHT_KILL) → Reaktionen → DAY.
## Solange Reaktionen offen sind, bleibt die Phase DAWN_RESOLUTION; der Wechsel zu
## DAY erfolgt automatisch mit der letzten Reaktion (BeginDay folgt später).
static func _resolve_dawn(ctx: RuleContext) -> void:
	var s := ctx.state
	PhaseMachine.enter(ctx, Phase.DAWN_RESOLUTION)
	if s.pack_target_id != GameState.NO_TARGET:
		KillPipeline.request_kill(ctx, s.pack_target_id, KillEvent.CAUSE_NIGHT_KILL, KillEvent.SOURCE_PACK)
	else:
		ctx.emit(GameEvent.NO_NIGHT_KILL, Visibility.GM, {"night_number": s.night_number})
	s.pack_target_id = GameState.NO_TARGET
	_finish_dawn_if_ready(ctx)


static func _finish_dawn_if_ready(ctx: RuleContext) -> void:
	var s := ctx.state
	if s.phase == Phase.DAWN_RESOLUTION and s.reactions.is_empty() and s.pending_prompt == null:
		PhaseMachine.enter(ctx, Phase.DAY)
