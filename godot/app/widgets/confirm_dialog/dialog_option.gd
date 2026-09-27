class_name DialogOption
extends RefCounted
## Eine Auswahloption in ConfirmDialog: Button mit Übersetzungsschlüssel und Platzhaltern,
## eindeutiger Knotenname (für Tests und Fokus) und Rückruf. `heading` = nur Zwischenüberschrift.

var node_name: String = ""
var text_key: String = ""
var values: Dictionary = {}
var on_select: Callable = Callable()
var heading: bool = false


static func create(p_node_name: String, p_text_key: String, p_values: Dictionary, p_on_select: Callable) -> DialogOption:
	var o := DialogOption.new()
	o.node_name = p_node_name
	o.text_key = p_text_key
	o.values = p_values
	o.on_select = p_on_select
	return o


static func header(p_text_key: String) -> DialogOption:
	var o := DialogOption.new()
	o.text_key = p_text_key
	o.heading = true
	return o
