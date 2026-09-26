extends TestCase
## AS-C08: Beschädigte Spielstände werden erkannt und nie still geladen.
## Rückfall auf einen älteren Checkpoint und das Verschieben der Datei gehören zur
## Speicherschicht außerhalb des Domain-Core (implementation-boundary.md A.6, B-13).

var _commands: Array[Command] = []
var _state: GameState
var _valid_text: String


func _prepare() -> void:
	_commands = [
		Fixtures.start_manual(6, [1, 2], 7),
		Command.start_night(),
		Command.answer_prompt(1, [6]),
		Command.end_night(),
	]
	_state = RulesEngine.replay(_commands).state
	_valid_text = StateCodec.encode(_state, _commands)


func _expect_error(text: String, expected: StringName, label: String) -> void:
	var result := StateCodec.decode(text)
	assert_false(result.ok, "%s: darf nicht geladen werden" % label)
	assert_eq(String(result.error), String(expected), "%s: Fehlergrund" % label)
	assert_true(result.state == null, "%s: kein Zustand bei Fehler" % label)


## Setzt die Integritätsprüfsumme passend, als hätte jemand die Datei gezielt umgeschrieben.
func _reseal(doc: Dictionary) -> String:
	doc.erase("integrity")
	doc["integrity"] = CanonicalJson.sha256(doc)
	return CanonicalJson.stringify(doc)


func test_valid_save_loads() -> void:
	_prepare()
	assert_true(StateCodec.decode(_valid_text).ok, "gültiger Spielstand lädt")


func test_truncated_json() -> void:
	_prepare()
	_expect_error(_valid_text.substr(0, _valid_text.length() / 2), &"invalid_json", "abgeschnitten")
	_expect_error("", &"invalid_json", "leer")


func test_flipped_byte_detected_by_integrity() -> void:
	_prepare()
	var tampered := _valid_text.replace("\"alive\":true", "\"alive\":false")
	assert_ne(tampered, _valid_text, "Manipulation hat stattgefunden")
	_expect_error(tampered, &"integrity_mismatch", "geändertes Byte im Zustand")
	var renamed := _valid_text.replace("\"name\":\"A\"", "\"name\":\"Z\"")
	_expect_error(renamed, &"integrity_mismatch", "geänderter Name")


func test_not_an_object_or_wrong_format() -> void:
	_prepare()
	_expect_error("[1,2,3]", &"not_an_object", "Array statt Objekt")
	var doc: Dictionary = JSON.parse_string(_valid_text)
	doc["format"] = "etwas-anderes"
	_expect_error(_reseal(doc), &"wrong_format", "falsches Format")


func test_unsupported_schema_version() -> void:
	_prepare()
	var doc: Dictionary = JSON.parse_string(_valid_text)
	doc["schema_version"] = 999
	_expect_error(_reseal(doc), &"unsupported_schema_version", "unbekannte Schemaversion")


func test_state_hash_mismatch() -> void:
	_prepare()
	var doc: Dictionary = JSON.parse_string(_valid_text)
	(doc["state"]["players"] as Array)[0]["alive"] = false
	_expect_error(_reseal(doc), &"state_hash_mismatch", "Zustand passt nicht zum Hash")


func test_state_does_not_match_commands() -> void:
	_prepare()
	# Zustand und Hash konsistent umgeschrieben, aber die Befehlsliste führt zu einem anderen Zustand.
	var doc: Dictionary = JSON.parse_string(_valid_text)
	(doc["state"]["players"] as Array)[0]["alive"] = false
	var forged := GameState.from_dict(doc["state"])
	assert_true(forged != null, "manipulierter Zustand ist strukturell gültig")
	doc["state_hash"] = forged.content_hash()
	_expect_error(_reseal(doc), &"replay_mismatch", "Zustand widerspricht Befehlsliste")


func test_invalid_command_in_log() -> void:
	_prepare()
	var doc: Dictionary = JSON.parse_string(_valid_text)
	(doc["commands"] as Array)[2]["payload"]["targets"] = [42]
	_expect_error(_reseal(doc), &"replay_rejected", "ungültiger Befehl im Protokoll")


func test_rules_version_mismatch() -> void:
	_prepare()
	var doc: Dictionary = JSON.parse_string(_valid_text)
	doc["rules_version"] = "grimmhain-andere-regeln"
	_expect_error(_reseal(doc), &"unsupported_rules_version", "fremde Regelversion")


func test_older_valid_save_still_loads_after_newer_is_corrupt() -> void:
	# Grundlage für den späteren Rückfall auf den vorherigen Checkpoint (B-13).
	_prepare()
	var older_commands: Array[Command] = _commands.slice(0, 2)
	var older_text := StateCodec.encode(RulesEngine.replay(older_commands).state, older_commands)
	_expect_error(_valid_text.substr(0, 40), &"invalid_json", "neuerer Stand beschädigt")
	var older := StateCodec.decode(older_text)
	assert_true(older.ok, "älterer Stand weiterhin ladbar")
	assert_eq(older.state.night_number, 1, "älterer Stand ist Nacht 1")
