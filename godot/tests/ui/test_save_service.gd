extends UiTestCase
## Spielstände auf dem Datenträger (SaveService, AppContext.autosave/resume): sicheres Schreiben mit
## Sicherung, Wiederaufnahme nach Abbruch an jedem Schritt, beschädigte Dateien werden beiseitegelegt
## statt überschrieben, keine falsche Erfolgsmeldung, offene mehrstufige Prompts überleben einen
## Neustart, identisches Replay. Jeder Test nutzt ein eigenes temporäres Verzeichnis.

const ROLES := ["werwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "dorfbewohner", "dorfbewohner"]


func _context() -> AppContext:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	return ctx


## Neuer App-Start mit demselben Speicherort (neue Sitzung, neue Dienste).
func _restart(old: AppContext) -> AppContext:
	var ctx := AppContext.new()
	ctx.saves.base_dir = old.saves.base_dir
	return ctx


func _start(ctx: AppContext) -> void:
	assert_true(ctx.session.submit(Fixtures.start_roles(ROLES, 4)).ok, "Start")


func _files(ctx: AppContext) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(ctx.saves.base_dir)
	if d != null:
		for f: String in d.get_files():
			out.append(f)
	out.sort()
	return out


func test_autosave_after_every_accepted_command() -> void:
	var ctx := _context()
	var statuses: Array = []
	ctx.saves.status_changed.connect(func(st: Dictionary) -> void: statuses.append(st))
	_start(ctx)
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	assert_eq(statuses.size(), 3, "ein Speichervorgang je angenommenem Befehl")
	assert_true(statuses.all(func(st: Dictionary) -> bool: return bool(st["ok"])), "alle gespeichert")
	ctx.session.answer_targets([2])  # abgelehnt: Rudel-Prompt ist noch nicht offen
	assert_eq(statuses.size(), 3, "abgelehnter Befehl speichert nicht")
	var loaded := ctx.saves.load_game(ctx.session.round_id())
	assert_true(bool(loaded["ok"]) and str(loaded["recovered"]) == "", "Datei lädt ohne Rückfall")
	var other := GameSession.new()
	assert_eq(other.load_text(str(loaded["core"])), &"", "Stand übernommen")
	assert_eq(other.state_hash(), ctx.session.state_hash(), "gleicher fachlicher Hash")
	assert_eq(other.event_log(), ctx.session.event_log(), "identische Ereignisse per Replay")


func test_resume_open_multistage_prompt_after_restart() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	ctx.session.begin_next_step()
	ctx.session.answer_targets([6])
	ctx.session.begin_next_step()
	ctx.session.answer_choice(false)  # Waldhexe: kein Heiltrank → Stufe Gift offen
	var before: Dictionary = ctx.session.cockpit_view()["next"]
	assert_eq(str(before["stage"]), "poison", "mitten in der Waldhexen-Kette")
	var fresh := _restart(ctx)
	var resumed := fresh.resume(ctx.session.round_id())
	assert_true(bool(resumed["ok"]), "Wiederaufnahme")
	var after: Dictionary = fresh.session.cockpit_view()["next"]
	assert_eq([str(after["kind"]), int(after["prompt_id"]), str(after["stage"])], ["prompt", int(before["prompt_id"]), "poison"], "offener Prompt mit Teilantwort")
	assert_eq(fresh.session.state_hash(), ctx.session.state_hash(), "gleicher Hash")
	assert_true(fresh.session.answer_choice(true).ok, "Kette geht weiter")
	assert_true(bool(fresh.saves.last_status["ok"]), "nach der Wiederaufnahme wird weiter gespeichert")


func test_failed_write_keeps_last_good_file_and_reports_error() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	var path := ctx.saves.path_for(ctx.session.round_id())
	var good := FileAccess.get_file_as_string(path)
	for failure: StringName in [&"write", &"verify", &"backup"]:
		ctx.saves.simulate_failure = failure
		var statuses: Array = []
		var cb := func(st: Dictionary) -> void: statuses.append(st)
		ctx.saves.status_changed.connect(cb)
		var r := ctx.autosave()
		ctx.saves.status_changed.disconnect(cb)
		assert_false(bool(r["ok"]), "%s: kein Erfolg gemeldet" % failure)
		assert_true(statuses.size() == 1 and not bool(statuses[0]["ok"]), "%s: Fehler signalisiert" % failure)
		assert_eq(FileAccess.get_file_as_string(path), good, "%s: letzte intakte Datei unverändert" % failure)
	ctx.saves.simulate_failure = &""
	assert_true(bool(ctx.autosave()["ok"]), "danach wieder speicherbar")


func test_interrupted_swap_is_completed_on_load() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	ctx.saves.simulate_failure = &"swap"
	ctx.session.answer_targets([5])  # Autosave bricht nach dem Sichern der alten Datei ab
	assert_false(bool(ctx.saves.last_status["ok"]), "Abbruch gemeldet")
	var path := ctx.saves.path_for(ctx.session.round_id())
	assert_false(FileAccess.file_exists(path), "Datei fehlt (Abbruch zwischen Sichern und Einsetzen)")
	assert_true(FileAccess.file_exists(path + ".tmp") and FileAccess.file_exists(path + ".bak"), "neue Fassung und Sicherung liegen vor")
	var fresh := _restart(ctx)
	var resumed := fresh.resume(ctx.session.round_id())
	assert_true(bool(resumed["ok"]) and str(resumed["recovered"]) == "tmp", "neueste vollständige Fassung eingesetzt")
	assert_eq(fresh.session.state_hash(), ctx.session.state_hash(), "letzter angenommener Befehl erhalten")
	assert_true(FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".tmp"), "Datei wiederhergestellt")


func test_incomplete_tmp_is_set_aside_and_main_file_used() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	var path := ctx.saves.path_for(ctx.session.round_id())
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	f.store_string("{\"format\": \"grimmhain-app-save\", \"core\": \"{abgeschnitt")
	f.close()
	var loaded := ctx.saves.load_game(ctx.session.round_id())
	assert_true(bool(loaded["ok"]) and str(loaded["recovered"]) == "", "intakte Datei geladen")
	assert_eq((loaded["set_aside"] as Array).size(), 1, "unvollständige Fassung beiseitegelegt")
	assert_true(FileAccess.file_exists(str(loaded["set_aside"][0])), "nichts gelöscht")


func test_corrupt_file_is_never_overwritten_and_backup_is_used() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	var path := ctx.saves.path_for(ctx.session.round_id())
	var corrupt := FileAccess.get_file_as_string(path).replace("schutzengel", "schutzengxl")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(corrupt)
	f.close()
	var fresh := _restart(ctx)
	var resumed := fresh.resume(ctx.session.round_id())
	assert_true(bool(resumed["ok"]) and str(resumed["recovered"]) == "backup", "Rückfall auf die Sicherung")
	var aside: Array = resumed["set_aside"]
	assert_true(aside.size() == 1 and FileAccess.get_file_as_string(str(aside[0])) == corrupt, "beschädigte Datei unverändert beiseitegelegt")
	assert_eq(int(fresh.session.view()["command_count"]), 2, "Stand der Sicherung (ein Befehl zurück)")
	assert_true(fresh.session.answer_targets([5]).ok, "weiterspielen")
	assert_true(bool(fresh.saves.last_status["ok"]), "neuer Stand gespeichert")
	assert_eq(FileAccess.get_file_as_string(str(aside[0])), corrupt, "beiseitegelegte Datei bleibt erhalten")


func test_all_copies_corrupt_reports_error_without_deleting() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	var path := ctx.saves.path_for(ctx.session.round_id())
	for p: String in [path, path + ".bak"]:
		var f := FileAccess.open(p, FileAccess.WRITE)
		f.store_string("kaputt")
		f.close()
	var fresh := _restart(ctx)
	var resumed := fresh.resume(ctx.session.round_id())
	assert_false(bool(resumed["ok"]), "nicht ladbar")
	assert_false(bool(fresh.session.view()["has_game"]), "Sitzung bleibt leer")
	assert_true(FileAccess.file_exists(path + ".bak"), "Sicherung nicht gelöscht")
	assert_true(_files(ctx).any(func(n: String) -> bool: return n.contains(".corrupt-")), "beschädigte Datei beiseitegelegt")


func test_list_shows_public_summary_only_and_discard_renames() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	var games := ctx.saves.list()
	assert_eq(games.size(), 1, "eine Partie")
	var summary: Dictionary = games[0]["summary"]
	assert_eq(summary["names"], ["A", "B", "C", "D", "E", "F", "G"], "Namen in Sitzreihenfolge")
	var text := JSON.stringify(summary)
	for role: String in ROLES:
		assert_false(text.contains(role), "Zusammenfassung ohne Rolle %s" % role)
	var moved := ctx.saves.discard(ctx.session.round_id())
	assert_true(moved.size() >= 1 and moved.all(func(p: String) -> bool: return FileAccess.file_exists(p)), "umbenannt, nicht gelöscht")
	assert_eq(ctx.saves.list().size(), 0, "nicht mehr in der Liste")


# --- Oberfläche ---------------------------------------------------------------------------------------

func test_continue_screen_resumes_saved_game_after_restart() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var dir := ctx.saves.base_dir
	_start(ctx)
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	var hash_before := ctx.session.state_hash()
	var round := ctx.session.round_id()
	# Neustart der App: alte Shell entfernen (Speicherort bleibt), neue Shell mit demselben Speicherort.
	_spawned.erase(shell)
	shell.get_parent().remove_child(shell)
	shell.free()
	await frames(2)
	shell = await spawn_shell()
	(context_of(shell) as AppContext).saves.base_dir = dir
	await navigate(shell, &"main_menu")
	await navigate(shell, &"continue")
	var screen := current_screen(shell)
	assert_false((find_node(screen, "EmptyStateLabel") as Control).is_visible_in_tree(), "kein leerer Zustand")
	var slot_text := ""
	for c: Control in text_controls(screen):
		slot_text += text_of(c) + "\n"
	assert_true(slot_text.contains("A, B, C, D, E"), "Namen in der Liste: %s" % slot_text)
	for role: String in ["Werwolf", "Schutzengel", "Waldhexe", "Orakel"]:
		assert_false(slot_text.contains(role), "keine Rolle in der Liste (%s)" % role)
	await press(find_button(screen, "ResumeButton_%s" % round))
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit geöffnet")
	var session := session_of(shell) as GameSession
	assert_eq(session.state_hash(), hash_before, "gleicher Stand")
	assert_eq(str(session.cockpit_view()["next"]["kind"]), "begin_step", "an derselben Stelle")
	var status := find_node(current_screen(shell), "SaveStatusLabel") as Label
	await press(find_button(current_screen(shell), "BeginStepButton"))
	assert_eq(status.text, "Gespeichert", "Speicheranzeige nach dem nächsten Befehl")


func test_cockpit_shows_save_error_without_false_success() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	_start(ctx)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	ctx.saves.simulate_failure = &"write"
	await press(find_button(current_screen(shell), "StartNightButton"))
	var status := find_node(current_screen(shell), "SaveStatusLabel") as Label
	assert_eq(status.text, "Fehler: nicht gespeichert", "Fehler sichtbar, keine Erfolgsanzeige")
	var toast := find_node(shell.call("get_toast") as Node, "MessageLabel") as Label
	assert_true(toast.text.begins_with("Fehler: Die Partie konnte nicht gespeichert werden"), "Statusmeldung: %s" % toast.text)
	ctx.saves.simulate_failure = &""
	await press(find_button(current_screen(shell), "BeginStepButton")) if find_node(current_screen(shell), "BeginStepButton") != null else null
	ctx.session.answer_targets([5])
	await frames(2)
	assert_eq(status.text, "Gespeichert", "nach erfolgreichem Speichern wieder grün")


func test_discard_from_continue_screen_asks_and_keeps_files() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	_start(ctx)
	var round := ctx.session.round_id()
	await navigate(shell, &"main_menu")
	await navigate(shell, &"continue")
	await press(find_button(current_screen(shell), "DiscardButton_%s" % round))
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog.call("is_open"), "Rückfrage vor dem Verwerfen")
	await press(find_node(dialog, "CancelButton") as BaseButton)
	assert_eq(ctx.saves.list().size(), 1, "Abbrechen verwirft nichts")
	await press(find_button(current_screen(shell), "DiscardButton_%s" % round))
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_eq(ctx.saves.list().size(), 0, "aus der Liste entfernt")
	assert_true(_files(ctx).any(func(n: String) -> bool: return n.contains(".discarded-")), "Datei umbenannt erhalten")
	assert_false(bool(ctx.session.view()["has_game"]), "laufende Partie geschlossen")
	assert_true((find_node(current_screen(shell), "EmptyStateLabel") as Control).is_visible_in_tree(), "leerer Zustand")
