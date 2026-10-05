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
## Zeichen im Text des Buttons (Bedienungshilfe, Tests). Auf dem Schild steht nur das Zeichen der handelnden Person: Wählbarkeit und
## Auswahl zeigen der Ring (Schimmer, Schein) und das Häkchen; die Namen bleiben so lang wie möglich.
const STATE_MARKS := {&"allowed": "› ", &"selected": "✓ ", &"actor": "• "}
const PLATE_MARKS := {&"actor": "• "}
const GLOW_SELECTED := ThemeTokens.MOON_GLOW  ## heller Mondsilber-Schein um das gewählte Ziel
const SHIMMER_ALLOWED := ThemeTokens.SEAT_SHIMMER  ## dezenter, kühler Schimmer wählbarer Plätze (ruhig, kein Pulsieren)
const FACE_OVERLAP := 1.04  ## das Porträt reicht etwas unter den Ring, damit kein Spalt bleibt
const RING_RADIUS := PortraitRingLayout.RING_RADIUS  ## Anteil der Rahmenbreite bis zum äußeren Rand des Rings (Tippfläche, Fokus, Zustandsschein)
const FACE_UV_SCALE := 0.62
const PLATE_FONT_SIZE := 13
const PLATE_PADDING := 6.0  ## Innenabstand im Namensschild (links und rechts zusammen, ohne die Eisenkappen)
const NUMBER_FONT_SIZE := 9
const PLATE_FONT_SIZE_MIN := 10
const RING_OVERLAY_SCALE := 0.95  ## Kantenlänge der Statusring-Bilder relativ zur Rahmenbreite
const GLOW_ACTIVE := ThemeTokens.BLOOD_GLOW  ## blutroter Schein am Ring der handelnden Person
const HUNT_PULSE_SPEED := 3.4  ## Pulse je Sekunde im Bogenmaß
const ACTIVE_PULSE_SPEED := 2.1  ## langsames Auf und Ab der aktiven Person (rund drei Sekunden je Zug)
const HUNT_ARCS := 10  ## Bögen des Feuerscheins um den Ring
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
var plate_span: Vector2 = Vector2.ZERO:  ## (links, rechts): so weit darf das Schild von der Mitte aus wachsen; Null = symmetrisch bis `plate_limit`
	set(value):
		plate_span = value
		queue_redraw()
var secrets_visible: bool = true:
	set(value):
		secrets_visible = value
		queue_redraw()
var marks: Array = []:  ## Zustandsabzeichen (Arten aus NightBoardView.KINDS), nur gezeichnet bei `secrets_visible`
	set(value):
		marks = value
		queue_redraw()
var chosen: bool = false:  ## Platz, dem gerade eine Rolle zugeordnet wird: roter Schein wie bei der handelnden Person
	set(value):
		chosen = value
		queue_redraw()
var locked: bool = false:  ## Nominierung: für diese Eingabe gesperrt, stark abgedunkelt mit kleinem Silber-Schloss
	set(value):
		locked = value
		queue_redraw()
var hunt: bool = false:  ## Werwolf-Phase und König Lykaon: starker, pulsierender Feuerring um die gezeigten Wölfe (nur bei `secrets_visible`)
	set(value):
		hunt = value
		_apply_hunt_motion()
		queue_redraw()
var hunt_animated: bool = true:  ## aus bei reduzierter Bewegung: der Ring steht still
	set(value):
		hunt_animated = value
		_apply_hunt_motion()
		queue_redraw()
var active: bool = false:  ## handelnde Person: Bildrahmen und Namensschild leuchten langsam in Mondsilber auf und ab (nur bei `secrets_visible`)
	set(value):
		active = value
		_apply_hunt_motion()
		queue_redraw()
var _hunt_time: float = 0.0
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
	set_process(false)  # nur der Feuerring animiert (`hunt`)
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
	var span := plate_span if plate_span != Vector2.ZERO else Vector2(limit * 0.5, limit * 0.5)
	return PortraitRingLayout.plate_rect_local(diameter, size, w, span)


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
	return tr(key).format({"mark": PLATE_MARKS.get(state, ""), "name": str(_seat["name"])})


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
	if alive and locked:
		dim = ThemeTokens.TINT_LOCKED
	match state:
		&"selected":
			_draw_glow(c, d, GLOW_SELECTED, 6, 0.7)
		&"allowed":
			_draw_glow(c, d, SHIMMER_ALLOWED, 3, 0.26)
	if chosen:
		_draw_glow(c, d, GLOW_ACTIVE, 6, 0.8)
	if hunt and secrets_visible:
		_draw_hunt(c, d)
	if active:
		_draw_active(c, d)
	if _nominated and alive:
		_draw_nominated(c, d)
	_draw_portrait(c, d, dim)
	var frame_rect := _frame_rect(c, d)
	var socket := frame_rect.position + GroveArtData.SEAT_SOCKET_CENTER * frame_rect.size
	draw_circle(socket, GroveArtData.SEAT_SOCKET_RADIUS * d * 1.05, ThemeTokens.NUMBER_BG)
	var frame := GroveSkin.texture("seat_frame")
	if frame != null:
		var silver := GroveSkin.TINT_SEAT_SILVER * dim
		draw_texture_rect(frame, frame_rect, false, silver)
	_draw_state_ring(c, d)
	_draw_socket(frame_rect, socket, d, GroveSkin.TINT_SEAT_SILVER * dim)  # in jedem Zustand über dem Ring, damit die Nummer lesbar bleibt
	_draw_number(socket, d)
	if state == &"selected":
		_draw_check(c, d)
	if alive and locked:
		_draw_lock(c, d)
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
func _draw_glow(c: Vector2, d: float, color: Color, arcs: int, strength: float) -> void:
	for i: int in arcs:
		var tone := color
		tone.a = strength * (1.0 - float(i) / float(arcs))
		draw_arc(c, d * RING_RADIUS + 1.0 + 2.0 * float(i), 0.0, TAU, 56, tone, 2.6, true)


## Feuerring der Wölfe: blutroter Schein mit heißem Kern, pulsierend (bei reduzierter Bewegung ruhig und voll).
func _draw_hunt(c: Vector2, d: float) -> void:
	var pulse := 1.0
	if hunt_animated:
		pulse = 0.75 + 0.25 * sin(_hunt_time * HUNT_PULSE_SPEED) + 0.08 * sin(_hunt_time * 11.0)
	var radius := d * RING_RADIUS
	for i: int in HUNT_ARCS:
		var tone := ThemeTokens.HUNT_FLAME
		tone.a = clampf(1.1 * pulse * (1.0 - float(i) / float(HUNT_ARCS)), 0.0, 1.0)
		draw_arc(c, radius + 1.0 + 3.2 * float(i) * (0.8 + 0.4 * pulse), 0.0, TAU, 64, tone, 4.4, true)
	var core := ThemeTokens.HUNT_CORE
	core.a = 0.7 + 0.3 * pulse
	draw_arc(c, radius + 1.5, 0.0, TAU, 64, core, 5.0, true)


## Aktive Person: Mondsilber-Schein um den Bildrahmen, pulsierend (bei reduzierter Bewegung ruhig und voll). Das Schild leuchtet in `_draw_plate`.
func _active_pulse() -> float:
	return 0.5 + 0.5 * sin(_hunt_time * ACTIVE_PULSE_SPEED) if hunt_animated else 0.85


func _draw_active(c: Vector2, d: float) -> void:
	var pulse := _active_pulse()
	var radius := d * RING_RADIUS
	for i: int in 8:
		var tone := ThemeTokens.MOON_GLOW
		tone.a = (0.35 + 0.55 * pulse) * (1.0 - float(i) / 8.0)
		draw_arc(c, radius + 1.0 + 2.6 * float(i), 0.0, TAU, 64, tone, 3.2, true)
	var rim := ThemeTokens.MOON_SILVER_BRIGHT
	rim.a = 0.55 + 0.45 * pulse
	draw_arc(c, radius + 1.5, 0.0, TAU, 64, rim, 3.0, true)


## Nominiert (öffentlich): ruhiger Blutrot-Ring, solange die Person lebt; der Tageswechsel setzt die Nominierung zurück.
func _draw_nominated(c: Vector2, d: float) -> void:
	_draw_glow(c, d, ThemeTokens.BLOOD_GLOW, 5, 0.8)
	draw_arc(c, d * RING_RADIUS + 1.5, 0.0, TAU, 64, ThemeTokens.BLOOD_RED_BRIGHT, 5.0, true)


func _apply_hunt_motion() -> void:
	set_process((hunt or active) and hunt_animated)


func _process(delta: float) -> void:
	_hunt_time += delta
	queue_redraw()


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
			pass  # heller Schein und Häkchen (siehe _draw)
		&"dead":
			overlay = "dead"
		&"allowed", &"actor":
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


## Nummernsockel noch einmal über Zustandsring und Abzeichen: dunkle Scheibe, dann der Sockelausschnitt des Rahmens.
func _draw_socket(frame_rect: Rect2, socket: Vector2, d: float, tint: Color) -> void:
	draw_circle(socket, GroveArtData.SEAT_SOCKET_RADIUS * d * 1.05, ThemeTokens.NUMBER_BG)
	var frame := GroveSkin.texture("seat_frame")
	if frame == null:
		return
	var tex := frame.get_size()
	var reach := GroveArtData.SEAT_SOCKET_RADIUS * 1.5 * tex.x
	var centre := GroveArtData.SEAT_SOCKET_CENTER * tex
	var src := Rect2(centre - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
	var scale := frame_rect.size / tex
	draw_texture_rect_region(frame, Rect2(frame_rect.position + src.position * scale, src.size * scale), src, tint)


## Häkchen am Ring des gewählten Ziels: die Auswahl hängt nicht an der Farbe allein.
func _draw_check(c: Vector2, d: float) -> void:
	var centre := c + Vector2(d * 0.31, -d * 0.27)
	draw_circle(centre, 8.5, ThemeTokens.NUMBER_BG)
	draw_arc(centre, 8.5, 0.0, TAU, 12 * 2, GLOW_SELECTED, 1.4, true)
	draw_polyline(PackedVector2Array([centre + Vector2(-4.0, 0.5), centre + Vector2(-1.2, 3.4), centre + Vector2(4.2, -3.2)]), GLOW_SELECTED, 2.0, true)


## Kleines Schloss in Silber (Körper und Bügel), an derselben Stelle wie das Häkchen.
func _draw_lock(c: Vector2, d: float) -> void:
	var centre := c + Vector2(d * 0.31, -d * 0.27)
	draw_circle(centre, 9.0, ThemeTokens.NUMBER_BG)
	draw_arc(centre, 9.0, 0.0, TAU, 24, ThemeTokens.MOON_SILVER, 1.2, true)
	draw_arc(centre + Vector2(0.0, -1.6), 3.0, PI, TAU, 10, ThemeTokens.MOON_SILVER, 1.8, true)
	draw_rect(Rect2(centre + Vector2(-4.0, -1.6), Vector2(8.0, 6.0)), ThemeTokens.MOON_SILVER)


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
		var rect := Rect2(c.x + d * 0.5 - size_px * 0.85 - float(i) * size_px * 0.7, c.y + d * 0.5 - size_px * 0.85, size_px, size_px)
		var texture := NightArt.badge(str(kind))
		if texture != null:
			draw_texture_rect(texture, rect, false)
		else:
			_draw_glyph_badge(str(kind), rect)
		i += 1


## Abzeichen ohne Bilddatei (Liebende, Rivalen, verzaubert): dunkle Scheibe, Silberring und ein Silberzeichen, das sich in der Form unterscheidet.
func _draw_glyph_badge(kind: String, rect: Rect2) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.46
	draw_circle(c, r, ThemeTokens.NUMBER_BG)
	draw_arc(c, r, 0.0, TAU, 32, ThemeTokens.MOON_SILVER, 1.6, true)
	var s := r * 0.55
	var silver := ThemeTokens.MOON_SILVER_BRIGHT
	match kind:
		"lovers":  # Herz
			var heart := PackedVector2Array()
			for k: int in 24:
				var a := TAU * float(k) / 24.0
				heart.append(c + Vector2(16.0 * pow(sin(a), 3.0), -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) * s / 16.0)
			draw_colored_polygon(heart, silver)
		"rivals":  # gekreuzte Klingen
			draw_line(c + Vector2(-s, -s), c + Vector2(s, s), silver, 2.2, true)
			draw_line(c + Vector2(s, -s), c + Vector2(-s, s), silver, 2.2, true)
			draw_line(c + Vector2(-s * 0.95, -s * 0.35), c + Vector2(-s * 0.35, -s * 0.95), silver, 1.6, true)
			draw_line(c + Vector2(s * 0.95, -s * 0.35), c + Vector2(s * 0.35, -s * 0.95), silver, 1.6, true)
		"charmed":  # Note (Flöte des Rattenfängers)
			draw_circle(c + Vector2(-s * 0.35, s * 0.55), s * 0.38, silver)
			draw_line(c + Vector2(s * 0.0, s * 0.55), c + Vector2(s * 0.0, -s * 0.9), silver, 1.8, true)
			draw_line(c + Vector2(s * 0.0, -s * 0.9), c + Vector2(s * 0.7, -s * 0.5), silver, 1.8, true)


func _draw_plate() -> void:
	var rect := plate_rect()
	if active:
		var glow := StyleBoxFlat.new()
		var pulse := _active_pulse()
		glow.bg_color = ThemeTokens.INVISIBLE
		glow.set_corner_radius_all(9)
		glow.shadow_color = ThemeTokens.MOON_GLOW
		glow.shadow_color.a = 0.35 + 0.5 * pulse
		glow.shadow_size = int(6.0 + 6.0 * pulse)
		draw_style_box(glow, rect.grow(1.0))
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
	while font_size > PLATE_FONT_SIZE_MIN and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit:
		font_size -= 1  # lange Namen: erst Schrift bis zur Mindestgröße verkleinern, dann kürzen
	while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > limit and text.length() > 3:
		text = text.trim_suffix("…")
		text = text.left(text.length() - 1) + "…"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var color := ThemeTokens.TEXT_MUTED if not alive else ThemeTokens.TEXT_PRIMARY
	draw_string(font, Vector2(rect.position.x + (rect.size.x - w) * 0.5, rect.position.y + (rect.size.y + float(font_size) * 0.72) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()
