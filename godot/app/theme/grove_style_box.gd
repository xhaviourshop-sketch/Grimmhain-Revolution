class_name GroveStyleBox
extends StyleBox
## Dehnbarer Rahmen aus einem Hain-Teil (`assets/ui/hain/`, Neun-Felder-Raster). Die Texturen haben `GroveArtData.TEXTURE_SCALE` Pixel
## je logische Einheit, damit sie auch auf zweifach aufgelösten Bildschirmen scharf sind; Standard-StyleBoxTexture zeichnet Ränder
## 1:1 und würde die Ornamente doppelt so groß machen. Ecken und Enden (Ränder) bleiben unverzerrt, die Mitte wird gedehnt.
## Zustände (gedrückt, gesperrt, Fokus) kommen über `tint`.

var texture: Texture2D = null
var margins: Vector4 = Vector4.ZERO  ## links, oben, rechts, unten in Texturpixeln
var tint: Color = Color.WHITE
var clasp: Vector2 = Vector2.ZERO  ## (Start, Breite) einer geschützten Mittelspange in Texturpixeln; nur waagerechte Leisten (Ränder oben und unten 0)
var with_clasp: bool = true
var native_height: float = 0.0  ## > 0: die Fläche wird nicht höher als das Bild (in logischen Einheiten) gezeichnet, sondern mittig; die Tippfläche bleibt die ganze Höhe


static func make(p_texture: Texture2D, p_margins: Vector4, p_tint: Color = Color.WHITE) -> GroveStyleBox:
	var box := GroveStyleBox.new()
	box.texture = p_texture
	box.margins = p_margins
	box.tint = p_tint
	return box


## Ränder in logischen Einheiten.
func edge(side: int) -> float:
	return margins[side] / GroveArtData.TEXTURE_SCALE


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var tex_size := texture.get_size()
	if native_height > 0.0 and rect.size.y > native_height:
		rect = Rect2(rect.position.x, rect.position.y + (rect.size.y - native_height) * 0.5, rect.size.x, native_height)
	if clasp.y > 0.0 and margins.y == 0.0 and margins.w == 0.0:
		_draw_clasp_bar(to_canvas_item, rect)
		return
	var left := edge(0)
	var top := edge(1)
	var right := edge(2)
	var bottom := edge(3)
	# Ist die Fläche kleiner als die Ornamente, werden die Ränder gemeinsam verkleinert statt zu überlappen.
	var fit_x := minf(1.0, rect.size.x / maxf(left + right, 0.001))
	var fit_y := minf(1.0, rect.size.y / maxf(top + bottom, 0.001))
	left *= fit_x
	right *= fit_x
	top *= fit_y
	bottom *= fit_y
	var xs := [rect.position.x, rect.position.x + left, rect.end.x - right, rect.end.x]
	var ys := [rect.position.y, rect.position.y + top, rect.end.y - bottom, rect.end.y]
	var sx := [0.0, margins.x, tex_size.x - margins.z, tex_size.x]
	var sy := [0.0, margins.y, tex_size.y - margins.w, tex_size.y]
	var rid := texture.get_rid()
	for row: int in 3:
		for col: int in 3:
			var dest := Rect2(xs[col], ys[row], xs[col + 1] - xs[col], ys[row + 1] - ys[row])
			var src := Rect2(sx[col], sy[row], sx[col + 1] - sx[col], sy[row + 1] - sy[row])
			if dest.size.x <= 0.0 or dest.size.y <= 0.0 or src.size.x <= 0.0 or src.size.y <= 0.0:
				continue
			RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, dest, rid, src, tint)


## Leiste mit Mittelspange: Enden und Spange bleiben unverzerrt, die glatten Abschnitte dazwischen werden gedehnt. `with_clasp` false
## (Chip) überspringt die Spange und dehnt den linken glatten Abschnitt über die ganze Mitte.
func _draw_clasp_bar(to_canvas_item: RID, rect: Rect2) -> void:
	var tex_size := texture.get_size()
	var left := edge(0)
	var right := edge(2)
	var clasp_w := clasp.y / GroveArtData.TEXTURE_SCALE
	var fit := minf(1.0, rect.size.x / maxf(left + right + (clasp_w if with_clasp else 0.0), 0.001))
	left *= fit
	right *= fit
	clasp_w *= fit
	var rid := texture.get_rid()
	var h := rect.size.y
	var plain_end := clasp.x  ## Texturpixel: Ende des linken glatten Abschnitts
	var inner := rect.size.x - left - right
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(rect.position.x, rect.position.y, left, h), rid, Rect2(0.0, 0.0, margins.x, tex_size.y), tint)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(rect.end.x - right, rect.position.y, right, h), rid, Rect2(tex_size.x - margins.z, 0.0, margins.z, tex_size.y), tint)
	if not with_clasp:
		RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(rect.position.x + left, rect.position.y, inner, h), rid, Rect2(margins.x, 0.0, plain_end - margins.x, tex_size.y), tint)
		return
	var plain_w := (inner - clasp_w) * 0.5
	var mid := rect.position.x + left + plain_w
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(rect.position.x + left, rect.position.y, plain_w, h), rid, Rect2(margins.x, 0.0, plain_end - margins.x, tex_size.y), tint)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(mid, rect.position.y, clasp_w, h), rid, Rect2(plain_end, 0.0, clasp.y, tex_size.y), tint)
	var after := plain_end + clasp.y
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(mid + clasp_w, rect.position.y, plain_w, h), rid, Rect2(after, 0.0, tex_size.x - margins.z - after, tex_size.y), tint)


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO
