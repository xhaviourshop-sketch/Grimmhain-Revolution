extends UiTestCase
## Partiehistorie und Abschlussbericht über Anwendungsschicht und Oberfläche (Paket D): Speichern genau einmal nach bestätigtem
## Sieg, Neustart, Rückgängig und erneuter Abschluss, Historienfehler ohne Schaden für die Partie, öffentliche und private
## Fassung, Textexport mit Überschreibschutz, Löschen, Cockpit-Einstieg, Sprachwechsel und Layout. Nur temporäre Daten.

const NAMES: Array = ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"]
const ROLES: Array = ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


func _paths() -> Dictionary:
	var dir := make_save_dir()
	return {"dir": dir, "history": dir + "/history.json", "exports": dir + "/exports", "saves": dir + "/saves"}


func _context(paths: Dictionary) -> AppContext:
	var ctx := AppContext.new()
	ctx.saves.base_dir = str(paths["saves"])
	ctx.history.path = str(paths["history"])
	ctx.history.load_from_disk()
	ctx.exports_dir = str(paths["exports"])
	return ctx


func _start(ctx: AppContext, round_id: String = "ui-bericht") -> void:
	var players: Array = []
	var map := {}
	for i: int in ROLES.size():
		players.append({"id": i + 1, "name": NAMES[i]})
		map[str(i + 1)] = ROLES[i]
	var result := ctx.session.submit(Command.start_game({"round_id": round_id, "seed": 1, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(ROLES.size()), "roles": map}))
	assert_true(result.ok, "Start angenommen")


## Bis zur offenen Siegentscheidung (Wolfsparität), nicht bestätigt.
func _to_decision(ctx: AppContext) -> int:
	_start(ctx)
	ctx.session.start_night()
	ctx.session.answer_targets([3])
	ctx.session.end_night()
	ctx.session.nominate(1, 4)
	ctx.session.decide_execution(4)
	return int(ctx.session.cockpit_view()["next"]["candidates"][0]["id"])


func _win(ctx: AppContext) -> void:
	assert_true(ctx.session.confirm_win(_to_decision(ctx)).ok, "Sieg bestätigt")


func _ids(ctx: AppContext) -> Array:
	return ctx.history.list().map(func(e: Dictionary) -> String: return str(e["game_id"]))


# --- Anwendungsschicht -----------------------------------------------------------------------------------------

func test_report_is_saved_once_after_the_confirmed_win_and_survives_a_restart() -> void:
	var paths := _paths()
	var ctx := _context(paths)
	var id := _to_decision(ctx)
	assert_eq(ctx.history.list().size(), 0, "vor der Bestätigung keine Historie")
	assert_true(ctx.session.confirm_win(id).ok, "Sieg bestätigt")
	assert_eq(_ids(ctx), ["ui-bericht"], "genau ein Eintrag nach bestätigtem Sieg")
	assert_eq(str(ctx.history.list()[0]["status"]), HistoryStore.STATUS_COMPLETED, "abgeschlossen")
	var modified := FileAccess.get_modified_time(str(paths["history"]))
	assert_false(bool(ctx.sync_history()["changed"]), "erneutes Synchronisieren ändert nichts")
	ctx.session.load_text(ctx.session.save_text())  # Laden löst wieder eine Sicht aus
	assert_eq(_ids(ctx), ["ui-bericht"], "kein Duplikat nach Laden")
	assert_eq(FileAccess.get_modified_time(str(paths["history"])), modified, "keine Schreibaktion ohne Änderung")
	# Neustart: neue Anwendungsinstanz, keine aktive Partie, Bericht lesbar.
	var restarted := _context(paths)
	assert_eq(restarted.session.round_id(), "", "keine aktive Partie")
	assert_eq(_ids(restarted), ["ui-bericht"], "Bericht nach Neustart vorhanden")
	var entry := restarted.history.get_entry("ui-bericht")
	assert_true(ReportText.plain_text(entry["report"], ReportText.PUBLIC).contains("Bärbel"), "Bericht ohne Partie lesbar")


func test_undo_of_the_confirmation_updates_the_entry_and_a_new_completion_replaces_it() -> void:
	var ctx := _context(_paths())
	_win(ctx)
	assert_true(ctx.session.undo(), "Siegbestätigung zurückgenommen")
	assert_eq(str(ctx.history.list()[0]["status"]), HistoryStore.STATUS_REOPENED, "keine veraltete Behauptung „abgeschlossen“")
	assert_eq(ctx.history.list().size(), 1, "Eintrag bleibt lesbar")
	assert_true(ctx.session.redo(), "Wiederholen")
	assert_eq(str(ctx.history.list()[0]["status"]), HistoryStore.STATUS_COMPLETED, "wieder abgeschlossen")
	assert_true(ctx.session.undo(), "erneut zurückgenommen")
	var next: Dictionary = ctx.session.cockpit_view()["next"]
	assert_true(ctx.session.confirm_win(int(next["candidates"][0]["id"])).ok, "Sieg erneut bestätigt")
	assert_eq(ctx.history.list().size(), 1, "derselbe Bericht wird aktualisiert, kein zweiter Eintrag")
	assert_eq(str(ctx.history.list()[0]["status"]), HistoryStore.STATUS_COMPLETED, "abgeschlossen")


func test_history_failure_never_damages_the_game() -> void:
	var healthy := _context(_paths())
	_win(healthy)
	var expected := healthy.session.state_hash()
	var ctx := _context(_paths())
	ctx.history.simulate_failure = &"write"
	_win(ctx)
	assert_true(ctx.session.is_over(), "Partie beendet trotz Historienfehler")
	assert_eq(ctx.session.state_hash(), expected, "Spielstand unverändert")
	assert_eq(ctx.history.list().size(), 0, "nichts in der Historie")
	assert_false(bool(ctx.history.last_status["ok"]), "Fehler gemeldet")
	var loaded := ctx.saves.load_game(ctx.session.round_id())
	assert_true(bool(loaded["ok"]), "Partie selbst ist gespeichert")
	ctx.history.simulate_failure = &""
	assert_true(bool(ctx.sync_history()["ok"]), "neuer Versuch gelingt")
	assert_eq(ctx.history.list().size(), 1, "Bericht nachgetragen")


func test_no_history_entry_for_a_running_or_rejected_game() -> void:
	var ctx := _context(_paths())
	var id := _to_decision(ctx)
	assert_eq(ctx.history.list().size(), 0, "offene Siegentscheidung")
	assert_true(ctx.session.reject_win("noch nicht").ok, "abgelehnt")
	assert_eq(ctx.history.list().size(), 0, "abgelehnter Sieg")
	assert_true(id >= 0, "Kandidat vorhanden")


# --- Oberfläche -------------------------------------------------------------------------------------------------

func _shell_with_finished_game(size: Vector2i = SIZE_4_3, locale: String = "de") -> Array:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return []
	var ctx := context_of(shell) as AppContext
	var paths := _paths()
	ctx.history.path = str(paths["history"])
	ctx.history.load_from_disk()
	ctx.exports_dir = str(paths["exports"])
	_win(ctx)
	await navigate(shell, &"main_menu")
	await press(find_button(current_screen(shell), "HistoryButton"))
	return [shell, ctx, paths]


func _view(shell: Control) -> HistoryView:
	return current_screen(shell).get("view") as HistoryView


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control


func _report_text(shell: Control) -> String:
	return "\n".join(_view(shell).report_texts())


func test_empty_history_and_list_after_a_win() -> void:
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var paths := _paths()
	ctx.history.path = str(paths["history"])
	await navigate(shell, &"main_menu")
	await press(find_button(current_screen(shell), "HistoryButton"))
	assert_eq(current_id(shell), &"history", "Hauptmenü öffnet die Historie")
	assert_true((find_node(current_screen(shell), "HistoryEmptyLabel") as Control).visible, "leerer Zustand")
	_win(ctx)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"history")
	var buttons := find_node(current_screen(shell), "HistoryList").get_children()
	assert_eq(buttons.size(), 1, "ein Bericht in der Liste")
	var text: String = (buttons[0] as BaseButton).text
	assert_true(text.contains("Anna") and text.contains("6") and text.contains("Werwölfe"), "Eintrag mit Namen, Zahl und Sieger: %s" % text)
	assert_false((find_node(current_screen(shell), "HistoryEmptyLabel") as Control).visible, "kein leerer Zustand mehr")


func test_public_version_first_private_only_after_confirmation() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	var view := _view(shell)
	assert_true(view.is_report_open(), "Bericht geöffnet")
	assert_eq(view.current_version(), ReportText.PUBLIC, "öffentliche Fassung zuerst")
	assert_true(find_button(screen, "HistoryPublicButton").button_pressed and not find_button(screen, "HistoryGmButton").button_pressed, "private Fassung nicht vorausgewählt")
	var text := _report_text(shell)
	assert_true(text.contains("Abschlussbericht (öffentliche Fassung)") and text.contains("Werwölfe") and text.contains("Dörte wurde hingerichtet"), "öffentlicher Inhalt")
	for released: String in ["Rollen zum Spielende", "Bärbel: Blutwolf", "Émile: Detektiv", "Siegbedingung: Die Wölfe sind mindestens so viele wie alle anderen Lebenden."]:
		assert_true(text.contains(released), "nach bestätigtem Spielende öffentlich: %s" % released)
	for secret: String in ["Rudelangriff", "ursprünglich", "Spielleiterkorrektur"]:
		assert_false(text.contains(secret), "öffentlich ohne %s" % secret)
	assert_eq(find_node(screen, "HistoryExportButton").get("text_key"), "ui.history.export.public", "Exportknopf nennt die öffentliche Fassung")
	# Wechsel zur privaten Fassung: erst nach Bestätigung, Abbrechen ändert nichts und baut nichts.
	await press(find_button(screen, "HistoryGmButton"))
	assert_true(_dialog(shell).visible, "Rückfrage vor der privaten Fassung")
	await press(find_button(_dialog(shell), "CancelButton"))
	assert_eq(view.current_version(), ReportText.PUBLIC, "nach Abbrechen weiter öffentlich")
	assert_false(_report_text(shell).contains("Rudelangriff"), "nichts Privates gebaut")
	assert_true(find_button(screen, "HistoryPublicButton").button_pressed, "Auswahl zurückgesetzt")
	await press(find_button(screen, "HistoryGmButton"))
	await press(find_button(_dialog(shell), "ConfirmButton"))
	assert_eq(view.current_version(), ReportText.GM, "private Fassung nach Bestätigung")
	text = _report_text(shell)
	assert_true(text.contains("Spielleiterfassung") and text.contains("Rudelangriff") and text.contains("Dörte: Amalia") and text.contains("Siegbedingung"), "privater Inhalt")
	assert_eq(find_node(screen, "HistoryExportButton").get("text_key"), "ui.history.export.gm", "Exportknopf nennt die Spielleiterfassung")
	assert_eq(find_node(screen, "HistoryExportInfoLabel").get("text_key"), "ui.history.export_info.gm", "Hinweis zur Fassung vor dem Export")
	# Erneutes Öffnen beginnt wieder öffentlich.
	await go_back(shell)
	assert_false(view.is_report_open(), "Zurück schließt den Bericht")
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	assert_eq(view.current_version(), ReportText.PUBLIC, "wieder öffentlich beim erneuten Öffnen")
	assert_false(_report_text(shell).contains("Rudelangriff"), "keine private Fassung stehen geblieben")


func test_export_needs_confirmation_before_overwriting_and_writes_utf8() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var ctx: AppContext = made[1]
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	await press(find_button(screen, "HistoryExportButton"))
	var public_path := ReportExport.path_for(ctx.exports_dir, ctx.history.get_entry("ui-bericht")["report"], ReportText.PUBLIC)
	assert_true(FileAccess.file_exists(public_path), "öffentliche Datei geschrieben")
	assert_true(public_path.get_file().contains("oeffentlich"), "Fassung im Dateinamen")
	var feedback := find_node(screen, "HistoryFeedbackLabel") as Label
	assert_true(feedback.visible and feedback.text.contains("grimmhain-bericht"), "Meldung nennt die Datei: %s" % feedback.text)
	var content := FileAccess.get_file_as_bytes(public_path).get_string_from_utf8()
	assert_true(content.contains("Bärbel") and content.contains("Çelik") and content.contains("Fjörd"), "UTF-8 mit Umlauten")
	assert_false(content.contains("Rudelangriff"), "Datei der öffentlichen Fassung ohne Privates")
	# Vorhandene Datei: nur nach Bestätigung überschreiben.
	var file := FileAccess.open(public_path, FileAccess.WRITE)
	file.store_string("ALTER INHALT")
	file.close()
	await press(find_button(screen, "HistoryExportButton"))
	assert_true(_dialog(shell).visible, "Rückfrage vor dem Überschreiben")
	await press(find_button(_dialog(shell), "CancelButton"))
	assert_eq(FileAccess.get_file_as_string(public_path), "ALTER INHALT", "Abbruch: Datei unverändert")
	await press(find_button(screen, "HistoryExportButton"))
	await press(find_button(_dialog(shell), "ConfirmButton"))
	assert_true(FileAccess.get_file_as_string(public_path).contains("Abschlussbericht"), "nach Bestätigung ersetzt")
	# Spielleiterfassung: eigene Datei, öffentliche Datei bleibt.
	var public_content := FileAccess.get_file_as_string(public_path)
	await press(find_button(screen, "HistoryGmButton"))
	await press(find_button(_dialog(shell), "ConfirmButton"))
	await press(find_button(screen, "HistoryExportButton"))
	var gm_path := ReportExport.path_for(ctx.exports_dir, ctx.history.get_entry("ui-bericht")["report"], ReportText.GM)
	assert_true(FileAccess.file_exists(gm_path) and gm_path.get_file().contains("spielleitung"), "Spielleiterdatei geschrieben")
	assert_true(FileAccess.get_file_as_bytes(gm_path).get_string_from_utf8().contains("Rudelangriff"), "Spielleiterdatei mit Rollen und Ursachen")
	assert_eq(FileAccess.get_file_as_string(public_path), public_content, "öffentliche Datei unverändert")


func test_export_failure_is_reported_and_changes_nothing() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var ctx: AppContext = made[1]
	var paths: Dictionary = made[2]
	var blocker := str(paths["dir"]) + "/blocker"
	var file := FileAccess.open(blocker, FileAccess.WRITE)
	file.store_string("x")
	file.close()
	ctx.exports_dir = blocker + "/unter"
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	await press(find_button(screen, "HistoryExportButton"))
	var feedback := find_node(screen, "HistoryFeedbackLabel") as Label
	assert_true(feedback.visible and feedback.text.contains("Export nicht möglich"), "verständliche Fehlermeldung: %s" % feedback.text)
	assert_eq(FileAccess.get_file_as_string(blocker), "x", "vorhandene Datei unverändert")
	assert_true(ctx.session.is_over(), "Partie unberührt")


func test_delete_needs_confirmation_and_leaves_the_game_alone() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var ctx: AppContext = made[1]
	var hash_before := ctx.session.state_hash()
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	await press(find_button(screen, "HistoryDeleteButton"))
	assert_true(_dialog(shell).visible, "Löschen fragt nach")
	await press(find_button(_dialog(shell), "CancelButton"))
	assert_eq(ctx.history.list().size(), 1, "Abbrechen: Bericht bleibt")
	assert_true(_view(shell).is_report_open(), "Bericht bleibt offen")
	await press(find_button(screen, "HistoryDeleteButton"))
	await press(find_button(_dialog(shell), "ConfirmButton"))
	assert_eq(ctx.history.list().size(), 0, "nach Bestätigung gelöscht")
	assert_false(_view(shell).is_report_open(), "zurück in der Liste")
	assert_true((find_node(screen, "HistoryEmptyLabel") as Control).visible, "leerer Zustand")
	assert_eq(ctx.session.state_hash(), hash_before, "Spielstand unverändert")
	var restarted := HistoryStore.new(ctx.history.path)
	restarted.load_from_disk()
	assert_eq(restarted.list().size(), 0, "auch nach Neustart gelöscht")


func test_reopened_entry_is_marked_and_cannot_be_exported() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var ctx: AppContext = made[1]
	assert_true(ctx.session.undo(), "Siegbestätigung zurückgenommen")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"history")
	var screen := current_screen(shell)
	var entry := find_node(screen, "HistoryList").get_child(0) as BaseButton
	assert_true(entry.text.contains("Partie läuft wieder") and not entry.text.contains("Sieger"), "Liste sagt nicht „abgeschlossen“: %s" % entry.text)
	await press(entry)
	assert_true((find_node(screen, "HistoryReopenedLabel") as Control).visible, "Hinweis im Bericht")
	assert_true(find_button(screen, "HistoryExportButton").disabled, "Export gesperrt")
	assert_true(_view(shell).is_report_open(), "Bericht bleibt lesbar")


func test_cockpit_game_over_card_opens_the_report() -> void:
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var paths := _paths()
	ctx.history.path = str(paths["history"])
	_win(ctx)
	await navigate(shell, &"cockpit")
	var button := find_button(current_screen(shell), "OpenReportButton")
	assert_true(button != null and button.is_visible_in_tree(), "Abschlussbericht am Spielende erreichbar")
	await press(button)
	assert_eq(current_id(shell), &"history", "Historienansicht")
	assert_true(_view(shell).is_report_open() and _view(shell).current_game_id() == "ui-bericht", "Bericht dieser Partie geöffnet")
	assert_eq(_view(shell).current_version(), ReportText.PUBLIC, "öffentliche Fassung")
	await go_back(shell)
	assert_false(_view(shell).is_report_open(), "Zurück: Liste")
	await go_back(shell)
	assert_eq(current_id(shell), &"main_menu", "dann Hauptmenü")


func test_cockpit_entry_retries_a_failed_history_save() -> void:
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	ctx.history.path = str(_paths()["history"])
	ctx.history.simulate_failure = &"write"
	_win(ctx)
	assert_eq(ctx.history.list().size(), 0, "Speichern gescheitert")
	await navigate(shell, &"cockpit")
	ctx.history.simulate_failure = &"write"
	await press(find_button(current_screen(shell), "OpenReportButton"))
	var status := find_node(current_screen(shell), "HistoryStatusLabel") as Label
	assert_true(status.visible and status.text.contains("konnte nicht"), "Hinweis, dass der Bericht nicht gespeichert wurde: %s" % status.text)
	assert_true(ctx.session.is_over(), "Partie unberührt")
	ctx.history.simulate_failure = &""
	await navigate(shell, &"cockpit")
	await press(find_button(current_screen(shell), "OpenReportButton"))
	assert_true(_view(shell).is_report_open(), "zweiter Versuch: Bericht geöffnet")
	assert_eq(ctx.history.list().size(), 1, "jetzt gespeichert")


func test_language_switch_keeps_report_and_version() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	await press(find_button(screen, "HistoryGmButton"))
	await press(find_button(_dialog(shell), "ConfirmButton"))
	settings_of(shell).call("set_language", "en")
	await frames(3)
	assert_true(_view(shell).is_report_open() and _view(shell).current_version() == ReportText.GM, "Bericht und Fassung bleiben")
	var text := _report_text(shell)
	assert_true(text.contains("Final report (game master version)") and text.contains("Night 1") and text.contains("Winner: Werewolves"), "englischer Text: %s" % text.left(80))


func test_report_fits_and_pages_at_1024x768() -> void:
	for lang: String in ["de", "en"]:
		var made := await _shell_with_finished_game(SIZE_4_3, lang)
		if made.is_empty():
			return
		var shell: Control = made[0]
		var screen := current_screen(shell)
		var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
		await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
		await press(find_button(screen, "HistoryGmButton"))
		await press(find_button(_dialog(shell), "ConfirmButton"))
		await frames(3)
		var view := _view(shell)
		assert_true(inside(rect_of(view), viewport), "%s: Historie im Fenster (%s)" % [lang, rect_of(view)])
		for name: String in ["HistoryBackToListButton", "HistoryPublicButton", "HistoryGmButton", "HistoryExportButton", "HistoryDeleteButton"]:
			var c := find_node(screen, name) as Control
			assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s im Fenster" % [lang, name])
			assert_true(c.size.x >= 47.5 and c.size.y >= 47.5, "%s: %s mindestens 48×48" % [lang, name])
		assert_true(find_node(screen, "HistoryReportHost").find_children("*", "ScrollContainer", true, false).is_empty(), "%s: keine Scrollleiste" % lang)
		var host := find_node(screen, "HistoryReportHost") as Control
		var next := find_button(screen, "NextPageButton")
		assert_true(next != null, "%s: der Bericht blättert" % lang)
		var guard := 0
		while next != null and not next.disabled and guard < 20:
			await press(next)
			guard += 1
		var page := find_node(screen, "PageBody") as Control
		var last := page.get_child(page.get_child_count() - 1) as Control
		assert_true(inside(rect_of(last), rect_of(host), 1.0), "%s: letzte Zeile auf der letzten Seite sichtbar" % lang)
		await after_each()


## Bildschirm und öffentliche Exportdatei haben denselben freigegebenen Umfang (Zeilen des Bildschirms = Zeilen der Datei),
## die Datei ist UTF-8 und enthält Rollen zum Spielende, aber keine weiteren Geheimnisse.
func test_screen_and_public_export_have_the_same_scope() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var ctx: AppContext = made[1]
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	var on_screen := _view(shell).report_texts()
	await press(find_button(screen, "HistoryExportButton"))
	var path := ReportExport.path_for(ctx.exports_dir, ctx.history.get_entry("ui-bericht")["report"], ReportText.PUBLIC)
	var exported := FileAccess.get_file_as_bytes(path).get_string_from_utf8()
	var file_lines: Array[String] = []
	for line: String in exported.split("
"):
		if line != "" and not line.begins_with("=") and not line.begins_with("-"):
			file_lines.append(line)
	assert_eq(file_lines, on_screen, "gleiche Zeilen auf dem Bildschirm und in der Datei")
	assert_true(exported.contains("Dörte: Amalia †") and exported.contains("Sieger: Werwölfe"), "Datei nennt Rollen und Sieger")
	for secret: String in ["Rudelangriff", "ursprünglich", "Spielleiterkorrektur"]:
		assert_false(exported.contains(secret), "Datei ohne %s" % secret)


## Nach Rückgängig der Siegbestätigung sind Rollen, Sieger und Siegbedingung in der Ansicht wieder gesperrt und der Export ist
## gesperrt; nach neuer Bestätigung ist die Freigabe wieder da. Die Rollen kommen aus dem neuen Abschluss, nicht aus dem alten.
func test_undo_locks_the_release_and_a_new_completion_replaces_the_old_roles() -> void:
	var made := await _shell_with_finished_game()
	if made.is_empty():
		return
	var shell: Control = made[0]
	var ctx: AppContext = made[1]
	assert_true(ctx.session.undo(), "Siegbestätigung zurückgenommen")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"history")
	var screen := current_screen(shell)
	await press(find_node(screen, "HistoryList").get_child(0) as BaseButton)
	var locked := _report_text(shell)
	for hidden: String in ["Rollen zum Spielende", "Blutwolf", "Detektiv", "Wahnsinniger Kutscher", "Siegbedingung:"]:
		assert_false(locked.contains(hidden), "gesperrt: %s nicht öffentlich" % hidden)
	assert_true(locked.contains("Dörte wurde hingerichtet"), "Chronik bleibt lesbar")
	assert_true(find_button(screen, "HistoryExportButton").disabled, "Export gesperrt")
	await press_blocked(find_button(screen, "HistoryExportButton"))
	assert_false(DirAccess.dir_exists_absolute(ctx.exports_dir) and not DirAccess.get_files_at(ctx.exports_dir).is_empty(), "keine Datei entstanden")
	# Spielweg ändern: andere Rolle für Person 6, danach neuer Abschluss.
	await navigate(shell, &"main_menu")
	assert_true(ctx.session.reject_win("Tisch spielt weiter").ok, "offener Sieg abgelehnt")
	assert_true(ctx.session.submit(CorrectionFixtures.gm("set_role", {"target_id": 6, "role_id": "dorfbewohner"}, "Karte vertauscht")).ok, "Rolle geändert")
	var next: Dictionary = ctx.session.cockpit_view()["next"]
	assert_eq(str(next["kind"]), "win_decision", "Sieg wird weiter vorgeschlagen")
	assert_true(ctx.session.confirm_win(int(next["candidates"][0]["id"])).ok, "Sieg erneut bestätigt")
	await navigate(shell, &"history")
	await press(find_node(current_screen(shell), "HistoryList").get_child(0) as BaseButton)
	var again := _report_text(shell)
	assert_true(again.contains("Fjörd: Dorfbewohner") and not again.contains("Wahnsinniger Kutscher"), "neue Rolle zum Spielende, keine alte")
	assert_false(find_button(current_screen(shell), "HistoryExportButton").disabled, "Export wieder frei")
	assert_eq(ctx.history.list().size(), 1, "derselbe Eintrag, kein zweiter")


## Ein schon gespeicherter Bericht ohne Rollen (unvollständig oder älter) wird nicht ergänzt: keine erfundene Rollenliste.
func test_stored_report_without_roles_is_not_filled_up() -> void:
	var ctx := _context(_paths())
	_win(ctx)
	var report: Dictionary = ctx.history.get_entry("ui-bericht")["report"].duplicate(true)
	report.erase("roles")
	var text := ReportText.plain_text(report, ReportText.PUBLIC)
	for line: Dictionary in ReportText.lines(report, ReportText.PUBLIC):
		assert_false(str(line["style"]) == "heading" and str(line["text"]) == "Rollen zum Spielende", "keine Rollenüberschrift ohne gespeicherte Rollen")
	assert_false(text.contains("Anna: Werwolf") or text.contains("Dörte: Amalia"), "keine erfundene Rollenzeile")
	assert_true(text.contains("Sieger: Werwölfe") and text.contains("Dörte wurde hingerichtet"), "übrige Angaben bleiben")
