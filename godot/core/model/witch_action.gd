class_name WitchAction
extends RefCounted
## Bestätigte Entscheidung einer Waldhexe in einer Nacht (rules-register.md §6, DR-06).
## Entsteht erst mit der finalen Bestätigung des Waldhexenschritts, auch bei Verzicht
## auf beide Tränke. Die Rettung (`saved_id`) wirkt nur gegen den Rudelangriff dieser
## Nacht und wird beim Tagesbeginn verworfen. Der dauerhafte Trankverbrauch pro Person
## steht in `Player.ability_uses` (WitchStep.HEAL_USE_KEY, WitchStep.POISON_USE_KEY).

var witch_id: int = -1          ## Waldhexe
var night: int = 0              ## Nacht der Entscheidung
var victim_id: int = -1         ## Rudelopfer, das die Waldhexe gesehen hat (−1 = keins)
var heal_used: bool = false     ## Heiltrank mit dieser Entscheidung verbraucht
var saved_id: int = -1          ## gerettete Person (−1 = keine); per GmCorrection änderbar
var poison_used: bool = false   ## Gifttrank mit dieser Entscheidung verbraucht
var poison_target_id: int = -1  ## Giftziel (−1 = keins)


func to_dict() -> Dictionary:
	return {
		"witch_id": witch_id,
		"night": night,
		"victim_id": victim_id,
		"heal_used": heal_used,
		"saved_id": saved_id,
		"poison_used": poison_used,
		"poison_target_id": poison_target_id,
	}


static func from_dict(d: Dictionary) -> WitchAction:
	var a := WitchAction.new()
	a.witch_id = DictRead.get_int(d, "witch_id", -1)
	a.night = DictRead.get_int(d, "night")
	a.victim_id = DictRead.get_int(d, "victim_id", -1)
	a.heal_used = DictRead.get_bool(d, "heal_used")
	a.saved_id = DictRead.get_int(d, "saved_id", -1)
	a.poison_used = DictRead.get_bool(d, "poison_used")
	a.poison_target_id = DictRead.get_int(d, "poison_target_id", -1)
	if a.witch_id < 1 or a.night < 1 or (a.poison_used != (a.poison_target_id > 0)):
		return null
	return a
