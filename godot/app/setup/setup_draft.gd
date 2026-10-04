class_name SetupDraft
extends RefCounted
## Setup-Entwurf „Neue Partie“ in drei Schritten (Runde, Namen, Rollen): Personen in Listenreihenfolge (= Sitzordnung im Uhrzeigersinn
## ab Platz 1), nächster ID-Zähler, Zielzahl der Runde (`player_count`), gewählter Akt, aktueller Schritt, Rollenwahl (`roles`) und
## Rollenverteilung (`distribution`). Es gibt keine Bestätigungen: Gültigkeit wird bei Bedarf aus dem Inhalt berechnet (`validation()`,
## `RolePoolDraft.issues`), nicht getrennt gespeichert. Nur PlayerSetup und RoleSetup verändern den Entwurf.

const STEP_ROUND := &"round"
const STEP_NAMES := &"names"
const STEP_ROLES := &"roles"
const STEPS: Array[StringName] = [STEP_ROUND, STEP_NAMES, STEP_ROLES]
const DEFAULT_PLAYER_COUNT := 8      ## Startwert des Zählers in Schritt 1 (nur Vorbelegung, jederzeit änderbar)
const DEFAULT_ACT := &"akt1"         ## erste Akt-Karte, vorgewählt

var persons: Array[SetupPerson] = []
var next_person_id: int = 1       ## nächste zu vergebende ID; sinkt nie (außer beim Verwerfen)
var current_step: StringName = STEP_ROUND
var player_count: int = DEFAULT_PLAYER_COUNT  ## Zielzahl der Runde (6 bis 24); die Namen müssen sie erreichen
var act: StringName = DEFAULT_ACT
var order_seed: int = DistributionDraft.NO_SEED  ## Seed der Namensreihenfolge (erstes „Mischen“), danach gespeichert
var order_shuffles: int = 0       ## bewusste Neumischungen der Namensreihenfolge
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
