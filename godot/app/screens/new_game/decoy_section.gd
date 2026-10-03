class_name DecoySection
extends PanelContainer
## Scheinrollen-Bereich einer Rolle mit Pflicht-Scheinrolle (Trugbilderwolf) im Rollenschritt,
## direkt unter ihrer Rollenzeile. Öffentlich sichtbar ist nur der Stand „Scheinrollen
## festgelegt: 1 von 2“. Kopien und Scheinrollen zeigt erst der bewusst geöffnete, als geheim
## markierte Bereich; Schließen nimmt ihm Sichtbarkeit, Fokus und Eingabe. Die Wahl läuft
## über einen modalen Dialog mit allen Nicht-Wolf-Rollen des Katalogs (DR-08). Das Setup belegt jede
## Kopie mit einer zufälligen Dorfrolle vor; der Spielleiter ändert sie hier. Alle Änderungen gehen über PlayerSetup.

signal dialog_requested(request: DialogRequest)

const ROW_SCENE := preload("res://app/screens/new_game/decoy_copy_row.tscn")

var decoy_role: StringName = &""  ## Rolle mit Pflicht-Scheinrolle, deren Kopien hier stehen
var _setup: PlayerSetup = null
var _revealed: bool = false
var _entries: Array = []

@onready var _status: GrimmLabel = %DecoyStatusLabel
@onready var _reveal: GrimmButton = %DecoyRevealButton
@onready var _panel: Control = %DecoySecretPanel
@onready var _list: VBoxContainer = %DecoyCopyList


func _ready() -> void:
	_reveal.pressed.connect(_on_reveal_pressed)
	_panel.visible = false


func start(setup: PlayerSetup, role: StringName) -> void:
	_setup = setup
	decoy_role = role


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for row: Node in _list.get_children():
			if row is DecoyCopyRow:
				(row as DecoyCopyRow).refresh_translation()


func is_revealed() -> bool:
	return _revealed


## Schließt den geheimen Bereich; Fokus darin wandert auf „Scheinrollen festlegen“.
func close() -> void:
	if not _revealed:
		return
	var owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var had_focus := owner != null and _panel.is_ancestor_of(owner)
	_revealed = false
	_panel.visible = false
	_reveal.text_key = "ui.setup.decoy.reveal"
	if had_focus:
		_reveal.grab_focus()


func render(roles: Dictionary) -> void:
	_entries.clear()
	for d: Variant in roles.get("decoys", []):
		if str((d as Dictionary)["role_id"]) == String(decoy_role):
			_entries.append(d)
	visible = not _entries.is_empty()
	if _entries.is_empty():
		close()
	var configured := 0
	for e: Variant in _entries:
		if bool((e as Dictionary)["configured"]):
			configured += 1
	_status.format_values = {"configured": configured, "total": _entries.size()}
	_status.text_key = "ui.setup.decoy.status"
	_status.theme_type_variation = &"MutedLabel" if configured == _entries.size() else &"WarningLabel"
	_render_rows()


func _render_rows() -> void:
	var ids: Array[int] = []
	for e: Variant in _entries:
		ids.append(int((e as Dictionary)["copy_id"]))
	var current: Array[int] = []
	for child: Node in _list.get_children():
		if child is DecoyCopyRow:
			current.append((child as DecoyCopyRow).copy_id)
	if current != ids:
		var owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
		var had_focus := owner != null and _list.is_ancestor_of(owner)
		for child: Node in _list.get_children():
			_list.remove_child(child)
			child.queue_free()
		for e: Variant in _entries:
			var row := ROW_SCENE.instantiate() as DecoyCopyRow
			_list.add_child(row)
			row.choose_requested.connect(_on_choose_requested)
			row.remove_requested.connect(_on_remove_requested)
		if had_focus:
			_reveal.grab_focus()
	var rows := _list.get_children()
	for i: int in _entries.size():
		(rows[i] as DecoyCopyRow).show_copy(_entries[i])


func _on_reveal_pressed() -> void:
	if _revealed:
		close()
		return
	_revealed = true
	_panel.visible = true
	_reveal.text_key = "ui.setup.decoy.hide"


func _entry(copy_id: int) -> Dictionary:
	for e: Variant in _entries:
		if int((e as Dictionary)["copy_id"]) == copy_id:
			return e as Dictionary
	return {}


## Modale Auswahl: alle Nicht-Wolf-Rollen des Katalogs, auch außerhalb des Pools.
func _on_choose_requested(copy_id: int) -> void:
	var entry := _entry(copy_id)
	if entry.is_empty():
		return
	var request := DialogRequest.create("ui.setup.decoy.picker.title", "ui.setup.decoy.picker.message", "")
	request.message_values = {"number": entry["number"]}
	var options: Array = _setup.view()["roles"]["appearance_options"]
	for role: StringName in RolePresentation.sorted_roles():
		if not options.has(String(role)):
			continue
		var current := String(role) == str(entry["appears_as"])
		var values := {"name": tr(RolePresentation.name_key(role))}
		var key := "ui.setup.decoy.picker.current" if current else RolePresentation.name_key(role)
		request.options.append(DialogOption.create("Appear_%s" % String(role), key, values if current else {}, _set_appearance.bind(copy_id, role)))
	dialog_requested.emit(request)


func _set_appearance(copy_id: int, role: StringName) -> void:
	_setup.set_decoy_appearance(copy_id, role)


## Unkonfigurierte Kopie ohne Rückfrage entfernen; eine konfigurierte nur nach Rückfrage, die
## die Kopie nennt (ohne ihre Scheinrolle).
func _on_remove_requested(copy_id: int) -> void:
	var entry := _entry(copy_id)
	if entry.is_empty():
		return
	if not bool(entry["configured"]) or bool(entry.get("auto", false)):
		_setup.remove_decoy_copy(copy_id)
		return
	dialog_requested.emit(removal_request(copy_id, int(entry["number"])))


func removal_request(copy_id: int, copy_number: int) -> DialogRequest:
	var request := DialogRequest.create("ui.setup.dialog.remove_copy.title", "ui.setup.dialog.remove_copy.message", "ui.setup.dialog.remove_copy.confirm", _remove_copy.bind(copy_id), true)
	request.message_values = {"copy": tr("ui.setup.decoy.copy").format({"number": copy_number})}
	return request


func _remove_copy(copy_id: int) -> void:
	_setup.remove_decoy_copy(copy_id)
	if _revealed and is_visible_in_tree():
		_reveal.grab_focus()
