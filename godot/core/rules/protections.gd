class_name Protections
extends RefCounted
## Zugriff auf die gespeicherten Schutzwahlen der laufenden Nacht (DR-05).


## Schutz eines Schutzengels für diese Nacht oder null.
static func of_guardian(s: GameState, guardian_id: int) -> Protection:
	for p: Protection in s.protections:
		if p.guardian_id == guardian_id and p.night == s.night_number and not p.extra:
			return p
	return null


## Zweiter Schutz desselben Engels in dieser Nacht (verdoppelter Schritt durch einen Apfel).
static func add_extra(s: GameState, guardian_id: int, target_id: int) -> void:
	var p := Protection.new()
	p.guardian_id = guardian_id
	p.target_id = target_id
	p.night = s.night_number
	p.extra = true
	s.protections.append(p)


## Setzt oder ersetzt den Schutz eines Schutzengels für die laufende Nacht.
static func set_protection(s: GameState, guardian_id: int, target_id: int) -> void:
	var p := of_guardian(s, guardian_id)
	if p == null:
		p = Protection.new()
		p.guardian_id = guardian_id
		p.night = s.night_number
		s.protections.append(p)
	p.target_id = target_id
	s.protections.sort_custom(func(a: Protection, b: Protection) -> bool: return a.guardian_id < b.guardian_id)


static func remove_protection(s: GameState, guardian_id: int) -> void:
	var p := of_guardian(s, guardian_id)
	if p != null:
		s.protections.erase(p)


## Schutzengel-IDs, die `target_id` in Nacht `night` schützen, aufsteigend.
static func guardians_of(s: GameState, target_id: int, night: int) -> Array[int]:
	var ids: Array[int] = []
	for p: Protection in s.protections:
		if p.target_id == target_id and p.night == night:
			ids.append(p.guardian_id)
	ids.sort()
	return ids
