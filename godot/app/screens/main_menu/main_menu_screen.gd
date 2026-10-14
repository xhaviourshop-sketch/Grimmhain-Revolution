class_name MainMenuScreen
extends BaseScreen
## Hauptmenü: Neue Partie, Fortsetzen, Cockpit, Rollenlexikon, Regelbuch, Partiehistorie, Einstellungen; Beenden nur auf Desktop,
## räumlich abgesetzt von den übrigen Aktionen.

@onready var _column: VBoxContainer = %Column
@onready var _new_game: GrimmButton = %NewGameButton
@onready var _quit: GrimmButton = %QuitButton

const LOGO := "res://assets/brand/wortmarke.webp"
const LOGO_HEIGHT := 44.0
const LOGO_SHADE_ALPHA := 0.75
const LOGO_SHADE_SPREAD := Vector2(110.0, 60.0)


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
	var shade := _logo_shade()
	backdrop.add_child(shade)  # im beschneidenden Hintergrund, damit der Rand über den Bildschirm hinausragen darf
	logo.item_rect_changed.connect(_place_shade.bind(logo, shade))
	_place_shade.call_deferred(logo, shade)
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
	_dim_unavailable()
	_quit.visible = AppPlatform.can_quit_from_menu()
	(%QuitGroup as Control).visible = _quit.visible
	($Center/Column/Actions as VBoxContainer).add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	(%QuitGroup as VBoxContainer).add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)  # enger, damit das Menü mit Erklärsatz in 1024×768 passt
	_quit.pressed.connect(quit_requested.emit)
	for node: Node in find_children("*", "GrimmButton", true, false):
		var button := node as GrimmButton
		var height := button.custom_minimum_size.y  # Tippfläche bleibt (Hauptaktion 64), der Rahmen wird mittig gezeichnet
		GroveSkin.skin_button(button, button == _new_game)
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, height)


## „Partie fortsetzen“ ohne gespeicherte Partie und „Spielleiter-Cockpit“ ohne laufende Partie sind ausgegraut; ein Satz sagt, warum.
func _dim_unavailable() -> void:
	if context == null:
		return
	var resume := %ContinueButton as GrimmButton
	var cockpit := %CockpitButton as GrimmButton
	resume.disabled = context.saves.list().is_empty()
	cockpit.disabled = not bool(context.session.view().get("has_game", false))
	var hint_key := ""
	if resume.disabled and cockpit.disabled:
		hint_key = "ui.menu.hint.none"
	elif resume.disabled:
		hint_key = "ui.menu.hint.no_save"
	elif cockpit.disabled:
		hint_key = "ui.menu.hint.no_game"
	if hint_key == "":
		return
	var hint := GrimmLabel.new()
	hint.name = "MenuHintLabel"
	hint.text_key = hint_key
	hint.theme_type_variation = &"MutedLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cockpit.get_parent().add_child(hint)
	cockpit.get_parent().move_child(hint, cockpit.get_index() + 1)


## Weiche dunkle Vignette hinter dem Logo, damit es auch über dem hellen Mond lesbar bleibt.
func _logo_shade() -> TextureRect:
	var gradient := Gradient.new()
	var dark := ThemeTokens.START_SHADE
	var clear := dark
	clear.a = 0.0
	dark.a = LOGO_SHADE_ALPHA
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([dark, dark, clear])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 128
	var shade := TextureRect.new()
	shade.name = "LogoShade"
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shade


func _place_shade(logo: Control, shade: Control) -> void:
	if not is_instance_valid(logo) or not is_instance_valid(shade) or not shade.is_inside_tree():
		return
	var rect := logo.get_global_rect().grow_individual(LOGO_SHADE_SPREAD.x, LOGO_SHADE_SPREAD.y, LOGO_SHADE_SPREAD.x, LOGO_SHADE_SPREAD.y)
	shade.global_position = rect.position
	shade.size = rect.size


func default_focus() -> Control:
	return _new_game
