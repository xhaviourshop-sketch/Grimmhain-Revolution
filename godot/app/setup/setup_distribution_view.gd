class_name SetupDistributionView
extends RefCounted
## Baut die Sicht der Verteilung aus dem Entwurf (reine Daten, immer eine neue Kopie). Enthält die geheime Zuordnung; nur der
## Modus „Echte Karten“ zeigt sie der Spielleitung beim Zuweisen an (die Plätze selbst zeigen nur „zugeordnet“). Die Scheinrolle einer
## Person ist immer die ausdrücklich gewählte Scheinrolle der ihr zugewiesenen Kopie.


static func build(d: SetupDraft) -> Dictionary:
	var dist := d.distribution
	var pool := d.roles.keys()
	var persons: Array = []
	for i: int in d.persons.size():
		var p := d.persons[i]
		var unit: StringName = dist.assignment.get(p.person_id, &"")
		var copy := d.roles.copy_by_key(unit) if RoleCopy.is_copy_key(unit) else null
		persons.append({
			"person_id": p.person_id,
			"number": i + 1,
			"name": p.name,
			"assigned": unit != &"",
			"unit": String(unit),
			"role": String(RoleCopy.role_of(unit)) if unit != &"" else "",
			"copy_number": d.roles.copy_number(copy) if copy != null else 0,
			"appearance": String(copy.appears_as) if copy != null else "",
		})
	var left := dist.remaining(pool)
	var remaining_units: Array = []
	var seen := {}
	for unit: StringName in pool:
		if left.get(unit, 0) <= 0 or seen.has(unit):
			continue
		seen[unit] = true
		var copy := d.roles.copy_by_key(unit)
		remaining_units.append({
			"unit": String(unit),
			"role_id": String(RoleCopy.role_of(unit)),
			"left": left[unit],
			"copy_number": d.roles.copy_number(copy) if copy != null else 0,
		})
	var assigned := 0
	for entry: Variant in persons:
		if bool((entry as Dictionary)["assigned"]):
			assigned += 1
	return {
		"mode": String(dist.mode),
		"assignment": persons,
		"assigned_count": assigned,
		"person_count": d.persons.size(),
		"role_count": pool.size(),
		"remaining_units": remaining_units,
		"complete": dist.is_complete(d.person_ids(), pool),
		"has_assignment": dist.has_assignment(),
		"has_seed": dist.has_seed(),
	}
