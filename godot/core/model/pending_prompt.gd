class_name PendingPrompt
extends RefCounted
## Offene Eingabe als Teil des Spielstands (03 §5.5, A-10). Genutzt für die
## Opferwahl des Rudels, Schutzengel, Reaktionen und die mehrstufigen Prompts von
## Waldhexe, Orakel und Lehrling (B-05): Dort stehen die bisherigen Teilantworten in `partial` und
## die aktuelle Stufe in `stage` (WitchStep, OracleStep, ApprenticeRules); einstufige Prompts haben
## `stage` = &"". Den Bezug zum übrigen Zustand prüft GameState.from_dict.

const KIND_PICK_PLAYERS := &"pick_players"
const OWNER_PACK := &"pack"
const OWNER_REACTION := &"reaction"
const OWNER_GUARD := &"schutzengel"
const OWNER_WITCH := &"waldhexe"
const KIND_WITCH_CHAIN := &"witch_chain"
const OWNER_ORACLE := &"das-orakel"
const OWNER_WOLF_CHILD := &"wolfskind"
const KIND_ORACLE_CHECK := &"oracle_check"
const OWNER_APPRENTICE := &"lehrling"
const KIND_APPRENTICE_CHAIN := &"apprentice_choice"
const OWNER_CHRONICLER := &"dorfchronistin"
const OWNER_BOUND := &"die-gebundenen"
const OWNER_RANGER := &"waldlaeufer"
const OWNER_DOCTOR := &"doktor"
const OWNER_TRACKER := &"faehrtenleser"
const OWNER_JUDGE := &"korrupter-richter"
const KIND_INFO_SHOWN := &"info_shown"  ## Informationsschritt mit Bestätigung „Gezeigt“ (InfoSteps)

var id: int = 0
var kind: StringName = KIND_PICK_PLAYERS
var owner: StringName = &""
var actor_id: int = -1  ## -1 = Gruppe (Rudel)
var min_count: int = 0
var max_count: int = 0
var allowed_ids: Array[int] = []
var partial: Dictionary = {}
var cancellable: bool = false
var step_id: String = ""  ## Regelschritt, zu dem der Prompt gehört (BeginStep/SkipStep)
var stage: StringName = &""  ## aktuelle Stufe eines mehrstufigen Prompts


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
		"step_id": step_id,
		"stage": String(stage),
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
	p.step_id = DictRead.get_string(d, "step_id")
	p.stage = StringName(DictRead.get_string(d, "stage"))
	# Die Stufe muss zu den gespeicherten Teilantworten passen, sonst wäre die Fortsetzung mehrdeutig.
	if p.owner == OWNER_WITCH:
		if not WitchStep.is_consistent(p):
			return null
	elif p.owner == OWNER_ORACLE:
		if not OracleStep.STAGES.has(p.stage):
			return null
	elif p.owner == OWNER_APPRENTICE:
		if not ApprenticeRules.STAGES.has(p.stage):
			return null
	elif InfoSteps.OWNERS.has(p.owner):
		if not InfoSteps.STAGES.has(p.stage):
			return null
	elif p.stage != &"":
		return null
	return p
