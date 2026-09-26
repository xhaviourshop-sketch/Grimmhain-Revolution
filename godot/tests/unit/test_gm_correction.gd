extends TestCase
## GmCorrection (G-GM-1, G-TOD-2): bestätigt, begründet, protokolliert mit altem
## und neuem Wert; kein Undo, historische Ereignisse bleiben unverändert.


func _day_one_reaper() -> GameState:
	return Fixtures.play([Fixtures.start_reaper_game(), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])


func test_kill_with_effects_queues_reaction() -> void:
	# AS-G01
	var r := apply_ok(_day_one_reaper(), CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}, "Regelverstoß"), "Tod mit Folgen")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_eq(corrected.size(), 1, "GmCorrected-Ereignis")
	if corrected.size() == 1:
		var d: Dictionary = corrected[0].data
		assert_eq(String(d["kind"]), "kill", "Art")
		assert_eq(int(d["target_id"]), 3, "Ziel")
		assert_eq(d["old"], {"alive": true}, "alter Wert")
		assert_eq(d["new"], {"alive": false}, "neuer Wert")
		assert_eq(String(d["reason"]), "Regelverstoß", "Begründung")
		assert_true(bool(d["trigger_effects"]), "mit Folgen")
		assert_eq(String(corrected[0].visibility), "gm", "nur Spielleiter")
	var died := events_of_type(r.events, "SeatDied")
	assert_eq(died.size(), 1, "Tod")
	if died.size() == 1:
		assert_eq(String(died[0].data["cause"]), "GM_CORRECTION", "Ursache")
		assert_eq(String(died[0].data["source_kind"]), "gm", "Quelle Spielleiter")
	assert_eq(events_of_type(r.events, "ReactionQueued").size(), 1, "Reaktion eingereiht")
	assert_eq(r.state.reactions.size(), 1, "Reaktion im Zustand")


func test_kill_without_effects() -> void:
	# AS-G02
	var r := apply_ok(_day_one_reaper(), CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": false}), "Tod ohne Folgen")
	assert_false(r.state.players[3].alive, "tot")
	assert_eq(events_of_type(r.events, "ReactionQueued").size(), 0, "keine Reaktion")
	assert_true(r.state.reactions.is_empty(), "Warteschlange leer")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_true(corrected.size() == 1 and not bool(corrected[0].data["trigger_effects"]), "ohne Folgen protokolliert")


func test_confirmation_and_reason_required() -> void:
	var s := _day_one_reaper()
	apply_rejected(s, Command.gm_correction({"kind": "kill", "target_id": 3, "trigger_effects": true, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, Command.gm_correction({"kind": "kill", "target_id": 3, "trigger_effects": true, "reason": "x", "confirmed": false}), "confirmation_required", "Bestätigung false")
	apply_rejected(s, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}, " "), "reason_required", "ohne Begründung")
	apply_rejected(s, CorrectionFixtures.gm("kill", {"target_id": 3}), "invalid_correction", "Folgen nicht ausdrücklich gewählt")
	apply_rejected(s, CorrectionFixtures.gm("teleport", {"target_id": 3}), "invalid_correction", "unbekannte Art")
	apply_rejected(s, CorrectionFixtures.gm("kill", {"target_id": 99, "trigger_effects": false}), "unknown_player", "unbekannte Person")
	apply_rejected(GameState.new(), CorrectionFixtures.gm("kill", {"target_id": 1, "trigger_effects": false}), "game_not_started", "vor Spielstart")


func test_revive_logs_old_and_new_and_keeps_history() -> void:
	var commands: Array[Command] = [Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night()]
	var dead := RulesEngine.replay(commands)
	apply_rejected(dead.state, CorrectionFixtures.gm("revive", {"target_id": 2}), "player_alive", "Lebende wiederbeleben")
	apply_rejected(dead.state, CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}), "player_dead", "Tote töten")
	var revive := CorrectionFixtures.gm("revive", {"target_id": 6}, "falsches Opfer eingetragen")
	var r := apply_ok(dead.state, revive, "Wiederbelebung")
	assert_true(r.state.players[6].alive, "lebt wieder")
	assert_true(r.state.players[6].death == null, "kein aktueller Todesdatensatz")
	var corrected := events_of_type(r.events, "GmCorrected")
	if corrected.size() == 1:
		var d: Dictionary = corrected[0].data
		assert_eq(bool((d["old"] as Dictionary)["alive"]), false, "alter Wert tot")
		assert_eq(String(((d["old"] as Dictionary)["death"] as Dictionary)["cause"]), "NIGHT_KILL", "alter Todesdatensatz protokolliert")
		assert_eq(d["new"], {"alive": true, "death": null}, "neuer Wert")
	else:
		fail("genau ein GmCorrected-Ereignis erwartet")
	# Kein Undo: Befehl wird angehängt, frühere Ereignisse bleiben bytegleich.
	commands.append(revive)
	var full := RulesEngine.replay(commands)
	assert_eq(full.state.command_count, 5, "Korrektur zählt als eigener Befehl")
	var prefix: Array[GameEvent] = full.events.slice(0, dead.events.size())
	assert_eq(events_json(prefix), events_json(dead.events), "historische Ereignisse unverändert")
	assert_eq(events_of_type(full.events, "SeatDied").size(), 1, "historischer Tod bleibt im Protokoll")


func test_set_role() -> void:
	var s := Fixtures.play([Fixtures.start_manual(6, [1])] as Array[Command])
	apply_rejected(s, CorrectionFixtures.gm("set_role", {"target_id": 2, "role_id": "dorfbewohner"}), "no_change", "gleiche Rolle")
	apply_rejected(s, CorrectionFixtures.gm("set_role", {"target_id": 2, "role_id": "das-orakel"}), "unknown_role", "Rolle außerhalb des Katalogs")
	apply_rejected(s, CorrectionFixtures.gm("set_role", {"target_id": 2, "role_id": "test-sensentraeger"}), "unknown_role", "Testrolle")
	var r := apply_ok(s, CorrectionFixtures.gm("set_role", {"target_id": 2, "role_id": "werwolf"}, "Karte vertauscht"), "Rollenkorrektur")
	var p := r.state.players[2]
	assert_eq(String(p.role_id), "werwolf", "neue Rolle")
	assert_true(p.counts_as_wolf, "zählt als Wolf")
	assert_eq(String(p.faction), "wolves", "Fraktion")
	assert_eq(String(p.original_role_id), "dorfbewohner", "ursprüngliche Rolle bleibt")
	var corrected := events_of_type(r.events, "GmCorrected")
	if corrected.size() == 1:
		var d: Dictionary = corrected[0].data
		assert_eq(String((d["old"] as Dictionary)["role_id"]), "dorfbewohner", "alter Wert")
		assert_eq(String((d["new"] as Dictionary)["role_id"]), "werwolf", "neuer Wert")
	else:
		fail("genau ein GmCorrected-Ereignis erwartet")


func test_blocked_while_win_candidate_open() -> void:
	var s := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, []), Command.end_night(),
		Command.nominate(2, 1), Command.decide_execution(1)] as Array[Command])
	assert_true(s.win_candidate != null, "Kandidat offen")
	apply_rejected(s, CorrectionFixtures.gm("revive", {"target_id": 1}), "win_candidate_open", "Korrektur bei offenem Kandidaten")


func test_corrections_save_load_and_replay() -> void:
	var commands: Array[Command] = [
		Fixtures.start_reaper_game(4711), Command.start_night(), Command.answer_prompt(1, []), Command.end_night(),
		CorrectionFixtures.gm("set_role", {"target_id": 4, "role_id": "werwolf"}),
		CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}),
	]
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok, "angenommen (%s @ %d)" % [a.error, a.failed_index])
	assert_eq(events_json(a.events), events_json(b.events), "Replay bytegleich")
	assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich")
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(loaded.state.content_hash(), a.state.content_hash(), "Hash nach Laden")
		assert_eq(events_json(loaded.events), events_json(a.events), "Ereignisse per Replay wiederhergestellt")
