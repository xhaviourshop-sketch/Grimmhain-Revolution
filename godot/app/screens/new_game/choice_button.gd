class_name ChoiceButton
extends GrimmButton
## Umschalter im Hain-Stil (Wahl zwischen zwei oder mehr Möglichkeiten in einer ButtonGroup): die Grafik kommt aus dem Theme
## (`SecondaryButtonToggle`: ruhig = dunkler Dornenknopf, gewählt = aktiv-Zustand der gemalten Haut). Zusätzlich trägt die gewählte
## Möglichkeit ein Häkchen links, die Wahl hängt also nie nur an der Farbe. Kein eigenes Rot, keine eigene Fläche.
## Verbinden über `toggled`, nicht `pressed` (Tests drücken Umschalter über `button_pressed`).

const CHECK_X := 30.0  ## Mitte des Häkchens vom linken Rand (liegt auf der Dornenspitze, der Text bleibt rechts davon)


var min_width: float = ThemeTokens.BUTTON_PRIMARY_MIN_WIDTH  ## schmale Reiter setzen weniger
var fit_width: bool = false  ## Breite folgt dem Text (Reiter in der Kopfzeile), nie schmaler als `min_width`


func _init() -> void:
	toggle_mode = true
	kind = Kind.SECONDARY  # übernimmt die Toggle-Variation des Themes
	wrap = false
	clip_text = true
	_apply_size()


func _ready() -> void:
	super._ready()  # setzt die Größe der Knopfart zurück
	_apply_size()


func refresh_text() -> void:
	super.refresh_text()
	if fit_width and is_node_ready():
		_apply_size()


func _apply_size() -> void:
	var width := min_width
	if fit_width and text != "":
		var type := theme_type_variation if theme_type_variation != &"" else &"Button"
		var inset := get_theme_stylebox(&"normal", type).get_minimum_size().x
		width = maxf(width, get_theme_font(&"font", type).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size(&"font_size", type)).x + inset * 0.85 + CHECK_X * 1.2)
	custom_minimum_size = Vector2(width, ThemeTokens.BUTTON_SECONDARY_HEIGHT)


func _draw() -> void:
	if not button_pressed:
		return
	var c := Vector2(CHECK_X, size.y * 0.5)
	draw_polyline(PackedVector2Array([c + Vector2(-7.0, 0.0), c + Vector2(-2.0, 5.5), c + Vector2(8.0, -6.0)]), ThemeTokens.MOON_SILVER_BRIGHT, 3.0, true)
