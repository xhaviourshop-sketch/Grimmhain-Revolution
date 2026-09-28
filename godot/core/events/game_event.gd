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
const TRACKER_RECORDED := &"TrackerRecorded"  ## Richtung für den Fährtenleser (nur Spielleiter)
const TRACKER_REVEALED := &"TrackerRevealed"  ## dieselbe Richtung für den Fährtenleser (actor)
const JUDGE_MARKED := &"JudgeMarked"              ## Markierung des Korrupten Richters (nur Spielleiter)
const JUDGE_NOMINATED := &"JudgeNominated"        ## Nominierung aus der Markierung, mit Richter (nur Spielleiter)
const JUDGE_NOMINATION_PUBLIC := &"JudgeNominationRecorded"  ## dieselbe Nominierung öffentlich, ohne Nominierenden
const NEW_WOLF_BLOCKED := &"NewWolfBlocked"        ## Wächter am Tor verhindert einen neuen Wolf (nur Spielleiter)
const NEW_WOLF_BLOCKED_NOTICE := &"NewWolfBlockedNotice"  ## private Mitteilung an die betroffene Person (actor)
const HOUND_RECORDED := &"HoundRecorded"      ## Prüfung des Spürhunds (nur Spielleiter)
const HOUND_REVEALED := &"HoundRevealed"      ## Ergebnis ✓/✗ für den Spürhund (actor)
const PARASITE_ATTACHED := &"ParasiteAttached"  ## Wirtwahl des Parasiten (nur Spielleiter)
const NIGHT_BLOCKED := &"NightBlocked"          ## Blockade durch Schattenhund oder Albtraumwolf (nur Spielleiter)
const WOLF_POISONED := &"WolfPoisoned"          ## Giftpranke des Giftwolfs (nur Spielleiter)
const WOLF_POISON_NOTICE := &"WolfPoisonNotice"  ## private Mitteilung an das vergiftete Ziel (actor)
const GROWTH_CHANGED := &"GrowthChanged"        ## Fenrir-Stufe oder Cerberus-Köpfe (nur Spielleiter)
const EXECUTION_DEFENDED := &"ExecutionDefended"  ## Cerberus wehrt eine Hinrichtung ab (nur Spielleiter)
const HANGMAN_MARKED := &"HangmanMarked"        ## Markierung des Henkers (nur Spielleiter)
const DREAM_RECORDED := &"DreamRecorded"        ## Vision des Traumdeuters mit Wölfen (nur Spielleiter)
const DREAM_REVEALED := &"DreamRevealed"        ## drei Namen, „mindestens ein Wolf“, für den Traumdeuter (actor)
const BOUNTY_RECORDED := &"BountyRecorded"      ## Liste des Kopfgeldjägers mit Wölfen (nur Spielleiter)
const BOUNTY_REVEALED := &"BountyRevealed"      ## drei Namen für den Kopfgeldjäger (actor)
const BOUNTY_EXPIRED := &"BountyExpired"        ## Liste verfallen, zu wenige Ziele (actor)
const KING_RECORDED := &"KingRecorded"          ## Dorfperson mit Rolle für den König (nur Spielleiter)
const KING_REVEALED := &"KingRevealed"          ## dieselbe Information für den König (actor)
const WARRIOR_RECORDED := &"WarriorRecorded"    ## Angriff der Kriegerin des Lichts (nur Spielleiter)
const WARRIOR_REVEALED := &"WarriorRevealed"    ## Wolf ja/nein für die Kriegerin (actor)
const BLOOD_RECORDED := &"BloodRecorded"        ## Opfer und genannte Wölfe des Blutpriesters (nur Spielleiter)
const BLOOD_REVEALED := &"BloodRevealed"        ## genannte Wölfe für den Blutpriester (actor)
const AMALIA_ANSWERED := &"AmaliaAnswered"      ## Selbstopfer Amalias mit Ja/Nein-Antwort (öffentlich)
const DETECTIVE_RECORDED := &"DetectiveRecorded"  ## Detektiv-Hinweis mit Ursprung (nur Spielleiter)
const DETECTIVE_HINT := &"DetectiveHint"        ## Richtung vom Platz des toten Wolfs (öffentlich)
const ETERNAL_RECORDED := &"EternalRecorded"    ## Prüfung der Ewigen (nur Spielleiter)
const ETERNAL_REVEALED := &"EternalRevealed"    ## Ja/Nein für jede wache Ewige (actor)
const SAGE_CURSED := &"SageCursed"              ## Fluch des Weisen mit Dauer (nur Spielleiter)
const WEAPON_GIVEN := &"WeaponGiven"            ## Waffe des Dorfschmieds vergeben (nur Spielleiter)
const SHIELD_GIVEN := &"ShieldGiven"            ## Schild des Schutzgeists vergeben (nur Spielleiter)
const GHOST_WOLF_ALERT := &"GhostWolfAlert"     ## Schutzgeist hat einen Wolf gewählt (öffentlich, ohne Namen)
const DOOM_JUDGED := &"DoomJudged"              ## Urteil des Verdammniswächters (nur Spielleiter)
const MARTYR_CHOSEN := &"MartyrChosen"          ## Märtyrerin opfert sich für das Rudelopfer (nur Spielleiter)
const LOKI_BOUND := &"LokiBound"                ## Paar des Loki (nur Spielleiter)
const RED_REFUGE := &"RedRefuge"                ## Zuflucht des Rotkäppchens, gewährt oder nicht (nur Spielleiter)
const WIDOW_STRUCK := &"WidowStruck"            ## Wahl der Schwarzen Witwe mit gefundenem Paar (nur Spielleiter)
const SHADOW_LINKED := &"ShadowLinked"          ## Verknüpfung des Schattenwanderers (nur Spielleiter)
const APPLE_USED := &"AppleUsed"                ## Apfel verdoppelt einen Nachtschritt (nur Spielleiter)
const DEMON_CURSED := &"DemonCursed"            ## Fluch des Dämonischen Wolfs (nur Spielleiter)
const LYCAON_CONVERTED := &"LycaonConverted"    ## Wahl des Königs Lykaon mit Verbündetem (nur Spielleiter)
const LYCAON_NOTICE := &"LycaonNotice"          ## neue Rolle für die verwandelte Person (actor)
const SOULS_SWAPPED := &"SoulsSwapped"          ## Rollentausch des Seelentauschers (nur Spielleiter)
const SOUL_SWAP_REVEALED := &"SoulSwapRevealed"  ## neue Rolle für eine lebende betroffene Person (actor)
const REVIVED_BY_ROLE := &"RevivedByRole"      ## Wiederbelebung durch Kutscher oder Frankenstein (nur Spielleiter)
const REVIVAL_NOTICE := &"RevivalNotice"        ## Rolle der wiederbelebten Person (actor)
const PLAYER_REVIVED := &"PlayerRevived"        ## Wiederbelebung, öffentlich am Morgen (ohne Rolle)
const CHARMED := &"Charmed"                    ## Verzauberung des Rattenfängers (nur Spielleiter)
const INFECTED := &"Infected"                  ## Infektion durch die Pestbringerin (nur Spielleiter)
const PLAGUE_SPREAD := &"PlagueSpread"          ## Ausbreitung der Seuche am Morgen (nur Spielleiter)
const PROPHET_MARKED := &"ProphetMarked"        ## Markierungen des Propheten (nur Spielleiter)
const PROPHET_UNLOCKED := &"ProphetUnlocked"    ## Prophet freigeschaltet (nur Spielleiter)
const PROPHECY_SET := &"ProphecySet"            ## Vorhersage des Todespredigers (nur Spielleiter)
const PREACHER_FULFILLED := &"PreacherFulfilled"  ## Vorhersage des Todespredigers erfüllt (nur Spielleiter)
const FIRE_MARKED := &"FireMarked"              ## Markierung des Feuerteufels gesetzt oder behalten (nur Spielleiter)
const FIRE_BURNED := &"FireBurned"              ## Brand nach dem Tod eines markierten Ziels (nur Spielleiter)
const VOODOO_DOLL_GIVEN := &"VoodooDollGiven"    ## Puppe des Voodoo-Priesters vergeben oder verzichtet (nur Spielleiter)
const NECRO_SHIELD := &"NecroShield"            ## Schild des Nekromanten errichtet (nur Spielleiter)
const NECRO_REDIRECTED := &"NecroRedirected"    ## Rudelangriff auf den Nekromanten umgelenkt (nur Spielleiter)
const NECRO_NAMED := &"NecroNamed"              ## Nekromant hat einen Wolf benannt, mit Treffer (nur Spielleiter)
const HADES_LIGHT := &"HadesLight"              ## Hades erhält ein Licht aus einem Tod (nur Spielleiter)
const HADES_ACTED := &"HadesActed"              ## Hades tötet und/oder kauft die Barriere (nur Spielleiter)
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
