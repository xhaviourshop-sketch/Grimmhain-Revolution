class_name EpicButton
extends Control
## Epischer Knopf (Knopf-Typ „epic“, nur für „Eintreten“ und „Spiel beginnen“): Wolfskopf links, Krallenspuren rechts, Lava in der Mitte.
## `EpicButton.apply(button, animated)` macht aus einem GrimmButton diesen Knopf: Es ersetzt dessen Rahmen durch die Fläche (Kind-Node
## `EpicFace`), setzt große helle Schrift mit dunklem Umriss und Mindesthöhe `MIN_HEIGHT`. Die Enden werden nie gestreckt (gleicher
## Maßstab wie die Balkenhöhe), die Lava-Mitte wird gekachelt. Die Mitte liegt unter den Enden; deren Innenkante läuft weich aus.
## Normal pulsiert die Lava langsam (`PULSE_SECONDS`, Shader). Gedrückt: kurz heller und leichtes Einsinken (`PRESS_SECONDS`).
## Kein Rechteck-Glühen (SelectionGlow) um diesen Knopf. Bei reduzierter Bewegung steht die Lava still und der Druck wirkt ohne Übergang.

const MIN_HEIGHT := 72.0
const PULSE_SECONDS := 3.0
const PRESS_SECONDS := 0.1
const PRESS_SCALE := 0.965
const PRESS_BOOST := 0.7
const FOCUS_BOOST := 0.3
const LEFT := "res://assets/ui/epic_button_left.webp"
const MID := "res://assets/ui/epic_button_mid.webp"
const RIGHT := "res://assets/ui/epic_button_right.webp"
## Maße im Quellbild (Pixel): Balkenhöhe und Überstand der Zierde oben; Breite der Enden samt auslaufender Kante.
const BAR_PX := 324.0
const TOP_OVERHANG_PX := 73.0
const FEATHER_PX := 60.0
const SHADER := """
shader_type canvas_item;
uniform float period = 3.0;
uniform float amp = 0.32;
uniform float boost = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float red = clamp((c.r - 0.6 * max(c.g, c.b)) * 2.0, 0.0, 1.0);
	float pulse = 0.5 + 0.5 * sin(TIME * 6.28318 / period);
	float k = amp * pulse + boost;
	c.rgb += vec3(0.62, 0.14, 0.05) * red * k + vec3(0.1, 0.06, 0.05) * boost;
	COLOR = c * COLOR;
}
"""

static var _shader: Shader = null

var _button: GrimmButton = null
var _left: Texture2D = null
var _mid: Texture2D = null
var _right: Texture2D = null
var _material: ShaderMaterial = null
var _tween: Tween = null
var _animated: bool = true


## Macht `button` zum epischen Knopf. Fehlen die Bilder, bleibt der Knopf unverändert.
static func apply(button: GrimmButton, animated: bool) -> void:
	if button.get_node_or_null("EpicFace") != null:
		return
	var face := EpicButton.new()
	face.name = "EpicFace"
	face._attach(button, animated)


func _attach(button: GrimmButton, animated: bool) -> void:
	_left = load(LEFT) as Texture2D
	_mid = load(MID) as Texture2D
	_right = load(RIGHT) as Texture2D
	if _left == null or _mid == null or _right == null:
		queue_free()  # nicht free(): im Web-Export ist das ein Parse-Fehler (Startbildschirm lud nicht)
		return
	_button = button
	_animated = animated
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = false
	_material = _make_material()
	material = _material
	button.add_child(self)
	button.wrap = false
	button.main = false  # der Lava-Knopf trägt keinen Rubinstein
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, MIN_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.clip_contents = false
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, ThemeTokens.TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", ThemeTokens.TEXT_MUTED)
	button.add_theme_color_override("font_outline_color", ThemeTokens.EPIC_TEXT_OUTLINE)
	button.add_theme_constant_override("outline_size", 8)
	button.add_theme_font_size_override("font_size", ThemeTokens.FONT_HEADING + 4)
	button.add_theme_color_override("font_shadow_color", ThemeTokens.EPIC_TEXT_SHADOW)
	button.add_theme_constant_override("shadow_offset_x", 0)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.pivot_offset = button.size * 0.5
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.button_down.connect(_on_down)
	button.button_up.connect(_on_up)
	button.focus_entered.connect(_refresh_boost)
	button.focus_exited.connect(_refresh_boost)
	button.draw.connect(_on_button_draw)
	_material.set_shader_parameter("amp", 0.32 if animated else 0.14)
	_refresh_boost()


static func _make_material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("period", PULSE_SECONDS)
	return m


func _on_down() -> void:
	_press(true)


func _on_up() -> void:
	_press(false)


func _press(down: bool) -> void:
	if _button == null or not is_inside_tree():
		return
	var boost := PRESS_BOOST if down else _rest_boost()
	var scale_to := Vector2.ONE * (PRESS_SCALE if down else 1.0)
	if _tween != null:
		_tween.kill()
	if not _animated:
		_material.set_shader_parameter("boost", boost)
		_button.scale = scale_to
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_button, "scale", scale_to, PRESS_SECONDS)
	_tween.tween_method(func(v: float) -> void: _material.set_shader_parameter("boost", v), float(_material.get_shader_parameter("boost")), boost, PRESS_SECONDS)


func _rest_boost() -> float:
	return FOCUS_BOOST if _button != null and _button.has_focus(true) and not _button.disabled else 0.0


func _refresh_boost() -> void:
	if _material != null and (_tween == null or not _tween.is_running()):
		_material.set_shader_parameter("boost", _rest_boost())


func _on_button_draw() -> void:
	modulate = ThemeTokens.TINT_EPIC_DISABLED if _button.disabled else ThemeTokens.TINT_NONE


func _draw() -> void:
	if _left == null:
		return
	var s := size.y / BAR_PX
	var top := -TOP_OVERHANG_PX * s
	var full_h := float(_left.get_height()) * s
	var left_w := float(_left.get_width()) * s
	var right_w := float(_right.get_width()) * s
	var feather := FEATHER_PX * s
	var mid_from := left_w - feather
	var mid_to := size.x - right_w + feather
	var tile_w := float(_mid.get_width()) * s
	var x := mid_from
	while x < mid_to - 0.01:
		var w := minf(tile_w, mid_to - x)
		draw_texture_rect_region(_mid, Rect2(x, top, w, full_h), Rect2(0.0, 0.0, w / s, float(_mid.get_height())))
		x += w
	draw_texture_rect(_left, Rect2(0.0, top, left_w, full_h), false)
	draw_texture_rect(_right, Rect2(size.x - right_w, top, right_w, full_h), false)
