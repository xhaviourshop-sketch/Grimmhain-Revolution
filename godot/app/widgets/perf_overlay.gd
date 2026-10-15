class_name PerfOverlay
extends CanvasLayer
## Verstecktes Messfeld für Geräte ohne Entwicklerwerkzeuge (iPad): Bilder pro Sekunde, Bildzeit, Zeichenaufrufe, Texturspeicher.
## Öffnen und Schließen mit drei Fingern gleichzeitig oder mit langem Druck (1,2 s) in der linken oberen Ecke. Reine Anzeige, ändert nichts am Spiel.

const CORNER := 90.0  ## Seitenlänge der Ecke für den langen Druck, in Bildschirmpunkten
const HOLD_SECONDS := 1.2
const REFRESH_SECONDS := 0.5
const MB := 1048576.0

var _label: Label = null
var _fingers: Dictionary = {}
var _hold: float = -1.0  ## Dauer des laufenden Drucks in der Ecke, -1 wenn keiner
var _since_refresh: float = 0.0
var _worst_ms: float = 0.0


func _init() -> void:
	name = "PerfOverlay"
	layer = 127


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(12.0, 12.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override(&"font_size", ThemeTokens.FONT_BODY)
	_label.add_theme_color_override(&"font_color", ThemeTokens.MOON_SILVER_BRIGHT)
	_label.add_theme_color_override(&"font_outline_color", ThemeTokens.BG_SURFACE)
	_label.add_theme_constant_override(&"outline_size", 6)
	_label.visible = false
	add_child(_label)
	set_process(false)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_fingers[touch.index] = touch.position
			if _fingers.size() == 3:
				_toggle()
		else:
			_fingers.erase(touch.index)
		_track_corner(touch.pressed, touch.position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var click := event as InputEventMouseButton
		_track_corner(click.pressed, click.position)


func _track_corner(pressed: bool, at: Vector2) -> void:
	_hold = 0.0 if pressed and at.x < CORNER and at.y < CORNER else -1.0
	set_process(_hold >= 0.0 or _label.visible)


func _toggle() -> void:
	_label.visible = not _label.visible
	_worst_ms = 0.0
	_since_refresh = REFRESH_SECONDS
	_hold = -1.0
	set_process(_label.visible)


func _process(delta: float) -> void:
	if _hold >= 0.0:
		_hold += delta
		if _hold >= HOLD_SECONDS:
			_toggle()
		return
	if not _label.visible:
		set_process(false)
		return
	_worst_ms = maxf(_worst_ms, delta * 1000.0)
	_since_refresh += delta
	if _since_refresh < REFRESH_SECONDS:
		return
	_since_refresh = 0.0
	var view := get_viewport().get_visible_rect().size
	_label.text = tr("ui.perf.report").replace(" / ", "\n").format({
		"fps": Engine.get_frames_per_second(),
		"ms": "%.1f" % (delta * 1000.0),
		"worst": "%.0f" % _worst_ms,
		"calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"mem": "%.0f" % (float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)) / MB),
		"w": int(view.x),
		"h": int(view.y),
	})
	_worst_ms = 0.0
