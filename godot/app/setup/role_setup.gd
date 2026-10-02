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
##   Name ändern → Pool, Scheinrollen und Verteilung bleiben (Zuordnung an der Personen-ID)
##   Rollenanzahl, Kopie oder Scheinrolle ändern → Bestätigung aufheben (roles_changed),
##     Verteilung verwerfen
##   Pool erneut bestätigen → Verteilung bleibt nur bei identischen Verteilungseinheiten
##   Neu mischen → nur die Personenzuordnung ändert sich; Scheinrollen hängen an ihrer Kopie
##
## Scheinrollen (DR-08): Der Spielleiter wählt sie für jede Kopie ausdrücklich. Es gibt keine
## Vorbelegung und keine aus Zufall oder Seed abgeleitete Scheinrolle.


# --- Personen -----------------------------------------------------------------------------------------

static func persons_changed(d: SetupDraft) -> void:
	d.distribution.clear(DistributionDraft.INVALIDATED_PERSONS)
	if d.roles.confirmed and d.roles.total() != d.persons.size():
		d.roles.confirmed = false
		d.roles.invalidated = RolePoolDraft.INVALIDATED_PERSONS


# --- Rollenwahl ---------------------------------------------------------------------------------------

## Setzt die Anzahl einer Rolle. Bei Rollen mit Pflicht-Scheinrolle entstehen neue Kopien
## unkonfiguriert; beim Verringern fallen nur unkonfigurierte Kopien (von hinten) weg, eine
## konfigurierte Kopie nur über `remove_copy` (sonst `confirmation_required`).
static func set_role_count(d: SetupDraft, role: StringName, count: int) -> StringName:
	if not SetupRoleCatalog.has_role(role):
		return &"unknown_role"
	if count < 0:
		return &"negative_count"
	var current: int = d.roles.counts.get(role, 0)
	if count > current and RoleCatalog.requires_cards(role) and not d.roles.death_cards:
		return &"cards_required"  # Kartenschlucker nur mit Totenreichkarten
	if count > SetupRoleCatalog.copy_limit(role, d.persons.size()) and count > current:
		return &"above_maximum"
	if count == current:
		return &""
	if SetupRoleCatalog.requires_appearance(role):
		var removable := _unconfigured_from_end(d, role, current - count)
		if count < current and removable.size() < current - count:
			return &"confirmation_required"
		_resize_copies(d, role, count)
	d.roles.counts[role] = count
	_roles_changed(d)
	return &""


## Kopie, die ein weiteres Minus als nächstes entfernen würde (für die Rückfrage), oder null.
static func copy_blocking_decrease(d: SetupDraft, role: StringName) -> RoleCopy:
	if not SetupRoleCatalog.requires_appearance(role) or not _unconfigured_from_end(d, role, 1).is_empty():
		return null
	var copies := d.roles.copies_of(role)
	return copies[-1] if not copies.is_empty() else null


static func remove_copy(d: SetupDraft, copy_id: int) -> StringName:
	var copy := d.roles.copy_by_id(copy_id)
	if copy == null:
		return &"unknown_copy"
	d.roles.copies.erase(copy)
	d.roles.counts[copy.role_id] = d.roles.copies_of(copy.role_id).size()
	_roles_changed(d)
	return &""


## Ausdrückliche Scheinrolle einer Kopie: bekannte Rolle, die nicht als Wolf zählt (auch
## außerhalb des Pools). Leer, unbekannt oder Wolf wird atomar abgelehnt.
static func set_copy_appearance(d: SetupDraft, copy_id: int, appearance: StringName) -> StringName:
	var copy := d.roles.copy_by_id(copy_id)
	if copy == null:
		return &"unknown_copy"
	if appearance == &"":
		return &"empty_appearance"
	if not SetupRoleCatalog.has_role(appearance):
		return &"unknown_role"
	if SetupRoleCatalog.counts_as_wolf(appearance):
		return &"invalid_appearance"
	if copy.appears_as != appearance:
		copy.appears_as = appearance
		_roles_changed(d)
	return &""


## Totenreichkarten ein- oder ausschalten. Ausschalten nimmt den Kartenschlucker aus der Rollenwahl, denn er gibt es nur mit Karten.
static func set_death_cards(d: SetupDraft, on: bool) -> StringName:
	if d.roles.death_cards == on:
		return &""
	d.roles.death_cards = on
	if not on:
		d.roles.counts[RoleCatalog.KARTENSCHLUCKER] = 0
	_roles_changed(d)
	return &""


static func reset_roles(d: SetupDraft) -> StringName:
	var changed := not d.roles.copies.is_empty()
	d.roles.copies.clear()
	for id: StringName in d.roles.counts:
		if d.roles.counts[id] != 0:
			d.roles.counts[id] = 0
			changed = true
	if changed:
		_roles_changed(d)
	return &""


## Vorschlag übernehmen; eine abweichende bestehende Auswahl nur mit `force`. Vorhandene
## Kopien bleiben mit ihrer Scheinrolle erhalten, soweit der Vorschlag sie vorsieht; neue
## Kopien sind unkonfiguriert.
static func apply_suggestion(d: SetupDraft, force: bool) -> StringName:
	var count := d.persons.size()
	if count < PersonNameRules.MIN_PERSONS or count > PersonNameRules.MAX_PERSONS:
		return &"too_few_persons" if count < PersonNameRules.MIN_PERSONS else &"too_many_persons"
	if is_suggestion(d):
		return &""
	if d.roles.total() > 0 and not force:
		return &"confirmation_required"
	var suggestion := RoleSuggestion.for_count(count)
	for id: StringName in d.roles.counts:
		var wanted := int(suggestion.get(String(id), 0))
		if SetupRoleCatalog.requires_appearance(id):
			_resize_copies(d, id, wanted)
		d.roles.counts[id] = wanted
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
	if d.distribution.has_assignment() and d.distribution.pool != d.roles.keys():
		d.distribution.clear(DistributionDraft.INVALIDATED_ROLES)
	d.current_step = SetupDraft.STEP_DISTRIBUTION
	return &""


static func _roles_changed(d: SetupDraft) -> void:
	if d.roles.confirmed:
		d.roles.confirmed = false
		d.roles.invalidated = RolePoolDraft.INVALIDATED_ROLES
	d.distribution.clear(DistributionDraft.INVALIDATED_ROLES)


## Bis zu `wanted` unkonfigurierte Kopien der Rolle, von hinten gezählt.
static func _unconfigured_from_end(d: SetupDraft, role: StringName, wanted: int) -> Array[RoleCopy]:
	var out: Array[RoleCopy] = []
	var copies := d.roles.copies_of(role)
	for i: int in range(copies.size() - 1, -1, -1):
		if out.size() >= wanted:
			break
		if not copies[i].is_configured():
			out.append(copies[i])
	return out


## Bringt die Kopien einer Rolle auf `count`: neue Kopien unkonfiguriert anhängen, beim
## Verringern zuerst unkonfigurierte, dann (nur bei bestätigtem Überschreiben) die letzten.
static func _resize_copies(d: SetupDraft, role: StringName, count: int) -> void:
	var copies := d.roles.copies_of(role)
	while copies.size() < count:
		var copy := RoleCopy.new(d.roles.next_copy_id, role)
		d.roles.next_copy_id += 1
		d.roles.copies.append(copy)
		copies.append(copy)
	var excess := copies.size() - count
	for copy: RoleCopy in _unconfigured_from_end(d, role, excess):
		d.roles.copies.erase(copy)
		excess -= 1
	copies = d.roles.copies_of(role)
	while excess > 0:
		d.roles.copies.erase(copies.pop_back())
		excess -= 1


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


## Weist eine Verteilungseinheit zu: eine normale Rollen-ID oder den Schlüssel einer
## konkreten Kopie (Rollen mit Pflicht-Scheinrolle brauchen immer die konkrete Kopie).
static func assign_role(d: SetupDraft, person_id: int, entry_key: StringName) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.MANUAL)
	if error != &"":
		return error
	if d.index_of(person_id) == -1:
		return &"unknown_person"
	var role := RoleCopy.role_of(entry_key)
	if not SetupRoleCatalog.has_role(role):
		return &"unknown_role"
	if SetupRoleCatalog.requires_appearance(role) and not RoleCopy.is_copy_key(entry_key):
		return &"copy_required"
	var keys := d.roles.keys()
	if not keys.has(entry_key):
		return &"unknown_copy" if RoleCopy.is_copy_key(entry_key) else &"role_not_in_pool"
	if d.distribution.assignment.get(person_id, &"") == entry_key:
		return &""
	if d.distribution.remaining(keys).get(entry_key, 0) <= 0:
		return &"no_copy_available"
	d.distribution.assignment[person_id] = entry_key
	_manual_changed(d)
	return &""


static func unassign_role(d: SetupDraft, person_id: int) -> StringName:
	var error := _distribution_ready(d, DistributionDraft.MANUAL)
	if error != &"":
		return error
	if d.index_of(person_id) == -1:
		return &"unknown_person"
	if not d.distribution.assignment.has(person_id):
		return &""
	d.distribution.assignment.erase(person_id)
	_manual_changed(d)
	return &""


## Tauscht die Einheiten zweier Personen (auch mit einer nicht zugewiesenen Person); eine
## Scheinrolle folgt ihrer Kopie.
static func swap_roles(d: SetupDraft, first_id: int, second_id: int) -> StringName:
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
	_manual_changed(d)
	return &""


static func confirm_distribution(d: SetupDraft) -> StringName:
	var error := _distribution_ready(d, d.distribution.mode)
	if error != &"":
		return error
	if not d.distribution.is_complete(d.person_ids(), d.roles.keys()):
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


## Mischt die Verteilungseinheiten (Rolle samt Kopie und Scheinrolle) gemeinsam.
static func _random_fill(d: SetupDraft) -> void:
	var dist := d.distribution
	dist.pool = d.roles.keys()
	dist.assignment = RoleDistribution.random_assignment(d.person_ids(), dist.pool, dist.effective_seed())
	dist.confirmed = false
	dist.invalidated = &""


## Nach jeder manuellen Änderung: Pool merken und Bestätigung aufheben.
static func _manual_changed(d: SetupDraft) -> void:
	var dist := d.distribution
	dist.pool = d.roles.keys()
	dist.confirmed = false
	dist.invalidated = &""
