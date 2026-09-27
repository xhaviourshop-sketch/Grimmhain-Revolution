extends UiTestCase
## Setup-Sitzordnung: Oberfläche. Sitzkreis, Tauschen per Antippen und per Drag-and-drop (echte
## Mausereignisse über den Viewport), Abbrechen, Schrittwechsel, Geheimhaltung, DE/EN und Layout
## bei 1024×768, 1280×800 und 1920×1080 mit 6, 12 und 24 Personen. Fester Seed.

const FIXED_SEED := 616161
const ROLE_IDS: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
		"sensentraeger", "wolfskind", "lehrling", "manipulator", "spiegelwolf"]


func _view(shell: Control) -> Dictionary:
	var s := setup_of(shell)
	return s.call("view") as Dictionary if s != null else {}


func _order(shell: Control) -> Array[int]:
	var out: Array[int] = []
	for seat: Variant in (_view(shell).get("seating", {}) as Dictionary).get("seats", []):
		out.append(int((seat as Dictionary)["person_id"]))
	return out


func _roles_by_person(shell: Control) -> Dictionary:
	var out := {}
	for e: Variant in (_view(shell)["distribution"] as Dictionary)["assignment"]:
		out[int((e as Dictionary)["person_id"])] = str((e as Dictionary)["role"])
	return out


func _label(root: Node, node_name: String) -> String:
	var label := find_node(root, node_name) as Label
	return label.text if label != null and label.is_visible_in_tree() else ""


## Neue Partie mit `names`, Vorschlag, Zufallsverteilung, bestätigt; dann per Button zur Sitzordnung.
func _to_seating(shell: Control, names: Array) -> Control:
	var screen := await open_new_game(shell)
	var s := setup_of(shell)
	s.set("seed_source", func() -> int: return FIXED_SEED)
	await seed_names(shell, names)
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	await press(find_button(screen, "SuggestButton"))
	for d: Variant in (s.call("view") as Dictionary)["roles"].get("decoys", []):
		s.call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"waldhexe")
	await frames(2)
	await press(find_button(screen, "ConfirmRolesButton"))
	await press(find_button(screen, "DistributeButton"))
	await press(find_button(screen, "ConfirmDistributionButton"))
	var to_seating := find_button(screen, "ToSeatingButton")
	assert_true(to_seating != null and to_seating.is_visible_in_tree(), "„Weiter zur Sitzordnung“ in der Karte „Bereit für Sitzordnung“")
	await press(to_seating)
	(shell.call("get_toast") as Control).call("hide_message")
	await frames(2)
	return screen


func _circle(screen: Node) -> Control:
	return find_node(screen, "SeatCircle") as Control


## Sichtbare Platzsymbole in Sitzreihenfolge.
func _tokens(screen: Node) -> Array[Control]:
	var out: Array[Control] = []
	var circle := _circle(screen)
	if circle == null or not circle.has_method("tokens"):
		return out
	for t: Variant in circle.call("tokens"):
		out.append(t as Control)
	return out


func _token(screen: Node, person_id: int) -> Control:
	var circle := _circle(screen)
	return circle.call("token_for", person_id) as Control if circle != null and circle.has_method("token_for") else null


func _state(token: Control) -> String:
	return str(token.get("state")) if token != null else ""


## Ziehen mit echten Mausereignissen: drücken, in Schritten bewegen, loslassen.
func _drag(from: Control, to: Vector2) -> void:
	var start := from.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = start
	down.global_position = start
	tree.root.push_input(down)
	await frames(1)
	var last := start
	for i: int in range(1, 11):
		var pos := start.lerp(to, i / 10.0)
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		move.position = pos
		move.global_position = pos
		move.relative = pos - last
		last = pos
		tree.root.push_input(move)
		await frames(1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	up.global_position = to
	tree.root.push_input(up)
	await frames(3)


func _role_names() -> Array[String]:
	var names: Array[String] = []
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for role: String in ROLE_IDS:
			var k := "ui.role.%s.name" % role.replace("-", "_")
			if po.has(k) and not names.has(str(po[k])):
				names.append(str(po[k]))
	return names


func _assert_no_roles_visible(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var names := _role_names()
	for c: Control in text_controls(screen):
		var text := text_of(c)
		for name: String in names:
			assert_false(text.contains(name), "%s: %s zeigt Rolle „%s“" % [label, c.name, name])
	var toast_label := find_node(shell.call("get_toast") as Node, "MessageLabel") as Label
	for name: String in names:
		assert_false(toast_label != null and toast_label.text.contains(name), "%s: Statusmeldung ohne Rolle" % label)


# --- Einstieg und Darstellung -------------------------------------------------------------------------

func test_ready_card_leads_to_seating_step() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_seating(shell, numbered_names(10))
	assert_eq(str(_view(shell)["step"]), "seating", "Schritt Sitzordnung aktiv")
	var step := find_node(screen, "SeatingStep") as Control
	assert_true(step != null and step.is_visible_in_tree(), "Sitzordnung sichtbar")
	assert_false((find_node(screen, "DistributionStep") as Control).is_visible_in_tree(), "Verteilung ausgeblendet")
	var progress := _label(screen, "StepLabel")
	assert_true(progress.contains("4") and progress.contains("Sitzordnung"), "Schrittanzeige 4 von 4: %s" % progress)
	var tokens := _tokens(screen)
	assert_eq(tokens.size(), 10, "zehn Plätze im Kreis")
	var order := _order(shell)
	for i: int in tokens.size():
		assert_eq(int(tokens[i].get("person_id")), order[i], "Platz %d zeigt die Person der Sitzreihenfolge" % (i + 1))
		var text := text_of(tokens[i])
		assert_true(text.contains(str(i + 1)) and text.contains("Person %d" % order[i]), "Platz %d zeigt Nummer und Namen: %s" % [i + 1, text])
	assert_false(find_button(screen, "ConfirmSeatingButton").disabled, "Sitzordnung bestätigbar")
	var session := session_of(shell)
	assert_false(bool((session.call("view") as Dictionary)["has_game"]), "kein GameState")


# --- Tauschen per Antippen ---------------------------------------------------------------------------

func test_tap_to_swap_select_and_cancel() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_seating(shell, numbered_names(8))
	var order := _order(shell)
	var roles := _roles_by_person(shell)
	var a := _token(screen, order[1])
	var b := _token(screen, order[5])
	await press(a as BaseButton)
	assert_eq(_state(a), "selected", "erste Person ausgewählt")
	var selection := _label(screen, "SelectionLabel")
	assert_true(selection.contains("Person %d" % order[1]) and selection.contains("2"), "Auswahl nennt Namen und Platz: %s" % selection)
	assert_true(find_button(screen, "CancelSelectionButton").is_visible_in_tree(), "Auswahl aufheben sichtbar")
	await press(b as BaseButton)
	var after := _order(shell)
	assert_eq(after[1], order[5], "Platz 2 jetzt mit der Person von Platz 6")
	assert_eq(after[5], order[1], "Platz 6 jetzt mit der Person von Platz 2")
	assert_eq(_roles_by_person(shell), roles, "Rollen bleiben an den Personen")
	assert_eq(_state(a), "normal", "Auswahl nach dem Tausch aufgehoben")
	assert_eq(_label(screen, "SelectionLabel"), "", "Auswahlhinweis ausgeblendet")
	var status := _label(screen, "SeatingStatusLabel")
	assert_true(status.contains("Person %d" % order[1]) and status.contains("Person %d" % order[5]), "Rückmeldung nennt beide: %s" % status)
	assert_true((a.get_global_rect().get_center() - b.get_global_rect().get_center()).length() > 1.0, "Symbole stehen an verschiedenen Plätzen")
	assert_eq(int(_tokens(screen)[1].get("person_id")), order[5], "Symbol an Platz 2 zeigt die getauschte Person")
	# Dieselbe Person erneut antippen hebt die Auswahl auf, ohne zu tauschen.
	await press(a as BaseButton)
	await press(a as BaseButton)
	assert_eq(_state(a), "normal", "zweites Antippen hebt Auswahl auf")
	assert_eq(_order(shell), after, "nichts getauscht")
	# „Auswahl aufheben“ und Zurück/Escape heben die Auswahl auf, ohne den Schritt zu verlassen.
	await press(a as BaseButton)
	await press(find_button(screen, "CancelSelectionButton"))
	assert_eq(_state(a), "normal", "Auswahl aufheben")
	await press(a as BaseButton)
	await go_back(shell)
	assert_eq(_state(a), "normal", "Zurück hebt zuerst die Auswahl auf")
	assert_eq(str(_view(shell)["step"]), "seating", "noch in der Sitzordnung")
	assert_eq(_order(shell), after, "Abbrechen ändert nichts")


# --- Drag-and-drop -----------------------------------------------------------------------------------

func test_drag_and_drop_swaps_seats() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_seating(shell, numbered_names(12))
	var order := _order(shell)
	var roles := _roles_by_person(shell)
	var source := _token(screen, order[0])
	var target := _token(screen, order[7])
	await _drag(source, target.get_global_rect().get_center())
	var after := _order(shell)
	assert_eq(after[0], order[7], "gezogene Person tauscht mit dem Ziel (Platz 1)")
	assert_eq(after[7], order[0], "gezogene Person sitzt auf Platz 8")
	assert_eq(_roles_by_person(shell), roles, "Rollen bleiben an den Personen")
	assert_eq(_state(source), "normal", "kein Ziehzustand mehr")
	assert_eq(_state(target), "normal", "keine Zielmarkierung mehr")
	var status := _label(screen, "SeatingStatusLabel")
	assert_true(status.contains("Person %d" % order[0]), "Rückmeldung nach dem Ziehen: %s" % status)


func test_drag_feedback_and_cancel_changes_nothing() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_seating(shell, numbered_names(12))
	var circle := _circle(screen)
	var order := _order(shell)
	var source := _token(screen, order[2])
	var target := _token(screen, order[9])
	# Während des Ziehens: Quelle markiert, Ziel unter dem Zeiger hervorgehoben.
	var data: Variant = source.call("_get_drag_data", Vector2.ZERO)
	assert_true(data is Dictionary, "Ziehen liefert Daten")
	assert_eq(_state(source), "dragging", "Quelle als gezogen markiert")
	assert_true(bool(target.call("_can_drop_data", Vector2.ZERO, data)), "anderer Platz nimmt an")
	assert_eq(_state(target), "target", "Ziel hervorgehoben")
	assert_false(bool(source.call("_can_drop_data", Vector2.ZERO, data)), "eigener Platz nimmt nicht an")
	assert_false(bool(target.call("_can_drop_data", Vector2.ZERO, {"fremd": 1})), "fremde Daten werden abgelehnt")
	circle.call("drag_finished", false)
	await frames(2)
	assert_eq(_state(source), "normal", "Abbruch: Quelle normal")
	assert_eq(_state(target), "normal", "Abbruch: Ziel normal")
	assert_eq(_order(shell), order, "Abbruch ändert nichts")
	assert_true(_label(screen, "SeatingStatusLabel") != "", "Abbruch wird gemeldet")
	# Echtes Ziehen auf die Tischmitte (kein Platz) bricht ebenfalls ohne Änderung ab.
	var center := find_node(screen, "TableCenter") as Control
	await _drag(source, center.get_global_rect().get_center())
	assert_eq(_order(shell), order, "Loslassen neben einem Platz ändert nichts")
	assert_eq(_state(source), "normal", "Quelle nach Abbruch normal")


# --- Bestätigen, Zurück, erneut öffnen ----------------------------------------------------------------

func test_confirm_back_and_reopen() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_seating(shell, numbered_names(9))
	var order := _order(shell)
	await press(_token(screen, order[0]) as BaseButton)
	await press(_token(screen, order[4]) as BaseButton)
	var swapped := _order(shell)
	await press(find_button(screen, "ConfirmSeatingButton"))
	var summary := find_node(screen, "SeatingSummary") as Control
	assert_true(summary != null and summary.is_visible_in_tree(), "Karte „Sitzordnung fertig“ sichtbar")
	assert_true(bool((_view(shell)["seating"] as Dictionary)["ready"]), "Setup-Entwurf vollständig")
	assert_true(find_button(screen, "ConfirmSeatingButton").disabled, "nicht doppelt bestätigbar")
	var session_view := session_of(shell).call("view") as Dictionary
	assert_false(bool(session_view["has_game"]), "kein GameState")
	assert_eq(int(session_view["command_count"]), 0, "kein StartGame oder anderer Befehl")
	# Zurück zur Verteilung und wieder vor: alles bleibt.
	await press(find_button(screen, "EditDistributionButton"))
	assert_eq(str(_view(shell)["step"]), "distribution", "zurück in der Verteilung")
	await press(find_button(screen, "ToSeatingButton"))
	assert_eq(str(_view(shell)["step"]), "seating", "wieder in der Sitzordnung")
	assert_eq(_order(shell), swapped, "Reihenfolge erhalten")
	assert_true((find_node(screen, "SeatingSummary") as Control).is_visible_in_tree(), "weiterhin fertig")
	# Verlassen und erneut öffnen: Der Wizard öffnet im zuletzt aktiven Schritt, alles bleibt.
	await navigate(shell, &"main_menu")
	screen = await open_new_game(shell)
	assert_eq(str(_view(shell)["step"]), "seating", "erneut in der Sitzordnung geöffnet")
	assert_true((find_node(screen, "SeatingStep") as Control).is_visible_in_tree(), "Sitzordnung sichtbar")
	assert_eq(_order(shell), swapped, "Reihenfolge nach erneutem Öffnen erhalten")
	assert_eq(int(_tokens(screen)[0].get("person_id")), swapped[0], "Kreis zeigt die gespeicherte Reihenfolge")
	# Zurück führt schrittweise zur Verteilung.
	await go_back(shell)
	assert_eq(str(_view(shell)["step"]), "distribution", "Zurück: Verteilung")


func test_person_list_change_updates_circle() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_seating(shell, numbered_names(8))
	var s := setup_of(shell)
	var order := _order(shell)
	s.call("remove_person", order[3])
	await frames(2)
	assert_eq(str(_view(shell)["step"]), "players", "Personenänderung führt zurück zu den Spielern")
	s.call("add_person", "Neue Person")
	s.call("confirm")
	s.call("apply_suggestion", true)
	s.call("confirm_roles")
	s.call("distribute_randomly")
	s.call("confirm_distribution")
	s.call("go_to_step", &"seating")
	await frames(3)
	var tokens := _tokens(screen)
	assert_eq(tokens.size(), 8, "wieder acht Plätze")
	assert_true(text_of(tokens[7]).contains("Neue Person"), "neue Person auf dem letzten Platz: %s" % text_of(tokens[7]))
	for t: Control in tokens:
		assert_ne(int(t.get("person_id")), order[3], "entfernte Person hat keinen Platz")
	var invalid := _label(screen, "SeatingInvalidatedLabel")
	assert_eq(invalid, "", "vorher unbestätigte Sitzordnung meldet keinen Invalidierungsgrund")


# --- Geheimhaltung und Sprache ------------------------------------------------------------------------

func test_seating_shows_no_roles_de_en() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_16_10, locale)
		if shell == null:
			return
		var screen := await _to_seating(shell, numbered_names(18))
		_assert_no_roles_visible(shell, "%s Start" % locale)
		var order := _order(shell)
		await press(_token(screen, order[0]) as BaseButton)
		_assert_no_roles_visible(shell, "%s Auswahl" % locale)
		await press(_token(screen, order[1]) as BaseButton)
		_assert_no_roles_visible(shell, "%s getauscht" % locale)
		await press(find_button(screen, "ConfirmSeatingButton"))
		_assert_no_roles_visible(shell, "%s bestätigt" % locale)
		for c: Control in text_controls(screen):
			var k := key_of(c)
			assert_false(k != "" and text_of(c) == k, "%s: %s zeigt Schlüssel statt Text" % [locale, c.name])
		await after_each()


# --- Layout -------------------------------------------------------------------------------------------

func _layout_case(size: Vector2i, locale: String, names: Array, label: String) -> void:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return
	var screen := await _to_seating(shell, names)
	var tokens := _tokens(screen)
	await press(tokens[0] as BaseButton)  # Auswahlzustand mit Hinweis und Abbrechen-Button
	await frames(2)
	var viewport := Rect2(Vector2.ZERO, Vector2(size))
	var circle := rect_of(_circle(screen))
	var center := find_node(screen, "TableCenter") as Control
	assert_eq(tokens.size(), names.size(), "%s: alle Plätze" % label)
	for i: int in tokens.size():
		var r := rect_of(tokens[i])
		assert_true(inside(r, viewport) and inside(r, circle), "%s: Platz %d im Kreisbereich (%s)" % [label, i + 1, r])
		assert_true(r.size.x >= 110.0 and r.size.y >= 47.5, "%s: Platz %d groß genug (%s)" % [label, i + 1, r.size])
		assert_false(overlaps(r, rect_of(center)), "%s: Tischmitte überdeckt Platz %d" % [label, i + 1])
		for j: int in range(i + 1, tokens.size()):
			assert_false(overlaps(r, rect_of(tokens[j])), "%s: Platz %d und %d überlappen" % [label, i + 1, j + 1])
	for c: Control in visible_controls(center):
		if c.size.x > 0.0 and c.size.y > 0.0:
			assert_true(inside(rect_of(c), rect_of(center), 1.0), "%s: %s in der Tischmitte" % [label, c.name])
			var min_size := c.get_combined_minimum_size()
			assert_true(min_size.y <= c.size.y + 0.5, "%s: %s nicht abgeschnitten" % [label, c.name])
			if c is BaseButton:
				assert_true(c.size.y >= 47.5, "%s: %s mindestens 48 hoch" % [label, c.name])
	for name: String in ["EditDistributionButton", "ConfirmSeatingButton", "SeatingStatusLabel", "StepLabel", "BackButton"]:
		var c := find_node(screen, name) as Control
		assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s sichtbar" % [label, name])
		assert_false(c != null and overlaps(rect_of(c), circle) and not _circle(screen).is_ancestor_of(c), "%s: %s überdeckt den Kreis" % [label, name])
	var font := (tokens[0] as Control).get_theme_font_size(&"font_size")
	assert_true(font >= ThemeTokens.FONT_COMPACT, "%s: Namen mindestens %d px (%d)" % [label, ThemeTokens.FONT_COMPACT, font])
	await after_each()


func test_seating_layout_sizes_and_counts() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10, SIZE_WIDE]:
		for count: int in [6, 12, 24]:
			await _layout_case(size, "de", numbered_names(count), "%s DE %d" % [size, count])
	await _layout_case(SIZE_4_3, "en", long_names(24), "1024×768 EN lange Namen 24")
	await _layout_case(SIZE_16_10, "en", long_names(6), "1280×800 EN lange Namen 6")
