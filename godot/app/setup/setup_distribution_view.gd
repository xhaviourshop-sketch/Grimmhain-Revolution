class_name SetupDistributionView
extends RefCounted
## Baut die Sicht des Verteilungsschritts aus dem Entwurf (reine Daten, immer eine neue
## Kopie). Enthält die geheime Zuordnung; nur der markierte Spielleiterbereich der
## Oberfläche zeigt Rollen und Scheinrollen an.


static func build(d: SetupDraft) -> Dictionary:
	var dist := d.distribution
	var pool := d.roles.pool()
	var persons: Array = []
	for i: int in d.persons.size():
		var p := d.persons[i]
		persons.append({
			"person_id": p.person_id,
			"number": i + 1,
			"name": p.name,
			"role": String(dist.assignment.get(p.person_id, &"")),
			"appearance": String(dist.appearances.get(p.person_id, &"")),
		})
	var remaining := {}
	var remaining_total := 0
	if d.roles.confirmed:
		var left := dist.remaining(pool)
		for id: StringName in SetupRoleCatalog.role_ids():
			if left.get(id, 0) > 0:
				remaining[String(id)] = left[id]
				remaining_total += left[id]
	var complete := d.roles.confirmed and dist.is_complete(d.person_ids(), pool)
	return {
		"mode": String(dist.mode),
		"assignment": persons,
		"assigned_count": dist.assignment.size(),
		"person_count": d.persons.size(),
		"role_count": pool.size(),
		"remaining": remaining,
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
