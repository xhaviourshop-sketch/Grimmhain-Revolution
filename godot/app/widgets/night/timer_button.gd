class_name TimerButton
extends GrimmButton
## Anzeige des Timers auf der Phasen-Kartusche (P3): Restzeit als Text, davor Wiedergabe- oder Pausenzeichen. Tippen startet oder
## pausiert (die Ansicht entscheidet, ob eine Dauer eingestellt ist). Reine Anzeige, kein Befehl. Zustand nie nur über Farbe:
## Zeichen (▶ als Dreieck, Pause als zwei Balken) und Zeit tragen ihn mit.

const GLYPH := 14.0

var _running: bool = false
var _unset: bool = true
var _expired: bool = false


func _init() -> void:
	name = "TimerButton"
	kind = Kind.COMPACT
	wrap = false
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_RIGHT
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN + 40.0, ThemeTokens.TOUCH_MIN)


## Zeigt Restzeit (Sekunden), Laufzustand und ob eine Dauer eingestellt ist. Ohne Dauer steht „–:––“ statt einer Zeit.
func show_time(remaining: float, running: bool, is_set: bool, expired: bool) -> void:
	_running = running
	_unset = not is_set
	_expired = expired
	text = DisplayTimer.format_seconds(remaining) if is_set else tr("ui.cockpit.timer.unset")
	add_theme_color_override("font_color", ThemeTokens.DANGER_TEXT if expired else (ThemeTokens.GOLD_BRIGHT if running else ThemeTokens.TEXT_PRIMARY))
	add_theme_color_override("font_hover_color", ThemeTokens.GOLD_BRIGHT)
	queue_redraw()


func _draw() -> void:
	if _unset:
		return
	var c := Vector2(GLYPH * 0.9, size.y * 0.5)
	var color := ThemeTokens.GOLD_BRIGHT if _running else ThemeTokens.TEXT_MUTED
	if _running:
		draw_rect(Rect2(c.x - GLYPH * 0.4, c.y - GLYPH * 0.5, GLYPH * 0.28, GLYPH), color)
		draw_rect(Rect2(c.x + GLYPH * 0.12, c.y - GLYPH * 0.5, GLYPH * 0.28, GLYPH), color)
	else:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-GLYPH * 0.35, -GLYPH * 0.5), c + Vector2(GLYPH * 0.45, 0.0), c + Vector2(-GLYPH * 0.35, GLYPH * 0.5)]), color)
