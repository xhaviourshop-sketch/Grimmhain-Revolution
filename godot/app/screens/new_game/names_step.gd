class_name NamesStep
extends PrepStep
## Schritt 2 „Namen“: Namen eintragen, einfügen oder diktieren (Tastatur-Diktat) und als nummerierte Namensschilder ordnen. Die
## Reihenfolge der Schilder ist die Sitzordnung im Uhrzeigersinn ab Platz 1 (kein eigener Sitzschritt); ein Schild antippen, dann früher oder
## später schieben, ändern oder entfernen; „Mischen“ ordnet über den gespeicherten Generator neu. Der Zähler „9 von 14“ zeigt, wie viele
## Namen zur Spielerzahl fehlen; ein Knopf gleicht die Spielerzahl an die Namen an. Namen bleiben Pflicht (keine Platzhalter).
## Linke Spalte, genau ein Modus: Eingabe, Liste einfügen, Namen ändern, gespeicherte Gruppen oder die Prüfliste für mehrere Namen
## aus einem Text (Komma, Zeilenumbruch, „und“/„and“). Die Wahrheit über Personen liegt in PlayerSetup.

signal next_requested

enum Mode { ENTRY, IMPORT, EDIT, GROUPS, REVIEW }

const GROUP_CARD_SCENE := preload("res://app/screens/new_game/group_card.tscn")
const IMPORT_ERROR_LIST_LIMIT := 3    ## höchstens so viele fehlerhafte Importeinträge einzeln nennen
const IMPORT_ERROR_NAME_PREVIEW := 20  ## Zeichen eines fehlerhaften Namens in der Meldung

var _mode: Mode = Mode.ENTRY
var _selected_id: int = 0
var _edit_id: int = -1
var _last_view: Dictionary = {}
var _feedback_key: String = ""
var _feedback_values: Dictionary = {}
var _feedback_variation: StringName = &"HainMutedLabel"
var _import_result: SetupResult = null
var _review_result: SetupResult = null
var _group_actions: GroupActions = null
var _plates: Array[NamePlate] = []

var _side: VBoxContainer
var _list_col: VBoxContainer
var _entry_card: PanelContainer
var _name_input: LineEdit
var _add: GrimmButton
var _import_toggle: GrimmButton
var _load_group: GrimmButton
var _save_group: GrimmButton
var _import_card: PanelContainer
var _import_text: TextEdit
var _import_confirm: GrimmButton
var _import_cancel: GrimmButton
var _import_feedback: GrimmLabel
var _edit_card: PanelContainer
var _edit_number: GrimmLabel
var _edit_input: LineEdit
var _edit_save: GrimmButton
var _edit_cancel: GrimmButton
var _group_card: GroupCard
var _review: NameReviewCard
var _feedback: GrimmLabel
var _count: GrimmLabel
var _fit: GrimmButton
var _shuffle: GrimmButton
var _duplicates: GrimmLabel
var _scroll: ScrollContainer
var _grid: GridContainer
var _earlier: GrimmButton
var _later: GrimmButton
var _edit: GrimmButton
var _remove: GrimmButton


func start(setup: PlayerSetup, groups: GroupStore) -> void:
	_setup = setup
	name = "NamesStep"
	_group_actions = GroupActions.new(groups, setup)
	var body := HBoxContainer.new()
	body.name = "NamesBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	add_child(body)
	_side = _side_column()
	_list_col = _list_column()
	body.add_child(_side)
	body.add_child(_list_col)
	HainStyle.apply(self)
	_group_actions.dialog_requested.connect(dialog_requested.emit)
	_group_actions.message.connect(_show_feedback)
	_group_actions.group_loaded.connect(_on_group_loaded)
	_group_card.start(_group_actions)
	_group_card.close_requested.connect(_leave_mode)
	_name_input.keep_editing_on_text_submit = true  # Tastatur bleibt offen, das Feld nimmt den nächsten Namen sofort an
	_apply_placeholders()
	_setup.changed.connect(_render)
	_set_mode(Mode.ENTRY)
	_render(_setup.view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _setup != null:
		_apply_placeholders()
		_show_feedback(_feedback_key, _feedback_values, _feedback_variation)
		_fill_error_label(_import_feedback, _import_result)
		_fill_error_label(_review.feedback_label(), _review_result)


func default_focus() -> Control:
	return _name_input if bool(_last_view.get("can_add", true)) else _later


func footer() -> Dictionary:
	var complete := bool(_last_view.get("names_complete", false))
	var missing := int(_last_view.get("names_missing", 0))
	var hint := ""
	var values := {}
	var error := false
	if not complete:
		hint = "ui.prep.names.missing_one" if missing == 1 else "ui.prep.names.missing"
		values = {"count": missing, "total": _last_view.get("player_count", 0)}
		if int(_last_view.get("count", 0)) > int(_last_view.get("player_count", 0)):
			hint = ""
	return {"next_key": "ui.prep.next.roles", "next_enabled": complete, "next_primary": true, "hint_key": hint, "hint_values": values, "hint_error": error}


func activate_next() -> void:
	if bool(_last_view.get("names_complete", false)):
		next_requested.emit()


## Zurück, Escape und System-Zurück: ein offener Modus (Liste einfügen, Ändern, Gruppen, Prüfliste) schließt zuerst, dann die Auswahl.
func handle_back() -> bool:
	if _mode != Mode.ENTRY:
		_leave_mode()
		return true
	if _selected_id != 0:
		_select(0)
		return true
	return false


# --- Aufbau ----------------------------------------------------------------------------------------------

func _side_column() -> VBoxContainer:
	var side := VBoxContainer.new()
	side.name = "SideColumn"
	side.custom_minimum_size.x = ThemeTokens.PREP_SIDE_WIDTH
	side.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_entry_card = _card("EntryCard")
	var entry := _card_column(_entry_card)
	entry.add_child(_label("EntryHeading", &"SectionLabel", "ui.setup.entry.heading"))
	_name_input = LineEdit.new()
	_name_input.name = "NameInput"
	_name_input.custom_minimum_size.y = ThemeTokens.INPUT_HEIGHT
	_name_input.add_to_group(&"user_content")
	_name_input.text_changed.connect(func(_t: String) -> void: _update_controls(_last_view))
	_name_input.text_submitted.connect(func(_t: String) -> void: _submit_single())
	entry.add_child(_name_input)
	_add = _button("AddButton", GrimmButton.Kind.PRIMARY, "ui.setup.add")
	_add.pressed.connect(_on_add_pressed)
	entry.add_child(_add)
	entry.add_child(_label("EntryHint", &"CaptionLabel", "ui.prep.names.hint"))
	_import_toggle = _button("ImportToggleButton", GrimmButton.Kind.SECONDARY, "ui.setup.import.open")
	_import_toggle.pressed.connect(_on_import_toggle)
	entry.add_child(_import_toggle)
	_load_group = _button("LoadGroupButton", GrimmButton.Kind.SECONDARY, "ui.groups.open")
	_load_group.pressed.connect(_on_groups_open)
	entry.add_child(_load_group)
	_save_group = _button("SaveGroupButton", GrimmButton.Kind.SECONDARY, "ui.groups.save")
	_save_group.pressed.connect(func() -> void: _group_actions.request_save())
	entry.add_child(_save_group)
	side.add_child(_entry_card)
	_import_card = _card("ImportCard")
	var imp := _card_column(_import_card)
	imp.add_child(_label("ImportHeading", &"SectionLabel", "ui.setup.import.heading"))
	imp.add_child(_label("ImportHint", &"CaptionLabel", "ui.setup.import.hint"))
	_import_text = TextEdit.new()
	_import_text.name = "ImportText"
	_import_text.custom_minimum_size.y = ThemeTokens.IMPORT_TEXT_MIN_HEIGHT
	_import_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_import_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_import_text.add_to_group(&"user_content")
	_import_text.text_changed.connect(func() -> void: _update_controls(_last_view))
	imp.add_child(_import_text)
	_import_feedback = _label("ImportFeedbackLabel", &"ErrorCaptionLabel", "")
	_import_feedback.visible = false
	imp.add_child(_import_feedback)
	_import_confirm = _button("ImportConfirmButton", GrimmButton.Kind.PRIMARY, "ui.setup.import.confirm")
	_import_confirm.pressed.connect(_on_import_confirm)
	imp.add_child(_import_confirm)
	_import_cancel = _button("ImportCancelButton", GrimmButton.Kind.SECONDARY, "ui.common.cancel")
	_import_cancel.pressed.connect(_on_import_cancel)
	imp.add_child(_import_cancel)
	side.add_child(_import_card)
	_edit_card = _card("EditCard")
	var edit := _card_column(_edit_card)
	edit.add_child(_label("EditHeading", &"SectionLabel", "ui.setup.edit.heading"))
	_edit_number = _label("EditNumberLabel", &"CaptionLabel", "ui.setup.edit.person")
	edit.add_child(_edit_number)
	_edit_input = LineEdit.new()
	_edit_input.name = "EditInput"
	_edit_input.custom_minimum_size.y = ThemeTokens.INPUT_HEIGHT
	_edit_input.add_to_group(&"user_content")
	_edit_input.text_submitted.connect(func(_t: String) -> void: _on_edit_save())
	edit.add_child(_edit_input)
	_edit_save = _button("EditSaveButton", GrimmButton.Kind.PRIMARY, "ui.setup.edit.save")
	_edit_save.pressed.connect(_on_edit_save)
	edit.add_child(_edit_save)
	_edit_cancel = _button("EditCancelButton", GrimmButton.Kind.SECONDARY, "ui.common.cancel")
	_edit_cancel.pressed.connect(_on_edit_cancel)
	edit.add_child(_edit_cancel)
	side.add_child(_edit_card)
	_group_card = GROUP_CARD_SCENE.instantiate() as GroupCard
	side.add_child(_group_card)
	_review = NameReviewCard.new()
	_review.visible = false
	_review.add_all_requested.connect(_on_review_add_all)
	_review.cancel_requested.connect(_on_review_cancel)
	side.add_child(_review)
	_feedback = _label("FeedbackLabel", &"MutedLabel", "")
	_feedback.visible = false
	side.add_child(_feedback)
	return side


func _list_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = "ListColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	var header := HBoxContainer.new()
	header.name = "ListHeader"
	_count = _label("CountLabel", &"HeadingLabel", "ui.prep.names.count")
	_count.wrap = false
	header.add_child(_count)
	_fit = _button("FitButton", GrimmButton.Kind.SECONDARY, "ui.prep.names.fit")
	_fit.pressed.connect(_on_fit_pressed)
	header.add_child(_fit)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_shuffle = _button("ShuffleButton", GrimmButton.Kind.SECONDARY, "ui.prep.names.shuffle")
	_shuffle.pressed.connect(_on_shuffle_pressed)
	header.add_child(_shuffle)
	column.add_child(header)
	column.add_child(_label("SeatHint", &"CaptionLabel", "ui.prep.names.seat_hint"))
	_duplicates = _label("DuplicateSummaryLabel", &"CaptionLabel", "")
	_duplicates.visible = false
	column.add_child(_duplicates)
	_scroll = ScrollContainer.new()
	_scroll.name = "PlateScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	column.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.name = "PlateGrid"
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_S)
	_grid.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_S)
	_scroll.add_child(_grid)
	var tools := HBoxContainer.new()
	tools.name = "PlateTools"
	tools.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_earlier = _button("EarlierButton", GrimmButton.Kind.SECONDARY, "ui.prep.names.earlier")
	_earlier.pressed.connect(func() -> void: _move(-1))
	tools.add_child(_earlier)
	_later = _button("LaterButton", GrimmButton.Kind.SECONDARY, "ui.prep.names.later")
	_later.pressed.connect(func() -> void: _move(1))
	tools.add_child(_later)
	_edit = _button("EditButton", GrimmButton.Kind.SECONDARY, "ui.prep.names.edit")
	_edit.pressed.connect(_on_edit_requested)
	tools.add_child(_edit)
	_remove = _button("RemoveButton", GrimmButton.Kind.SECONDARY, "ui.prep.names.remove")
	_remove.pressed.connect(_on_remove_requested)
	tools.add_child(_remove)
	column.add_child(tools)
	return column


func _card(node_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.theme_type_variation = &"CardPanel"
	return card


func _card_column(card: PanelContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	card.add_child(column)
	return column


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


# --- Darstellung ------------------------------------------------------------------------------------------

func _render(view: Dictionary) -> void:
	_last_view = view
	var persons: Array = view["persons"]
	var focus_id := _focused_plate_id()
	_build_plates(view)
	if _selected_id != 0 and not _has_person(persons, _selected_id):
		_selected_id = 0
	for plate: NamePlate in _plates:
		plate.selected = not plate.empty and plate.person_id == _selected_id
	_count.format_values = {"count": view["count"], "total": view["player_count"]}
	_count.text_key = "ui.prep.names.count"
	var fit := int(view["fit_count"])
	_fit.visible = fit != 0
	_fit.format_values = {"count": fit}
	_fit.text_key = "ui.prep.names.fit"
	_shuffle.disabled = persons.size() < 2
	var duplicates := int(view["duplicate_count"])
	_duplicates.visible = duplicates > 0
	_duplicates.format_values = {"count": duplicates}
	_duplicates.text_key = "ui.setup.warning.duplicates_summary" if duplicates > 0 else ""
	if _mode == Mode.EDIT and not _has_person(persons, _edit_id):
		_set_mode(Mode.ENTRY)  # bearbeitete Person existiert nicht mehr
	_update_controls(view)
	if focus_id != 0 and _plate_for(focus_id) != null:
		_plate_for(focus_id).grab_focus()
	footer_changed.emit()


func _build_plates(view: Dictionary) -> void:
	var persons: Array = view["persons"]
	var slots := maxi(int(view["player_count"]), persons.size())
	while _plates.size() < slots:
		var plate := NamePlate.new()
		plate.name = "NamePlate_%d" % (_plates.size() + 1)  # nach Platz, nicht nach Person: Umordnen benennt nichts um
		plate.pressed.connect(_on_plate_pressed.bind(plate))
		_grid.add_child(plate)
		_plates.append(plate)
	while _plates.size() > slots:
		var extra: NamePlate = _plates.pop_back()
		_grid.remove_child(extra)
		extra.queue_free()
	for i: int in _plates.size():
		if i < persons.size():
			_plates[i].show_person(persons[i])
		else:
			_plates[i].show_empty(i + 1)


func _update_controls(view: Dictionary) -> void:
	var can_add := bool(view.get("can_add", true))
	_name_input.editable = can_add
	_add.disabled = not can_add or PersonNameRules.normalize(_name_input.text).is_empty()
	_import_toggle.disabled = not can_add
	_import_confirm.disabled = PersonNameRules.split_import(_import_text.text).is_empty()
	_save_group.disabled = bool(view.get("is_empty", true))
	if _mode == Mode.GROUPS:
		_group_card.refresh()
	var has_selection := _selected_id != 0
	var index := _index_of(_selected_id)
	var count := int(view.get("count", 0))
	_earlier.disabled = not has_selection or index <= 0
	_later.disabled = not has_selection or index >= count - 1
	_edit.disabled = not has_selection
	_remove.disabled = not has_selection


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_entry_card.visible = mode == Mode.ENTRY
	_import_card.visible = mode == Mode.IMPORT
	_edit_card.visible = mode == Mode.EDIT
	_group_card.visible = mode == Mode.GROUPS
	_review.visible = mode == Mode.REVIEW
	# Die Gruppenkarte braucht die volle Breite (vier Knöpfe nebeneinander); die Namensschilder treten solange zurück.
	_list_col.visible = mode != Mode.GROUPS
	_side.custom_minimum_size.x = 0.0 if mode == Mode.GROUPS else ThemeTokens.PREP_SIDE_WIDTH
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mode == Mode.GROUPS else Control.SIZE_FILL


func _apply_placeholders() -> void:
	_name_input.placeholder_text = tr("ui.prep.names.placeholder")
	_edit_input.placeholder_text = tr("ui.setup.edit.placeholder")
	_import_text.placeholder_text = tr("ui.setup.import.placeholder")


func _show_feedback(key: String, values: Dictionary = {}, variation: StringName = &"MutedLabel") -> void:
	_feedback_key = key
	_feedback_values = values
	_feedback_variation = variation
	_feedback.theme_type_variation = HainStyle.LABELS.get(variation, variation)
	_feedback.format_values = values
	_feedback.text_key = key
	_feedback.visible = key != ""


## Meldung eines abgelehnten Imports; fehlerhafte Einträge werden einzeln genannt.
func _show_import_feedback(result: SetupResult) -> void:
	_import_result = result
	_fill_error_label(_import_feedback, result)


func _fill_error_label(label: GrimmLabel, result: SetupResult) -> void:
	if result == null or result.ok:
		label.text_key = ""
		label.visible = false
		return
	var values := result.details.duplicate()
	var key := "ui.setup.error." + String(result.error)
	if result.error == &"invalid_entries":
		var lines: Array[String] = []
		for i: int in mini(result.entries.size(), IMPORT_ERROR_LIST_LIMIT):
			var entry := result.entries[i]
			var entry_name := str(entry["name"])
			if entry_name.length() > IMPORT_ERROR_NAME_PREVIEW:
				entry_name = entry_name.left(IMPORT_ERROR_NAME_PREVIEW) + "…"
			lines.append(tr("ui.setup.error.entry").format({
				"position": entry["position"], "name": entry_name,
				"reason": tr("ui.setup.reason." + String(entry["error"])).format(values),
			}))
		if result.entries.size() > IMPORT_ERROR_LIST_LIMIT:
			lines.append(tr("ui.setup.error.entries_more").format({"count": result.entries.size() - IMPORT_ERROR_LIST_LIMIT}))
		if bool(values.get("exceeds_max", false)):
			lines.append(tr("ui.setup.error.also_too_many").format(values))
		values["count"] = result.entries.size()
		values["entries"] = "\n".join(lines)
	label.format_values = values
	label.text_key = key
	label.visible = true


func _feedback_for_error(result: SetupResult) -> void:
	_show_feedback("ui.setup.error." + String(result.error), result.details, &"ErrorLabel")


# --- Namensschilder ---------------------------------------------------------------------------------------

func plates() -> Array[NamePlate]:
	return _plates


func selected_person() -> int:
	return _selected_id


func _plate_for(person_id: int) -> NamePlate:
	for plate: NamePlate in _plates:
		if not plate.empty and plate.person_id == person_id:
			return plate
	return null


func _focused_plate_id() -> int:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focused is NamePlate and not (focused as NamePlate).empty:
		return (focused as NamePlate).person_id
	return 0


func _has_person(persons: Array, person_id: int) -> bool:
	for entry: Variant in persons:
		if int((entry as Dictionary)["person_id"]) == person_id:
			return true
	return false


func _index_of(person_id: int) -> int:
	var persons: Array = _last_view.get("persons", [])
	for i: int in persons.size():
		if int((persons[i] as Dictionary)["person_id"]) == person_id:
			return i
	return -1


func _on_plate_pressed(plate: NamePlate) -> void:
	if plate.empty:
		return
	_select(0 if plate.person_id == _selected_id else plate.person_id)


func _select(person_id: int) -> void:
	_selected_id = person_id
	for plate: NamePlate in _plates:
		plate.selected = not plate.empty and plate.person_id == _selected_id
	_update_controls(_last_view)


func _move(delta: int) -> void:
	if _selected_id == 0:
		return
	var id := _selected_id
	_setup.move_person(id, delta)
	var plate := _plate_for(id)
	if plate != null and plate.is_inside_tree():
		_scroll.ensure_control_visible.call_deferred(plate)


func _on_fit_pressed() -> void:
	_setup.fit_player_count_to_names()


func _on_shuffle_pressed() -> void:
	if _shuffle.disabled:
		return
	var result := _setup.shuffle_persons()
	if not result.ok:
		_feedback_for_error(result)


func _scroll_to_person(person_id: int) -> void:
	var plate := _plate_for(person_id)
	if plate != null and plate.is_inside_tree():
		_scroll.ensure_control_visible(plate)


# --- Einzeleingabe und Prüfliste --------------------------------------------------------------------------

func _on_add_pressed() -> void:
	if _add.disabled or _mode != Mode.ENTRY:
		return
	_submit_single()


func _submit_single() -> void:
	var spoken := PersonNameRules.split_spoken(_name_input.text)
	if spoken.size() > 1:
		_open_review(spoken)
		return
	var result := _setup.add_person(_name_input.text)
	if not result.ok:
		_feedback_for_error(result)
		_name_input.grab_focus()
		return
	_name_input.text = ""
	if result.warnings.has(&"duplicate_name"):
		_show_feedback("ui.setup.warning.duplicate_added", {"name": _name_of(result.person_ids[0])}, &"WarningLabel")
	else:
		_show_feedback("")
	_update_controls(_last_view)
	_name_input.grab_focus()
	_scroll_to_person.call_deferred(result.person_ids[0])


func _open_review(entries: Array[String]) -> void:
	_show_feedback("")
	_review_result = null
	_review.show_names(entries)
	_set_mode(Mode.REVIEW)
	_review.default_focus().grab_focus()


func _on_review_add_all(entries: Array[String]) -> void:
	if _mode != Mode.REVIEW or entries.is_empty():
		return
	var result := _setup.import_names("\n".join(entries))
	_review_result = result
	if not result.ok:
		_fill_error_label(_review.feedback_label(), result)
		return
	_name_input.text = ""
	_review_result = null
	_set_mode(Mode.ENTRY)
	_show_imported(result)
	_update_controls(_last_view)
	_name_input.grab_focus()


func _on_review_cancel() -> void:
	if _mode == Mode.REVIEW:
		_leave_mode()  # der eingegebene Text bleibt zum Korrigieren im Feld


func _show_imported(result: SetupResult) -> void:
	var duplicates := result.warnings.has(&"duplicate_name")
	_show_feedback("ui.setup.info.imported_with_duplicates" if duplicates else "ui.setup.info.imported", {"count": result.person_ids.size()}, &"WarningLabel" if duplicates else &"MutedLabel")


func _name_of(person_id: int) -> String:
	var plate := _plate_for(person_id)
	return plate.person_name if plate != null else ""


# --- Liste einfügen ---------------------------------------------------------------------------------------

func _on_import_toggle() -> void:
	if _import_toggle.disabled or _mode != Mode.ENTRY:
		return
	_show_feedback("")
	_show_import_feedback(null)
	_set_mode(Mode.IMPORT)
	_update_controls(_last_view)
	_import_text.grab_focus()


func _on_import_confirm() -> void:
	if _mode != Mode.IMPORT or _import_confirm.disabled:
		return
	var result := _setup.import_names(_import_text.text)
	if not result.ok:
		_show_import_feedback(result)
		_import_text.grab_focus()
		return
	_import_text.text = ""
	_show_import_feedback(null)
	_set_mode(Mode.ENTRY)
	_show_imported(result)
	_update_controls(_last_view)
	_name_input.grab_focus()


func _on_import_cancel() -> void:
	if _mode != Mode.IMPORT:
		return
	_import_text.text = ""
	_leave_mode()


# --- Gespeicherte Gruppen ---------------------------------------------------------------------------------

func _on_groups_open() -> void:
	if _mode != Mode.ENTRY:
		return
	_show_feedback("")
	_show_import_feedback(null)
	_group_card.refresh()
	_set_mode(Mode.GROUPS)
	_group_card.default_focus().grab_focus()


## Nach dem Laden einer Gruppe: zurück zur Eingabe, die Meldung der Aktion bleibt stehen.
func _on_group_loaded(_group_id: String) -> void:
	_selected_id = 0
	_set_mode(Mode.ENTRY)
	_update_controls(_last_view)
	_name_input.grab_focus()


# --- Ändern, Entfernen, Verlassen eines Modus -------------------------------------------------------------

func _on_edit_requested() -> void:
	var plate := _plate_for(_selected_id)
	if plate == null:
		return
	_show_import_feedback(null)
	_show_feedback("")
	_edit_id = plate.person_id
	_edit_number.format_values = {"number": plate.number}
	_edit_input.text = plate.person_name
	_set_mode(Mode.EDIT)
	_edit_input.grab_focus()
	_edit_input.caret_column = _edit_input.text.length()


func _on_edit_save() -> void:
	if _mode != Mode.EDIT:
		return
	var id := _edit_id
	var result := _setup.rename_person(id, _edit_input.text)
	if not result.ok:
		_feedback_for_error(result)
		_edit_input.grab_focus()
		return
	_set_mode(Mode.ENTRY)
	_edit_id = -1
	if result.warnings.has(&"duplicate_name"):
		_show_feedback("ui.setup.warning.duplicate_renamed", {"name": _name_of(id)}, &"WarningLabel")
	else:
		_show_feedback("")
	var plate := _plate_for(id)
	if plate != null:
		plate.grab_focus()


func _on_edit_cancel() -> void:
	if _mode == Mode.EDIT:
		_leave_mode()


## Schließt Liste einfügen, Ändern, Gruppen oder Prüfliste ohne Änderung und setzt den Fokus sinnvoll zurück.
func _leave_mode() -> void:
	var was_edit := _mode == Mode.EDIT
	var id := _edit_id
	_edit_id = -1
	_show_feedback("")
	_show_import_feedback(null)
	_review_result = null
	_set_mode(Mode.ENTRY)
	_update_controls(_last_view)
	if was_edit and _plate_for(id) != null:
		_plate_for(id).grab_focus()
	else:
		_name_input.grab_focus()


func _on_remove_requested() -> void:
	var plate := _plate_for(_selected_id)
	if plate == null:
		return
	var request := DialogRequest.create("ui.setup.dialog.remove.title", "ui.setup.dialog.remove.message", "ui.setup.dialog.remove.confirm", _remove_person.bind(plate.person_id), true)
	request.message_values = {"name": plate.person_name, "number": plate.number}
	dialog_requested.emit(request)


func _remove_person(person_id: int) -> void:
	var result := _setup.remove_person(person_id)
	if not result.ok:
		_feedback_for_error(result)
		return
	_show_feedback("")
	_selected_id = 0
	_update_controls(_last_view)
	_name_input.grab_focus()
