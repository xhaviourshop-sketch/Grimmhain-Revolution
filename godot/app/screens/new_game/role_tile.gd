class_name RoleTile
extends RoleChip
## Rollenkachel im Rollenschritt (DA-91): Rollensymbol und Name auf dem Namensschild in der Teamfarbe. Antippen schaltet die Rolle an oder aus
## (`toggled_role`), nichts öffnet sich. Gewählt: volle Teamfarbe mit Glühen, nicht gewählt: entsättigt und dunkel. Rollen mit Zähler
## (Werwolf, Die Gebundenen) zeigen gewählt „×N“ mit kleinem − und + von mindestens 56 Pixel Trefferfläche (`count_step`). Langes Drücken
## meldet `info_requested` (Rollenbeschreibung) und schaltet dabei nichts. Reine Darstellung, die Wahrheit liegt in PlayerSetup.

signal toggled_role(role: StringName)
signal count_step(role: StringName, delta: int)
signal info_requested(role: StringName)

const LONG_PRESS_SECONDS := 0.55
const STEP_SIZE := 56.0

var counted: bool = false
var _long_fired: bool = false
var _timer: Timer
var _press_at: Vector2 = Vector2.ZERO
var _minus: GlyphButton
var _plus: GlyphButton


func _init() -> void:
	super()
	team_tint = true
	glow_when_chosen = true
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = LONG_PRESS_SECONDS
	_timer.timeout.connect(_on_long_press)
	add_child(_timer)
	button_down.connect(func() -> void:
		_long_fired = false
		_press_at = get_local_mouse_position()
		_timer.start())
	button_up.connect(_timer.stop)
	pressed.connect(func() -> void:
		if _long_fired:
			_long_fired = false
		else:
			toggled_role.emit(role))


## `p_count`: gewählte Kopien (0 = nicht gewählt), `p_counted`: Rolle mit Zähler, `usable`: wählbar (Kartenrolle ohne Totenreichkarten nicht).
func show_tile(p_role: StringName, p_count: int, p_counted: bool, usable: bool) -> void:
	counted = p_counted
	force_count = counted and p_count > 0
	show_role(p_role, p_count)
	name = "Tile_%s" % String(role).replace("-", "_")
	chosen = p_count > 0
	disabled = not usable
	dimmed = not usable
	if counted and chosen and _minus == null:
		_build_steppers()
	if _minus != null:
		_minus.visible = chosen
		_plus.visible = chosen
	queue_redraw()


func _fit() -> void:
	super()
	if counted:
		custom_minimum_size.x += STEP_SIZE * 2.0 + 8.0


func _build_steppers() -> void:
	_minus = _stepper("StepMinus", "minus", -1, -STEP_SIZE * 2.0 - 4.0)
	_plus = _stepper("StepPlus", "plus", 1, -STEP_SIZE)


func _stepper(node_name: String, glyph_name: String, delta: int, offset_x: float) -> GlyphButton:
	var button := GlyphButton.new()
	button.name = node_name
	button.glyph = glyph_name
	button.text_key = "ui.prep.roles.tile.%s" % ("less" if delta < 0 else "more")
	button.tooltip_text = tr(button.text_key)
	button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	button.custom_minimum_size = Vector2(STEP_SIZE, STEP_SIZE)
	button.offset_left = offset_x
	button.offset_right = offset_x + STEP_SIZE
	button.offset_top = -STEP_SIZE * 0.5
	button.offset_bottom = STEP_SIZE * 0.5
	button.pressed.connect(func() -> void: count_step.emit(role, delta))
	add_child(button)
	return button


## Wischen (Raster scrollen) bricht das lange Drücken ab.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _timer.is_stopped() and get_local_mouse_position().distance_to(_press_at) > float(ThemeTokens.TOUCH_DRAG_DEADZONE):
		_timer.stop()


func _on_long_press() -> void:
	_long_fired = true
	info_requested.emit(role)
