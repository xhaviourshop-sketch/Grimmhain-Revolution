class_name GroveSkin
extends RefCounted
## Hain-Oberfläche des Nachtbretts (P5): Aktionskarte, Knöpfe und Namensschilder aus den Teilen in `res://assets/ui/hain/`
## (nur intern freigegeben, siehe Asset-Register). Fehlt eine Datei, bleibt der Theme-Stil stehen. Beschriftungen bleiben echter,
## übersetzter Text des Steuerelements; die Bilder tragen keinen Text.

const ROOT := "res://assets/ui/hain/"
const BUTTON_SIZE_PRIMARY := Vector2(214.0, 56.0)
const BUTTON_SIZE_SECONDARY := Vector2(144.0, 56.0)
const BUTTON_TEXT_INSET := 28.0   ## so weit reichen die Spitzen und Wurzeln in den Knopf; der Text bleibt innerhalb
const CARD_INSET := Vector4(28.0, 24.0, 28.0, 24.0)  ## Textabstand der Aktionskarte (links, oben, rechts, unten)
const TINT_HOVER := Color(1.14, 1.1, 1.06)
const TINT_PRESSED := Color(0.74, 0.72, 0.74)
const TINT_FOCUS := Color(1.3, 1.22, 1.08)
const TINT_DISABLED := Color(0.5, 0.46, 0.48)
const TINT_SEAT_SILVER := Color(0.9, 0.92, 0.97)  ## dämpft das helle Silber, damit 24 Ringe ruhig wirken

static var _cache: Dictionary = {}


static func texture(part: String) -> Texture2D:
	if _cache.has(part):
		return _cache[part]
	var path := ROOT + part + ".png"
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_cache[part] = tex
	return tex


## Rahmen der Aktionskarte; null, wenn das Bild fehlt.
static func card_box() -> StyleBox:
	var tex := texture("card_frame")
	if tex == null:
		return null
	var box := GroveStyleBox.make(tex, GroveArtData.CARD_FRAME_MARGINS)
	box.content_margin_left = CARD_INSET.x
	box.content_margin_top = CARD_INSET.y
	box.content_margin_right = CARD_INSET.z
	box.content_margin_bottom = CARD_INSET.w
	return box


## Namensschild (kurz, ohne Spitzen); der Aufrufer zeichnet es mit `draw_style_box`.
static func plate_box() -> GroveStyleBox:
	var tex := texture("name_plate_short")
	return GroveStyleBox.make(tex, GroveArtData.NAME_PLATE_SHORT_MARGINS) if tex != null else null


## Knopf im Hain-Stil: Hauptaktion (rot) oder Nebenaktion (dunkel). Zustände nur über Tönung.
static func skin_button(button: GrimmButton, primary: bool) -> void:
	var tex := texture("button_primary" if primary else "button_secondary")
	if tex == null:
		return
	var margins := GroveArtData.BUTTON_PRIMARY_MARGINS if primary else GroveArtData.BUTTON_SECONDARY_MARGINS
	var tints := {"normal": Color.WHITE, "hover": TINT_HOVER, "pressed": TINT_PRESSED, "hover_pressed": TINT_PRESSED,
		"focus": TINT_FOCUS, "disabled": TINT_DISABLED}
	for state: String in tints:
		var box := GroveStyleBox.make(tex, margins, tints[state])
		box.native_height = tex.get_height() / GroveArtData.TEXTURE_SCALE
		box.content_margin_left = BUTTON_TEXT_INSET
		box.content_margin_right = BUTTON_TEXT_INSET
		box.content_margin_top = 4.0
		box.content_margin_bottom = 4.0
		button.add_theme_stylebox_override(state, box)
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, ThemeTokens.TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", ThemeTokens.TEXT_DISABLED)
	button.add_theme_font_size_override("font_size", ThemeTokens.FONT_CAPTION)
	button.custom_minimum_size = BUTTON_SIZE_PRIMARY if primary else Vector2(maxf(button.custom_minimum_size.x, BUTTON_SIZE_SECONDARY.x), BUTTON_SIZE_SECONDARY.y)
