extends UiTestCase
## Theme-Tokens, Zustände, Kontrast, reduzierte Bewegung (Test 10) und Übergänge.

const COLOR_TOKENS: Array[String] = [
	"BG_APP", "BG_SURFACE", "BG_SURFACE_RAISED", "BG_OVERLAY", "BORDER_SUBTLE", "GOLD", "GOLD_BRIGHT", "GOLD_DEEP",
	"DANGER", "DANGER_BRIGHT", "DANGER_DEEP", "TEXT_PRIMARY", "TEXT_MUTED", "TEXT_ON_GOLD", "TEXT_DISABLED",
	"FOCUS_RING", "DISABLED_FILL", "DISABLED_BORDER",
]
const SIZE_TOKENS: Array[String] = [
	"SPACE_XS", "SPACE_S", "SPACE_M", "SPACE_L", "SPACE_XL", "RADIUS_S", "RADIUS_M", "RADIUS_L",
	"BORDER_THIN", "BORDER_THICK", "FOCUS_WIDTH", "FONT_CAPTION", "FONT_BODY", "FONT_BUTTON", "FONT_HEADING",
	"FONT_TITLE", "TOUCH_MIN", "BUTTON_SECONDARY_HEIGHT", "BUTTON_PRIMARY_HEIGHT", "SAFE_MARGIN",
	"MENU_COLUMN_WIDTH", "TRANSITION_SECONDS", "TRANSITION_OFFSET",
]
const BUTTON_VARIATIONS: Array[StringName] = [&"PrimaryButton", &"SecondaryButton", &"DangerButton"]
const STATES: Array[String] = ["normal", "hover", "pressed", "focus", "disabled"]


func test_tokens_complete() -> void:
	var tokens := load_script(THEME_TOKENS_SCRIPT)
	if tokens == null:
		return
	var constants := tokens.get_script_constant_map()
	for name: String in COLOR_TOKENS:
		assert_true(constants.get(name) is Color, "Farbtoken %s" % name)
	for name: String in SIZE_TOKENS:
		assert_true(constants.get(name) is int or constants.get(name) is float, "Größentoken %s" % name)
	var transition := float(constants.get("TRANSITION_SECONDS", 0.0))
	assert_true(transition >= 0.15 and transition <= 0.25, "Übergang 150 bis 250 ms (%s)" % transition)


func test_button_states_distinguishable() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var theme := shell.theme
	for variation: StringName in BUTTON_VARIATIONS:
		assert_true(theme.is_type_variation(variation, &"Button"), "%s ist Variation von Button" % variation)
		var seen: Array[String] = []
		for state: String in STATES:
			var box := theme.get_stylebox(state, variation) as StyleBoxFlat
			assert_true(box != null, "%s/%s als StyleBoxFlat" % [variation, state])
			if box == null:
				continue
			var signature := "%s|%s|%d" % [box.bg_color.to_html(), box.border_color.to_html(), box.border_width_bottom]
			if state != "focus":
				assert_false(seen.has(signature), "%s/%s unterscheidbar" % [variation, state])
				seen.append(signature)
		var focus := theme.get_stylebox("focus", variation) as StyleBoxFlat
		assert_true(focus != null and not focus.draw_center and focus.border_width_top >= 2, "%s: Fokusrahmen sichtbar" % variation)
		assert_ne(theme.get_color("font_disabled_color", variation), theme.get_color("font_color", variation), "%s: deaktivierter Text unterscheidbar" % variation)
	# Primär, sekundär und Gefahr unterscheiden sich im Normalzustand.
	var normals: Array[String] = []
	for variation: StringName in BUTTON_VARIATIONS:
		var box := theme.get_stylebox("normal", variation) as StyleBoxFlat
		if box != null:
			assert_false(normals.has(box.bg_color.to_html()), "%s mit eigener Grundfarbe" % variation)
			normals.append(box.bg_color.to_html())


func test_text_contrast() -> void:
	# WCAG AA: Text ≥ 4,5:1, Fokusrahmen ≥ 3:1.
	var tokens := load_script(THEME_TOKENS_SCRIPT)
	if tokens == null:
		return
	var c := tokens.get_script_constant_map()
	var pairs := [
		["TEXT_PRIMARY", "BG_APP", 4.5], ["TEXT_PRIMARY", "BG_SURFACE", 4.5], ["TEXT_PRIMARY", "BG_SURFACE_RAISED", 4.5],
		["TEXT_MUTED", "BG_SURFACE", 4.5], ["TEXT_MUTED", "BG_APP", 4.5], ["TEXT_ON_GOLD", "GOLD", 4.5],
		["TEXT_ON_GOLD", "GOLD_BRIGHT", 4.5], ["TEXT_PRIMARY", "DANGER", 4.5], ["GOLD", "BG_SURFACE", 4.5],
		["FOCUS_RING", "BG_APP", 3.0], ["FOCUS_RING", "BG_SURFACE", 3.0],
	]
	for pair: Array in pairs:
		if not (c.get(pair[0]) is Color and c.get(pair[1]) is Color):
			fail("Token %s/%s fehlt" % [pair[0], pair[1]])
			continue
		var ratio := _contrast(c[pair[0]], c[pair[1]])
		assert_true(ratio >= float(pair[2]), "Kontrast %s auf %s: %.2f (mind. %s)" % [pair[0], pair[1], ratio, pair[2]])


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(c: Color) -> float:
	var channels: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		channels.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


func test_no_hardcoded_styles_outside_theme() -> void:
	var scene_forbidden := RegEx.create_from_string("Color\\(|theme_override_|custom_minimum_size|StyleBox|FontFile|font_size")
	for path: String in files_in("res://app", ".tscn"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			assert_true(scene_forbidden.search(lines[n]) == null, "%s:%d Stilwert in der Szene: %s" % [path, n + 1, lines[n].strip_edges()])
	var script_forbidden := RegEx.create_from_string("\\bColor(8)?\\s*\\(|Color\\.html|Color\\.[A-Z_]{3,}")
	for path: String in files_in("res://app", ".gd"):
		if path.begins_with("res://app/theme/"):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var code := lines[n].split("#")[0]
			assert_true(script_forbidden.search(code) == null, "%s:%d Farbwert außerhalb der Tokens: %s" % [path, n + 1, code.strip_edges()])


func test_no_unlicensed_fonts_embedded() -> void:
	# Schriftentscheidung offen: keine Schriftdatei im Godot-Projekt, Engine-Standardschrift.
	for ext: String in [".ttf", ".otf", ".woff", ".woff2"]:
		assert_eq(files_in("res://", ext).size(), 0, "keine %s-Datei im Godot-Projekt" % ext)
	var shell := await spawn_shell()
	if shell != null:
		assert_true(shell.theme.default_font == null, "keine eigene Schrift im Theme")


func test_reduced_motion_disables_transitions() -> void:
	# 10
	var shell := await spawn_shell(SIZE_16_10, "de", false)
	if shell == null:
		return
	var router := router_of(shell)
	var duration := float(router.call("transition_duration"))
	assert_true(duration >= 0.15 and duration <= 0.25, "Übergang aktiv: %.2f s" % duration)
	shell.call("navigate", &"main_menu")
	var screen := current_screen(shell)
	assert_true(screen != null and screen.modulate.a < 1.0, "neue Ansicht blendet ein")
	await wait_seconds(duration + 0.2)
	await frames(2)
	assert_true(screen != null and is_equal_approx(screen.modulate.a, 1.0) and screen.position.is_zero_approx(), "Übergang abgeschlossen")
	settings_of(shell).call("set_reduced_motion", true)
	assert_eq(float(router.call("transition_duration")), 0.0, "reduzierte Bewegung: keine Übergangszeit")
	shell.call("navigate", &"settings")
	screen = current_screen(shell)
	assert_true(screen != null and is_equal_approx(screen.modulate.a, 1.0) and screen.position.is_zero_approx(), "sofort sichtbar ohne Bewegung")
	var toast := shell.call("get_toast") as Control
	assert_eq(float(toast.call("fade_duration")), 0.0, "Statusmeldung ohne Einblendung")
	await frames(2)
	var toggle := find_button(screen, "ReducedMotionToggle")
	assert_true(toggle != null and toggle.button_pressed, "Schalter zeigt den Zustand")
	await press(toggle)
	assert_false(bool(settings_of(shell).get("reduced_motion")), "Schalter ändert die Einstellung")
	assert_true(float(router.call("transition_duration")) > 0.0, "Übergänge wieder aktiv")


func test_settings_foundation_for_left_handed_mode() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var s := settings_of(shell)
	assert_false(bool(s.get("left_handed")), "Linkshänder-Grundlage vorhanden, standardmäßig aus")
	var changes: Array[String] = []
	s.connect("changed", func(k: StringName) -> void: changes.append(String(k)))
	s.call("set_left_handed", true)
	assert_true(bool(s.get("left_handed")) and changes.has("left_handed"), "Zustand änderbar und gemeldet")


func test_switch_icon_is_themed() -> void:
	# Nachträglich ergänzt: Schalter „Bewegung reduzieren“ nutzt kein Engine-Standardsymbol.
	var shell := await spawn_shell()
	if shell == null:
		return
	var theme := shell.theme
	for icon: String in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
		assert_true(theme.has_icon(icon, &"CheckButton"), "Schaltersymbol %s im Theme" % icon)
	var on := theme.get_icon("checked", &"CheckButton").get_image()
	var off := theme.get_icon("unchecked", &"CheckButton").get_image()
	assert_true(on != null and off != null and on.get_size() == off.get_size(), "gleiche Größe an/aus")
	if on != null and off != null:
		assert_ne(on.get_data(), off.get_data(), "an und aus unterscheiden sich")
		assert_true(on.get_height() >= 24, "Schalter gut erkennbar (%d px hoch)" % on.get_height())
