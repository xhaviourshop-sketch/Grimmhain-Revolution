class_name SkinBarBox
extends StyleBox
## Waagerechte Leiste aus einem gemalten Bild in drei Teilen (Feedback 8): linkes und rechtes Ende bleiben unverzerrt (Seitenverhältnis),
## nur die glatte Mitte wird gedehnt. Gilt für Knöpfe (`knopf_*.webp`, Dornen-Enden) und Listenzeilen (`listenzeile.webp`).
## Die Rechteckhöhe entspricht `fit_height` Bildpixeln; ist das Bild höher (Dornen-Spitzen), ragt es oben und unten gleichmäßig über.
## Zustände (Hover, gesperrt, Fokus) kommen über `tint`.

var texture: Texture2D = null
var tint: Color = Color.WHITE
var end_width: float = 96.0     ## Breite jedes Endes in Bildpixeln
var fit_height: float = 100.0   ## Bildpixel, die der Rechteckhöhe entsprechen
var max_height: float = 0.0     ## > 0: höhere Flächen zeichnen die Leiste nicht höher, sondern mittig (die Tippfläche bleibt ganz)


static func make(p_texture: Texture2D, p_end_width: float, p_fit_height: float, p_tint: Color = Color.WHITE) -> SkinBarBox:
	var box := SkinBarBox.new()
	box.texture = p_texture
	box.end_width = p_end_width
	box.fit_height = p_fit_height
	box.tint = p_tint
	return box


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var tex_size := texture.get_size()
	var bar_h := minf(rect.size.y, max_height) if max_height > 0.0 else rect.size.y
	var scale := bar_h / fit_height
	var h := tex_size.y * scale
	var top := rect.position.y + (rect.size.y - h) * 0.5
	var end := end_width * scale
	# Ist die Fläche schmaler als beide Enden, schrumpfen die Enden gemeinsam, statt sich zu überlappen.
	if end * 2.0 > rect.size.x:
		end = rect.size.x * 0.5
	var rid := texture.get_rid()
	var x0 := rect.position.x
	var x1 := rect.end.x
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(x0, top, end, h), rid, Rect2(0.0, 0.0, end_width, tex_size.y), tint)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(x1 - end, top, end, h), rid, Rect2(tex_size.x - end_width, 0.0, end_width, tex_size.y), tint)
	if x1 - x0 - end * 2.0 > 0.0:
		RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(x0 + end, top, x1 - x0 - end * 2.0, h), rid, Rect2(end_width, 0.0, tex_size.x - end_width * 2.0, tex_size.y), tint)
