class_name LanguageFlags
extends HBoxContainer
## Zwei kleine gemalte Flaggen (Deutschland, England) zum Umschalten DE/EN, oben rechts auf dem Startbildschirm (Feedback 5). Im Silber-Stil der
## Marke: dunkle Flaggenfläche in gedämpften Farben, Mondsilber-Rahmen mit Lichtkante; die gewählte Sprache trägt den hellen Silberring, die andere
## ist abgedunkelt. Der Zustand hängt nicht an der Farbe allein: die gewählte Flagge hat zusätzlich einen Silberstrich darunter. Die Sprache ändert
## `AppSettings.set_language` (wird gespeichert, alle Texte aktualisieren sich).

const FLAG_SIZE := Vector2(60.0, 48.0)  ## Tippfläche mindestens TOUCH_MIN hoch
const LANGUAGE_NAMES := {"de": "Deutsch", "en": "English"}  ## Eigenname der Sprache als Tooltip (bleibt unübersetzt)

var _settings: AppSettings = null
var _flags: Dictionary = {}


func setup(settings: AppSettings) -> void:
	_settings = settings
	name = "LanguageFlags"
	add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	for code: String in AppSettings.LANGUAGES:
		var flag := Flag.new()
		flag.setup(code, _settings.language == code)
		flag.pressed.connect(_on_flag.bind(code))
		add_child(flag)
		_flags[code] = flag
	_settings.changed.connect(_on_settings_changed)


func flag(code: String) -> Button:
	return _flags.get(code, null)


func _on_flag(code: String) -> void:
	_settings.set_language(code)


func _on_settings_changed(key: StringName) -> void:
	if key != &"language":
		return
	for code: String in _flags:
		(_flags[code] as Flag).selected = _settings.language == code


class Flag extends Button:
	var code: String = "de"
	var selected: bool = false:
		set(value):
			selected = value
			queue_redraw()

	func setup(p_code: String, p_selected: bool) -> void:
		code = p_code
		selected = p_selected
		name = "Flag_%s" % p_code
		custom_minimum_size = FLAG_SIZE
		tooltip_text = LANGUAGE_NAMES[p_code]
		focus_mode = Control.FOCUS_ALL
		var empty := StyleBoxEmpty.new()
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			add_theme_stylebox_override(state, empty)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)

	func _draw() -> void:
		var area := Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 14.0))
		var dim := 1.0 if (selected or is_hovered() or has_focus()) else 0.55
		if selected:
			for i: int in 4:
				var halo := ThemeTokens.MOON_GLOW
				halo.a = 0.28 * (1.0 - float(i) / 4.0)
				draw_rect(area.grow(1.5 + 2.0 * float(i)), halo, false, 2.0)
		draw_rect(area, ThemeTokens.FLAG_BACK)
		if code == "de":
			_paint_germany(area, dim)
		else:
			_paint_england(area, dim)
		# Lichtkante oben und gedämpfter Verlauf unten: wirkt gemalt statt flach.
		var sheen := ThemeTokens.FLAG_SHEEN
		sheen.a *= dim
		draw_rect(Rect2(area.position, Vector2(area.size.x, area.size.y * 0.42)), sheen)
		draw_rect(Rect2(area.position + Vector2(0.0, area.size.y * 0.7), Vector2(area.size.x, area.size.y * 0.3)), ThemeTokens.FLAG_SHADE)
		var rim := ThemeTokens.MOON_SILVER_BRIGHT if selected else ThemeTokens.MOON_SILVER_DIM
		draw_rect(area, rim, false, 2.0)
		rim.a = 0.35
		draw_rect(area.grow(-3.0), rim, false, 1.0)
		if selected:
			draw_line(Vector2(area.position.x + 8.0, size.y - 3.0), Vector2(area.end.x - 8.0, size.y - 3.0), ThemeTokens.MOON_SILVER_BRIGHT, 2.5, true)
		if has_focus():
			draw_rect(area.grow(4.0), ThemeTokens.FOCUS_RING, false, float(ThemeTokens.FOCUS_WIDTH))

	## Schwarz-Rot-Gold in gedämpften Tönen (Nachtschwarz, Blutrot, mattes Altgold).
	func _paint_germany(area: Rect2, dim: float) -> void:
		var third := area.size.y / 3.0
		var bands := [ThemeTokens.FLAG_BLACK, ThemeTokens.FLAG_RED, ThemeTokens.FLAG_BAND_LOW]
		for i: int in 3:
			var c: Color = bands[i]
			draw_rect(Rect2(area.position + Vector2(0.0, third * float(i)), Vector2(area.size.x, third)), c.darkened(1.0 - dim))

	## Silberfeld mit blutrotem Georgskreuz.
	func _paint_england(area: Rect2, dim: float) -> void:
		var field := ThemeTokens.FLAG_SILVER
		draw_rect(area, field.darkened(1.0 - dim))
		var red := ThemeTokens.FLAG_RED.darkened(1.0 - dim)
		var bar := area.size.y * 0.24
		draw_rect(Rect2(area.position + Vector2(0.0, (area.size.y - bar) * 0.5), Vector2(area.size.x, bar)), red)
		draw_rect(Rect2(area.position + Vector2((area.size.x - bar) * 0.5, 0.0), Vector2(bar, area.size.y)), red)
