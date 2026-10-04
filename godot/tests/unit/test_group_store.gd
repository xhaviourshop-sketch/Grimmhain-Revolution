extends TestCase
## Spielergruppen (Paket B): GroupStore (Speichern, Laden nach neuer Instanz, Umbenennen, Aktualisieren, Löschen,
## Namens- und Personenvalidierung, Schreibfehler, defekte Dateien) und PlayerSetup.replace_persons. Nur temporäre
## Dateien unter user://, nie echte Nutzerdaten (die Standarddatei user://groups.json wird nicht berührt).

const NAMES: Array = ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"]

var _dirs: Array[String] = []


func _path() -> String:
	var dir := "user://test-groups-%d-%d" % [Time.get_ticks_usec(), _dirs.size()]
	_dirs.append(dir)
	return dir + "/groups.json"


func _cleanup() -> void:
	for dir: String in _dirs:
		var d := DirAccess.open(dir)
		if d != null:
			for f: String in d.get_files():
				DirAccess.remove_absolute(dir.path_join(f))
			DirAccess.remove_absolute(dir)
	_dirs.clear()


func _write_raw(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_missing_file_is_empty_list() -> void:
	var store := GroupStore.new(_path())
	var status := store.load_from_disk()
	assert_true(bool(status["ok"]), "fehlende Datei ist kein Fehler")
	assert_eq(store.list().size(), 0, "leere Liste")
	assert_false(FileAccess.file_exists(store.path), "Laden schreibt nichts")
	_cleanup()


func test_save_and_reload_in_new_instance_keeps_order_and_umlauts() -> void:
	var path := _path()
	var first := GroupStore.new(path)
	var result := first.create("  Freitagsrunde  ", NAMES)
	assert_true(bool(result["ok"]), "speichern")
	assert_eq(str(result["id"]), "grp-1", "stabile ID")
	first.create("Familie", ["Ömer", "Zoë"])
	var second := GroupStore.new(path)
	var status := second.load_from_disk()
	assert_true(bool(status["ok"]), "laden")
	var groups := second.list()
	assert_eq(groups.size(), 2, "zwei Gruppen")
	assert_eq(str(groups[0]["name"]), "Freitagsrunde", "Name normalisiert")
	assert_eq(groups[0]["players"], NAMES, "Namen und Reihenfolge inklusive Umlauten")
	assert_eq(str(groups[1]["id"]), "grp-2", "zweite ID")
	_cleanup()


func test_file_contains_only_allowed_fields() -> void:
	var path := _path()
	var store := GroupStore.new(path)
	store.create("Runde", NAMES)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var keys: Array = data.keys()
	keys.sort()
	assert_eq(keys, ["format", "groups", "next_id", "version"], "Dateikopf")
	var group: Dictionary = (data["groups"] as Array)[0]
	var group_keys: Array = group.keys()
	group_keys.sort()
	assert_eq(group_keys, ["id", "name", "players"], "Gruppe: nur ID, Name und Namen")
	for player: Variant in group["players"]:
		assert_true(player is String, "Spieler ist nur ein Name")
	_cleanup()


func test_rename_update_delete_and_ids_not_reused() -> void:
	var path := _path()
	var store := GroupStore.new(path)
	var a := str(store.create("A", NAMES)["id"])
	var b := str(store.create("B", NAMES)["id"])
	assert_true(bool(store.rename(a, "Anders")["ok"]), "umbenennen")
	assert_true(bool(store.rename(a, "ANDERS")["ok"]), "nur Schreibweise des eigenen Namens ändern ist erlaubt")
	assert_eq(str(store.get_group(a)["name"]), "ANDERS", "Schreibweise übernommen")
	var taken := store.rename(a, "b")
	assert_false(bool(taken["ok"]), "Name einer anderen Gruppe (ohne Groß-/Kleinschreibung)")
	assert_eq(str(taken["error"]), "name_taken", "Fehler name_taken")
	assert_eq(str(taken["id"]), b, "vorhandene Gruppe genannt")
	assert_true(bool(store.update_players(a, ["X", "Y", "Z"])["ok"]), "aktualisieren")
	assert_eq(store.get_group(a)["players"], ["X", "Y", "Z"], "neue Namen")
	assert_eq(store.get_group(b)["players"], NAMES, "andere Gruppe unverändert")
	assert_true(bool(store.delete(a)["ok"]), "löschen")
	assert_eq(store.get_group(a), {}, "Gruppe weg")
	var c := str(store.create("C", NAMES)["id"])
	assert_eq(c, "grp-3", "gelöschte ID wird nicht wiederverwendet")
	var reloaded := GroupStore.new(path)
	reloaded.load_from_disk()
	assert_eq(reloaded.list().size(), 2, "Stand nach Neustart")
	assert_eq(str(reloaded.create("D", NAMES)["id"]), "grp-4", "Zähler bleibt über Neustart erhalten")
	assert_false(bool(store.delete("grp-99")["ok"]), "unbekannte Gruppe")
	_cleanup()


func test_same_name_is_not_silently_overwritten() -> void:
	var store := GroupStore.new(_path())
	var id := str(store.create("Runde", NAMES)["id"])
	var dup := store.create("  runde ", ["Neu", "Neu2"])
	assert_false(bool(dup["ok"]), "gleicher Name abgelehnt")
	assert_eq(str(dup["error"]), "name_taken", "Fehlergrund")
	assert_eq(str(dup["id"]), id, "vorhandene Gruppe genannt")
	assert_eq(store.get_group(id)["players"], NAMES, "vorhandene Namen unverändert")
	assert_eq(store.list().size(), 1, "keine zweite Gruppe")
	_cleanup()


func test_name_and_player_validation() -> void:
	var store := GroupStore.new(_path())
	var cases := {
		"empty name": ["   ", NAMES, "empty_name"],
		"control character in name": ["A\tB", NAMES, "invalid_characters"],
		"name too long": ["x".repeat(33), NAMES, "name_too_long"],
		"no players": ["Runde", [], "no_players"],
		"too many players": ["Runde", numbered(25), "too_many_persons"],
		"empty player": ["Runde", ["Anna", "  "], "empty_player"],
		"player with control character": ["Runde", ["Anna", "B\nen"], "invalid_player_characters"],
		"player too long": ["Runde", ["Anna", "y".repeat(33)], "player_name_too_long"],
	}
	for label: String in cases:
		var c: Array = cases[label]
		var result := store.create(str(c[0]), c[1])
		assert_false(bool(result["ok"]), "%s abgelehnt" % label)
		assert_eq(str(result["error"]), str(c[2]), "%s: Fehlergrund" % label)
	assert_eq(store.list().size(), 0, "nichts gespeichert")
	assert_true(bool(store.create("x".repeat(32), numbered(24))["ok"]), "Grenzfall: 32 Zeichen und 24 Namen sind gültig")
	assert_true(bool(store.create("Kurz", ["Nur einer"])["ok"]), "eine Gruppe darf auch kleiner als eine Partie sein")
	_cleanup()


func numbered(count: int) -> Array:
	var out: Array = []
	for i: int in count:
		out.append("P%d" % (i + 1))
	return out


func test_write_failures_keep_last_valid_state() -> void:
	for step: StringName in [&"write", &"verify", &"backup", &"swap"]:
		var path := _path()
		var store := GroupStore.new(path)
		var id := str(store.create("Runde", NAMES)["id"])
		store.simulate_failure = step
		var before_disk := FileAccess.get_file_as_string(path)
		for result: Dictionary in [store.create("Zweite", NAMES), store.rename(id, "Neu"), store.update_players(id, ["A", "B"]), store.delete(id)]:
			assert_false(bool(result["ok"]), "%s: Schreibfehler gemeldet" % step)
		assert_eq(store.list().size(), 1, "%s: Speicher unverändert" % step)
		assert_eq(str(store.get_group(id)["name"]), "Runde", "%s: Name unverändert" % step)
		assert_eq(store.get_group(id)["players"], NAMES, "%s: Namen unverändert" % step)
		if step != &"swap":
			assert_eq(FileAccess.get_file_as_string(path), before_disk, "%s: Datei unverändert" % step)
		store.simulate_failure = &""
		var reloaded := GroupStore.new(path)
		var status := reloaded.load_from_disk()
		assert_true(bool(status["ok"]), "%s: neu ladbar" % step)
		assert_eq(reloaded.list().size(), 1, "%s: Gruppe nach Neustart vorhanden" % step)
		assert_eq(reloaded.get_group(id)["players"], NAMES, "%s: Namen nach Neustart erhalten" % step)
		assert_true(bool(store.create("Später", NAMES)["ok"]), "%s: danach wieder speicherbar" % step)
	_cleanup()


func test_corrupt_file_is_reported_and_set_aside() -> void:
	var path := _path()
	_write_raw(path, "{ das ist kein JSON")
	var store := GroupStore.new(path)
	var status := store.load_from_disk()
	assert_false(bool(status["ok"]), "defekte Datei nicht als erfolgreich gemeldet")
	assert_eq(str(status["error"]), "unreadable", "Fehler unreadable")
	assert_eq(store.list().size(), 0, "leere Liste")
	assert_true(FileAccess.file_exists(path + ".corrupt"), "defekte Datei beiseitegelegt, nicht gelöscht")
	assert_false(FileAccess.file_exists(path), "kein Überschreiben durch das nächste Speichern")
	assert_true(bool(store.create("Neu", NAMES)["ok"]), "danach normal speicherbar")
	assert_true(FileAccess.file_exists(path + ".corrupt"), "defekte Datei bleibt erhalten")
	_cleanup()


func test_wrong_format_and_newer_version_are_reported() -> void:
	var path := _path()
	_write_raw(path, JSON.stringify({"format": "etwas-anderes", "version": 1, "groups": []}))
	var store := GroupStore.new(path)
	assert_eq(str(store.load_from_disk()["error"]), "unreadable", "fremdes Format")
	var newer := _path()
	_write_raw(newer, JSON.stringify({"format": GroupStore.FORMAT, "version": 99, "next_id": 5, "groups": []}))
	var other := GroupStore.new(newer)
	var status := other.load_from_disk()
	assert_false(bool(status["ok"]), "neuere Version nicht als erfolgreich gemeldet")
	assert_eq(str(status["error"]), "newer_version", "Fehler newer_version")
	assert_true(FileAccess.file_exists(newer + ".corrupt"), "Datei unverändert beiseitegelegt")
	_cleanup()


func test_invalid_entries_are_skipped_and_counted() -> void:
	var path := _path()
	var groups := [
		{"id": "grp-1", "name": "Gut", "players": ["Anna", "Ben"]},
		{"id": "grp-2", "name": "", "players": ["Anna"]},
		{"id": "grp-3", "name": "Leer", "players": []},
		{"id": "grp-4", "name": "Zahl", "players": [1, 2]},
		{"id": "grp-1", "name": "DoppelteID", "players": ["X"]},
		{"id": "grp-5", "name": "gut", "players": ["Doppelter Name"]},
		"kein Objekt",
	]
	_write_raw(path, JSON.stringify({"format": GroupStore.FORMAT, "version": 1, "next_id": 1, "groups": groups}))
	var store := GroupStore.new(path)
	var status := store.load_from_disk()
	assert_true(bool(status["ok"]), "Datei lesbar")
	assert_eq(int(status["skipped"]), 6, "sechs ungültige Einträge gezählt")
	assert_eq(store.list().size(), 1, "nur die gültige Gruppe")
	assert_eq(str(store.create("Neu", ["A"])["id"]), "grp-2", "Zähler liegt hinter der höchsten gelesenen ID, auch bei zu kleinem next_id")
	_cleanup()


func test_backup_is_used_when_main_file_is_unreadable() -> void:
	var path := _path()
	var store := GroupStore.new(path)
	store.create("Erste", NAMES)
	store.create("Zweite", NAMES)  # zweites Schreiben legt die erste Fassung als .bak ab
	_write_raw(path, "kaputt")
	var reloaded := GroupStore.new(path)
	var status := reloaded.load_from_disk()
	assert_true(bool(status["ok"]), "aus der Sicherung gelesen")
	assert_eq(str(status["recovered"]), "backup", "Sicherung gemeldet")
	assert_eq(reloaded.list().size(), 1, "Stand der Sicherung")
	_cleanup()


func test_memory_only_store_never_touches_files() -> void:
	var store := GroupStore.new()
	assert_true(bool(store.create("Nur Speicher", NAMES)["ok"]), "ohne Pfad möglich")
	assert_eq(store.list().size(), 1, "im Speicher vorhanden")
	assert_true(bool(store.load_from_disk()["ok"]), "Laden ohne Pfad ist ein No-op")
	assert_eq(store.list().size(), 0, "Laden ohne Pfad setzt die Liste leer")


# --- PlayerSetup.replace_persons -------------------------------------------------------------------------

func test_replace_persons_builds_new_draft_in_order() -> void:
	var setup := PlayerSetup.new()
	setup.add_person("Alt Eins")
	setup.add_person("Alt Zwei")
	var old_ids: Array = []
	for p: Variant in setup.view()["persons"]:
		old_ids.append(int((p as Dictionary)["person_id"]))
	var result := setup.replace_persons(NAMES)
	assert_true(result.ok, "ersetzt")
	var persons: Array = setup.view()["persons"]
	assert_eq(persons.size(), NAMES.size(), "Anzahl")
	for i: int in persons.size():
		assert_eq(str((persons[i] as Dictionary)["name"]), NAMES[i], "Name %d in Reihenfolge" % (i + 1))
		assert_eq(int((persons[i] as Dictionary)["number"]), i + 1, "Nummer")
	assert_eq(int(setup.view()["roles"]["total"]), 0, "keine Rollenwahl übernommen")
	assert_eq(String(setup.view()["step"]), "round", "erster Schritt")
	assert_eq(int(setup.view()["player_count"]), NAMES.size(), "die Gruppe bestimmt die Spielerzahl")
	assert_eq(old_ids.size(), 2, "Kontrolle: Vorher zwei Personen")


func test_replace_persons_rejects_atomically() -> void:
	var setup := PlayerSetup.new()
	setup.add_person("Bleibt")
	var before := setup.view()
	for bad: Array in [[], ["Anna", ""], ["Anna", "B\ten"], ["Anna", "z".repeat(33)], numbered(25)]:
		var result := setup.replace_persons(bad)
		assert_false(result.ok, "abgelehnt: %s" % str(bad).left(40))
		assert_eq(setup.view(), before, "Entwurf unverändert")
