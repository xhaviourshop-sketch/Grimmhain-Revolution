class_name MainMenuScreen
extends BaseScreen
## Hauptmenü: Neue Partie, Fortsetzen, Cockpit, Rollenlexikon, Regelbuch, Partiehistorie, Einstellungen; Beenden nur auf Desktop,
## räumlich abgesetzt von den übrigen Aktionen.

@onready var _column: VBoxContainer = %Column
@onready var _new_game: GrimmButton = %NewGameButton
@onready var _quit: GrimmButton = %QuitButton

const LOGO := "res://assets/start/start-logo.webp"
const LOGO_HEIGHT := 84.0


func _setup() -> void:
	var backdrop := StartBackdrop.new(StartBackdrop.Mode.MENU)
	backdrop.animated = context == null or not context.settings.reduced_motion
	add_child(backdrop)
	move_child(backdrop, 0)
	var title := %TitleLabel as Control
	title.visible = false  # statt des Textes steht das Logo (Text bleibt für Bedienungshilfe im Baum)
	var logo := TextureRect.new()
	logo.name = "LogoImage"
	logo.texture = load(LOGO) as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(LOGO_HEIGHT * logo.texture.get_width() / logo.texture.get_height(), LOGO_HEIGHT)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.tooltip_text = tr("app.title")
	title.get_parent().add_child(logo)
	title.get_parent().move_child(logo, 0)
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
