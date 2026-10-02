class_name ScrollHint
extends Control
## Hinweis „es geht weiter“ am unteren Rand eines scrollenden Kartentexts (P5b): ein weicher Verlauf und ein kleiner Pfeil nach unten,
## solange unterhalb noch Text liegt. Kein Text, also keine Übersetzung. Liegt als freie Ebene (`top_level`) über dem Scrollbereich,
## ohne das Layout der Karte zu beeinflussen, und fängt keine Eingaben ab.

const HEIGHT := 30.0
const FADE := ThemeTokens.SCROLL_FADE
const ARROW := ThemeTokens.MOON_GLOW

var _scroll: ScrollContainer = null
var _more: bool = false


func _init() -> void:
	name = "ScrollHint"
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func bind(scroll: ScrollContainer) -> void:
	_scroll = scroll


## Ob unterhalb des sichtbaren Ausschnitts noch Text liegt.
func has_more() -> bool:
	return _more


func _process(_delta: float) -> void:
	if _scroll == null or not is_instance_valid(_scroll) or not _scroll.is_visible_in_tree():
		visible = false
		return
	var bar := _scroll.get_v_scroll_bar()
	var more := bar.max_value - bar.page > 1.0 and bar.value < bar.max_value - bar.page - 1.0
	var rect := _scroll.get_global_rect()
	global_position = Vector2(rect.position.x, rect.end.y - HEIGHT)
	size = Vector2(rect.size.x, HEIGHT)
	if more != _more or visible != more:
		_more = more
		visible = more
		queue_redraw()


func _draw() -> void:
	var steps := 6
	for i: int in steps:
		var tone := FADE
		tone.a = FADE.a * float(i + 1) / float(steps)
		draw_rect(Rect2(0.0, HEIGHT * float(i) / float(steps), size.x, HEIGHT / float(steps) + 0.5), tone)
	var centre := Vector2(size.x * 0.5, HEIGHT - 9.0)
	draw_polyline(PackedVector2Array([centre + Vector2(-7.0, -3.5), centre + Vector2(0.0, 3.5), centre + Vector2(7.0, -3.5)]), ARROW, 2.4, true)
