class_name GrimmLabel
extends Label
## Beschriftung nur über Übersetzungsschlüssel. `format_values` füllt Platzhalter wie
## `{version}`; Werte vom Typ StringName gelten als Übersetzungsschlüssel (z. B. Rollenname).
## Bricht Wörter um statt abzuschneiden und aktualisiert sich beim Sprachwechsel.
## Ohne Schlüssel ist der Text leer (z. B. eine Meldungszeile ohne aktuelle Meldung).

@export var text_key: String = "":
	set(value):
		text_key = value
		refresh_text()
@export var wrap: bool = true:
	set(value):
		wrap = value
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if value else TextServer.AUTOWRAP_OFF

var suffix: String = "":  ## wird ohne Übersetzung an den Text gehängt (z. B. Namen in Klammern im Kartentitel)
	set(value):
		suffix = value
		refresh_text()
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
		text = ""
		return
	var translated := tr(text_key)
	text = (translated.format(translated_values(self, format_values)) if not format_values.is_empty() else translated) + suffix


## Platzhalterwerte mit übersetzten Schlüsseln (StringName) für `String.format`.
static func translated_values(node: Node, values: Dictionary) -> Dictionary:
	var out := {}
	for k: Variant in values:
		var v: Variant = values[k]
		out[k] = node.tr(String(v)) if v is StringName else v
	return out
