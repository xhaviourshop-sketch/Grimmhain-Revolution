class_name KillEvent
extends RefCounted
## Todesdatensatz (A-09, G-TOD-1): Ursache, Quelle, Ziel und Zeitpunkt getrennt.
## `interception` ist der Abfangstatus; ohne Abfangregeln (B-04) immer "none".

const CAUSE_NIGHT_KILL := &"NIGHT_KILL"
const CAUSE_LYNCH := &"LYNCH"
const CAUSE_HUNTER_SHOT := &"HUNTER_SHOT"      ## Fluch nach dem Tod (Sensenträger-Reaktion)
const CAUSE_POSSESSED_DRAG := &"POSSESSED_DRAG"  ## vom Besessenen Wolf mitgerissen (Rollenaudit)
const CAUSE_KNIGHT_STRIKE := &"KNIGHT_STRIKE"    ## Schlag des sterbenden Ritters (Rollenaudit)
const CAUSE_WOLF_POISON := &"WOLF_POISON"  ## Giftpranke des Giftwolfs, zwei Nächte später (Rollenaudit)
const CAUSE_HANGMAN_EXTRA := &"HANGMAN_EXTRA"  ## vom Henker markiert, stirbt bei der Hinrichtung mit (Rollenaudit)
const CAUSE_PARASITE_HOST := &"PARASITE_HOST"  ## Parasit stirbt mit seinem Wirt (Rollenaudit)
const CAUSE_COACHMAN_CRASH := &"COACHMAN_CRASH"  ## Nachbar des gelynchten Wahnsinnigen Kutschers (Rollenaudit)
const CAUSE_GM_CORRECTION := &"GM_CORRECTION"  ## Spielleiterkorrektur
const CAUSE_WITCH_POISON := &"WITCH_POISON"    ## Gifttrank der Waldhexe, in der Morgenauflösung (Todesmarkierung)
const CAUSE_SPIEGELWOLF_RETALIATE := &"SPIEGELWOLF_RETALIATE"  ## gespiegelte Hinrichtung, Quelle Spiegelwolf
const CAUSE_MANIPULATOR_NOMINATED := &"MANIPULATOR_NOMINATED"  ## Tod des Manipulators bei seiner Nominierung
const CAUSES: Array[StringName] = [CAUSE_NIGHT_KILL, CAUSE_LYNCH, CAUSE_HUNTER_SHOT, CAUSE_GM_CORRECTION, CAUSE_WITCH_POISON, CAUSE_SPIEGELWOLF_RETALIATE, CAUSE_MANIPULATOR_NOMINATED, CAUSE_COACHMAN_CRASH, CAUSE_POSSESSED_DRAG, CAUSE_KNIGHT_STRIKE, CAUSE_PARASITE_HOST, CAUSE_WOLF_POISON, CAUSE_HANGMAN_EXTRA]

const SOURCE_PACK := &"pack"        ## Rudel (alle lebenden Wölfe gemeinsam)
const SOURCE_VILLAGE := &"village"  ## Hinrichtung nach physischer Abstimmung
const SOURCE_PLAYER := &"player"    ## eine Person (source_id)
const SOURCE_GM := &"gm"            ## Spielleiter
const SOURCES: Array[StringName] = [SOURCE_PACK, SOURCE_VILLAGE, SOURCE_PLAYER, SOURCE_GM]

const INTERCEPTION_NONE := &"none"

var target_id: int = -1
var cause: StringName = &""
var source_kind: StringName = &""
var source_id: int = -1  ## Person als Quelle; -1 bei Rudel/Dorf/Spielleiter
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
