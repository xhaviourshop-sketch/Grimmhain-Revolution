extends TestCase
## DR-14: vorläufiger Siegstatus nach jedem Tod, verbindliche Prüfung erst nach
## allen Reaktionen. DR-02: keine automatische Priorität, niemand lebt → kein Gewinner.


## AS-R36-Besetzung: 1, 2 Werwölfe; 3 Test-Sensenträger; 4, 5, 6 Dorfbewohner.
## Nacht 1 tötet 6; Tag 1 ohne Hinrichtung; Nacht 2 tötet den Sensenträger.
func _reaper_dies_at_parity() -> Array[Command]:
	return [
		Fixtures.start_reaper_game(), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.answer_prompt(2, [3]),
		Command.end_night(),
	]


func test_provisional_parity_is_lifted_by_reaction() -> void:
	# AS-R36
	var run := RulesEngine.replay(_reaper_dies_at_parity())
	assert_true(run.ok, "Befehle angenommen (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	var s := run.state
	assert_eq(s.alive_ids(), [1, 2, 4, 5] as Array[int], "2 Wölfe gegen 2 Nicht-Wölfe")
	var provisional := events_of_type(run.events, "WinStatusProvisional")
	assert_true(provisional.size() >= 1, "vorläufiger Status nach dem Tod")
	var last: Dictionary = provisional[provisional.size() - 1].data
	assert_eq(String((last["results"] as Array)[0]["kind"]), "wolves", "vorläufig Werwölfe")
	assert_true(sole_candidate(s) == null, "kein bestätigbarer Kandidat")
	assert_eq(events_of_type(run.events, "WinDetected").size(), 0, "nichts zur Bestätigung vorgelegt")
	assert_eq(String(s.phase), "DAWN_RESOLUTION", "Partie läuft weiter")
	apply_rejected(s, Command.confirm_win(1), "reaction_open", "keine Bestätigung bei offener Reaktion")
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion").state
	var cursed := apply_ok(begun, Command.answer_prompt(3, [1]), "Fluch auf Werwolf")
	assert_eq(cursed.state.alive_ids(), [2, 4, 5] as Array[int], "1 Wolf gegen 2")
	var final_status := events_of_type(cursed.events, "WinStatusFinal")
	assert_eq(final_status.size(), 1, "verbindliche Prüfung nach der Reaktion")
	if final_status.size() == 1:
		assert_eq((final_status[0].data["results"] as Array).size(), 0, "verbindlich kein Sieg")
	assert_eq(events_of_type(cursed.events, "WinDetected").size(), 0, "kein Kandidat")
	assert_true(sole_candidate(cursed.state) == null, "kein Kandidat im Zustand")
	assert_eq(String(cursed.state.phase), "DAY", "Tag beginnt")


func test_provisional_confirmed_after_reaction() -> void:
	var s := RulesEngine.replay(_reaper_dies_at_parity()).state
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion").state
	var declined := apply_ok(begun, Command.answer_prompt(3, []), "Verzicht")
	var detected := events_of_type(declined.events, "WinDetected")
	assert_eq(detected.size(), 1, "erst jetzt Kandidat")
	assert_true(sole_candidate(declined.state) != null and String(sole_candidate(declined.state).kind) == "wolves", "Kandidat Werwölfe")
	var confirmed := apply_ok(declined.state, Command.confirm_win(sole_candidate(declined.state).id), "Bestätigung")
	assert_eq(String(confirmed.state.phase), "GAME_OVER", "Spielende erst nach Bestätigung")


func test_nobody_alive_has_no_automatic_winner() -> void:
	# AS-R35 / DR-02: Nach abgelehnten Kandidaten stirbt die letzte Person.
	var state := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])
	var candidate_id := 0
	for target: int in [2, 3, 4, 5, 6]:
		var r := apply_ok(state, CorrectionFixtures.gm("kill", {"target_id": target, "trigger_effects": false}), "Korrektur Tod %d" % target)
		state = r.state
		if sole_candidate(state) != null:
			candidate_id = sole_candidate(state).id
			state = apply_ok(state, Command.reject_win(candidate_id, "Spiel geht weiter"), "Ablehnung").state
	assert_eq(state.alive_ids(), [1] as Array[int], "nur der Werwolf lebt")
	var last := apply_ok(state, CorrectionFixtures.gm("kill", {"target_id": 1, "trigger_effects": false}), "letzter Tod")
	assert_eq(last.state.alive_ids().size(), 0, "niemand lebt")
	assert_true(sole_candidate(last.state) == null, "kein automatischer Kandidat")
	var final_status := events_of_type(last.events, "WinStatusFinal")
	assert_eq(final_status.size(), 1, "verbindliche Prüfung erfolgt")
	if final_status.size() == 1:
		assert_eq((final_status[0].data["results"] as Array).size(), 2, "beide Bedingungen gleichzeitig erfüllt")
		assert_true(bool(final_status[0].data["requires_gm_decision"]), "Spielleiter muss entscheiden")
	apply_rejected(last.state, Command.confirm_win(candidate_id), "no_open_win_candidate", "nichts zu bestätigen")
	var declared := apply_ok(last.state, CorrectionFixtures.gm("declare_winner", {"winner_kind": "village"}, "Dorf hat moralisch gewonnen"), "Siegerklärung")
	assert_eq(String(declared.state.phase), "GAME_OVER", "Spielende")
	assert_eq(String(declared.state.winner().kind), "village", "erklärter Sieger")
	assert_eq(String(declared.state.winner().reason_key), "gm_declared", "Grund: Spielleitererklärung")


func test_single_death_without_reaction_detects_immediately() -> void:
	# Ohne Reaktionen fallen vorläufige und verbindliche Prüfung in denselben Befehl.
	var run := RulesEngine.replay([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, []),
		Command.end_night(), Command.nominate(2, 1), Command.decide_execution(1)] as Array[Command])
	assert_true(run.ok, "angenommen")
	assert_eq(events_of_type(run.events, "WinStatusProvisional").size(), 1, "ein vorläufiger Status")
	assert_eq(events_of_type(run.events, "WinStatusFinal").size(), 1, "eine verbindliche Prüfung")
	assert_eq(events_of_type(run.events, "WinDetected").size(), 1, "Kandidat Dorf")


func test_win_status_replay_and_save_load() -> void:
	var commands := _reaper_dies_at_parity()
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_eq(events_json(a.events), events_json(b.events), "Replay bytegleich")
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(loaded.state.content_hash(), a.state.content_hash(), "Hash nach Laden")
		assert_eq(CanonicalJson.stringify(loaded.state.provisional_win), CanonicalJson.stringify(a.state.provisional_win), "vorläufiger Status geladen")
		assert_true(loaded.state.win_check_pending, "ausstehende verbindliche Prüfung geladen")
