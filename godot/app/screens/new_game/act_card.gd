class_name ActCard
extends GrimmButton
## Akt-Karte der Vorbereitung (DA-89): ein fertiges Rollen-Set auf dem Hain-Kartenrahmen. Zeigt Aktnummer, Titel, Untertitel,
## Schwierigkeit (Punkte, zusätzlich als Text im Untertitel) und die Tragkraft („bis 17 Personen“, wenn der Akt die Runde nicht trägt).
## Der gewählte Akt lodert als Feuer entlang des Kartenrahmens (`FireGlow`, Stärke nach Aktstufe: schon I lodert kräftig, bis IV steigert sich Glut, Höhe, Unruhe und Funkenflug)
## und trägt ein Häkchen (Blutrot nur für Aktives); nicht gewählte Akte brennen nicht. Ein Akt, der die Personenzahl nicht trägt,
## ist gedämpft und nicht wählbar. Verbinden über `pressed`; Auswahl setzt PlayerSetup.

const MAX_LEVEL := 4

var act: StringName = &""
## Träger des Feuers: ein Platzhalter mit derselben Fläche in einer Ebene hinter allen Akt-Karten (sonst überdeckt das Feuer von Akt IV
## die Karte darüber). Ohne Träger hängt das Feuer an der Karte selbst.
var fire_host: Control = null
var animated: bool = true:  ## aus bei reduzierter Bewegung: Flamme steht still, keine Funken
	set(value):
		animated = value
		FireGlow.set_on(_fire_target(), "card_frame", GroveArtData.CARD_FRAME_MARGINS, selected, _level, animated)
var selected: bool = false:
	set(value):
		selected = value
		FireGlow.set_on(_fire_target(), "card_frame", GroveArtData.CARD_FRAME_MARGINS, value, _level, animated)
		queue_redraw()
var _title: GrimmLabel
var _name: GrimmLabel
var _subtitle: GrimmLabel
var _limit: GrimmLabel
var _level: int = 0


func setup(p_act: StringName) -> void:
	act = p_act
	name = "ActCard_%s" % String(act)
	_level = ActCatalog.level(act)
	kind = Kind.COMPACT
	wrap = false
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(ThemeTokens.ACT_CARD_MIN_WIDTH, ThemeTokens.ACT_CARD_HEIGHT)
	_skin()
	text_key = ActCatalog.name_key(act)  # nur Bedienungshilfe und Tooltip, gezeichnet wird nichts davon
	for color: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(color, ThemeTokens.INVISIBLE)
	var column := VBoxContainer.new()
	column.name = "ActContent"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 0)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = ThemeTokens.SPACE_XL + 4.0
	column.offset_right = -(ThemeTokens.SPACE_XL + 4.0)
	column.offset_top = ThemeTokens.SPACE_M + 6.0
	column.offset_bottom = -(ThemeTokens.SPACE_M + 2.0)
	add_child(column)
	_title = _label(column, "ActName", &"HainHeadingLabel", ActCatalog.name_key(act))
	_name = _label(column, "ActTitle", &"HainLabel", ActCatalog.title_key(act))
	_name.add_theme_font_size_override(&"font_size", ThemeTokens.FONT_CAPTION)
	_name.add_theme_color_override(&"font_color", ThemeTokens.MOON_SILVER_BRIGHT)
	_subtitle = _label(column, "ActSubtitle", &"HainCaptionLabel", ActCatalog.subtitle_key(act))
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	_limit = _label(column, "ActLimit", &"HainCaptionLabel", "")
	column.minimum_size_changed.connect(func() -> void: _fit_height(column))


func _fire_target() -> Control:
	return fire_host if fire_host != null else self


## `capacity`: größte Personenzahl, die der Akt trägt.
func show_state(is_selected: bool, capacity: int) -> void:
	selected = is_selected
	_limit.format_values = {"count": capacity}
	_limit.text_key = "ui.prep.act.capacity"
	queue_redraw()


## Die Karte wächst mit ihrem Text (lange Untertitel, DE und EN), nie unter die Mindesthöhe.
func _fit_height(column: Control) -> void:
	var wanted := maxf(float(ThemeTokens.ACT_CARD_HEIGHT), column.get_combined_minimum_size().y + column.offset_top - column.offset_bottom + float(ThemeTokens.SPACE_S))
	if not is_equal_approx(custom_minimum_size.y, wanted):
		custom_minimum_size.y = wanted


func _skin() -> void:
	var tex := GroveSkin.texture("card_frame")
	if tex == null:
		return
	var states := {
		"normal": ThemeTokens.TINT_NONE, "hover": GroveSkin.TINT_HOVER, "pressed": GroveSkin.TINT_PRESSED,
		"hover_pressed": GroveSkin.TINT_PRESSED, "disabled": GroveSkin.TINT_DISABLED,
	}
	for state: String in states:
		var box := GroveStyleBox.make(tex, GroveArtData.CARD_FRAME_MARGINS, states[state])
		add_theme_stylebox_override(state, box)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	focus_entered.connect(_refresh_focus)
	focus_exited.connect(_refresh_focus)


## Fokusrahmen und Aufhellung nur bei Tastatur- oder Gamepadbedienung; ein Standardfokus ohne Eingabe (Betreten des Schritts) und Antippen
## zeigen allein die rote Auswahl.
func _refresh_focus() -> void:
	self_modulate = GroveSkin.TINT_FOCUS if has_focus(true) else ThemeTokens.TINT_NONE
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and has_focus():
		_refresh_focus.call_deferred()


func _label(parent: Control, node_name: String, variation: StringName, key: String) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.name = node_name
	label.theme_type_variation = variation
	label.text_key = key
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _draw() -> void:
	var inset := 14.0
	# Schwierigkeit: vier Punkte rechts oben, gefüllt je Stufe (zusätzlich steht sie im Untertitel).
	for i: int in MAX_LEVEL:
		var centre := Vector2(size.x - inset - 12.0 - float(MAX_LEVEL - 1 - i) * 14.0, inset + 14.0)
		if i < _level:
			draw_circle(centre, 5.0, ThemeTokens.MOON_SILVER_BRIGHT)
		else:
			draw_arc(centre, 5.0, 0.0, TAU, 16, ThemeTokens.MOON_SILVER_DIM, 1.5, true)
	if selected:
		var c := Vector2(size.x - inset - 12.0, size.y - inset - 14.0)  # Ecke unten rechts, nie auf dem Text
		draw_circle(c, 11.0, ThemeTokens.NUMBER_BG)
		draw_arc(c, 11.0, 0.0, TAU, 20, ThemeTokens.BLOOD_RED, 2.0, true)
		draw_polyline(PackedVector2Array([c + Vector2(-5.0, 0.5), c + Vector2(-1.5, 4.0), c + Vector2(5.5, -4.0)]), ThemeTokens.MOON_SILVER_BRIGHT, 2.4, true)
	if has_focus(true):
		draw_rect(Rect2(Vector2.ZERO, size).grow(-2.0), ThemeTokens.MOON_GLOW, false, float(ThemeTokens.FOCUS_WIDTH))
