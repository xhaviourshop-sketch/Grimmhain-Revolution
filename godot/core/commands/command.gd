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
const BEGIN_STEP := &"BeginStep"
const SKIP_STEP := &"SkipStep"
const CANCEL_PROMPT := &"CancelPrompt"
const GM_CORRECTION := &"GmCorrection"
const OVERRIDE_SHOWN_ROLE := &"OverrideShownRole"
const AMALIA_SACRIFICE := &"AmaliaSacrifice"
const NAME_WOLF := &"NameWolf"  ## Nekromant benennt am Tag geheim einen Wolf (E-19)

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


## Mehrstufiger Prompt (Waldhexe): Antwort auf die aktuelle Stufe `stage` mit Ja/Nein
## bzw. Bestätigung (`choice`).
static func answer_choice(prompt_id: int, stage: String, choice: bool) -> Command:
	return create(ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": stage, "choice": choice})


## Mehrstufiger Prompt: Antwort auf eine Auswahlstufe (z. B. Giftziel).
static func answer_stage_targets(prompt_id: int, stage: String, targets: Array) -> Command:
	return create(ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": stage, "targets": targets})


## Orakel-Prompt in der Stufe „Gezeigt“: gezeigtes Ergebnis übersteuern (Spielleiter,
## bestätigte Warnung und Begründung). Wahrheit und ermitteltes Ergebnis bleiben unverändert.
static func override_shown_role(prompt_id: int, shown_role: String, reason: String) -> Command:
	return create(OVERRIDE_SHOWN_ROLE, {"prompt_id": prompt_id, "shown_role": shown_role, "reason": reason, "confirmed": true})


static func end_night() -> Command:
	return create(END_NIGHT)


static func nominate(nominator_id: int, nominee_id: int) -> Command:
	return create(NOMINATE, {"nominator_id": nominator_id, "nominee_id": nominee_id})


## target_id = GameState.NO_TARGET bedeutet „keine Hinrichtung heute“.
static func decide_execution(target_id: int) -> Command:
	return create(DECIDE_EXECUTION, {"target_id": target_id})


static func end_day() -> Command:
	return create(END_DAY)


## Amalia opfert sich am Tag; `answer` ist die wahrheitsgemäße Ja/Nein-Antwort des Spielleiters (I-09).
static func amalia_sacrifice(player_id: int, answer: bool) -> Command:
	return create(AMALIA_SACRIFICE, {"player_id": player_id, "answer": answer})


static func confirm_win(candidate_id: int) -> Command:
	return create(CONFIRM_WIN, {"candidate_id": candidate_id})


static func reject_win(candidate_id: int, reason: String) -> Command:
	return create(REJECT_WIN, {"candidate_id": candidate_id, "reason": reason})


## step_id: genau der erwartete nächste Schritt (RulesEngine.next_step_id).
static func begin_step(step_id: String) -> Command:
	return create(BEGIN_STEP, {"step_id": step_id})


static func skip_step(step_id: String, reason: String) -> Command:
	return create(SKIP_STEP, {"step_id": step_id, "reason": reason})


static func cancel_prompt(prompt_id: int, reason: String) -> Command:
	return create(CANCEL_PROMPT, {"prompt_id": prompt_id, "reason": reason})


## payload: kind ("kill" | "execute" | "revive" | "set_role" | "set_role_field" |
## "set_protection" | "remove_protection" | "set_witch_potion" | "set_rescue" |
## "remove_rescue" | "declare_winner"), target_id, trigger_effects (kill), role_id
## (set_role), field + value (set_role_field), guardian_id (+ target_id)
## (set/remove_protection), witch_id + potion + available (set_witch_potion),
## witch_id (+ target_id) (set/remove_rescue), winner_kind (declare_winner),
## reason (Pflicht), confirmed = true (Pflicht, bestätigte Warnung).
static func gm_correction(p_payload: Dictionary) -> Command:
	return create(GM_CORRECTION, p_payload)


func to_dict() -> Dictionary:
	return {"type": String(type), "payload": payload.duplicate(true)}


static func from_dict(d: Dictionary) -> Command:
	return create(StringName(DictRead.get_string(d, "type")), DictRead.get_dict(d, "payload"))


## Nekromant `player_id` benennt am Tag `target_id` als Werwolf (höchstens einmal je Tag, geheim).
static func name_wolf(player_id: int, target_id: int) -> Command:
	return create(NAME_WOLF, {"player_id": player_id, "target_id": target_id})
