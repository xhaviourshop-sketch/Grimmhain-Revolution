extends UiTestCase
## Vollständige Partie nur über die Oberfläche: Nach dem Start tippt der Test ausschließlich sichtbare
## Buttons der Ansagekarte, Plätze im Sitzkreis und Dialogaktionen an (kein Befehl direkt an die
## Sitzung). Er spielt Nächte, Morgenberichte, Reaktionen, Nominierungen und Hinrichtungen, bis der
## Sieg bestätigt ist. Die Entscheidungen trifft der Test wie ein Spielleiter nach den Karten.

const ROLES := ["werwolf", "werwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner", "dorfbewohner"]
const MAX_ACTIONS := 400

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
	var b := _button(shell, node_name)
	if b == null:
		return false
	_trace.append(node_name)
	await press(b)
	return true


## Tippt freie, antippbare Plätze (in Sitzreihenfolge), bis `count` gewählt sind.
func _tap_seats(shell: Control, count: int, skip: Array = []) -> void:
	var tapped := 0
	for token: Variant in find_node(current_screen(shell), "SeatRing").call("tokens"):
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
		if await _dialog_confirm(shell):
			continue
		var next: Dictionary = view["next"]
		var acted := false
		for name: String in ["RevealButton", "StartNightButton", "BeginStepButton", "ContinueDayButton", "EndNightButton", "EndDayButton", "AckButton"]:
			if await _tap(shell, name):
				acted = true
				break
		if acted:
			continue
		if str(next["kind"]) == "win_decision":
			acted = await _tap(shell, "ConfirmWinButton_%d" % int((next["candidates"] as Array)[0]["id"]))
		elif str(next["kind"]) == "prompt":
			match str(next["answer"]):
				"choice":
					acted = await _tap(shell, "NoButton")
				"targets":
					var need := maxi(int(next["min"]), 1)
					await _tap_seats(shell, need)
					acted = await _tap(shell, "ConfirmTargetsButton")
					if not acted:
						acted = await _tap(shell, "DeclineButton")
		elif str(next["kind"]) == "day":
			acted = await _play_day(shell, next)
		if not acted:
			fail("Schritt %d: keine bedienbare Aktion für %s (%s)" % [step, next["kind"], _trace.slice(-6)])
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
	if not await _tap(shell, "ConfirmExecutionTargetButton"):
		return false
	if not await _tap(shell, "RevealButton"):
		return false
	return await _tap(shell, "ConfirmExecutionButton")
