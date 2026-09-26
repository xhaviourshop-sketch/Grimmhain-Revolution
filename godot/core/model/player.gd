class_name Player
extends RefCounted
## Person mit stabiler ID (G-ID-1). Die Sitzposition ist KEIN Feld der Person,
## sondern ergibt sich aus GameState.seat_order.
## Rolle, Fraktion, Wolfszählung und Erscheinung sind getrennte Werte (G-ID-2).

var id: int = 0
var name: String = ""
var role_id: StringName = &""
var original_role_id: StringName = &""
var faction: StringName = &""
var counts_as_wolf: bool = false
var appears_as: StringName = &""  ## für Informationsrollen; im Core-Slice ohne Nutzer
var alive: bool = true
var death: KillEvent = null


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"role_id": String(role_id),
		"original_role_id": String(original_role_id),
		"faction": String(faction),
		"counts_as_wolf": counts_as_wolf,
		"appears_as": String(appears_as),
		"alive": alive,
		"death": death.to_dict() if death != null else null,
	}


static func from_dict(d: Dictionary) -> Player:
	var p := Player.new()
	p.id = DictRead.get_int(d, "id", -1)
	p.name = DictRead.get_string(d, "name")
	p.role_id = StringName(DictRead.get_string(d, "role_id"))
	p.original_role_id = StringName(DictRead.get_string(d, "original_role_id"))
	p.faction = StringName(DictRead.get_string(d, "faction"))
	p.counts_as_wolf = DictRead.get_bool(d, "counts_as_wolf")
	p.appears_as = StringName(DictRead.get_string(d, "appears_as"))
	p.alive = DictRead.get_bool(d, "alive", true)
	if d.get("death") is Dictionary:
		p.death = KillEvent.from_dict(d["death"])
		if p.death == null:
			return null
	if p.id < 1 or p.name.strip_edges() == "" or not RoleCatalog.has_role(p.role_id):
		return null
	return p
