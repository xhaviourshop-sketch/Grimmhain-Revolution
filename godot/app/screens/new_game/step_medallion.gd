class_name StepMedallion
extends GrimmButton
## Ein Schrittmedaillon: Ring `card_medallion` mit Ziffer. Zustände: current (Ring blutrot getönt), done (Mondsilber, Häkchen statt
## Ziffer), open (gedämpft). Der Button-Text (Übersetzung) bleibt Bedienungshilfe und Tooltip und wird nicht gezeichnet.

var step: StringName = &""
var number: int = 0
var step_state: String = "open"


func setup(p_step: StringName, p_number: int) -> void:
	step = p_step
	number = p_number
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	custom_minimum_size = Vector2(ThemeTokens.MEDALLION_SIZE, ThemeTokens.MEDALLION_SIZE)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for style: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)
	format_values = {"number": number, "name": StringName("ui.prep.step.%s" % String(step))}
	text_key = "ui.prep.step.label"
	tooltip_text = tr(text_key).format(GrimmLabel.translated_values(self, format_values))


func show_state(p_state: String, reachable: bool) -> void:
	step_state = p_state
	disabled = not reachable and p_state != "current"
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size * 0.5) <= minf(size.x, size.y) * 0.5


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var tint := ThemeTokens.TINT_NONE
	var ink := ThemeTokens.MOON_SILVER
	match step_state:
		"current":
			tint = ThemeTokens.TINT_RING_ACTIVE
			ink = ThemeTokens.MOON_SILVER_BRIGHT
		"done":
			tint = ThemeTokens.TINT_RING_DONE
		_:
			tint = ThemeTokens.TINT_DEAD
			ink = ThemeTokens.MOON_SILVER_DIM
	if is_hovered() and not disabled:
		tint *= ThemeTokens.TINT_HOVER
	draw_circle(c, r * 0.8, ThemeTokens.NUMBER_BG)
	var ring := GroveSkin.texture("card_medallion")
	if ring != null:
		draw_texture_rect(ring, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, tint)
	else:
		draw_arc(c, r - 2.0, 0.0, TAU, 40, ink, 3.0, true)
	if step_state == "current":
		draw_arc(c, r + 1.0, 0.0, TAU, 40, ThemeTokens.BLOOD_RED_HALO, 2.0, true)
	if step_state == "done":
		draw_polyline(PackedVector2Array([c + Vector2(-r * 0.3, 0.0), c + Vector2(-r * 0.08, r * 0.24), c + Vector2(r * 0.34, -r * 0.24)]), ink, 3.5, true)
	else:
		var font := get_theme_default_font()
		var text := str(number)
		var size_px := ThemeTokens.FONT_SUBTITLE
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		draw_string(font, Vector2(c.x - w * 0.5, c.y + size_px * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, ink)
	if has_focus():
		draw_arc(c, r + 3.0, 0.0, TAU, 48, ThemeTokens.MOON_GLOW, float(ThemeTokens.FOCUS_WIDTH), true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
