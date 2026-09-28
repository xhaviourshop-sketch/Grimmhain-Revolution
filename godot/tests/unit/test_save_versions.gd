extends TestCase
## Spielstände älterer Schemaversionen werden mit klarer Meldung abgelehnt.


func test_schema_v1_rejected_with_message() -> void:
	for old: int in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]:
		var commands: Array[Command] = [Fixtures.start_manual(6, [1]), Command.start_night()]
		var state := RulesEngine.replay(commands).state
		var doc: Dictionary = JSON.parse_string(StateCodec.encode(state, commands))
		doc["schema_version"] = old
		doc.erase("integrity")
		doc["integrity"] = CanonicalJson.sha256(doc)
		var result := StateCodec.decode(CanonicalJson.stringify(doc))
		assert_false(result.ok, "Schema %d wird nicht geladen" % old)
		assert_eq(String(result.error), "unsupported_schema_version", "Fehlergrund")
		assert_true(result.detail.contains(str(old)) and result.detail.contains(str(GameState.SCHEMA_VERSION)), "Meldung nennt gefundene und erwartete Version: %s" % result.detail)
	assert_eq(GameState.SCHEMA_VERSION, 11, "aktuelle Schemaversion")
