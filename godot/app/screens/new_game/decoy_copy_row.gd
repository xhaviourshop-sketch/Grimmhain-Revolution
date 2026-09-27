class_name DecoyCopyRow
extends PanelContainer
## Eine Trugbilderwolf-Kopie im geheimen Scheinrollen-Bereich: „Trugbilderwolf 2“, gewählte
## Scheinrolle oder „Scheinrolle fehlt“, Wählen bzw. Ändern und Entfernen. Die Kopien-ID
## wird nur intern gehalten. Meldet Wünsche als Signale; ändert selbst nichts.

signal choose_requested(copy_id: int)
signal remove_requested(copy_id: int)

var copy_id: int = -1
var number: int = 0
var appears_as: String = ""

@onready var _copy: GrimmLabel = %DecoyCopyLabel
@onready var _appearance: GrimmLabel = %DecoyAppearanceLabel
@onready var _choose: GrimmButton = %ChooseAppearanceButton
@onready var _remove: GrimmButton = %RemoveCopyButton


func _ready() -> void:
	_choose.pressed.connect(func() -> void: choose_requested.emit(copy_id))
	_remove.pressed.connect(func() -> void: remove_requested.emit(copy_id))


## `entry` aus PlayerSetup.view()["roles"]["decoys"].
func show_copy(entry: Dictionary) -> void:
	copy_id = int(entry["copy_id"])
	number = int(entry["number"])
	appears_as = str(entry["appears_as"])
	_copy.format_values = {"number": number}
	_copy.text_key = "ui.setup.decoy.copy"
	if appears_as == "":
		_appearance.theme_type_variation = &"WarningLabel"
		_appearance.format_values = {}
		_appearance.text_key = "ui.setup.decoy.missing"
		_choose.text_key = "ui.setup.decoy.choose"
	else:
		_appearance.theme_type_variation = &"MutedLabel"
		_appearance.format_values = {"role": tr(RolePresentation.name_key(StringName(appears_as)))}
		_appearance.text_key = "ui.setup.decoy.chosen"
		_choose.text_key = "ui.setup.decoy.change"


func refresh_translation() -> void:
	if appears_as != "":
		_appearance.format_values = {"role": tr(RolePresentation.name_key(StringName(appears_as)))}


func choose_button() -> GrimmButton:
	return _choose


func remove_button() -> GrimmButton:
	return _remove
