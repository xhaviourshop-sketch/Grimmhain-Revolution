class_name PlayerSetup
extends RefCounted
## Anwendungsschicht des Setups „Neue Partie“ in drei Schritten (Runde → Namen → Rollen): einzige Wahrheit über Zielzahl, Akt,
## Personen und IDs, Namensreihenfolge (= Sitzordnung), Rollenwahl, Verteilungsmodus, Zuordnung und Wizard-Schritt.
## Die UI stellt nur dar und ruft die Operationen auf. Jede Operation ist atomar: bei Ablehnung bleibt der Entwurf unverändert.
## Es gibt keine Bestätigungen (DA-89): Startbereitschaft wird aus dem Inhalt berechnet (`blockers`, `warnings`, `can_start`).
## Rollen- und Verteilungslogik liegt in RoleSetup, RolePoolDraft, DistributionDraft und RoleDistribution.
## Erzeugt keinen GameState und keinen Befehl; das Ergebnis bleibt ein Entwurf im Speicher (AppContext), bis GameStart daraus
## den Spielaufbau baut.

signal changed(view: Dictionary)  ## nach jeder angenommenen Änderung (auch Schrittwechsel, Verwerfen)

## Quelle des ersten Setup-Seeds (nur beim ersten bewussten Mischen oder Verteilen gerufen). Standard:
## AppPlatform.initial_seed() (Systemzeit und Laufzeitzähler); Tests setzen einen festen Wert.
var seed_source: Callable = func() -> int: return AppPlatform.initial_seed()

var _draft: SetupDraft = SetupDraft.new()


# --- Runde (Schritt 1) ------------------------------------------------------------------------------

## Zielzahl der Runde (6 bis 24). Die Namen müssen sie im Schritt „Namen“ erreichen.
func set_player_count(count: int) -> SetupResult:
	if count < PersonNameRules.MIN_PERSONS or count > PersonNameRules.MAX_PERSONS:
		return SetupResult.failure(&"player_count_out_of_range", view(), {"count": count, "min": PersonNameRules.MIN_PERSONS, "max": PersonNameRules.MAX_PERSONS})
	if count != _draft.player_count:
		_draft.player_count = count
		_clamp_step()
		changed.emit(view())
	return SetupResult.success(view())


## Gleicht die Zielzahl an die vorhandenen Namen an (Knopf „Spielerzahl anpassen“).
func fit_player_count_to_names() -> SetupResult:
	return set_player_count(_draft.persons.size()) if _draft.validation()["valid"] \
			else SetupResult.failure(&"too_few_persons", view(), {"missing": _draft.validation()["missing"], "min": PersonNameRules.MIN_PERSONS})


## Wählt den Akt (Rollen-Set). Ein anderer Akt verwirft die bisherige Rollenwahl, der Vorschlag entsteht beim Öffnen des Rollenschritts neu.
func set_act(act: StringName) -> SetupResult:
	if not ActCatalog.has_act(act):
		return SetupResult.failure(&"unknown_act", view(), {"act": act})
	if act != _draft.act:
		_draft.act = act
		RoleSetup.reset_roles(_draft)
		_clamp_step()
		if _draft.current_step == SetupDraft.STEP_ROLES:
			_ensure_role_proposal()
		changed.emit(view())
	return SetupResult.success(view())


## Modus der Verteilung: zufällig durch die App oder echte Karten (der Spielleiter weist zu). Ein Wechsel verwirft die Zuordnung.
func set_distribution_mode(mode: StringName) -> SetupResult:
	return _apply(RoleSetup.set_mode(_draft, mode), {"mode": mode})


# --- Personen (Schritt 2) ---------------------------------------------------------------------------

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


## Ersetzt die Namen durch neue Personen mit den genannten Namen in dieser Reihenfolge (gespeicherte Gruppe laden): frische
## Personen-IDs, keine Rollenwahl und keine Zuordnung; die Zielzahl folgt der Gruppe, Akt und Modus bleiben. Alle Namen oder keiner; dieselben Namensregeln und
## dieselbe Höchstzahl wie beim Import.
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
	var fresh := SetupDraft.new()
	fresh.player_count = clampi(names.size(), PersonNameRules.MIN_PERSONS, PersonNameRules.MAX_PERSONS)  # eine Gruppe bestimmt die Spielerzahl
	fresh.act = _draft.act
	fresh.current_step = _draft.current_step
	fresh.distribution.mode = _draft.distribution.mode
	_draft = fresh
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
		return SetupResult.success(view(), ids)
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


## Verschiebt eine Person um `delta` Plätze (-1 früher, +1 später) in der Namensreihenfolge, die zugleich die Sitzordnung im
## Uhrzeigersinn ab Platz 1 ist. Nur die Anordnung ändert sich; Personen-ID, Name, Rollenwahl und Zuordnung bleiben. Am Rand: keine Änderung.
func move_person(person_id: int, delta: int) -> SetupResult:
	var index := _draft.index_of(person_id)
	if index == -1:
		return SetupResult.failure(&"unknown_person", view(), {"person_id": person_id})
	var target := clampi(index + delta, 0, _draft.persons.size() - 1)
	var ids: Array[int] = [person_id]
	if target == index:
		return SetupResult.success(view(), ids)
	var person := _draft.persons[index]
	_draft.persons.remove_at(index)
	_draft.persons.insert(target, person)
	return _commit(ids, [])


## Mischt die Namensreihenfolge. Zufall nur über den gespeicherten Generator: Der erste Aufruf legt den Seed über `seed_source` an,
## jeder weitere mischt mit dem nächsten abgeleiteten Seed (gleiche Eingabe und gleicher Seed ergeben dieselbe Reihenfolge).
func shuffle_persons() -> SetupResult:
	if _draft.persons.size() < 2:
		return SetupResult.failure(&"too_few_persons", view(), {"missing": maxi(0, PersonNameRules.MIN_PERSONS - _draft.persons.size()), "min": PersonNameRules.MIN_PERSONS})
	if _draft.order_seed == DistributionDraft.NO_SEED:
		var value: Variant = seed_source.call() if seed_source.is_valid() else null
		if not value is int or not RoleDistribution.is_valid_seed(int(value)):
			return SetupResult.failure(&"invalid_seed", view())
		_draft.order_seed = int(value)
	var seed_value := RoleDistribution.effective_seed(_draft.order_seed, _draft.order_shuffles)
	_draft.order_shuffles += 1
	var ordered: Array = SeededRng.new(seed_value).shuffled(_draft.persons)
	var persons: Array[SetupPerson] = []
	for p: Variant in ordered:
		persons.append(p as SetupPerson)
	_draft.persons = persons
	return _commit(_draft.person_ids(), [])


## Verwirft den Entwurf vollständig (Verwerfen beim Verlassen, Neu beginnen).
func reset() -> void:
	_draft = SetupDraft.new()
	changed.emit(view())


## Verlassen braucht eine Rückfrage, sobald Personen erfasst sind.
func needs_leave_confirmation() -> bool:
	return not _draft.persons.is_empty()


# --- Wizard -----------------------------------------------------------------------------------------

## Wechselt den Setup-Schritt, nur wenn alle Vorbedingungen erfüllt sind. Kein Befehl, keine Datenänderung außer dem Vorschlag beim
## ersten Öffnen des Rollenschritts; ein Doppelklick kann keinen Schritt überspringen. Zurück ist immer möglich und verliert nichts.
func go_to_step(step: StringName) -> SetupResult:
	if not SetupDraft.STEPS.has(step):
		return SetupResult.failure(&"unknown_step", view(), {"step": step})
	var error := _step_block(step)
	if error != &"":
		return SetupResult.failure(error, view(), {"step": step})
	if _draft.current_step != step:
		_draft.current_step = step
		if step == SetupDraft.STEP_ROLES:
			_ensure_role_proposal()
		changed.emit(view())
	return SetupResult.success(view())


# --- Rollenwahl (Schritt 3) -------------------------------------------------------------------------

## Anzahl setzen. Eine konfigurierte Trugbilderwolf-Kopie fällt dabei nie stillschweigend weg: dann `confirmation_required`.
func set_role_count(role: StringName, count: int) -> SetupResult:
	return _apply(RoleSetup.set_role_count(_draft, role, count), {"role": role, "count": count})


## Scheinrolle einer Trugbilderwolf-Kopie ausdrücklich festlegen (DR-08).
func set_decoy_appearance(copy_id: int, appearance: StringName) -> SetupResult:
	return _apply(RoleSetup.set_copy_appearance(_draft, copy_id, appearance), {"copy_id": copy_id, "appearance": appearance})


## Rolle antippen, „entfernen“: eine Kopie der Rolle aus der Auswahl nehmen.
func remove_role(role: StringName) -> SetupResult:
	return _apply(RoleSetup.remove_one(_draft, role), {"role": role})


## „Rolle hinzufügen“: eine Kopie der Rolle in die Auswahl nehmen.
func add_role(role: StringName) -> SetupResult:
	return _apply(RoleSetup.add_one(_draft, role), {"role": role})


## Rolle antippen, „tauschen“: eine Kopie von `old` durch `new` ersetzen.
func replace_role(old: StringName, new: StringName) -> SetupResult:
	return _apply(RoleSetup.replace_one(_draft, old, new), {"old": old, "new": new})


## Partie mit Totenreichkarten (Standard aus). Ausschalten nimmt den Kartenschlucker aus der Auswahl.
func set_death_cards(on: bool) -> SetupResult:
	return _apply(RoleSetup.set_death_cards(_draft, on), {"death_cards": on})


## „Empfehlung übernehmen“: ersetzt die Auswahl durch den Vorschlag des Aktes (die Wahl ist ausdrücklich, keine Rückfrage).
func apply_suggestion() -> SetupResult:
	return _apply(RoleSetup.apply_suggestion(_draft, true), {"act": _draft.act})


# --- Verteilung (Echte Karten) ----------------------------------------------------------------------

func distribute_randomly() -> SetupResult:
	return _apply(RoleSetup.distribute_randomly(_draft, seed_source))


## `unit`: Rollen-ID oder, bei Trugbilderwolf, der Schlüssel einer konkreten Kopie.
func assign_role(person_id: int, unit: StringName) -> SetupResult:
	return _apply(RoleSetup.assign_role(_draft, person_id, unit), {"person_id": person_id, "unit": unit})


func unassign_role(person_id: int) -> SetupResult:
	return _apply(RoleSetup.unassign_role(_draft, person_id), {"person_id": person_id})


func swap_roles(first_id: int, second_id: int) -> SetupResult:
	return _apply(RoleSetup.swap_roles(_draft, first_id, second_id), {"person_ids": [first_id, second_id]})


# --- Start ------------------------------------------------------------------------------------------

## Macht den Entwurf startbereit und liefert die Startdaten (`start_data`): Im Modus „App verteilt zufällig“ verteilt sie jetzt (mit dem
## gespeicherten Seed), im Modus „Echte Karten“ müssen alle Personen zugeordnet sein. Fehler: erster Blocker oder `distribution_incomplete`.
func prepare_start() -> SetupResult:
	var blocked := blockers()
	if not blocked.is_empty():
		return SetupResult.failure(blocked[0], view(), {"blockers": blocked})
	if _draft.distribution.mode == DistributionDraft.RANDOM:
		var error := RoleSetup.distribute_randomly(_draft, seed_source)
		if error != &"":
			return SetupResult.failure(error, view())
		changed.emit(view())
	return start_data()


## Reine Startdaten (keine Änderung): players [{id, name}] in Listenreihenfolge, seat_order [id…] ab Platz 1 (= Listenreihenfolge),
## roles {"<id>": Rolle} aus der Zuordnung und appearances {"<id>": Scheinrolle} nur für Kopien mit Pflicht-Scheinrolle.
## Fehler: erster Blocker oder `distribution_incomplete`.
func start_data() -> SetupResult:
	var blocked := blockers()
	if not blocked.is_empty():
		return SetupResult.failure(blocked[0], view(), {"blockers": blocked})
	if not _draft.distribution.is_complete(_draft.person_ids(), _draft.roles.keys()):
		return SetupResult.failure(&"distribution_incomplete", view())
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
	result.details = {"players": players, "seat_order": _draft.person_ids(), "roles": roles, "appearances": appearances, "death_cards": _draft.roles.death_cards}
	return result


## Gründe, warum die Partie nicht starten kann (leer = startbar, ohne die noch fehlende Zuordnung im Modus „Echte Karten“). Nur was den
## Start technisch unmöglich macht: Zielzahl und Namen, Akt zu klein, Summe, Höchstzahl, Wolf, Dorf, Scheinrolle, Totenreichkarten.
func blockers() -> Array[StringName]:
	var out: Array[StringName] = []
	var validation := _draft.validation()
	if not bool(validation["valid"]):
		out.append(&"too_few_persons" if int(validation["count"]) < PersonNameRules.MIN_PERSONS else &"too_many_persons")
	elif _draft.persons.size() != _draft.player_count:
		out.append(&"names_incomplete")
	out.append_array(_draft.roles.issues(_draft.persons.size()))
	return out


# --- Sicht ------------------------------------------------------------------------------------------

## Sicht für die Darstellung (immer eine neue Kopie).
func view() -> Dictionary:
	var dup := _draft.duplicate_ids()
	var persons: Array = []
	for i: int in _draft.persons.size():
		var p := _draft.persons[i]
		persons.append({"person_id": p.person_id, "number": i + 1, "name": p.name, "duplicate": dup.has(p.person_id)})
	var validation := _draft.validation()
	var count := _draft.persons.size()
	var found := blockers()
	var distribution := SetupDistributionView.build(_draft)
	var manual := _draft.distribution.mode == DistributionDraft.MANUAL
	var assignment_ok := bool(distribution["complete"]) if manual else true
	var roles := _roles_view()
	return {
		"persons": persons,
		"count": count,
		"player_count": _draft.player_count,
		"min_persons": PersonNameRules.MIN_PERSONS,
		"max_persons": PersonNameRules.MAX_PERSONS,
		"max_name_length": PersonNameRules.MAX_NAME_LENGTH,
		"can_add": not bool(validation["at_maximum"]),
		"is_empty": _draft.persons.is_empty(),
		"duplicate_count": dup.size(),
		"next_person_id": _draft.next_person_id,
		"validation": validation,
		"names_complete": bool(validation["valid"]) and count == _draft.player_count,
		"names_missing": maxi(0, _draft.player_count - count),
		"fit_count": count if bool(validation["valid"]) and count != _draft.player_count else 0,
		"revival_round": _draft.roles.is_revival_round(),  # DI-01: aus der Rollenwahl abgeleitet, nicht wählbar
		"act": String(_draft.act),
		"acts": _acts_view(),
		"proposal_teams": _proposal_teams(),
		"mode": String(_draft.distribution.mode),
		"step": String(_draft.current_step),
		"steps": _steps_view(),
		"roles": roles,
		"distribution": distribution,
		"blockers": found.map(func(code: StringName) -> String: return String(code)),
		"warnings": roles["warnings"],
		"can_start": found.is_empty() and assignment_ok,
	}


# --- intern -----------------------------------------------------------------------------------------

func _create(name: String) -> int:
	var id := _draft.next_person_id
	_draft.next_person_id += 1
	_draft.persons.append(SetupPerson.new(id, name, id))
	return id


func _commit(ids: Array[int], warnings: Array[StringName], count_changed: bool = false) -> SetupResult:
	if count_changed:
		RoleSetup.persons_changed(_draft)
		_draft.player_count = clampi(maxi(_draft.player_count, _draft.persons.size()), PersonNameRules.MIN_PERSONS, PersonNameRules.MAX_PERSONS)
	_clamp_step()
	var v := view()
	changed.emit(v)
	return SetupResult.success(v, ids, warnings)


func _name_details(name: String) -> Dictionary:
	return {"name": name, "length": name.length(), "max": PersonNameRules.MAX_NAME_LENGTH}


## Ergebnis einer RoleSetup-Operation: bei Erfolg Scheinrollen vorbelegen, Schritt prüfen und Änderung melden.
func _apply(error: StringName, details: Dictionary = {}) -> SetupResult:
	if error != &"":
		return SetupResult.failure(error, view(), details)
	RoleSetup.autofill_appearances(_draft, seed_source)
	_clamp_step()
	var v := view()
	changed.emit(v)
	return SetupResult.success(v)


## Beim Öffnen des Rollenschritts: Die Auswahl startet leer (DA-91), nur die Scheinrollen werden vorbelegt. Eine vorhandene Auswahl bleibt, damit
## Zurück und Weiter nichts verlieren; die Empfehlung kommt erst mit `apply_suggestion` („Empfehlung übernehmen“).
func _ensure_role_proposal() -> void:
	RoleSetup.autofill_appearances(_draft, seed_source)


## Grund, warum `step` nicht erreichbar ist (&"" = erreichbar).
func _step_block(step: StringName) -> StringName:
	if step == SetupDraft.STEP_ROUND:
		return &""
	if step == SetupDraft.STEP_NAMES:
		return &""
	if not _draft.validation()["valid"] or _draft.persons.size() != _draft.player_count:
		return &"names_incomplete"
	return &""


## Fällt auf den letzten erreichbaren Schritt zurück, wenn eine Änderung den aktuellen sperrt.
func _clamp_step() -> void:
	while _step_block(_draft.current_step) != &"":
		_draft.current_step = SetupDraft.STEPS[SetupDraft.STEPS.find(_draft.current_step) - 1]


func _steps_view() -> Array:
	var out: Array = []
	var current := SetupDraft.STEPS.find(_draft.current_step)
	for i: int in SetupDraft.STEPS.size():
		var id := SetupDraft.STEPS[i]
		var state := "current" if i == current else ("done" if i < current else "open")
		out.append({"id": String(id), "number": i + 1, "state": state, "current": i == current, "reachable": _step_block(id) == &""})
	return out


func _acts_view() -> Array:
	var out: Array = []
	for act: StringName in ActCatalog.ACT_IDS:
		var capacity := ActCatalog.capacity(act, _draft.roles.death_cards)
		out.append({"id": String(act), "level": ActCatalog.level(act), "capacity": capacity, "selected": act == _draft.act})
	return out


## Dorf/Wölfe/Einzelgänger des Vorschlags für Akt und Zielzahl (Zähler in Schritt 1); leer, wenn der Akt die Zahl nicht trägt.
func _proposal_teams() -> Dictionary:
	var counts := RoleSuggestion.for_act(_draft.act, _draft.player_count, _draft.roles.death_cards)
	if counts.is_empty():
		return {}
	var teams := {String(Faction.VILLAGE): 0, String(Faction.WOLVES): 0, String(Faction.SOLO): 0}
	for key: String in counts:
		var faction := String(SetupRoleCatalog.faction_of(StringName(key)))
		teams[faction] = int(teams.get(faction, 0)) + int(counts[key])
	return teams


func _roles_view() -> Dictionary:
	var v := _draft.roles.view(_draft.persons.size())
	v["is_suggestion"] = RoleSetup.is_suggestion(_draft)
	v["act_roles"] = ActCatalog.roles(_draft.act).map(func(role: StringName) -> String: return String(role))
	return v
