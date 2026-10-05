class_name SettingsStore
extends RefCounted
## Dauerhafte Geräteeinstellungen (Paket 5a), getrennt von Spielständen: eine kleine JSON-Datei
## `user://settings.json` mit {format, version, language, reduced_motion, left_handed, show_night_timer, show_calls, music_enabled}. Keine Rollen, Namen,
## Spielstände oder Geheimnisse; `version` betrifft nur dieses Format, nicht Spielschema oder Regelversion.
##
## Laden setzt nur gültige Werte direkt in AppSettings (ohne `changed`, also ohne Speicher-/Signalfolge) und
## schreibt nie. Fehlende Datei = Erstbenutzung mit Standardwerten. Ungültige Einzelwerte fallen einzeln auf den
## Standard zurück, unbekannte Schlüssel werden ignoriert, eine unlesbare Datei ergibt Standardwerte.
##
## Sicheres Schreiben wie SaveService, vereinfacht: `.tmp` schreiben und zurücklesen, vorhandene Datei zu `.bak`,
## `.tmp` zu Datei. Scheitert ein Schritt, bleibt die letzte gültige Fassung als Datei oder `.bak` lesbar; Laden
## greift bei fehlender oder unlesbarer Datei auf `.bak` zurück. Kein automatischer Wiederholversuch.

const DEFAULT_PATH := "user://settings.json"
const FORMAT := "grimmhain-settings"
const VERSION := 1

var path: String = DEFAULT_PATH
## Nur für Tests: erzwingt einen Fehler im genannten Schritt ("write", "verify", "backup", "swap").
var simulate_failure: StringName = &""
var last_status: Dictionary = {}  ## letztes Speichern: {ok, error}


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


## Lädt gespeicherte Werte in `settings`. Ergebnis {ok, error, first_run, recovered, rejected}:
##   ok false + error "unreadable": Datei und Sicherung unlesbar, Standardwerte bleiben
##   recovered "backup": Datei fehlte oder war unlesbar, Sicherung verwendet
##   rejected: Schlüssel mit ungültigem Wert (Standard bleibt)
func load_into(settings: AppSettings) -> Dictionary:
	var result := {"ok": true, "error": "", "first_run": false, "recovered": "", "rejected": []}
	var data := _read(path)
	if data.is_empty() and FileAccess.file_exists(path + ".bak"):
		data = _read(path + ".bak")
		result["recovered"] = "backup" if not data.is_empty() else ""
	if data.is_empty():
		if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
			result["ok"] = false
			result["error"] = "unreadable"
		else:
			result["first_run"] = true
		return result
	var rejected: Array = []
	if data.has("language"):
		var lang: Variant = data["language"]
		if lang is String and AppSettings.LANGUAGES.has(lang):
			settings.language = lang
		else:
			rejected.append("language")
	for key: String in ["reduced_motion", "left_handed", "show_night_timer", "show_calls", "music_enabled"]:
		if data.has(key):
			if data[key] is bool:
				settings.set(key, data[key])
			else:
				rejected.append(key)
	result["rejected"] = rejected
	return result


## Speichert die aktuellen Werte sicher. Ergebnis {ok, error}; bei Fehler bleibt die letzte gültige Fassung.
func save(settings: AppSettings) -> Dictionary:
	last_status = _save(settings)
	return last_status


func _save(settings: AppSettings) -> Dictionary:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir) != OK:
		return {"ok": false, "error": "no_directory"}
	var text := JSON.stringify({"format": FORMAT, "version": VERSION, "language": settings.language,
		"reduced_motion": settings.reduced_motion, "left_handed": settings.left_handed, "show_night_timer": settings.show_night_timer, "show_calls": settings.show_calls, "music_enabled": settings.music_enabled})
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
		# Die vorherige Fassung liegt als `.bak` vor; Laden greift darauf zurück.
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error": "swap_failed"}
	return {"ok": true, "error": ""}


## Gültige Hülle oder leer. Eine beschädigte Datei ist ein erwarteter Fall, kein Engine-Fehler.
func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	return data if str(data.get("format", "")) == FORMAT else {}
