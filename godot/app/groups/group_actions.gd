class_name GroupActions
extends RefCounted
## Bedienabläufe für gespeicherte Spielergruppen (Speichern, Laden, Umbenennen, Aktualisieren, Löschen) zwischen
## Oberfläche, GroupStore und PlayerSetup. Kennt weder Szenen noch Knoten: Rückfragen gehen als DialogRequest über
## `dialog_requested`, Ergebnisse als Meldung (Schlüssel und Werte) über `message`. Rückfragen stehen immer vor
## Ersetzen, Aktualisieren und Löschen; gleichnamige Gruppen werden nie still überschrieben. Der Setup-Entwurf
## ändert sich nur beim Laden, gespeicherte Gruppen nur durch die hier ausdrücklich bestätigten Aktionen.
## Kein Regelkern, kein Spielstand, keine laufende Partie.

signal dialog_requested(request: DialogRequest)
signal message(key: String, values: Dictionary, variation: StringName)
signal groups_changed  ## Liste der Gruppen hat sich geändert (gespeichert, umbenannt, aktualisiert, gelöscht)
signal group_loaded(group_id: String)  ## Entwurf wurde durch eine Gruppe ersetzt

var _store: GroupStore
var _setup: PlayerSetup


func _init(p_store: GroupStore, p_setup: PlayerSetup) -> void:
	_store = p_store
	_setup = p_setup


func store() -> GroupStore:
	return _store


## Namen der aktuellen Setup-Liste in Listenreihenfolge (nicht in Sitzordnung).
func current_names() -> Array:
	var out: Array = []
	for person: Variant in _setup.view()["persons"]:
		out.append(str((person as Dictionary)["name"]))
	return out


func can_save_current() -> bool:
	return not current_names().is_empty()


# --- Speichern ----------------------------------------------------------------------------------------

## Fragt nach einem Namen und speichert die aktuelle Liste als neue Gruppe. Gibt es den Namen schon, folgt eine
## eigene Rückfrage „aktualisieren?“.
func request_save() -> void:
	var names := current_names()
	if names.is_empty():
		message.emit("ui.groups.error.no_players", {}, &"ErrorLabel")
		return
	var request := DialogRequest.with_input("ui.groups.dialog.save.title", "ui.groups.dialog.save.message", "ui.groups.dialog.save.confirm", "ui.groups.dialog.name_placeholder", _save_named.bind(names))
	request.message_values = {"count": names.size()}
	dialog_requested.emit(request)


func _save_named(raw_name: String, names: Array) -> void:
	var result := _store.create(raw_name, names)
	if bool(result["ok"]):
		var group := _store.get_group(str(result["id"]))
		message.emit("ui.groups.info.saved", {"name": group["name"], "count": names.size()}, &"MutedLabel")
		groups_changed.emit()
	elif str(result["error"]) == "name_taken":
		_confirm_update_same_name(str(result["id"]), names)
	else:
		_report(result, PersonNameRules.normalize(raw_name))


func _confirm_update_same_name(id: String, names: Array) -> void:
	var group := _store.get_group(id)
	var request := DialogRequest.create("ui.groups.dialog.exists.title", "ui.groups.dialog.exists.message", "ui.groups.dialog.exists.confirm", _apply_update.bind(id, names), true)
	request.message_values = {"name": group["name"], "old": (group["players"] as Array).size(), "count": names.size()}
	dialog_requested.emit(request)


# --- Laden ----------------------------------------------------------------------------------------------

## Lädt eine Gruppe in den Setup-Entwurf. Eine gefüllte Liste wird nur nach Bestätigung ersetzt.
func request_load(id: String) -> void:
	var group := _store.get_group(id)
	if group.is_empty():
		message.emit("ui.groups.error.unknown_group", {}, &"ErrorLabel")
		return
	var current := current_names().size()
	if current == 0:
		_apply_load(id)
		return
	var request := DialogRequest.create("ui.groups.dialog.load.title", "ui.groups.dialog.load.message", "ui.groups.dialog.load.confirm", _apply_load.bind(id), true)
	request.message_values = {"name": group["name"], "count": (group["players"] as Array).size(), "current": current}
	dialog_requested.emit(request)


func _apply_load(id: String) -> void:
	var group := _store.get_group(id)
	if group.is_empty():
		message.emit("ui.groups.error.unknown_group", {}, &"ErrorLabel")
		return
	var result := _setup.replace_persons(group["players"] as Array)
	if not result.ok:
		# Gespeicherte Gruppen sind geprüft; scheitert das Laden trotzdem, bleibt der Entwurf unverändert.
		message.emit("ui.groups.error.load_failed", {"name": group["name"]}, &"ErrorLabel")
		return
	message.emit("ui.groups.info.loaded", {"name": group["name"], "count": (group["players"] as Array).size()}, &"MutedLabel")
	group_loaded.emit(id)


# --- Umbenennen -----------------------------------------------------------------------------------------

func request_rename(id: String) -> void:
	var group := _store.get_group(id)
	if group.is_empty():
		message.emit("ui.groups.error.unknown_group", {}, &"ErrorLabel")
		return
	var request := DialogRequest.with_input("ui.groups.dialog.rename.title", "ui.groups.dialog.rename.message", "ui.groups.dialog.rename.confirm", "ui.groups.dialog.name_placeholder", _apply_rename.bind(id))
	request.message_values = {"name": group["name"]}
	dialog_requested.emit(request)


func _apply_rename(raw_name: String, id: String) -> void:
	var result := _store.rename(id, raw_name)
	if bool(result["ok"]):
		message.emit("ui.groups.info.renamed", {"name": _store.get_group(id)["name"]}, &"MutedLabel")
		groups_changed.emit()
	else:
		_report(result, PersonNameRules.normalize(raw_name))


# --- Aktualisieren --------------------------------------------------------------------------------------

## Ersetzt die Namen einer Gruppe bewusst durch die aktuelle Liste (nach Rückfrage).
func request_update(id: String) -> void:
	var group := _store.get_group(id)
	var names := current_names()
	if group.is_empty():
		message.emit("ui.groups.error.unknown_group", {}, &"ErrorLabel")
		return
	if names.is_empty():
		message.emit("ui.groups.error.no_players", {}, &"ErrorLabel")
		return
	var request := DialogRequest.create("ui.groups.dialog.update.title", "ui.groups.dialog.update.message", "ui.groups.dialog.update.confirm", _apply_update.bind(id, names), true)
	request.message_values = {"name": group["name"], "old": (group["players"] as Array).size(), "count": names.size()}
	dialog_requested.emit(request)


func _apply_update(id: String, names: Array) -> void:
	var result := _store.update_players(id, names)
	if bool(result["ok"]):
		message.emit("ui.groups.info.updated", {"name": _store.get_group(id)["name"], "count": names.size()}, &"MutedLabel")
		groups_changed.emit()
	else:
		_report(result, "")


# --- Löschen --------------------------------------------------------------------------------------------

func request_delete(id: String) -> void:
	var group := _store.get_group(id)
	if group.is_empty():
		message.emit("ui.groups.error.unknown_group", {}, &"ErrorLabel")
		return
	var request := DialogRequest.create("ui.groups.dialog.delete.title", "ui.groups.dialog.delete.message", "ui.groups.dialog.delete.confirm", _apply_delete.bind(id), true)
	request.message_values = {"name": group["name"], "count": (group["players"] as Array).size()}
	dialog_requested.emit(request)


func _apply_delete(id: String) -> void:
	var name := str(_store.get_group(id).get("name", ""))
	var result := _store.delete(id)
	if bool(result["ok"]):
		message.emit("ui.groups.info.deleted", {"name": name}, &"MutedLabel")
		groups_changed.emit()
	else:
		_report(result, name)


# --- Meldungen ------------------------------------------------------------------------------------------

## Fehlermeldung zu einem abgelehnten Speicher-Ergebnis. Schreibfehler sagen ausdrücklich, dass der letzte
## gespeicherte Stand erhalten blieb.
func _report(result: Dictionary, name: String) -> void:
	var error := str(result["error"])
	var values := {"name": name, "max_length": PersonNameRules.MAX_NAME_LENGTH, "max": PersonNameRules.MAX_PERSONS}
	if ["write_failed", "verify_failed", "backup_failed", "swap_failed", "no_directory"].has(error):
		error = "write_failed"
	message.emit("ui.groups.error." + error, values, &"ErrorLabel")
