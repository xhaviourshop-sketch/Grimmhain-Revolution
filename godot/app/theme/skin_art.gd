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
