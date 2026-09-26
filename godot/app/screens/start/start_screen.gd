class_name StartScreen
extends BaseScreen
## Startbildschirm: Titel, Untertitel, Eintreten ins Hauptmenü, Version aus zentraler Quelle.

@onready var _column: VBoxContainer = %Column
@onready var _enter: GrimmButton = %EnterButton
@onready var _version: GrimmLabel = %VersionLabel


func _setup() -> void:
	_column.custom_minimum_size.x = ThemeTokens.MENU_COLUMN_WIDTH
	_version.format_values = {"version": AppPlatform.app_version()}
	_enter.pressed.connect(navigate_requested.emit.bind(ScreenIds.MAIN_MENU))


func default_focus() -> Control:
	return _enter
