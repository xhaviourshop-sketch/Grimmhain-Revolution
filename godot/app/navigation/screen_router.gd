class_name ScreenRouter
extends Control
## Screen-Router: hält genau eine aktive Ansicht. Navigation ersetzt sie (die alte wird
## sofort aus dem Baum genommen), deshalb kann schnelles Tippen keine Ansicht doppelt stapeln;
## Navigation zur aktiven Ansicht wird ignoriert. Zurück führt zur Elternansicht aus ScreenIds.
## Wünsche der Ansichten (Zurück, Beenden, Statusmeldung) reicht der Router an die Shell weiter.

signal screen_changed(screen_id: StringName)
signal back_requested
signal quit_requested
signal status_message_requested(text_key: String)

var context: AppContext

var _current: BaseScreen = null
var _current_id: StringName = &""


func setup(p_context: AppContext) -> void:
	context = p_context


func current_id() -> StringName:
	return _current_id


func current_screen() -> BaseScreen:
	return _current


## Ziel von Zurück oder &"" in der Wurzelansicht.
func back_target() -> StringName:
	return ScreenIds.parent_of(_current_id)


## Wechselt zur Ansicht `id`. false bei unbekannter ID oder wenn sie bereits aktiv ist.
func navigate(id: StringName) -> bool:
	if id == _current_id or not ScreenIds.has(id):
		return false
	var scene := load(ScreenIds.scene_path(id)) as PackedScene
	var screen := scene.instantiate() as BaseScreen if scene != null else null
	if screen == null:
		return false
	screen.setup(context)
	_remove_current()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.navigate_requested.connect(navigate)
	screen.back_requested.connect(back_requested.emit)
	screen.quit_requested.connect(quit_requested.emit)
	screen.status_message_requested.connect(status_message_requested.emit)
	_current = screen
	_current_id = id
	_show(screen)
	var focus := screen.default_focus()
	if focus != null and focus.is_visible_in_tree():
		focus.grab_focus()
	screen_changed.emit(id)
	return true


func _show(screen: BaseScreen) -> void:
	screen.modulate.a = 1.0
	screen.position = Vector2.ZERO


func _remove_current() -> void:
	if _current == null:
		return
	remove_child(_current)
	_current.queue_free()
	_current = null
	_current_id = &""
