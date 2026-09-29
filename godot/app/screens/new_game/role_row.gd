class_name RoleRow
extends PanelContainer
## Eine Zeile der Rollenwahl: Name, Fraktion als Text, Kurzbeschreibung, Regeln (Lexikoneintrag), Anzahl mit Minus
## und Plus (je mindestens 48×48). Gesperrte Grenzen sind sichtbar gesperrt, die Höchstzahl
## steht zusätzlich als Text da. Meldet Wünsche als Signal; ändert selbst nichts.

signal change_requested(role_id: StringName, delta: int)
signal info_requested(role_id: StringName)  ## Lexikoneintrag öffnen; ändert Auswahl und Verteilung nicht

var role_id: StringName = &""

@onready var _name: GrimmLabel = %RoleNameLabel
@onready var _faction: GrimmLabel = %RoleFactionLabel
@onready var _short: GrimmLabel = %RoleShortLabel
@onready var _limit: GrimmLabel = %RoleLimitLabel
@onready var _count: Label = %RoleCountLabel
@onready var _minus: GrimmButton = %MinusButton
@onready var _plus: GrimmButton = %PlusButton
@onready var _info: GrimmButton = %InfoButton


func _ready() -> void:
	_count.custom_minimum_size.x = ThemeTokens.ROLE_COUNT_WIDTH
	_minus.pressed.connect(_request.bind(-1))
	_plus.pressed.connect(_request.bind(1))
	_info.pressed.connect(func() -> void: info_requested.emit(role_id))


## Einmalig: Rolle und ihre Darstellungsschlüssel (Fraktion aus dem Katalog).
func show_role(role: StringName) -> void:
	role_id = role
	name = "RoleRow_%s" % String(role)
	_name.text_key = RolePresentation.name_key(role)
	_short.text_key = RolePresentation.short_key(role)
	_faction.text_key = RolePresentation.faction_key(SetupRoleCatalog.faction_of(role))
	_info.name = "RoleInfoButton_%s" % String(role)


## Bei jeder Änderung: Anzahl und gesperrte Grenzen.
func show_count(count: int, can_decrease: bool, can_increase: bool) -> void:
	_count.text = str(count)
	_minus.disabled = not can_decrease
	_plus.disabled = not can_increase
	var at_limit := not can_increase and count > 0
	_limit.visible = at_limit
	_limit.text_key = "ui.setup.roles.limit" if at_limit else ""


func plus_button() -> GrimmButton:
	return _plus


func _request(delta: int) -> void:
	var button := _plus if delta > 0 else _minus
	if not button.disabled:
		change_requested.emit(role_id, delta)
