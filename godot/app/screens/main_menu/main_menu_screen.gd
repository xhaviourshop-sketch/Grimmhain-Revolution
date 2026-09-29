class_name MainMenuScreen
extends BaseScreen
## Hauptmenü: Neue Partie, Fortsetzen, Cockpit, Rollenlexikon, Einstellungen; Beenden nur auf Desktop,
## räumlich abgesetzt von den übrigen Aktionen.

@onready var _column: VBoxContainer = %Column
@onready var _new_game: GrimmButton = %NewGameButton
@onready var _quit: GrimmButton = %QuitButton


func _setup() -> void:
	_column.custom_minimum_size.x = ThemeTokens.MENU_COLUMN_WIDTH
	_new_game.pressed.connect(navigate_requested.emit.bind(ScreenIds.NEW_GAME))
	(%ContinueButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.CONTINUE))
	(%CockpitButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.COCKPIT))
	(%LexiconButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.LEXICON))
	(%SettingsButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.SETTINGS))
	_quit.visible = AppPlatform.can_quit_from_menu()
	(%QuitGroup as Control).visible = _quit.visible
	_quit.pressed.connect(quit_requested.emit)


func default_focus() -> Control:
	return _new_game
