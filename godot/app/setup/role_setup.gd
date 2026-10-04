class_name RoleSetup
extends RefCounted
## Operationen des Rollen- und Verteilungsteils auf einem SetupDraft, einschließlich der Verwerfungsregeln. Jede Operation
## liefert &"" bei Erfolg oder einen Fehlercode; bei Ablehnung bleibt der Entwurf unverändert. PlayerSetup ruft sie auf, meldet
## Änderungen und baut daraus SetupResult und Sicht.
##
## Verwerfen der Zuordnung (es gibt keine Bestätigungen mehr):
##   Person hinzufügen/entfernen → Verteilung verwerfen
##   Name ändern oder Reihenfolge ändern → Pool, Scheinrollen und Verteilung bleiben (Zuordnung an der Personen-ID)
##   Rollenanzahl, Kopie oder Scheinrolle ändern → Verteilung verwerfen
##   Neu mischen → nur die Personenzuordnung ändert sich; Scheinrollen hängen an ihrer Kopie
##
## Scheinrollen (DR-08): Der Spielleiter kann sie für jede Kopie ausdrücklich wählen. Fehlt die Wahl, belegt das Setup
## sie vor (`autofill_appearances`: zufällige Dorfrolle des Pools, Zufall über SeededRng); die Vorbelegung bleibt änderbar.


# --- Personen -----------------------------------------------------------------------------------------

static func persons_changed(d: SetupDraft) -> void:
	d.distribution.clear()


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


## Nimmt eine Kopie der Rolle aus der Auswahl (Antippen einer Rolle: entfernen). Bei Rollen mit Pflicht-Scheinrolle fällt die letzte
## Kopie samt ihrer Scheinrolle weg, ohne Rückfrage: Die Wahl „entfernen“ war ausdrücklich.
static func remove_one(d: SetupDraft, role: StringName) -> StringName:
	if not SetupRoleCatalog.has_role(role):
		return &"unknown_role"
	var current: int = d.roles.counts.get(role, 0)
	if current <= 0:
		return &"role_not_in_pool"
	if SetupRoleCatalog.requires_appearance(role):
		return remove_copy(d, d.roles.copies_of(role)[-1].copy_id)
	return set_role_count(d, role, current - 1)


## Fügt eine Kopie der Rolle hinzu (Höchstzahl der Startbesetzung, Kartenschlucker nur mit Totenreichkarten).
static func add_one(d: SetupDraft, role: StringName) -> StringName:
	if not SetupRoleCatalog.has_role(role):
		return &"unknown_role"
	return set_role_count(d, role, d.roles.counts.get(role, 0) + 1)


## Ersetzt eine Kopie von `old` durch eine Kopie von `new` (Antippen einer Rolle: tauschen). Atomar: ist `new` nicht wählbar, bleibt alles.
static func replace_one(d: SetupDraft, old: StringName, new: StringName) -> StringName:
	if old == new:
		return &""
	if not SetupRoleCatalog.has_role(new) or not SetupRoleCatalog.has_role(old):
		return &"unknown_role"
	if d.roles.counts.get(old, 0) <= 0:
		return &"role_not_in_pool"
	var current: int = d.roles.counts.get(new, 0)
	if current + 1 > SetupRoleCatalog.copy_limit(new, d.persons.size()):
		return &"above_maximum"
	if RoleCatalog.requires_cards(new) and not d.roles.death_cards:
		return &"cards_required"
	var error := remove_one(d, old)
	return error if error != &"" else add_one(d, new)


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
	copy.auto_chosen = false
	if copy.appears_as != appearance:
		copy.appears_as = appearance
		_roles_changed(d)
	return &""


## Vorbelegung der Scheinrollen: Jede Kopie ohne Scheinrolle erhält eine zufällige Dorfrolle aus dem Pool dieser Partie.
## Eine frühere Vorbelegung, deren Rolle nicht mehr im Pool steht, wird neu gezogen (gibt es keine Dorfrolle, wird sie
## geleert). Wahlen des Spielleiters bleiben unberührt. Der Zufall kommt aus einem SeededRng mit `seed_source`; die
## gezogene Rolle steht danach in der Kopie. Ändert nie die Bestätigung: Aufrufe folgen auf eine Rollenänderung.
static func autofill_appearances(d: SetupDraft, seed_source: Callable) -> void:
	var candidates: Array[StringName] = []
	for id: StringName in d.roles.pool():
		if SetupRoleCatalog.is_village(id) and RoleCatalog.is_valid_appearance(id) and not candidates.has(id):
			candidates.append(id)
	var rng: SeededRng = null
	for copy: RoleCopy in d.roles.copies:
		var stale := copy.auto_chosen and not candidates.has(copy.appears_as)
		if copy.is_configured() and not stale:
			continue
		if candidates.is_empty():
			copy.appears_as = &""
			copy.auto_chosen = false
			continue
		if rng == null:
			rng = SeededRng.new(int(seed_source.call()))
		copy.appears_as = candidates[rng.next_int(0, candidates.size() - 1)]
		copy.auto_chosen = true


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


## Vorschlag des gewählten Aktes für die Personenzahl übernehmen; eine abweichende bestehende Auswahl nur mit `force`. Vorhandene
## Kopien bleiben mit ihrer Scheinrolle erhalten, soweit der Vorschlag sie vorsieht; neue Kopien sind unkonfiguriert. Jeder Akt trägt
## 6 bis 24 Personen (DA-90), ein leerer Vorschlag ist im erlaubten Bereich nicht möglich.
static func apply_suggestion(d: SetupDraft, force: bool) -> StringName:
	var count := d.persons.size()
	if count < PersonNameRules.MIN_PERSONS or count > PersonNameRules.MAX_PERSONS:
		return &"too_few_persons" if count < PersonNameRules.MIN_PERSONS else &"too_many_persons"
	var suggestion := RoleSuggestion.for_act(d.act, count, d.roles.death_cards)
	if is_suggestion(d):
		return &""
	if d.roles.total() > 0 and not force:
		return &"confirmation_required"
	for id: StringName in d.roles.counts:
		var wanted := int(suggestion.get(String(id), 0))
		if SetupRoleCatalog.requires_appearance(id):
			_resize_copies(d, id, wanted)
		d.roles.counts[id] = wanted
	_roles_changed(d)
	return &""


static func is_suggestion(d: SetupDraft) -> bool:
	var suggestion := RoleSuggestion.for_act(d.act, d.persons.size(), d.roles.death_cards)
	if suggestion.is_empty():
		return false
	for id: StringName in d.roles.counts:
		if d.roles.counts[id] != int(suggestion.get(String(id), 0)):
			return false
	return true


static func _roles_changed(d: SetupDraft) -> void:
	d.distribution.clear()


## Bis zu `wanted` Kopien der Rolle ohne eigene Wahl (unkonfiguriert oder nur vorbelegt), von hinten gezählt.
static func _unconfigured_from_end(d: SetupDraft, role: StringName, wanted: int) -> Array[RoleCopy]:
	var out: Array[RoleCopy] = []
	var copies := d.roles.copies_of(role)
	for i: int in range(copies.size() - 1, -1, -1):
		if out.size() >= wanted:
			break
		if not copies[i].is_configured() or copies[i].auto_chosen:
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

## Moduswechsel verwirft eine bestehende Zuordnung (die Wahl ist ausdrücklich, keine Rückfrage).
static func set_mode(d: SetupDraft, mode: StringName) -> StringName:
	if mode != DistributionDraft.RANDOM and mode != DistributionDraft.MANUAL:
		return &"unknown_mode"
	if mode == d.distribution.mode:
		return &""
	d.distribution.clear()
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


## Verteilen setzt eine gültige Personenzahl und einen startbaren Pool voraus (keine Blocker, `RolePoolDraft.issues`).
static func _distribution_ready(d: SetupDraft, mode: StringName) -> StringName:
	if not d.validation()["valid"]:
		return &"too_few_persons"
	if not d.roles.issues(d.persons.size()).is_empty():
		return &"roles_invalid"
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


## Nach jeder manuellen Änderung: Pool merken.
static func _manual_changed(d: SetupDraft) -> void:
	d.distribution.pool = d.roles.keys()
