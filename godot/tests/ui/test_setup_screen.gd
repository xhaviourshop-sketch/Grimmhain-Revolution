extends UiTestCase
## Spieler-Setup-Ansicht „Neue Partie“ (Tests 6, 7, 17, 30, 32, 34 bis 36, 38 bis 45).


func _input_of(screen: Control) -> LineEdit:
	return find_node(screen, "NameInput") as LineEdit


func _add_via_button(screen: Control, text: String) -> void:
	await type_text(_input_of(screen), text)
	await press(find_button(screen, "AddButton"))


func _feedback(screen: Control) -> String:
	var label := find_node(screen, "FeedbackLabel") as Label
	return label.text if label != null else ""


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control if shell != null and shell.has_method("get_dialog") else null


func test_single_entry_button_and_enter() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var input := _input_of(screen)
	if input == null:
		fail("NameInput fehlt")
		return
	assert_true(input.has_focus(), "Eingabefeld hat beim Öffnen den Fokus")
	await _add_via_button(screen, "  Anna ")
	assert_eq(row_ids(screen), [1] as Array[int], "Button fügt hinzu")
	assert_eq(row_label(person_rows(screen)[0], "NameLabel") if person_rows(screen).size() == 1 else "", "Anna", "normalisierter Name angezeigt")
	assert_eq(input.text, "", "Feld nach Erfolg geleert")
	assert_true(input.has_focus(), "Fokus zurück im Eingabefeld")
	input.grab_focus()
	await type_text(input, "Ben")
	await key(KEY_ENTER)
	assert_eq(row_ids(screen), [1, 2] as Array[int], "Enter fügt hinzu")
	await type_text(input, "   ")
	input.text_submitted.emit(input.text)
	await frames(2)
	assert_eq(row_ids(screen), [1, 2] as Array[int], "Leerzeichen werden nicht angelegt")
	assert_true(_feedback(screen) != "" and _feedback(screen) == tr("ui.setup.error.empty_name"), "verständliche Meldung bei leerer Eingabe")
	var too_long := "Z".repeat(33)
	await type_text(input, too_long)
	input.text_submitted.emit(input.text)
	await frames(2)
	assert_eq(row_ids(screen), [1, 2] as Array[int], "zu langer Name nicht angelegt")
	assert_eq(input.text, too_long, "ungültiger Text bleibt zur Korrektur erhalten")
	assert_true(_feedback(screen).contains("32"), "Meldung nennt die Grenze: %s" % _feedback(screen))
	var add := find_button(screen, "AddButton")
	await type_text(input, "")
	assert_true(add != null and add.disabled, "Hinzufügen ohne Text gesperrt")


func test_name_field_stays_in_edit_mode_after_enter_and_button() -> void:
	# Web/Tablet: Nach Enter verließ das Feld den Bearbeitungsmodus, das erneute grab_focus() tat nichts und der
	# nächste Name ging verloren, bis das Feld neu angetippt wurde.
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var input := _input_of(screen)
	await type_text(input, "Anna")
	await key(KEY_ENTER)
	assert_eq(row_ids(screen), [1] as Array[int], "Enter fügt hinzu")
	assert_true(input.has_focus() and input.is_editing(), "nach Enter bleibt das Feld im Bearbeitungsmodus")
	await _add_via_button(screen, "Ben")
	assert_eq(row_ids(screen), [1, 2] as Array[int], "Hinzufügen fügt hinzu")
	assert_true(input.has_focus() and input.is_editing(), "nach Hinzufügen bleibt das Feld im Bearbeitungsmodus")


func test_several_names_in_one_text_are_reviewed_before_adding() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var input := _input_of(screen)
	await type_text(input, "Anna, Ben und Cara")
	await key(KEY_ENTER)
	assert_eq(row_ids(screen), [] as Array[int], "noch nichts hinzugefügt")
	var card := find_node(screen, "NameReviewCard") as Control
	assert_true(card != null and card.is_visible_in_tree(), "Prüfliste erscheint")
	var fields := card.find_children("ReviewNameInput", "LineEdit", true, false)
	assert_eq(fields.size(), 3, "drei erkannte Namen")
	(fields[1] as LineEdit).text = "Benno"
	(fields[1] as LineEdit).text_changed.emit("Benno")
	await press(card.find_children("ReviewRemoveButton", "Button", true, false)[2] as BaseButton)
	await press(find_button(card, "ReviewAddAllButton"))
	assert_eq(row_ids(screen), [1, 2] as Array[int], "geänderte Liste ohne den entfernten Namen übernommen")
	var names: Array[String] = []
	for row: Control in person_rows(screen):
		names.append(row_label(row, "NameLabel"))
	assert_eq(names, ["Anna", "Benno"] as Array[String], "Namen wie in der Prüfliste")
	assert_false(card.is_visible_in_tree(), "Prüfliste geschlossen")
	assert_eq(input.text, "", "Eingabefeld geleert")
	assert_true(input.has_focus() and input.is_editing(), "Feld bereit für den nächsten Namen")


func test_double_press_adds_and_imports_once() -> void:
	# 30
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await type_text(_input_of(screen), "Anna")
	var add := find_button(screen, "AddButton")
	if add == null:
		return
	add.pressed.emit()
	add.pressed.emit()
	await frames(2)
	assert_eq(row_ids(screen), [1] as Array[int], "Doppeltippen fügt genau einmal hinzu")
	assert_eq(_feedback(screen), "", "keine Fehlermeldung nach Doppeltippen")
	await press(find_button(screen, "ImportToggleButton"))
	var text := find_node(screen, "ImportText") as TextEdit
	assert_true(text != null and text.is_visible_in_tree(), "Importbereich geöffnet")
	await type_text(text, "Ben, Clara; Dora")
	var confirm := find_button(screen, "ImportConfirmButton")
	if confirm == null:
		return
	confirm.pressed.emit()
	confirm.pressed.emit()
	await frames(2)
	assert_eq(row_ids(screen), [1, 2, 3, 4] as Array[int], "Doppeltippen importiert genau einmal")
	assert_false(text.is_visible_in_tree(), "Importbereich nach Erfolg geschlossen")


func test_import_rejection_is_explained() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await press(find_button(screen, "ImportToggleButton"))
	var text := find_node(screen, "ImportText") as TextEdit
	var long_name := "Q".repeat(33)
	await type_text(text, "Anna\n%s\nBen" % long_name)
	await press(find_button(screen, "ImportConfirmButton"))
	assert_eq(row_ids(screen).size(), 0, "nichts importiert")
	var message := (find_node(screen, "ImportFeedbackLabel") as Label).text
	assert_true(message.contains("2") and message.contains(long_name.left(8)), "Meldung nennt Eintrag 2: %s" % message)
	assert_eq(text.text, "Anna\n%s\nBen" % long_name, "Eingabe bleibt zur Korrektur")
	await seed_names(shell, numbered_names(22))
	await type_text(text, "A, B, C")
	await press(find_button(screen, "ImportConfirmButton"))
	assert_eq(row_ids(screen).size(), 22, "Import über 24 vollständig abgelehnt")
	message = (find_node(screen, "ImportFeedbackLabel") as Label).text
	assert_true(message.contains("24"), "Meldung nennt die Höchstzahl: %s" % message)


func test_counter_limits_and_confirm_button() -> void:
	# 17, 14, 15
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var confirm := find_button(screen, "ConfirmPlayersButton")
	var count := find_node(screen, "CountLabel") as Label
	if confirm == null or count == null:
		fail("Bestätigen oder Zähler fehlt")
		return
	assert_true(count.text.contains("0 / 24"), "Zähler 0 / 24: %s" % count.text)
	assert_true(confirm.disabled, "Bestätigen bei 0 gesperrt")
	await seed_names(shell, numbered_names(5))
	assert_true(confirm.disabled and count.text.contains("5 / 24"), "bei 5 gesperrt")
	await seed_names(shell, ["anna", "Anna"])
	assert_false(confirm.disabled, "bei 7 mit Dublette frei")
	await seed_names(shell, numbered_names(17, "Mehr"))
	assert_true(count.text.contains("24 / 24"), "Zähler 24 / 24")
	var input := _input_of(screen)
	assert_true(not input.editable and find_button(screen, "AddButton").disabled and find_button(screen, "ImportToggleButton").disabled, "bei 24 keine weitere Eingabe")
	assert_false(confirm.disabled, "24 bestätigbar")


func test_ids_survive_language_rerender_and_reopen() -> void:
	# 6, 7, 42
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, ["Anna", "Ben", "Clara"])
	var ids := row_ids(screen)
	settings_of(shell).call("set_language", "en")
	await frames(3)
	assert_eq(row_ids(screen), ids, "Sprachwechsel verändert keine IDs")
	assert_true((find_node(screen, "CountLabel") as Label).text.contains("3 / 24") and find_button(screen, "AddButton").text == "Add", "Texte englisch")
	await navigate(shell, &"settings")
	await navigate(shell, &"main_menu")
	# Unbestätigte Änderungen: das Hauptmenü wurde hier programmgesteuert erreicht, der Entwurf bleibt.
	screen = await open_new_game(shell)
	assert_eq(row_ids(screen), ids, "neu aufgebaute Ansicht zeigt dieselben IDs")
	await seed_names(shell, ["Dora", "Emil", "Frida"])
	await press(find_button(screen, "ConfirmPlayersButton"))
	assert_true(bool((setup_of(shell).call("view") as Dictionary)["confirmed"]), "bestätigt")
	await press(find_button(screen, "BackButton"))
	assert_eq(current_id(shell), &"main_menu", "bestätigter Entwurf: Zurück ohne Rückfrage")
	assert_false(_dialog(shell).visible, "kein Dialog")
	screen = await open_new_game(shell)
	assert_eq(row_ids(screen), [1, 2, 3, 4, 5, 6] as Array[int], "wieder geöffnet: gleiche IDs")
	var summary := find_node(screen, "ConfirmedSummary") as Control
	assert_true(summary != null and summary.is_visible_in_tree(), "bestätigter Zustand sichtbar")


func test_confirm_creates_no_game() -> void:
	# 38, 40, 41
	var shell := await spawn_shell()
	if shell == null:
		return
	var session := session_of(shell)
	var events := [0]
	session.connect("events_applied", func(_e: Array) -> void: events[0] += 1)
	var screen := await open_new_game(shell)
	await seed_names(shell, numbered_names(8))
	await press(find_button(screen, "ConfirmPlayersButton"))
	var setup_view: Dictionary = setup_of(shell).call("view")
	assert_true(bool(setup_view["confirmed"]), "Entwurf bestätigt")
	var view: Dictionary = session.call("view")
	assert_false(bool(view["has_game"]), "kein GameState-Spiel")
	assert_eq(int(view["command_count"]), 0, "kein StartGame oder anderer Befehl")
	assert_eq(events[0], 0, "keine Spielereignisse")
	var status := find_node(screen, "StatusLabel") as Label
	assert_true(status != null and status.text == tr("ui.setup.status.confirmed").format({"count": 8}), "Erfolgsstatus: %s" % (status.text if status != null else ""))
	var toast := shell.call("get_toast") as Control
	assert_true(bool(toast.call("is_showing")), "Statusmeldung")
	await press(find_button(person_rows(screen)[0], "EditButton"))
	await type_text(find_node(screen, "EditInput") as LineEdit, "Anders")
	await press(find_button(screen, "EditSaveButton"))
	assert_false(bool((setup_of(shell).call("view") as Dictionary)["confirmed"]), "Bearbeiten hebt Bestätigung auf")
	var summary := find_node(screen, "ConfirmedSummary") as Control
	assert_false(summary.is_visible_in_tree(), "Zusammenfassung verschwindet")


func test_edit_cancel_and_duplicate_warning() -> void:
	# 31, 32, 33
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, ["Anna", "Ben", "Clara"])
	var row := person_rows(screen)[1]
	await press(find_button(row, "EditButton"))
	var edit := find_node(screen, "EditInput") as LineEdit
	assert_true(edit != null and edit.is_visible_in_tree() and edit.text == "Ben" and edit.has_focus(), "Bearbeitungsmodus mit vollem Namen")
	assert_false((find_node(screen, "NameInput") as Control).is_visible_in_tree(), "Einzeleingabe währenddessen verborgen")
	await type_text(edit, "Benjamin")
	await press(find_button(screen, "EditCancelButton"))
	assert_eq((setup_of(shell).call("view") as Dictionary)["persons"][1]["name"], "Ben", "Abbrechen verändert nichts")
	assert_true(find_button(person_rows(screen)[1], "EditButton").has_focus(), "Fokus zurück zur Zeile")
	await press(find_button(person_rows(screen)[1], "EditButton"))
	await type_text(edit, "x".repeat(33))
	await press(find_button(screen, "EditSaveButton"))
	assert_true(edit.is_visible_in_tree() and _feedback(screen).contains("32"), "zu lang: bleibt im Bearbeitungsmodus mit Meldung")
	assert_eq((setup_of(shell).call("view") as Dictionary)["persons"][1]["name"], "Ben", "atomar abgelehnt")
	await key(KEY_ESCAPE)
	assert_eq(current_id(shell), &"new_game", "Escape beendet nur den Bearbeitungsmodus")
	assert_false(edit.is_visible_in_tree(), "Bearbeitungsmodus geschlossen")
	await press(find_button(person_rows(screen)[1], "EditButton"))
	await type_text(edit, " anna ")
	await press(find_button(screen, "EditSaveButton"))
	var rows := person_rows(screen)
	assert_eq(row_ids(screen), [1, 2, 3] as Array[int], "IDs unverändert")
	assert_eq(row_label(rows[1], "NameLabel"), "anna", "neuer Name")
	for i: int in [0, 1]:
		var badge := find_node(rows[i], "DuplicateBadge") as Control
		assert_true(badge != null and badge.is_visible_in_tree(), "Zeile %d mit Dublettenhinweis" % (i + 1))
	var badge_text := row_label(rows[0], "DuplicateLabel")
	assert_true(badge_text != "" and badge_text == tr("ui.setup.person.duplicate"), "Hinweis als Text, nicht nur Farbe")
	assert_false((find_node(rows[2], "DuplicateBadge") as Control).is_visible_in_tree(), "Clara ohne Hinweis")
	var summary := find_node(screen, "DuplicateSummaryLabel") as Label
	assert_true(summary != null and summary.is_visible_in_tree() and summary.text != "", "Zusammenfassung der Dubletten")


func test_remove_requires_confirmation() -> void:
	# 34, 35, 36, 37
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, ["Anna", "Ben", "Clara", "Dora"])
	var remove := find_button(person_rows(screen)[1], "RemoveButton")
	remove.grab_focus()
	await press(remove)
	var dialog := _dialog(shell)
	assert_true(dialog.visible, "Rückfrage vor dem Entfernen")
	var message := (find_node(dialog, "MessageLabel") as Label).text
	assert_true(message.contains("Ben"), "Dialog nennt den Namen: %s" % message)
	assert_eq(row_ids(screen), [1, 2, 3, 4] as Array[int], "noch nichts entfernt")
	await press(find_button(dialog, "CancelButton"))
	assert_eq(row_ids(screen), [1, 2, 3, 4] as Array[int], "Abbruch verändert nichts")
	await press(find_button(person_rows(screen)[1], "RemoveButton"))
	await press(find_button(dialog, "ConfirmButton"))
	assert_eq(row_ids(screen), [1, 3, 4] as Array[int], "Ben entfernt, übrige IDs bleiben")
	var numbers: Array[String] = []
	for row: Control in person_rows(screen):
		numbers.append(row_label(row, "NumberLabel"))
	assert_eq(numbers, ["1.", "2.", "3."] as Array[String], "Listennummern aktualisiert")
	var owner := focus_owner()
	assert_true(owner != null and screen.is_ancestor_of(owner), "Fokus bleibt in der Ansicht")


func test_leave_with_unconfirmed_changes() -> void:
	# 43, 44
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await press(find_button(screen, "BackButton"))
	assert_eq(current_id(shell), &"main_menu", "leerer Entwurf: Zurück ohne Rückfrage")
	screen = await open_new_game(shell)
	await seed_names(shell, ["Anna", "Ben"])
	var dialog := _dialog(shell)
	await press(find_button(screen, "BackButton"))
	assert_true(dialog.visible and current_id(shell) == &"new_game", "Rückfrage bei unbestätigten Änderungen")
	var alternative := find_node(dialog, "AlternativeButton") as Button
	assert_true(alternative != null and alternative.is_visible_in_tree(), "drei Wahlmöglichkeiten")
	await press(find_button(dialog, "CancelButton"))
	assert_true(not dialog.visible and current_id(shell) == &"new_game", "weiter bearbeiten")
	await key(KEY_ESCAPE)
	assert_true(dialog.visible, "Escape fragt ebenfalls")
	await press(alternative)
	assert_eq(current_id(shell), &"main_menu", "Entwurf behalten und zum Hauptmenü")
	assert_eq((setup_of(shell).call("view") as Dictionary)["count"], 2, "Entwurf behalten")
	screen = await open_new_game(shell)
	assert_eq(row_ids(screen), [1, 2] as Array[int], "unbestätigte Daten wieder da")
	shell.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	assert_true(dialog.visible, "System-Zurück fragt ebenfalls")
	await press(find_button(dialog, "ConfirmButton"))
	assert_eq(current_id(shell), &"main_menu", "verwerfen und zum Hauptmenü")
	var v: Dictionary = setup_of(shell).call("view")
	assert_true(int(v["count"]) == 0 and int(v["next_person_id"]) == 1, "Entwurf verworfen")


func test_restart_requires_confirmation() -> void:
	# 45
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var restart := find_button(screen, "RestartButton")
	assert_true(restart != null and restart.disabled, "Neu beginnen bei leerem Entwurf gesperrt")
	await seed_names(shell, numbered_names(6))
	await press(find_button(screen, "ConfirmPlayersButton"))
	assert_false(restart.disabled, "Neu beginnen verfügbar")
	var dialog := _dialog(shell)
	await press(restart)
	assert_true(dialog.visible, "Rückfrage")
	await press(find_button(dialog, "CancelButton"))
	assert_eq(row_ids(screen).size(), 6, "Abbruch behält alles")
	await press(restart)
	await press(find_button(dialog, "ConfirmButton"))
	var v: Dictionary = setup_of(shell).call("view")
	assert_true(int(v["count"]) == 0 and int(v["next_person_id"]) == 1 and not bool(v["confirmed"]) and not bool(v["has_unconfirmed_changes"]), "vollständig zurückgesetzt")
	assert_eq(row_ids(screen).size(), 0, "Liste leer")
	assert_true(_input_of(screen).has_focus(), "Fokus im Eingabefeld")
