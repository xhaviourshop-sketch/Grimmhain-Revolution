class_name ToastHost
extends Control
## Statusmeldungen: kurze, nicht blockierende Meldung am unteren Rand, verschwindet nach
## TOAST_VISIBLE_SECONDS. Fängt nie Eingaben ab. Text nur über Übersetzungsschlüssel.
## Kurzes Einblenden, bei reduzierter Bewegung sofort sichtbar.

var settings: AppSettings = null

@onready var _panel: PanelContainer = %ToastPanel
@onready var _label: GrimmLabel = %MessageLabel
@onready var _timer: Timer = %HideTimer

var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size.x = ThemeTokens.TOAST_WIDTH
	# Über einer Fußzeile mit Primäraktion schweben, nicht auf ihr.
	(%Bottom as Control).offset_bottom = -ThemeTokens.TOAST_BOTTOM_OFFSET
	_panel.visible = false
	_timer.one_shot = true
	_timer.wait_time = ThemeTokens.TOAST_VISIBLE_SECONDS
	_timer.timeout.connect(hide_message)


func show_message(text_key: String) -> void:
	_label.text_key = text_key
	_panel.visible = true
	(%Bottom as Control).offset_bottom = -ThemeTokens.TOAST_BOTTOM_OFFSET
	_dodge_buttons.call_deferred()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var duration := fade_duration()
	if duration > 0.0:
		_panel.modulate.a = 0.0
		_tween = create_tween()
		_tween.tween_property(_panel, "modulate:a", 1.0, duration)
	else:
		_panel.modulate.a = 1.0
	_timer.start()


## Verdeckt die Meldung an ihrer Stelle einen sichtbaren Knopf oder Schalter, rutscht sie an den unteren Rand.
func _dodge_buttons() -> void:
	if not _panel.visible or not is_inside_tree():
		return
	var rect := _panel.get_global_rect()
	var stack: Array[Node] = [get_parent()]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == self:
			continue
		if node is BaseButton and (node as BaseButton).is_visible_in_tree() and (node as BaseButton).get_global_rect().intersects(rect):
			(%Bottom as Control).offset_bottom = -ThemeTokens.SPACE_M
			return
		stack.append_array(node.get_children())


## Dauer des Einblendens; 0 bei reduzierter Bewegung.
func fade_duration() -> float:
	if settings != null and settings.reduced_motion:
		return 0.0
	return ThemeTokens.TOAST_FADE_SECONDS


func hide_message() -> void:
	_panel.visible = false


func is_showing() -> bool:
	return _panel.visible
