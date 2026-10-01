class_name NightOrderBar
extends Control
## Nachtreihenfolge-Leiste oben (P3, Mockup V3): je Rolle ein ovaler Slot mit Rollensymbol, Nummer und Name; erledigt, aktiv
## (roter Rand) und offen unterscheiden sich durch Slotbild, Helligkeit und Beschriftung. Passt nicht alles in die Breite, blättern
## zwei Pfeile. Einklappbar: als Chip zeigt sie nur die aktive Rolle (auf 4:3 Standard, Entscheidung Abnahme 1).
## Reine Darstellung: Die Einträge kommen aus `GameSession.night_order()` (geheim, die Ansicht blendet die Leiste bei „Verbergen“
## aus). Namen immer aus der Übersetzung, nie aus Bildern.

signal expand_toggled(expanded: bool)

const FULL_HEIGHT := 130.0
const CHIP_SIZE := Vector2(320.0, 52.0)
const SLOT_HEIGHT := 84.0
const SLOT_PITCH_MIN := 92.0
const EDGE := 45.0
const SYMBOL_SIZE := 42.0
const FRAME_MARGIN := Vector2(30.0, 25.0)  ## 9-Slice-Ränder des Rahmenbilds (Bild 168 px hoch)
const LABEL_SIZE := 11
const NUMBER_SIZE := 10
const CHIP_FONT_SIZE := 17
const ARROW_SIZE := 26.0

var _entries: Array = []
var _expanded: bool = true
var _collapsible: bool = false
var _first: int = 0
var _peek: int = 0  ## eingeklappt: angezeigter Eintrag (Pfeile blättern, Wechsel der Nacht setzt auf aktiv)
var _left: TextureButton
var _right: TextureButton
var _toggle: Button


func _init() -> void:
	name = "NightOrderBar"
	mouse_filter = Control.MOUSE_FILTER_PASS
	_left = _arrow("ArrowLeftButton", "ui/arrow-left.png", -1)
	_right = _arrow("ArrowRightButton", "ui/arrow-right.png", 1)
	_toggle = Button.new()
	_toggle.name = "ToggleButton"
	_toggle.flat = true
	_toggle.focus_mode = Control.FOCUS_ALL
	_toggle.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_toggle.custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	_toggle.pressed.connect(_on_toggle)
	add_child(_toggle)


func _arrow(node_name: String, art: String, step: int) -> TextureButton:
	var b := TextureButton.new()
	b.name = node_name
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.texture_normal = NightArt.texture(art)
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	b.pressed.connect(_step.bind(step))
	add_child(b)
	return b


## Aktualisiert Einträge und Zustand. `expanded` false = Chip. `collapsible` zeigt den Umschalter.
func show_order(entries: Array, expanded: bool, collapsible: bool) -> void:
	var active := _active_index(entries)
	var changed := _entries.size() != entries.size() or active != _active_index(_entries)
	_entries = entries
	_expanded = expanded
	_collapsible = collapsible
	if changed:
		_peek = maxi(active, 0)
	_peek = clampi(_peek, 0, maxi(_entries.size() - 1, 0))
	_toggle.tooltip_text = tr("ui.cockpit.order.toggle")
	_toggle.visible = collapsible
	_ensure_visible(active)
	custom_minimum_size = size_for(expanded)
	_arrange()
	queue_redraw()


func entries() -> Array:
	return _entries


func is_expanded() -> bool:
	return _expanded


func size_for(expanded: bool) -> Vector2:
	return Vector2(0.0, FULL_HEIGHT) if expanded else CHIP_SIZE


## Anzahl der Slots, die bei der aktuellen Breite nebeneinander passen.
func visible_slots() -> int:
	return maxi(1, floori((size.x - 2.0 * EDGE) / SLOT_PITCH_MIN))


static func _active_index(entries: Array) -> int:
	for i: int in entries.size():
		if str((entries[i] as Dictionary)["state"]) == "active":
			return i
	return -1


func _ensure_visible(active: int) -> void:
	var count := visible_slots()
	var target := active if active >= 0 else _first
	if target < _first or target >= _first + count:
		_first = target - floori(count / 2.0)
	_first = clampi(_first, 0, maxi(_entries.size() - count, 0))


func _step(direction: int) -> void:
	if _expanded:
		_first = clampi(_first + direction, 0, maxi(_entries.size() - visible_slots(), 0))
	else:
		_peek = clampi(_peek + direction, 0, maxi(_entries.size() - 1, 0))
	_arrange()
	queue_redraw()


func _on_toggle() -> void:
	expand_toggled.emit(not _expanded)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_ensure_visible(_active_index(_entries))
		_arrange()
		queue_redraw()
	elif what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


## Pfeile und Umschalter an ihre Plätze; Pfeile nur, wenn geblättert werden kann.
func _arrange() -> void:
	if _left == null:
		return
	var more := (_entries.size() > visible_slots()) if _expanded else (_entries.size() > 1)
	_left.visible = more
	_right.visible = more
	_left.disabled = (_first <= 0) if _expanded else (_peek <= 0)
	_right.disabled = (_first >= _entries.size() - visible_slots()) if _expanded else (_peek >= _entries.size() - 1)
	var arrow := Vector2(ARROW_SIZE, ARROW_SIZE + 20.0)
	var y := (size.y - arrow.y) * 0.5 - (6.0 if _expanded else 0.0)
	_left.position = Vector2(8.0, y)
	_left.size = arrow
	_right.position = Vector2(size.x - arrow.x - 8.0, y)
	_right.size = arrow
	_toggle.size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	_toggle.position = Vector2((size.x - _toggle.size.x) * 0.5, size.y - _toggle.size.y + (8.0 if _expanded else 2.0))


# --- Zeichnen -----------------------------------------------------------------------------------------

func _draw() -> void:
	var frame := NightArt.texture("ui/bar-frame.png")
	if frame != null:
		var box := StyleBoxTexture.new()
		box.texture = frame
		box.texture_margin_left = FRAME_MARGIN.x
		box.texture_margin_right = FRAME_MARGIN.x
		box.texture_margin_top = FRAME_MARGIN.y
		box.texture_margin_bottom = FRAME_MARGIN.y
		draw_style_box(box, Rect2(Vector2.ZERO, size))
	if _entries.is_empty():
		return
	if _expanded:
		_draw_slots()
	else:
		_draw_chip()
	_draw_chevron()


func _label_of(role_id: String) -> String:
	return tr(CockpitText.role_name(role_id))


func _draw_slots() -> void:
	var font := get_theme_default_font()
	var count := visible_slots()
	var pitch := (size.x - 2.0 * EDGE) / float(count)
	for k: int in mini(count, _entries.size() - _first):
		var i := _first + k
		var entry: Dictionary = _entries[i]
		var state := str(entry["state"])
		var sx := EDGE + pitch * (float(k) + 0.5)
		var top := 6.0
		var symbol := NightArt.role_symbol(str(entry["role_id"]))
		var tint := ThemeTokens.TINT_ART_DONE if state == "done" else ThemeTokens.TINT_ART_OPEN
		if symbol != null:
			draw_texture_rect(symbol, Rect2(sx - SYMBOL_SIZE * 0.5, top + SLOT_HEIGHT * 0.57 - SYMBOL_SIZE * 0.5, SYMBOL_SIZE, SYMBOL_SIZE), false, tint)
		var slot := NightArt.texture("ui/slot-%s.png" % ("inactive" if state == "upcoming" else state))
		if slot != null:
			var w := SLOT_HEIGHT * float(slot.get_width()) / float(slot.get_height())
			draw_texture_rect(slot, Rect2(sx - w * 0.5, top, w, SLOT_HEIGHT), false)
		var number := str(i + 1)
		var nw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
		draw_string(font, Vector2(sx - nw * 0.5, top + SLOT_HEIGHT * 0.06 + NUMBER_SIZE), number, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, ThemeTokens.TEXT_PRIMARY)
		var color := ThemeTokens.DANGER_TEXT if state == "active" else (ThemeTokens.TEXT_DISABLED if state == "done" else ThemeTokens.TEXT_MUTED)
		_draw_fitted(font, _label_of(str(entry["role_id"])), Vector2(sx, top + SLOT_HEIGHT + 12.0), pitch - 6.0, LABEL_SIZE, color)


func _draw_chip() -> void:
	var font := get_theme_default_font()
	var entry: Dictionary = _entries[clampi(_peek, 0, _entries.size() - 1)]
	var symbol := NightArt.role_symbol(str(entry["role_id"]))
	if symbol != null:
		draw_texture_rect(symbol, Rect2(52.0, (size.y - SYMBOL_SIZE) * 0.5 - 2.0, SYMBOL_SIZE - 4.0, SYMBOL_SIZE - 4.0), false)
	var text := "%d · %s" % [_peek + 1, _label_of(str(entry["role_id"]))]
	var state := str(entry["state"])
	var color := ThemeTokens.DANGER_TEXT if state == "active" else ThemeTokens.TEXT_MUTED
	_draw_fitted(font, text, Vector2(94.0 + (size.x - 94.0 - 52.0) * 0.5, size.y * 0.5 + CHIP_FONT_SIZE * 0.35), size.x - 94.0 - 52.0, CHIP_FONT_SIZE, color)


## Text mittig bei `centre` (Grundlinie), bei Bedarf mit Auslassungspunkten gekürzt.
func _draw_fitted(font: Font, text: String, centre: Vector2, limit: float, font_size: int, color: Color) -> void:
	while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit and text.length() > 3:
		text = text.trim_suffix("…")
		text = text.left(text.length() - 1) + "…"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(centre.x - w * 0.5, centre.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_chevron() -> void:
	if not _collapsible:
		return
	var c := Vector2(size.x * 0.5, size.y - 10.0)
	var pts := PackedVector2Array([c + Vector2(-8.0, -3.0), c + Vector2(8.0, -3.0), c + Vector2(0.0, 5.0)])
	if _expanded:
		pts = PackedVector2Array([c + Vector2(-8.0, 5.0), c + Vector2(8.0, 5.0), c + Vector2(0.0, -3.0)])
	draw_colored_polygon(pts, ThemeTokens.GOLD)
