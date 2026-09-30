class_name SaveService
extends RefCounted
## Spielstände auf dem Datenträger (B-13, 03 §6.4). Außerhalb des Regelkerns: Der Kern liefert nur den
## versionierten Text (StateCodec), hier liegen Dateien, sicheres Schreiben, Sicherung und Wiederaufnahme.
##
## Je Partie eine Datei `game-<round_id>.json` im Verzeichnis `base_dir` (Standard user://saves) mit Hülle:
##   {format, version, app_version, saved_at, summary, core}
## `summary` enthält nur öffentliche Angaben für die Liste (Namen, Phase, Zähler), nie Rollen; `core` ist
## der unveränderte StateCodec-Text. Geladen wird immer über StateCodec.decode (Integrität, Replay).
##
## Sicheres Schreiben (jeder Schritt einzeln prüfbar):
##   0. liegt noch eine vollständige `.tmp` aus einem abgebrochenen Speichern vor, wird sie zuerst eingesetzt
##   1. neuen Stand in `<datei>.tmp` schreiben und byteweise zurücklesen
##   2. vorhandene Datei zu `<datei>.bak` umbenennen (ältere Sicherung ersetzt)
##   3. `.tmp` zu `<datei>` umbenennen
## Laden erkennt jeden Abbruchpunkt: eine vollständige `.tmp` ist immer neuer als die Datei und wird
## eingesetzt; eine unvollständige `.tmp` wird beiseitegelegt. Ist die Datei beschädigt, wird sie nie
## überschrieben, sondern als `<datei>.corrupt-<zeit>` beiseitegelegt, und die Sicherung wird geladen.
## Verwerfen einer Partie benennt die Dateien nur um (`.discarded-<zeit>`), es wird nichts gelöscht.

signal status_changed(status: Dictionary)  ## nach jedem Speicherversuch: {ok, error, round_id, saved_at}

const DEFAULT_DIR := "user://saves"
const FORMAT := "grimmhain-app-save"
const VERSION := 1
const PREFIX := "game-"
const EXT := ".json"

var base_dir: String = DEFAULT_DIR
## Nur für Tests: erzwingt einen Fehler im genannten Schritt ("write", "verify", "backup", "swap").
var simulate_failure: StringName = &""
var last_status: Dictionary = {}


func _init(p_base_dir: String = DEFAULT_DIR) -> void:
	base_dir = p_base_dir


func path_for(round_id: String) -> String:
	return base_dir.path_join(PREFIX + round_id + EXT)


## Speichert den Stand sicher. Ergebnis {ok, error, round_id, saved_at}; bei Fehler bleibt die letzte
## intakte Datei unverändert erhalten.
func save(round_id: String, core_text: String, summary: Dictionary) -> Dictionary:
	var status := _save(round_id, core_text, summary)
	last_status = status
	status_changed.emit(status)
	return status


func _save(round_id: String, core_text: String, summary: Dictionary) -> Dictionary:
	var saved_at := int(Time.get_unix_time_from_system())
	var failed := func(error: String) -> Dictionary:
		return {"ok": false, "error": error, "round_id": round_id, "saved_at": 0}
	if round_id == "" or not _ensure_dir():
		return failed.call("no_directory")
	var path := path_for(round_id)
	var tmp := path + ".tmp"
	# Eine vollständige `.tmp` aus einem abgebrochenen Speichern ist der neueste Stand: erst einsetzen, damit ein
	# erneuter Fehler beim Überschreiben der `.tmp` ihn nicht zerstört.
	if FileAccess.file_exists(tmp) and bool(_read(tmp)["ok"]) and not _promote_tmp(path):
		return failed.call("backup_failed")
	var text := JSON.stringify({"format": FORMAT, "version": VERSION, "app_version": AppPlatform.app_version(),
		"saved_at": saved_at, "summary": summary, "core": core_text})
	var file := FileAccess.open(tmp, FileAccess.WRITE) if simulate_failure != &"write" else null
	if file == null:
		return failed.call("write_failed")
	file.store_string(text)
	file.flush()
	file.close()
	if simulate_failure == &"verify" or FileAccess.get_file_as_string(tmp) != text:
		DirAccess.remove_absolute(tmp)
		return failed.call("verify_failed")
	var bak := path + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		if simulate_failure == &"backup" or DirAccess.rename_absolute(path, bak) != OK:
			return failed.call("backup_failed")
	if simulate_failure == &"swap" or DirAccess.rename_absolute(tmp, path) != OK:
		# Die neue Fassung liegt vollständig in `.tmp`; Laden setzt sie ein.
		return failed.call("swap_failed")
	return {"ok": true, "error": "", "round_id": round_id, "saved_at": saved_at}


## Lädt die Partie `round_id`. Ergebnis {ok, error, core, summary, recovered, set_aside}:
##   recovered  "" | "tmp" (unterbrochenes Schreiben fortgesetzt) | "backup" (Datei beschädigt)
##   set_aside  beiseitegelegte Dateien (beschädigt oder unvollständig), nie gelöscht
## Ein Spielstand aus einer anderen Schema- oder Regelversion ist nicht beschädigt: Er wird nie beiseitegelegt, nie
## verändert und nie neu gedeutet, sondern mit dem Fehler "incompatible" gemeldet (DI-01, Schema 13).
func load_game(round_id: String) -> Dictionary:
	var path := path_for(round_id)
	var tmp := path + ".tmp"
	var bak := path + ".bak"
	var set_aside: Array = []
	if FileAccess.file_exists(tmp):
		var from_tmp := _read(tmp)
		if bool(from_tmp["ok"]):
			_promote_tmp(path)
			return _result(from_tmp, "tmp", set_aside)
		if bool(from_tmp.get("incompatible", false)):
			return _incompatible(from_tmp, set_aside)
		set_aside.append(_set_aside(tmp))
	if FileAccess.file_exists(path):
		var main := _read(path)
		if bool(main["ok"]):
			return _result(main, "", set_aside)
		if bool(main.get("incompatible", false)):
			return _incompatible(main, set_aside)
		set_aside.append(_set_aside(path))
	if FileAccess.file_exists(bak):
		var backup := _read(bak)
		if bool(backup["ok"]):
			return _result(backup, "backup", set_aside)
		if bool(backup.get("incompatible", false)):
			return _incompatible(backup, set_aside)
		return {"ok": false, "error": "backup_invalid", "detail": str(backup["error"]), "set_aside": set_aside}
	return {"ok": false, "error": "not_found" if set_aside.is_empty() else "corrupt", "set_aside": set_aside}


## Gespeicherte Partien für „Fortsetzen“, neueste zuerst: {round_id, summary, saved_at, readable, compatible, schema, expected}.
## `compatible` = false: Schema oder Regelversion passen nicht zu dieser Version (Datei bleibt unverändert).
## Liest nur die Hülle; die vollständige Prüfung erfolgt beim Laden.
func list() -> Array:
	var out: Array = []
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return out
	var ids := {}
	for f: String in dir.get_files():
		if f.begins_with(PREFIX) and (f.ends_with(EXT) or f.ends_with(EXT + ".bak") or f.ends_with(EXT + ".tmp")):
			ids[f.trim_prefix(PREFIX).get_slice(EXT, 0)] = true
	for id: String in ids:
		var entry := {"round_id": id, "summary": {}, "saved_at": 0, "readable": false, "compatible": true, "schema": GameState.SCHEMA_VERSION, "expected": GameState.SCHEMA_VERSION,
			"found_label": "", "expected_label": _version_label(GameState.SCHEMA_VERSION, String(GameState.RULES_VERSION))}
		for candidate: String in [path_for(id) + ".tmp", path_for(id), path_for(id) + ".bak"]:
			var env := _envelope(candidate)
			if not env.is_empty():
				entry["summary"] = env.get("summary", {})
				entry["saved_at"] = int(env.get("saved_at", 0))
				entry["readable"] = true
				var compat := _compatibility(env)
				entry["compatible"] = bool(compat["compatible"])
				entry["schema"] = int(compat["schema"])
				entry["found_label"] = _version_label(int(compat["schema"]), str(compat["rules"]))
				break
		out.append(entry)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["saved_at"]) > int(b["saved_at"]))
	return out


## Verwerfen: alle Dateien der Partie umbenennen (nicht löschen). Ergebnis: umbenannte Dateien.
func discard(round_id: String) -> Array:
	var stamp := str(int(Time.get_unix_time_from_system()))
	var moved: Array = []
	for f: String in [path_for(round_id), path_for(round_id) + ".bak", path_for(round_id) + ".tmp"]:
		if FileAccess.file_exists(f) and DirAccess.rename_absolute(f, f + ".discarded-" + stamp) == OK:
			moved.append(f + ".discarded-" + stamp)
	return moved


func _read(path: String) -> Dictionary:
	var env := _envelope(path)
	if env.is_empty():
		return {"ok": false, "error": "unreadable"}
	var decoded := StateCodec.decode(str(env.get("core", "")))
	if not decoded.ok:
		var incompatible := decoded.error == &"unsupported_schema_version" or decoded.error == &"unsupported_rules_version"
		return {"ok": false, "error": String(decoded.error), "incompatible": incompatible, "detail": decoded.detail}
	return {"ok": true, "core": str(env["core"]), "summary": env.get("summary", {})}


## Schema und Regelversion des gespeicherten Kerns gegen diese Version (nur Kopfdaten, keine Prüfung des Inhalts).
func _compatibility(env: Dictionary) -> Dictionary:
	var json := JSON.new()
	if json.parse(str(env.get("core", ""))) != OK or not json.data is Dictionary:
		return {"compatible": true, "schema": GameState.SCHEMA_VERSION, "rules": String(GameState.RULES_VERSION)}
	var doc: Dictionary = json.data
	var schema := DictRead.get_int(doc, "schema_version", -1)
	var rules := DictRead.get_string(doc, "rules_version")
	return {"compatible": schema == GameState.SCHEMA_VERSION and rules == String(GameState.RULES_VERSION), "schema": schema, "rules": rules}


## Anzeigetext „Schema 14, Regeln grimmhain-core-0.13“: Schema und Regelversion können einzeln abweichen.
func _version_label(schema: int, rules: String) -> String:
	return "Schema %d, %s" % [schema, rules.trim_prefix("grimmhain-core-")]


func _incompatible(read: Dictionary, set_aside: Array) -> Dictionary:
	return {"ok": false, "error": "incompatible", "detail": str(read.get("detail", "")), "set_aside": set_aside}


func _envelope(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	# JSON-Instanz statt JSON.parse_string: eine beschädigte Datei ist ein erwarteter Fall, kein Engine-Fehler.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary or str((data as Dictionary).get("format", "")) != FORMAT or not (data as Dictionary).get("core") is String:
		return {}
	return data


## Setzt die vollständige `<datei>.tmp` ein: vorhandene Datei wird Sicherung, `.tmp` wird Datei.
func _promote_tmp(path: String) -> bool:
	var bak := path + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		if DirAccess.rename_absolute(path, bak) != OK:
			return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


## Legt `base_dir` bei Bedarf an. Steht eine Datei im Pfad, ist das Anlegen unmöglich: dann ohne Engine-Fehler ablehnen.
func _ensure_dir() -> bool:
	var p := base_dir
	while not DirAccess.dir_exists_absolute(p):
		if FileAccess.file_exists(p):
			return false
		var parent := p.get_base_dir()
		if parent == p or parent == "":
			break
		p = parent
	return DirAccess.dir_exists_absolute(base_dir) or DirAccess.make_dir_recursive_absolute(base_dir) == OK


func _set_aside(path: String) -> String:
	var target := "%s.corrupt-%d" % [path, int(Time.get_unix_time_from_system())]
	var n := 1
	while FileAccess.file_exists(target):
		target = "%s.corrupt-%d-%d" % [path, int(Time.get_unix_time_from_system()), n]
		n += 1
	DirAccess.rename_absolute(path, target)
	return target


func _result(read: Dictionary, recovered: String, set_aside: Array) -> Dictionary:
	return {"ok": true, "error": "", "core": read["core"], "summary": read["summary"], "recovered": recovered, "set_aside": set_aside}
