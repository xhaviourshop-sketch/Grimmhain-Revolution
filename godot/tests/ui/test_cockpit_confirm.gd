extends UiTestCase
## Zweite Bestätigung: Jede Entscheidung der Spielleitung zeigt erst eine Zusammenfassung; erst „Bestätigen“ sendet den Befehl.

const ROLES := ["werwolf", "trugbilderwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "kutscher"]
const SEATS: Array[int] = [3, 1, 4, 7, 2, 6, 5]


func _shell() -> Control:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var players := Fixtures.players(ROLES.size())
	players[6]["name"] = "Gerda"
	var shell := await spawn_shell()
	var start := Command.start_game({"round_id": "t", "seed": 11, "assignment": "manual", "players": players, "seat_order": SEATS, "roles": map,
		"appearances": {"2": "dorfbewohner"}})
	var result: CommandResult = session_of(shell).call("submit", start)
	assert_true(result.ok, "Partie gestartet (%s)" % result.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	CockpitScreen.confirm_actions = true
	return shell


func _count(shell: Control) -> int:
	return int((session_of(shell).call("view") as Dictionary)["command_count"])


func test_target_choice_asks_before_sending_and_back_discards_it() -> void:
	var shell := await _shell()
	if shell == null:
		return
	var screen := current_screen(shell)
	await press(find_button(screen, "StartNightButton"))
	var before := _count(shell)
	var ring := find_node(screen, "SeatRing")
	await press(ring.call("token_for", 7) as BaseButton)
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog.call("is_open"), "Zusammenfassung erscheint")
	assert_eq(_count(shell), before, "noch kein Befehl gesendet")
	var message := find_node(dialog, "MessageLabel") as Label
	assert_true(message.text.contains("Gerda"), "Name der gewählten Person steht in der Zusammenfassung: %s" % message.text)
	await press(find_node(dialog, "CancelButton") as BaseButton)
	assert_eq(_count(shell), before, "Zurück sendet nichts")
	await press(ring.call("token_for", 7) as BaseButton)
	assert_true(dialog.call("is_open"), "erneute Wahl fragt wieder")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_eq(_count(shell), before + 1, "Bestätigen sendet genau einen Befehl")


func test_confirm_off_sends_immediately() -> void:
	var shell := await _shell()
	if shell == null:
		return
	CockpitScreen.confirm_actions = false
	var screen := current_screen(shell)
	await press(find_button(screen, "StartNightButton"))
	var before := _count(shell)
	await press(find_node(screen, "SeatRing").call("token_for", 7) as BaseButton)
	assert_eq(_count(shell), before + 1, "ohne Bestätigung gilt die Wahl sofort")


func test_yes_no_choice_names_the_answer() -> void:
	var shell := await _shell()
	if shell == null:
		return
	var screen := current_screen(shell)
	var ring := find_node(screen, "SeatRing")
	var dialog := shell.call("get_dialog") as Control
	await press(find_button(screen, "StartNightButton"))
	for seat: int in [7, 6]:  # Schutz, dann Rudelopfer; jede Wahl braucht ihr Bestätigen
		await press(ring.call("token_for", seat) as BaseButton)
		await press(find_node(dialog, "ConfirmButton") as BaseButton)
		await wait_seconds(0.7)  # Sperre nach „Bestätigen“
	var before := _count(shell)
	await press(find_button(screen, "NoButton"))
	assert_true(dialog.call("is_open"), "auch Ja oder Nein wird zusammengefasst")
	assert_eq(_count(shell), before, "noch nichts gesendet")
	var message := find_node(dialog, "MessageLabel") as Label
	assert_true(message.text.contains(tr("ui.cockpit.action.no.waldhexe.heal")), "die gewählte Antwort steht dort: %s" % message.text)
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_true(_count(shell) > before, "Bestätigen sendet die Antwort")
