extends UiTestCase
## Rollen-Setup: Wizard und Rollenwahl-Oberfläche (Auftrag Rollen, Tests 22, 23, 33, 73 bis 83,
## 86 bis 89). Bedienung über Buttons wie Maus und Touch; Vorbereitung über die Anwendungsschicht.

const ROLE_IDS: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
		"sensentraeger", "wolfskind", "lehrling", "manipulator", "spiegelwolf", "siegreicher-wolf", "doppelspion", "selbstmoerder", "dorfchronistin", "die-gebundenen", "waldlaeufer", "doktor", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "ritter", "faehrtenleser", "besessener-wolf", "korrupter-richter", "waechter-am-tor", "blutwolf", "spuerhund", "parasit", "schattenhund", "albtraumwolf", "giftwolf", "rudelvater", "seuchenwolf", "fenrir", "cerberus", "henker", "traumdeuter", "kopfgeldjaeger", "koenig", "kriegerin-des-lichts", "blutpriester", "amalia", "detektiv", "die-ewigen", "der-weise", "maertyrerin", "schutzgeist", "dorfschmied", "verdammniswaechter", "loki", "rotkaeppchen", "schwarze-witwe", "schattenwanderer", "seelentauscher", "daemonischer-wolf", "koenig-lykaon", "schicksalswolf", "kutscher", "dr-victor-frankenstein", "rattenfaenger", "pestbringerin", "prophet-des-untergangs", "todesprediger", "feuerteufel", "voodoo-priester", "nekromant", "hades", "grabraeuber", "rachsuechtiger-wolf", "zeitwaechter"]


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


## Sichtbare Rollenzeilen. Der Kartenschlucker erscheint nur bei eingeschalteten Totenreichkarten (`all` zählt ihn immer mit).
func _role_rows(screen: Node, all: bool = false) -> Array[Control]:
	var out: Array[Control] = []
	var list := find_node(screen, "RoleList")
	if list == null:
		return out
	_collect_rows(list, out)
	return out if all else out.filter(func(row: Control) -> bool: return row.visible)


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
	assert_eq(rows.size(), ROLE_IDS.size(), "eine Zeile je Katalogrolle ohne den Kartenschlucker")
	assert_eq(_role_rows(screen, true).size(), RoleCatalog.ROLES.size(), "der Kartenschlucker hat eine verborgene Zeile")
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
	assert_eq(_label(werwolf, "RoleCountLabel"), "1", "Plus erhöht")
	assert_true(find_button(werwolf, "PlusButton").disabled, "Höchstzahl 1: Plus gesperrt (PE-07)")
	assert_eq(_label(werwolf, "RoleLimitLabel"), tr("ui.setup.roles.limit_once"), "Hinweis „nur einmal zu Spielbeginn“")
	assert_false(_label(werwolf, "RoleLimitLabel").to_lower().contains("partie"), "kein „pro Partie“: spätere gleiche Rollen sind nicht ausgeschlossen")
	await press(find_button(werwolf, "MinusButton"))
	assert_eq(_label(werwolf, "RoleCountLabel"), "0", "Minus verringert")
	assert_false(find_button(werwolf, "PlusButton").disabled, "nach dem Entfernen wieder auswählbar")
	await press(find_button(werwolf, "PlusButton"))
	assert_true(_label(screen, "RoleSelectionCountLabel").contains("1"), "Summe aktualisiert")
	var issues := _label(screen, "RoleIssuesLabel")
	assert_true(issues.contains(tr("ui.setup.roles.issue.missing_village")) and issues.contains(tr("ui.setup.roles.issue.missing_solo")), "fehlende Fraktionen benannt: %s" % issues)
	assert_true(find_button(screen, "ConfirmRolesButton").disabled, "ungültig: Bestätigen gesperrt")
	var villagers := {}
	for role: String in Fixtures.village_fillers(8):
		villagers[role] = 1
	await _set_counts(shell, {"manipulator": 1})
	await _set_counts(shell, villagers)
	assert_eq(_label(screen, "RemainingLabel"), tr("ui.setup.roles.too_many").format({"count": 2}), "2 zu viele")
	var summary := _label(screen, "FactionSummaryLabel")
	assert_true(summary.contains("8") and summary.contains(tr("ui.faction.village")), "Fraktionszusammenfassung als Text: %s" % summary)
	var two_less := {}
	for role: String in Fixtures.village_fillers(8).slice(6):
		two_less[role] = 0
	await _set_counts(shell, two_less)
	assert_eq(_label(screen, "RemainingLabel"), tr("ui.setup.roles.exact"), "passt genau")
	assert_false((find_node(screen, "RoleIssuesLabel") as Control).is_visible_in_tree(), "keine Fehler")
	assert_false(find_button(screen, "ConfirmRolesButton").disabled, "gültig: Bestätigen frei")
	# Technische Grenze: Die Gebundenen (einzige Rolle mit mehr als einer Kopie) bis zur Personenzahl.
	var cleared := {"werwolf": 0, "manipulator": 0, "die-gebundenen": 8}
	for role: String in Fixtures.village_fillers(6):
		cleared[role] = 0
	await _set_counts(shell, cleared)
	var bound := _role_row(screen, "die-gebundenen")
	assert_true(find_button(bound, "PlusButton").disabled, "technische Grenze: Plus gesperrt")
	assert_eq(_label(bound, "RoleLimitLabel"), tr("ui.setup.roles.limit"), "Höchstzahl erreicht (nicht „nur einmal“)")


## PE-07: Ein vorhandener Entwurf mit einer Rolle über der Höchstzahl (hier zwei Dorfbewohner und zwei Werwölfe) wird erklärt, nicht
## still gekürzt: die betroffenen Rollen stehen namentlich in der Fehlerliste, „Bestätigen“ bleibt gesperrt, die Anzahlen bleiben
## bis zur Korrektur durch die Spielleitung. Der Entwurf wird nur als isolierte Testvorbereitung so hergestellt (über die Oberfläche
## ist das nicht mehr möglich).
func test_over_limit_draft_fits_at_1024x768() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_4_3, locale)
		if shell == null:
			return
		await _to_roles(shell, 8)
		var setup := setup_of(shell) as PlayerSetup
		for role: String in ["werwolf", "manipulator", "schutzengel", "das-orakel", "waldhexe", "dorfwache"]:
			setup.set_role_count(StringName(role), 1)
		setup._draft.roles.counts[&"dorfbewohner"] = 2
		setup._draft.roles.counts[&"ritter"] = 2  # zwei betroffene Rollen: längste Fehlerzeile
		setup.changed.emit(setup.view())
		await frames(3)
		await _check_layout(shell, "1024×768 %s über der Höchstzahl" % locale)
		await after_each()


func test_over_limit_draft_is_explained_and_never_trimmed() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_16_10, locale)
		if shell == null:
			return
		var screen := await _to_roles(shell, 8)
		var setup := setup_of(shell) as PlayerSetup
		var village := ["schutzengel", "das-orakel", "waldhexe", "dorfwache"]
		for role: String in ["werwolf", "manipulator"] + village:
			setup.set_role_count(StringName(role), 1)
		setup._draft.roles.counts[&"dorfbewohner"] = 2  # Testvorbereitung: Entwurf über der Höchstzahl
		setup.changed.emit(setup.view())
		await frames(2)
		assert_eq(int(_roles(shell)["total"]), 8, "%s: acht Rollen vorhanden" % locale)
		assert_true((_roles(shell)["issues"] as Array).has("above_maximum"), "%s: Verstoß erkannt" % locale)
		assert_eq(_roles(shell)["over_limit"], ["dorfbewohner"], "%s: betroffene Rolle benannt" % locale)
		var issues := _label(screen, "RoleIssuesLabel")
		assert_true(issues.contains(tr("ui.setup.roles.issue.above_maximum")), "%s: Fehlerliste nennt den Verstoß: %s" % [locale, issues])
		var over := find_node(screen, "OverLimitLabel") as Label
		var role_name := tr("ui.role.dorfbewohner.name")
		assert_true(over != null and over.is_visible_in_tree() and over.text.contains(role_name), "%s: Listenkopf nennt die Rolle „%s“: %s" % [locale, role_name, over.text if over != null else ""])
		assert_true(over.text.contains("einmal" if locale == "de" else "once"), "%s: Text nennt die Regel: %s" % [locale, over.text])
		assert_false(over.text.to_lower().contains("partie") or over.text.to_lower().contains("per game"), "%s: kein „pro Partie“" % locale)
		assert_true(find_button(screen, "ConfirmRolesButton").disabled, "%s: Bestätigen gesperrt" % locale)
		assert_false((_roles(shell)["valid"]) as bool, "%s: Entwurf ungültig" % locale)
		await _check_layout(shell, "1280×800 %s über der Höchstzahl" % locale)
		assert_eq(_label(_role_row(screen, "dorfbewohner"), "RoleCountLabel"), "2", "%s: nicht still gekürzt" % locale)
		# Ein Start ist so nicht möglich: Bestätigen wird abgelehnt, weder Entwurf noch Sitzung noch Zufall ändern sich.
		var draws := [0]
		setup.seed_source = func() -> int:
			draws[0] += 1
			return 1
		var draft_before := JSON.stringify(setup.view())
		var refused := setup.confirm_roles()
		assert_true(not refused.ok and refused.error == &"roles_invalid", "%s: Rollen bestätigen abgelehnt (%s)" % [locale, refused.error])
		assert_false(setup.start_data().ok, "%s: keine Startdaten" % locale)
		assert_eq(JSON.stringify(setup.view()), draft_before, "%s: Entwurf unverändert" % locale)
		assert_eq(draws[0], 0, "%s: kein Zufall verbraucht" % locale)
		assert_false(bool((session_of(shell).call("view") as Dictionary)["has_game"]), "%s: keine Partie entstanden" % locale)
		# Korrektur durch die Spielleitung: ein Dorfbewohner weniger, dafür eine andere Dorfrolle.
		await press(find_button(_role_row(screen, "dorfbewohner"), "MinusButton"))
		assert_eq(_label(_role_row(screen, "dorfbewohner"), "RoleCountLabel"), "1", "%s: Minus korrigiert" % locale)
		await press(find_button(_role_row(screen, "ritter"), "PlusButton"))
		assert_false((_roles(shell)["issues"] as Array).has("above_maximum"), "%s: Verstoß behoben" % locale)
		assert_true((_roles(shell)["over_limit"] as Array).is_empty(), "%s: keine Rolle mehr über der Höchstzahl" % locale)
		assert_false(over.is_visible_in_tree(), "%s: Hinweis im Listenkopf weg" % locale)
		assert_false(find_button(screen, "ConfirmRolesButton").disabled, "%s: Bestätigen frei" % locale)
		await after_each()


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
	var side_scroll := find_node(screen, "RoleSideScroll") as ScrollContainer
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
		var in_side := side_scroll != null and side_scroll.is_ancestor_of(c)
		if in_side:
			continue  # Seitenspalte: eigene Prüfung in _side_column_reachable
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


## `n` verschiedene wirkungsarme Dorfrollen als Anzahlen (PE-07: jede Rolle höchstens einmal).
func _village(n: int) -> Dictionary:
	var out := {}
	for role: String in Fixtures.village_fillers(n):
		out[role] = 1
	return out


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
	# Zweizeilige Fehler der Seitenspalte: eigener Test test_side_column_two_line_issue_stays_reachable.
	await _layout_case(SIZE_4_3, "de", "1024×768 DE Fehler", _village(6).merged({"werwolf": 1}))
	await _layout_case(SIZE_16_10, "en", "1280×800 EN", _village(5).merged({"werwolf": 1, "manipulator": 1}))
	await _layout_case(SIZE_16_10, "de", "1280×800 DE Überschreibdialog", {"werwolf": 1, "dorfbewohner": 1, "amalia": 1, "detektiv": 1}, true)
	await _layout_case(SIZE_4_3, "de", "1024×768 DE Überschreibdialog", {"werwolf": 1, "dorfbewohner": 1, "amalia": 1, "detektiv": 1}, true)
	await _layout_case(SIZE_WIDE, "de", "1920×1080 DE", _village(6).merged({"werwolf": 1, "manipulator": 1}))
	# PE-04: beide Besetzungshinweise zusätzlich zu Fehlern (ungünstigster Platzbedarf der Seitenspalte).
	var hinted := {"werwolf": 1, "blutwolf": 1, "kutscher": 1, "parasit": 1, "voodoo-priester": 1, "dorfbewohner": 1, "amalia": 1, "detektiv": 1}
	await _layout_case(SIZE_4_3, "de", "1024×768 DE Hinweise", hinted)
	await _layout_case(SIZE_16_10, "en", "1280×800 EN Hinweise", hinted)


## Zwei Zeilen in der Fehlermeldung der Seitenspalte (nur Werwolf, keine Dorf- und keine Einzelsiegrolle) schoben die Ansicht bei
## 1024×768 um 24 px aus dem Fenster. Alle Bedienelemente und Hinweise müssen erreichbar bleiben (ggf. per Scrollen der Spalte).
func test_side_column_two_line_issue_stays_reachable() -> void:
	for locale: String in ["de", "en"]:
		await _layout_case(SIZE_4_3, locale, "1024×768 %s zweizeilige Fehler" % locale, {"werwolf": 1})
		await _side_column_reachable(SIZE_4_3, locale, {"werwolf": 1})
		await _side_column_reachable(SIZE_4_3, locale, {"werwolf": 1, "blutwolf": 1, "kutscher": 1, "parasit": 1, "voodoo-priester": 1, "dorfbewohner": 1, "amalia": 1, "detektiv": 1})


## Die Seitenspalte liegt im Fenster; jedes ihrer Elemente ist sichtbar oder per Scrollen der Spalte erreichbar (Scrollen bis zum
## letzten Element, danach liegt es vollständig im sichtbaren Ausschnitt).
func _side_column_reachable(size: Vector2i, locale: String, counts: Dictionary) -> void:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return
	var screen := await _to_roles(shell, 8)
	await _set_counts(shell, counts)
	await frames(3)
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var side := find_node(screen, "RoleSideScroll") as ScrollContainer
	assert_true(side != null and inside(rect_of(side), viewport), "%s %s: Seitenspalte im Fenster (%s)" % [size, locale, rect_of(side) if side != null else Rect2()])
	if side == null:
		return
	var column := find_node(screen, "RoleSideColumn") as Control
	for c: Control in visible_controls(column):
		if c.size.x <= 0.0 or c.size.y <= 0.0 or not c is BaseButton and not c is Label:
			continue
		assert_true(rect_of(c).position.x >= rect_of(side).position.x - 0.5 and rect_of(c).end.x <= rect_of(side).end.x + 0.5, "%s %s: %s nicht seitlich abgeschnitten" % [size, locale, c.name])
	side.scroll_vertical = int(side.get_v_scroll_bar().max_value)
	await frames(2)
	for name: String in ["ResetRolesButton", "RevivalRoundLabel"]:
		var c := find_node(screen, name) as Control
		assert_true(c != null and inside(rect_of(c), rect_of(side)), "%s %s: %s nach Scrollen vollständig sichtbar (%s in %s)" % [size, locale, name, rect_of(c), rect_of(side)])
	side.scroll_vertical = 0
	await frames(2)
	var suggest := find_node(screen, "SuggestButton") as Control
	assert_true(inside(rect_of(suggest), rect_of(side)), "%s %s: Vorschlag oben ohne Scrollen sichtbar" % [size, locale])
	await after_each()


func test_role_list_scrolls_completely() -> void:
	# 88
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var screen := await _to_roles(shell)
	var scroll := find_node(screen, "RoleScroll") as ScrollContainer
	var rows := _role_rows(screen)
	if scroll == null or rows.size() != ROLE_IDS.size():
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
	await _set_counts(shell, {"werwolf": 1, "spiegelwolf": 1, "blutwolf": 1}.merged(_village(5)))
	for c: Control in text_controls(find_node(screen, "RoleStep")):
		var k := key_of(c)
		var shown := text_of(c)
		if c.is_in_group(&"user_content") or (shown == "" and k == ""):
			continue
		if c.name == "RoleCountLabel":
			continue  # reine Zahl
		assert_true(k != "" and de.has(k), "%s nutzt einen Übersetzungsschlüssel (%s)" % [c.name, k])
		assert_true(shown != k, "%s zeigt Text statt Schlüssel" % c.name)


## Totenreichkarten im Rollenschritt: Der Schalter ist standardmäßig aus, schaltet den Kartenschlucker frei und nimmt ihn beim
## Ausschalten wieder aus der Auswahl; die Rolle zählt erst mit Karten als gültig.
func test_death_cards_toggle_unlocks_the_card_swallower() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell)
	var toggle := find_node(screen, "DeathCardsToggle") as CheckButton
	assert_true(toggle != null and not toggle.button_pressed, "Schalter vorhanden und aus")
	var swallower := find_node(screen, "RoleRow_kartenschlucker") as Control
	assert_true(swallower != null and not swallower.visible, "Kartenschlucker ohne Karten verborgen")
	toggle.button_pressed = true
	await frames(3)
	assert_true(swallower.visible, "Kartenschlucker mit Karten sichtbar")
	var plus := find_button(swallower, "PlusButton")
	assert_true(plus != null and not plus.disabled, "Plus frei")
	await press(plus)
	assert_eq(_label(swallower, "RoleCountLabel"), "1", "gewählt")
	toggle.button_pressed = false
	await frames(3)
	assert_false(swallower.visible, "wieder verborgen")
	assert_eq(_label(swallower, "RoleCountLabel"), "0", "Anzahl zurückgesetzt")
