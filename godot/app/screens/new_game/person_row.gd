class_name PersonRow
extends PanelContainer
## Eine Zeile der Spielerliste: sichtbare Listennummer, Name (Nutzerdaten, voller Name im
## Tooltip), Dublettenhinweis als Text, Bearbeiten und Entfernen. Die Personen-ID wird nur
## intern gehalten und nie angezeigt. Meldet Wünsche als Signale; ändert selbst nichts.

signal edit_requested(person_id: int)
signal remove_requested(person_id: int)

var person_id: int = -1
var person_name: String = ""
var number: int = 0

@onready var _number: GrimmLabel = %NumberLabel
@onready var _name: Label = %NameLabel
@onready var _badge: Control = %DuplicateBadge
@onready var _edit: GrimmButton = %EditButton
@onready var _remove: GrimmButton = %RemoveButton


func _ready() -> void:
	_number.custom_minimum_size.x = ThemeTokens.PERSON_NUMBER_WIDTH
	_edit.pressed.connect(func() -> void: edit_requested.emit(person_id))
	_remove.pressed.connect(func() -> void: remove_requested.emit(person_id))


## Übernimmt einen Eintrag aus PlayerSetup.view()["persons"].
func show_person(entry: Dictionary) -> void:
	person_id = int(entry["person_id"])
	person_name = str(entry["name"])
	number = int(entry["number"])
	_number.format_values = {"number": number}
	_name.text = person_name
	_name.tooltip_text = person_name
	_badge.visible = bool(entry["duplicate"])


func edit_button() -> GrimmButton:
	return _edit


func remove_button() -> GrimmButton:
	return _remove
