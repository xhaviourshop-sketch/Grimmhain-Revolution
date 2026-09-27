class_name DistributionStep
extends VBoxContainer
## Wizard-Schritt 3 „Verteilung“ (Grundgerüst): Überschrift und „Rollen bearbeiten“.

signal dialog_requested(request: DialogRequest)
signal status_message_requested(text_key: String)
signal roles_requested  ## „Rollen bearbeiten“

var _setup: PlayerSetup = null

@onready var _edit_roles: GrimmButton = %EditRolesButton


func start(setup: PlayerSetup) -> void:
	_setup = setup
	_edit_roles.pressed.connect(roles_requested.emit)


func default_focus() -> Control:
	return _edit_roles


func handle_back() -> bool:
	return false
