class_name NamePlate
extends GrimmButton
## Namenszeile im Namensschritt: der Name auf der gemalten Listenzeile (Skin `listenzeile`), nie eine Nummer. Die Reihenfolge der Zeilen ist
## die Sitzordnung im Uhrzeigersinn, sie zeigt sich nur durch die Stellung. Ein freier Platz steht gedämpft mit „noch frei“; die gewählte
## Person trägt den glühenden Rubinstein der Haut (aktiv) rechts, ein doppelter Name ein „!“. Lange Namen verkleinern die Schrift, statt
## gekürzt zu werden. Der Button-Text ist Bedienungshilfe, Tooltip und Testanker und wird nicht gezeichnet. Antippen wählt (`pressed`);
## was folgt, entscheidet der Schritt.

const MIN_HEIGHT := 36.0
const MAX_ROW_HEIGHT := 52.0   ## höhere Flächen zeichnen die Zeile mittig in dieser Höhe, die Tippfläche bleibt ganz
const TEXT_LEFT := 26.0
const MARKER_WIDTH := 40.0     ## Platz für Rubinstein oder „!“ rechts
const STONE_SIZE := 26.0
const FIT_MIN_FONT := 12

var person_id: int = 0
var number: int = 0  ## Platz in der Reihenfolge (intern), wird nie angezeigt
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
	custom_minimum_size = Vector2(150.0, MIN_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	format_values = {"name": person_name}
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
	format_values = {}
	text_key = "ui.prep.names.plate_free"
	tooltip_text = ""
	disabled = true
	queue_redraw()


func _draw() -> void:
	var row_height := minf(size.y, MAX_ROW_HEIGHT)
	var row := Rect2(0.0, (size.y - row_height) * 0.5, size.x, row_height)
	var tint := ThemeTokens.TINT_NONE
	if empty:
		tint = ThemeTokens.TINT_DEAD
	elif is_hovered():
		tint = ThemeTokens.TINT_HOVER
	var box := SkinArt.row_box(tint)
	if box.texture != null:
		draw_style_box(box, row)
		if has_focus(true):
			draw_style_box(SkinArt.row_box(SkinArt.TINT_FOCUS), row)
	var marker := MARKER_WIDTH if duplicate or selected else 0.0
	var text := tr("ui.prep.names.plate_free") if empty else person_name
	var ink := ThemeTokens.MOON_SILVER_DIM if empty else ThemeTokens.PREP_CARD_TEXT
	var room := size.x - TEXT_LEFT - TEXT_LEFT - marker
	var font := get_theme_default_font()
	var font_size := FitLabel.best_size(font, text, Vector2(room, 0.0), ThemeTokens.FONT_BODY, FIT_MIN_FONT, false)
	var baseline := row.position.y + row_height * 0.5 + float(font_size) * 0.36
	draw_string(font, Vector2(TEXT_LEFT, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, room, font_size, ink)
	var centre := Vector2(size.x - TEXT_LEFT - STONE_SIZE * 0.5 + 6.0, row.position.y + row_height * 0.5)
	if selected:
		var stone := SkinArt.stone("aktiv")
		if stone != null:
			var side := Vector2(stone.get_size() * STONE_SIZE / stone.get_size().y)
			draw_texture_rect(stone, Rect2(centre - side * 0.5, side), false)
	elif duplicate:
		draw_arc(centre, 10.0, 0.0, TAU, 18, ThemeTokens.MOON_SILVER, 1.8, true)
		draw_string(font, centre + Vector2(-3.0, 6.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeTokens.FONT_CAPTION, ThemeTokens.MOON_SILVER_BRIGHT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
