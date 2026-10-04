extends UiTestCase
## Spielbrettzentriertes Cockpit: Zielwahl mit Textmarkierung (nicht nur Farbe) bei lebenden und toten Personen, langer Text in der
## Detailansicht scrollt bei festen Buttons, private Ansicht schließt zurück zum sicheren Brett, Speicherfehler mit erreichbarem
## „Erneut speichern“. Die Flächenverteilung (85 bis 90 Prozent Brett, 6 und 24 Personen, beide Größen) prüft test_cockpit_screen.


func _cockpit(locale: String = "de", size: Vector2i = SIZE_4_3, count: int = 7) -> Control:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return null
	var r: CommandResult = session_of(shell).call("submit", Fixtures.start_roles(Fixtures.unique_roles(count), 1))
	assert_true(r.ok, "Partie gestartet (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _screen(shell: Control) -> Control:
	return current_screen(shell)


func _token(shell: Control, id: int) -> BaseButton:
	return find_node(_screen(shell), "SeatRing").call("token_for", id) as BaseButton


func _tokens(shell: Control) -> Array:
	return find_node(_screen(shell), "SeatRing").call("tokens")


# --- Zielwahl am Brett ---------------------------------------------------------------------------

func test_target_selection_is_marked_by_text_for_living_people() -> void:
	for locale: String in ["de", "en"]:
		var shell := await _cockpit(locale)
		if shell == null:
			return
		await press(find_button(_screen(shell), "StartNightButton"))
		var next: Dictionary = effective_of((session_of(shell).call("cockpit_view") as Dictionary)["next"])
		assert_eq(str(next.get("answer")), "targets", "%s: Zielwahl offen" % locale)
		var allowed: Array = next["allowed_ids"]
		for t: Variant in _tokens(shell):
			var token := t as BaseButton
			var id := int(token.get("person_id"))
			if allowed.has(id):
				assert_true(token.text.begins_with("› "), "%s: wählbare Person %d trägt ein Textzeichen (%s)" % [locale, id, token.text])
				assert_false(token.disabled, "%s: wählbare Person %d antippbar" % [locale, id])
			else:
				assert_false(token.text.begins_with("› ") or token.text.begins_with("✓ "), "%s: Person %d ohne Zielzeichen" % [locale, id])
				assert_true(token.disabled, "%s: nicht wählbare Person %d gesperrt" % [locale, id])
		var target := int(allowed[0])
		# Feste Anzahl: Das Antippen übernimmt die Wahl sofort (Rückgängig-Leiste), es gibt keine Zwischenauswahl mehr.
		var commands_before := (session_of(shell).call("commands") as Array).size()
		await press(_token(shell, target))
		assert_eq((session_of(shell).call("commands") as Array).size(), commands_before + 1, "%s: Tipp übernimmt die Wahl sofort" % locale)
		assert_true(find_node(_screen(shell), "ConfirmTargetsButton") == null, "%s: kein Bestätigungsknopf" % locale)


func test_dead_people_are_marked_and_selectable_when_the_rules_allow_them() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var s := session_of(shell)
	var r: CommandResult = s.call("gm_correction", {"kind": "kill", "target_id": 3, "trigger_effects": false, "reason": "Test", "confirmed": true})
	assert_true(r.ok, "Korrektur (%s)" % r.error)
	await frames(2)
	assert_true(_token(shell, 3).text.contains("†"), "tote Person trägt † im Text")
	await press(find_button(_screen(shell), "GmButton"))
	await press(find_button(_screen(shell), "GmKind_revive"))
	for t: Variant in _tokens(shell):
		var token := t as BaseButton
		var id := int(token.get("person_id"))
		assert_eq(not token.disabled, id == 3, "Wiederbeleben: nur die tote Person %d wählbar" % id)
	assert_true(_token(shell, 3).text.begins_with("› ") and _token(shell, 3).text.contains("†"), "tote Zielperson: Zielzeichen und † (%s)" % _token(shell, 3).text)
	await press(_token(shell, 3))
	assert_true(_token(shell, 3).text.begins_with("✓ "), "tote Person gewählt: Auswahlzeichen")
	assert_false(find_button(_screen(shell), "GmConfirmButton").disabled, "Korrektur bestätigbar")
	await press(find_button(_screen(shell), "CancelModeButton"))
	assert_false(_token(shell, 3).text.begins_with("› ") or _token(shell, 3).text.begins_with("✓ "), "nach Abbruch keine Markierung")


# --- Detailansicht: langer Text scrollt, Buttons bleiben ---------------------------------------------

func test_detail_panel_scrolls_long_text_and_keeps_buttons_visible() -> void:
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		await resize(size)
		var root := Control.new()
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(center)
		var panel := DetailPanel.new()
		center.add_child(panel)
		for i: int in 40:
			var l := Label.new()
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.text = "Zeile %d: Ein sehr langer Kartentext, der mehrere Zeilen füllt und weit über die Fensterhöhe hinausgeht." % i
			panel.content.add_child(l)
		var play := GrimmButton.new()
		play.text_key = "ui.cards.action.play"
		play.kind = GrimmButton.Kind.PRIMARY
		play.name = "PlayButton"
		panel.actions.add_child(play)
		var close := GrimmButton.new()
		close.text_key = "ui.cockpit.show.close"
		close.name = "CloseButton"
		panel.actions.add_child(close)
		tree.root.add_child(root)
		_spawned.append(root)
		await frames(5)
		var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
		var scroll := panel.find_child("DetailScroll", true, false) as ScrollContainer
		assert_true(inside(rect_of(panel), viewport), "%s: Panel liegt im Fenster (%s)" % [size, str(rect_of(panel))])
		assert_true(inside(rect_of(play), viewport) and inside(rect_of(close), viewport), "%s: Buttons ohne Scrollen sichtbar" % size)
		assert_false(scroll.is_ancestor_of(play), "%s: Buttons stehen außerhalb des scrollenden Textes" % size)
		assert_true(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page + 1.0, "%s: der lange Text scrollt" % size)
		scroll.scroll_vertical = 100000
		await frames(2)
		assert_true(inside(rect_of(play), viewport) and inside(rect_of(close), viewport), "%s: Buttons bleiben nach dem Scrollen sichtbar" % size)
		assert_false(rect_of(play).intersects(rect_of(scroll)), "%s: Buttons überdecken den Text nicht" % size)
		_spawned.erase(root)
		root.free()


# --- Private Ansicht schließt zum sicheren Brett ---------------------------------------------------

func test_closing_a_private_role_card_returns_to_a_board_without_roles() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var screen := _screen(shell)
	var role_names: Array[String] = []
	for role: StringName in RolePresentation.sorted_roles():
		role_names.append(TranslationServer.translate(String(RolePresentation.name_key(role))))
	await press(find_button(screen, "ShowRolesButton"))
	await press(find_button(find_node(screen, "RoleListLayer"), "RolePerson_2"))
	await press(find_button(find_node(screen, "RoleCardLayer"), "RevealRoleButton"))
	var card_texts: Array[String] = []
	for c: Control in text_controls(find_node(screen, "RoleCardLayer")):
		card_texts.append(text_of(c))
	assert_true("\n".join(card_texts).length() > 0, "Rollenkarte zeigte Inhalt")
	await press(find_button(find_node(screen, "RoleCardLayer"), "CloseWithoutConfirmButton"))
	assert_true(find_node(screen, "RoleListLayer") != null, "zurück zur neutralen Liste")
	await press(find_button(find_node(screen, "RoleListLayer"), "CloseLayerButton"))
	assert_eq(String(screen.call("layer_kind")), "", "keine Ebene offen")
	assert_eq((find_node(screen, "OverlayHost") as Control).get_child_count(), 0, "kein Rest der privaten Ansicht im Baum")
	assert_true((find_node(screen, "Layout") as Control).is_visible_in_tree(), "Brett wieder sichtbar")
	for c: Control in text_controls(screen):
		var text := text_of(c)
		for role_name: String in role_names:
			assert_false(role_name != "" and text.contains(role_name), "kein Rollenname auf dem Brett: %s in „%s“" % [role_name, text])


# --- Speicherfehler -----------------------------------------------------------------------------------

func test_save_error_is_visible_retry_reachable_and_does_not_cover_the_action() -> void:
	var shell := await _cockpit("de", SIZE_4_3, 24)
	if shell == null:
		return
	var ctx := context_of(shell) as AppContext
	ctx.saves.simulate_failure = &"write"
	await press(find_button(_screen(shell), "StartNightButton"))
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var status := find_node(_screen(shell), "SaveStatusLabel") as Label
	var retry := find_button(_screen(shell), "RetrySaveButton")
	assert_eq(status.text, "Fehler: nicht gespeichert", "Fehlertext deutlich")
	assert_eq(status.theme_type_variation, &"ErrorCaptionLabel", "Fehler in Fehlerstil")
	assert_true(retry.is_visible_in_tree() and not retry.disabled and retry.size.y >= 47.5 and inside(rect_of(retry), viewport), "Erneut speichern erreichbar (%s, sichtbar %s, Zeile %s)" % [str(rect_of(retry)), str(retry.is_visible_in_tree()), str(rect_of(find_node(_screen(shell), "SaveRow") as Control))])
	for b: BaseButton in visible_buttons(find_node(_screen(shell), "InstructionCard")):
		assert_false(overlaps(rect_of(b), rect_of(retry)), "%s von der Fehleranzeige nicht überdeckt" % b.name)
	for t: Variant in _tokens(shell):
		assert_false(seat_hits_rect(t as Control, rect_of(retry)), "Platz %d von der Fehleranzeige nicht überdeckt (%s)" % [int((t as Control).get("person_id")), str(rect_of(retry))])
	ctx.saves.simulate_failure = &""
	await press(retry)
	assert_eq(status.text, "Gespeichert", "nach erneutem Speichern bestätigt")
	assert_false(retry.is_visible_in_tree(), "Wiederholen-Button verschwindet")
