class_name SeatToken
extends GrimmButton
## Ein Platz im Sitzkreis: „3 · Anna“. Zeigt nur Platznummer und Namen, nie eine Rolle. Antippen
## meldet `tapped`; Ziehen liefert die Personen-ID als Drag-Daten, ein anderer Platz nimmt sie an.
## Zustände (sichtbar über die Theme-Variation): normal, selected (zum Tauschen ausgewählt),
## dragging (wird gezogen, abgeblendet) und target (Ablageziel unter dem Zeiger).

signal tapped(person_id: int)
signal drag_begun(person_id: int)
signal drop_hovered(person_id: int)
signal dropped(source_id: int, target_id: int)

const DRAG_KEY := "seat_person_id"
const DRAGGING_ALPHA := 0.45
const STATE_VARIATIONS := {
	&"normal": &"CompactButton",
	&"selected": &"SeatSelectedButton",
	&"target": &"SeatTargetButton",
	&"dragging": &"CompactButton",
}

var person_id: int = 0
var seat_number: int = 0
var state: StringName = &"normal":
	set(value):
		state = value
		theme_type_variation = STATE_VARIATIONS.get(value, &"CompactButton")
		modulate.a = DRAGGING_ALPHA if value == &"dragging" else 1.0


## Einmal nach dem Erzeugen: feste Person, Kompaktschrift, eine Zeile mit Auslassungszeichen.
func setup(p_person_id: int) -> void:
	person_id = p_person_id
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.BUTTON_SECONDARY_HEIGHT)
	pressed.connect(func() -> void: tapped.emit(person_id))
	state = &"normal"


func show_seat(p_seat: int, name: String) -> void:
	seat_number = p_seat
	format_values = {"number": p_seat, "name": name}
	text_key = "ui.setup.seating.seat"


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = ThemeTokens.GOLD
	box.set_corner_radius_all(ThemeTokens.RADIUS_M)
	box.set_content_margin_all(ThemeTokens.SPACE_M)
	preview.add_theme_stylebox_override(&"panel", box)
	var label := Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	label.add_theme_font_size_override(&"font_size", ThemeTokens.FONT_COMPACT)
	label.add_theme_color_override(&"font_color", ThemeTokens.TEXT_ON_GOLD)
	preview.add_child(label)
	if get_viewport().gui_is_dragging():
		set_drag_preview(preview)
	else:
		preview.free()  # direkter Aufruf ohne laufendes Ziehen (Test): keine Vorschau
	drag_begun.emit(person_id)
	return {DRAG_KEY: person_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and (data as Dictionary).has(DRAG_KEY)):
		return false
	if int((data as Dictionary)[DRAG_KEY]) == person_id:
		return false
	drop_hovered.emit(person_id)
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	dropped.emit(int((data as Dictionary)[DRAG_KEY]), person_id)
