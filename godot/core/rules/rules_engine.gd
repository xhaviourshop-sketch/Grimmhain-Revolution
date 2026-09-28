class_name RulesEngine
extends RefCounted
## Befehlsverarbeitung: Command → Validierung → Events → neuer Zustand (03 §3).
## `apply` verändert den übergebenen Zustand nie. Abgelehnte Befehle liefern einen
## Fehlergrund, keine Ereignisse und keinen Zustand (A-13).

const MIN_PLAYERS := 6   ## DECISION-LOG: 6 bis 24 Personen
const MAX_PLAYERS := 24
const TIME_USE_KEY := "zeitwaechter:freeze"  ## Zeitwächter: einmal je Leben (E-36)


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
		Command.AMALIA_SACRIFICE:
			return _validate_amalia(s, p)
		Command.NAME_WOLF:
			return SoloRules.validate_name_wolf(s, p)
		Command.CONFIRM_WIN, Command.REJECT_WIN:
			var open := s.open_candidates()
			if open.is_empty():
				return &"no_open_win_candidate"
			# ConfirmWin nennt genau einen offenen Kandidaten; RejectWin darf zur Kompatibilität
			# einen offenen Kandidaten nennen, lehnt aber immer alle offenen ab.
			if c.type == Command.CONFIRM_WIN or p.has("candidate_id"):
				if not DictRead.is_int_like(p.get("candidate_id")) or s.candidate_by_id(int(p["candidate_id"])) == null \
						or s.candidate_by_id(int(p["candidate_id"])).status != WinCandidate.STATUS_OPEN:
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
	if prompt.owner == PendingPrompt.OWNER_APPRENTICE:
		return ApprenticeRules.validate_answer(s, prompt, p)
	if InfoSteps.OWNERS.has(prompt.owner):
		return InfoSteps.validate_answer(s, prompt, p)
	if BondSteps.OWNERS.has(prompt.owner):
		return BondSteps.validate_answer(s, prompt, p)
	if prompt.owner == PendingPrompt.OWNER_SHADOW or prompt.owner == PendingPrompt.OWNER_TIME:
		if DictRead.get_string(p, "stage") != "use":
			return &"stage_mismatch"
		return &"" if (not p.has("targets") and p.get("choice") is bool) else &"invalid_answer"
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


## Amalia (I-09): lebende Amalia am Tag, mindestens drei lebende Wölfe, Antwort Ja/Nein.
static func _validate_amalia(s: GameState, p: Dictionary) -> StringName:
	var id := DictRead.get_int(p, "player_id", GameState.NO_TARGET)
	if not s.players.has(id):
		return &"unknown_player"
	if not s.players[id].alive:
		return &"player_dead"
	if s.players[id].role_id != RoleCatalog.AMALIA:
		return &"not_amalia"
	if not p.get("answer") is bool:
		return &"invalid_answer"
	if InfoSteps.living_wolf_count(s) < RoleCatalog.AMALIA_MIN_WOLVES:
		return &"too_few_wolves"
	if GuardRoles.silenced(s, id):
		return &"cursed"
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
	if ExecutionRules.needs_cerberus_decision(s, target) and not p.get("cerberus_defend") is bool:
		return &"cerberus_decision_required"
	var curse_error := GuardRoles.validate_curse_field(s, target, p)
	if curse_error != &"":
		return curse_error
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
			elif s.pending_prompt.owner == PendingPrompt.OWNER_APPRENTICE:
				ApprenticeRules.answer(ctx, p)
			elif InfoSteps.OWNERS.has(s.pending_prompt.owner):
				InfoSteps.answer(ctx, p)
			elif BondSteps.OWNERS.has(s.pending_prompt.owner):
				BondSteps.answer(ctx, p)
			elif s.pending_prompt.owner == PendingPrompt.OWNER_SHADOW:
				_answer_shadow(ctx, bool(p["choice"]))
			elif s.pending_prompt.owner == PendingPrompt.OWNER_TIME:
				_answer_time(ctx, bool(p["choice"]))
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
		Command.NAME_WOLF:
			SoloRules.name_wolf(ctx, p)
		Command.AMALIA_SACRIFICE:
			# Öffentliche Frage mit Antwort des Spielleiters, danach stirbt Amalia sofort mit allen Folgen.
			var amalia := int(p["player_id"])
			ctx.emit(GameEvent.AMALIA_ANSWERED, Visibility.PUBLIC, {"player_id": amalia, "answer": bool(p["answer"]), "day": s.day_number})
			KillPipeline.request_kill(ctx, amalia, KillEvent.CAUSE_AMALIA_SACRIFICE, KillEvent.SOURCE_PLAYER, amalia)
		Command.END_NIGHT:
			_resolve_dawn(ctx)
		Command.NOMINATE:
			_record_nomination(ctx, int(p["nominator_id"]), int(p["nominee_id"]), false)
		Command.DECIDE_EXECUTION:
			var target := int(p["target_id"])
			s.day_step = Phase.DAY_EXECUTION_DECIDED
			if target == GameState.NO_TARGET:
				ctx.emit(GameEvent.NO_EXECUTION, Visibility.PUBLIC, {"day": s.day_number})
			else:
				ctx.emit(GameEvent.EXECUTION_CONFIRMED, Visibility.PUBLIC, {"target_id": target, "day": s.day_number, "gm_override": false})
				ExecutionRules.execute(ctx, target, KillEvent.SOURCE_VILLAGE, DictRead.get_bool(p, "cerberus_defend"), DictRead.get_int(p, "sage_curse"))
		Command.END_DAY:
			s.day_step = Phase.DAY_ENDED
			ctx.emit(GameEvent.DAY_ENDED, Visibility.PUBLIC, {"day": s.day_number})
		Command.CONFIRM_WIN:
			# Genau einer wird bestätigt; alle übrigen offenen gelten als nicht gewählt.
			var chosen_id := int(p["candidate_id"])
			var chosen: WinCandidate = null
			for candidate: WinCandidate in s.open_candidates():
				candidate.resolved_at_command = ctx.command_index
				if candidate.id == chosen_id:
					candidate.status = WinCandidate.STATUS_CONFIRMED
					chosen = candidate
				else:
					candidate.status = WinCandidate.STATUS_NOT_CHOSEN
					ctx.emit(GameEvent.WIN_REJECTED, Visibility.GM, {"candidate": candidate.to_dict(), "reason": String(WinCandidate.STATUS_NOT_CHOSEN)})
			s.winner_id = chosen.id
			ctx.emit(GameEvent.WIN_CONFIRMED, Visibility.PUBLIC, {"winner": chosen.to_dict()})
			PhaseMachine.enter(ctx, Phase.GAME_OVER)
		Command.REJECT_WIN:
			# Die gesamte offene Kandidatenmenge wird gemeinsam abgelehnt.
			var reason := DictRead.get_string(p, "reason").strip_edges()
			for candidate: WinCandidate in s.open_candidates():
				candidate.status = WinCandidate.STATUS_REJECTED
				candidate.resolved_at_command = ctx.command_index
				candidate.rejection_reason = reason
				ctx.emit(GameEvent.WIN_REJECTED, Visibility.GM, {"candidate": candidate.to_dict(), "reason": reason})


## Speichert eine Nominierung (DR-03, DR-12) und löst ihre Folgen aus. Eine Richter-Nominierung
## (RM-DR-012) ist intern normal, öffentlich erscheint nur die nominierte Person.
static func _record_nomination(ctx: RuleContext, nominator: int, nominee: int, by_judge: bool) -> void:
	var s := ctx.state
	var n := Nomination.new()
	n.nominator_id = nominator
	n.nominee_id = nominee
	n.day = s.day_number
	n.by_judge = by_judge
	s.nominations.append(n)
	s.players[n.nominee_id].ever_nominated = true  # dauerhaft an der Person (DR-12)
	s.day_step = Phase.DAY_NOMINATION
	if by_judge:
		ctx.emit(GameEvent.JUDGE_NOMINATED, Visibility.GM, {"judge_id": nominator, "nominee_id": nominee, "day": n.day})
		ctx.emit(GameEvent.JUDGE_NOMINATION_PUBLIC, Visibility.PUBLIC, {"nominee_id": nominee, "day": n.day})
	else:
		ctx.emit(GameEvent.NOMINATION_RECORDED, Visibility.PUBLIC, n.to_dict())
	# Manipulator stirbt sofort bei seiner Nominierung; der Tag bleibt aktiv.
	if s.players[n.nominee_id].role_id == RoleCatalog.MANIPULATOR:
		KillPipeline.request_kill(ctx, n.nominee_id, KillEvent.CAUSE_MANIPULATOR_NOMINATED, KillEvent.SOURCE_PLAYER, n.nominator_id)


## Bei Tagesbeginn: jede Markierung eines lebenden Richters auf eine lebende Person wird zu seiner
## Nominierung, sofern beide heute noch frei sind (nach Personen-ID des Richters).
## Schattenhund: „jetzt blockieren?“; Ja blockiert alle Dorf-Nachtschritte dieser Nacht (einmal je Leben).
static func _answer_shadow(ctx: RuleContext, use: bool) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": "use", "choice": use})
	if use:
		s.village_blocked = true
		s.players[prompt.actor_id].ability_uses["schattenhund:block"] = 1
		ctx.emit(GameEvent.NIGHT_BLOCKED, Visibility.GM, {"by": String(RoleCatalog.SCHATTENHUND), "blocker_id": prompt.actor_id, "target_id": -1, "night": s.night_number})
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


## Zeitwächter (E-36): „Nacht einfrieren?“; Ja lässt alle weiteren Nachtschritte dieser Nacht entfallen (einmal je Leben).
static func _answer_time(ctx: RuleContext, use: bool) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": "use", "choice": use})
	if use:
		s.night_frozen = true
		s.players[prompt.actor_id].ability_uses[TIME_USE_KEY] = 1
		ctx.emit(GameEvent.NIGHT_FREEZE_USED, Visibility.GM, {"warden_id": prompt.actor_id, "night": s.night_number})
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


static func _judge_nominations(ctx: RuleContext) -> void:
	var s := ctx.state
	for mark: Dictionary in s.judge_marks:
		var judge := int(mark["judge_id"])
		var target := int(mark["target_id"])
		if not s.players[judge].alive or not SoloRules.has_ability(s, judge, RoleCatalog.KORRUPTER_RICHTER) or not s.players[target].alive or GuardRoles.silenced(s, judge):
			continue
		if _validate_nominate(s, {"nominator_id": judge, "nominee_id": target}) != &"":
			continue
		_record_nomination(ctx, judge, target, true)


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
	s.necro_shields.clear()  # ungenutzte Schilde verfallen mit Beginn der nächsten Nacht (E-16)
	s.martyr_saves.clear()  # vor dem Plan: die Frage der Märtyrerin hängt von dieser Nacht ab
	s.night_plan = StepQueue.build_night_plan(s)
	s.pack_bonus_pending = false  # in den Plan übernommen (Rudelvater)
	s.judge_marks.clear()  # Markierungen gelten nur für den folgenden Tag
	s.hangman_marks.clear()
	s.village_blocked = false
	s.blocked_ids.clear()
	s.pack_extra_target_id = GameState.NO_TARGET
	s.fate_kills.clear()
	s.night_frozen = false
	s.night_wolf_ids.clear()
	for id: int in s.alive_ids():
		if s.players[id].counts_as_wolf:
			s.night_wolf_ids.append(id)
	s.next_night_step = 0
	s.night_step_status.clear()
	for _step: StringName in s.night_plan:
		s.night_step_status.append(StepQueue.STATUS_PENDING)
	s.protections.clear()
	s.witch_actions.clear()
	s.doom_offers.clear()
	s.apple_steps.clear()
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
			if s.apple_steps.has(s.next_night_step):
				Protections.add_extra(s, prompt.actor_id, target)  # zweiter Schutz durch einen Apfel
			else:
				Protections.set_protection(s, prompt.actor_id, target)
			ctx.emit(GameEvent.PROTECTION_SET, Visibility.GM, {"guardian_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_PIPER:
			for id: int in targets:
				s.charms.append({"piper_id": prompt.actor_id, "target_id": id})
			ctx.emit(GameEvent.CHARMED, Visibility.GM, {"piper_id": prompt.actor_id, "target_ids": targets.duplicate(), "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_PEST:
			SoloRules.infect(s, target)
			ctx.emit(GameEvent.INFECTED, Visibility.GM, {"pest_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_PROPHET:
			if prompt.min_count == RoleCatalog.PROPHET_MARKS:
				for id: int in targets:
					s.prophet_marks.append({"prophet_id": prompt.actor_id, "target_id": id})
				ctx.emit(GameEvent.PROPHET_MARKED, Visibility.GM, {"prophet_id": prompt.actor_id, "target_ids": targets.duplicate()})
			elif target != GameState.NO_TARGET:
				# Tötung des freigeschalteten Propheten: Tod am Morgen (Markierung), eigene Ursache.
				s.death_marks.append({"target_id": target, "source_id": prompt.actor_id, "cause": String(KillEvent.CAUSE_PROPHET_KILL)})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_FIRE:
			if target != GameState.NO_TARGET:
				SoloRules.set_fire_mark(s, prompt.actor_id, target)
			ctx.emit(GameEvent.FIRE_MARKED, Visibility.GM, {"devil_id": prompt.actor_id, "target_id": SoloRules.fire_mark_of(s, prompt.actor_id),
				"kept": target == GameState.NO_TARGET, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_VOODOO:
			if target != GameState.NO_TARGET:
				SoloRules.give_doll(s, prompt.actor_id, target)
			ctx.emit(GameEvent.VOODOO_DOLL_GIVEN, Visibility.GM, {"priest_id": prompt.actor_id, "doll_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_LONE:
			if target != GameState.NO_TARGET:
				s.death_marks.append({"target_id": target, "source_id": prompt.actor_id, "cause": String(KillEvent.CAUSE_LONE_WOLF_KILL)})
			ctx.emit(GameEvent.LONE_WOLF_STRUCK, Visibility.GM, {"wolf_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_FATE:
			if SoloRules.fate_marking(s, prompt.actor_id):
				for id: int in targets:
					s.fate_marks.append({"wolf_id": prompt.actor_id, "target_id": id})
				ctx.emit(GameEvent.FATE_MARKED, Visibility.GM, {"wolf_id": prompt.actor_id, "target_ids": targets.duplicate()})
			else:
				for id: int in targets:
					s.fate_kills.append({"wolf_id": prompt.actor_id, "target_id": id, "redirect_from": -1})
				ctx.emit(GameEvent.FATE_KILLS_CHOSEN, Visibility.GM, {"wolf_id": prompt.actor_id, "target_ids": targets.duplicate(), "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_WIDOW:
			# Schwarze Witwe (B-03, B-06): lebendes Paar des Loki → beide sterben am Morgen.
			var partners := BondRules.living_partners(s, target)
			if not partners.is_empty():
				for id: int in [target] + partners:
					s.death_marks.append({"target_id": id, "source_id": prompt.actor_id, "cause": String(KillEvent.CAUSE_BLACK_WIDOW)})
			ctx.emit(GameEvent.WIDOW_STRUCK, Visibility.GM, {"widow_id": prompt.actor_id, "target_id": target, "partner_ids": partners, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_SHADOWWALKER:
			if target != GameState.NO_TARGET:
				s.shadow_links.append({"walker_id": prompt.actor_id, "partner_id": target})
				s.players[prompt.actor_id].ability_uses["schattenwanderer:link"] = 1
			ctx.emit(GameEvent.SHADOW_LINKED, Visibility.GM, {"walker_id": prompt.actor_id, "partner_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_SMITH:
			if target != GameState.NO_TARGET:
				s.weapons.append({"holder_id": target, "smith_id": prompt.actor_id})
				s.players[prompt.actor_id].ability_uses[GuardRoles.SMITH_USE_KEY] = 1
			ctx.emit(GameEvent.WEAPON_GIVEN, Visibility.GM, {"smith_id": prompt.actor_id, "holder_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_GHOST:
			s.shields.append({"holder_id": target, "source_id": prompt.actor_id, "night": s.night_number})
			s.players[prompt.actor_id].ability_uses[GuardRoles.GHOST_USE_KEY] = 1
			if s.players[target].counts_as_wolf:
				s.ghost_alerts += 1  # öffentlich am Morgen, ohne Namen
			ctx.emit(GameEvent.SHIELD_GIVEN, Visibility.GM, {"spirit_id": prompt.actor_id, "holder_id": target, "is_wolf": s.players[target].counts_as_wolf, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_DOOM:
			# Urteil (S-07): die gewählte Person wird statt des Rudelopfers vom Rudel angegriffen.
			var victim := s.pack_target_id
			ctx.emit(GameEvent.DOOM_JUDGED, Visibility.GM, {"warden_id": prompt.actor_id, "victim_id": victim,
				"offer_id": int(s.doom_offers.get(prompt.actor_id, -1)), "chosen_id": target, "night": s.night_number})
			s.pack_target_id = target
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_MARTYR:
			if target != GameState.NO_TARGET:
				s.martyr_saves.append({"martyr_id": prompt.actor_id, "victim_id": target})
				ctx.emit(GameEvent.MARTYR_CHOSEN, Visibility.GM, {"martyr_id": prompt.actor_id, "victim_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_HANGMAN:
			if target != GameState.NO_TARGET:
				s.hangman_marks.append({"hangman_id": prompt.actor_id, "target_id": target})
			ctx.emit(GameEvent.HANGMAN_MARKED, Visibility.GM, {"hangman_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_PACK2:
			s.pack_extra_target_id = target
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_NIGHTMARE:
			if target != GameState.NO_TARGET and not s.blocked_ids.has(target):
				s.blocked_ids.append(target)
			ctx.emit(GameEvent.NIGHT_BLOCKED, Visibility.GM, {"by": String(RoleCatalog.ALBTRAUMWOLF), "blocker_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_POISON_WOLF:
			if target != GameState.NO_TARGET:
				var wolf := s.players[prompt.actor_id]
				wolf.ability_uses["giftwolf:paw1" if not wolf.ability_uses.has("giftwolf:paw1") else "giftwolf:paw2"] = 1
				s.wolf_poisons.append({"target_id": target, "source_id": prompt.actor_id, "due_night": s.night_number + 2})
				ctx.emit(GameEvent.WOLF_POISONED, Visibility.GM, {"wolf_id": prompt.actor_id, "target_id": target, "due_night": s.night_number + 2})
				ctx.emit(GameEvent.WOLF_POISON_NOTICE, Visibility.ACTOR, {"due_night": s.night_number + 2}, target)
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_PARASITE:
			if target != GameState.NO_TARGET:
				s.parasite_hosts = s.parasite_hosts.filter(func(b: Dictionary) -> bool: return int(b["parasite_id"]) != prompt.actor_id)
				s.parasite_hosts.append({"parasite_id": prompt.actor_id, "host_id": target})
				s.parasite_hosts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["parasite_id"]) < int(b["parasite_id"]))
			ctx.emit(GameEvent.PARASITE_ATTACHED, Visibility.GM, {"parasite_id": prompt.actor_id, "host_id": KillPipeline.host_of(s, prompt.actor_id), "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_JUDGE:
			s.judge_marks = s.judge_marks.filter(func(m: Dictionary) -> bool: return int(m["judge_id"]) != prompt.actor_id)
			if target != GameState.NO_TARGET:
				s.judge_marks.append({"judge_id": prompt.actor_id, "target_id": target})
				s.judge_marks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["judge_id"]) < int(b["judge_id"]))
			ctx.emit(GameEvent.JUDGE_MARKED, Visibility.GM, {"judge_id": prompt.actor_id, "target_id": target, "night": s.night_number})
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_WOLF_CHILD:
			WolfChildRules.bind(ctx, prompt.actor_id, target)
			s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
			s.next_night_step += 1
		PendingPrompt.OWNER_REACTION:
			var reaction: Reaction = s.reactions.pop_front()
			if reaction.kind == Reaction.KIND_DEMON:
				# Dämonischer Wolf (V-01, V-02): Fluch statt Tod; nur Rollenauskünfte zeigen „Werwolf“.
				if target != GameState.NO_TARGET:
					s.players[target].cursed = true
					ctx.emit(GameEvent.DEMON_CURSED, Visibility.GM, {"demon_id": reaction.owner_id, "target_id": target})
				ctx.emit(GameEvent.REACTION_RESOLVED, Visibility.GM, {
					"reaction_id": reaction.id, "owner_id": reaction.owner_id, "target_id": target, "kind": reaction.kind,
					"outcome": "declined" if target == GameState.NO_TARGET else "cursed",
				})
				_finish_dawn_if_ready(ctx)
				return
			var cause: StringName = {Reaction.KIND_CURSE: KillEvent.CAUSE_HUNTER_SHOT, Reaction.KIND_POSSESSED: KillEvent.CAUSE_POSSESSED_DRAG,
				Reaction.KIND_KNIGHT: KillEvent.CAUSE_KNIGHT_STRIKE, Reaction.KIND_SMITH: KillEvent.CAUSE_SMITH_WEAPON}[reaction.kind]
			ctx.emit(GameEvent.REACTION_RESOLVED, Visibility.GM, {
				"reaction_id": reaction.id, "owner_id": reaction.owner_id, "target_id": target, "kind": reaction.kind,
				"outcome": "declined" if target == GameState.NO_TARGET else ("cursed" if reaction.kind == Reaction.KIND_CURSE else "killed"),
			})
			if target != GameState.NO_TARGET:
				KillPipeline.request_kill(ctx, target, cause, KillEvent.SOURCE_PLAYER, reaction.owner_id)
			_finish_dawn_if_ready(ctx)


## Morgenauflösung (vertical-slice-flow.md §4):
## NIGHT → DAWN_RESOLUTION → Gifttode (WITCH_POISON) → Wolfsopfer (NIGHT_KILL, Schutz/Rettung) → Reaktionen → DAY.
## Solange Reaktionen offen sind, bleibt die Phase DAWN_RESOLUTION; der Wechsel zu
## DAY erfolgt automatisch mit der letzten Reaktion (BeginDay folgt später).
static func _resolve_dawn(ctx: RuleContext) -> void:
	var s := ctx.state
	PhaseMachine.enter(ctx, Phase.DAWN_RESOLUTION)
	# Detektiv: nachts entstandene Hinweise werden jetzt öffentlich (I-10).
	for hint: Dictionary in s.detective_hints:
		ctx.emit(GameEvent.DETECTIVE_HINT, Visibility.PUBLIC, {"anchor_id": int(hint["anchor_id"]), "direction": String(hint["direction"])})
	s.detective_hints.clear()
	# Schutzgeist hat einen Wolf gewählt: öffentlich, ohne Namen (S-04).
	for i: int in s.ghost_alerts:
		ctx.emit(GameEvent.GHOST_WOLF_ALERT, Visibility.PUBLIC, {"night": s.night_number})
	s.ghost_alerts = 0
	# Pestbringerin (E-02): Ausbreitung zu Beginn der Morgenauflösung.
	SoloRules.spread(ctx)
	# Wiederbelebungen durch Kutscher und Frankenstein werden am Morgen sichtbar (W-04).
	for id: int in s.revived_tonight:
		ctx.emit(GameEvent.PLAYER_REVIVED, Visibility.PUBLIC, {"player_id": id, "night": s.night_number})
	s.revived_tonight.clear()
	# Gift vor dem Rudelangriff: Ursache und Reihenfolge wie beim früheren Sofort-Tod.
	WitchStep.apply_poisons(ctx)
	# Todesmarkierungen aus Nachtschritten (Kriegerin des Lichts, Blutpriester), in Reihenfolge der Markierung.
	# Die Liste bleibt bis zum Ende bestehen: noch markierte Personen sterben an ihrer eigenen Markierung
	# (z. B. beide Partner der Schwarzen Witwe), nicht an einer Todesfolge davor.
	for mark: Dictionary in s.death_marks.duplicate(true):
		KillPipeline.request_kill(ctx, int(mark["target_id"]), StringName(mark["cause"]), KillEvent.SOURCE_PLAYER, int(mark["source_id"]))
	s.death_marks.clear()
	# Giftwolf: fällige Vergiftungen (zwei Nächte nach der Giftpranke), unaufhaltbar.
	for entry: Dictionary in s.wolf_poisons.duplicate():
		if int(entry["due_night"]) == s.night_number:
			s.wolf_poisons.erase(entry)
			KillPipeline.request_kill(ctx, int(entry["target_id"]), KillEvent.CAUSE_WOLF_POISON, KillEvent.SOURCE_PLAYER, int(entry["source_id"]))
	if s.pack_target_id != GameState.NO_TARGET:
		# Seuchenwolf: der nächste tatsächliche Rudelangriff durchdringt Schutz und verbraucht die Wirkung.
		var pierce := s.plague_pierce_pending
		s.plague_pierce_pending = false
		var martyr := GuardRoles.martyr_for(s, s.pack_target_id) if s.players[s.pack_target_id].alive else GameState.NO_TARGET
		if martyr != GameState.NO_TARGET:
			# Märtyrerin (S-03): Ersatzopfer, auch gegen Durchdringung (RM-DR-005).
			ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": s.pack_target_id, "cause": KillEvent.CAUSE_NIGHT_KILL, "source_kind": KillEvent.SOURCE_PACK,
				"protection": RoleCatalog.MAERTYRERIN, "sources": [RoleCatalog.MAERTYRERIN], "martyr_id": martyr, "night": s.night_number})
			KillPipeline.request_kill(ctx, martyr, KillEvent.CAUSE_MARTYR_SACRIFICE, KillEvent.SOURCE_PLAYER, martyr)
		else:
			KillPipeline.request_kill(ctx, s.pack_target_id, KillEvent.CAUSE_NIGHT_KILL, KillEvent.SOURCE_PACK, -1, true, pierce, _redirect_chain(s.pack_redirect_from))
	else:
		ctx.emit(GameEvent.NO_NIGHT_KILL, Visibility.GM, {"night_number": s.night_number})
	s.martyr_saves.clear()
	# Äpfel gelten nur in der Nacht nach der Zuflucht (R-03).
	for holder: int in s.apples.keys():
		if int(s.apples[holder]) <= s.night_number:
			s.apples.erase(holder)
	if s.pack_extra_target_id != GameState.NO_TARGET:
		KillPipeline.request_kill(ctx, s.pack_extra_target_id, KillEvent.CAUSE_NIGHT_KILL, KillEvent.SOURCE_PACK, -1, true, true, _redirect_chain(s.pack_extra_redirect_from))
	# Schicksalswolf (RM-DR-109.2 A): Zusatzopfer sind Rudelangriffe nach Rudel und Zusatzopfer des Rudelvaters.
	for fate: Dictionary in s.fate_kills.duplicate(true):
		KillPipeline.request_kill(ctx, int(fate["target_id"]), KillEvent.CAUSE_NIGHT_KILL, KillEvent.SOURCE_PACK, -1, true, false, _redirect_chain(int(fate["redirect_from"])))
	s.fate_kills.clear()
	s.pack_target_id = GameState.NO_TARGET
	s.pack_extra_target_id = GameState.NO_TARGET
	s.pack_redirect_from = -1
	s.pack_extra_redirect_from = -1
	# Zeitwächter (E-36): öffentliche Meldung; die eingefrorene Nacht zählt nicht als überlebte Nacht.
	if s.night_frozen:
		ctx.emit(GameEvent.NIGHT_FROZEN, Visibility.PUBLIC, {"night": s.night_number})
	# Fenrir und Cerberus wachsen in jeder Morgenauflösung, die sie lebend erreichen (nicht nach einer eingefrorenen Nacht).
	for id: int in (s.alive_ids() if not s.night_frozen else [] as Array[int]):
		var role := s.players[id].role_id
		if role == RoleCatalog.FENRIR or (role == RoleCatalog.CERBERUS and int(s.growth.get(id, 0)) < RoleCatalog.CERBERUS_MAX_HEADS):
			s.growth[id] = int(s.growth.get(id, 0)) + 1
			ctx.emit(GameEvent.GROWTH_CHANGED, Visibility.GM, {"player_id": id, "role_id": String(role), "value": s.growth[id]})
	s.night_frozen = false
	_finish_dawn_if_ready(ctx)


static func _finish_dawn_if_ready(ctx: RuleContext) -> void:
	var s := ctx.state
	if s.phase == Phase.DAWN_RESOLUTION and s.reactions.is_empty() and s.pending_prompt == null:
		PhaseMachine.enter(ctx, Phase.DAY)
		_ring_alarm_bells(ctx)
		_judge_nominations(ctx)


## Nachtwächter (DECISION-LOG „Rollenaudit · … Nachtwächter“): nach der vollständigen
## Morgenauflösung prüft jeder lebende Nachtwächter seine nächsten lebenden Nachbarn; gehört einer
## nicht zum Dorf (Wolf oder Einzelsieg), läuten öffentlich die Glocken, einmal pro Morgen und
## ohne Namen oder Seite. Die Einzelheiten erhält nur der Spielleiter.
static func _ring_alarm_bells(ctx: RuleContext) -> void:
	var s := ctx.state
	var watchmen: Array[int] = []
	var suspects: Array[int] = []
	for id: int in s.alive_ids():
		if s.players[id].role_id != RoleCatalog.NACHTWAECHTER or GuardRoles.silenced(s, id):
			continue
		for n: int in Seats.living_neighbours(s, id):
			if s.players[n].faction != Faction.VILLAGE:
				if not watchmen.has(id):
					watchmen.append(id)
				if not suspects.has(n):
					suspects.append(n)
	if watchmen.is_empty():
		return
	suspects.sort()
	ctx.emit(GameEvent.ALARM_BELLS_DETAIL, Visibility.GM, {"watchman_ids": watchmen, "neighbour_ids": suspects, "day": s.day_number})
	ctx.emit(GameEvent.ALARM_BELLS, Visibility.PUBLIC, {"day": s.day_number})


## Umlenkungskette eines Rudelangriffs, den ein Nekromant umgelenkt hat (E-20: nie zurück zu ihm).
static func _redirect_chain(from_id: int) -> Array[int]:
	var chain: Array[int] = []
	if from_id != -1:
		chain.append(from_id)
	return chain
