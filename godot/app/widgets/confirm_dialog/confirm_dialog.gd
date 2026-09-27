class_name ConfirmDialog
extends Control
## Overlay für blockierende Rückfragen (Modal): abgedunkelter Hintergrund, Karte mit Titel,
## Text und zwei oder drei Aktionen (DialogRequest). Abbrechen steht links und erhält den
## Fokus (sichere Vorgabe); zwischen den Aktionen liegt großer Abstand (ButtonRow).
## Modal:
##   - die Abdunklung fängt Maus und Touch ab, der Hintergrund reagiert nicht
##   - Tab, Shift+Tab und Pfeiltasten wechseln nur zwischen den Dialogaktionen
##   - Fokus, der von außen in den Hintergrund gesetzt wird, kehrt in den Dialog zurück
##   - Escape und System-Zurück führen über die Shell die Abbruchaktion aus
##   - nach dem Schließen erhält das vorher fokussierte Control den Fokus zurück; erst danach
##     läuft der Rückruf der gewählten Aktion (er darf den Fokus neu setzen)
## Mit `options` zeigt der Dialog zusätzlich eine scrollbare Auswahlliste (z. B. Rollenauswahl);
## die Optionen gehören zur Fokussperre.
## Solange ein Dialog offen ist, werden weitere Anfragen verworfen (`open_request` → false).

signal confirmed
signal cancelled
signal alternative_chosen

var _request: DialogRequest = null
var _return_focus: Control = null

@onready var _panel: PanelContainer = %DialogPanel
@onready var _title: GrimmLabel = %TitleLabel
@onready var _message: GrimmLabel = %MessageLabel
@onready var _confirm: GrimmButton = %ConfirmButton
@onready var _cancel: GrimmButton = %CancelButton
@onready var _alternative: GrimmButton = %AlternativeButton
@onready var _option_scroll: ScrollContainer = %OptionScroll
@onready var _option_list: VBoxContainer = %OptionList


func _ready() -> void:
	visible = false
	_panel.custom_minimum_size.x = ThemeTokens.DIALOG_WIDTH
	_confirm.pressed.connect(_on_confirm)
	_cancel.pressed.connect(cancel)
	_alternative.pressed.connect(_on_alternative)
	_option_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_option_scroll.follow_focus = true
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


## Kurzform für einfache Rückfragen (zwei Aktionen, Rückruf über das Signal `confirmed`).
func open(title_key: String, message_key: String, confirm_key: String, danger: bool = false, cancel_key: String = "ui.common.cancel") -> bool:
	var r := DialogRequest.create(title_key, message_key, confirm_key, Callable(), danger)
	r.cancel_key = cancel_key
	return open_request(r)


func open_request(request: DialogRequest) -> bool:
	if visible or request == null:
		return false
	_request = request
	var focused := get_viewport().gui_get_focus_owner()
	_return_focus = focused if focused != null and not is_ancestor_of(focused) else null
	_title.text_key = request.title_key
	_message.format_values = request.message_values
	_message.text_key = request.message_key
	_confirm.text_key = request.confirm_key
	_confirm.visible = request.confirm_key != ""
	_confirm.kind = GrimmButton.Kind.DANGER if request.confirm_danger else GrimmButton.Kind.PRIMARY
	_cancel.text_key = request.cancel_key
	var has_alternative := request.alternative_key != ""
	_alternative.visible = has_alternative
	if has_alternative:
		_alternative.text_key = request.alternative_key
	_panel.custom_minimum_size.x = ThemeTokens.DIALOG_WIDE_WIDTH if has_alternative else ThemeTokens.DIALOG_WIDTH
	_message.visible = request.message_key != ""
	_build_options(request.options)
	visible = true
	var first := _first_option()
	(first if first != null else _cancel).grab_focus()
	return true


func is_open() -> bool:
	return visible


## Abbruchaktion (Button, Escape, System-Zurück, Navigation von außen).
func cancel() -> void:
	if not visible:
		return
	var request := _close()
	cancelled.emit()
	if request != null and request.on_cancel.is_valid():
		request.on_cancel.call()


func _on_confirm() -> void:
	if not visible:
		return
	var request := _close()
	confirmed.emit()
	if request != null and request.on_confirm.is_valid():
		request.on_confirm.call()


func _on_alternative() -> void:
	if not visible:
		return
	var request := _close()
	alternative_chosen.emit()
	if request != null and request.on_alternative.is_valid():
		request.on_alternative.call()


func _on_option(option: DialogOption) -> void:
	if not visible:
		return
	_close()
	if option.on_select.is_valid():
		option.on_select.call()


## Baut die Auswahlliste; ihre Höhe ist auf den im Fenster verfügbaren Platz begrenzt.
func _build_options(options: Array[DialogOption]) -> void:
	for child: Node in _option_list.get_children():
		_option_list.remove_child(child)
		child.queue_free()
	_option_scroll.visible = not options.is_empty()
	if options.is_empty():
		return
	for option: DialogOption in options:
		if option.heading:
			var label := GrimmLabel.new()
			label.theme_type_variation = &"CaptionLabel"
			label.text_key = option.text_key
			_option_list.add_child(label)
			continue
		var button := GrimmButton.new()
		button.name = option.node_name
		button.format_values = option.values
		button.text_key = option.text_key
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_option.bind(option))
		_option_list.add_child(button)
	var available := get_viewport_rect().size.y - ThemeTokens.DIALOG_LIST_RESERVED_HEIGHT
	_option_scroll.custom_minimum_size.y = minf(_option_list.get_combined_minimum_size().y, maxf(available, ThemeTokens.TOUCH_MIN))


func _first_option() -> Control:
	for child: Node in _option_list.get_children():
		if child is BaseButton and _option_scroll.visible:
			return child as Control
	return null


func _close() -> DialogRequest:
	var request := _request
	_request = null
	visible = false
	_build_options([])
	var target := _return_focus
	_return_focus = null
	if target != null and is_instance_valid(target) and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus()
	return request


# --- Fokussperre -----------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.is_pressed():
		return
	var step := 0
	if event.is_action("ui_focus_prev", true) or event.is_action("ui_left", true) or event.is_action("ui_up", true):
		step = -1
	elif event.is_action("ui_focus_next", true) or event.is_action("ui_right", true) or event.is_action("ui_down", true):
		step = 1
	if step == 0:
		return
	var actions := _actions()
	var current := actions.find(get_viewport().gui_get_focus_owner())
	var next := posmod(current + step, actions.size()) if current != -1 else 0
	actions[next].grab_focus()
	get_viewport().set_input_as_handled()


func _actions() -> Array[Control]:
	var out: Array[Control] = []
	if _option_scroll.visible:
		for child: Node in _option_list.get_children():
			if child is BaseButton and not child.is_queued_for_deletion():
				out.append(child as Control)
	out.append(_cancel)
	if _alternative.visible:
		out.append(_alternative)
	if _confirm.visible:
		out.append(_confirm)
	return out


func _on_focus_changed(control: Control) -> void:
	if visible and control != null and not is_ancestor_of(control):
		_actions()[0].grab_focus.call_deferred()
