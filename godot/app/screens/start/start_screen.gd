class_name StartScreen
extends BaseScreen
## Startbildschirm: lebendiger Nachthintergrund (StartBackdrop), Logo, „Eintreten“ als Hain-Knopf mit pulsierendem Glühen, Version aus
## zentraler Quelle. Beim Antippen zieht der Nebel kurz zu (0,6 s), dann folgt das Hauptmenü; bei reduzierter Bewegung sofort.

const LOGO := "res://assets/start/start-logo.webp"
const LOGO_MIN_WIDTH := 620.0
const FOG_SECONDS := 0.6

@onready var _column: VBoxContainer = %Column
@onready var _enter: GrimmButton = %EnterButton
@onready var _version: GrimmLabel = %VersionLabel

var _backdrop: StartBackdrop = null


func _setup() -> void:
	_column.custom_minimum_size.x = ThemeTokens.MENU_COLUMN_WIDTH
	_version.format_values = {"version": AppPlatform.app_version()}
	_backdrop = StartBackdrop.new(StartBackdrop.Mode.START)
	_backdrop.animated = _animated()
	add_child(_backdrop)
	move_child(_backdrop, 0)
	var logo := TextureRect.new()
	logo.name = "LogoImage"
	logo.texture = load(LOGO) as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(LOGO_MIN_WIDTH, LOGO_MIN_WIDTH * logo.texture.get_height() / logo.texture.get_width())
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.tooltip_text = tr("app.title")
	_column.add_child(logo)
	_column.move_child(logo, 0)
	var height := _enter.custom_minimum_size.y
	GroveSkin.skin_button(_enter, true)
	_enter.custom_minimum_size = Vector2(maxf(_enter.custom_minimum_size.x, 300.0), maxf(_enter.custom_minimum_size.y, height))
	var inset_y := maxf(0.0, (_enter.custom_minimum_size.y - 40.0) * 0.5)
	SelectionGlow.set_on(_enter, "button_primary", GroveArtData.BUTTON_PRIMARY_MARGINS, true, Vector4(0.0, inset_y, 0.0, inset_y))
	_enter.pressed.connect(_on_enter)


func default_focus() -> Control:
	return _enter


func _animated() -> bool:
	return context == null or not context.settings.reduced_motion


func _on_enter() -> void:
	_enter.disabled = true
	await _backdrop.fog_close(FOG_SECONDS)
	StartBackdrop.fog_open_pending = true
	navigate_requested.emit(ScreenIds.MAIN_MENU)
