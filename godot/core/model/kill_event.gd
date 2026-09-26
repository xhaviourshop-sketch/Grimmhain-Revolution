class_name KillEvent
extends RefCounted
## Todesdatensatz (A-09, G-TOD-1): Ursache, Quelle, Ziel und Zeitpunkt getrennt.
## `interception` ist der Abfangstatus; ohne Abfangregeln (B-04) immer "none".

const CAUSE_NIGHT_KILL := &"NIGHT_KILL"
const CAUSE_LYNCH := &"LYNCH"
const CAUSES: Array[StringName] = [CAUSE_NIGHT_KILL, CAUSE_LYNCH]

const SOURCE_PACK := &"pack"        ## Rudel (alle lebenden Wölfe gemeinsam)
const SOURCE_VILLAGE := &"village"  ## Hinrichtung nach physischer Abstimmung
const SOURCES: Array[StringName] = [SOURCE_PACK, SOURCE_VILLAGE]

const INTERCEPTION_NONE := &"none"

var target_id: int = -1
var cause: StringName = &""
var source_kind: StringName = &""
var source_id: int = -1  ## Person als Quelle; -1 bei Rudel/Dorf
var phase: StringName = &""
var phase_number: int = 0  ## Nachtnummer in NIGHT/DAWN_RESOLUTION, sonst Tagesnummer
var order_index: int = 0   ## fortlaufende Nummer aller Tode der Partie
var interception: StringName = INTERCEPTION_NONE


func to_dict() -> Dictionary:
	return {
		"target_id": target_id,
		"cause": String(cause),
		"source_kind": String(source_kind),
		"source_id": source_id,
		"phase": String(phase),
		"phase_number": phase_number,
		"order_index": order_index,
		"interception": String(interception),
	}


static func from_dict(d: Dictionary) -> KillEvent:
	var k := KillEvent.new()
	k.target_id = DictRead.get_int(d, "target_id", -1)
	k.cause = StringName(DictRead.get_string(d, "cause"))
	k.source_kind = StringName(DictRead.get_string(d, "source_kind"))
	k.source_id = DictRead.get_int(d, "source_id", -1)
	k.phase = StringName(DictRead.get_string(d, "phase"))
	k.phase_number = DictRead.get_int(d, "phase_number")
	k.order_index = DictRead.get_int(d, "order_index")
	k.interception = StringName(DictRead.get_string(d, "interception"))
	if not CAUSES.has(k.cause) or not SOURCES.has(k.source_kind) or not Phase.ALL.has(k.phase):
		return null
	return k
