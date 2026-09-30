extends UiTestCase
## Paket 4: Positivlisten der Ausgabewege, die bisher nur per Suche nach einzelnen Zeichenfolgen geprüft waren:
## Speicher-/Fortsetzen-Übersicht, Statusmeldungen (Toasts) und die öffentliche Cockpit-Sicht. Jedes neue Feld macht
## den Test rot und verlangt eine bewusste Prüfung. Testdaten mit unterscheidbaren Geheimnissen: wahre Rollen,
## Scheinrolle (Trugbilderwolf erscheint als Orakel), Loki-Bindung mit privaten Hinweisen, Schutz, Heiltrank, Tod mit Ursache.
## Weitere Ausgabewege mit bestehender Positivliste: Morgenbericht und Todeseffekte (test_death_effect_lines,
## test_death_effects), Zeigekarten (test_role_operation_kinds, test_cockpit_model), Rollenkarte (test_role_show),
## Hinweiskarten (test_notice_cards), öffentliche Ereignisse (Fuzz-Invariante in test_role_interaction_fuzz).

const UiGame := preload("res://tests/ui/ui_game.gd")
const ROLES := ["werwolf", "trugbilderwolf", "loki", "schutzengel", "waldhexe", "dorfbewohner", "amalia", "detektiv"]
const SUMMARY_KEYS := ["alive_count", "command_count", "day_number", "names", "night_number", "phase", "player_count"]
## `expected_label` und `found_label` (Regelversion 0.14): nur Schema- und Regelversionsnummern, keine Spielinhalte.
const LIST_KEYS := ["compatible", "expected", "expected_label", "found_label", "readable", "round_id", "saved_at", "schema", "summary"]
const COCKPIT_KEYS := ["alive_count", "day_number", "day_step", "has_game", "next", "night_number", "night_progress", "phase",
	"player_count", "revival_round", "seats", "warnings"]
const SEAT_KEYS := ["alive", "name", "nominated_someone_today", "nominated_today", "person_id", "seat"]


## Partie mit Geheimnissen bis zum Morgen: Loki bindet 6 und 7, Schutzengel schützt 5, Rudel greift 6 an.
func _secret_game() -> AppContext:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	assert_true(ctx.session.submit(UiGame.start(ROLES, 7, {"2": "das-orakel"})).ok, "Start")
	assert_true(UiGame.to_day(ctx.session, {"loki/targets": [6, 7], "loki/mode": true, "schutzengel/": [5], "pack/": [6]}), "bis zum Morgen")
	return ctx


func _sorted_keys(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort()
	return keys


## Rollen-IDs und DE/EN-Rollennamen des gesamten Katalogs.
func _secret_words() -> Array[String]:
	var words: Array[String] = []
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	for id: Variant in RoleCatalog.ROLES.keys():
		var role := String(id)
		words.append(role)
		for po: Dictionary in [de, en]:
			var name := str(po.get("ui.role.%s.name" % role, ""))
			if name != "" and not words.has(name):
				words.append(name)
	return words


func _assert_no_secret(text: String, label: String) -> void:
	for w: String in _secret_words():
		assert_false(text.contains(w), "%s enthält „%s“" % [label, w])
	for k: String in ["notice", "cause", "appears", "protect", "role"]:
		assert_false(text.contains(k), "%s enthält Feld „%s“" % [label, k])


func test_save_summary_and_list_contain_only_the_positive_list() -> void:
	var ctx := _secret_game()
	assert_false(ctx.session.cockpit_view()["next"].is_empty(), "Partie läuft")
	var summary := ctx.session.summary()
	assert_eq(_sorted_keys(summary), SUMMARY_KEYS, "Zusammenfassung nur mit Positivliste")
	var entries := ctx.saves.list()
	assert_eq(entries.size(), 1, "eine Partie")
	assert_eq(_sorted_keys(entries[0]), LIST_KEYS, "Listeneintrag nur mit Positivliste")
	assert_eq(_sorted_keys(entries[0]["summary"]), SUMMARY_KEYS, "gespeicherte Zusammenfassung nur mit Positivliste")
	_assert_no_secret(JSON.stringify(entries), "Fortsetzen-Liste")
	# Die Hülle der Datei trägt außerhalb von `core` nur öffentliche Angaben.
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ctx.saves.path_for(ctx.session.round_id())))
	assert_eq(_sorted_keys(envelope), ["app_version", "core", "format", "saved_at", "summary", "version"], "Hülle nur mit Positivliste")
	envelope.erase("core")
	_assert_no_secret(JSON.stringify(envelope), "Hülle ohne Kern")


## Toasts tragen nur einen festen Textschlüssel (ToastHost.show_message hat keine Werte). Jeder Schlüssel, den die App als
## Statusmeldung sendet, ist in DE und EN vorhanden und ohne Platzhalter, kann also keine Person, Rolle oder Ursache nennen.
func test_status_messages_are_fixed_texts_without_values() -> void:
	var toast_method: Dictionary = (load("res://app/widgets/toast/toast_host.gd") as Script).get_script_method_list().filter(
		func(m: Dictionary) -> bool: return str(m["name"]) == "show_message")[0]
	assert_eq((toast_method["args"] as Array).size(), 1, "show_message nimmt nur den Schlüssel")
	var keys := {}
	var regex := RegEx.create_from_string("status_message_requested\\.emit\\(([^\\n]*)\\)")
	var literal := RegEx.create_from_string("\"(ui\\.[a-z0-9_.]+)\"")
	for path: String in _app_scripts("res://app"):
		for m: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
			for k: RegExMatch in literal.search_all(m.get_string(1)):
				keys[k.get_string(1)] = path
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	for k: String in de:
		if k.begins_with("ui.cockpit.error."):
			keys[k] = "cockpit_screen.gd (_on_rejected)"
	assert_true(keys.size() > 30, "Statusmeldungen gefunden (%d)" % keys.size())
	for k: String in keys:
		for po: Dictionary in [de, en]:
			assert_true(po.has(k), "%s: Text in beiden Sprachen (%s)" % [k, keys[k]])
			assert_false(str(po.get(k, "")).contains("{"), "%s: keine Platzhalter" % k)


func _app_scripts(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f: String in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for d: String in dir.get_directories():
		out.append_array(_app_scripts(dir_path.path_join(d)))
	return out


## Öffentliche Cockpit-Sicht: feste Felder, Sitzplätze ohne Rolle, auch nach Laden und Rückgängig (die Sicht wird aus dem
## Zustand neu gebaut und bekommt nie den gesamten Kernzustand).
func test_public_cockpit_view_has_only_the_positive_list_after_load_and_undo() -> void:
	var ctx := _secret_game()
	var views: Array = [["laufend", ctx.session.cockpit_view()]]
	var other := GameSession.new()
	assert_eq(other.load_text(ctx.session.save_text()), &"", "Laden")
	views.append(["nach Laden", other.cockpit_view()])
	assert_true(other.undo(), "Rückgängig")
	views.append(["nach Rückgängig", other.cockpit_view()])
	for entry: Array in views:
		var view: Dictionary = entry[1]
		assert_eq(_sorted_keys(view), COCKPIT_KEYS, "%s: Cockpit nur mit Positivliste" % entry[0])
		for seat: Dictionary in view["seats"]:
			assert_eq(_sorted_keys(seat), SEAT_KEYS, "%s: Sitzplatz nur mit Positivliste" % entry[0])
		_assert_no_secret(JSON.stringify(view["seats"]), "%s: Sitzkreis" % entry[0])
		_assert_no_secret(JSON.stringify(view["warnings"]), "%s: Hinweiszeile" % entry[0])
