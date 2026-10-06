class_name NightTab
extends GrimmButton
## Lasche am Rand des Bretts (Protokoll links, Optionen rechts). Zeichnet die senkrechte gemalte Lasche (`randlasche`, Dornen-Enden unverzerrt, Mitte
## gedehnt) mit einem Mondsilber-Symbol (Buch, Zahnrad); die Beschriftung (Übersetzung) bleibt als Button-Text für Bedienungshilfe und
## Tooltip erhalten, wird aber nicht gezeichnet. Die Tippfläche ist breiter als das Bild: mindestens `ThemeTokens.TOUCH_MIN` (48 px).

const ART_WIDTH := 110.0  ## Breite des Laschenbilds (Bild ist 220 breit; die Dornen nehmen davon etwa ein Drittel ein)
const STRIPE_CENTER := 0.602  ## senkrechte Mittelspange im Bild als Anteil der Bildbreite
const BEAD_RADIUS := 17.0  ## dunkle Scheibe unter dem Symbol auf der schmalen Spange
const GEAR_TEETH := 8
const GLYPH_SCALE := 1.2  ## Symbol im Innenraum der Lasche
const _STYLE_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const _FONT_COLORS: Array[String] = ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]

@export var glyph: String = "protocol"  ## "protocol" = Buch, "options" = Zahnrad
@export var at_right: bool = false  ## Laschenbild am rechten Rand (Tippfläche wächst nach links)


func _init() -> void:
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	for style: String in _STYLE_STATES:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in _FONT_COLORS:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN + 4.0, 220.0)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _has_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


func _draw() -> void:
	var box := GroveSkin.side_tab_box(_tint(), SkinArt.SIDE_TAB_FIT_WIDTH)
	var art := Rect2(size.x * 0.5 - ART_WIDTH * STRIPE_CENTER, 0.0, ART_WIDTH, size.y)  # Spange mittig in der Tippfläche
	if box == null:
		draw_rect(Rect2(Vector2.ZERO, size), ThemeTokens.BG_SURFACE)
	else:
		draw_style_box(box, art)
	var color := ThemeTokens.MOON_SILVER_DIM if disabled else (ThemeTokens.MOON_SILVER_BRIGHT if (is_hovered() or is_pressed()) else ThemeTokens.MOON_SILVER)
	var mid := Vector2(size.x * 0.5, size.y * 0.5)
	draw_circle(mid, BEAD_RADIUS, ThemeTokens.NUMBER_BG)
	draw_set_transform(mid, 0.0, Vector2(GLYPH_SCALE, GLYPH_SCALE))
	if glyph == "options":
		_draw_gear(Vector2.ZERO, color)
	else:
		_draw_book(Vector2.ZERO, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if has_focus():
		draw_rect(Rect2(Vector2.ZERO, size).grow(1.0), ThemeTokens.FOCUS_RING, false, float(ThemeTokens.FOCUS_WIDTH))


func _tint() -> Color:
	if disabled:
		return ThemeTokens.TINT_DEAD
	return ThemeTokens.TINT_HOVER if (is_pressed() or is_hovered()) else ThemeTokens.TINT_NONE


func _draw_book(c: Vector2, color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var page := PackedVector2Array([c + Vector2(1.2 * side, -4.0), c + Vector2(12.0 * side, -6.5), c + Vector2(12.0 * side, 6.5), c + Vector2(1.2 * side, 9.0), c + Vector2(1.2 * side, -4.0)])
		draw_polyline(page, color, 1.3, true)
		for row: int in 3:
			var dy := -1.0 + 3.2 * row
			draw_line(c + Vector2(3.6 * side, dy - 0.2), c + Vector2(9.6 * side, dy - 1.6), color, 0.9, true)


func _draw_gear(c: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for tooth: int in GEAR_TEETH:
		var a := TAU * tooth / GEAR_TEETH
		for step: Array in [[-0.2, 8.5], [-0.11, 12.0], [0.11, 12.0], [0.2, 8.5]]:
			points.append(c + Vector2.from_angle(a + float(step[0])) * float(step[1]))
	draw_colored_polygon(points, color)
	draw_circle(c, 3.8, ThemeTokens.NUMBER_BG)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT 			or what == NOTIFICATION_RESIZED or what == NOTIFICATION_DRAW or what == NOTIFICATION_VISIBILITY_CHANGED:
		queue_redraw()
