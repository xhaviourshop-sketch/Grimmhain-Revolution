extends UiTestCase
## Rollen-Setup: Wizard und Rollenwahl-Oberfläche (Auftrag Rollen, Tests 22, 23, 33, 73 bis 83,
## 86 bis 89). Bedienung über Buttons wie Maus und Touch; Vorbereitung über die Anwendungsschicht.

const ROLE_IDS: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
		"sensentraeger", "wolfskind", "lehrling", "manipulator", "spiegelwolf", "siegreicher-wolf", "doppelspion", "selbstmoerder", "dorfchronistin", "die-gebundenen", "waldlaeufer", "doktor", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "ritter", "faehrtenleser", "besessener-wolf", "korrupter-richter", "waechter-am-tor", "blutwolf", "spuerhund", "parasit", "schattenhund", "albtraumwolf", "giftwolf", "rudelvater", "seuchenwolf", "fenrir", "cerberus", "henker", "traumdeuter", "kopfgeldjaeger", "koenig", "kriegerin-des-lichts", "blutpriester", "amalia", "detektiv", "die-ewigen"]


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control if shell != null and shell.has_method("get_dialog") else null


func _view(shell: Control) -> Dictionary:
	var s := setup_of(shell)
	return s.call("view") as Dictionary if s != null else {}


func _step(shell: Control) -> String:
	return str(_view(shell).get("step", ""))


func _roles(shell: Control) -> Dictionary:
	return _view(shell).get("roles", {}) as Dictionary


## Neue Partie mit `count` bestätigten Personen, dann per Button zum Rollenschritt.
func _to_roles(shell: Control, count: int = 8) -> Control:
	var screen := await open_new_game(shell)
	await seed_names(shell, numbered_names(count))
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	return screen


func _role_rows(screen: Node) -> Array[Control]:
	var out: Array[Control] = []
	var list := find_node(screen, "RoleList")
	if list == null:
		return out
	_collect_rows(list, out)
	return out


func _collect_rows(node: Node, out: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child is Control and child.get("role_id") != null:
			out.append(child as Control)
		else:
			_collect_rows(child, out)


func _role_row(screen: Node, role: String) -> Control:
	for row: Control in _role_rows(screen):
		if str(row.get("role_id")) == role:
			return row
	fail("Rollenzeile %s fehlt" % role)
	return null


func _label(root: Node, node_name: String) -> String:
	var label := find_node(root, node_name) as Label
	return label.text if label != null else ""


func _set_counts(shell: Control, counts: Dictionary) -> void:
	var s := setup_of(shell)
	for role: Variant in counts:
		s.call("set_role_count", StringName(str(role)), int(counts[role]))
	await frames(2)


func _role_names() -> Array[String]:
	var names: Array[String] = []
	for locale: String in ["de", "en"]:
		var po := po_entries(PO_DE if locale == "de" else PO_EN)
		for role: String in ROLE_IDS:
			var k := "ui.role.%s.name" % role.replace("-", "_")
			if po.has(k):
				names.append(str(po[k]))
	return names


# --- Wizard -------------------------------------------------------------------------------------------

func test_wizard_progress_and_gating() -> void:
	# 73, 74, 76, 77
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	var step_label := find_node(screen, "StepLabel") as Label
	assert_true(step_label != null and step_label.is_visible_in_tree(), "Schrittanzeige sichtbar")
	assert_true(_label(screen, "StepLabel").contains("1") and _label(screen, "StepLabel").contains("4"), "1 von 4: %s" % _label(screen, "StepLabel"))
	for id: String in ["players", "roles", "distribution"]:
		var chip := find_node(screen, "StepChip_%s" % id) as Label
		assert_true(chip != null and chip.is_visible_in_tree() and chip.text != "", "Schrittname %s sichtbar" % id)
	await seed_names(shell, numbered_names(8))
	var to_roles := find_node(screen, "ToRolesButton") as BaseButton
	assert_true(to_roles == null or not to_roles.is_visible_in_tree() or to_roles.disabled, "Rollen vor Bestätigung nicht erreichbar")
	assert_false(bool((setup_of(shell).call("go_to_step", &"roles") as Object).get("ok")), "auch nicht über die Anwendungsschicht")
	await press(find_button(screen, "ConfirmPlayersButton"))
	assert_eq(_step(shell), "players", "Bestätigen bleibt im Spielerschritt")
	assert_true(_label(screen, "StepChip_players").contains(tr("ui.setup.wizard.state.done")), "Spieler als erledigt markiert (Text)")
	to_roles = find_button(screen, "ToRolesButton")
	assert_true(to_roles != null and to_roles.is_visible_in_tree() and not to_roles.disabled, "Weiter zu den Rollen")
	to_roles.pressed.emit()
	to_roles.pressed.emit()
	await frames(3)
	assert_eq(_step(shell), "roles", "Doppelklick landet im Rollenschritt, nicht weiter")
	assert_eq(current_id(shell), &"new_game", "Schritte sind keine eigenen Screen-IDs")
	assert_true(_label(screen, "StepLabel").contains("2"), "2 von 3: %s" % _label(screen, "StepLabel"))
	assert_true((find_node(screen, "RoleStep") as Control).is_visible_in_tree(), "Rollenschritt sichtbar")
	assert_false((find_node(screen, "NameInput") as Control).is_visible_in_tree(), "Spielerschritt verborgen")
	var confirm := find_button(screen, "ConfirmRolesButton")
	assert_true(confirm != null and confirm.disabled, "Rollen bestätigen bei ungültigem Pool gesperrt")
	assert_false(bool((setup_of(shell).call("go_to_step", &"distribution") as Object).get("ok")), "Verteilung vor bestätigten Rollen nicht erreichbar")
	assert_eq(_step(shell), "roles", "Schritt unverändert")
	for id: StringName in SCREEN_IDS:
		assert_false(String(id).contains("role") or String(id).contains("distribution"), "keine Screen-ID je Setup-Schritt (%s)" % id)


func test_back_keeps_data_and_navigation_keeps_pool() -> void:
	# 22, 23, 75
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell)
	await press(find_button(screen, "SuggestButton"))
	var counts: Dictionary = _roles(shell).get("counts", {})
	assert_true(int(_roles(shell).get("total", 0)) == 8, "Vorschlag übernommen")
	await press(find_button(screen, "BackButton"))
	assert_eq(_step(shell), "players", "Zurück von Rollen zu Spielern")
	assert_eq(current_id(shell), &"new_game", "bleibt in Neue Partie")
	assert_eq(row_ids(screen), [1, 2, 3, 4, 5, 6, 7, 8] as Array[int], "Personen erhalten")
	assert_eq(_roles(shell).get("counts", {}), counts, "Rollenauswahl erhalten")
	await press(find_button(screen, "ToRolesButton"))
	assert_eq(_step(shell), "roles", "wieder im Rollenschritt")
	settings_of(shell).call("set_language", "en")
	await frames(3)
	assert_eq(_roles(shell).get("counts", {}), counts, "Sprachwechsel erhält den Pool")
	await navigate(shell, &"settings")
	await navigate(shell, &"main_menu")
	screen = await open_new_game(shell)
	assert_eq(_step(shell), "roles", "wieder geöffnet im selben Schritt")
	assert_eq(_roles(shell).get("counts", {}), counts, "Navigation erhält den Pool")
	assert_eq(int((find_node(_role_row(screen, "werwolf"), "RoleCountLabel") as Label).text), int(counts["werwolf"]), "neu aufgebaute Zeilen zeigen dieselben Zahlen")


func test_leave_uses_existing_draft_dialog() -> void:
	# 78
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell)
	await press(find_button(_role_row(screen, "werwolf"), "PlusButton"))
	var dialog := _dialog(shell)
	await key(KEY_ESCAPE)
	assert_true(not dialog.visible and _step(shell) == "players", "Escape im Rollenschritt: zurück zu Spielern ohne Dialog")
	await press(find_button(screen, "BackButton"))
	assert_true(dialog.visible and current_id(shell) == &"new_game", "unbestätigte Rollenwahl: Rückfrage beim Verlassen")
	assert_eq((find_node(dialog, "TitleLabel") as Label).text, tr("ui.setup.dialog.leave.title"), "bestehender Entwurf-Dialog")
	await press(find_button(dialog, "AlternativeButton"))
	assert_eq(current_id(shell), &"main_menu", "Entwurf behalten")
	assert_eq(int((_roles(shell)["counts"] as Dictionary)["werwolf"]), 1, "Rollenauswahl behalten")


# --- Rollenwahl-Oberfläche ---------------------------------------------------------------------------

func test_role_rows_show_catalog_data() -> void:
	# Oberfläche: Name, Beschreibung, Fraktion als Text, Anzahl, Minus, Plus, Gruppierung
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell)
	var rows := _role_rows(screen)
	assert_eq(rows.size(), RoleCatalog.ROLES.size(), "eine Zeile je Katalogrolle")
	var seen: Array[String] = []
	var faction_order: Array[String] = []
	for row: Control in rows:
		var role := str(row.get("role_id"))
		seen.append(role)
		var faction := String(RoleCatalog.faction_of(StringName(role)))
		if faction_order.is_empty() or faction_order[-1] != faction:
			assert_false(faction_order.has(faction), "Rollen nach Fraktion gruppiert (%s)" % role)
			faction_order.append(faction)
		assert_eq(_label(row, "RoleNameLabel"), tr("ui.role.%s.name" % role.replace("-", "_")), "%s: Name" % role)
		assert_eq(_label(row, "RoleShortLabel"), tr("ui.role.%s.short" % role.replace("-", "_")), "%s: Kurzbeschreibung" % role)
		assert_eq(_label(row, "RoleFactionLabel"), tr("ui.faction.%s" % faction), "%s: Fraktion als Text" % role)
		assert_eq(_label(row, "RoleCountLabel"), "0", "%s: Anzahl" % role)
		var minus := find_button(row, "MinusButton")
		var plus := find_button(row, "PlusButton")
		assert_true(minus != null and minus.disabled, "%s: Minus bei 0 gesperrt" % role)
		assert_true(plus != null and not plus.disabled, "%s: Plus frei" % role)
	seen.sort()
	var expected := ROLE_IDS.duplicate()
	expected.sort()
	assert_eq(seen, expected, "genau die Katalogrollen")
	assert_eq(faction_order, ["village", "wolves", "solo"] as Array[String], "Gruppen Dorf, Werwölfe, Einzelsieg")
	for faction: String in faction_order:
		var heading := find_node(screen, "FactionHeading_%s" % faction) as Label
		assert_true(heading != null and heading.text != "", "Gruppenüberschrift %s" % faction)


func test_counts_summary_and_issues() -> void:
	# 8, 9, 12 bis 18 in der Oberfläche
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell)
	assert_true(_label(screen, "RoleSelectionCountLabel").contains("0") and _label(screen, "RoleSelectionCountLabel").contains("8"), "0 von 8 ausgewählt: %s" % _label(screen, "RoleSelectionCountLabel"))
	assert_eq(_label(screen, "RemainingLabel"), tr("ui.setup.roles.free").format({"count": 8}), "8 Plätze frei")
	var werwolf := _role_row(screen, "werwolf")
	await press(find_button(werwolf, "PlusButton"))
	await press(find_button(werwolf, "PlusButton"))
	assert_eq(_label(werwolf, "RoleCountLabel"), "2", "Plus erhöht")
	await press(find_button(werwolf, "MinusButton"))
	assert_eq(_label(werwolf, "RoleCountLabel"), "1", "Minus verringert")
	assert_true(_label(screen, "RoleSelectionCountLabel").contains("1"), "Summe aktualisiert")
	var issues := _label(screen, "RoleIssuesLabel")
	assert_true(issues.contains(tr("ui.setup.roles.issue.missing_village")) and issues.contains(tr("ui.setup.roles.issue.missing_solo")), "fehlende Fraktionen benannt: %s" % issues)
	assert_true(find_button(screen, "ConfirmRolesButton").disabled, "ungültig: Bestätigen gesperrt")
	await _set_counts(shell, {"manipulator": 1, "dorfbewohner": 8})
	assert_eq(_label(screen, "RemainingLabel"), tr("ui.setup.roles.too_many").format({"count": 2}), "2 zu viele")
	var summary := _label(screen, "FactionSummaryLabel")
	assert_true(summary.contains("8") and summary.contains(tr("ui.faction.village")), "Fraktionszusammenfassung als Text: %s" % summary)
	await _set_counts(shell, {"dorfbewohner": 6})
	assert_eq(_label(screen, "RemainingLabel"), tr("ui.setup.roles.exact"), "passt genau")
	assert_false((find_node(screen, "RoleIssuesLabel") as Control).is_visible_in_tree(), "keine Fehler")
	assert_false(find_button(screen, "ConfirmRolesButton").disabled, "gültig: Bestätigen frei")
	var dorf := _role_row(screen, "dorfbewohner")
	await _set_counts(shell, {"werwolf": 0, "manipulator": 0, "dorfbewohner": 8})
	assert_true(find_button(dorf, "PlusButton").disabled, "technische Grenze: Plus gesperrt")


func test_suggestion_overwrite_needs_confirmation() -> void:
	# 32, 33
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 12)
	var dialog := _dialog(shell)
	var suggest := find_button(screen, "SuggestButton")
	assert_eq(suggest.text, tr("ui.setup.roles.suggest"), "als Vorschlag bezeichnet")
	assert_false(tr("ui.setup.roles.suggest").to_lower().contains("balanc"), "nicht als ausbalanciert bezeichnet")
	await press(suggest)
	assert_false(dialog.visible, "leere Auswahl: ohne Rückfrage")
	var suggested: Dictionary = _roles(shell)["counts"]
	assert_eq(int(_roles(shell)["total"]), 12, "Vorschlag passt zur Personenzahl")
	await press(find_button(_role_row(screen, "schutzengel"), "PlusButton"))
	await press(find_button(_role_row(screen, "dorfbewohner"), "MinusButton"))
	var manual: Dictionary = _roles(shell)["counts"]
	await press(suggest)
	assert_true(dialog.visible, "manuelle Auswahl: Rückfrage vor dem Überschreiben")
	var title := (find_node(dialog, "TitleLabel") as Label).text
	for name: String in _role_names():
		assert_false(title.contains(name), "Dialogtitel nennt keine Rolle (%s)" % name)
	await press(find_button(dialog, "CancelButton"))
	assert_eq(_roles(shell)["counts"], manual, "Abbruch lässt die Auswahl unverändert")
	await press(suggest)
	await press(find_button(dialog, "ConfirmButton"))
	assert_eq(_roles(shell)["counts"], suggested, "Bestätigen übernimmt den Vorschlag")
	await press(find_button(screen, "ResetRolesButton"))
	if dialog.visible:
		await press(find_button(dialog, "ConfirmButton"))
	assert_eq(int(_roles(shell)["total"]), 0, "Auswahl zurückgesetzt")


func test_confirm_roles_creates_no_game() -> void:
	# 19, 77, 79, 81
	var shell := await spawn_shell()
	if shell == null:
		return
	var session := session_of(shell)
	var events := [0]
	session.connect("events_applied", func(_e: Array) -> void: events[0] += 1)
	var screen := await _to_roles(shell)
	await press(find_button(screen, "SuggestButton"))
	var confirm := find_button(screen, "ConfirmRolesButton")
	confirm.pressed.emit()
	confirm.pressed.emit()
	await frames(3)
	assert_true(bool(_roles(shell)["confirmed"]), "Rollen bestätigt")
	assert_eq(_step(shell), "distribution", "wechselt zur Verteilung")
	assert_false(bool(_view(shell)["distribution"]["confirmed"]), "Doppelklick bestätigt keine Verteilung")
	assert_true(_label(screen, "StepLabel").contains("3"), "3 von 3")
	var view: Dictionary = session.call("view")
	assert_false(bool(view["has_game"]), "kein GameState")
	assert_eq(int(view["command_count"]), 0, "kein StartGame oder anderer Befehl")
	assert_eq(events[0], 0, "keine Spielereignisse")


# --- Layout -------------------------------------------------------------------------------------------

func _check_layout(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var scroll := find_node(screen, "RoleScroll") as ScrollContainer
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var root: Control = screen
	var dialog := _dialog(shell)
	if dialog != null and dialog.visible:
		root = dialog
	var buttons: Array[BaseButton] = []
	for c: Control in visible_controls(root):
		if c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var r := rect_of(c)
		var in_scroll := scroll != null and scroll.is_ancestor_of(c)
		if in_scroll:
			if not r.intersects(rect_of(scroll)) or (c is BaseButton and not inside(r, rect_of(scroll))):
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
		for name: String in ["BackButton", "StepLabel", "ConfirmRolesButton", "SuggestButton", "ResetRolesButton", "RoleSelectionCountLabel", "RemainingLabel"]:
			var c := find_node(screen, name) as Control
			assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s erreichbar" % [label, name])
		assert_true(scroll != null and rect_of(scroll).size.y >= 200.0, "%s: Rollenliste behält Platz (%s)" % [label, rect_of(scroll).size if scroll != null else Vector2.ZERO])


func _layout_case(size: Vector2i, locale: String, label: String, counts: Dictionary, open_dialog: bool = false) -> void:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return
	var screen := await _to_roles(shell, 8)
	await _set_counts(shell, counts)
	if open_dialog:
		await press(find_button(screen, "SuggestButton"))
	await frames(3)
	await _check_layout(shell, label)
	await after_each()


func test_role_step_layout() -> void:
	# 82, 83, 86, 87, 89
	await _layout_case(SIZE_4_3, "de", "1024×768 DE leer", {})
	await _layout_case(SIZE_4_3, "de", "1024×768 DE Fehler", {"werwolf": 3, "dorfbewohner": 7})
	await _layout_case(SIZE_16_10, "en", "1280×800 EN", {"werwolf": 2, "manipulator": 1, "dorfbewohner": 5})
	await _layout_case(SIZE_16_10, "de", "1280×800 DE Überschreibdialog", {"werwolf": 2, "dorfbewohner": 3}, true)
	await _layout_case(SIZE_4_3, "de", "1024×768 DE Überschreibdialog", {"werwolf": 2, "dorfbewohner": 3}, true)
	await _layout_case(SIZE_WIDE, "de", "1920×1080 DE", {"werwolf": 1, "manipulator": 1, "dorfbewohner": 6})


func test_role_list_scrolls_completely() -> void:
	# 88
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var screen := await _to_roles(shell)
	var scroll := find_node(screen, "RoleScroll") as ScrollContainer
	var rows := _role_rows(screen)
	if scroll == null or rows.size() != RoleCatalog.ROLES.size():
		fail("Rollenliste fehlt")
		return
	scroll.scroll_vertical = 0
	await frames(2)
	assert_true(inside(rect_of(rows[0]), rect_of(scroll)), "erste Rolle sichtbar")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await frames(2)
	assert_true(inside(rect_of(rows[rows.size() - 1]), rect_of(scroll)), "letzte Rolle nach Scrollen vollständig sichtbar")
	scroll.scroll_vertical = 0
	await frames(2)
	find_button(rows[rows.size() - 1], "PlusButton").grab_focus()
	await frames(3)
	assert_true(inside(rect_of(find_button(rows[rows.size() - 1], "PlusButton")), rect_of(scroll)), "Tastaturfokus scrollt die Rollenliste mit")


func test_role_step_texts_are_keys() -> void:
	# 20 (Lokalisierung), keine festen Texte
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	for k: Variant in de:
		assert_true(en.has(k), "EN hat %s" % k)
	for k: Variant in en:
		assert_true(de.has(k), "DE hat %s" % k)
	for required: String in ["ui.setup.wizard.step.players", "ui.setup.wizard.step.roles", "ui.setup.wizard.step.distribution",
			"ui.setup.wizard.progress", "ui.setup.wizard.state.done", "ui.setup.wizard.state.invalid", "ui.setup.roles.suggest",
			"ui.setup.roles.reset", "ui.setup.roles.confirm", "ui.setup.roles.free", "ui.setup.roles.too_many",
			"ui.setup.dialog.suggest.title", "ui.faction.village", "ui.faction.wolves", "ui.faction.solo"]:
		assert_true(de.has(required) and en.has(required), "Schlüssel %s" % required)
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell)
	await _set_counts(shell, {"werwolf": 3, "dorfbewohner": 7})
	for c: Control in text_controls(find_node(screen, "RoleStep")):
		var k := key_of(c)
		var shown := text_of(c)
		if c.is_in_group(&"user_content") or (shown == "" and k == ""):
			continue
		if c.name == "RoleCountLabel":
			continue  # reine Zahl
		assert_true(k != "" and de.has(k), "%s nutzt einen Übersetzungsschlüssel (%s)" % [c.name, k])
		assert_true(shown != k, "%s zeigt Text statt Schlüssel" % c.name)
