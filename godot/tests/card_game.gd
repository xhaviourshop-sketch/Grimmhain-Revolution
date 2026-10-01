class_name CardGame
extends RefCounted
## Testhilfe für Totenreichkarten: eine laufende Partie über echte Befehle, mit Befehlsliste für Replay und Laden.
## Karten werden entweder über echte Tode gezogen oder mit `give` gezielt vergeben (nur für tote Personen, als gültiger
## Zustand, der über `GameState.from_dict` geprüft wird).

var t: TestCase
var state: GameState = GameState.new()
var commands: Array[Command] = []
var events: Array[GameEvent] = []


func _init(p_test: TestCase) -> void:
	t = p_test


## Startet eine Partie mit Totenreichkarten. `specials`: Person-ID-Text → Rolle; `wolf_ids` erhalten Wolfsfüller.
static func started(p_test: TestCase, count: int, wolf_ids: Array[int], seed_value: int = 1, specials: Dictionary = {}, options: Dictionary = {}) -> CardGame:
	var g := CardGame.new(p_test)
	var payload := {
		"round_id": "test-round", "seed": seed_value, "assignment": "manual", "players": Fixtures.players(count),
		"seat_order": Fixtures.identity_order(count), "roles": Fixtures.filled_roles(count, wolf_ids, specials), "death_cards": true,
	}
	payload.merge(options, true)
	g.do(Command.start_game(payload), "StartGame")
	return g


## Wendet einen Befehl an und erwartet Annahme.
func do(c: Command, label: String = "") -> CommandResult:
	var r := RulesEngine.apply(state, c)
	t.assert_true(r.ok, "%s: %s angenommen (Fehler: %s)" % [label, c.type, r.error])
	if r.ok:
		state = r.state
		commands.append(c)
		events.append_array(r.events)
	return r


## Wendet einen Befehl an, ohne Annahme zu verlangen (Ablehnung ändert nichts).
func attempt(c: Command) -> CommandResult:
	var r := RulesEngine.apply(state, c)
	if r.ok:
		state = r.state
		commands.append(c)
		events.append_array(r.events)
	return r


func reject(c: Command, error: String, label: String) -> void:
	t.apply_rejected(state, c, error, label)


func gm_kill(id: int, trigger: bool = true) -> void:
	do(Command.gm_correction({"kind": "kill", "target_id": id, "trigger_effects": trigger, "reason": "Test", "confirmed": true}), "kill %d" % id)


func gm_revive(id: int) -> void:
	do(Command.gm_correction({"kind": "revive", "target_id": id, "reason": "Test", "confirmed": true}), "revive %d" % id)


func gm_set_role(id: int, role: String) -> void:
	do(Command.gm_correction({"kind": "set_role", "target_id": id, "role_id": role, "reason": "Test", "confirmed": true}), "set_role %d" % id)


## Spielt eine Nacht bis zum Tag durch. `victim` ist das Rudelopfer (-1 = kein Opfer). Andere Prompts werden mit
## „nichts“ beantwortet (leere Auswahl, Nein).
func night(victim: Variant = -1, card_answers: Array = []) -> void:
	do(Command.start_night(), "StartNight")
	night_rest(victim, card_answers)


## Führt eine bereits begonnene Nacht zu Ende (wie `night`, ohne StartNight).
func night_rest(victim: Variant = -1, card_answers: Array = []) -> void:
	var guard := 0
	var next_answer := 0
	while state.phase == Phase.NIGHT and guard < 60:
		guard += 1
		if state.pending_prompt != null:
			var p := state.pending_prompt
			if p.owner == PendingPrompt.OWNER_PACK:
				var choice: Array = victim if victim is Array else ([victim] if int(victim) != -1 else [])
				if not choice.is_empty() and not choice.all(func(v: int) -> bool: return p.allowed_ids.has(v)):
					choice = [p.allowed_ids[0]]  # Karten können die Rudelwahl einschränken (Verrat)
				do(Command.answer_prompt(p.id, choice), "pack")
			elif p.owner == PendingPrompt.OWNER_CARD and next_answer < card_answers.size():
				answer_card(p, card_answers[next_answer])
				next_answer += 1
			else:
				answer_default(p)
		elif RulesEngine.next_step_id(state) != "":
			do(Command.begin_step(RulesEngine.next_step_id(state)), "begin")
		else:
			do(Command.end_night(), "EndNight")
			break
	# Reaktionen und offene Karteneingaben der Morgenauflösung werden nicht automatisch beantwortet.


func answer_default(p: PendingPrompt) -> void:
	if p.stage == &"":
		var picks: Array = []
		for i: int in maxi(p.min_count, 0):
			picks.append(p.allowed_ids[i])
		do(Command.answer_prompt(p.id, picks), "default")
	elif p.stage == &"shown" or p.stage == &"ack" or p.stage == &"confirm":
		var r := attempt(Command.answer_choice(p.id, String(p.stage), true))
		if not r.ok and r.error == "false_info_required":
			# Falsche Fährte: die Spielleitung legt die falsche Auskunft fest, dann wird bestätigt.
			do(Command.override_shown_role(p.id, "dorfbewohner", "Test"), "override")
			do(Command.answer_choice(p.id, String(p.stage), true), "default ack")
	elif p.stage == &"act":
		do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "act", "option": 0}), "act")
	elif p.stage == &"pick" or p.stage == &"target" or p.stage == &"targets" or p.stage == &"ally":
		var stage_picks: Array = []
		for i: int in maxi(p.min_count, 0):
			stage_picks.append(p.allowed_ids[i])
		do(Command.answer_stage_targets(p.id, String(p.stage), stage_picks), "default stage")
	else:
		do(Command.answer_choice(p.id, String(p.stage), false), "default choice %s/%s" % [p.owner, p.stage])


## Beantwortet alle offenen Aufgaben und Reaktionen mit der kleinsten gültigen Wahl (für Abläufe, die nicht Gegenstand sind).
func settle() -> void:
	var guard := 0
	while guard < 40:
		guard += 1
		if state.pending_prompt != null:
			var p := state.pending_prompt
			if p.owner == PendingPrompt.OWNER_CARD:
				answer_card_min(p)
			else:
				answer_default(p)
		elif StepQueue.reactions_due(state):
			do(Command.begin_step(RulesEngine.next_step_id(state)), "reaction begin")
		else:
			return


## Kleinste gültige Antwort auf eine Kartenstufe.
func answer_card_min(p: PendingPrompt) -> void:
	match p.stage:
		&"pick":
			var n := maxi(p.min_count, 0)
			var picks: Array = []
			for i: int in n:
				picks.append(p.allowed_ids[i])
			do(Command.answer_stage_targets(p.id, "pick", picks), "pick")
		&"option":
			do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "option", "option": 0}), "option")
		&"ask":
			do(Command.answer_choice(p.id, "ask", true), "ask")
		&"roll":
			do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "roll", "roll": true}), "roll")
		&"confirm":
			do(Command.answer_choice(p.id, "confirm", true), "confirm")


## Vergibt `card_id` als Originalkarte an die tote Person `owner_id` (Spielleiterkorrektur `set_card`, Variante nach ihrer Fraktion).
func give(owner_id: int, card_id: StringName) -> Dictionary:
	t.assert_false(state.players[owner_id].alive, "give: %d ist tot" % owner_id)
	do(Command.gm_correction({"kind": "set_card", "target_id": owner_id, "card_id": String(card_id), "reason": "Test", "confirmed": true}), "give %s" % card_id)
	return CardRules.held_of(state, owner_id)


## Das Kartenfenster ist offen und die gefragte Person ist `owner_id`.
func window_for(owner_id: int) -> bool:
	return CardRules.window_open(state) and CardRules.current_owner(state) == owner_id


## Spielt die Karte der aktuell gefragten Person und beantwortet alle Eingaben mit der kleinsten gültigen Wahl.
func play_min() -> void:
	var owner_id := CardRules.current_owner(state)
	do(Command.card_act(owner_id, "play"), "play")
	var guard := 0
	while state.pending_prompt != null and guard < 20:
		guard += 1
		answer_card_min(state.pending_prompt)


func close_window() -> void:
	do(Command.card_close_window(), "close window")


## Tag bis zum Hinrichtungsentscheid ohne Hinrichtung und mit EndDay (zweites Fenster öffnet sich, wenn jemand etwas tun kann).
func end_day() -> void:
	if state.day_step != Phase.DAY_EXECUTION_DECIDED:
		do(Command.decide_execution(GameState.NO_TARGET), "no execution")
	do(Command.end_day(), "EndDay")


func replay_equals() -> bool:
	var r := RulesEngine.replay(commands)
	return r.ok and CanonicalJson.stringify(r.state.to_dict()) == CanonicalJson.stringify(state.to_dict())


func reload_equals() -> bool:
	var loaded := StateCodec.decode(StateCodec.encode(state, commands))
	return loaded.ok and CanonicalJson.stringify(loaded.state.to_dict()) == CanonicalJson.stringify(state.to_dict())


# --- Szenario-Bausteine für die Kartentests --------------------------------------------------------------------

## Setzt die Karte `card_id` bei der toten Person `owner_id` (Person wird bei Bedarf ohne Folgen getötet), führt eine Nacht mit
## Opfer `victim` (oder ohne) und hält im ersten Kartenfenster, in dem `owner_id` gefragt wird (andere behalten ihre Karte).
func arm(owner_id: int, card_id: StringName, victim: int = -1, reach_window: bool = true) -> void:
	if state.players[owner_id].alive:
		gm_kill(owner_id, false)
	give(owner_id, card_id)
	if state.phase == Phase.SETUP or state.day_step == Phase.DAY_ENDED:
		night(victim)
	if reach_window:
		reach(owner_id)


## Hält im Fenster der Person `owner_id`: schließt dazu zuerst andere Fragen mit „Aufbewahren“.
func reach(owner_id: int) -> void:
	var guard := 0
	while CardRules.window_open(state) and CardRules.current_owner(state) != owner_id and guard < 20:
		guard += 1
		do(Command.card_act(CardRules.current_owner(state), "keep"), "keep %d" % CardRules.current_owner(state))
	if state.day_step == Phase.DAY_DISCUSSION and not CardRules.window_open(state):
		return


## Spielt die Karte der aktuell gefragten Person; `answers` beantwortet die Eingaben der Reihe nach: Array = Personen, int = Option,
## bool = Ja/Nein, String "roll" = Würfeln; fehlende Antworten nehmen die kleinste gültige Wahl.
func play_with(answers: Array = []) -> void:
	var owner_id := CardRules.current_owner(state)
	do(Command.card_act(owner_id, "play"), "play")
	var i := 0
	var guard := 0
	while state.pending_prompt != null and state.pending_prompt.owner == PendingPrompt.OWNER_CARD and guard < 30:
		guard += 1
		answer_card(state.pending_prompt, answers[i] if i < answers.size() else null)
		i += 1


## Beantwortet eine Karteneingabe: Array = Personen, int = Option, bool = Ja/Nein, null = kleinste gültige Wahl.
func answer_card(p: PendingPrompt, a: Variant) -> void:
	match p.stage:
		&"pick":
			var picks: Array = a if a is Array else ([a] if a != null else [])
			if a == null:
				for k: int in maxi(p.min_count, 0):
					picks.append(p.allowed_ids[k])
			do(Command.answer_stage_targets(p.id, "pick", picks), "pick")
		&"option":
			do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "option", "option": int(a) if a != null else 0}), "option")
		&"ask":
			do(Command.answer_choice(p.id, "ask", bool(a) if a != null else true), "ask")
		&"roll":
			do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "roll", "roll": true}), "roll")
		&"confirm":
			do(Command.answer_choice(p.id, "confirm", true), "confirm")


## Nominiert (Standard: nächste lebende Person als Nominierende) und führt die Hinrichtung der Person `target` aus.
func lynch(target: int, nominator: int = -1, extra: Dictionary = {}) -> CommandResult:
	if nominator == -1:
		for id: int in state.alive_ids():
			if id != target:
				nominator = id
				break
	do(Command.nominate(nominator, target), "nominate")
	var payload := {"target_id": target}
	payload.merge(extra)
	return attempt(Command.create(Command.DECIDE_EXECUTION, payload))


## Schließt das offene Fenster (alle behalten ihre Karten) und beginnt den Tag ohne weitere Karten.
func skip_cards() -> void:
	while CardRules.window_open(state):
		close_window()


## Kartenwirkung gespeichert (Effekt der Art `kind` vorhanden)?
func has_effect(kind: String) -> bool:
	return not CardEffects.effects(state, kind).is_empty()


## Nächste Nacht: schließt offene Fenster, beendet den Tag (ohne Hinrichtung, falls noch keine fiel) und führt die Nacht durch.
func next_night(victim: Variant = -1, card_answers: Array = [], settle_tasks: bool = true) -> void:
	skip_cards()
	if state.phase == Phase.DAY and state.day_step != Phase.DAY_ENDED:
		end_day()
		skip_cards()
	night(victim, card_answers)
	# Nachts ausgelöste Aufgaben der Morgenauflösung mit der kleinsten gültigen Wahl beantworten.
	if settle_tasks and state.pending_prompt != null and state.pending_prompt.owner == PendingPrompt.OWNER_CARD:
		settle()


## Anzahl Toter, die vor Beginn des Szenarios nicht tot waren (Vergleich mit einer Merkliste).
func dead_ids() -> Array[int]:
	var out: Array[int] = []
	for id: int in state.players:
		if not state.players[id].alive:
			out.append(id)
	out.sort()
	return out


## Ereignisse der Art `type` aller bisher angewandten Befehle.
func events_of(type: StringName) -> Array[GameEvent]:
	var out: Array[GameEvent] = []
	for e: GameEvent in events:
		if e.type == type:
			out.append(e)
	return out
