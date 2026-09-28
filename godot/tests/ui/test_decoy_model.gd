extends UiTestCase
## Trugbilderwolf-Scheinrolle nach DR-08: Der Spielleiter legt sie für jede Kopie ausdrücklich
## fest; keine Vorbelegung, kein Zufall. Rolle und Scheinrolle bilden im Setup eine Kopie, die
## gemeinsam verteilt, gemischt und getauscht wird. Ohne Szenen, feste Seeds.

const SETUP_SCRIPT := "res://app/setup/player_setup.gd"
const DECOY := &"trugbilderwolf"
const FIXED_SEED := 515151
const OTHER_SEED := 626262


func _make(count: int, counts: Dictionary, seed_value: int = FIXED_SEED, calls: Array = [0]) -> Object:
	var script := load_script(SETUP_SCRIPT)
	if script == null:
		return null
	var s: Object = script.new()
	s.set("seed_source", func() -> int:
		calls[0] += 1
		return seed_value)
	for i: int in count:
		s.call("add_person", "Person %d" % (i + 1))
	s.call("confirm")
	for role: Variant in counts:
		s.call("set_role_count", StringName(str(role)), int(counts[role]))
	return s


func _roles(s: Object) -> Dictionary:
	return (s.call("view") as Dictionary).get("roles", {}) as Dictionary


func _dist(s: Object) -> Dictionary:
	return (s.call("view") as Dictionary).get("distribution", {}) as Dictionary


func _decoys(s: Object) -> Array:
	return _roles(s).get("decoys", []) as Array


func _copy_id(s: Object, index: int) -> int:
	var decoys := _decoys(s)
	return int((decoys[index] as Dictionary)["copy_id"]) if index < decoys.size() else -1


## {copy_id: appears_as} der Kopien im Rollenschritt.
func _config(s: Object) -> Dictionary:
	var out := {}
	for d: Variant in _decoys(s):
		out[int((d as Dictionary)["copy_id"])] = str((d as Dictionary)["appears_as"])
	return out


## {person_id: [role, copy_key, appearance]} aus der Verteilungssicht.
func _placed(s: Object) -> Dictionary:
	var out := {}
	for e: Variant in _dist(s).get("assignment", []):
		var entry: Dictionary = e
		if str(entry["role"]) != "":
			out[int(entry["person_id"])] = [str(entry["role"]), str(entry.get("copy_key", "")), str(entry["appearance"])]
	return out


func _key_of(s: Object, copy_id: int) -> String:
	for d: Variant in _decoys(s):
		if int((d as Dictionary)["copy_id"]) == copy_id:
			return str((d as Dictionary)["key"])
	return ""


func _ok(result: Object, label: String) -> bool:
	var ok := result != null and bool(result.get("ok"))
	assert_true(ok, "%s angenommen (%s)" % [label, result.get("error") if result != null else "kein Ergebnis"])
	return ok


func _rejected(s: Object, result: Object, error: String, label: String, before: String) -> void:
	assert_true(result != null and not bool(result.get("ok")), "%s abgelehnt" % label)
	if result != null:
		assert_eq(String(result.get("error")), error, "%s: Fehlercode" % label)
	assert_eq(JSON.stringify(s.call("view")), before, "%s: Zustand unverändert" % label)


## Jede verteilte Trugbilderwolf-Person trägt genau die Scheinrolle ihrer Kopie.
func _check_follow(s: Object, label: String) -> void:
	var config := _config(s)
	var keys := {}
	for d: Variant in _decoys(s):
		keys[str((d as Dictionary)["key"])] = str((d as Dictionary)["appears_as"])
	var seen := 0
	var placed := _placed(s)
	for person: Variant in placed:
		var p: Array = placed[person]
		if p[0] == String(DECOY):
			seen += 1
			assert_true(keys.has(p[1]), "%s: Person %s hält eine bekannte Kopie (%s)" % [label, person, p[1]])
			assert_eq(p[2], str(keys.get(p[1], "?")), "%s: Scheinrolle folgt der Kopie" % label)
		else:
			assert_eq(p[2], "", "%s: andere Rollen ohne Scheinrolle" % label)
	assert_eq(seen, config.size(), "%s: jede Kopie genau einmal verteilt" % label)


# --- Auswahl ------------------------------------------------------------------------------------------

func test_unconfigured_copy_blocks_role_confirmation() -> void:
	var calls := [0]
	var s := _make(8, {"werwolf": 1, "manipulator": 1, "dorfbewohner": 5}, FIXED_SEED, calls)
	if s == null:
		return
	_ok(s.call("change_role_count", DECOY, 1), "Trugbilderwolf hinzufügen")
	var decoys := _decoys(s)
	assert_eq(decoys.size(), 1, "eine Kopie angelegt")
	if decoys.size() != 1:
		return
	assert_true(str(decoys[0]["appears_as"]) == "" and not bool(decoys[0]["configured"]), "keine Vorbelegung")
	assert_eq(int(decoys[0]["number"]), 1, "sichtbare Nummer 1")
	var r := _roles(s)
	assert_true(not bool(r["valid"]) and (r["issues"] as Array).has("missing_appearance"), "fehlende Scheinrolle macht den Pool ungültig: %s" % r["issues"])
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("confirm_roles"), "roles_invalid", "Bestätigen ohne Scheinrolle", before)
	assert_eq(calls[0], 0, "keine Seed-Quelle für die Scheinrolle")
	_ok(s.call("set_decoy_appearance", _copy_id(s, 0), &"waldhexe"), "Scheinrolle außerhalb des Pools wählen")
	assert_true(bool(_roles(s)["valid"]), "jetzt gültig")
	_ok(s.call("confirm_roles"), "bestätigt")


func test_appearance_choices_are_validated_atomically() -> void:
	var s := _make(8, {"trugbilderwolf": 1, "manipulator": 1, "dorfbewohner": 6})
	if s == null:
		return
	var copy := _copy_id(s, 0)
	var before := JSON.stringify(s.call("view"))
	for wolf: StringName in [&"werwolf", &"spiegelwolf", DECOY]:
		_rejected(s, s.call("set_decoy_appearance", copy, wolf), "invalid_appearance", "Wolfsrolle %s" % wolf, before)
	_rejected(s, s.call("set_decoy_appearance", copy, &"nicht-im-katalog"), "unknown_role", "unbekannte Rolle", before)
	_rejected(s, s.call("set_decoy_appearance", copy, &""), "empty_appearance", "leere Rolle", before)
	_rejected(s, s.call("set_decoy_appearance", copy + 999, &"waldhexe"), "unknown_copy", "unbekannte Kopie", before)
	var options: Array = _roles(s).get("appearance_options", [])
	var expected := ["amalia", "blutpriester", "das-orakel", "der-weise", "detektiv", "die-ewigen", "die-gebundenen", "doktor", "doppelspion", "dorfbewohner", "dorfchronistin", "dorfschmied", "dorfwache", "faehrtenleser", "henker", "koenig", "kopfgeldjaeger", "korrupter-richter", "kriegerin-des-lichts", "lehrling", "loki", "maertyrerin", "manipulator", "nachtwaechter", "parasit", "ritter", "rotkaeppchen", "schutzengel", "schutzgeist", "selbstmoerder", "sensentraeger", "spuerhund", "traumdeuter", "verdammniswaechter", "waechter-am-tor", "wahnsinniger-kutscher", "waldhexe", "waldlaeufer", "wolfskind"]
	var sorted := options.duplicate()
	sorted.sort()
	assert_eq(sorted, expected, "angeboten: alle Nicht-Wolf-Rollen des Katalogs")
	for role: String in expected:
		_ok(s.call("set_decoy_appearance", copy, StringName(role)), "Scheinrolle %s" % role)
		assert_eq(_config(s)[copy], role, "%s gespeichert" % role)


func test_two_copies_same_or_different_and_add_remove() -> void:
	var s := _make(10, {"trugbilderwolf": 2, "manipulator": 1, "dorfbewohner": 7})
	if s == null:
		return
	var a := _copy_id(s, 0)
	var b := _copy_id(s, 1)
	assert_true(a != b and a > 0 and b > 0, "zwei stabile, getrennte Kopien")
	_ok(s.call("set_decoy_appearance", a, &"waldhexe"), "A")
	_ok(s.call("set_decoy_appearance", b, &"waldhexe"), "B gleich")
	assert_true(bool(_roles(s)["valid"]), "gleiche Scheinrolle zulässig")
	_ok(s.call("set_decoy_appearance", b, &"das-orakel"), "B anders")
	assert_eq(_config(s), {a: "waldhexe", b: "das-orakel"}, "unterschiedliche Scheinrollen")
	s.call("set_role_count", &"dorfbewohner", 6)
	_ok(s.call("change_role_count", DECOY, 1), "dritte Kopie")
	var c := _copy_id(s, 2)
	assert_eq(_config(s), {a: "waldhexe", b: "das-orakel", c: ""}, "neue Kopie unkonfiguriert, übrige unverändert")
	_ok(s.call("change_role_count", DECOY, -1), "unkonfigurierte Kopie ohne Rückfrage entfernen")
	assert_eq(_config(s), {a: "waldhexe", b: "das-orakel"}, "übrige Kopien unverändert")
	var before := JSON.stringify(s.call("view"))
	var result: Object = s.call("change_role_count", DECOY, -1)
	_rejected(s, result, "confirmation_required", "konfigurierte Kopie per Minus", before)
	assert_eq(int((result.get("details") as Dictionary).get("copy_id", -1)), b, "Rückfrage nennt die betroffene Kopie")
	_ok(s.call("remove_decoy_copy", a), "Kopie A gezielt entfernen")
	assert_eq(_config(s), {b: "das-orakel"}, "B bleibt mit Scheinrolle und ID")
	assert_eq(int(_roles(s)["counts"]["trugbilderwolf"]), 1, "Anzahl folgt den Kopien")
	assert_eq(int(_decoys(s)[0]["number"]), 1, "sichtbare Nummer neu gezählt")


func test_suggestion_and_reset_handle_copies() -> void:
	var s := _make(18, {})
	if s == null:
		return
	_ok(s.call("apply_suggestion"), "Vorschlag für 18")
	assert_eq(_decoys(s).size(), int(_roles(s)["counts"]["trugbilderwolf"]), "Kopien passend zum Vorschlag")
	assert_eq(_roles(s)["issues"], ["missing_appearance"], "Vorschlag wählt keine Scheinrolle")
	var copy := _copy_id(s, 0)
	s.call("set_decoy_appearance", copy, &"lehrling")
	_ok(s.call("apply_suggestion"), "gleicher Vorschlag")
	assert_eq(_config(s), {copy: "lehrling"}, "Vorschlag erhält eine passende Konfiguration")
	_ok(s.call("reset_roles"), "zurücksetzen")
	assert_true(_decoys(s).is_empty(), "zurücksetzen entfernt alle Kopien")


# --- Verteilung ---------------------------------------------------------------------------------------

func _two_copy_setup(seed_value: int = FIXED_SEED, calls: Array = [0]) -> Object:
	var s := _make(10, {"trugbilderwolf": 2, "werwolf": 1, "manipulator": 1, "dorfbewohner": 6}, seed_value, calls)
	if s == null:
		return null
	s.call("set_decoy_appearance", _copy_id(s, 0), &"waldhexe")
	s.call("set_decoy_appearance", _copy_id(s, 1), &"das-orakel")
	var r: Object = s.call("confirm_roles")
	assert_true(r != null and bool(r.get("ok")), "Vorbereitung: Rollen bestätigt")
	return s


func test_random_distribution_moves_copies_as_units() -> void:
	var calls := [0]
	var s := _two_copy_setup(FIXED_SEED, calls)
	if s == null:
		return
	var config := _config(s)
	_ok(s.call("distribute_randomly"), "verteilen")
	_check_follow(s, "zufällig")
	var twin := _two_copy_setup(FIXED_SEED)
	twin.call("distribute_randomly")
	assert_eq(_placed(twin), _placed(s), "gleicher Seed und gleiche Einträge: gleiche Verteilung")
	for i: int in 3:
		_ok(s.call("reshuffle"), "neu mischen %d" % (i + 1))
		_check_follow(s, "neu gemischt %d" % (i + 1))
		assert_eq(_config(s), config, "Neu mischen erhält die gewählten Scheinrollen")
	var other := _two_copy_setup(OTHER_SEED)
	other.call("distribute_randomly")
	_check_follow(other, "anderer Seed")
	assert_eq(_config(other), config, "Seed erzeugt keine Scheinrolle")
	assert_eq(calls[0], 1, "Seed-Quelle nur für die Verteilung")


func test_manual_distribution_uses_specific_copies() -> void:
	var s := _two_copy_setup()
	if s == null:
		return
	s.call("set_distribution_mode", &"manual")
	var a := _key_of(s, _copy_id(s, 0))
	var b := _key_of(s, _copy_id(s, 1))
	assert_true(a != "" and b != "" and a != b, "Kopien haben getrennte Schlüssel")
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("assign_role", 3, DECOY), "copy_required", "Trugbilderwolf ohne konkrete Kopie", before)
	_ok(s.call("assign_role", 1, StringName(b)), "Person 1 erhält Kopie B")
	_ok(s.call("assign_role", 2, StringName(a)), "Person 2 erhält Kopie A")
	var placed := _placed(s)
	assert_eq(placed[1], ["trugbilderwolf", b, "das-orakel"], "Person 1: Kopie B mit Orakel")
	assert_eq(placed[2], ["trugbilderwolf", a, "waldhexe"], "Person 2: Kopie A mit Waldhexe")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("assign_role", 3, StringName(a)), "no_copy_available", "Kopie A doppelt", before)
	_ok(s.call("unassign_role", 2), "Person 2 freigeben")
	assert_true((_dist(s)["remaining_keys"] as Array).has(a) and not (_dist(s)["remaining_keys"] as Array).has(b), "genau Kopie A wieder frei")
	_ok(s.call("assign_role", 3, StringName(a)), "Person 3 erhält Kopie A")
	_ok(s.call("swap_roles", 3, 4), "mit nicht zugewiesener Person tauschen")
	placed = _placed(s)
	assert_true(not placed.has(3) and placed[4] == ["trugbilderwolf", a, "waldhexe"], "Scheinrolle folgt beim Tauschen")
	_ok(s.call("swap_roles", 1, 4), "zwei Kopien tauschen")
	placed = _placed(s)
	assert_true(placed[1][2] == "waldhexe" and placed[4][2] == "das-orakel", "beide Scheinrollen wandern mit ihren Kopien")


func test_appearance_change_invalidates_distribution() -> void:
	var s := _two_copy_setup()
	if s == null:
		return
	s.call("distribute_randomly")
	s.call("confirm_distribution")
	var before := JSON.stringify(s.call("view"))
	_ok(s.call("set_decoy_appearance", _copy_id(s, 1), &"das-orakel"), "unveränderte Wahl")
	assert_eq(JSON.stringify(s.call("view")), before, "gleiche Scheinrolle ändert nichts")
	_ok(s.call("set_decoy_appearance", _copy_id(s, 1), &"sensentraeger"), "Scheinrolle ändern")
	var r := _roles(s)
	var d := _dist(s)
	assert_true(not bool(r["confirmed"]) and str(r["invalidated"]) == "roles_changed", "Rollenbestätigung aufgehoben")
	assert_true(not bool(d["has_assignment"]) and not bool(d["confirmed"]) and str(d["invalidated"]) == "roles_changed", "Verteilung kontrolliert verworfen")
	assert_eq(str((s.call("view") as Dictionary)["step"]), "roles", "zurück im Rollenschritt")


func test_rename_and_language_keep_configuration() -> void:
	var s := _two_copy_setup()
	if s == null:
		return
	s.call("distribute_randomly")
	var config := _config(s)
	var placed := _placed(s)
	TranslationServer.set_locale("en")
	assert_true(_config(s) == config and _placed(s) == placed, "Sprachwechsel erhält alles")
	TranslationServer.set_locale("de")
	_ok(s.call("rename_person", 1, "Umbenannt"), "umbenennen")
	assert_true(_config(s) == config and _placed(s) == placed, "Namensänderung erhält alles")
	assert_true(bool(_roles(s)["confirmed"]), "Rollen bleiben bestätigt")


func test_no_seed_derived_appearance_code() -> void:
	# Die Setup-Schicht leitet keine Scheinrolle aus Zufall oder Seed ab.
	var forbidden := RegEx.create_from_string("appearance_for|appearances_for|APPEARANCE_SALT")
	for path: String in files_in("res://app/setup", ".gd"):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code := line.split("#")[0]
			assert_true(forbidden.search(code) == null, "%s ohne abgeleitete Scheinrolle: %s" % [path.get_file(), code.strip_edges()])
	var dist := FileAccess.get_file_as_string("res://app/setup/role_distribution.gd")
	assert_false(dist.contains("appearance_options"), "Verteilung wählt keine Scheinrolle")
