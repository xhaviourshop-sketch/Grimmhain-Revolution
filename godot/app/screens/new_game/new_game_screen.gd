class_name NewGameScreen
extends BaseScreen
## „Neue Partie“, Schritt 1: Personen erfassen, bearbeiten, entfernen und bestätigen.
## Die Wahrheit über Personen, IDs und Bestätigung liegt in PlayerSetup (AppContext); diese
## Ansicht stellt nur dar, ruft Operationen auf und zeigt deren Ergebnisse als Meldungen.
## Linke Spalte, genau ein Modus: Einzeleingabe, Mehrfachimport oder Bearbeiten.
## Rechte Spalte: Anzahl, Hinweise, scrollbare Liste. Fußzeile: Neu beginnen, Status, Bestätigen.
## Noch keine Rollen, keine Sitzordnung, kein StartGame.

enum Mode { ENTRY, IMPORT, EDIT }

const ROW_SCENE := preload("res://app/screens/new_game/person_row.tscn")
const IMPORT_ERROR_LIST_LIMIT := 3    ## höchstens so viele fehlerhafte Importeinträge einzeln nennen
const IMPORT_ERROR_NAME_PREVIEW := 20  ## Zeichen eines fehlerhaften Namens in der Meldung

var _mode: Mode = Mode.ENTRY
var _edit_id: int = -1
var _feedback_key: String = ""
var _feedback_values: Dictionary = {}
var _feedback_variation: StringName = &"MutedLabel"
var _import_result: SetupResult = null

@onready var _entry_card: Control = %EntryCard
@onready var _name_input: LineEdit = %NameInput
@onready var _add: GrimmButton = %AddButton
@onready var _import_toggle: GrimmButton = %ImportToggleButton
@onready var _import_card: Control = %ImportCard
@onready var _import_text: TextEdit = %ImportText
@onready var _import_confirm: GrimmButton = %ImportConfirmButton
@onready var _import_cancel: GrimmButton = %ImportCancelButton
@onready var _import_feedback: GrimmLabel = %ImportFeedbackLabel
@onready var _edit_card: Control = %EditCard
@onready var _edit_number: GrimmLabel = %EditNumberLabel
@onready var _edit_input: LineEdit = %EditInput
@onready var _edit_save: GrimmButton = %EditSaveButton
@onready var _edit_cancel: GrimmButton = %EditCancelButton
@onready var _feedback: GrimmLabel = %FeedbackLabel
@onready var _count: GrimmLabel = %CountLabel
@onready var _minimum_hint: GrimmLabel = %MinimumHintLabel
@onready var _duplicate_summary: GrimmLabel = %DuplicateSummaryLabel
@onready var _confirmed_summary: Control = %ConfirmedSummary
@onready var _scroll: ScrollContainer = %PersonScroll
@onready var _list: VBoxContainer = %PersonList
@onready var _empty_label: Control = %EmptyListLabel
@onready var _restart: GrimmButton = %RestartButton
@onready var _status: GrimmLabel = %StatusLabel
@onready var _confirm: GrimmButton = %ConfirmPlayersButton


func _setup() -> void:
	(%SideColumn as Control).custom_minimum_size.x = ThemeTokens.SETUP_SIDE_WIDTH
	for field: Control in [_name_input, _edit_input]:
		field.custom_minimum_size.y = ThemeTokens.INPUT_HEIGHT
	_import_text.custom_minimum_size.y = ThemeTokens.IMPORT_TEXT_MIN_HEIGHT
	_import_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_apply_placeholders()
	_name_input.text_changed.connect(func(_t: String) -> void: _update_controls(_setup_view()))
	_name_input.text_submitted.connect(func(_t: String) -> void: _submit_single())
	_add.pressed.connect(_on_add_pressed)
	_import_toggle.pressed.connect(_on_import_toggle)
	_import_text.text_changed.connect(func() -> void: _update_controls(_setup_view()))
	_import_confirm.pressed.connect(_on_import_confirm)
	_import_cancel.pressed.connect(_on_import_cancel)
	_edit_input.text_submitted.connect(func(_t: String) -> void: _on_edit_save())
	_edit_save.pressed.connect(_on_edit_save)
	_edit_cancel.pressed.connect(_on_edit_cancel)
	_restart.pressed.connect(_on_restart_pressed)
	_confirm.pressed.connect(_on_confirm_pressed)
	context.setup.changed.connect(_render)
	_set_mode(Mode.ENTRY)
	_render(_setup_view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_placeholders()
		_show_feedback(_feedback_key, _feedback_values, _feedback_variation)
		_show_import_feedback(_import_result)


func default_focus() -> Control:
	return _name_input


## Zurück, Escape und System-Zurück: offenen Modus schließen, sonst bei unbestätigten
## Änderungen nachfragen; sonst normales Zurück über die Shell.
func handle_back() -> bool:
	if _mode != Mode.ENTRY:
		_leave_mode()
		return true
	if not context.setup.needs_leave_confirmation():
		return false
	var request := DialogRequest.create("ui.setup.dialog.leave.title", "ui.setup.dialog.leave.message", "ui.setup.dialog.leave.discard", _discard_and_leave, true)
	request.cancel_key = "ui.setup.dialog.leave.continue"
	request.alternative_key = "ui.setup.dialog.leave.keep"
	request.on_alternative = navigate_requested.emit.bind(ScreenIds.MAIN_MENU)
	dialog_requested.emit(request)
	return true


# --- Darstellung ------------------------------------------------------------------------------------

func _setup_view() -> Dictionary:
	return context.setup.view()


func _render(view: Dictionary) -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_row_id := -1
	for row: Node in _list.get_children():
		if row is PersonRow:
			if focused != null and row.is_ancestor_of(focused):
				focus_row_id = (row as PersonRow).person_id
			_list.remove_child(row)
			row.queue_free()
	for entry: Variant in view["persons"]:
		var row := ROW_SCENE.instantiate() as PersonRow
		_list.add_child(row)
		row.show_person(entry)
		row.edit_requested.connect(_on_edit_requested)
		row.remove_requested.connect(_on_remove_requested)
	_empty_label.visible = (view["persons"] as Array).is_empty()
	_count.format_values = {"count": view["count"], "max": view["max_persons"]}
	var validation: Dictionary = view["validation"]
	if bool(validation["at_maximum"]):
		_minimum_hint.format_values = {"max": view["max_persons"]}
		_minimum_hint.text_key = "ui.setup.hint.full"
	elif int(validation["missing"]) > 0:
		_minimum_hint.format_values = {"min": view["min_persons"], "missing": validation["missing"]}
		_minimum_hint.text_key = "ui.setup.hint.minimum"
	else:
		_minimum_hint.text_key = "ui.setup.hint.enough"
	var duplicates := int(view["duplicate_count"])
	_duplicate_summary.visible = duplicates > 0
	_duplicate_summary.format_values = {"count": duplicates}
	_duplicate_summary.text_key = "ui.setup.warning.duplicates_summary" if duplicates > 0 else ""
	_confirmed_summary.visible = bool(view["confirmed"])
	if bool(view["confirmed"]):
		_status.format_values = {"count": view["count"]}
		_status.text_key = "ui.setup.status.confirmed"
	elif bool(validation["valid"]):
		_status.text_key = "ui.setup.status.ready"
	else:
		_status.format_values = {"missing": validation["missing"]}
		_status.text_key = "ui.setup.status.incomplete"
	if _mode == Mode.EDIT and _row_for(_edit_id) == null:
		_set_mode(Mode.ENTRY)  # bearbeitete Person existiert nicht mehr
	_update_controls(view)
	if focus_row_id != -1:
		_focus_row(focus_row_id)


func _update_controls(view: Dictionary) -> void:
	var can_add := bool(view["can_add"])
	_name_input.editable = can_add
	_add.disabled = not can_add or PersonNameRules.normalize(_name_input.text).is_empty()
	_import_toggle.disabled = not can_add
	_import_confirm.disabled = PersonNameRules.split_import(_import_text.text).is_empty()
	_confirm.disabled = not bool(view["can_confirm"])
	_restart.disabled = bool(view["is_empty"])


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_entry_card.visible = mode == Mode.ENTRY
	_import_card.visible = mode == Mode.IMPORT
	_edit_card.visible = mode == Mode.EDIT


func _apply_placeholders() -> void:
	_name_input.placeholder_text = tr("ui.setup.input.placeholder")
	_edit_input.placeholder_text = tr("ui.setup.edit.placeholder")
	_import_text.placeholder_text = tr("ui.setup.import.placeholder")


func _show_feedback(key: String, values: Dictionary = {}, variation: StringName = &"MutedLabel") -> void:
	_feedback_key = key
	_feedback_values = values
	_feedback_variation = variation
	_feedback.theme_type_variation = variation
	_feedback.format_values = values
	_feedback.text_key = key
	_feedback.visible = key != ""


## Meldung eines abgelehnten Imports; fehlerhafte Einträge werden einzeln genannt.
func _show_import_feedback(result: SetupResult) -> void:
	_import_result = result
	if result == null or result.ok:
		_import_feedback.text_key = ""
		_import_feedback.visible = false
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
	_import_feedback.format_values = values
	_import_feedback.text_key = key
	_import_feedback.visible = true


func _feedback_for_error(result: SetupResult) -> void:
	_show_feedback("ui.setup.error." + String(result.error), result.details, &"ErrorLabel")


func _row_for(person_id: int) -> PersonRow:
	for row: Node in _list.get_children():
		if row is PersonRow and (row as PersonRow).person_id == person_id:
			return row as PersonRow
	return null


func _focus_row(person_id: int, remove: bool = false) -> void:
	var row := _row_for(person_id)
	if row != null:
		(row.remove_button() if remove else row.edit_button()).grab_focus()
	else:
		_name_input.grab_focus()


# --- Einzeleingabe ----------------------------------------------------------------------------------

func _on_add_pressed() -> void:
	if _add.disabled or _mode != Mode.ENTRY:
		return  # z. B. zweites Tippen nach erfolgreichem Hinzufügen
	_submit_single()


func _submit_single() -> void:
	var result := context.setup.add_person(_name_input.text)
	if not result.ok:
		_feedback_for_error(result)
		_name_input.grab_focus()
		return
	_name_input.text = ""
	if result.warnings.has(&"duplicate_name"):
		_show_feedback("ui.setup.warning.duplicate_added", {"name": _name_of(result.person_ids[0])}, &"WarningLabel")
	else:
		_show_feedback("")
	_update_controls(_setup_view())
	_name_input.grab_focus()
	_scroll_to_row.call_deferred(result.person_ids[0])


func _scroll_to_row(person_id: int) -> void:
	var row := _row_for(person_id)
	if row != null and row.is_inside_tree():
		_scroll.ensure_control_visible(row)


func _name_of(person_id: int) -> String:
	var row := _row_for(person_id)
	return row.person_name if row != null else ""


# --- Mehrfachimport ---------------------------------------------------------------------------------

func _on_import_toggle() -> void:
	if _import_toggle.disabled or _mode != Mode.ENTRY:
		return
	_show_feedback("")
	_show_import_feedback(null)
	_set_mode(Mode.IMPORT)
	_update_controls(_setup_view())
	_import_text.grab_focus()


func _on_import_confirm() -> void:
	if _mode != Mode.IMPORT or _import_confirm.disabled:
		return
	var result := context.setup.import_names(_import_text.text)
	if not result.ok:
		_show_import_feedback(result)
		_import_text.grab_focus()
		return
	_import_text.text = ""
	_show_import_feedback(null)
	_set_mode(Mode.ENTRY)
	var key := "ui.setup.info.imported_with_duplicates" if result.warnings.has(&"duplicate_name") else "ui.setup.info.imported"
	_show_feedback(key, {"count": result.person_ids.size()}, &"WarningLabel" if result.warnings.has(&"duplicate_name") else &"MutedLabel")
	_update_controls(_setup_view())
	_name_input.grab_focus()


func _on_import_cancel() -> void:
	if _mode != Mode.IMPORT:
		return
	_import_text.text = ""
	_leave_mode()


# --- Bearbeiten -------------------------------------------------------------------------------------

func _on_edit_requested(person_id: int) -> void:
	var row := _row_for(person_id)
	if row == null:
		return
	_show_import_feedback(null)
	_show_feedback("")
	_edit_id = person_id
	_edit_number.format_values = {"number": row.number}
	_edit_input.text = row.person_name
	_set_mode(Mode.EDIT)
	_edit_input.grab_focus()
	_edit_input.caret_column = _edit_input.text.length()


func _on_edit_save() -> void:
	if _mode != Mode.EDIT:
		return
	var id := _edit_id
	var result := context.setup.rename_person(id, _edit_input.text)
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
	_focus_row(id)


func _on_edit_cancel() -> void:
	if _mode == Mode.EDIT:
		_leave_mode()


## Schließt Import oder Bearbeiten ohne Änderung und setzt den Fokus sinnvoll zurück.
func _leave_mode() -> void:
	var was_edit := _mode == Mode.EDIT
	var id := _edit_id
	_edit_id = -1
	_show_feedback("")
	_show_import_feedback(null)
	_set_mode(Mode.ENTRY)
	_update_controls(_setup_view())
	if was_edit:
		_focus_row(id)
	else:
		_name_input.grab_focus()


# --- Entfernen, Neu beginnen, Bestätigen, Verlassen --------------------------------------------------

func _on_remove_requested(person_id: int) -> void:
	var row := _row_for(person_id)
	if row == null:
		return
	var request := DialogRequest.create("ui.setup.dialog.remove.title", "ui.setup.dialog.remove.message", "ui.setup.dialog.remove.confirm", _remove_person.bind(person_id, row.number), true)
	request.message_values = {"name": row.person_name, "number": row.number}
	dialog_requested.emit(request)


func _remove_person(person_id: int, number: int) -> void:
	var result := context.setup.remove_person(person_id)
	if not result.ok:
		_feedback_for_error(result)
		return
	_show_feedback("")
	var persons: Array = _setup_view()["persons"]
	if persons.is_empty():
		_name_input.grab_focus()
	else:
		var next: Dictionary = persons[mini(number - 1, persons.size() - 1)]
		_focus_row(int(next["person_id"]), true)


func _on_restart_pressed() -> void:
	if _restart.disabled:
		return
	var request := DialogRequest.create("ui.setup.dialog.restart.title", "ui.setup.dialog.restart.message", "ui.setup.dialog.restart.confirm", _restart_draft, true)
	request.message_values = {"count": _setup_view()["count"]}
	dialog_requested.emit(request)


func _restart_draft() -> void:
	context.setup.reset()
	_import_text.text = ""
	_name_input.text = ""
	_show_feedback("")
	_show_import_feedback(null)
	_set_mode(Mode.ENTRY)
	_update_controls(_setup_view())
	_name_input.grab_focus()


func _on_confirm_pressed() -> void:
	if _confirm.disabled:
		return
	var result := context.setup.confirm()
	if not result.ok:
		_feedback_for_error(result)
		return
	_show_feedback("")
	status_message_requested.emit("ui.setup.toast.confirmed")


func _discard_and_leave() -> void:
	context.setup.reset()
	navigate_requested.emit(ScreenIds.MAIN_MENU)
