extends TestCase
## Führt alle JSON-Szenarien aus tests/scenarios/ aus (Szenarioformat: README.md).
## Jeder Schritt enthält einen Befehl; optional `reject` (erwarteter Fehlergrund)
## und `expect` (Prüfungen nach dem Schritt).

const SCENARIO_DIR := "res://tests/scenarios"


func test_all_scenarios() -> void:
	var files := DirAccess.get_files_at(SCENARIO_DIR)
	assert_true(files.size() > 0, "keine Szenarien gefunden")
	for file: String in files:
		if file.ends_with(".json"):
			_run_scenario(SCENARIO_DIR.path_join(file))


func _run_scenario(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		fail("%s: kein gültiges JSON-Objekt" % path)
		return
	var scenario: Dictionary = parsed
	var label: String = "%s (%s)" % [scenario.get("id", "?"), path.get_file()]
	var state := GameState.new()
	var all_events: Array[GameEvent] = []
	var steps: Array = scenario.get("steps", [])
	assert_true(steps.size() > 0, "%s: keine Schritte" % label)

	for i: int in steps.size():
		var step: Dictionary = steps[i]
		var command := Command.from_dict(step["cmd"])
		var where := "%s Schritt %d %s" % [label, i + 1, command.type]
		var before_hash := state.content_hash()
		var result := RulesEngine.apply(state, command)
		if step.has("reject"):
			assert_false(result.ok, "%s: Befehl hätte abgelehnt werden müssen" % where)
			assert_eq(String(result.error), String(step["reject"]), "%s: Fehlergrund" % where)
			assert_eq(state.content_hash(), before_hash, "%s: abgelehnter Befehl hat den Zustand verändert" % where)
			assert_true(result.events.is_empty(), "%s: abgelehnter Befehl erzeugte Ereignisse" % where)
		else:
			assert_true(result.ok, "%s: unerwartet abgelehnt (%s)" % [where, result.error])
			if not result.ok:
				return
			state = result.state
			all_events.append_array(result.events)
		if step.has("expect"):
			_check_expectations(where, state, result.events, all_events, step["expect"])


func _check_expectations(where: String, state: GameState, step_events: Array[GameEvent], all_events: Array[GameEvent], expect: Dictionary) -> void:
	var sd := state.to_dict()
	if expect.has("phase"):
		assert_eq(String(state.phase), String(expect["phase"]), "%s: Phase" % where)
	if expect.has("night_number"):
		assert_eq(state.night_number, int(expect["night_number"]), "%s: Nachtzähler" % where)
	if expect.has("day_number"):
		assert_eq(state.day_number, int(expect["day_number"]), "%s: Tageszähler" % where)
	if expect.has("alive"):
		var expected_alive: Array[int] = []
		for v: Variant in expect["alive"]:
			expected_alive.append(int(v))
		assert_eq(state.alive_ids(), expected_alive, "%s: lebende Personen" % where)
	# Szenarien kennen einen einzelnen offenen Kandidaten und den Sieger; beide leiten sich aus der Kandidatenmenge ab.
	var sole := sole_candidate(state)
	var derived := {
		"win_candidate": sole.to_dict() if sole != null else null,
		"winner": state.winner().to_dict() if state.winner() != null else null,
	}
	for key: String in ["win_candidate", "winner"]:
		if expect.has(key):
			if expect[key] == null:
				assert_eq(derived[key], null, "%s: %s muss leer sein" % [where, key])
			else:
				assert_true(_is_subset(expect[key], derived[key]), "%s: %s erwartet %s, erhalten %s" % [where, key, JSON.stringify(expect[key]), JSON.stringify(derived[key])])
	if expect.has("nominations"):
		assert_true(_is_subset(expect["nominations"], sd["nominations"]) and (sd["nominations"] as Array).size() == (expect["nominations"] as Array).size(),
			"%s: Nominierungen erwartet %s, erhalten %s" % [where, JSON.stringify(expect["nominations"]), JSON.stringify(sd["nominations"])])
	if expect.has("events"):
		for wanted: Variant in expect["events"]:
			var found := false
			for e: GameEvent in step_events:
				if _is_subset(wanted, e.to_dict()):
					found = true
					break
			assert_true(found, "%s: Ereignis %s fehlt" % [where, JSON.stringify(wanted)])
	if expect.has("no_event_types"):
		for e: GameEvent in step_events:
			assert_false((expect["no_event_types"] as Array).has(String(e.type)), "%s: unerwartetes Ereignis %s" % [where, e.type])
	if expect.has("forbidden_key_substrings"):
		var docs: Array = [sd]
		for e: GameEvent in all_events:
			docs.append(e.to_dict())
		for bad: Variant in expect["forbidden_key_substrings"]:
			for doc: Variant in docs:
				var hit := _find_key_containing(doc, String(bad))
				assert_eq(hit, "", "%s: verbotener Schlüssel mit '%s'" % [where, bad])


## true, wenn `expected` vollständig in `actual` enthalten ist (Dictionaries rekursiv als Teilmenge,
## Arrays elementweise, Zahlen typunabhängig).
func _is_subset(expected: Variant, actual: Variant) -> bool:
	if expected is Dictionary:
		if not actual is Dictionary:
			return false
		var a: Dictionary = actual
		for k: Variant in (expected as Dictionary):
			if not a.has(k) or not _is_subset(expected[k], a[k]):
				return false
		return true
	if expected is Array:
		if not actual is Array or (expected as Array).size() != (actual as Array).size():
			return false
		for i: int in (expected as Array).size():
			if not _is_subset(expected[i], actual[i]):
				return false
		return true
	if (expected is int or expected is float) and (actual is int or actual is float):
		return float(expected) == float(actual)
	if expected == null:
		return actual == null
	if (expected is String or expected is StringName) and (actual is String or actual is StringName):
		return String(expected) == String(actual)
	return typeof(expected) == typeof(actual) and expected == actual


func _find_key_containing(value: Variant, needle: String) -> String:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			if String(k).to_lower().contains(needle):
				return String(k)
			var inner := _find_key_containing(value[k], needle)
			if inner != "":
				return inner
	elif value is Array:
		for v: Variant in (value as Array):
			var inner := _find_key_containing(v, needle)
			if inner != "":
				return inner
	elif value is String or value is StringName:
		# Auch Ereignistypen und Schlüsselwerte dürfen keine Stimmbegriffe enthalten.
		if String(value).to_lower().contains(needle):
			return String(value)
	return ""
