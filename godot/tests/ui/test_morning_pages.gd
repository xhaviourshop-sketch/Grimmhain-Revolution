extends UiTestCase
## F-20: Ein langer Morgenbericht scrollt nie, sondern steht in Seiten („Weiter“, „Seite 1 von 2“); nichts wird abgeschnitten.

const ROLES := ["werwolf", "blutwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner", "amalia"]


func _morning(lines: int) -> Dictionary:
	var notices: Array = []
	for i: int in lines:
		notices.append({"key": "ui.morning.read.intro"})
	return {"kind": "morning", "night_number": 1, "secret": false, "public": {"deaths": [], "notices": notices}, "private": []}


func test_long_morning_report_is_paged_not_scrolled() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var r: CommandResult = session_of(shell).call("submit", Command.start_game({"round_id": "r", "seed": 9, "assignment": "manual",
		"players": Fixtures.players(ROLES.size()), "seat_order": [2, 5, 1, 7, 3, 8, 4, 6], "roles": map}))
	assert_true(r.ok, "Start")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var screen := current_screen(shell)
	var card := find_node(screen, "ActionCard")
	var context: Dictionary = card.get("_last_context")
	card.call("render", _morning(1), context)
	await frames(20)
	assert_true(find_node(screen, "ContinueDayButton") != null and find_node(screen, "MorningNextPageButton") == null, "kurzer Bericht: eine Seite mit „Weiter“")
	card.call("render", _morning(60), context)
	await frames(60)
	assert_true(find_node(screen, "MorningNextPageButton") != null, "langer Bericht: Seite 1 mit „Weiter“")
	assert_true(find_node(screen, "ContinueDayButton") == null, "der Tag beginnt erst auf der letzten Seite")
	assert_true(find_node(screen, "MorningPageLabel") != null, "„Seite 1 von …“ steht da")
	var scroll := find_node(card, "Scroll") as ScrollContainer
	var bar := scroll.get_v_scroll_bar()
	assert_true(bar.max_value - bar.page <= 1.0, "Seite 1 scrollt nicht")
	var guard := 0
	while find_node(screen, "MorningNextPageButton") != null and guard < 30:
		await press(find_node(screen, "MorningNextPageButton") as BaseButton)
		await frames(40)
		assert_true(bar.max_value - bar.page <= 1.0, "Seite %d scrollt nicht" % (guard + 2))
		guard += 1
	assert_true(find_node(screen, "ContinueDayButton") != null, "letzte Seite hat „Weiter“ zum Tag")
