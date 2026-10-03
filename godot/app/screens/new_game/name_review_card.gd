class_name NameReviewCard
extends PanelContainer
## Prüfliste im Spieler-Schritt, wenn ein Text mehrere Namen enthält (zum Beispiel per Diktat der System-Tastatur):
## Jeder erkannte Name steht in einem eigenen Feld, ist änderbar und einzeln entfernbar; erst „Alle hinzufügen“
## übernimmt sie. Die Karte kennt keine Spielregeln und ändert nichts im Setup, sie meldet nur Wünsche als Signale.

signal add_all_requested(names: Array[String])
signal cancel_requested

var _heading: GrimmLabel
var _scroll: ScrollContainer
var _list: VBoxContainer
var _feedback: GrimmLabel
var _add_all: GrimmButton
var _cancel: GrimmButton


func _init() -> void:
	name = "NameReviewCard"
	theme_type_variation = &"CardPanel"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	add_child(column)
	_heading = _label("ReviewHeading", &"SectionLabel", "ui.setup.review.heading")
	column.add_child(_heading)
	column.add_child(_label("ReviewHint", &"CaptionLabel", "ui.setup.review.hint"))
	_scroll = ScrollContainer.new()
	_scroll.name = "ReviewScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.name = "ReviewList"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_feedback = _label("ReviewFeedbackLabel", &"ErrorCaptionLabel", "")
	_feedback.visible = false
	column.add_child(_feedback)
	_add_all = _button("ReviewAddAllButton", GrimmButton.Kind.PRIMARY, "ui.setup.review.add_all")
	_add_all.pressed.connect(func() -> void: add_all_requested.emit(names()))
	column.add_child(_add_all)
	_cancel = _button("ReviewCancelButton", GrimmButton.Kind.SECONDARY, "ui.common.cancel")
	_cancel.pressed.connect(cancel_requested.emit)
	column.add_child(_cancel)


## Füllt die Liste neu; jeder Name bekommt ein Feld und einen Entfernen-Knopf.
func show_names(entries: Array[String]) -> void:
	for row: Node in _list.get_children():
		_list.remove_child(row)
		row.queue_free()
	for entry: String in entries:
		_list.add_child(_make_row(entry))
	show_feedback_cleared()
	_refresh()


## Aktuelle, normalisierte, nicht leere Namen in Listenreihenfolge.
func names() -> Array[String]:
	var out: Array[String] = []
	for row: Node in _list.get_children():
		var text := PersonNameRules.normalize(((row as Control).find_child("ReviewNameInput", true, false) as LineEdit).text)
		if not text.is_empty():
			out.append(text)
	return out


func feedback_label() -> GrimmLabel:
	return _feedback


func show_feedback_cleared() -> void:
	_feedback.text_key = ""
	_feedback.visible = false


func default_focus() -> Control:
	return _add_all


func _make_row(entry: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ReviewRow"
	var input := LineEdit.new()
	input.name = "ReviewNameInput"
	input.text = entry
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size.y = ThemeTokens.INPUT_HEIGHT
	input.keep_editing_on_text_submit = true
	input.add_to_group(&"user_content")
	input.text_changed.connect(func(_t: String) -> void: _refresh())
	row.add_child(input)
	var remove := _button("ReviewRemoveButton", GrimmButton.Kind.COMPACT, "ui.setup.review.remove")
	remove.wrap = false
	remove.pressed.connect(func() -> void:
		_list.remove_child(row)
		row.queue_free()
		_refresh())
	row.add_child(remove)
	return row


func _refresh() -> void:
	var count := names().size()
	_heading.format_values = {"count": count}
	_add_all.disabled = count == 0


func _label(node_name: String, variation: StringName, key: String) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.name = node_name
	label.theme_type_variation = variation
	label.text_key = key
	return label


func _button(node_name: String, kind: GrimmButton.Kind, key: String) -> GrimmButton:
	var button := GrimmButton.new()
	button.name = node_name
	button.kind = kind
	button.text_key = key
	return button
