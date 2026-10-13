class_name StarDust
extends Control
## Schimmer des Aktes Classic (DA-108): ruhiges, silbrig-weißes Sternenstaub-Funkeln entlang des Kartenrahmens, kein Feuer, kein Blau.
## Billig für ein Standard-iPad: feste Punkte ohne Partikelsystem und Shader, neu gezeichnet höchstens 12-mal pro Sekunde und nur,
## solange das Funkeln sichtbar ist. Ohne Bewegung (`animated` aus) stehen die Punkte still. Positionen sind fest (Goldener Schnitt),
## kein Zufall.

const COUNT := 26
const REDRAW_INTERVAL := 1.0 / 12.0
const EDGE_INSET := 9.0   ## Abstand der Funken zum Kartenrand
const BAND := 10.0        ## Breite des Bands nach innen, in dem die Funken liegen

var animated: bool = true:
	set(value):
		animated = value
		_update_processing()
		queue_redraw()
var _time: float = 0.0
var _since_redraw: float = 0.0


func _init() -> void:
	name = "StarDust"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visibility_changed.connect(_update_processing)
	_update_processing()


func _update_processing() -> void:
	set_process(animated and is_visible_in_tree())


func _process(delta: float) -> void:
	_time += delta
	_since_redraw += delta
	if _since_redraw >= REDRAW_INTERVAL:
		_since_redraw = 0.0
		queue_redraw()


func _draw() -> void:
	var inner := Rect2(Vector2.ZERO, size).grow(-EDGE_INSET)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	var perimeter := 2.0 * (inner.size.x + inner.size.y)
	for i: int in COUNT:
		var along := fposmod(float(i) * 0.618034, 1.0) * perimeter
		var depth := fposmod(float(i) * 0.381966 * 3.0, 1.0) * BAND
		var centre := _on_edge(inner, along, depth)
		var phase := float(i) * 1.7
		var speed := 0.6 + fposmod(float(i) * 0.2718, 1.0) * 0.9
		var wave := 0.5 + 0.5 * sin(_time * speed + phase) if animated else 0.6 + 0.4 * fposmod(float(i) * 0.437, 1.0)
		var glow := wave * wave
		var colour := ThemeTokens.MOON_SILVER_BRIGHT
		colour.a = 0.25 + 0.65 * glow
		draw_circle(centre, 1.0 + 1.2 * glow, colour, true, -1.0, true)
		if glow > 0.7:  # die hellsten Funken tragen ein kleines Sternkreuz
			var arm := 2.0 + 3.0 * glow
			colour.a *= 0.7
			draw_line(centre - Vector2(arm, 0.0), centre + Vector2(arm, 0.0), colour, 1.0, true)
			draw_line(centre - Vector2(0.0, arm), centre + Vector2(0.0, arm), colour, 1.0, true)


## Punkt im Abstand `along` entlang des Rahmens (oben, rechts, unten, links), um `depth` nach innen versetzt.
func _on_edge(r: Rect2, along: float, depth: float) -> Vector2:
	var w := r.size.x
	var h := r.size.y
	if along < w:
		return r.position + Vector2(along, depth)
	along -= w
	if along < h:
		return r.position + Vector2(w - depth, along)
	along -= h
	if along < w:
		return r.position + Vector2(w - along, h - depth)
	along -= w
	return r.position + Vector2(depth, h - along)
