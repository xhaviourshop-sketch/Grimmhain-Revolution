extends UiTestCase
## Vollständige Partien mit Totenreichkarten (6, 12 und 24 Personen) nur über die Oberfläche: Der Test tippt ausschließlich sichtbare
## Buttons der Ansagekarte, Plätze im Sitzkreis und Dialogaktionen an. Kartenfenster (Aufdecken, Spielen, Aufbewahren, Tauschen),
## Karteneingaben (Personen, Optionen, Ja/Nein, Würfel), Kartenschlucker-Handzeichen, Tagesregeln und die Zusatzfragen der
## Hinrichtung werden wie von einer Spielleitung bedient. Danach müssen Replay und Neuladen denselben Zustand ergeben.

const MAX_ACTIONS := 3000
const NAMES := ["Anna", "Ben", "Cara", "Dirk", "Eva", "Finn", "Gina", "Hugo", "Ida", "Jan", "Kim", "Lea", "Max", "Nina", "Otto", "Pia", "Quin", "Rosa", "Sven", "Tina", "Uwe", "Vera", "Willi", "Xenia"]

var _trace: Array[String] = []
var _played := 0
var _kept := 0
var _exchanged := 0
var _rolls := 0
var _flip := 0
var _flow_done := {}


func _start(shell: Control, count: int, wolves: Array[int], seed_value: int, specials: Dictionary = {}) -> void:
	var players: Array = []
	for i: int in count:
		players.append({"id": i + 1, "name": NAMES[i]})
	var r: CommandResult = session_of(shell).call("submit", Command.start_game({"round_id": "r%d" % count, "seed": seed_value, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(count), "roles": Fixtures.filled_roles(count, wolves, specials), "death_cards": true}))
	assert_true(r.ok, "Start %d Personen (%s)" % [count, r.error])
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


func _tap_seats(shell: Control, count: int, prefer: Array = [], skip: Array = []) -> int:
	var tapped := 0
	var tokens: Array = find_node(current_screen(shell), "SeatRing").call("tokens")
	tokens.sort_custom(func(a: Variant, b: Variant) -> bool: return prefer.has(int(a.get("person_id"))) and not prefer.has(int(b.get("person_id"))))
	for token: Variant in tokens:
		var t := token as Button
		if tapped >= count:
			return tapped
		if t.disabled or skip.has(int(t.get("person_id"))) or t.theme_type_variation == &"SeatSelectedButton":
			continue
		_trace.append("seat %d" % int(t.get("person_id")))
		await press(t)
		tapped += 1
	return tapped


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


func _state_of(shell: Control) -> GameState:
	return RulesEngine.replay((session_of(shell) as GameSession).commands()).state


## Fenster einer toten Person: aufdecken, dann abwechselnd spielen, behalten und (mit lebendem Kartenschlucker) tauschen.
func _card_window(shell: Control) -> bool:
	if await _tap(shell, "ContinueDayButton"):  # der Morgenbericht kommt vor dem ersten Kartenfenster
		return true
	if await _tap(shell, "RevealButton"):
		return true
	_flip += 1
	if _flip % 5 == 0 and await _tap(shell, "CardExchangeButton"):
		_exchanged += 1
		return true
	if _flip % 3 != 0 and await _tap(shell, "CardPlayButton"):
		_played += 1
		return true
	if await _tap(shell, "CardKeepButton"):
		_kept += 1
		return true
	if await _tap(shell, "CardPlayButton"):
		_played += 1
		return true
	return await _tap(shell, "CardCloseWindowButton")


## Zusatzfragen der Hinrichtung: Aufdecken, Entscheid des Dorfes, zweitmeiste Stimmen, Cerberus, Weiser, dann bestätigen.
func _execution_flow(shell: Control) -> bool:
	for name: String in ["RevealButton", "CerberusDefendNo", "SageCurse0", "VillageConfirmsYes", "NoRunnerUpButton", "ConfirmExecutionButton"]:
		# Eine Antwort je Hinrichtung nur einmal geben (die Buttons bleiben nach der Wahl sichtbar), die Enthüllung zählt zweimal.
		if _flow_done.get(name, 0) >= (2 if name == "RevealButton" else 1):
			continue
		if await _tap(shell, name):
			_flow_done[name] = int(_flow_done.get(name, 0)) + 1
			if name == "ConfirmExecutionButton":
				_flow_done.clear()
			return true
	return false


func _play_day(shell: Control, next: Dictionary) -> bool:
	if await _tap(shell, "ConfirmExecutionTargetButton"):
		return true
	if bool(next.get("execution_cancelled", false)):
		return await _tap(shell, "NoExecutionButton")
	if (next["nominations"] as Array).is_empty():
		if not await _tap(shell, "NominateButton"):
			return false
		var nominators: Array = next.get("nominator_ids", [])
		var tapped := await _tap_seats(shell, 1, nominators)
		if tapped == 0:
			return false
		await _tap_seats(shell, 1)
		return await _tap(shell, "ConfirmNominationButton")
	if not await _tap(shell, "ExecuteButton"):
		return await _tap(shell, "NoExecutionButton")
	await _tap_seats(shell, 1)
	if await _tap(shell, "ConfirmExecutionTargetButton"):
		return true
	return false


func _act(shell: Control) -> bool:
	if await _dialog_confirm(shell):
		return true
	var next: Dictionary = effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])
	var kind := str(next["kind"])
	if kind == "card_window":
		return await _card_window(shell)
	if str(next["kind"]) == "notice":
		return await _tap(shell, "ShowNoticeButton") and await _tap(shell, "CloseLayerButton")  # Schließen bestätigt den Hinweis
	if await _tap(shell, "ShowCardButton"):
		return await _tap(shell, "CloseLayerButton")  # Schließen erledigt die Auskunft

	if kind == "day" and await _execution_flow(shell):
		return true
	for name: String in ["RevealButton", "StartNightButton", "BeginStepButton", "ContinueDayButton", "EndNightButton", "EndDayButton", "AckButton"]:
		if await _tap(shell, name):
			return true
	if kind == "win_decision":
		return await _tap(shell, "ConfirmWinButton_%d" % int((next["candidates"] as Array)[0]["id"]))
	if kind == "prompt":
		match str(next["answer"]):
			"choice":
				if await _tap(shell, "YesButton"):
					return true
				return await _tap(shell, "NoButton")
			"roll":
				_rolls += 1
				return await _tap(shell, "RollButton")
			"option":
				return await _tap(shell, "OptionButton_0")
			"targets":
				var counts: Array = next.get("counts", [])
				var need := int(counts[0]) if not counts.is_empty() else int(next["min"])
				if str(next["owner"]) != "card":
					need = maxi(need, 1)
				var prefer: Array = []
				if str(next["owner"]) == "traumdeuter" or str(next["owner"]) == "card":
					var state := _state_of(shell)
					prefer = state.alive_ids().filter(func(id: int) -> bool: return state.players[id].counts_as_wolf)
				if str(next["owner"]) == "loki":
					await _tap(shell, "YesButton")  # Loki: erst Liebende oder Rivalen, dann die zwei Personen
				await _tap_seats(shell, need, prefer)
				if CockpitText.auto_commit(next):
					return true  # eine feste Anzahl gilt sofort
				if await _tap(shell, "ConfirmTargetsButton"):
					return true
				return await _tap(shell, "DeclineButton")
	if kind == "day":
		return await _play_day(shell, next)
	return false


func _visible_buttons(shell: Control) -> Array[String]:
	var out: Array[String] = []
	var stack: Array[Node] = [current_screen(shell)]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is BaseButton and (n as BaseButton).is_visible_in_tree():
			out.append("%s%s" % [n.name, "(aus)" if (n as BaseButton).disabled else ""])
		stack.append_array(n.get_children())
	return out


func _play_game(count: int, wolves: Array[int], seed_value: int, specials: Dictionary = {}) -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	_trace.clear()
	await _start(shell, count, wolves, seed_value, specials)
	var session := session_of(shell) as GameSession
	for step: int in MAX_ACTIONS:
		var view: Dictionary = session.call("cockpit_view")
		if str(view["phase"]) == "GAME_OVER":
			break
		if not await _act(shell):
			fail("%d Personen, Schritt %d: keine bedienbare Aktion für %s/%s/%s (%s) sichtbar: %s" % [count, step, (view["next"] as Dictionary)["kind"], (view["next"] as Dictionary).get("owner", ""), (view["next"] as Dictionary).get("stage", ""), _trace.slice(-8), _visible_buttons(shell)])
			return
	var final: Dictionary = session.call("cockpit_view")
	if str(final["phase"]) != "GAME_OVER":
		print("      DBG Schluss: tag=%s nacht=%s next=%s spur=%s lebende=%d" % [final.get("day_number"), final.get("night_number"), JSON.stringify((final["next"] as Dictionary).get("kind")), _trace.slice(-30), _state_of(shell).alive_ids().size()])
	assert_eq(str(final["phase"]), "GAME_OVER", "%d Personen: Partie über Buttons beendet" % count)
	assert_true(_played + _kept + _exchanged > 0, "%d Personen: Kartenfenster wurden bedient" % count)
	print("      %d Personen: %d Aktionen, Karten gespielt %d, behalten %d, getauscht %d, gewürfelt %d" % [count, _trace.size(), _played, _kept, _exchanged, _rolls])
	var replayed := RulesEngine.replay(session.commands())
	assert_true(replayed.ok, "%d Personen: Replay möglich" % count)
	assert_true(CardRules.state_is_consistent(replayed.state), "%d Personen: Kartenzustand konsistent" % count)
	var round_id := session.round_id()
	var context := context_of(shell) as AppContext
	var fresh := AppContext.new()
	fresh.saves.base_dir = context.saves.base_dir
	var resumed := fresh.resume(round_id)
	assert_true(bool(resumed["ok"]), "%d Personen: Fortsetzen (%s)" % [count, str(resumed.get("error", ""))])
	assert_eq(fresh.session.state_hash(), session.state_hash(), "%d Personen: gleicher Zustand nach dem Fortsetzen" % count)


func test_six_players_with_cards_through_buttons() -> void:
	await _play_game(6, [1], 21)


func test_twelve_players_with_cards_through_buttons() -> void:
	await _play_game(12, [1, 2, 3], 22)


func test_twenty_four_players_with_cards_through_buttons() -> void:
	await _play_game(24, [1, 2, 3, 4, 5], 23)


func test_twelve_players_with_the_card_swallower_through_buttons() -> void:
	await _play_game(12, [1, 2, 3], 24, {"4": "kartenschlucker"})


## Mehrere feste Seeds mit Kartenschlucker: über alle Partien müssen Tausch, Würfel und Handzeichen real bedient worden sein.
func test_several_seeds_with_the_card_swallower_cover_exchange_and_dice() -> void:
	_exchanged = 0
	_rolls = 0
	for seed_value: int in [31, 32, 33, 34, 35, 36]:
		await _play_game(12, [1, 2, 3], seed_value, {"4": "kartenschlucker"})
	print("      Seeds 31 bis 36: getauscht %d, gewürfelt %d" % [_exchanged, _rolls])
	assert_true(_exchanged > 0, "mindestens ein Kartentausch über Buttons")
