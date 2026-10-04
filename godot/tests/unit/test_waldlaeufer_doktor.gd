extends TestCase
## Informationsrollen jeder Nacht (DECISION-LOG „Rollenaudit · Waldläufer, Doktor …“, 27.09.2026).
##   Waldläufer: „Erfährt, wie viele lebende Werwölfe im Spiel sind.“ Jede Nacht (RM-DR-147.1);
##     Personen, die bei seinem Schritt leben und als Wolf zählen, jede einmal (RM-DR-147.2).
##     Priorität 5.4 (Legacy-Stufe), Bestätigung „Gezeigt“.
##   Doktor: „Nimmt jede Nacht Blutproben von zwei Spielern und erfährt, ob sie demselben Team
##     angehören.“ Zwei verschiedene andere Lebende; aktuelle Fraktion (RM-DR-145.2), zwei
##     Einzelsiegpersonen gelten als gleiches Team (RM-DR-145.1 = B), Trugbilderwolf mit wahrer
##     Fraktion. Priorität 5.0 (Legacy-Stufe), Stufen „targets“ und „shown“.
## Beide: Pflichtschritt, abbrechbar, nicht überspringbar; Ergebnis nur an die Person (actor).

const WL := "waldlaeufer"
const DK := "doktor"


func _start(roles: Array, appearances: Dictionary = {}) -> Command:
	var payload := Fixtures.start_roles(roles, 1).payload.duplicate(true)
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func test_production_roles_and_order() -> void:
	assert_eq(RoleCatalog.night_priority(&"waldlaeufer"), 54, "Waldläufer 5.4")
	assert_eq(RoleCatalog.night_priority(&"doktor"), 50, "Doktor 5.0")
	for role: StringName in [&"waldlaeufer", &"doktor"]:
		assert_eq(RoleCatalog.faction_of(role), Faction.VILLAGE, "%s Dorf" % role)
	var run := _run([_start(["werwolf", WL, DK, "das-orakel", "waldhexe", "dorfbewohner"]), Command.start_night()] as Array[Command], "Plan")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack", &"waldhexe:5", &"das-orakel:4", &"doktor:3", &"waldlaeufer:2"] as Array[StringName], "Reihenfolge nach Priorität")
		assert_false(StepQueue.is_skippable("night:1:3:doktor:3") or StepQueue.is_skippable("night:1:4:waldlaeufer:2"), "nicht überspringbar")


# --- Waldläufer ---------------------------------------------------------------------------------------

func test_ranger_counts_living_wolf_persons_now() -> void:
	# 1 Werwolf, 2 Siegreicher Wolf (einfach gezählt), 3 Wolfskind (per Korrektur verwandelt, Rudelopfer),
	# 4 Waldläufer, 5–8 Dorf. Das Rudelopfer lebt beim Schritt noch → 3.
	var cmds: Array[Command] = [_start(["werwolf", "siegreicher-wolf", "wolfskind", WL, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]),
		_gm("set_wolf_model", {"child_id": 3, "target_id": 5}), _gm("transform_wolf_child", {"child_id": 3}), Command.start_night(),
		Command.answer_prompt(1, [3]), Command.begin_step("night:1:1:waldlaeufer:4")]
	var run := _run(cmds, "Schritt")
	if not run.ok:
		return
	assert_eq(int(run.state.pending_prompt.partial["wolf_count"]), 3, "drei Wolfspersonen, Siegreicher einfach, Opfer lebt noch")
	cmds.append(Command.answer_choice(2, "shown", true))
	run = _run(cmds, "Gezeigt")
	if not run.ok:
		return
	var actor := events_of_type(run.events, "RangerRevealed")
	assert_true(actor.size() == 1 and actor[0].visibility == Visibility.ACTOR and actor[0].actor_id == 4 and int(actor[0].data["wolf_count"]) == 3, "nur der Waldläufer erfährt 3")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
	assert_true(loaded.ok and events_json(loaded.events) == events_json(run.events), "Save/Load und Replay identisch")


func test_ranger_every_night_and_marked_ranger_sleeps() -> void:
	var cmds: Array[Command] = [_start(["werwolf", WL, "waldhexe", "dorfbewohner", "amalia", "detektiv"]), Command.start_night(),
		Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:waldhexe:3"), Command.answer_choice(2, "heal", false), Command.answer_choice(2, "poison", false),
		Command.answer_choice(2, "confirm", true), Command.begin_step("night:1:2:waldlaeufer:2"), Command.answer_choice(3, "shown", true),
		Command.end_night(), CorrectionFixtures.gm("revive", {"target_id": 6}, "Test"), Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var run := _run(cmds, "Nacht 2")
	if not run.ok:
		return
	assert_true(run.state.night_plan.has(&"waldlaeufer:2"), "Schritt auch in Nacht 2")
	# Nacht 2: Waldhexe vergiftet den Waldläufer (Schritt 5.4 nach 3.4) → er wacht nicht mehr auf.
	cmds.append_array([Command.answer_prompt(4, [6]), Command.begin_step("night:2:1:waldhexe:3"), Command.answer_choice(5, "heal", false), Command.answer_choice(5, "poison", true),
		Command.answer_stage_targets(5, "poison_target", [2]), Command.answer_choice(5, "confirm", true)])
	run = _run(cmds, "Gift")
	if run.ok:
		var dropped := events_of_type(run.events, "StepDropped")
		assert_true(not dropped.is_empty() and String(dropped[-1].data["step_id"]) == "night:2:2:waldlaeufer:2" and String(dropped[-1].data["reason"]) == "marked_for_death", "vergifteter Waldläufer schläft")


func test_ranger_corrupt_count_rejected() -> void:
	var s := _run([_start(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", WL]), Command.start_night(),
		Command.answer_prompt(1, [5]), Command.begin_step("night:1:1:waldlaeufer:6")] as Array[Command], "Prompt").state
	if s == null:
		return
	var st: Dictionary = s.to_dict()
	st["pending_prompt"]["partial"]["wolf_count"] = 2
	assert_true(GameState.from_dict(st) == null, "falsche Zahl beim Laden abgelehnt")
	apply_rejected(s, Command.skip_step("night:1:1:waldlaeufer:6", "nein"), "step_not_skippable", "nicht überspringbar")


# --- Doktor -------------------------------------------------------------------------------------------

## Doktor 2 prüft `a` und `b` in Nacht 1; liefert das Ergebnis `same_team` oder null.
func _doctor(roles: Array, a: int, b: int, before: Array[Command] = [], appearances: Dictionary = {}) -> Variant:
	# Wolfskind 8 erhält vorab ein Vorbild, damit sein Auswahlschritt nicht vor dem Rudel liegt.
	var cmds: Array[Command] = [_start(roles, appearances), _gm("set_wolf_model", {"child_id": 8, "target_id": 4})]
	cmds.append_array(before)
	cmds.append_array([Command.start_night(), Command.answer_prompt(1, [1]), Command.begin_step("night:1:1:doktor:2"),
		Command.answer_stage_targets(2, "targets", [a, b])])
	var run := _run(cmds, "Doktor %d/%d" % [a, b])
	if not run.ok:
		return null
	var same: bool = run.state.pending_prompt.partial["same_team"]
	cmds.append(Command.answer_choice(2, "shown", true))
	var done := _run(cmds, "Gezeigt")
	if done.ok:
		var actor := events_of_type(done.events, "DoctorRevealed")
		assert_true(actor.size() == 1 and actor[0].actor_id == 2 and bool(actor[0].data["same_team"]) == same, "Ergebnis nur an den Doktor")
	return same


func test_doctor_same_team_rules() -> void:
	var base := ["werwolf", DK, "dorfbewohner", "amalia", "manipulator", "doppelspion", "trugbilderwolf", "wolfskind"]
	var app := {"7": "schutzengel"}
	assert_eq(_doctor(base, 3, 4, [], app), true, "zwei Dorfbewohner: gleich")
	assert_eq(_doctor(base, 1, 3, [], app), false, "Wolf und Dorf: verschieden")
	assert_eq(_doctor(base, 5, 6, [], app), true, "zwei Einzelsiegpersonen: gleiches Team (RM-DR-145.1 = B)")
	assert_eq(_doctor(base, 7, 3, [], app), false, "Trugbilderwolf mit wahrer Fraktion")
	assert_eq(_doctor(base, 8, 3, [], app), true, "unverwandeltes Wolfskind ist Dorf")
	assert_eq(_doctor(base, 8, 1, [_gm("transform_wolf_child", {"child_id": 8})] as Array[Command], app), true, "verwandeltes Wolfskind ist Wolf (aktuelle Fraktion)")


func test_doctor_invalid_targets_cancel_and_corrupt() -> void:
	var s := _run([_start(["werwolf", DK, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), _gm("kill", {"target_id": 6, "trigger_effects": false}),
		Command.start_night(), Command.answer_prompt(1, [5]), Command.begin_step("night:1:1:doktor:2")] as Array[Command], "Prompt").state
	if s == null:
		return
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [2, 3]), "invalid_target", "nicht sich selbst")
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [3, 6]), "invalid_target", "keine Toten")
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [3, 3]), "invalid_target", "zwei verschiedene")
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [3]), "invalid_target_count", "genau zwei")
	apply_rejected(s, Command.answer_choice(2, "shown", true), "stage_mismatch", "erst Ziele")
	var shown := apply_ok(s, Command.answer_stage_targets(2, "targets", [3, 1]), "Ziele").state
	var st: Dictionary = shown.to_dict()
	st["pending_prompt"]["partial"]["same_team"] = true
	assert_true(GameState.from_dict(st) == null, "falsches Ergebnis beim Laden abgelehnt")
	var cancelled := apply_ok(shown, Command.cancel_prompt(2, "zurück"), "Abbruch").state
	var again := apply_ok(cancelled, Command.begin_step("night:1:1:doktor:2"), "neu").state
	assert_true(again.pending_prompt.partial.is_empty() and String(again.pending_prompt.stage) == "targets", "Abbruch verwirft alles")


func test_no_leak_public() -> void:
	var run := _run([_start(["werwolf", DK, WL, "dorfbewohner", "amalia", "detektiv"]), Command.start_night(),
		Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:doktor:2"), Command.answer_stage_targets(2, "targets", [1, 4]),
		Command.answer_choice(2, "shown", true), Command.begin_step("night:1:2:waldlaeufer:3"), Command.answer_choice(3, "shown", true), Command.end_night()] as Array[Command], "Partie")
	if run.ok:
		for e: GameEvent in run.events:
			if e.visibility == Visibility.PUBLIC:
				assert_false(e.data.has("same_team") or e.data.has("wolf_count"), "öffentlich nichts (%s)" % e.type)
