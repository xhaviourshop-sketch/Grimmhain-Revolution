class_name Command
extends RefCounted
## Absicht des Spielleiters, serialisierbar (03 §5.6). Nur angenommene Befehle
## verändern den Zustand. Entsprechung zu den Masterplan-Namen: siehe godot/README.md.

const START_GAME := &"StartGame"
const START_NIGHT := &"StartNight"
const ANSWER_PROMPT := &"AnswerPrompt"
const END_NIGHT := &"EndNight"
const NOMINATE := &"Nominate"
const DECIDE_EXECUTION := &"DecideExecution"
const END_DAY := &"EndDay"
const CONFIRM_WIN := &"ConfirmWin"
const REJECT_WIN := &"RejectWin"

var type: StringName = &""
var payload: Dictionary = {}


static func create(p_type: StringName, p_payload: Dictionary = {}) -> Command:
	var c := Command.new()
	c.type = p_type
	c.payload = CanonicalJson.normalize(p_payload)
	return c


## payload: round_id, seed, assignment ("manual" | "random"), players [{id, name}],
## seat_order [id…], roles {"<id>": role_id} (manual) bzw. role_pool [role_id…] (random)
static func start_game(p_payload: Dictionary) -> Command:
	return create(START_GAME, p_payload)


static func start_night() -> Command:
	return create(START_NIGHT)


## targets: leeres Array = ausdrücklich „kein Opfer“.
static func answer_prompt(prompt_id: int, targets: Array) -> Command:
	return create(ANSWER_PROMPT, {"prompt_id": prompt_id, "targets": targets})


static func end_night() -> Command:
	return create(END_NIGHT)


static func nominate(nominator_id: int, nominee_id: int) -> Command:
	return create(NOMINATE, {"nominator_id": nominator_id, "nominee_id": nominee_id})


## target_id = GameState.NO_TARGET bedeutet „keine Hinrichtung heute“.
static func decide_execution(target_id: int) -> Command:
	return create(DECIDE_EXECUTION, {"target_id": target_id})


static func end_day() -> Command:
	return create(END_DAY)


static func confirm_win(candidate_id: int) -> Command:
	return create(CONFIRM_WIN, {"candidate_id": candidate_id})


static func reject_win(candidate_id: int, reason: String) -> Command:
	return create(REJECT_WIN, {"candidate_id": candidate_id, "reason": reason})


func to_dict() -> Dictionary:
	return {"type": String(type), "payload": payload.duplicate(true)}


static func from_dict(d: Dictionary) -> Command:
	return create(StringName(DictRead.get_string(d, "type")), DictRead.get_dict(d, "payload"))
