class_name GlyphButton
extends GrimmButton
## Runder Randknopf mit gezeichnetem Zeichen (P3): „hide“ = Auge (Verbergen, Umschalter; aktiv mit Schrägstrich), „cover“ =
## Schloss (Sichtschutz), „info“ = i im Kreis (Details der Aktionskarte). Der Text (Übersetzung) bleibt Tooltip und Bedienungshilfe und wird nicht gezeichnet. Zustand nie nur über
## Farbe: aktives Verbergen zeigt den Schrägstrich und einen Goldrand.

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
	var gold := ThemeTokens.GOLD_BRIGHT if (active or is_hovered() or has_focus()) else ThemeTokens.GOLD
	if disabled:
		gold = ThemeTokens.TEXT_DISABLED
	draw_circle(c, r, ThemeTokens.NUMBER_BG)
	draw_arc(c, r, 0.0, TAU, 40, gold, 2.0 if not active else 3.5, true)
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
			draw_polyline(pts, gold, 2.0, true)
			draw_circle(c, r * 0.17, gold)
			if active:
				draw_line(c + Vector2(-w, h * 1.6), c + Vector2(w, -h * 1.6), ThemeTokens.DANGER_TEXT, 3.0, true)
		"info":
			draw_circle(c + Vector2(0.0, -r * 0.4), r * 0.11, gold)
			draw_rect(Rect2(c + Vector2(-r * 0.09, -r * 0.18), Vector2(r * 0.18, r * 0.62)), gold)
		"cover":
			var body := Rect2(c + Vector2(-r * 0.36, -r * 0.02), Vector2(r * 0.72, r * 0.5))
			draw_rect(body, gold)
			draw_arc(c + Vector2(0.0, -r * 0.02), r * 0.25, PI, TAU, SHACKLE_POINTS, gold, 2.5, true)
			draw_circle(body.get_center() + Vector2(0.0, -1.0), r * 0.07, ThemeTokens.NUMBER_BG)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT \
			or what == NOTIFICATION_RESIZED:
		queue_redraw()
