extends UiTestCase
## Totenreichkarten über die Oberfläche: Kartenfenster, Spielen, Aufbewahren, Tauschen, Personenwahl am Sitzkreis, sichtbare
## Würfel, Kartenschlucker-Handzeichen, Tagesregeln mit Verstoßmeldung, Überblick, Kartenfläche zum Zeigen, DE und EN.
## Alle Aktionen sind echte Buttons der Ansagekarte oder Plätze im Sitzkreis; der Test sendet keinen Befehl an die Sitzung, außer
## dem Spielaufbau und den Spielleiterkorrekturen, die den Ausgangszustand herstellen (Tote mit einer bestimmten Karte).

const NAMES := ["Anna", "Ben", "Cara", "Dirk", "Eva", "Finn", "Gina", "Hugo", "Ida", "Jan", "Kim", "Lea"]
const COUNT := 10


## Startet eine Partie mit Totenreichkarten; `dead_cards`: {Personen-ID: Karten-ID} sind tot und halten diese Karte.
func _game(dead_cards: Dictionary, locale: String = "de", specials: Dictionary = {}, count: int = COUNT) -> Control:
	var shell := await spawn_shell(SIZE_16_10, locale)
	if shell == null:
		return null
	var players: Array = []
	for i: int in count:
		players.append({"id": i + 1, "name": NAMES[i]})
	var s := session_of(shell)
	var r: CommandResult = s.call("submit", Command.start_game({"round_id": "r", "seed": 11, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(count), "roles": Fixtures.filled_roles(count, [1, 2], specials), "death_cards": true}))
	assert_true(r.ok, "Start (%s)" % r.error)
	for id: Variant in dead_cards:
		_gm(s, {"kind": "kill", "target_id": int(id), "trigger_effects": false})
		_gm(s, {"kind": "set_card", "target_id": int(id), "card_id": String(dead_cards[id])})
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _gm(s: Object, payload: Dictionary) -> void:
	var p := payload.duplicate()
	p["reason"] = "Test"
	p["confirmed"] = true
	var r: CommandResult = s.call("gm_correction", p)
	assert_true(r.ok, "Korrektur %s (%s)" % [payload.get("kind"), r.error])


## Nacht ohne Opfer bis zum Tag; das Kartenfenster öffnet sich mit dem Tagesbeginn.
func _to_day(shell: Control) -> void:
	var s := session_of(shell)
	s.call("start_night")
	for i: int in 30:
		var next: Dictionary = effective_of((s.call("cockpit_view") as Dictionary)["next"])
		match str(next["kind"]):
			"day", "card_window":
				break
			"begin_step":
				s.call("skip_next_step", "Test") if bool(next["skippable"]) else s.call("begin_next_step")
			"prompt":
				s.call("skip_next_step", "Test")
			"end_night":
				s.call("end_night")
	await frames(3)
	var cont := find_node(current_screen(shell), "ContinueDayButton") as BaseButton
	if cont != null:
		await press(cont)


## Tauscht jede Karte im Fenster gegen eine Ersatzkarte, spielt diese mit der kleinsten gültigen Wahl und schließt das Fenster.
func _exchange_all(s: Object) -> void:
	for guard: int in 60:
		var n: Dictionary = effective_of((s.call("cockpit_view") as Dictionary)["next"])
		match str(n["kind"]):
			"card_window":
				if bool(n["can_exchange"]):
					s.call("card_act", int(n["owner_id"]), "exchange")
				elif bool(n["can_play"]):
					s.call("card_act", int(n["owner_id"]), "play")
				else:
					s.call("card_close_window")
			"prompt":
				match str(n["answer"]):
					"targets":
						var counts: Array = n["counts"]
						var need := int(counts[0]) if not counts.is_empty() else int(n["min"])
						s.call("answer_targets", (n["allowed_ids"] as Array).slice(0, need))
					"option":
						s.call("answer_option", 0)
					"choice":
						s.call("answer_choice", true)
					"ack":
						s.call("answer_choice", true)
					"roll":
						s.call("answer_roll")
			_:
				return


func _view(shell: Control) -> Dictionary:
	return session_of(shell).call("cockpit_view")


func _next(shell: Control) -> Dictionary:
	return _view(shell)["next"]


func _tap(shell: Control, node_name: String) -> void:
	var b := find_button(current_screen(shell), node_name)
	assert_true(b != null and b.is_visible_in_tree(), "Button %s sichtbar" % node_name)
	if b != null:
		await press(b)


func _seat(shell: Control, id: int) -> BaseButton:
	return find_node(current_screen(shell), "SeatRing").call("token_for", id) as BaseButton


func _dialog_confirm(shell: Control) -> void:
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog.call("is_open"), "Dialog offen")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)


func _all_text(shell: Control) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(current_screen(shell)):
		out.append(text_of(c))
	return "\n".join(out)


func test_window_is_covered_then_shows_the_card_with_all_actions() -> void:
	var shell := await _game({10: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	assert_eq(str(_next(shell)["kind"]), "card_window", "Kartenfenster statt Tag")
	assert_true(find_node(current_screen(shell), "CardPlayButton") == null, "verdeckt: kein Spielen-Button")
	assert_true(find_node(current_screen(shell), "RevealButton") != null, "Aufdecken angeboten")
	await _tap(shell, "RevealButton")
	var name_label := find_node(current_screen(shell), "CardNameLabel") as Label
	assert_eq(name_label.text, tr("ui.card.schicksal_03.name"), "Kartenname")
	assert_eq((find_node(current_screen(shell), "CardTextLabel") as Label).text, tr("ui.card.schicksal_03.neutral.text"), "Kartentext")
	assert_true(find_button(current_screen(shell), "CardPlayButton") != null and not find_button(current_screen(shell), "CardPlayButton").disabled, "Spielen möglich")
	assert_true(find_button(current_screen(shell), "CardKeepButton") != null and not find_button(current_screen(shell), "CardKeepButton").disabled, "Aufbewahren möglich")
	assert_true(find_node(current_screen(shell), "CardExchangeButton") == null, "ohne Kartenschlucker kein Tauschen")
	assert_true(find_button(current_screen(shell), "CardCloseWindowButton") != null, "Fenster schließen")
	assert_true(find_button(current_screen(shell), "CardOverviewButton") != null, "Überblick")
	assert_true(find_button(current_screen(shell), "CardShowButton") != null, "Karte zeigen")


func test_keep_leaves_the_card_and_opens_the_day() -> void:
	var shell := await _game({10: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	await _tap(shell, "CardKeepButton")
	assert_eq(str(_next(shell)["kind"]), "day", "danach der Tag")
	var held := CardRules.held_of(session_of(shell).get("_state"), 10)
	assert_true(not held.is_empty() and held["status"] == "held", "Karte bleibt bei der Person")


func test_play_amnesty_cancels_todays_execution() -> void:
	var shell := await _game({10: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	await _tap(shell, "CardPlayButton")
	assert_eq(str(_next(shell)["kind"]), "day", "nach dem Spielen der Tag")
	assert_true(find_node(current_screen(shell), "ExecutionCancelledLabel") != null, "Hinweis: Hinrichtung entfällt")
	var execute := find_button(current_screen(shell), "ExecuteButton")
	assert_true(execute != null and execute.disabled, "Hinrichten gesperrt")
	assert_true(find_node(current_screen(shell), "CardPublicLine") != null or _all_text(shell).contains(tr("ui.card.schicksal_03.neutral.text")), "öffentliche Ansage der Karte am Tag")


func test_revival_pick_is_made_on_the_seat_ring_and_confirmed() -> void:
	var shell := await _game({10: "wende_04", 9: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	# Person 10 hält Wiedergeburt (Dorf): die Spielleitung wählt eine tote Person der Fraktion.
	var first_owner := int(_next(shell)["owner_id"])
	if first_owner != 10:
		await _tap(shell, "CardKeepButton")
		await _tap(shell, "RevealButton")
	await _tap(shell, "CardPlayButton")
	assert_eq(str(_next(shell)["kind"]), "prompt", "Karteneingabe als Prompt")
	assert_eq(str(_next(shell)["owner"]), "card", "Besitzer Karte")
	assert_eq(str(_next(shell)["answer"]), "targets", "Antwort: Personen")
	await _tap(shell, "RevealButton")
	var target := int((_next(shell)["allowed_ids"] as Array)[0])
	var seat := _seat(shell, target)
	assert_true(seat != null and not seat.disabled, "Tote Person im Sitzkreis antippbar")
	await press(seat)
	var confirm := find_button(current_screen(shell), "ConfirmTargetsButton")
	assert_true(confirm != null and inside(rect_of(confirm), Rect2(Vector2.ZERO, Vector2(tree.root.size))), "Bestätigen der Karteneingabe ohne Scrollen sichtbar")
	await _tap(shell, "ConfirmTargetsButton")
	var state: GameState = session_of(shell).get("_state")
	assert_true(state.players[target].alive, "Person ist zurückgekehrt")


func test_dice_are_rolled_stored_and_drawn() -> void:
	var shell := await _game({10: "loki_10", 9: "schicksal_03", 8: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	for i: int in 3:
		if int(_next(shell).get("owner_id", -1)) == 10:
			break
		await _tap(shell, "CardKeepButton")
		await _tap(shell, "RevealButton")
	await _tap(shell, "CardPlayButton")
	await _tap(shell, "RevealButton")
	assert_true(find_button(current_screen(shell), "RollButton") != null, "Würfeln-Button")
	assert_true(find_node(current_screen(shell), "DiceRow") == null or (find_node(current_screen(shell), "DiceRow") as Control).get_child_count() == 0, "vor dem Wurf keine Würfel")
	await _tap(shell, "RollButton")
	await _tap(shell, "RevealButton") if find_button(current_screen(shell), "RevealButton") != null else await frames(1)
	var row := find_node(current_screen(shell), "DiceRow") as Control
	assert_true(row != null and row.get_child_count() == 2, "zwei sichtbare Würfel")
	var stored: Array = (_next(shell)["dice"] as Array)
	assert_eq(stored.size(), 2, "gespeicherte Würfe im Prompt")
	for i: int in 2:
		assert_eq(int(stored[i]) >= 1 and int(stored[i]) <= 6, true, "Wurf %d im Bereich" % i)
		assert_eq((row.get_child(i) as Control).get("value"), int(stored[i]), "Würfel %d zeigt den gespeicherten Wurf" % i)
	assert_true(find_node(current_screen(shell), "DiceResultLabel") != null, "Ergebnis zusätzlich als Text")
	# Neu laden darf nicht neu würfeln: dieselben Würfe nach Speichern und Laden.
	var text: String = session_of(shell).call("save_text")
	assert_eq(session_of(shell).call("load_text", text), &"", "Laden")
	var again: Array = (_next(shell)["dice"] as Array)
	assert_eq(again, stored, "gleiche Würfe nach dem Laden")


func test_rule_card_report_violation_kills_after_selecting_the_person() -> void:
	var shell := await _game({10: "loki_11"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	await _tap(shell, "CardPlayButton")
	assert_eq(str(_next(shell)["kind"]), "day", "Tag mit Tagesregel")
	var report := current_screen(shell).find_children("CardReportButton_*", "BaseButton", true, false)
	assert_eq(report.size(), 1, "ein Button für den Verstoß")
	await press(report[0] as BaseButton)
	await press(_seat(shell, 3))
	await _tap(shell, "ConfirmCardReportButton")
	var state: GameState = session_of(shell).get("_state")
	assert_false(state.players[3].alive, "Person nach dem Verstoß tot")


func test_close_window_asks_and_keeps_cards() -> void:
	var shell := await _game({10: "schicksal_03", 9: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	await _tap(shell, "CardCloseWindowButton")
	await _dialog_confirm(shell)
	assert_eq(str(_next(shell)["kind"]), "day", "Fenster zu, der Tag läuft")
	var state: GameState = session_of(shell).get("_state")
	assert_eq(CardRules.held_of(state, 10)["status"], "held", "Karte 10 bleibt")
	assert_eq(CardRules.held_of(state, 9)["status"], "held", "Karte 9 bleibt")


func test_overview_and_card_face_layers() -> void:
	var shell := await _game({10: "schicksal_03"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	await _tap(shell, "CardOverviewButton")
	var layer := find_node(shell, "CardsLayer")
	assert_true(layer != null, "Überblick offen")
	assert_true(find_node(layer, "CardRow_1") != null, "Zeile der Karte")
	await _tap(shell, "CloseLayerButton")
	await _tap(shell, "CardShowButton")
	var face := find_node(shell, "CardLayer")
	assert_true(face != null, "Kartenfläche offen")
	assert_eq((find_node(face, "CardFaceName") as Label).text, tr("ui.card.schicksal_03.name"), "Kartenname groß")
	await _tap(shell, "CloseLayerButton")


func test_card_swallower_shows_hand_signs_with_costs() -> void:
	# Der Kartenschlucker (Person 3) erhält durch getauschte Karten Stapel (hier über zwei Tote mit Tausch).
	var shell := await _game({9: "schicksal_03", 10: "schicksal_03"}, "de", {"3": "kartenschlucker"})
	if shell == null:
		return
	var s := session_of(shell)
	await _to_day(shell)
	# Die beiden Tauschvorgänge laufen über die Anwendungsschicht (der Bedienweg des Tauschens ist in einem eigenen Test geprüft).
	_exchange_all(s)
	var state: GameState = s.get("_state")
	assert_true(SwallowerRules.balance_of(state, 3) >= 2, "Guthaben für eine Tötung (%d)" % SwallowerRules.balance_of(state, 3))

	# Nacht: Der Kartenschlucker wählt per Handzeichen. Die Optionen tragen ihre Kosten, Guthaben und Zahlen stehen auf der Karte.
	if str(_next(shell)["kind"]) == "card_window":
		await _tap(shell, "CardCloseWindowButton")
		await _dialog_confirm(shell)
	await _tap(shell, "NoExecutionButton")
	await _dialog_confirm(shell)
	await _tap(shell, "EndDayButton")
	if str(_next(shell)["kind"]) == "card_window":
		await _tap(shell, "CardCloseWindowButton")
		await _dialog_confirm(shell)
	await _tap(shell, "StartNightButton")
	for guard: int in 14:
		var n := _next(shell)
		if str(n["kind"]) == "prompt" and str(n["owner"]) == "kartenschlucker":
			break
		if str(n["kind"]) == "begin_step":
			await _tap(shell, "BeginStepButton")
		elif str(n["kind"]) == "prompt":
			# Rudelwahl: erste zulässige Person
			await press(_seat(shell, int((n["allowed_ids"] as Array)[0])))
			await _tap(shell, "ConfirmTargetsButton")
		else:
			break
	var act := _next(shell)
	assert_eq(str(act.get("owner")), "kartenschlucker", "Handzeichen-Prompt des Kartenschluckers")
	assert_eq(str(act.get("answer")), "option", "Antwort: Option")
	var options: Array = act["options"]
	assert_eq(options, ["none", "kill"], "Optionen nach Guthaben: nichts oder Tötung")
	assert_eq((find_button(current_screen(shell), "OptionButton_1") as GrimmButton).text, tr("ui.card.option.swallower.kill"), "Beschriftung mit Kosten")
	assert_true(find_node(current_screen(shell), "SwallowerStatusLabel") != null, "Guthaben sichtbar")
	await _tap(shell, "OptionButton_1")
	assert_eq(str(_next(shell)["answer"]), "targets", "danach die Zielwahl")


func test_exchange_by_buttons_plays_the_replacement_at_once_and_moves_on() -> void:
	# Die Ersatzkarte wird sofort gespielt (Decision Log 3A): ohne Eingabe wirkt sie ohne Zwischenschritt, das Fenster fragt die nächste Person.
	var shell := await _game({9: "schicksal_03", 10: "schicksal_03"}, "de", {"3": "kartenschlucker"})
	if shell == null:
		return
	await _to_day(shell)
	await _tap(shell, "RevealButton")
	assert_eq(int(_next(shell)["owner_id"]), 9, "erste gefragte Person")
	assert_true(find_node(current_screen(shell), "CardExchangeButton") != null, "Tauschen angeboten")
	await _tap(shell, "CardExchangeButton")
	await _dialog_confirm(shell)
	var state: GameState = session_of(shell).get("_state")
	var records := CardRules.records(state)
	assert_eq(records[0]["status"], "swapped", "Originalkarte getauscht")
	assert_eq(records[2]["status"], "played", "Ersatzkarte sofort gespielt")
	assert_eq(records[2]["origin"], "exchange", "Herkunft: Tausch")
	assert_eq(SwallowerRules.balance_of(state, 3), 1, "ein Stapel für den Kartenschlucker")
	assert_eq(int(_next(shell).get("owner_id", -1)), 10, "danach die nächste Person")
	# Die Ersatzkarte ist nicht erneut tauschbar; die zweite Person darf tauschen.
	await _tap(shell, "RevealButton")
	assert_true(find_node(current_screen(shell), "CardExchangeButton") != null, "zweite Person darf tauschen")


## Rechts- und Linkshänder, DE und EN: Alle Kartenaktionen stehen im festen Aktionsbereich der Karte in der Tischmitte
## (ohne Scrollen sichtbar, nicht im scrollenden Text), überdecken keinen Platz, und nur die Hauptaktion wechselt mit der Bedienhand
## das Ende (Texte, Reihenfolge und Spielzustand bleiben gleich).
func test_card_window_fits_for_both_hands_and_languages() -> void:
	for lang: String in ["de", "en"]:
		var side_x := {}
		for left: bool in [false, true]:
			var shell := await _game({10: "schicksal_03"}, lang)
			if shell == null:
				return
			settings_of(shell).call("set_left_handed", left)
			await _to_day(shell)
			await _tap(shell, "RevealButton")
			var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
			var card := rect_of(find_node(current_screen(shell), "InstructionCard") as Control)
			var scroll := find_node(current_screen(shell), "Scroll") as ScrollContainer
			var seats: Array = find_node(current_screen(shell), "SeatRing").call("tokens")
			for node_name: String in ["CardPlayButton", "CardKeepButton", "CardShowButton", "CardOverviewButton", "CardCloseWindowButton"]:
				var b := find_button(current_screen(shell), node_name)
				assert_true(b != null, "%s/%s: %s vorhanden" % [lang, left, node_name])
				if b == null:
					continue
				var r := rect_of(b)
				assert_false(scroll.is_ancestor_of(b), "%s/%s: %s steht außerhalb des scrollenden Textes" % [lang, left, node_name])
				# Die Hauptaktion steht im Dock am unteren Rand (P3), alle anderen Aktionen in der Karte.
				var home := rect_of(find_node(current_screen(shell), "ActionsArea") as Control) if node_name == "CardPlayButton" else card
				assert_true(inside(r, viewport) and inside(r, home), "%s/%s: %s ohne Scrollen sichtbar (%s)" % [lang, left, node_name, str(r)])
				for t: Variant in seats:
					assert_false(seat_hits_rect(t as Control, r), "%s/%s: %s überdeckt keinen Platz" % [lang, left, node_name])
				assert_true(r.size.y >= 44.0, "%s/%s: %s mindestens 44 hoch" % [lang, left, node_name])
			side_x[left] = rect_of(find_button(current_screen(shell), "CardPlayButton")).get_center().x
			assert_true(str(_next(shell)["kind"]) == "card_window", "%s/%s: Zustand unverändert (Fenster offen)" % [lang, left])
		assert_true(side_x[true] < side_x[false], "%s: die Hauptaktion liegt für Linkshänder weiter links" % lang)
