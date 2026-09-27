extends TestCase
## Rolle `dorfchronistin` (Village Chronicler). Rollentext: „Erfährt zu Beginn des Spiels, wie viele
## Solo-Rollen im Spiel sind.“ Entscheidungen (DECISION-LOG „Rollenaudit“, 27.09.2026): strikt nur
## in Nacht 1 (RM-DR-014 = B); gezählt werden Personen mit Einzelsiegrolle, lebend und tot;
## mehrere Chronistinnen erhalten die Information jeweils für sich (F-09 = A, G-ID-3).
## Schritt: Priorität 0.3 (Legacy-Stufe), Bestätigung „Gezeigt“, abbrechbar, nicht überspringbar.

const DC := "dorfchronistin"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


## 1 Werwolf; 2 Chronistin; 3, 4 Manipulator; 5 Doppelspion; 6 Selbstmörder; 7, 8 Dorfbewohner → 4 Einzelsiegpersonen.
func _roles() -> Array:
	return ["werwolf", DC, "manipulator", "manipulator", "doppelspion", "selbstmoerder", "dorfbewohner", "dorfbewohner"]


func test_production_role() -> void:
	var role := StringName(DC)
	assert_true(RoleCatalog.has_role(role), "im Katalog")
	assert_eq(RoleCatalog.faction_of(role), Faction.VILLAGE, "Dorf")
	assert_false(RoleCatalog.counts_as_wolf(role), "kein Wolf")
	assert_eq(RoleCatalog.night_priority(role), 3, "Priorität 0.3")
	var run := _run([_start(["werwolf", DC, "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), Command.start_night()] as Array[Command], "Start")
	if not run.ok:
		return
	assert_eq(run.state.night_plan, [&"dorfchronistin:2", &"wolfskind:3", &"pack"] as Array[StringName], "zuerst die Chronistin")
	var p := run.state.pending_prompt
	assert_true(p != null and String(p.owner) == DC and p.actor_id == 2 and p.cancellable, "Prompt der Chronistin offen")
	assert_false(StepQueue.is_skippable("night:1:0:dorfchronistin:2"), "nicht überspringbar")


func test_counts_solo_persons_including_dead() -> void:
	# Manipulator 3 stirbt vor dem Schritt: gezählt werden weiter 4 Personen (lebend und tot).
	var cmds: Array[Command] = [_start(_roles()), Command.start_night(), _gm("kill", {"target_id": 3, "trigger_effects": false}),
		Command.begin_step("night:1:0:dorfchronistin:2")]
	var run := _run(cmds, "Schritt")
	if not run.ok:
		return
	assert_eq(int(run.state.pending_prompt.partial["solo_count"]), 4, "4 Personen mit Einzelsiegrolle")
	cmds.append(Command.answer_choice(run.state.pending_prompt.id, "shown", true))
	run = _run(cmds, "Gezeigt")
	if not run.ok:
		return
	var actor := events_of_type(run.events, "ChronicleRevealed")
	assert_true(actor.size() == 1 and actor[0].visibility == Visibility.ACTOR and actor[0].actor_id == 2 and int(actor[0].data["solo_count"]) == 4, "Chronistin erfährt 4")
	var gm := events_of_type(run.events, "ChronicleRecorded")
	assert_true(gm.size() == 1 and gm[0].visibility == Visibility.GM, "Spielleiterdatensatz")
	assert_eq(String(run.state.night_step_status[0]), "done", "Schritt erledigt")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
	assert_true(loaded.ok and events_json(loaded.events) == events_json(run.events), "Save/Load und Replay identisch")


func test_only_first_night() -> void:
	var cmds: Array[Command] = [_start(_roles()), Command.start_night(), Command.answer_choice(1, "shown", true),
		Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var run := _run(cmds, "Nacht 2")
	if run.ok:
		assert_false(run.state.night_plan.has(&"dorfchronistin:2"), "kein Schritt in Nacht 2 (RM-DR-014 = B)")


func test_two_chroniclers_each_informed() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DC, "manipulator", DC, "dorfbewohner", "dorfbewohner"]), Command.start_night(),
		Command.answer_choice(1, "shown", true), Command.begin_step("night:1:1:dorfchronistin:4"), Command.answer_choice(2, "shown", true)]
	var run := _run(cmds, "zwei")
	if not run.ok:
		return
	var actor := events_of_type(run.events, "ChronicleRevealed")
	assert_eq(actor.size(), 2, "jede Chronistin für sich")
	if actor.size() == 2:
		assert_true(actor[0].actor_id == 2 and actor[1].actor_id == 4 and int(actor[1].data["solo_count"]) == 1, "nach Personen-ID, je 1")


func test_dead_chronicler_step_dropped() -> void:
	var cmds: Array[Command] = [_start(_roles()), Command.start_night(), _gm("kill", {"target_id": 2, "trigger_effects": false})]
	var run := _run(cmds, "tot")
	if not run.ok:
		return
	var dropped := events_of_type(run.events, "StepDropped")
	assert_true(not dropped.is_empty() and String(dropped[0].data["step_id"]) == "night:1:0:dorfchronistin:2" and String(dropped[0].data["reason"]) == "actor_dead", "entfällt")


func test_cancel_and_role_correction_recount() -> void:
	# Abbruch öffnet neu mit gleicher Zahl; eine Rollenkorrektur vor dem Schritt ändert die Zahl.
	var cmds: Array[Command] = [_start(_roles()), Command.start_night(), Command.cancel_prompt(1, "später"), Command.begin_step("night:1:0:dorfchronistin:2")]
	var run := _run(cmds, "Abbruch")
	if not run.ok:
		return
	assert_eq(int(run.state.pending_prompt.partial["solo_count"]), 4, "gleiche Zahl nach Abbruch")
	cmds.append_array([_gm("set_role", {"target_id": 7, "role_id": "manipulator"}), Command.begin_step("night:1:0:dorfchronistin:2")])
	run = _run(cmds, "Korrektur")
	if run.ok:
		assert_eq(int(run.state.pending_prompt.partial["solo_count"]), 5, "neue Zahl nach Rollenkorrektur")


func test_invalid_answers_and_corrupt_prompt() -> void:
	var s := _run([_start(_roles()), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	apply_rejected(s, Command.answer_choice(1, "shown", false), "invalid_answer", "nur Ja")
	apply_rejected(s, Command.answer_prompt(1, [3]), "stage_mismatch", "keine Zielwahl")
	apply_rejected(s, Command.skip_step("night:1:0:dorfchronistin:2", "keine Lust"), "step_not_skippable", "nicht überspringbar")
	var st: Dictionary = s.to_dict()
	st["pending_prompt"]["partial"]["solo_count"] = 9
	assert_true(GameState.from_dict(st) == null, "falsche Zahl im Prompt wird beim Laden abgelehnt")


func test_no_leak() -> void:
	var run := _run([_start(_roles()), Command.start_night(), Command.answer_choice(1, "shown", true)] as Array[Command], "Partie")
	if run.ok:
		for e: GameEvent in run.events:
			if e.visibility == Visibility.PUBLIC:
				assert_false(e.data.has("solo_count"), "öffentlich keine Zahl (%s)" % e.type)
			if e.visibility == Visibility.ACTOR and String(e.type) == "ChronicleRevealed":
				assert_eq(e.data.keys().size(), 2, "nur Zahl und Nacht an die Chronistin")
