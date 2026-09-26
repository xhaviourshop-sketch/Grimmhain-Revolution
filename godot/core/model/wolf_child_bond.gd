class_name WolfChildBond
extends RefCounted
## Zustand eines Wolfskinds (rules-register.md §8, DR-10). Genau ein Datensatz je Person
## mit aktueller Rolle `wolfskind`; er entsteht beim Spielaufbau oder per `set_role` und
## verschwindet, wenn die Person die Rolle verliert.
## Maßgeblich für die Verwandlung ist `transformed`. Die Rollenfelder der Person folgen
## daraus und werden beim Laden geprüft (WolfChildRules.fields_match):
##   unverwandelt: faction village, counts_as_wolf false, appears_as wolfskind
##   verwandelt:   faction wolves,  counts_as_wolf true,  appears_as werwolf
## `role_id` bleibt immer `wolfskind`.

var child_id: int = -1
var model_id: int = -1           ## Vorbild (−1 = keins)
var bound_night: int = 0         ## Nacht der Bindung (0 = ohne Bindung oder im Spielaufbau gesetzt)
var bound_command: int = -1      ## Befehl der Bindung (−1 = ohne Bindung)
var transformed: bool = false
var transform_order: int = -1    ## `order_index` des auslösenden Todes (−1 = keiner, z. B. Korrektur)
var transform_command: int = -1  ## Befehl der Verwandlung (−1 = unverwandelt)


func to_dict() -> Dictionary:
	return {
		"child_id": child_id,
		"model_id": model_id,
		"bound_night": bound_night,
		"bound_command": bound_command,
		"transformed": transformed,
		"transform_order": transform_order,
		"transform_command": transform_command,
	}


## Strukturprüfung; Bezug zu Personen und Nacht prüft WolfChildRules.state_is_consistent.
static func from_dict(d: Dictionary) -> WolfChildBond:
	var b := WolfChildBond.new()
	b.child_id = DictRead.get_int(d, "child_id", -1)
	b.model_id = DictRead.get_int(d, "model_id", -1)
	b.bound_night = DictRead.get_int(d, "bound_night", -1)
	b.bound_command = DictRead.get_int(d, "bound_command", -2)
	b.transformed = DictRead.get_bool(d, "transformed")
	b.transform_order = DictRead.get_int(d, "transform_order", -2)
	b.transform_command = DictRead.get_int(d, "transform_command", -2)
	if b.child_id < 1 or b.bound_night < 0 or b.transform_order < -1:
		return null
	if b.model_id == -1:
		if b.bound_night != 0 or b.bound_command != -1:
			return null
	elif b.model_id < 1 or b.bound_command < 0:
		return null
	if b.transformed != (b.transform_command >= 0) or (not b.transformed and b.transform_order != -1):
		return null
	return b
