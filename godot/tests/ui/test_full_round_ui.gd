extends UiTestCase
## Vollständige Partie nur über die Oberfläche: Nach dem Start tippt der Test ausschließlich sichtbare
## Buttons der Ansagekarte, Plätze im Sitzkreis und Dialogaktionen an (kein Befehl direkt an die
## Sitzung). Er spielt Nächte, Morgenberichte, Reaktionen, Nominierungen und Hinrichtungen, bis der
## Sieg bestätigt ist. Die Entscheidungen trifft der Test wie ein Spielleiter nach den Karten.
## PE-07: Zusätzlich läuft der Weg von „Neue Partie“ (Namen erfassen, automatischen Vorschlag übernehmen, Scheinrolle bestätigen,
## verteilen, Sitzordnung, Start) über echte Buttons bis zur ersten Nacht, zum Morgenbericht und zu einer Nominierung am Tag.

const ROLES := ["werwolf", "blutwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner", "amalia"]
const MAX_ACTIONS := 400
const SETUP_SEED := 20260930

var _trace: Array[String] = []


func _start(shell: Control) -> void:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var r: CommandResult = session_of(shell).call("submit", Command.start_game({"round_id": "r", "seed": 9, "assignment": "manual",
		"players": Fixtures.players(ROLES.size()), "seat_order": [2, 5, 1, 7, 3, 8, 4, 6], "roles": map}))
	assert_true(r.ok, "Start")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")


func _button(shell: Control, node_name: String) -> BaseButton:
	var b := current_screen(shell).find_child(node_name, true, false) as BaseButton
	return b if b != null and b.is_visible_in_tree() and not b.disabled else null


func _tap(shell: Control, node_name: String) -> bool:
	await tool_button(current_screen(shell), node_name)  # Werkzeuge im Optionenmenü: erst die Lasche öffnen
	var b := _button(shell, node_name)
	if b == null:
		return false
	_trace.append(node_name)
	await press(b)
	return true


## Tippt freie, antippbare Plätze (in Sitzreihenfolge, `prefer` zuerst), bis `count` gewählt sind.
func _tap_seats(shell: Control, count: int, skip: Array = [], prefer: Array = []) -> void:
	var tapped := 0
	var tokens: Array = find_node(current_screen(shell), "SeatRing").call("tokens")
	tokens.sort_custom(func(a: Variant, b: Variant) -> bool: return prefer.has(int(a.get("person_id"))) and not prefer.has(int(b.get("person_id"))))
	for token: Variant in tokens:
		var t := token as Button
		if tapped >= count:
			return
		if t.disabled or skip.has(int(t.get("person_id"))) or t.theme_type_variation == &"SeatSelectedButton":
			continue
		_trace.append("seat %d" % int(t.get("person_id")))
		await press(t)
		tapped += 1


func _dialog_confirm(shell: Control) -> bool:
	var dialog := shell.call("get_dialog") as Control
	if not dialog.call("is_open"):
		return false
	var confirm := find_node(dialog, "ConfirmButton") as BaseButton
	if confirm.visible and not confirm.disabled:
		_trace.append("dialog confirm")
		await press(confirm)
		return true
	var field := find_node(dialog, "InputField") as LineEdit
	if field.visible:
		await type_text(field, "Testlauf")
		await press(confirm)
		return true
	return false


## Eine Aktion nach den Kartendaten: Dialog bestätigen, Kartenbutton, Ziele wählen oder Tagesaktion. Wahr, wenn etwas bedient wurde.
func _act(shell: Control) -> bool:
	if await _dialog_confirm(shell):
		return true
	var next: Dictionary = effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])
	if str(next["kind"]) == "notice":
		return await _tap(shell, "ShowNoticeButton") and await _tap(shell, "CloseLayerButton")  # Schließen bestätigt den Hinweis
	if await _tap(shell, "ShowCardButton"):
		return await _tap(shell, "CloseLayerButton")  # Schließen erledigt die Auskunft
	for name: String in ["RevealButton", "StartNightButton", "BeginStepButton", "ContinueDayButton", "EndNightButton", "EndDayButton", "AckButton"]:
		if await _tap(shell, name):
			return true
	if str(next["kind"]) == "win_decision":
		return await _tap(shell, "ConfirmWinButton_%d" % int((next["candidates"] as Array)[0]["id"]))
	if str(next["kind"]) == "prompt":
		match str(next["answer"]):
			"choice":
				# Bestätigungsstufen (z. B. Lehrling) mit „Ja“, sonst „Nein“ (Trank nicht einsetzen, Fähigkeit nicht nutzen).
				if str(next["stage"]) == "confirm" and await _tap(shell, "YesButton"):
					return true
				return await _tap(shell, "NoButton")
			"option":
				return await _tap(shell, "OptionButton_0")
			"targets":
				var counts: Array = next.get("counts", [])
				var need := maxi(int(counts[0]) if not counts.is_empty() else int(next["min"]), 1)
				# Der Traumdeuter nennt drei Personen, darunter mindestens einen Wolf: die Spielleitung kennt die Wölfe.
				var wolves: Array = []
				if str(next["owner"]) == "traumdeuter":
					var state := RulesEngine.replay((session_of(shell) as GameSession).commands()).state
					wolves = state.alive_ids().filter(func(id: int) -> bool: return state.players[id].counts_as_wolf)
				if str(next["owner"]) == "loki":
					await _tap(shell, "YesButton")  # Loki: erst Liebende oder Rivalen, dann die zwei Personen
				await _tap_seats(shell, need, [], wolves)
				if CockpitText.auto_commit(next):
					return true  # eine feste Anzahl gilt sofort
				if await _tap(shell, "ConfirmTargetsButton"):
					return true
				return await _tap(shell, "DeclineButton")
	if str(next["kind"]) == "day":
		return await _play_day(shell, next)
	return false


func test_complete_game_through_buttons_only() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	await _start(shell)
	var nights_seen := {}
	for step: int in MAX_ACTIONS:
		var view: Dictionary = session_of(shell).call("cockpit_view")
		if str(view["phase"]) == "GAME_OVER":
			assert_true(str((view["next"] as Dictionary)["kind"]) == "game_over", "Spielende-Karte")
			assert_true(nights_seen.size() >= 2, "mindestens zwei Nächte gespielt (%d)" % nights_seen.size())
			print("      Partie über Buttons: %d Aktionen, %d Nächte" % [_trace.size(), nights_seen.size()])
			return
		nights_seen[int(view["night_number"])] = true
		if not await _act(shell):
			fail("Schritt %d: keine bedienbare Aktion für %s (%s)" % [step, (view["next"] as Dictionary)["kind"], _trace.slice(-6)])
			return
	fail("Partie nach %d Aktionen nicht beendet" % MAX_ACTIONS)


## Tag: erst eine Nominierung (Personen in Sitzreihenfolge), dann die Hinrichtung der Nominierten.
func _play_day(shell: Control, next: Dictionary) -> bool:
	if (next["nominations"] as Array).is_empty():
		if not await _tap(shell, "NominateButton"):
			return false
		await _tap_seats(shell, 1)
		await _tap_seats(shell, 1)
		return await _tap(shell, "ConfirmNominationButton")
	if not await _tap(shell, "ExecuteButton"):
		return await _tap(shell, "NoExecutionButton")
	await _tap_seats(shell, 1)
	return await _tap(shell, "ConfirmExecutionButton")


# --- PE-07: von „Neue Partie“ bis zum ersten Tag über echte Buttons --------------------------------------------

## Vorbereitung nur über sichtbare Buttons (Spielerzahl, Akt III, Namen per Einfügen, Spiel starten). Nur die Seed-Quelle ist fest.
## Liefert die Startdaten des Setups unmittelbar vor dem Start.
func _new_game_through_buttons(shell: Control, count: int, act: StringName = &"akt3") -> Dictionary:
	var screen := await prepare_through_buttons(shell, count, act, SETUP_SEED)
	var setup := setup_of(shell) as PlayerSetup
	assert_eq(int(((setup.view() as Dictionary)["roles"] as Dictionary)["total"]), count, "Vorschlag passt zur Personenzahl")
	assert_false(find_button(screen, "NextButton").disabled, "%d: Spiel starten möglich" % count)
	var data := setup.prepare_start()  # verteilt mit dem gespeicherten Seed; „Spiel starten“ ergibt dieselbe Zuordnung
	assert_true(data.ok, "%d: Startdaten vollständig" % count)
	await press(find_button(screen, "NextButton"))
	await frames(3)
	assert_eq(String(current_id(shell)), "cockpit", "%d: Cockpit geöffnet" % count)
	return data.details


## Prüft die gestartete Partie gegen die Startdaten des Setups: genau ein StartGame mit denselben Rollen, IDs und Sitzordnung,
## keine zweite Verteilung (kein Zufall im Kern), jede Rolle höchstens einmal.
func _check_started_game(shell: Control, details: Dictionary, count: int) -> void:
	var session := session_of(shell) as GameSession
	var commands := session.commands()
	assert_eq(commands.size(), 1, "%d: genau ein StartGame" % count)
	var payload := commands[0].payload
	assert_eq(payload["roles"], details["roles"], "%d: dieselben Rollen je Personen-ID" % count)
	assert_eq(payload["seat_order"], details["seat_order"], "%d: dieselbe Sitzordnung" % count)
	assert_eq(payload["assignment"], "manual", "%d: feste Zuordnung, keine Verteilung im Kern" % count)
	var state := RulesEngine.replay(commands).state
	assert_eq(state.rng.draws, 0, "%d: keine zweite Rollenverteilung beim Start (keine Ziehung)" % count)
	assert_eq(state.alive_ids(), Fixtures.identity_order(count), "%d: Personen-IDs 1 bis %d" % [count, count])
	var seen := {}
	for id: int in state.alive_ids():
		assert_false(seen.has(state.players[id].role_id), "%d: %s höchstens einmal" % [count, state.players[id].role_id])
		seen[state.players[id].role_id] = true
	assert_eq(seen.keys().size(), count, "%d: verschiedene Rollen" % count)
	var wolves := state.alive_ids().filter(func(id: int) -> bool: return state.players[id].counts_as_wolf).size()
	assert_true(wolves >= RoleSuggestion.wolf_count(count), "%d: mindestens die Wolfsrollen der Staffel (kleine Akte füllen mit weiteren auf)" % count)


## Spielt über Buttons bis `stop` wahr ist; false bei nicht bedienbarer Karte oder ohne Ende.
func _play_until(shell: Control, stop: Callable, label: String) -> bool:
	for step: int in MAX_ACTIONS:
		if stop.call(session_of(shell).call("cockpit_view")):
			return true
		if not await _act(shell):
			var card: Dictionary = effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])
			fail("%s: keine bedienbare Aktion bei %s/%s/%s/%s (%s)" % [label, card["kind"], card.get("owner", ""), card.get("stage", ""), card.get("answer", ""), _trace.slice(-6)])
			return false
	fail("%s: Ziel nach %d Aktionen nicht erreicht (zuletzt: %s)" % [label, MAX_ACTIONS, _trace.slice(-10)])
	return false


## Erste Nacht, Morgenbericht und eine Nominierung am Tag über Buttons (Tagesaktion nach dem Morgen).
func _first_night_morning_and_nomination(shell: Control, count: int) -> void:
	var day_reached := func(view: Dictionary) -> bool: return str(view["phase"]) == "DAY" and _button(shell, "NominateButton") != null
	if not await _play_until(shell, day_reached, "%d: erste Nacht bis Tag" % count):
		return
	var session := session_of(shell) as GameSession
	var report: Dictionary = session.morning_report()
	assert_true(not (report["public"] as Dictionary).is_empty(), "%d: Morgenbericht vorhanden" % count)
	assert_eq(int((session.cockpit_view() as Dictionary)["night_number"]), 1, "%d: nach der ersten Nacht" % count)
	var before := session.commands().size()
	var next: Dictionary = (session.cockpit_view() as Dictionary)["next"]
	assert_true((next["nominations"] as Array).is_empty(), "%d: noch keine Nominierung" % count)
	assert_true(await _play_day(shell, next), "%d: Nominierung über Buttons" % count)
	assert_true(session.commands().size() > before, "%d: Nominierung wurde angenommen" % count)
	assert_eq(((session.cockpit_view() as Dictionary)["next"] as Dictionary)["nominations"].size(), 1, "%d: genau eine Nominierung heute" % count)


func test_new_game_small_round_from_setup_to_first_day() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var details := await _new_game_through_buttons(shell, 6, &"akt1")
	_check_started_game(shell, details, 6)
	# Der Vorschlag von Akt I für 6 Personen wird gestartet, wie er ist.
	var roles: Array = (details["roles"] as Dictionary).values()
	roles.sort()
	var proposal: Array = []
	for key: String in RoleSuggestion.for_act(&"akt1", 6):
		if int(RoleSuggestion.for_act(&"akt1", 6)[key]) > 0:
			proposal.append(key)
	proposal.sort()
	assert_eq(roles, proposal, "Rollen des Vorschlags für 6 Personen")
	await _first_night_morning_and_nomination(shell, 6)


## 13 Personen: die Stufe mit drei Wolfsrollen, darunter der Trugbilderwolf mit seiner Scheinrolle aus dem Auswahldialog.
func test_new_game_at_a_wolf_tier_boundary_with_decoy_wolf() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var details := await _new_game_through_buttons(shell, 13)
	_check_started_game(shell, details, 13)
	assert_eq((details["appearances"] as Dictionary).size(), 1, "eine vorbelegte Scheinrolle (DA-88)")
	var state := RulesEngine.replay((session_of(shell) as GameSession).commands()).state
	for id: int in state.alive_ids():
		if state.players[id].role_id == &"trugbilderwolf":
			assert_eq(String(state.players[id].appears_as), str(details["appearances"][str(id)]), "Scheinrolle wie im Setup festgelegt")
			assert_true(SetupRoleCatalog.is_village(state.players[id].appears_as), "vorbelegt mit einer Dorfrolle")
	await _first_night_morning_and_nomination(shell, 13)


func test_new_game_with_24_persons_starts_and_plays_a_night() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var details := await _new_game_through_buttons(shell, 24)
	_check_started_game(shell, details, 24)
	await _first_night_morning_and_nomination(shell, 24)


## Speichern und Fortsetzen einer gültigen neuen Partie sowie Rückgängig nach einer repräsentativen Aktion (über Buttons).
func test_new_game_can_be_saved_resumed_and_undone() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var details := await _new_game_through_buttons(shell, 8, &"akt1")
	_check_started_game(shell, details, 8)
	var context := context_of(shell) as AppContext
	var session := session_of(shell) as GameSession
	# Bis zur ersten Antwort des Rudels spielen; der Autosave läuft nach jedem angenommenen Befehl.
	var prompt_reached := func(view: Dictionary) -> bool: return str((view["next"] as Dictionary)["kind"]) == "prompt"
	if not await _play_until(shell, prompt_reached, "erste Antwort"):
		return
	var round_id := session.round_id()
	var hash_before := session.state_hash()
	var commands_before := session.commands().size()
	var fresh := AppContext.new()
	fresh.saves.base_dir = context.saves.base_dir
	var resumed := fresh.resume(round_id)
	assert_true(bool(resumed["ok"]), "Fortsetzen der neuen Partie (%s)" % str(resumed.get("error", "")))
	assert_eq(fresh.session.state_hash(), hash_before, "gleicher Zustand nach dem Fortsetzen")
	assert_eq(fresh.session.commands().size(), commands_before, "gleicher Befehlsverlauf, kein zweiter Start")
	assert_eq(JSON.stringify((fresh.session.cockpit_view() as Dictionary)["next"]), JSON.stringify((session.cockpit_view() as Dictionary)["next"]), "gleiche nächste Handlung")
	# Rückgängig nach einer repräsentativen Aktion (das Rudel wählt): Spielleiterwerkzeug → Rückgängig → Bestätigen.
	await _tap_seats(shell, 1)  # eine feste Anzahl gilt sofort, kein Bestätigen
	var after_answer := session.commands().size()
	assert_eq(after_answer, commands_before + 1, "ein Befehl mehr")
	assert_true(await _tap(shell, "GmButton"), "Spielleiterwerkzeuge")
	assert_true(await _tap(shell, "UndoButton"), "Rückgängig")
	await _dialog_confirm(shell)
	assert_eq(session.commands().size(), commands_before, "genau die Antwort zurückgenommen")
	assert_eq(session.state_hash(), hash_before, "Zustand wie vor der Antwort")
	assert_eq(session.commands()[0].payload["roles"], details["roles"], "Rollen und Personen-IDs unverändert")
