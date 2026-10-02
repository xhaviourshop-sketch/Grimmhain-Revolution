class_name NightOrderBar
extends Control
## Nachtreihenfolge-Leiste oben: Hain-Teil `night_bar` als Rahmen (Enden und Mittelspange geschützt), je Rolle ein `role_medallion`
## (Silberring mit Wurzeln) mit Rollensymbol, Nummer und Name. Aktiv: blutroter Ring plus Raute am Ring (nicht nur Farbe); erledigt:
## gedämpft mit Haken; offen: Silber. Die Medaillons stehen links und rechts der Mittelspange. Passt nicht alles in die Breite, blättern
## zwei Pfeile. Einklappbar: als Chip zeigt sie nur die aktive Rolle (auf 4:3 Standard, Entscheidung Abnahme 1).
## Reine Darstellung: Die Einträge kommen aus `GameSession.night_order()` (geheim, die Ansicht blendet die Leiste bei „Verbergen“
## aus). Namen immer aus der Übersetzung, nie aus Bildern.

signal expand_toggled(expanded: bool)

const FULL_HEIGHT := 70.0
const CHIP_SIZE := Vector2(400.0, 52.0)
const MEDALLION := 44.0  ## Durchmesser des Rollenrings in der vollen Leiste
const CHIP_MEDALLION := 44.0
const BAR_Y_CENTER := 26.0  ## Mitte der vollen Leiste (und der Medaillons) von oben
const SLOT_PITCH_MIN := 62.0
const SLOT_PITCH_MAX := 76.0
const CLASP_GAP := 14.0  ## Luft links und rechts der Mittelspange
const LABEL_SIZE := 11
const LABEL_PLATE_HEIGHT := 18.0  ## Namensschild unter dem Medaillon (Teil `name_plate_short`)
const LABEL_PLATE_PAD := 5.0
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
	_left = _arrow("ArrowLeftButton", "arrow_left", -1)
	_right = _arrow("ArrowRightButton", "arrow_right", 1)
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
	b.texture_normal = GroveSkin.texture(art)
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


## Breite einer Hälfte (links oder rechts der Mittelspange), in der Medaillons stehen können.
func _half_room() -> float:
	var ends := minf(GroveArtData.NIGHT_BAR_MARGINS.x, GroveArtData.NIGHT_BAR_MARGINS.z) / GroveArtData.TEXTURE_SCALE
	return size.x * 0.5 - _clasp_width() * 0.5 - CLASP_GAP - ends - ARROW_SIZE - 16.0


func _clasp_width() -> float:
	return GroveArtData.NIGHT_BAR_CLASP.y / GroveArtData.TEXTURE_SCALE


## Anzahl der Slots, die bei der aktuellen Breite nebeneinander passen (gleich viele links und rechts der Spange).
func visible_slots() -> int:
	return maxi(1, 2 * floori(_half_room() / SLOT_PITCH_MIN))


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
	var y := (BAR_Y_CENTER if _expanded else size.y * 0.5) - arrow.y * 0.5
	var margins := GroveArtData.NIGHT_BAR_MARGINS / GroveArtData.TEXTURE_SCALE
	_left.position = Vector2(margins.x + 2.0, y)
	_left.size = arrow
	_right.position = Vector2(size.x - margins.z - arrow.x - 2.0, y)
	_right.size = arrow
	_toggle.size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	var toggle_y := (BAR_Y_CENTER + 8.0) if _expanded else (size.y - _toggle.size.y + 4.0)
	_toggle.position = Vector2((size.x - _toggle.size.x) * 0.5, toggle_y)


# --- Zeichnen -----------------------------------------------------------------------------------------

func _draw() -> void:
	var box := GroveSkin.night_bar_box(_expanded)
	if box != null:
		var bar_h := float(box.texture.get_height()) / GroveArtData.TEXTURE_SCALE
		var centre_y := BAR_Y_CENTER if _expanded else size.y * 0.5
		draw_style_box(box, Rect2(0.0, centre_y - bar_h * 0.5, size.x, bar_h))
	if _entries.is_empty():
		return
	if _expanded:
		_draw_slots()
	else:
		_draw_chip()
	_draw_chevron()


func _label_of(role_id: String) -> String:
	return tr(CockpitText.role_name(role_id))


## Rollenring an `centre` mit Durchmesser `diameter`: dunkler Grund, Rollensymbol im Innenraum, dann der Silberring darüber.
## Aktiv: blutroter Ring, roter Halo und eine Raute unten am Ring. Erledigt: gedämpft und mit Haken.
func _draw_medallion(centre: Vector2, diameter: float, entry: Dictionary) -> void:
	var state := str(entry["state"])
	var ring := GroveSkin.texture("role_medallion")
	var hole_radius := GroveArtData.ROLE_MEDALLION_HOLE_RADIUS * diameter
	var ring_size := Vector2(diameter, diameter * GroveArtData.ROLE_MEDALLION_ASPECT)
	var ring_origin := centre - GroveArtData.ROLE_MEDALLION_HOLE_CENTER * ring_size
	draw_circle(centre, hole_radius + 1.0, ThemeTokens.NUMBER_BG)
	var symbol := NightArt.role_symbol(str(entry["role_id"]))
	if symbol != null:
		var side := hole_radius * 2.0
		draw_texture_rect(symbol, Rect2(centre - Vector2(side, side) * 0.5, Vector2(side, side)), false, ThemeTokens.TINT_RING_DONE if state == "done" else ThemeTokens.TINT_NONE)
	if state == "active":
		draw_arc(centre, diameter * 0.5 + 2.0, 0.0, TAU, 48, ThemeTokens.BLOOD_RED_HALO, 4.0, true)
	if ring != null:
		draw_texture_rect(ring, Rect2(ring_origin, ring_size), false, ThemeTokens.TINT_RING_ACTIVE if state == "active" else (ThemeTokens.TINT_RING_DONE if state == "done" else ThemeTokens.TINT_NONE))
	var foot := centre + Vector2(0.0, diameter * 0.5 - 1.0)
	if state == "active":
		var gem := PackedVector2Array([foot + Vector2(0.0, -6.0), foot + Vector2(6.0, 0.0), foot + Vector2(0.0, 6.0), foot + Vector2(-6.0, 0.0)])
		draw_colored_polygon(gem, ThemeTokens.BLOOD_RED)
		gem.append(gem[0])
		draw_polyline(gem, ThemeTokens.MOON_SILVER_BRIGHT, 1.2, true)
	elif state == "done":
		draw_circle(foot, 6.5, ThemeTokens.NUMBER_BG)
		draw_polyline(PackedVector2Array([foot + Vector2(-3.2, 0.2), foot + Vector2(-0.8, 2.6), foot + Vector2(3.4, -2.4)]), ThemeTokens.MOON_SILVER, 1.8, true)


## Abstand der Medaillon-Mitten: so groß wie möglich, höchstens `SLOT_PITCH_MAX`.
func _pitch(shown: int) -> float:
	return minf(SLOT_PITCH_MAX, _half_room() / float(maxi(ceili(shown / 2.0), 1)))


## Mittelpunkt des k-ten angezeigten Medaillons von `shown`: links der Spange `ceil(shown / 2)`, rechts der Rest, jeweils zur Spange hin.
func _slot_centre_x(k: int, shown: int) -> float:
	var left_count := ceili(shown / 2.0)
	var gap := _clasp_width() * 0.5 + CLASP_GAP
	var pitch := _pitch(shown)
	var mid := size.x * 0.5
	if k < left_count:
		return mid - gap - pitch * (float(left_count - k) - 0.5)
	return mid + gap + pitch * (float(k - left_count) + 0.5)


func _draw_slots() -> void:
	var font := get_theme_default_font()
	var shown := mini(visible_slots(), _entries.size() - _first)
	var badge_y := BAR_Y_CENTER - MEDALLION * 0.5 + 6.0
	for k: int in shown:
		var i := _first + k
		var entry: Dictionary = _entries[i]
		var state := str(entry["state"])
		var sx := _slot_centre_x(k, shown)
		_draw_medallion(Vector2(sx, BAR_Y_CENTER), MEDALLION, entry)
		var number := str(i + 1)
		var badge_x := sx - MEDALLION * 0.5 + 4.0
		var nw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
		draw_circle(Vector2(badge_x, badge_y), 8.0, ThemeTokens.NUMBER_BG)
		draw_string(font, Vector2(badge_x - nw * 0.5, badge_y + NUMBER_SIZE * 0.35), number, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, ThemeTokens.TEXT_PRIMARY)
		var color := ThemeTokens.DANGER_TEXT if state == "active" else (ThemeTokens.TEXT_DISABLED if state == "done" else ThemeTokens.TEXT_MUTED)
		_draw_label_plate(font, _label_of(str(entry["role_id"])), Vector2(sx, BAR_Y_CENTER + MEDALLION * 0.5 + 13.0), _pitch(shown) + 4.0, color)


## Name unter dem Medaillon auf einem schmalen dunklen Schild (gleiches Teil wie die Namensschilder der Plätze), damit er auf dem Pflaster lesbar bleibt.
func _draw_label_plate(font: Font, text: String, centre: Vector2, limit: float, color: Color) -> void:
	var box := GroveSkin.plate_box()
	var text_limit := limit - LABEL_PLATE_PAD * 2.0
	while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x > text_limit and text.length() > 3:
		text = text.trim_suffix("…")
		text = text.left(text.length() - 1) + "…"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var plate_w := w + LABEL_PLATE_PAD * 2.0
	if box != null:
		box.native_height = LABEL_PLATE_HEIGHT
		draw_style_box(box, Rect2(centre.x - plate_w * 0.5, centre.y - LABEL_PLATE_HEIGHT * 0.5 - 3.0, plate_w, LABEL_PLATE_HEIGHT))
	else:
		draw_rect(Rect2(centre.x - plate_w * 0.5, centre.y - LABEL_PLATE_HEIGHT * 0.5 - 3.0, plate_w, LABEL_PLATE_HEIGHT), ThemeTokens.PLATE_BG)
	draw_string(font, Vector2(centre.x - w * 0.5, centre.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, color)


func _draw_chip() -> void:
	var font := get_theme_default_font()
	var entry: Dictionary = _entries[clampi(_peek, 0, _entries.size() - 1)]
	var margins := GroveArtData.NIGHT_BAR_MARGINS / GroveArtData.TEXTURE_SCALE
	var left := margins.x + ARROW_SIZE + 16.0
	var right := size.x - margins.z - ARROW_SIZE - 8.0
	_draw_medallion(Vector2(left + CHIP_MEDALLION * 0.5, size.y * 0.5), CHIP_MEDALLION, entry)
	var text := "%d · %s" % [_peek + 1, _label_of(str(entry["role_id"]))]
	var color := ThemeTokens.DANGER_TEXT if str(entry["state"]) == "active" else ThemeTokens.TEXT_MUTED
	var from := left + CHIP_MEDALLION + 8.0
	_draw_fitted(font, text, Vector2((from + right) * 0.5, size.y * 0.5 + CHIP_FONT_SIZE * 0.35), right - from, CHIP_FONT_SIZE, color)


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
	var c := Vector2(size.x * 0.5, (BAR_Y_CENTER + 33.0) if _expanded else (size.y - 8.0))
	var pts := PackedVector2Array([c + Vector2(-8.0, -3.0), c + Vector2(8.0, -3.0), c + Vector2(0.0, 5.0)])
	if _expanded:
		pts = PackedVector2Array([c + Vector2(-8.0, 5.0), c + Vector2(8.0, 5.0), c + Vector2(0.0, -3.0)])
	draw_colored_polygon(pts, ThemeTokens.MOON_SILVER)
