class_name GrimmLabel
extends Label
## Beschriftung nur über Übersetzungsschlüssel. `format_values` füllt Platzhalter wie
## `{version}`. Bricht Wörter um statt abzuschneiden und aktualisiert sich beim Sprachwechsel.

@export var text_key: String = "":
	set(value):
		text_key = value
		refresh_text()
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
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _ready() -> void:
	refresh_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_text()


func refresh_text() -> void:
	if text_key == "":
		return
	var translated := tr(text_key)
	text = translated.format(format_values) if not format_values.is_empty() else translated
