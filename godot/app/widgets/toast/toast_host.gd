class_name ToastHost
extends Control
## Statusmeldungen: kurze, nicht blockierende Meldung am unteren Rand, verschwindet nach
## TOAST_VISIBLE_SECONDS. Fängt nie Eingaben ab. Text nur über Übersetzungsschlüssel.

var settings: AppSettings = null

@onready var _panel: PanelContainer = %ToastPanel
@onready var _label: GrimmLabel = %MessageLabel
@onready var _timer: Timer = %HideTimer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size.x = ThemeTokens.TOAST_WIDTH
	_panel.visible = false
	_timer.one_shot = true
	_timer.wait_time = ThemeTokens.TOAST_VISIBLE_SECONDS
	_timer.timeout.connect(hide_message)


func show_message(text_key: String) -> void:
	_label.text_key = text_key
	_panel.visible = true
	_panel.modulate.a = 1.0
	_timer.start()


func hide_message() -> void:
	_panel.visible = false


func is_showing() -> bool:
	return _panel.visible
