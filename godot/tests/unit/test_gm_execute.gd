extends TestCase
## GmCorrection „execute“: Hinrichtung ohne vorherige Nominierung als bestätigte
## Spielleiter-Übersteuerung (DR-03, G-TAG-4). Ursache bleibt LYNCH; Reaktionen
## und DR-14 laufen normal.


func _day_one(roles_cmd: Command) -> GameState:
	return Fixtures.play([roles_cmd, Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])


func test_execute_without_nomination() -> void:
	var s := _day_one(Fixtures.start_manual(6, [1, 2]))
	assert_true(s.nominations_on_day(1).is_empty(), "keine Nominierung")
	apply_rejected(s, Command.decide_execution(4), "not_nominated_today", "normale Hinrichtung ohne Nominierung")
	var r := apply_ok(s, CorrectionFixtures.gm("execute", {"target_id": 4}, "Nominierung am Tisch vergessen"), "Übersteuerung")
	var died := events_of_type(r.events, "SeatDied")
	assert_eq(died.size(), 1, "ein Tod")
	if died.size() == 1:
		assert_eq(String(died[0].data["cause"]), "LYNCH", "Ursache Hinrichtung")
		assert_eq(String(died[0].data["source_kind"]), "gm", "Quelle Spielleiter-Übersteuerung")
		assert_eq(String(died[0].data["phase"]), "DAY", "am Tag")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_eq(corrected.size(), 1, "als GM-Übersteuerung protokolliert")
	if corrected.size() == 1:
		assert_eq(String(corrected[0].data["kind"]), "execute", "Art")
		assert_eq(int(corrected[0].data["target_id"]), 4, "Ziel")
		assert_eq(String(corrected[0].data["reason"]), "Nominierung am Tisch vergessen", "Begründung")
	var confirmed := events_of_type(r.events, "ExecutionConfirmed")
	assert_true(confirmed.size() == 1 and bool(confirmed[0].data["gm_override"]), "Hinrichtung als Übersteuerung markiert")
	assert_eq(String(r.state.day_step), "EXECUTION_DECIDED", "Hinrichtung des Tages erfolgt")
	apply_ok(r.state, Command.end_day(), "Tagesende möglich")


func test_execute_validation() -> void:
	var s := _day_one(Fixtures.start_manual(6, [1, 2]))
	apply_rejected(s, Command.gm_correction({"kind": "execute", "target_id": 4, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, CorrectionFixtures.gm("execute", {"target_id": 4}, ""), "reason_required", "ohne Begründung")
	apply_rejected(s, CorrectionFixtures.gm("execute", {"target_id": 99}), "unknown_player", "unbekannt")
	var dead := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false}), "Vorbereitung").state
	apply_rejected(dead, CorrectionFixtures.gm("execute", {"target_id": 5}), "player_dead", "tote Person")
	var night := Fixtures.play([Fixtures.start_manual(6, [1, 2]), Command.start_night()] as Array[Command])
	apply_rejected(night, CorrectionFixtures.gm("execute", {"target_id": 4}), "wrong_phase", "nachts")
	var ended := apply_ok(apply_ok(s, Command.decide_execution(-1), "keine Hinrichtung").state, Command.end_day(), "Tagesende").state
	apply_rejected(ended, CorrectionFixtures.gm("execute", {"target_id": 4}), "day_already_ended", "nach Tagesende")


func test_execute_triggers_reaction_and_dr14() -> void:
	# 1, 2 Werwölfe; 3 Test-Sensenträger; 4–6 Dorf. Nacht 1 tötet 6 → 2 gegen 3.
	var s := Fixtures.play([Fixtures.start_reaper_game(), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night()] as Array[Command])
	var r := apply_ok(s, CorrectionFixtures.gm("execute", {"target_id": 3}, "Übersteuerung"), "Hinrichtung des Sensenträgers")
	assert_eq(events_of_type(r.events, "ReactionQueued").size(), 1, "Todesreaktion eingereiht")
	var provisional := events_of_type(r.events, "WinStatusProvisional")
	assert_eq(provisional.size(), 1, "vorläufiger Status")
	if provisional.size() == 1:
		assert_eq(String((provisional[0].data["results"] as Array)[0]["kind"]), "wolves", "vorläufig Parität 2:2")
	assert_eq(events_of_type(r.events, "WinDetected").size(), 0, "kein Kandidat bei offener Reaktion")
	apply_rejected(r.state, Command.end_day(), "reaction_open", "Tagesende blockiert")
	var begun := apply_ok(r.state, Command.begin_step("reaction:1"), "Reaktion").state
	var cursed := apply_ok(begun, Command.answer_prompt(begun.pending_prompt.id, [1]), "Fluch auf Werwolf")
	var final_status := events_of_type(cursed.events, "WinStatusFinal")
	assert_true(final_status.size() == 1 and (final_status[0].data["results"] as Array).is_empty(), "verbindlich kein Sieg")
	assert_true(sole_candidate(cursed.state) == null, "kein Kandidat")


func test_execute_save_load_and_replay() -> void:
	var commands: Array[Command] = [Fixtures.start_reaper_game(7), Command.start_night(), Command.answer_prompt(1, [6]),
		Command.end_night(), CorrectionFixtures.gm("execute", {"target_id": 3})]
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok, "angenommen (%s @ %d)" % [a.error, a.failed_index])
	assert_eq(events_json(a.events), events_json(b.events), "Replay bytegleich")
	assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich")
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(loaded.state.content_hash(), a.state.content_hash(), "Hash nach Laden")
		assert_eq(RulesEngine.next_step_id(loaded.state), "reaction:1", "offene Reaktion nach Laden")
