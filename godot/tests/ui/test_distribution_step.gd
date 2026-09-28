extends UiTestCase
## Rollen-Setup: Verteilungs-Oberfläche, Geheimhaltung und Layout (Auftrag Rollen, Tests 44,
## 53 bis 57, 63, 64, 72, 74, 80, 81, 84, 85, 87, 89 bis 91). Fester Seed über die Anwendungsschicht.

const FIXED_SEED := 777001
const ROLE_IDS: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
		"sensentraeger", "wolfskind", "lehrling", "manipulator", "spiegelwolf", "siegreicher-wolf", "doppelspion", "selbstmoerder", "dorfchronistin", "die-gebundenen", "waldlaeufer", "doktor", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "ritter", "faehrtenleser", "besessener-wolf", "korrupter-richter", "waechter-am-tor", "blutwolf", "spuerhund", "parasit", "schattenhund", "albtraumwolf", "giftwolf", "rudelvater", "seuchenwolf", "fenrir", "cerberus", "henker", "traumdeuter", "kopfgeldjaeger", "koenig", "kriegerin-des-lichts", "blutpriester", "amalia", "detektiv", "die-ewigen"]


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control if shell != null and shell.has_method("get_dialog") else null


func _view(shell: Control) -> Dictionary:
	var s := setup_of(shell)
	return s.call("view") as Dictionary if s != null else {}


func _dist(shell: Control) -> Dictionary:
	return _view(shell).get("distribution", {}) as Dictionary


func _label(root: Node, node_name: String) -> String:
	var label := find_node(root, node_name) as Label
	return label.text if label != null else ""


## Neue Partie mit `count` Personen und bestätigtem Pool, dann per Button zur Verteilung.
func _to_distribution(shell: Control, count: int = 8, counts: Dictionary = {}) -> Control:
	var screen := await open_new_game(shell)
	var s := setup_of(shell)
	s.set("seed_source", func() -> int: return FIXED_SEED)
	await seed_names(shell, numbered_names(count))
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	if counts.is_empty():
		await press(find_button(screen, "SuggestButton"))
	else:
		for role: Variant in counts:
			s.call("set_role_count", StringName(str(role)), int(counts[role]))
	# DR-08: jede Trugbilderwolf-Kopie (auch aus dem Vorschlag) erhält ausdrücklich eine Scheinrolle.
	for d: Variant in (s.call("view") as Dictionary)["roles"].get("decoys", []):
		s.call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"waldhexe")
	await frames(2)
	await press(find_button(screen, "ConfirmRolesButton"))
	return screen


func _assignment_rows(screen: Node) -> Array[Control]:
	var out: Array[Control] = []
	var list := find_node(screen, "AssignmentList")
	if list == null:
		return out
	for child: Node in list.get_children():
		if child is Control and child.get("person_id") != null and (child as Control).visible:
			out.append(child as Control)
	return out


## Alle Anzeigenamen der Rollen in DE und EN.
func _role_names() -> Array[String]:
	var names: Array[String] = []
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for role: String in ROLE_IDS:
			var k := "ui.role.%s.name" % role.replace("-", "_")
			if po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


func _contains_role(text: String) -> String:
	for name: String in _role_names():
		if text.contains(name):
			return name
	return ""


## Öffentliche Texte: alles Sichtbare außerhalb des markierten Spielleiterbereichs, dazu
## Statusmeldung (Toast) und offene Dialogtitel.
func _assert_public_texts_secret(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var secret := find_node(screen, "AssignmentPanel") as Control
	var heading := find_node(screen, "SecretHeading") as Control
	var revealed := heading != null and heading.is_visible_in_tree()
	for c: Control in text_controls(screen):
		var found := _contains_role(text_of(c))
		if found == "":
			continue
		var inside_secret := secret != null and secret.is_ancestor_of(c)
		assert_true(revealed and inside_secret, "%s: %s zeigt Rolle „%s“ außerhalb des geöffneten Spielleiterbereichs" % [label, c.name, found])
		assert_true(c.tooltip_text == "" or _contains_role(c.tooltip_text) == "" or inside_secret, "%s: Tooltip von %s" % [label, c.name])
	var toast := shell.call("get_toast") as Control
	var toast_text := _label(toast, "MessageLabel")
	assert_eq(_contains_role(toast_text), "", "%s: Statusmeldung ohne Rolle (%s)" % [label, toast_text])
	var dialog := _dialog(shell)
	if dialog != null and dialog.visible:
		assert_eq(_contains_role(_label(dialog, "TitleLabel")), "", "%s: Dialogtitel ohne Rolle" % label)
	assert_eq(_contains_role(String(current_id(shell))), "", "%s: Screen-ID ohne Rolle" % label)


# --- Zufällig -----------------------------------------------------------------------------------------

func test_random_distribution_keeps_roles_hidden() -> void:
	# 44, 72, 74, 91
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_distribution(shell, 10, {"trugbilderwolf": 1, "werwolf": 1, "manipulator": 1, "dorfbewohner": 7})
	assert_eq(str(_view(shell)["step"]), "distribution", "im Verteilungsschritt")
	assert_true((find_node(screen, "DistributionStep") as Control).is_visible_in_tree(), "Verteilung sichtbar")
	for name: String in ["ModeRandomButton", "ModeManualButton", "DistributeButton", "EditRolesButton", "ConfirmDistributionButton", "SecretWarningLabel", "DistributionCountsLabel", "DistributionStatusLabel"]:
		var c := find_node(screen, name) as Control
		assert_true(c != null and c.is_visible_in_tree(), "%s sichtbar" % name)
	assert_true(_label(screen, "DistributionCountsLabel").contains("10"), "Personen und Rollen gezählt")
	assert_true(find_button(screen, "ConfirmDistributionButton").disabled, "vor dem Verteilen nicht bestätigbar")
	assert_true(find_button(screen, "ReshuffleButton") == null or not find_button(screen, "ReshuffleButton").is_visible_in_tree() or find_button(screen, "ReshuffleButton").disabled, "Neu mischen erst nach dem Verteilen")
	await press(find_button(screen, "DistributeButton"))
	assert_eq(_dist(shell)["assigned_count"], 10, "verteilt")
	var rows := _assignment_rows(screen)
	assert_eq(rows.size(), 10, "zehn Personenzeilen")
	for row: Control in rows:
		assert_eq(_label(row, "AssignmentStateLabel"), tr("ui.setup.distribution.assigned"), "Standardansicht: „zugewiesen“")
	assert_false((find_node(screen, "SecretHeading") as Control).is_visible_in_tree(), "Spielleiterbereich zunächst geschlossen")
	await _assert_public_texts_secret(shell, "nach dem Verteilen")
	assert_true(_label(screen, "SeedLabel").contains(str(FIXED_SEED)), "Seed in den technischen Details: %s" % _label(screen, "SeedLabel"))
	var assignment := JSON.stringify(_dist(shell)["assignment"])
	await press(find_button(screen, "RevealButton"))
	assert_true((find_node(screen, "SecretHeading") as Control).is_visible_in_tree(), "Spielleiterbereich bewusst geöffnet")
	var shown: Array[String] = []
	for row: Control in _assignment_rows(screen):
		var role_text := _label(row, "SecretRoleLabel")
		assert_true(_contains_role(role_text) != "", "Rolle im geöffneten Bereich: %s" % role_text)
		shown.append(role_text)
	var entries: Array = _dist(shell)["assignment"]
	for i: int in entries.size():
		var role := str((entries[i] as Dictionary)["role"])
		assert_eq(shown[i], tr("ui.role.%s.name" % role.replace("-", "_")), "Zeile %d zeigt die zugeordnete Rolle" % (i + 1))
		if role == "trugbilderwolf":
			var appearance := _label(_assignment_rows(screen)[i], "AppearanceLabel")
			var expected := tr("ui.role.%s.name" % str((entries[i] as Dictionary)["appearance"]).replace("-", "_"))
			assert_true(appearance.contains(expected) and str((entries[i] as Dictionary)["appearance"]) == "waldhexe", "gewählte Scheinrolle geheim sichtbar: %s" % appearance)
	await _assert_public_texts_secret(shell, "geöffnet")
	settings_of(shell).call("set_language", "en")
	await frames(3)
	assert_eq(JSON.stringify(_dist(shell)["assignment"]), assignment, "Sprachwechsel ändert nichts")
	await press(find_button(screen, "RevealButton"))
	assert_false((find_node(screen, "SecretHeading") as Control).is_visible_in_tree(), "wieder verborgen")
	await press(find_button(screen, "ReshuffleButton"))
	assert_eq(int(_dist(shell)["shuffle_count"]), 1, "Neu mischen per Button")
	await _assert_public_texts_secret(shell, "nach Neu mischen")


func test_confirm_distribution_shows_summary_without_game() -> void:
	# 12 (Zusammenfassung), 80, 81
	var shell := await spawn_shell()
	if shell == null:
		return
	var session := session_of(shell)
	var events := [0]
	session.connect("events_applied", func(_e: Array) -> void: events[0] += 1)
	var screen := await _to_distribution(shell)
	await press(find_button(screen, "DistributeButton"))
	var confirm := find_button(screen, "ConfirmDistributionButton")
	assert_false(confirm.disabled, "vollständig: bestätigbar")
	confirm.pressed.emit()
	confirm.pressed.emit()
	await frames(3)
	assert_true(bool(_dist(shell)["confirmed"]), "bestätigt")
	var summary := find_node(screen, "DistributionSummary") as Control
	assert_true(summary != null and summary.is_visible_in_tree(), "Zusammenfassung sichtbar")
	var text := _label(screen, "SummaryHeading") + " " + _label(screen, "SummaryBody")
	assert_true(text.contains(tr("ui.setup.distribution.summary.heading")), "Bereit für Sitzordnung")
	assert_true(text.contains("8") and text.contains(str(FIXED_SEED)) and text.contains(tr("ui.setup.distribution.mode.random")), "Personen, Modus und Seed: %s" % text)
	assert_true(text.contains(tr("ui.faction.village")), "Rollen nach Fraktion")
	await _assert_public_texts_secret(shell, "bestätigt")
	var view: Dictionary = session.call("view")
	assert_false(bool(view["has_game"]), "kein GameState")
	assert_eq(int(view["command_count"]), 0, "kein StartGame oder anderer Befehl")
	assert_eq(events[0], 0, "keine Spielereignisse")
	assert_eq(current_id(shell), &"new_game", "bleibt in Neue Partie")
	await press(find_button(screen, "EditRolesButton"))
	assert_eq(str(_view(shell)["step"]), "roles", "Rollen bearbeiten führt zurück")
	assert_true(bool(_dist(shell)["confirmed"]), "nur Ansehen hebt nichts auf")
	await key(KEY_ESCAPE)
	assert_eq(str(_view(shell)["step"]), "players", "Escape: Rollen → Spieler")


# --- Manuell ------------------------------------------------------------------------------------------

func test_manual_distribution_with_picker_dialog() -> void:
	# 53 bis 57, 63, 64, 90
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_distribution(shell, 6, {"werwolf": 2, "manipulator": 1, "dorfbewohner": 3})
	var dialog := _dialog(shell)
	await press(find_button(screen, "ModeManualButton"))
	assert_false(dialog.visible, "ohne Zuordnung: Wechsel ohne Rückfrage")
	assert_eq(str(_dist(shell)["mode"]), "manual", "manueller Modus")
	var rows := _assignment_rows(screen)
	assert_eq(rows.size(), 6, "sechs Personen")
	for row: Control in rows:
		assert_eq(_label(row, "AssignmentStateLabel"), tr("ui.setup.distribution.unassigned"), "zunächst nicht zugewiesen")
		assert_true(_label(row, "NumberLabel") != "" and _label(row, "NameLabel") != "", "Nummer und Name")
	assert_true(_label(screen, "RemainingCountLabel").contains("6"), "Restbestand: %s" % _label(screen, "RemainingCountLabel"))
	var choose := find_button(rows[0], "ChooseRoleButton")
	assert_eq(choose.text, tr("ui.setup.distribution.choose"), "Rolle zuweisen")
	choose.grab_focus()
	await press(choose)
	assert_true(dialog.visible, "Rollenauswahl als modaler Dialog")
	assert_eq(_contains_role(_label(dialog, "TitleLabel")), "", "Dialogtitel ohne Rolle")
	var options: Array[String] = []
	for c: Control in visible_buttons(dialog):
		if String(c.name).begins_with("Pick_"):
			options.append(String(c.name).trim_prefix("Pick_"))
	options.sort()
	assert_eq(options, ["dorfbewohner", "manipulator", "werwolf"] as Array[String], "nur verfügbare Rollen des Pools")
	var owner := focus_owner()
	assert_true(owner != null and dialog.is_ancestor_of(owner), "Fokus im Dialog")
	for i: int in 8:
		await key(KEY_TAB)
		owner = focus_owner()
		assert_true(owner != null and dialog.is_ancestor_of(owner), "Tab bleibt im Dialog (%d)" % i)
	await press(find_button(dialog, "Pick_werwolf"))
	assert_false(dialog.visible, "Auswahl schließt den Dialog")
	assert_eq(str((_dist(shell)["assignment"] as Array)[0]["role"]), "werwolf", "zugewiesen")
	assert_true(find_button(_assignment_rows(screen)[0], "ChooseRoleButton").has_focus(), "Fokus zurück zur Zeile")
	assert_eq(_label(_assignment_rows(screen)[0], "AssignmentStateLabel"), tr("ui.setup.distribution.assigned"), "Standardansicht verrät die Rolle nicht")
	assert_true(_label(screen, "RemainingCountLabel").contains("5"), "Rest aktualisiert")
	await _assert_public_texts_secret(shell, "manuell teilweise")
	await press(find_button(_assignment_rows(screen)[1], "ChooseRoleButton"))
	await press(find_button(dialog, "Pick_werwolf"))
	await press(find_button(_assignment_rows(screen)[2], "ChooseRoleButton"))
	assert_true(find_node(dialog, "Pick_werwolf") == null or not (find_node(dialog, "Pick_werwolf") as Control).is_visible_in_tree(), "vergebene Rolle nicht mehr angeboten")
	await key(KEY_ESCAPE)
	assert_false(dialog.visible, "Escape bricht die Auswahl ab")
	assert_eq(str(_view(shell)["step"]), "distribution", "Escape schließt nur den Dialog")
	await press(find_button(_assignment_rows(screen)[0], "ChooseRoleButton"))
	assert_eq(find_button(_assignment_rows(screen)[0], "ChooseRoleButton").text, tr("ui.setup.distribution.change"), "Rolle ändern")
	await press(find_button(dialog, "UnassignOption"))
	assert_eq(str((_dist(shell)["assignment"] as Array)[0]["role"]), "", "Zuweisung entfernt")
	await press(find_button(screen, "ModeRandomButton"))
	assert_true(dialog.visible, "Moduswechsel mit Zuordnung: Rückfrage")
	await press(find_button(dialog, "CancelButton"))
	assert_true(str(_dist(shell)["mode"]) == "manual" and int(_dist(shell)["assigned_count"]) == 1, "Abbruch erhält Modus und Zuordnung")
	await press(find_button(screen, "ModeRandomButton"))
	await press(find_button(dialog, "ConfirmButton"))
	assert_true(str(_dist(shell)["mode"]) == "random" and int(_dist(shell)["assigned_count"]) == 0, "bestätigt: kontrolliert verworfen")


func test_manual_confirm_only_when_complete() -> void:
	# 61, 62
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_distribution(shell, 6, {"werwolf": 1, "manipulator": 1, "dorfbewohner": 4})
	await press(find_button(screen, "ModeManualButton"))
	var s := setup_of(shell)
	var pool: Array = _view(shell)["roles"]["pool"]
	for i: int in 5:
		s.call("assign_role", i + 1, StringName(str(pool[i])))
	await frames(2)
	assert_true(find_button(screen, "ConfirmDistributionButton").disabled, "unvollständig: nicht bestätigbar")
	assert_true(_label(screen, "DistributionStatusLabel") != "" and _contains_role(_label(screen, "DistributionStatusLabel")) == "", "Status ohne Rolle")
	s.call("assign_role", 6, StringName(str(pool[5])))
	await frames(2)
	assert_false(find_button(screen, "ConfirmDistributionButton").disabled, "vollständig: bestätigbar")
	await press(find_button(screen, "ConfirmDistributionButton"))
	assert_true(bool(_dist(shell)["ready_for_seating"]), "bereit für Sitzordnung")


# --- Layout -------------------------------------------------------------------------------------------

func _check_layout(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var scroll := find_node(screen, "AssignmentScroll") as ScrollContainer
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var root: Control = screen
	var dialog := _dialog(shell)
	if dialog != null and dialog.visible:
		root = dialog
	var scrolls: Array[ScrollContainer] = []
	for c: Control in visible_controls(root):
		if c is ScrollContainer:
			scrolls.append(c as ScrollContainer)
	var buttons: Array[BaseButton] = []
	for c: Control in visible_controls(root):
		if c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var r := rect_of(c)
		var host: ScrollContainer = null
		for sc: ScrollContainer in scrolls:
			if sc.is_ancestor_of(c):
				host = sc
		if host != null:
			if not r.intersects(rect_of(host)) or (c is BaseButton and not inside(r, rect_of(host))):
				continue
		else:
			assert_true(inside(r, viewport), "%s: %s im Viewport (%s)" % [label, c.name, r])
		var min_size := c.get_combined_minimum_size()
		assert_true(min_size.x <= c.size.x + 0.5 and min_size.y <= c.size.y + 0.5, "%s: %s nicht abgeschnitten (min %s, ist %s)" % [label, c.name, min_size, c.size])
		if c is BaseButton:
			buttons.append(c as BaseButton)
			assert_true(c.size.x >= 47.5 and c.size.y >= 47.5, "%s: %s mindestens 48×48 (%s)" % [label, c.name, c.size])
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			assert_false(overlaps(rect_of(buttons[i]), rect_of(buttons[j])), "%s: %s und %s überlappen" % [label, buttons[i].name, buttons[j].name])
	if root == screen:
		for name: String in ["BackButton", "StepLabel", "ConfirmDistributionButton", "EditRolesButton", "DistributionStatusLabel", "SecretWarningLabel"]:
			var c := find_node(screen, name) as Control
			assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s erreichbar" % [label, name])
		assert_true(scroll != null and rect_of(scroll).size.y >= 200.0, "%s: Zuordnungsliste behält Platz" % label)


func _layout_case(size: Vector2i, locale: String, label: String, count: int, prepare: Callable) -> void:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return
	var screen := await _to_distribution(shell, count)
	await prepare.call(shell, screen)
	await frames(3)
	await _check_layout(shell, label)
	await after_each()


func test_distribution_layout() -> void:
	# 84, 85, 87, 89
	var none := func(_shell: Control, _screen: Control) -> void:
		pass
	var random_open := func(_shell: Control, screen: Control) -> void:
		await press(find_button(screen, "DistributeButton"))
		await press(find_button(screen, "RevealButton"))
	var manual_dialog := func(_shell: Control, screen: Control) -> void:
		await press(find_button(screen, "ModeManualButton"))
		await press(find_button(_assignment_rows(screen)[0], "ChooseRoleButton"))
	var confirmed := func(_shell: Control, screen: Control) -> void:
		await press(find_button(screen, "DistributeButton"))
		await press(find_button(screen, "ConfirmDistributionButton"))
	await _layout_case(SIZE_4_3, "de", "1024×768 DE Modus", 8, none)
	await _layout_case(SIZE_4_3, "de", "1024×768 DE 24 zufällig geöffnet", 24, random_open)
	await _layout_case(SIZE_4_3, "de", "1024×768 DE manueller Dialog", 24, manual_dialog)
	await _layout_case(SIZE_16_10, "en", "1280×800 EN manueller Dialog", 12, manual_dialog)
	await _layout_case(SIZE_16_10, "de", "1280×800 DE bestätigt", 12, confirmed)
	await _layout_case(SIZE_WIDE, "de", "1920×1080 DE geöffnet", 24, random_open)


func test_assignment_list_scrolls_completely() -> void:
	# 88
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var screen := await _to_distribution(shell, 24)
	await press(find_button(screen, "ModeManualButton"))
	var scroll := find_node(screen, "AssignmentScroll") as ScrollContainer
	var rows := _assignment_rows(screen)
	if scroll == null or rows.size() != 24:
		fail("Zuordnungsliste fehlt")
		return
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await frames(2)
	assert_true(inside(rect_of(rows[23]), rect_of(scroll)), "letzte Person nach Scrollen sichtbar")
	scroll.scroll_vertical = 0
	await frames(2)
	find_button(rows[23], "ChooseRoleButton").grab_focus()
	await frames(3)
	assert_true(inside(rect_of(find_button(rows[23], "ChooseRoleButton")), rect_of(scroll)), "Fokus scrollt mit")
