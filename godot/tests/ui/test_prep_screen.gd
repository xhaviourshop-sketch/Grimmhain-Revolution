extends UiTestCase
## Vorbereitung „Neue Partie“ über echte Buttons (DA-89): drei Schritte in beiden Modi bis zum Cockpit, Weiter erst bei vollständigen Namen,
## Zurück verliert nichts, im Kartenmodus startet erst die vollständige Zuordnung. Keine Positions- oder Aussehenstests (das prüfen Screenshots).

const SEED := 20261003


func _next(screen: Control) -> BaseButton:
	return find_button(screen, "NextButton")


func test_random_mode_goes_from_round_to_cockpit_in_three_steps() -> void:
	var shell := await spawn_shell(SIZE_4_3)
	if shell == null:
		return
	var screen := await prepare_through_buttons(shell, 9, &"akt2", SEED)
	assert_eq(String((setup_of(shell).call("view") as Dictionary)["step"]), "roles", "dritter Schritt")
	assert_eq(int((setup_of(shell).call("view") as Dictionary)["count"]), 9, "neun Namen")
	assert_false(_next(screen).disabled, "Spiel starten ist möglich")
	await press(_next(screen))
	await frames(3)
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit nach dem Start")
	var commands: Array = session_of(shell).call("commands")
	assert_eq(commands.size(), 1, "genau ein StartGame")
	assert_eq(commands[0].payload["players"].size(), 9, "neun Personen")


func test_next_needs_all_names_and_back_loses_nothing() -> void:
	var shell := await spawn_shell(SIZE_4_3)
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var setup := setup_of(shell)
	await press(find_button(screen, "NextButton"))
	assert_eq(String((setup.call("view") as Dictionary)["step"]), "names", "Namen")
	assert_true(_next(screen).disabled, "ohne Namen kein Weiter")
	var count := int((setup.call("view") as Dictionary)["player_count"])
	for i: int in count - 1:
		setup.call("add_person", "Person %d" % (i + 1))
	await frames(2)
	assert_true(_next(screen).disabled, "ein Name fehlt: kein Weiter")
	setup.call("add_person", "Letzte Person")
	await frames(2)
	assert_false(_next(screen).disabled, "alle Namen: Weiter möglich")
	await press(_next(screen))
	var before := JSON.stringify((setup.call("view") as Dictionary)["roles"]["counts"])
	await press(find_button(screen, "BackStepButton"))
	await press(find_button(screen, "BackStepButton"))
	assert_eq(String((setup.call("view") as Dictionary)["step"]), "round", "zurück in der Runde")
	assert_eq(int((setup.call("view") as Dictionary)["count"]), count, "Namen bleiben")
	await press(_next(screen))
	await press(_next(screen))
	assert_eq(JSON.stringify((setup.call("view") as Dictionary)["roles"]["counts"]), before, "Rollenauswahl bleibt")


func test_real_cards_mode_starts_only_when_everyone_is_assigned() -> void:
	var shell := await spawn_shell(SIZE_4_3)
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var setup := setup_of(shell)
	setup.set("seed_source", func() -> int: return SEED)
	await press(find_button(screen, "ManualModeButton"))
	assert_eq(String((setup.call("view") as Dictionary)["mode"]), "manual", "Echte Karten")
	await press(_next(screen))
	for i: int in int((setup.call("view") as Dictionary)["player_count"]):
		setup.call("add_person", "Person %d" % (i + 1))
	await frames(2)
	await press(_next(screen))
	await press(find_button(screen, "ProposalButton"))  # Schritt 3 startet leer: „Empfehlung übernehmen“
	await press(_next(screen))  # Weiter zur Zuordnung
	var ring := find_node(screen, "SeatRing")
	var persons: Array = (setup.call("view") as Dictionary)["persons"]
	for i: int in persons.size():
		assert_true(_next(screen).disabled, "Platz %d: noch nicht alle zugeordnet, kein Start" % (i + 1))
		await press(ring.call("token_for", int(persons[i]["person_id"])) as BaseButton)
		var chips := find_node(screen, "RoleBarChips").get_children()
		assert_false(chips.is_empty(), "Rollenleiste zeigt Rollen")
		await press(chips[0] as BaseButton)
	assert_false(_next(screen).disabled, "alle zugeordnet: Spiel starten")
	var chosen := {}
	for entry: Dictionary in (setup.call("view") as Dictionary)["distribution"]["assignment"]:
		chosen[str(int(entry["person_id"]))] = str(entry["role"])
	await press(_next(screen))
	await frames(3)
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit nach dem Start")
	var commands: Array = session_of(shell).call("commands")
	assert_eq(commands[0].payload["roles"], chosen, "gestartet mit der eingetragenen Zuordnung")


func _counts(shell: Control) -> Dictionary:
	return (setup_of(shell).call("view") as Dictionary)["roles"]["counts"]


## Schritt 3 als Kachelraster (DA-91): startet leer, Antippen schaltet an und aus, Werwolf zählt mit − und +, Zähler und Kopfzeile stimmen,
## „Empfehlung übernehmen“ füllt auf die Personenzahl. Keine Positions- oder Aussehenstests.
func test_role_tiles_start_empty_toggle_count_and_recommendation_fills() -> void:
	var shell := await spawn_shell(SIZE_4_3)
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var setup := setup_of(shell)
	setup.set("seed_source", func() -> int: return SEED)
	await press(find_button(screen, "ActCard_akt1"))
	await press(_next(screen))
	for i: int in int((setup.call("view") as Dictionary)["player_count"]):
		setup.call("add_person", "Person %d" % (i + 1))
	await frames(2)
	await press(_next(screen))
	var target := int((setup.call("view") as Dictionary)["player_count"])
	assert_eq(int((setup.call("view") as Dictionary)["roles"]["total"]), 0, "0 Rollen beim Öffnen")
	assert_eq((find_node(screen, "SelectedCount") as Label).text, "0 / %d Rollen gewählt" % target, "Kopfzeile")
	assert_eq(find_node(screen, "Warnings").get("visible"), false, "keine Warnungen ohne Rolle")
	assert_true(find_node(screen, "Tile_dorfbewohner") == null, "kein Dorfbewohner als Kachel")
	await press(find_button(screen, "Tile_schutzengel"))
	assert_eq(int(_counts(shell)["schutzengel"]), 1, "Antippen wählt an")
	await press(find_button(screen, "Tile_schutzengel"))
	assert_eq(int(_counts(shell)["schutzengel"]), 0, "nochmal Antippen wählt ab")
	await press(find_button(screen, "Tile_werwolf"))
	assert_eq(int(_counts(shell)["werwolf"]), 1, "Werwolf gewählt")
	assert_true(find_node(find_button(screen, "Tile_die_gebundenen"), "StepPlus") == null, "− und + nur auf einer gewählten Kachel")
	await press(find_button(screen, "StepPlus"))
	await press(find_button(screen, "StepPlus"))
	assert_eq(int(_counts(shell)["werwolf"]), 3, "drei Werwölfe")
	assert_eq((find_node(screen, "SelectedCount") as Label).text, "3 / %d Rollen gewählt" % target, "Kopfzeile zählt Kopien")
	assert_eq(int((find_node(find_node(screen, "RolePoolView"), "TeamCounter_wolves") as TeamCounter).value()), 3, "Zähler Wölfe")
	await press(find_button(screen, "StepMinus"))
	assert_eq(int(_counts(shell)["werwolf"]), 2, "minus nimmt eine Kopie")
	await press(find_button(screen, "Tile_werwolf"))
	assert_eq(int(_counts(shell)["werwolf"]), 0, "Antippen einer gewählten Kachel wählt alle Kopien ab")
	await press(find_button(screen, "ProposalButton"))
	assert_eq(int((setup.call("view") as Dictionary)["roles"]["total"]), target, "Empfehlung füllt auf die Personenzahl")
	assert_true(bool((setup.call("view") as Dictionary)["roles"]["is_suggestion"]), "Auswahl = Empfehlung")
