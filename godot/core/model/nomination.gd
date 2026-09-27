class_name Nomination
extends RefCounted
## Gespeicherte Nominierung (A-08, DR-03). Es gibt bewusst kein Feld für Stimmen.

var nominator_id: int = -1
var nominee_id: int = -1
var day: int = 0
var by_judge: bool = false  ## Nominierung durch die Markierung des Korrupten Richters (öffentlich ohne Nominierenden)


func to_dict() -> Dictionary:
	var d := {"nominator_id": nominator_id, "nominee_id": nominee_id, "day": day}
	if by_judge:
		d["by_judge"] = true
	return d


static func from_dict(d: Dictionary) -> Nomination:
	var n := Nomination.new()
	n.nominator_id = DictRead.get_int(d, "nominator_id", -1)
	n.nominee_id = DictRead.get_int(d, "nominee_id", -1)
	n.day = DictRead.get_int(d, "day")
	n.by_judge = DictRead.get_bool(d, "by_judge")
	return n
