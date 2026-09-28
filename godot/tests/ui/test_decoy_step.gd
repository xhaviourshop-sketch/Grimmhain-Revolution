extends UiTestCase
## Trugbilderwolf-Scheinrolle in der Oberfläche (DR-08): ausdrückliche Wahl im geheimen
## Bereich des Rollenschritts, Anzeige in der Verteilung, Geheimhaltung, Dialog und Layout.

const FIXED_SEED := 818181
const ROLE_IDS: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
		"sensentraeger", "wolfskind", "lehrling", "manipulator", "spiegelwolf", "siegreicher-wolf", "doppelspion", "selbstmoerder", "dorfchronistin", "die-gebundenen", "waldlaeufer", "doktor", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "ritter", "faehrtenleser", "besessener-wolf", "korrupter-richter", "waechter-am-tor", "blutwolf", "spuerhund", "parasit", "schattenhund", "albtraumwolf", "giftwolf", "rudelvater", "seuchenwolf", "fenrir", "cerberus", "henker", "traumdeuter", "kopfgeldjaeger", "koenig", "kriegerin-des-lichts", "blutpriester", "amalia", "detektiv", "die-ewigen", "der-weise", "maertyrerin", "schutzgeist", "dorfschmied", "verdammniswaechter", "loki", "rotkaeppchen", "schwarze-witwe", "schattenwanderer", "seelentauscher", "daemonischer-wolf", "koenig-lykaon", "kutscher", "dr-victor-frankenstein", "rattenfaenger", "pestbringerin", "prophet-des-untergangs", "todesprediger", "feuerteufel", "voodoo-priester", "nekromant", "hades"]


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control


func _view(shell: Control) -> Dictionary:
	return setup_of(shell).call("view") as Dictionary


func _label(root: Node, node_name: String) -> String:
	var label := find_node(root, node_name) as Label
	return label.text if label != null else ""


func _role_names() -> Array[String]:
	var names: Array[String] = []
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for role: String in ROLE_IDS:
			var k := "ui.role.%s.name" % role.replace("-", "_")
			if po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


## Scheinrollen-Namen (alle Nicht-Wolf-Rollen) in DE und EN.
func _appearance_names() -> Array[String]:
	var names: Array[String] = []
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for role: String in ROLE_IDS:
			if RoleCatalog.counts_as_wolf(StringName(role)):
				continue
			var k := "ui.role.%s.name" % role.replace("-", "_")
			if po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


func _contains_any(text: String, names: Array[String]) -> String:
	for n: String in names:
		if text.contains(n):
			return n
	return ""


func _to_roles(shell: Control, count: int) -> Control:
	var screen := await open_new_game(shell)
	setup_of(shell).set("seed_source", func() -> int: return FIXED_SEED)
	await seed_names(shell, numbered_names(count))
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	return screen


func _set_counts(shell: Control, counts: Dictionary) -> void:
	for role: Variant in counts:
		setup_of(shell).call("set_role_count", StringName(str(role)), int(counts[role]))
	await frames(2)


func _copy_rows(screen: Node) -> Array[Control]:
	var out: Array[Control] = []
	var list := find_node(screen, "DecoyCopyList")
	if list == null:
		return out
	for child: Node in list.get_children():
		if child is Control and child.get("copy_id") != null and (child as Control).visible:
			out.append(child as Control)
	return out


func _choose_appearance(shell: Control, row: Control, role: String) -> void:
	await press(find_button(row, "ChooseAppearanceButton"))
	await press(find_button(_dialog(shell), "Appear_%s" % role))


## Öffentliche Texte außerhalb geöffneter geheimer Bereiche dürfen keine Scheinrolle nennen.
func _assert_public_secret(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var names := _appearance_names()
	for c: Control in text_controls(screen):
		var found := _contains_any(text_of(c), names)
		if found == "":
			continue
		var in_decoy := find_node(screen, "DecoySecretPanel") != null and (find_node(screen, "DecoySecretPanel") as Control).is_ancestor_of(c)
		var in_assignment := find_node(screen, "AssignmentPanel") != null and (find_node(screen, "AssignmentPanel") as Control).is_ancestor_of(c)
		var assignment_open := find_node(screen, "SecretHeading") != null and (find_node(screen, "SecretHeading") as Control).is_visible_in_tree()
		var in_role_list := c.name == "RoleNameLabel" or c.name == "RoleShortLabel" or String(c.name).begins_with("FactionHeading")
		assert_true(in_decoy or (in_assignment and assignment_open) or in_role_list, "%s: %s nennt „%s“ außerhalb eines geöffneten geheimen Bereichs" % [label, c.name, found])
	var toast := _label(shell.call("get_toast") as Control, "MessageLabel")
	assert_eq(_contains_any(toast, _role_names()), "", "%s: Statusmeldung ohne Rolle (%s)" % [label, toast])
	for chip: String in ["StepLabel", "StepChip_players", "StepChip_roles", "StepChip_distribution"]:
		assert_eq(_contains_any(_label(screen, chip), _role_names()), "", "%s: Fortschritt ohne Rolle" % label)
	var dialog := _dialog(shell)
	if dialog.visible:
		assert_eq(_contains_any(_label(dialog, "TitleLabel"), _role_names()), "", "%s: Dialogtitel ohne Rolle" % label)


# --- Rollenschritt ------------------------------------------------------------------------------------

func test_missing_appearance_is_shown_and_blocks() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 8)
	await _set_counts(shell, {"manipulator": 1, "dorfbewohner": 6})
	var decoy_row: Control = null
	for row: Node in find_node(screen, "RoleList").find_children("*", "RoleRow", true, false):
		if str(row.get("role_id")) == "trugbilderwolf":
			decoy_row = row as Control
	if decoy_row == null:
		fail("Trugbilderwolf-Zeile fehlt")
		return
	await press(find_button(decoy_row, "PlusButton"))
	var section := find_node(screen, "DecoySection") as Control
	assert_true(section != null and section.is_visible_in_tree(), "Scheinrollen-Bereich erscheint mit der Kopie")
	var status := _label(screen, "DecoyStatusLabel")
	assert_eq(status, tr("ui.setup.decoy.status").format({"configured": 0, "total": 1}), "fehlende Auswahl als Text: %s" % status)
	assert_true(_label(screen, "RoleIssuesLabel").contains(tr("ui.setup.roles.issue.missing_appearance")), "Fehlerliste nennt die fehlende Scheinrolle")
	assert_true(find_button(screen, "ConfirmRolesButton").disabled, "Bestätigen gesperrt")
	var panel := find_node(screen, "DecoySecretPanel") as Control
	assert_false(panel.is_visible_in_tree(), "geheimer Bereich zunächst geschlossen")
	await _assert_public_secret(shell, "geschlossen")
	await press(find_button(screen, "DecoyRevealButton"))
	assert_true(panel.is_visible_in_tree() and (find_node(screen, "DecoySecretHeading") as Control).is_visible_in_tree(), "bewusst geöffnet und als geheim markiert")
	var rows := _copy_rows(screen)
	assert_eq(rows.size(), 1, "eine Kopie")
	assert_eq(_label(rows[0], "DecoyCopyLabel"), tr("ui.setup.decoy.copy").format({"number": 1}), "„Trugbilderwolf 1“")
	assert_eq(_label(rows[0], "DecoyAppearanceLabel"), tr("ui.setup.decoy.missing"), "„Scheinrolle fehlt“")
	var dialog := _dialog(shell)
	var choose := find_button(rows[0], "ChooseAppearanceButton")
	choose.grab_focus()
	await press(choose)
	assert_true(dialog.visible, "Auswahl im modalen Dialog")
	assert_eq(_contains_any(_label(dialog, "TitleLabel"), _role_names()), "", "Titel ohne Rolle")
	var options: Array[String] = []
	for b: BaseButton in visible_buttons(dialog):
		if String(b.name).begins_with("Appear_"):
			options.append(String(b.name).trim_prefix("Appear_"))
			assert_eq(b.text, tr("ui.role.%s.name" % String(b.name).trim_prefix("Appear_").replace("-", "_")), "lokalisierter Name")
	options.sort()
	assert_eq(options, ["amalia", "blutpriester", "das-orakel", "der-weise", "detektiv", "die-ewigen", "die-gebundenen", "doktor", "doppelspion", "dorfbewohner", "dorfchronistin", "dorfschmied", "dorfwache", "dr-victor-frankenstein", "faehrtenleser", "feuerteufel", "hades", "henker", "koenig", "kopfgeldjaeger", "korrupter-richter", "kriegerin-des-lichts", "kutscher", "lehrling", "loki", "maertyrerin", "manipulator", "nachtwaechter", "nekromant", "parasit", "pestbringerin", "prophet-des-untergangs", "rattenfaenger", "ritter", "rotkaeppchen", "schutzengel", "schutzgeist", "seelentauscher", "selbstmoerder", "sensentraeger", "spuerhund", "todesprediger", "traumdeuter", "verdammniswaechter", "voodoo-priester", "waechter-am-tor", "wahnsinniger-kutscher", "waldhexe", "waldlaeufer", "wolfskind"] as Array[String], "nur Nicht-Wolf-Rollen, auch außerhalb des Pools")
	for i: int in 10:
		await key(KEY_TAB)
		assert_true(dialog.is_ancestor_of(focus_owner()), "Fokus bleibt im Dialog (%d)" % i)
	await key(KEY_ESCAPE)
	assert_false(dialog.visible, "Escape bricht ab")
	assert_eq(str((_view(shell)["roles"]["decoys"] as Array)[0]["appears_as"]), "", "Abbruch wählt nichts")
	assert_true(choose.has_focus(), "Fokus zurück zur Kopie")
	await _choose_appearance(shell, rows[0], "waldhexe")
	assert_eq(_label(_copy_rows(screen)[0], "DecoyAppearanceLabel"), tr("ui.setup.decoy.chosen").format({"role": tr("ui.role.waldhexe.name")}), "gewählte Scheinrolle sichtbar")
	assert_false(_label(_copy_rows(screen)[0], "DecoyAppearanceLabel").contains(tr("ui.setup.decoy.missing")), "keine Fehlmeldung mehr")
	assert_false(find_button(screen, "ConfirmRolesButton").disabled, "jetzt bestätigbar")
	await _assert_public_secret(shell, "gewählt")


func test_closing_secret_area_removes_focus_and_input() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 8)
	await _set_counts(shell, {"trugbilderwolf": 1, "manipulator": 1, "dorfbewohner": 6})
	var reveal := find_button(screen, "DecoyRevealButton")
	await press(reveal)
	var choose := find_button(_copy_rows(screen)[0], "ChooseAppearanceButton")
	choose.grab_focus()
	await frames(1)
	await press(reveal)
	var panel := find_node(screen, "DecoySecretPanel") as Control
	assert_false(panel.is_visible_in_tree(), "geschlossen")
	var owner := focus_owner()
	assert_true(owner == null or not panel.is_ancestor_of(owner), "kein Fokus im geschlossenen Bereich")
	assert_true(reveal.has_focus(), "Fokus auf dem Öffnen-Button")
	for b: BaseButton in visible_buttons(screen):
		assert_false(panel.is_ancestor_of(b), "keine bedienbaren Elemente im geschlossenen Bereich (%s)" % b.name)
	await press(reveal)
	await press(find_button(screen, "BackButton"))
	assert_eq(str(_view(shell)["step"]), "players", "Schritt verlassen")
	await press(find_button(screen, "ToRolesButton"))
	assert_false(panel.is_visible_in_tree(), "beim Verlassen geschlossen")
	assert_eq((_view(shell)["roles"]["decoys"] as Array).size(), 1, "Navigation verliert nichts")


func test_two_copies_and_removing_a_configured_copy() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 10)
	await _set_counts(shell, {"trugbilderwolf": 2, "manipulator": 1, "dorfbewohner": 7})
	await press(find_button(screen, "DecoyRevealButton"))
	var rows := _copy_rows(screen)
	assert_eq(rows.size(), 2, "zwei Kopien")
	assert_eq(_label(rows[1], "DecoyCopyLabel"), tr("ui.setup.decoy.copy").format({"number": 2}), "„Trugbilderwolf 2“")
	await _choose_appearance(shell, rows[0], "waldhexe")
	await _choose_appearance(shell, _copy_rows(screen)[1], "das-orakel")
	var decoys: Array = _view(shell)["roles"]["decoys"]
	assert_true(str(decoys[0]["appears_as"]) == "waldhexe" and str(decoys[1]["appears_as"]) == "das-orakel", "unterschiedlich konfiguriert")
	settings_of(shell).call("set_language", "en")
	await frames(3)
	assert_eq(_view(shell)["roles"]["decoys"], decoys, "Sprachwechsel verliert nichts")
	assert_eq(_label(_copy_rows(screen)[1], "DecoyAppearanceLabel"), tr("ui.setup.decoy.chosen").format({"role": "The Oracle"}), "englisch angezeigt")
	settings_of(shell).call("set_language", "de")
	await frames(3)
	var dialog := _dialog(shell)
	await press(find_button(_copy_rows(screen)[1], "RemoveCopyButton"))
	assert_true(dialog.visible, "konfigurierte Kopie: Rückfrage")
	assert_true(_label(dialog, "MessageLabel").contains(tr("ui.setup.decoy.copy").format({"number": 2})), "Rückfrage nennt die Kopie: %s" % _label(dialog, "MessageLabel"))
	assert_eq(_contains_any(_label(dialog, "TitleLabel"), _role_names()), "", "Titel ohne Rolle")
	await press(find_button(dialog, "CancelButton"))
	assert_eq((_view(shell)["roles"]["decoys"] as Array).size(), 2, "Abbruch behält die Kopie")
	await press(find_button(_copy_rows(screen)[1], "RemoveCopyButton"))
	await press(find_button(dialog, "ConfirmButton"))
	decoys = _view(shell)["roles"]["decoys"]
	assert_true(decoys.size() == 1 and str(decoys[0]["appears_as"]) == "waldhexe", "Kopie 1 bleibt unverändert")


# --- Verteilung ---------------------------------------------------------------------------------------

func _to_distribution_with_copies(shell: Control) -> Control:
	var screen := await _to_roles(shell, 10)
	await _set_counts(shell, {"trugbilderwolf": 2, "werwolf": 1, "manipulator": 1, "dorfbewohner": 6})
	var s := setup_of(shell)
	var decoys: Array = _view(shell)["roles"]["decoys"]
	s.call("set_decoy_appearance", int(decoys[0]["copy_id"]), &"waldhexe")
	s.call("set_decoy_appearance", int(decoys[1]["copy_id"]), &"das-orakel")
	await frames(2)
	await press(find_button(screen, "ConfirmRolesButton"))
	return screen


func test_distribution_shows_chosen_appearance_only_when_open() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var session := session_of(shell)
	var screen := await _to_distribution_with_copies(shell)
	assert_eq(str(_view(shell)["step"]), "distribution", "Verteilung erreicht")
	await press(find_button(screen, "DistributeButton"))
	await _assert_public_secret(shell, "verteilt, geschlossen")
	await press(find_button(screen, "RevealButton"))
	var entries: Array = _view(shell)["distribution"]["assignment"]
	var shown := 0
	for i: int in entries.size():
		var e: Dictionary = entries[i]
		if str(e["role"]) == "trugbilderwolf":
			shown += 1
			var rows := find_node(screen, "AssignmentList").get_children()
			var text := _label(rows[i], "AppearanceLabel")
			assert_eq(text, tr("ui.setup.distribution.appearance").format({"role": tr("ui.role.%s.name" % str(e["appearance"]).replace("-", "_"))}), "Scheinrolle geöffnet sichtbar")
			assert_false(text.contains("vorläufig") or text.contains("provisional"), "nicht mehr „vorläufig“")
	assert_eq(shown, 2, "beide Kopien verteilt")
	await press(find_button(screen, "ReshuffleButton"))
	await _assert_public_secret(shell, "neu gemischt")
	await press(find_button(screen, "ConfirmDistributionButton"))
	await _assert_public_secret(shell, "bestätigt")
	var view: Dictionary = session.call("view")
	assert_false(bool(view["has_game"]), "kein GameState")
	assert_eq(int(view["command_count"]), 0, "kein StartGame")


func test_manual_picker_offers_each_copy() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_distribution_with_copies(shell)
	await press(find_button(screen, "ModeManualButton"))
	var dialog := _dialog(shell)
	var rows := find_node(screen, "AssignmentList").get_children()
	await press(find_button(rows[0], "ChooseRoleButton"))
	assert_true(dialog.visible, "Rollenauswahl offen")
	var decoys: Array = _view(shell)["roles"]["decoys"]
	for i: int in 2:
		var option := find_node(dialog, "Pick_trugbilderwolf_%d" % int(decoys[i]["copy_id"])) as Button
		assert_true(option != null and option.is_visible_in_tree(), "Kopie %d einzeln wählbar" % (i + 1))
		if option != null:
			assert_true(option.text.contains(tr("ui.setup.decoy.copy").format({"number": i + 1})), "Option nennt die Kopie: %s" % option.text)
	assert_true(find_node(dialog, "Pick_trugbilderwolf") == null, "keine unbestimmte Trugbilderwolf-Option")
	await press(find_button(dialog, "Pick_trugbilderwolf_%d" % int(decoys[1]["copy_id"])))
	var first: Dictionary = (_view(shell)["distribution"]["assignment"] as Array)[0]
	assert_true(str(first["role"]) == "trugbilderwolf" and str(first["appearance"]) == "das-orakel", "gezielt Kopie 2 mit ihrer Scheinrolle")
	await _assert_public_secret(shell, "manuell")


# --- Layout -------------------------------------------------------------------------------------------

func _check(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var root: Control = screen
	if _dialog(shell).visible:
		root = _dialog(shell)
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
			assert_true(inside(r, viewport), "%s: %s im Viewport" % [label, c.name])
		var min_size := c.get_combined_minimum_size()
		assert_true(min_size.x <= c.size.x + 0.5 and min_size.y <= c.size.y + 0.5, "%s: %s nicht abgeschnitten (min %s, ist %s)" % [label, c.name, min_size, c.size])
		if c is BaseButton:
			buttons.append(c as BaseButton)
			assert_true(c.size.x >= 47.5 and c.size.y >= 47.5, "%s: %s mindestens 48×48 (%s)" % [label, c.name, c.size])
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			assert_false(overlaps(rect_of(buttons[i]), rect_of(buttons[j])), "%s: %s und %s überlappen" % [label, buttons[i].name, buttons[j].name])


func test_decoy_layout() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		for locale: String in ["de", "en"]:
			var shell := await spawn_shell(size, locale)
			if shell == null:
				return
			var screen := await _to_roles(shell, 12)
			await _set_counts(shell, {"trugbilderwolf": 2, "manipulator": 1, "dorfbewohner": 9})
			await press(find_button(screen, "DecoyRevealButton"))
			var scroll := find_node(screen, "RoleScroll") as ScrollContainer
			scroll.ensure_control_visible(find_node(screen, "DecoySection") as Control)
			await frames(3)
			await _check(shell, "%s %s geöffnet" % [size, locale])
			await press(find_button(_copy_rows(screen)[0], "ChooseAppearanceButton"))
			await _check(shell, "%s %s Auswahldialog" % [size, locale])
			await after_each()
