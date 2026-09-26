class_name GrimmToggle
extends CheckButton
## Umschalter mit übersetzter Beschriftung. Der Zustand ist über die Schalterform sichtbar,
## nicht nur über Farbe. Mindesthöhe wie ein Sekundärbutton, immer fokussierbar.

@export var text_key: String = "":
	set(value):
		text_key = value
		refresh_text()


func _init() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	focus_mode = Control.FOCUS_ALL
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.BUTTON_SECONDARY_HEIGHT)


func _ready() -> void:
	refresh_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_text()


func refresh_text() -> void:
	if text_key != "":
		text = tr(text_key)
