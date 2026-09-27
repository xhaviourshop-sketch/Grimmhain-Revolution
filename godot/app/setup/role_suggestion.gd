class_name RoleSuggestion
extends RefCounted
## Deterministischer Rollenvorschlag je Personenzahl (Setup-Hilfe, keine Spielregel, nicht
## als ausbalanciert garantiert). Heuristik:
##   1. als Wolf zählende Rollen: bis 8 Personen 1, ab 9 → 2, ab 13 → 3, ab 18 → 4, ab 22 → 5,
##      in der Reihenfolge WOLF_ORDER (Werwolf, Spiegelwolf, Werwolf, Trugbilderwolf, Werwolf)
##   2. genau eine Einzelsiegrolle (Manipulator)
##   3. Sonderrollen des Dorfs: (Personen − Wölfe − 1) / 2, höchstens SPECIAL_ORDER.size(),
##      in der festen Reihenfolge SPECIAL_ORDER
##   4. Rest: Dorfbewohner
## Kein Zufall, keine Uhr: gleiche Personenzahl ergibt immer denselben Vorschlag.

## [ab Personenzahl, Wölfe]; darunter gilt 1 Wolf.
const WOLF_STEPS: Array[Vector2i] = [Vector2i(9, 2), Vector2i(13, 3), Vector2i(18, 4), Vector2i(22, 5)]
const WOLF_ORDER: Array[StringName] = [&"werwolf", &"spiegelwolf", &"werwolf", &"trugbilderwolf", &"werwolf"]
const SOLO_ROLE: StringName = &"manipulator"
const SPECIAL_ORDER: Array[StringName] = [&"schutzengel", &"das-orakel", &"waldhexe", &"sensentraeger", &"lehrling", &"wolfskind"]
const FILL_ROLE: StringName = &"dorfbewohner"


static func wolf_count(persons: int) -> int:
	var wolves := 1
	for step: Vector2i in WOLF_STEPS:
		if persons >= step.x:
			wolves = step.y
	return wolves


## Anzahl je Rollen-ID (String-Schlüssel, alle Katalogrollen, kanonisch sortiert).
static func for_count(persons: int) -> Dictionary:
	var counts := {}
	for id: StringName in SetupRoleCatalog.role_ids():
		counts[String(id)] = 0
	var wolves := wolf_count(persons)
	for i: int in wolves:
		_add(counts, WOLF_ORDER[i % WOLF_ORDER.size()])
	_add(counts, SOLO_ROLE)
	var specials := mini(SPECIAL_ORDER.size(), maxi(0, (persons - wolves - 1) / 2))
	for i: int in specials:
		_add(counts, SPECIAL_ORDER[i])
	var used := wolves + 1 + specials
	counts[String(FILL_ROLE)] = int(counts[String(FILL_ROLE)]) + maxi(0, persons - used)
	return counts


static func _add(counts: Dictionary, role: StringName) -> void:
	counts[String(role)] = int(counts[String(role)]) + 1
