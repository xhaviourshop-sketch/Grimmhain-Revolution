extends UiTestCase
## Rechts-/Linkshänder-Modus (NQ-04): Auswahl über die echten Einstellungscontrols, sofortige Wirkung, dauerhafte
## Speicherung, im Cockpit wechselt nur die Seitenspalte (Ansagekarte und Werkzeuge) die Seite des Sitzkreises. Sitzreihenfolge,
## Nachbarn, Texte, Spielzustand, Zufall und offene Auswahl bleiben unberührt.

const STORE_SCRIPT := "res://app/settings/settings_store.gd"


func _store_path() -> String:
	return make_save_dir().path_join("settings.json")


func _screen(shell: Control) -> Control:
	return current_screen(shell)


func _cockpit(size: Vector2i, locale: String, roles: Array, hand_left: bool = false) -> Control:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return null
	settings_of(shell).call("set_left_handed", hand_left)
	var r: CommandResult = session_of(shell).call("submit", Fixtures.start_roles(roles, 1))
	assert_true(r.ok, "Partie gestartet (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _rect(shell: Control, node_name: String) -> Rect2:
	return rect_of(find_node(_screen(shell), node_name) as Control)


## Liegt die Hauptaktion der ersten Karte (Nacht beginnen) in der linken Hälfte der Ansagekarte?
func _main_action_on_left(shell: Control) -> bool:
	var action := rect_of(find_node(_screen(shell), "StartNightButton") as Control).get_center().x
	return action < _rect(shell, "InstructionCard").get_center().x


func _seat_rects(shell: Control) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t: Variant in find_node(_screen(shell), "SeatRing").call("tokens"):
		out.append(rect_of(t as Control))
	return out


func _hand_state(shell: Control) -> Array:
	var right := find_node(_screen(shell), "HandRightButton") as BaseButton
	var left := find_node(_screen(shell), "HandLeftButton") as BaseButton
	return [right.button_pressed, left.button_pressed]


func test_settings_controls_switch_both_modes_immediately() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"settings")
	var settings := settings_of(shell)
	assert_false(bool(settings.get("left_handed")), "Standard rechtshändig")
	assert_eq(_hand_state(shell), [true, false], "Rechtshändig als aktuelle Auswahl erkennbar")
	var status := find_node(_screen(shell), "HandStatusLabel") as Control
	assert_eq(key_of(status), "ui.settings.hand.active_right", "Statuszeile nennt die aktive Bedienhand")
	assert_eq(text_of(status), "Aktiv: Rechtshändig", "Statuszeile DE")
	await press(find_button(_screen(shell), "HandLeftButton"))
	assert_true(bool(settings.get("left_handed")), "Linkshändig sofort gesetzt")
	assert_eq(_hand_state(shell), [false, true], "genau ein Button gewählt")
	assert_eq(text_of(status), "Aktiv: Linkshändig", "Statuszeile folgt sofort")
	await press(find_button(_screen(shell), "HandRightButton"))
	assert_false(bool(settings.get("left_handed")), "Rechtshändig sofort zurück")
	assert_eq(_hand_state(shell), [true, false], "Auswahl folgt")
	settings.call("set_language", "en")
	await frames(2)
	assert_eq(text_of(status), "Active: right-handed", "Statuszeile EN")
	settings.call("set_language", "de")


func test_choice_survives_restart_and_uses_only_the_temp_file() -> void:
	var path := _store_path()
	var script := load_script(STORE_SCRIPT)
	if script == null:
		return
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	ctx.use_settings_store(script.new(path) as SettingsStore)
	ctx.settings.set_left_handed(true)
	var restarted := AppSettings.new()
	assert_true(bool(script.new(path).call("load_into", restarted)["ok"]), "Datei lesbar")
	assert_true(restarted.left_handed, "Linkshändig nach Neustart erhalten")
	ctx.settings.set_left_handed(false)
	var again := AppSettings.new()
	script.new(path).call("load_into", again)
	assert_false(again.left_handed, "Rechtshändig nach Neustart erhalten")


## Echte Bedienung: Button tippen, App beenden, neue App-Instanz mit derselben (temporären) Einstellungsdatei starten.
func test_button_choice_reaches_the_cockpit_after_a_real_restart() -> void:
	var path := _store_path()
	var script := load_script(STORE_SCRIPT)
	if script == null:
		return
	for left: bool in [true, false]:
		var first := await _launch(path)
		await navigate(first, &"main_menu")
		await navigate(first, &"settings")
		await press(find_button(_screen(first), "HandLeftButton" if left else "HandRightButton"))
		first.queue_free()
		await frames(2)
		var second := await _launch(path)
		assert_eq(bool(settings_of(second).get("left_handed")), left, "Auswahl nach Neustart geladen")
		var r: CommandResult = session_of(second).call("submit", Fixtures.start_roles(Fixtures.unique_roles(7), 1))
		assert_true(r.ok, "Partie gestartet")
		await navigate(second, &"main_menu")
		await navigate(second, &"cockpit")
		assert_eq(_main_action_on_left(second), left, "Cockpit nach Neustart: Hauptaktion %s" % ("links" if left else "rechts"))
		await navigate(second, &"main_menu")
		await navigate(second, &"settings")
		assert_eq(_hand_state(second), [not left, left], "Einstellungsansicht zeigt die geladene Auswahl")
		second.queue_free()
		await frames(2)


## Neue App-Instanz wie beim echten Start mit Einstellungsdatei unter `path` (nie die echte Datei, keine echten Spielstände).
func _launch(path: String) -> Control:
	await resize(SIZE_16_10)
	var shell := (load(MAIN_SCENE) as PackedScene).instantiate() as Control
	shell.set("quit_handler", func() -> void: quit_calls += 1)
	var context := AppContext.new()
	context.saves.base_dir = make_save_dir()
	shell.set("app_context", context)
	shell.set("settings_store", (load_script(STORE_SCRIPT)).new(path))
	tree.root.add_child(shell)
	_spawned.append(shell)
	await frames(3)
	return shell


func test_restart_applies_the_saved_side_to_the_cockpit() -> void:
	var shell := await _cockpit(SIZE_16_10, "de", Fixtures.unique_roles(7), true)
	if shell == null:
		return
	assert_true(_main_action_on_left(shell), "gespeicherte Linkshändigkeit: Hauptaktion links")


func test_cockpit_never_mirrors_the_ring_and_only_moves_the_main_action() -> void:
	var shell := await _cockpit(SIZE_16_10, "de", Fixtures.unique_roles(7))
	if shell == null:
		return
	var ids_before: Array = (session_of(shell).call("cockpit_view") as Dictionary)["seats"].map(func(s: Dictionary) -> Variant: return s["person_id"])
	var commands_before := (session_of(shell).call("commands") as Array).size()
	var state_before := str(session_of(shell).call("state_hash"))
	var ring_before := _rect(shell, "SeatRingArea")
	var seats_before := _seat_rects(shell)
	assert_false(_main_action_on_left(shell), "rechtshändig: Hauptaktion rechts")
	assert_true(find_node(_screen(shell), "SideColumn") == null, "keine dauerhafte Seitenspalte")
	var texts_before := {}
	for c: Control in text_controls(_screen(shell)):
		if c.is_visible_in_tree():
			texts_before[str(c.get_path())] = text_of(c)
	settings_of(shell).call("set_left_handed", true)
	await frames(3)
	assert_true(_main_action_on_left(shell), "linkshändig: Hauptaktion links")
	assert_eq(_rect(shell, "SeatRingArea"), ring_before, "Sitzkreisfläche unverändert")
	assert_eq(_seat_rects(shell), seats_before, "Sitzkreis nicht gespiegelt: jeder Platz an derselben Stelle")
	var ids_after: Array = (session_of(shell).call("cockpit_view") as Dictionary)["seats"].map(func(s: Dictionary) -> Variant: return s["person_id"])
	assert_eq(ids_after, ids_before, "Personenreihenfolge und Sitznummern unverändert")
	assert_eq((session_of(shell).call("commands") as Array).size(), commands_before, "kein Spielbefehl")
	assert_eq(str(session_of(shell).call("state_hash")), state_before, "Spielzustand unverändert (auch der gespeicherte Generator)")
	for path: String in texts_before:
		var node := tree.root.get_node_or_null(path) as Control
		assert_true(node != null and text_of(node) == texts_before[path], "Text unverändert: %s" % path)
	# Zurück: gleiche Ausgangsgeometrie, kein doppeltes Umschalten.
	settings_of(shell).call("set_left_handed", true)
	await frames(2)
	assert_true(_main_action_on_left(shell), "gleicher Wert ohne Wirkung")
	settings_of(shell).call("set_left_handed", false)
	await frames(3)
	assert_false(_main_action_on_left(shell), "zurück auf rechts")
	assert_eq(_seat_rects(shell), seats_before, "Plätze nach dem Rückwechsel unverändert")


func test_open_selection_stays_valid_and_confirms_exactly_once() -> void:
	var shell := await _cockpit(SIZE_16_10, "de", Fixtures.unique_roles(7))
	if shell == null:
		return
	await press(find_button(_screen(shell), "StartNightButton"))  # erster Schritt: Zielwahl des Schutzengels
	var ring := find_node(_screen(shell), "SeatRing")
	var next2: Dictionary = (session_of(shell).call("cockpit_view") as Dictionary).get("next", {})
	assert_eq(str(next2.get("answer")), "targets", "offene Zielwahl")
	var allowed: Array = next2.get("allowed_ids", [])
	assert_false(allowed.is_empty(), "erlaubte Ziele vorhanden")
	var target := int(allowed[0])
	await press(ring.call("token_for", target) as BaseButton)
	var confirm := find_button(_screen(shell), "ConfirmTargetsButton")
	assert_false(confirm.disabled, "Auswahl gültig vor dem Wechsel")
	var commands_before := (session_of(shell).call("commands") as Array).size()
	var state_before := str(session_of(shell).call("state_hash"))
	settings_of(shell).call("set_left_handed", true)
	await frames(3)
	confirm = find_button(_screen(shell), "ConfirmTargetsButton")
	assert_false(confirm.disabled, "Auswahl bleibt gültig nach dem Wechsel")
	assert_eq((session_of(shell).call("commands") as Array).size(), commands_before, "Wechsel sendet keinen Befehl")
	assert_eq(str(session_of(shell).call("state_hash")), state_before, "Zustand unverändert")
	assert_eq(_tapped_selection_marks(ring), [target], "gewähltes Ziel bleibt markiert")
	await press(confirm)
	var sent: Array = (session_of(shell).call("commands") as Array)
	assert_eq(sent.size(), commands_before + 1, "Bestätigung genau einmal angenommen (keine doppelte Verbindung)")
	assert_eq((sent.back() as Command).payload["targets"], [target], "das vor dem Wechsel gewählte Ziel")
	settings_of(shell).call("set_left_handed", false)
	await frames(2)
	assert_eq((session_of(shell).call("commands") as Array).size(), commands_before + 1, "zweiter Wechsel sendet nichts")


func _tapped_selection_marks(ring: Node) -> Array:
	var out: Array = []
	for t: Node in ring.call("tokens"):
		if t.get("state") == &"selected":
			out.append(int(t.get("person_id")))
	return out


## Spieler-Zeigekarte („Rollen zeigen“): Ein Seitenwechsel bei geöffneter Karte schließt sie nicht, verändert nichts und die Bestätigung
## wird genau einmal gesendet.
func test_open_role_card_survives_a_side_change_and_confirms_once() -> void:
	var shell := await _cockpit(SIZE_4_3, "de", Fixtures.unique_roles(7))
	if shell == null:
		return
	var screen := _screen(shell)
	var session := session_of(shell) as GameSession
	await press(find_button(screen, "ShowRolesButton"))
	var list := find_node(screen, "RoleListLayer")
	assert_true(list != null, "Rollenliste geöffnet")
	await press(find_button(list, "RolePerson_2"))
	var card := find_node(screen, "RoleCardLayer")
	assert_true(card != null, "neutrale Vorderseite geöffnet")
	var before := (session.commands() as Array).size()
	var hash_before := session.state_hash()
	settings_of(shell).call("set_left_handed", true)
	await frames(3)
	card = find_node(screen, "RoleCardLayer")
	assert_true(card != null, "Karte bleibt nach dem Seitenwechsel offen")
	assert_eq((session.commands() as Array).size(), before, "Seitenwechsel sendet nichts")
	assert_eq(session.state_hash(), hash_before, "Zustand unverändert")
	await press(find_button(card, "RevealRoleButton"))
	card = find_node(screen, "RoleCardLayer")
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	for b: BaseButton in visible_buttons(card):
		assert_true(inside(clipped_rect(b), viewport), "%s im Viewport" % b.name)
		assert_true(b.size.y >= 47.5, "%s mindestens 48 hoch" % b.name)
	await press(find_button(card, "ConfirmRoleButton"))
	await frames(2)
	assert_eq((session.commands() as Array).size(), before + 1, "genau ein Befehl (ConfirmRoleShown)")


func test_dialog_and_role_card_stay_operable_in_left_mode() -> void:
	var shell := await _cockpit(SIZE_4_3, "de", Fixtures.unique_roles(7), true)
	if shell == null:
		return
	await press(find_button(_screen(shell), "RolesButton"))
	var layer_rect := (find_node(_screen(shell), "OverlayHost") as Control).get_global_rect()
	assert_true(layer_rect.size.x > 0.0, "Ebene geöffnet")
	var buttons := visible_buttons(find_node(_screen(shell), "OverlayHost"))
	assert_false(buttons.is_empty(), "Ebene enthält Bedienelemente")
	for b: BaseButton in buttons:
		assert_true(inside(clipped_rect(b), Rect2(Vector2.ZERO, Vector2(tree.root.size))), "%s liegt im Viewport" % b.name)
	shell.call("request_quit")
	await frames(3)
	var dialog := shell.call("get_dialog") as Control
	assert_true(dialog != null and find_node(dialog, "ConfirmButton") != null and find_node(dialog, "CancelButton") != null, "Dialog vorhanden")
	if dialog != null:
		var confirm := find_node(dialog, "ConfirmButton") as Control
		var cancel := find_node(dialog, "CancelButton") as Control
		assert_false(overlaps(rect_of(confirm), rect_of(cancel)), "Dialogbuttons überlappen nicht")


func test_layout_both_sides_sizes_languages_and_group_sizes() -> void:
	for count: int in [6, 24]:
		for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
			for locale: String in ["de", "en"]:
				for left: bool in [false, true]:
					var shell := await _cockpit(size, locale, Fixtures.unique_roles(count), left)
					if shell == null:
						return
					await _check_layout(shell, "%d Personen %s %s %s" % [count, size, locale, "links" if left else "rechts"], left)
					await after_each()


## Mit sichtbarer Speicherwarnung (Wiederholen-Button) und der längsten Beschriftung.
func test_layout_with_visible_save_warning() -> void:
	for left: bool in [false, true]:
		for locale: String in ["de", "en"]:
			var shell := await _cockpit(SIZE_4_3, locale, Fixtures.unique_roles(24), left)
			if shell == null:
				return
			var ctx := context_of(shell) as AppContext
			ctx.saves.simulate_failure = &"write"
			await press(find_button(_screen(shell), "StartNightButton"))
			assert_true(find_button(_screen(shell), "RetrySaveButton").is_visible_in_tree(), "Speicherwarnung sichtbar")
			await _check_layout(shell, "Speicherwarnung %s %s" % [locale, "links" if left else "rechts"], left)
			ctx.saves.simulate_failure = &""
			await after_each()


func _check_layout(shell: Control, label: String, _left: bool) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var card := _rect(shell, "InstructionCard")
	var ring := _rect(shell, "SeatRingArea")
	assert_true(inside(card, viewport) and inside(ring, viewport), "%s: Karte und Sitzkreis im Viewport" % label)
	assert_true(inside(card, ring), "%s: Ansagekarte liegt in der Tischmitte des Bretts" % label)
	for t: Variant in find_node(_screen(shell), "SeatRing").call("tokens"):
		assert_false(seat_hits_rect(t as Control, card), "%s: Ansagekarte überdeckt keinen Platz" % label)
	var buttons := visible_buttons(_screen(shell))
	for b: BaseButton in buttons:
		if b.size.x > 0.0 and b.size.y > 0.0:
			assert_true(inside(clipped_rect(b), viewport), "%s: %s im Viewport" % [label, b.name])
			assert_true(b.size.y >= 47.5, "%s: %s mindestens 48 hoch (%s)" % [label, b.name, b.size])
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			var a := buttons[i]
			var b := buttons[j]
			if a.has_method("portrait_rect") or b.has_method("portrait_rect"):
				# Plätze sind rund und liegen auf einer Ellipse: Steuerelementflächen überlappen diagonal, sichtbare Teile nicht.
				if a.has_method("portrait_rect") and b.has_method("portrait_rect"):
					assert_false(seats_overlap(a, b), "%s: %s und %s überlappen" % [label, a.name, b.name])
				else:
					var seat := a if a.has_method("portrait_rect") else b
					var other := b if seat == a else a
					assert_false(seat_hits_rect(seat, clipped_rect(other)), "%s: %s und %s überlappen" % [label, a.name, b.name])
				continue
			assert_false(overlaps(clipped_rect(a), clipped_rect(b)), "%s: %s und %s überlappen" % [label, a.name, b.name])
	for c: Control in visible_controls(find_node(_screen(shell), "InstructionCard")):
		if c.size.x <= 0.0 or c.size.y <= 0.0 or c is ScrollContainer:
			continue
		var m := c.get_combined_minimum_size()
		assert_true(m.x <= c.size.x + 0.5, "%s: %s nicht abgeschnitten (min %s, ist %s)" % [label, c.name, m, c.size])
