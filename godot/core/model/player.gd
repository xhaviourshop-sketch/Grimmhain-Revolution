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
var appears_as: StringName = &""  ## Erscheinung für Informationsrollen; beim Trugbilderwolf die Scheinrolle
var alive: bool = true
var death: KillEvent = null
var ability_uses: Dictionary = {}  ## begrenzte Einsätze pro Person: "<rolle>:<fähigkeit>" → Anzahl (G-ID-3)


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
		"ability_uses": ability_uses.duplicate(),
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
	for key: Variant in DictRead.get_dict(d, "ability_uses"):
		var count: Variant = DictRead.get_dict(d, "ability_uses")[key]
		# Nur bekannte Einsätze, jeweils 0 oder 1 (einmal pro Person und Partie).
		if not RoleCatalog.ABILITY_USE_KEYS.has(String(key)) or not DictRead.is_int_like(count) or int(count) < 0 or int(count) > 1:
			return null
		p.ability_uses[String(key)] = int(count)
	if d.get("death") is Dictionary:
		p.death = KillEvent.from_dict(d["death"])
		if p.death == null:
			return null
	if p.id < 1 or p.name.strip_edges() == "" or not RoleCatalog.has_role(p.role_id) or not RoleCatalog.has_role(p.appears_as):
		return null
	# Eine Rolle mit Scheinrolle (Trugbilderwolf) braucht eine zulässige, nicht wölfische.
	if RoleCatalog.requires_appearance(p.role_id) and not RoleCatalog.is_valid_appearance(p.appears_as):
		return null
	return p
