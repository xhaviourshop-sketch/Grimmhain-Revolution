extends TestCase
## Rolle `die-gebundenen` (The Bound). Rollentext: „Wacht in der ersten Nacht auf und lernt alle
## anderen Gebundenen kennen.“ Entscheidungen (DECISION-LOG „Rollenaudit“, 27.09.2026): strikt
## nur Nacht 1 (RM-DR-014 = B); jede lebende Gebundene sieht alle anderen lebenden Gebundenen;
## lebt nur eine, erfährt sie „keine anderen“ (F-08 = A). Ein gemeinsamer Schritt (Legacy: eine
## Zeile für alle Kopien), Priorität 0.5, Bestätigung „Gezeigt“, abbrechbar, nicht überspringbar.

const DG := "die-gebundenen"
const STEP := "night:1:0:die-gebundenen"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


## ACTOR-Ereignisse `BoundRevealed` als {Person: andere IDs}.
func _revealed(events: Array[GameEvent]) -> Dictionary:
	var out := {}
	for e: GameEvent in events_of_type(events, "BoundRevealed"):
		assert_eq(e.visibility, Visibility.ACTOR, "nur an die Person")
		out[e.actor_id] = e.data["other_bound_ids"]
	return out


func test_production_role() -> void:
	var role := StringName(DG)
	assert_true(RoleCatalog.has_role(role), "im Katalog")
	assert_eq(RoleCatalog.faction_of(role), Faction.VILLAGE, "Dorf")
	assert_false(RoleCatalog.counts_as_wolf(role), "kein Wolf")
	var run := _run([_start(["werwolf", DG, "dorfchronistin", DG, "wolfskind", "dorfbewohner"]), Command.start_night()] as Array[Command], "Start")
	if not run.ok:
		return
	assert_eq(run.state.night_plan, [&"dorfchronistin:3", &"die-gebundenen", &"wolfskind:5", &"pack"] as Array[StringName], "gemeinsamer Schritt nach der Chronistin")
	assert_false(StepQueue.is_skippable("night:1:1:die-gebundenen"), "nicht überspringbar")


func test_each_living_bound_sees_other_living() -> void:
	# 2, 4, 6 Gebundene; 6 stirbt vor dem Schritt.
	var cmds: Array[Command] = [_start(["werwolf", DG, "dorfbewohner", DG, "amalia", DG, "detektiv"]), Command.start_night(),
		_gm("kill", {"target_id": 6, "trigger_effects": false}), Command.begin_step(STEP)]
	var run := _run(cmds, "Schritt")
	if not run.ok:
		return
	assert_eq(run.state.pending_prompt.partial["bound_ids"], [2, 4], "Spielleiter sieht die lebenden Gebundenen")
	cmds.append(Command.answer_choice(run.state.pending_prompt.id, "shown", true))
	run = _run(cmds, "Gezeigt")
	if not run.ok:
		return
	assert_eq(_revealed(run.events), {2: [4], 4: [2]}, "jede sieht die anderen lebenden, nicht die tote 6")
	assert_eq(events_of_type(run.events, "BoundRecorded").size(), 1, "Spielleiterdatensatz")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
	assert_true(loaded.ok and events_json(loaded.events) == events_json(run.events), "Save/Load und Replay identisch")


func test_single_bound_learns_nobody() -> void:
	var run := _run([_start(["werwolf", DG, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), Command.start_night(),
		Command.answer_choice(1, "shown", true)] as Array[Command], "allein")
	if run.ok:
		assert_eq(_revealed(run.events), {2: []}, "keine anderen")


func test_only_first_night_and_absent_without_bound() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DG, DG, "dorfbewohner", "amalia", "detektiv"]), Command.start_night(),
		Command.answer_choice(1, "shown", true), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var run := _run(cmds, "Nacht 2")
	if run.ok:
		assert_false(run.state.night_plan.has(&"die-gebundenen"), "kein Schritt in Nacht 2")
	var none := _run([_start(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), Command.start_night()] as Array[Command], "ohne")
	if none.ok:
		assert_false(none.state.night_plan.has(&"die-gebundenen"), "kein Schritt ohne Gebundene")


func test_all_bound_dead_step_dropped() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DG, DG, "dorfbewohner", "amalia", "detektiv"]), Command.start_night(),
		_gm("kill", {"target_id": 2, "trigger_effects": false}), _gm("kill", {"target_id": 3, "trigger_effects": false})]
	var run := _run(cmds, "alle tot")
	if not run.ok:
		return
	var dropped := events_of_type(run.events, "StepDropped")
	assert_true(not dropped.is_empty() and String(dropped[-1].data["step_id"]) == STEP and String(dropped[-1].data["reason"]) == "no_decision", "entfällt")


func test_cancel_invalid_and_corrupt() -> void:
	var s := _run([_start(["werwolf", DG, DG, "dorfbewohner", "amalia", "detektiv"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	apply_rejected(s, Command.answer_choice(1, "shown", false), "invalid_answer", "nur Ja")
	apply_rejected(s, Command.skip_step(STEP, "keine Lust"), "step_not_skippable", "nicht überspringbar")
	var cancelled := apply_ok(s, Command.cancel_prompt(1, "später"), "Abbruch").state
	assert_true(cancelled.pending_prompt == null and RulesEngine.next_step_id(cancelled) == STEP, "erneut ausführbar")
	var st: Dictionary = s.to_dict()
	st["pending_prompt"]["partial"]["bound_ids"] = [2]
	assert_true(GameState.from_dict(st) == null, "falsche Liste im Prompt wird beim Laden abgelehnt")


func test_24_players_six_bound() -> void:
	# 4 Wölfe, 6 Gebundene (die einzige Rolle, die mehrfach beginnen darf), 14 verschiedene Dorfrollen (PE-07).
	var roles: Array = Fixtures.wolf_fillers(4)
	for i: int in 6:
		roles.append(DG)
	roles.append_array(Fixtures.village_fillers(9))
	roles.append_array(Fixtures.extra_village(5))
	var run := _run([_start(roles), Command.start_night(), Command.answer_choice(1, "shown", true)] as Array[Command], "24")
	if not run.ok:
		return
	var seen := _revealed(run.events)
	assert_eq(seen.size(), 6, "sechs Gebundene informiert")
	assert_eq(seen[5], [6, 7, 8, 9, 10], "jede sieht die fünf anderen")


func test_no_leak() -> void:
	var run := _run([_start(["werwolf", DG, DG, "dorfbewohner", "amalia", "detektiv"]), Command.start_night(),
		Command.answer_choice(1, "shown", true)] as Array[Command], "Partie")
	if run.ok:
		for e: GameEvent in run.events:
			if e.visibility == Visibility.PUBLIC:
				assert_false(e.data.has("bound_ids") or e.data.has("other_bound_ids"), "öffentlich keine Namen (%s)" % e.type)
