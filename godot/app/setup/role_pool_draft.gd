class_name RolePoolDraft
extends RefCounted
## Rollenwahl im Setup-Entwurf: Anzahl je Rollen-ID und Bestätigung. Der Pool selbst wird
## aus den Anzahlen berechnet (`pool()`, kanonisch nach Rollen-ID sortiert, reine Daten).
## Rollen mit Pflicht-Scheinrolle (Trugbilderwolf) werden zusätzlich als einzelne Kopien
## (`copies`, RoleCopy) mit ausdrücklich gewählter Scheinrolle geführt; ihre Anzahl in
## `counts` entspricht immer der Zahl ihrer Kopien. `entries()` ist die Verteilungseinheit.
## Validierung gegen die Personenzahl über `issues()`. Nur RoleSetup verändert den Entwurf.

const INVALIDATED_ROLES := &"roles_changed"             ## Rollenanzahl nach Bestätigung geändert
const INVALIDATED_PERSONS := &"person_count_changed"    ## Personenzahl passt nicht mehr
const HINT_COACH_SMALL_ROUND := &"coach_small_round"             ## Besetzungshinweis PE-04, siehe `hints`
const HINT_SIMULTANEOUS_SOLO_WINS := &"simultaneous_solo_wins"   ## Besetzungshinweis PE-04, siehe `hints`
const COACH_HINT_BELOW_PERSONS := 13                             ## Schwelle aus PE-04

var counts: Dictionary[StringName, int] = {}
var confirmed: bool = false
var invalidated: StringName = &""   ## Grund, warum eine frühere Bestätigung aufgehoben wurde
var copies: Array[RoleCopy] = []    ## Kopien mit Pflicht-Scheinrolle in Anlagereihenfolge
var next_copy_id: int = 1           ## nächste Kopien-ID; sinkt nie


func _init() -> void:
	for id: StringName in SetupRoleCatalog.role_ids():
		counts[id] = 0


## Wiederbelebungsrunde (DI-01): Die Rollenwahl enthält eine direkte Wiederbelebungsrolle. Nur Anzeige;
## der Regelkern leitet den Modus beim Start selbst aus der Besetzung ab.
func is_revival_round() -> bool:
	for id: StringName in counts:
		if counts[id] > 0 and SetupRoleCatalog.is_revival_role(id):
			return true
	return false


## Nicht blockierende Besetzungshinweise (PE-04) für `persons` Personen; nur Anzeige im privaten Rollenschritt, ohne
## Einfluss auf Gültigkeit, Start oder Regelkern. Kutscher unter 13 Personen (Analyse R-07 C-1) und mindestens zwei Kopien
## der Rollen mit Einzelsieg bei höchstens drei Lebenden (C-3).
func hints(persons: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if counts.get(SetupRoleCatalog.COACH, 0) > 0 and persons < COACH_HINT_BELOW_PERSONS:
		out.append(HINT_COACH_SMALL_ROUND)
	var solo := 0
	for id: StringName in SetupRoleCatalog.SMALL_ROUND_SOLO_ROLES:
		solo += maxi(0, counts.get(id, 0))
	if solo >= 2:
		out.append(HINT_SIMULTANEOUS_SOLO_WINS)
	return out


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


## Verteilungseinheiten in kanonischer Reihenfolge: je Kopie `{key, role_id, appears_as}`.
## Normale Rollen haben ihre Rollen-ID als Schlüssel (gleiche Kopien sind austauschbar),
## Kopien mit Pflicht-Scheinrolle ihren eigenen Schlüssel (RoleCopy.key()).
func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in SetupRoleCatalog.role_ids():
		if SetupRoleCatalog.requires_appearance(id):
			for copy: RoleCopy in copies_of(id):
				out.append({"key": copy.key(), "role_id": id, "appears_as": copy.appears_as})
		else:
			for i: int in maxi(0, counts.get(id, 0)):
				out.append({"key": id, "role_id": id, "appears_as": &""})
	return out


## Schlüssel aller Verteilungseinheiten (kanonisch); Grundlage der Verteilung.
func keys() -> Array[StringName]:
	var out: Array[StringName] = []
	for e: Dictionary in entries():
		out.append(e["key"] as StringName)
	return out


## Kopien einer Rolle nach Kopien-ID (entspricht der Anlagereihenfolge).
func copies_of(role: StringName) -> Array[RoleCopy]:
	var out: Array[RoleCopy] = []
	for copy: RoleCopy in copies:
		if copy.role_id == role:
			out.append(copy)
	return out


func copy_by_id(copy_id: int) -> RoleCopy:
	for copy: RoleCopy in copies:
		if copy.copy_id == copy_id:
			return copy
	return null


func copy_by_key(entry_key: StringName) -> RoleCopy:
	for copy: RoleCopy in copies:
		if copy.key() == entry_key:
			return copy
	return null


## Sichtbare Nummer einer Kopie innerhalb ihrer Rolle („Trugbilderwolf 2“).
func copy_number(copy: RoleCopy) -> int:
	return copies_of(copy.role_id).find(copy) + 1


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
	for copy: RoleCopy in copies:
		if not copy.is_configured():
			out.append(&"missing_appearance")
			break
	return out


## Rollen, deren Anzahl die Höchstzahl der Startbesetzung übersteigt (PE-07), kanonisch sortiert. Nur bei einem ungültigen
## Entwurf nicht leer; der Entwurf wird nie still gekürzt, die Namen stehen in der Fehlerliste.
func over_limit(persons: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in SetupRoleCatalog.role_ids():
		if SetupRoleCatalog.has_role(id) and counts.get(id, 0) > SetupRoleCatalog.copy_limit(id, persons):
			out.append(id)
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
	var over_names: Array[String] = []
	for id: StringName in over_limit(persons):
		over_names.append(String(id))
	var issue_names: Array[String] = []
	for issue: StringName in found:
		issue_names.append(String(issue))
	var pool_names: Array[String] = []
	for id: StringName in pool():
		pool_names.append(String(id))
	var s := summary()
	var sum := total()
	var hint_names: Array[String] = []
	for hint: StringName in hints(persons):
		hint_names.append(String(hint))
	return {
		"counts": string_counts,
		"revival_round": is_revival_round(),
		"hints": hint_names,
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
		"over_limit": over_names,
		"can_increase": can_increase,
		"can_decrease": can_decrease,
		"is_empty": sum == 0,
		"decoys": _copies_view(),
		"entries": _entries_view(),
		"appearance_options": _appearance_options_view(),
	}


func _copies_view() -> Array:
	var out: Array = []
	for copy: RoleCopy in copies:
		out.append({
			"copy_id": copy.copy_id,
			"number": copy_number(copy),
			"key": String(copy.key()),
			"role_id": String(copy.role_id),
			"appears_as": String(copy.appears_as),
			"configured": copy.is_configured(),
		})
	return out


func _entries_view() -> Array:
	var out: Array = []
	for e: Dictionary in entries():
		out.append({"key": String(e["key"]), "role_id": String(e["role_id"]), "appears_as": String(e["appears_as"])})
	return out


static func _appearance_options_view() -> Array:
	var out: Array = []
	for id: StringName in SetupRoleCatalog.appearance_options():
		out.append(String(id))
	return out
