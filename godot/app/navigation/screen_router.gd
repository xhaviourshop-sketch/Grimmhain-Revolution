class_name ScreenRouter
extends Control
## Screen-Router: hält genau eine aktive Ansicht. Navigation ersetzt sie (die alte wird
## sofort aus dem Baum genommen), deshalb kann schnelles Tippen keine Ansicht doppelt stapeln;
## Navigation zur aktiven Ansicht wird ignoriert. Zurück führt zur Elternansicht aus ScreenIds.
## Wünsche der Ansichten (Zurück, Beenden, Statusmeldung, Rückfrage) reicht der Router an die Shell weiter.
## Übergang: kurzes Einblenden mit kleiner Aufwärtsbewegung (ThemeTokens.TRANSITION_SECONDS).
## Bei reduzierter Bewegung erscheint die Ansicht sofort. Eingaben sind nie blockiert; eine
## neue Navigation beendet einen laufenden Übergang.

signal screen_changed(screen_id: StringName)
signal back_requested
signal quit_requested
signal status_message_requested(text_key: String)
signal dialog_requested(request: DialogRequest)

var context: AppContext

var _current: BaseScreen = null
var _current_id: StringName = &""
var _tween: Tween = null


func setup(p_context: AppContext) -> void:
	context = p_context


func current_id() -> StringName:
	return _current_id


func current_screen() -> BaseScreen:
	return _current


## Dauer des Einblendens; 0 bei reduzierter Bewegung.
func transition_duration() -> float:
	if context != null and context.settings.reduced_motion:
		return 0.0
	return ThemeTokens.TRANSITION_SECONDS


## Beendet einen laufenden Übergang sofort (z. B. wenn Bewegung reduziert wird).
func finish_transition() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _current != null:
		_current.modulate.a = 1.0
		_current.position = Vector2.ZERO


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
	screen.dialog_requested.connect(dialog_requested.emit)
	_current = screen
	_current_id = id
	_show(screen)
	var focus := screen.default_focus()
	if focus != null and focus.is_visible_in_tree():
		focus.grab_focus()
	screen_changed.emit(id)
	return true


func _show(screen: BaseScreen) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	var duration := transition_duration()
	if duration <= 0.0:
		screen.modulate.a = 1.0
		screen.position = Vector2.ZERO
		return
	screen.modulate.a = 0.0
	screen.position = Vector2(0.0, ThemeTokens.TRANSITION_OFFSET)
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(screen, "modulate:a", 1.0, duration)
	_tween.tween_property(screen, "position", Vector2.ZERO, duration)


func _remove_current() -> void:
	if _current == null:
		return
	remove_child(_current)
	_current.queue_free()
	_current = null
	_current_id = &""
