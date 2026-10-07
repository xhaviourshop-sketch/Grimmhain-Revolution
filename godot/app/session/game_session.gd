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
signal state_replaced                             ## Zustand durch Rückgängig/Wiederholen ersetzt (danach speichern)
## Darstellungshinweis (PresentationCue) aus einem soeben angenommenen Befehl. Nie beim Laden, Rückgängig, Wiederholen oder
## Neuzeichnen; er trägt nur seine Kennung und ändert nichts am Zustand.
signal cue_requested(cue: StringName)

var _state: GameState = GameState.new()
var _commands: Array[Command] = []
var _events: Array[GameEvent] = []
var _redo: Array[Command] = []  ## zurückgenommene Befehle, letzter zuerst wiederholbar
var _five_dead_at: int = -1  ## Index des Befehls, der den Hinweis bei fünf Toten tatsächlich ausgelöst hat (DI-09), sonst -1
var _five_dead_armed: bool = true  ## Die Zahl der Toten war seit dem letzten Erreichen von fünf wieder unter fünf (oder nie darüber)


## Reicht den Befehl an den Regelkern weiter und übernimmt bei Annahme den neuen Zustand.
func submit(command: Command) -> CommandResult:
	var result := RulesEngine.apply(_state, command)
	if not result.ok:
		command_rejected.emit(result.error)
		return result
	var before := _state
	_state = result.state
	_commands.append(command)
	_events.append_array(result.events)
	_redo.clear()  # ein neuer Befehl verwirft zurückgenommene
	events_applied.emit(result.events)
	view_changed.emit(view())
	if _observe_five_dead(before, _state, _commands.size() - 1):
		cue_requested.emit(PresentationCue.FIVE_DEAD)
	return result


## DI-09 (Entscheidung B): Ein Auslöseversuch ist jedes Erreichen von fünf öffentlichen Toten, nachdem die Zahl unter fünf lag.
## Er löst nur aus, wenn dann eine lebende Person die Rolle Selbstmörder hat; ein erfolgloser Versuch verbraucht den Hinweis nicht.
## Nach einer tatsächlichen Auslösung (`_five_dead_at`) gibt es keine weitere. Fünf Tote ohne vorheriges Absinken unter fünf sind
## kein neuer Versuch, außer eine lebende Person erhält die Rolle Selbstmörder, während schon fünf Personen tot sind
## (Entscheidung 6B: Rollenübernahme oder Spielleiterkorrektur); sie gilt als neuer Versuch, auch wenn sie in der Nacht geschieht
## und erst mit der Morgenauflösung öffentlich wird. Wiederbelebung ist keine Rollenübernahme.
## Gibt zurück, ob der Hinweis an diesem Zustand (nach Befehl `index`) ausgelöst wird; Laden, Wiederholen und Neuzeichnen melden nie.
func _observe_five_dead(before: GameState, s: GameState, index: int) -> bool:
	if PresentationCue.dead_count(s) < PresentationCue.THRESHOLD:
		_five_dead_armed = true
		return false
	if PresentationCue.death_seeker_gained(before, s):
		_five_dead_armed = true
	if not _five_dead_armed or not PresentationCue.five_dead_reached(s):
		return false  # Nacht mit schon toten Personen ist kein neuer Versuch; öffentlich wird es erst am Morgen
	_five_dead_armed = false
	if _five_dead_at != -1 or not PresentationCue.five_dead_eligible(s):
		return false
	_five_dead_at = index
	return true


## Nach Laden oder Rückgängig: Zustand des Hinweises aus der Befehlsfolge neu bestimmen (gleiche Auswertung wie im Betrieb).
## Ohne mindestens fünf Todesereignisse gab es nie einen Versuch.
func _rescan_five_dead() -> void:
	_five_dead_at = -1
	_five_dead_armed = true
	var deaths := 0
	for e: GameEvent in _events:
		if e.type == GameEvent.SEAT_DIED:
			deaths += 1
	if deaths < PresentationCue.THRESHOLD:
		return
	var s := GameState.new()
	for i: int in _commands.size():
		var r := RulesEngine.apply(s, _commands[i])
		if not r.ok:
			return
		var before := s
		s = r.state
		_observe_five_dead(before, s, i)


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


## Warnungen der Mini-Nachtkarte zur Karte `next` und der aktuellen Auswahl (nur Spielleitung), siehe NightWarnings.
func night_warnings(next: Dictionary, selection: Array) -> Array:
	return NightWarnings.build(_state, next, selection)


## Nur Rollen-Vorschau (Einstellungen): ändert den Zustand einer Wegwerf-Partie ohne Befehl, damit ein Sonderfall der Nachtkarte sichtbar
## wird (Warnungsarten aus NightWarnings.kinds_for_role). Nie in echten Partien; die Vorschau speichert nichts. `targets`: wählbare
## Personen ohne die Rolle; `holder`: Person mit der Rolle. „protected“ gibt der ersten Person ein Schild, „cursed“ verflucht sie,
## „lovers“ verbindet die ersten beiden als Liebende, „blocked“ blockiert die Rolle (ihr noch nicht begonnener Schritt entfällt, die nächste
## Karte trägt die Warnung). Ergebnis: ob etwas geändert wurde. Jeder Eintrag besteht die Zustandsprüfung (`GameState.from_dict`).
func preview_special(kinds: Array, targets: Array, holder: int) -> bool:
	var changed := false
	if not targets.is_empty() and (kinds.has("protected") or kinds.has("cursed") or kinds.has("lovers")):
		var first := int(targets[0])
		if kinds.has("protected"):
			_state.shields.append({"holder_id": first, "source_id": first, "night": maxi(_state.night_number - 1, 0)})
		if kinds.has("cursed"):
			_state.players[first].cursed = true
		if kinds.has("lovers") and targets.size() >= 2:
			_state.loki_pairs.append({"loki_id": first, "a": first, "b": int(targets[1]), "kind": "love", "ended": false})
		changed = true
	elif kinds.has("blocked"):
		var i := _state.next_night_step
		if _state.phase == Phase.NIGHT and _state.pending_prompt == null and i < _state.night_plan.size() - 1 and _state.players.has(holder):
			_state.blocked_ids.append(holder)
			_state.night_step_status[i] = StepQueue.STATUS_SKIPPED
			_state.next_night_step = i + 1
			changed = true
	if changed:
		view_changed.emit(view())
	return changed


## Morgenbericht der letzten Nacht (öffentlicher und privater Teil getrennt), siehe MorningReport.
func morning_report() -> Dictionary:
	return MorningReport.build(_state, _events)


## Abschlussbericht der beendeten Partie (siehe GameReport) oder leer, solange kein Sieg bestätigt ist.
func game_report() -> Dictionary:
	return GameReport.build(_state, _events)


## Sieg bestätigt (Phase Spielende).
func is_over() -> bool:
	return _state.phase == Phase.GAME_OVER


## Öffentliche Tode des laufenden Tages (Namen, Rolle nur mit der Setup-Option).
func day_deaths() -> Array:
	return MorningReport.day_deaths(_state, _events)


## Angesagte Todeseffekte des laufenden Tages (DI-03), siehe MorningReport.day_effects.
func day_effects() -> Array:
	return MorningReport.day_effects(_state, _events)


## Öffentliche Kartenereignisse des laufenden Tages (Totenreichkarten), siehe MorningReport.day_cards.
func day_cards() -> Array:
	return MorningReport.day_cards(_state, _events)


## Akt I bis IV der laufenden Partie für die Dorfstimmung: der kleinste Akt, der alle Startrollen enthält (der Akt selbst steht nicht im
## Spielstand). Passt kein einzelner Akt (gemischte Rollen) oder gibt es keine Partie, gilt I.
func act_level() -> int:
	if not _state.is_started():
		return 1
	for act: StringName in ActCatalog.ACT_IDS:
		var fits := true
		for p: Player in _state.players.values():
			if not ActCatalog.contains(act, p.original_role_id):
				fits = false
				break
		if fits:
			return ActCatalog.level(act)
	return 1


## Rollen je Person, nur für den ausdrücklich geöffneten Spielleiterbereich.
func private_seats() -> Array:
	return CockpitView.private_seats(_state) if _state.is_started() else []


## Zustandsabzeichen je lebender Person (Schutz, Gift, Markierung, Stumm, Sonder) für das Brett der Spielleitung, nur Lesen.
## Geheim: nie in die öffentliche Sicht, die Oberfläche blendet sie bei „Verbergen“ aus (NightBoardView).
func board_marks() -> Dictionary:
	return NightBoardView.marks(_state)


## Nachtreihenfolge der laufenden Nacht für die Leiste der Spielleitung (geheim, siehe NightBoardView).
func night_order() -> Array:
	return NightBoardView.night_order(_state)


## Angenommene Befehle in Reihenfolge (Kopie).
func commands() -> Array[Command]:
	return _commands.duplicate()


## Alle Ereignisse der Partie in Reihenfolge (Kopie als einfache Werte).
func event_log() -> Array:
	var out: Array = []
	for e: GameEvent in _events:
		out.append(e.to_dict())
	return out


## Protokoll der Partie in Alltagssätzen („Nacht 1: Anna hat die Rolle Wolfskind.“), nur für die Spielleitung (nennt Geheimes),
## siehe LogText. Nur lesend.
func log_lines() -> Array[String]:
	return LogText.lines(event_log(), _state) if _state.is_started() else ([] as Array[String])


## Fachlicher Hash des aktuellen Zustands (Prüfung und spätere Speicheranzeige).
func state_hash() -> String:
	return _state.content_hash()


## Versionierter Spielstand als Text (StateCodec: Zustand, Befehle, Integrität).
func save_text() -> String:
	return StateCodec.encode(_state, _commands)


## Übernimmt einen gespeicherten Stand. Nur ein vollständig geprüfter Stand (Integrität, Replay)
## ersetzt die Sitzung; sonst bleibt sie unverändert. Ergebnis: Fehlergrund oder &"".
func load_text(text: String) -> StringName:
	var loaded := StateCodec.decode(text)
	if not loaded.ok:
		return loaded.error
	_state = loaded.state
	_commands = loaded.commands.duplicate()
	_events = loaded.events.duplicate()
	_redo.clear()
	_rescan_five_dead()
	view_changed.emit(view())
	return &""


func round_id() -> String:
	return _state.round_id if _state.is_started() else ""


## Öffentliche Zusammenfassung für die Spielstandliste: Namen in Sitzreihenfolge, Phase, Zähler.
## Keine Rollen, kein Nachtgeheimnis.
func summary() -> Dictionary:
	if not _state.is_started():
		return {}
	var names: Array = []
	for id: int in _state.seat_order:
		names.append(_state.players[id].name)
	return {"names": names, "player_count": _state.players.size(), "alive_count": _state.alive_ids().size(),
		"phase": String(_state.phase), "night_number": _state.night_number, "day_number": _state.day_number,
		"command_count": _commands.size()}


## Verwirft die Sitzung (kein Spielstand).
func reset() -> void:
	_state = GameState.new()
	_commands.clear()
	_events.clear()
	_redo.clear()
	_five_dead_at = -1
	_five_dead_armed = true
	view_changed.emit(view())


# --- Rückgängig und Wiederholen -------------------------------------------------------------------
# Grundlage ist die Befehlsfolge: Rückgängig spielt alle Befehle bis auf den letzten erneut ab
# (RulesEngine.replay, deterministisch über den gespeicherten Seed); Wiederholen wendet den
# zurückgenommenen Befehl erneut über den Regelkern an. Genau ein Befehl je Schritt (Vertical
# Slice §10); StartGame ist nicht rücknehmbar. Keine eigene Regel, kein Sonderzustand.

func can_undo() -> bool:
	return _commands.size() > 1


func can_redo() -> bool:
	return not _redo.is_empty()


func undo() -> bool:
	if not can_undo():
		return false
	var prefix: Array[Command] = _commands.slice(0, _commands.size() - 1)
	var replayed := RulesEngine.replay(prefix)
	if not replayed.ok:
		return false  # kann bei einer angenommenen Befehlsfolge nicht eintreten; dann nichts ändern
	_redo.append(_commands.back())
	_state = replayed.state
	_commands = prefix
	_events = replayed.events
	_rescan_five_dead()  # eine zurückgenommene Auslösung gilt als nicht gegeben
	view_changed.emit(view())
	state_replaced.emit()
	return true


func redo() -> bool:
	if _redo.is_empty():
		return false
	var command: Command = _redo.back()
	var result := RulesEngine.apply(_state, command)
	if not result.ok:
		_redo.clear()
		command_rejected.emit(result.error)
		return false
	_redo.pop_back()
	var before := _state
	_state = result.state
	_commands.append(command)
	_events.append_array(result.events)
	_observe_five_dead(before, _state, _commands.size() - 1)  # Wiederholen spielt nichts ab
	view_changed.emit(view())
	state_replaced.emit()
	return true


## Beschreibung des Befehls, den Rückgängig zurücknähme (nur für den Spielleiterbereich).
func undo_info() -> Dictionary:
	if not can_undo():
		return {}
	var prefix: Array[Command] = _commands.slice(0, _commands.size() - 1)
	return CockpitView.command_info(RulesEngine.replay(prefix).state, _commands.back())


## Beschreibung des Befehls, den Wiederholen erneut anwendete.
func redo_info() -> Dictionary:
	return CockpitView.command_info(_state, _redo.back()) if can_redo() else {}


## Ereignisse des letzten angenommenen Befehls (für die Anzeige „Was hat sich geändert“).
func last_command_events() -> Array:
	var out: Array = []
	var last := _commands.size() - 1
	for e: GameEvent in _events:
		if e.command_index == last:
			out.append(e.to_dict())
	return out


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
	return submit(_targets_command(targets))


## Prüft dieselbe Auswahl wie `answer_targets` beim Regelkern, ohne sie zu senden: Fehlergrund oder "".
func check_targets(targets: Array) -> StringName:
	return RulesEngine.check(_state, _targets_command(targets))


## Zufallsvorschlag für die offene Spielleiterwahl (RM-DR-015.2), gezogen aus einer Kopie des gespeicherten Generators:
## Personen-IDs, oder null ohne Zufallsknopf bzw. ohne zulässiges Ergebnis. Ändert nichts; gleicher Zustand, gleicher Vorschlag.
## Ein angekündigter Schritt, dessen Prompt die Karte schon zeigt, zählt mit (Vorschau über einen kopierten Beginn des Schritts).
func random_proposal() -> Variant:
	var st := _state
	if st.pending_prompt == null:
		var begun := RulesEngine.apply(_state, Command.begin_step(RulesEngine.next_step_id(_state)))
		if begun.ok:
			st = begun.state
	var r := InfoSteps.random_choice(st)
	return (r["targets"] as Array).duplicate() if not r.is_empty() else null


## Bestätigt den Zufallsvorschlag. Der Regelkern zieht erneut und nimmt nur genau dieses Ergebnis an.
func answer_random(targets: Array) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.answer_random(_prompt_id(), String(p.stage) if p != null else "", targets))


func _targets_command(targets: Array) -> Command:
	var p := _state.pending_prompt
	if p != null and p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), targets)
	return Command.answer_prompt(_prompt_id(), targets)


## Ja/Nein bzw. Bestätigen (ack = Ja) der aktuellen Stufe.
func answer_choice(choice: bool) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.answer_choice(_prompt_id(), String(p.stage) if p != null else "", choice))


func answer_option(index: int) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.create(Command.ANSWER_PROMPT, {"prompt_id": _prompt_id(), "stage": String(p.stage) if p != null else "", "option": index}))


## Würfeln für die offene Karteneingabe (Stufe „roll“): Der Kern wirft über den gespeicherten Generator und merkt sich das Ergebnis.
func answer_roll() -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.create(Command.ANSWER_PROMPT, {"prompt_id": _prompt_id(), "stage": String(p.stage) if p != null else "", "roll": true}))


## Totenreichkarte der aktuell gefragten Person: "play", "keep" oder "exchange".
func card_act(owner_id: int, action: String) -> CommandResult:
	return submit(Command.card_act(owner_id, action))


func card_close_window() -> CommandResult:
	return submit(Command.card_close_window())


## Meldet einen Verstoß gegen eine Tagesregel (Nebelhorn, Stummfilm) für `person_id`.
func card_table_action(effect_id: int, person_id: int) -> CommandResult:
	return submit(Command.card_table_action(effect_id, person_id))


func card_overview() -> Array:
	return CardView.overview(_state)


## Lebende Kartenschlucker mit Guthaben, gesammelten Stapeln und Schild (nur Spielleiter).
func card_swallowers() -> Array:
	return CardView.swallower(_state)


func answer_prediction(kind: String, number: int) -> CommandResult:
	var p := _state.pending_prompt
	return submit(Command.create(Command.ANSWER_PROMPT, {"prompt_id": _prompt_id(), "stage": String(p.stage) if p != null else "",
		"prediction": {"kind": kind, "number": number}}))


func override_shown_role(role_id: String, reason: String) -> CommandResult:
	return submit(Command.override_shown_role(_prompt_id(), role_id, reason))


func end_night() -> CommandResult:
	return submit(Command.end_night())


## Der erste offene private Hinweis wurde der betroffenen Person gezeigt (DI-04, DI-06, DI-07).
func ack_notice(notice_id: int) -> CommandResult:
	return submit(Command.ack_notice(notice_id))


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


## Rollenanzeige: neutrale Liste (ohne Rollen) und Karte einer Person (nur auf bewusste Aktion abrufen), siehe CockpitView.
func role_show_list() -> Dictionary:
	return CockpitView.role_show_list(_state) if _state.is_started() else {}


func role_show_card(person_id: int) -> Dictionary:
	return CockpitView.role_show_card(_state, person_id) if _state.is_started() else {}


## Die Person hat ihre Rolle gesehen und die Karte bewusst geschlossen (nicht: geöffnet oder abgebrochen).
func confirm_role_shown(person_id: int) -> CommandResult:
	return submit(Command.confirm_role_shown(person_id))


## Einfach korrigierbare Werte einer Person (Spielleitung, privat), siehe CockpitView.status_fields.
func status_fields(person_id: int) -> Array:
	return CockpitView.status_fields(_state, person_id)


## Stimmhinweise (Blutwolf, Korrupter Richter) nur für den privaten Bereich, siehe CockpitView.vote_hints.
func vote_hints() -> Array:
	return CockpitView.vote_hints(_state) if _state.is_started() else []


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
