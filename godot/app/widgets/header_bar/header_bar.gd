class_name HeaderBar
extends PanelContainer
## Kopfzeile jeder Unterseite: Zurück-Button links, Titel daneben, Platz für spätere
## Aktionen rechts (`%Actions`). Meldet Zurück nur als Signal.

signal back_pressed

@export var title_key: String = "":
	set(value):
		title_key = value
		if is_node_ready():
			_title.text_key = value
@export var show_back: bool = true:
	set(value):
		show_back = value
		if is_node_ready():
			_back.visible = value

@onready var _back: GrimmButton = %BackButton
@onready var _title: GrimmLabel = %TitleLabel


func _ready() -> void:
	_title.text_key = title_key
	_back.visible = show_back
	_back.pressed.connect(back_pressed.emit)


func back_button() -> GrimmButton:
	return _back
