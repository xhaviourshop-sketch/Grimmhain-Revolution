extends UiTestCase
## Tag im Cockpit über echte Buttons: Nominierung in zwei Schritten, Hinrichtung nur von heute
## Nominierten mit verdeckter Prüfkarte (Vorschau des Regelkerns), keine Hinrichtung, Tag beenden,
## nächste Nacht, geheime Tagesaktionen, Siegbestätigung. Keine digitale Stimmzählung.

const NAMES := ["Anna", "Ben", "Cara", "Dirk", "Eva", "Finn", "Gina", "Hugo"]


func _cockpit(roles: Array) -> Control:
	var shell := await spawn_shell()
	if shell == null:
		return null
	var map := {}
	var players: Array = []
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
		players.append({"id": i + 1, "name": NAMES[i]})
	var r: CommandResult = session_of(shell).call("submit", Command.start_game({"round_id": "r", "seed": 3, "assignment": "manual",
		"players": players, "seat_order": Fixtures.identity_order(roles.size()), "roles": map}))
	assert_true(r.ok, "Start (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


## Nacht ohne Opfer über die Anwendungsschicht bis zum Tag; Morgenbericht weiterschalten.
func _quiet_night(shell: Control) -> void:
	var s := session_of(shell)
	s.call("start_night")
	for i: int in 20:
		var next: Dictionary = effective_of((s.call("cockpit_view") as Dictionary)["next"])
		match str(next["kind"]):
			"day":
				break
			"begin_step":
				s.call("skip_next_step", "Test") if bool(next["skippable"]) else s.call("begin_next_step")
			"prompt":
				if bool(next.get("skippable", false)) or str(next["owner"]) == "pack":
					s.call("skip_next_step", "Test")
				else:
					fail("unerwarteter Prompt %s" % next["owner"])
					return
			"end_night":
				s.call("end_night")
	await frames(3)
	var cont := find_node(current_screen(shell), "ContinueDayButton") as BaseButton
	if cont != null:
		await press(cont)


func _press(shell: Control, node_name: String) -> void:
	await press(find_button(current_screen(shell), node_name))


func _seat(shell: Control, id: int) -> BaseButton:
	return find_node(current_screen(shell), "SeatRing").call("token_for", id) as BaseButton


func _texts(shell: Control) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(current_screen(shell)):
		out.append(text_of(c))
	return "\n".join(out)


func _confirm_dialog(shell: Control) -> void:
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog.call("is_open"), "Rückfrage offen")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)


func _view(shell: Control) -> Dictionary:
	return session_of(shell).call("cockpit_view")


func test_execution_in_a_revival_round_names_no_role() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "nachtwaechter", "kutscher"])
	if shell == null:
		return
	await _quiet_night(shell)
	var s := session_of(shell)
	assert_true((s.call("nominate", 3, 1) as CommandResult).ok, "Nominierung")
	assert_true((s.call("decide_execution", 1, {}) as CommandResult).ok, "Hinrichtung")
	await frames(3)
	assert_true(_texts(shell).contains("„Heute gestorben: Anna.“"), "Wiederbelebungsrunde: Ansage ohne Rolle (DI-01)")
	assert_false(_texts(shell).contains("Werwolf"), "keine Rolle der Toten in der Ansage")


func test_nomination_execution_end_day_and_next_night() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	if shell == null:
		return
	await _quiet_night(shell)
	assert_true(find_button(current_screen(shell), "NominateButton").is_visible_in_tree(), "Tagesaktionen")
	assert_true(find_button(current_screen(shell), "ExecuteButton").disabled, "ohne Nominierung keine Hinrichtung")
	for b: BaseButton in visible_buttons(current_screen(shell)):
		assert_false(text_of(b).contains("Stimme"), "keine Stimmenerfassung: %s" % text_of(b))
	assert_true(find_children_of_type(current_screen(shell), "SpinBox").is_empty(), "kein Zählfeld")
	await _press(shell, "NominateButton")
	await press(_seat(shell, 3))
	assert_true(_texts(shell).contains("Cara klagt an"), "Nominierende Person gewählt")
	assert_true(_seat(shell, 3).disabled, "Cara kann sich nicht selbst nominieren")
	await press(_seat(shell, 1))
	var confirm := find_button(current_screen(shell), "ConfirmNominationButton")
	confirm.pressed.emit()
	confirm.pressed.emit()
	await frames(3)
	var noms: Array = _view(shell)["next"]["nominations"]
	assert_eq(noms.size(), 1, "genau eine Nominierung trotz Doppeltippen")
	assert_true(_texts(shell).contains("Cara klagt Anna an"), "öffentliche Nominierungsliste")
	assert_true(_texts(shell).contains("Alle Angeklagten dürfen sich jetzt nacheinander verteidigen."), "Vorlesezeile zur Verteidigung")
	await _press(shell, "NominateButton")
	assert_true(_seat(shell, 3).disabled, "wer heute nominiert hat, ist still gesperrt")
	assert_false(_seat(shell, 2).disabled, "andere dürfen weiter nominieren")
	await press(_seat(shell, 2))
	assert_true(_seat(shell, 1).disabled, "wer heute nominiert wurde, ist als Ziel still gesperrt")
	await _press(shell, "CancelModeButton")
	await _press(shell, "ExecuteButton")
	assert_true(_seat(shell, 2).disabled, "nicht Nominierte nicht wählbar")
	await press(_seat(shell, 1))
	assert_true(find_node(current_screen(shell), "RevealButton") == null, "Prüfkarte ohne Verdecken (Fenster-Diät)")
	assert_true(_texts(shell).contains("Keine Besonderheit: Anna stirbt"), "Vorschau des Regelkerns")
	await _press(shell, "ConfirmExecutionButton")  # ohne Rückfrage: die Wahl ist schon getroffen
	assert_false(_seat(shell, 1).get("alive"), "Anna hingerichtet")
	assert_true(_texts(shell).contains("„Heute gestorben: Anna (Werwolf).“"), "Runde ohne Wiederbelebung: Ansage mit Rolle (DI-01)")
	await _press(shell, "EndDayButton")
	assert_true(find_button(current_screen(shell), "StartNightButton").is_visible_in_tree(), "nächste Nacht beginnen")
	await _press(shell, "StartNightButton")
	assert_eq(int(_view(shell)["night_number"]), 2, "Nacht 2")


func test_no_execution_applies_directly() -> void:
	var shell := await _cockpit(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	await _quiet_night(shell)
	await _press(shell, "NoExecutionButton")
	assert_false((shell.call("get_dialog") as Control).call("is_open"), "keine Rückfrage")
	assert_eq(str(_view(shell)["next"]["kind"]), "end_day", "Entscheidung gefallen")


func test_mirror_wolf_preview_names_real_victim() -> void:
	var shell := await _cockpit(["spiegelwolf", "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	await _quiet_night(shell)
	session_of(shell).call("nominate", 4, 1)
	await frames(2)
	await press(_seat(shell, 1))  # zwei Tipps: Person antippen, dann „Hinrichten“
	assert_true(_texts(shell).contains("Stattdessen stirbt Dirk"), "Spiegelung in der Vorschau")
	await _press(shell, "ConfirmExecutionButton")  # ohne Rückfrage: die Wahl ist schon getroffen
	assert_true(_seat(shell, 1).get("alive") and not _seat(shell, 4).get("alive"), "Dirk statt des Spiegelwolfs")


func test_sage_curse_length_is_required() -> void:
	var shell := await _cockpit(["werwolf", "der-weise", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	await _quiet_night(shell)
	session_of(shell).call("nominate", 3, 2)
	await frames(2)
	await _press(shell, "ExecuteButton")
	await press(_seat(shell, 2))
	assert_true(find_button(current_screen(shell), "ConfirmExecutionButton").disabled, "ohne Fluchdauer nicht bestätigbar")
	await _press(shell, "SageCurse2")
	assert_false(find_button(current_screen(shell), "ConfirmExecutionButton").disabled, "mit Fluchdauer")
	await _press(shell, "ConfirmExecutionButton")  # ohne Rückfrage: die Wahl ist schon getroffen
	var log: Array = session_of(shell).call("event_log")
	assert_true(log.any(func(e: Dictionary) -> bool: return str(e["type"]) == "SageCursed" and int(e["data"]["length"]) == 2), "Fluch mit zwei Tagen")


func test_amalia_secret_day_action() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "rudelvater", "amalia", "dorfbewohner", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null:
		return
	await _quiet_night(shell)
	assert_true(find_node(current_screen(shell), "SecretAction_amalia_4") == null, "keine geheime Aktion außerhalb des privaten Bereichs")
	await _press(shell, "PrivateButton")
	await _press(shell, "SecretAction_amalia_4")
	assert_true(find_node(current_screen(shell), "PrivateLayer") == null, "privater Bereich geschlossen")
	var dialog := shell.call("get_dialog") as Control
	await press(find_node(dialog, "AlternativeButton") as BaseButton)
	assert_false(_seat(shell, 4).get("alive"), "Amalia stirbt sofort")
	var log: Array = session_of(shell).call("event_log")
	assert_true(log.any(func(e: Dictionary) -> bool: return str(e["type"]) == "AmaliaAnswered" and e["data"]["answer"] == false), "Antwort Nein gespeichert")


## Fenster-Diät (Markus 05.10.2026): Ein eindeutiger Sieg nach einer Handlung auf der Karte führt direkt zum Siegbildschirm.
func test_win_after_card_action_goes_straight_to_victory_screen() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	if shell == null:
		return
	await _quiet_night(shell)
	var s := session_of(shell)
	s.call("nominate", 1, 3)
	s.call("decide_execution", 3)
	await frames(3)
	s.call("end_day")
	s.call("start_night")
	s.call("answer_targets", [4])
	await frames(3)
	await _press(shell, "EndNightButton")  # nach Steuerung über die Sitzung bleibt die Karte; ihr Knopf ist eine Kartenhandlung
	assert_eq(str(_view(shell)["phase"]), "GAME_OVER", "Wolfsparität: Sieg ohne Rückfrage")
	assert_true(find_node(current_screen(shell), "ConfirmWinButton_1") == null, "kein Fenster „Mögliches Spielende“")
	assert_true(_texts(shell).contains("Die Werwölfe siegen"), "Siegbildschirm mit Gewinner-Team: %s" % _texts(shell))


## Entsteht der Sieg ohne Kartenhandlung (Steuerung über die Sitzung, Rückgängig), bleibt die Siegkarte: ein Tipp bestätigt, ohne Rückfrage.
func test_win_card_without_card_action_confirms_with_one_tap() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	if shell == null:
		return
	await _quiet_night(shell)
	var s := session_of(shell)
	s.call("nominate", 1, 3)
	s.call("decide_execution", 3)
	s.call("end_day")
	s.call("start_night")
	s.call("answer_targets", [4])
	s.call("end_night")
	await frames(3)
	assert_eq(str(_view(shell)["next"]["kind"]), "win_decision", "Wolfsparität erkannt")
	await _press(shell, "ConfirmWinButton_1")
	assert_eq(str(_view(shell)["phase"]), "GAME_OVER", "Spielende nach einem Tipp")


func find_children_of_type(root: Node, type: String) -> Array[Node]:
	return root.find_children("*", type, true, false)


func test_necromancer_names_wolf_secretly() -> void:
	var shell := await _cockpit(["werwolf", "nekromant", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	if shell == null:
		return
	await _quiet_night(shell)
	await _press(shell, "PrivateButton")
	await _press(shell, "SecretAction_name_wolf_2")
	assert_true(_seat(shell, 2).disabled, "Nekromant benennt nicht sich selbst")
	await press(_seat(shell, 1))
	await _press(shell, "ConfirmNameWolfButton")
	var log: Array = session_of(shell).call("event_log")
	assert_true(log.any(func(e: Dictionary) -> bool: return str(e["type"]) == "NecroNamed" and str(e["visibility"]) == "gm"), "Benennung nur für die Spielleitung")
	# Treffer (E-19): eindeutiger Sieg des Nekromanten, direkt der Siegbildschirm.
	assert_eq(str(_view(shell)["phase"]), "GAME_OVER", "Sieg nach richtiger Benennung")


## Rückgängig ersetzt den Zustand: eine offene Bedienung (hier die Prüfkarte einer Hinrichtung mit
## Vorschau des alten Zustands) darf nicht stehen bleiben.
func test_undo_drops_open_execution_check() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	if shell == null:
		return
	await _quiet_night(shell)
	assert_true((session_of(shell).call("nominate", 3, 1) as CommandResult).ok, "Nominierung")
	await frames(2)
	await _press(shell, "ExecuteButton")
	await press(_seat(shell, 1))
	assert_true(find_button(current_screen(shell), "ConfirmExecutionButton").is_visible_in_tree(), "Prüfkarte offen")
	await _press(shell, "GmButton")
	await _press(shell, "UndoButton")
	await _confirm_dialog(shell)
	assert_true((_view(shell)["next"]["nominations"] as Array).is_empty(), "Nominierung zurückgenommen")
	assert_true(find_node(current_screen(shell), "ConfirmExecutionButton") == null, "keine veraltete Prüfkarte")
	assert_false(_texts(shell).contains("Keine Besonderheit"), "keine veraltete Vorschau")
	assert_true(find_node(current_screen(shell), "NominateButton") != null, "Tageskarte des neuen Zustands")


## Nach einer Nominierung zeigt das Dock „Rückgängig“, sobald die 3-Sekunden-Leiste der Karte abgelaufen ist.
func test_dock_undo_is_visible_after_nomination() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	if shell == null:
		return
	await _quiet_night(shell)
	await _press(shell, "NominateButton")
	await press(_seat(shell, 3))
	await press(_seat(shell, 1))
	await _press(shell, "ConfirmNominationButton")
	await frames(3)
	var dock := find_node(shell, "DockUndoButton") as Control
	var bar := find_node(shell, "UndoBar") as Control
	assert_true(dock.is_visible_in_tree() or (bar != null and bar.is_visible_in_tree()), "Rückgängig sofort erreichbar (Dock oder Leiste)")
	await wait_seconds(3.4)
	assert_true(dock.is_visible_in_tree(), "Rückgängig im Dock nach Ablauf der Leiste")


## Die Tageskarte schrumpft nach dem ersten Schritt der Anklage wieder auf ihren Inhalt (sie blieb zuvor als hoher Streifen stehen).
func test_day_card_stays_as_tall_as_its_content_in_the_second_nomination_step() -> void:
	var shell := await _cockpit(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	if shell == null:
		return
	await _quiet_night(shell)
	await _press(shell, "NominateButton")
	await press(_seat(shell, 3))
	await frames(20)
	var panel := find_node(current_screen(shell), "InstructionCard") as Control
	assert_true(panel.size.y <= panel.get_combined_minimum_size().y + 1.0, "Karte so hoch wie ihr Inhalt (%s statt %s)" % [panel.size.y, panel.get_combined_minimum_size().y])
