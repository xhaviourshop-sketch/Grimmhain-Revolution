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
const PROMPT_STAGE_ANSWERED := &"PromptStageAnswered"  ## Teilantwort eines mehrstufigen Prompts (nur Spielleiter)
const WITCH_ACTED := &"WitchActed"          ## bestätigte Entscheidung der Waldhexe (nur Spielleiter)
const INFO_OVERRIDDEN := &"InfoOverridden"    ## gezeigtes Ergebnis übersteuert (nur Spielleiter)
const INFO_RECORDED := &"InfoRecorded"        ## vollständiger Informationsdatensatz (nur Spielleiter)
const INFO_REVEALED := &"InfoRevealed"        ## gezeigtes Ergebnis für die handelnde Person (actor)
const WOLF_CHILD_BOUND := &"WolfChildBound"              ## Vorbildwahl des Wolfskinds (nur Spielleiter)
const WOLF_CHILD_TRANSFORMED := &"WolfChildTransformed"  ## Verwandlung des Wolfskinds (nur Spielleiter)
const EXECUTION_REDIRECTED := &"ExecutionRedirected"  ## Spiegelung einer Hinrichtung (nur Spielleiter)
const MIRROR_NOT_TRIGGERED := &"MirrorNotTriggered"    ## Hinrichtung eines Spiegelwolfs ohne Spiegelung, mit Grund (nur Spielleiter)
const APPRENTICE_OPTIONS_SHOWN := &"ApprenticeOptionsShown"        ## Rollenoptionen für den Lehrling (actor, ohne Personen)
const APPRENTICE_CHOICE_CONFIRMED := &"ApprenticeChoiceConfirmed"  ## bestätigte Wahl für den Lehrling (actor, nur Rollen)
const APPRENTICE_BOUND := &"ApprenticeBound"  ## vollständige Bindung des Lehrlings (nur Spielleiter)
const ROLE_CHANGED := &"RoleChanged"          ## Rollenwechsel durch Erbe des Lehrlings (nur Spielleiter)
const DEATH_SEEKER_FULFILLED := &"DeathSeekerFulfilled"  ## Selbstmörder bei mindestens 5 Toten hingerichtet (nur Spielleiter)
const CHRONICLE_RECORDED := &"ChronicleRecorded"  ## Zahl der Einzelsiegpersonen für die Chronistin (nur Spielleiter)
const CHRONICLE_REVEALED := &"ChronicleRevealed"  ## dieselbe Zahl für die Chronistin (actor)
const BOUND_RECORDED := &"BoundRecorded"          ## lebende Gebundene in Nacht 1 (nur Spielleiter)
const BOUND_REVEALED := &"BoundRevealed"          ## die anderen lebenden Gebundenen für eine Gebundene (actor)
const RANGER_RECORDED := &"RangerRecorded"      ## Wolfszahl für den Waldläufer (nur Spielleiter)
const RANGER_REVEALED := &"RangerRevealed"      ## dieselbe Zahl für den Waldläufer (actor)
const DOCTOR_RECORDED := &"DoctorRecorded"      ## Blutprobe des Doktors (nur Spielleiter)
const DOCTOR_REVEALED := &"DoctorRevealed"      ## Ergebnis „gleiches Team“ für den Doktor (actor)
const ALARM_BELLS := &"AlarmBells"              ## Glocken des Nachtwächters (öffentlich, ohne Namen)
const ALARM_BELLS_DETAIL := &"AlarmBellsDetail"  ## auslösende Nachtwächter und Nachbarn (nur Spielleiter)
const STEP_DROPPED := &"StepDropped"        ## Nachtschritt entfällt automatisch (tot, keine Entscheidung möglich)

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
