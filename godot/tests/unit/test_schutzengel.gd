extends TestCase
## Produktionsrolle `schutzengel` (Guardian Angel), rules-register.md §3, DR-05.
## G6:  1, 2 Werwölfe; 3 Schutzengel; 4, 5, 6 Dorfbewohner.
## G6R: 1, 2 Werwölfe; 3 Schutzengel; 4 Sensenträger; 5, 6 Dorfbewohner.
## G7:  1, 2 Werwölfe; 3, 4 Schutzengel; 5, 6, 7 Dorfbewohner.
## Nacht 1: Schritt 0 = Schutzengel (Prompt 1), danach Rudel per BeginStep.

const GUARD_1 := "night:1:0:schutzengel:3"
const PACK_1 := "night:1:1:pack"
const FORBIDDEN_PUBLIC := ["schutzengel", "guardian", "protect", "prevent", "werwolf", "dorfbewohner", "sensentraeger", "role", "allowed", "cause", "targets"]


func _g6(seed_value: int = 1) -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "dorfbewohner", "dorfbewohner", "dorfbewohner"], seed_value)


func _g6r() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "sensentraeger", "dorfbewohner", "dorfbewohner"])


func _g7() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "schutzengel", "dorfbewohner", "dorfbewohner", "dorfbewohner"])


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## Nacht 1 bis einschließlich Rudelwahl: Schutz auf `protect`, Rudel wählt `victim` (-1 = kein Opfer).
func _night_one(start: Command, protect: int, victim: int) -> Array[Command]:
	return [start, Command.start_night(), Command.answer_prompt(1, [protect]), Command.begin_step(PACK_1),
		Command.answer_prompt(2, [] if victim < 0 else [victim])]


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _protection_of(s: GameState, guardian: int) -> Protection:
	for p: Protection in s.protections:
		if p.guardian_id == guardian:
			return p
	return null


# --- Rolle und Nachtplan -------------------------------------------------------

func test_production_role() -> void:
	# Zusatz 1
	var r := apply_ok(GameState.new(), _g6(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	var p := r.state.players[3]
	assert_eq(String(p.role_id), "schutzengel", "Rolle")
	assert_eq(String(p.faction), "village", "Dorf")
	assert_false(p.counts_as_wolf, "kein Wolf")
	assert_eq(String(p.appears_as), "schutzengel", "Erscheinung")


func test_guard_step_before_pack() -> void:
	# Zusatz 2 und 4
	var run := _replay_ok([_g6(), Command.start_night()] as Array[Command], "Nacht 1")
	if not run.ok:
		return
	var s := run.state
	assert_eq(s.night_plan, [&"schutzengel:3", &"pack"] as Array[StringName], "Schutzengel vor dem Rudel")
	assert_eq(RulesEngine.next_step_id(s), GUARD_1, "erster Schritt ist der Schutzengel")
	assert_eq(s.pending_prompt.step_id, GUARD_1, "Prompt gehört zum Schutzengel")
	assert_eq(int(s.pending_prompt.actor_id), 3, "handelnde Person")
	assert_eq(s.pending_prompt.allowed_ids, [1, 2, 4, 5, 6] as Array[int], "jede andere lebende Person")
	assert_eq(s.pending_prompt.min_count, 1, "Pflichtauswahl")
	assert_eq(s.pending_prompt.max_count, 1, "genau eine Person")
	apply_rejected(s, Command.end_night(), "prompt_open", "nicht still überspringen")
	apply_rejected(s, Command.answer_prompt(1, []), "invalid_target_count", "leere Auswahl")


func test_choose_other_living_person() -> void:
	# Zusatz 3
	var s := Fixtures.play([_g6(), Command.start_night()] as Array[Command])
	var r := apply_ok(s, Command.answer_prompt(1, [6]), "Schutz auf 6")
	var p := _protection_of(r.state, 3)
	assert_true(p != null and p.target_id == 6 and p.night == 1, "Schutz gespeichert (Schutzengel, Ziel, Nacht)")
	assert_eq(String(r.state.night_step_status[0]), "done", "Schritt erledigt")
	assert_eq(events_of_type(r.events, "ProtectionSet").size(), 1, "ProtectionSet protokolliert")
	assert_eq(RulesEngine.next_step_id(r.state), PACK_1, "danach das Rudel")
	apply_rejected(r.state, Command.begin_step(GUARD_1), "step_out_of_order", "Schritt genau einmal")


func test_self_protection_rejected() -> void:
	# AS-R04, Zusatz 5
	var s := Fixtures.play([_g6(), Command.start_night()] as Array[Command])
	assert_false(s.pending_prompt.allowed_ids.has(3), "Selbstwahl nicht angeboten")
	apply_rejected(s, Command.answer_prompt(1, [3]), "invalid_target", "manipulierte Selbstwahl")


func test_dead_not_valid_and_same_target_twice() -> void:
	# Zusatz 6 und 7: Nacht 1 Schutz auf 6, Rudel tötet 4; Nacht 2 erneut Schutz auf 6.
	var commands := _concat(_night_one(_g6(), 6, 4), [Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command])
	var run := _replay_ok(commands, "Nacht 2")
	if not run.ok:
		return
	var s := run.state
	assert_eq(RulesEngine.next_step_id(s), "night:2:0:schutzengel:3", "Schutzengel in Nacht 2")
	assert_false(s.pending_prompt.allowed_ids.has(4), "Tote nicht wählbar")
	apply_rejected(s, Command.answer_prompt(s.pending_prompt.id, [4]), "invalid_target", "tote Person")
	var again := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [6]), "dieselbe Person erneut")
	assert_true(_protection_of(again.state, 3).night == 2, "Schutz für Nacht 2")


func test_no_guard_step_without_living_guardian() -> void:
	# Zusatz 19
	var commands := _concat(_night_one(_g6(), 6, 3), [Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command])
	var run := _replay_ok(commands, "Schutzengel tot")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack"] as Array[StringName], "nur Rudelschritt")
		assert_eq(RulesEngine.next_step_id(run.state), "night:2:0:pack", "nächster Schritt Rudel")


func test_two_guardians_ordered_by_id() -> void:
	# Zusatz 20
	var run := _replay_ok([_g7(), Command.start_night()] as Array[Command], "zwei Schutzengel")
	if not run.ok:
		return
	assert_eq(run.state.night_plan, [&"schutzengel:3", &"schutzengel:4", &"pack"] as Array[StringName], "stabile Reihenfolge nach ID")
	var s := apply_ok(run.state, Command.answer_prompt(1, [6]), "erster Schutzengel").state
	assert_eq(RulesEngine.next_step_id(s), "night:1:1:schutzengel:4", "eigene Step-ID für den zweiten")
	var begun := apply_ok(s, Command.begin_step("night:1:1:schutzengel:4"), "zweiter Schutzengel").state
	assert_eq(int(begun.pending_prompt.actor_id), 4, "zweiter handelt")
	assert_false(begun.pending_prompt.allowed_ids.has(4), "auch hier kein Selbstschutz")


func test_cancel_before_confirmation() -> void:
	# Zusatz 22
	var s := Fixtures.play([_g6(), Command.start_night()] as Array[Command])
	var cancelled := apply_ok(s, Command.cancel_prompt(1, "zu früh"), "Abbruch").state
	assert_eq(RulesEngine.next_step_id(cancelled), GUARD_1, "Schritt erneut angeboten")
	assert_true(cancelled.protections.is_empty(), "kein Schutz gespeichert")
	var begun := apply_ok(cancelled, Command.begin_step(GUARD_1), "neu begonnen").state
	assert_eq(begun.pending_prompt.allowed_ids, s.pending_prompt.allowed_ids, "gleiche Ziele")
	var done := apply_ok(begun, Command.answer_prompt(2, [6]), "bestätigt").state
	apply_rejected(done, Command.cancel_prompt(2, "zu spät"), "no_open_prompt", "bestätigte Wahl nicht abbrechbar")
	assert_true(_protection_of(done, 3) != null, "Schutz bleibt")


func test_skip_guard_step_with_reason() -> void:
	var s := Fixtures.play([_g6(), Command.start_night()] as Array[Command])
	apply_rejected(s, Command.skip_step(GUARD_1, " "), "reason_required", "nicht still")
	var r := apply_ok(s, Command.skip_step(GUARD_1, "Person schläft"), "Überspringen mit Grund")
	assert_eq(String(r.state.night_step_status[0]), "skipped", "Status übersprungen")
	assert_true(r.state.protections.is_empty(), "kein Schutz")


# --- Abfangen -------------------------------------------------------------------

func test_protected_target_survives() -> void:
	# AS-R01, AS-R02, Zusatz 8–10, 12
	var run := _replay_ok(_night_one(_g6(), 6, 6), "Schutz und Angriff auf 6")
	if not run.ok:
		return
	assert_true(run.state.players[6].alive, "vor der Morgenauflösung lebt 6")
	assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "noch keine Anwendung")
	var dawn := apply_ok(run.state, Command.end_night(), "Morgen")
	assert_true(dawn.state.players[6].alive, "6 überlebt")
	var prevented := events_of_type(dawn.events, "KillPrevented")
	assert_eq(prevented.size(), 1, "genau ein KillPrevented")
	if prevented.size() == 1:
		var d: Dictionary = prevented[0].data
		assert_eq(int(d["target_id"]), 6, "Ziel")
		assert_eq(String(d["cause"]), "NIGHT_KILL", "Ursache")
		assert_eq(String(d["source_kind"]), "pack", "Angreifer")
		assert_eq(String(d["protection"]), "schutzengel", "Schutzquelle")
		assert_eq(int(d["guardian_id"]), 3, "Schutzengel-ID")
		assert_eq(int(d["night"]), 1, "Nacht")
		assert_eq(String(prevented[0].visibility), "gm", "nur Spielleiter")
	assert_eq(events_of_type(dawn.events, "SeatDied").size(), 0, "kein Todesereignis")
	assert_eq(events_of_type(dawn.events, "WinStatusProvisional").size(), 0, "keine vorläufige Siegprüfung")
	assert_eq(String(dawn.state.phase), "DAY", "Morgen läuft normal weiter")
	assert_true(dawn.state.protections.is_empty(), "Schutz endet bei Tagesbeginn")


func test_prevented_attack_on_reaper_no_reaction() -> void:
	# Zusatz 11
	var run := _replay_ok(_concat(_night_one(_g6r(), 4, 4), [Command.end_night()] as Array[Command]), "Schutz auf Sensenträger")
	if run.ok:
		assert_true(run.state.players[4].alive, "Sensenträger lebt")
		assert_eq(events_of_type(run.events, "ReactionQueued").size(), 0, "keine Todesreaktion")


func test_curse_not_prevented() -> void:
	# AS-R32, Zusatz 13: Schutz auf 5, Rudel tötet Sensenträger 4, Fluch auf 5.
	var run := _replay_ok(_concat(_night_one(_g6r(), 5, 4), [Command.end_night(), Command.begin_step("reaction:1"),
		Command.answer_prompt(3, [5])] as Array[Command]), "Fluch trotz Schutz")
	if not run.ok:
		return
	assert_false(run.state.players[5].alive, "geschützte Person stirbt durch Fluch")
	assert_eq(String(run.state.players[5].death.cause), "HUNTER_SHOT", "Ursache Fluch")
	assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "nichts verhindert")


func test_execution_not_prevented() -> void:
	# Zusatz 14
	var run := _replay_ok(_concat(_night_one(_g6(), 5, 6), [Command.end_night(), Command.nominate(4, 5), Command.decide_execution(5)] as Array[Command]), "Hinrichtung")
	if run.ok:
		assert_false(run.state.players[5].alive, "Hinrichtung wirkt")
		assert_eq(String(run.state.players[5].death.cause), "LYNCH", "Ursache")


func test_gm_kill_not_prevented() -> void:
	# AS-R32, Zusatz 15
	var run := _replay_ok([_g6(), Command.start_night(), Command.answer_prompt(1, [5]),
		CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false})] as Array[Command], "GM-Tod")
	if run.ok:
		assert_false(run.state.players[5].alive, "GM-Tod wirkt")
		assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "nichts verhindert")


func test_protection_ends_after_night() -> void:
	# AS-R03, Zusatz 16: Nacht 1 Schutz auf 6 (kein Angriff); Nacht 2 Schutz auf 5, Rudel tötet 6.
	var commands := _concat(_night_one(_g6(), 6, -1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night(), Command.answer_prompt(3, [5]), Command.begin_step("night:2:1:pack"), Command.answer_prompt(4, [6]),
		Command.end_night()] as Array[Command])
	var run := _replay_ok(commands, "Nacht 2")
	if run.ok:
		assert_false(run.state.players[6].alive, "Schutz aus Nacht 1 wirkt nicht mehr")
		assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "nichts verhindert")


func test_guardian_dies_after_confirmation() -> void:
	# AS-R42, Zusatz 17
	var run := _replay_ok([_g6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1),
		CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": false}), Command.begin_step(PACK_1),
		Command.answer_prompt(3, [6]), Command.end_night()] as Array[Command], "Schutzengel stirbt")
	if not run.ok:
		return
	assert_true(run.state.players[6].alive, "Schutz wirkt trotzdem")
	var prevented := events_of_type(run.events, "KillPrevented")
	assert_true(prevented.size() == 1 and int(prevented[0].data["guardian_id"]) == 3, "verhindert durch den toten Schutzengel")


func test_protected_dies_earlier_no_new_target() -> void:
	# Zusatz 18
	var run := _replay_ok(_concat(_night_one(_g6(), 6, 6), [CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}),
		Command.end_night()] as Array[Command]), "geschützte Person stirbt vorher")
	if not run.ok:
		return
	assert_false(run.state.players[6].alive, "nicht wiederbelebt")
	assert_eq(String(run.state.players[6].death.cause), "GM_CORRECTION", "ursprüngliche Todesursache")
	assert_eq(events_of_type(run.events, "KillIgnored").size(), 1, "Angriff ins Leere")
	assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "kein Schutz nötig")
	assert_eq(String(run.state.phase), "DAY", "kein neues Rudelziel")


func test_two_guardians_same_target_one_prevention() -> void:
	# AS-R43, Zusatz 21
	var run := _replay_ok([_g7(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:schutzengel:4"),
		Command.answer_prompt(2, [6]), Command.begin_step("night:1:2:pack"), Command.answer_prompt(3, [6]), Command.end_night()] as Array[Command], "doppelter Schutz")
	if not run.ok:
		return
	var prevented := events_of_type(run.events, "KillPrevented")
	assert_eq(prevented.size(), 1, "nur einmal verhindert")
	if prevented.size() == 1:
		assert_eq(prevented[0].data["guardian_ids"], [3, 4], "beide Schutzengel")
		assert_eq(int(prevented[0].data["guardian_id"]), 3, "erster Schutzengel")


# --- Korrektur -------------------------------------------------------------------

func test_gm_set_protection() -> void:
	# Zusatz 29
	var s := Fixtures.play([_g6(), Command.start_night(), Command.skip_step(GUARD_1, "Person schläft"), Command.begin_step(PACK_1)] as Array[Command])
	var r := apply_ok(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 6}, "Wahl übersehen"), "Schutz setzen")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_true(corrected.size() == 1 and corrected[0].data["old"] == {"protected_id": -1} and corrected[0].data["new"] == {"protected_id": 6}, "alter und neuer Wert")
	assert_eq(events_of_type(r.events, "PromptCancelled").size(), 1, "offener Rudel-Prompt abgebrochen")
	var night := apply_ok(r.state, Command.begin_step(PACK_1), "Rudel neu").state
	var dawn := apply_ok(apply_ok(night, Command.answer_prompt(3, [6]), "Rudel wählt 6").state, Command.end_night(), "Morgen")
	assert_true(dawn.state.players[6].alive, "gesetzter Schutz wirkt")


func test_gm_change_protection() -> void:
	# Zusatz 30
	var s := Fixtures.play([_g6(), Command.start_night(), Command.answer_prompt(1, [5])] as Array[Command])
	var r := apply_ok(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 6}), "Schutz ändern")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_true(corrected.size() == 1 and corrected[0].data["old"] == {"protected_id": 5} and corrected[0].data["new"] == {"protected_id": 6}, "alter und neuer Wert")
	var dawn := RulesEngine.replay([_g6(), Command.start_night(), Command.answer_prompt(1, [5]),
		CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 6}), Command.begin_step(PACK_1),
		Command.answer_prompt(2, [6]), Command.end_night()] as Array[Command])
	assert_true(dawn.ok and dawn.state.players[6].alive, "geänderter Schutz wirkt")


func test_gm_remove_protection() -> void:
	# Zusatz 31
	var run := _replay_ok([_g6(), Command.start_night(), Command.answer_prompt(1, [6]),
		CorrectionFixtures.gm("remove_protection", {"guardian_id": 3}), Command.begin_step(PACK_1),
		Command.answer_prompt(2, [6]), Command.end_night()] as Array[Command], "Schutz entfernen")
	if not run.ok:
		return
	assert_false(run.state.players[6].alive, "ohne Schutz stirbt 6")
	var corrected := events_of_type(run.events, "GmCorrected")
	assert_true(corrected.size() == 1 and corrected[0].data["old"] == {"protected_id": 6} and corrected[0].data["new"] == {"protected_id": -1}, "alter und neuer Wert")


func test_invalid_protection_corrections() -> void:
	# Zusatz 32
	var open := Fixtures.play([_g6(), Command.start_night()] as Array[Command])
	apply_rejected(open, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 6}), "step_not_completed", "Schritt noch offen")
	var s := Fixtures.play([_g6(), Command.start_night(), Command.answer_prompt(1, [5])] as Array[Command])
	apply_rejected(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 3}), "invalid_target", "Selbstschutz")
	apply_rejected(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 5}), "no_change", "gleiches Ziel")
	apply_rejected(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 4, "target_id": 6}), "not_a_guardian", "kein Schutzengel")
	apply_rejected(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 99, "target_id": 6}), "unknown_player", "unbekannt")
	apply_rejected(s, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 99}), "unknown_player", "unbekanntes Ziel")
	apply_rejected(s, Command.gm_correction({"kind": "set_protection", "guardian_id": 3, "target_id": 6, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	var dead := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}), "Vorbereitung").state
	apply_rejected(dead, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 6}), "player_dead", "tote Person")
	var removed := apply_ok(s, CorrectionFixtures.gm("remove_protection", {"guardian_id": 3}), "entfernen").state
	apply_rejected(removed, CorrectionFixtures.gm("remove_protection", {"guardian_id": 3}), "no_change", "kein Schutz vorhanden")
	var day := Fixtures.play(_concat(_night_one(_g6(), 5, -1), [Command.end_night()] as Array[Command]))
	apply_rejected(day, CorrectionFixtures.gm("set_protection", {"guardian_id": 3, "target_id": 6}), "wrong_phase", "vergangene Nacht")


# --- Save/Load, Replay, Geheimhaltung ------------------------------------------

func test_save_load_points() -> void:
	# Zusatz 23–26 und 34
	var cases := {
		"vor dem Schutzengelschritt": [_g6()] as Array[Command],
		"Prompt offen": [_g6(), Command.start_night()] as Array[Command],
		"nach bestätigter Wahl": [_g6(), Command.start_night(), Command.answer_prompt(1, [6])] as Array[Command],
		"Morgenauflösung": _concat(_night_one(_g6r(), 5, 4), [Command.end_night()] as Array[Command]),
	}
	var next_cmd := {
		"vor dem Schutzengelschritt": Command.start_night(),
		"Prompt offen": Command.answer_prompt(1, [6]),
		"nach bestätigter Wahl": Command.begin_step(PACK_1),
		"Morgenauflösung": Command.begin_step("reaction:1"),
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label])
		var run := _replay_ok(commands, label)
		if not run.ok:
			continue
		var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
		assert_true(loaded.ok, "%s: Laden (%s)" % [label, loaded.error])
		if not loaded.ok:
			continue
		assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: Hash" % label)
		assert_eq(loaded.state.night_plan, run.state.night_plan, "%s: Nachtplan" % label)
		assert_eq(RulesEngine.next_step_id(loaded.state), RulesEngine.next_step_id(run.state), "%s: nächster Schritt" % label)
		var a := RulesEngine.apply(run.state, next_cmd[label])
		var b := RulesEngine.apply(loaded.state, next_cmd[label])
		assert_true(a.ok and b.ok, "%s: Fortsetzung angenommen (%s)" % [label, a.error])
		assert_eq(events_json(b.events), events_json(a.events), "%s: identische Fortsetzung" % label)


func test_replay_prevented_and_ineffective() -> void:
	# Zusatz 27 und 28
	for victim: int in [6, 4]:
		var commands := _concat(_night_one(_g6(4711), 6, victim), [Command.end_night()] as Array[Command])
		var a := RulesEngine.replay(commands)
		var b := RulesEngine.replay(commands)
		assert_true(a.ok and b.ok, "Replay angenommen (%s)" % a.error)
		assert_eq(events_json(a.events), events_json(b.events), "Ereignisse bytegleich (Opfer %d)" % victim)
		assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich (Opfer %d)" % victim)


func test_no_secrets_in_public_events() -> void:
	# Zusatz 33
	var run := _replay_ok(_concat(_night_one(_g6(), 6, 6), [Command.end_night(), Command.nominate(4, 1), Command.decide_execution(1),
		Command.end_day()] as Array[Command]), "Partie")
	if not run.ok:
		return
	for type: String in ["KillPrevented", "ProtectionSet", "PromptOpened", "PromptAnswered"]:
		for e: GameEvent in events_of_type(run.events, type):
			assert_eq(String(e.visibility), "gm", "%s nur für Spielleiter" % type)
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			assert_eq(_find_forbidden(e.data), "", "öffentliches %s ohne Geheimnis" % e.type)
		elif e.visibility == &"actor":
			assert_eq(int(e.data.get("player_id", e.actor_id)), e.actor_id, "%s nur über die eigene Person" % e.type)
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")


func _find_forbidden(value: Variant) -> String:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			var hit := _match(String(k))
			if hit == "":
				hit = _find_forbidden(value[k])
			if hit != "":
				return hit
	elif value is Array:
		for v: Variant in (value as Array):
			var hit := _find_forbidden(v)
			if hit != "":
				return hit
	elif value is String or value is StringName:
		return _match(String(value))
	return ""


func _match(text: String) -> String:
	for bad: String in FORBIDDEN_PUBLIC:
		if text.to_lower().contains(bad):
			return "%s (%s)" % [text, bad]
	return ""
