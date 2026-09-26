class_name AppShell
extends Control
## App-Shell (Wurzel von main.tscn): Theme, Dienste (AppContext), sichere Fläche, Router,
## Dialog und Statusmeldungen. Einzige Stelle für Zurück: Button, Escape (ui_cancel) und
## System-Zurück (Android) laufen über `go_back()`:
##   1. offener Dialog → schließen
##   2. Ansicht erledigt Zurück selbst (`handle_back`)
##   3. Elternansicht vorhanden → dorthin
##   4. Wurzel (Start) → Desktop: Beenden-Rückfrage, Mobilgerät: App verlassen

## Ersetzt `get_tree().quit()` (Tests, spätere Plattformschicht).
var quit_handler: Callable = Callable()
var app_context: AppContext = null

var _safe_rect_override: Rect2 = Rect2()
var _has_safe_override: bool = false

@onready var _router: ScreenRouter = %ScreenHost
@onready var _safe_area: MarginContainer = %SafeArea
@onready var _dialog: ConfirmDialog = %ConfirmDialog
@onready var _toast: ToastHost = %ToastHost


func _ready() -> void:
	theme = ThemeFactory.build()
	if app_context == null:
		app_context = AppContext.new()
	app_context.settings.apply()
	app_context.settings.changed.connect(_on_settings_changed)
	_toast.settings = app_context.settings
	_router.setup(app_context)
	_router.back_requested.connect(go_back)
	_router.quit_requested.connect(request_quit)
	_router.status_message_requested.connect(_toast.show_message)
	_dialog.confirmed.connect(_quit)
	get_viewport().size_changed.connect(_update_safe_area)
	_update_safe_area()
	_apply_window_limits()
	_router.navigate(ScreenIds.START)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		accept_event()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


# --- öffentliche Schnittstelle ------------------------------------------------------------------

func get_app_context() -> AppContext:
	return app_context


func get_router() -> ScreenRouter:
	return _router


func get_dialog() -> ConfirmDialog:
	return _dialog


func get_toast() -> ToastHost:
	return _toast


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


## Beenden: Desktop mit Rückfrage, Mobilgerät sofort (Systemverhalten beim Zurück in der Wurzel).
func request_quit() -> void:
	if AppPlatform.is_mobile():
		_quit()
		return
	_dialog.open("ui.dialog.quit.title", "ui.dialog.quit.message", "ui.dialog.quit.confirm")


## Sichere Fläche in Viewport-Koordinaten; leeres Rechteck = keine Geräteangabe.
func apply_safe_area(rect: Rect2) -> void:
	_safe_rect_override = rect
	_has_safe_override = true
	_apply_margins(rect)


# --- intern ---------------------------------------------------------------------------------------

func _quit() -> void:
	if quit_handler.is_valid():
		quit_handler.call()
	else:
		get_tree().quit()


func _on_settings_changed(key: StringName) -> void:
	if key == &"language":
		propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)


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
