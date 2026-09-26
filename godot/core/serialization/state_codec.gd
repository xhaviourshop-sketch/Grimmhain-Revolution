class_name StateCodec
extends RefCounted
## Versionierter JSON-Codec für Spielstände (A-19, 03 §6.1). Arbeitet nur auf
## Strings; Dateizugriff, atomisches Schreiben und Backups liegen außerhalb des
## Domain-Core (SaveService, B-13).
##
## Aufbau: format, schema_version, rules_version, round_id, commands, state,
## state_hash (fachlicher Hash) und integrity (SHA-256 über alle übrigen Felder).
## Beim Laden wird die Befehlsliste erneut abgespielt und muss denselben
## fachlichen Hash ergeben.

const FORMAT := "grimmhain-save"


static func encode(state: GameState, commands: Array[Command]) -> String:
	var command_list: Array = []
	for c: Command in commands:
		command_list.append(c.to_dict())
	var doc := {
		"format": FORMAT,
		"schema_version": GameState.SCHEMA_VERSION,
		"rules_version": String(state.rules_version),
		"round_id": state.round_id,
		"commands": command_list,
		"state": state.to_dict(),
		"state_hash": state.content_hash(),
	}
	doc["integrity"] = CanonicalJson.sha256(doc)
	return CanonicalJson.stringify(doc)


static func decode(text: String) -> LoadResult:
	var json := JSON.new()
	if text.strip_edges() == "" or json.parse(text) != OK:
		return LoadResult.failed(&"invalid_json")
	var data: Variant = CanonicalJson.normalize(json.data)
	if not data is Dictionary:
		return LoadResult.failed(&"not_an_object")
	var doc: Dictionary = data
	if DictRead.get_string(doc, "format") != FORMAT:
		return LoadResult.failed(&"wrong_format")
	if DictRead.get_int(doc, "schema_version", -1) != GameState.SCHEMA_VERSION:
		# Später: Migrationskette core/serialization/migrations/ (03 §6.2).
		return LoadResult.failed(&"unsupported_schema_version")
	if DictRead.get_string(doc, "rules_version") != String(GameState.RULES_VERSION):
		return LoadResult.failed(&"unsupported_rules_version")

	var body := doc.duplicate(true)
	body.erase("integrity")
	if CanonicalJson.sha256(body) != DictRead.get_string(doc, "integrity"):
		return LoadResult.failed(&"integrity_mismatch")

	var state := GameState.from_dict(DictRead.get_dict(doc, "state"))
	if state == null:
		return LoadResult.failed(&"state_invalid")
	if state.content_hash() != DictRead.get_string(doc, "state_hash"):
		return LoadResult.failed(&"state_hash_mismatch")

	var commands: Array[Command] = []
	for item: Variant in DictRead.get_array(doc, "commands"):
		if not item is Dictionary:
			return LoadResult.failed(&"commands_invalid")
		commands.append(Command.from_dict(item))
	var replayed := RulesEngine.replay(commands)
	if not replayed.ok:
		return LoadResult.failed(&"replay_rejected")
	if replayed.state.content_hash() != state.content_hash():
		return LoadResult.failed(&"replay_mismatch")

	var result := LoadResult.new()
	result.ok = true
	result.state = state
	result.commands = commands
	result.events = replayed.events
	return result
