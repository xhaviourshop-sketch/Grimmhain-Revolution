class_name GlyphButton
extends GrimmButton
## Runder Randknopf auf dem gemalten Randknopf (`randknopf`) mit gezeichnetem Mondsilber-Zeichen: „hide“ = Auge (Verbergen, Umschalter;
## aktiv mit Schrägstrich), „cover“ = Schloss (Sichtschutz), „info“ = i (Details der Aktionskarte), „mic“ = Mikrofon (Namen per Sprache;
## als Umschalter zeigt der rote Ring die laufende Aufnahme). Der Text (Übersetzung) bleibt
## Tooltip und Bedienungshilfe und wird nicht gezeichnet. Zustand nie nur über Farbe: aktives Verbergen zeigt den Schrägstrich und
## einen blutroten Ring.

const SHACKLE_POINTS := 16  ## Stützpunkte des Bügels am Schloss
const _STYLE_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const _FONT_COLORS: Array[String] = ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]

@export var glyph: String = "hide"


func _init() -> void:
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	for style: String in _STYLE_STATES:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: String in _FONT_COLORS:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size * 0.5) <= minf(size.x, size.y) * 0.5


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var active := button_pressed and toggle_mode
	var ink := ThemeTokens.MOON_SILVER_BRIGHT if (active or is_hovered() or has_focus()) else ThemeTokens.MOON_SILVER
	if disabled:
		ink = ThemeTokens.MOON_SILVER_DIM
	var tex := SkinArt.edge_knob()
	if tex != null:
		if is_pressed() or active:  # Glühen hinter dem Rand, nicht nur Farbe
			draw_circle(c, r + 3.0, ThemeTokens.BLOOD_RED_HALO if active else ThemeTokens.MOON_GLOW)
		var tint := ThemeTokens.TINT_DEAD if disabled else (ThemeTokens.TINT_HOVER if (is_pressed() or is_hovered()) else ThemeTokens.TINT_NONE)
		draw_texture_rect(tex, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, tint)
	else:
		draw_circle(c, r, ThemeTokens.NUMBER_BG)
		draw_arc(c, r, 0.0, TAU, 40, ink, 2.0, true)
	if active:
		draw_arc(c, r - 3.0, 0.0, TAU, 40, ThemeTokens.BLOOD_RED, 3.5, true)
	if has_focus():
		draw_arc(c, r + 1.0, 0.0, TAU, 40, ThemeTokens.FOCUS_RING, float(ThemeTokens.FOCUS_WIDTH), true)
	r *= 0.8  # Zeichen mittig im leeren Innenraum des Randknopfs
	match glyph:
		"hide":
			var w := r * 0.62
			var h := r * 0.34
			var pts := PackedVector2Array()
			for i: int in 17:
				var t := float(i) / 16.0
				pts.append(c + Vector2(lerpf(-w, w, t), -sin(t * PI) * h))
			for i: int in 17:
				var t := float(16 - i) / 16.0
				pts.append(c + Vector2(lerpf(-w, w, t), sin(t * PI) * h))
			draw_polyline(pts, ink, 2.0, true)
			draw_circle(c, r * 0.17, ink)
			if active:
				draw_line(c + Vector2(-w, h * 1.6), c + Vector2(w, -h * 1.6), ThemeTokens.BLOOD_RED, 3.0, true)
		"plus":
			draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.07), Vector2(r, r * 0.14)), ink)
			draw_rect(Rect2(c + Vector2(-r * 0.07, -r * 0.5), Vector2(r * 0.14, r)), ink)
		"minus":
			draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.07), Vector2(r, r * 0.14)), ink)
		"info":
			draw_circle(c + Vector2(0.0, -r * 0.4), r * 0.11, ink)
			draw_rect(Rect2(c + Vector2(-r * 0.09, -r * 0.18), Vector2(r * 0.18, r * 0.62)), ink)
		"mic":
			draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.5), Vector2(r * 0.4, r * 0.5)), ink)
			draw_circle(c + Vector2(0.0, -r * 0.5), r * 0.2, ink)
			draw_circle(c + Vector2(0.0, 0.0), r * 0.2, ink)
			draw_arc(c + Vector2(0.0, -r * 0.08), r * 0.4, 0.0, PI, 20, ink, 2.0, true)
			draw_line(c + Vector2(0.0, r * 0.32), c + Vector2(0.0, r * 0.58), ink, 2.0, true)
			draw_line(c + Vector2(-r * 0.24, r * 0.58), c + Vector2(r * 0.24, r * 0.58), ink, 2.0, true)
		"cover":
			var body := Rect2(c + Vector2(-r * 0.56, -r * 0.02), Vector2(r * 1.12, r * 0.78))
			draw_rect(body, ink)
			draw_arc(c + Vector2(0.0, -r * 0.04), r * 0.4, PI, TAU, SHACKLE_POINTS, ink, 3.0, true)
			draw_circle(body.get_center() + Vector2(0.0, -1.0), r * 0.09, ThemeTokens.NUMBER_BG)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED:
		queue_redraw()
