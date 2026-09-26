class_name ConfirmDialog
extends Control
## Overlay-Grundlage für blockierende Rückfragen: abgedunkelter Hintergrund, Karte mit Titel,
## Text und zwei getrennten Aktionen. Abbrechen steht links und erhält den Fokus (sichere
## Vorgabe); zwischen den Aktionen liegt großer Abstand (ButtonRow). `danger` färbt die
## Bestätigung rot für destruktive Aktionen.

signal confirmed
signal cancelled

@onready var _panel: PanelContainer = %DialogPanel
@onready var _title: GrimmLabel = %TitleLabel
@onready var _message: GrimmLabel = %MessageLabel
@onready var _confirm: GrimmButton = %ConfirmButton
@onready var _cancel: GrimmButton = %CancelButton


func _ready() -> void:
	visible = false
	_panel.custom_minimum_size.x = ThemeTokens.DIALOG_WIDTH
	_confirm.pressed.connect(_on_confirm)
	_cancel.pressed.connect(cancel)


func open(title_key: String, message_key: String, confirm_key: String, danger: bool = false, cancel_key: String = "ui.common.cancel") -> void:
	_title.text_key = title_key
	_message.text_key = message_key
	_confirm.text_key = confirm_key
	_cancel.text_key = cancel_key
	_confirm.kind = GrimmButton.Kind.DANGER if danger else GrimmButton.Kind.PRIMARY
	visible = true
	_cancel.grab_focus()


func is_open() -> bool:
	return visible


func cancel() -> void:
	if not visible:
		return
	visible = false
	cancelled.emit()


func _on_confirm() -> void:
	visible = false
	confirmed.emit()
