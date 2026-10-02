class_name HistoryStore
extends RefCounted
## Lokale Liste abgeschlossener Partien (Paket D): je Partie der Abschlussbericht (GameReport) in `user://history.json`,
##   {format, version, entries: [{game_id, status, saved_at, report}]}
## Getrennt von Spielständen, Einstellungen und Spielergruppen. Kein Cloud-Upload, kein automatisches Teilen, keine Statistik,
## keine automatische Löschfrist: Ein Bericht verschwindet nur durch „Löschen“ nach Bestätigung.
##
## Konsistenz: `save_report` ist idempotent über die Partie-ID. Derselbe Bericht erzeugt weder einen zweiten Eintrag noch eine
## Schreibaktion; ein erneuter Abschluss derselben Partie ersetzt den Bericht. Wird die Siegbestätigung zurückgenommen, meldet
## `mark_reopened` den Eintrag als „Partie läuft wieder“ (Status `reopened`), damit keine veraltete Behauptung „abgeschlossen“
## stehen bleibt. Die aktive Partie bleibt maßgeblich: Diese Klasse berührt nie einen Spielstand. Schreibfehler ändern weder Speicher
## noch Datei (letzter gültiger Stand bleibt), siehe SafeJsonFile. Ohne Pfad nur im Speicher (Tests, Werkzeuge).

const DEFAULT_PATH := "user://history.json"
const FORMAT := "grimmhain-game-history"
const VERSION := 1
const STATUS_COMPLETED := "completed"
const STATUS_REOPENED := "reopened"

var path: String = ""
## Nur für Tests: erzwingt einen Fehler im genannten Schreibschritt ("write", "verify", "backup", "swap").
var simulate_failure: StringName = &""
var last_status: Dictionary = {"ok": true, "error": ""}  ## letztes Speichern
## Ergebnis des letzten Ladens: {ok, error ("unreadable", "newer_version" oder ""), recovered, skipped}
var load_status: Dictionary = {"ok": true, "error": "", "recovered": "", "skipped": 0}

var _entries: Array[Dictionary] = []


func _init(p_path: String = "") -> void:
	path = p_path


func load_from_disk() -> Dictionary:
	_entries = []
	load_status = {"ok": true, "error": "", "recovered": "", "skipped": 0}
	if path == "":
		return load_status
	var read := SafeJsonFile.read(path, FORMAT)
	if str(read["state"]) == "missing":
		return load_status
	if str(read["state"]) == "unreadable":
		SafeJsonFile.set_aside(path)
		load_status = {"ok": false, "error": "unreadable", "recovered": "", "skipped": 0}
		return load_status
	var data: Dictionary = read["data"]
	var version: Variant = data.get("version", null)
	if not version is float or int(version) < 1 or int(version) > VERSION or not data.get("entries", null) is Array:
		SafeJsonFile.set_aside(path)
		load_status = {"ok": false, "error": "newer_version" if version is float and int(version) > VERSION else "unreadable", "recovered": "", "skipped": 0}
		return load_status
	var seen := {}
	var skipped := 0
	for raw: Variant in data["entries"]:
		var entry := _valid(raw)
		if entry.is_empty() or seen.has(str(entry["game_id"])):
			skipped += 1
			continue
		seen[str(entry["game_id"])] = true
		_entries.append(entry)
	load_status = {"ok": true, "error": "", "recovered": str(read["recovered"]), "skipped": skipped}
	return load_status


## Zusammenfassungen (neueste zuerst): {game_id, status, saved_at, names, players, side, nights, days}.
func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in range(_entries.size() - 1, -1, -1):
		out.append(_summary(_entries[i]))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["saved_at"]) > int(b["saved_at"]))
	return out


func has(game_id: String) -> bool:
	return _index_of(game_id) != -1


## Eintrag {game_id, status, saved_at, report} als Kopie oder leer.
func get_entry(game_id: String) -> Dictionary:
	var index := _index_of(game_id)
	return _entries[index].duplicate(true) if index != -1 else {}


## Bericht einer beendeten Partie speichern (Einfügen oder Ersetzen). Ergebnis {ok, error, changed, created}; `changed` false bei
## unverändertem, schon als abgeschlossen gespeichertem Bericht (keine Schreibaktion).
func save_report(report: Dictionary) -> Dictionary:
	var game_id := str(report.get("game_id", ""))
	if game_id == "" or not report.get("entries", null) is Array or int(report.get("version", 0)) != GameReport.VERSION:
		return {"ok": false, "error": "invalid_report", "changed": false, "created": false}
	var normalized := _normalize(report)
	var index := _index_of(game_id)
	if index != -1 and str(_entries[index]["status"]) == STATUS_COMPLETED and JSON.stringify(_entries[index]["report"]) == JSON.stringify(normalized):
		return {"ok": true, "error": "", "changed": false, "created": false}
	var next := _entries.duplicate(true)
	var entry := {"game_id": game_id, "status": STATUS_COMPLETED, "saved_at": int(Time.get_unix_time_from_system()), "report": normalized}
	if index == -1:
		next.append(entry)
	else:
		next[index] = entry
	var result := _commit(next)
	result["changed"] = bool(result["ok"])
	result["created"] = bool(result["ok"]) and index == -1
	return result


## Die Siegbestätigung einer schon gespeicherten Partie wurde zurückgenommen: Der Bericht bleibt lesbar, gilt aber nicht mehr als
## abgeschlossen. Ergebnis {ok, error, changed}; ohne Eintrag oder bei schon gesetztem Status keine Änderung.
func mark_reopened(game_id: String) -> Dictionary:
	var index := _index_of(game_id)
	if index == -1 or str(_entries[index]["status"]) == STATUS_REOPENED:
		return {"ok": true, "error": "", "changed": false}
	var next := _entries.duplicate(true)
	next[index]["status"] = STATUS_REOPENED
	var result := _commit(next)
	result["changed"] = bool(result["ok"])
	return result


func delete(game_id: String) -> Dictionary:
	var index := _index_of(game_id)
	if index == -1:
		return {"ok": false, "error": "unknown_report"}
	var next := _entries.duplicate(true)
	next.remove_at(index)
	return _commit(next)


# --- intern -----------------------------------------------------------------------------------------

func _commit(next: Array) -> Dictionary:
	if path != "":
		var text := JSON.stringify({"format": FORMAT, "version": VERSION, "entries": next})
		last_status = SafeJsonFile.write(path, text, simulate_failure)
		if not bool(last_status["ok"]):
			return last_status.duplicate()
	else:
		last_status = {"ok": true, "error": ""}
	_entries.clear()
	for entry: Variant in next:
		_entries.append(entry as Dictionary)
	return last_status.duplicate()


func _index_of(game_id: String) -> int:
	for i: int in _entries.size():
		if str(_entries[i]["game_id"]) == game_id:
			return i
	return -1


## Wie nach dem Speichern und Laden: Zahlen als Kommazahlen, damit Vergleiche vor und nach einem Neustart gleich ausfallen.
func _normalize(report: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(report)) as Dictionary


func _valid(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var d: Dictionary = raw
	if not d.get("game_id", null) is String or str(d["game_id"]) == "" or not d.get("saved_at", null) is float or not d.get("report", null) is Dictionary:
		return {}
	var status := str(d.get("status", ""))
	var report: Dictionary = d["report"]
	if not [STATUS_COMPLETED, STATUS_REOPENED].has(status) or not report.get("entries", null) is Array or not report.get("names", null) is Array \
			or str(report.get("game_id", "")) != str(d["game_id"]) or int(report.get("version", 0)) != GameReport.VERSION:
		return {}
	return {"game_id": str(d["game_id"]), "status": status, "saved_at": int(d["saved_at"]), "report": report}


func _summary(entry: Dictionary) -> Dictionary:
	var report: Dictionary = entry["report"]
	return {"game_id": str(entry["game_id"]), "status": str(entry["status"]), "saved_at": int(entry["saved_at"]), "names": (report.get("names", []) as Array).duplicate(),
		"players": int(report.get("players", 0)), "side": str((report.get("winner", {}) as Dictionary).get("side", "none")), "nights": int(report.get("nights", 0)), "days": int(report.get("days", 0))}
