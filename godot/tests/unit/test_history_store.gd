extends TestCase
## Partiehistorie (Paket D): HistoryStore (idempotentes Speichern, Ersetzen, Neustart, zurückgenommene Siegbestätigung,
## Löschen, Schreibfehler, defekte Dateien) und ReportExport (UTF-8-Datei, kein stilles Überschreiben, Fehler erhalten die
## vorhandene Datei). Nur temporäre Dateien unter user://, nie echte Nutzerdaten.

var _dirs: Array[String] = []


func _dir() -> String:
	var dir := "user://test-history-%d-%d" % [Time.get_ticks_usec(), _dirs.size()]
	_dirs.append(dir)
	return dir


func _cleanup() -> void:
	for dir: String in _dirs:
		var d := DirAccess.open(dir)
		if d != null:
			for f: String in d.get_files():
				DirAccess.remove_absolute(dir.path_join(f))
			DirAccess.remove_absolute(dir)
	_dirs.clear()


func _report(game_id: String, marker: String = "eins") -> Dictionary:
	return {"version": GameReport.VERSION, "game_id": game_id, "players": 6, "names": ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"], "nights": 2, "days": 2,
		"revival_round": false, "winner": {"side": "wolves", "reason_key": "wolf_parity", "reason_args": {}, "names": [], "co_names": []},
		"roles": [], "other_events": 0, "entries": [{"vis": "public", "kind": "night", "number": 1}, {"vis": "public", "kind": "win", "side": "wolves"}], "marker": marker}


# --- HistoryStore -------------------------------------------------------------------------------------------

func test_missing_file_is_an_empty_list_and_nothing_is_written() -> void:
	var store := HistoryStore.new(_dir() + "/history.json")
	assert_true(bool(store.load_from_disk()["ok"]), "fehlende Datei ist kein Fehler")
	assert_eq(store.list().size(), 0, "leer")
	assert_false(FileAccess.file_exists(store.path), "Laden schreibt nichts")
	_cleanup()


func test_save_is_idempotent_and_survives_a_restart() -> void:
	var path := _dir() + "/history.json"
	var store := HistoryStore.new(path)
	var first := store.save_report(_report("partie-1"))
	assert_true(bool(first["ok"]) and bool(first["created"]) and bool(first["changed"]), "erste Speicherung legt an")
	var modified := FileAccess.get_modified_time(path)
	var again := store.save_report(_report("partie-1"))
	assert_true(bool(again["ok"]), "gleicher Bericht: ok")
	assert_false(bool(again["changed"]), "gleicher Bericht: nichts geändert, keine Schreibaktion")
	assert_eq(FileAccess.get_modified_time(path), modified, "Datei nicht neu geschrieben")
	assert_eq(store.list().size(), 1, "kein Duplikat")
	var second := HistoryStore.new(path)
	assert_true(bool(second.load_from_disk()["ok"]), "neue Instanz lädt")
	assert_eq(second.list().size(), 1, "Eintrag nach Neustart")
	assert_false(bool(second.save_report(_report("partie-1"))["changed"]), "nach Neustart ebenfalls idempotent (Zahlenformat gleich)")
	var summary := second.list()[0]
	assert_eq(str(summary["game_id"]), "partie-1", "Partie-ID")
	assert_eq(summary["names"], ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"], "Namen mit Umlauten in Reihenfolge")
	assert_eq(str(summary["status"]), HistoryStore.STATUS_COMPLETED, "abgeschlossen")
	assert_eq(str(summary["side"]), "wolves", "Siegseite")
	_cleanup()


func test_recompletion_replaces_the_matching_report() -> void:
	var store := HistoryStore.new(_dir() + "/history.json")
	store.save_report(_report("a"))
	store.save_report(_report("b"))
	store.mark_reopened("a")
	var result := store.save_report(_report("a", "zwei"))
	assert_true(bool(result["ok"]) and bool(result["changed"]) and not bool(result["created"]), "erneuter Abschluss aktualisiert")
	assert_eq(store.list().size(), 2, "weiterhin zwei Einträge")
	assert_eq(str(store.get_entry("a")["status"]), HistoryStore.STATUS_COMPLETED, "wieder abgeschlossen")
	assert_eq(str(store.get_entry("a")["report"]["marker"]), "zwei", "Bericht ersetzt")
	assert_eq(str(store.get_entry("b")["report"]["marker"]), "eins", "anderer Bericht unverändert")
	_cleanup()


func test_reopen_marks_but_keeps_the_report_readable() -> void:
	var path := _dir() + "/history.json"
	var store := HistoryStore.new(path)
	store.save_report(_report("a"))
	assert_true(bool(store.mark_reopened("a")["changed"]), "als wieder laufend markiert")
	assert_false(bool(store.mark_reopened("a")["changed"]), "zweites Markieren ändert nichts")
	assert_true(bool(store.mark_reopened("gibt-es-nicht")["ok"]), "unbekannte Partie: nichts zu tun")
	assert_eq(str(store.list()[0]["status"]), HistoryStore.STATUS_REOPENED, "Status reopened")
	var reloaded := HistoryStore.new(path)
	reloaded.load_from_disk()
	assert_eq(str(reloaded.list()[0]["status"]), HistoryStore.STATUS_REOPENED, "Status nach Neustart")
	assert_false(reloaded.get_entry("a").is_empty(), "Bericht bleibt lesbar")
	_cleanup()


func test_delete_removes_only_the_chosen_report() -> void:
	var path := _dir() + "/history.json"
	var store := HistoryStore.new(path)
	store.save_report(_report("a"))
	store.save_report(_report("b"))
	assert_true(bool(store.delete("a")["ok"]), "gelöscht")
	assert_false(store.has("a"), "a weg")
	assert_true(store.has("b"), "b bleibt")
	assert_false(bool(store.delete("a")["ok"]), "unbekannter Bericht")
	var reloaded := HistoryStore.new(path)
	reloaded.load_from_disk()
	assert_eq(reloaded.list().size(), 1, "nach Neustart ein Eintrag")
	_cleanup()


func test_invalid_reports_are_rejected() -> void:
	var store := HistoryStore.new()
	for bad: Dictionary in [{}, {"game_id": "", "entries": [], "version": 1}, {"game_id": "x", "version": 1}, {"game_id": "x", "entries": [], "version": 99}]:
		var result := store.save_report(bad)
		assert_false(bool(result["ok"]), "abgelehnt: %s" % str(bad).left(40))
	assert_eq(store.list().size(), 0, "nichts gespeichert")


func test_write_failures_keep_the_last_valid_state() -> void:
	for step: StringName in [&"write", &"verify", &"backup", &"swap"]:
		var path := _dir() + "/history.json"
		var store := HistoryStore.new(path)
		store.save_report(_report("a"))
		store.simulate_failure = step
		var disk_before := FileAccess.get_file_as_string(path)
		assert_false(bool(store.save_report(_report("b"))["ok"]), "%s: neuer Bericht: Fehler gemeldet" % step)
		assert_false(bool(store.save_report(_report("a", "zwei"))["ok"]), "%s: Ersetzen: Fehler gemeldet" % step)
		assert_false(bool(store.mark_reopened("a")["ok"]), "%s: Markieren: Fehler gemeldet" % step)
		assert_false(bool(store.delete("a")["ok"]), "%s: Löschen: Fehler gemeldet" % step)
		assert_eq(store.list().size(), 1, "%s: Speicher unverändert" % step)
		assert_eq(str(store.get_entry("a")["report"]["marker"]), "eins", "%s: Bericht unverändert" % step)
		assert_eq(str(store.get_entry("a")["status"]), HistoryStore.STATUS_COMPLETED, "%s: Status unverändert" % step)
		if step != &"swap":
			assert_eq(FileAccess.get_file_as_string(path), disk_before, "%s: Datei unverändert" % step)
		store.simulate_failure = &""
		var reloaded := HistoryStore.new(path)
		assert_true(bool(reloaded.load_from_disk()["ok"]), "%s: neu ladbar" % step)
		assert_eq(reloaded.list().size(), 1, "%s: Bericht nach Neustart vorhanden" % step)
		assert_true(bool(store.save_report(_report("b"))["ok"]), "%s: danach wieder speicherbar" % step)
	_cleanup()


func test_corrupt_and_foreign_files_are_reported_and_set_aside() -> void:
	var dir := _dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + "/history.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ kaputt")
	file.close()
	var store := HistoryStore.new(path)
	var status := store.load_from_disk()
	assert_false(bool(status["ok"]), "defekte Datei nicht als erfolgreich gemeldet")
	assert_eq(str(status["error"]), "unreadable", "Fehler")
	assert_true(FileAccess.file_exists(path + ".corrupt"), "beiseitegelegt, nicht gelöscht")
	assert_true(bool(store.save_report(_report("a"))["ok"]), "danach normal speicherbar")
	assert_true(FileAccess.file_exists(path + ".corrupt"), "defekte Datei bleibt erhalten")
	var other := dir + "/neuer.json"
	file = FileAccess.open(other, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format": HistoryStore.FORMAT, "version": 99, "entries": []}))
	file.close()
	var newer := HistoryStore.new(other)
	assert_eq(str(newer.load_from_disk()["error"]), "newer_version", "neuere Version gemeldet")
	assert_true(FileAccess.file_exists(other + ".corrupt"), "unverändert beiseitegelegt")
	_cleanup()


func test_invalid_entries_are_skipped_and_counted() -> void:
	var dir := _dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + "/history.json"
	var good := {"game_id": "a", "status": "completed", "saved_at": 100, "report": _report("a")}
	var entries: Array = [good, {"game_id": "", "status": "completed", "saved_at": 1, "report": _report("")}, {"game_id": "b", "status": "seltsam", "saved_at": 1, "report": _report("b")},
		{"game_id": "c", "status": "completed", "saved_at": 1, "report": _report("anders")}, good, "kein Objekt"]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format": HistoryStore.FORMAT, "version": 1, "entries": entries}))
	file.close()
	var store := HistoryStore.new(path)
	var status := store.load_from_disk()
	assert_true(bool(status["ok"]), "Datei lesbar")
	assert_eq(int(status["skipped"]), 5, "fünf ungültige Einträge gezählt")
	assert_eq(store.list().size(), 1, "nur der gültige Eintrag")
	_cleanup()


func test_list_is_newest_first_and_memory_only_store_never_writes() -> void:
	var store := HistoryStore.new()
	store.save_report(_report("alt"))
	store._entries[0]["saved_at"] = 100
	store.save_report(_report("neu"))
	store._entries[1]["saved_at"] = 200
	assert_eq(str(store.list()[0]["game_id"]), "neu", "neueste zuerst")
	assert_true(bool(store.load_from_disk()["ok"]), "Laden ohne Pfad ist ein No-op")
	assert_eq(store.list().size(), 0, "Laden ohne Pfad leert die Liste")


# --- ReportExport -----------------------------------------------------------------------------------------------

func test_export_writes_utf8_and_names_the_version() -> void:
	var dir := _dir()
	var report := _report("partie/1:x")
	var result := ReportExport.export(dir, report, ReportText.PUBLIC)
	assert_true(bool(result["ok"]), "Export ok")
	assert_true(str(result["path"]).get_file().contains("oeffentlich"), "öffentliche Fassung im Dateinamen: %s" % str(result["path"]).get_file())
	assert_false(str(result["path"]).get_file().contains("/") or str(result["path"]).get_file().contains(":"), "Dateiname ohne Sonderzeichen der Partie-ID")
	var bytes := FileAccess.get_file_as_bytes(str(result["path"]))
	var text := bytes.get_string_from_utf8()
	assert_true(text.contains("Bärbel") and text.contains("Çelik") and text.contains("Fjörd"), "Umlaute und Sonderzeichen als UTF-8 lesbar")
	assert_eq(text, ReportText.plain_text(report, ReportText.PUBLIC), "Inhalt entspricht der öffentlichen Fassung")
	assert_true(bytes.size() >= text.length(), "Bytes und Zeichen (UTF-8, mehrere Bytes je Umlaut)")
	var gm := ReportExport.export(dir, report, ReportText.GM)
	assert_true(bool(gm["ok"]) and str(gm["path"]).get_file().contains("spielleitung"), "Spielleiterfassung: eigene Datei")
	assert_ne(str(gm["path"]), str(result["path"]), "beide Fassungen getrennt")
	_cleanup()


func test_export_never_overwrites_without_confirmation_and_keeps_files_on_failure() -> void:
	var dir := _dir()
	var report := _report("a")
	var first := ReportExport.export(dir, report, ReportText.PUBLIC)
	var path := str(first["path"])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("ALTER INHALT")
	file.close()
	var refused := ReportExport.export(dir, report, ReportText.PUBLIC)
	assert_false(bool(refused["ok"]), "vorhandene Datei: kein Export")
	assert_eq(str(refused["error"]), "exists", "Fehler exists")
	assert_eq(FileAccess.get_file_as_string(path), "ALTER INHALT", "Datei unverändert")
	for step: StringName in [&"write", &"verify", &"swap"]:
		var failed := ReportExport.export(dir, report, ReportText.PUBLIC, true, step)
		assert_false(bool(failed["ok"]), "%s: Fehler gemeldet" % step)
		assert_eq(FileAccess.get_file_as_string(path), "ALTER INHALT", "%s: vorhandene Datei erhalten" % step)
		assert_false(FileAccess.file_exists(path + ".tmp") or FileAccess.file_exists(path + ".old"), "%s: keine Reste" % step)
	var replaced := ReportExport.export(dir, report, ReportText.PUBLIC, true)
	assert_true(bool(replaced["ok"]), "mit Bestätigung ersetzt")
	assert_eq(FileAccess.get_file_as_string(path), ReportText.plain_text(report, ReportText.PUBLIC), "neue Fassung geschrieben")
	assert_false(FileAccess.file_exists(path + ".tmp") or FileAccess.file_exists(path + ".old"), "keine Reste nach Erfolg")
	_cleanup()


func test_export_reports_an_unusable_directory() -> void:
	var dir := _dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var blocker := dir + "/datei"
	var file := FileAccess.open(blocker, FileAccess.WRITE)
	file.store_string("x")
	file.close()
	var result := ReportExport.export(blocker + "/unter", _report("a"), ReportText.PUBLIC)
	assert_false(bool(result["ok"]), "Ordner nicht anlegbar")
	assert_eq(str(result["error"]), "no_directory", "Fehler no_directory")
	_cleanup()
