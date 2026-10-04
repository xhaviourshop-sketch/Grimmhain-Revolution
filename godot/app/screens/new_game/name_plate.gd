class_name NamePlate
extends GrimmButton
## Nummeriertes Namensschild im Namensschritt: runde Nummer links, Name auf dem Hain-Teil `name_plate_short`. Die Nummer ist der Sitzplatz im
## Uhrzeigersinn. Ein freier Platz (noch kein Name) steht gedämpft mit „frei“; die gewählte Person trägt einen blutroten Rahmen und ein
## Häkchen (Blutrot nur für Aktives), ein doppelter Name ein „!“. Der Button-Text (Nummer und Name) ist Bedienungshilfe, Tooltip und
## Testanker und wird nicht gezeichnet. Antippen wählt (`pressed`); was folgt, entscheidet der Schritt.

const NUMBER_RADIUS := 18.0
const PLATE_HEIGHT := 40.0
const TEXT_PAD := 14.0     ## Abstand des Namens zu Nummer und rechtem Rand
const MARKER_WIDTH := 26.0  ## Platz für Häkchen oder „!“ rechts

var person_id: int = 0
var number: int = 0
var person_name: String = ""
var empty: bool = true
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var duplicate: bool = false


func _init() -> void:
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	custom_minimum_size = Vector2(ThemeTokens.NAME_PLATE_MIN_WIDTH, ThemeTokens.NAME_PLATE_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for style: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)


func show_person(entry: Dictionary) -> void:
	person_id = int(entry["person_id"])
	number = int(entry["number"])
	person_name = str(entry["name"])
	empty = false
	duplicate = bool(entry.get("duplicate", false))
	format_values = {"number": number, "name": person_name}
	text_key = "ui.prep.names.plate"
	tooltip_text = person_name
	disabled = false
	queue_redraw()


## Freier Platz `p_number`: noch kein Name; nicht antippbar.
func show_empty(p_number: int) -> void:
	person_id = 0
	number = p_number
	person_name = ""
	empty = true
	duplicate = false
	selected = false
	format_values = {"number": number}
	text_key = "ui.prep.names.plate_free"
	tooltip_text = ""
	disabled = true
	queue_redraw()


func _draw() -> void:
	var mid := size.y * 0.5
	var dim := ThemeTokens.TINT_NONE if not empty else ThemeTokens.TINT_DEAD
	if is_hovered() and not empty:
		dim = ThemeTokens.TINT_HOVER
	var plate_left := NUMBER_RADIUS + 6.0
	var plate_rect := Rect2(plate_left, mid - PLATE_HEIGHT * 0.5, size.x - plate_left, PLATE_HEIGHT)
	var tex := GroveSkin.texture("name_plate_short")
	if tex != null:
		draw_style_box(GroveStyleBox.make(tex, GroveArtData.NAME_PLATE_SHORT_MARGINS, dim), plate_rect)
	else:
		draw_rect(plate_rect, ThemeTokens.PLATE_BG)
	if selected:
		var box := StyleBoxFlat.new()
		box.draw_center = false
		box.border_color = ThemeTokens.BLOOD_RED
		box.set_border_width_all(3)
		box.set_corner_radius_all(ThemeTokens.RADIUS_M)
		draw_style_box(box, plate_rect.grow(3.0))
	var centre := Vector2(NUMBER_RADIUS + 2.0, mid)
	draw_circle(centre, NUMBER_RADIUS, ThemeTokens.NUMBER_BG)
	draw_arc(centre, NUMBER_RADIUS, 0.0, TAU, 28, ThemeTokens.BLOOD_RED if selected else (ThemeTokens.MOON_SILVER_DIM if empty else ThemeTokens.MOON_SILVER), 2.0, true)
	var font := get_theme_default_font()
	var digits := str(number)
	var digit_size := ThemeTokens.FONT_COMPACT
	var digit_width := font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, digit_size).x
	draw_string(font, Vector2(centre.x - digit_width * 0.5, centre.y + digit_size * 0.36), digits, HORIZONTAL_ALIGNMENT_LEFT, -1, digit_size, ThemeTokens.MOON_SILVER_DIM if empty else ThemeTokens.MOON_SILVER_BRIGHT)
	var text_left := plate_left + TEXT_PAD
	var text_right := size.x - TEXT_PAD - (MARKER_WIDTH if duplicate or selected else 0.0)
	var text := tr("ui.prep.names.free") if empty else person_name
	var ink := ThemeTokens.MOON_SILVER_DIM if empty else ThemeTokens.PREP_CARD_TEXT
	var font_size := ThemeTokens.FONT_COMPACT
	var shown := text
	while shown.length() > 1 and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > text_right - text_left:
		shown = shown.left(shown.length() - 2).strip_edges() + "…"
		if shown == "…":
			break
	draw_string(font, Vector2(text_left, mid + font_size * 0.36), shown, HORIZONTAL_ALIGNMENT_LEFT, text_right - text_left, font_size, ink)
	if selected:
		var c := Vector2(size.x - TEXT_PAD - 8.0, mid)
		draw_polyline(PackedVector2Array([c + Vector2(-6.0, 0.5), c + Vector2(-2.0, 4.5), c + Vector2(6.5, -5.0)]), ThemeTokens.MOON_SILVER_BRIGHT, 2.6, true)
	elif duplicate:
		var c2 := Vector2(size.x - TEXT_PAD - 8.0, mid)
		draw_arc(c2, 9.0, 0.0, TAU, 18, ThemeTokens.MOON_SILVER, 1.8, true)
		draw_string(font, c2 + Vector2(-3.0, 5.5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeTokens.FONT_CAPTION, ThemeTokens.MOON_SILVER_BRIGHT)
	if has_focus():
		draw_style_box(_focus_box(), plate_rect.grow(4.0))


static func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = ThemeTokens.MOON_GLOW
	box.set_border_width_all(ThemeTokens.FOCUS_WIDTH)
	box.set_corner_radius_all(ThemeTokens.RADIUS_M)
	return box


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
