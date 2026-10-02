extends UiTestCase
## Spielergruppen im Spielerschritt (Paket B): speichern, nach Neustart laden, umbenennen, aktualisieren, löschen,
## Rückfragen mit Abbruch, gleichnamige Gruppen, Schreib- und Dateifehler, Layout. Jede Test-Shell speichert in ein
## eigenes, danach entferntes Verzeichnis (nie echte Nutzerdateien).

const GROUP_NAMES: Array[String] = ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd", "Günther", "Hélène"]


## Neue App-Instanz (Shell) mit Gruppendatei `path` (leer = neuer Pfad in einem Testverzeichnis).
func _shell(path: String = "", size: Vector2i = SIZE_16_10, locale: String = "de") -> Control:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return null
	var store := context_of(shell).get("groups") as Object
	store.set("path", path if path != "" else make_save_dir() + "/groups.json")
	store.call("load_from_disk")
	return shell


func _store(shell: Control) -> Object:
	return context_of(shell).get("groups") as Object


func _groups(shell: Control) -> Array:
	return _store(shell).call("list") as Array


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control


func _names(shell: Control) -> Array:
	var out: Array = []
	for p: Variant in (setup_of(shell).call("view") as Dictionary)["persons"]:
		out.append(str((p as Dictionary)["name"]))
	return out


func _person_ids(shell: Control) -> Array:
	var out: Array = []
	for p: Variant in (setup_of(shell).call("view") as Dictionary)["persons"]:
		out.append(int((p as Dictionary)["person_id"]))
	return out


func _confirm(shell: Control) -> void:
	await press(find_button(_dialog(shell), "ConfirmButton"))


func _cancel(shell: Control) -> void:
	await press(find_button(_dialog(shell), "CancelButton"))


func _dialog_title(shell: Control) -> String:
	return (find_node(_dialog(shell), "TitleLabel") as Label).text


func _type_and_confirm(shell: Control, text: String) -> void:
	await type_text(find_node(_dialog(shell), "InputField") as LineEdit, text)
	await _confirm(shell)


func _feedback(screen: Control) -> String:
	var label := find_node(screen, "FeedbackLabel") as Label
	return label.text if label != null and label.visible else ""


## Gruppe unter dem Namen `name` über die Oberfläche speichern (Liste muss gefüllt sein).
func _save(shell: Control, screen: Control, name: String) -> void:
	await press(find_button(screen, "SaveGroupButton"))
	assert_true(_dialog(shell).visible, "Namensdialog offen")
	await _type_and_confirm(shell, name)


func _open_groups(screen: Control) -> void:
	await press(find_button(screen, "LoadGroupButton"))


func _entry(screen: Control, name: String) -> BaseButton:
	for child: Node in find_node(screen, "GroupList").get_children():
		if child is BaseButton and (child as BaseButton).text.begins_with(name + " "):
			return child as BaseButton
	fail("Gruppeneintrag %s fehlt" % name)
	return null


func _entries(screen: Control) -> Array[String]:
	var out: Array[String] = []
	for child: Node in find_node(screen, "GroupList").get_children():
		if child is BaseButton:
			out.append((child as BaseButton).text)
	return out


func _card_visible(screen: Control) -> bool:
	return (find_node(screen, "GroupCard") as Control).visible


# --- Speichern und Wiederverwenden nach Neustart --------------------------------------------------------------

func test_save_then_reuse_after_restart_reaches_a_started_game() -> void:
	var dir := "user://test-groups-restart-%d" % Time.get_ticks_usec()  # überlebt after_each, bis der Test es selbst entfernt
	var path := dir + "/groups.json"
	var first := await _shell(path)
	if first == null:
		return
	var screen := await open_new_game(first)
	await seed_names(first, GROUP_NAMES)
	var before := _names(first)
	await _save(first, screen, "  Freitagsrunde ")
	assert_false(_dialog(first).visible, "Dialog geschlossen")
	assert_eq(_names(first), before, "Speichern verändert die aktuelle Liste nicht")
	assert_true(_feedback(screen).contains("Freitagsrunde") and _feedback(screen).contains("8"), "Bestätigung nennt Name und Anzahl: %s" % _feedback(screen))
	assert_eq(_groups(first).size(), 1, "eine Gruppe gespeichert")
	assert_eq(int((session_of(first).call("view") as Dictionary)["command_count"]), 0, "kein Spielbefehl")
	await after_each()
	# Neue App-Instanz: gleiche Datei, leerer Setup-Entwurf.
	var second := await _shell(path)
	screen = await open_new_game(second)
	assert_eq(_names(second), [], "neuer Entwurf ist leer")
	await _open_groups(screen)
	assert_true(_card_visible(screen), "Gruppenkarte offen")
	assert_eq(_entries(screen).size(), 1, "gespeicherte Gruppe sichtbar")
	assert_true(_entries(screen)[0].contains("Freitagsrunde") and _entries(screen)[0].contains("8"), "Eintrag mit Name und Anzahl: %s" % _entries(screen)[0])
	await press(find_button(screen, "GroupLoadButton"))
	assert_false(_dialog(second).visible, "leere Liste braucht keine Rückfrage")
	assert_false(_card_visible(screen), "Karte nach dem Laden geschlossen")
	assert_eq(_names(second), GROUP_NAMES, "Namen mit Umlauten in gespeicherter Reihenfolge")
	assert_eq(_person_ids(second), [1, 2, 3, 4, 5, 6, 7, 8], "neue Personenobjekte nach dem üblichen Verfahren")
	assert_true(_feedback(screen).contains("Freitagsrunde"), "Meldung nennt die geladene Gruppe: %s" % _feedback(screen))
	# Bedienweg bis zur gestarteten Partie mit genau diesen Namen.
	setup_of(second).set("seed_source", func() -> int: return 4711)
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	await press(find_button(screen, "SuggestButton"))
	for d: Variant in ((setup_of(second).call("view") as Dictionary)["roles"] as Dictionary).get("decoys", []):
		setup_of(second).call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"waldhexe")
	await frames(2)
	await press(find_button(screen, "ConfirmRolesButton"))
	await press(find_button(screen, "DistributeButton"))
	await press(find_button(screen, "ConfirmDistributionButton"))
	await press(find_button(screen, "ToSeatingButton"))
	await press(find_button(screen, "ConfirmSeatingButton"))
	await press(find_button(screen, "StartGameButton"))
	await frames(3)
	var summary := session_of(second).call("summary") as Dictionary
	assert_eq(summary["names"], GROUP_NAMES, "gestartete Partie mit den Namen der Gruppe")
	assert_eq(_groups(second)[0]["players"], GROUP_NAMES, "Gruppe nach dem Spielstart unverändert")
	_remove_dir(dir)


func test_group_file_holds_only_names_after_a_full_setup() -> void:
	var path := make_save_dir() + "/groups.json"
	var shell := await _shell(path)
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, GROUP_NAMES)
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	await press(find_button(screen, "SuggestButton"))
	await press(find_button(screen, "BackToPlayersButton"))
	await _save(shell, screen, "Mit Rollen")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var group: Dictionary = (data["groups"] as Array)[0]
	var keys: Array = group.keys()
	keys.sort()
	assert_eq(keys, ["id", "name", "players"], "nur ID, Name und Namen")
	assert_eq(group["players"], GROUP_NAMES, "nur Namen in Listenreihenfolge")
	var text := FileAccess.get_file_as_string(path)
	for forbidden: String in ["role", "person_id", "round", "seat", "werwolf", "dorfbewohner"]:
		assert_false(text.to_lower().contains(forbidden), "Datei enthält kein „%s“" % forbidden)


func test_save_needs_a_name_and_a_filled_list() -> void:
	var shell := await _shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	assert_true(find_button(screen, "SaveGroupButton").disabled, "leere Liste: Speichern gesperrt")
	await seed_names(shell, GROUP_NAMES)
	assert_false(find_button(screen, "SaveGroupButton").disabled, "gefüllte Liste: Speichern frei")
	await press(find_button(screen, "SaveGroupButton"))
	assert_true(find_button(_dialog(shell), "ConfirmButton").disabled, "ohne Namen kein Speichern")
	await type_text(find_node(_dialog(shell), "InputField") as LineEdit, "   ")
	assert_true(find_button(_dialog(shell), "ConfirmButton").disabled, "nur Leerzeichen zählen nicht")
	await _cancel(shell)
	assert_eq(_groups(shell).size(), 0, "Abbrechen speichert nichts")
	assert_false(_dialog(shell).visible, "Dialog geschlossen")
	await press(find_button(screen, "SaveGroupButton"))
	await _type_and_confirm(shell, "x".repeat(33))
	assert_eq(_groups(shell).size(), 0, "zu langer Name abgelehnt")
	assert_true(_feedback(screen).contains("32"), "Fehler nennt die Grenze: %s" % _feedback(screen))
	assert_eq(_names(shell), GROUP_NAMES, "Liste bleibt")


# --- Laden mit Rückfrage --------------------------------------------------------------------------------------

func _shell_with_group(name: String = "Alte Runde") -> Array:
	var shell := await _shell()
	if shell == null:
		return []
	_store(shell).call("create", name, GROUP_NAMES)
	return [shell, await open_new_game(shell)]


func test_loading_over_a_filled_list_needs_confirmation() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	var current: Array[String] = ["Neu Eins", "Neu Zwei", "Neu Drei"]
	await seed_names(shell, current)
	await _open_groups(screen)
	await press(find_button(screen, "GroupLoadButton"))
	assert_true(_dialog(shell).visible, "gefüllte Liste: Rückfrage")
	assert_true((find_node(_dialog(shell), "MessageLabel") as Label).text.contains("3") and (find_node(_dialog(shell), "MessageLabel") as Label).text.contains("Alte Runde"), "Rückfrage nennt Anzahl und Gruppe")
	await _cancel(shell)
	assert_eq(_names(shell), current, "Abbrechen: Liste unverändert")
	assert_true(_card_visible(screen), "Abbrechen: Gruppenkarte bleibt offen")
	await press(find_button(screen, "GroupLoadButton"))
	await _confirm(shell)
	assert_eq(_names(shell), GROUP_NAMES, "nach Bestätigung ersetzt")
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "gespeicherte Gruppe unverändert")


func test_load_discards_confirmed_roles_and_never_takes_old_state() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	await seed_names(shell, ["Ein", "Zwei", "Drei", "Vier", "Fünf", "Sechs"])
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	await press(find_button(screen, "SuggestButton"))
	await press(find_button(screen, "BackToPlayersButton"))
	assert_true(int(((setup_of(shell).call("view") as Dictionary)["roles"] as Dictionary)["total"]) > 0, "Vorbereitung: Rollenwahl vorhanden")
	await _open_groups(screen)
	await press(find_button(screen, "GroupLoadButton"))
	await _confirm(shell)
	var view := setup_of(shell).call("view") as Dictionary
	assert_eq(int((view["roles"] as Dictionary)["total"]), 0, "keine alte Rollenwahl")
	assert_false(bool(view["confirmed"]), "Namen nicht bestätigt")
	assert_eq(String(view["step"]), "players", "Spielerschritt")
	assert_eq(_person_ids(shell), [1, 2, 3, 4, 5, 6, 7, 8], "neue Personen-IDs")


func test_later_setup_changes_do_not_alter_the_group() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	await _open_groups(screen)
	await press(find_button(screen, "GroupLoadButton"))
	setup_of(shell).call("add_person", "Nachzügler")
	setup_of(shell).call("remove_person", 1)
	setup_of(shell).call("rename_person", 2, "Umbenannt")
	await frames(2)
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "Gruppe bleibt unverändert")
	assert_eq(_names(shell).size(), 8, "Setup hat sich geändert (Kontrolle)")


func test_load_with_empty_group_list_shows_hint() -> void:
	var shell := await _shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await _open_groups(screen)
	assert_true(_card_visible(screen), "Karte offen")
	assert_true((find_node(screen, "GroupEmptyLabel") as Control).visible, "Hinweis „Noch keine Gruppe“")
	for name: String in ["GroupLoadButton", "GroupRenameButton", "GroupUpdateButton", "GroupDeleteButton"]:
		assert_true(find_button(screen, name).disabled, "%s ohne Gruppe gesperrt" % name)
	await press(find_button(screen, "GroupCloseButton"))
	assert_false(_card_visible(screen), "Karte geschlossen")
	assert_true((find_node(screen, "EntryCard") as Control).visible, "Eingabe wieder sichtbar")


func test_back_closes_group_card_before_leaving_setup() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	await _open_groups(screen)
	await go_back(shell)
	assert_false(_card_visible(screen), "Zurück schließt zuerst die Gruppenkarte")
	assert_eq(String(current_id(shell)), "new_game", "Setup bleibt offen")


# --- Umbenennen, Aktualisieren, Löschen, gleicher Name ----------------------------------------------------------

func test_rename_group_with_dialog() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	_store(shell).call("create", "Zweite", ["A", "B"])
	await _open_groups(screen)
	await press(find_button(screen, "GroupRenameButton"))
	assert_true(_dialog(shell).visible, "Umbenennen-Dialog")
	await _cancel(shell)
	assert_eq(str(_groups(shell)[0]["name"]), "Alte Runde", "Abbrechen: Name bleibt")
	await press(find_button(screen, "GroupRenameButton"))
	await _type_and_confirm(shell, "zweite")
	assert_eq(str(_groups(shell)[0]["name"]), "Alte Runde", "Name einer anderen Gruppe wird nicht übernommen")
	assert_true(_feedback(screen).contains("zweite"), "Fehlermeldung nennt den Namen: %s" % _feedback(screen))
	await press(find_button(screen, "GroupRenameButton"))
	await _type_and_confirm(shell, " Neue Runde ")
	assert_eq(str(_groups(shell)[0]["name"]), "Neue Runde", "umbenannt")
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "Namen unverändert")
	assert_true(_entries(screen)[0].contains("Neue Runde"), "Liste zeigt neuen Namen")


func test_update_group_is_explicit_and_confirmed() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	await _open_groups(screen)
	assert_true(find_button(screen, "GroupUpdateButton").disabled, "leere Liste: Aktualisieren gesperrt")
	await press(find_button(screen, "GroupCloseButton"))
	var current: Array[String] = ["Neu Eins", "Neu Zwei", "Neu Drei"]
	await seed_names(shell, current)
	await _open_groups(screen)
	assert_false(find_button(screen, "GroupUpdateButton").disabled, "gefüllte Liste: Aktualisieren frei")
	await press(find_button(screen, "GroupUpdateButton"))
	assert_true(_dialog(shell).visible, "Rückfrage")
	await _cancel(shell)
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "Abbrechen: Gruppe unverändert")
	await press(find_button(screen, "GroupUpdateButton"))
	await _confirm(shell)
	assert_eq(_groups(shell)[0]["players"], current, "Gruppe hat die aktuelle Liste")
	assert_eq(_names(shell), current, "aktuelle Liste bleibt")
	assert_eq(str(_groups(shell)[0]["name"]), "Alte Runde", "Name bleibt")


func test_delete_group_after_confirmation_only() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	await seed_names(shell, ["Bleibt", "Bleibt2"])
	await _open_groups(screen)
	await press(find_button(screen, "GroupDeleteButton"))
	assert_true(_dialog(shell).visible, "Löschen fragt nach")
	await _cancel(shell)
	assert_eq(_groups(shell).size(), 1, "Abbrechen: nichts gelöscht")
	await press(find_button(screen, "GroupDeleteButton"))
	await _confirm(shell)
	assert_eq(_groups(shell).size(), 0, "nach Bestätigung gelöscht")
	assert_eq(_entries(screen).size(), 0, "Liste leer")
	assert_true((find_node(screen, "GroupEmptyLabel") as Control).visible, "Hinweis „Noch keine Gruppe“")
	assert_eq(_names(shell), ["Bleibt", "Bleibt2"], "aktuelle Liste bleibt")


func test_saving_under_an_existing_name_asks_before_replacing() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	var current: Array[String] = ["Neu Eins", "Neu Zwei"]
	await seed_names(shell, current)
	await _save(shell, screen, "ALTE RUNDE")
	assert_true(_dialog(shell).visible, "gleicher Name: Rückfrage statt stillem Überschreiben")
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "noch nichts überschrieben")
	await _cancel(shell)
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "Abbrechen: Gruppe unverändert")
	assert_eq(_groups(shell).size(), 1, "keine zweite Gruppe")
	await _save(shell, screen, "Alte Runde")
	await _confirm(shell)
	assert_eq(_groups(shell).size(), 1, "weiterhin eine Gruppe")
	assert_eq(_groups(shell)[0]["players"], current, "nach Bestätigung aktualisiert")
	assert_eq(str(_groups(shell)[0]["name"]), "Alte Runde", "Name der Gruppe bleibt")


# --- Fehlerfälle -----------------------------------------------------------------------------------------------

func test_write_failure_keeps_group_and_list() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	await seed_names(shell, ["Neu Eins", "Neu Zwei"])
	_store(shell).set("simulate_failure", &"write")
	await _save(shell, screen, "Zweite")
	assert_eq(_groups(shell).size(), 1, "nichts Neues gespeichert")
	assert_true(_feedback(screen).contains("Speichern nicht möglich"), "verständliche Fehlermeldung: %s" % _feedback(screen))
	assert_eq(_names(shell), ["Neu Eins", "Neu Zwei"], "aktuelle Liste bleibt")
	await _open_groups(screen)
	await press(find_button(screen, "GroupDeleteButton"))
	await _confirm(shell)
	assert_eq(_groups(shell).size(), 1, "Löschen bei Schreibfehler: Gruppe bleibt")
	_store(shell).set("simulate_failure", &"")
	assert_eq(_groups(shell)[0]["players"], GROUP_NAMES, "Gruppe unverändert")


func test_corrupt_group_file_is_reported_not_loaded() -> void:
	var path := make_save_dir() + "/groups.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ kaputt")
	file.close()
	var shell := await _shell(path)
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await _open_groups(screen)
	var status := find_node(screen, "GroupStatusLabel") as Label
	assert_true(status.visible and status.text.contains("nicht gelesen"), "Defekt sichtbar gemeldet: %s" % status.text)
	assert_eq(_entries(screen).size(), 0, "keine Gruppen als geladen ausgegeben")
	assert_true(FileAccess.file_exists(path + ".corrupt"), "defekte Datei beiseitegelegt")


func test_groups_never_touch_game_state() -> void:
	var made := await _shell_with_group()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen: Control = made[1]
	var events := [0]
	session_of(shell).connect("events_applied", func(_e: Array) -> void: events[0] += 1)
	var hash_before := str(session_of(shell).call("state_hash"))
	await seed_names(shell, ["Neu Eins", "Neu Zwei"])
	await _save(shell, screen, "Zweite")
	await _open_groups(screen)
	await press(find_button(screen, "GroupRenameButton"))
	await _type_and_confirm(shell, "Dritte")
	await press(find_button(screen, "GroupUpdateButton"))
	await _confirm(shell)
	await press(find_button(screen, "GroupLoadButton"))
	await _confirm(shell)
	assert_eq(events[0], 0, "keine Spielereignisse")
	assert_eq(str(session_of(shell).call("state_hash")), hash_before, "Spielzustand unverändert")
	assert_eq(int((session_of(shell).call("view") as Dictionary)["command_count"]), 0, "kein Befehl")


# --- Lokalisierung und Layout ---------------------------------------------------------------------------------

func test_group_texts_exist_in_both_languages() -> void:
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	for code: String in ["empty_name", "invalid_characters", "name_too_long", "no_players", "too_many_persons", "empty_player",
			"invalid_player_characters", "player_name_too_long", "name_taken", "unknown_group", "write_failed", "load_failed"]:
		var key := "ui.groups.error.%s" % code
		assert_true(de.has(key) and en.has(key), "%s in DE und EN" % key)
	for key: String in ["ui.groups.status.unreadable", "ui.groups.status.newer_version", "ui.groups.status.skipped", "ui.groups.status.recovered"]:
		assert_true(de.has(key) and en.has(key), "%s in DE und EN" % key)


func _check_layout(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var dialog := _dialog(shell)
	var root: Control = dialog if dialog.visible else screen
	var group_scroll := find_node(screen, "GroupScroll") as ScrollContainer
	var person_scroll := find_node(screen, "PersonScroll") as ScrollContainer
	var buttons: Array[BaseButton] = []
	for c: Control in visible_controls(root):
		if c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var scrolls: Array[ScrollContainer] = []
		for s: ScrollContainer in [group_scroll, person_scroll]:
			if s != null and s.is_ancestor_of(c):
				scrolls.append(s)
		var r := rect_of(c)
		if not scrolls.is_empty():
			if not r.intersects(rect_of(scrolls[0])) or (c is BaseButton and not inside(r, rect_of(scrolls[0]))):
				continue
		else:
			assert_true(inside(r, viewport), "%s: %s im Viewport (%s)" % [label, c.name, r])
		var min_size := c.get_combined_minimum_size()
		assert_true(min_size.x <= c.size.x + 0.5 and min_size.y <= c.size.y + 0.5, "%s: %s nicht abgeschnitten (min %s, ist %s)" % [label, c.name, min_size, c.size])
		if c is BaseButton:
			buttons.append(c as BaseButton)
			assert_true(c.size.x >= 47.5 and c.size.y >= 47.5, "%s: %s mindestens 48×48 (%s)" % [label, c.name, c.size])
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			assert_false(overlaps(rect_of(buttons[i]), rect_of(buttons[j])), "%s: %s und %s überlappen" % [label, buttons[i].name, buttons[j].name])
	if root == screen:
		for name: String in ["BackButton", "ConfirmPlayersButton", "RestartButton", "LoadGroupButton", "SaveGroupButton"]:
			var c := find_node(screen, name) as Control
			assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s erreichbar" % [label, name])
		var column := find_node(screen, "SideColumn") as Control
		assert_true(inside(rect_of(column), viewport), "%s: linke Spalte im Fenster (%s)" % [label, rect_of(column)])


func test_layout_entry_and_group_card() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		for locale: String in ["de", "en"]:
			var shell := await _shell("", size, locale)
			if shell == null:
				return
			for i: int in 6:
				_store(shell).call("create", "Gruppe mit einem sehr langen Namen Nr. %d" % i if i % 2 == 0 else "Runde %d" % i, GROUP_NAMES)
			var screen := await open_new_game(shell)
			await seed_names(shell, long_names(12))
			await _check_layout(shell, "%s %s Eingabe mit Gruppenknöpfen" % [size, locale])
			await _open_groups(screen)
			await _check_layout(shell, "%s %s Gruppenkarte" % [size, locale])
			await press(find_button(screen, "GroupRenameButton"))
			await _check_layout(shell, "%s %s Umbenennen-Dialog" % [size, locale])
			await _cancel(shell)
			await press(find_button(screen, "GroupLoadButton"))
			await _check_layout(shell, "%s %s Ersetzen-Dialog" % [size, locale])
			await _cancel(shell)
			await after_each()
