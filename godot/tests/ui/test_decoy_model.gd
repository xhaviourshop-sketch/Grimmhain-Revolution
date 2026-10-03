extends UiTestCase
## Trugbilderwolf-Scheinrolle nach DR-08: Der Spielleiter kann sie für jede Kopie ausdrücklich
## festlegen; fehlt die Wahl, belegt das Setup sie mit einer zufälligen Dorfrolle des Pools vor. Rolle und Scheinrolle bilden im Setup eine Kopie, die
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
	var legal := Fixtures.legal_counts(counts)  # PE-07: Füllplätze werden zu verschiedenen Füllrollen
	for role: Variant in legal:
		s.call("set_role_count", StringName(str(role)), int(legal[role]))
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

func test_new_copy_is_prefilled_with_a_village_role_of_the_pool() -> void:
	var calls := [0]
	var s := _make(8, {"werwolf": 1, "manipulator": 1, "dorfbewohner": 5}, FIXED_SEED, calls)
	if s == null:
		return
	_ok(s.call("change_role_count", DECOY, 1), "Trugbilderwolf hinzufügen")
	var decoys := _decoys(s)
	assert_eq(decoys.size(), 1, "eine Kopie angelegt")
	if decoys.size() != 1:
		return
	var village_in_pool: Array = []
	for id: Variant in (_roles(s)["pool"] as Array):
		if SetupRoleCatalog.is_village(StringName(str(id))):
			village_in_pool.append(str(id))
	assert_true(village_in_pool.has(str(decoys[0]["appears_as"])), "Vorbelegung ist eine Dorfrolle des Pools: %s" % str(decoys[0]["appears_as"]))
	assert_true(bool(decoys[0]["configured"]) and bool(decoys[0]["auto"]), "als Vorbelegung gekennzeichnet")
	assert_eq(int(decoys[0]["number"]), 1, "sichtbare Nummer 1")
	assert_true(bool(_roles(s)["valid"]), "Pool gültig: %s" % str(_roles(s)["issues"]))
	assert_eq(calls[0], 1, "Seed-Quelle genau einmal für die Vorbelegung")
	var twin := _make(8, {"werwolf": 1, "manipulator": 1, "dorfbewohner": 5}, FIXED_SEED)
	twin.call("change_role_count", DECOY, 1)
	assert_eq(_config(twin).values(), _config(s).values(), "gleicher Seed: gleiche Vorbelegung")
	_ok(s.call("set_decoy_appearance", _copy_id(s, 0), &"waldhexe"), "Scheinrolle außerhalb des Pools wählen")
	assert_false(bool(_decoys(s)[0]["auto"]), "eigene Wahl ist keine Vorbelegung mehr")
	_ok(s.call("change_role_count", &"dorfbewohner", -1), "Pool danach ändern")
	_ok(s.call("change_role_count", &"dorfbewohner", 1), "und wiederherstellen")
	assert_eq(_config(s).values(), ["waldhexe"], "eigene Wahl bleibt bei Poolwechsel")
	assert_true(bool(_roles(s)["valid"]), "gültig")
	_ok(s.call("confirm_roles"), "bestätigt")


func test_copy_without_any_village_role_in_the_pool_stays_open_and_blocks() -> void:
	var s := _make(6, {})
	if s == null:
		return
	for role: StringName in [&"werwolf", &"giftwolf", &"blutwolf", &"manipulator", &"parasit", &"trugbilderwolf"]:
		_ok(s.call("set_role_count", role, 1), "Rolle %s" % role)
	var decoys := _decoys(s)
	assert_eq(decoys.size(), 1, "eine Kopie")
	if decoys.size() != 1:
		return
	assert_false(bool(decoys[0]["configured"]), "ohne Dorfrolle keine Vorbelegung")
	var r := _roles(s)
	assert_true((r["issues"] as Array).has("missing_appearance"), "fehlende Scheinrolle bleibt ein Befund: %s" % str(r["issues"]))
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("confirm_roles"), "roles_invalid", "Bestätigen ohne Scheinrolle", before)


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
	var expected := ["amalia", "blutpriester", "das-orakel", "der-weise", "detektiv", "die-ewigen", "die-gebundenen", "doktor", "doppelspion", "dorfbewohner", "dorfchronistin", "dorfschmied", "dorfwache", "dr-victor-frankenstein", "faehrtenleser", "feuerteufel", "grabraeuber", "hades", "henker", "koenig", "kopfgeldjaeger", "korrupter-richter", "kriegerin-des-lichts", "kutscher", "lehrling", "loki", "maertyrerin", "manipulator", "nachtwaechter", "nekromant", "parasit", "pestbringerin", "prophet-des-untergangs", "rattenfaenger", "ritter", "rotkaeppchen", "schutzengel", "schutzgeist", "seelentauscher", "selbstmoerder", "sensentraeger", "spuerhund", "todesprediger", "traumdeuter", "verdammniswaechter", "voodoo-priester", "waechter-am-tor", "wahnsinniger-kutscher", "waldhexe", "waldlaeufer", "wolfskind", "zeitwaechter"]
	var sorted := options.duplicate()
	sorted.sort()
	assert_eq(sorted, expected, "angeboten: alle Nicht-Wolf-Rollen des Katalogs")
	for role: String in expected:
		_ok(s.call("set_decoy_appearance", copy, StringName(role)), "Scheinrolle %s" % role)
		assert_eq(_config(s)[copy], role, "%s gespeichert" % role)


## Seit PE-07 gibt es beim Start höchstens einen Trugbilderwolf; mehrere Kopien mit eigener Scheinrolle sind im Setup nicht mehr
## erreichbar (`above_maximum`). Geprüft werden Anlegen, Konfigurieren, Entfernen mit Rückfrage und die stabile Kopien-ID.
func test_single_copy_add_configure_remove_and_readd() -> void:
	var s := _make(10, {"trugbilderwolf": 1, "manipulator": 1, "dorfbewohner": 8})
	if s == null:
		return
	var a := _copy_id(s, 0)
	assert_true(a > 0, "stabile Kopie mit ID")
	assert_eq(_config(s).keys(), [a], "eine Kopie")
	assert_true(bool(_decoys(s)[0]["auto"]), "neue Kopie vorbelegt")
	var full := JSON.stringify(s.call("view"))
	_rejected(s, s.call("change_role_count", DECOY, 1), "above_maximum", "zweite Kopie beim Start", full)
	_rejected(s, s.call("set_role_count", DECOY, 2), "above_maximum", "zweite Kopie per Anzahl", full)
	assert_false(bool((_roles(s)["can_increase"] as Dictionary)["trugbilderwolf"]), "Plus gesperrt")
	_ok(s.call("set_decoy_appearance", a, &"waldhexe"), "Scheinrolle wählen")
	assert_true(bool(_roles(s)["valid"]), "gültig mit Scheinrolle")
	var before := JSON.stringify(s.call("view"))
	var result: Object = s.call("change_role_count", DECOY, -1)
	_rejected(s, result, "confirmation_required", "konfigurierte Kopie per Minus", before)
	assert_eq(int((result.get("details") as Dictionary).get("copy_id", -1)), a, "Rückfrage nennt die betroffene Kopie")
	_ok(s.call("remove_decoy_copy", a), "Kopie gezielt entfernen")
	assert_true(_config(s).is_empty(), "keine Kopie mehr")
	assert_eq(int(_roles(s)["counts"]["trugbilderwolf"]), 0, "Anzahl folgt den Kopien")
	_ok(s.call("change_role_count", DECOY, 1), "nach dem Entfernen wieder auswählbar")
	var again := _copy_id(s, 0)
	assert_true(again > a, "neue Kopie erhält eine neue ID (IDs sinken nie)")
	assert_eq(_config(s).keys(), [again], "eine neue Kopie")
	assert_true(bool(_decoys(s)[0]["auto"]), "neue Kopie vorbelegt")
	assert_eq(int(_decoys(s)[0]["number"]), 1, "sichtbare Nummer 1")
	_ok(s.call("change_role_count", DECOY, -1), "vorbelegte Kopie ohne Rückfrage entfernen")
	assert_true(_decoys(s).is_empty(), "wieder ohne Kopie")


func test_suggestion_and_reset_handle_copies() -> void:
	var s := _make(18, {})
	if s == null:
		return
	_ok(s.call("apply_suggestion"), "Vorschlag für 18")
	assert_eq(_decoys(s).size(), int(_roles(s)["counts"]["trugbilderwolf"]), "Kopien passend zum Vorschlag")
	assert_eq(_roles(s)["issues"], [], "Vorschlag: Scheinrolle vorbelegt")
	var copy := _copy_id(s, 0)
	s.call("set_decoy_appearance", copy, &"lehrling")
	_ok(s.call("apply_suggestion"), "gleicher Vorschlag")
	assert_eq(_config(s), {copy: "lehrling"}, "Vorschlag erhält eine passende Konfiguration")
	_ok(s.call("reset_roles"), "zurücksetzen")
	assert_true(_decoys(s).is_empty(), "zurücksetzen entfernt alle Kopien")


# --- Verteilung ---------------------------------------------------------------------------------------

## Zehn Personen mit einem Trugbilderwolf (Scheinrolle Waldhexe), Werwolf, Manipulator und sieben Dorfrollen.
func _two_copy_setup(seed_value: int = FIXED_SEED, calls: Array = [0]) -> Object:
	var s := _make(10, {"trugbilderwolf": 1, "werwolf": 1, "manipulator": 1, "dorfbewohner": 7}, seed_value, calls)
	if s == null:
		return null
	s.call("set_decoy_appearance", _copy_id(s, 0), &"waldhexe")
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
	assert_eq(calls[0], 2, "Seed-Quelle: einmal für die Vorbelegung der Scheinrolle, einmal für die Verteilung")


func test_manual_distribution_uses_specific_copies() -> void:
	var s := _two_copy_setup()
	if s == null:
		return
	s.call("set_distribution_mode", &"manual")
	var a := _key_of(s, _copy_id(s, 0))
	assert_true(a != "", "die Kopie hat einen Schlüssel")
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("assign_role", 3, DECOY), "copy_required", "Trugbilderwolf ohne konkrete Kopie", before)
	_ok(s.call("assign_role", 2, StringName(a)), "Person 2 erhält die Kopie")
	var placed := _placed(s)
	assert_eq(placed[2], ["trugbilderwolf", a, "waldhexe"], "Person 2: Kopie mit Waldhexe")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("assign_role", 3, StringName(a)), "no_copy_available", "Kopie doppelt", before)
	_ok(s.call("unassign_role", 2), "Person 2 freigeben")
	assert_true((_dist(s)["remaining_keys"] as Array).has(a), "Kopie wieder frei")
	_ok(s.call("assign_role", 3, StringName(a)), "Person 3 erhält die Kopie")
	_ok(s.call("swap_roles", 3, 4), "mit nicht zugewiesener Person tauschen")
	placed = _placed(s)
	assert_true(not placed.has(3) and placed[4] == ["trugbilderwolf", a, "waldhexe"], "Scheinrolle folgt beim Tauschen")


func test_appearance_change_invalidates_distribution() -> void:
	var s := _two_copy_setup()
	if s == null:
		return
	s.call("distribute_randomly")
	s.call("confirm_distribution")
	var before := JSON.stringify(s.call("view"))
	_ok(s.call("set_decoy_appearance", _copy_id(s, 0), &"waldhexe"), "unveränderte Wahl")
	assert_eq(JSON.stringify(s.call("view")), before, "gleiche Scheinrolle ändert nichts")
	_ok(s.call("set_decoy_appearance", _copy_id(s, 0), &"sensentraeger"), "Scheinrolle ändern")
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
	# Die Vorbelegung wird gezogen und in der Kopie gespeichert; keine Scheinrolle wird aus einem Seed neu abgeleitet.
	var forbidden := RegEx.create_from_string("appearance_for|appearances_for|APPEARANCE_SALT")
	for path: String in files_in("res://app/setup", ".gd"):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code := line.split("#")[0]
			assert_true(forbidden.search(code) == null, "%s ohne abgeleitete Scheinrolle: %s" % [path.get_file(), code.strip_edges()])
	var dist := FileAccess.get_file_as_string("res://app/setup/role_distribution.gd")
	assert_false(dist.contains("appearance_options"), "Verteilung wählt keine Scheinrolle")
