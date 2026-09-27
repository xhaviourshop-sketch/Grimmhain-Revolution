class_name SetupDistributionView
extends RefCounted
## Baut die Sicht des Verteilungsschritts aus dem Entwurf (reine Daten, immer eine neue
## Kopie). Enthält die geheime Zuordnung; nur der markierte Spielleiterbereich der
## Oberfläche zeigt Rollen und Scheinrollen an. Die Scheinrolle einer Person ist immer die
## ausdrücklich gewählte Scheinrolle der ihr zugewiesenen Kopie.


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
			"role": String(RoleCopy.role_of(unit)) if unit != &"" else "",
			"copy_key": String(unit) if copy != null else "",
			"copy_number": d.roles.copy_number(copy) if copy != null else 0,
			"appearance": String(copy.appears_as) if copy != null else "",
		})
	var remaining := {}
	var remaining_keys: Array = []
	var remaining_copies: Array = []
	var remaining_total := 0
	if d.roles.confirmed:
		var left := dist.remaining(pool)
		for unit: StringName in pool:
			if left.get(unit, 0) <= 0 or remaining_keys.has(String(unit)):
				continue
			remaining_keys.append(String(unit))
			var role := String(RoleCopy.role_of(unit))
			remaining[role] = int(remaining.get(role, 0)) + left[unit]
			remaining_total += left[unit]
			var copy := d.roles.copy_by_key(unit)
			if copy != null:
				remaining_copies.append({"key": String(unit), "role_id": role, "number": d.roles.copy_number(copy), "appears_as": String(copy.appears_as)})
	var complete := d.roles.confirmed and dist.is_complete(d.person_ids(), pool)
	return {
		"mode": String(dist.mode),
		"assignment": persons,
		"assigned_count": dist.assignment.size(),
		"person_count": d.persons.size(),
		"role_count": pool.size(),
		"remaining": remaining,
		"remaining_keys": remaining_keys,
		"remaining_copies": remaining_copies,
		"remaining_total": remaining_total,
		"complete": complete,
		"has_assignment": dist.has_assignment(),
		"confirmed": dist.confirmed,
		"can_confirm": complete and not dist.confirmed,
		"invalidated": String(dist.invalidated),
		"has_seed": dist.has_seed(),
		"seed": str(dist.base_seed) if dist.has_seed() else "",
		"effective_seed": str(dist.effective_seed()) if dist.has_seed() else "",
		"shuffle_count": dist.shuffle_count,
		"factions": d.roles.summary()["factions"],
		"ready_for_seating": d.confirmed and d.roles.confirmed and dist.confirmed,
	}
