class_name DetailPanel
extends PanelContainer
## Detailansicht über dem Cockpit (gezeigte Karte, Hinweiskarte, Ansage, Rollenkarte): Text und Überschriften kommen in
## `content` und scrollen, wenn sie die Fensterhöhe überschreiten; alle Aktionsbuttons kommen in `actions` und bleiben in einem
## festen Bereich darunter immer sichtbar. Die Höhe des Textbereichs folgt dem Inhalt, begrenzt auf die Höhe der Ebene.

var content: VBoxContainer = null
var actions: VBoxContainer = null

var _scroll: ScrollContainer = null
var _column: VBoxContainer = null
var _fit_queued: bool = false


func _init() -> void:
	theme_type_variation = &"ShowPanel"
	custom_minimum_size.x = ThemeTokens.DIALOG_WIDE_WIDTH
	# Grimmhain-Stil (Markus 05.10.2026): dunkler Grund im Eisenrahmen, Ornamente nur an den Ecken (Teil der Aktionskarte).
	var frame := GroveSkin.card_box()
	if frame != null:
		frame.content_margin_left = ThemeTokens.SPACE_XL * 2.0
		frame.content_margin_right = ThemeTokens.SPACE_XL * 2.0
		frame.content_margin_top = ThemeTokens.SPACE_XL * 1.5
		frame.content_margin_bottom = ThemeTokens.SPACE_XL * 1.5
		add_theme_stylebox_override(&"panel", frame)
	_column = VBoxContainer.new()
	_column.theme_type_variation = &"ScreenColumn"
	add_child(_column)
	_scroll = ScrollContainer.new()
	_scroll.name = "DetailScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column.add_child(_scroll)
	content = VBoxContainer.new()
	content.name = "DetailContent"
	content.theme_type_variation = &"ScreenColumn"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(content)
	actions = VBoxContainer.new()
	actions.name = "DetailActions"
	_column.add_child(actions)


func _ready() -> void:
	for b: Node in actions.get_children():  # Knöpfe im Hain-Stil wie auf der Aktionskarte
		if b is GrimmButton:
			GroveSkin.skin_button(b as GrimmButton, (b as GrimmButton).kind == GrimmButton.Kind.PRIMARY)
	content.minimum_size_changed.connect(_queue_fit)
	actions.minimum_size_changed.connect(_queue_fit)
	if get_parent() is Control:
		(get_parent() as Control).resized.connect(_queue_fit)
	_queue_fit()


func _queue_fit() -> void:
	if not _fit_queued:
		_fit_queued = true
		_fit.call_deferred()


## Textbereich so hoch wie sein Inhalt, höchstens so hoch, dass Panel und feste Aktionen in die Ebene passen.
func _fit() -> void:
	_fit_queued = false
	if not is_inside_tree():
		return
	var layer_height := (get_parent() as Control).size.y if get_parent() is Control else 0.0
	if layer_height <= 0.0:
		layer_height = get_viewport_rect().size.y - 2.0 * ThemeTokens.SAFE_MARGIN
	var chrome := get_theme_stylebox(&"panel").get_minimum_size().y + actions.get_combined_minimum_size().y + float(_column.get_theme_constant(&"separation"))
	var room := maxf(layer_height - chrome, float(ThemeTokens.TOUCH_MIN))
	_scroll.custom_minimum_size.y = clampf(content.get_combined_minimum_size().y, 0.0, room)
