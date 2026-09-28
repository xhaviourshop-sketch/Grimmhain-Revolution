extends UiTestCase
## Spielleitung im Cockpit über echte Buttons: geführte Korrekturen mit Warnung und Pflichtbegründung,
## Protokoll und Anzeige der Änderung, Rückgängig/Wiederholen mit Klartext, Hinrichtung ohne
## Nominierung, Sieger erklären, Partie beenden und verwerfen ohne Löschen.

const ROLES := ["werwolf", "werwolf", "schutzengel", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]


func _cockpit() -> Control:
	var shell := await spawn_shell()
	if shell == null:
		return null
	assert_true((session_of(shell).call("submit", Fixtures.start_roles(ROLES, 2)) as CommandResult).ok, "Start")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _press(shell: Control, node_name: String) -> void:
	await press(find_button(current_screen(shell), node_name))


func _seat(shell: Control, id: int) -> BaseButton:
	return find_node(current_screen(shell), "SeatRing").call("token_for", id) as BaseButton


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control


func _confirm_with_reason(shell: Control, reason: String) -> void:
	var dialog := _dialog(shell)
	assert_true(dialog.call("is_open"), "Rückfrage mit Begründung")
	var confirm := find_node(dialog, "ConfirmButton") as BaseButton
	assert_true(confirm.disabled, "ohne Begründung gesperrt")
	await type_text(find_node(dialog, "InputField") as LineEdit, reason)
	await press(confirm)


func _alive(shell: Control, id: int) -> bool:
	for seat: Dictionary in (session_of(shell).call("cockpit_view") as Dictionary)["seats"]:
		if int(seat["person_id"]) == id:
			return bool(seat["alive"])
	return false


func _texts(node: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(node):
		out.append(text_of(c))
	return "\n".join(out)


func test_kill_correction_with_warning_reason_log_and_change() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	await _press(shell, "GmButton")
	assert_true(find_node(current_screen(shell), "GmLayer") != null, "Spielleitung offen")
	await _press(shell, "GmKind_kill")
	assert_true(find_node(current_screen(shell), "GmLayer") == null, "Ebene geschlossen, Korrekturkarte aktiv")
	assert_true(_texts(current_screen(shell)).contains("Hinweis: Eine Korrektur übersteuert"), "Warnung sichtbar")
	await press(_seat(shell, 4))
	assert_true(find_button(current_screen(shell), "GmConfirmButton").disabled, "Todesfolgen müssen gewählt werden")
	await _press(shell, "GmEffectsNo")
	await _press(shell, "GmConfirmButton")
	await _confirm_with_reason(shell, "falsch getippt")
	assert_false(_alive(shell, 4), "Person 4 tot")
	var log: Array = session_of(shell).call("event_log")
	assert_true(log.any(func(e: Dictionary) -> bool: return str(e["type"]) == "GmCorrected" and str(e["data"]["reason"]) == "falsch getippt"), "Protokoll mit Begründung")
	var layer := find_node(current_screen(shell), "GmLayer")
	assert_true(layer != null, "Änderung wird in der Spielleitung gezeigt")
	var change := _texts(layer)
	assert_true(change.contains("das hat sich geändert") and change.contains("GmCorrected") and change.contains("SeatDied"), "Änderung sichtbar: %s" % change)


func test_undo_and_redo_with_plain_text() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	await _press(shell, "StartNightButton")
	await press(_seat(shell, 4))
	await _press(shell, "ConfirmTargetsButton")
	await _press(shell, "GmButton")
	var undo := find_button(current_screen(shell), "UndoButton")
	assert_eq(undo.text, "Rückgängig: Antwort im Schritt Schutzengel", "Klartext des Rücknehmbaren")
	assert_true(find_button(current_screen(shell), "RedoButton").disabled, "noch nichts zu wiederholen")
	await press(undo)
	var dialog := _dialog(shell)
	assert_true(dialog.call("is_open"), "Rückfrage")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	var next: Dictionary = (session_of(shell).call("cockpit_view") as Dictionary)["next"]
	assert_eq(str(next["owner"]), "schutzengel", "Schutzengel-Prompt wieder offen")
	await _press(shell, "GmButton")
	await _press(shell, "RedoButton")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	next = (session_of(shell).call("cockpit_view") as Dictionary)["next"]
	assert_eq(str(next["kind"]), "begin_step", "Antwort wiederhergestellt")


func test_set_role_and_declare_winner() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	await _press(shell, "GmButton")
	await _press(shell, "GmKind_set_role")
	await press(_seat(shell, 5))
	await _press(shell, "GmChooseRoleButton")
	await press(find_node(_dialog(shell), "Role_waldhexe") as BaseButton)
	assert_true(_texts(current_screen(shell)).contains("Neue Rolle: Waldhexe"), "gewählte Rolle angezeigt")
	await _press(shell, "GmConfirmButton")
	await _confirm_with_reason(shell, "Karte vertauscht")
	var roles := {}
	for s: Dictionary in session_of(shell).call("private_seats"):
		roles[int(s["person_id"])] = str(s["role_id"])
	assert_eq(roles[5], "waldhexe", "Rolle geändert")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _press(shell, "GmButton")
	await _press(shell, "GmKind_declare_winner")
	await _press(shell, "GmWinner_village")
	await _confirm_with_reason(shell, "Runde abgebrochen")
	assert_eq(str((session_of(shell).call("cockpit_view") as Dictionary)["phase"]), "GAME_OVER", "Sieger erklärt")


func test_execute_without_nomination_uses_check_card() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell)
	s.call("start_night")
	s.call("answer_targets", [4])
	s.call("skip_next_step", "kein Opfer")
	s.call("end_night")
	await frames(3)
	await _press(shell, "ContinueDayButton")
	await _press(shell, "GmButton")
	await _press(shell, "GmKind_execute")
	await press(_seat(shell, 1))
	await _press(shell, "GmConfirmButton")
	assert_true(_texts(current_screen(shell)).contains("Keine Besonderheit: 1 · A stirbt"), "Vorschau des Regelkerns")
	await _press(shell, "ConfirmExecutionButton")
	await _confirm_with_reason(shell, "Nominierung vergessen")
	assert_false(_alive(shell, 1), "hingerichtet")
	var log: Array = s.call("event_log")
	assert_true(log.any(func(e: Dictionary) -> bool: return str(e["type"]) == "ExecutionConfirmed" and bool(e["data"]["gm_override"])), "als Übersteuerung protokolliert")


func test_gm_execute_only_offered_during_day_actions() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	await _press(shell, "GmButton")
	assert_true(find_node(current_screen(shell), "GmKind_execute") == null, "vor dem Tag kein Hinrichten")
	assert_true(find_node(current_screen(shell), "GmKind_kill") != null, "Töten jederzeit")


func test_discard_game_asks_and_keeps_files() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	await _press(shell, "StartNightButton")
	await _press(shell, "GmButton")
	await _press(shell, "DiscardGameButton")
	var dialog := _dialog(shell)
	assert_true(dialog.call("is_open"), "Rückfrage")
	await press(find_node(dialog, "CancelButton") as BaseButton)
	assert_true(bool(ctx.session.view()["has_game"]), "Abbrechen behält die Partie")
	await _press(shell, "GmButton")
	await _press(shell, "DiscardGameButton")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_eq(String(current_id(shell)), "main_menu", "Hauptmenü")
	assert_false(bool(ctx.session.view()["has_game"]), "Partie geschlossen")
	assert_eq(ctx.saves.list().size(), 0, "nicht mehr fortsetzbar")
	var d := DirAccess.open(ctx.saves.base_dir)
	assert_true(Array(d.get_files()).any(func(n: String) -> bool: return n.contains(".discarded-")), "Datei umbenannt erhalten")
