class_name ContinueScreen
extends BaseScreen
## Gespeicherte Partien fortsetzen (SaveService): je Partie eine Karte mit Namen, Phase, Runde und
## Speicherzeit, „Fortsetzen“ (beendet: „Bericht“) und „Löschen“. Ohne Spielstand der leere Zustand. Die Liste zeigt
## nur öffentliche Angaben (keine Rollen). Verwerfen benennt die Dateien nur um.

const MAX_LISTED := 3  ## die neuesten Partien (mehr passen nicht ohne Scrollen auf den Bildschirm); ältere bleiben auf dem Datenträger
const BUTTON_WIDTH := 170  ## Breite jedes Knopfes einer Zeile: das gemalte Band braucht Platz neben dem Text

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
	var readable := bool(game["readable"])
	var compatible := bool(game.get("compatible", true))
	var panel := PanelContainer.new()
	panel.name = "Slot_%s" % id
	panel.theme_type_variation = &"ListPanel"  # Fläche aus Grund und Rahmen (neun Felder), wächst mit dem Inhalt ohne Verzerrung
	var column := VBoxContainer.new()
	panel.add_child(column)
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	var names: Array = summary.get("names", [])
	if readable:  # Zustand zuerst und groß, damit man nicht die falsche Partie greift
		var status := GrimmLabel.new()
		status.name = "StatusLabel"
		status.theme_type_variation = &"HeadingLabel"
		status.format_values = {"n": status_number(summary)}
		status.text_key = status_key(str(summary.get("phase", "")))
		column.add_child(status)
	var title := GrimmLabel.new()
	title.theme_type_variation = &"SectionLabel"
	title.format_values = {"names": ", ".join(names.slice(0, 5)) + (" …" if names.size() > 5 else ""), "count": int(summary.get("player_count", names.size()))}
	title.text_key = "ui.continue.slot.title" if readable else "ui.continue.slot.unreadable"
	column.add_child(title)
	if readable and not compatible:
		var note := GrimmLabel.new()
		note.name = "IncompatibleLabel"
		note.theme_type_variation = &"WarningLabel"
		note.format_values = {"found": str(game.get("found_label", "")), "expected": str(game.get("expected_label", ""))}
		note.text_key = "ui.continue.slot.incompatible"
		column.add_child(note)
	# Unterste Zeile: „Löschen“ links, Angaben in der Mitte, Hauptknopf rechts (räumlich getrennt: kein Fehltippen).
	var line := HBoxContainer.new()
	column.add_child(line)
	line.add_child(_button("DiscardButton_%s" % id, "ui.continue.discard", _ask_discard.bind(id)))
	var detail := GrimmLabel.new()
	detail.theme_type_variation = &"MutedLabel"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if readable:
		detail.format_values = {"alive": int(summary.get("alive_count", 0)), "saved": _time_text(int(game["saved_at"]))}
		detail.text_key = "ui.continue.slot.detail"
	line.add_child(detail)
	var buttons := slot_buttons(str(summary.get("phase", "")), context.history.has(id))
	if buttons.has(&"resume"):
		var resume := _button("ResumeButton_%s" % id, "ui.continue.resume", _resume.bind(id))
		resume.disabled = not compatible  # Spielstand anderer Version: nicht fortsetzbar, Datei bleibt unverändert
		line.add_child(resume)
	if buttons.has(&"report"):
		line.add_child(_button("ReportButton_%s" % id, "ui.continue.report", _open_report.bind(id)))
	return panel


## Knopf einer Zeile: alle gleich groß und gleiche Schrift.
func _button(button_name: String, key: String, on_pressed: Callable) -> GrimmButton:
	var button := GrimmButton.new()
	button.name = button_name
	button.kind = GrimmButton.Kind.COMPACT
	button.text_key = key
	button.custom_minimum_size.x = BUTTON_WIDTH
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(on_pressed)
	return button


## Zustandszeile einer Partie: laufend mit Runde, Vorbereitung, beendet.
static func status_key(phase: String) -> String:
	match phase:
		String(Phase.NIGHT), String(Phase.DAWN_RESOLUTION):
			return "ui.continue.slot.status.night"
		String(Phase.DAY):
			return "ui.continue.slot.status.day"
		String(Phase.GAME_OVER):
			return "ui.continue.slot.status.over"
	return "ui.continue.slot.status.running"


static func status_number(summary: Dictionary) -> int:
	return int(summary.get("day_number", 0)) if str(summary.get("phase", "")) == String(Phase.DAY) else int(summary.get("night_number", 0))


## Knöpfe einer Zeile: laufende Partie „Fortsetzen“, beendete Partie „Bericht“ (nur mit gespeichertem Bericht), immer „Löschen“.
## Eine beendete Partie wird nie fortgesetzt.
static func slot_buttons(phase: String, has_report: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	if phase == String(Phase.GAME_OVER):
		if has_report:
			out.append(&"report")
	else:
		out.append(&"resume")
	out.append(&"discard")
	return out


func _open_report(id: String) -> void:
	context.history_focus = id
	navigate_requested.emit(ScreenIds.HISTORY)


## Ortszeit „29.09.2026 21:40“ (Nutzerdaten, keine Übersetzung nötig).
func _time_text(unix: int) -> String:
	if unix <= 0:
		return "–"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(unix + bias)
	return "%02d.%02d.%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]  # fester Leerraum: Datum und Uhrzeit brechen nicht auseinander


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
	if context.session.is_over():  # nie in eine beendete Partie zurück: der Bericht ist ihr Ziel
		_open_report(context.session.round_id())
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
