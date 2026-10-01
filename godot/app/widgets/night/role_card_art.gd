class_name RoleCardArt
extends Control
## Rollenbild der Aktionskarte (Variante A, P3): ovales Bild im Rahmen `ui/role-frame.png`. Zeigt das vorläufige Rollenbild
## der Rolle der aktuellen Nachthandlung; ohne Bild oder ohne Rolle bleibt die Fläche leer. Geheim: Die Ansicht blendet das Bild
## bei „Verbergen“ aus und zeigt es nie außerhalb der Nacht. Keine Texte im Bild; Rollenname und Anweisung stehen als Text in der Karte.

const FRAME_ASPECT := 0.657     ## Breite zu Höhe des Rahmenbilds
const WINDOW := Vector2(0.37, 0.355)  ## Halbachsen des ovalen Bildfensters im Rahmen (Anteil von Breite und Höhe)
const WINDOW_CENTRE := Vector2(0.5, 0.47)
const SEGMENTS := 48

var _role_id: String = ""


func _init() -> void:
	name = "RoleCardArt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(96.0, 96.0 / FRAME_ASPECT)


func show_role(role_id: String) -> void:
	_role_id = role_id
	visible = role_id != "" and NightArt.role_art(role_id) != null
	queue_redraw()


func role_id() -> String:
	return _role_id


func _draw() -> void:
	if _role_id == "":
		return
	var art := NightArt.role_art(_role_id)
	if art == null:
		return
	var h := minf(size.y, size.x / FRAME_ASPECT)
	var w := h * FRAME_ASPECT
	var origin := Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
	var centre := origin + Vector2(w * WINDOW_CENTRE.x, h * WINDOW_CENTRE.y)
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i: int in SEGMENTS:
		var a := TAU * float(i) / float(SEGMENTS)
		points.append(centre + Vector2(cos(a) * w * WINDOW.x, sin(a) * h * WINDOW.y))
		uvs.append(Vector2(0.5 + 0.5 * cos(a), 0.5 + 0.5 * sin(a)))
	draw_colored_polygon(points, ThemeTokens.TINT_NONE, uvs, art)
	var frame := NightArt.texture("ui/role-frame.png")
	if frame != null:
		draw_texture_rect(frame, Rect2(origin, Vector2(w, h)), false)
