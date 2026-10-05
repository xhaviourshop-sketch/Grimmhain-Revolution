class_name SkinWindowBox
extends StyleBox
## Fensterfläche (Feedback 8): gekachelter Grund (`tafel_grund.webp`) unter dem Dornenrahmen (`rahmen.webp`, Neun-Felder-Raster).
## Ecken-Ornamente bleiben unverzerrt, die Seiten werden gedehnt. `frame_scale` ist die Größe der Ornamente (1 = Bildpixel).
## `tint` färbt Rahmen und Grund (Tag, Nacht, gesperrt).

var ground: Texture2D = null
var frame: GroveStyleBox = null
var tint: Color = Color.WHITE
var ground_inset: Vector4 = Vector4(10.0, 10.0, 10.0, 10.0)  ## Abstand des Grunds zum Rand (links, oben, rechts, unten), damit er unter der Rahmenlinie endet


static func make(p_ground: Texture2D, p_frame: Texture2D, p_margins: Vector4, p_frame_scale: float, p_tint: Color = Color.WHITE) -> SkinWindowBox:
	var box := SkinWindowBox.new()
	box.ground = p_ground
	box.frame = GroveStyleBox.make(p_frame, p_margins, p_tint)
	box.frame.px_per_unit = 1.0 / p_frame_scale
	box.tint = p_tint
	return box


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if ground != null:
		var inner := Rect2(rect.position + Vector2(ground_inset.x, ground_inset.y), rect.size - Vector2(ground_inset.x + ground_inset.z, ground_inset.y + ground_inset.w))
		if inner.size.x > 0.0 and inner.size.y > 0.0:
			RenderingServer.canvas_item_add_texture_rect(to_canvas_item, inner, ground.get_rid(), true, tint)
	if frame != null:
		frame.draw(to_canvas_item, rect)
