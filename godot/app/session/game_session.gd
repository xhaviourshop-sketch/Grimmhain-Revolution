class_name GameSession
extends RefCounted
## Anwendungsschicht zwischen UI und Regelkern (03 §3). Einzige Stelle der App, die einen
## `GameState` hält und `RulesEngine.apply` aufruft. Die UI liest nur Sichten (Kopien aus
## einfachen Werten: `view()`, `cockpit_view()`, `private_seats()`) und sendet Befehle über
## `submit()` oder die Bausteine unten, die Befehle aus dem aktuellen Prompt zusammensetzen.
## Keine eigene Regel: Annahme, Ablehnung, Ereignisse und Folgezustand kommen unverändert aus
## dem Regelkern.

signal events_applied(events: Array[GameEvent])  ## nach jedem angenommenen Befehl
signal command_rejected(error: StringName)        ## Befehl abgelehnt, Zustand unverändert
signal view_changed(view: Dictionary)             ## neue Sicht nach Annahme, Laden oder Reset

var _state: GameState = GameState.new()
var _commands: Array[Command] = []
var _events: Array[GameEvent] = []


## Reicht den Befehl an den Regelkern weiter und übernimmt bei Annahme den neuen Zustand.
func submit(command: Command) -> CommandResult:
	var result := RulesEngine.apply(_state, command)
	if not result.ok:
		command_rejected.emit(result.error)
		return result
	_state = result.state
	_commands.append(command)
	_events.append_array(result.events)
	events_applied.emit(result.events)
	view_changed.emit(view())
	return result


## Lesbare Sicht für die Darstellung. Immer eine neue Kopie aus einfachen Werten.
func view() -> Dictionary:
	var started := _state.is_started()
	return {
		"has_game": started,
		"phase": String(_state.phase) if started else "",
		"night_number": _state.night_number,
		"day_number": _state.day_number,
		"player_count": _state.players.size(),
		"command_count": _commands.size(),
	}


## Cockpit ohne Rollen (Sitzkreis, Phase, nächste Handlung, Hinweise). Siehe CockpitView.
func cockpit_view() -> Dictionary:
	return CockpitView.build(_state)


## Rollen je Person, nur für den ausdrücklich geöffneten Spielleiterbereich.
func private_seats() -> Array:
	return CockpitView.private_seats(_state) if _state.is_started() else []


## Angenommene Befehle in Reihenfolge (Kopie).
func commands() -> Array[Command]:
	return _commands.duplicate()


## Alle Ereignisse der Partie in Reihenfolge (Kopie als einfache Werte).
func event_log() -> Array:
	var out: Array = []
	for e: GameEvent in _events:
		out.append(e.to_dict())
	return out


## Fachlicher Hash des aktuellen Zustands (Prüfung und spätere Speicheranzeige).
func state_hash() -> String:
	return _state.content_hash()


## Verwirft die Sitzung (kein Spielstand).
func reset() -> void:
	_state = GameState.new()
	_commands.clear()
	_events.clear()
	view_changed.emit(view())


# --- Befehlsbausteine für die Oberfläche --------------------------------------------------------
# Jeder Baustein setzt nur Prompt-ID, Stufe oder Schritt-ID des aktuellen Zustands ein und reicht
# den Befehl weiter. Ob er gilt, entscheidet der Regelkern.

func start_night() -> CommandResult:
	return submit(Command.start_night())


func begin_next_step() -> CommandResult:
	return submit(Command.begin_step(RulesEngine.next_step_id(_state)))


func skip_next_step(reason: String) -> CommandResult:
	return submit(Command.skip_step(RulesEngine.next_step_id(_state), reason))


func cancel_prompt(reason: String) -> CommandResult:
	return submit(Command.cancel_prompt(_prompt_id(), reason))


## Auswahl von Personen; einstufige Prompts ohne Stufe, mehrstufige mit ihrer aktuellen Stufe.
func answer_targets(targets: Array) -> CommandResult:
	var p := _state.pending_prompt
	if p != null and p.stage != &"":
		return submit(Command.answer_stage_targets(p.id, String(p.stage), targets))
	return submit(Command.answer_prompt(_prompt_id(), targets))


## Ja/Nein bzw. Bestätigen (ack = Ja) der aktuellen Stufe.
func answer_choice(choice: bool) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.answer_choice(_prompt_id(), String(p.stage) if p != null else "", choice))


func answer_option(index: int) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.create(Command.ANSWER_PROMPT, {"prompt_id": _prompt_id(), "stage": String(p.stage) if p != null else "", "option": index}))


func answer_prediction(kind: String, number: int) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.create(Command.ANSWER_PROMPT, {"prompt_id": _prompt_id(), "stage": String(p.stage) if p != null else "",
		"prediction": {"kind": kind, "number": number}}))


func override_shown_role(role_id: String, reason: String) -> CommandResult:
	return submit(Command.override_shown_role(_prompt_id(), role_id, reason))


func end_night() -> CommandResult:
	return submit(Command.end_night())


func nominate(nominator_id: int, nominee_id: int) -> CommandResult:
	return submit(Command.nominate(nominator_id, nominee_id))


## Hinrichtung (target_id = -1: keine Hinrichtung heute). `extra` enthält nur die Pflichtfelder aus
## `execution_preview` (cerberus_defend, sage_curse), die der Spielleiter beantwortet hat.
func decide_execution(target_id: int, extra: Dictionary = {}) -> CommandResult:
	var payload := {"target_id": target_id}
	payload.merge(extra)
	return submit(Command.create(Command.DECIDE_EXECUTION, payload))


func end_day() -> CommandResult:
	return submit(Command.end_day())


func amalia_sacrifice(player_id: int, answer: bool) -> CommandResult:
	return submit(Command.amalia_sacrifice(player_id, answer))


func name_wolf(player_id: int, target_id: int) -> CommandResult:
	return submit(Command.name_wolf(player_id, target_id))


## Geheime Vorschau einer Hinrichtung (nur Spielleitung): wer tatsächlich stirbt und welche
## Entscheidungen der Regelkern zusätzlich verlangt. Siehe CockpitView.execution_preview.
func execution_preview(target_id: int) -> Dictionary:
	return CockpitView.execution_preview(_state, target_id)


## Geheime Tagesaktionen einzelner Rollen (Amalia, Nekromant), nur für den privaten Bereich.
func secret_day_actions() -> Array:
	return CockpitView.secret_day_actions(_state)


## Spielleiterkorrektur (GmCorrections): `payload` mit kind, Feldern und Begründung; die bestätigte
## Warnung setzt dieser Baustein (confirmed = true), weil die Oberfläche sie vorher abfragt.
func gm_correction(payload: Dictionary) -> CommandResult:
	var p := payload.duplicate(true)
	p["confirmed"] = true
	return submit(Command.gm_correction(p))


func confirm_win(candidate_id: int) -> CommandResult:
	return submit(Command.confirm_win(candidate_id))


func reject_win(reason: String) -> CommandResult:
	# RejectWin lehnt immer alle offenen Kandidaten gemeinsam ab; ohne candidate_id.
	return submit(Command.create(Command.REJECT_WIN, {"reason": reason}))


func _prompt_id() -> int:
	return _state.pending_prompt.id if _state.pending_prompt != null else -1
