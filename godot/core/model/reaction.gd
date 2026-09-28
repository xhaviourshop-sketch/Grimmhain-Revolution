class_name Reaction
extends RefCounted
## Offene Todesfolge mit Entscheidung (G-TOD-4, 03 §5.2 `reaction_queue`).
## Liegt persistent in GameState.reactions, bis sie per AnswerPrompt erledigt ist.
## Reihenfolge: nach Einreihung (aufsteigende `id`).

const KIND_CURSE := &"curse"  ## eine lebende Person verfluchen oder verzichten (Sensenträger-Muster)
const KIND_POSSESSED := &"possessed"  ## Besessener Wolf: eine andere lebende Person mitreißen oder verzichten
const KIND_KNIGHT := &"knight"        ## Ritter bei Gleichstand: einen der gleich nahen Wölfe wählen (Pflicht)
const KIND_SMITH := &"smith"          ## Schmiedewaffe: Spielleiter wählt den lebenden Wolf, der stirbt (Pflicht)
const KINDS: Array[StringName] = [KIND_CURSE, KIND_POSSESSED, KIND_KNIGHT, KIND_SMITH]

var id: int = 0
var kind: StringName = KIND_CURSE
var owner_id: int = -1       ## gestorbene Person, der die Reaktion gehört
var trigger_order: int = 0   ## `order_index` des auslösenden Todes


func to_dict() -> Dictionary:
	return {"id": id, "kind": String(kind), "owner_id": owner_id, "trigger_order": trigger_order}


static func from_dict(d: Dictionary) -> Reaction:
	var r := Reaction.new()
	r.id = DictRead.get_int(d, "id")
	r.kind = StringName(DictRead.get_string(d, "kind"))
	r.owner_id = DictRead.get_int(d, "owner_id", -1)
	r.trigger_order = DictRead.get_int(d, "trigger_order")
	if r.id < 1 or not KINDS.has(r.kind) or r.owner_id < 1:
		return null
	return r
