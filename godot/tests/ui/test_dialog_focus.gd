extends UiTestCase
## ConfirmDialog als Modal (Tests 46 bis 51): Fokus bleibt im Dialog, Hintergrund gesperrt,
## Escape bricht ab, Fokus kehrt zum Auslöser zurück, kein zweiter Dialog.


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control if shell != null and shell.has_method("get_dialog") else null


func _in_dialog(dialog: Control) -> bool:
	var owner := focus_owner()
	return owner != null and dialog.is_ancestor_of(owner)


func test_focus_trapped_with_tab_and_shift_tab() -> void:
	# 47, 48
	var shell := await spawn_shell()
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	var trigger := find_button(current_screen(shell), "NewGameButton")
	trigger.grab_focus()
	shell.call("request_quit")
	await frames(2)
	var dialog := _dialog(shell)
	assert_true(dialog.visible and _in_dialog(dialog), "Fokus springt in den Dialog")
	var seen := {}
	for i: int in 5:
		await key(KEY_TAB)
		assert_true(_in_dialog(dialog), "Tab %d bleibt im Dialog" % (i + 1))
		if focus_owner() != null:
			seen[focus_owner().name] = true
	assert_true(seen.has(&"CancelButton") and seen.has(&"ConfirmButton"), "Tab wechselt zwischen den Dialogaktionen")
	for i: int in 5:
		await key_mod(KEY_TAB, true)
		assert_true(_in_dialog(dialog), "Shift+Tab %d bleibt im Dialog" % (i + 1))
	for k: Key in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		await key(k)
		assert_true(_in_dialog(dialog), "Pfeiltaste %s bleibt im Dialog" % OS.get_keycode_string(k))
	trigger.grab_focus()
	await frames(1)
	assert_true(_in_dialog(dialog), "Fokus kann nicht in den Hintergrund gezogen werden")


func test_background_blocked_for_pointer() -> void:
	# 46
	var shell := await spawn_shell()
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	var target := find_button(current_screen(shell), "SettingsButton")
	shell.call("request_quit")
	await frames(2)
	await click(target)
	assert_eq(current_id(shell), &"main_menu", "Klick auf verdeckten Button wirkt nicht")
	assert_true(_dialog(shell).visible, "Dialog bleibt offen")


func test_escape_cancels_and_focus_returns() -> void:
	# 49, 50
	var shell := await spawn_shell()
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	var trigger := find_button(current_screen(shell), "SettingsButton")
	trigger.grab_focus()
	shell.call("request_quit")
	await frames(2)
	await key(KEY_ESCAPE)
	var dialog := _dialog(shell)
	assert_false(dialog.visible, "Escape schließt")
	assert_eq(quit_calls, 0, "Abbruchaktion, nicht Bestätigung")
	assert_eq(current_id(shell), &"main_menu", "Ansicht bleibt")
	assert_true(trigger.has_focus(), "Fokus zurück zum Auslöser")
	shell.call("request_quit")
	await frames(2)
	await press(find_button(dialog, "CancelButton"))
	assert_true(trigger.has_focus(), "auch nach Abbrechen per Button")


func test_focus_returns_after_setup_dialogs() -> void:
	# 50 für Entfernen und Neu beginnen
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, numbered_names(6))
	var dialog := _dialog(shell)
	var remove := find_button(person_rows(screen)[2], "RemoveButton")
	remove.grab_focus()
	await press(remove)
	assert_true(dialog.visible and _in_dialog(dialog), "Entfernen-Dialog mit Fokus")
	await key(KEY_ESCAPE)
	assert_true(not dialog.visible and remove.has_focus(), "Fokus zurück zu Entfernen")
	var restart := find_button(screen, "RestartButton")
	restart.grab_focus()
	await press(restart)
	await key(KEY_ESCAPE)
	assert_true(restart.has_focus(), "Fokus zurück zu Neu beginnen")
	assert_eq(row_ids(screen).size(), 6, "nichts verändert")


func test_no_second_dialog() -> void:
	# 51
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, numbered_names(3))
	var remove := find_button(person_rows(screen)[0], "RemoveButton")
	remove.pressed.emit()
	remove.pressed.emit()
	find_button(person_rows(screen)[1], "RemoveButton").pressed.emit()
	shell.call("request_quit")
	await frames(2)
	var dialogs := 0
	for node: Node in tree.root.find_children("*", "", true, false):
		if node.get_script() != null and (node.get_script() as Script).get_global_name() == &"ConfirmDialog" and (node as Control).visible:
			dialogs += 1
	assert_eq(dialogs, 1, "genau ein offener Dialog")
	var message := (find_node(_dialog(shell), "MessageLabel") as Label).text
	assert_true(message.contains("Person 1"), "erste Anfrage bleibt gültig: %s" % message)
	await press(find_button(_dialog(shell), "ConfirmButton"))
	assert_eq(row_ids(screen), [2, 3] as Array[int], "nur die erste Anfrage ausgeführt")
	assert_eq(quit_calls, 0, "spätere Anfragen verworfen")
	assert_false(_dialog(shell).visible, "Dialog geschlossen")
