class_name PlayerSetup
extends RefCounted
## Anwendungsschicht des Namensschritts „Neue Partie“: einzige Wahrheit über Personen, IDs
## und Bestätigung. Die UI stellt nur dar und ruft die Operationen auf. Jede Operation ist
## atomar: bei Ablehnung bleiben Personen, ID-Zähler und Status unverändert.
## Erzeugt keinen GameState, keinen Befehl und keine Rollen; das Ergebnis bleibt ein Entwurf
## im Speicher (AppContext), bis ein späterer Schritt daraus StartGame baut.

signal changed(view: Dictionary)  ## nach jeder angenommenen Änderung (auch Bestätigen, Verwerfen)

var _draft: SetupDraft = SetupDraft.new()


# --- Operationen ------------------------------------------------------------------------------------

func add_person(raw_name: String) -> SetupResult:
	var name := PersonNameRules.normalize(raw_name)
	var error := PersonNameRules.error_for(name)
	if error != &"":
		return SetupResult.failure(error, view(), _name_details(name))
	if _draft.persons.size() >= PersonNameRules.MAX_PERSONS:
		return SetupResult.failure(&"too_many_persons", view(), {"current": _draft.persons.size(), "incoming": 1, "max": PersonNameRules.MAX_PERSONS})
	var warnings: Array[StringName] = []
	if _draft.has_duplicate_of(name):
		warnings.append(&"duplicate_name")
	var id := _create(name)
	return _commit([id], warnings)


## Mehrfachimport: alle Einträge oder keiner.
func import_names(raw_text: String) -> SetupResult:
	var names := PersonNameRules.split_import(raw_text)
	if names.is_empty():
		return SetupResult.failure(&"import_empty", view())
	var invalid: Array[Dictionary] = []
	for i: int in names.size():
		var error := PersonNameRules.error_for(names[i])
		if error != &"":
			invalid.append({"position": i + 1, "name": names[i], "error": error})
	var current := _draft.persons.size()
	var details := {"current": current, "incoming": names.size(), "max": PersonNameRules.MAX_PERSONS, "max_length": PersonNameRules.MAX_NAME_LENGTH}
	if not invalid.is_empty():
		details["exceeds_max"] = current + names.size() > PersonNameRules.MAX_PERSONS
		return SetupResult.failure(&"invalid_entries", view(), details, invalid)
	if current + names.size() > PersonNameRules.MAX_PERSONS:
		return SetupResult.failure(&"too_many_persons", view(), details)
	var warnings: Array[StringName] = []
	var ids: Array[int] = []
	for name: String in names:
		if _draft.has_duplicate_of(name) and not warnings.has(&"duplicate_name"):
			warnings.append(&"duplicate_name")
		ids.append(_create(name))
	var result := _commit(ids, warnings)
	result.details = {"imported": ids.size()}
	return result


func rename_person(person_id: int, raw_name: String) -> SetupResult:
	var index := _draft.index_of(person_id)
	if index == -1:
		return SetupResult.failure(&"unknown_person", view(), {"person_id": person_id})
	var name := PersonNameRules.normalize(raw_name)
	var error := PersonNameRules.error_for(name)
	if error != &"":
		return SetupResult.failure(error, view(), _name_details(name))
	var ids: Array[int] = [person_id]
	if _draft.persons[index].name == name:
		return SetupResult.success(view(), ids)  # nichts geändert: Bestätigung bleibt
	var warnings: Array[StringName] = []
	if _draft.has_duplicate_of(name, person_id):
		warnings.append(&"duplicate_name")
	_draft.persons[index].name = name
	return _commit(ids, warnings)


func remove_person(person_id: int) -> SetupResult:
	var index := _draft.index_of(person_id)
	if index == -1:
		return SetupResult.failure(&"unknown_person", view(), {"person_id": person_id})
	_draft.persons.remove_at(index)
	var ids: Array[int] = [person_id]
	return _commit(ids, [])


## Bestätigt den Namensschritt (6 bis 24 Personen; Dubletten erlaubt).
func confirm() -> SetupResult:
	var validation := _draft.validation()
	if not bool(validation["valid"]):
		return SetupResult.failure(&"too_few_persons", view(), {"missing": validation["missing"], "min": PersonNameRules.MIN_PERSONS})
	if _draft.confirmed:
		return SetupResult.success(view())
	_draft.confirmed = true
	_draft.has_unconfirmed_changes = false
	var v := view()
	changed.emit(v)
	return SetupResult.success(v)


## Verwirft den Entwurf vollständig (Verwerfen beim Verlassen, Neu beginnen).
func reset() -> void:
	_draft = SetupDraft.new()
	changed.emit(view())


## Verlassen braucht eine Rückfrage: unbestätigte Änderungen an einer nicht leeren Liste.
func needs_leave_confirmation() -> bool:
	return _draft.has_unconfirmed_changes and not _draft.persons.is_empty()


# --- Sicht ------------------------------------------------------------------------------------------

## Sicht für die Darstellung (immer eine neue Kopie).
func view() -> Dictionary:
	var dup := _draft.duplicate_ids()
	var persons: Array = []
	for i: int in _draft.persons.size():
		var p := _draft.persons[i]
		persons.append({"person_id": p.person_id, "number": i + 1, "name": p.name, "duplicate": dup.has(p.person_id)})
	var validation := _draft.validation()
	return {
		"persons": persons,
		"count": _draft.persons.size(),
		"min_persons": PersonNameRules.MIN_PERSONS,
		"max_persons": PersonNameRules.MAX_PERSONS,
		"max_name_length": PersonNameRules.MAX_NAME_LENGTH,
		"can_add": not bool(validation["at_maximum"]),
		"can_confirm": bool(validation["valid"]) and not _draft.confirmed,
		"confirmed": _draft.confirmed,
		"has_unconfirmed_changes": _draft.has_unconfirmed_changes,
		"is_empty": _draft.persons.is_empty(),
		"duplicate_count": dup.size(),
		"next_person_id": _draft.next_person_id,
		"validation": validation,
	}


# --- intern -----------------------------------------------------------------------------------------

func _create(name: String) -> int:
	var id := _draft.next_person_id
	_draft.next_person_id += 1
	_draft.persons.append(SetupPerson.new(id, name, id))
	return id


func _commit(ids: Array[int], warnings: Array[StringName]) -> SetupResult:
	_draft.confirmed = false
	_draft.has_unconfirmed_changes = true
	var v := view()
	changed.emit(v)
	return SetupResult.success(v, ids, warnings)


func _name_details(name: String) -> Dictionary:
	return {"name": name, "length": name.length(), "max": PersonNameRules.MAX_NAME_LENGTH}
