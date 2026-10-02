class_name AppShell
extends Control
## App-Shell (Wurzel von main.tscn): Theme, Dienste (AppContext), sichere Fläche, Router,
## Dialog und Statusmeldungen. Einzige Stelle für Zurück: Button, Escape (ui_cancel) und
## System-Zurück (Android) laufen über `go_back()` (Escape wird vor der GUI abgefangen):
##   1. offener Dialog → schließen
##   2. Ansicht erledigt Zurück selbst (`handle_back`)
##   3. Elternansicht vorhanden → dorthin
##   4. Wurzel (Start) → Desktop: Beenden-Rückfrage, Mobilgerät: App verlassen

## Ersetzt `get_tree().quit()` (Tests, spätere Plattformschicht).
var quit_handler: Callable = Callable()
var app_context: AppContext = null
## Dauerhafte Einstellungen. Beim echten Start (ohne vorbereiteten Kontext) user://settings.json; ein von außen
## übergebener Kontext bleibt ohne Datei, außer ein Speicher wird ausdrücklich gesetzt (Tests mit Temp-Pfad).
var settings_store: SettingsStore = null

var _safe_rect_override: Rect2 = Rect2()
var _has_safe_override: bool = false
var _settings_applied: bool = false

@onready var _router: ScreenRouter = %ScreenHost
@onready var _safe_area: MarginContainer = %SafeArea
@onready var _dialog: ConfirmDialog = %ConfirmDialog
@onready var _toast: ToastHost = %ToastHost

var _cues: AudioCuePlayer = null


## Einstellungen laden und anwenden, bevor Kindknoten und erste Ansicht entstehen (_enter_tree des Elternknotens
## läuft vor dem Aufbau der Kinder): Die Oberfläche entsteht gleich in der gespeicherten Sprache.
func _enter_tree() -> void:
	if _settings_applied:
		return
	_settings_applied = true
	if app_context == null:
		app_context = AppContext.new()
		if settings_store == null:
			settings_store = SettingsStore.new()
		app_context.groups.path = GroupStore.DEFAULT_PATH
		app_context.groups.load_from_disk()
		app_context.history.path = HistoryStore.DEFAULT_PATH
		app_context.history.load_from_disk()
	if settings_store != null:
		app_context.use_settings_store(settings_store)
	else:
		app_context.settings.apply()


func _ready() -> void:
	theme = ThemeFactory.build()
	get_tree().set_auto_accept_quit(false)  # Fenster schließen läuft über _notification (Warnung bei ungespeichertem Stand)
	app_context.settings.changed.connect(_on_settings_changed)
	_toast.settings = app_context.settings
	_cues = AudioCuePlayer.new()
	_cues.name = "AudioCuePlayer"
	add_child(_cues)
	_cues.setup(app_context)
	_router.setup(app_context)
	_router.back_requested.connect(go_back)
	_router.quit_requested.connect(request_quit)
	_router.status_message_requested.connect(_toast.show_message)
	_router.dialog_requested.connect(_dialog.open_request)
	get_viewport().size_changed.connect(_update_safe_area)
	_update_safe_area()
	_apply_window_limits()
	_router.navigate(ScreenIds.START)


## Escape vor der GUI behandeln: Textfelder (LineEdit) verbrauchen `ui_cancel` sonst selbst,
## dann wäre Zurück aus einem fokussierten Eingabefeld unmöglich.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Fenster schließen (Desktop): wie bisher sofort, außer der letzte Stand ist nicht gespeichert. Ein erzwungenes
		# Beenden durch das Betriebssystem erreicht die App nicht und ist nicht abfangbar.
		if _unsaved():
			_open_unsaved_quit()
		else:
			_quit()


# --- öffentliche Schnittstelle ------------------------------------------------------------------

func get_app_context() -> AppContext:
	return app_context


func get_router() -> ScreenRouter:
	return _router


func get_dialog() -> ConfirmDialog:
	return _dialog


func get_toast() -> ToastHost:
	return _toast


func get_cue_player() -> AudioCuePlayer:
	return _cues


func current_screen_id() -> StringName:
	return _router.current_id()


func current_screen() -> BaseScreen:
	return _router.current_screen()


## Navigation von außen; ein offener Dialog gehört zur alten Ansicht und wird geschlossen.
func navigate(id: StringName) -> bool:
	if _dialog.is_open():
		_dialog.cancel()
	return _router.navigate(id)


func go_back() -> void:
	if _dialog.is_open():
		_dialog.cancel()
		return
	var screen := _router.current_screen()
	if screen != null and screen.handle_back():
		return
	var target := _router.back_target()
	if target != &"":
		_router.navigate(target)
		return
	request_quit()


## Beenden: Desktop mit Rückfrage, Mobilgerät sofort (Systemverhalten beim Zurück in der Wurzel). Ist der letzte
## Stand der laufenden Partie nicht gespeichert, warnt die Rückfrage auf beiden Plattformen.
func request_quit() -> void:
	if _unsaved():
		_open_unsaved_quit()
		return
	if AppPlatform.is_mobile():
		_quit()
		return
	_dialog.open_request(DialogRequest.create("ui.dialog.quit.title", "ui.dialog.quit.message", "ui.dialog.quit.confirm", _quit))


## Sichere Fläche in Viewport-Koordinaten; leeres Rechteck = keine Geräteangabe.
func apply_safe_area(rect: Rect2) -> void:
	_safe_rect_override = rect
	_has_safe_override = true
	_apply_margins(rect)


# --- intern ---------------------------------------------------------------------------------------

## Letztes Speichern der laufenden Partie ist fehlgeschlagen.
func _unsaved() -> bool:
	var round := app_context.session.round_id()
	return round != "" and not bool(app_context.saves.last_status.get("ok", true)) \
		and str(app_context.saves.last_status.get("round_id", "")) == round


func _open_unsaved_quit() -> void:
	_dialog.open_request(DialogRequest.create("ui.dialog.quit.title", "ui.dialog.quit.unsaved_message", "ui.dialog.quit.confirm", _quit))


func _quit() -> void:
	if quit_handler.is_valid():
		quit_handler.call()
	else:
		get_tree().quit()


func _on_settings_changed(key: StringName) -> void:
	if key == &"language":
		propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
	elif key == &"reduced_motion" and app_context.settings.reduced_motion:
		_router.finish_transition()


func _update_safe_area() -> void:
	_apply_margins(_safe_rect_override if _has_safe_override else _device_safe_rect())


## Displayränder (Notch, Kamera, Gestenleiste) nur auf Mobilgeräten; Desktopfenster haben keine.
func _device_safe_rect() -> Rect2:
	if not AppPlatform.is_mobile():
		return Rect2()
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe.size == Vector2i.ZERO or window_size == Vector2i.ZERO:
		return Rect2()
	var local := Rect2(Vector2(safe.position - DisplayServer.window_get_position()), Vector2(safe.size))
	var scale := get_viewport_rect().size / Vector2(window_size)
	return Rect2(local.position * scale, local.size * scale)


func _apply_margins(rect: Rect2) -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var insets := [0.0, 0.0, 0.0, 0.0]
	if rect.has_area():
		insets = [rect.position.x, rect.position.y, view.x - rect.end.x, view.y - rect.end.y]
	var sides := ["margin_left", "margin_top", "margin_right", "margin_bottom"]
	for i: int in sides.size():
		_safe_area.add_theme_constant_override(sides[i], ceili(maxf(float(insets[i]), ThemeTokens.SAFE_MARGIN)))


func _apply_window_limits() -> void:
	if AppPlatform.is_mobile() or DisplayServer.get_name() == "headless":
		return
	get_window().min_size = Vector2i(ThemeTokens.WINDOW_MIN_WIDTH, ThemeTokens.WINDOW_MIN_HEIGHT)
