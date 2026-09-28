extends UiTestCase
## Cockpit mit laufender Partie über echte Buttons: Sitzkreis ohne Rollen, geführte erste Nacht bis
## zum Tag, verdeckte geheime Karten außerhalb der Nacht, privater Bereich, Sichtschutz, gezeigte
## Karte mit Positivliste, Pflichtbegründung beim Überspringen, Mehrfachtippen und Layout.

## 1 Werwolf, 2 Trugbilderwolf (erscheint als Dorfbewohner), 3 Schutzengel, 4 Waldhexe, 5 Orakel,
## 6 Sensenträger, 7 Dorfbewohner. Sitzordnung nicht nach ID.
const ROLES := ["werwolf", "trugbilderwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner"]
const SEATS: Array[int] = [3, 1, 4, 7, 2, 6, 5]


func _start_command(roles: Array, seats: Array, names: Array = []) -> Command:
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	var players := Fixtures.players(roles.size())
	for i: int in names.size():
		players[i]["name"] = names[i]
	var payload := {"round_id": "test-round", "seed": 11, "assignment": "manual", "players": players, "seat_order": seats, "roles": map}
	if roles.has("trugbilderwolf"):
		payload["appearances"] = {str(roles.find("trugbilderwolf") + 1): "dorfbewohner"}
	return Command.start_game(payload)


## Shell mit laufender Partie im Cockpit.
func _cockpit(size: Vector2i = SIZE_16_10, locale: String = "de", roles: Array = ROLES, seats: Array = SEATS, names: Array = []) -> Control:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return null
	var result: CommandResult = session_of(shell).call("submit", _start_command(roles, seats, names))
	assert_true(result.ok, "Partie gestartet (%s)" % result.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _screen(shell: Control) -> Control:
	return current_screen(shell)


func _seat(shell: Control, person_id: int) -> BaseButton:
	var ring := find_node(_screen(shell), "SeatRing")
	return ring.call("token_for", person_id) as BaseButton if ring != null else null


func _tap_seat(shell: Control, person_id: int) -> void:
	await press(_seat(shell, person_id))


func _press(shell: Control, node_name: String) -> void:
	await press(find_button(_screen(shell), node_name))


func _next(shell: Control) -> Dictionary:
	return (session_of(shell).call("cockpit_view") as Dictionary).get("next", {})


func _role_names(roles: Array) -> Array[String]:
	var names: Array[String] = []
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for role: Variant in roles:
			var k := "ui.role.%s.name" % str(role).replace("-", "_")
			if po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


## Kein sichtbarer Text im Cockpit (inklusive Ebenen und Statusmeldung) nennt eine der Rollen.
func _assert_no_roles(shell: Control, label: String, roles: Array = ROLES) -> void:
	var names := _role_names(roles)
	var texts: Array[Control] = text_controls(_screen(shell))
	var toast := find_node(shell.call("get_toast") as Node, "MessageLabel") as Label
	if toast != null and toast.is_visible_in_tree():
		texts.append(toast)
	for c: Control in texts:
		for name: String in names:
			assert_false(text_of(c).contains(name), "%s: %s zeigt Rolle „%s“ (%s)" % [label, c.name, name, text_of(c)])


func _visible_texts(shell: Control) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(_screen(shell)):
		out.append(text_of(c))
	return "\n".join(out)


# --- Sitzkreis ----------------------------------------------------------------------------------------

func test_seat_ring_shows_started_game_without_roles() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var screen := _screen(shell)
	assert_false((find_node(screen, "NoGameBadge") as Control).is_visible_in_tree(), "kein Hinweis „Keine Partie“")
	var ring := find_node(screen, "SeatRing")
	var tokens: Array = ring.call("tokens")
	assert_eq(tokens.size(), 7, "sieben Plätze")
	for i: int in tokens.size():
		var token := tokens[i] as Button
		var name := str(Fixtures.players(7)[SEATS[i] - 1]["name"])
		assert_eq(token.text, "%d · %s" % [i + 1, name], "Platz %d zeigt Nummer und Namen" % (i + 1))
	assert_eq((find_node(screen, "PhaseValueLabel") as Label).text, "Vorbereitung", "Phase")
	assert_true(find_button(screen, "StartNightButton").is_visible_in_tree(), "nächster Schritt: Nacht beginnen")
	_assert_no_roles(shell, "Start")
	settings_of(shell).call("set_language", "en")
	await frames(2)
	assert_eq(find_button(screen, "StartNightButton").text, "Begin night", "Englisch")
	_assert_no_roles(shell, "Start EN")


# --- Geführte Nacht ------------------------------------------------------------------------------------

func test_first_night_through_buttons() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	await _press(shell, "StartNightButton")
	assert_eq(str(_next(shell)["owner"]), "schutzengel", "Schutzengel-Prompt")
	var confirm := find_button(_screen(shell), "ConfirmTargetsButton")
	assert_true(confirm.disabled, "Bestätigen erst mit Auswahl")
	assert_true(_seat(shell, 3).disabled, "Schutzengel kann sich nicht selbst wählen (nicht antippbar)")
	await _tap_seat(shell, 7)
	assert_eq(_seat(shell, 7).theme_type_variation, &"SeatSelectedButton", "Auswahl sichtbar")
	assert_true(_visible_texts(shell).contains("Gewählt: 4 · "), "Auswahl in der Karte")
	await _press(shell, "ConfirmTargetsButton")
	assert_eq(str(_next(shell)["kind"]), "begin_step", "Rudel angekündigt")
	assert_true(_visible_texts(shell).contains("Werwölfe, erwacht"), "Vorlesetext des Rudels")
	await _press(shell, "BeginStepButton")
	await _tap_seat(shell, 6)
	await _press(shell, "ConfirmTargetsButton")
	await _press(shell, "BeginStepButton")
	assert_eq(str(_next(shell)["stage"]), "heal", "Waldhexe: Heiltrank")
	await _press(shell, "NoButton")
	assert_eq(str(_next(shell)["stage"]), "poison", "Gifttrank")
	await _press(shell, "NoButton")
	await _press(shell, "AckButton")
	await _press(shell, "BeginStepButton")
	await _tap_seat(shell, 1)
	await _press(shell, "ConfirmTargetsButton")
	assert_eq(str(_next(shell)["stage"]), "shown", "Orakel: Ergebnis zeigen")
	await _press(shell, "AckButton")
	assert_eq(str(_next(shell)["kind"]), "end_night", "Nacht abschließen")
	await _press(shell, "EndNightButton")
	var view: Dictionary = session_of(shell).call("view")
	# Sensenträger (6) ist gestorben: Reaktion in der Morgenauflösung.
	assert_eq(str(view["phase"]), "DAWN_RESOLUTION", "Morgen mit offener Reaktion")
	assert_false(_seat(shell, 6).get("alive"), "Opfer im Sitzkreis tot")
	assert_true(_seat(shell, 6).text.contains("†"), "Tod als Zeichen, nicht nur Farbe")


func test_reaction_card_is_covered_outside_night() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell)
	s.call("start_night")
	s.call("answer_targets", [7])
	s.call("begin_next_step")
	s.call("answer_targets", [6])  # Rudel tötet den Sensenträger
	s.call("begin_next_step")
	s.call("answer_choice", false)
	s.call("answer_choice", false)
	s.call("answer_choice", true)
	s.call("begin_next_step")
	s.call("answer_targets", [1])
	s.call("answer_choice", true)
	s.call("end_night")
	await frames(3)
	var screen := _screen(shell)
	assert_eq(str(_next(shell)["kind"]), "begin_step", "Reaktion angekündigt")
	assert_true(find_button(screen, "RevealButton").is_visible_in_tree(), "Karte verdeckt")
	assert_true(find_node(screen, "BeginStepButton") == null, "keine Aktion vor dem Aufdecken")
	_assert_no_roles(shell, "verdeckte Reaktion")
	for token: Variant in find_node(screen, "SeatRing").call("tokens"):
		assert_ne((token as Button).theme_type_variation, &"SeatActorButton", "keine Hervorhebung der handelnden Person vor dem Aufdecken")
	await _press(shell, "RevealButton")
	assert_true(find_button(screen, "BeginStepButton").is_visible_in_tree(), "nach „Anzeigen“ bedienbar")
	await _press(shell, "BeginStepButton")
	assert_true(find_button(screen, "RevealButton").is_visible_in_tree(), "neuer Prompt wieder verdeckt")
	await _press(shell, "RevealButton")
	await _press(shell, "DeclineButton")
	assert_eq(str((s.call("view") as Dictionary)["phase"]), "DAY", "Tag nach der Reaktion")


# --- Geheimhaltung: Ebenen ----------------------------------------------------------------------------

func test_private_area_opens_only_on_request_and_closes() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	assert_true(find_node(_screen(shell), "PrivateLayer") == null, "kein privater Bereich im Baum")
	await _press(shell, "PrivateButton")
	var layer := find_node(_screen(shell), "PrivateLayer")
	assert_true(layer != null and (layer as Control).is_visible_in_tree(), "privater Bereich offen")
	assert_true(_visible_texts(shell).contains("Schutzengel"), "Rollen im privaten Bereich")
	assert_true(_visible_texts(shell).contains("Erscheint bei Prüfungen als: Dorfbewohner"), "Scheinrolle sichtbar")
	await _press(shell, "CloseLayerButton")
	await frames(2)
	assert_true(find_node(_screen(shell), "PrivateLayer") == null, "nach Schließen entfernt")
	_assert_no_roles(shell, "nach Schließen")
	# Zurück schließt die Ebene, statt die Ansicht zu verlassen.
	await _press(shell, "PrivateButton")
	await go_back(shell)
	assert_eq(String(current_id(shell)), "cockpit", "Zurück schließt nur die Ebene")
	assert_true(find_node(_screen(shell), "PrivateLayer") == null, "Ebene per Zurück entfernt")
	# Navigation entfernt die Ebene mit der Ansicht.
	await _press(shell, "PrivateButton")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	assert_true(find_node(_screen(shell), "PrivateLayer") == null, "nach Navigation kein privater Bereich")
	_assert_no_roles(shell, "nach Navigation")


func test_cover_hides_everything_and_resumes() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	session_of(shell).call("start_night")
	await frames(2)
	await _press(shell, "PrivateButton")
	await _press(shell, "CoverButton")
	var screen := _screen(shell)
	assert_true(find_node(screen, "PrivateLayer") == null, "Sichtschutz entfernt den privaten Bereich")
	assert_false((find_node(screen, "Layout") as Control).is_visible_in_tree(), "Cockpit verborgen")
	_assert_no_roles(shell, "Sichtschutz")
	assert_false(_visible_texts(shell).contains("Schutzengel, erwache"), "kein Nachttext sichtbar")
	await _press(shell, "UncoverButton")
	assert_true((find_node(screen, "Layout") as Control).is_visible_in_tree(), "Cockpit wieder sichtbar")


func test_show_card_contains_only_positive_list() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell)
	s.call("start_night")
	s.call("answer_targets", [7])
	s.call("skip_next_step", "Test")
	s.call("begin_next_step")
	s.call("answer_choice", false)
	s.call("answer_choice", true)
	s.call("begin_next_step")
	s.call("answer_targets", [2])  # Orakel prüft den Trugbilderwolf
	await frames(3)
	var info := _visible_texts(shell)
	assert_true(info.contains("Wahre Rolle: Trugbilderwolf"), "Spielleiter sieht die Wahrheit")
	await _press(shell, "ShowCardButton")
	var screen := _screen(shell)
	assert_true(find_node(screen, "ShowLayer") != null, "gezeigte Karte offen")
	assert_false((find_node(screen, "Layout") as Control).is_visible_in_tree(), "Cockpit vollständig ersetzt")
	var shown := _visible_texts(shell)
	assert_true(shown.contains("Dorfbewohner"), "gezeigtes Ergebnis")
	assert_false(shown.contains("Trugbilderwolf"), "keine Wahrheit auf der gezeigten Karte")
	assert_false(shown.contains("Werwolf"), "keine andere Rolle")
	await _press(shell, "CloseLayerButton")
	await frames(2)
	assert_true((find_node(screen, "Layout") as Control).is_visible_in_tree(), "zurück im Cockpit")


# --- Bedienung ----------------------------------------------------------------------------------------

func test_skip_requires_reason_in_dialog() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell)
	s.call("start_night")
	s.call("answer_targets", [7])
	await frames(2)
	await _press(shell, "SkipStepButton")
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog.call("is_open"), "Rückfrage offen")
	var confirm := find_node(dialog, "ConfirmButton") as BaseButton
	var field := find_node(dialog, "InputField") as LineEdit
	assert_true(field != null and field.is_visible_in_tree(), "Begründungsfeld")
	assert_true(confirm.disabled, "ohne Begründung nicht bestätigbar")
	await type_text(field, "   ")
	assert_true(confirm.disabled, "Leerzeichen zählen nicht")
	await type_text(field, "Wölfe uneinig")
	assert_false(confirm.disabled, "mit Begründung bestätigbar")
	await press(confirm)
	assert_eq(str(_next(shell)["role_id"]), "waldhexe", "Rudel übersprungen, weiter mit der Waldhexe")
	var log: Array = s.call("event_log")
	assert_true(log.any(func(e: Dictionary) -> bool: return str(e["type"]) == "StepSkipped" and str(e["data"]["reason"]) == "Wölfe uneinig"), "Begründung protokolliert")


func test_double_tap_sends_one_command() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var start := find_button(_screen(shell), "StartNightButton")
	start.pressed.emit()
	start.pressed.emit()
	await frames(3)
	assert_eq(int((session_of(shell).call("view") as Dictionary)["command_count"]), 2, "StartGame und genau ein StartNight")
	await _tap_seat(shell, 7)
	var confirm := find_button(_screen(shell), "ConfirmTargetsButton")
	var rejected: Array = []
	session_of(shell).connect("command_rejected", func(e: StringName) -> void: rejected.append(e))
	confirm.pressed.emit()
	confirm.pressed.emit()
	await frames(3)
	assert_eq(int((session_of(shell).call("view") as Dictionary)["command_count"]), 3, "genau eine Antwort")
	assert_eq(rejected.size(), 0, "kein zweiter Befehl an den Regelkern")


func test_back_asks_before_leaving_running_game() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	await go_back(shell)
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog.call("is_open"), "Rückfrage vor dem Verlassen")
	assert_eq(String(current_id(shell)), "cockpit", "noch im Cockpit")
	await press(find_node(dialog, "ConfirmButton") as BaseButton)
	assert_eq(String(current_id(shell)), "main_menu", "Hauptmenü")
	await navigate(shell, &"cockpit")
	assert_true(bool((session_of(shell).call("view") as Dictionary)["has_game"]), "Partie erhalten")
	assert_true(find_button(_screen(shell), "StartNightButton").is_visible_in_tree(), "an derselben Stelle")


# --- Layout -------------------------------------------------------------------------------------------

func _check_layout(shell: Control, count: int, label: String) -> void:
	var screen := _screen(shell)
	var area := find_node(screen, "SeatRingArea") as Control
	var tokens: Array = find_node(screen, "SeatRing").call("tokens")
	assert_eq(tokens.size(), count, "%s: alle Plätze" % label)
	for i: int in tokens.size():
		var a := tokens[i] as Control
		assert_true(inside(rect_of(a), rect_of(area)), "%s: Platz %d im Sitzbereich" % [label, i + 1])
		assert_true(a.size.y >= ThemeTokens.TOUCH_MIN and a.size.x >= 96.0, "%s: Platz %d Touch-Größe und lesbare Breite %s" % [label, i + 1, a.size])
		for j: int in range(i + 1, tokens.size()):
			assert_false(overlaps(rect_of(a), rect_of(tokens[j] as Control)), "%s: Plätze %d und %d überlappen" % [label, i + 1, j + 1])
	var card := find_node(screen, "InstructionCard") as Control
	assert_false(overlaps(rect_of(area), rect_of(card)), "%s: Sitzkreis und Karte getrennt" % label)
	assert_true(inside(rect_of(card), Rect2(Vector2.ZERO, tree.root.get_visible_rect().size)), "%s: Karte im Fenster" % label)


func test_layout_6_and_24_people_all_sizes() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10, SIZE_WIDE]:
		for count: int in [6, 24]:
			var roles: Array = []
			var seats: Array = []
			for i: int in count:
				roles.append("werwolf" if i < 2 else "dorfbewohner")
				seats.append(i + 1)
			var names: Array = long_names(count)
			var shell := await _cockpit(size, "de", roles, seats, names)
			if shell == null:
				return
			await frames(2)
			_check_layout(shell, count, "%dx%d, %d Personen" % [size.x, size.y, count])
			after_each_shell(shell)


func after_each_shell(shell: Control) -> void:
	_spawned.erase(shell)
	shell.get_parent().remove_child(shell)
	shell.free()
