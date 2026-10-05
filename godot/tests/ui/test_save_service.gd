extends UiTestCase
## Spielstände auf dem Datenträger (SaveService, AppContext.autosave/resume): sicheres Schreiben mit
## Sicherung, Wiederaufnahme nach Abbruch an jedem Schritt, beschädigte Dateien werden beiseitegelegt
## statt überschrieben, keine falsche Erfolgsmeldung, offene mehrstufige Prompts überleben einen
## Neustart, identisches Replay. Jeder Test nutzt ein eigenes temporäres Verzeichnis.

const ROLES := ["werwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "amalia", "detektiv"]


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


## Paket 4: Nach einem abgebrochenen Speichern liegt der neueste vollständige Stand nur in `.tmp`. Scheitert das
## nächste Speichern (Prüfung), darf dieser Stand nicht verloren gehen; sonst lädt der Neustart einen älteren.
func test_failure_after_interrupted_save_keeps_the_newest_complete_state() -> void:
	for first: StringName in [&"swap", &"backup"]:
		var ctx := _context()
		_start(ctx)
		ctx.session.start_night()
		ctx.saves.simulate_failure = first
		ctx.session.answer_targets([5])  # Stand N liegt vollständig in `.tmp`
		assert_false(bool(ctx.saves.last_status["ok"]), "%s: Abbruch gemeldet" % first)
		var hash_n := ctx.session.state_hash()
		ctx.saves.simulate_failure = &"verify"
		ctx.session.begin_next_step()  # Stand N+1: Prüfung scheitert
		assert_false(bool(ctx.saves.last_status["ok"]), "%s: zweiter Fehler gemeldet" % first)
		var fresh := _restart(ctx)
		var resumed := fresh.resume(ctx.session.round_id())
		assert_true(bool(resumed["ok"]), "%s: ladbar" % first)
		assert_eq(fresh.session.state_hash(), hash_n, "%s: neuester vollständiger Stand N, nicht die ältere Sicherung" % first)
		assert_ne(str(resumed.get("recovered", "")), "backup", "%s: kein Rückfall auf die Sicherung" % first)


## Fehlendes Verzeichnis wird angelegt; ein nicht anlegbares Verzeichnis (eine Datei steht im Weg) ist ein echter
## Schreibfehler, unabhängig von Kontorechten. Danach kann in ein gültiges Verzeichnis gespeichert werden.
func test_missing_directory_is_created_and_blocked_directory_reports_error() -> void:
	var ctx := _context()
	var root := ctx.saves.base_dir
	ctx.saves.base_dir = root.path_join("neu/unter")
	_start(ctx)
	assert_true(bool(ctx.saves.last_status["ok"]) and FileAccess.file_exists(ctx.saves.path_for(ctx.session.round_id())), "fehlendes Verzeichnis angelegt")
	var blocker := root.path_join("blockiert")
	var f := FileAccess.open(blocker, FileAccess.WRITE)
	f.store_string("keine Mappe")
	f.close()
	ctx.saves.base_dir = blocker.path_join("saves")
	var r := ctx.autosave()
	assert_false(bool(r["ok"]), "kein Erfolg gemeldet")
	assert_eq(str(r["error"]), "no_directory", "Fehlergrund")
	assert_eq(FileAccess.get_file_as_string(blocker), "keine Mappe", "im Weg stehende Datei unverändert")
	ctx.saves.base_dir = root.path_join("neu/unter")
	assert_true(bool(ctx.autosave()["ok"]), "nach Behebung wieder speicherbar")
	for p: String in [root.path_join("neu/unter").path_join(ctx.saves.PREFIX + ctx.session.round_id() + ctx.saves.EXT), root.path_join("neu/unter").path_join(ctx.saves.PREFIX + ctx.session.round_id() + ctx.saves.EXT + ".bak")]:
		DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(root.path_join("neu/unter"))
	DirAccess.remove_absolute(root.path_join("neu"))


## Wiederholtes Laden und Wiederherstellen wendet keinen Befehl doppelt an und liefert immer denselben Stand.
func test_repeated_resume_never_applies_commands_twice() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	ctx.saves.simulate_failure = &"swap"
	ctx.session.answer_targets([5])
	var expected := [ctx.session.state_hash(), ctx.session.commands().size(), ctx.session.event_log()]
	var recovered: Array = []
	for i: int in 3:
		var fresh := _restart(ctx)
		var resumed := fresh.resume(ctx.session.round_id())
		recovered.append(str(resumed.get("recovered", "")))
		assert_eq([fresh.session.state_hash(), fresh.session.commands().size(), fresh.session.event_log()], expected, "Laden %d: gleicher Stand" % i)
		assert_eq(fresh.resume(ctx.session.round_id())["ok"], true, "Laden %d: erneut in derselben Sitzung" % i)
		assert_eq(fresh.session.commands().size(), int(expected[1]), "Laden %d: keine doppelten Befehle" % i)
	assert_eq(recovered, ["tmp", "", ""], "Unterbrechung nur einmal eingesetzt, danach reguläre Datei")


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


## CM-02/CM-03: Ein Umschlag mit falsch typisiertem `saved_at` oder `summary` lässt die Liste nicht abbrechen.
func test_list_survives_wrong_typed_envelope_fields() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	var path := ctx.saves.path_for(ctx.session.round_id())
	var env: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	env["saved_at"] = [1, 2]
	env["summary"] = "kein Dictionary"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(env))
	file.close()
	var games := ctx.saves.list()
	assert_eq(games.size(), 1, "die Partie bleibt in der Liste")
	if games.size() == 1:
		assert_true(games[0]["summary"] is Dictionary, "Zusammenfassung ist ein Dictionary")
		assert_eq(games[0]["saved_at"], 0, "saved_at fällt auf 0 zurück")


# --- Spielstand anderer Version (DI-01, Schema 13) -----------------------------------------------------

## Schreibt die laufende Partie mit Schema 12 (Stand vor der Wiederbelebungsrunde) auf den Datenträger.
func _write_old_schema(ctx: AppContext, schema: int = 12) -> Dictionary:
	var doc: Dictionary = JSON.parse_string(ctx.session.save_text())
	doc["schema_version"] = schema
	if schema == 13:
		(doc["state"] as Dictionary).erase("roles_shown")  # Schema 13 kannte die Rollenanzeige noch nicht
	var old_text := JSON.stringify(doc)
	assert_true(bool(ctx.saves.save(ctx.session.round_id(), old_text, {"player_names": ["A", "B", "C", "D", "E"], "player_count": 5})["ok"]), "Altstand geschrieben")
	return {"text": old_text, "round": ctx.session.round_id()}


func test_old_schema_save_is_reported_incompatible_and_left_untouched() -> void:
	var ctx := _context()
	_start(ctx)
	var old := _write_old_schema(ctx)
	var path := ctx.saves.path_for(str(old["round"]))
	var bytes_before := FileAccess.get_file_as_string(path)
	var entries := ctx.saves.list()
	assert_eq(entries.size(), 1, "in der Liste")
	assert_true(bool(entries[0]["readable"]) and not bool(entries[0]["compatible"]), "lesbar, aber nicht kompatibel")
	assert_eq(int(entries[0]["schema"]), 12, "gefundenes Schema")
	var loaded := ctx.saves.load_game(str(old["round"]))
	assert_false(bool(loaded["ok"]), "nicht ladbar")
	assert_eq(str(loaded["error"]), "incompatible", "Fehler benennt die Version")
	assert_eq(FileAccess.get_file_as_string(path), bytes_before, "Datei unverändert")
	assert_false(_files(ctx).any(func(n: String) -> bool: return n.contains(".corrupt-")), "nichts beiseitegelegt")
	assert_true(ctx.saves.discard(str(old["round"])).size() > 0, "Verwerfen bleibt möglich (umbenannt, nicht gelöscht)")
	assert_true(_files(ctx).any(func(n: String) -> bool: return n.contains(".discarded-")), "Datei erhalten")


## Schema 13 (vor der Rollenanzeige): dieselbe Behandlung wie jede ältere Version, keine Migration, Datei bleibt erhalten.
func test_schema_13_save_is_incompatible_and_left_untouched() -> void:
	var ctx := _context()
	_start(ctx)
	var old := _write_old_schema(ctx, 13)
	var path := ctx.saves.path_for(str(old["round"]))
	var bytes_before := FileAccess.get_file_as_string(path)
	var entries := ctx.saves.list()
	assert_true(bool(entries[0]["readable"]) and not bool(entries[0]["compatible"]), "lesbar, aber nicht kompatibel")
	assert_eq(int(entries[0]["schema"]), 13, "gefundenes Schema")
	assert_eq(int(entries[0]["expected"]), GameState.SCHEMA_VERSION, "erwartetes Schema")
	var loaded := ctx.saves.load_game(str(old["round"]))
	assert_eq(str(loaded["error"]), "incompatible", "als inkompatibel gemeldet, nicht als beschädigt")
	assert_eq(FileAccess.get_file_as_string(path), bytes_before, "Datei unverändert")
	assert_false(_files(ctx).any(func(n: String) -> bool: return n.contains(".corrupt-")), "nichts beiseitegelegt")


const PE07_FIXTURE := "res://tests/saves/pe07-core-0.13-duplicate-roles.json"


## Kopiert den echten Spielstand der Regelversion 0.13 (mit doppelten Startrollen) bytegleich in das Testverzeichnis.
func _install_pe07_fixture(ctx: AppContext) -> String:
	var bytes := FileAccess.get_file_as_bytes(PE07_FIXTURE)
	assert_true(bytes.size() > 0, "Fixture lesbar")
	DirAccess.make_dir_recursive_absolute(ctx.saves.base_dir)
	var path := ctx.saves.path_for("test-round")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
	return path


## PE-07: Ein Stand mit doppelten Startrollen (Regelversion 0.13, Schema 14) ist seit den Totenreichkarten (Schema 15, Regeln 0.15, seit DA-93 0.16, Loki-Hinweis 0.17, Rivalen 0.18)
## eine ältere Version, keine beschädigte Datei: keine Migration, keine neue Verteilung, Datei bleibt bytegleich, nichts beiseitegelegt.
func test_pe07_rules_0_13_save_is_incompatible_and_left_untouched() -> void:
	var ctx := _context()
	var path := _install_pe07_fixture(ctx)
	var bytes_before := FileAccess.get_file_as_bytes(path)
	var entries := ctx.saves.list()
	assert_eq(entries.size(), 1, "in der Liste")
	assert_true(bool(entries[0]["readable"]) and not bool(entries[0]["compatible"]), "lesbar, aber nicht kompatibel")
	assert_eq(int(entries[0]["schema"]), 14, "gefundenes Schema")
	assert_eq(str(entries[0]["found_label"]), "Schema 14, 0.13", "gefundene Version benannt")
	assert_eq(str(entries[0]["expected_label"]), "Schema 15, 0.18", "erwartete Version benannt")
	var loaded := ctx.saves.load_game("test-round")
	assert_false(bool(loaded["ok"]), "nicht ladbar")
	assert_eq(str(loaded["error"]), "incompatible", "als andere Version gemeldet, nicht als beschädigt")
	assert_eq((loaded["set_aside"] as Array).size(), 0, "nichts beiseitegelegt")
	assert_eq(FileAccess.get_file_as_bytes(path), bytes_before, "Datei bytegleich")
	assert_eq(_files(ctx), ["game-test-round.json"], "keine weitere Datei (keine Migration, kein .corrupt-, kein Löschen)")
	var decoded := StateCodec.decode(str(JSON.parse_string(bytes_before.get_string_from_utf8()).get("core", "")))
	assert_eq(str(decoded.error), "unsupported_schema_version", "der Kern lehnt die ältere Version ab, ohne neu zu verteilen")


const CORE_014_FIXTURE := "res://tests/saves/core-0.14-night-and-day.json"


## Totenreichkarten (Schema 15, Regeln 0.15, seit DA-93 0.16, Loki-Hinweis 0.17, Rivalen 0.18): Ein echter Stand der Regelversion 0.14 mit Nacht und Tag bleibt unberührt und wird als
## ältere Version gemeldet, nicht als beschädigt; es gibt keine Migration und keine Neuverteilung.
func test_core_0_14_save_is_incompatible_and_left_untouched() -> void:
	var ctx := _context()
	var bytes := FileAccess.get_file_as_bytes(CORE_014_FIXTURE)
	assert_true(bytes.size() > 0, "Fixture lesbar")
	DirAccess.make_dir_recursive_absolute(ctx.saves.base_dir)
	var path := ctx.saves.path_for("test-round")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
	var entries := ctx.saves.list()
	assert_eq(entries.size(), 1, "in der Liste")
	assert_true(bool(entries[0]["readable"]) and not bool(entries[0]["compatible"]), "lesbar, aber nicht kompatibel")
	assert_eq(str(entries[0]["found_label"]), "Schema 14, 0.14", "gefundene Version benannt")
	assert_eq(str(entries[0]["expected_label"]), "Schema 15, 0.18", "erwartete Version benannt")
	var loaded := ctx.saves.load_game("test-round")
	assert_false(bool(loaded["ok"]), "nicht ladbar")
	assert_eq(str(loaded["error"]), "incompatible", "als andere Version gemeldet, nicht als beschädigt")
	assert_eq((loaded["set_aside"] as Array).size(), 0, "nichts beiseitegelegt")
	assert_eq(FileAccess.get_file_as_bytes(path), bytes, "Datei bytegleich")
	assert_eq(_files(ctx), ["game-test-round.json"], "keine weitere Datei")


func test_continue_screen_shows_pe07_save_as_other_version() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var path := _install_pe07_fixture(ctx)
	var bytes_before := FileAccess.get_file_as_bytes(path)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"continue")
	var screen := current_screen(shell)
	var note := find_node(screen, "IncompatibleLabel") as Label
	assert_true(note != null and note.is_visible_in_tree(), "Hinweis sichtbar")
	assert_true(note != null and note.text.contains("anderen Version") and note.text.contains("0.13") and note.text.contains("0.18"), "Text nennt andere Version, gespeichert und erwartet: %s" % (note.text if note != null else ""))
	assert_true((find_button(screen, "ResumeButton_test-round") as BaseButton).disabled, "Fortsetzen gesperrt")
	assert_true(find_button(screen, "DiscardButton_test-round") != null, "Verwerfen weiter möglich")
	assert_eq(FileAccess.get_file_as_bytes(path), bytes_before, "Datei bytegleich")
	assert_false(_files(ctx).any(func(n: String) -> bool: return n.contains(".corrupt-")), "nichts beiseitegelegt")


func test_continue_screen_disables_resume_for_old_schema_save() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	_start(ctx)
	var old := _write_old_schema(ctx)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"continue")
	var screen := current_screen(shell)
	var note := find_node(screen, "IncompatibleLabel") as Control
	assert_true(note != null and note.is_visible_in_tree(), "Hinweis sichtbar")
	assert_true((find_button(screen, "ResumeButton_%s" % old["round"]) as BaseButton).disabled, "Fortsetzen gesperrt")
	assert_true(find_button(screen, "DiscardButton_%s" % old["round"]) != null, "Verwerfen weiter möglich")
	assert_false(_files(ctx).any(func(n: String) -> bool: return n.contains(".corrupt-")), "nichts beiseitegelegt")


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
	# Der Schritt zeigt seine Vorschau ohne „Schritt beginnen“; die feste Zielwahl wird beim Tippen sofort übernommen.
	var shown := effective_of(session.cockpit_view()["next"])
	await press(find_node(current_screen(shell), "SeatRing").call("token_for", int((shown["allowed_ids"] as Array)[0])) as BaseButton)
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


## Paket 4: Nach einem Speicherfehler kann ohne neuen Spielbefehl erneut gespeichert werden (etwa nach Spielende).
## Kein automatisches Wiederholen: jeder Versuch geht von einem Tippen aus. Die Partie bleibt dabei unverändert bedienbar.
func test_retry_save_button_after_failure_without_automatic_loop() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	_start(ctx)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var retry := find_node(current_screen(shell), "RetrySaveButton") as BaseButton
	assert_true(retry != null and not retry.is_visible_in_tree(), "ohne Fehler kein Button „Erneut speichern“")
	var attempts: Array = []
	ctx.saves.status_changed.connect(func(st: Dictionary) -> void: attempts.append(st))
	ctx.saves.simulate_failure = &"write"
	await press(find_button(current_screen(shell), "StartNightButton"))
	await frames(3)
	assert_eq(attempts.size(), 1, "genau ein Speicherversuch, keine automatische Wiederholung")
	assert_true(retry.is_visible_in_tree() and not retry.disabled, "Erneut speichern angeboten")
	var hash := ctx.session.state_hash()
	await press(retry)
	assert_eq(attempts.size(), 2, "ein Versuch je Tippen")
	assert_eq((find_node(current_screen(shell), "SaveStatusLabel") as Label).text, "Fehler: nicht gespeichert", "Fehler bleibt sichtbar")
	assert_true(retry.is_visible_in_tree(), "weiter angeboten")
	assert_eq(ctx.session.state_hash(), hash, "Partie unverändert, nicht zurückgesetzt")
	var shown := effective_of(ctx.session.cockpit_view()["next"])
	var token := find_node(current_screen(shell), "SeatRing").call("token_for", int((shown["allowed_ids"] as Array)[0])) as BaseButton
	assert_false(token.disabled, "Partie weiter bedienbar")
	ctx.saves.simulate_failure = &""
	await press(retry)
	assert_eq((find_node(current_screen(shell), "SaveStatusLabel") as Label).text, "Gespeichert", "nach Behebung gespeichert")
	assert_false(retry.is_visible_in_tree(), "Button verschwindet nach Erfolg")
	var loaded := ctx.saves.load_game(ctx.session.round_id())
	var other := GameSession.new()
	assert_eq(other.load_text(str(loaded["core"])), &"", "gespeicherter Stand ladbar")
	assert_eq(other.state_hash(), hash, "gespeichert ist der aktuelle Stand")


## Die Beenden-Rückfrage verspricht nur dann einen gespeicherten Stand, wenn das letzte Speichern gelang.
func test_quit_dialog_warns_when_the_running_game_is_not_saved() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var dialog := shell.call("get_dialog") as Control
	var message := find_node(dialog, "MessageLabel") as Label
	shell.call("request_quit")
	assert_true(message.text.contains("gespeichert") and not message.text.contains("nicht gespeichert"), "ohne Partie: Standardtext (%s)" % message.text)
	dialog.call("cancel")
	_start(ctx)
	ctx.saves.simulate_failure = &"write"
	ctx.autosave()
	shell.call("request_quit")
	assert_true(message.text.contains("nicht gespeichert"), "Warnung bei ungespeichertem Stand: %s" % message.text)
	await press(find_node(dialog, "CancelButton") as BaseButton)
	assert_eq(quit_calls, 0, "Abbrechen beendet nicht")
	ctx.saves.simulate_failure = &""
	ctx.autosave()
	shell.call("request_quit")
	assert_false(message.text.contains("nicht gespeichert"), "nach erfolgreichem Speichern keine Warnung")
	dialog.call("cancel")


## Mobilgerät: System-Zurück in der Wurzel beendet sofort, außer der letzte Stand der laufenden Partie ist nicht
## gespeichert. Dann warnt dieselbe Rückfrage; Abbrechen erhält die Sitzung, Bestätigen beendet genau einmal.
func test_mobile_back_at_root_warns_when_unsaved() -> void:
	var platform := load_script(PLATFORM_SCRIPT)
	platform.call("set_override", &"mobile")
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var dialog := shell.call("get_dialog") as Control
	var message := find_node(dialog, "MessageLabel") as Label
	_start(ctx)
	ctx.saves.simulate_failure = &"write"
	ctx.autosave()
	var hash := ctx.session.state_hash()
	await navigate(shell, &"start")
	await go_back(shell)
	assert_eq(quit_calls, 0, "ungespeichert: nicht sofort beendet")
	assert_true(dialog.call("is_open") and message.text.contains("nicht gespeichert"), "Warnung: %s" % message.text)
	await press(find_node(dialog, "CancelButton") as BaseButton)
	assert_eq(quit_calls, 0, "Abbrechen beendet nicht")
	assert_eq(ctx.session.state_hash(), hash, "Sitzung und Zustand erhalten")
	await go_back(shell)
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_eq(quit_calls, 1, "bewusstes Beenden genau einmal")
	# Nach erfolgreichem erneutem Speichern: bisheriges Plattformverhalten, sofort beenden.
	ctx.saves.simulate_failure = &""
	ctx.autosave()
	await go_back(shell)
	assert_eq(quit_calls, 2, "gespeichert: System-Zurück beendet sofort")
	assert_false(dialog.call("is_open"), "keine falsche Warnung")


## Zurück bei offenem Dialog oder in einer Unteransicht beendet auch mit ungespeichertem Stand nicht.
func test_mobile_back_in_dialog_or_sub_view_never_quits() -> void:
	var platform := load_script(PLATFORM_SCRIPT)
	platform.call("set_override", &"mobile")
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	_start(ctx)
	ctx.saves.simulate_failure = &"write"
	ctx.autosave()
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	await go_back(shell)
	assert_eq(quit_calls, 0, "Zurück im Cockpit beendet nicht")
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit behandelt Zurück selbst")
	assert_true((shell.call("get_dialog") as Control).call("is_open"), "Rückfrage „Partie verlassen“")
	await go_back(shell)
	assert_false((shell.call("get_dialog") as Control).call("is_open"), "Zurück schließt zuerst den Dialog")
	assert_eq(String(current_id(shell)), "cockpit", "weiter im Cockpit")
	await navigate(shell, &"settings")
	await go_back(shell)
	assert_ne(String(current_id(shell)), "settings", "Unteransicht führt zur Elternansicht")
	assert_eq(quit_calls, 0, "kein Beenden")


## Desktop: Fenster schließen (X, Alt+F4) ist ein freiwilliges Beenden und darf die Warnung nicht umgehen. Ohne
## Speicherfehler schließt es wie bisher sofort.
func test_window_close_request_warns_only_when_unsaved() -> void:
	var platform := load_script(PLATFORM_SCRIPT)
	platform.call("set_override", &"desktop")
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	var dialog := shell.call("get_dialog") as Control
	_start(ctx)
	assert_false(tree.is_auto_accept_quit(), "Schließen wird von der App behandelt")
	shell.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(quit_calls, 1, "gespeichert: Fenster schließt sofort")
	ctx.saves.simulate_failure = &"write"
	ctx.autosave()
	shell.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(quit_calls, 1, "ungespeichert: nicht sofort geschlossen")
	assert_true(dialog.call("is_open") and (find_node(dialog, "MessageLabel") as Label).text.contains("nicht gespeichert"), "Warnung")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_eq(quit_calls, 2, "bewusstes Schließen genau einmal")


## Rückfall auf die Sicherung: Die Meldung sagt, dass ein älterer Stand geladen wurde.
func test_backup_recovery_message_names_the_older_state() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	_start(ctx)
	ctx.session.start_night()
	var path := ctx.saves.path_for(ctx.session.round_id())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("kaputt")
	f.close()
	var round := ctx.session.round_id()
	ctx.session.reset()
	await navigate(shell, &"main_menu")
	await navigate(shell, &"continue")
	await press(find_button(current_screen(shell), "ResumeButton_%s" % round))
	var toast := find_node(shell.call("get_toast") as Node, "MessageLabel") as Label
	assert_true(toast.text.contains("älter"), "Meldung nennt den älteren Stand: %s" % toast.text)
	assert_eq(int((session_of(shell) as GameSession).view()["command_count"]), 1, "Stand der Sicherung geladen")


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


func test_corrupt_file_without_backup_reports_error_and_keeps_it() -> void:
	var ctx := _context()
	_start(ctx)  # erster Speicherstand: noch keine Sicherung
	var path := ctx.saves.path_for(ctx.session.round_id())
	assert_false(FileAccess.file_exists(path + ".bak"), "keine Sicherung vorhanden")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("kaputt")
	f.close()
	var fresh := _restart(ctx)
	var resumed := fresh.resume(ctx.session.round_id())
	assert_false(bool(resumed["ok"]), "nicht ladbar")
	assert_eq(str(resumed["error"]), "corrupt", "Fehlergrund")
	assert_false(bool(fresh.session.view()["has_game"]), "Sitzung bleibt leer")
	var aside: Array = resumed["set_aside"]
	assert_true(aside.size() == 1 and FileAccess.get_file_as_string(str(aside[0])) == "kaputt", "beschädigte Datei beiseitegelegt, nicht gelöscht")


func test_corrupt_backup_does_not_affect_intact_file() -> void:
	var ctx := _context()
	_start(ctx)
	ctx.session.start_night()
	var path := ctx.saves.path_for(ctx.session.round_id())
	var f := FileAccess.open(path + ".bak", FileAccess.WRITE)
	f.store_string("kaputt")
	f.close()
	var fresh := _restart(ctx)
	var resumed := fresh.resume(ctx.session.round_id())
	assert_true(bool(resumed["ok"]) and str(resumed["recovered"]) == "", "intakte Datei geladen")
	assert_eq(fresh.session.state_hash(), ctx.session.state_hash(), "gleicher Stand")
	assert_eq(FileAccess.get_file_as_string(path + ".bak"), "kaputt", "Sicherung beim Laden unverändert")


## Spielende mitten in der Nacht (Sieg nach Korrekturen bestätigt): Neustart, gleicher Zustand und
## Verlauf, Rückgängig öffnet die Entscheidung wieder und wird gespeichert.
func test_game_over_during_night_survives_restart_and_undo() -> void:
	var ctx := _context()
	assert_true(ctx.session.submit(Fixtures.start_roles(["werwolf", "blutwolf", "schutzengel", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"], 2)).ok, "Start")
	ctx.session.start_night()
	for id: int in [4, 5, 6]:
		assert_true(ctx.session.gm_correction({"kind": "kill", "target_id": id, "trigger_effects": false, "reason": "Test"}).ok, "Korrektur %d" % id)
	var next: Dictionary = ctx.session.cockpit_view()["next"]
	assert_eq([str(next["kind"]), str(ctx.session.view()["phase"])], ["win_decision", "NIGHT"], "Siegentscheidung in der Nacht")
	assert_true(ctx.session.confirm_win(int(next["candidates"][0]["id"])).ok, "Sieg bestätigt")
	var fresh := _restart(ctx)
	assert_true(bool(fresh.resume(ctx.session.round_id())["ok"]), "Wiederaufnahme nach Spielende")
	assert_eq(fresh.session.state_hash(), ctx.session.state_hash(), "gleicher Zustand")
	assert_eq(fresh.session.event_log(), ctx.session.event_log(), "gleicher Ereignisverlauf")
	assert_eq(str(fresh.session.cockpit_view()["next"]["kind"]), "game_over", "Spielende")
	assert_true(fresh.session.undo(), "Rückgängig nach Neustart")
	assert_eq(str(fresh.session.cockpit_view()["next"]["kind"]), "win_decision", "Entscheidung wieder offen")
	assert_true(bool(fresh.saves.last_status["ok"]), "Rückgängig gespeichert")
