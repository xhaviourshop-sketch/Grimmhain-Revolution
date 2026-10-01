class_name GameSeatToken
extends GrimmButton
## Ein Platz im Cockpit-Sitzkreis als Porträtplatz (P3): rundes Porträt im Rahmen, Nummern-Abzeichen oben, Namensschild unten,
## Zustände als Ring über dem Porträt, kleine Zustandsabzeichen unten rechts. Zeigt nie eine Rolle. Bleibt ein Button
## mit Personen-ID und Signal `tapped`; der Button-Text (Nummer, Name, Zeichen) dient der Bedienungshilfe, den Tests und dem
## Tooltip und wird nicht gezeichnet. Information hängt nie allein an der Farbe: Das Schild trägt Tod („†“), Nominierung
## („(N)“), wählbares Ziel („›“), Auswahl („✓“) und handelnde Person („•“); die Abzeichen unterscheiden sich durch Form.
##
## Geheime Zustände (`marks`, handelnde Person) zeichnet der Platz nur, solange `secrets_visible` gilt („Verbergen“ schaltet es ab).

signal tapped(person_id: int)

## Theme-Variationen je Zustand bleiben die Kennung des Zustands (Tests, Fokus); gezeichnet wird in `_draw`.
const STATE_VARIATIONS := {
	&"normal": &"SeatButton",
	&"dead": &"SeatDeadButton",
	&"allowed": &"SeatTargetButton",
	&"selected": &"SeatSelectedButton",
	&"actor": &"SeatActorButton",
}
const STATE_MARKS := {&"allowed": "› ", &"selected": "✓ ", &"actor": "• "}
const FACE_RADIUS := 0.36  ## Anteil des Durchmessers, den das Porträtfenster im Rahmen füllt
const FACE_UV_SCALE := 0.62
const PLATE_FONT_SIZE := 13
const PLATE_FONT_SIZE_TIGHT := 11
const PLATE_PADDING := 8.0  ## Innenabstand im Namensschild (links und rechts zusammen)
const NUMBER_FONT_SIZE := 11
const RING_PRIORITY: Array[String] = ["marked", "poisoned", "silenced", "protected"]
const _STYLE_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const _FONT_COLORS: Array[String] = ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]

var person_id: int = 0
var alive: bool = true
var diameter: float = 66.0:
	set(value):
		diameter = value
		queue_redraw()
var plate_limit: float = 0.0:  ## größte Schildbreite (0 = nur die Obergrenze des Layouts); der Ring setzt sie je Platz
	set(value):
		plate_limit = value
		queue_redraw()
var secrets_visible: bool = true:
	set(value):
		secrets_visible = value
		queue_redraw()
var marks: Array = []:  ## Zustandsabzeichen (Arten aus NightBoardView.KINDS), nur gezeichnet bei `secrets_visible`
	set(value):
		marks = value
		queue_redraw()
var _nominated: bool = false
var _seat: Dictionary = {}
var _portrait: Texture2D = null
var state: StringName = &"normal":
	set(value):
		state = value
		theme_type_variation = STATE_VARIATIONS.get(value, &"SeatButton")
		_show()
		queue_redraw()


func setup(p_person_id: int) -> void:
	person_id = p_person_id
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	# Der Button zeichnet selbst nichts: Rahmen, Porträt und Schild entstehen in `_draw`.
	for style: String in _STYLE_STATES:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in _FONT_COLORS:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)
	_portrait = NightArt.portrait(p_person_id)
	pressed.connect(func() -> void: tapped.emit(person_id))
	state = &"normal"


## Eigenes Porträt statt der automatischen Zuordnung (spätere Auswahl durch die Spielleitung, nie ein Rollenbild).
func set_portrait(texture: Texture2D) -> void:
	_portrait = texture if texture != null else NightArt.portrait(person_id)
	queue_redraw()


func portrait_texture() -> Texture2D:
	return _portrait


## Öffentliche Sitzdaten: {seat, name, alive, nominated_today}.
func show_seat(seat: Dictionary) -> void:
	alive = bool(seat.get("alive", true))
	_nominated = bool(seat.get("nominated_today", false))
	_seat = seat
	tooltip_text = str(seat["name"])
	_show()
	queue_redraw()


func _show() -> void:
	if _seat.is_empty():
		return
	format_values = {"mark": STATE_MARKS.get(state, ""), "number": int(_seat["seat"]), "name": str(_seat["name"])}
	var key := "ui.cockpit.seat.alive"
	if not alive:
		key = "ui.cockpit.seat.dead"
	elif _nominated:
		key = "ui.cockpit.seat.nominated"
	text_key = key


# --- Geometrie ----------------------------------------------------------------------------------------

## Mittelpunkt, Porträtkreis und Schild im Koordinatensystem des Steuerelements.
func portrait_center() -> Vector2:
	return PortraitRingLayout.portrait_center(diameter)


func portrait_rect() -> Rect2:
	return Rect2(portrait_center() - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter)


func plate_rect() -> Rect2:
	var limit := plate_limit if plate_limit > 0.0 else PortraitRingLayout.plate_max_width(diameter)
	var w := minf(minf(size.x, limit), _plate_text_width() + 14.0)
	return Rect2((size.x - w) * 0.5, PortraitRingLayout.NUMBER_BAND + diameter - PortraitRingLayout.PLATE_DROP, w, PortraitRingLayout.PLATE_HEIGHT)


## Tippen zählt nur auf dem Porträtkreis und dem Schild; die Steuerelemente überlappen diagonal, die Tippflächen nicht.
func _has_point(point: Vector2) -> bool:
	return point.distance_to(portrait_center()) <= diameter * 0.5 + 4.0 or plate_rect().grow(2.0).has_point(point)


# --- Zeichnen -----------------------------------------------------------------------------------------

func _plate_text() -> String:
	if _seat.is_empty():
		return ""
	var key := "ui.cockpit.seat.plate.alive"
	if not alive:
		key = "ui.cockpit.seat.plate.dead"
	elif _nominated:
		key = "ui.cockpit.seat.plate.nominated"
	return tr(key).format({"mark": STATE_MARKS.get(state, ""), "name": str(_seat["name"])})


func _plate_font() -> Font:
	return get_theme_default_font()


func _plate_text_width() -> float:
	return _plate_font().get_string_size(_plate_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE).x


func _draw() -> void:
	if _seat.is_empty():
		return
	var c := portrait_center()
	var d := diameter
	var dim := ThemeTokens.TINT_NONE
	if not alive:
		dim = ThemeTokens.TINT_DEAD
	elif disabled:
		dim = ThemeTokens.TINT_DISABLED
	_draw_portrait(c, d, dim)
	var frame := NightArt.texture("frames/seat-frame.png")
	var box := Rect2(c - Vector2.ONE * d * 0.5, Vector2.ONE * d)
	if frame != null:
		draw_texture_rect(frame, box, false, dim)
	_draw_state_ring(c, d, box)
	_draw_number(c, d)
	_draw_badges(c, d)
	_draw_plate()
	if has_focus():
		draw_arc(c, d * 0.5 + 3.0, 0.0, TAU, 48, ThemeTokens.FOCUS_RING, float(ThemeTokens.FOCUS_WIDTH), true)


func _draw_portrait(c: Vector2, d: float, tint: Color) -> void:
	if _portrait == null:
		draw_circle(c, d * FACE_RADIUS, ThemeTokens.BG_SURFACE)
		return
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i: int in 48:
		var a := TAU * float(i) / 48.0
		points.append(c + Vector2(cos(a), sin(a)) * d * FACE_RADIUS)
		uvs.append(Vector2(0.5 + 0.5 * cos(a) * FACE_UV_SCALE, 0.5 + 0.5 * sin(a) * FACE_UV_SCALE))
	draw_colored_polygon(points, tint, uvs, _portrait)


## Ring über dem Porträt: Zustand der Bedienung (handelnd, gewählt, wählbar, tot) vor dem geheimen Statusring.
func _draw_state_ring(c: Vector2, d: float, box: Rect2) -> void:
	var overlay := ""
	match state:
		&"actor":
			overlay = "active"
		&"selected":
			overlay = "selected"
		&"dead":
			overlay = "dead"
		&"allowed":
			draw_arc(c, d * 0.46, 0.0, TAU, 48, ThemeTokens.GOLD_BRIGHT, 3.0, true)
		_:
			if secrets_visible and not marks.is_empty():
				for kind: String in RING_PRIORITY:
					if marks.has(kind):
						overlay = kind
						break
	if overlay == "":
		return
	var texture := NightArt.ring(overlay)
	if texture != null:
		draw_texture_rect(texture, box, false)


func _draw_number(c: Vector2, d: float) -> void:
	var centre := Vector2(c.x, c.y - d * 0.5 + 3.0)
	draw_circle(centre, 9.0, ThemeTokens.NUMBER_BG)
	draw_arc(centre, 9.0, 0.0, TAU, 20, ThemeTokens.GOLD_DEEP, 1.2, true)
	var text := str(int(_seat["seat"]))
	var font := _plate_font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE).x
	draw_string(font, Vector2(centre.x - w * 0.5, centre.y + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, ThemeTokens.TEXT_PRIMARY)


func _draw_badges(c: Vector2, d: float) -> void:
	if not secrets_visible or marks.is_empty() or not alive:
		return
	var size_px := maxf(ThemeTokens.BADGE_MIN, d * 0.37)
	var i := 0
	for kind: Variant in marks:
		var texture := NightArt.badge(str(kind))
		if texture != null:
			draw_texture_rect(texture, Rect2(c.x + d * 0.5 - size_px * 0.85 - float(i) * size_px * 0.7, c.y + d * 0.5 - size_px * 0.85, size_px, size_px), false)
		i += 1


func _draw_plate() -> void:
	var rect := plate_rect()
	var pill := StyleBoxFlat.new()
	pill.bg_color = ThemeTokens.PLATE_BG
	pill.set_corner_radius_all(9)
	draw_style_box(pill, rect)
	var text := _plate_text()
	var font := _plate_font()
	var limit := rect.size.x - PLATE_PADDING
	var font_size := PLATE_FONT_SIZE
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit:
		font_size = PLATE_FONT_SIZE_TIGHT  # enge Plätze am Rand der Ellipse: erst kleiner schreiben, dann kürzen
	while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit and text.length() > 3:
		text = text.trim_suffix("…")
		text = text.left(text.length() - 1) + "…"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var color := ThemeTokens.TEXT_MUTED if not alive else ThemeTokens.TEXT_PRIMARY
	draw_string(font, Vector2(rect.position.x + (rect.size.x - w) * 0.5, rect.position.y + font_size + 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()
