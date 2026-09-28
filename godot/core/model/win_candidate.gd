class_name WinCandidate
extends RefCounted
## Erkannter möglicher Sieg (A-11, G-SIEG-3). Alle Kandidaten der Partie stehen in
## `GameState.win_candidates` (einzige Quelle); offen sind die mit Status `open`. Der
## Spielleiter bestätigt genau einen (ConfirmWin, die übrigen offenen werden `not_chosen`)
## oder lehnt alle offenen gemeinsam mit Grund ab (RejectWin).

const STATUS_OPEN := &"open"
const STATUS_CONFIRMED := &"confirmed"
const STATUS_REJECTED := &"rejected"
const STATUS_NOT_CHOSEN := &"not_chosen"  ## offen, als ein anderer Kandidat bestätigt wurde
const STATUSES: Array[StringName] = [STATUS_OPEN, STATUS_CONFIRMED, STATUS_REJECTED, STATUS_NOT_CHOSEN]

const REASON_WOLF_PARITY := &"wolf_parity"                    ## G-SIEG-2
const REASON_NO_WOLVES_ALIVE := &"no_wolves_alive"            ## G-SIEG-1
const REASON_MANIPULATOR := &"manipulator_three_alive"        ## DR-12: genau drei Lebende, nie nominiert
const REASON_GM_DECLARED := &"gm_declared"                    ## Siegerklärung per GmCorrection (DR-02)
const REASON_DOUBLE_AGENT := &"double_agent_no_wolves"        ## RM-DR-155: lebender Doppelspion, kein Wolf lebt
const REASON_DEATH_SEEKER := &"death_seeker_lynched"          ## RM-DR-138: Selbstmörder bei mindestens 5 Toten hingerichtet
const REASON_PARASITE := &"parasite_final_three"               ## RM-DR-157: höchstens drei Lebende, Parasit lebt
const REASON_PIED_PIPER := &"pied_piper_all_charmed"          ## E-01: alle anderen Lebenden verzaubert
const REASON_PLAGUE := &"plague_all_infected"                 ## E-02: alle anderen Lebenden infiziert
const REASON_PROPHET := &"prophet_no_wolves"                  ## E-03: freigeschaltet, kein Wolf lebt
const REASON_DEATH_PREACHER := &"death_preacher_prophecy"     ## E-04: Tod zum vorhergesagten Zeitpunkt
const REASON_VOODOO := &"voodoo_final_three"                  ## E-15: Voodoo-Priester lebt, höchstens drei Lebende
const REASON_NECROMANCER := &"necromancer_named_wolf"          ## E-19: lebenden Wolf am Tag korrekt benannt
const REASON_HADES := &"hades_ten_lights"                     ## E-29: Hades lebt mit mindestens 10 Lichtern
const REASON_GRAVE_ROBBER := &"grave_robber_final_three"      ## E-33: Grabräuber lebt, höchstens drei Lebende
const REASONS: Array[StringName] = [REASON_WOLF_PARITY, REASON_NO_WOLVES_ALIVE, REASON_MANIPULATOR, REASON_GM_DECLARED, REASON_DOUBLE_AGENT, REASON_DEATH_SEEKER, REASON_PARASITE,
	REASON_PIED_PIPER, REASON_PLAGUE, REASON_PROPHET, REASON_DEATH_PREACHER, REASON_VOODOO, REASON_NECROMANCER, REASON_HADES, REASON_GRAVE_ROBBER]
const KINDS: Array[StringName] = [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO, &"none"]

var id: int = 0
var kind: StringName = &""  ## Faction oder "none"
var reason_key: StringName = &""
var reason_args: Dictionary = {}
var beneficiary_ids: Array[int] = []  ## begünstigte Personen bei personenbezogenen Siegen (Manipulator)
var co_winner_ids: Array[int] = []    ## zusätzliche Mitsieger jedes Siegs: lebende Feuerteufel (RM-DR-131.5), aufsteigend
var status: StringName = STATUS_OPEN
var detected_at_command: int = -1
var resolved_at_command: int = -1
var rejection_reason: String = ""


## Gleiche Bedingung für dieselben Personen (für die Duplikatprüfung).
func semantic_key() -> String:
	return "%s|%s|%s|%s" % [kind, reason_key, str(beneficiary_ids), str(co_winner_ids)]


func to_dict() -> Dictionary:
	var d := {
		"id": id,
		"kind": String(kind),
		"reason_key": String(reason_key),
		"reason_args": reason_args.duplicate(true),
		"beneficiary_ids": beneficiary_ids.duplicate(),
		"status": String(status),
		"detected_at_command": detected_at_command,
		"resolved_at_command": resolved_at_command,
		"rejection_reason": rejection_reason,
	}
	# Nur gespeichert, wenn vorhanden: Spielstände ohne Feuerteufel bleiben unverändert.
	if not co_winner_ids.is_empty():
		d["co_winner_ids"] = co_winner_ids.duplicate()
	return d


static func from_dict(d: Dictionary) -> WinCandidate:
	var w := WinCandidate.new()
	w.id = DictRead.get_int(d, "id")
	w.kind = StringName(DictRead.get_string(d, "kind"))
	w.reason_key = StringName(DictRead.get_string(d, "reason_key"))
	w.reason_args = DictRead.get_dict(d, "reason_args").duplicate(true)
	var ids: Variant = DictRead.to_int_array(DictRead.get_array(d, "beneficiary_ids"))
	if ids == null or not d.get("beneficiary_ids") is Array:
		return null
	w.beneficiary_ids = ids
	if d.has("co_winner_ids"):
		var co: Variant = DictRead.to_int_array(DictRead.get_array(d, "co_winner_ids"))
		if co == null or not d.get("co_winner_ids") is Array or (co as Array).is_empty():
			return null
		w.co_winner_ids = co
	w.status = StringName(DictRead.get_string(d, "status"))
	w.detected_at_command = DictRead.get_int(d, "detected_at_command", -1)
	w.resolved_at_command = DictRead.get_int(d, "resolved_at_command", -1)
	w.rejection_reason = DictRead.get_string(d, "rejection_reason")
	if w.id < 1 or not KINDS.has(w.kind) or not REASONS.has(w.reason_key) or not STATUSES.has(w.status):
		return null
	# Offen heißt unaufgelöst; aufgelöste Kandidaten tragen den Auflösungsbefehl, abgelehnte einen Grund.
	if (w.status == STATUS_OPEN) != (w.resolved_at_command == -1):
		return null
	if (w.status == STATUS_REJECTED) != (w.rejection_reason.strip_edges() != ""):
		return null
	return w
