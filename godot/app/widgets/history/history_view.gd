class_name HistoryView
extends PanelContainer
## Partiehistorie: Liste der abgeschlossenen Partien und der Abschlussbericht einer Partie (Paket D). Lesen ohne aktive Partie;
## die Ansicht ändert nie einen Spielstand. Der Bericht erscheint zuerst in der öffentlichen Fassung; die Spielleiterfassung wird
## erst nach ausdrücklicher Bestätigung gebaut und bei jedem erneuten Öffnen wieder verworfen (nie vorausgewählt). Vor dem Export
## steht die Fassung auf dem Knopf und in der Zeile darüber; eine vorhandene Datei wird nur nach Bestätigung überschrieben.
## Einen Bericht, dessen Siegbestätigung zurückgenommen wurde, gibt es weiter zu lesen, er gilt aber nicht als abgeschlossen und
## lässt sich nicht exportieren. Löschen fragt nach; nichts wird automatisch gelöscht.

signal dialog_requested(request: DialogRequest)

var context: AppContext = null

var _game_id: String = ""
var _version: String = ReportText.PUBLIC
var _title: GrimmLabel
var _back: GrimmButton
var _list_view: VBoxContainer
var _status: GrimmLabel
var _empty: GrimmLabel
var _list_host: VBoxContainer
var _report_view: VBoxContainer
var _public_button: GrimmButton
var _gm_button: GrimmButton
var _export_info: GrimmLabel
var _reopened: GrimmLabel
var _report_host: VBoxContainer
var _report_lines: Array[Dictionary] = []
var _export: GrimmButton
var _delete: GrimmButton
var _feedback: GrimmLabel


const LIST_ENTRY_HEIGHT := 64.0
const LIST_CHROME := 300.0
const REPORT_CHROME := 400.0  ## Rahmen, Kopf, Fassungswahl, Hinweiszeile, Blätterleiste und Knopfzeile


func _init(p_context: AppContext = null) -> void:
	context = p_context
	name = "HistoryView"
	theme_type_variation = &"CardPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(head)
	_back = _button("HistoryBackToListButton", "ui.history.back_to_list")
	_back.pressed.connect(show_list)
	head.add_child(_back)
	_title = GrimmLabel.new()
	_title.name = "HistoryTitleLabel"
	_title.theme_type_variation = &"HeadingLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_build_list(column)
	_build_report(column)
	show_list()


func is_report_open() -> bool:
	return _game_id != ""


func current_game_id() -> String:
	return _game_id


func current_version() -> String:
	return _version


## Liste der Berichte (neueste zuerst), Hinweis zum Laden der Datei.
func show_list() -> void:
	_game_id = ""
	_version = ReportText.PUBLIC
	_clear_report()
	_list_view.visible = true
	_report_view.visible = false
	_back.visible = false
	_title.text_key = "ui.history.title"
	_title.visible = false  # die Kopfzeile der Ansicht trägt den Titel
	refresh_list()


func refresh_list() -> void:
	_status.theme_type_variation = &"WarningLabel"
	for child: Node in _list_host.get_children():
		_list_host.remove_child(child)
		child.queue_free()
	var entries := context.history.list()
	_empty.visible = entries.is_empty()
	if not entries.is_empty():
		var pager := CockpitLayers.Pager.new()
		pager.setup(entries, _list_entry, func(_entry: Dictionary) -> float: return LIST_ENTRY_HEIGHT, _page_room(LIST_CHROME), false)
		_list_host.add_child(pager)
		pager.find_child("PageBody", true, false).name = "HistoryList"  # die Zeilen der sichtbaren Seite
	var load := context.history.load_status
	var problem := not bool(load["ok"]) or int(load["skipped"]) > 0 or str(load["recovered"]) != ""
	_status.visible = problem
	if problem:
		_status.format_values = {"count": load["skipped"]}
		if not bool(load["ok"]):
			_status.text_key = "ui.history.status.newer_version" if str(load["error"]) == "newer_version" else "ui.history.status.unreadable"
		else:
			_status.text_key = "ui.history.status.skipped" if int(load["skipped"]) > 0 else "ui.history.status.recovered"
	else:
		_status.text_key = ""


## Bericht öffnen (öffentliche Fassung); unbekannte IDs bleiben in der Liste.
func open_report(game_id: String) -> void:
	if not context.history.has(game_id):
		return
	_game_id = game_id
	_version = ReportText.PUBLIC
	_list_view.visible = false
	_report_view.visible = true
	_back.visible = true
	_title.visible = true
	_title.text_key = "ui.history.report_title"
	_public_button.set_pressed_no_signal(true)
	_gm_button.set_pressed_no_signal(false)
	_set_feedback("")
	_render_report()
	_focus(_back)


## Bericht mit Fehlermeldung zur Historie (Speichern der Historie ist gescheitert): zeigt den Hinweis in der Liste.
func show_save_failed() -> void:
	show_list()
	_status.visible = true
	_status.format_values = {}
	_status.text_key = "ui.history.error.save"


## Fassung wechseln. Die Spielleiterfassung verlangt eine ausdrückliche Bestätigung.
func choose_version(version: String) -> void:
	if not is_report_open() or version == _version:
		return
	if version == ReportText.GM:
		var request := DialogRequest.create("ui.history.dialog.gm.title", "ui.history.dialog.gm.message", "ui.history.dialog.gm.confirm", _apply_version.bind(ReportText.GM))
		request.on_cancel = _restore_version_buttons
		dialog_requested.emit(request)
	else:
		_apply_version(ReportText.PUBLIC)


## Sichtbare Zeilen des geöffneten Berichts (für Tests).
func report_texts() -> Array[String]:
	var out: Array[String] = []
	for line: Dictionary in _report_lines:
		out.append(str(line["text"]))
	return out


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _title != null and is_report_open():
		_render_report()


func _list_entry(entry: Dictionary) -> Control:
	var b := _button("Report_%s" % _node_part(str(entry["game_id"])), "ui.history.entry_reopened" if str(entry["status"]) == HistoryStore.STATUS_REOPENED else "ui.history.entry", true)
	b.format_values = {"names": ", ".join(PackedStringArray(entry["names"])), "count": int(entry["players"]), "date": _date(int(entry["saved_at"])),
		"side": StringName("ui.cockpit.win.kind.%s" % str(entry["side"]))}
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("game_id", str(entry["game_id"]))
	b.pressed.connect(open_report.bind(str(entry["game_id"])))
	return b


func _report_line(line: Dictionary) -> Control:
	var label := Label.new()
	label.add_to_group(&"user_content")  # Text aus Partiedaten, nicht aus festen Übersetzungsschlüsseln
	label.text = str(line["text"])
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match str(line["style"]):
		"title", "heading":
			label.theme_type_variation = &"HeadingLabel" if str(line["style"]) == "title" else &"SectionLabel"
		"note":
			label.theme_type_variation = &"CaptionLabel"
	return label


## Zwischentitel und Überschriften bleiben mit der nächsten Zeile zusammen.
func _is_heading(line: Dictionary) -> bool:
	return str(line["style"]) in ["title", "heading"]


## Höhe einer Berichtszeile für die Seiteneinteilung: gemessen in der Schrift ihres Stils bei der Breite der Seite.
func _line_height(line: Dictionary) -> float:
	var width := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size.x - RuleBook.SIDE_CHROME
	var type: StringName = &"Label"
	match str(line["style"]):
		"title":
			type = &"HeadingLabel"
		"heading":
			type = &"SectionLabel"
		"note":
			type = &"CaptionLabel"
	return RuleBook.text_height(self, str(line["text"]), type, width)


## Platz für Listenzeilen auf einer Seite: Fensterhöhe minus der übrigen Teile der Ansicht.
func _page_room(chrome: float) -> float:
	return maxf((Engine.get_main_loop() as SceneTree).root.get_visible_rect().size.y - chrome, 3.0 * LIST_ENTRY_HEIGHT)


func _build_list(column: VBoxContainer) -> void:
	_list_view = VBoxContainer.new()
	_list_view.name = "HistoryListView"
	_list_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_view.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(_list_view)
	_status = GrimmLabel.new()
	_status.name = "HistoryStatusLabel"
	_status.theme_type_variation = &"WarningLabel"
	_status.visible = false
	_list_view.add_child(_status)
	_empty = GrimmLabel.new()
	_empty.name = "HistoryEmptyLabel"
	_empty.theme_type_variation = &"MutedLabel"
	_empty.text_key = "ui.history.empty"
	_list_view.add_child(_empty)
	_list_host = VBoxContainer.new()
	_list_host.name = "HistoryListHost"
	_list_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_view.add_child(_list_host)


func _build_report(column: VBoxContainer) -> void:
	_report_view = VBoxContainer.new()
	_report_view.name = "HistoryReportView"
	_report_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_report_view.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(_report_view)
	var versions := HBoxContainer.new()
	versions.name = "HistoryVersionRow"
	versions.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_report_view.add_child(versions)
	var group := ButtonGroup.new()
	_public_button = _button("HistoryPublicButton", "ui.history.version.public")
	_public_button.toggle_mode = true
	_public_button.button_group = group
	_public_button.toggled.connect(func(on: bool) -> void:
		if on:
			choose_version(ReportText.PUBLIC))
	versions.add_child(_public_button)
	_gm_button = _button("HistoryGmButton", "ui.history.version.gm")
	_gm_button.toggle_mode = true
	_gm_button.button_group = group
	_gm_button.toggled.connect(func(on: bool) -> void:
		if on:
			choose_version(ReportText.GM))
	versions.add_child(_gm_button)
	_reopened = GrimmLabel.new()
	_reopened.name = "HistoryReopenedLabel"
	_reopened.theme_type_variation = &"WarningLabel"
	_reopened.text_key = "ui.history.reopened"
	_report_view.add_child(_reopened)
	_export_info = GrimmLabel.new()
	_export_info.name = "HistoryExportInfoLabel"
	_export_info.theme_type_variation = &"BadgeLabel"  # Mondsilber hell: der gedämpfte Hilfstext ist auf dem Tafelgrund zu blass
	_export_info.set_meta(&"keep_style", true)
	_export_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_view.add_child(_export_info)
	_report_host = VBoxContainer.new()
	_report_host.name = "HistoryReportHost"
	_report_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_report_view.add_child(_report_host)
	var actions := HBoxContainer.new()
	actions.name = "HistoryActions"
	actions.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_report_view.add_child(actions)
	_export = _button("HistoryExportButton", "ui.history.export.public")
	_export.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_export.pressed.connect(_on_export)
	actions.add_child(_export)
	_delete = _button("HistoryDeleteButton", "ui.history.delete")
	_delete.kind = GrimmButton.Kind.DANGER
	_delete.pressed.connect(_on_delete)
	actions.add_child(_delete)
	_feedback = GrimmLabel.new()
	_feedback.name = "HistoryFeedbackLabel"
	_feedback.theme_type_variation = &"MutedLabel"
	_feedback.visible = false
	_report_view.add_child(_feedback)


func _apply_version(version: String) -> void:
	_version = version
	_public_button.set_pressed_no_signal(version == ReportText.PUBLIC)
	_gm_button.set_pressed_no_signal(version == ReportText.GM)
	_set_feedback("")
	_render_report()


func _restore_version_buttons() -> void:
	_public_button.set_pressed_no_signal(_version == ReportText.PUBLIC)
	_gm_button.set_pressed_no_signal(_version == ReportText.GM)


func _render_report() -> void:
	_clear_report()
	var entry := context.history.get_entry(_game_id)
	if entry.is_empty():
		return
	var report: Dictionary = entry["report"]
	var gm := _version == ReportText.GM
	var reopened := str(entry["status"]) == HistoryStore.STATUS_REOPENED
	_reopened.visible = reopened
	_export_info.text_key = "ui.history.export_info.gm" if gm else "ui.history.export_info.public"
	_export.text_key = "ui.history.export.gm" if gm else "ui.history.export.public"
	_export.disabled = reopened
	_report_lines = ReportText.lines(report, _version, not reopened)
	var pager := CockpitLayers.Pager.new()
	pager.setup(_report_lines, _report_line, _line_height, _page_room(REPORT_CHROME), false, _is_heading)
	_report_host.add_child(pager)


func _clear_report() -> void:
	if _report_host == null:
		return
	for child: Node in _report_host.get_children():
		_report_host.remove_child(child)
		child.queue_free()
	_report_lines = []
	_reopened.visible = false


func _on_export() -> void:
	if not is_report_open() or _export.disabled:
		return
	_do_export(false)


func _do_export(overwrite: bool) -> void:
	var entry := context.history.get_entry(_game_id)
	if entry.is_empty():
		return
	var result := ReportExport.export(context.exports_dir, entry["report"], _version, overwrite, &"", str(entry["status"]) != HistoryStore.STATUS_REOPENED)
	if bool(result["ok"]):
		_set_feedback("ui.history.info.exported", {"path": ProjectSettings.globalize_path(str(result["path"]))}, &"MutedLabel")
	elif str(result["error"]) == "exists":
		var request := DialogRequest.create("ui.history.dialog.overwrite.title", "ui.history.dialog.overwrite.message", "ui.history.dialog.overwrite.confirm", _do_export.bind(true), true)
		request.message_values = {"file": str(result["path"]).get_file()}
		dialog_requested.emit(request)
	else:
		_set_feedback("ui.history.error.export", {}, &"ErrorLabel")


func _on_delete() -> void:
	if not is_report_open():
		return
	var request := DialogRequest.create("ui.history.dialog.delete.title", "ui.history.dialog.delete.message", "ui.history.dialog.delete.confirm", _do_delete, true)
	dialog_requested.emit(request)


func _do_delete() -> void:
	var result := context.history.delete(_game_id)
	if bool(result["ok"]):
		show_list()
		_status.visible = true
		_status.theme_type_variation = &"MutedLabel"
		_status.format_values = {}
		_status.text_key = "ui.history.info.deleted"
	else:
		_set_feedback("ui.history.error.delete", {}, &"ErrorLabel")


func _set_feedback(key: String, values: Dictionary = {}, variation: StringName = &"MutedLabel") -> void:
	_feedback.theme_type_variation = variation
	_feedback.format_values = values
	_feedback.text_key = key
	_feedback.visible = key != ""


func _date(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_datetime_string_from_unix_time(unix + bias, true).substr(0, 16)


func _node_part(id: String) -> String:
	return RegEx.create_from_string("[^A-Za-z0-9_]").sub(id, "_", true)


func _focus(target: Control) -> void:
	if target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


func _button(node_name: String, key: String, wrap: bool = false) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = wrap
	b.text_key = key
	return b
