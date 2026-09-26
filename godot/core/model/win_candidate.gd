class_name WinCandidate
extends RefCounted
## Erkannter möglicher Sieg (A-11, G-SIEG-3). Wird erst durch den Spielleiter
## bestätigt (ConfirmWin) oder mit Grund abgelehnt (RejectWin).

const STATUS_OPEN := &"open"
const STATUS_CONFIRMED := &"confirmed"
const STATUS_REJECTED := &"rejected"

const REASON_WOLF_PARITY := &"wolf_parity"          ## G-SIEG-2
const REASON_NO_WOLVES_ALIVE := &"no_wolves_alive"  ## G-SIEG-1
const REASON_GM_DECLARED := &"gm_declared"          ## Siegerklärung per GmCorrection (DR-02)

var id: int = 0
var kind: StringName = &""  ## Faction
var reason_key: StringName = &""
var reason_args: Dictionary = {}
var status: StringName = STATUS_OPEN
var detected_at_command: int = -1
var resolved_at_command: int = -1
var rejection_reason: String = ""


func to_dict() -> Dictionary:
	return {
		"id": id,
		"kind": String(kind),
		"reason_key": String(reason_key),
		"reason_args": reason_args.duplicate(true),
		"status": String(status),
		"detected_at_command": detected_at_command,
		"resolved_at_command": resolved_at_command,
		"rejection_reason": rejection_reason,
	}


static func from_dict(d: Dictionary) -> WinCandidate:
	var w := WinCandidate.new()
	w.id = DictRead.get_int(d, "id")
	w.kind = StringName(DictRead.get_string(d, "kind"))
	w.reason_key = StringName(DictRead.get_string(d, "reason_key"))
	w.reason_args = DictRead.get_dict(d, "reason_args").duplicate(true)
	w.status = StringName(DictRead.get_string(d, "status"))
	w.detected_at_command = DictRead.get_int(d, "detected_at_command", -1)
	w.resolved_at_command = DictRead.get_int(d, "resolved_at_command", -1)
	w.rejection_reason = DictRead.get_string(d, "rejection_reason")
	return w
