extends UiTestCase
## Geräteeinstellungen dauerhaft (SettingsStore, Paket 5a): getrennt von Spielständen, vor der ersten Ansicht
## angewendet, robuste Validierung, sicheres Schreiben ohne Zerstörung der letzten gültigen Datei und keine
## falsche Erfolgsmeldung. Jeder Test nutzt ein eigenes temporäres Verzeichnis, nie die echte Einstellungsdatei.

const STORE_SCRIPT := "res://app/settings/settings_store.gd"
const ROLES := ["werwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "amalia", "detektiv"]


func _store_path() -> String:
	return make_save_dir().path_join("settings.json")


func _store(path: String) -> Object:
	var script := load_script(STORE_SCRIPT)
	return script.new(path) if script != null else null


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _files(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d != null:
		for f: String in d.get_files():
			out.append(f)
	out.sort()
	return out


## Neue App-Instanz wie beim echten Start: Shell ohne vorbereitete Einstellungen, Einstellungsdatei unter `path`.
## `locales` sammelt die aktive Sprache für jeden Knoten, der beim Aufbau in den Baum kommt.
func _launch(path: String, locales: Array = []) -> Control:
	await resize(SIZE_16_10)
	var shell := (load(MAIN_SCENE) as PackedScene).instantiate() as Control
	shell.set("quit_handler", func() -> void: quit_calls += 1)
	var context := AppContext.new()
	context.saves.base_dir = make_save_dir()  # keine echten Spielstände
	shell.set("app_context", context)
	shell.set("settings_store", _store(path))
	var watch := func(_node: Node) -> void: locales.append(TranslationServer.get_locale())
	tree.node_added.connect(watch)
	tree.root.add_child(shell)
	tree.node_added.disconnect(watch)
	_spawned.append(shell)
	await frames(3)
	return shell


func _toast_key(shell: Control) -> String:
	var toast := shell.call("get_toast") as Control
	var label := find_node(toast, "MessageLabel")
	return str(label.get("text_key")) if label != null else ""


func test_first_start_without_file_uses_defaults_and_writes_nothing() -> void:
	var path := _store_path()
	var store := _store(path)
	if store == null:
		return
	var s := AppSettings.new()
	var status: Dictionary = store.call("load_into", s)
	assert_true(bool(status["ok"]), "fehlende Datei ist normale Erstbenutzung")
	assert_true(bool(status["first_run"]), "Erstbenutzung erkannt")
	assert_eq(s.language, "de", "Standardsprache")
	assert_false(s.reduced_motion, "Standard: Bewegung aktiv")
	assert_false(s.left_handed, "Standard: Linkshänderwert aus")
	assert_false(FileAccess.file_exists(path), "Laden legt keine Datei an")


func test_changes_via_controls_survive_restart() -> void:
	var path := _store_path()
	var shell := await _launch(path)
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"settings")
	var screen := current_screen(shell)
	await press(find_button(screen, "LanguageEnglishButton"))
	assert_eq(_toast_key(shell), "ui.settings.toast.language", "Erfolgsmeldung nach gespeicherter Änderung")
	var motion := find_button(screen, "ReducedMotionToggle")
	if motion.button_pressed:
		await press(motion)
	await press(motion)
	assert_true(motion.button_pressed, "Bewegung reduziert")
	assert_eq(_toast_key(shell), "ui.settings.toast.motion_on", "Erfolgsmeldung Bewegung")
	assert_true(FileAccess.file_exists(path), "Einstellungsdatei geschrieben")
	# Neue Einstellungs-Instanz liest dieselben Werte.
	var fresh := AppSettings.new()
	assert_true(bool(_store(path).call("load_into", fresh)["ok"]), "neu geladen")
	assert_eq(fresh.language, "en", "Sprache dauerhaft")
	assert_true(fresh.reduced_motion, "Bewegung reduzieren dauerhaft")
	# Neue App-Instanz startet mit den Werten.
	TranslationServer.set_locale("de")
	var again := await _launch(path)
	assert_eq(str(settings_of(again).get("language")), "en", "neue App: Englisch")
	assert_true(bool(settings_of(again).get("reduced_motion")), "neue App: Bewegung reduziert")
	var toast := again.call("get_toast") as Object
	assert_eq(float(toast.call("fade_duration")), 0.0, "reduzierte Bewegung wirkt nach dem Neustart")


func test_settings_applied_before_first_screen() -> void:
	var path := _store_path()
	_write(path, JSON.stringify({"format": "grimmhain-settings", "version": 1, "language": "en", "reduced_motion": true, "left_handed": false}))
	TranslationServer.set_locale("de")
	var locales: Array = []
	var shell := await _launch(path, locales)
	if shell == null:
		return
	assert_true(locales.size() > 3, "Aufbau beobachtet (%d Knoten)" % locales.size())
	assert_false(locales.has("de"), "kein Knoten wurde mit Deutsch aufgebaut (kein Sprachsprung)")
	assert_eq(current_id(shell), &"start", "Startansicht")
	var button := find_node(current_screen(shell), "EnterButton") as Button
	assert_true(button != null and button.text == "Enter", "erste Ansicht sofort Englisch (%s)" % (button.text if button != null else "?"))


func test_invalid_values_fall_back_individually_and_unknown_keys_ignored() -> void:
	var path := _store_path()
	var text := JSON.stringify({"format": "grimmhain-settings", "version": 1, "language": "fr", "reduced_motion": "yes",
		"left_handed": true, "volume": 3, "future": {"x": 1}})
	_write(path, text)
	var s := AppSettings.new()
	var status: Dictionary = _store(path).call("load_into", s)
	assert_true(bool(status["ok"]), "Datei lesbar trotz einzelner ungültiger Werte")
	assert_eq(s.language, "de", "ungültige Sprache → Standard")
	assert_false(s.reduced_motion, "falscher Typ → Standard")
	assert_true(s.left_handed, "gültiger unabhängiger Wert bleibt erhalten")
	var rejected: Array = status["rejected"]
	rejected.sort()
	assert_eq(rejected, ["language", "reduced_motion"], "abgelehnte Werte benannt")
	assert_eq(_read(path), text, "Laden schreibt die Datei nicht um")
	# Falsche Typen je Feld: Zahl als Sprache, Zahl als Schalter.
	_write(path, JSON.stringify({"format": "grimmhain-settings", "version": 1, "language": 1, "reduced_motion": 1, "left_handed": "true"}))
	var t := AppSettings.new()
	var st: Dictionary = _store(path).call("load_into", t)
	assert_eq([t.language, t.reduced_motion, t.left_handed], ["de", false, false], "alle falschen Typen → Standard")
	assert_eq((st["rejected"] as Array).size(), 3, "drei abgelehnte Werte")


func test_corrupt_file_does_not_block_start() -> void:
	var path := _store_path()
	for text: String in ["{nicht json", "[1, 2]", JSON.stringify({"format": "andere-app", "language": "en"}), ""]:
		_write(path, text)
		var s := AppSettings.new()
		var status: Dictionary = _store(path).call("load_into", s)
		assert_false(bool(status["ok"]), "defekt erkannt: %s" % text)
		assert_eq(str(status["error"]), "unreadable", "Fehlerart")
		assert_eq(s.language, "de", "Standardwerte bei defekter Datei")
		assert_eq(_read(path), text, "defekte Datei beim Laden nicht verändert")
	_write(path, "{nicht json")
	TranslationServer.set_locale("de")
	var shell := await _launch(path)
	assert_eq(current_id(shell), &"start", "App startet trotz defekter Datei")
	assert_eq(_read(path), "{nicht json", "Start schreibt nichts")


func test_load_does_not_write_or_emit() -> void:
	var path := _store_path()
	var text := "{\"format\": \"grimmhain-settings\",  \"version\": 1, \"language\": \"en\", \"reduced_motion\": true}\n"
	_write(path, text)
	var s := AppSettings.new()
	var changes: Array = []
	s.changed.connect(func(k: StringName) -> void: changes.append(k))
	_store(path).call("load_into", s)
	assert_eq(changes, [], "Laden meldet keine Änderungen (keine Speicher-/Signalfolge)")
	TranslationServer.set_locale("de")
	var shell := await _launch(path)
	assert_eq(str(settings_of(shell).get("language")), "en", "geladen")
	assert_eq(_read(path), text, "Start schreibt die Datei nicht um (Formatierung unverändert)")
	assert_eq(_files(path.get_base_dir()), ["settings.json"], "keine Zusatzdateien beim Laden")


func test_write_failure_keeps_last_valid_file_and_reports() -> void:
	var path := _store_path()
	var shell := await _launch(path)
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"settings")
	var screen := current_screen(shell)
	var motion := find_button(screen, "ReducedMotionToggle")
	if not motion.button_pressed:
		await press(motion)
	var valid := _read(path)
	assert_true(valid.contains("\"reduced_motion\":true"), "gültige Ausgangsfassung gespeichert")
	var store := shell.get("settings_store") as Object
	for step: String in ["write", "verify", "backup", "swap"]:
		store.set("simulate_failure", StringName(step))
		await press(find_button(screen, "LanguageEnglishButton" if str(settings_of(shell).get("language")) == "de" else "LanguageGermanButton"))
		assert_eq(_toast_key(shell), "ui.settings.toast.save_failed", "%s: Fehler sichtbar statt Erfolg" % step)
		var check := AppSettings.new()
		assert_true(bool(_store(path).call("load_into", check)["ok"]), "%s: letzte gültige Fassung lesbar" % step)
		assert_eq(check.language, "de", "%s: gespeicherte Sprache unverändert" % step)
		assert_true(check.reduced_motion, "%s: gespeicherter Wert unverändert" % step)
	assert_eq(str(settings_of(shell).get("language")), "de", "Sitzung nutzt die gewählte Einstellung weiter")
	# Fehler behoben: die nächste Änderung wird gespeichert, ohne Wiederholungsschleife davor.
	store.set("simulate_failure", &"")
	await press(find_button(screen, "LanguageEnglishButton"))
	assert_eq(_toast_key(shell), "ui.settings.toast.language", "Erfolg nach behobenem Fehler")
	var after := AppSettings.new()
	_store(path).call("load_into", after)
	assert_eq(after.language, "en", "weitere Änderung gespeichert")
	assert_true(after.reduced_motion, "unabhängiger Wert erhalten")


func test_settings_file_holds_no_game_data_and_game_untouched() -> void:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	assert_true(ctx.session.submit(Fixtures.start_roles(ROLES, 4)).ok, "Partie gestartet")
	var core_before := ctx.session.save_text()
	var saves_before := _files(ctx.saves.base_dir)
	var save_file_before := _read(ctx.saves.path_for(ctx.session.round_id()))
	var path := _store_path()
	ctx.use_settings_store(_store(path) as SettingsStore)
	ctx.settings.set_language("en")
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_left_handed(true)
	assert_eq(ctx.session.save_text(), core_before, "Partiezustand und Seed unverändert")
	assert_eq(_files(ctx.saves.base_dir), saves_before, "keine zusätzlichen Spielstanddateien")
	assert_eq(_read(ctx.saves.path_for(ctx.session.round_id())), save_file_before, "Spielstand nicht neu geschrieben")
	assert_true(path.get_base_dir() != ctx.saves.base_dir, "Einstellungen getrennt von Spielständen")
	var data: Variant = JSON.parse_string(_read(path))
	assert_true(data is Dictionary, "Einstellungsdatei ist JSON")
	var keys: Array = (data as Dictionary).keys()
	keys.sort()
	assert_eq(keys, ["format", "language", "left_handed", "music_enabled", "reduced_motion", "show_calls", "show_night_timer", "version"], "nur Geräteeinstellungen")
	assert_eq(int(ctx.settings_store.last_status.get("ok", false)), 1, "letztes Speichern erfolgreich")
	TranslationServer.set_locale("de")


func test_music_off_survives_restart_and_old_file_defaults_on() -> void:
	var path := _store_path()
	var store := _store(path) as SettingsStore
	var s := AppSettings.new()
	assert_true(s.music_enabled, "Standard: Musik an")
	s.set_music_enabled(false)
	assert_true(store.save(s).get("ok", false), "gespeichert")
	var fresh := AppSettings.new()
	store.load_into(fresh)
	assert_false(fresh.music_enabled, "Musik aus bleibt nach Neustart aus")
	DirAccess.remove_absolute(path + ".bak")
	_write(path, '{"format": "grimmhain-settings", "version": 1, "language": "de"}')
	var old := AppSettings.new()
	store.load_into(old)
	assert_true(old.music_enabled, "alter Stand ohne Feld: Standard an")


func test_production_default_path_is_separate_from_saves() -> void:
	var script := load_script(STORE_SCRIPT)
	if script == null:
		return
	var default_path := str(script.get("DEFAULT_PATH"))
	assert_eq(default_path, "user://settings.json", "fester Speicherort")
	assert_false(default_path.begins_with(SaveService.DEFAULT_DIR), "nicht im Spielstandverzeichnis")
