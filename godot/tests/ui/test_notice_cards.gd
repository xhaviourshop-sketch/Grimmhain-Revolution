extends UiTestCase
## DI-04 bis DI-08 in der Oberfläche: private Hinweise als bedienbare Karten (zeigen, dann als gezeigt bestätigen).
##   Loki: beide Personen sehen nur ihren Partner und die Bindungsart.
##   Rattenfänger: die neu Verzauberten (ohne Namen); „Alle Verzauberten“ ist ein Nachtschritt (PE-06, test_piper_all_ui).
##   Pestbringerin: jede neu infizierte Person, auch nach der Ausbreitung am Morgen.
##   Rotkäppchen: Die Frage an die gefragte Person erklärt Apfel und Kette, ohne Rolle und ohne fragende Person.
##   Trugbilderwolf: Seine Scheinrolle steht auf keiner Karte.
## Die Karten überstehen Navigation, Neustart und Rückgängig; im Sichtschutz bleibt ihr Inhalt verdeckt.

const UiGame := preload("res://tests/ui/ui_game.gd")
const W := "werwolf"
const D := "dorfbewohner"


func _cockpit(roles: Array, appearances: Dictionary = {}) -> Control:
	var shell := await spawn_shell()
	if shell == null:
		return null
	var r: CommandResult = session_of(shell).call("submit", UiGame.start(roles, 7, appearances))
	assert_true(r.ok, "Start (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _texts(root: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		out.append(text_of(c))
	return "\n".join(out)


func _is_notice(kind: String = "") -> Callable:
	return func(n: Dictionary) -> bool: return str(n.get("kind")) == "notice" and (kind == "" or str(n.get("notice_kind")) == kind)


func _role_names() -> Array[String]:
	var names: Array[String] = []
	for path: String in ["res://content/i18n/ui.de.po", "res://content/i18n/ui.en.po"]:
		var po := po_entries(path)
		for role: String in ["loki", "rattenfaenger", "pestbringerin", "rotkaeppchen", "trugbilderwolf", "waldhexe", "schutzengel", "werwolf"]:
			var k := "ui.role.%s.name" % role.replace("-", "_")
			if po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


func _assert_no_role_names(text: String, label: String) -> void:
	for name: String in _role_names():
		assert_false(text.contains(name), "%s: nennt Rolle „%s“" % [label, name])


# --- Loki -------------------------------------------------------------------------------------------

func test_loki_cards_show_only_the_own_partner_and_are_confirmed_one_by_one() -> void:
	var shell := await _cockpit([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(s.answer_targets([3, 5]).ok and s.answer_choice(true).ok, "Loki bindet 3 und 5 als Liebende")
	await frames(3)
	var screen := current_screen(shell)
	var next := UiGame.next_of(s)
	assert_eq(str(next["kind"]), "notice", "Hinweiskarte folgt sofort")
	assert_eq(str(next["text_key"]), "ui.notice.loki_bond.love", "Text für Liebende")
	assert_eq((next["viewers"] as Array).map(func(v: Dictionary) -> int: return int(v["person_id"])), [3], "erste Karte für Person 3")
	assert_eq(int((next["values"] as Dictionary)["partner"]["person_id"]), 5, "Partner ist Person 5")
	assert_true(find_button(screen, "ShowNoticeButton") != null and find_node(screen, "AckNoticeButton") == null, "nur Zeigen; Schließen der Karte bestätigt")
	_assert_no_role_names(_texts(screen), "Hinweiskarte der Spielleitung")
	await press(find_button(screen, "ShowNoticeButton"))
	var layer := find_node(screen, "NoticeLayer")
	assert_true(layer != null, "Karte für die Person")
	var shown := _texts(layer)
	assert_true(shown.contains("5 · E"), "nennt den eigenen Partner: %s" % shown)
	assert_false(shown.contains("3 · C"), "nennt nicht die betrachtende Person selbst als Dritte")
	assert_false(shown.contains("2 · B"), "nennt nicht Loki")
	_assert_no_role_names(shown, "gezeigte Karte")
	await press(find_button(layer, "CloseLayerButton"))  # Schließen der gezeigten Karte bestätigt sie
	next = UiGame.next_of(s)
	assert_eq(str(next["kind"]), "notice", "zweite Karte")
	assert_eq(int(((next["viewers"] as Array)[0] as Dictionary)["person_id"]), 5, "für Person 5")
	assert_eq(int((next["values"] as Dictionary)["partner"]["person_id"]), 3, "Partner ist Person 3")
	assert_true(UiGame.step(s) == "notice", "auch die zweite wird bestätigt")
	assert_ne(str(UiGame.next_of(s)["kind"]), "notice", "danach geht die Nacht weiter")
	var acks := s.commands().filter(func(c: Command) -> bool: return c.type == Command.ACK_NOTICE)
	assert_eq(acks.size(), 2, "zwei AckNotice im Befehlsverlauf")


func test_loki_rivals_card_names_the_kind() -> void:
	var s := UiGame.session([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(s.answer_targets([4, 6]).ok and s.answer_choice(false).ok, "Rivalen")
	var next := UiGame.next_of(s)
	assert_eq(str(next["text_key"]), "ui.notice.loki_bond.rival", "Text für Rivalen")
	assert_eq(int(((next["values"] as Dictionary)["partner"] as Dictionary)["person_id"]), 6, "Partner")


func test_notice_survives_navigation_restart_and_undo() -> void:
	var shell := await _cockpit([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.start_night().ok and s.answer_targets([3, 5]).ok and s.answer_choice(true).ok, "Loki bindet")
	var id_before := int(UiGame.next_of(s)["notice_id"])
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	assert_eq(int(UiGame.next_of(s)["notice_id"]), id_before, "nach Navigation dieselbe Karte")
	assert_true(find_button(current_screen(shell), "ShowNoticeButton") != null, "Karte bedienbar")
	var other := GameSession.new()
	assert_eq(other.load_text(s.save_text()), &"", "Neustart: Laden")
	assert_eq(int(UiGame.next_of(other)["notice_id"]), id_before, "nach dem Laden dieselbe offene Karte")
	assert_true(UiGame.step(s) == "notice", "Bestätigen")
	assert_ne(int(UiGame.next_of(s).get("notice_id", -1)), id_before, "die erste Karte ist erledigt")
	assert_true(s.undo(), "Rückgängig")
	assert_eq(int(UiGame.next_of(s)["notice_id"]), id_before, "nach Rückgängig steht die Karte wieder an")
	assert_true(s.redo(), "Wiederholen")
	assert_ne(int(UiGame.next_of(s).get("notice_id", -1)), id_before, "nach Wiederholen erledigt")


# --- Rattenfänger -----------------------------------------------------------------------------------

func test_piper_shows_new_enchanted_without_names_then_the_all_step() -> void:
	var shell := await _cockpit([W, "rattenfaenger", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.run_until(s, _is_notice("piper_new"), {"rattenfaenger/": [3, 4]}), "erste Phase")
	await frames(3)
	var screen := current_screen(shell)
	var next := UiGame.next_of(s)
	assert_eq(str(next["text_key"]), "ui.notice.piper_new", "neu Verzauberte")
	assert_true(bool(next["group"]), "Gruppenkarte")
	assert_true((next["values"] as Dictionary).is_empty(), "ohne Namen")
	await press(find_button(screen, "ShowNoticeButton"))
	var first := _texts(find_node(screen, "NoticeLayer"))
	assert_false(first.contains("3 · C") or first.contains("4 · D"), "erste Phase nennt keine Namen: %s" % first)
	await press(find_button(find_node(screen, "NoticeLayer"), "CloseLayerButton"))
	next = UiGame.next_of(s)
	assert_eq(str(next["kind"]), "begin_step", "danach kein zweiter Hinweis, sondern der Schritt")
	assert_eq(str(next["role_id"]), "piper-all", "Schritt „Alle Verzauberten“")


# --- Pestbringerin ----------------------------------------------------------------------------------

func test_plague_notice_at_night_and_after_the_spread_and_hidden_until_revealed() -> void:
	var shell := await _cockpit([W, "pestbringerin", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.run_until(s, _is_notice("pest_infected"), {"pestbringerin/": [5]}), "Infektion in der Nacht")
	var next := UiGame.next_of(s)
	assert_eq(int(((next["viewers"] as Array)[0] as Dictionary)["person_id"]), 5, "Hinweis für Person 5")
	assert_eq(str(next["text_key"]), "ui.notice.pest_infected", "Text")
	assert_true(UiGame.step(s) == "notice", "bestätigt")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night"), "Nacht bis zum Ende")
	assert_true(s.end_night().ok, "Morgen mit Ausbreitung")
	await frames(3)
	var fresh: Array[int] = []
	for e: Dictionary in s.event_log():
		if str(e["type"]) == "PlagueSpread" and bool((e["data"] as Dictionary)["new"]):
			fresh.append(int((e["data"] as Dictionary)["target_id"]))
	assert_true(not fresh.is_empty(), "Ausbreitung hat eine neue Person erreicht")
	next = UiGame.next_of(s)
	assert_eq(str(next["kind"]), "notice", "Hinweis nach der Ausbreitung")
	assert_true(fresh.has(int(((next["viewers"] as Array)[0] as Dictionary)["person_id"])), "für die neu Angesteckte")
	var screen := current_screen(shell)
	# Im Sichtschutz (Tag) bleibt der Inhalt verdeckt, bis die Spielleitung ausdrücklich aufdeckt.
	assert_true(find_node(screen, "ShowNoticeButton") == null, "vor dem Aufdecken keine Hinweisbedienung")
	var covered := _texts(find_node(screen, "ActionCard"))
	assert_false(covered.contains("infiziert") or covered.contains("infected"), "Inhalt verdeckt: %s" % covered)
	await press(find_button(screen, "RevealButton"))
	assert_true(find_button(screen, "ShowNoticeButton") != null, "nach dem Aufdecken bedienbar")


# --- Rotkäppchen ------------------------------------------------------------------------------------

func test_refuge_card_asks_the_person_and_hides_the_asker() -> void:
	var shell := await _cockpit([W, "rotkaeppchen", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.start_night().ok, "Nacht 1")
	var reached := UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "prompt" and str(n.get("owner")) == "rotkaeppchen" and str(n.get("stage")) == "grant",
		{"rotkaeppchen/targets": [4]})
	assert_true(reached, "Frage an die gefragte Person")
	await frames(3)
	var next := UiGame.next_of(s)
	assert_true(bool(next["anonymous_asker"]), "anonyme Frage")
	assert_eq(next["actor_ids"], [4], "handelnd ist die gefragte Person, nicht Rotkäppchen")
	assert_eq(str(next["role_id"]), "", "keine Rolle auf der Karte")
	var text := _texts(find_node(current_screen(shell), "ActionCard"))  # nur die Karte, der Sitzkreis nennt alle Namen öffentlich
	assert_false(text.contains("Rotkäppchen"), "nennt nicht die Rolle: %s" % text)
	assert_false(text.contains("2 · B"), "nennt nicht die fragende Person")
	assert_true(text.contains("Zuflucht") and text.contains("gewähren oder ablehnen"), "Schablone: ein Satz und eine Hilfe: %s" % text)
	assert_true(text.contains("4 · D"), "nennt die gefragte Person: %s" % text)
	assert_true(text.contains("Apfel") and text.contains("Todeskette"), "ein Hilfesatz zu Apfel und Kette: %s" % text)
	assert_false(text.contains("ui.role") and text.contains("erwache"), "keine Ansagezeile mit leerer Rolle: %s" % text)
	assert_false((find_node(current_screen(shell), "OrderBar") as Control).visible, "S-04: keine Nachtleiste bei der anonymen Frage")
	var ring := find_node(current_screen(shell), "SeatRing")
	assert_eq(String(ring.call("token_for", 4).get("state")), "actor", "die gefragte Person ist am Sitzkreis markiert")
	var screen := current_screen(shell)
	assert_true(find_button(screen, "YesButton") != null and find_button(screen, "NoButton") != null, "Zustimmen und Ablehnen bedienbar")
	assert_true(s.answer_choice(true).ok, "Zustimmung")
	assert_eq(s.state_hash() != "", true, "Partie läuft weiter")


func test_refuge_can_be_declined_without_effect() -> void:
	var s := UiGame.session([W, "rotkaeppchen", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "prompt" and str(n.get("stage")) == "grant", {"rotkaeppchen/targets": [4]}), "Frage")
	assert_true(s.answer_choice(false).ok, "Ablehnung")
	var chains := 0
	for e: Dictionary in s.event_log():
		if str(e["type"]) == "RedRefuge" and bool((e["data"] as Dictionary).get("granted", false)):
			chains += 1
	assert_eq(chains, 0, "Ablehnung setzt keine Kette")


# --- Trugbilderwolf ---------------------------------------------------------------------------------

func test_decoy_wolf_gets_no_card_and_public_view_shows_no_appearance() -> void:
	var s := UiGame.session([W, "trugbilderwolf", "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher"], 7, {"2": "waldhexe"})
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.to_day(s), "Tag 1")
	for e: Dictionary in s.event_log():
		if str(e["type"]) == "NoticeQueued":
			assert_false(((e["data"] as Dictionary)["viewer_ids"] as Array).has(2), "keine Karte für den Trugbilderwolf")
	var public_view := JSON.stringify(s.cockpit_view()["seats"])
	assert_false(public_view.contains("waldhexe") or public_view.contains("trugbilderwolf"), "öffentliche Sitzsicht ohne Rollen und Scheinrolle")
	var private: Array = s.private_seats()
	var wolf: Dictionary = private.filter(func(p: Dictionary) -> bool: return int(p["person_id"]) == 2)[0]
	assert_true(JSON.stringify(wolf["notes"]).contains("waldhexe"), "nur der private Spielleiterbereich nennt die Scheinrolle")


## S-07 (DA-93): Verdeckte Karten tragen für jede Art denselben Text (eine offene Siegentscheidung ist nicht erkennbar).
func test_covered_cards_share_one_text() -> void:
	var card := ActionCard.new()
	tree.root.add_child(card)
	var texts: Array[String] = []
	for kind: String in ["win_decision", "card_window", "begin_step"]:
		card.render({"kind": kind, "secret": true}, {"revealed": false, "phase": "DAY"})
		var parts: Array[String] = []
		for c: Control in text_controls(card):
			parts.append(key_of(c))
		texts.append("|".join(parts))
	assert_eq(texts[0], texts[1], "Siegentscheidung wie Kartenfenster")
	assert_eq(texts[0], texts[2], "Siegentscheidung wie Schritt")
	card.queue_free()
