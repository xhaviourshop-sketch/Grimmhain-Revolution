class_name GameEvent
extends RefCounted
## Unveränderliches Ereignis (A-14). Entsteht nur in RulesEngine aus einem
## angenommenen Befehl. Grundlage für Protokoll, Replay-Vergleich und später
## Audio/VFX und Projektionen.

const GAME_STARTED := &"GameStarted"
const ROLE_ASSIGNED := &"RoleAssigned"
const PHASE_CHANGED := &"PhaseChanged"
const PROMPT_OPENED := &"PromptOpened"
const PROMPT_ANSWERED := &"PromptAnswered"
const NIGHT_STEP_SKIPPED := &"NightStepSkipped"
const NO_NIGHT_KILL := &"NoNightKill"
const SEAT_DIED := &"SeatDied"  ## Name nach 03 §5.6; referenziert die Personen-ID
const KILL_IGNORED := &"KillIgnored"
const NOMINATION_RECORDED := &"NominationRecorded"
const EXECUTION_CONFIRMED := &"ExecutionConfirmed"
const NO_EXECUTION := &"NoExecution"
const DAY_ENDED := &"DayEnded"
const WIN_DETECTED := &"WinDetected"
const WIN_CONFIRMED := &"WinConfirmed"
const WIN_REJECTED := &"WinRejected"
const WIN_STATUS_PROVISIONAL := &"WinStatusProvisional"  ## DR-14: nach jedem Tod
const WIN_STATUS_FINAL := &"WinStatusFinal"              ## DR-14: nach allen Reaktionen
const STEP_BEGUN := &"StepBegun"
const STEP_SKIPPED := &"StepSkipped"
const PROMPT_CANCELLED := &"PromptCancelled"
const REACTION_QUEUED := &"ReactionQueued"
const REACTION_RESOLVED := &"ReactionResolved"
const GM_CORRECTED := &"GmCorrected"
const PROTECTION_SET := &"ProtectionSet"    ## bestätigte Schutzwahl (nur Spielleiter)
const KILL_PREVENTED := &"KillPrevented"    ## verhinderter Rudelangriff (nur Spielleiter)

var index: int = 0          ## fortlaufend über die ganze Partie
var command_index: int = 0  ## Index des auslösenden Befehls
var type: StringName = &""
var visibility: StringName = Visibility.GM
var actor_id: int = -1      ## nur bei Visibility.ACTOR gesetzt
var data: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"index": index,
		"command_index": command_index,
		"type": String(type),
		"visibility": String(visibility),
		"actor_id": actor_id,
		"data": data.duplicate(true),
	}
