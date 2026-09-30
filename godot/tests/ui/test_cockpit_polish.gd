extends UiTestCase
## Bedienqualität des Cockpits: Tag/Nacht-Hintergrund, kurzes abbrechbares Einblenden der Karte,
## reduzierte Bewegung ohne Übergänge, Fokus nach Aktionen, Anschlussstellen für spätere Bilder und
## Karteninhalt innerhalb der Spalte bei 1024×768 in DE und EN.

const ROLES := ["werwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "amalia", "detektiv"]


func _cockpit(size: Vector2i = SIZE_16_10, locale: String = "de", reduced: bool = true) -> Control:
	var shell := await spawn_shell(size, locale, reduced)
	if shell == null:
		return null
	assert_true((session_of(shell).call("submit", Fixtures.start_roles(ROLES, 3)) as CommandResult).ok, "Start")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	if not reduced:
		await wait_seconds(0.4)  # Bildschirmübergang abwarten
	return shell


func test_backdrop_follows_night_and_day() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var backdrop := find_node(current_screen(shell), "Backdrop") as Control
	assert_eq(backdrop.theme_type_variation, &"AppBackground", "Vorbereitung neutral")
	await press(find_button(current_screen(shell), "StartNightButton"))
	assert_eq(backdrop.theme_type_variation, &"NightBackdrop", "Nacht")
	assert_eq(backdrop.modulate.a, 1.0, "reduzierte Bewegung: sofort")
	var s := session_of(shell)
	s.call("answer_targets", [5])
	s.call("skip_next_step", "Test")
	s.call("begin_next_step")
	s.call("answer_choice", false)
	s.call("answer_choice", true)
	s.call("begin_next_step")
	s.call("answer_targets", [1])
	s.call("answer_choice", true)
	s.call("end_night")
	await frames(2)
	assert_eq(backdrop.theme_type_variation, &"DayBackdrop", "Tag")


func test_card_fades_in_and_new_render_cancels() -> void:
	var shell := await _cockpit(SIZE_16_10, "de", false)
	if shell == null:
		return
	var card := find_node(current_screen(shell), "ActionCard") as Control
	await press(find_button(current_screen(shell), "StartNightButton"))
	assert_true(card.modulate.a < 1.0, "neue Handlung blendet ein (%.2f)" % card.modulate.a)
	# Sofort weiter: Auswahl ändert nur dieselbe Karte, kein erneutes Einblenden nötig.
	await press(find_node(current_screen(shell), "SeatRing").call("token_for", 5) as BaseButton)
	await press(find_button(current_screen(shell), "ConfirmTargetsButton"))
	await wait_seconds(ThemeTokens.CARD_FADE_SECONDS + 0.15)
	assert_eq(card.modulate.a, 1.0, "Einblenden beendet, nichts bleibt halb transparent")
	var backdrop := find_node(current_screen(shell), "Backdrop") as Control
	await wait_seconds(ThemeTokens.BACKDROP_FADE_SECONDS)
	assert_eq(backdrop.modulate.a, 1.0, "Hintergrundwechsel beendet")


func test_reduced_motion_shows_card_immediately() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var card := find_node(current_screen(shell), "ActionCard") as Control
	await press(find_button(current_screen(shell), "StartNightButton"))
	assert_eq(card.modulate.a, 1.0, "kein Einblenden bei reduzierter Bewegung")


func test_focus_moves_to_next_card_action() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var start := find_button(current_screen(shell), "StartNightButton")
	start.grab_focus()
	await key(KEY_ENTER)
	await frames(2)
	var owner := focus_owner()
	var card := find_node(current_screen(shell), "ActionCard")
	assert_true(owner != null and card.is_ancestor_of(owner), "Fokus auf der neuen Karte (%s)" % (owner.name if owner != null else "keiner"))


func test_hooks_for_later_art_are_empty_and_settable() -> void:
	var shell := await _cockpit()
	if shell == null:
		return
	var screen := current_screen(shell)
	var art := find_node(screen, "BackdropArt") as TextureRect
	assert_true(art != null and art.texture == null, "Hintergrundebene vorbereitet, ohne Bild")
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var texture := ImageTexture.create_from_image(image)
	screen.call("set_backdrop_art", texture)
	assert_eq(art.texture, texture, "Bild setzbar")
	var token := find_node(screen, "SeatRing").call("token_for", 1) as Button
	assert_true(token.icon == null, "Platz ohne Porträt")
	token.call("set_portrait", texture)
	assert_eq(token.icon, texture, "Porträt setzbar")
	token.call("set_portrait", null)
	assert_true(token.icon == null and not token.expand_icon, "Porträt entfernbar")


func test_card_content_stays_inside_column_at_4_3() -> void:
	for locale: String in ["de", "en"]:
		var shell := await _cockpit(SIZE_4_3, locale)
		if shell == null:
			return
		var s := session_of(shell)
		s.call("start_night")
		s.call("answer_targets", [5])
		s.call("begin_next_step")
		s.call("answer_targets", [6])
		s.call("begin_next_step")  # Waldhexe: lange Texte und mehrere Aktionen
		await frames(3)
		var column := find_node(current_screen(shell), "InstructionCard") as Control
		var bounds := rect_of(column)
		for c: Control in visible_controls(find_node(current_screen(shell), "ActionCard")):
			var r := rect_of(c)
			assert_true(r.position.x >= bounds.position.x - 0.5 and r.end.x <= bounds.end.x + 0.5, "%s: %s innerhalb der Kartenbreite (%s in %s)" % [locale, c.name, r, bounds])
			if c is Button:
				assert_true(c.size.y >= ThemeTokens.TOUCH_MIN, "%s: %s Touch-Höhe" % [locale, c.name])
		_spawned.erase(shell)
		shell.get_parent().remove_child(shell)
		shell.free()
