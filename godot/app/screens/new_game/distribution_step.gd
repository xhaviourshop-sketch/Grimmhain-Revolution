class_name DistributionStep
extends VBoxContainer
## Wizard-Schritt 3 „Verteilung“: Modus wählen (zufällig oder manuell), verteilen, neu mischen,
## manuell zuweisen und bestätigen. Rollen sind geheim: Die Standardansicht zeigt nur
## „zugewiesen“; Rollen und Scheinrollen erscheinen ausschließlich im bewusst geöffneten,
## markierten Spielleiterbereich (AssignmentPanel mit SecretHeading) und in der modalen
## Rollenauswahl. Statusmeldungen, Dialogtitel und Status nennen keine Rolle.
## Alle Daten und Regeln kommen aus PlayerSetup; Zeilen werden nur bei geänderten Personen neu
## gebaut, sonst aktualisiert.

signal dialog_requested(request: DialogRequest)
signal status_message_requested(text_key: String)
signal roles_requested  ## „Rollen bearbeiten“
signal seating_requested  ## „Weiter zur Sitzordnung“ in der Karte „Bereit für Sitzordnung“

const ROW_SCENE := preload("res://app/screens/new_game/assignment_row.tscn")

var _setup: PlayerSetup = null
var _revealed: bool = false
var _rows: Dictionary[int, AssignmentRow] = {}
var _last_view: Dictionary = {}

@onready var _counts: GrimmLabel = %DistributionCountsLabel
@onready var _invalidated: GrimmLabel = %DistributionInvalidatedLabel
@onready var _mode_random: GrimmButton = %ModeRandomButton
@onready var _mode_manual: GrimmButton = %ModeManualButton
@onready var _mode_state: GrimmLabel = %ModeStateLabel
@onready var _distribute: GrimmButton = %DistributeButton
@onready var _reshuffle: GrimmButton = %ReshuffleButton
@onready var _seed: GrimmLabel = %SeedLabel
@onready var _reveal: GrimmButton = %RevealButton
@onready var _remaining_count: GrimmLabel = %RemainingCountLabel
@onready var _summary: Control = %DistributionSummary
@onready var _summary_body: GrimmLabel = %SummaryBody
@onready var _panel: PanelContainer = %AssignmentPanel
@onready var _secret_heading: Control = %SecretHeading
@onready var _remaining_pool: GrimmLabel = %RemainingPoolLabel
@onready var _scroll: ScrollContainer = %AssignmentScroll
@onready var _list: VBoxContainer = %AssignmentList
@onready var _edit_roles: GrimmButton = %EditRolesButton
@onready var _status: GrimmLabel = %DistributionStatusLabel
@onready var _confirm: GrimmButton = %ConfirmDistributionButton
@onready var _to_seating: GrimmButton = %ToSeatingButton


## Wird vom Host einmal nach `_ready` aufgerufen.
func start(setup: PlayerSetup) -> void:
	_setup = setup
	(%DistributionSideColumn as Control).custom_minimum_size.x = ThemeTokens.SETUP_SIDE_WIDTH
	_scroll.custom_minimum_size.y = ThemeTokens.ROLE_LIST_MIN_HEIGHT
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	(%DistributionSideScroll as ScrollContainer).horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	(%DistributionSideScroll as ScrollContainer).follow_focus = true
	_mode_random.pressed.connect(_on_mode_pressed.bind(DistributionDraft.RANDOM))
	_mode_manual.pressed.connect(_on_mode_pressed.bind(DistributionDraft.MANUAL))
	_distribute.pressed.connect(_on_distribute_pressed)
	_reshuffle.pressed.connect(_on_reshuffle_pressed)
	_reveal.pressed.connect(_on_reveal_pressed)
	_edit_roles.pressed.connect(roles_requested.emit)
	_to_seating.pressed.connect(seating_requested.emit)
	_confirm.pressed.connect(_on_confirm_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_setup.changed.connect(_render)
	_render(_setup.view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _last_view.is_empty():
		_render(_last_view)


func default_focus() -> Control:
	if _to_seating.is_visible_in_tree():
		return _to_seating
	if not _confirm.disabled:
		return _confirm
	return _distribute if _distribute.visible else _mode_random


func handle_back() -> bool:
	return false


## Beim Verlassen oder erneuten Anzeigen ist der Spielleiterbereich immer geschlossen.
func _on_visibility_changed() -> void:
	if not visible and _revealed:
		_revealed = false
		if not _last_view.is_empty():
			_render(_last_view)


# --- Darstellung ------------------------------------------------------------------------------------

func _render(view: Dictionary) -> void:
	_last_view = view
	var dist: Dictionary = view["distribution"]
	var manual := str(dist["mode"]) == String(DistributionDraft.MANUAL)
	var has_assignment := bool(dist["has_assignment"])
	_counts.format_values = {"persons": dist["person_count"], "roles": dist["role_count"]}
	_counts.text_key = "ui.setup.distribution.counts"
	var reason := str(dist["invalidated"])
	_invalidated.visible = reason != "" and not has_assignment
	_invalidated.text_key = "ui.setup.distribution.invalidated.%s" % reason if _invalidated.visible else ""
	_render_mode(manual)
	_distribute.visible = not manual and not has_assignment
	_reshuffle.visible = not manual and has_assignment
	if bool(dist["has_seed"]):
		_seed.format_values = {"seed": dist["seed"], "count": dist["shuffle_count"]}
		_seed.text_key = "ui.setup.distribution.seed"
	else:
		_seed.text_key = "ui.setup.distribution.seed_none"
	_reveal.text_key = "ui.setup.distribution.hide" if _revealed else "ui.setup.distribution.reveal"
	_panel.theme_type_variation = &"SecretPanel" if _revealed else &"ListPanel"
	_secret_heading.visible = _revealed
	var remaining := int(dist["remaining_total"])
	_remaining_count.format_values = {"count": remaining}
	_remaining_count.text_key = "ui.setup.distribution.remaining_count" if remaining > 0 else "ui.setup.distribution.remaining_none"
	_render_remaining_pool(dist, manual)
	_render_rows(dist["assignment"] as Array, manual)
	_render_summary(dist)
	_confirm.disabled = not bool(dist["can_confirm"])
	if bool(dist["confirmed"]):
		_status.text_key = "ui.setup.distribution.status.confirmed"
	elif bool(dist["complete"]):
		_status.text_key = "ui.setup.distribution.status.complete"
	elif int(dist["assigned_count"]) > 0:
		_status.format_values = {"assigned": dist["assigned_count"], "persons": dist["person_count"]}
		_status.text_key = "ui.setup.distribution.status.partial"
	else:
		_status.text_key = "ui.setup.distribution.status.none"


## Aktiver Modus in Primärfarbe und zusätzlich als Text (nicht nur Farbe). Beide Buttons
## behalten die Größe eines Sekundärbuttons, damit sie nebeneinander passen.
func _render_mode(manual: bool) -> void:
	_mode_random.theme_type_variation = &"SecondaryButton" if manual else &"PrimaryButton"
	_mode_manual.theme_type_variation = &"PrimaryButton" if manual else &"SecondaryButton"
	var mode := "manual" if manual else "random"
	_mode_state.format_values = {"mode": tr("ui.setup.distribution.mode.%s" % mode), "hint": tr("ui.setup.distribution.mode.%s_hint" % mode)}
	_mode_state.text_key = "ui.setup.distribution.mode.active"


## Restbestand mit Rollennamen nur im geöffneten Spielleiterbereich.
func _render_remaining_pool(dist: Dictionary, manual: bool) -> void:
	var remaining: Dictionary = dist["remaining"]
	var show := _revealed and manual and not remaining.is_empty()
	_remaining_pool.visible = show
	if not show:
		_remaining_pool.text_key = ""
		return
	var items: Array[String] = []
	for role: StringName in RolePresentation.sorted_roles():
		if remaining.has(String(role)):
			items.append(tr("ui.setup.distribution.remaining_item").format({"name": tr(RolePresentation.name_key(role)), "count": remaining[String(role)]}))
	_remaining_pool.format_values = {"roles": ", ".join(items)}
	_remaining_pool.text_key = "ui.setup.distribution.remaining_pool"


## Zeilen nur bei geänderten Personen neu bauen; sonst in place aktualisieren.
func _render_rows(entries: Array, manual: bool) -> void:
	var ids: Array[int] = []
	for entry: Variant in entries:
		ids.append(int((entry as Dictionary)["person_id"]))
	var current: Array[int] = []
	for child: Node in _list.get_children():
		if child is AssignmentRow:
			current.append((child as AssignmentRow).person_id)
	if current != ids:
		for child: Node in _list.get_children():
			_list.remove_child(child)
			child.queue_free()
		_rows.clear()
		for id: int in ids:
			var row := ROW_SCENE.instantiate() as AssignmentRow
			_list.add_child(row)
			row.choose_requested.connect(_on_choose_requested)
			_rows[id] = row
	for entry: Variant in entries:
		var e: Dictionary = entry
		_rows[int(e["person_id"])].show_entry(e, _revealed, manual)


func _render_summary(dist: Dictionary) -> void:
	var confirmed := bool(dist["confirmed"])
	_summary.visible = confirmed
	if not confirmed:
		return
	var factions: Dictionary = dist["factions"]
	_summary_body.format_values = {
		"persons": dist["person_count"],
		"village": factions.get(String(Faction.VILLAGE), 0),
		"wolves": factions.get(String(Faction.WOLVES), 0),
		"solo": factions.get(String(Faction.SOLO), 0),
		"mode": tr("ui.setup.distribution.mode.%s" % str(dist["mode"])),
		"seed": dist["seed"] if bool(dist["has_seed"]) else tr("ui.setup.distribution.summary.no_seed"),
	}
	_summary_body.text_key = "ui.setup.distribution.summary.body"


# --- Aktionen ---------------------------------------------------------------------------------------

func _on_mode_pressed(mode: StringName) -> void:
	var result := _setup.set_distribution_mode(mode)
	if result.ok or result.error != &"confirmation_required":
		return
	var request := DialogRequest.create("ui.setup.dialog.mode.title", "ui.setup.dialog.mode.message", "ui.setup.dialog.mode.confirm", _force_mode.bind(mode), true)
	dialog_requested.emit(request)


func _force_mode(mode: StringName) -> void:
	_setup.set_distribution_mode(mode, true)
	(_mode_manual if mode == DistributionDraft.MANUAL else _mode_random).grab_focus()


func _on_distribute_pressed() -> void:
	if not _distribute.visible:
		return
	if _setup.distribute_randomly().ok:
		status_message_requested.emit("ui.setup.distribution.toast.distributed")
		_reshuffle.grab_focus()


func _on_reshuffle_pressed() -> void:
	if not _reshuffle.visible:
		return
	if _setup.reshuffle().ok:
		status_message_requested.emit("ui.setup.distribution.toast.reshuffled")


func _on_reveal_pressed() -> void:
	_revealed = not _revealed
	_render(_last_view)


func _on_confirm_pressed() -> void:
	if _confirm.disabled:
		return
	if _setup.confirm_distribution().ok:
		status_message_requested.emit("ui.setup.distribution.toast.confirmed")
		_to_seating.grab_focus()


# --- Manuelle Rollenauswahl (modaler Dialog) ---------------------------------------------------------

func _on_choose_requested(person_id: int) -> void:
	var dist: Dictionary = _last_view["distribution"]
	var entry := _entry_for(dist, person_id)
	if entry.is_empty():
		return
	var current := _unit_of(entry)
	var remaining: Dictionary = dist["remaining"]
	var request := DialogRequest.create("ui.setup.distribution.picker.title", "ui.setup.distribution.picker.message", "")
	request.title_values = {"number": entry["number"]}
	request.message_values = {"name": entry["name"]}
	for role: StringName in RolePresentation.sorted_roles():
		if SetupRoleCatalog.requires_appearance(role):
			_add_copy_options(request, dist, role, person_id, current)
			continue
		var free := int(remaining.get(String(role), 0))
		if free > 0 and String(role) != current:
			var values := {"name": tr(RolePresentation.name_key(role)), "count": free}
			request.options.append(DialogOption.create("Pick_%s" % String(role), "ui.setup.distribution.picker.option", values, _assign.bind(person_id, role)))
	if current != "":
		request.options.append(DialogOption.create("UnassignOption", "ui.setup.distribution.picker.unassign", {}, _unassign.bind(person_id)))
	var swaps: Array[DialogOption] = []
	for other: Variant in dist["assignment"]:
		var o: Dictionary = other
		if int(o["person_id"]) != person_id and _unit_of(o) != "" and _unit_of(o) != current:
			swaps.append(DialogOption.create("Swap_%d" % int(o["person_id"]), "ui.setup.distribution.picker.swap_option", {"number": o["number"], "name": o["name"]}, _swap.bind(person_id, int(o["person_id"]))))
	if not swaps.is_empty():
		request.options.append(DialogOption.header("ui.setup.distribution.picker.swap_heading"))
		request.options.append_array(swaps)
	dialog_requested.emit(request)


## Jede freie Kopie einer Rolle mit Scheinrolle einzeln: „Trugbilderwolf 2 · Scheinrolle: …“.
func _add_copy_options(request: DialogRequest, dist: Dictionary, role: StringName, person_id: int, current: String) -> void:
	for c: Variant in dist["remaining_copies"]:
		var copy: Dictionary = c
		if str(copy["role_id"]) != String(role) or str(copy["key"]) == current:
			continue
		var values := {
			"copy": tr("ui.setup.decoy.copy").format({"number": copy["number"]}),
			"appearance": tr(RolePresentation.name_key(StringName(str(copy["appears_as"])))),
		}
		var node_name := "Pick_%s_%s" % [String(role), str(copy["key"]).get_slice(RoleCopy.KEY_SEPARATOR, 1)]
		request.options.append(DialogOption.create(node_name, "ui.setup.distribution.picker.copy_option", values, _assign.bind(person_id, StringName(str(copy["key"])))))


## Verteilungseinheit eines Eintrags: Kopien-Schlüssel oder Rollen-ID ("" = nicht zugewiesen).
static func _unit_of(entry: Dictionary) -> String:
	return str(entry["copy_key"]) if str(entry["copy_key"]) != "" else str(entry["role"])


func _entry_for(dist: Dictionary, person_id: int) -> Dictionary:
	for entry: Variant in dist["assignment"]:
		if int((entry as Dictionary)["person_id"]) == person_id:
			return entry as Dictionary
	return {}


func _assign(person_id: int, role: StringName) -> void:
	_setup.assign_role(person_id, role)


func _unassign(person_id: int) -> void:
	_setup.unassign_role(person_id)


func _swap(person_id: int, other_id: int) -> void:
	_setup.swap_roles(person_id, other_id)
