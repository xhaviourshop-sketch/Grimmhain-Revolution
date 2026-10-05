class_name FitLabel
extends GrimmLabel
## Text so groß wie möglich und passend in seinen Platz (Feedback 8, nie scrollen): Die Schriftgröße sinkt von `max_font_size`
## (0 = Größe aus dem Theme) bis `min_font_size`, bis der Text in die Breite (und bei Umbruch auch in die Höhe) des Labels passt.
## Keine „...“-Kürzung. Ohne Umbruch (Standard, für Titel und Knopftexte) ist der Text eine Zeile; mit `wrap` bricht er an Wortgrenzen um.
## Das Label gibt seinen Platz vom Container vor (Mindestbreite 0), damit es schrumpfen kann statt den Container zu weiten.

@export var min_font_size: int = 12:
	set(value):
		min_font_size = value
		_fit()
@export var max_font_size: int = 0:
	set(value):
		max_font_size = value
		_fit()
var _fitting: bool = false


func _init() -> void:
	wrap = false  ## Umbruch nur auf Wunsch (`wrap = true`)
	clip_text = true  ## nur damit die Mindestbreite nicht vom Text abhängt; es wird nichts abgeschnitten, weil die Schrift schrumpft
	text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	resized.connect(_fit)


func _ready() -> void:
	super._ready()
	_fit()


func refresh_text() -> void:
	super.refresh_text()
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit()


## Größte Schriftgröße in [min, max], bei der `text` in `box` passt (ohne Umbruch: Breite; mit Umbruch: Höhe bei dieser Breite).
static func best_size(font: Font, text: String, box: Vector2, max_size: int, min_size: int, wrapped: bool) -> int:
	if box.x <= 0.0 or text == "":
		return max_size
	var low := mini(min_size, max_size)
	var high := max_size
	while low < high:
		var mid := (low + high + 1) / 2
		var fits: bool
		if wrapped:
			fits = box.y <= 0.0 or font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, box.x, mid).y <= box.y
		else:
			fits = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, mid).x <= box.x
		if fits:
			low = mid
		else:
			high = mid - 1
	return low


func _fit() -> void:
	if _fitting or not is_inside_tree():
		return
	_fitting = true
	# Ohne Typangabe würde die Suche den eigenen Override finden; mit Typ liefert sie die Größe aus dem Theme.
	var type := theme_type_variation if theme_type_variation != &"" else &"Label"
	var limit := max_font_size if max_font_size > 0 else get_theme_font_size(&"font_size", type)
	var chosen := best_size(get_theme_font(&"font", type), text, size, limit, min_font_size, autowrap_mode != TextServer.AUTOWRAP_OFF)
	if not has_theme_font_size_override(&"font_size") or get_theme_font_size(&"font_size") != chosen:
		add_theme_font_size_override(&"font_size", chosen)
	_fitting = false
