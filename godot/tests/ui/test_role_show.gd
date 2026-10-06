extends UiTestCase
## Rollenanzeige („Rollen zeigen“, vertical-slice-flow.md §2): Die Spielleitung behält das Tablet und zeigt gezielt einer
## Person ihre Karte. Neutrale Namensliste (nur Namen), Antippen zeigt groß das Bild der Rollenkarte ohne Text, Antippen der Karte
## schließt zurück zur Liste und gilt als „gesehen“ (`ConfirmRoleShown`). Trugbilderwolf: nie die Scheinrolle. Jede
## Zustandsänderung (Undo, Laden, Korrektur) verwirft eine offene Karte.

const UiGame := preload("res://tests/ui/ui_game.gd")
const W := "werwolf"
const D := "dorfbewohner"
const ROLES: Array = [D, W, "waldhexe", "amalia", "schutzengel", "detektiv"]


func _cockpit(roles: Array = ROLES, appearances: Dictionary = {}) -> Control:
	var shell := await spawn_shell()
	if shell == null:
		return null
	var r: CommandResult = session_of(shell).call("submit", UiGame.start(roles, 7, appearances))
	assert_true(r.ok, "Start (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _texts(root: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		out.append(text_of(c))
	return "\n".join(out)


func _role_names(except: Array = []) -> Array[String]:
	var names: Array[String] = []
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for role: String in ["dorfbewohner", "werwolf", "waldhexe", "schutzengel", "trugbilderwolf"]:
			var k := "ui.role.%s.name" % role
			if not except.has(role) and po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


func _assert_no_role_names(text: String, label: String, except: Array = []) -> void:
	for name: String in _role_names(except):
		assert_false(text.contains(name), "%s: nennt Rolle „%s“" % [label, name])


func _shown_count(s: GameSession) -> int:
	return s.commands().filter(func(c: Command) -> bool: return c.type == Command.CONFIRM_ROLE_SHOWN).size()


## Rolle auf dem großen Kartenbild der offenen Karte ("" ohne Bild).
func _card_role(screen: Node) -> String:
	var picture := find_node(screen, "RoleCardPicture") as RoleCardImage
	return picture.role_id if picture != null else ""


func _open_list(shell: Control) -> Node:
	var screen := current_screen(shell)
	await press(find_button(screen, "RolesButton"))
	return find_node(screen, "RoleListLayer")


# --- Anwendungsschicht ------------------------------------------------------------------------------------

func test_session_views_and_commands() -> void:
	var s := UiGame.session(ROLES)
	var list: Dictionary = s.role_show_list()
	assert_eq((list["persons"] as Array).size(), 6, "sechs Personen")
	assert_eq(int(list["next_id"]), 1, "Fortsetzung bei der ersten Person")
	assert_eq(int(list["confirmed_count"]), 0, "noch niemand bestätigt")
	for entry: Dictionary in list["persons"]:
		assert_false(entry.has("role_id"), "die Liste enthält keine Rolle")
	assert_true(s.confirm_role_shown(1).ok, "Bestätigung Person 1")
	assert_eq(int(s.role_show_list()["next_id"]), 2, "danach Person 2")
	var card: Dictionary = s.role_show_card(2)
	assert_eq(str(card["role_id"]), W, "Karte nennt die Rolle der Person")
	var card_keys := card.keys()
	card_keys.sort()
	assert_eq(card_keys, ["confirmed", "name", "person_id", "role_id", "seat"], "Karte enthält nur die Positivliste")
	var bad := s.confirm_role_shown(99)
	assert_false(bad.ok, "ungültige Person abgelehnt")
	assert_false(s.confirm_role_shown(1).ok, "doppelte Bestätigung abgelehnt")
	assert_eq(_shown_count(s), 1, "abgelehnte Befehle stehen nicht im Verlauf")
	assert_true(s.role_show_card(99).is_empty(), "keine Karte für unbekannte Person")


func test_trugbilderwolf_card_shows_true_role_never_the_appearance() -> void:
	var s := UiGame.session([D, "trugbilderwolf", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 7, {"2": "schutzengel"})
	var card: Dictionary = s.role_show_card(2)
	assert_eq(str(card["role_id"]), "trugbilderwolf", "wahre Rolle")
	assert_false(JSON.stringify(card).contains("schutzengel"), "Scheinrolle nirgends in der Karte")
	assert_false(s.role_show_list().has("appears_as"), "Liste ohne Scheinrolle")


# --- Bedienweg über die Buttons ---------------------------------------------------------------------------

func test_tapping_the_card_confirms_once_and_returns_to_a_list_without_numbers() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	var screen := current_screen(shell)
	var list := await _open_list(shell)
	assert_true(list != null, "Liste geöffnet")
	assert_eq(str((screen as CockpitScreen).layer_kind()), "roles", "Ebene Rollenliste")
	_assert_no_role_names(_texts(list), "Liste")
	assert_false(_texts(list).contains("·"), "keine Sitzplatznummer in der Liste: %s" % _texts(list))
	assert_true(find_button(list, "RolePerson_1") != null and find_button(list, "RolePerson_6") != null, "alle Personen wählbar")
	await press(find_button(list, "RolePerson_2"))
	var card := find_node(screen, "RoleCardLayer")
	assert_true(card != null, "Karte offen")
	assert_eq(_card_role(screen), W, "Bild der eigenen Rollenkarte")
	assert_eq(_texts(card).strip_edges(), str(s.role_show_card(2)["name"]), "auf der Karte steht oben nur der Name der Person (keine Rolle, keine Platznummer)")
	assert_eq(_shown_count(s), 0, "Öffnen bestätigt nichts")
	await press(find_button(card, "ConfirmRoleButton"))
	await frames(2)
	assert_eq(_shown_count(s), 1, "genau ein ConfirmRoleShown")
	assert_true(s.role_show_list()["persons"][1]["confirmed"], "Person 2 bestätigt")
	list = find_node(screen, "RoleListLayer")
	assert_true(list != null and find_node(screen, "RoleCardLayer") == null, "zurück zur Liste, Karte entfernt")
	_assert_no_role_names(_texts(screen), "nach dem Schließen")
	assert_true(find_node(screen, "PrivateLayer") == null and find_node(screen, "GmLayer") == null, "keine private Ebene aufgeklappt")
	await press(find_button(list, "CloseLayerButton"))
	assert_eq(str((screen as CockpitScreen).layer_kind()), "", "Cockpit wieder sichtbar")
	assert_true((screen.find_child("Layout", true, false) as Control).visible, "Layout sichtbar")


func test_closing_the_open_card_by_back_changes_nothing() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	var screen := current_screen(shell)
	var before := s.state_hash()
	var list := await _open_list(shell)
	await press(find_button(list, "RolePerson_3"))
	assert_true(find_node(screen, "RoleCardLayer") != null, "Karte offen")
	await go_back(shell)
	assert_true(find_node(screen, "RoleCardLayer") == null, "Karte weg")
	_assert_no_role_names(_texts(screen), "nach Zurück")
	assert_eq(_shown_count(s), 0, "nichts bestätigt")
	assert_eq(s.state_hash(), before, "Zustand unverändert")
	assert_eq(int(s.role_show_list()["next_id"]), 1, "Fortsetzung weiter bei Person 1")


func test_reread_of_confirmed_role_needs_no_command_and_changes_no_state() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	var screen := current_screen(shell)
	assert_true(s.confirm_role_shown(3).ok, "vorab bestätigt")
	var before := s.state_hash()
	var commands_before := s.commands().size()
	var list := await _open_list(shell)
	await press(find_button(list, "RolePerson_3"))
	var card := find_node(screen, "RoleCardLayer")
	assert_eq(_card_role(screen), "waldhexe", "Rolle erneut lesbar")
	assert_true(find_node(card, "ConfirmRoleButton") == null, "keine zweite Bestätigung angeboten")
	await press(find_button(card, "CloseRoleButton"))
	assert_eq(s.commands().size(), commands_before, "kein neuer Befehl")
	assert_eq(s.state_hash(), before, "Spielzustand unverändert")


func test_resume_after_restart_continues_with_first_unconfirmed_person() -> void:
	var s := UiGame.session(ROLES)
	for id: int in [1, 2, 3]:
		assert_true(s.confirm_role_shown(id).ok, "Bestätigung %d" % id)
	var shell := await spawn_shell()
	if shell == null:
		return
	assert_eq(session_of(shell).call("load_text", s.save_text()), &"", "Neustart: Laden")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var list := await _open_list(shell)
	assert_eq(int((session_of(shell) as GameSession).role_show_list()["next_id"]), 4, "Fortsetzung bei der vierten Person")
	assert_true(list.find_child("RolePersonNext_4", true, false) != null, "vierte Person als Fortsetzung markiert")
	assert_true(list.find_child("RolePersonNext_5", true, false) == null, "nur eine Fortsetzung markiert")
	assert_true(find_button(list, "RolePerson_4") != null, "Person 4 wählbar")


## AUDIT-2026-10-02 S-02 (Entscheidung Markus: Geheimhaltung geht vor): Nach einem geheimen Rollenwechsel bleibt die Person in der
## neutralen Liste „gesehen“ und der Zähler unverändert (sonst verriete die Liste den Wechsel, z. B. den Lehrling). Nur die
## private Karte zeigt, dass die neue Rolle noch nicht gesehen wurde, und erlaubt das erneute Zeigen.
func test_role_change_keeps_person_seen_in_the_neutral_list() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.confirm_role_shown(1).ok, "Person 1 gesehen")
	assert_true(s.gm_correction({"kind": "set_role", "target_id": 1, "role_id": "waldhexe", "reason": "Test"}).ok, "Rollenwechsel")
	var entry: Dictionary = s.role_show_list()["persons"][0]
	assert_true(bool(entry["confirmed"]), "neutrale Liste: weiterhin gesehen")
	assert_eq(int(s.role_show_list()["next_id"]), 2, "Fortsetzung unverändert bei Person 2")
	assert_eq(int(s.role_show_list()["confirmed_count"]), 1, "Zähler unverändert")
	assert_false(bool(s.role_show_card(1)["confirmed"]), "private Karte: neue Rolle noch nicht gesehen")
	assert_true(s.confirm_role_shown(1).ok, "neue Rolle bestätigbar")


func test_open_card_is_discarded_on_state_change_and_undo() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	var screen := current_screen(shell)
	var list := await _open_list(shell)
	await press(find_button(list, "RolePerson_2"))
	assert_eq(_card_role(screen), W, "Karte zeigt die Rolle")
	# Zustandswechsel im Hintergrund (Rollenwechsel per Korrektur): die alte Karte darf nicht stehen bleiben.
	assert_true(s.gm_correction({"kind": "set_role", "target_id": 2, "role_id": "schutzengel", "reason": "Test"}).ok, "Rollenwechsel")
	await frames(2)
	assert_true(find_node(screen, "RoleCardLayer") == null, "Karte verworfen")
	assert_eq(_card_role(screen), "", "kein Kartenbild mehr im Baum")
	_assert_no_role_names(_texts(screen), "nach Zustandswechsel")
	assert_true(find_node(screen, "RoleListLayer") != null, "neutrale Liste")
	# Rückgängig ersetzt den Zustand: auch dann keine alte Karte.
	await press(find_button(find_node(screen, "RoleListLayer"), "RolePerson_2"))
	assert_true(s.undo(), "Rückgängig")
	await frames(2)
	assert_true(find_node(screen, "RoleCardLayer") == null and _card_role(screen) == "", "Karte nach Undo verworfen")
	_assert_no_role_names(_texts(screen), "nach Undo")


func test_cover_closes_role_layers_and_screen_exit_removes_them() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var screen := current_screen(shell)
	var list := await _open_list(shell)
	await press(find_button(list, "RolePerson_2"))
	(screen as CockpitScreen).cover()
	await frames(2)
	assert_true(find_node(screen, "RoleCardLayer") == null and _card_role(screen) == "", "Sichtschutz entfernt die Karte")
	_assert_no_role_names(_texts(screen), "im Sichtschutz")


func test_trugbilderwolf_card_through_buttons_never_shows_appearance() -> void:
	var shell := await _cockpit([D, "trugbilderwolf", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], {"2": "schutzengel"})
	if shell == null:
		return
	var screen := current_screen(shell)
	var list := await _open_list(shell)
	await press(find_button(list, "RolePerson_2"))
	assert_eq(_card_role(screen), "trugbilderwolf", "wahre Rolle, nicht die Scheinrolle")


func test_no_obligation_start_night_works_without_any_confirmation() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var screen := current_screen(shell)
	var start := find_button(screen, "StartNightButton")
	assert_true(start != null and not start.disabled, "StartNight ohne Rollenanzeige möglich")
	var entry := find_button(screen, "ShowRolesButton")
	assert_true(entry != null, "Einstieg auch auf der Startkarte")
	await press(entry)
	assert_true(find_node(screen, "RoleListLayer") != null, "öffnet die Liste")


func test_entry_button_is_disabled_without_game_and_has_both_languages() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	assert_true(find_button(current_screen(shell), "RolesButton").disabled, "ohne Partie gesperrt")
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for key: String in ["ui.cockpit.tools.roles", "ui.cockpit.roles.heading", "ui.cockpit.roles.progress", "ui.cockpit.action.show_roles"]:
			assert_true(po.has(key) and str(po[key]) != "", "%s: %s" % [path.get_file(), key])
