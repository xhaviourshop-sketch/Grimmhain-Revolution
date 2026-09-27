extends UiTestCase
## Rollen-Setup: Katalogadapter, Darstellungsdaten, Rollenpool, Vorschlag und Abhängigkeiten
## (Auftrag Rollen, Tests 1 bis 40 ohne Verteilung). Ohne Szenen.

const SETUP_SCRIPT := "res://app/setup/player_setup.gd"
const CATALOG_SCRIPT := "res://app/setup/setup_role_catalog.gd"
const PRESENTATION_SCRIPT := "res://app/setup/role_presentation.gd"
const SUGGESTION_SCRIPT := "res://app/setup/role_suggestion.gd"


func _make(count: int = 8, confirm: bool = true) -> Object:
	var script := load_script(SETUP_SCRIPT)
	if script == null:
		return null
	var s: Object = script.new()
	for i: int in count:
		s.call("add_person", "Person %d" % (i + 1))
	if confirm:
		s.call("confirm")
	return s


func _roles(s: Object) -> Dictionary:
	return (s.call("view") as Dictionary).get("roles", {}) as Dictionary


func _count(s: Object, role: String) -> int:
	return int((_roles(s).get("counts", {}) as Dictionary).get(role, -1))


func _set_counts(s: Object, counts: Dictionary) -> void:
	for role: Variant in counts:
		s.call("set_role_count", StringName(str(role)), int(counts[role]))


func _valid_pool(persons: int) -> Dictionary:
	return {"werwolf": 1, "manipulator": 1, "dorfbewohner": persons - 2}


func _ok(result: Object, label: String) -> bool:
	var ok := result != null and bool(result.get("ok"))
	assert_true(ok, "%s angenommen (%s)" % [label, result.get("error") if result != null else "kein Ergebnis"])
	return ok


func _rejected(s: Object, result: Object, error: String, label: String, before: String) -> void:
	assert_true(result != null and not bool(result.get("ok")), "%s abgelehnt" % label)
	if result != null:
		assert_eq(String(result.get("error")), error, "%s: Fehlercode" % label)
	assert_eq(JSON.stringify(s.call("view")), before, "%s: Zustand unverändert" % label)


# --- Katalog und Darstellung (1 bis 7) ----------------------------------------------------------------

func test_catalog_adapter_matches_rule_catalog() -> void:
	var catalog := load_script(CATALOG_SCRIPT)
	if catalog == null:
		return
	var ids: Array = catalog.call("role_ids")
	var expected: Array = RoleCatalog.ROLES.keys()
	expected.sort()
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()
	assert_eq(ids.size(), 11, "exakt elf produktive Rollen")
	assert_eq(sorted_ids, expected, "dieselben IDs wie RoleCatalog")
	for id: Variant in ids:
		var role := StringName(id)
		assert_true(RoleCatalog.has_role(role), "%s im Regelkatalog" % role)
		assert_eq(StringName(catalog.call("faction_of", role)), RoleCatalog.faction_of(role), "%s: Fraktion aus dem Katalog" % role)
		assert_eq(bool(catalog.call("counts_as_wolf", role)), RoleCatalog.counts_as_wolf(role), "%s: counts_as_wolf aus dem Katalog" % role)
		assert_eq(int(catalog.call("night_priority", role)), RoleCatalog.night_priority(role), "%s: Nachtpriorität" % role)
		assert_eq(bool(catalog.call("requires_appearance", role)), RoleCatalog.requires_appearance(role), "%s: Pflicht-Scheinrolle" % role)
		assert_eq(bool(catalog.call("is_solo", role)), RoleCatalog.faction_of(role) == Faction.SOLO, "%s: Einzelsieg aus der Fraktion" % role)
	assert_false(bool(catalog.call("has_role", &"nicht-im-katalog")), "unbekannte Rolle")
	# Keine zweite Wahrheit: Fraktion, Wolfszählung, Priorität stehen nur im Regelkern.
	var duplicate_rules := RegEx.create_from_string("\"(village|wolves|solo)\"|counts_as_wolf\\s*[:=]\\s*(true|false)|night_priority\\s*[:=]\\s*\\d")
	for path: String in [PRESENTATION_SCRIPT, CATALOG_SCRIPT]:
		if FileAccess.file_exists(path):
			for line: String in FileAccess.get_file_as_string(path).split("\n"):
				var code := line.split("#")[0]
				assert_true(duplicate_rules.search(code) == null, "%s dupliziert keine Regeldaten: %s" % [path.get_file(), code.strip_edges()])


func test_presentation_has_every_role_in_both_languages() -> void:
	var presentation := load_script(PRESENTATION_SCRIPT)
	var catalog := load_script(CATALOG_SCRIPT)
	if presentation == null or catalog == null:
		return
	var order: Array = presentation.call("sorted_roles")
	var ids: Array = catalog.call("role_ids")
	assert_eq(order.size(), ids.size(), "Darstellungsreihenfolge enthält jede Rolle genau einmal")
	for id: Variant in ids:
		assert_true(order.has(id), "%s in der Darstellungsreihenfolge" % id)
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	for id: Variant in ids:
		for key_method: String in ["name_key", "short_key"]:
			var k := str(presentation.call(key_method, StringName(id)))
			assert_true(de.has(k) and en.has(k) and str(de[k]) != "" and str(en[k]) != "", "%s: %s in DE und EN (%s)" % [id, key_method, k])
	for faction: StringName in [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]:
		var k := str(presentation.call("faction_key", faction))
		assert_true(de.has(k) and en.has(k), "Fraktion %s übersetzt (%s)" % [faction, k])
	TranslationServer.set_locale("de")
	var de_name := tr(str(presentation.call("name_key", &"das-orakel")))
	TranslationServer.set_locale("en")
	var en_name := tr(str(presentation.call("name_key", &"das-orakel")))
	TranslationServer.set_locale("de")
	assert_true(de_name == "Das Orakel" and en_name == "The Oracle", "Anzeigenamen lokalisiert, ID bleibt (%s / %s)" % [de_name, en_name])


# --- Rollenpool (8 bis 23) --------------------------------------------------------------------------

func test_plus_minus_and_limits() -> void:
	var s := _make(8)
	if s == null:
		return
	assert_true(_roles(s).has("counts") and (_roles(s)["counts"] as Dictionary).size() == 11, "jede Rolle mit Anzahl")
	assert_eq(_count(s, "werwolf"), 0, "Start bei 0")
	_ok(s.call("change_role_count", &"werwolf", 1), "Plus")
	assert_eq(_count(s, "werwolf"), 1, "Plus erhöht um eins")
	s.call("change_role_count", &"werwolf", 1)
	_ok(s.call("change_role_count", &"werwolf", -1), "Minus")
	assert_eq(_count(s, "werwolf"), 1, "Minus verringert um eins")
	s.call("change_role_count", &"werwolf", -1)
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("change_role_count", &"werwolf", -1), "negative_count", "unter 0", before)
	assert_false(bool((_roles(s)["can_decrease"] as Dictionary)["werwolf"]), "Minus bei 0 gesperrt")
	_rejected(s, s.call("change_role_count", &"nicht-im-katalog", 1), "unknown_role", "unbekannte Rolle", before)
	_rejected(s, s.call("set_role_count", &"dorfbewohner", 9), "above_maximum", "mehr Kopien als Personen", before)
	_ok(s.call("set_role_count", &"dorfbewohner", 8), "genau Personenzahl")
	assert_false(bool((_roles(s)["can_increase"] as Dictionary)["dorfbewohner"]), "Plus an der technischen Grenze gesperrt")


func test_pool_validation() -> void:
	var s := _make(8)
	if s == null:
		return
	var r := _roles(s)
	assert_true(not bool(r["valid"]) and int(r["total"]) == 0 and int(r["persons"]) == 8 and int(r["free"]) == 8, "leer: ungültig, 8 frei")
	_set_counts(s, {"werwolf": 1, "manipulator": 1, "dorfbewohner": 4})
	r = _roles(s)
	assert_true(not bool(r["valid"]) and (r["issues"] as Array).has("too_few_roles") and int(r["free"]) == 2, "unter Personenzahl ungültig")
	_set_counts(s, {"dorfbewohner": 8})
	r = _roles(s)
	assert_true(not bool(r["valid"]) and (r["issues"] as Array).has("too_many_roles") and int(r["free"]) == -2 and int(r["total"]) == 10, "über Personenzahl ungültig")
	_set_counts(s, {"dorfbewohner": 6})
	r = _roles(s)
	assert_true(bool(r["valid"]) and (r["issues"] as Array).is_empty(), "exakt passend und vollständig gültig")
	var cases := {
		"missing_village": {"werwolf": 7, "manipulator": 1, "dorfbewohner": 0},
		"missing_wolf": {"werwolf": 0, "manipulator": 1, "dorfbewohner": 7},
		"missing_solo": {"werwolf": 1, "manipulator": 0, "dorfbewohner": 7},
	}
	for issue: String in cases:
		_set_counts(s, cases[issue])
		r = _roles(s)
		assert_true(not bool(r["valid"]) and (r["issues"] as Array).has(issue), "%s erkannt (%s)" % [issue, r["issues"]])
	# Fraktionen kommen aus dem Katalog: Sonderwölfe zählen als Wolf, Wolfskind nicht.
	_set_counts(s, {"werwolf": 0, "spiegelwolf": 1, "wolfskind": 1, "manipulator": 1, "dorfbewohner": 5})
	r = _roles(s)
	assert_true(bool(r["valid"]) and int(r["wolf_count"]) == 1 and int((r["factions"] as Dictionary)["village"]) == 6, "Spiegelwolf als Wolf, Wolfskind im Dorf")


func test_confirm_pool_is_canonical_and_stable() -> void:
	var s := _make(8)
	if s == null:
		return
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("confirm_roles"), "roles_invalid", "ungültigen Pool bestätigen", before)
	_set_counts(s, {"dorfbewohner": 5, "manipulator": 1, "werwolf": 1, "schutzengel": 1})
	var result: Object = s.call("confirm_roles")
	if not _ok(result, "gültigen Pool bestätigen"):
		return
	var r := _roles(s)
	assert_true(bool(r["confirmed"]), "bestätigt")
	var pool: Array = r["pool"]
	assert_eq(pool.size(), 8, "eine Kopie je Person")
	var sorted := pool.duplicate()
	sorted.sort()
	assert_eq(pool, sorted, "kanonisch nach Rollen-ID sortiert")
	assert_eq(pool, ["dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "manipulator", "schutzengel", "werwolf"], "exakte Anzahl je Rolle")
	for id: Variant in pool:
		assert_true(id is String, "reine Daten (String)")
	var other := _make(8)
	_set_counts(other, {"schutzengel": 1, "werwolf": 1, "manipulator": 1, "dorfbewohner": 5})
	other.call("confirm_roles")
	assert_eq(_roles(other)["pool"], pool, "unabhängig von der Eingabereihenfolge")
	assert_eq(String((s.call("view") as Dictionary)["step"]), "distribution", "Bestätigen wechselt zur Verteilung")
	TranslationServer.set_locale("en")
	assert_eq(_roles(s)["pool"], pool, "Sprachwechsel verändert den Pool nicht")
	TranslationServer.set_locale("de")
	s.call("change_role_count", &"schutzengel", -1)
	r = _roles(s)
	assert_true(not bool(r["confirmed"]) and String(r["invalidated"]) == "roles_changed", "Rollenänderung hebt die Bestätigung auf")


func test_wizard_steps_are_guarded() -> void:
	var s := _make(8, false)
	if s == null:
		return
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("go_to_step", &"roles"), "players_not_confirmed", "Rollen vor bestätigten Personen", before)
	_rejected(s, s.call("go_to_step", &"distribution"), "players_not_confirmed", "Verteilung vor bestätigten Personen", before)
	s.call("confirm")
	_ok(s.call("go_to_step", &"roles"), "Rollen nach bestätigten Personen")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("go_to_step", &"distribution"), "roles_not_confirmed", "Verteilung vor bestätigten Rollen", before)
	_rejected(s, s.call("go_to_step", &"irgendwas"), "unknown_step", "unbekannter Schritt", before)
	_ok(s.call("go_to_step", &"players"), "zurück zu Spielern")
	var steps: Array = (s.call("view") as Dictionary)["steps"]
	assert_eq(steps.size(), 4, "vier Schritte (mit Sitzordnung)")
	assert_true(String(steps[0]["id"]) == "players" and String(steps[0]["state"]) == "done", "Spieler erledigt")
	assert_true(String(steps[1]["state"]) == "open" and String(steps[2]["state"]) == "open", "Rollen und Verteilung offen")


# --- Vorschlag (24 bis 33) --------------------------------------------------------------------------

func test_suggestion_for_every_person_count() -> void:
	var suggestion := load_script(SUGGESTION_SCRIPT)
	var catalog := load_script(CATALOG_SCRIPT)
	if suggestion == null or catalog == null:
		return
	var expected_wolves := {6: 1, 8: 1, 9: 2, 12: 2, 13: 3, 17: 3, 18: 4, 21: 4, 22: 5, 24: 5}
	for n: int in range(6, 25):
		var counts: Dictionary = suggestion.call("for_count", n)
		var total := 0
		var village := 0
		var wolves := 0
		var solo := 0
		for id: Variant in counts:
			var role := StringName(str(id))
			var c := int(counts[id])
			assert_true(bool(catalog.call("has_role", role)) and c >= 0, "%d: nur produktive Rollen (%s)" % [n, role])
			var limit := int(catalog.call("max_copies", role))
			assert_true(limit < 0 or c <= limit, "%d: Grenze für %s" % [n, role])
			total += c
			if StringName(catalog.call("faction_of", role)) == Faction.VILLAGE:
				village += c
			if bool(catalog.call("counts_as_wolf", role)):
				wolves += c
			if bool(catalog.call("is_solo", role)):
				solo += c
		assert_eq(total, n, "%d: Summe passt" % n)
		assert_true(village >= 1 and wolves >= 1, "%d: Dorf und Wolf enthalten" % n)
		assert_eq(int(counts.get(&"manipulator", counts.get("manipulator", 0))), 1, "%d: genau ein Manipulator" % n)
		assert_eq(solo, 1, "%d: genau eine Einzelsiegrolle" % n)
		if expected_wolves.has(n):
			assert_eq(wolves, int(expected_wolves[n]), "%d: Wolfsanzahl nach Heuristik" % n)
		assert_eq(JSON.stringify(counts), JSON.stringify(suggestion.call("for_count", n)), "%d: deterministisch" % n)
		var s := _make(n)
		s.call("apply_suggestion")
		# DR-08: Trugbilderwolf-Kopien des Vorschlags brauchen eine ausdrückliche Scheinrolle.
		var decoys: Array = _roles(s).get("decoys", [])
		var expected_issues: Array = ["missing_appearance"] if int(counts.get("trugbilderwolf", 0)) > 0 else []
		assert_eq(_roles(s)["issues"], expected_issues, "%d: Vorschlag gültig bis auf offene Scheinrollen" % n)
		for d: Variant in decoys:
			s.call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"dorfbewohner")
		assert_true(bool(_roles(s)["valid"]), "%d: Vorschlag mit gewählten Scheinrollen ist ein gültiger Pool" % n)


func test_suggestion_overwrites_only_after_confirmation() -> void:
	var s := _make(8)
	if s == null:
		return
	_ok(s.call("apply_suggestion"), "Vorschlag auf leere Auswahl")
	var suggested := JSON.stringify(_roles(s)["counts"])
	_ok(s.call("apply_suggestion"), "gleicher Vorschlag erneut ohne Rückfrage")
	s.call("change_role_count", &"schutzengel", 1)
	s.call("change_role_count", &"dorfbewohner", -1)
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("apply_suggestion"), "confirmation_required", "manuelle Auswahl überschreiben", before)
	_ok(s.call("apply_suggestion", true), "mit Bestätigung überschreiben")
	assert_eq(JSON.stringify(_roles(s)["counts"]), suggested, "Vorschlag übernommen")
	_ok(s.call("reset_roles"), "Auswahl zurücksetzen")
	assert_eq(int(_roles(s)["total"]), 0, "zurückgesetzt")


# --- Abhängigkeiten (34 bis 36) ------------------------------------------------------------------------

func test_person_changes_and_role_pool() -> void:
	var s := _make(8)
	if s == null:
		return
	_set_counts(s, _valid_pool(8))
	s.call("confirm_roles")
	var ids: Array = ((s.call("view") as Dictionary)["persons"] as Array).map(func(p: Dictionary) -> int: return int(p["person_id"]))
	s.call("rename_person", ids[0], "Neuer Name")
	var r := _roles(s)
	assert_true(bool(r["confirmed"]) and String(r["invalidated"]) == "", "Namensänderung erhält den Pool")
	s.call("add_person", "Neunte Person")
	r = _roles(s)
	assert_true(not bool(r["confirmed"]) and String(r["invalidated"]) == "person_count_changed" and not bool(r["valid"]), "Person hinzufügen invalidiert unpassenden Pool")
	var steps: Array = (s.call("view") as Dictionary)["steps"]
	assert_eq(String(steps[1]["state"]), "invalid", "Rollenschritt als ungültig geworden markiert")
	s.call("set_role_count", &"dorfbewohner", 7)
	s.call("confirm")
	_ok(s.call("confirm_roles"), "neu bestätigt")
	s.call("remove_person", ids[1])
	r = _roles(s)
	assert_true(not bool(r["confirmed"]) and String(r["invalidated"]) == "person_count_changed", "Person entfernen invalidiert unpassenden Pool")
	var before := JSON.stringify(s.call("view"))
	var too_many: Array[String] = []
	for i: int in PersonNameRules.MAX_PERSONS:
		too_many.append("Import %d" % i)
	_rejected(s, s.call("import_names", ", ".join(too_many)), "too_many_persons", "abgelehnter Import", before)
	var ids_after: Array = ((s.call("view") as Dictionary)["persons"] as Array).map(func(p: Dictionary) -> int: return int(p["person_id"]))
	assert_false(ids_after.has(ids[1]), "entfernte Person bleibt entfernt")
	assert_eq(ids_after[0], ids[0], "Personen-IDs bleiben stabil")


func test_setup_layer_has_no_randomness_or_clock() -> void:
	# 47 (Grundlage): keine globale Zufallsquelle und keine Uhr in der Setup-Schicht.
	var forbidden := RegEx.create_from_string("(?<![\\w.])(randi|randf|randi_range|randf_range|randomize)\\s*\\(|RandomNumberGenerator|\\bTime\\.|\\bOS\\.get_(ticks|unix|system)")
	for path: String in files_in("res://app/setup", ".gd"):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code := line.split("#")[0]
			assert_true(forbidden.search(code) == null, "%s ohne globalen Zufall oder Uhr: %s" % [path.get_file(), code.strip_edges()])
	assert_true(files_in("res://app/setup", ".gd").size() >= 8, "Setup-Dateien vorhanden")
