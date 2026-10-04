extends UiTestCase
## Abschlusscheck der Kartenoberfläche, nur die bisher nicht belegten Fälle: ein englischer Ablauf von „Neue Partie“ bis zur gespielten
## Karte mit Zielauswahl, und 1024×768 mit 24 Personen (längster Kartentext, Zielauswahl am Sitzkreis, Speicherfehler) für Rechts- und
## Linkshänder. Alles über echte Buttons und Sitzplätze; Befehle an die Sitzung gibt es nur für Ausgangszustände (tote Person mit
## bestimmter Karte, wie in den anderen Kartentests). Headless: geprüft werden Geometrie und Bedienbarkeit, keine Pixel, keine Touch-Eingabe.

const NAMES := ["Anna", "Ben", "Cara", "Dirk", "Eva", "Finn", "Gina", "Hugo", "Ida", "Jan", "Kim", "Lea", "Max", "Nina", "Otto", "Pia", "Quin", "Rosa", "Sven", "Tina", "Uwe", "Vera", "Willi", "Xenia"]
const SETUP_SEED := 20261001
const PICK_CARD := "wende_01"  ## Wunsch einer Person: eine Personenwahl in beiden Fraktionsvarianten


func _button(shell: Control, node_name: String) -> BaseButton:
	var b := current_screen(shell).find_child(node_name, true, false) as BaseButton
	return b if b != null and b.is_visible_in_tree() and not b.disabled else null


func _tap(shell: Control, node_name: String) -> bool:
	var b := _button(shell, node_name)
	if b == null:
		return false
	await press(b)
	return true


## Tippt freie, antippbare Plätze (`prefer` zuerst), bis `count` gewählt sind.
func _tap_seats(shell: Control, count: int, prefer: Array = []) -> int:
	var tapped := 0
	var tokens: Array = find_node(current_screen(shell), "SeatRing").call("tokens")
	tokens.sort_custom(func(a: Variant, b: Variant) -> bool: return prefer.has(int(a.get("person_id"))) and not prefer.has(int(b.get("person_id"))))
	for token: Variant in tokens:
		var t := token as Button
		if tapped >= count:
			break
		if t.disabled or t.theme_type_variation == &"SeatSelectedButton":
			continue
		await press(t)
		tapped += 1
	return tapped


func _dialog_confirm(shell: Control) -> bool:
	var dialog := shell.call("get_dialog") as Control
	if not dialog.call("is_open"):
		return false
	var confirm := find_node(dialog, "ConfirmButton") as BaseButton
	if confirm.visible and not confirm.disabled:
		await press(confirm)
		return true
	var field := find_node(dialog, "InputField") as LineEdit
	if field.visible:
		await type_text(field, "Test")
		await press(confirm)
		return true
	return false


func _next(shell: Control) -> Dictionary:
	return effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])


func _gm(shell: Control, payload: Dictionary) -> void:
	var p := payload.duplicate()
	p["reason"] = "Test"
	p["confirmed"] = true
	var r: CommandResult = session_of(shell).call("gm_correction", p)
	assert_true(r.ok, "Korrektur %s (%s)" % [payload.get("kind"), r.error])


func _state_of(shell: Control) -> GameState:
	return RulesEngine.replay((session_of(shell) as GameSession).commands()).state


# --- Englischer Ablauf von „Neue Partie“ bis zur gespielten Karte ----------------------------------------------------

## Vorbereitung nur über sichtbare Buttons, mit eingeschalteten Totenreichkarten (Akt IV kennt den Kartenschlucker).
func _new_game_with_cards(shell: Control, count: int) -> void:
	var screen := await prepare_through_buttons(shell, count, &"akt4", SETUP_SEED, true)
	await press(find_button(screen, "NextButton"))
	await frames(3)


## Eine Bedienung der Nacht bis zum Kartenfenster oder zum Tag.
func _night_step(shell: Control) -> bool:
	if await _dialog_confirm(shell):
		return true
	var next := _next(shell)
	if str(next["kind"]) == "notice":
		return await _tap(shell, "ShowNoticeButton") and await _tap(shell, "CloseLayerButton")  # Schließen bestätigt den Hinweis
	if await _tap(shell, "ShowCardButton"):
		return await _tap(shell, "CloseLayerButton")  # Schließen erledigt die Auskunft
	for node_name: String in ["StartNightButton", "BeginStepButton", "EndNightButton", "AckButton", "ContinueDayButton"]:
		if await _tap(shell, node_name):
			return true
	if str(next["kind"]) == "prompt":
		match str(next["answer"]):
			"choice":
				return await _tap(shell, "YesButton") or await _tap(shell, "NoButton")
			"roll":
				return await _tap(shell, "RollButton")
			"option":
				return await _tap(shell, "OptionButton_0")
			"targets":
				var counts: Array = next.get("counts", [])
				var need := maxi(int(counts[0]) if not counts.is_empty() else int(next["min"]), 1)
				if str(next["owner"]) == "loki":
					await _tap(shell, "YesButton")  # Loki: erst Liebende oder Rivalen, dann die zwei Personen
				await _tap_seats(shell, need)
				if CockpitText.auto_commit(next):
					return true  # eine feste Anzahl gilt sofort
				return await _tap(shell, "ConfirmTargetsButton") or await _tap(shell, "DeclineButton")
	return false


func test_english_game_from_setup_to_a_played_card_with_target_selection() -> void:
	var shell := await spawn_shell(SIZE_16_10, "en")
	if shell == null:
		return
	assert_true(TranslationServer.get_locale().begins_with("en"), "Sprache Englisch")
	await _new_game_with_cards(shell, 8)
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit nach dem Start")
	var state := _state_of(shell)
	assert_true(state.death_cards, "Totenreichkarten aktiv")
	# Ausgangszustand: eine Dorfperson (die zufällige Verteilung entscheidet, welche) ist schon tot und hält eine Karte mit Personenwahl.
	var holder := 0
	for id: int in state.alive_ids():
		if state.players[id].faction == Faction.VILLAGE and not state.players[id].counts_as_wolf:
			holder = id
			break  # der niedrigste Sitz: sein Kartenfenster kommt zuerst
	assert_ne(holder, 0, "es gibt eine Dorfperson")
	_gm(shell, {"kind": "kill", "target_id": holder, "trigger_effects": false})
	_gm(shell, {"kind": "set_card", "target_id": holder, "card_id": PICK_CARD})
	var dead_before := _state_of(shell).alive_ids().size()
	for guard: int in 80:
		if str(_next(shell)["kind"]) in ["card_window", "day"]:
			break
		assert_true(await _night_step(shell), "Nacht: bedienbarer Button (Schritt %d, %s)" % [guard, str(_next(shell)["kind"])])
		if not failures.is_empty():
			return
	assert_true(_state_of(shell).alive_ids().size() < dead_before, "in der Nacht starb jemand (Tod vor dem Kartenfenster)")
	var played := false
	var target := -1
	for guard: int in 30:
		var next := _next(shell)
		if str(next["kind"]) == "card_window":
			if int(next["owner_id"]) != holder and not played and await _tap(shell, "CardKeepButton"):
				continue  # andere Fenster (ein gezogenes Los einer lebenden Person) behält die Person, bis das Fenster der Karte kommt
			if await _tap(shell, "ContinueDayButton"):
				continue
			if await _tap(shell, "RevealButton"):
				if int(next["owner_id"]) == holder and not played:
					var name_label := find_node(current_screen(shell), "CardNameLabel") as Label
					assert_eq(name_label.text, po_entries(PO_EN)["ui.card.%s.name" % PICK_CARD], "englischer Kartenname")
					assert_ne(name_label.text, po_entries(PO_DE)["ui.card.%s.name" % PICK_CARD], "kein deutscher Kartenname")
				continue
			if int(next["owner_id"]) == holder and not played:
				played = await _tap(shell, "CardPlayButton")
			else:
				await _tap(shell, "CardKeepButton")
		elif str(next["kind"]) == "prompt" and str(next["owner"]) == "card":
			await _tap(shell, "RevealButton")
			target = int((next["allowed_ids"] as Array)[0])
			var seat := find_node(current_screen(shell), "SeatRing").call("token_for", target) as BaseButton
			assert_true(seat != null and not seat.disabled, "Zielperson im Sitzkreis antippbar")
			await press(seat)
			assert_true(await _tap(shell, "ConfirmTargetsButton"), "Auswahl bestätigen")
		else:
			break
	assert_true(played and target != -1, "die Karte mit Zielauswahl wurde gespielt")
	assert_true(_state_of(shell).apples.has(target), "die Karte wirkte auf die gewählte Person")
	assert_eq(str(_next(shell)["kind"]), "day", "weiter zur nächsten Phase: Tag")
	assert_eq(str((session_of(shell).call("cockpit_view") as Dictionary)["phase"]), "DAY", "Phase Tag")


# --- 1024×768 mit 24 Personen -------------------------------------------------------------------------------------------

## Die Karte (Variante passend zur Spielerfraktion) mit dem längsten Text samt Hinweis in der Sprache `locale`.
func _longest_card(locale: String) -> Dictionary:
	var po := po_entries(PO_EN if locale == "en" else PO_DE)
	var best := {"id": &"", "variant": &"", "length": 0}
	for id: StringName in CardCatalog.ids():
		for variant: StringName in (CardCatalog.CARDS[id]["v"] as Dictionary).keys():
			if variant == CardCatalog.SOLO:
				continue
			var length := str(po.get(CardCatalog.text_key(id, variant), "")).length() + str(po.get(CardCatalog.guide_key(id, variant), "")).length()
			if length > int(best["length"]):
				best = {"id": id, "variant": variant, "length": length}
	return best


## Startet eine Partie mit 24 Personen bei 1024×768; Personen 6 bis 24 sind Dorf (Wölfe 1 bis 5).
## Tote halten ihre Karten: `cards` = {Personen-ID: Karten-ID}.
func _game24(locale: String, left: bool, cards: Dictionary) -> Control:
	var shell := await spawn_shell(SIZE_4_3, locale)
	if shell == null:
		return null
	settings_of(shell).call("set_left_handed", left)
	var players: Array = []
	for i: int in 24:
		players.append({"id": i + 1, "name": NAMES[i]})
	var r: CommandResult = session_of(shell).call("submit", Command.start_game({"round_id": "r24", "seed": 11, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(24), "roles": Fixtures.filled_roles(24, [1, 2, 3, 4, 5]), "death_cards": true}))
	assert_true(r.ok, "Start (%s)" % r.error)
	for id: Variant in cards:
		_gm(shell, {"kind": "kill", "target_id": int(id), "trigger_effects": false})
		_gm(shell, {"kind": "set_card", "target_id": int(id), "card_id": String(cards[id])})
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var s := session_of(shell)
	s.call("start_night")
	for guard: int in 200:
		var next: Dictionary = (s.call("cockpit_view") as Dictionary)["next"]  # Vorbereitung: der Kern-Ablauf, nicht die Kartenvorschau
		match str(next["kind"]):
			"begin_step":
				s.call("skip_next_step", "Test") if bool(next["skippable"]) else s.call("begin_next_step")
			"prompt":
				if str(next["owner"]) == "pack":
					s.call("skip_next_step", "Test")  # Vorbereitung: ruhige Nacht, kein Rudelopfer mit eigener Karte
				else:
					_answer_prompt_minimally(s, next)
			"end_night":
				s.call("end_night")
			"notice":
				s.call("ack_notice", int(next["notice_id"]))
			_:
				break
	await frames(3)
	var cont := find_node(current_screen(shell), "ContinueDayButton") as BaseButton
	if cont != null:
		await press(cont)
	return shell


## Beantwortet eine Eingabe mit der kleinsten gültigen Wahl (nur Vorbereitung des Nachtablaufs).
func _answer_prompt_minimally(s: Object, next: Dictionary) -> void:
	match str(next["answer"]):
		"targets":
			var need := maxi(int(next["min"]), 0)
			s.call("answer_targets", (next["allowed_ids"] as Array).slice(0, need))
		"option":
			s.call("answer_option", 0)
		"roll":
			s.call("answer_roll")
		"ack":
			s.call("answer_choice", true)
		_:
			s.call("answer_choice", false)


## Die Pflichtaktion steht ohne Scrollen im festen Aktionsbereich der Ansagekarte (nicht im scrollenden Text): ganz in der Karte und im
## Fenster; die Hauptaktion (Dock, P3) ganz im Dock am unteren Rand.
func _reachable(shell: Control, b: BaseButton) -> bool:
	var scroll := find_node(current_screen(shell), "Scroll") as ScrollContainer
	var home := find_node(current_screen(shell), "InstructionCard") as Control
	if find_node(current_screen(shell), "NextHost").is_ancestor_of(b):
		home = find_node(current_screen(shell), "ActionsArea") as Control
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	return not scroll.is_ancestor_of(b) and inside(rect_of(b), rect_of(home)) and inside(rect_of(b), viewport) and b.size.y >= 47.5


## Trifft ein Rechteck einen Platz (Porträtkreis oder Namensschild)? Die Ansagekarte liegt in der Tischmitte, nicht auf einem Platz.
func _hits_seat(shell: Control, r: Rect2) -> bool:
	for t: Variant in find_node(current_screen(shell), "SeatRing").call("tokens"):
		if seat_hits_rect(t as Control, r):
			return true
	return false


func test_cockpit_tool_buttons_keep_a_usable_shape_at_1024x768_with_24_persons() -> void:
	for locale: String in ["de", "en"]:
		for left: bool in [false, true]:
			var shell := await _game24(locale, left, {24: PICK_CARD})
			if shell == null:
				return
			var label := "%s/%s" % [locale, "links" if left else "rechts"]
			# Laschen und Randknöpfe stehen am Rand (mindestens 48 px je Seite); die übrigen Werkzeuge stehen im Optionenmenü.
			for node_name: String in ["LogButton", "OptionsButton", "HideButton", "CoverButton"]:
				var edge := find_button(current_screen(shell), node_name)
				assert_true(edge != null and edge.size.x >= 47.5 and edge.size.y >= 47.5, "%s: %s hat eine nutzbare Form (%s)" % [label, node_name, str(edge.size) if edge != null else "fehlt"])
			await press(find_button(current_screen(shell), "OptionsButton"))
			for node_name: String in ["PrivateButton", "RolesButton", "GmButton", "LexiconButton", "RulebookButton"]:
				var b := find_button(current_screen(shell), node_name)
				assert_true(b != null and b.is_visible_in_tree(), "%s: %s im geöffneten Optionenmenü sichtbar" % [label, node_name])
				if b != null:
					assert_true(b.size.x >= 64.0 and b.size.y <= 64.0, "%s: %s hat eine nutzbare Form (%s)" % [label, node_name, str(b.size)])
			await press(find_button(current_screen(shell), "OptionsButton"))
			var card := rect_of(find_node(current_screen(shell), "InstructionCard") as Control)
			assert_true(card.size.y >= 240.0, "%s: die Ansagekarte behält mindestens 240 Höhe (%.0f)" % [label, card.size.y])
			assert_false(_hits_seat(shell, card), "%s: die Ansagekarte überdeckt keinen Platz" % label)


func test_longest_card_text_is_complete_and_its_actions_reachable_at_1024x768_with_24_persons() -> void:
	for locale: String in ["de", "en"]:
		var longest := _longest_card(locale)
		assert_true(int(longest["length"]) > 0, "%s: längste Karte gefunden" % locale)
		var owner := 1 if longest["variant"] == CardCatalog.WOLF else 24
		for left: bool in [false, true]:
			var label := "%s/%s/%s" % [locale, "links" if left else "rechts", longest["id"]]
			var shell := await _game24(locale, left, {owner: String(longest["id"])})
			if shell == null:
				return
			assert_eq(str(_next(shell)["kind"]), "card_window", "%s: Kartenfenster" % label)
			await _tap(shell, "RevealButton")
			for node_name: String in ["CardTextLabel", "CardGuideLabel"]:
				var l := find_node(current_screen(shell), node_name) as Label
				assert_true(l != null and l.get_line_count() > 0, "%s: %s vorhanden" % [label, node_name])
				if l == null:
					continue
				assert_eq(l.get_visible_line_count(), l.get_line_count(), "%s: %s nicht abgeschnitten (%d Zeilen)" % [label, node_name, l.get_line_count()])
				assert_false(_hits_seat(shell, clipped_rect(l)), "%s: %s überdeckt keinen Platz" % [label, node_name])
			# Langer Text scrollt, Pflichtaktionen bleiben ohne Scrollen sichtbar.
			var scroll := find_node(current_screen(shell), "Scroll") as ScrollContainer
			for node_name: String in ["CardPlayButton", "CardKeepButton", "CardShowButton", "CardCloseWindowButton"]:
				var b := find_button(current_screen(shell), node_name)
				assert_true(b != null, "%s: %s vorhanden" % [label, node_name])
				if b != null:
					assert_true(await _reachable(shell, b), "%s: %s fest sichtbar" % [label, node_name])
					assert_false(_hits_seat(shell, rect_of(b)), "%s: %s überdeckt keinen Platz" % [label, node_name])
			scroll.scroll_vertical = 100000
			await frames(2)
			for node_name: String in ["CardPlayButton", "CardKeepButton"]:
				assert_true(await _reachable(shell, find_button(current_screen(shell), node_name)), "%s: %s bleibt beim Scrollen sichtbar" % [label, node_name])


func test_target_selection_with_24_persons_is_operable_for_both_hands_and_with_a_save_error() -> void:
	for left: bool in [false, true]:
		var label := "links" if left else "rechts"
		var shell := await _game24("de", left, {24: PICK_CARD})
		if shell == null:
			return
		var ctx := context_of(shell) as AppContext
		await _tap(shell, "RevealButton")
		if left:
			ctx.saves.simulate_failure = &"write"  # Der nächste Befehl kann nicht gespeichert werden: Fehlermeldung bleibt, das Spiel läuft weiter.
		assert_true(await _tap(shell, "CardPlayButton"), "%s: Karte spielen" % label)
		assert_eq(str(_next(shell)["kind"]), "prompt", "%s: Zielauswahl offen" % label)
		await _tap(shell, "RevealButton")
		var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
		var ring_node := find_node(current_screen(shell), "SeatRing") as Control
		var allowed: Array = _next(shell)["allowed_ids"]
		assert_false(allowed.is_empty(), "%s: wählbare Personen vorhanden" % label)
		var tokens_allowed: Array[Control] = []
		for id: Variant in allowed:
			var token := ring_node.call("token_for", int(id)) as BaseButton
			assert_true(token != null and not token.disabled and token.is_visible_in_tree(), "%s: Platz %d antippbar" % [label, int(id)])
			if token == null:
				continue
			for part: Rect2 in seat_parts(token):
				assert_true(inside(part, viewport), "%s: Platz %d im sichtbaren Bereich" % [label, int(id)])
			tokens_allowed.append(token)
		for i: int in tokens_allowed.size():
			for j: int in range(i + 1, tokens_allowed.size()):
				assert_false(seats_overlap(tokens_allowed[i], tokens_allowed[j]), "%s: Plätze %d und %d überlappen nicht" % [label, i, j])
		var confirm := find_button(current_screen(shell), "ConfirmTargetsButton")
		assert_true(confirm != null and await _reachable(shell, confirm), "%s: Bestätigen fest sichtbar" % label)
		if confirm != null:
			for token: Control in tokens_allowed:
				assert_false(seat_hits_rect(token, rect_of(confirm)), "%s: Bestätigen verdeckt keinen Platz" % label)
		if left:
			var status := find_node(current_screen(shell), "SaveStatusLabel") as Label
			assert_eq(status.text, "Fehler: nicht gespeichert", "%s: Speicherfehler sichtbar" % label)
			assert_true(status.is_visible_in_tree() and inside(rect_of(status), viewport), "%s: Fehlermeldung im sichtbaren Bereich" % label)
			var retry := find_button(current_screen(shell), "RetrySaveButton")
			assert_true(retry != null and retry.is_visible_in_tree() and rect_of(retry).size.y >= 47.5, "%s: erneut speichern erreichbar" % label)
			if confirm != null and retry != null:
				assert_false(overlaps(rect_of(status), rect_of(confirm)) or overlaps(rect_of(retry), rect_of(confirm)), "%s: Fehlermeldung verdeckt Bestätigen nicht" % label)
		var target := int(allowed[0])
		await press(ring_node.call("token_for", target) as BaseButton)
		assert_true(await _tap(shell, "ConfirmTargetsButton"), "%s: Pflichtaktion bestätigen" % label)
		var played := CardRules.records(_state_of(shell)).filter(func(r: Dictionary) -> bool: return int(r["owner"]) == 24 and String(r["status"]) == "played")
		assert_eq(played.size(), 1, "%s: die Karte wurde trotz Speicherfehler gespielt" % label)
		assert_eq(str(_next(shell)["kind"]), "day", "%s: weiter zum Tag (%s)" % [label, JSON.stringify(_next(shell)).left(300)])
		if left:
			ctx.saves.simulate_failure = &""
