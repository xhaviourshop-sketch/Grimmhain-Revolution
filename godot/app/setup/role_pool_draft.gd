class_name RolePoolDraft
extends RefCounted
## Rollenwahl im Setup-Entwurf: Anzahl je Rollen-ID und Bestätigung. Der Pool selbst wird
## aus den Anzahlen berechnet (`pool()`, kanonisch nach Rollen-ID sortiert, reine Daten).
## Validierung gegen die Personenzahl über `issues()`. Nur RoleSetup verändert den Entwurf.

const INVALIDATED_ROLES := &"roles_changed"             ## Rollenanzahl nach Bestätigung geändert
const INVALIDATED_PERSONS := &"person_count_changed"    ## Personenzahl passt nicht mehr

var counts: Dictionary[StringName, int] = {}
var confirmed: bool = false
var invalidated: StringName = &""   ## Grund, warum eine frühere Bestätigung aufgehoben wurde


func _init() -> void:
	for id: StringName in SetupRoleCatalog.role_ids():
		counts[id] = 0


func total() -> int:
	var sum := 0
	for id: StringName in counts:
		sum += counts[id]
	return sum


## Kanonischer Pool: jede Kopie einmal, nach Rollen-ID sortiert, unabhängig von der Sprache.
func pool() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in SetupRoleCatalog.role_ids():
		for i: int in maxi(0, counts.get(id, 0)):
			out.append(id)
	return out


## Anzahl je Fraktion und als Wolf zählende Kopien (Daten aus dem Katalog).
func summary() -> Dictionary:
	var factions := {}
	for faction: StringName in RolePresentation.FACTION_ORDER:
		factions[String(faction)] = 0
	var wolves := 0
	for id: StringName in counts:
		var key := String(SetupRoleCatalog.faction_of(id))
		factions[key] = int(factions.get(key, 0)) + counts[id]
		if SetupRoleCatalog.counts_as_wolf(id):
			wolves += counts[id]
	return {"factions": factions, "wolf_count": wolves}


## Gründe, warum der Pool für `persons` Personen nicht gültig ist (leer = gültig).
func issues(persons: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var village := 0
	var wolves := 0
	var solo := 0
	for id: StringName in counts:
		var c := counts[id]
		if not SetupRoleCatalog.has_role(id):
			out.append(&"unknown_role")
			continue
		if c < 0:
			out.append(&"negative_count")
		elif c > SetupRoleCatalog.copy_limit(id, persons) and not out.has(&"above_maximum"):
			out.append(&"above_maximum")
		if SetupRoleCatalog.is_village(id):
			village += c
		if SetupRoleCatalog.counts_as_wolf(id):
			wolves += c
		if SetupRoleCatalog.is_solo(id):
			solo += c
	var sum := total()
	if sum < persons:
		out.append(&"too_few_roles")
	elif sum > persons:
		out.append(&"too_many_roles")
	if village < 1:
		out.append(&"missing_village")
	if wolves < 1:
		out.append(&"missing_wolf")
	if solo < 1:
		out.append(&"missing_solo")
	return out


func view(persons: int) -> Dictionary:
	var string_counts := {}
	var can_increase := {}
	var can_decrease := {}
	var limits := {}
	for id: StringName in SetupRoleCatalog.role_ids():
		var c: int = counts.get(id, 0)
		var limit := SetupRoleCatalog.copy_limit(id, persons)
		string_counts[String(id)] = c
		limits[String(id)] = limit
		can_increase[String(id)] = c < limit
		can_decrease[String(id)] = c > 0
	var found := issues(persons)
	var issue_names: Array[String] = []
	for issue: StringName in found:
		issue_names.append(String(issue))
	var pool_names: Array[String] = []
	for id: StringName in pool():
		pool_names.append(String(id))
	var s := summary()
	var sum := total()
	return {
		"counts": string_counts,
		"total": sum,
		"persons": persons,
		"free": persons - sum,
		"valid": found.is_empty(),
		"issues": issue_names,
		"confirmed": confirmed,
		"can_confirm": found.is_empty(),
		"invalidated": String(invalidated),
		"pool": pool_names,
		"factions": s["factions"],
		"wolf_count": s["wolf_count"],
		"limits": limits,
		"can_increase": can_increase,
		"can_decrease": can_decrease,
		"is_empty": sum == 0,
	}
