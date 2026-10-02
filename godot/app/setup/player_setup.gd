class_name PlayerSetup
extends RefCounted
## Anwendungsschicht des Setups „Neue Partie“ (Spieler → Rollen → Verteilung → Sitzordnung):
## einzige Wahrheit über Personen, IDs, Rollenwahl, Verteilung, Sitzordnung, Wizard-Schritt und
## Bestätigungen.
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


## Ersetzt den gesamten Entwurf durch neue Personen mit den genannten Namen in dieser Reihenfolge (gespeicherte Gruppe
## laden): frische Personen-IDs, keine Rollenwahl, Verteilung oder Sitzordnung. Alle Namen oder keiner; dieselben
## Namensregeln und dieselbe Höchstzahl wie beim Import.
func replace_persons(raw_names: Array) -> SetupResult:
	var names: Array[String] = []
	for raw: Variant in raw_names:
		names.append(PersonNameRules.normalize(str(raw)))
	if names.is_empty():
		return SetupResult.failure(&"import_empty", view())
	var invalid: Array[Dictionary] = []
	for i: int in names.size():
		var error := PersonNameRules.error_for(names[i])
		if error != &"":
			invalid.append({"position": i + 1, "name": names[i], "error": error})
	var details := {"current": 0, "incoming": names.size(), "max": PersonNameRules.MAX_PERSONS, "max_length": PersonNameRules.MAX_NAME_LENGTH}
	if not invalid.is_empty():
		details["exceeds_max"] = names.size() > PersonNameRules.MAX_PERSONS
		return SetupResult.failure(&"invalid_entries", view(), details, invalid)
	if names.size() > PersonNameRules.MAX_PERSONS:
		return SetupResult.failure(&"too_many_persons", view(), details)
	_draft = SetupDraft.new()
	var warnings: Array[StringName] = []
	var ids: Array[int] = []
	for name: String in names:
		if _draft.has_duplicate_of(name) and not warnings.has(&"duplicate_name"):
			warnings.append(&"duplicate_name")
		ids.append(_create(name))
	return _commit(ids, warnings, true)


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
	var open_seating := not _draft.seating.confirmed and _draft.seating.order != _draft.person_ids()
	return _draft.has_unconfirmed_changes or open_roles or open_distribution or open_seating


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

## Anzahl setzen. Eine konfigurierte Trugbilderwolf-Kopie fällt dabei nie stillschweigend weg:
## dann `confirmation_required` mit `copy_id` und `number` der betroffenen Kopie.
func set_role_count(role: StringName, count: int) -> SetupResult:
	var current: int = _draft.roles.counts.get(role, 0)
	var details := {"role": role, "count": count, "current": current}
	var blocking := RoleSetup.copy_blocking_decrease(_draft, role)
	if blocking != null:
		details["copy_id"] = blocking.copy_id
		details["number"] = _draft.roles.copy_number(blocking)
	return _apply(RoleSetup.set_role_count(_draft, role, count), details)


## Scheinrolle einer Trugbilderwolf-Kopie ausdrücklich festlegen (DR-08).
func set_decoy_appearance(copy_id: int, appearance: StringName) -> SetupResult:
	return _apply(RoleSetup.set_copy_appearance(_draft, copy_id, appearance), {"copy_id": copy_id, "appearance": appearance})


## Eine bestimmte Kopie entfernen; übrige Kopien und ihre Scheinrollen bleiben.
func remove_decoy_copy(copy_id: int) -> SetupResult:
	return _apply(RoleSetup.remove_copy(_draft, copy_id), {"copy_id": copy_id})


func change_role_count(role: StringName, delta: int) -> SetupResult:
	if not SetupRoleCatalog.has_role(role):
		return SetupResult.failure(&"unknown_role", view(), {"role": role})
	return set_role_count(role, _draft.roles.counts.get(role, 0) + delta)


## Partie mit Totenreichkarten (Standard aus). Eine bestätigte Rollenwahl verliert dabei ihre Bestätigung.
func set_death_cards(on: bool) -> SetupResult:
	return _apply(RoleSetup.set_death_cards(_draft, on), {"death_cards": on})


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


## `unit`: Rollen-ID oder, bei Trugbilderwolf, der Schlüssel einer konkreten Kopie.
func assign_role(person_id: int, unit: StringName) -> SetupResult:
	return _apply(RoleSetup.assign_role(_draft, person_id, unit), {"person_id": person_id, "unit": unit})


func unassign_role(person_id: int) -> SetupResult:
	return _apply(RoleSetup.unassign_role(_draft, person_id), {"person_id": person_id})


func swap_roles(first_id: int, second_id: int) -> SetupResult:
	return _apply(RoleSetup.swap_roles(_draft, first_id, second_id), {"person_ids": [first_id, second_id]})


func confirm_distribution() -> SetupResult:
	return _apply(RoleSetup.confirm_distribution(_draft))


# --- Sitzordnung ------------------------------------------------------------------------------------

## Tauscht die Plätze zweier Personen. Nur die Anordnung ändert sich; Name, Rolle und alle anderen
## Daten bleiben an der Personen-ID. Hebt die Bestätigung der Sitzordnung auf.
func swap_seats(first_id: int, second_id: int) -> SetupResult:
	var details := {"person_ids": [first_id, second_id]}
	var error := _step_block(SetupDraft.STEP_SEATING)
	if error == &"" and (_draft.index_of(first_id) == -1 or _draft.index_of(second_id) == -1):
		error = &"unknown_person"
	if error == &"" and first_id == second_id:
		error = &"same_person"
	if error != &"":
		return SetupResult.failure(error, view(), details)
	_draft.seating.swap(first_id, second_id)
	_draft.seating.confirmed = false
	_draft.seating.invalidated = &""
	var v := view()
	changed.emit(v)
	return SetupResult.success(v, [first_id, second_id] as Array[int])


## Bestätigt die Sitzordnung: Der Setup-Entwurf ist vollständig. Kein Befehl, kein GameState.
func confirm_seating() -> SetupResult:
	var error := _step_block(SetupDraft.STEP_SEATING)
	if error != &"":
		return SetupResult.failure(error, view())
	if _draft.seating.confirmed:
		return SetupResult.success(view())
	_draft.seating.confirmed = true
	_draft.seating.invalidated = &""
	var v := view()
	changed.emit(v)
	return SetupResult.success(v)


## Reine Startdaten des vollständig bestätigten Entwurfs in `details` (keine Änderung):
## players [{id, name}] in Listenreihenfolge, seat_order [id…] ab Platz 1, roles {"<id>": Rolle}
## aus der festen Zuordnung und appearances {"<id>": Scheinrolle} nur für Kopien mit Pflicht-
## Scheinrolle. Fehler: Vorbedingungen der Sitzordnung oder `seating_not_confirmed`.
func start_data() -> SetupResult:
	var error := _step_block(SetupDraft.STEP_SEATING)
	if error == &"" and not _draft.seating.confirmed:
		error = &"seating_not_confirmed"
	if error != &"":
		return SetupResult.failure(error, view())
	var players: Array = []
	var roles := {}
	var appearances := {}
	for p: SetupPerson in _draft.persons:
		players.append({"id": p.person_id, "name": p.name})
		var unit: StringName = _draft.distribution.assignment[p.person_id]
		roles[str(p.person_id)] = String(RoleCopy.role_of(unit))
		var copy := _draft.roles.copy_by_key(unit) if RoleCopy.is_copy_key(unit) else null
		if copy != null:
			appearances[str(p.person_id)] = String(copy.appears_as)
	var result := SetupResult.success(view())
	result.details = {"players": players, "seat_order": _draft.seating.order.duplicate(), "roles": roles, "appearances": appearances, "death_cards": _draft.roles.death_cards}
	return result


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
		"revival_round": _draft.roles.is_revival_round(),  # DI-01: aus der Rollenwahl abgeleitet, nicht wählbar
		"is_empty": _draft.persons.is_empty(),
		"duplicate_count": dup.size(),
		"next_person_id": _draft.next_person_id,
		"validation": validation,
		"step": String(_draft.current_step),
		"steps": _steps_view(),
		"roles": _roles_view(),
		"distribution": SetupDistributionView.build(_draft),
		"seating": _seating_view(),
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
	_sync_seating(count_changed)
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
	_sync_seating(false)
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
	if step != SetupDraft.STEP_ROLES and not _draft.roles.confirmed:
		return &"roles_not_confirmed"
	if step == SetupDraft.STEP_SEATING and not _draft.distribution.confirmed:
		return &"distribution_not_confirmed"
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
		SetupDraft.STEP_SEATING: _state(_draft.seating.confirmed, _draft.seating.invalidated != &""),
	}
	for i: int in SetupDraft.STEPS.size():
		var id := SetupDraft.STEPS[i]
		out.append({"id": String(id), "number": i + 1, "state": states[id], "current": id == _draft.current_step, "reachable": _step_block(id) == &""})
	return out


static func _state(done: bool, invalid: bool) -> String:
	if done:
		return "done"
	return "invalid" if invalid else "open"


## Sitzordnung an Personen angleichen. Hinzufügen/Entfernen passt die Reihenfolge an und hebt eine
## Bestätigung auf (person_count_changed); ist ein früherer Schritt nicht mehr bestätigt, fällt nur
## die Bestätigung weg (setup_changed). Die Reihenfolge selbst bleibt erhalten.
func _sync_seating(count_changed: bool) -> void:
	var seating := _draft.seating
	if count_changed and seating.sync(_draft.person_ids()) and (seating.confirmed or seating.invalidated != &""):
		seating.confirmed = false
		seating.invalidated = SeatingDraft.INVALIDATED_PERSONS
	if _step_block(SetupDraft.STEP_SEATING) != &"":
		seating.lift(SeatingDraft.INVALIDATED_SETUP)


## Sicht der Sitzordnung: nur Platznummer, Personen-ID und Name. Enthält bewusst keine Rolle,
## Scheinrolle oder Kopie; die Verteilung bleibt privat.
func _seating_view() -> Dictionary:
	var seating := _draft.seating
	var names := {}
	for p: SetupPerson in _draft.persons:
		names[p.person_id] = p.name
	var seats: Array = []
	for i: int in seating.order.size():
		var id := seating.order[i]
		seats.append({"seat": i + 1, "person_id": id, "name": names.get(id, "")})
	var reachable := _step_block(SetupDraft.STEP_SEATING) == &""
	return {
		"seats": seats,
		"person_count": seats.size(),
		"confirmed": seating.confirmed,
		"can_confirm": reachable and not seating.confirmed,
		"invalidated": String(seating.invalidated),
		"ready": reachable and seating.confirmed,
	}


func _roles_view() -> Dictionary:
	var v := _draft.roles.view(_draft.persons.size())
	v["can_confirm"] = bool(v["valid"]) and _draft.confirmed
	v["is_suggestion"] = RoleSetup.is_suggestion(_draft)
	return v
