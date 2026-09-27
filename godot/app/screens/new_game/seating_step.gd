class_name SeatingStep
extends VBoxContainer
## Wizard-Schritt 4 „Sitzordnung“: Sitzkreis mit allen Personen, Tauschen per Drag-and-drop oder
## durch zweimaliges Antippen (erste Person auswählen, dann Zielplatz). Zeigt nur Platznummer und
## Namen, nie Rollen. „Sitzordnung bestätigen“ schließt das Setup ab; es entsteht weder ein Befehl
## noch ein GameState. Alle Daten und Regeln kommen aus PlayerSetup.

signal dialog_requested(request: DialogRequest)
signal status_message_requested(text_key: String)
signal distribution_requested  ## „Verteilung bearbeiten“

var _setup: PlayerSetup = null
var _selected_id: int = 0
var _last_view: Dictionary = {}

@onready var _circle: SeatCircle = %SeatCircle
@onready var _counts: GrimmLabel = %SeatingCountsLabel
@onready var _invalidated: GrimmLabel = %SeatingInvalidatedLabel
@onready var _hint: GrimmLabel = %SeatingHintLabel
@onready var _selection: GrimmLabel = %SelectionLabel
@onready var _cancel_selection: GrimmButton = %CancelSelectionButton
@onready var _summary: Control = %SeatingSummary
@onready var _summary_body: GrimmLabel = %SeatingSummaryBody
@onready var _edit_distribution: GrimmButton = %EditDistributionButton
@onready var _status: GrimmLabel = %SeatingStatusLabel
@onready var _confirm: GrimmButton = %ConfirmSeatingButton


## Wird vom Host einmal nach `_ready` aufgerufen.
func start(setup: PlayerSetup) -> void:
	_setup = setup
	_circle.custom_minimum_size.y = ThemeTokens.SEAT_CIRCLE_MIN_HEIGHT
	_circle.seat_tapped.connect(_on_seat_tapped)
	_circle.swap_requested.connect(_swap)
	_circle.drag_begun.connect(func(_id: int) -> void: _select(0))
	_circle.drag_cancelled.connect(_on_drag_cancelled)
	_cancel_selection.pressed.connect(_select.bind(0))
	_edit_distribution.pressed.connect(distribution_requested.emit)
	_confirm.pressed.connect(_on_confirm_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_setup.changed.connect(_render)
	_render(_setup.view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _last_view.is_empty():
		_render(_last_view)


func default_focus() -> Control:
	return _confirm if not _confirm.disabled else _edit_distribution


## Zurück hebt zuerst eine Auswahl auf; sonst entscheidet der Host (zur Verteilung).
func handle_back() -> bool:
	if _selected_id != 0:
		_select(0)
		return true
	return false


func _on_visibility_changed() -> void:
	if not visible and _selected_id != 0:
		_select(0)


# --- Darstellung ------------------------------------------------------------------------------------

func _render(view: Dictionary) -> void:
	_last_view = view
	var seating: Dictionary = view["seating"]
	_circle.show_seats(seating["seats"] as Array)
	_counts.format_values = {"count": seating["person_count"]}
	_counts.text_key = "ui.setup.seating.counts"
	var reason := str(seating["invalidated"])
	_invalidated.visible = reason != ""
	_invalidated.text_key = "ui.setup.seating.invalidated.%s" % reason if reason != "" else ""
	var confirmed := bool(seating["confirmed"])
	_hint.visible = not confirmed
	_summary.visible = confirmed
	if confirmed:
		_summary_body.format_values = {"count": seating["person_count"]}
		_summary_body.text_key = "ui.setup.seating.summary.body"
	_confirm.disabled = not bool(seating["can_confirm"])
	if confirmed:
		_set_status("ui.setup.seating.status.confirmed")
	elif _status.text_key == "ui.setup.seating.status.confirmed":
		_set_status("ui.setup.seating.status.ready")
	if _selected_id != 0 and _seat_of(_selected_id) == 0:
		_selected_id = 0
	_render_selection()
	if _status.text_key == "":
		_set_status("ui.setup.seating.status.ready")


func _render_selection() -> void:
	_circle.set_selected(_selected_id)
	var active := _selected_id != 0
	_selection.visible = active
	_cancel_selection.visible = active
	if active:
		_selection.format_values = {"name": _name_of(_selected_id), "seat": _seat_of(_selected_id)}
		_selection.text_key = "ui.setup.seating.selection"
	else:
		_selection.text_key = ""


func _set_status(key: String, values: Dictionary = {}) -> void:
	_status.format_values = values
	_status.text_key = key


# --- Aktionen ---------------------------------------------------------------------------------------

## Antippen: erste Person auswählen, dieselbe erneut hebt die Auswahl auf, eine andere tauscht.
func _on_seat_tapped(person_id: int) -> void:
	if _selected_id == 0:
		_select(person_id)
	elif _selected_id == person_id:
		_select(0)
		_set_status("ui.setup.seating.status.selection_cleared")
	else:
		var first := _selected_id
		_selected_id = 0
		_swap(first, person_id)


func _select(person_id: int) -> void:
	_selected_id = person_id
	_render_selection()
	if person_id != 0:
		_set_status("ui.setup.seating.status.selected", {"name": _name_of(person_id)})


func _swap(first_id: int, second_id: int) -> void:
	var names := {"first": _name_of(first_id), "second": _name_of(second_id)}
	var result := _setup.swap_seats(first_id, second_id)
	if not result.ok:
		_render_selection()
		return
	_set_status("ui.setup.seating.status.swapped", names)
	status_message_requested.emit("ui.setup.seating.toast.swapped")
	var token := _circle.token_for(second_id)
	if token != null:
		token.grab_focus()


func _on_drag_cancelled(person_id: int) -> void:
	_set_status("ui.setup.seating.status.drag_cancelled", {"name": _name_of(person_id)})


func _on_confirm_pressed() -> void:
	if _confirm.disabled:
		return
	_select(0)
	if _setup.confirm_seating().ok:
		status_message_requested.emit("ui.setup.seating.toast.confirmed")
		_edit_distribution.grab_focus()


func _seat_of(person_id: int) -> int:
	for seat: Variant in (_last_view["seating"] as Dictionary)["seats"]:
		if int((seat as Dictionary)["person_id"]) == person_id:
			return int((seat as Dictionary)["seat"])
	return 0


func _name_of(person_id: int) -> String:
	for seat: Variant in (_last_view["seating"] as Dictionary)["seats"]:
		if int((seat as Dictionary)["person_id"]) == person_id:
			return str((seat as Dictionary)["name"])
	return ""
