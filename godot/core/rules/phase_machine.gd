class_name PhaseMachine
extends RefCounted
## Phasenmaschine (A-15, 03 §4.3). Legt fest, in welcher Phase welcher Befehl
## zulässig ist, und führt Phasenwechsel mit Ereignis aus.
##
##   SETUP ─StartNight→ NIGHT ─EndNight→ DAWN_RESOLUTION ─(automatisch)→ DAY
##   DAY ─EndDay, StartNight→ NIGHT      jede Phase ─ConfirmWin→ GAME_OVER
##
## Ein offener Prompt blockiert jeden Phasenwechsel (G-PH-3).

const TRANSITIONS := {
	Phase.SETUP: [Phase.NIGHT, Phase.GAME_OVER],
	Phase.NIGHT: [Phase.DAWN_RESOLUTION, Phase.GAME_OVER],
	Phase.DAWN_RESOLUTION: [Phase.DAY, Phase.GAME_OVER],
	Phase.DAY: [Phase.NIGHT, Phase.GAME_OVER],
	Phase.GAME_OVER: [],
}


static func can_enter(from: StringName, to: StringName) -> bool:
	return (TRANSITIONS.get(from, []) as Array).has(to)


## Prüft, ob der Befehlstyp in der aktuellen Phase zulässig ist. Leerer Rückgabewert = zulässig.
static func check_command(state: GameState, type: StringName) -> StringName:
	if state.phase == Phase.GAME_OVER:
		return &"game_over"
	if state.win_candidate != null and type != Command.CONFIRM_WIN and type != Command.REJECT_WIN:
		return &"win_candidate_open"
	match type:
		Command.START_GAME:
			if state.is_started():
				return &"game_already_started"
		Command.START_NIGHT:
			if not state.is_started():
				return &"game_not_started"
			if state.phase == Phase.DAY:
				if state.day_step != Phase.DAY_ENDED:
					return &"day_not_ended"
			elif state.phase != Phase.SETUP:
				return &"wrong_phase"
		Command.ANSWER_PROMPT, Command.END_NIGHT:
			if state.phase != Phase.NIGHT:
				return &"wrong_phase"
			if type == Command.END_NIGHT and state.pending_prompt != null:
				return &"prompt_open"
		Command.NOMINATE, Command.DECIDE_EXECUTION, Command.END_DAY:
			if state.phase != Phase.DAY:
				return &"wrong_phase"
			if state.day_step == Phase.DAY_ENDED:
				return &"day_already_ended"
			if type != Command.END_DAY and state.day_step == Phase.DAY_EXECUTION_DECIDED:
				return &"execution_already_decided"
			if type == Command.END_DAY and state.day_step != Phase.DAY_EXECUTION_DECIDED:
				return &"execution_not_decided"
		Command.CONFIRM_WIN, Command.REJECT_WIN:
			pass
		_:
			return &"unknown_command"
	return &""


## Wechselt die Phase und protokolliert den Wechsel. Unzulässige Wechsel werden ignoriert
## (können nach check_command nicht auftreten) und liefern false.
static func enter(ctx: RuleContext, to: StringName) -> bool:
	var s := ctx.state
	if not can_enter(s.phase, to) or (s.pending_prompt != null and to != Phase.GAME_OVER):
		return false
	var from := s.phase
	s.phase = to
	match to:
		Phase.NIGHT:
			s.night_number += 1
			s.day_step = Phase.DAY_NONE
		Phase.DAY:
			s.day_number += 1
			s.day_step = Phase.DAY_DISCUSSION
		Phase.GAME_OVER:
			s.day_step = Phase.DAY_NONE
	ctx.emit(GameEvent.PHASE_CHANGED, Visibility.PUBLIC, {
		"from": from, "to": to, "night_number": s.night_number, "day_number": s.day_number,
	})
	return true
