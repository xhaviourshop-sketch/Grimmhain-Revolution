extends UiTestCase
## Gemeinsamer Treiber der Rollen-Bedientests (Paket 3). Er bedient das Cockpit ausschließlich wie eine Spielleitung:
## Sitzplätze über `SeatRing.token_for`, Buttons der Aktionskarte und den Dialog der Shell. Er sendet nie selbst einen
## Befehl an `GameSession`. Nur die Vorbereitung eines Szenarios (`start`) darf Kernbefehle nutzen (Start, Spielleiter-
## korrekturen `kill`); diese Grenze steht in jedem Test.
##
## Plan (Dictionary) für `run`: Schlüssel "<besitzer>/<stufe>" (einstufige Prompts: "<besitzer>/", Reaktionen:
## "reaction/<art>") mit Antwort:
##   Array[int]         Sitzplätze antippen und „Bestätigen“; leeres Array = Verzicht-Button
##   true / false       Ja- bzw. Nein-Button
##   {"option": i}      Options-Button i
##   {"prediction": ["night"|"day", n]}  Vorhersage über Art-Buttons und Plus
##   "cancel"           Abbrechen mit Begründung im Dialog
## "step/<rolle>": "skip" überspringt den Schritt mit Begründung. "day<N>": {"nominate": [von, an], "execute": id,
## "cerberus": bool, "sage": n} für Tag N; sonst keine Hinrichtung. Ohne Plan: Verzicht, sonst Bestätigen/Nein,
## sonst die ersten zulässigen Personen.

const UiGame := preload("res://tests/ui/ui_game.gd")

var shell: Control = null
var trace: Array[String] = []


## Vorbereitung (Kernbefehle erlaubt): Start mit `roles` (Person i+1 hat roles[i], Sitzreihenfolge = IDs), Tote über
## Spielleiterkorrektur ohne Folgen, dann Cockpit öffnen.
func start(roles: Array, kills: Array = [], appearances: Dictionary = {}, seed_value: int = 7) -> bool:
	shell = await spawn_shell()
	if shell == null:
		return false
	var r := session().submit(UiGame.start(roles, seed_value, appearances))
	if not r.ok:
		fail("Start abgelehnt: %s" % r.error)
		return false
	for id: Variant in kills:
		r = session().submit(CorrectionFixtures.gm("kill", {"target_id": int(id), "trigger_effects": false}, "Vorbereitung"))
		if not r.ok:
			fail("Vorbereitung kill %s abgelehnt: %s" % [id, r.error])
			return false
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return true


func session() -> GameSession:
	return session_of(shell) as GameSession


func screen() -> Control:
	return current_screen(shell)


func next() -> Dictionary:
	return (session().cockpit_view() as Dictionary).get("next", {})


func state() -> GameState:
	return RulesEngine.replay(session().commands()).state


func events(type: String) -> Array:
	return session().event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == type)


func has_event(type: String) -> bool:
	return not events(type).is_empty()


## Button der aktuellen Ansicht, nur wenn sichtbar und freigegeben (sonst null, ohne Fehler).
func live(node_name: String, root: Node = null) -> BaseButton:
	var b := (root if root != null else screen()).find_child(node_name, true, false) as BaseButton
	return b if b != null and b.is_visible_in_tree() and not b.disabled else null


## Drückt einen sichtbaren, freigegebenen Button; fehlt er, schlägt der Test fehl.
func tap_button(node_name: String, root: Node = null) -> bool:
	var b := live(node_name, root)
	if b == null:
		fail("Button %s nicht bedienbar (%s)" % [node_name, str(next().get("kind"))])
		return false
	trace.append(node_name)
	await press(b)
	return true


func tap_seat(id: int) -> void:
	trace.append("seat %d" % id)
	await press(find_node(screen(), "SeatRing").call("token_for", id) as BaseButton)


func dialog() -> Control:
	return shell.call("get_dialog") as Control


## Bestätigt den offenen Dialog; mit Pflichtfeld wird eine Begründung eingetippt.
func confirm_dialog(reason: String = "Testlauf") -> bool:
	if not dialog().call("is_open"):
		fail("kein Dialog offen")
		return false
	var field := find_node(dialog(), "InputField") as LineEdit
	if field != null and field.is_visible_in_tree():
		await type_text(field, reason)
	return await tap_button("ConfirmButton", dialog())


## Verdeckte Karte (außerhalb der Nacht) zuerst aufdecken.
func _uncover() -> void:
	if live("RevealButton") != null and next().get("kind") != "day":
		await tap_button("RevealButton")


## Eine Bedienhandlung für die aktuelle Karte. Liefert false, wenn kein Weg gefunden wurde.
func step(plan: Dictionary) -> bool:
	if live("ContinueDayButton") != null:
		return await tap_button("ContinueDayButton")
	var n := next()
	await _uncover()
	match str(n.get("kind")):
		"start_night":
			return await tap_button("StartNightButton")
		"begin_step":
			# Invariante: Überspringen nur bei überspringbaren Schritten (Regelkern), nie bei Pflichtschritten.
			assert_eq(live("SkipStepButton") != null, bool(n.get("skippable")), "Schritt %s: Überspringen nur wenn erlaubt" % str(n.get("step_id")))
			if str(plan.get("step/%s" % str(n.get("role_id")), "")) == "skip":
				return await tap_button("SkipStepButton") and await confirm_dialog()
			return await tap_button("BeginStepButton")
		"prompt":
			return await answer(plan.get(plan_key(n)))
		"notice":
			return await tap_button("AckNoticeButton")
		"end_night":
			return await tap_button("EndNightButton")
		"day":
			return await day(plan.get("day%d" % int((session().cockpit_view() as Dictionary)["day_number"]), {}))
		"end_day":
			return await tap_button("EndDayButton")
	fail("keine Bedienung für %s" % str(n.get("kind")))
	return false


func plan_key(n: Dictionary) -> String:
	if str(n.get("owner")) == "reaction":
		return "reaction/%s" % str(n.get("reaction_kind"))
	return "%s/%s" % [str(n.get("owner")), str(n.get("stage"))]


## Antwort auf den offenen Prompt ausschließlich über die Karte.
func answer(action: Variant) -> bool:
	var n := next()
	# Invarianten jeder Karte: Abbrechen genau bei abbrechbaren Prompts, Verzicht genau bei zulässiger Anzahl 0.
	assert_eq(live("CancelPromptButton") != null, bool(n.get("cancellable")), "%s: Abbrechen nur wenn erlaubt" % plan_key(n))
	if str(n.get("answer")) == "targets":
		assert_eq(live("DeclineButton") != null, (n.get("counts", []) as Array).has(0), "%s: Verzicht nur bei zulässiger Anzahl 0" % plan_key(n))
	if action is String and action == "cancel":
		return await tap_button("CancelPromptButton") and await confirm_dialog()
	match str(n.get("answer")):
		"targets":
			var picks: Array = []
			if action is Array:
				picks = action
			elif live("DeclineButton") == null:
				picks = (n["allowed_ids"] as Array).slice(0, int(n["min"]))
			if picks.is_empty():
				return await tap_button("DeclineButton")
			for id: Variant in picks:
				await tap_seat(int(id))
			return await tap_button("ConfirmTargetsButton")
		"choice":
			return await tap_button("YesButton" if action is bool and action else "NoButton")
		"ack":
			return await tap_button("AckButton")
		"option":
			return await tap_button("OptionButton_%d" % (int((action as Dictionary)["option"]) if action is Dictionary else 0))
		"prediction":
			var wanted: Array = (action as Dictionary)["prediction"] if action is Dictionary else ["night", 0]
			if str(wanted[0]) == "day":
				await tap_button("PredictionDayButton")
			var minimum := int((n["prediction_min"] as Dictionary)[str(wanted[0])])
			for i: int in maxi(0, int(wanted[1]) - minimum):
				await tap_button("PredictionPlusButton")
			return await tap_button("ConfirmPredictionButton")
	fail("unbekannte Antwortart %s" % str(n.get("answer")))
	return false


## Tag: Nominierung und Hinrichtung über Karte und Sitzplätze, sonst „Keine Hinrichtung“ mit Rückfrage.
func day(plan: Dictionary) -> bool:
	var n := next()
	var target := int(plan.get("execute", -1))
	if target != -1 and (n.get("execution_candidates", []) as Array).has(target):
		await tap_button("ExecuteButton")
		await tap_seat(target)
		await tap_button("ConfirmExecutionTargetButton")
		await tap_button("RevealButton")
		if plan.has("cerberus"):
			await tap_button("CerberusDefend%s" % ("Yes" if bool(plan["cerberus"]) else "No"))
		if plan.has("sage"):
			await tap_button("SageCurse%d" % int(plan["sage"]))
		return await tap_button("ConfirmExecutionButton") and await confirm_dialog()
	var pair: Array = plan.get("nominate", [])
	if not pair.is_empty() and not (n.get("nominations", []) as Array).any(func(x: Dictionary) -> bool: return int(x["nominee_id"]) == int(pair[1])):
		await tap_button("NominateButton")
		await tap_seat(int(pair[0]))
		await tap_seat(int(pair[1]))
		return await tap_button("ConfirmNominationButton")
	return await tap_button("NoExecutionButton") and await confirm_dialog()


## Bedient Karten, bis `stop` (erhält die nächste Handlung) wahr ist. Bricht bei Spielende, Siegentscheidung oder
## fehlender Bedienung ab (false).
func run(plan: Dictionary, stop: Callable, max_steps: int = 120) -> bool:
	for i: int in max_steps:
		var n := next()
		if stop.call(n):
			return true
		if str(n.get("kind")) in ["game_over", "win_decision"]:
			fail("Partie endete vor dem Ziel (%s); Spur: %s" % [n.get("kind"), ", ".join(trace.slice(-12))])
			return false
		var count := session().commands().size()
		if not await step(plan):
			fail("Spur: %s" % ", ".join(trace.slice(-12)))
			return false
		if session().commands().size() == count and live("ContinueDayButton") == null and not str(n.get("kind")) in ["day"]:
			# Aufdecken oder Weiterschalten ohne Befehl ist erlaubt; ein ausbleibender Befehl bei derselben Karte nicht.
			if JSON.stringify(next()) == JSON.stringify(n) and live("RevealButton") == null:
				fail("Bedienung ohne Wirkung bei %s; Spur: %s" % [str(n.get("kind")), ", ".join(trace.slice(-12))])
				return false
	fail("Ziel nicht erreicht; Spur: %s" % ", ".join(trace.slice(-12)))
	return false


## Stoppt, sobald ein Ereignis `type` im Protokoll steht.
func until_event(type: String) -> Callable:
	return func(_n: Dictionary) -> bool: return has_event(type)


## Stoppt, sobald der Prompt `owner` (optional mit Stufe) offen ist.
func until_prompt(owner: String, stage: String = "*") -> Callable:
	return func(n: Dictionary) -> bool: return str(n.get("kind")) == "prompt" and str(n.get("owner")) == owner and (stage == "*" or str(n.get("stage")) == stage)


## Stoppt an der Tageskarte (bzw. am Tagesende) des Tages `n`.
func until_day(n: int, kind: String = "day") -> Callable:
	return func(x: Dictionary) -> bool: return str(x.get("kind")) == kind and int(session().cockpit_view()["day_number"]) == n


func until_kind(kind: String) -> Callable:
	return func(n: Dictionary) -> bool: return str(n.get("kind")) == kind


## Letzter angenommener Befehl (zur Kontrolle, dass die Bedienung genau diesen Befehl erzeugt hat).
func last_command() -> Command:
	return session().commands().back()


func alive(id: int) -> bool:
	return state().players[id].alive
