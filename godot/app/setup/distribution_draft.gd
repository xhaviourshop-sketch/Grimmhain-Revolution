class_name DistributionDraft
extends RefCounted
## Rollenverteilung im Setup-Entwurf: Modus (App verteilt zufällig / echte Karten, der Spielleiter weist zu), Zuordnung
## Personen-ID → Verteilungseinheit (Rollen-ID oder Schlüssel einer Kopie mit Scheinrolle, siehe RoleCopy), Setup-Seed und Zahl
## der bewussten Neumischungen. Scheinrollen stehen nur an ihrer Kopie im Rollenpool, nie hier.
## Nur RoleSetup verändert den Entwurf; alle Werte sind reine, speicherbare Daten.

const RANDOM := &"random"
const MANUAL := &"manual"
const NO_SEED := -1

var mode: StringName = RANDOM
var assignment: Dictionary[int, StringName] = {}   ## Personen-ID → Verteilungseinheit
var base_seed: int = NO_SEED     ## beim ersten bewussten Verteilen gesetzt, danach gespeichert
var shuffle_count: int = 0       ## bewusste Neumischungen seit dem ersten Seed
var pool: Array[StringName] = [] ## Verteilungseinheiten, für die die Zuordnung gilt (kanonisch)


func has_seed() -> bool:
	return base_seed != NO_SEED


func effective_seed() -> int:
	return RoleDistribution.effective_seed(base_seed, shuffle_count) if has_seed() else NO_SEED


func has_assignment() -> bool:
	return not assignment.is_empty()


## Verwirft die Zuordnung; Seed und Mischzähler bleiben.
func clear() -> void:
	assignment.clear()
	pool.clear()


## Noch nicht vergebene Einheiten je Schlüssel für die Einheiten `for_pool`.
func remaining(for_pool: Array[StringName]) -> Dictionary[StringName, int]:
	var left: Dictionary[StringName, int] = {}
	for id: StringName in for_pool:
		left[id] = left.get(id, 0) + 1
	for person: int in assignment:
		var id := assignment[person]
		left[id] = left.get(id, 0) - 1
	return left


## Vollständig: jede Person genau eine Rolle und jede Poolkopie genau einmal.
func is_complete(person_ids: Array[int], for_pool: Array[StringName]) -> bool:
	if assignment.size() != person_ids.size() or for_pool.size() != person_ids.size():
		return false
	for id: int in person_ids:
		if not assignment.has(id):
			return false
	for id: StringName in remaining(for_pool):
		if remaining(for_pool)[id] != 0:
			return false
	return true
