class_name AssignmentRow
extends PanelContainer
## Eine Personenzeile der Verteilung: Listennummer, Name (Nutzerdaten), öffentlicher Zustand
## („zugewiesen“ / „nicht zugewiesen“) und nur im geöffneten Spielleiterbereich Rolle und
## vom Spielleiter gewählte Scheinrolle der zugewiesenen Kopie. Im manuellen Modus „Rolle zuweisen“ bzw. „Rolle ändern“.
## Wird bei Änderungen nur aktualisiert, nicht neu gebaut (Fokus bleibt erhalten).

signal choose_requested(person_id: int)

var person_id: int = -1
var person_name: String = ""
var number: int = 0

@onready var _number: GrimmLabel = %NumberLabel
@onready var _name: Label = %NameLabel
@onready var _state: GrimmLabel = %AssignmentStateLabel
@onready var _role: GrimmLabel = %SecretRoleLabel
@onready var _appearance: GrimmLabel = %AppearanceLabel
@onready var _choose: GrimmButton = %ChooseRoleButton


func _ready() -> void:
	_number.custom_minimum_size.x = ThemeTokens.PERSON_NUMBER_WIDTH
	(%StateBox as Control).custom_minimum_size.x = ThemeTokens.ASSIGNMENT_STATE_WIDTH
	_choose.pressed.connect(func() -> void: choose_requested.emit(person_id))


## `entry` aus PlayerSetup.view()["distribution"]["assignment"].
func show_entry(entry: Dictionary, revealed: bool, manual: bool) -> void:
	person_id = int(entry["person_id"])
	person_name = str(entry["name"])
	number = int(entry["number"])
	_number.format_values = {"number": number}
	_name.text = person_name
	_name.tooltip_text = person_name
	var role := str(entry["role"])
	var appearance := str(entry["appearance"])
	var show_role := revealed and role != ""
	_state.visible = not show_role
	_state.text_key = "ui.setup.distribution.assigned" if role != "" else "ui.setup.distribution.unassigned"
	_state.theme_type_variation = &"CaptionLabel" if role != "" else &"WarningLabel"
	_role.visible = show_role
	_role.text_key = RolePresentation.name_key(StringName(role)) if show_role else ""
	_appearance.visible = show_role and appearance != ""
	if _appearance.visible:
		_appearance.format_values = {"role": tr(RolePresentation.name_key(StringName(appearance)))}
		_appearance.text_key = "ui.setup.distribution.appearance"
	else:
		_appearance.text_key = ""
	_choose.visible = manual
	_choose.text_key = "ui.setup.distribution.change" if role != "" else "ui.setup.distribution.choose"


func choose_button() -> GrimmButton:
	return _choose
