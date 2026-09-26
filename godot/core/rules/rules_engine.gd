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

	var roles: Array[StringName] = []
	match DictRead.get_string(p, "assignment"):
		"manual":
			var map := DictRead.get_dict(p, "roles")
			if map.size() != ids.size():
				return &"role_count_mismatch"
			for id: int in ids:
				if not map.has(str(id)):
					return &"role_count_mismatch"
				roles.append(StringName(str(map[str(id)])))
		"random":
			var pool := DictRead.get_array(p, "role_pool")
			if pool.size() != ids.size():
				return &"role_count_mismatch"
			for r: Variant in pool:
				roles.append(StringName(str(r)))
		_:
			return &"invalid_assignment"

	var counts := {}
	var test_mode := p.get("test_mode") is bool and bool(p["test_mode"])
	for r: StringName in roles:
		# Testrollen nur mit ausdrücklichem test_mode (headless Tests, keine Produktion).
		if not RoleCatalog.has_role(r) or (RoleCatalog.is_test_only(r) and not test_mode):
			return &"unknown_role"
		counts[r] = int(counts.get(r, 0)) + 1
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
		# Pflichtreaktionen werden beantwortet (auch mit Verzicht), nie übersprungen.
		if StepQueue.is_reaction_step(step_id):
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
	var targets: Variant = DictRead.to_int_array(DictRead.get_array(p, "targets"))
	if targets == null or not p.get("targets") is Array:
		return &"invalid_target"
	var list: Array[int] = targets
	if list.size() < prompt.min_count or list.size() > prompt.max_count:
		return &"invalid_target_count"
	var seen: Array[int] = []
	for t: int in list:
		if not prompt.allowed_ids.has(t) or seen.has(t):
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
			_answer_prompt(ctx, DictRead.to_int_array(p["targets"]))
		Command.BEGIN_STEP:
			StepQueue.begin(ctx, DictRead.get_string(p, "step_id"))
		Command.SKIP_STEP:
			StepQueue.skip(ctx, DictRead.get_string(p, "step_id"), DictRead.get_string(p, "reason").strip_edges())
		Command.CANCEL_PROMPT:
			StepQueue.cancel_prompt(ctx, DictRead.get_string(p, "reason").strip_edges())
		Command.GM_CORRECTION:
			GmCorrections.execute(ctx, p)
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
				ctx.emit(GameEvent.EXECUTION_CONFIRMED, Visibility.PUBLIC, {"target_id": target, "day": s.day_number})
				KillPipeline.request_kill(ctx, target, KillEvent.CAUSE_LYNCH, KillEvent.SOURCE_VILLAGE)
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

	# Zuordnung Person → Rolle. Zufall ausschließlich über den gespeicherten Seed,
	# Personen in aufsteigender ID-Reihenfolge (unabhängig von der Sitzreihenfolge).
	var roles: Array = []
	if DictRead.get_string(p, "assignment") == "random":
		roles = s.rng.shuffled(DictRead.get_array(p, "role_pool"))
	else:
		var map := DictRead.get_dict(p, "roles")
		for id: int in ids:
			roles.append(map[str(id)])

	for i: int in ids.size():
		var player := Player.new()
		player.id = ids[i]
		player.name = names[ids[i]]
		player.role_id = StringName(str(roles[i]))
		player.original_role_id = player.role_id
		player.faction = RoleCatalog.faction_of(player.role_id)
		player.counts_as_wolf = RoleCatalog.counts_as_wolf(player.role_id)
		player.appears_as = RoleCatalog.appears_as(player.role_id)
		s.players[player.id] = player
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
	if s.night_plan.is_empty():
		ctx.emit(GameEvent.NIGHT_STEP_SKIPPED, Visibility.GM, {"step": StepQueue.PACK, "reason": "no_living_wolf"})
		return
	StepQueue.begin(ctx, StepQueue.night_step_id(s, 0))


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
			s.next_night_step += 1
		PendingPrompt.OWNER_REACTION:
			var reaction: Reaction = s.reactions.pop_front()
			ctx.emit(GameEvent.REACTION_RESOLVED, Visibility.GM, {
				"reaction_id": reaction.id, "owner_id": reaction.owner_id, "target_id": target,
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
