class_name RoleSetup
extends RefCounted
## Operationen des Rollen- und Verteilungsschritts auf einem SetupDraft, einschließlich der
## zentralen Invalidierungsregeln. Jede Operation liefert &"" bei Erfolg oder einen
## Fehlercode; bei Ablehnung bleibt der Entwurf unverändert. PlayerSetup ruft sie auf,
## meldet Änderungen und baut daraus SetupResult und Sicht.
##
## Invalidierung:
##   Person hinzufügen/entfernen → Verteilung verwerfen; bestätigter Pool, dessen Summe nicht
##     mehr passt, verliert die Bestätigung (Grund person_count_changed)
##   Name ändern → Pool und Verteilung bleiben (Zuordnung hängt an der Personen-ID)
##   Rollenanzahl ändern → Bestätigung aufheben (roles_changed), Verteilung verwerfen
##   Pool erneut bestätigen → Verteilung bleibt nur bei semantisch identischem Pool
##   Neu mischen → nur zufällige Zuordnung und Scheinrollen ändern sich


# --- Personen -----------------------------------------------------------------------------------------

static func persons_changed(d: SetupDraft) -> void:
	d.distribution.clear(DistributionDraft.INVALIDATED_PERSONS)
	if d.roles.confirmed and d.roles.total() != d.persons.size():
		d.roles.confirmed = false
		d.roles.invalidated = RolePoolDraft.INVALIDATED_PERSONS


# --- Rollenwahl ---------------------------------------------------------------------------------------

static func set_role_count(d: SetupDraft, role: StringName, count: int) -> StringName:
	if not SetupRoleCatalog.has_role(role):
		return &"unknown_role"
	if count < 0:
		return &"negative_count"
	if count > SetupRoleCatalog.copy_limit(role, d.persons.size()) and count > d.roles.counts.get(role, 0):
		return &"above_maximum"
	if d.roles.counts.get(role, 0) != count:
		d.roles.counts[role] = count
		_roles_changed(d)
	return &""


static func reset_roles(d: SetupDraft) -> StringName:
	var changed := false
	for id: StringName in d.roles.counts:
		if d.roles.counts[id] != 0:
			d.roles.counts[id] = 0
			changed = true
	if changed:
		_roles_changed(d)
	return &""


## Vorschlag übernehmen; eine abweichende bestehende Auswahl nur mit `force`.
static func apply_suggestion(d: SetupDraft, force: bool) -> StringName:
	var count := d.persons.size()
	if count < PersonNameRules.MIN_PERSONS or count > PersonNameRules.MAX_PERSONS:
		return &"too_few_persons" if count < PersonNameRules.MIN_PERSONS else &"too_many_persons"
	var suggestion := RoleSuggestion.for_count(count)
	var differs := false
	for id: StringName in d.roles.counts:
		if d.roles.counts[id] != int(suggestion.get(String(id), 0)):
			differs = true
	if not differs:
		return &""
	if d.roles.total() > 0 and not force:
		return &"confirmation_required"
	for id: StringName in d.roles.counts:
		d.roles.counts[id] = int(suggestion.get(String(id), 0))
	_roles_changed(d)
	return &""


static func is_suggestion(d: SetupDraft) -> bool:
	var suggestion := RoleSuggestion.for_count(d.persons.size())
	for id: StringName in d.roles.counts:
		if d.roles.counts[id] != int(suggestion.get(String(id), 0)):
			return false
	return true


static func confirm_roles(d: SetupDraft) -> StringName:
	if not d.confirmed:
		return &"players_not_confirmed"
	if not d.roles.issues(d.persons.size()).is_empty():
		return &"roles_invalid"
	d.roles.confirmed = true
	d.roles.invalidated = &""
	if d.distribution.has_assignment() and d.distribution.pool != d.roles.pool():
		d.distribution.clear(DistributionDraft.INVALIDATED_ROLES)
	d.current_step = SetupDraft.STEP_DISTRIBUTION
	return &""


static func _roles_changed(d: SetupDraft) -> void:
	if d.roles.confirmed:
		d.roles.confirmed = false
		d.roles.invalidated = RolePoolDraft.INVALIDATED_ROLES
	d.distribution.clear(DistributionDraft.INVALIDATED_ROLES)


# --- Verteilung ---------------------------------------------------------------------------------------

static func set_mode(d: SetupDraft, mode: StringName, force: bool) -> StringName:
	if mode != DistributionDraft.RANDOM and mode != DistributionDraft.MANUAL:
		return &"unknown_mode"
	if mode == d.distribution.mode:
		return &""
	if d.distribution.has_assignment() and not force:
		return &"confirmation_required"
	d.distribution.clear()
	d.distribution.invalidated = &""
	d.distribution.mode = mode
	return &""


## Zufällig verteilen. Der erste Aufruf erzeugt den Seed über `seed_source` und speichert ihn.
static func distribute_randomly(d: SetupDraft, seed_source: Callable) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.RANDOM)
	if error != &"":
		return error
	if not d.distribution.has_seed():
		error = _create_seed(d, seed_source)
		if error != &"":
			return error
	_random_fill(d)
	return &""


static func reshuffle(d: SetupDraft) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.RANDOM)
	if error != &"":
		return error
	if not d.distribution.has_assignment() or not d.distribution.has_seed():
		return &"nothing_to_reshuffle"
	d.distribution.shuffle_count += 1
	_random_fill(d)
	return &""


static func assign_role(d: SetupDraft, person_id: int, role: StringName, seed_source: Callable) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.MANUAL)
	if error != &"":
		return error
	if d.index_of(person_id) == -1:
		return &"unknown_person"
	if not SetupRoleCatalog.has_role(role):
		return &"unknown_role"
	var pool := d.roles.pool()
	if not pool.has(role):
		return &"role_not_in_pool"
	if d.distribution.assignment.get(person_id, &"") == role:
		return &""
	if d.distribution.remaining(pool).get(role, 0) <= 0:
		return &"no_copy_available"
	d.distribution.assignment[person_id] = role
	return _manual_changed(d, seed_source)


static func unassign_role(d: SetupDraft, person_id: int) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.MANUAL)
	if error != &"":
		return error
	if d.index_of(person_id) == -1:
		return &"unknown_person"
	if not d.distribution.assignment.has(person_id):
		return &""
	d.distribution.assignment.erase(person_id)
	return _manual_changed(d, Callable())


static func swap_roles(d: SetupDraft, first_id: int, second_id: int, seed_source: Callable) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.MANUAL)
	if error != &"":
		return error
	if d.index_of(first_id) == -1 or d.index_of(second_id) == -1:
		return &"unknown_person"
	var a: StringName = d.distribution.assignment.get(first_id, &"")
	var b: StringName = d.distribution.assignment.get(second_id, &"")
	d.distribution.assignment.erase(first_id)
	d.distribution.assignment.erase(second_id)
	if b != &"":
		d.distribution.assignment[first_id] = b
	if a != &"":
		d.distribution.assignment[second_id] = a
	return _manual_changed(d, seed_source)


static func confirm_distribution(d: SetupDraft) -> StringName:
	var error := _distribution_ready(d, d.distribution.mode)
	if error != &"":
		return error
	if not d.distribution.is_complete(d.person_ids(), d.roles.pool()):
		return &"distribution_incomplete"
	d.distribution.confirmed = true
	d.distribution.invalidated = &""
	return &""


static func _distribution_ready(d: SetupDraft, mode: StringName) -> StringName:
	if not d.confirmed:
		return &"players_not_confirmed"
	if not d.roles.confirmed:
		return &"roles_not_confirmed"
	if d.distribution.mode != mode:
		return &"wrong_mode"
	return &""


static func _create_seed(d: SetupDraft, seed_source: Callable) -> StringName:
	if not seed_source.is_valid():
		return &"no_seed_source"
	var value: Variant = seed_source.call()
	if not value is int or not RoleDistribution.is_valid_seed(int(value)):
		return &"invalid_seed"
	d.distribution.base_seed = int(value)
	d.distribution.shuffle_count = 0
	return &""


static func _random_fill(d: SetupDraft) -> void:
	var dist := d.distribution
	dist.pool = d.roles.pool()
	var seed_value := dist.effective_seed()
	dist.assignment = RoleDistribution.random_assignment(d.person_ids(), dist.pool, seed_value)
	dist.appearances = RoleDistribution.appearances_for(dist.assignment, seed_value)
	dist.confirmed = false
	dist.invalidated = &""


## Nach jeder manuellen Änderung: Bestätigung aufheben; bei vollständiger Zuordnung die
## Scheinrollen deterministisch aus dem (bei Bedarf jetzt erzeugten) Seed ableiten.
static func _manual_changed(d: SetupDraft, seed_source: Callable) -> StringName:
	var dist := d.distribution
	dist.pool = d.roles.pool()
	dist.confirmed = false
	dist.invalidated = &""
	dist.appearances.clear()
	if dist.is_complete(d.person_ids(), dist.pool):
		if not dist.has_seed() and seed_source.is_valid():
			_create_seed(d, seed_source)
		if dist.has_seed():
			dist.appearances = RoleDistribution.appearances_for(dist.assignment, dist.effective_seed())
	return &""
