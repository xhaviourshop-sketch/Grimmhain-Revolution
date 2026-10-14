extends UiTestCase
## Flötenspieler und Rattenfänger: Die Spielleitung wählt zuerst „1 oder 2“, dann genau so viele Personen; bleibt nur eine übrig, entfällt die Frage.

const ROLES := ["rattenfaenger", "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


func _next(shell: Control) -> Dictionary:
	var view: Dictionary = (session_of(shell).call("cockpit_view") as Dictionary).get("next", {})
	return view["preview"] if str(view.get("kind")) == "begin_step" and not (view.get("preview", {}) as Dictionary).is_empty() else view


func _start(seed_charmed: Array = []) -> Control:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var shell := await spawn_shell()
	var start := Command.start_game({"round_id": "t", "seed": 11, "assignment": "manual", "players": Fixtures.players(ROLES.size()), "seat_order": [1, 2, 3, 4, 5, 6], "roles": map})
	var started: CommandResult = session_of(shell).call("submit", start)
	assert_true(started.ok, "Partie gestartet: %s" % started.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	await press(find_button(current_screen(shell), "StartNightButton"))
	var ring := find_node(current_screen(shell), "SeatRing")
	for guard: int in 6:
		if str(_next(shell).get("owner")) == "rattenfaenger":
			break
		if str(_next(shell).get("owner")) == "pack":
			await press(ring.call("token_for", 3) as BaseButton)
		else:
			await wait_seconds(0.1)
	return shell


func test_count_question_then_exactly_that_many_targets() -> void:
	var shell := await _start()
	var screen := current_screen(shell)
	var ring := find_node(screen, "SeatRing")
	assert_eq(str(_next(shell).get("owner")), "rattenfaenger", "Rattenfänger-Schritt")
	assert_true(find_button(screen, "PipeOneButton") != null and find_button(screen, "PipeTwoButton") != null, "Frage mit zwei Knöpfen")
	await press(ring.call("token_for", 4) as BaseButton)
	assert_eq(str(_next(shell).get("owner")), "rattenfaenger", "vor der Zahl zählt kein Tippen")
	assert_true(find_node(screen, "PipeTwoButton") != null, "Frage steht noch")
	await press(find_button(screen, "PipeTwoButton"))
	assert_true(find_node(screen, "PipeTwoButton") == null, "Frage ist beantwortet")
	await press(ring.call("token_for", 4) as BaseButton)
	assert_eq(str(_next(shell).get("owner")), "rattenfaenger", "eine Person reicht bei „Zwei“ nicht")
	await press(ring.call("token_for", 5) as BaseButton)
	assert_ne(str(_next(shell).get("owner")), "rattenfaenger", "zwei Personen gelten sofort")
