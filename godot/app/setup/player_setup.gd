class_name PlayerSetup
extends RefCounted
## Anwendungsschicht des Setups „Neue Partie“ (Spieler → Rollen → Verteilung): einzige
## Wahrheit über Personen, IDs, Rollenwahl, Verteilung, Wizard-Schritt und Bestätigungen.
## Die UI stellt nur dar und ruft die Operationen auf. Jede Operation ist atomar: bei
## Ablehnung bleibt der Entwurf unverändert. Rollen- und Verteilungslogik liegt in
## RoleSetup, RolePoolDraft, DistributionDraft und RoleDistribution.
## Erzeugt keinen GameState und keinen Befehl; das Ergebnis bleibt ein Entwurf im Speicher
## (AppContext), bis ein späterer Schritt daraus den Spielaufbau baut.

signal changed(view: Dictionary)  ## nach jeder angenommenen Änderung (auch Schrittwechsel, Verwerfen)

## Quelle des ersten Setup-Seeds (nur beim ersten bewussten Verteilen gerufen). Standard:
## AppPlatform.initial_seed() (Systemzeit und Laufzeitzähler); Tests setzen einen festen Wert.
var seed_source: Callable = func() -> int: return AppPlatform.initial_seed()

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
	return _commit([id], warnings, true)


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
	var result := _commit(ids, warnings, true)
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
	return _commit(ids, [], true)


## Bestätigt den Namensschritt (6 bis 24 Personen; Dubletten erlaubt).
func confirm() -> SetupResult:
	var validation := _draft.validation()
	if not bool(validation["valid"]):
		return SetupResult.failure(&"too_few_persons", view(), {"missing": validation["missing"], "min": PersonNameRules.MIN_PERSONS})
	if _draft.confirmed:
		return SetupResult.success(view())
	_draft.confirmed = true
	_draft.has_unconfirmed_changes = false
	_draft.players_invalidated = false
	var v := view()
	changed.emit(v)
	return SetupResult.success(v)


## Verwirft den Entwurf vollständig (Verwerfen beim Verlassen, Neu beginnen).
func reset() -> void:
	_draft = SetupDraft.new()
	changed.emit(view())


## Verlassen braucht eine Rückfrage: unbestätigte Änderungen an einer nicht leeren Liste,
## eine unbestätigte Rollenwahl oder eine unbestätigte Zuordnung.
func needs_leave_confirmation() -> bool:
	if _draft.persons.is_empty():
		return false
	var open_roles := _draft.roles.total() > 0 and not _draft.roles.confirmed
	var open_distribution := _draft.distribution.has_assignment() and not _draft.distribution.confirmed
	return _draft.has_unconfirmed_changes or open_roles or open_distribution


# --- Wizard -----------------------------------------------------------------------------------------

## Wechselt den Setup-Schritt, nur wenn alle Vorbedingungen erfüllt sind. Kein Befehl, keine
## Datenänderung; ein Doppelklick kann keinen Schritt überspringen.
func go_to_step(step: StringName) -> SetupResult:
	if not SetupDraft.STEPS.has(step):
		return SetupResult.failure(&"unknown_step", view(), {"step": step})
	var error := _step_block(step)
	if error != &"":
		return SetupResult.failure(error, view(), {"step": step})
	if _draft.current_step != step:
		_draft.current_step = step
		changed.emit(view())
	return SetupResult.success(view())


# --- Rollenwahl -------------------------------------------------------------------------------------

func set_role_count(role: StringName, count: int) -> SetupResult:
	var current: int = _draft.roles.counts.get(role, 0)
	return _apply(RoleSetup.set_role_count(_draft, role, count), {"role": role, "count": count, "current": current})


func change_role_count(role: StringName, delta: int) -> SetupResult:
	if not SetupRoleCatalog.has_role(role):
		return SetupResult.failure(&"unknown_role", view(), {"role": role})
	return set_role_count(role, _draft.roles.counts.get(role, 0) + delta)


func reset_roles() -> SetupResult:
	return _apply(RoleSetup.reset_roles(_draft))


## Übernimmt den Vorschlag. Eine abweichende Auswahl wird nur mit `force` überschrieben
## (sonst `confirmation_required`, die UI fragt nach).
func apply_suggestion(force: bool = false) -> SetupResult:
	return _apply(RoleSetup.apply_suggestion(_draft, force))


## Bestätigt einen gültigen Pool und wechselt zur Verteilung.
func confirm_roles() -> SetupResult:
	var issues := _draft.roles.issues(_draft.persons.size())
	return _apply(RoleSetup.confirm_roles(_draft), {"issues": issues})


# --- Verteilung -------------------------------------------------------------------------------------

## Moduswechsel; eine bestehende Zuordnung wird nur mit `force` verworfen.
func set_distribution_mode(mode: StringName, force: bool = false) -> SetupResult:
	return _apply(RoleSetup.set_mode(_draft, mode, force), {"mode": mode})


func distribute_randomly() -> SetupResult:
	return _apply(RoleSetup.distribute_randomly(_draft, seed_source))


func reshuffle() -> SetupResult:
	return _apply(RoleSetup.reshuffle(_draft))


func assign_role(person_id: int, role: StringName) -> SetupResult:
	return _apply(RoleSetup.assign_role(_draft, person_id, role, seed_source), {"person_id": person_id, "role": role})


func unassign_role(person_id: int) -> SetupResult:
	return _apply(RoleSetup.unassign_role(_draft, person_id), {"person_id": person_id})


func swap_roles(first_id: int, second_id: int) -> SetupResult:
	return _apply(RoleSetup.swap_roles(_draft, first_id, second_id, seed_source), {"person_ids": [first_id, second_id]})


func confirm_distribution() -> SetupResult:
	return _apply(RoleSetup.confirm_distribution(_draft))


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
		"step": String(_draft.current_step),
		"steps": _steps_view(),
		"roles": _roles_view(),
		"distribution": SetupDistributionView.build(_draft),
	}


# --- intern -----------------------------------------------------------------------------------------

func _create(name: String) -> int:
	var id := _draft.next_person_id
	_draft.next_person_id += 1
	_draft.persons.append(SetupPerson.new(id, name, id))
	return id


func _commit(ids: Array[int], warnings: Array[StringName], count_changed: bool = false) -> SetupResult:
	if _draft.confirmed:
		_draft.players_invalidated = true
	_draft.confirmed = false
	_draft.has_unconfirmed_changes = true
	if count_changed:
		RoleSetup.persons_changed(_draft)
	_clamp_step()
	var v := view()
	changed.emit(v)
	return SetupResult.success(v, ids, warnings)


func _name_details(name: String) -> Dictionary:
	return {"name": name, "length": name.length(), "max": PersonNameRules.MAX_NAME_LENGTH}


## Ergebnis einer RoleSetup-Operation: bei Erfolg Schritt prüfen und Änderung melden.
func _apply(error: StringName, details: Dictionary = {}) -> SetupResult:
	if error != &"":
		return SetupResult.failure(error, view(), details)
	_clamp_step()
	var v := view()
	changed.emit(v)
	return SetupResult.success(v)


## Grund, warum `step` nicht erreichbar ist (&"" = erreichbar).
func _step_block(step: StringName) -> StringName:
	if step == SetupDraft.STEP_PLAYERS:
		return &""
	if not _draft.confirmed:
		return &"players_not_confirmed"
	if step == SetupDraft.STEP_DISTRIBUTION and not _draft.roles.confirmed:
		return &"roles_not_confirmed"
	return &""


## Fällt auf den letzten erreichbaren Schritt zurück, wenn eine Änderung den aktuellen sperrt.
func _clamp_step() -> void:
	while _step_block(_draft.current_step) != &"":
		_draft.current_step = SetupDraft.STEPS[SetupDraft.STEPS.find(_draft.current_step) - 1]


func _steps_view() -> Array:
	var out: Array = []
	var states := {
		SetupDraft.STEP_PLAYERS: _state(_draft.confirmed, _draft.players_invalidated),
		SetupDraft.STEP_ROLES: _state(_draft.roles.confirmed, _draft.roles.invalidated != &""),
		SetupDraft.STEP_DISTRIBUTION: _state(_draft.distribution.confirmed, _draft.distribution.invalidated != &""),
	}
	for i: int in SetupDraft.STEPS.size():
		var id := SetupDraft.STEPS[i]
		out.append({"id": String(id), "number": i + 1, "state": states[id], "current": id == _draft.current_step, "reachable": _step_block(id) == &""})
	return out


static func _state(done: bool, invalid: bool) -> String:
	if done:
		return "done"
	return "invalid" if invalid else "open"


func _roles_view() -> Dictionary:
	var v := _draft.roles.view(_draft.persons.size())
	v["can_confirm"] = bool(v["valid"]) and _draft.confirmed
	v["is_suggestion"] = RoleSetup.is_suggestion(_draft)
	return v
