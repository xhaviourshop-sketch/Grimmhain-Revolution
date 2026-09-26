class_name PendingPrompt
extends RefCounted
## Offene Eingabe als Teil des Spielstands (03 §5.5, A-10). Im Core-Slice nur für
## die Opferwahl des Rudels genutzt. `partial` nimmt später Teilantworten
## mehrstufiger Prompts auf (B-05).

const KIND_PICK_PLAYERS := &"pick_players"
const OWNER_PACK := &"pack"

var id: int = 0
var kind: StringName = KIND_PICK_PLAYERS
var owner: StringName = &""
var actor_id: int = -1  ## -1 = Gruppe (Rudel)
var min_count: int = 0
var max_count: int = 0
var allowed_ids: Array[int] = []
var partial: Dictionary = {}
var cancellable: bool = false


func to_dict() -> Dictionary:
	return {
		"id": id,
		"kind": String(kind),
		"owner": String(owner),
		"actor_id": actor_id,
		"min_count": min_count,
		"max_count": max_count,
		"allowed_ids": allowed_ids.duplicate(),
		"partial": partial.duplicate(true),
		"cancellable": cancellable,
	}


static func from_dict(d: Dictionary) -> PendingPrompt:
	var p := PendingPrompt.new()
	p.id = DictRead.get_int(d, "id")
	p.kind = StringName(DictRead.get_string(d, "kind"))
	p.owner = StringName(DictRead.get_string(d, "owner"))
	p.actor_id = DictRead.get_int(d, "actor_id", -1)
	p.min_count = DictRead.get_int(d, "min_count")
	p.max_count = DictRead.get_int(d, "max_count")
	var ids: Variant = DictRead.to_int_array(DictRead.get_array(d, "allowed_ids"))
	if ids == null:
		return null
	p.allowed_ids = ids
	p.partial = DictRead.get_dict(d, "partial").duplicate(true)
	p.cancellable = DictRead.get_bool(d, "cancellable")
	return p
