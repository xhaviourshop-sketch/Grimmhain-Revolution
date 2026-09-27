class_name GrimmButton
extends Button
## Wiederverwendbarer Button: Text nur über Übersetzungsschlüssel, Art (primär, sekundär,
## Gefahr) über Theme-Variation, Mindestgröße aus ThemeTokens, immer fokussierbar.
## `wrap` (Standard an) bricht lange Beschriftungen um statt sie abzuschneiden; nur für
## Buttons, deren Breite der Container vorgibt. Buttons mit Inhaltsbreite (Kopfzeile) ohne.
## `format_values` füllt Platzhalter wie `{name}` (z. B. Auswahloptionen eines Dialogs).

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
	refresh_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_text()


func refresh_text() -> void:
	if text_key != "":
		var translated := tr(text_key)
		text = translated.format(format_values) if not format_values.is_empty() else translated


func _apply_kind() -> void:
	theme_type_variation = _VARIATIONS[kind]
	var height := ThemeTokens.BUTTON_SECONDARY_HEIGHT
	var width := ThemeTokens.TOUCH_MIN
	if kind == Kind.PRIMARY:
		height = ThemeTokens.BUTTON_PRIMARY_HEIGHT
		width = ThemeTokens.BUTTON_PRIMARY_MIN_WIDTH
	elif kind == Kind.COMPACT:
		height = ThemeTokens.TOUCH_MIN
	custom_minimum_size = Vector2(width, height)
