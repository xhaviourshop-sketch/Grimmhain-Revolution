extends UiTestCase
## Gemeinsamer Treiber der Rollen-Bedientests (Paket 3). Er bedient das Cockpit ausschließlich wie eine Spielleitung:
## Sitzplätze über `SeatRing.token_for`, Buttons der Aktionskarte und den Dialog der Shell. Er sendet nie selbst einen
## Befehl an `GameSession`. Nur die Vorbereitung eines Szenarios (`start`) darf Kernbefehle nutzen (Start, Spielleiter-
## korrekturen `kill`); diese Grenze steht in jedem Test.
##
## Plan (Dictionary) für `run`: Schlüssel "<besitzer>/<stufe>" (einstufige Prompts: "<besitzer>/", Reaktionen:
## "reaction/<art>") mit Antwort:
##   Array[int]         Sitzplätze antippen; eine feste Anzahl gilt sofort, sonst „Weiter“; leeres Array = Verzicht-Button
##   true / false       Ja- bzw. Nein-Button
##   {"option": i}      Options-Button i
##   {"prediction": ["night"|"day", n]}  Vorhersage über Art-Buttons und Plus
##   "cancel"           Abbrechen mit Begründung im Dialog (nur Karteneingaben der Totenreichkarten)
## Loki: "loki/targets" mit den zwei Personen, "loki/mode" mit true (Liebende) oder false (Rivalen); die Art wird zuerst getippt.
## Karte zeigen: ein Tippen auf „Karte zeigen“ und das Schließen der gezeigten Karte erledigen die Auskunft (kein „Gezeigt“).
## "day<N>": {"nominate": [von, an], "execute": id, "cerberus": bool, "sage": n} für Tag N; sonst keine Hinrichtung.
## Ohne Plan: Verzicht, sonst die ersten zulässigen Personen bzw. Nein.

const UiGame := preload("res://tests/ui/ui_game.gd")

var shell: Control = null
var trace: Array[String] = []
var plan_loki_mode: bool = false  ## Art der Bindung für Loki (Plan "loki/mode"), gesetzt von `step`
var quiet_nights: bool = false  ## Vorbereitung für lange Szenarien: das bedeutungslose Rudelopfer wird am Morgen per Korrektur wiederbelebt
var _revived_day: int = -1
var _revived_ids: Array[int] = []
var plan_now: Dictionary = {}  ## Plan der laufenden Bedienhandlung (die Wölfe meiden Personen, die der Plan später braucht)


## Vorbereitung (Kernbefehle erlaubt): Start mit `roles` (Person i+1 hat roles[i], Sitzreihenfolge = IDs), Tote über
## Spielleiterkorrektur ohne Folgen, dann Cockpit öffnen.
func start(roles: Array, kills: Array = [], appearances: Dictionary = {}, seed_value: int = 7) -> bool:
	shell = await spawn_shell()
	if shell == null:
		return false
	# PE-07: Füllplätze („dorfbewohner“, „werwolf“ mehrfach) werden zu verschiedenen Füllern; weitere gleiche Rollen entstehen
	# nach dem Start durch Spielleiterkorrektur (Vorbereitung, wie das Töten unten).
	for c: Command in Fixtures.start_with_copies(Fixtures.legalize(roles), seed_value, appearances):
		var r := session().submit(c)
		if not r.ok:
			fail("Start abgelehnt: %s" % r.error)
			return false
	var r := CommandResult.new()
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


## Nächste Handlung wie die Karte sie zeigt: Ein Schritt, dessen Prompt die Karte schon als Vorschau zeigt (Ansage und Aktion auf einem
## Bildschirm, `BeginStep` geht erst mit der ersten Handlung), gilt hier als offener Prompt (`needs_begin`).
func next() -> Dictionary:
	var n: Dictionary = (session().cockpit_view() as Dictionary).get("next", {})
	if str(n.get("kind")) == "begin_step" and not (n.get("preview", {}) as Dictionary).is_empty():
		var shown: Dictionary = (n["preview"] as Dictionary).duplicate()
		shown["needs_begin"] = true
		shown["decoys"] = n.get("decoys", [])
		shown["index"] = n.get("index", 0)
		shown["total"] = n.get("total", 0)
		return shown
	return n


## Vorbereitung für Tests, die den offenen Prompt im Zustand brauchen: beginnt den angekündigten Schritt (Kernbefehl).
func begin_open_step() -> void:
	if str(raw_next().get("kind")) == "begin_step":
		assert_true(session().begin_next_step().ok, "Schritt begonnen")
		await frames(2)


## Unveränderte Sicht des Regelkerns (ein angekündigter Schritt bleibt `begin_step`).
func raw_next() -> Dictionary:
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
	await tool_button(root if root != null else screen(), node_name)  # Werkzeuge im Optionenmenü: erst die Lasche öffnen
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


## Szenariovorbereitung (Kernbefehl erlaubt, wie das Töten in `start`): Wer in der Nacht dem Rudel zum Opfer fiel, lebt am Tag wieder.
func _revive_night_victims() -> void:
	var day := int((session().cockpit_view() as Dictionary)["day_number"])
	if day == _revived_day:
		return
	_revived_day = day
	for e: Dictionary in events("SeatDied"):
		var data: Dictionary = e["data"]
		var id := int(data["target_id"])
		if str(data.get("cause")) == "NIGHT_KILL" and not _revived_ids.has(id) and not state().players[id].alive:
			_revived_ids.append(id)
			session().submit(CorrectionFixtures.gm("revive", {"target_id": id}, "Vorbereitung"))


## Eine Bedienhandlung für die aktuelle Karte. Liefert false, wenn kein Weg gefunden wurde.
func step(plan: Dictionary) -> bool:
	plan_now = plan
	if quiet_nights and str(next().get("kind")) == "day":
		_revive_night_victims()
	if live("ContinueDayButton") != null:
		return await tap_button("ContinueDayButton")
	var n := next()
	await _uncover()
	match str(n.get("kind")):
		"start_night":
			return await tap_button("StartNightButton")
		"begin_step":
			# Nur ein Schritt ohne Prompt-Vorschau (entfällt oder endet sofort): „Weiter“; nie ein Knopf zum Überspringen.
			assert_true(live("SkipStepButton") == null, "Schritt %s: kein Überspringen auf der Karte" % str(n.get("step_id")))
			return await tap_button("BeginStepButton")
		"prompt":
			plan_loki_mode = bool(plan.get("loki/mode", false))
			return await answer(plan.get(plan_key(n)))
		"notice":
			return await show_and_close("ShowNoticeButton")
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


## Zeigt die Karte über `button` und schließt sie wieder: Das Schließen erledigt die Auskunft bzw. bestätigt den Hinweis.
func show_and_close(button: String) -> bool:
	if not await tap_button(button):
		return false
	return await tap_button("CloseLayerButton", shell)


## Antwort auf den offenen Prompt (oder die Prompt-Vorschau `shown`) ausschließlich über die Karte.
func answer(action: Variant) -> bool:
	var n := next()
	# Invarianten jeder Karte: Abbrechen nur bei Karteneingaben, Verzicht genau bei zulässiger Anzahl 0, nie „Auswahl leeren“.
	assert_eq(live("CancelPromptButton") != null, bool(n.get("cancellable")) and str(n.get("owner")) == "card", "%s: Abbrechen nur bei Karteneingaben" % plan_key(n))
	assert_true(live("SkipStepButton") == null, "%s: kein Überspringen" % plan_key(n))
	if str(n.get("answer")) == "targets":
		assert_eq(live("DeclineButton") != null, (n.get("counts", []) as Array).has(0), "%s: Verzicht nur bei zulässiger Anzahl 0" % plan_key(n))
		assert_eq(live("ClearSelectionButton") != null, false, "%s: kein „Auswahl leeren“" % plan_key(n))
	if action is String and action == "cancel":
		return await tap_button("CancelPromptButton") and await confirm_dialog()
	match str(n.get("answer")):
		"targets":
			var picks: Array = []
			if action is Array:
				picks = action
			elif ["pack", "pack2"].has(str(n.get("owner"))):
				picks = [Fixtures.quiet_victim(state(), n["allowed_ids"], plan_now)]  # die Wölfe töten jede Nacht: ohne Plan trifft es eine wirkungslose Person
			elif live("DeclineButton") == null:
				picks = (n["allowed_ids"] as Array).slice(0, int(n["min"]))
			if picks.is_empty():
				return await tap_button("DeclineButton")
			if str(n.get("owner")) == "loki" and str(n.get("stage")) == "targets":
				await tap_button("YesButton" if bool(plan_loki_mode) else "NoButton")  # erst Liebende oder Rivalen
			for id: Variant in picks:
				await tap_seat(int(id))
			if CockpitText.auto_commit(n):
				return true  # eine feste Anzahl gilt sofort
			return await tap_button("ConfirmTargetsButton")
		"choice":
			return await tap_button("YesButton" if action is bool and action else "NoButton")
		"ack":
			if not (n.get("show", []) as Array).is_empty() and not ["die-gebundenen", "piper-all"].has(str(n.get("owner"))):
				return await show_and_close("ShowCardButton")
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
