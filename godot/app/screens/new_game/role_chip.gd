class_name RoleChip
extends GrimmButton
## Rollenmarke der Vorbereitung: Silbersymbol im Hain-Medaillon `role_medallion` links, Rollenname auf dem Schild `name_plate_short`.
## Dient in der Rollenübersicht (Antippen öffnet die Rollenaktionen), in der Rollenleiste beim Zuordnen und als „Rolle hinzufügen“
## (gestrichelter Rand, Plus statt Symbol). Der Button-Text (Name) ist Bedienungshilfe, Tooltip und Testanker und wird nicht gezeichnet.

const MEDALLION := 52.0
const PLATE_HEIGHT := 38.0
const PAD := 14.0

var role: StringName = &""
var team: StringName = &""   ## nur bei der „Rolle hinzufügen“-Marke: das Team der Gruppe
var is_add: bool = false
var count: int = 1
var dimmed: bool = false:
	set(value):
		dimmed = value
		queue_redraw()
var _label: String = ""


func _init() -> void:
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	custom_minimum_size = Vector2(ThemeTokens.ROLE_CHIP_MIN_WIDTH, ThemeTokens.ROLE_CHIP_HEIGHT)
	for style: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)


## Rolle mit Name und optionaler Anzahl (Die Gebundenen können mehrfach vorkommen).
func show_role(p_role: StringName, p_count: int = 1) -> void:
	role = p_role
	count = p_count
	is_add = false
	name = "Role_%s" % String(role).replace("-", "_")
	text_key = RolePresentation.name_key(role)
	tooltip_text = tr(text_key)
	_fit()


func show_add(p_team: StringName) -> void:
	team = p_team
	is_add = true
	name = "Add_%s" % String(team)
	text_key = "ui.prep.roles.add"
	tooltip_text = tr(text_key)
	_fit()


func _fit() -> void:
	_label = tr(text_key)
	if count > 1:
		_label += " ×%d" % count
	var width := get_theme_default_font().get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeTokens.FONT_COMPACT).x
	custom_minimum_size.x = maxf(float(ThemeTokens.ROLE_CHIP_MIN_WIDTH) * 0.6, MEDALLION * 0.5 + 12.0 + PAD + width + PAD + 6.0)
	queue_redraw()


func _draw() -> void:
	var mid := size.y * 0.5
	var tint := ThemeTokens.TINT_NONE
	if dimmed or disabled:
		tint = ThemeTokens.TINT_DEAD
	elif is_hovered():
		tint = ThemeTokens.TINT_HOVER
	var plate := Rect2(MEDALLION * 0.5, mid - PLATE_HEIGHT * 0.5, size.x - MEDALLION * 0.5, PLATE_HEIGHT)
	var plate_tex := GroveSkin.texture("name_plate_short")
	if is_add:
		var dash := StyleBoxFlat.new()
		dash.bg_color = ThemeTokens.PREP_DASH_FILL
		dash.border_color = ThemeTokens.MOON_SILVER_DIM
		dash.set_border_width_all(2)
		dash.set_corner_radius_all(ThemeTokens.RADIUS_M)
		draw_style_box(dash, Rect2(0.0, mid - PLATE_HEIGHT * 0.5, size.x, PLATE_HEIGHT))
	elif plate_tex != null:
		draw_style_box(GroveStyleBox.make(plate_tex, GroveArtData.NAME_PLATE_SHORT_MARGINS, tint), plate)
	else:
		draw_rect(plate, ThemeTokens.PLATE_BG)
	var centre := Vector2(MEDALLION * 0.5, mid)
	if is_add:
		draw_line(Vector2(PAD, mid), Vector2(PAD + 14.0, mid), ThemeTokens.MOON_SILVER, 2.4, true)
		draw_line(Vector2(PAD + 7.0, mid - 7.0), Vector2(PAD + 7.0, mid + 7.0), ThemeTokens.MOON_SILVER, 2.4, true)
	else:
		_draw_medallion(centre, tint)
	var font := get_theme_default_font()
	var left := MEDALLION + 4.0 if not is_add else PAD + 24.0
	var ink := ThemeTokens.MOON_SILVER if is_add else ThemeTokens.PREP_CARD_TEXT
	draw_string(font, Vector2(left, mid + ThemeTokens.FONT_COMPACT * 0.36), _label, HORIZONTAL_ALIGNMENT_LEFT, size.x - left - PAD * 0.5, ThemeTokens.FONT_COMPACT, ink * (ThemeTokens.TINT_DEAD if dimmed else ThemeTokens.TINT_NONE))
	if has_focus():
		var box := StyleBoxFlat.new()
		box.draw_center = false
		box.border_color = ThemeTokens.MOON_GLOW
		box.set_border_width_all(ThemeTokens.FOCUS_WIDTH)
		box.set_corner_radius_all(ThemeTokens.RADIUS_M)
		draw_style_box(box, Rect2(Vector2.ZERO, size).grow(-1.0))


func _draw_medallion(centre: Vector2, tint: Color) -> void:
	var ring := GroveSkin.texture("role_medallion")
	var side := MEDALLION
	var frame := Rect2(centre - Vector2(side, side * GroveArtData.ROLE_MEDALLION_ASPECT) * 0.5, Vector2(side, side * GroveArtData.ROLE_MEDALLION_ASPECT))
	var hole_centre := frame.position + GroveArtData.ROLE_MEDALLION_HOLE_CENTER * frame.size
	var hole_radius := GroveArtData.ROLE_MEDALLION_HOLE_RADIUS * side
	draw_circle(hole_centre, hole_radius * 1.02, ThemeTokens.NUMBER_BG)
	var symbol := NightArt.role_symbol(role)
	if symbol != null:
		var inner := hole_radius * 1.7
		draw_texture_rect(symbol, Rect2(hole_centre - Vector2(inner, inner) * 0.5, Vector2(inner, inner)), false, ThemeTokens.TINT_ART_OPEN * tint)
	if ring != null:
		draw_texture_rect(ring, frame, false, tint)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSLATION_CHANGED:
		if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and text_key != "":
			_fit()
		queue_redraw()
