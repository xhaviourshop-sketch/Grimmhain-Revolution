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
const FACE_OVERLAP := 1.04  ## das Porträt reicht etwas unter den Ring, damit kein Spalt bleibt
const RING_RADIUS := PortraitRingLayout.RING_RADIUS  ## Anteil der Rahmenbreite bis zum äußeren Rand des Rings (Tippfläche, Fokus, Zustandsschein)
const FACE_UV_SCALE := 0.62
const PLATE_FONT_SIZE := 13
const PLATE_FONT_SIZE_TIGHT := 11
const PLATE_PADDING := 8.0  ## Innenabstand im Namensschild (links und rechts zusammen, ohne die Eisenkappen)
const NUMBER_FONT_SIZE := 9
const PLATE_FONT_SIZE_MIN := 10
const RING_OVERLAY_SCALE := 0.95  ## Kantenlänge der Statusring-Bilder relativ zur Rahmenbreite
const GLOW_ACTIVE := Color(0.78, 0.08, 0.1)  ## blutroter Schein am Ring der handelnden Person
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
		material = _dead_material() if value == &"dead" else null
		_show()
		queue_redraw()


static var _desaturate: ShaderMaterial = null


## Gemeinsames Material für tote Plätze (entsättigt, leicht abgedunkelt).
static func _dead_material() -> ShaderMaterial:
	if _desaturate == null:
		_desaturate = ShaderMaterial.new()
		_desaturate.shader = load("res://app/theme/grove_desaturate.gdshader") as Shader
	return _desaturate


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
	return Rect2(portrait_center() - Vector2.ONE * diameter * RING_RADIUS, Vector2.ONE * diameter * RING_RADIUS * 2.0)  # der sichtbare Ring, nicht das Bildrechteck


func plate_rect() -> Rect2:
	var limit := plate_limit if plate_limit > 0.0 else PortraitRingLayout.plate_max_width(diameter)
	var w := minf(minf(size.x, limit), _plate_text_width() + 2.0 * _plate_cap() + PLATE_PADDING)
	return Rect2((size.x - w) * 0.5, PortraitRingLayout.NUMBER_BAND + diameter - PortraitRingLayout.PLATE_DROP, w, PortraitRingLayout.PLATE_HEIGHT)


## Tippen zählt nur auf dem Porträtkreis und dem Schild; die Steuerelemente überlappen diagonal, die Tippflächen nicht.
func _has_point(point: Vector2) -> bool:
	return point.distance_to(portrait_center()) <= diameter * RING_RADIUS + 2.0 or plate_rect().grow(2.0).has_point(point)


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
	if alive and disabled:
		dim = ThemeTokens.TINT_DISABLED  # tote Plätze entsättigt das Material (siehe `state`)
	if state == &"actor":
		_draw_glow(c, d, GLOW_ACTIVE)
	_draw_portrait(c, d, dim)
	var frame_rect := _frame_rect(c, d)
	var socket := frame_rect.position + GroveArtData.SEAT_SOCKET_CENTER * frame_rect.size
	draw_circle(socket, GroveArtData.SEAT_SOCKET_RADIUS * d * 1.05, ThemeTokens.NUMBER_BG)
	var frame := GroveSkin.texture("seat_frame")
	if frame != null:
		var silver := GroveSkin.TINT_SEAT_SILVER * dim
		if state == &"actor":
			silver = Color(silver.r, silver.g * 0.78, silver.b * 0.78)
		draw_texture_rect(frame, frame_rect, false, silver)
	_draw_state_ring(c, d)
	_draw_number(socket, d)
	_draw_badges(c, d)
	_draw_plate()
	if has_focus():
		draw_arc(c, d * RING_RADIUS + 3.0, 0.0, TAU, 48, ThemeTokens.FOCUS_RING, float(ThemeTokens.FOCUS_WIDTH), true)


## Rechteck des Rahmenbilds so, dass das Porträtfenster des Rings auf der Porträtmitte liegt.
func _frame_rect(c: Vector2, d: float) -> Rect2:
	var frame_size := Vector2(d, d * GroveArtData.SEAT_ASPECT)
	return Rect2(c - GroveArtData.SEAT_HOLE_CENTER * frame_size, frame_size)


func _plate_cap() -> float:
	return GroveArtData.NAME_PLATE_SHORT_MARGINS.x / GroveArtData.TEXTURE_SCALE


## Weicher Schein um den Ring: mehrere dünne Bögen mit abnehmender Deckkraft.
func _draw_glow(c: Vector2, d: float, color: Color) -> void:
	for i: int in 6:
		var alpha := 0.55 - 0.09 * float(i)
		draw_arc(c, d * RING_RADIUS + 1.0 + 2.0 * float(i), 0.0, TAU, 56, Color(color.r, color.g, color.b, alpha), 2.6, true)


func _draw_portrait(c: Vector2, d: float, tint: Color) -> void:
	var radius := d * GroveArtData.SEAT_HOLE_RADIUS * FACE_OVERLAP
	if _portrait == null:
		draw_circle(c, radius, ThemeTokens.BG_SURFACE)
		return
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i: int in 48:
		var a := TAU * float(i) / 48.0
		points.append(c + Vector2(cos(a), sin(a)) * radius)
		uvs.append(Vector2(0.5 + 0.5 * cos(a) * FACE_UV_SCALE, 0.5 + 0.5 * sin(a) * FACE_UV_SCALE))
	draw_colored_polygon(points, tint, uvs, _portrait)


## Zustand der Bedienung (gewählt, wählbar, tot) und geheimer Statusring über dem Porträt; die handelnde Person trägt den roten Schein.
func _draw_state_ring(c: Vector2, d: float) -> void:
	var overlay := ""
	match state:
		&"selected":
			overlay = "selected"
		&"dead":
			overlay = "dead"
		&"allowed":
			draw_arc(c, d * RING_RADIUS + 2.0, 0.0, TAU, 48, ThemeTokens.GOLD_BRIGHT, 3.0, true)
		&"actor":
			pass
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
		var side := d * RING_OVERLAY_SCALE
		draw_texture_rect(texture, Rect2(c - Vector2.ONE * side * 0.5, Vector2.ONE * side), false)


func _draw_number(socket: Vector2, d: float) -> void:
	var text := str(int(_seat["seat"]))
	var font := _plate_font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE).x
	draw_string(font, Vector2(socket.x - w * 0.5, socket.y + NUMBER_FONT_SIZE * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, ThemeTokens.TEXT_PRIMARY)


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
	var box := GroveSkin.plate_box()
	if box != null:
		draw_style_box(box, rect)
	else:
		var pill := StyleBoxFlat.new()
		pill.bg_color = ThemeTokens.PLATE_BG
		pill.set_corner_radius_all(9)
		draw_style_box(pill, rect)
	var text := _plate_text()
	var font := _plate_font()
	var limit := rect.size.x - 2.0 * _plate_cap() - PLATE_PADDING
	var font_size := PLATE_FONT_SIZE
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit:
		font_size = PLATE_FONT_SIZE_TIGHT  # enge Plätze am Rand der Ellipse: erst kleiner schreiben, dann kürzen
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit:
		font_size = PLATE_FONT_SIZE_MIN
	while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit and text.length() > 3:
		text = text.trim_suffix("…")
		text = text.left(text.length() - 1) + "…"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var color := ThemeTokens.TEXT_MUTED if not alive else ThemeTokens.TEXT_PRIMARY
	draw_string(font, Vector2(rect.position.x + (rect.size.x - w) * 0.5, rect.position.y + (rect.size.y + float(font_size) * 0.72) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()
