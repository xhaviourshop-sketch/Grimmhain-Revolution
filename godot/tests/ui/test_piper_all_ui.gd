extends "res://tests/ui/role_ui_case.gd"
## PE-06 über den Bedienweg: Die Spielleitung führt Rattenfänger → Hinweis an die neu Verzauberten → „Alle Verzauberten“
## → nächster Schritt allein über Karten, Buttons und Sitzplätze. Bei einem Tarnaufruf steht der Rattenfänger als Ansage
## vor „Alle Verzauberten“ auf derselben Karte. Die Liste der Verzauberten steht nur auf der Karte der Spielleitung; es
## gibt keine zeigbare Karte, keinen zweiten Hinweis und keinen öffentlichen Grund für einen Tarnaufruf.
## Vorbereitung ohne Karten: nur der Start (role_ui_case.gd).

const W := "werwolf"
const D := "dorfbewohner"


func _card_text() -> String:
	var out: Array[String] = []
	for c: Control in text_controls(find_node(screen(), "ActionCard")):
		out.append(text_of(c))
	return "\n".join(out)


func _answers() -> int:
	return session().commands().filter(func(c: Command) -> bool: return c.type == Command.ANSWER_PROMPT).size()


func _until_step(role: String) -> Callable:
	return func(n: Dictionary) -> bool: return str(n.get("kind")) == "begin_step" and str(n.get("role_id")) == role


func test_new_charm_through_the_cockpit() -> void:
	if not await start([W, "rattenfaenger", D, D, D, D, D]):
		return
	assert_true(await run({}, _until_step("rattenfaenger")), "bis zum Rattenfänger")
	assert_true(find_node(screen(), "DecoyCall_rattenfaenger") == null, "echter Aufruf, kein Tarnaufruf")
	await tap_button("BeginStepButton")
	await tap_seat(4)
	await tap_seat(5)
	await tap_button("ConfirmTargetsButton")
	assert_eq(str(next().get("notice_kind")), "piper_new", "zuerst der Hinweis an die neu Verzauberten")
	await tap_button("AckNoticeButton")
	var n := next()
	assert_eq(str(n.get("kind")), "begin_step", "danach der Schritt, kein zweiter Hinweis")
	assert_eq(str(n.get("role_id")), "piper-all", "„Alle Verzauberten“")
	assert_true(bool(n.get("secret")), "Karte der Spielleitung")
	assert_eq(n.get("decoys"), [], "kein Tarnaufruf")
	await frames(2)
	var text := _card_text()
	assert_true(text.contains("Alle Verzauberten, öffnet die Augen"), "Ansage zum Vorlesen: %s" % text)
	assert_true(text.contains("4 · D") and text.contains("5 · E"), "berechtigte Personen auf der Karte: %s" % text)
	assert_true(live("SkipStepButton") == null, "Pflichtschritt, nicht überspringbar")
	await tap_button("BeginStepButton")
	n = next()
	assert_true(str(n.get("kind")) == "prompt" and str(n.get("owner")) == "piper-all" and str(n.get("answer")) == "ack", "Bestätigungskarte")
	await frames(2)
	text = _card_text()
	assert_true(text.contains("Lebende Verzauberte") and text.contains("4 · D") and text.contains("5 · E"), "Liste auf der Karte: %s" % text)
	assert_true(text.contains("Danach „Gezeigt“"), "eindeutige Anweisung: %s" % text)
	assert_true(find_node(screen(), "ShowCardButton") == null, "keine Karte zum Zeigen: Liste wird niemandem eingeblendet")
	# Doppeltippen im selben Frame (wie test_cockpit_screen): genau eine Bestätigung, kein zweiter Befehl an den Regelkern.
	var before := _answers()
	var rejected: Array = []
	session().command_rejected.connect(func(e: StringName) -> void: rejected.append(e))
	var ack := live("AckButton")
	ack.pressed.emit()
	ack.pressed.emit()
	await frames(3)
	assert_eq(_answers(), before + 1, "genau eine Bestätigung")
	assert_eq(rejected.size(), 0, "kein zweiter Befehl")
	assert_eq(str(next().get("kind")), "end_night", "danach weiter mit dem nächsten Schritt (Nachtende)")
	assert_false((next().get("decoys", []) as Array).has("rattenfaenger"), "Rattenfänger nicht erneut angesagt")
	await tap_button("EndNightButton")
	var public := JSON.stringify((session().morning_report() as Dictionary).get("public", {}))
	assert_false(public.contains("piper") or public.contains("charm"), "Morgenbericht ohne Verzauberte: %s" % public)


func test_decoy_call_comes_first_and_gives_no_reason() -> void:
	if not await start([W, "rattenfaenger", "waldhexe", D, D, D, D]):
		return
	assert_true(await run({"rattenfaenger/": [4, 5]}, until_day(1)), "Nacht 1 mit Verzauberung")
	assert_true(await run({}, until_kind("start_night")), "Tag ohne Hinrichtung")
	var plan := {"waldhexe/poison": true, "waldhexe/poison_target": [2]}
	assert_true(await run(plan, _until_step("piper-all")), "Nacht 2 bis „Alle Verzauberten“")
	var n := next()
	assert_eq(n.get("decoys"), ["rattenfaenger"], "Rattenfänger als Tarnaufruf auf derselben Karte")
	await frames(2)
	assert_true(find_node(screen(), "DecoyCall_rattenfaenger") != null, "Ansage des Rattenfängers sichtbar")
	var text := _card_text()
	var piper_at := text.find("Rattenfänger, erwache")
	var all_at := text.find("Alle Verzauberten, öffnet die Augen")
	assert_true(piper_at >= 0 and all_at > piper_at, "zuerst Rattenfänger, dann alle Verzauberten: %s" % text)
	for word: String in ["Gift", "vergiftet", "blockiert", "gestorben", "entfällt", "entfallen"]:
		assert_false(text.contains(word), "kein Grund für den Tarnaufruf („%s“)" % word)
	assert_true(events("NoticeQueued").filter(func(e: Dictionary) -> bool: return int((e["data"] as Dictionary)["notice_id"]) > 1).is_empty(),
		"keine neu Verzauberten in Nacht 2")
	await tap_button("BeginStepButton")
	assert_eq(next().get("actor_ids"), [4, 5], "alle Verzauberten")
	await tap_button("AckButton")
	assert_false((next().get("decoys", []) as Array).has("rattenfaenger"), "Rattenfänger nicht zweimal angesagt")
	assert_eq(state().charms.size(), 2, "keine Verzauberung durch den Folgeschritt")


func test_help_on_the_all_step_opens_the_piper_entry() -> void:
	if not await start([W, "rattenfaenger", D, D, D, D, D]):
		return
	assert_true(await run({"rattenfaenger/": [4, 5]}, _until_step("piper-all")), "bis „Alle Verzauberten“")
	assert_eq(CockpitText.help_role(next()), "rattenfaenger", "Regel nachlesen führt zum Rattenfänger")
