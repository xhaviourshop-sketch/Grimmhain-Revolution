class_name ThemeFactory
extends RefCounted
## Baut das Grimmhain-Theme aus ThemeTokens (keine .tres-Kopie der Werte). Variationen:
##   Buttons:  PrimaryButton (Gold gefüllt), SecondaryButton (Fläche mit Rahmen), DangerButton (gedämpftes Rot)
##   Labels:   TitleLabel, SubtitleLabel, HeadingLabel, MutedLabel, CaptionLabel
##   Panels:   CardPanel, HeaderPanel, PlaceholderPanel, StatusBadge, DialogPanel, ToastPanel, AppBackground
##   Container: ScreenColumn (großer Abstand), ScreenMargin (Innenrand)
## Jeder Button-Zustand (normal, hover, pressed, focus, disabled) hat eine eigene StyleBox;
## Primär/Sekundär unterscheiden sich zusätzlich in der Form (gefüllt/umrandet), nicht nur
## in der Farbe. Fokus ist ein separater, heller Rahmen mit Abstand.



static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = ThemeTokens.FONT_BODY
	_labels(theme)
	_buttons(theme)
	_toggles(theme)
	_panels(theme)
	_containers(theme)
	_inputs(theme)
	_scrolling(theme)
	return theme


static func _box(bg: Color, border: Color, border_width: int, radius: int = ThemeTokens.RADIUS_M) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = ThemeTokens.SPACE_L
	box.content_margin_right = ThemeTokens.SPACE_L
	box.content_margin_top = ThemeTokens.SPACE_S
	box.content_margin_bottom = ThemeTokens.SPACE_S
	box.anti_aliasing = true
	return box


static func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = ThemeTokens.FOCUS_RING
	box.set_border_width_all(ThemeTokens.FOCUS_WIDTH)
	box.set_corner_radius_all(ThemeTokens.RADIUS_M + ThemeTokens.FOCUS_WIDTH)
	box.set_expand_margin_all(ThemeTokens.FOCUS_WIDTH + 1)
	return box


static func _labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", ThemeTokens.TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", ThemeTokens.FONT_BODY)
	var variations := {
		&"TitleLabel": [ThemeTokens.FONT_TITLE, ThemeTokens.GOLD],
		&"SubtitleLabel": [ThemeTokens.FONT_SUBTITLE, ThemeTokens.TEXT_MUTED],
		&"HeadingLabel": [ThemeTokens.FONT_HEADING, ThemeTokens.TEXT_PRIMARY],
		&"MutedLabel": [ThemeTokens.FONT_BODY, ThemeTokens.TEXT_MUTED],
		&"CaptionLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.TEXT_MUTED],
		&"ErrorLabel": [ThemeTokens.FONT_BODY, ThemeTokens.DANGER_TEXT],
		&"WarningLabel": [ThemeTokens.FONT_BODY, ThemeTokens.WARNING_TEXT],
		&"BadgeLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.WARNING_TEXT],
		&"SectionLabel": [ThemeTokens.FONT_SUBTITLE, ThemeTokens.TEXT_PRIMARY],
		&"ErrorCaptionLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.DANGER_TEXT],
	}
	for name: StringName in variations:
		theme.set_type_variation(name, &"Label")
		theme.set_font_size("font_size", name, variations[name][0])
		theme.set_color("font_color", name, variations[name][1])


## Farben je Variation: [normal, hover, pressed, Text, Text gedrückt, Rahmen normal, Rahmen hover].
static func _buttons(theme: Theme) -> void:
	var palettes := {
		&"PrimaryButton": [ThemeTokens.GOLD, ThemeTokens.GOLD_BRIGHT, ThemeTokens.GOLD_DEEP, ThemeTokens.TEXT_ON_GOLD, ThemeTokens.TEXT_ON_GOLD, ThemeTokens.GOLD_DEEP, ThemeTokens.GOLD],
		&"SecondaryButton": [ThemeTokens.BG_SURFACE, ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.BG_APP, ThemeTokens.TEXT_PRIMARY, ThemeTokens.GOLD_BRIGHT, ThemeTokens.BORDER_SUBTLE, ThemeTokens.GOLD],
		&"DangerButton": [ThemeTokens.DANGER, ThemeTokens.DANGER_BRIGHT, ThemeTokens.DANGER_DEEP, ThemeTokens.TEXT_PRIMARY, ThemeTokens.TEXT_PRIMARY, ThemeTokens.DANGER_DEEP, ThemeTokens.TEXT_MUTED],
	}
	for name: StringName in palettes:
		var p: Array = palettes[name]
		if name != &"SecondaryButton":
			theme.set_type_variation(name, &"Button")
		_button_type(theme, name, p)
	# Kompakter Sekundärbutton für Listenzeilen (48 hoch, kleinere Schrift, schmaler Innenrand).
	theme.set_type_variation(&"CompactButton", &"Button")
	_button_type(theme, &"CompactButton", palettes[&"SecondaryButton"])
	theme.set_font_size("font_size", &"CompactButton", ThemeTokens.FONT_COMPACT)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := theme.get_stylebox(state, &"CompactButton") as StyleBoxFlat
		box.content_margin_left = ThemeTokens.SPACE_M
		box.content_margin_right = ThemeTokens.SPACE_M
	# Platzsymbole der Sitzordnung: ausgewählt (Gold, wie Primäraktion) und Ablageziel beim Ziehen
	# (angehobene Fläche mit hellem Goldrahmen). Schriftgröße und Innenrand wie CompactButton.
	var seat_palettes := {
		&"SeatSelectedButton": palettes[&"PrimaryButton"],
		&"SeatTargetButton": [ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.TEXT_PRIMARY, ThemeTokens.TEXT_PRIMARY, ThemeTokens.GOLD_BRIGHT, ThemeTokens.GOLD_BRIGHT],
	}
	for name: StringName in seat_palettes:
		theme.set_type_variation(name, &"Button")
		_button_type(theme, name, seat_palettes[name])
		theme.set_font_size("font_size", name, ThemeTokens.FONT_COMPACT)
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var box := theme.get_stylebox(state, name) as StyleBoxFlat
			box.content_margin_left = ThemeTokens.SPACE_M
			box.content_margin_right = ThemeTokens.SPACE_M
			box.set_border_width_all(ThemeTokens.FOCUS_WIDTH)
	# Der Grundtyp Button entspricht dem Sekundärbutton.
	theme.set_type_variation(&"SecondaryButton", &"Button")
	_button_type(theme, &"Button", palettes[&"SecondaryButton"])


static func _button_type(theme: Theme, type: StringName, p: Array) -> void:
	theme.set_stylebox("normal", type, _box(p[0], p[5], ThemeTokens.BORDER_THICK))
	theme.set_stylebox("hover", type, _box(p[1], p[6], ThemeTokens.BORDER_THICK))
	var pressed := _box(p[2], p[6], ThemeTokens.FOCUS_WIDTH)
	theme.set_stylebox("pressed", type, pressed)
	theme.set_stylebox("hover_pressed", type, pressed)
	theme.set_stylebox("disabled", type, _box(ThemeTokens.DISABLED_FILL, ThemeTokens.DISABLED_BORDER, ThemeTokens.BORDER_THIN))
	theme.set_stylebox("focus", type, _focus_box())
	theme.set_color("font_color", type, p[3])
	theme.set_color("font_hover_color", type, p[3])
	theme.set_color("font_focus_color", type, p[3])
	theme.set_color("font_pressed_color", type, p[4])
	theme.set_color("font_hover_pressed_color", type, p[4])
	theme.set_color("font_disabled_color", type, ThemeTokens.TEXT_DISABLED)
	theme.set_font_size("font_size", type, ThemeTokens.FONT_BUTTON)
	theme.set_constant("h_separation", type, ThemeTokens.SPACE_S)


## Umschalter (CheckButton): Zustand über Schalterform und Beschriftung, nicht nur Farbe.
static func _toggles(theme: Theme) -> void:
	var type := &"CheckButton"
	theme.set_stylebox("normal", type, _box(ThemeTokens.BG_SURFACE, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THICK))
	theme.set_stylebox("hover", type, _box(ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.GOLD, ThemeTokens.BORDER_THICK))
	theme.set_stylebox("pressed", type, _box(ThemeTokens.BG_SURFACE, ThemeTokens.GOLD, ThemeTokens.BORDER_THICK))
	theme.set_stylebox("hover_pressed", type, _box(ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.GOLD_BRIGHT, ThemeTokens.BORDER_THICK))
	theme.set_stylebox("disabled", type, _box(ThemeTokens.DISABLED_FILL, ThemeTokens.DISABLED_BORDER, ThemeTokens.BORDER_THIN))
	theme.set_stylebox("focus", type, _focus_box())
	for c: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(c, type, ThemeTokens.TEXT_PRIMARY)
	theme.set_color("font_disabled_color", type, ThemeTokens.TEXT_DISABLED)
	theme.set_font_size("font_size", type, ThemeTokens.FONT_BUTTON)
	theme.set_constant("h_separation", type, ThemeTokens.SPACE_M)
	# Eigener Schalter statt Engine-Symbol: an = goldene Bahn, Knopf rechts; aus = Rahmen, Knopf links.
	theme.set_icon("checked", type, _switch_icon(true, false))
	theme.set_icon("unchecked", type, _switch_icon(false, false))
	theme.set_icon("checked_disabled", type, _switch_icon(true, true))
	theme.set_icon("unchecked_disabled", type, _switch_icon(false, true))
	theme.set_icon("checked_mirrored", type, _switch_icon(true, false))
	theme.set_icon("unchecked_mirrored", type, _switch_icon(false, false))
	theme.set_icon("checked_disabled_mirrored", type, _switch_icon(true, true))
	theme.set_icon("unchecked_disabled_mirrored", type, _switch_icon(false, true))


## Schaltersymbol aus einfachen Formen (keine Bilddatei): Bahn als Pille, runder Knopf.
static func _switch_icon(on: bool, disabled: bool) -> ImageTexture:
	var w := ThemeTokens.SWITCH_WIDTH
	var h := ThemeTokens.SWITCH_HEIGHT
	var image := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var track := ThemeTokens.GOLD if on else ThemeTokens.BG_APP
	var outline := ThemeTokens.GOLD if on else ThemeTokens.TEXT_MUTED
	var knob := ThemeTokens.TEXT_ON_GOLD if on else ThemeTokens.TEXT_MUTED
	if disabled:
		track = ThemeTokens.DISABLED_FILL
		outline = ThemeTokens.DISABLED_BORDER
		knob = ThemeTokens.TEXT_DISABLED
	var r := h / 2.0
	var knob_center := Vector2(w - r if on else r, r)
	var knob_radius := r - ThemeTokens.SPACE_XS - ThemeTokens.BORDER_THICK
	for y: int in h:
		for x: int in w:
			var p := Vector2(x + 0.5, y + 0.5)
			# Abstand zur Pille (Rechteck mit Halbkreisen).
			var cx := clampf(p.x, r, w - r)
			var d := p.distance_to(Vector2(cx, r))
			var color := Color(0, 0, 0, 0)
			if d <= r:
				color = outline if d > r - ThemeTokens.BORDER_THICK else track
				color.a *= clampf(r - d + 0.5, 0.0, 1.0)
			var dk := p.distance_to(knob_center)
			if dk <= knob_radius + 0.5:
				color = color.blend(Color(knob, clampf(knob_radius - dk + 0.5, 0.0, 1.0)))
			image.set_pixelv(Vector2i(x, y), color)
	return ImageTexture.create_from_image(image)


static func _panel(color: Color, border: Color, border_width: int, radius: int, padding: int) -> StyleBoxFlat:
	var box := _box(color, border, border_width, radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box


static func _panels(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", _panel(ThemeTokens.BG_SURFACE, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_L, ThemeTokens.SPACE_L))
	theme.set_stylebox("panel", "Panel", _panel(ThemeTokens.BG_APP, ThemeTokens.BG_APP, 0, 0, 0))
	var variations := {
		&"AppBackground": _panel(ThemeTokens.BG_APP, ThemeTokens.BG_APP, 0, 0, 0),
		&"CardPanel": _panel(ThemeTokens.BG_SURFACE, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_L, ThemeTokens.SPACE_L),
		&"HeaderPanel": _panel(ThemeTokens.BG_SURFACE, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_M, ThemeTokens.SPACE_S),
		&"PlaceholderPanel": _panel(ThemeTokens.BG_APP, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THICK, ThemeTokens.RADIUS_L, ThemeTokens.SPACE_L),
		&"StatusBadge": _panel(ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.GOLD, ThemeTokens.BORDER_THICK, ThemeTokens.RADIUS_S, ThemeTokens.SPACE_S),
		&"DialogPanel": _panel(ThemeTokens.BG_SURFACE, ThemeTokens.GOLD_DEEP, ThemeTokens.BORDER_THICK, ThemeTokens.RADIUS_L, ThemeTokens.SPACE_XL),
		&"ToastPanel": _panel(ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.GOLD_DEEP, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_M, ThemeTokens.SPACE_M),
		&"PersonRowPanel": _panel(ThemeTokens.BG_SURFACE, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_M, ThemeTokens.SPACE_S),
		&"WarningBadge": _panel(ThemeTokens.BG_APP, ThemeTokens.WARNING_TEXT, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_S, ThemeTokens.SPACE_XS),
		&"SummaryPanel": _panel(ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.GOLD, ThemeTokens.BORDER_THICK, ThemeTokens.RADIUS_M, ThemeTokens.SPACE_M),
		&"ListPanel": _panel(ThemeTokens.BG_APP, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_M, ThemeTokens.SPACE_S),
		&"SecretPanel": _panel(ThemeTokens.BG_SURFACE, ThemeTokens.WARNING_TEXT, ThemeTokens.BORDER_THICK, ThemeTokens.RADIUS_M, ThemeTokens.SPACE_S),
	}
	for name: StringName in variations:
		var base := &"Panel" if name == &"AppBackground" else &"PanelContainer"
		theme.set_type_variation(name, base)
		theme.set_stylebox("panel", name, variations[name])
	var line := StyleBoxLine.new()
	line.color = ThemeTokens.BORDER_SUBTLE
	line.thickness = ThemeTokens.BORDER_THIN
	theme.set_stylebox("separator", "HSeparator", line)
	var overlay := StyleBoxFlat.new()
	overlay.bg_color = ThemeTokens.BG_OVERLAY
	theme.set_type_variation(&"OverlayDim", &"Panel")
	theme.set_stylebox("panel", &"OverlayDim", overlay)


static func _containers(theme: Theme) -> void:
	theme.set_constant("separation", "VBoxContainer", ThemeTokens.SPACE_M)
	theme.set_constant("separation", "HBoxContainer", ThemeTokens.SPACE_M)
	theme.set_type_variation(&"ScreenColumn", &"VBoxContainer")
	theme.set_constant("separation", &"ScreenColumn", ThemeTokens.SPACE_L)
	theme.set_type_variation(&"ButtonRow", &"HBoxContainer")
	theme.set_constant("separation", &"ButtonRow", ThemeTokens.SPACE_XL)
	theme.set_type_variation(&"ScreenMargin", &"MarginContainer")
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		theme.set_constant(side, &"ScreenMargin", ThemeTokens.SCREEN_PADDING)


## Texteingaben (LineEdit, TextEdit): dunkle Fläche, Goldrahmen im Fokus, gut lesbarer Platzhalter.
static func _inputs(theme: Theme) -> void:
	for type: StringName in [&"LineEdit", &"TextEdit"]:
		theme.set_stylebox("normal", type, _box(ThemeTokens.BG_APP, ThemeTokens.BORDER_SUBTLE, ThemeTokens.BORDER_THICK, ThemeTokens.RADIUS_S))
		theme.set_stylebox("focus", type, _box(ThemeTokens.BG_APP, ThemeTokens.FOCUS_RING, ThemeTokens.FOCUS_WIDTH, ThemeTokens.RADIUS_S))
		theme.set_stylebox("read_only", type, _box(ThemeTokens.DISABLED_FILL, ThemeTokens.DISABLED_BORDER, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_S))
		theme.set_color("font_color", type, ThemeTokens.TEXT_PRIMARY)
		theme.set_color("font_readonly_color", type, ThemeTokens.TEXT_DISABLED)
		theme.set_color("font_placeholder_color", type, ThemeTokens.TEXT_MUTED)
		theme.set_color("caret_color", type, ThemeTokens.GOLD_BRIGHT)
		theme.set_color("selection_color", type, Color(ThemeTokens.GOLD_DEEP, 0.55))
		theme.set_font_size("font_size", type, ThemeTokens.FONT_BODY)


## Scrollleiste breit genug für Touch-Rückmeldung; Tooltips im Grimmhain-Stil.
static func _scrolling(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = ThemeTokens.BG_APP
	track.set_corner_radius_all(ThemeTokens.RADIUS_S)
	track.content_margin_left = ThemeTokens.SCROLLBAR_WIDTH / 2.0
	track.content_margin_right = ThemeTokens.SCROLLBAR_WIDTH / 2.0
	theme.set_stylebox("scroll", "VScrollBar", track)
	for state: Array in [["grabber", ThemeTokens.BORDER_SUBTLE], ["grabber_highlight", ThemeTokens.GOLD_DEEP], ["grabber_pressed", ThemeTokens.GOLD]]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = state[1]
		grabber.set_corner_radius_all(ThemeTokens.RADIUS_S)
		theme.set_stylebox(state[0], "VScrollBar", grabber)
	theme.set_constant("scrollbar_h_separation", "ScrollContainer", ThemeTokens.SPACE_S)
	theme.set_stylebox("panel", "TooltipPanel", _panel(ThemeTokens.BG_SURFACE_RAISED, ThemeTokens.GOLD_DEEP, ThemeTokens.BORDER_THIN, ThemeTokens.RADIUS_S, ThemeTokens.SPACE_S))
	theme.set_color("font_color", "TooltipLabel", ThemeTokens.TEXT_PRIMARY)
	theme.set_font_size("font_size", "TooltipLabel", ThemeTokens.FONT_BODY)
