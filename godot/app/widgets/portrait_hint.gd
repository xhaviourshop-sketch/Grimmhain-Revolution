class_name PortraitHint
extends Control
## Hinweis „Bitte das Gerät drehen“ (Block H): Das Spiel ist für Querformat gebaut. Solange die Fläche höher als breit ist, deckt dieses
## Fenster alles ab und fängt Eingaben ab; sobald sie quer ist, verschwindet es von selbst. „Trotzdem weiter“ blendet es für die laufende
## Sitzung aus (nicht gespeichert). Ausgeblendet ist es unsichtbar und lässt jede Eingabe durch. Eine kleine Schwelle (`HYSTERESIS`)
## verhindert Flackern, wenn die Fläche beim Drehen kurz fast quadratisch ist.

const HYSTERESIS := 24.0  ## Pixel Unterschied zwischen Höhe und Breite, ab dem der Zustand wechselt

var dismissed: bool = false
var _portrait: bool = false
var _button: GrimmButton = null


func _ready() -> void:
	name = "PortraitHint"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var ground := Panel.new()
	ground.theme_type_variation = &"AppBackground"
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"DialogPanel"
	panel.custom_minimum_size.x = ThemeTokens.DIALOG_WIDTH
	GroveWindow.frame(panel)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	panel.add_child(column)
	var title := GrimmLabel.new()
	title.name = "PortraitTitle"
	title.text_key = &"ui.portrait.title"
	title.theme_type_variation = &"GothicTitleLabel"
	title.add_theme_font_size_override(&"font_size", ThemeTokens.FONT_GOTHIC - 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var text := GrimmLabel.new()
	text.name = "PortraitText"
	text.text_key = &"ui.portrait.text"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(text)
	_button = GrimmButton.new()
	_button.name = "PortraitContinueButton"
	_button.text_key = &"ui.portrait.continue"
	_button.pressed.connect(dismiss)
	column.add_child(_button)
	GroveWindow.dress(self)
	get_viewport().size_changed.connect(update_state)
	update_state()


## Blendet den Hinweis für die laufende Sitzung aus.
func dismiss() -> void:
	dismissed = true
	update_state()


func is_portrait() -> bool:
	return _portrait


## Fläche prüfen und Sichtbarkeit setzen (mit Schwelle, damit der Zustand beim Drehen nicht flackert).
func update_state() -> void:
	var size_now := get_viewport().get_visible_rect().size
	if size_now.y > size_now.x + HYSTERESIS:
		_portrait = true
	elif size_now.x > size_now.y - HYSTERESIS:
		_portrait = false
	visible = _portrait and not dismissed
