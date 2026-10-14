extends UiTestCase
## Waldhexe und Classic-Hexe sehen das Rudelopfer als große Rollenkarte; nach der Rettung steht der Name groß unter der Karte.

const ROLES := ["werwolf", "trugbilderwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "kutscher"]
const SEATS: Array[int] = [3, 1, 4, 7, 2, 6, 5]


func test_victim_card_before_and_name_below_after_healing() -> void:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var players := Fixtures.players(ROLES.size())
	players[5]["name"] = "Berta"
	var shell := await spawn_shell()
	var start := Command.start_game({"round_id": "t", "seed": 11, "assignment": "manual", "players": players, "seat_order": SEATS, "roles": map,
		"appearances": {"2": "dorfbewohner"}})
	assert_true((session_of(shell).call("submit", start) as CommandResult).ok, "Partie gestartet")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var screen := current_screen(shell)
	var ring := find_node(screen, "SeatRing")
	await press(find_button(screen, "StartNightButton"))
	for seat: int in [7, 6]:
		await press(ring.call("token_for", seat) as BaseButton)
	await press(find_button(screen, "ShowCardButton"))
	var layer := find_node(screen, "ShowLayer")
	assert_true(layer != null and find_node(layer, "ShowRoleCard") != null, "Rollenkarte des Opfers vor der Entscheidung")
	assert_true(find_node(layer, "ShowName") == null, "noch ohne Namen")
	await press(find_button(screen, "CloseLayerButton"))
	await press(find_button(screen, "YesButton"))
	await press(find_button(screen, "ShowCardButton"))
	layer = find_node(screen, "ShowLayer")
	var column := find_node(layer, "BareContent")
	var names: Array[String] = []
	for child: Node in column.get_children():
		names.append(String(child.name))
	assert_true(names.find("ShowRoleCard") >= 0 and names.find("ShowName") > names.find("ShowRoleCard"), "Name steht unter der Karte: %s" % str(names))
	assert_true(text_of(find_node(layer, "ShowName") as Control).contains("Berta"), "Name des Opfers")
