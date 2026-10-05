class_name GroveSkin
extends RefCounted
## Hain-Oberfläche des Nachtbretts (P5): Aktionskarte, Knöpfe und Namensschilder aus den Teilen in `res://assets/ui/hain/`
## (nur intern freigegeben, siehe Asset-Register). Fehlt eine Datei, bleibt der Theme-Stil stehen. Beschriftungen bleiben echter,
## übersetzter Text des Steuerelements; die Bilder tragen keinen Text.

const ROOT := "res://assets/ui/hain/"
const TEAM_TILE_ROOT := "res://assets/ui/"  ## Team-Kachelrahmen `team_tile_village|wolves|solo` (WebP)
const BUTTON_SIZE_PRIMARY := Vector2(214.0, 56.0)
const BUTTON_SIZE_SECONDARY := Vector2(144.0, 56.0)
const BUTTON_TEXT_INSET := 28.0   ## so weit reichen die Spitzen und Wurzeln in den Knopf; der Text bleibt innerhalb
const BACK_SIZE := 56.0           ## Zurück-Platte: Tippfläche mindestens 56
const CARD_INSET := Vector4(28.0, 18.0, 28.0, 18.0)  ## Textabstand der Aktionskarte (links, oben, rechts, unten)
const CARD_INSET_MINI := Vector4(18.0, 12.0, 14.0, 14.0)  ## Mini-Nachtkarte (DA-101): schmaler Rahmen, mehr Platz für Name und Aktion
const TINT_HOVER := Color(1.14, 1.1, 1.06)
const TINT_PRESSED := Color(0.74, 0.72, 0.74)
const TINT_FOCUS := Color(1.22, 1.24, 1.32)
const TINT_DISABLED := Color(0.68, 0.68, 0.72)  ## gesperrter Knopf: dunkle Nebenaktionsfläche, nur leicht gedämpft
const TEXT_DISABLED := Color("#c3c6ce")        ## hellgraue Schrift auf dem gesperrten Knopf: lesbar, aber erkennbar inaktiv
const TINT_SEAT_SILVER := Color(0.9, 0.92, 0.97)  ## dämpft das helle Silber, damit 24 Ringe ruhig wirken

static var _cache: Dictionary = {}


static func texture(part: String) -> Texture2D:
	if _cache.has(part):
		return _cache[part]
	var path := TEAM_TILE_ROOT + part + ".webp" if part.begins_with("team_tile_") else ROOT + part + ".png"
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_cache[part] = tex
	return tex


## Rahmen der Aktionskarte; null, wenn das Bild fehlt.
static func card_box(inset: Vector4 = CARD_INSET) -> StyleBox:
	var tex := texture("card_frame")
	if tex == null:
		return null
	var box := GroveStyleBox.make(tex, GroveArtData.CARD_FRAME_MARGINS)
	box.content_margin_left = inset.x
	box.content_margin_top = inset.y
	box.content_margin_right = inset.z
	box.content_margin_bottom = inset.w
	return box


## Namensschild (kurz, ohne Spitzen); der Aufrufer zeichnet es mit `draw_style_box`.
static func plate_box() -> GroveStyleBox:
	var tex := texture("name_plate_short")
	return GroveStyleBox.make(tex, GroveArtData.NAME_PLATE_SHORT_MARGINS) if tex != null else null


## Senkrechte Lasche (Protokoll, Optionen): Enden geschützt, Mitte dehnbar.
static func side_tab_box(tint: Color = Color.WHITE) -> GroveStyleBox:
	var tex := texture("side_tab")
	return GroveStyleBox.make(tex, GroveArtData.SIDE_TAB_MARGINS, tint) if tex != null else null


## Nachtleiste: Enden und Mittelspange geschützt; `with_clasp` false (Chip) lässt die Spange weg.
static func night_bar_box(with_clasp: bool = true) -> GroveStyleBox:
	var tex := texture("night_bar")
	if tex == null:
		return null
	var box := GroveStyleBox.make(tex, GroveArtData.NIGHT_BAR_MARGINS)
	box.clasp = GroveArtData.NIGHT_BAR_CLASP
	box.with_clasp = with_clasp
	return box


## Phasen-Kartusche (Mond links, Mitte dehnbar). Der Innenabstand hält den Text zwischen den Enden.
static func cartouche_box() -> GroveStyleBox:
	var tex := texture("cartouche")
	if tex == null:
		return null
	var box := GroveStyleBox.make(tex, GroveArtData.CARTOUCHE_MARGINS)
	box.content_margin_left = GroveArtData.CARTOUCHE_MARGINS.x / GroveArtData.TEXTURE_SCALE - 10.0
	box.content_margin_right = GroveArtData.CARTOUCHE_MARGINS.z / GroveArtData.TEXTURE_SCALE - 14.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	return box


## Quadratische Platte (Zurück), Ecken geschützt.
static func back_plate_box(tint: Color = Color.WHITE) -> GroveStyleBox:
	var tex := texture("back_plate")
	return GroveStyleBox.make(tex, GroveArtData.BACK_PLATE_MARGINS, tint) if tex != null else null


## Zurück-Knopf im Hain-Stil: Platte mit Pfeil; der Text (Übersetzung) bleibt für Bedienungshilfe und Tooltip, wird aber nicht gezeichnet.
static func skin_back_button(button: GrimmButton) -> void:
	var tex := texture("back_plate")
	if tex == null:
		return
	var tints := {"normal": Color.WHITE, "hover": TINT_HOVER, "pressed": TINT_PRESSED, "hover_pressed": TINT_PRESSED, "disabled": TINT_DISABLED}
	for state: String in tints:
		var box := back_plate_box(tints[state])
		box.native_height = BACK_SIZE
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.focus_entered.connect(func() -> void: button.self_modulate = TINT_FOCUS)
	button.focus_exited.connect(func() -> void: button.self_modulate = Color.WHITE)
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color, ThemeTokens.INVISIBLE)
	button.tooltip_text = button.tr(button.text_key) if button.text_key != "" else button.text
	button.clip_text = true
	button.custom_minimum_size = Vector2(BACK_SIZE, BACK_SIZE)
	var arrow := Control.new()
	arrow.name = "BackArrow"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	arrow.draw.connect(func() -> void: _draw_back_arrow(arrow, button))
	button.add_child(arrow)


static func _draw_back_arrow(canvas: Control, button: GrimmButton) -> void:
	var c := canvas.size * 0.5
	var color := ThemeTokens.MOON_SILVER_DIM if button.disabled else (ThemeTokens.MOON_SILVER_BRIGHT if (button.is_hovered() or button.has_focus()) else ThemeTokens.MOON_SILVER)
	canvas.draw_polyline(PackedVector2Array([c + Vector2(4.0, -11.0), c + Vector2(-7.0, 0.0), c + Vector2(4.0, 11.0)]), color, 3.5, true)
	canvas.draw_line(c + Vector2(-7.0, 0.0), c + Vector2(11.0, 0.0), color, 3.5, true)


## Knopf eines Hain-Bildschirms (Feedback 8): die Grafik kommt aus dem Theme; hier nur Hauptaktion (Rubinstein) und Mindestgröße.
static func skin_button(button: GrimmButton, primary: bool) -> void:
	button.main = button.main or primary
	button.custom_minimum_size = BUTTON_SIZE_PRIMARY if primary else Vector2(maxf(button.custom_minimum_size.x, BUTTON_SIZE_SECONDARY.x), BUTTON_SIZE_SECONDARY.y)
