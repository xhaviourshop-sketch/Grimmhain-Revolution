class_name NightTab
extends GrimmButton
## Lasche am Rand des Bretts (Protokoll links, Optionen rechts, P3). Zeichnet das textfreie Laschenbild; die Beschriftung
## (Übersetzung) bleibt als Button-Text für Bedienungshilfe und Tooltip erhalten, wird aber nicht gezeichnet. Die Tippfläche
## ist breiter als das Bild: mindestens `ThemeTokens.TOUCH_MIN` (48 px).

const ART_WIDTH := 44.0
const _STYLE_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const _FONT_COLORS: Array[String] = ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]

@export var art: String = "ui/tab-protocol.png"  ## Bild unter `res://assets/night/`
@export var at_right: bool = false  ## Laschenbild am rechten Rand (Tippfläche wächst nach links)


func _init() -> void:
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	for style: String in _STYLE_STATES:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in _FONT_COLORS:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)
	custom_minimum_size = Vector2(maxf(ThemeTokens.TOUCH_MIN + 4.0, ART_WIDTH), 220.0)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _has_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


func _draw() -> void:
	var texture := NightArt.texture(art)
	if texture == null:
		draw_rect(Rect2(Vector2.ZERO, size), ThemeTokens.BG_SURFACE)
		return
	var h := minf(size.y, ART_WIDTH * float(texture.get_height()) / float(texture.get_width()))
	var x := size.x - ART_WIDTH if at_right else 0.0
	var tint := ThemeTokens.TINT_NONE
	if disabled:
		tint = ThemeTokens.TINT_DEAD
	elif is_pressed() or is_hovered():
		tint = ThemeTokens.TINT_HOVER
	draw_texture_rect(texture, Rect2(x, (size.y - h) * 0.5, ART_WIDTH, h), false, tint)
	if has_focus():
		draw_rect(Rect2(x - 1.0, (size.y - h) * 0.5, ART_WIDTH + 2.0, h), ThemeTokens.FOCUS_RING, false, float(ThemeTokens.FOCUS_WIDTH))


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED or what == NOTIFICATION_DRAW or what == NOTIFICATION_VISIBILITY_CHANGED:
		queue_redraw()
