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


## Stoppt an der Karte des Schritts `role` (ein noch nicht begonnener Schritt zeigt seinen Prompt schon als Vorschau).
func _until_step(role: String) -> Callable:
	return func(n: Dictionary) -> bool: return ["begin_step", "prompt"].has(str(n.get("kind"))) and str(n.get("role_id")) == role


func test_new_charm_through_the_cockpit() -> void:
	if not await start([W, "rattenfaenger", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	assert_true(await run({}, _until_step("rattenfaenger")), "bis zum Rattenfänger")
	assert_true(find_node(screen(), "DecoyLine") == null, "echter Aufruf, kein Tarnaufruf")
	await tap_seat(4)
	await tap_seat(5)
	await tap_button("ConfirmTargetsButton")  # 1 bis 2 Personen: erst „Weiter“
	assert_eq(str(next().get("notice_kind")), "piper_new", "zuerst der Hinweis an die neu Verzauberten")
	await show_and_close("ShowNoticeButton")  # Karte zeigen, Schließen bestätigt den Hinweis
	var n := next()
	assert_eq(str(n.get("kind")), "prompt", "danach der Schritt mit seiner Aktion, kein zweiter Hinweis")
	assert_eq(str(n.get("role_id")), "piper-all", "„Alle Verzauberten“")
	assert_true(bool(n.get("secret")), "Karte der Spielleitung")
	assert_eq(n.get("decoys"), [], "kein Tarnaufruf")
	await frames(2)
	var text := _card_text()
	assert_true(text.contains("Alle Verzauberten, öffnet die Augen"), "Ansage zum Vorlesen: %s" % text)
	assert_true(text.contains("4 · D") and text.contains("5 · E"), "berechtigte Personen auf der Karte: %s" % text)
	assert_true(live("SkipStepButton") == null, "Pflichtschritt, nicht überspringbar")
	assert_true(str(n.get("owner")) == "piper-all" and str(n.get("answer")) == "ack", "Bestätigungskarte")
	assert_true(text.contains("Alle erkennen einander"), "eine Hilfezeile: %s" % text)
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
	assert_true(str(state().phase) != "NIGHT", "letzter Schritt: die Nacht endet ohne Fenster")
	var decoy := find_node(screen(), "DecoyLine") as Label
	assert_true(decoy == null or not decoy.text.contains(tr(CockpitText.role_name("rattenfaenger"))), "Rattenfänger nicht erneut angesagt")
	var public := JSON.stringify((session().morning_report() as Dictionary).get("public", {}))
	assert_false(public.contains("piper") or public.contains("charm"), "Morgenbericht ohne Verzauberte: %s" % public)


func test_decoy_call_comes_first_and_gives_no_reason() -> void:
	if not await start([W, "rattenfaenger", "waldhexe", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({"rattenfaenger/": [4, 5]}, until_day(1)), "Nacht 1 mit Verzauberung")
	assert_true(await run({}, until_kind("start_night")), "Tag ohne Hinrichtung")
	var plan := {"waldhexe/poison": true, "waldhexe/poison_target": [2]}
	assert_true(await run(plan, _until_step("piper-all")), "Nacht 2 bis „Alle Verzauberten“")
	var n := next()
	assert_eq(n.get("decoys"), ["rattenfaenger"], "Rattenfänger als Tarnaufruf auf derselben Karte")
	await frames(2)
	assert_true(find_node(screen(), "DecoyLine") != null, "Ansage des Rattenfängers sichtbar")
	var text := _card_text()
	var piper_at := text.find("Rattenfänger")
	var all_at := text.find("Alle Verzauberten, öffnet die Augen")
	assert_true(piper_at >= 0 and all_at > piper_at, "zuerst Rattenfänger, dann alle Verzauberten: %s" % text)
	for word: String in ["Gift", "vergiftet", "blockiert", "gestorben", "entfällt", "entfallen"]:
		assert_false(text.contains(word), "kein Grund für den Tarnaufruf („%s“)" % word)
	assert_true(events("NoticeQueued").filter(func(e: Dictionary) -> bool: return int((e["data"] as Dictionary)["notice_id"]) > 1).is_empty(),
		"keine neu Verzauberten in Nacht 2")
	assert_eq(next().get("actor_ids"), [4, 5], "alle Verzauberten")
	await tap_button("AckButton")
	assert_false((next().get("decoys", []) as Array).has("rattenfaenger"), "Rattenfänger nicht zweimal angesagt")
	assert_eq(state().charms.size(), 2, "keine Verzauberung durch den Folgeschritt")


func test_help_on_the_all_step_opens_the_piper_entry() -> void:
	if not await start([W, "rattenfaenger", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	assert_true(await run({"rattenfaenger/": [4, 5]}, _until_step("piper-all")), "bis „Alle Verzauberten“")
	assert_eq(CockpitText.help_role(next()), "rattenfaenger", "Regel nachlesen führt zum Rattenfänger")
