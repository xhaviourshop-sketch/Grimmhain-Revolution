extends UiTestCase
## Spielstart über die Oberfläche: „Partie starten“ erscheint erst mit bestätigter Sitzordnung,
## sendet genau einen StartGame-Befehl und öffnet das Cockpit als aktive Partie. Doppeltippen,
## Ablehnung durch den Regelkern und Geheimhaltung der Statusmeldungen (DE/EN). Fester Seed.

const FIXED_SEED := 838383
const ROLE_IDS: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
		"sensentraeger", "wolfskind", "lehrling", "manipulator", "spiegelwolf"]


func _view(shell: Control) -> Dictionary:
	var s := setup_of(shell)
	return s.call("view") as Dictionary if s != null else {}


## Neue Partie bis zur bestätigten Sitzordnung (Vorbereitung über echte Buttons).
func _to_confirmed_seating(shell: Control, count: int, revival: bool = false) -> Control:
	var screen := await open_new_game(shell)
	var s := setup_of(shell)
	s.set("seed_source", func() -> int: return FIXED_SEED)
	await seed_names(shell, numbered_names(count))
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	await press(find_button(screen, "SuggestButton"))
	for d: Variant in (s.call("view") as Dictionary)["roles"].get("decoys", []):
		s.call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"waldhexe")
	if revival:
		# Ein Dorfbewohner weniger, dafür ein Kutscher: direkte Wiederbelebungsrolle (DI-01).
		var counts: Dictionary = (s.call("view") as Dictionary)["roles"]["counts"]
		s.call("set_role_count", &"dorfbewohner", int(counts["dorfbewohner"]) - 1)
		s.call("set_role_count", &"kutscher", 1)
	await frames(2)
	await press(find_button(screen, "ConfirmRolesButton"))
	await press(find_button(screen, "DistributeButton"))
	await press(find_button(screen, "ConfirmDistributionButton"))
	await press(find_button(screen, "ToSeatingButton"))
	await press(find_button(screen, "ConfirmSeatingButton"))
	(shell.call("get_toast") as Control).call("hide_message")
	await frames(2)
	return screen


func _start_button(screen: Node) -> BaseButton:
	return find_button(screen, "StartGameButton")


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
	var names := _role_names()
	for c: Control in text_controls(current_screen(shell)):
		var text := text_of(c)
		for name: String in names:
			assert_false(text.contains(name), "%s: %s zeigt Rolle „%s“" % [label, c.name, name])
	var toast_label := find_node(shell.call("get_toast") as Node, "MessageLabel") as Label
	for name: String in names:
		assert_false(toast_label != null and toast_label.text.contains(name), "%s: Statusmeldung ohne Rolle" % label)


func _toast_text(shell: Control) -> String:
	var toast_label := find_node(shell.call("get_toast") as Node, "MessageLabel") as Label
	return toast_label.text if toast_label != null else ""


# --- Sichtbarkeit ---------------------------------------------------------------------------------------

func test_start_button_only_with_confirmed_seating() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_confirmed_seating(shell, 8)
	var start := _start_button(screen)
	assert_true(start != null and start.is_visible_in_tree() and not start.disabled, "„Partie starten“ nach bestätigter Sitzordnung")
	assert_eq(text_of(start), "Partie starten", "Beschriftung")
	assert_false(find_button(screen, "ConfirmSeatingButton").is_visible_in_tree(), "ersetzt „Sitzordnung bestätigen“")
	var center := find_node(screen, "TableCenter") as Control
	var column := center.get_child(0) as Control if center != null else null
	assert_true(column != null and column.get_combined_minimum_size().y <= center.size.y + 0.5, "Tischmitte passt in ihre Fläche")
	assert_eq(int((session_of(shell).call("view") as Dictionary)["command_count"]), 0, "Bestätigen allein startet nichts")
	# Prüfen und Ändern vor dem Start bleibt möglich: ein Tausch blendet den Start aus.
	var order: Array = []
	for seat: Variant in (_view(shell)["seating"] as Dictionary)["seats"]:
		order.append(int((seat as Dictionary)["person_id"]))
	setup_of(shell).call("swap_seats", order[0], order[1])
	await frames(2)
	assert_false(start.is_visible_in_tree(), "nach Tausch kein Start ohne erneute Bestätigung")
	await press(find_button(screen, "ConfirmSeatingButton"))
	assert_true(start.is_visible_in_tree(), "nach erneuter Bestätigung wieder startbar")


func test_ready_layout_fits_with_twentyfour_at_4_3() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_4_3, locale)
		if shell == null:
			return
		var screen := await _to_confirmed_seating(shell, 24)
		var center := find_node(screen, "TableCenter") as Control
		var needed := (center.get_child(0) as Control).get_combined_minimum_size().y
		assert_true(needed <= center.size.y + 0.5, "%s: Tischmitte passt (%.0f ≤ %.0f)" % [locale, needed, center.size.y])
		var circle := find_node(screen, "SeatCircle") as Control
		for token: Variant in circle.call("tokens"):
			assert_false(overlaps(rect_of(token as Control), rect_of(center)), "%s: %s überlappt die Tischmitte" % [locale, (token as Control).name])
		var start := _start_button(screen)
		assert_true(inside(rect_of(start), Rect2(Vector2.ZERO, Vector2(SIZE_4_3))), "%s: „Partie starten“ vollständig sichtbar" % locale)
		await after_each()


# --- Start -----------------------------------------------------------------------------------------------

func test_start_opens_cockpit_with_active_game() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_confirmed_seating(shell, 6)
	await press(_start_button(screen))
	await frames(3)
	var view: Dictionary = session_of(shell).call("view")
	assert_true(bool(view["has_game"]), "Partie aktiv")
	assert_eq(int(view["command_count"]), 1, "genau ein StartGame")
	assert_eq(int(view["player_count"]), 6, "sechs Personen")
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit geöffnet")
	var cockpit := current_screen(shell)
	var badge := find_node(cockpit, "NoGameBadge") as Control
	assert_true(badge != null and not badge.is_visible_in_tree(), "kein Hinweis „Keine Partie aktiv“")
	# Das Cockpit zeigt die gestartete Partie: sechs Plätze und als nächsten Schritt „Nacht beginnen“.
	var ring := find_node(cockpit, "SeatRing")
	assert_eq(ring.call("tokens").size() if ring != null else 0, 6, "Sitzkreis mit sechs Plätzen")
	var start_night := find_node(cockpit, "StartNightButton") as BaseButton
	assert_true(start_night != null and start_night.is_visible_in_tree(), "nächster Schritt: Nacht beginnen")
	assert_eq(_toast_text(shell), "Partie gestartet", "Statusmeldung")
	_assert_no_roles_visible(shell, "Cockpit")
	# Der Entwurf ist verbraucht: „Neue Partie“ beginnt leer.
	assert_eq((_view(shell)["persons"] as Array).size(), 0, "Setup-Entwurf nach dem Start verworfen")


func test_double_tap_starts_one_game() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_confirmed_seating(shell, 7)
	var start := _start_button(screen)
	var rejections: Array[String] = []
	session_of(shell).connect("command_rejected", func(e: StringName) -> void: rejections.append(String(e)))
	start.pressed.emit()
	start.pressed.emit()
	await frames(4)
	assert_eq(int((session_of(shell).call("view") as Dictionary)["command_count"]), 1, "nur eine Partie")
	assert_true(rejections.is_empty(), "zweites Tippen erreicht den Regelkern nicht")
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit geöffnet")


func test_rejected_start_keeps_setup_and_session() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_16_10, locale)
		if shell == null:
			return
		var session := session_of(shell)
		session.call("submit", Fixtures.start_manual(6, [1]))
		var screen := await _to_confirmed_seating(shell, 8)
		var setup_before := JSON.stringify(_view(shell))
		var hash_before := str(session.call("state_hash"))
		await press(_start_button(screen))
		assert_eq(String(current_id(shell)), "new_game", "%s: bleibt im Setup" % locale)
		assert_eq(JSON.stringify(_view(shell)), setup_before, "%s: Setup unverändert" % locale)
		assert_eq(str(session.call("state_hash")), hash_before, "%s: Sitzung unverändert" % locale)
		assert_eq(int((session.call("view") as Dictionary)["command_count"]), 1, "%s: kein weiterer Befehl" % locale)
		var status := find_node(screen, "SeatingStatusLabel") as Label
		var expected := "läuft bereits" if locale == "de" else "already running"
		assert_true(status != null and status.text.contains(expected), "%s: verständliche Meldung: %s" % [locale, status.text if status != null else ""])
		assert_false(_start_button(screen).disabled, "%s: nach Ablehnung erneut versuchbar" % locale)
		_assert_no_roles_visible(shell, "%s abgelehnt" % locale)
		await after_each()


func test_start_messages_show_no_roles_de_en() -> void:
	for locale: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_16_10, locale)
		if shell == null:
			return
		var screen := await _to_confirmed_seating(shell, 18)
		_assert_no_roles_visible(shell, "%s bereit" % locale)
		await press(_start_button(screen))
		assert_eq(String(current_id(shell)), "cockpit", "%s: Cockpit" % locale)
		assert_ne(_toast_text(shell), "", "%s: Statusmeldung sichtbar" % locale)
		_assert_no_roles_visible(shell, "%s gestartet" % locale)
		await after_each()


func test_start_game_has_no_reveal_option_and_the_mode_follows_the_roles() -> void:
	# DI-01: keine frei wählbare Aufdeckung mehr; der Regelkern leitet die Wiederbelebungsrunde aus der Besetzung ab.
	for revival: bool in [false, true]:
		var shell := await spawn_shell()
		if shell == null:
			return
		var screen := await _to_confirmed_seating(shell, 6, revival)
		assert_true(find_node(screen, "RevealRoleToggle") == null, "keine frei wählbare Aufdeckungsoption")
		var label := find_node(screen, "RevivalRoundLabel") as Label
		assert_true(label != null, "Anzeige der Wiederbelebungsrunde im Rollenschritt")
		if label != null:
			assert_eq(label.text, tr("ui.setup.roles.revival_round.on" if revival else "ui.setup.roles.revival_round.off"), "Anzeige folgt der Rollenwahl (%s)" % revival)
		assert_eq(bool((setup_of(shell).call("view") as Dictionary)["revival_round"]), revival, "Sicht des Setups (%s)" % revival)
		assert_true(_start_button(screen).is_visible_in_tree(), "Start bereit")
		await press(_start_button(screen))
		var commands: Array = session_of(shell).call("commands")
		assert_false((commands[0] as Command).payload.has("reveal_role_on_death"), "StartGame ohne Aufdeckungsangabe")
		assert_eq(bool((session_of(shell).call("cockpit_view") as Dictionary)["revival_round"]), revival, "Regelkern leitet den Modus ab (%s)" % revival)
		after_each_shell(shell)


func after_each_shell(shell: Control) -> void:
	_spawned.erase(shell)
	shell.get_parent().remove_child(shell)
	shell.free()
