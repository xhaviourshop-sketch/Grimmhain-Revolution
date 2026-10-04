class_name ChoiceButton
extends GrimmButton
## Umschalter im Hain-Stil (Wahl zwischen zwei oder mehr Möglichkeiten in einer ButtonGroup): dunkles Teil `button_secondary`, die
## gewählte Möglichkeit auf dem roten Teil `button_primary` (Blutrot nur für Aktives). Zusätzlich trägt die gewählte Möglichkeit ein
## Häkchen links, die Wahl hängt also nie nur an der Farbe. Alle Zustände nur über Tönung.
## Verbinden über `toggled`, nicht `pressed` (Tests drücken Umschalter über `button_pressed`).


func _init() -> void:
	toggle_mode = true
	wrap = false
	clip_text = true
	custom_minimum_size = Vector2(ThemeTokens.BUTTON_PRIMARY_MIN_WIDTH, ThemeTokens.BUTTON_PRIMARY_HEIGHT)
	_skin()


func _skin() -> void:
	var dark := GroveSkin.texture("button_secondary")
	var red := GroveSkin.texture("button_primary")
	if dark == null or red == null:
		return
	var states := {
		"normal": [dark, ThemeTokens.TINT_NONE],
		"hover": [dark, GroveSkin.TINT_HOVER],
		"pressed": [red, ThemeTokens.TINT_NONE],
		"hover_pressed": [red, GroveSkin.TINT_HOVER],
		"disabled": [dark, GroveSkin.TINT_DISABLED],
	}
	for state: String in states:
		var box := GroveStyleBox.make(states[state][0], GroveArtData.BUTTON_PRIMARY_MARGINS, states[state][1])
		box.content_margin_left = GroveSkin.BUTTON_TEXT_INSET
		box.content_margin_right = GroveSkin.BUTTON_TEXT_INSET
		box.content_margin_top = 4.0
		box.content_margin_bottom = 4.0
		add_theme_stylebox_override(state, box)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	focus_entered.connect(func() -> void: self_modulate = GroveSkin.TINT_FOCUS)
	focus_exited.connect(func() -> void: self_modulate = ThemeTokens.TINT_NONE)
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		add_theme_color_override(color, ThemeTokens.TEXT_PRIMARY)
	add_theme_color_override("font_disabled_color", GroveSkin.TEXT_DISABLED)
	add_theme_font_size_override("font_size", ThemeTokens.FONT_CAPTION)


func _draw() -> void:
	if not button_pressed:
		return
	var c := Vector2(GroveSkin.BUTTON_TEXT_INSET * 0.5 + 4.0, size.y * 0.5)
	draw_polyline(PackedVector2Array([c + Vector2(-7.0, 0.0), c + Vector2(-2.0, 5.5), c + Vector2(8.0, -6.0)]), ThemeTokens.MOON_SILVER_BRIGHT, 3.0, true)
