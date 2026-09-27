class_name SetupDraft
extends RefCounted
## Setup-Entwurf „Neue Partie“: Personen in Listenreihenfolge, nächster ID-Zähler,
## Bearbeitungsstatus und Bestätigung des Namensschritts, aktueller Wizard-Schritt sowie
## Rollenwahl (`roles`) und Rollenverteilung (`distribution`). Das Validierungsergebnis wird
## bei Bedarf aus der Personenliste berechnet (`validation()`), nicht getrennt gespeichert.
## Nur PlayerSetup und RoleSetup verändern den Entwurf.

const STEP_PLAYERS := &"players"
const STEP_ROLES := &"roles"
const STEP_DISTRIBUTION := &"distribution"
const STEPS: Array[StringName] = [STEP_PLAYERS, STEP_ROLES, STEP_DISTRIBUTION]

var persons: Array[SetupPerson] = []
var next_person_id: int = 1       ## nächste zu vergebende ID; sinkt nie (außer beim Verwerfen)
var confirmed: bool = false       ## Namensschritt bestätigt
var has_unconfirmed_changes: bool = false  ## Änderungen seit der letzten Bestätigung bzw. dem Neubeginn
var players_invalidated: bool = false  ## Personenliste nach einer Bestätigung geändert
var current_step: StringName = STEP_PLAYERS
var roles: RolePoolDraft = RolePoolDraft.new()
var distribution: DistributionDraft = DistributionDraft.new()


func index_of(person_id: int) -> int:
	for i: int in persons.size():
		if persons[i].person_id == person_id:
			return i
	return -1


## Personen-IDs, deren Name mindestens einmal weiteren Personen gleicht.
func duplicate_ids() -> Dictionary:
	var by_key := {}
	for p: SetupPerson in persons:
		var key := PersonNameRules.duplicate_key(p.name)
		if not by_key.has(key):
			by_key[key] = []
		(by_key[key] as Array).append(p.person_id)
	var out := {}
	for key: Variant in by_key:
		var ids: Array = by_key[key]
		if ids.size() > 1:
			for id: Variant in ids:
				out[int(id)] = true
	return out


## true, wenn ein weiterer Name mit `name` eine Dublette bilden würde (ohne `except_id`).
func has_duplicate_of(name: String, except_id: int = -1) -> bool:
	var key := PersonNameRules.duplicate_key(name)
	for p: SetupPerson in persons:
		if p.person_id != except_id and PersonNameRules.duplicate_key(p.name) == key:
			return true
	return false


func validation() -> Dictionary:
	var count := persons.size()
	return {
		"count": count,
		"valid": count >= PersonNameRules.MIN_PERSONS and count <= PersonNameRules.MAX_PERSONS,
		"missing": maxi(0, PersonNameRules.MIN_PERSONS - count),
		"at_maximum": count >= PersonNameRules.MAX_PERSONS,
	}


## Personen-IDs in Listenreihenfolge.
func person_ids() -> Array[int]:
	var out: Array[int] = []
	for p: SetupPerson in persons:
		out.append(p.person_id)
	return out
