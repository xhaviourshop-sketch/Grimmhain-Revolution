class_name SafeJsonFile
extends RefCounted
## Sicheres Lesen und Schreiben kleiner lokaler JSON-Dateien (Spielergruppen, Partiehistorie).
## Schreiben wie SettingsStore: `.tmp` schreiben und zurücklesen, vorhandene Datei zu `.bak`, `.tmp` zu Datei. Scheitert
## ein Schritt, bleibt die letzte gültige Fassung als Datei oder `.bak` lesbar. Lesen greift bei fehlender oder
## unlesbarer Datei auf `.bak` zurück. Eine unlesbare Datei wird nie überschrieben, sondern von `set_aside` als
## `.corrupt` zur Seite gelegt. Kein automatischer Wiederholversuch.

## Ergebnis von `read`: {state, data, recovered}
##   state "missing"     weder Datei noch Sicherung vorhanden
##   state "ok"          gültige Hülle gelesen (recovered "backup", wenn aus der Sicherung)
##   state "unreadable"  Datei oder Sicherung vorhanden, aber keine gültige Hülle
static func read(path: String, format: String) -> Dictionary:
	var main_exists := FileAccess.file_exists(path)
	var bak_exists := FileAccess.file_exists(path + ".bak")
	if not main_exists and not bak_exists:
		return {"state": "missing", "data": {}, "recovered": ""}
	var data := _parse(path, format)
	if not data.is_empty():
		return {"state": "ok", "data": data, "recovered": ""}
	data = _parse(path + ".bak", format)
	if not data.is_empty():
		return {"state": "ok", "data": data, "recovered": "backup"}
	return {"state": "unreadable", "data": {}, "recovered": ""}


## Schreibt `text` sicher nach `path`. `simulate_failure` (nur Tests): "write", "verify", "backup", "swap".
## Ergebnis {ok, error}.
static func write(path: String, text: String, simulate_failure: StringName = &"") -> Dictionary:
	if not ensure_dir(path.get_base_dir()):
		return {"ok": false, "error": "no_directory"}
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE) if simulate_failure != &"write" else null
	if file == null:
		return {"ok": false, "error": "write_failed"}
	file.store_string(text)
	file.close()
	if simulate_failure == &"verify" or FileAccess.get_file_as_string(tmp) != text:
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error": "verify_failed"}
	var bak := path + ".bak"
	if FileAccess.file_exists(path):
		if simulate_failure == &"backup":
			DirAccess.remove_absolute(tmp)
			return {"ok": false, "error": "backup_failed"}
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		if DirAccess.rename_absolute(path, bak) != OK:
			DirAccess.remove_absolute(tmp)
			return {"ok": false, "error": "backup_failed"}
	if simulate_failure == &"swap" or DirAccess.rename_absolute(tmp, path) != OK:
		# Die vorherige Fassung liegt als `.bak` vor; Lesen greift darauf zurück.
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error": "swap_failed"}
	return {"ok": true, "error": ""}


## Legt den Ordner an, falls er fehlt. false, wenn das nicht geht, etwa weil ein Teil des Pfads eine Datei ist (ohne
## Fehlermeldung der Engine).
static func ensure_dir(dir: String) -> bool:
	if DirAccess.dir_exists_absolute(dir):
		return true
	var part := dir
	while part.contains("/") and not part.ends_with("://"):
		if FileAccess.file_exists(part):
			return false
		part = part.get_base_dir()
	return DirAccess.make_dir_recursive_absolute(dir) == OK


## Legt unlesbare Dateien (Datei und Sicherung) als `.corrupt` beiseite, damit ein späteres Speichern sie nicht
## überschreibt. Ein früheres `.corrupt` wird dabei ersetzt.
static func set_aside(path: String) -> void:
	for suffix: String in ["", ".bak"]:
		var source := path + suffix
		if FileAccess.file_exists(source):
			var target := source + ".corrupt"
			if FileAccess.file_exists(target):
				DirAccess.remove_absolute(target)
			DirAccess.rename_absolute(source, target)


## Gültige Hülle (Wörterbuch mit passendem `format`) oder leer. Eine beschädigte Datei ist ein erwarteter Fall.
static func _parse(file_path: String, format: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	return data if str(data.get("format", "")) == format else {}
