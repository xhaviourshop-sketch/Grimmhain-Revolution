class_name ContinueScreen
extends BaseScreen
## Gespeicherte Partien fortsetzen (SaveService): je Partie eine Karte mit Namen, Phase, Runde und
## Speicherzeit, „Fortsetzen“ und „Verwerfen …“. Ohne Spielstand der leere Zustand. Die Liste zeigt
## nur öffentliche Angaben (keine Rollen). Verwerfen benennt die Dateien nur um.

const MAX_LISTED := 8  ## die neuesten Partien; ältere bleiben auf dem Datenträger

@onready var _list: VBoxContainer = %SaveSlotList
@onready var _empty: Control = %EmptyStateLabel
@onready var _empty_hint: Control = %EmptyHintLabel


func _setup() -> void:
	(%Card as Control).custom_minimum_size.x = ThemeTokens.CONTENT_MAX_WIDTH
	_render()


func default_focus() -> Control:
	var first := _list.find_children("ResumeButton_*", "BaseButton", true, false)
	return first[0] as Control if not first.is_empty() else super.default_focus()


func _render() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var games := context.saves.list()
	_empty.visible = games.is_empty()
	_empty_hint.visible = games.is_empty()
	for i: int in mini(games.size(), MAX_LISTED):
		_list.add_child(_slot(games[i]))


func _slot(game: Dictionary) -> Control:
	var id := str(game["round_id"])
	var summary: Dictionary = game.get("summary", {})
	var panel := PanelContainer.new()
	panel.name = "Slot_%s" % id
	panel.theme_type_variation = &"PersonRowPanel"
	var column := VBoxContainer.new()
	panel.add_child(column)
	var names: Array = summary.get("names", [])
	var title := GrimmLabel.new()
	title.theme_type_variation = &"SectionLabel"
	title.format_values = {"names": ", ".join(names.slice(0, 5)) + (" …" if names.size() > 5 else ""), "count": int(summary.get("player_count", names.size()))}
	title.text_key = "ui.continue.slot.title" if bool(game["readable"]) else "ui.continue.slot.unreadable"
	column.add_child(title)
	if bool(game["readable"]):
		var detail := GrimmLabel.new()
		detail.theme_type_variation = &"MutedLabel"
		detail.format_values = {"phase": StringName("ui.phase.%s" % str(summary.get("phase", "")).to_lower()),
			"night": int(summary.get("night_number", 0)), "day": int(summary.get("day_number", 0)),
			"alive": int(summary.get("alive_count", 0)), "saved": _time_text(int(game["saved_at"]))}
		detail.text_key = "ui.continue.slot.detail"
		column.add_child(detail)
	var compatible := bool(game.get("compatible", true))
	if bool(game["readable"]) and not compatible:
		var note := GrimmLabel.new()
		note.name = "IncompatibleLabel"
		note.theme_type_variation = &"WarningLabel"
		note.format_values = {"found": int(game.get("schema", -1)), "expected": int(game.get("expected", -1))}
		note.text_key = "ui.continue.slot.incompatible"
		column.add_child(note)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"ButtonRow"
	column.add_child(row)
	var resume := GrimmButton.new()
	resume.name = "ResumeButton_%s" % id
	resume.kind = GrimmButton.Kind.PRIMARY
	resume.text_key = "ui.continue.resume"
	resume.disabled = not compatible  # Spielstand anderer Version: nicht fortsetzbar, Datei bleibt unverändert
	resume.pressed.connect(_resume.bind(id))
	row.add_child(resume)
	var discard := GrimmButton.new()
	discard.name = "DiscardButton_%s" % id
	discard.kind = GrimmButton.Kind.DANGER
	discard.text_key = "ui.continue.discard"
	discard.pressed.connect(_ask_discard.bind(id))
	row.add_child(discard)
	return panel


## Ortszeit „29.09.2026 21:40“ (Nutzerdaten, keine Übersetzung nötig).
func _time_text(unix: int) -> String:
	if unix <= 0:
		return "–"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(unix + bias)
	return "%02d.%02d.%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


func _resume(id: String) -> void:
	var current := context.session.round_id()
	if current != "" and current != id and not bool(context.saves.last_status.get("ok", true)):
		# Die laufende Partie ist zuletzt nicht gespeichert worden: nicht still verwerfen.
		dialog_requested.emit(DialogRequest.create("ui.continue.unsaved.title", "ui.continue.unsaved.message",
			"ui.continue.unsaved.confirm", _load.bind(id), true))
		return
	_load(id)


func _load(id: String) -> void:
	var result := context.resume(id)
	if not bool(result["ok"]):
		status_message_requested.emit("ui.continue.status.incompatible" if str(result.get("error", "")) == "incompatible" else "ui.continue.status.failed")
		_render()
		return
	match str(result.get("recovered", "")):
		"backup":
			status_message_requested.emit("ui.continue.status.recovered_backup")
		"tmp":
			status_message_requested.emit("ui.continue.status.recovered_tmp")
		_:
			status_message_requested.emit("ui.continue.status.resumed")
	navigate_requested.emit(ScreenIds.COCKPIT)


func _ask_discard(id: String) -> void:
	dialog_requested.emit(DialogRequest.create("ui.continue.discard_dialog.title", "ui.continue.discard_dialog.message",
		"ui.continue.discard_dialog.confirm", _discard.bind(id), true))


func _discard(id: String) -> void:
	context.saves.discard(id)
	if context.session.round_id() == id:
		context.session.reset()
	status_message_requested.emit("ui.continue.status.discarded")
	_render()
