class_name GrimmButton
extends Button
## Wiederverwendbarer Button: Text nur über Übersetzungsschlüssel, Art (primär, sekundär,
## Gefahr) über Theme-Variation, Mindestgröße aus ThemeTokens, immer fokussierbar.
## `wrap` (Standard an) bricht lange Beschriftungen um statt sie abzuschneiden; nur für
## Buttons, deren Breite der Container vorgibt. Buttons mit Inhaltsbreite (Kopfzeile) ohne.

enum Kind { PRIMARY, SECONDARY, DANGER }

const _VARIATIONS := {
	Kind.PRIMARY: &"PrimaryButton",
	Kind.SECONDARY: &"SecondaryButton",
	Kind.DANGER: &"DangerButton",
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
		text = tr(text_key)


func _apply_kind() -> void:
	theme_type_variation = _VARIATIONS[kind]
	var height := ThemeTokens.BUTTON_SECONDARY_HEIGHT
	var width := ThemeTokens.TOUCH_MIN
	if kind == Kind.PRIMARY:
		height = ThemeTokens.BUTTON_PRIMARY_HEIGHT
		width = ThemeTokens.BUTTON_PRIMARY_MIN_WIDTH
	custom_minimum_size = Vector2(width, height)
