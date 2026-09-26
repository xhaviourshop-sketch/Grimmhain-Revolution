extends TestCase
## GmCorrection „set_role_field“: eng begrenzte Korrektur gespeicherter Rollenfelder.
## Erlaubt ist nur `appears_as` (Erscheinung gegenüber Informationsrollen; das Feld,
## das beim Trugbilderwolf die Scheinrolle trägt). Der Trugbilderwolf selbst ist noch
## keine Rolle im Kern; getestet wird die Mechanik an einem Werwolf.


func _setup() -> GameState:
	return Fixtures.play([Fixtures.start_manual(6, [1, 2])] as Array[Command])


func test_correct_appears_as() -> void:
	var s := _setup()
	assert_eq(String(s.players[1].appears_as), "werwolf", "Ausgangswert")
	var r := apply_ok(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": "dorfbewohner"}, "Scheinrolle falsch eingetragen"), "Feldkorrektur")
	var p := r.state.players[1]
	assert_eq(String(p.appears_as), "dorfbewohner", "neuer Wert")
	assert_eq(String(p.role_id), "werwolf", "Rolle unverändert")
	assert_true(p.counts_as_wolf, "Wolfszählung unverändert")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_eq(corrected.size(), 1, "protokolliert")
	if corrected.size() == 1:
		var d: Dictionary = corrected[0].data
		assert_eq(String(d["kind"]), "set_role_field", "Art")
		assert_eq(int(d["target_id"]), 1, "Ziel")
		assert_eq(d["old"], {"appears_as": "werwolf"}, "alter Wert")
		assert_eq(d["new"], {"appears_as": "dorfbewohner"}, "neuer Wert")
		assert_eq(String(d["reason"]), "Scheinrolle falsch eingetragen", "Begründung")


func test_only_allowed_fields_and_values() -> void:
	var s := _setup()
	for field: String in ["role_id", "faction", "counts_as_wolf", "alive", "original_role_id", "name", ""]:
		apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": field, "value": "dorfbewohner"}), "field_not_correctable", "Feld '%s'" % field)
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": "spiegelwolf"}), "invalid_value", "unbekannte Rolle")
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": ""}), "invalid_value", "leerer Wert")
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": 7}), "invalid_value", "kein Text")
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": "werwolf"}), "no_change", "gleicher Wert")
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 99, "field": "appears_as", "value": "dorfbewohner"}), "unknown_player", "unbekannte Person")
	apply_rejected(s, Command.gm_correction({"kind": "set_role_field", "target_id": 1, "field": "appears_as", "value": "dorfbewohner", "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": "dorfbewohner"}, " "), "reason_required", "ohne Begründung")


func test_role_field_save_load_and_replay() -> void:
	var commands: Array[Command] = [Fixtures.start_manual(6, [1, 2], 3),
		CorrectionFixtures.gm("set_role_field", {"target_id": 2, "field": "appears_as", "value": "dorfbewohner"})]
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok, "angenommen (%s)" % a.error)
	assert_eq(events_json(a.events), events_json(b.events), "Replay bytegleich")
	assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich")
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(String(loaded.state.players[2].appears_as), "dorfbewohner", "korrigierter Wert geladen")
		assert_eq(loaded.state.content_hash(), a.state.content_hash(), "Hash nach Laden")
