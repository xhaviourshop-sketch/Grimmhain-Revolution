class_name GroupStore
extends RefCounted
## Gespeicherte Spielergruppen (Paket B): benannte, geordnete Namenslisten für die nächste Partie. Getrennt von
## Einstellungen und Spielständen, eine kleine JSON-Datei `user://groups.json`:
##   {format, version, next_id, groups: [{id, name, players: [Name, …]}]}
## Keine Rollen, Bindungen, Markierungen, Ressourcen, Partie-IDs oder Personen-IDs. `version` betrifft nur dieses Format.
## Die Gruppen-ID ist ein stabiler Zähler („grp-1“, „grp-2“, …), ohne Zufall und ohne Wiederverwendung gelöschter IDs.
##
## Ohne Pfad (Standard) lebt die Liste nur im Speicher (Tests, Screenshot-Werkzeug); die Shell setzt beim echten Start
## den Standardpfad und lädt. Jede Änderung ist atomar: sie wird zuerst geschrieben und erst danach im Speicher
## übernommen. Scheitert das Schreiben, bleibt der letzte gültige Stand im Speicher und auf dem Datenträger.
## Namen und Personenlisten folgen PersonNameRules (Normalisierung, Länge, keine Steuerzeichen; 1 bis 24 Personen).
## Gruppennamen sind ohne Beachtung von Groß-/Kleinschreibung eindeutig.

const DEFAULT_PATH := "user://groups.json"
const FORMAT := "grimmhain-player-groups"
const VERSION := 1
const ID_PREFIX := "grp-"

var path: String = ""
## Nur für Tests: erzwingt einen Fehler im genannten Schreibschritt ("write", "verify", "backup", "swap").
var simulate_failure: StringName = &""
var last_status: Dictionary = {"ok": true, "error": ""}  ## letztes Speichern
## Ergebnis des letzten Ladens: {ok, error ("unreadable", "newer_version" oder ""), recovered ("backup" oder ""), skipped}
var load_status: Dictionary = {"ok": true, "error": "", "recovered": "", "skipped": 0}

var _groups: Array[Dictionary] = []
var _next_id: int = 1


func _init(p_path: String = "") -> void:
	path = p_path


## Lädt die Gruppen vom Datenträger. Fehlende Datei = leere Liste. Unlesbare Datei = leere Liste plus Fehler; die Datei
## wird als `.corrupt` beiseitegelegt. Einzelne ungültige Gruppen werden übersprungen und gezählt.
func load_from_disk() -> Dictionary:
	_groups = []
	_next_id = 1
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
	if not data.get("version", null) is float or int(data["version"]) < 1 or int(data["version"]) > VERSION or not data.get("groups", null) is Array:
		SafeJsonFile.set_aside(path)
		load_status = {"ok": false, "error": "newer_version" if data.get("version", null) is float and int(data["version"]) > VERSION else "unreadable", "recovered": "", "skipped": 0}
		return load_status
	var seen_ids := {}
	var seen_names := {}
	var skipped := 0
	var highest := 0
	for entry: Variant in data["groups"]:
		var group := _valid_entry(entry)
		var id := str(group.get("id", ""))
		if group.is_empty() or seen_ids.has(id) or seen_names.has(PersonNameRules.duplicate_key(str(group["name"]))):
			skipped += 1
			continue
		seen_ids[id] = true
		seen_names[PersonNameRules.duplicate_key(str(group["name"]))] = true
		_groups.append(group)
		if id.begins_with(ID_PREFIX) and id.trim_prefix(ID_PREFIX).is_valid_int():
			highest = maxi(highest, id.trim_prefix(ID_PREFIX).to_int())
	var stored_next: int = int(data["next_id"]) if data.get("next_id", null) is float else 1
	_next_id = maxi(stored_next, highest + 1)
	load_status = {"ok": true, "error": "", "recovered": str(read["recovered"]), "skipped": skipped}
	return load_status


## Kopien aller Gruppen in gespeicherter Reihenfolge: [{id, name, players}].
func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for group: Dictionary in _groups:
		out.append(_copy(group))
	return out


func get_group(id: String) -> Dictionary:
	var index := _index_of(id)
	return _copy(_groups[index]) if index != -1 else {}


## ID der Gruppe mit diesem Namen (ohne Beachtung von Groß-/Kleinschreibung) oder "".
func id_for_name(name: String) -> String:
	var key := PersonNameRules.duplicate_key(name)
	for group: Dictionary in _groups:
		if PersonNameRules.duplicate_key(str(group["name"])) == key:
			return str(group["id"])
	return ""


## Neue Gruppe. Ergebnis {ok, error, id}. Fehler: empty_name, invalid_characters, name_too_long, no_players,
## too_many_persons, empty_player, invalid_player_characters, player_name_too_long, name_taken (id = vorhandene
## Gruppe), write_failed und weitere Schreibfehler (siehe SafeJsonFile).
func create(raw_name: String, raw_players: Array) -> Dictionary:
	var name := PersonNameRules.normalize(raw_name)
	var error := _name_error(name)
	var players := _normalized_players(raw_players)
	if error == &"":
		error = _players_error(players)
	if error != &"":
		return {"ok": false, "error": String(error), "id": ""}
	var taken := id_for_name(name)
	if taken != "":
		return {"ok": false, "error": "name_taken", "id": taken}
	var id := "%s%d" % [ID_PREFIX, _next_id]
	var next := _groups.duplicate(true)
	next.append({"id": id, "name": name, "players": players})
	var written := _commit(next, _next_id + 1)
	written["id"] = id if bool(written["ok"]) else ""
	return written


## Gruppe umbenennen. Gleicher Name in anderer Schreibweise derselben Gruppe ist erlaubt.
func rename(id: String, raw_name: String) -> Dictionary:
	var index := _index_of(id)
	if index == -1:
		return {"ok": false, "error": "unknown_group", "id": id}
	var name := PersonNameRules.normalize(raw_name)
	var error := _name_error(name)
	if error != &"":
		return {"ok": false, "error": String(error), "id": id}
	var taken := id_for_name(name)
	if taken != "" and taken != id:
		return {"ok": false, "error": "name_taken", "id": taken}
	var next := _groups.duplicate(true)
	next[index]["name"] = name
	var written := _commit(next, _next_id)
	written["id"] = id
	return written


## Personenliste einer Gruppe ersetzen (bewusstes Aktualisieren mit der aktuellen Liste).
func update_players(id: String, raw_players: Array) -> Dictionary:
	var index := _index_of(id)
	if index == -1:
		return {"ok": false, "error": "unknown_group", "id": id}
	var players := _normalized_players(raw_players)
	var error := _players_error(players)
	if error != &"":
		return {"ok": false, "error": String(error), "id": id}
	var next := _groups.duplicate(true)
	next[index]["players"] = players
	var written := _commit(next, _next_id)
	written["id"] = id
	return written


func delete(id: String) -> Dictionary:
	var index := _index_of(id)
	if index == -1:
		return {"ok": false, "error": "unknown_group", "id": id}
	var next := _groups.duplicate(true)
	next.remove_at(index)
	var written := _commit(next, _next_id)
	written["id"] = id
	return written


# --- intern -----------------------------------------------------------------------------------------

func _commit(next: Array, next_id: int) -> Dictionary:
	if path != "":
		var text := JSON.stringify({"format": FORMAT, "version": VERSION, "next_id": next_id, "groups": next})
		last_status = SafeJsonFile.write(path, text, simulate_failure)
		if not bool(last_status["ok"]):
			return last_status.duplicate()
	else:
		last_status = {"ok": true, "error": ""}
	_groups.clear()
	for group: Variant in next:
		_groups.append(group as Dictionary)
	_next_id = next_id
	return last_status.duplicate()


func _index_of(id: String) -> int:
	for i: int in _groups.size():
		if str(_groups[i]["id"]) == id:
			return i
	return -1


func _copy(group: Dictionary) -> Dictionary:
	return {"id": str(group["id"]), "name": str(group["name"]), "players": (group["players"] as Array).duplicate()}


func _name_error(name: String) -> StringName:
	return PersonNameRules.error_for(name)


func _normalized_players(raw_players: Array) -> Array:
	var out: Array = []
	for raw: Variant in raw_players:
		out.append(PersonNameRules.normalize(str(raw)))
	return out


func _players_error(players: Array) -> StringName:
	if players.is_empty():
		return &"no_players"
	if players.size() > PersonNameRules.MAX_PERSONS:
		return &"too_many_persons"
	for player: Variant in players:
		var error := PersonNameRules.error_for(str(player))
		match error:
			&"empty_name":
				return &"empty_player"
			&"invalid_characters":
				return &"invalid_player_characters"
			&"name_too_long":
				return &"player_name_too_long"
	return &""


## Gültige Gruppe aus gelesenen Daten (nur id, name, players, alles geprüft und normalisiert) oder leer.
func _valid_entry(entry: Variant) -> Dictionary:
	if not entry is Dictionary:
		return {}
	var raw: Dictionary = entry
	if not raw.get("id", null) is String or not raw.get("name", null) is String or not raw.get("players", null) is Array:
		return {}
	var id: String = raw["id"]
	var name := PersonNameRules.normalize(raw["name"])
	for player: Variant in raw["players"]:
		if not player is String:
			return {}
	var players := _normalized_players(raw["players"])
	if id == "" or _name_error(name) != &"" or _players_error(players) != &"":
		return {}
	return {"id": id, "name": name, "players": players}
