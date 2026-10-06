class_name GameSeatToken
extends GrimmButton
## Ein Platz im Cockpit-Sitzkreis als Porträtplatz (P3): rundes Porträt im Rahmen, Namensschild unten (nie eine Sitznummer: der Sitz ist nur Anordnung),
## Zustände als Ring über dem Porträt, kleine Zustandsabzeichen unten rechts. Zeigt nie eine Rolle. Bleibt ein Button
## mit Personen-ID und Signal `tapped`; der Button-Text (Name, Zeichen) dient der Bedienungshilfe, den Tests und dem
## Tooltip und wird nicht gezeichnet. Information hängt nie allein an der Farbe: Das Schild trägt Tod („†“), Nominierung
## (roter Ring und Band, ohne Zusatz im Namen), wählbares Ziel („›“), Auswahl („✓“); die handelnde Person trägt nur das Leuchten (kein Zeichen); die Abzeichen unterscheiden sich durch Form.
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
const PLATE_MARKS := {}  ## Zeichen im Schild: keines (die handelnde Person zeigt das Leuchten, DA-104)
const GLOW_SELECTED := ThemeTokens.MOON_GLOW  ## heller Mondsilber-Schein um das gewählte Ziel
const SHIMMER_ALLOWED := ThemeTokens.SEAT_SHIMMER  ## dezenter, kühler Schimmer wählbarer Plätze (ruhig, kein Pulsieren)
const FRAME_SCALE := 0.95  ## Kantenlänge des Rahmenbilds relativ zur Rahmenbreite des Platzes (der sichtbare Ring misst dann rund 0,40)
const RING_RADIUS := PortraitRingLayout.RING_RADIUS  ## Anteil der Rahmenbreite bis zum äußeren Rand des Rings (Tippfläche, Fokus, Zustandsschein)
const FACE_UV_SCALE := 0.62
const GLOW_DENSE_DIAMETER := 90.0  ## ab 13 Personen (Rahmen 86) gilt der schmale Schein
const GLOW_STEP_DENSE := 0.85
const PLATE_FONT_SIZE := 14  ## Schrift im Schild (Basisauflösung 1024x768); nie kleiner, lange Namen laufen in eine zweite und dritte Zeile
const PLATE_PADDING := 2.0  ## Innenabstand im Namensschild (links und rechts zusammen, ohne die Eisenkappen)
const PLATE_FONT_SIZE_FLOOR := 14  ## kleinste Schrift im Schild (Markus: mindestens 14 px)
const ELLIPSIS := "…"
const MIDWORD_PENALTY := 1000.0  ## bei der Wahl der Zeilen zählt jede Trennung mitten im Wort mehr als jede Breite: Trennstellen im Wort nur, wo es sein muss
const RING_OVERLAY_SCALE := 0.95  ## Kantenlänge der Statusring-Bilder relativ zur Rahmenbreite
const GLOW_ACTIVE := ThemeTokens.BLOOD_GLOW  ## blutroter Schein am Ring der handelnden Person
const HUNT_PULSE_SPEED := 3.4  ## Pulse je Sekunde im Bogenmaß
const ACTIVE_PULSE_SPEED := 2.1  ## langsames Auf und Ab der aktiven Person (rund drei Sekunden je Zug)
const HUNT_ARCS := 10  ## Bögen des Feuerscheins um den Ring
## Statusringe gibt es nur für Gift, Stille und Schutz. Das Fadenkreuz (Opfer, Markierung) bleibt ein Abzeichen: Ein roter Ring heißt am Platz
## nur „nominiert“ (Tag) oder „gewählt“ (Zuordnung), nie ein Opfer der Nacht (Feedback 8, L3/L11).
const RING_PRIORITY: Array[String] = ["poisoned", "silenced", "protected"]
## Gemalte kleine Bundzeichen der Liebenden und Rivalen am Ring (nur Spielleitung, nachts): SkinArt.bond_small.
const BOND_SCALE := 0.55  ## Kantenlänge des Bundzeichens relativ zur Rahmenbreite (lockerer Ring)
const BOND_SCALE_DENSE := 0.42  ## dichter Ring (ab 13 Personen): kleiner, damit es nie ein Nachbarporträt berührt
const BOND_STEP_ANGLE := 40.0  ## weitere Bundzeichen am selben Rahmen rücken so viele Grad zur Senkrechten
const BOND_SINK := 0.2  ## Anteil der Zeichengröße, um den es außerhalb der Ringkante sitzt (der Rest liegt auf dem eigenen Rahmenrand)
const BADGE_SCALE := 0.3  ## Kantenlänge der Zustandsabzeichen relativ zur Rahmenbreite (sie bleiben im eigenen Ring)
const BADGE_FIRST_ANGLE := 50.0  ## Winkel des ersten Abzeichens (Grad, 0 = rechts, 90 = unten)
const BADGE_STEP_ANGLE := 55.0
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
var plate_max_lines: int = 2:  ## so viele Zeilen darf der Name im Schild haben (der Ring setzt sie je Platz nach dem Layout)
	set(value):
		plate_max_lines = value
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
var _lines_key: String = ""  ## Zwischenspeicher für `_plate_lines` (die Berechnung ist aufwendig, `plate_rect` fragt sie bei jedem Tippen)
var _lines_cache: Array[String] = []
var _needs_key: String = ""
var _needs_cache: Array[float] = []
var _show_full_name: bool = false  ## solange der Finger aufliegt: das Schild zeigt den vollen Namen (nur wenn er gekürzt wäre)
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
	button_down.connect(func() -> void: set_full_name_shown(true))
	button_up.connect(func() -> void: set_full_name_shown(false))
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
	format_values = {"mark": STATE_MARKS.get(state, ""), "name": str(_seat["name"])}
	var key := "ui.cockpit.seat.alive"
	if not alive:
		key = "ui.cockpit.seat.dead"
	elif _nominated:
		key = "ui.cockpit.seat.nominated"
	text_key = key


## Voller Name in der Plakette (Finger liegt auf): nur wenn das Schild den Namen kürzt; liegt über den Nachbarn. Löst kein Antippen aus.
func set_full_name_shown(on: bool) -> void:
	var show := on and is_name_truncated()
	if show == _show_full_name:
		return
	_show_full_name = show
	z_index = 20 if show else 0
	queue_redraw()


func is_name_truncated() -> bool:
	for line: String in _plate_lines():
		if line.ends_with(ELLIPSIS):
			return true
	return false


# --- Geometrie ----------------------------------------------------------------------------------------

## Mittelpunkt, Porträtkreis und Schild im Koordinatensystem des Steuerelements.
func portrait_center() -> Vector2:
	return PortraitRingLayout.portrait_center(diameter)


func portrait_rect() -> Rect2:
	return Rect2(portrait_center() - Vector2.ONE * diameter * RING_RADIUS, Vector2.ONE * diameter * RING_RADIUS * 2.0)  # der sichtbare Ring, nicht das Bildrechteck


func plate_rect() -> Rect2:
	if _show_full_name:
		var full := _plate_text_width() + 2.0 * _plate_cap() + PLATE_PADDING
		var base := _base_plate_rect()
		return Rect2(base.get_center().x - full * 0.5, base.position.y, full, PortraitRingLayout.PLATE_HEIGHT)
	return _base_plate_rect()


func _base_plate_rect() -> Rect2:
	var limit := _plate_limit()
	var lines := _plate_lines()
	var widest := 0.0
	for line: String in lines:
		widest = maxf(widest, _line_width(line))
	var w := minf(limit, widest + 2.0 * _plate_cap() + PLATE_PADDING)
	var span := plate_span if plate_span != Vector2.ZERO else Vector2(limit * 0.5, limit * 0.5)
	return PortraitRingLayout.plate_rect_local(diameter, size, w, span, PortraitRingLayout.plate_height(lines.size()))


## Schildbreite, die der Name in einer, zwei und drei Zeilen braucht (so, wie er gerade steht; der Ring ordnet bei jeder Sitzänderung neu): der Ring gibt sie dem
## Layout, damit jeder Platz nur so viele Zeilen reserviert, wie sein Name braucht.
func plate_needs() -> Array[float]:
	if _seat.is_empty():
		return [0.0, 0.0, 0.0]
	var text := _plate_text()
	if _needs_key != text:
		_needs_key = text
		_needs_cache = []
		for w: float in plate_line_widths(text, _plate_font()):
			_needs_cache.append(w + 2.0 * _plate_cap() + PLATE_PADDING)  # (INF bleibt INF)
	return _needs_cache


func _plate_limit() -> float:
	return plate_limit if plate_limit > 0.0 else PortraitRingLayout.plate_max_width(diameter)


## Zeilen des Namens im Schild: so viele, wie das Layout erlaubt (`plate_max_lines`); „…“ nur, wenn der Name auch so nicht passt.
func _plate_lines() -> Array[String]:
	var room := _text_room(_plate_limit())
	var key := "%s|%.1f|%d" % [_plate_text(), room, plate_max_lines]
	if key != _lines_key:
		_lines_key = key
		_lines_cache = plate_lines(_plate_text(), _plate_font(), room, plate_max_lines)
	return _lines_cache


func _line_width(line: String) -> float:
	return _plate_font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE).x


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
	var frame := SkinArt.seat_frame()
	if frame != null:
		draw_texture_rect(frame, frame_rect, false, dim)
	_draw_state_ring(c, d)
	if state == &"selected":
		_draw_check(c, d)
	if alive and locked:
		_draw_lock(c, d)
	_draw_badges(c, d)
	_draw_plate()
	if has_focus():
		draw_arc(c, d * RING_RADIUS + 3.0, 0.0, TAU, 48, ThemeTokens.FOCUS_RING, float(ThemeTokens.FOCUS_WIDTH), true)


## Rechteck des Rahmenbilds so, dass die Öffnung des Rings auf der Porträtmitte liegt.
func _frame_rect(c: Vector2, d: float) -> Rect2:
	var frame_size := Vector2.ONE * d * FRAME_SCALE
	return Rect2(c - SkinArt.SEAT_HOLE_CENTER * frame_size, frame_size)


func _plate_cap() -> float:
	return GroveArtData.NAME_PLATE_SHORT_MARGINS.x / GroveArtData.TEXTURE_SCALE


## Weicher Schein um den Ring: mehrere dünne Bögen mit abnehmender Deckkraft.
func _draw_glow(c: Vector2, d: float, color: Color, arcs: int, strength: float) -> void:
	var step := GLOW_STEP_DENSE if d < GLOW_DENSE_DIAMETER else 2.0  # dichte Ringe: der Schein bleibt schmal, sonst berühren sich die Scheine der Nachbarn (DA-92)
	for i: int in arcs:
		var tone := color
		tone.a = strength * (1.0 - float(i) / float(arcs))
		draw_arc(c, d * RING_RADIUS + 1.0 + step * float(i), 0.0, TAU, 56, tone, step * 1.3, true)


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
	var radius := d * FRAME_SCALE * SkinArt.SEAT_PORTRAIT_RADIUS  # reicht etwas unter den Rahmen, der darüber gezeichnet wird
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


func _draw_badges(c: Vector2, d: float) -> void:
	if not secrets_visible or marks.is_empty() or not alive:
		return
	var size_px := maxf(ThemeTokens.BADGE_MIN, d * BADGE_SCALE)
	var i := 0
	var bonds := 0
	for kind: Variant in marks:
		var bond := SkinArt.bond_small(str(kind))
		var side := size_px
		# Zustandsabzeichen sitzen am eigenen Ring unten rechts (weitere reihen sich nach links unten auf). Bundzeichen sitzen als Abzeichen
		# auf dem eigenen Rahmenrand, in Richtung der freien Seite (siehe `_bond_angle`), nie zwischen zwei Porträts.
		var angle := deg_to_rad(BADGE_FIRST_ANGLE + float(i) * BADGE_STEP_ANGLE)
		var rect := Rect2(c + Vector2.from_angle(angle) * (d * RING_RADIUS - side * 0.35) - Vector2.ONE * side * 0.5, Vector2.ONE * side)
		if bond != null:
			side = d * (BOND_SCALE_DENSE if d < GLOW_DENSE_DIAMETER else BOND_SCALE)
			angle = _bond_angle(bonds)
			rect = Rect2(c + Vector2.from_angle(angle) * (d * RING_RADIUS + side * BOND_SINK) - Vector2.ONE * side * 0.5, Vector2.ONE * side)
			bonds += 1
		var texture := bond if bond != null else NightArt.badge(str(kind))
		if texture != null:
			draw_texture_rect(texture, rect, false)
		else:
			_draw_glyph_badge(str(kind), rect)
		i += 1


## Richtung des k-ten Bundzeichens am eigenen Rahmen (Bogenmaß, 0 = rechts, negativ = oben): in der oberen Ringhälfte nach außen, in der unteren
## zur Ringmitte, also immer nach oben und nie auf das Namensschild; weitere rücken zur Senkrechten. Die Nachbarn liegen seitlich entlang
## des Rings, die Richtung zeigt nach oben oder zur Seite, nie zu ihnen hin.
func _bond_angle(k: int) -> float:
	var angle := deg_to_rad(-90.0)
	var holder := get_parent() as Control
	if holder != null and holder.size.x > 0.0:
		var away := position + portrait_center() - holder.size * 0.5
		if away.y > 0.0:
			away = -away
		angle = clampf(away.angle(), deg_to_rad(-165.0), deg_to_rad(-15.0))
	var turn := deg_to_rad(BOND_STEP_ANGLE) * float(k)
	return angle + (-turn if cos(angle) > 0.05 else turn)


## Abzeichen ohne Bilddatei (verzaubert): dunkle Scheibe, Silberring und ein Silberzeichen.
func _draw_glyph_badge(kind: String, rect: Rect2) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.46
	draw_circle(c, r, ThemeTokens.NUMBER_BG)
	draw_arc(c, r, 0.0, TAU, 32, ThemeTokens.MOON_SILVER, 1.6, true)
	var s := r * 0.55
	var silver := ThemeTokens.MOON_SILVER_BRIGHT
	match kind:
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
	var font := _plate_font()
	var lines: Array[String] = [_plate_text()] if _show_full_name else _plate_lines()
	var color := ThemeTokens.TEXT_MUTED if not alive else ThemeTokens.TEXT_PRIMARY
	if lines.size() < 2:
		var w := _line_width(lines[0])
		draw_string(font, Vector2(rect.position.x + (rect.size.x - w) * 0.5, rect.position.y + (rect.size.y + float(PLATE_FONT_SIZE) * 0.72) * 0.5), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE, color)
		return
	var line_h := float(PLATE_FONT_SIZE) + 1.0  # enger als die Zeilenhöhe der Schrift: beide Zeilen bleiben im Rahmen des Schilds
	var top := rect.position.y + (rect.size.y - line_h * float(lines.size())) * 0.5 + font.get_ascent(PLATE_FONT_SIZE) - 1.0
	for k: int in lines.size():
		var w := _line_width(lines[k])
		draw_string(font, Vector2(rect.position.x + (rect.size.x - w) * 0.5, top + line_h * float(k)), lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE, color)


## Platz für den Text im Schild der Breite `plate_width`.
func _text_room(plate_width: float) -> float:
	return plate_width - 2.0 * _plate_cap() - PLATE_PADDING


## Text in Schriftgröße PLATE_FONT_SIZE, bei Bedarf mit „…“ gekürzt, sodass er in `room` Pixel passt (die Schrift schrumpft nie).
static func fitted_plate_text(text: String, font: Font, room: float) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE).x <= room:
		return text
	var n := text.length()
	while n > 1 and font.get_string_size(text.substr(0, n).strip_edges(false, true) + ELLIPSIS, HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE).x > room:
		n -= 1
	return text.substr(0, n).strip_edges(false, true) + ELLIPSIS


## Name in höchstens `max_lines` Zeilen zu je `room` Pixel (Schrift fest PLATE_FONT_SIZE). Reihenfolge: eine Zeile; getrennt nur an Leerzeichen oder
## Bindestrich (zwei, dann drei Zeilen, möglichst gleich breit, der Bindestrich bleibt am Ende der Zeile); dann auch mitten im Wort mit „-“ (mindestens
## drei Buchstaben auf jeder Seite); „…“ nur als letzte Rückfallstufe, wenn der Name auch so nicht passt (über 32 Zeichen, die Namensgrenze).
static func plate_lines(text: String, font: Font, room_exact: float, max_lines: int = 3) -> Array[String]:
	var room := room_exact + 0.5  # halbes Pixel Spiel: das Layout rechnet ebenso (Rundung der Schildbreite)
	if _text_width(text, font) <= room:
		return [text]
	var memo := {}
	for any_break: bool in [false, true]:
		for k: int in range(2, max_lines + 1):
			var best := _best_split(text, font, k, any_break, memo, room)
			if not best.is_empty() and _widest(best, font) <= room:
				return best
	return _lines_with_ellipsis(text, font, room, max_lines)


## Breiten (ohne Schildrand): [eine Zeile, höchstens zwei, höchstens drei Zeilen (nie zunehmend), nur an Leerzeichen und Bindestrich in zwei, ebenso in drei
## Zeilen (INF, wo es keine Trennstelle gibt)]. Die ersten drei sind das Mindestmaß, die letzten beiden die Breite für die schönere Aufteilung.
static func plate_line_widths(text: String, font: Font) -> Array[float]:
	var memo := {}
	var out: Array[float] = [_text_width(text, font)]
	for k: int in range(2, 4):
		var best := _best_split(text, font, k, true, memo)
		out.append(minf(out[k - 2], _widest(best, font) if not best.is_empty() else INF))
	for k: int in range(2, 4):
		var nice := _best_split(text, font, k, false, memo)
		out.append(_widest(nice, font) if not nice.is_empty() else INF)
	return out


static func _text_width(text: String, font: Font) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FONT_SIZE).x


static func _widest(lines: Array[String], font: Font) -> float:
	var widest := 0.0
	for line: String in lines:
		widest = maxf(widest, _text_width(line, font))
	return widest


## Mögliche Trennstellen: Vector3i(Ende der Zeile davor, Anfang der nächsten, 1 = mitten im Wort mit Trennstrich).
static func _break_options(text: String, any_break: bool) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for i: int in range(1, text.length()):
		var prev := text[i - 1]
		if prev == " ":
			if i > 1 and text[i] != " ":
				out.append(Vector3i(i - 1, i, 0))
		elif prev == "-":
			if text[i] != " ":
				out.append(Vector3i(i, i, 0))
		elif any_break and text[i] != " " and text[i] != "-" and i >= 3 and text.length() - i >= 3:
			out.append(Vector3i(i, i, 1))
	return out


## Beste Aufteilung in genau `k` Zeilen (die schmalste breiteste Zeile), leer, wenn es keine gibt.
static func _best_split(text: String, font: Font, k: int, any_break: bool, memo: Dictionary, room: float = INF) -> Array[String]:
	var options := _break_options(text, any_break)
	var best: Array[String] = []
	var best_width := INF
	for o1: Vector3i in options:
		var first := text.substr(0, o1.x) + ("-" if o1.z == 1 else "")
		if first == "†":
			continue
		if k == 2:
			var candidate: Array[String] = [first, text.substr(o1.y)]
			var widest := _memo_widest(candidate, font, memo)
			var score := widest + (MIDWORD_PENALTY * float(o1.z) if room < INF else 0.0)
			if widest <= room and score < best_width:
				best = candidate
				best_width = score
			continue
		for o2: Vector3i in options:
			var middle := o2.x - o1.y
			if middle < 1 or ((o1.z == 1 or o2.z == 1) and middle < 3):
				continue
			var candidate3: Array[String] = [first, text.substr(o1.y, middle) + ("-" if o2.z == 1 else ""), text.substr(o2.y)]
			var widest3 := _memo_widest(candidate3, font, memo)
			var score3 := widest3 + (MIDWORD_PENALTY * float(o1.z + o2.z) if room < INF else 0.0)
			if widest3 <= room and score3 < best_width:
				best = candidate3
				best_width = score3
	return best


static func _memo_widest(lines: Array[String], font: Font, memo: Dictionary) -> float:
	var widest := 0.0
	for line: String in lines:
		if not memo.has(line):
			memo[line] = _text_width(line, font)
		widest = maxf(widest, float(memo[line]))
	return widest


## Rückfallstufe für Namen, die in `max_lines` Zeilen nicht passen: jede Zeile so voll wie möglich (lieber an Leerzeichen oder Bindestrich),
## die letzte mit „…“ gekürzt.
static func _lines_with_ellipsis(text: String, font: Font, room: float, max_lines: int) -> Array[String]:
	var lines: Array[String] = []
	var rest := text
	while lines.size() < max_lines - 1 and _text_width(rest, font) > room:
		var cut := Vector3i(-1, -1, 0)
		for o: Vector3i in _break_options(rest, true):
			var line := rest.substr(0, o.x) + ("-" if o.z == 1 else "")
			if _text_width(line, font) > room or line == "†":
				continue
			if cut.x < 0 or (o.z == 0 and cut.z == 1) or (o.z == cut.z and o.x > cut.x):
				cut = o
		if cut.x < 0:
			break
		lines.append(rest.substr(0, cut.x) + ("-" if cut.z == 1 else ""))
		rest = rest.substr(cut.y)
	lines.append(fitted_plate_text(rest, font, room))
	return lines


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()
