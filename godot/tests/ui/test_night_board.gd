extends UiTestCase
## Nachtbrett (P3): Porträtplätze, Layout bei 6 und 24 Personen auf beiden Zielgrößen, Dock und Laschen, „Verbergen“, Nachtleiste
## (4:3 eingeklappt, 16:10 voll), Zielplatz, Linkshändermodus. Prüft Geometrie und Sichtbarkeit der echten Steuerelemente; ob es gut
## aussieht, zeigen die Screenshots (godot/tools/capture_p3_night.gd), nicht dieser Test.


func _cockpit(size: Vector2i, count: int, left_handed: bool = false) -> Control:
	var shell := await spawn_shell(size, "de")
	if shell == null:
		return null
	if left_handed:
		settings_of(shell).call("set_left_handed", true)
	var r: CommandResult = session_of(shell).call("submit", Fixtures.start_roles(Fixtures.unique_roles(count), 1))
	assert_true(r.ok, "Partie gestartet (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	await frames(2)
	return shell


func _screen(shell: Control) -> Control:
	return current_screen(shell)


func _ring(shell: Control) -> Control:
	return find_node(_screen(shell), "SeatRing") as Control


func _tokens(shell: Control) -> Array:
	return _ring(shell).call("tokens")


## Rechteck in globalen Koordinaten.
func _grect(c: Control) -> Rect2:
	return c.get_global_rect()


## Porträtkreis (als Quadrat) und Schild eines Platzes in globalen Koordinaten.
func _portrait(token: Control) -> Rect2:
	var r: Rect2 = token.call("portrait_rect")
	return Rect2(token.get_global_position() + r.position, r.size)


## Berührt der Kreis (Mitte und Radius des Porträtquadrats) das Rechteck? Porträts sind rund, ihre Quadrate überlappen diagonal.
func _circle_hits(portrait: Rect2, rect: Rect2) -> bool:
	var c := portrait.get_center()
	var nearest := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
	return c.distance_to(nearest) < portrait.size.x * 0.5 - 0.5


func _plate(token: Control) -> Rect2:
	var r: Rect2 = token.call("plate_rect")
	return Rect2(token.get_global_position() + r.position, r.size)


func _start_night(shell: Control) -> void:
	await press(find_button(_screen(shell), "StartNightButton"))


# --- Porträtplätze -----------------------------------------------------------------------------------

func test_portraits_are_unique_large_enough_and_never_overlap() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		for count: int in [6, 24]:
			var shell := await _cockpit(size, count)
			if shell == null:
				return
			var label := "%dx%d, %d Personen" % [size.x, size.y, count]
			var tokens := _tokens(shell)
			assert_eq(tokens.size(), count, "%s: alle Plätze" % label)
			var faces := {}
			var area := _grect(find_node(_screen(shell), "SeatRingArea") as Control)
			for i: int in tokens.size():
				var a := tokens[i] as Control
				var diameter := float(a.get("diameter"))
				assert_true(diameter >= 56.0, "%s: Platz %d Porträt mindestens 56 px (%.0f)" % [label, i + 1, diameter])
				if count >= 13:
					assert_true(diameter >= 66.0, "%s: Platz %d Porträt Ziel 66 px (%.0f)" % [label, i + 1, diameter])
				var number := PortraitAssignment.face_number(int(a.get("person_id")))
				assert_false(faces.has(number), "%s: Gesicht %d doppelt" % [label, number])
				faces[number] = true
				assert_true(inside(_portrait(a), area), "%s: Porträt %d im Brett" % [label, i + 1])
				assert_true(inside(_plate(a), area), "%s: Schild %d im Brett" % [label, i + 1])
				assert_true(_portrait(a).size.x >= float(ThemeTokens.TOUCH_MIN), "%s: Tippfläche %d mindestens 48 px" % [label, i + 1])
				for j: int in range(i + 1, tokens.size()):
					var b := tokens[j] as Control
					assert_false(_portrait(a).get_center().distance_to(_portrait(b).get_center()) < _portrait(a).size.x - 0.5, "%s: Porträts %d und %d überlappen" % [label, i + 1, j + 1])
					assert_false(overlaps(_plate(a), _plate(b)), "%s: Schilder %d und %d überlappen" % [label, i + 1, j + 1])
					assert_false(_circle_hits(_portrait(b), _plate(a)) or _circle_hits(_portrait(a), _plate(b)), "%s: Schild und Porträt %d/%d überlappen" % [label, i + 1, j + 1])
			after_each_shell(shell)


func test_card_dock_plate_and_tabs_leave_every_seat_free() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		for count: int in [6, 24]:
			var shell := await _cockpit(size, count)
			if shell == null:
				return
			await _start_night(shell)
			await frames(2)
			var screen := _screen(shell)
			var label := "%dx%d, %d Personen" % [size.x, size.y, count]
			var window := Rect2(Vector2.ZERO, Vector2(tree.root.get_visible_rect().size))
			var blockers := {
				"Karte": _grect(find_node(screen, "InstructionCard") as Control),
				"Dock": _grect(find_node(screen, "ActionsArea") as Control),
				"Phase": _grect(find_node(screen, "PhaseArea") as Control),
				"Protokoll": _grect(find_node(screen, "LogButton") as Control),
				"Optionen": _grect(find_node(screen, "OptionsButton") as Control),
				"Verbergen": _grect(find_node(screen, "HideButton") as Control),
				"Sichtschutz": _grect(find_node(screen, "CoverButton") as Control),
			}
			var bar := find_node(screen, "OrderBar") as Control
			if bar.is_visible_in_tree():
				blockers["Leiste"] = _grect(bar)
			for name: String in blockers:
				var r: Rect2 = blockers[name]
				assert_true(inside(r, window), "%s: %s liegt im Fenster (%s)" % [label, name, str(r)])
				for t: Variant in _tokens(shell):
					var token := t as Control
					assert_false(_circle_hits(_portrait(token), r) or overlaps(r, _plate(token)), "%s: %s überdeckt Platz %d" % [label, name, int(token.get("person_id"))])
			for tab_name: String in ["LogButton", "OptionsButton"]:
				var tab := find_node(screen, tab_name) as Control
				assert_true(tab.size.x >= float(ThemeTokens.TOUCH_MIN) and tab.size.y >= float(ThemeTokens.TOUCH_MIN), "%s: %s Tippfläche mindestens 48 px (%s)" % [label, tab_name, str(tab.size)])
			for knob_name: String in ["HideButton", "CoverButton", "DockUndoButton", "TimerButton"]:
				var knob := find_node(screen, knob_name) as Control
				assert_true(knob.size.x >= float(ThemeTokens.TOUCH_MIN) - 0.5 and knob.size.y >= float(ThemeTokens.TOUCH_MIN) - 0.5, "%s: %s Tippfläche mindestens 48 px (%s)" % [label, knob_name, str(knob.size)])
			after_each_shell(shell)


func after_each_shell(shell: Control) -> void:
	_spawned.erase(shell)
	shell.get_parent().remove_child(shell)
	shell.free()


func test_tokens_keep_order_identity_and_signals() -> void:
	var shell := await _cockpit(SIZE_16_10, 7)
	if shell == null:
		return
	var tokens := _tokens(shell)
	var ids: Array = tokens.map(func(t: Control) -> int: return int(t.get("person_id")))
	assert_eq(ids, [1, 2, 3, 4, 5, 6, 7], "Sitzreihenfolge und Personen-ID unverändert")
	var tapped: Array = []
	_ring(shell).connect("seat_tapped", func(id: int) -> void: tapped.append(id))
	await _start_night(shell)
	var next: Dictionary = effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])
	var allowed: Array = next["allowed_ids"]
	await press(find_node(_ring(shell), "Seat_%d" % int(allowed[0])) as BaseButton)
	assert_eq(tapped, [int(allowed[0])], "Antippen meldet die Personen-ID über dasselbe Signal")


# --- Hauptaktion im Dock, Zielplatz ------------------------------------------------------------------

func test_main_action_sits_in_the_dock_and_secondary_actions_in_the_card() -> void:
	var shell := await _cockpit(SIZE_16_10, 7)
	if shell == null:
		return
	var screen := _screen(shell)
	var dock := find_node(screen, "NextHost") as Control
	var start := find_button(screen, "StartNightButton")
	# Spielbeginn (Testrunde 1): kein Textkasten, der große Knopf „Spiel beginnen“ steht mittig statt im Dock.
	assert_false(dock.is_ancestor_of(start), "Spielbeginn: großer Knopf nicht im Dock")
	assert_true(start.size.y >= float(ThemeTokens.TOUCH_MIN), "Tippfläche mindestens 48 px")
	await press(start)
	var confirm := find_button(screen, "ConfirmTargetsButton")
	assert_true(confirm != null and dock.is_ancestor_of(confirm), "Auswahl bestätigen im Dock (%s)" % str(confirm))
	assert_true(confirm.disabled, "ohne Auswahl gesperrt")


func test_target_slot_shows_the_choice_and_arrows_cycle_through_allowed_people() -> void:
	var shell := await _cockpit(SIZE_16_10, 7)
	if shell == null:
		return
	var screen := _screen(shell)
	await _start_night(shell)
	var next: Dictionary = effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])
	var allowed: Array = next["allowed_ids"]
	assert_eq(str(next["answer"]), "targets", "Zielwahl")
	assert_true(allowed.size() >= 2, "mindestens zwei wählbare Personen")
	var slot := find_node(screen, "TargetSlot") as Control
	assert_true(slot != null and slot.is_visible_in_tree(), "Zielplatz sichtbar")
	await press(find_button(screen, "TargetNextButton"))
	assert_true(find_node(screen, "SelectionLabel") != null, "Auswahl genannt")
	var first_choice := (find_node(screen, "TargetNameLabel") as Label).text
	assert_true(first_choice.begins_with("%d · " % int(allowed[0])), "Pfeil rechts wählt die erste wählbare Person (%s)" % first_choice)
	assert_false(find_button(screen, "ConfirmTargetsButton").disabled, "Auswahl bestätigbar")
	await press(find_button(screen, "TargetNextButton"))
	var second_choice := (find_node(screen, "TargetNameLabel") as Label).text
	assert_ne(second_choice, first_choice, "Pfeil wechselt zur nächsten Person")
	await press(find_button(screen, "TargetPrevButton"))
	assert_eq((find_node(screen, "TargetNameLabel") as Label).text, first_choice, "Pfeil links geht zurück")
	var wanted := int(allowed[0])
	assert_eq(String(_ring(shell).call("token_for", wanted).get("state")), "selected", "der Platz am Kreis ist gewählt")


# --- Verbergen -----------------------------------------------------------------------------------------

## Nacht bis zur ersten bestätigten Schutzwahl: dann gibt es für die Spielleitung ein Abzeichen.
func _night_with_protection(shell: Control) -> void:
	var s := session_of(shell)
	await _start_night(shell)
	for i: int in 12:
		if not (s.call("board_marks") as Dictionary).is_empty():
			return
		var next: Dictionary = effective_of((s.call("cockpit_view") as Dictionary)["next"])
		if str(next.get("kind")) == "prompt" and str(next.get("answer")) == "targets":
			var ids: Array = next["allowed_ids"]
			await press(find_node(_ring(shell), "Seat_%d" % int(ids[0])) as BaseButton)
		var primary := (find_node(_screen(shell), "ActionCard") as Object).call("primary_button") as BaseButton
		if primary == null or primary.disabled:
			break
		await press(primary)


func test_hiding_removes_every_secret_and_keeps_names_portraits_and_death() -> void:
	var shell := await _cockpit(SIZE_16_10, 8)
	if shell == null:
		return
	var screen := _screen(shell)
	var s := session_of(shell)
	var r: CommandResult = s.call("gm_correction", {"kind": "kill", "target_id": 3, "trigger_effects": false, "reason": "Test", "confirmed": true})
	assert_true(r.ok, "Korrektur (%s)" % r.error)
	await _night_with_protection(shell)
	await frames(2)
	var marks: Dictionary = s.call("board_marks")
	assert_false(marks.is_empty(), "Spielleitung sieht ein Zustandsabzeichen")
	var marked_id := int(marks.keys()[0])
	var ring := _ring(shell)
	var token := ring.call("token_for", marked_id) as Control
	assert_false((token.get("marks") as Array).is_empty(), "Abzeichen am Platz sichtbar")
	var bar := find_node(screen, "OrderBar") as Control
	assert_true(bar.is_visible_in_tree(), "Nachtreihenfolge sichtbar")
	var hide := find_button(screen, "HideButton")
	await press(hide)
	assert_true(hide.button_pressed, "Verbergen aktiv")
	assert_true((token.get("marks") as Array).is_empty(), "keine Abzeichen")
	assert_false(bool(token.get("secrets_visible")), "Platz zeichnet keine geheimen Zustände")
	for t: Variant in _tokens(shell):
		assert_ne(String((t as Control).get("state")), "actor", "keine Hervorhebung handelnder Personen")
	assert_false(bar.is_visible_in_tree(), "Nachtreihenfolge verborgen")
	assert_false((find_node(screen, "RoleCardArt") as Control).is_visible_in_tree(), "Rollenbild der Karte verborgen")
	assert_true((find_node(screen, "HiddenLabel") as Control).is_visible_in_tree(), "Hinweis, dass verborgen ist")
	# Öffentliches bleibt: Namen, Porträts, tot oder lebendig.
	var dead := ring.call("token_for", 3) as Control
	assert_false(bool(dead.get("alive")), "tot bleibt sichtbar tot")
	assert_true(dead.text.contains("†"), "Tod trägt weiter das Zeichen im Text")
	for t: Variant in _tokens(shell):
		var seat := t as Control
		assert_true(seat.is_visible_in_tree(), "Platz %d sichtbar" % int(seat.get("person_id")))
		assert_true(str(seat.get("text")) != "", "Name vorhanden")
	await press(hide)
	assert_false((token.get("marks") as Array).is_empty(), "Abzeichen wieder da")
	assert_true(bar.is_visible_in_tree(), "Nachtreihenfolge wieder da")


func test_no_hidden_text_names_a_role_while_hiding() -> void:
	var shell := await _cockpit(SIZE_16_10, 8)
	if shell == null:
		return
	var screen := _screen(shell)
	await _night_with_protection(shell)
	await press(find_button(screen, "HideButton"))
	var role_names: Array[String] = []
	for role: StringName in RolePresentation.sorted_roles():
		role_names.append(TranslationServer.translate(String(RolePresentation.name_key(role))))
	for c: Control in text_controls(find_node(screen, "SeatRingArea")):
		var text := text_of(c)
		for role_name: String in role_names:
			assert_false(role_name != "" and text == role_name, "Platz zeigt keine Rolle (%s)" % text)
	var bar := find_node(screen, "OrderBar") as Control
	assert_false(bar.is_visible_in_tree(), "Leiste mit Rollennamen nicht sichtbar")


# --- Nachtleiste ------------------------------------------------------------------------------------

func test_order_bar_is_collapsed_on_4_3_and_full_on_16_10_and_can_expand() -> void:
	var narrow := await _cockpit(SIZE_4_3, 12)
	if narrow == null:
		return
	await _start_night(narrow)
	var bar := find_node(_screen(narrow), "OrderBar") as Control
	assert_true(bar.is_visible_in_tree(), "Nachtleiste in der Nacht sichtbar")
	assert_false(bool(bar.call("is_expanded")), "4:3: eingeklappt")
	assert_true(absf(bar.size.y - NightOrderBar.CHIP_SIZE.y) < 1.0, "4:3: Chip statt voller Leiste (%s)" % str(bar.size))
	var toggle := find_button(_screen(narrow), "ToggleButton")
	assert_true(toggle.is_visible_in_tree(), "Umschalter vorhanden")
	await press(toggle)
	assert_true(bool(bar.call("is_expanded")), "ausgeklappt")
	assert_true(bar.size.y >= NightOrderBar.FULL_HEIGHT - 1.0, "volle Leiste")
	after_each_shell(narrow)
	var wide := await _cockpit(SIZE_16_10, 12)
	if wide == null:
		return
	await _start_night(wide)
	var bar_wide := find_node(_screen(wide), "OrderBar") as Control
	assert_true(bool(bar_wide.call("is_expanded")), "16:10: voll sichtbar")
	assert_true(bar_wide.size.y >= NightOrderBar.FULL_HEIGHT - 1.0, "volle Höhe (%s)" % str(bar_wide.size))


func test_order_bar_lists_the_night_and_marks_exactly_one_active_role() -> void:
	var shell := await _cockpit(SIZE_16_10, 12)
	if shell == null:
		return
	await _start_night(shell)
	var bar := find_node(_screen(shell), "OrderBar")
	var entries: Array = bar.call("entries")
	assert_eq(entries, session_of(shell).call("night_order"), "die Leiste zeigt die Reihenfolge der Sitzung")
	var active := entries.filter(func(e: Dictionary) -> bool: return str(e["state"]) == "active")
	assert_eq(active.size(), 1, "genau eine aktive Rolle")
	var day_shell_bar := find_node(_screen(shell), "OrderBar") as Control
	assert_true(day_shell_bar.is_visible_in_tree(), "in der Nacht sichtbar")


# --- Linkshändermodus ---------------------------------------------------------------------------------

func test_left_handed_mode_mirrors_dock_and_phase_plate_but_not_the_ring() -> void:
	var right := await _cockpit(SIZE_16_10, 7)
	if right == null:
		return
	var screen_r := _screen(right)
	var ring_before := _grect(find_node(screen_r, "SeatRing") as Control)
	var dock_r := _grect(find_node(screen_r, "ActionsArea") as Control)
	var plate_r := _grect(find_node(screen_r, "PhaseArea") as Control)
	var order_r: Array = _tokens(right).map(func(t: Control) -> int: return int(t.get("person_id")))
	assert_true(dock_r.get_center().x > plate_r.get_center().x, "Rechtshänder: Dock rechts, Phase links")
	after_each_shell(right)
	var left := await _cockpit(SIZE_16_10, 7, true)
	if left == null:
		return
	var screen_l := _screen(left)
	var dock_l := _grect(find_node(screen_l, "ActionsArea") as Control)
	var plate_l := _grect(find_node(screen_l, "PhaseArea") as Control)
	assert_true(dock_l.get_center().x < plate_l.get_center().x, "Linkshänder: Dock links, Phase rechts")
	assert_eq(_grect(find_node(screen_l, "SeatRing") as Control), ring_before, "Sitzkreis nicht gespiegelt")
	var order_l: Array = _tokens(left).map(func(t: Control) -> int: return int(t.get("person_id")))
	assert_eq(order_l, order_r, "Sitzfolge unverändert")
	for t: Variant in _tokens(left):
		assert_false(_circle_hits(_portrait(t as Control), dock_l) or _circle_hits(_portrait(t as Control), plate_l), "Dock und Phase überdecken keinen Platz")


# --- Texte aus der Übersetzung ---------------------------------------------------------------------

func test_board_texts_come_from_the_translation_in_both_languages() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_16_10, locale)
		if shell == null:
			return
		session_of(shell).call("submit", Fixtures.start_roles(Fixtures.unique_roles(7), 1))
		await navigate(shell, &"main_menu")
		await navigate(shell, &"cockpit")
		var screen := _screen(shell)
		for node_name: String in ["LogButton", "OptionsButton", "HideButton", "CoverButton", "DockUndoButton", "TimerButton"]:
			var b := find_button(screen, node_name)
			var shown: String = b.tooltip_text if b.text == "" else b.text
			assert_true(shown != "" and not shown.begins_with("ui."), "%s (%s): übersetzter Text (%s)" % [node_name, locale, shown])
		after_each_shell(shell)
