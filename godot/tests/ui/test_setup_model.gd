extends UiTestCase
## Spieler-Setup, Modell und Anwendungsschicht (Auftrag Spieler-Setup, Tests 1 bis 5, 8 bis 29,
## 31, 33, 37 bis 41, 45). Ohne Szenen: PlayerSetup wird direkt erzeugt.

const SETUP_SCRIPT := "res://app/setup/player_setup.gd"
const SETUP_DIR := "res://app/setup"


func _make() -> Object:
	var script := load_script(SETUP_SCRIPT)
	return script.new() as Object if script != null else null


func _view(s: Object) -> Dictionary:
	return s.call("view") as Dictionary


func _persons(s: Object) -> Array:
	return _view(s).get("persons", []) as Array


func _ids(s: Object) -> Array[int]:
	var out: Array[int] = []
	for p: Variant in _persons(s):
		out.append(int((p as Dictionary)["person_id"]))
	return out


func _names(s: Object) -> Array[String]:
	var out: Array[String] = []
	for p: Variant in _persons(s):
		out.append(str((p as Dictionary)["name"]))
	return out


func _numbers(s: Object) -> Array[int]:
	var out: Array[int] = []
	for p: Variant in _persons(s):
		out.append(int((p as Dictionary)["number"]))
	return out


func _ok(result: Object, label: String) -> bool:
	var ok := result != null and bool(result.get("ok"))
	assert_true(ok, "%s angenommen (%s)" % [label, result.get("error") if result != null else "kein Ergebnis"])
	return ok


func _rejected(s: Object, result: Object, error: String, before: String, label: String) -> void:
	assert_true(result != null and not bool(result.get("ok")), "%s abgelehnt" % label)
	if result != null:
		assert_eq(String(result.get("error")), error, "%s: Fehlercode" % label)
	assert_eq(JSON.stringify(_view(s)), before, "%s: Zustand unverändert" % label)


func _fill(s: Object, count: int, prefix: String = "Person") -> void:
	for i: int in count:
		s.call("add_person", "%s %d" % [prefix, i + 1])


# --- IDs -------------------------------------------------------------------------------------------

func test_ids_stable_and_never_reused() -> void:
	# 1 bis 5
	var s := _make()
	if s == null:
		return
	var first: Object = s.call("add_person", "Anna")
	if not _ok(first, "erste Person"):
		return
	assert_eq(_ids(s), [1] as Array[int], "erste ID ist 1")
	assert_eq(first.get("person_ids"), [1] as Array[int], "Ergebnis nennt die neue ID")
	s.call("add_person", "Ben")
	s.call("add_person", "Clara")
	assert_eq(_ids(s), [1, 2, 3] as Array[int], "monoton steigend")
	_ok(s.call("rename_person", 1, "Anna Maria"), "umbenennen")
	assert_eq(_ids(s), [1, 2, 3] as Array[int], "Bearbeiten behält die ID")
	assert_eq(_names(s)[0], "Anna Maria", "neuer Name")
	_ok(s.call("remove_person", 2), "entfernen")
	s.call("add_person", "Dora")
	assert_eq(_ids(s), [1, 3, 4] as Array[int], "entfernte ID 2 wird nicht erneut vergeben")
	assert_eq(int(_view(s)["next_person_id"]), 5, "Zähler läuft weiter")
	var removed_all: Array[int] = _ids(s)
	for id: int in removed_all:
		s.call("remove_person", id)
	s.call("add_person", "Emil")
	assert_eq(_ids(s), [5] as Array[int], "auch nach Leeren keine Wiederverwendung")
	s.call("reset")
	var v := _view(s)
	assert_true((v["persons"] as Array).is_empty() and int(v["next_person_id"]) == 1 and not bool(v["confirmed"]) and not bool(v["has_unconfirmed_changes"]), "Verwerfen setzt Liste, Zähler und Status zurück")
	s.call("add_person", "Neu")
	assert_eq(_ids(s), [1] as Array[int], "nach Verwerfen beginnt ein neuer Entwurf bei 1")


func test_limits_come_from_one_place_and_match_core() -> void:
	var s := _make()
	if s == null:
		return
	var v := _view(s)
	assert_eq(int(v["min_persons"]), RulesEngine.MIN_PLAYERS, "Mindestzahl wie im Regelkern")
	assert_eq(int(v["max_persons"]), RulesEngine.MAX_PLAYERS, "Höchstzahl wie im Regelkern")
	assert_eq(int(v["max_name_length"]), 32, "zentrale maximale Namenslänge 32")
	var magic := RegEx.create_from_string("\\b(32|24)\\b")
	for path: String in files_in("res://app", ".gd"):
		if path.ends_with("person_name_rules.gd") or path.begins_with("res://app/theme/"):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var code := lines[n].split("#")[0]
			assert_true(magic.search(code) == null, "%s:%d Grenze nicht zentral: %s" % [path, n + 1, code.strip_edges()])


# --- Namensregeln ---------------------------------------------------------------------------------

func test_empty_and_whitespace_rejected() -> void:
	# 8, 9
	var s := _make()
	if s == null:
		return
	for raw: String in ["", "   ", "\t  ", "   ", "　"]:
		var before := JSON.stringify(_view(s))
		_rejected(s, s.call("add_person", raw), "empty_name", before, "leer %s" % JSON.stringify(raw))


func test_normalization_keeps_names_intact() -> void:
	# 10, 11
	var s := _make()
	if s == null:
		return
	var cases := {
		"  Max  ": "Max", "\tAnna Lena ": "Anna Lena", "Anna  Lena": "Anna  Lena",
		"Zoë": "Zoë", "Jean-Luc": "Jean-Luc", "O'Neill": "O'Neill", "Łukasz": "Łukasz",
		"José Ólafur": "José Ólafur", "李雷": "李雷", "mcDonald": "mcDonald", "D’Artagnan": "D’Artagnan",
	}
	for raw: String in cases:
		var result: Object = s.call("add_person", raw)
		if _ok(result, "Name %s" % raw):
			assert_eq(_names(s)[-1], cases[raw], "normalisiert %s" % JSON.stringify(raw))


func test_invalid_characters_rejected() -> void:
	var s := _make()
	if s == null:
		return
	for raw: String in ["Anna\nBen", "An\tna", "Bell\u0007"]:
		var before := JSON.stringify(_view(s))
		_rejected(s, s.call("add_person", raw), "invalid_characters", before, "Steuerzeichen %s" % JSON.stringify(raw))


func test_maximum_length() -> void:
	# 12, 13
	var s := _make()
	if s == null:
		return
	var max_len := int(_view(s)["max_name_length"])
	var exact := "Ä".repeat(max_len)
	_ok(s.call("add_person", "  " + exact + "  "), "genau %d Zeichen (nach Normalisierung)" % max_len)
	assert_eq(_names(s)[-1], exact, "nicht abgeschnitten")
	var before := JSON.stringify(_view(s))
	var result: Object = s.call("add_person", exact + "x")
	_rejected(s, result, "name_too_long", before, "%d Zeichen" % (max_len + 1))
	if result != null:
		assert_eq(int((result.get("details") as Dictionary).get("max", -1)), max_len, "Grenze im Ergebnis")


# --- Anzahl ----------------------------------------------------------------------------------------

func test_person_count_limits() -> void:
	# 14 bis 17
	var s := _make()
	if s == null:
		return
	var v := _view(s)
	assert_true(not bool(v["can_confirm"]) and int((v["validation"] as Dictionary)["missing"]) == 6, "0 Personen: unvollständig, 6 fehlen")
	_fill(s, 5)
	v = _view(s)
	assert_true(not bool(v["can_confirm"]) and int((v["validation"] as Dictionary)["missing"]) == 1, "5 Personen: gesperrt")
	var before := JSON.stringify(v)
	_rejected(s, s.call("confirm"), "too_few_persons", before, "Bestätigen mit 5")
	s.call("add_person", "Sechs")
	v = _view(s)
	assert_true(bool(v["can_confirm"]) and bool((v["validation"] as Dictionary)["valid"]), "6 Personen gültig")
	_fill(s, 18, "Weitere")
	v = _view(s)
	assert_eq(int(v["count"]), 24, "24 Personen")
	assert_true(bool(v["can_confirm"]) and not bool(v["can_add"]) and bool((v["validation"] as Dictionary)["at_maximum"]), "24 gültig, keine weitere möglich")
	before = JSON.stringify(v)
	_rejected(s, s.call("add_person", "Fünfundzwanzig"), "too_many_persons", before, "25. Person")
	_rejected(s, s.call("import_names", "A, B"), "too_many_persons", before, "Import bei 24")


# --- Dubletten -------------------------------------------------------------------------------------

func test_duplicates_warn_but_stay_separate() -> void:
	# 18, 19, 20
	var s := _make()
	if s == null:
		return
	for raw: String in ["Anna", "Ben", " max ", "Clara"]:
		s.call("add_person", raw)
	var second: Object = s.call("add_person", "anna")
	assert_true(second != null and bool(second.get("ok")) and (second.get("warnings") as Array).has(&"duplicate_name"), "Dublette angenommen mit Warnung")
	s.call("add_person", " ANNA ")
	s.call("add_person", "Max")
	var flags := {}
	for p: Variant in _persons(s):
		flags[str((p as Dictionary)["name"])] = bool((p as Dictionary)["duplicate"])
	assert_true(flags["Anna"] and flags["anna"] and flags["ANNA"] and flags["max"] and flags["Max"], "case-insensitiv erkannt")
	assert_false(flags["Ben"] or flags["Clara"], "Einzelnamen ohne Warnung")
	assert_eq(_names(s), ["Anna", "Ben", "max", "Clara", "anna", "ANNA", "Max"] as Array[String], "keine Umbenennung, nur Randleerzeichen entfernt")
	assert_eq(_ids(s), [1, 2, 3, 4, 5, 6, 7] as Array[int], "getrennte IDs")
	assert_eq(int(_view(s)["duplicate_count"]), 5, "fünf Personen mit Dublettenwarnung")
	assert_true(bool(_view(s)["can_confirm"]), "Dubletten blockieren nicht")
	_ok(s.call("confirm"), "Bestätigen trotz Dubletten")


# --- Mehrfachimport --------------------------------------------------------------------------------

func test_import_separators_and_order() -> void:
	# 21 bis 26
	var cases := {
		"Anna\nBen\nClara": ["Anna", "Ben", "Clara"],
		"Anna, Ben,Clara": ["Anna", "Ben", "Clara"],
		"Anna; Ben;Clara": ["Anna", "Ben", "Clara"],
		"Anna, Ben; Clara\n Dora ,, ;\n\n Emil\r\nFrida;": ["Anna", "Ben", "Clara", "Dora", "Emil", "Frida"],
	}
	for text: String in cases:
		var s := _make()
		if s == null:
			return
		s.call("add_person", "Vorher")
		var result: Object = s.call("import_names", text)
		if not _ok(result, "Import %s" % JSON.stringify(text)):
			continue
		var expected: Array[String] = ["Vorher"]
		expected.append_array(cases[text])
		assert_eq(_names(s), expected, "Reihenfolge %s" % JSON.stringify(text))
		var ids: Array[int] = []
		for i: int in (cases[text] as Array).size():
			ids.append(i + 2)
		assert_eq(result.get("person_ids"), ids, "IDs in Eingabereihenfolge")


func test_import_is_atomic() -> void:
	# 27, 28, 29
	var s := _make()
	if s == null:
		return
	_fill(s, 20)
	var before := JSON.stringify(_view(s))
	var too_many: Object = s.call("import_names", "A, B, C, D, E")
	_rejected(s, too_many, "too_many_persons", before, "Import über 24")
	if too_many != null:
		var d := too_many.get("details") as Dictionary
		assert_true(int(d.get("current", -1)) == 20 and int(d.get("incoming", -1)) == 5 and int(d.get("max", -1)) == 24, "Ergebnis nennt Anzahl")
	var long_name := "L".repeat(33)
	var invalid: Object = s.call("import_names", "Gut1, %s; Gut2\n%s" % [long_name, long_name + "X"])
	_rejected(s, invalid, "invalid_entries", before, "Import mit ungültigem Namen")
	if invalid != null:
		var entries := invalid.get("entries") as Array
		assert_eq(entries.size(), 2, "zwei fehlerhafte Einträge")
		if entries.size() == 2:
			assert_true(int(entries[0]["position"]) == 2 and String(entries[0]["error"]) == "name_too_long" and str(entries[0]["name"]) == long_name, "Eintrag 2 benannt")
			assert_eq(int(entries[1]["position"]), 4, "Eintrag 4 benannt")
	_rejected(s, s.call("import_names", " ,; \n\n"), "import_empty", before, "Import ohne Namen")
	_rejected(s, s.call("import_names", "Gut, Zeile\twelche"), "invalid_entries", before, "Steuerzeichen im Import")
	assert_eq(int(_view(s)["next_person_id"]), 21, "abgelehnte Importe verändern den Zähler nicht")
	var exact: Object = s.call("import_names", "A; B; person 1; D")
	assert_true(_ok(exact, "Import genau bis 24") and (exact.get("warnings") as Array).has(&"duplicate_name"), "Dublette im Import nur Warnung")
	assert_eq(int(_view(s)["count"]), 24, "24 erreicht")


# --- Bearbeiten und Entfernen ---------------------------------------------------------------------

func test_rename_is_atomic() -> void:
	# 31, 33
	var s := _make()
	if s == null:
		return
	for raw: String in ["Anna", "Ben", "Clara"]:
		s.call("add_person", raw)
	var before := JSON.stringify(_view(s))
	_rejected(s, s.call("rename_person", 2, "   "), "empty_name", before, "leer umbenennen")
	_rejected(s, s.call("rename_person", 2, "x".repeat(33)), "name_too_long", before, "zu lang umbenennen")
	_rejected(s, s.call("rename_person", 99, "Neu"), "unknown_person", before, "unbekannte Person")
	var dup: Object = s.call("rename_person", 2, " anna ")
	assert_true(_ok(dup, "zu Dublette umbenennen") and (dup.get("warnings") as Array).has(&"duplicate_name"), "Dublettenwarnung beim Umbenennen")
	assert_eq(_names(s), ["Anna", "anna", "Clara"] as Array[String], "nur Person 2 geändert")
	assert_eq(_ids(s), [1, 2, 3] as Array[int], "IDs unverändert")


func test_remove_keeps_other_ids() -> void:
	# 37
	var s := _make()
	if s == null:
		return
	for raw: String in ["Anna", "Ben", "Clara", "Dora"]:
		s.call("add_person", raw)
	_ok(s.call("remove_person", 2), "entfernen")
	assert_eq(_ids(s), [1, 3, 4] as Array[int], "übrige IDs bleiben")
	assert_eq(_numbers(s), [1, 2, 3] as Array[int], "Listennummern neu durchgezählt")
	var before := JSON.stringify(_view(s))
	_rejected(s, s.call("remove_person", 2), "unknown_person", before, "bereits entfernt")


# --- Zustand ----------------------------------------------------------------------------------------

func test_confirmed_and_unconfirmed_state() -> void:
	# 38, 39, 45 (Zurücksetzen)
	var s := _make()
	if s == null:
		return
	assert_false(bool(s.call("needs_leave_confirmation")), "leerer Entwurf: Verlassen ohne Rückfrage")
	s.call("add_person", "Anna")
	assert_true(bool(s.call("needs_leave_confirmation")), "unbestätigte Änderung: Rückfrage")
	s.call("remove_person", 1)
	assert_false(bool(s.call("needs_leave_confirmation")), "wieder leer: keine Rückfrage")
	_fill(s, 6)
	_ok(s.call("confirm"), "bestätigen")
	var v := _view(s)
	assert_true(bool(v["confirmed"]) and not bool(v["has_unconfirmed_changes"]) and not bool(v["can_confirm"]), "bestätigt")
	assert_false(bool(s.call("needs_leave_confirmation")), "bestätigt: keine Rückfrage")
	var ids_before := _ids(s)
	for action: Array in [["rename_person", [ids_before[0], "Neuer Name"]], ["add_person", ["Sieben"]], ["remove_person", [ids_before[1]]]]:
		s.call("confirm")
		s.callv(String(action[0]), action[1] as Array)
		v = _view(s)
		assert_true(not bool(v["confirmed"]) and bool(v["has_unconfirmed_changes"]), "%s setzt Bestätigung zurück" % action[0])
	var same: Object = s.call("rename_person", _ids(s)[0], "Neuer Name")
	s.call("confirm")
	same = s.call("rename_person", _ids(s)[0], " Neuer Name ")
	assert_true(same != null and bool(same.get("ok")) and bool(_view(s)["confirmed"]), "unveränderter Name hebt die Bestätigung nicht auf")
	var changes := [0]
	s.connect("changed", func(_v: Dictionary) -> void: changes[0] += 1)
	s.call("add_person", "Acht")
	assert_eq(changes[0], 1, "Änderung wird gemeldet")
	s.call("reset")
	v = _view(s)
	assert_true((v["persons"] as Array).is_empty() and int(v["next_person_id"]) == 1 and not bool(v["confirmed"]), "Neu beginnen setzt vollständig zurück")


func test_setup_layer_never_touches_rules_core() -> void:
	# 40, 41 statisch: Setup-Modell und Anwendungsschicht kennen keinen Regelkern und keine Befehle.
	var pattern := RegEx.create_from_string("\\b(GameState|RulesEngine|Command|StartGame|start_game|Player|GameSession|StateCodec)\\b")
	var files := files_in(SETUP_DIR, ".gd")
	assert_true(files.size() >= 4, "Setup-Dateien gefunden (%d)" % files.size())
	for path: String in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var code := lines[n].split("#")[0]
			assert_true(pattern.search(code) == null, "%s:%d greift auf den Regelkern zu: %s" % [path, n + 1, code.strip_edges()])


func test_view_is_a_copy() -> void:
	var s := _make()
	if s == null:
		return
	s.call("add_person", "Anna")
	var v := _view(s)
	(v["persons"] as Array).clear()
	v["count"] = 99
	assert_eq(_names(s), ["Anna"] as Array[String], "Sicht verändert den Entwurf nicht")
	var persons := _persons(s)
	(persons[0] as Dictionary)["person_id"] = 42
	assert_eq(_ids(s), [1] as Array[int], "auch nicht über Personeneinträge")
