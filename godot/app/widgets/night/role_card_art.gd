class_name RoleCardArt
extends Control
## Rollenbild der Aktionskarte (Variante A, P3; P5): rundes Bild im Medaillon `ui/hain/card_medallion.png`. Zeigt das vorläufige Rollenbild
## der Rolle der aktuellen Nachthandlung; ohne Bild oder ohne Rolle bleibt die Fläche leer. Geheim: Die Ansicht blendet das Bild
## bei „Verbergen“ aus und zeigt es nie außerhalb der Nacht. Keine Texte im Bild; Rollenname und Anweisung stehen als Text in der Karte.

const FRAME_ASPECT := 1.0 / GroveArtData.MEDALLION_ASPECT  ## Breite zu Höhe des Rahmenbilds
const WINDOW_OVERLAP := 1.04    ## das Bild reicht etwas unter den Ring, damit kein Spalt bleibt
const SEGMENTS := 48

var _role_id: String = ""


func _init() -> void:
	name = "RoleCardArt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(104.0, 104.0 / FRAME_ASPECT)


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
	var centre := origin + Vector2(w * GroveArtData.MEDALLION_HOLE_CENTER.x, h * GroveArtData.MEDALLION_HOLE_CENTER.y)
	var radius := w * GroveArtData.MEDALLION_HOLE_RADIUS * WINDOW_OVERLAP
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i: int in SEGMENTS:
		var a := TAU * float(i) / float(SEGMENTS)
		points.append(centre + Vector2(cos(a), sin(a)) * radius)
		uvs.append(Vector2(0.5 + 0.5 * cos(a), 0.5 + 0.5 * sin(a)))
	draw_colored_polygon(points, ThemeTokens.TINT_NONE, uvs, art)
	var frame := GroveSkin.texture("card_medallion")
	if frame != null:
		draw_texture_rect(frame, Rect2(origin, Vector2(w, h)), false)
