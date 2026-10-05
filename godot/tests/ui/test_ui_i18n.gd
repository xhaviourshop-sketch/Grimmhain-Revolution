extends UiTestCase
## Lokalisierung (Tests 7 bis 9): sichtbare Texte nur über Schlüssel, DE und EN mit
## denselben Schlüsseln, Sprachwechsel aktualisiert sichtbare Texte sofort.

const KEY_PATTERN := "^(app|ui)\\.[a-z0-9_]+(\\.[a-z0-9_]+)*$"


func test_po_files_have_same_keys() -> void:
	# 8
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	assert_true(de.size() >= 30, "DE-Schlüssel vorhanden (%d)" % de.size())
	var de_keys: Array = de.keys()
	var en_keys: Array = en.keys()
	de_keys.sort()
	en_keys.sort()
	assert_eq(de_keys, en_keys, "DE und EN haben dieselben Schlüssel")
	var pattern := RegEx.create_from_string(KEY_PATTERN)
	for k: Variant in de_keys:
		assert_true(pattern.search(str(k)) != null, "Schlüssel %s stabil benannt" % k)
		assert_true(str(de[k]).strip_edges() != "", "DE-Text für %s" % k)
		assert_true(str(en.get(k, "")).strip_edges() != "", "EN-Text für %s" % k)
	var registered: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	assert_true(registered.has(PO_DE) and registered.has(PO_EN), "beide Übersetzungen im Projekt registriert")
	TranslationServer.set_locale("de")
	assert_eq(tr("ui.menu.new_game"), "Neue Partie", "DE geladen")
	TranslationServer.set_locale("en")
	assert_eq(tr("ui.menu.new_game"), "New game", "EN geladen")
	TranslationServer.set_locale("de")


func test_visible_texts_use_translation_keys() -> void:
	# 7
	var de := po_entries(PO_DE)
	var shell := await spawn_shell()
	if shell == null:
		return
	var dialog := shell.call("get_dialog") as Control if shell.has_method("get_dialog") else null
	if dialog != null and shell.has_method("request_quit"):
		shell.call("request_quit")
		await frames(2)
	var toast := shell.call("get_toast") as Control if shell.has_method("get_toast") else null
	if toast != null:
		toast.call("show_message", "ui.settings.toast.language")
		await frames(2)
	for id: StringName in SCREEN_IDS:
		await navigate(shell, id)
		var roots: Array[Control] = [current_screen(shell)]
		if dialog != null:
			roots.append(dialog)
		if toast != null:
			roots.append(toast)
		for root: Control in roots:
			for c: Control in text_controls(root):
				var k := key_of(c)
				var shown := text_of(c)
				if shown == "" and k == "":
					continue  # reine Symbol- oder Umschaltflächen ohne Text
				assert_true(k != "", "%s: %s hat einen Übersetzungsschlüssel" % [id, c.name])
				assert_true(de.has(k), "%s: Schlüssel %s existiert" % [id, k])
				assert_true(shown != k and shown != "", "%s: %s zeigt übersetzten Text statt Schlüssel" % [id, c.name])


func test_no_literal_texts_in_scenes_or_scripts() -> void:
	# 7: keine sichtbaren Texte fest in Szenen oder Skripten
	var text_line := RegEx.create_from_string("^\\s*(text|tooltip_text|placeholder_text|title)\\s*=\\s*\"[^\"]+\"")
	for path: String in files_in("res://app", ".tscn"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			assert_true(text_line.search(lines[n]) == null, "%s:%d fester Text: %s" % [path, n + 1, lines[n].strip_edges()])
	var assign := RegEx.create_from_string("\\.?(text|tooltip_text)\\s*=\\s*\"[^\"]+\"")
	for path: String in files_in("res://app", ".gd"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var code := lines[n].split("#")[0]
			assert_true(assign.search(code) == null, "%s:%d fester Text im Skript: %s" % [path, n + 1, code.strip_edges()])


func test_all_referenced_keys_exist_in_both_languages() -> void:
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	var ref := RegEx.create_from_string("\"((app|ui)\\.[a-z0-9_]+(\\.[a-z0-9_]+)+)\"")
	var found := 0
	for path: String in files_in("res://app", ".gd") + files_in("res://app", ".tscn"):
		for m: RegExMatch in ref.search_all(FileAccess.get_file_as_string(path)):
			var k := m.get_string(1)
			if k.ends_with("."):
				continue
			found += 1
			assert_true(de.has(k) and en.has(k), "%s: Schlüssel %s in DE und EN" % [path.get_file(), k])
	assert_true(found >= 30, "Schlüsselverwendungen gefunden (%d)" % found)


func test_language_switch_updates_visible_texts() -> void:
	# 9
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	var button := find_node(current_screen(shell), "NewGameButton") as Button
	if button == null:
		fail("NewGameButton fehlt")
		return
	assert_eq(button.text, "Neue Partie", "Deutsch")
	settings_of(shell).call("set_language", "en")
	await frames(2)
	assert_eq(TranslationServer.get_locale(), "en", "Locale Englisch")
	assert_eq(button.text, "New game", "sofort Englisch ohne Neuladen der Ansicht")
	await navigate(shell, &"settings")
	var screen := current_screen(shell)
	assert_true(find_button(screen, "LanguageEnglishButton").button_pressed, "gewählter Knopf zeigt Englisch")
	await press(find_button(screen, "LanguageGermanButton"))
	assert_eq(TranslationServer.get_locale(), "de", "Umschalten über die Einstellungen")
	assert_eq(str(settings_of(shell).get("language")), "de", "Einstellung gespeichert (nur im Speicher)")
	assert_true(find_button(screen, "LanguageGermanButton").button_pressed, "gewählter Knopf zeigt Deutsch")
	var back := find_node(screen, "BackButton") as Button
	assert_true(back != null and back.text == "Zurück", "Kopfzeile Deutsch")
	await press(find_button(screen, "LanguageEnglishButton"))
	assert_true(back != null and back.text == "Back", "Kopfzeile Englisch")
	var version := find_node(await _start_screen(shell), "VersionLabel") as Label
	assert_true(version != null and version.text.contains(str(ProjectSettings.get_setting("application/config/version", "?"))), "Version aus zentraler Quelle")


func _start_screen(shell: Control) -> Control:
	await navigate(shell, &"start")
	return current_screen(shell)


func test_unsupported_language_rejected() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var s := settings_of(shell)
	assert_false(bool(s.call("set_language", "fr")), "nicht unterstützte Sprache abgelehnt")
	assert_eq(str(s.get("language")), "de", "Sprache unverändert")
	assert_eq(TranslationServer.get_locale(), "de", "Locale unverändert")
