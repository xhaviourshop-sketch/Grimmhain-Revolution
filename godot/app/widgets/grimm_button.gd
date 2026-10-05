class_name GrimmButton
extends Button
## Wiederverwendbarer Button: Text nur über Übersetzungsschlüssel, Art (primär, sekundär,
## Gefahr) über Theme-Variation, Mindestgröße aus ThemeTokens, immer fokussierbar.
## `wrap` (Standard an) bricht lange Beschriftungen um statt sie abzuschneiden; nur für
## Buttons, deren Breite der Container vorgibt. Buttons mit Inhaltsbreite (Kopfzeile) ohne.
## `format_values` füllt Platzhalter wie `{name}` (z. B. Auswahloptionen eines Dialogs); Werte vom
## Typ StringName gelten als Übersetzungsschlüssel.
## `main` (Hauptknopf: Spiel starten, Hinrichten, Weiter) trägt den roten Mittelstein klein links neben dem Text; er glimmt beim Drücken
## und glüht, wenn der Knopf gewählt ist. Primär- und Gefahr-Knöpfe sind Hauptknöpfe; normale Knöpfe tragen keinen Stein.
## Alle Knopfgrafiken kommen aus dem Theme (Variation je Art, für Umschalter der „…Toggle“-Zwilling).

const MIN_FONT := 14

enum Kind { PRIMARY, SECONDARY, DANGER, COMPACT }

const _VARIATIONS := {
	Kind.PRIMARY: &"PrimaryButton",
	Kind.SECONDARY: &"SecondaryButton",
	Kind.DANGER: &"DangerButton",
	Kind.COMPACT: &"CompactButton",  ## kleinere Schrift für Listenzeilen, weiterhin 48 hoch
}

@export var text_key: String = "":
	set(value):
		text_key = value
		refresh_text()
@export var kind: Kind = Kind.SECONDARY:
	set(value):
		kind = value
		_apply_kind()
@export var wrap: bool = true:
	set(value):
		wrap = value
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if value else TextServer.AUTOWRAP_OFF

## Hauptknopf mit Rubinstein; wird von `kind` (Primär, Gefahr) vorbelegt und kann danach gesetzt werden.
@export var main: bool = false:
	set(value):
		main = value
		_refresh_stone()

var _stone_shown: bool = false
var _fit_queued: bool = false
var _fit_changes: int = 0  ## Schutz: Schriftanpassung ändert sich höchstens wenige Male, bis neuer Text kommt
var format_values: Dictionary = {}:
	set(value):
		format_values = value
		refresh_text()


func _init() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	focus_mode = Control.FOCUS_ALL
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_kind()


func _ready() -> void:
	if toggle_mode:
		_apply_kind(false)
	if not button_down.is_connected(_refresh_stone):
		button_down.connect(_refresh_stone)
		button_up.connect(_refresh_stone)
		toggled.connect(_refresh_stone.unbind(1))
	refresh_text()
	_refresh_stone()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_text()
	elif what == NOTIFICATION_RESIZED and not _fit_queued:
		_fit_queued = true
		_fit_font.call_deferred()  # erst wenn der Container fertig bemessen hat


func refresh_text() -> void:
	if text_key != "":
		var translated := tr(text_key)
		var new_text := translated.format(GrimmLabel.translated_values(self, format_values)) if not format_values.is_empty() else translated
		if new_text != text and has_meta(&"fit_font"):  # neuer Text: wieder von der Themegröße aus anpassen
			remove_meta(&"fit_font")
			remove_theme_font_size_override(&"font_size")
		text = new_text
		_fit_changes = 0
		if not _fit_queued:
			_fit_queued = true
			_fit_font.call_deferred()


func _apply_kind(reset_main: bool = true) -> void:
	theme_type_variation = StringName(String(_VARIATIONS[kind]) + ("Toggle" if toggle_mode else ""))
	if reset_main:
		main = kind == Kind.PRIMARY or kind == Kind.DANGER
	var height := ThemeTokens.BUTTON_SECONDARY_HEIGHT
	var width := ThemeTokens.TOUCH_MIN
	if kind == Kind.PRIMARY:
		height = ThemeTokens.BUTTON_PRIMARY_HEIGHT
		width = ThemeTokens.BUTTON_PRIMARY_MIN_WIDTH
	elif kind == Kind.COMPACT:
		height = ThemeTokens.TOUCH_MIN
	custom_minimum_size = Vector2(width, height)


## Stein je Zustand: Ruhe, gedrückt (glimmt schwach), gewählt (glüht).
func _refresh_stone() -> void:
	if not main:
		if _stone_shown:
			icon = null
			_stone_shown = false
		return
	_stone_shown = true
	var state := "normal"
	if toggle_mode and button_pressed:
		state = "aktiv"
	elif get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED:
		state = "gedrueckt"
	icon = SkinArt.stone(state)
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


## Kein Wort wird mitten im Wort umgebrochen: Passt das längste Wort nicht in die Breite zwischen den Dornen-Enden, sinkt die Schrift
## (bis `MIN_FONT`); reicht auch das nicht, wächst die Mindestbreite. Nur für den Grundtyp mit Umbruch (Unterklassen und der Lava-Knopf
## zeichnen und bemessen selbst) und nur, solange niemand eine eigene Schriftgröße gesetzt hat. Läuft verzögert (fertige Breite) und
## verkleinert höchstens viermal je Text, damit sich Layout und Schrift nicht aufschaukeln.
func _fit_font() -> void:
	_fit_queued = false
	if not is_inside_tree() or autowrap_mode == TextServer.AUTOWRAP_OFF or size.x <= 0.0 or text == "" or (get_script() as Script).get_global_name() != &"GrimmButton":
		return
	if has_theme_font_size_override(&"font_size") and not has_meta(&"fit_font"):
		return
	var type := theme_type_variation if theme_type_variation != &"" else &"Button"
	var font := get_theme_font(&"font", type)
	var base := get_theme_font_size(&"font_size", type)
	var room := size.x - get_theme_stylebox(&"normal").get_minimum_size().x
	if icon != null:
		room -= icon.get_width() + get_theme_constant(&"h_separation", type)
	var longest := ""
	for word: String in text.split(" "):
		if word.length() > longest.length():
			longest = word
	var chosen := FitLabel.best_size(font, longest, Vector2(room, 0.0), base, MIN_FONT, false)
	var current := get_theme_font_size(&"font_size")
	if chosen == current:
		return
	if chosen < current and _fit_changes >= 4:
		return
	if chosen < base:
		_fit_changes += 1
		set_meta(&"fit_font", true)
		add_theme_font_size_override(&"font_size", chosen)
		var needed := font.get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, chosen).x + size.x - room
		if needed > size.x:
			custom_minimum_size.x = maxf(custom_minimum_size.x, ceilf(needed))
	elif has_meta(&"fit_font"):
		remove_meta(&"fit_font")
		remove_theme_font_size_override(&"font_size")
