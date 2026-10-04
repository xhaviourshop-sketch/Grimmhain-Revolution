class_name MainMenuScreen
extends BaseScreen
## Hauptmenü: Neue Partie, Fortsetzen, Cockpit, Rollenlexikon, Regelbuch, Partiehistorie, Einstellungen; Beenden nur auf Desktop,
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
	(%RulebookButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.RULEBOOK))
	(%HistoryButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.HISTORY))
	(%SettingsButton as GrimmButton).pressed.connect(navigate_requested.emit.bind(ScreenIds.SETTINGS))
	_quit.visible = AppPlatform.can_quit_from_menu()
	(%QuitGroup as Control).visible = _quit.visible
	_quit.pressed.connect(quit_requested.emit)
	for node: Node in find_children("*", "GrimmButton", true, false):
		var button := node as GrimmButton
		var height := button.custom_minimum_size.y  # Tippfläche bleibt (Hauptaktion 64), der Rahmen wird mittig gezeichnet
		GroveSkin.skin_button(button, button == _new_game)
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, height)


func default_focus() -> Control:
	return _new_game
