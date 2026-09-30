extends UiTestCase
## App-Shell und Navigation (Auftrag UI-Grundlage, Tests 1 bis 6, 15, 19).
## Menüfolge: Start → Hauptmenü → Neue Partie | Fortsetzen | Cockpit | Einstellungen,
## jede Unterseite zurück zum Hauptmenü, Hauptmenü zurück zum Start.

const MENU_BUTTONS := {
	&"new_game": "NewGameButton",
	&"continue": "ContinueButton",
	&"cockpit": "CockpitButton",
	&"settings": "SettingsButton",
	&"lexicon": "LexiconButton",
	&"rulebook": "RulebookButton",
}


func test_main_scene_loads() -> void:
	# 1
	assert_eq(str(ProjectSettings.get_setting("application/run/main_scene", "")), MAIN_SCENE, "Hauptszene in project.godot")
	var shell := await spawn_shell()
	if shell == null:
		return
	var script := shell.get_script() as Script
	assert_true(script != null and script.get_global_name() == &"AppShell", "Wurzel ist AppShell")
	assert_eq(current_id(shell), &"start", "App beginnt mit dem Startbildschirm")
	assert_true(router_of(shell) != null, "Screen-Router vorhanden")
	assert_true(shell.theme != null, "Theme an der Shell gesetzt")


func test_all_scenes_load() -> void:
	# 2 und Laden jeder neuen Szene
	var ids := load_script(SCREEN_IDS_SCRIPT)
	if ids == null:
		return
	for id: StringName in SCREEN_IDS:
		var path := str(ids.call("scene_path", id))
		var scene := load(path) as PackedScene if ResourceLoader.exists(path) else null
		assert_true(scene != null, "%s: Szene %s ladbar" % [id, path])
		if scene == null:
			continue
		var screen := scene.instantiate() as Control
		assert_true(screen != null, "%s: instanziierbar" % id)
		if screen == null:
			continue
		var script := screen.get_script() as Script
		var base := script.get_base_script() if script != null else null
		assert_true(base != null and base.get_global_name() == &"BaseScreen", "%s: erbt von BaseScreen" % id)
		assert_eq(StringName(screen.get("screen_id")), id, "%s: Szene trägt ihre ID" % id)
		screen.free()
	var scenes := files_in("res://app", ".tscn")
	assert_true(scenes.size() >= 10, "App-Szenen gefunden (%d)" % scenes.size())
	for path: String in scenes:
		var scene := load(path) as PackedScene
		assert_true(scene != null and scene.can_instantiate(), "%s ladbar" % path)
		if scene != null:
			var node := scene.instantiate()
			assert_true(node != null, "%s instanziierbar" % path)
			if node != null:
				node.free()


func test_screen_ids_unique_and_complete() -> void:
	# 3
	var ids := load_script(SCREEN_IDS_SCRIPT)
	if ids == null:
		return
	var all: Array = ids.call("all")
	assert_eq(all.size(), SCREEN_IDS.size(), "genau acht Ansichten")
	var seen := {}
	var paths := {}
	for id: Variant in all:
		assert_false(seen.has(id), "ID %s eindeutig" % id)
		seen[id] = true
		assert_true(SCREEN_IDS.has(StringName(id)), "ID %s erwartet" % id)
		var path := str(ids.call("scene_path", id))
		assert_false(paths.has(path), "Szene %s nur einer ID zugeordnet" % path)
		paths[path] = true
	assert_eq(StringName(ids.call("parent_of", &"start")), &"", "Start hat keine Elternansicht")
	assert_eq(StringName(ids.call("parent_of", &"main_menu")), &"start", "Hauptmenü zurück zum Start")
	for id: StringName in SUB_SCREENS:
		assert_eq(StringName(ids.call("parent_of", id)), &"main_menu", "%s zurück zum Hauptmenü" % id)
	assert_eq(str(ids.call("scene_path", &"gibt-es-nicht")), "", "unbekannte ID ohne Szene")


func test_navigation_reaches_all_screens() -> void:
	# 4, 5
	var shell := await spawn_shell()
	if shell == null:
		return
	await press(find_button(current_screen(shell), "EnterButton"))
	assert_eq(current_id(shell), &"main_menu", "Start → Hauptmenü")
	for id: StringName in MENU_BUTTONS:
		await press(find_button(current_screen(shell), MENU_BUTTONS[id]))
		assert_eq(current_id(shell), id, "Hauptmenü → %s" % id)
		await press(find_button(current_screen(shell), "BackButton"))
		assert_eq(current_id(shell), &"main_menu", "%s → zurück zum Hauptmenü" % id)


func test_back_escape_and_system_back() -> void:
	# 5: Zurück, Escape und Android-/System-Zurück folgen derselben Logik.
	var shell := await spawn_shell()
	if shell == null:
		return
	for id: StringName in SUB_SCREENS:
		await navigate(shell, id)
		await go_back(shell)
		assert_eq(current_id(shell), &"main_menu", "go_back von %s" % id)
		await navigate(shell, id)
		await key(KEY_ESCAPE)
		assert_eq(current_id(shell), &"main_menu", "Escape von %s" % id)
		await navigate(shell, id)
		shell.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames(3)
		assert_eq(current_id(shell), &"main_menu", "System-Zurück von %s" % id)
	await go_back(shell)
	assert_eq(current_id(shell), &"start", "Hauptmenü → Start")
	assert_false(bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)), "System-Zurück beendet die App nicht automatisch")


func test_back_on_start_desktop_asks_before_quit() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var dialog := shell.call("get_dialog") as Control if shell.has_method("get_dialog") else null
	assert_true(dialog != null and not dialog.visible, "Dialog anfangs verborgen")
	if dialog == null:
		return
	await key(KEY_ESCAPE)
	assert_true(dialog.visible, "Escape auf dem Start öffnet die Beenden-Rückfrage")
	assert_eq(current_id(shell), &"start", "Ansicht bleibt")
	await key(KEY_ESCAPE)
	assert_false(dialog.visible, "Escape schließt zuerst den Dialog")
	assert_eq(quit_calls, 0, "nicht beendet")
	await go_back(shell)
	await press(find_button(dialog, "ConfirmButton"))
	assert_eq(quit_calls, 1, "Bestätigen beendet")
	assert_false(dialog.visible, "Dialog geschlossen")


func test_back_on_start_mobile_quits_and_menu_hides_quit() -> void:
	var platform := load_script(PLATFORM_SCRIPT)
	if platform == null:
		return
	platform.call("set_override", &"mobile")
	var shell := await spawn_shell()
	if shell == null:
		return
	await go_back(shell)
	assert_eq(quit_calls, 1, "System-Zurück auf dem Start verlässt die App auf Mobilgeräten")
	await navigate(shell, &"main_menu")
	var quit := find_node(current_screen(shell), "QuitButton") as Control
	assert_true(quit != null and not quit.visible, "Beenden nur auf Desktop")
	platform.call("set_override", &"desktop")
	await navigate(shell, &"start")
	await navigate(shell, &"main_menu")
	quit = find_node(current_screen(shell), "QuitButton") as Control
	assert_true(quit != null and quit.visible, "Beenden auf Desktop sichtbar")


func test_repeated_navigation_creates_no_duplicates() -> void:
	# 6
	for reduced: bool in [true, false]:
		var shell := await spawn_shell(SIZE_16_10, "de", reduced)
		if shell == null:
			return
		await navigate(shell, &"main_menu")
		var button := find_button(current_screen(shell), "NewGameButton")
		if button != null:
			button.pressed.emit()
			button.pressed.emit()
			button.pressed.emit()
		for i: int in 3:
			shell.call("navigate", &"new_game")
		await frames(3)
		assert_eq(current_id(shell), &"new_game", "Ziel erreicht (Übergänge %s)" % ("aus" if reduced else "an"))
		assert_eq(_screen_count(shell), 1, "genau eine Ansicht im Host (Übergänge %s)" % ("aus" if reduced else "an"))
		assert_false(bool(shell.call("navigate", &"new_game")), "Navigation zur aktiven Ansicht wird ignoriert")
		shell.call("go_back")
		shell.call("go_back")
		await frames(3)
		assert_eq(_screen_count(shell), 1, "auch nach schnellem Zurück genau eine Ansicht")
		await after_each()


func _screen_count(shell: Control) -> int:
	var router := router_of(shell)
	var count := 0
	if router == null:
		return -1
	for child: Node in router.get_children():
		if child.get("screen_id") != null:
			count += 1
	return count


func test_mouse_click_and_keyboard_trigger_same_actions() -> void:
	# Maus und Tastatur lösen dieselbe Aktion aus wie das Signal (Touch: Mausemulation).
	var shell := await spawn_shell()
	if shell == null:
		return
	var enter := find_button(current_screen(shell), "EnterButton")
	if enter == null:
		return
	await click(enter)
	assert_eq(current_id(shell), &"main_menu", "Mausklick auf Eintreten")
	await go_back(shell)
	assert_true(tree.root.gui_get_focus_owner() != null, "Fokus nach Navigation gesetzt")
	await key(KEY_ENTER)
	assert_eq(current_id(shell), &"main_menu", "Enter auf dem fokussierten Button")
	assert_true(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)), "Touch wird als Maus emuliert")


func test_keyboard_focus() -> void:
	# 15
	var shell := await spawn_shell()
	if shell == null:
		return
	for id: StringName in SCREEN_IDS:
		await navigate(shell, id)
		var screen := current_screen(shell)
		var buttons := visible_buttons(screen)
		assert_true(buttons.size() >= 1, "%s: interaktive Elemente vorhanden" % id)
		for b: BaseButton in buttons:
			assert_eq(b.focus_mode, Control.FOCUS_ALL, "%s: %s fokussierbar" % [id, b.name])
		var owner := tree.root.gui_get_focus_owner()
		assert_true(owner != null and screen.is_ancestor_of(owner), "%s: Standardfokus in der Ansicht" % id)
	await navigate(shell, &"main_menu")
	var before := tree.root.gui_get_focus_owner()
	await key(KEY_TAB)
	var after := tree.root.gui_get_focus_owner()
	assert_true(before != null and after != null and before != after, "Tab bewegt den Fokus")


func test_placeholders_emit_no_game_events() -> void:
	# 19
	var shell := await spawn_shell()
	if shell == null:
		return
	var session := session_of(shell)
	if session == null:
		fail("Anwendungsschicht fehlt im Kontext")
		return
	var counter := [0]
	session.connect("events_applied", func(_events: Array) -> void: counter[0] += 1)
	for id: StringName in SCREEN_IDS:
		await navigate(shell, id)
		for b: BaseButton in visible_buttons(current_screen(shell)):
			if ["BackButton", "QuitButton"].has(String(b.name)) or MENU_BUTTONS.values().has(String(b.name)) or b.name == &"EnterButton":
				continue
			await press(b)
			await navigate(shell, id)
	var view: Dictionary = session.call("view")
	assert_false(bool(view.get("has_game", true)), "keine Partie entstanden")
	assert_eq(int(view.get("command_count", -1)), 0, "kein Befehl an den Regelkern")
	assert_eq(counter[0], 0, "keine Spielereignisse")
	await navigate(shell, &"cockpit")
	var badge := find_node(current_screen(shell), "NoGameBadge") as Control
	assert_true(badge != null and badge.is_visible_in_tree(), "Cockpit kennzeichnet: keine Partie aktiv")
	for name: String in ["PhaseArea", "InstructionCard", "SeatRingArea", "ActionsArea"]:
		var area := find_node(current_screen(shell), name) as Control
		assert_true(area != null and area.is_visible_in_tree(), "Cockpit-Bereich %s vorhanden" % name)


func test_toast_and_dialog_foundation() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var toast := shell.call("get_toast") as Control if shell.has_method("get_toast") else null
	assert_true(toast != null, "Toast-Grundlage vorhanden")
	if toast == null:
		return
	toast.call("show_message", "ui.settings.toast.language")
	await frames(2)
	assert_true(toast.is_visible_in_tree(), "Statusmeldung sichtbar")
	var label := find_node(toast, "MessageLabel") as Label
	assert_true(label != null and label.text == tr("ui.settings.toast.language") and label.text != "ui.settings.toast.language", "Statusmeldung übersetzt")
