class_name GroupCard
extends PanelContainer
## Karte „Gespeicherte Gruppen“ in der linken Spalte des Spielerschritts (ein Modus neben Eingabe, Import und
## Bearbeiten). Zeigt die Gruppen als Auswahlliste und die Aktionen für die gewählte Gruppe: Laden, Umbenennen,
## Aktualisieren, Löschen. Die Abläufe samt Rückfragen liegen in GroupActions; die Karte stellt nur dar und ruft sie.
## Meldungen der Aktionen zeigt der Spielerschritt. Kein Regelkern, keine laufende Partie.

signal close_requested

var _actions: GroupActions = null
var _selected_id: String = ""
var _button_group := ButtonGroup.new()

@onready var _status: GrimmLabel = %GroupStatusLabel
@onready var _empty: GrimmLabel = %GroupEmptyLabel
@onready var _list: VBoxContainer = %GroupList
@onready var _scroll: ScrollContainer = %GroupScroll
@onready var _preview: GrimmLabel = %GroupPreviewLabel
@onready var _load: GrimmButton = %GroupLoadButton
@onready var _rename: GrimmButton = %GroupRenameButton
@onready var _update: GrimmButton = %GroupUpdateButton
@onready var _delete: GrimmButton = %GroupDeleteButton
@onready var _close: GrimmButton = %GroupCloseButton


func start(actions: GroupActions) -> void:
	_actions = actions
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.custom_minimum_size.y = ThemeTokens.GROUP_LIST_MIN_HEIGHT
	_load.pressed.connect(func() -> void: _act(_actions.request_load))
	_rename.pressed.connect(func() -> void: _act(_actions.request_rename))
	_update.pressed.connect(func() -> void: _act(_actions.request_update))
	_delete.pressed.connect(func() -> void: _act(_actions.request_delete))
	_close.pressed.connect(close_requested.emit)
	_actions.groups_changed.connect(refresh)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _actions != null:
		_show_preview()


## Liste neu aufbauen; die gewählte Gruppe bleibt gewählt, sonst die erste.
func refresh() -> void:
	if _actions == null:
		return
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var groups := _actions.store().list()
	var found := false
	for group: Dictionary in groups:
		found = found or str(group["id"]) == _selected_id
	if not found:
		_selected_id = str(groups[0]["id"]) if not groups.is_empty() else ""
	for group: Dictionary in groups:
		var button := GrimmButton.new()
		button.name = "Group_%s" % str(group["id"]).replace("-", "_")
		button.toggle_mode = true
		button.button_group = _button_group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.format_values = {"name": group["name"], "count": (group["players"] as Array).size()}
		button.text_key = "ui.groups.entry"
		button.set_meta("group_id", str(group["id"]))
		button.button_pressed = str(group["id"]) == _selected_id
		button.toggled.connect(_on_group_toggled.bind(str(group["id"])))
		_list.add_child(button)
	_empty.visible = groups.is_empty()
	var load_status := _actions.store().load_status
	_status.visible = not bool(load_status["ok"]) or int(load_status["skipped"]) > 0 or str(load_status["recovered"]) != ""
	if _status.visible:
		_status.format_values = {"count": load_status["skipped"]}
		_status.text_key = _status_key(load_status)
	else:
		_status.text_key = ""
	_show_preview()


func _status_key(load_status: Dictionary) -> String:
	if not bool(load_status["ok"]):
		return "ui.groups.status.newer_version" if str(load_status["error"]) == "newer_version" else "ui.groups.status.unreadable"
	if int(load_status["skipped"]) > 0:
		return "ui.groups.status.skipped"
	return "ui.groups.status.recovered"


func selected_id() -> String:
	return _selected_id


func default_focus() -> Control:
	var first := _first_entry()
	return first if first != null else _close


func _first_entry() -> Control:
	for child: Node in _list.get_children():
		if child is GrimmButton and not child.is_queued_for_deletion():
			return child as Control
	return null


func _on_group_toggled(on: bool, id: String) -> void:
	if on:
		_selected_id = id
		_show_preview()


func _show_preview() -> void:
	var group := _actions.store().get_group(_selected_id) if _selected_id != "" else {}
	var has_group := not group.is_empty()
	_preview.visible = has_group
	if has_group:
		_preview.format_values = {"players": ", ".join(PackedStringArray(group["players"] as Array))}
		_preview.text_key = "ui.groups.preview"
	else:
		_preview.text_key = ""
	_load.disabled = not has_group
	_rename.disabled = not has_group
	_delete.disabled = not has_group
	_update.disabled = not has_group or not _actions.can_save_current()


func _act(action: Callable) -> void:
	if _selected_id != "":
		action.call(_selected_id)
