class_name RoleChip
extends GrimmButton
## Rollenmarke der Vorbereitung: Silbersymbol im Hain-Medaillon `role_medallion` links, Rollenname auf dem Schild `name_plate_short`.
## Dient als Rollenkachel im Rollenschritt (`RoleTile`), in der Rollenleiste beim Zuordnen (Teamfarbe, größer über `set_scale_factor`). Der Button-Text (Name) ist Bedienungshilfe, Tooltip und Testanker und wird nicht gezeichnet.

const MEDALLION := 52.0
const PLATE_HEIGHT := 38.0
const PAD := 14.0

## Wird die Marke angetippt, während sie `chosen` ist, glüht sie (`glow_when_chosen`, Rollenkachel).

var role: StringName = &""
var count: int = 1
var dimmed: bool = false:
	set(value):
		dimmed = value
		queue_redraw()
var team_tint: bool = false          ## Namensschild in der Teamfarbe der Rolle (Kachel, Rollenleiste)
var glow_when_chosen: bool = false   ## Kachel: gewählt = Teamfarbe plus Glühen
var chosen: bool = true:
	set(value):
		chosen = value
		if glow_when_chosen:
			SelectionGlow.set_on(self, "name_plate_short", GroveArtData.NAME_PLATE_SHORT_MARGINS, value, Vector4(MEDALLION * 0.5 * k, (float(ThemeTokens.ROLE_CHIP_HEIGHT) - PLATE_HEIGHT) * 0.5 * k, 0.0, (float(ThemeTokens.ROLE_CHIP_HEIGHT) - PLATE_HEIGHT) * 0.5 * k), _glow_color())
		queue_redraw()
var force_count: bool = false         ## „×N“ auch bei einer Kopie (Kachel mit Zähler)
var k: float = 1.0                   ## Größenfaktor (Rollenleiste im Kartenmodus ist größer)
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
func set_scale_factor(factor: float) -> void:
	k = factor
	custom_minimum_size.y = float(ThemeTokens.ROLE_CHIP_HEIGHT) * k
	_fit()


## Farbe des Namensschilds: Teamfarbe (gewählt) oder entsättigt (nicht gewählt); ohne Teamfarbe unverändert.
func _glow_color() -> Color:
	match SetupRoleCatalog.faction_of(role):
		Faction.WOLVES:
			return ThemeTokens.GLOW_WOLVES
		Faction.SOLO:
			return ThemeTokens.GLOW_SOLO
	return ThemeTokens.GLOW_VILLAGE


func _plate_tint(base: Color) -> Color:
	if not team_tint:
		return base
	var team_color := ThemeTokens.TEAM_PLATE_VILLAGE
	match SetupRoleCatalog.faction_of(role):
		Faction.WOLVES:
			team_color = ThemeTokens.TEAM_PLATE_WOLVES
		Faction.SOLO:
			team_color = ThemeTokens.TEAM_PLATE_SOLO
	return (team_color if chosen else ThemeTokens.TEAM_PLATE_OFF) * base


func show_role(p_role: StringName, p_count: int = 1) -> void:
	role = p_role
	count = p_count
	name = "Role_%s" % String(role).replace("-", "_")
	text_key = RolePresentation.name_key(role)
	tooltip_text = tr(text_key)
	_fit()


func _fit() -> void:
	_label = tr(text_key)
	if count > 1 or force_count:
		_label += " ×%d" % count
	var width := get_theme_default_font().get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size()).x
	custom_minimum_size.x = maxf(float(ThemeTokens.ROLE_CHIP_MIN_WIDTH) * 0.6 * k, MEDALLION * k + 4.0 + width + PAD + 6.0)
	queue_redraw()


func _font_size() -> int:
	return int(round(float(ThemeTokens.FONT_COMPACT) * k))


func _draw() -> void:
	var mid := size.y * 0.5
	var tint := ThemeTokens.TINT_NONE
	if dimmed or disabled:
		tint = ThemeTokens.TINT_DEAD
	elif is_hovered():
		tint = ThemeTokens.TINT_HOVER
	var medallion := MEDALLION * k
	var plate_height := PLATE_HEIGHT * k
	var plate := Rect2(medallion * 0.5, mid - plate_height * 0.5, size.x - medallion * 0.5, plate_height)
	var plate_tex := GroveSkin.texture("name_plate_short")
	if plate_tex != null:
		draw_style_box(GroveStyleBox.make(plate_tex, GroveArtData.NAME_PLATE_SHORT_MARGINS, _plate_tint(tint)), plate)
	else:
		draw_rect(plate, ThemeTokens.PLATE_BG)
	var centre := Vector2(medallion * 0.5, mid)
	_draw_medallion(centre, tint)
	var font := get_theme_default_font()
	var left := medallion + 4.0
	var ink := ThemeTokens.PREP_CARD_TEXT
	if team_tint and not chosen:
		ink = ThemeTokens.MOON_SILVER_DIM
	var font_size := _font_size()
	draw_string(font, Vector2(left, mid + float(font_size) * 0.36), _label, HORIZONTAL_ALIGNMENT_LEFT, size.x - left - PAD * 0.5, font_size, ink * (ThemeTokens.TINT_DEAD if dimmed else ThemeTokens.TINT_NONE))
	if has_focus(true):
		var box := StyleBoxFlat.new()
		box.draw_center = false
		box.border_color = ThemeTokens.MOON_GLOW
		box.set_border_width_all(ThemeTokens.FOCUS_WIDTH)
		box.set_corner_radius_all(ThemeTokens.RADIUS_M)
		draw_style_box(box, Rect2(Vector2.ZERO, size).grow(-1.0))


func _draw_medallion(centre: Vector2, p_tint: Color) -> void:
	var tint := p_tint * (ThemeTokens.TINT_NONE if chosen or not team_tint else ThemeTokens.TINT_DEAD)
	var ring := GroveSkin.texture("role_medallion")
	var side := MEDALLION * k
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
