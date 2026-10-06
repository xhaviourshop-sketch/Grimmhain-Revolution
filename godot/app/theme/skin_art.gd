class_name SkinArt
extends RefCounted
## Gemalte Oberfläche (Feedback 8, `assets/ui/skin/`): Knöpfe, Listenzeilen, Fenster, Schalter und Rubinstein. Nur das Theme (ThemeFactory)
## und die Knopf-Bausteine fragen hier; Bildschirme bekommen ihre Grafik über Theme-Varianten. Fehlt eine Datei, bleibt die Fläche leer
## (kein Ersatzkasten); der Theme-Test meldet das.

const ROOT := "res://assets/ui/skin/"
const BUTTON_END := 96.0         ## Breite der Dornen-Enden im Knopfbild (Pixel)
const BUTTON_FIT_HEIGHT := 100.0 ## Bildpixel, die der Knopfhöhe entsprechen (Leiste 72 plus ein Teil der Spitzen)
const BUTTON_MAX_HEIGHT := 64.0  ## höhere Knöpfe zeichnen die Leiste nicht größer (Enden und Text kämen sich sonst in die Quere)
const ROW_END := 48.0            ## Enden der Listenzeile
const ROW_FIT_HEIGHT := 58.0
const FRAME_MARGINS := Vector4(150.0, 165.0, 150.0, 180.0)  ## Ecken-Ornamente des Rahmens in Bildpixeln (gemessen am Alpha)
const FRAME_GROUND_INSET := Vector4(30.0, 37.0, 31.0, 56.0)  ## Innenkante der Rahmenlinie in Bildpixeln (links, oben, rechts, unten)
const FRAME_SCALE := 0.38        ## Rahmenbild je logische Einheit
const FRAME_SCALE_SMALL := 0.26  ## kleine Fenster (Meldung, Leiste)
const STONE_HEIGHT := 40         ## Rubinstein im Hauptknopf, logische Höhe
## Feedback 9 (Bildmaße in Pixeln der fertigen WebP-Dateien):
const INPUT_END := 40.0          ## eingabefeld.webp (882x57): Dornen-Enden
const INPUT_FIT_HEIGHT := 57.0
const PLAQUE_END := 36.0         ## plakette.webp (197x66)
const PLAQUE_FIT_HEIGHT := 66.0
const DIVIDER_END := 20.0        ## trennlinie.webp (631x22), Mittelornament sitzt in der Bildmitte
const DIVIDER_FIT_HEIGHT := 22.0
const SIDE_TAB_END := 150.0      ## randlasche.webp (220x692): Höhe der Dornen-Enden oben und unten
const SIDE_TAB_FIT_WIDTH := 220.0  ## Bildbreite (Dornen) entspricht der Rechteckbreite; Leiste und Enden skalieren gemeinsam mit der Breite
const NIGHT_BAR_END := 150.0     ## nachtleiste.webp (982x344, Leiste genau in der Bildmitte): Breite der Dornen-Enden
const NIGHT_BAR_FIT_HEIGHT := 200.0  ## Bildpixel, die der Rechteckhöhe entsprechen (Dornen ragen darüber hinaus)
const NIGHT_CLASP_MID := 0.5     ## Mittelspange (nachtleiste_spange.webp, 68x80): waagerechte Lage als Anteil der Rechteckbreite, senkrecht mittig
const EDGE_KNOB_SIZE := 160      ## randknopf.webp, quadratisch; leere Mitte für das Symbol, Mitte des Bildes = Mitte des Knopfs
const SEAT_FRAME_SIZE := 256     ## sitzrahmen.webp, quadratisch
const SEAT_HOLE_CENTER := Vector2(0.4975, 0.5018)  ## Mitte der Rahmenöffnung als Anteil der Bildgröße (an der Alpha-Innenkante gemessen)
const SEAT_HOLE_RADIUS := 0.279  ## größter freier Kreis der Öffnung, Anteil der Bildbreite (Porträt füllt ihn sicher aus)
const SEAT_PORTRAIT_RADIUS := 0.30  ## empfohlener Porträtradius: etwas unter die Innenkante (Rahmen wird darüber gezeichnet; Innenkante liegt bei 0.279 bis 0.32)
const DIE_FACE_SIZE := 256       ## wuerfel.webp, quadratisch, leer (Augen kommen darüber)
const BOND_SMALL_SIZE := 128     ## bund_*_klein.webp, quadratisch, für Anzeige um 64 px
const SWITCH_HEIGHT := 72        ## Drehknopf-Schalter, logische Höhe
const TINT_HOVER := Color(1.16, 1.12, 1.1)
const TINT_FOCUS := Color(1.7, 1.7, 1.85, 0.5)  ## Fokus: heller Schimmer über dem Knopf
const TINT_DISABLED := Color(0.5, 0.5, 0.55)
const TINT_DEAD := Color(0.55, 0.5, 0.5)
const TINT_NIGHT := Color(0.78, 0.86, 1.12)
const TINT_DAY := Color(1.12, 1.04, 0.9)

static var _cache: Dictionary = {}


static func texture(part: String) -> Texture2D:
	if not _cache.has(part):
		var path := ROOT + part + ".webp"
		_cache[part] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[part]


## Knopfleiste; `state` ist `normal`, `gedrueckt` oder `aktiv`.
static func button_box(state: String, tint: Color = Color.WHITE) -> SkinBarBox:
	var box := SkinBarBox.make(texture("knopf_" + state), BUTTON_END, BUTTON_FIT_HEIGHT, tint)
	box.max_height = BUTTON_MAX_HEIGHT
	return box


static func row_box(tint: Color = Color.WHITE) -> SkinBarBox:
	return SkinBarBox.make(texture("listenzeile"), ROW_END, ROW_FIT_HEIGHT, tint)

static func input_box(tint: Color = Color.WHITE) -> SkinBarBox:
	return SkinBarBox.make(texture("eingabefeld"), INPUT_END, INPUT_FIT_HEIGHT, tint)


static func plaque_box(tint: Color = Color.WHITE) -> SkinBarBox:
	return SkinBarBox.make(texture("plakette"), PLAQUE_END, PLAQUE_FIT_HEIGHT, tint)


static func divider_box(tint: Color = Color.WHITE) -> SkinBarBox:
	return SkinBarBox.make(texture("trennlinie"), DIVIDER_END, DIVIDER_FIT_HEIGHT, tint)


## Senkrechte Lasche: Bild skaliert mit der Rechteckbreite (`fit_width` Bildpixel), obere und untere Dornen bleiben unverzerrt, die Mitte wird gedehnt.
static func side_tab_box(tint: Color = Color.WHITE, fit_width: float = SIDE_TAB_FIT_WIDTH) -> StyleBox:
	var box := _SideTabBox.new()
	box.texture = texture("randlasche")
	box.tint = tint
	box.fit_width = fit_width
	return box


## Nachtleiste mit Mittelspange (wird von der Box selbst mittig gezeichnet, nicht gedehnt).
static func night_bar_box(tint: Color = Color.WHITE, fit_height: float = NIGHT_BAR_FIT_HEIGHT) -> SkinBarBox:
	var box := _NightBarBox.new()
	box.texture = texture("nachtleiste")
	box.clasp = texture("nachtleiste_spange")
	box.end_width = NIGHT_BAR_END
	box.fit_height = fit_height
	box.tint = tint
	return box


static func edge_knob() -> Texture2D:
	return texture("randknopf")


static func die_face() -> Texture2D:
	return texture("wuerfel")


## Porträtrahmen ohne Nummernsockel; Porträt unter dem Rahmen mit `SEAT_HOLE_CENTER` und `SEAT_PORTRAIT_RADIUS` einsetzen.
static func seat_frame() -> Texture2D:
	return texture("sitzrahmen")


## Kleines Bundzeichen am Ring; `kind` ist `lovers`/`liebende` oder `rivals`/`rivalen`, sonst null.
static func bond_small(kind: String) -> Texture2D:
	match kind:
		"lovers", "liebende":
			return texture("bund_liebende_klein")
		"rivals", "rivalen":
			return texture("bund_rivalen_klein")
	return null


static func window_box(tint: Color = Color.WHITE, small: bool = false) -> SkinWindowBox:
	var scale := FRAME_SCALE_SMALL if small else FRAME_SCALE
	var box := SkinWindowBox.make(texture("tafel_grund"), texture("rahmen"), FRAME_MARGINS, scale, tint)
	box.ground_inset = FRAME_GROUND_INSET * scale
	return box


## Rubinstein für Hauptknöpfe, auf `STONE_HEIGHT` skaliert (die drei Zustände haben unterschiedliche Bildmaße); null, wenn das Bild fehlt.
static func stone(state: String) -> Texture2D:
	return _scaled("stone_" + state, "stein_" + state, STONE_HEIGHT)


## Drehknopf-Schalter, auf Bediengröße skaliert.
static func switch_icon(on: bool) -> Texture2D:
	var part := "schalter_an" if on else "schalter_aus"
	return _scaled("switch_" + part, part, SWITCH_HEIGHT)


static func _scaled(key: String, part: String, height: int) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var source := texture(part)
	var result: Texture2D = null
	if source != null:
		var image := source.get_image()
		if image != null:
			if image.is_compressed():
				image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			image.resize(maxi(1, roundi(image.get_width() * float(height) / image.get_height())), height, Image.INTERPOLATE_LANCZOS)
			result = ImageTexture.create_from_image(image)
	_cache[key] = result
	return result


class _NightBarBox extends SkinBarBox:
	var clasp: Texture2D = null

	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		super._draw(to_canvas_item, rect)
		if clasp == null or texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return
		var scale := rect.size.y / fit_height
		var size := clasp.get_size() * scale
		var origin := Vector2(rect.position.x + rect.size.x * SkinArt.NIGHT_CLASP_MID - size.x * 0.5, rect.position.y + (rect.size.y - size.y) * 0.5)
		RenderingServer.canvas_item_add_texture_rect(to_canvas_item, Rect2(origin, size), clasp.get_rid(), false, tint)


class _SideTabBox extends StyleBox:
	var texture: Texture2D = null
	var tint: Color = Color.WHITE
	var fit_width: float = 220.0

	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return
		var tex_size := texture.get_size()
		var scale := rect.size.x / fit_width
		var w := tex_size.x * scale
		var left := rect.position.x + (rect.size.x - w) * 0.5
		var end := SkinArt.SIDE_TAB_END * scale
		if end * 2.0 > rect.size.y:
			end = rect.size.y * 0.5
		var src_end := end / scale
		var rid := texture.get_rid()
		var top := rect.position.y
		var bottom := rect.end.y
		RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(left, top, w, end), rid, Rect2(0.0, 0.0, tex_size.x, src_end), tint)
		RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(left, bottom - end, w, end), rid, Rect2(0.0, tex_size.y - src_end, tex_size.x, src_end), tint)
		if bottom - top - end * 2.0 > 0.0:
			RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(left, top + end, w, bottom - top - end * 2.0), rid, Rect2(0.0, src_end, tex_size.x, tex_size.y - src_end * 2.0), tint)
