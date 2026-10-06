class_name ThemeFactory
extends RefCounted
## Baut das Grimmhain-Theme aus ThemeTokens (keine .tres-Kopie der Werte). Variationen:
##   Buttons:  PrimaryButton, SecondaryButton, DangerButton, CompactButton und je ein "…Toggle"-Zwilling (gewählt = aktiv-Bild);
##             alle aus gemalten Leisten (SkinArt, SkinBarBox), Hauptaktion über den Rubinstein (GrimmButton.main)
##   Labels:   TitleLabel, SubtitleLabel, HeadingLabel, MutedLabel, CaptionLabel
##   Panels:   Fenster (SkinWindowBox: CardPanel, DialogPanel, DrawerPanel, ...), Leisten und Listenzeilen (SkinBarBox: HeaderPanel,
##             ToastPanel, ListRow, PersonRowPanel, ...), AppBackground (einfarbig)
##   Container: ScreenColumn (großer Abstand), ScreenMargin (Innenrand)
## Jeder Button-Zustand (normal, hover, pressed, focus, disabled) hat eine eigene StyleBox aus einem gemalten Bild.



static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = ThemeTokens.FONT_BODY
	_labels(theme)
	_buttons(theme)
	_toggles(theme)
	_panels(theme)
	_containers(theme)
	_inputs(theme)
	_hain_inputs(theme)
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


static func _labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", ThemeTokens.TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", ThemeTokens.FONT_BODY)
	var variations := {
		&"TitleLabel": [ThemeTokens.FONT_TITLE, ThemeTokens.MOON_SILVER],
		&"SubtitleLabel": [ThemeTokens.FONT_SUBTITLE, ThemeTokens.TEXT_MUTED],
		&"HeadingLabel": [ThemeTokens.FONT_HEADING, ThemeTokens.TEXT_PRIMARY],
		&"MutedLabel": [ThemeTokens.FONT_BODY, ThemeTokens.TEXT_MUTED],
		&"CaptionLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.TEXT_MUTED],
		&"ErrorLabel": [ThemeTokens.FONT_BODY, ThemeTokens.DANGER_TEXT],
		&"WarningLabel": [ThemeTokens.FONT_BODY, ThemeTokens.MOON_SILVER_BRIGHT],
		&"BadgeLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.MOON_SILVER_BRIGHT],
		&"SectionLabel": [ThemeTokens.FONT_SUBTITLE, ThemeTokens.TEXT_PRIMARY],
		&"ErrorCaptionLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.DANGER_TEXT],
		&"ReadAloudLabel": [ThemeTokens.FONT_SUBTITLE, ThemeTokens.TEXT_PRIMARY],
		&"ShowValueLabel": [ThemeTokens.FONT_SHOW, ThemeTokens.MOON_SILVER_BRIGHT],
		&"ShowNumberLabel": [ThemeTokens.FONT_SHOW_NUMBER, ThemeTokens.MOON_SILVER_BRIGHT],
		&"ShowCaptionLabel": [ThemeTokens.FONT_SHOW_CAPTION, ThemeTokens.MOON_SILVER],
		# Mini-Nachtkarte (DA-101): Zeile „Name · Rolle · Aktion“, Warnungen in lesbarem Rot, zuschaltbare Ansage klein.
		&"NightLineLabel": [ThemeTokens.FONT_BUTTON, ThemeTokens.TEXT_PRIMARY],
		&"NightActionLabel": [ThemeTokens.FONT_BODY, ThemeTokens.MOON_SILVER_BRIGHT],
		&"NightWarningLabel": [ThemeTokens.FONT_BODY, ThemeTokens.DANGER_TEXT],
		&"NightCallLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.MOON_SILVER],
		# Vorbereitung im Hain-Stil: Mondsilber statt Gold, Blutrot nur für Aktives (siehe ThemeTokens, DA-89).
		&"HainLabel": [ThemeTokens.FONT_BODY, ThemeTokens.PREP_CARD_TEXT],
		&"HainMutedLabel": [ThemeTokens.FONT_BODY, ThemeTokens.MOON_SILVER],
		&"HainCaptionLabel": [ThemeTokens.FONT_CAPTION, ThemeTokens.MOON_SILVER],
		&"HainSectionLabel": [ThemeTokens.FONT_SUBTITLE, ThemeTokens.MOON_SILVER_BRIGHT],
		&"HainHeadingLabel": [ThemeTokens.FONT_HEADING, ThemeTokens.MOON_SILVER_BRIGHT],
		&"HainCounterLabel": [ThemeTokens.COUNTER_VALUE_FONT, ThemeTokens.MOON_SILVER_BRIGHT],
	}
	for name: StringName in variations:
		theme.set_type_variation(name, &"Label")
		theme.set_font_size("font_size", name, variations[name][0])
		theme.set_color("font_color", name, variations[name][1])
	# Gotischer Titel (Marke: große Titel gotisch-geschmiedet, Mondsilber); fehlt die Schriftdatei, bleibt es die Grundschrift.
	theme.set_type_variation(&"GothicTitleLabel", &"Label")
	theme.set_font_size("font_size", &"GothicTitleLabel", ThemeTokens.FONT_GOTHIC)
	theme.set_color("font_color", &"GothicTitleLabel", ThemeTokens.MOON_SILVER_BRIGHT)
	if ResourceLoader.exists(ThemeTokens.GOTHIC_FONT):
		theme.set_font("font", &"GothicTitleLabel", load(ThemeTokens.GOTHIC_FONT) as Font)


const BUTTON_MARGIN_X := 42  ## Text bleibt zwischen den Dornen-Enden der Knopfleiste
const BUTTON_MARGIN_Y := 6
const SEAT_MARGIN_X := 36
const DIVIDER_PAD := 18  ## halbe Höhe der Silber-Trennlinie in Pixeln


## Knöpfe (Feedback 8): alle Zustände aus gemalten Leisten (`SkinBarBox`), nie Flat. Ruhe = normal, gedrückt = gedrückt-Bild,
## gewählt (Umschalter, Hauptaktion gewählt) = aktiv-Bild; gesperrt = Ruhebild abgedunkelt, Hover und Fokus heller.
## Die Hauptaktion unterscheidet sich durch den Rubinstein (GrimmButton.main), nicht durch eine rote Fläche.
static func _buttons(theme: Theme) -> void:
	var text := ThemeTokens.TEXT_PRIMARY
	var bright := ThemeTokens.MOON_SILVER_BRIGHT
	for name: StringName in [&"Button", &"SecondaryButton", &"PrimaryButton", &"DangerButton", &"CompactButton"]:
		if name != &"Button":
			theme.set_type_variation(name, &"Button")
		var font := ThemeTokens.DANGER_TEXT if name == &"DangerButton" else text
		var margin := ThemeTokens.SPACE_XL + ThemeTokens.SPACE_S if name == &"CompactButton" else BUTTON_MARGIN_X
		_skin_button_type(theme, name, "normal", "gedrueckt", "gedrueckt", font, bright, Color.WHITE, margin)
		if name == &"CompactButton":
			theme.set_font_size("font_size", name, ThemeTokens.FONT_COMPACT)
		# Umschalter-Zwilling (GrimmButton mit toggle_mode): gewählt zeigt das aktiv-Bild.
		if name != &"Button":
			var twin := StringName(String(name) + "Toggle")
			theme.set_type_variation(twin, &"Button")
			_skin_button_type(theme, twin, "normal", "aktiv", "aktiv", font, bright, Color.WHITE, margin)
			if name == &"CompactButton":
				theme.set_font_size("font_size", twin, ThemeTokens.FONT_COMPACT)
	# Platzsymbole der Sitzordnung: Ruhe, gewählt (aktiv), Ablageziel (gedrückt), tot (abgedunkelt), handelnd (aktiv).
	var seats := {
		&"SeatButton": ["normal", "gedrueckt", Color.WHITE, text],
		&"SeatSelectedButton": ["aktiv", "aktiv", Color.WHITE, text],
		&"SeatTargetButton": ["gedrueckt", "gedrueckt", Color.WHITE, text],
		&"SeatDeadButton": ["normal", "gedrueckt", SkinArt.TINT_DEAD, ThemeTokens.TEXT_MUTED],
		&"SeatActorButton": ["aktiv", "aktiv", Color.WHITE, text],
	}
	for name: StringName in seats:
		var d: Array = seats[name]
		theme.set_type_variation(name, &"Button")
		_skin_button_type(theme, name, d[0], d[1], d[1], d[3], bright, d[2], SEAT_MARGIN_X)
		theme.set_font_size("font_size", name, ThemeTokens.FONT_COMPACT)
	theme.set_type_variation(&"SecondaryButton", &"Button")


## Eine Knopf-Variation: Ruhebild `rest`, Bild beim Drücken `down`, Bild gedrückt-und-darüber `hover_down`; `rest_tint` färbt das Ruhebild.
static func _skin_button_type(theme: Theme, type: StringName, rest: String, down: String, hover_down: String, font: Color, font_down: Color, rest_tint: Color, margin_x: int) -> void:
	var boxes := {
		"normal": SkinArt.button_box(rest, rest_tint),
		"hover": SkinArt.button_box(rest, rest_tint * SkinArt.TINT_HOVER),
		"pressed": SkinArt.button_box(down, rest_tint),
		"hover_pressed": SkinArt.button_box(hover_down, rest_tint * SkinArt.TINT_HOVER),
		"disabled": SkinArt.button_box(rest, rest_tint * SkinArt.TINT_DISABLED),
		"focus": SkinArt.button_box(rest, SkinArt.TINT_FOCUS),
	}
	for state: String in boxes:
		var box := boxes[state] as SkinBarBox
		box.content_margin_left = margin_x
		box.content_margin_right = margin_x
		box.content_margin_top = BUTTON_MARGIN_Y
		box.content_margin_bottom = BUTTON_MARGIN_Y
		theme.set_stylebox(state, type, box)
	theme.set_color("font_color", type, font)
	theme.set_color("font_hover_color", type, font)
	theme.set_color("font_focus_color", type, font)
	theme.set_color("font_pressed_color", type, font_down)
	theme.set_color("font_hover_pressed_color", type, font_down)
	theme.set_color("font_disabled_color", type, ThemeTokens.TEXT_DISABLED)
	theme.set_font_size("font_size", type, ThemeTokens.FONT_BUTTON)
	theme.set_constant("h_separation", type, ThemeTokens.SPACE_S)


## Umschalter (CheckButton): der gemalte Drehknopf-Schalter zeigt den Zustand (an = roter Hebel, aus = dunkel), die Beschriftung steht daneben.
static func _toggles(theme: Theme) -> void:
	var type := &"CheckButton"
	var empty := StyleBoxEmpty.new()
	empty.content_margin_top = ThemeTokens.SPACE_S
	empty.content_margin_bottom = ThemeTokens.SPACE_S
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		theme.set_stylebox(state, type, empty)
	for c: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(c, type, ThemeTokens.TEXT_PRIMARY)
	theme.set_color("font_disabled_color", type, ThemeTokens.TEXT_DISABLED)
	theme.set_font_size("font_size", type, ThemeTokens.FONT_BUTTON)
	theme.set_constant("h_separation", type, ThemeTokens.SPACE_M)
	var on := SkinArt.switch_icon(true)
	var off := SkinArt.switch_icon(false)
	for suffix: String in ["", "_mirrored"]:
		theme.set_icon("checked" + suffix, type, on)
		theme.set_icon("unchecked" + suffix, type, off)
		theme.set_icon("checked_disabled" + suffix, type, on)
		theme.set_icon("unchecked_disabled" + suffix, type, off)


## Fensterfläche: gekachelter Grund im Dornenrahmen; `inset` = Textabstand (links, oben, rechts, unten).
static func _window(inset: Vector4, tint: Color = Color.WHITE, small: bool = false) -> SkinWindowBox:
	var box := SkinArt.window_box(tint, small)
	box.content_margin_left = inset.x
	box.content_margin_top = inset.y
	box.content_margin_right = inset.z
	box.content_margin_bottom = inset.w
	return box


## Schmale Leiste oder Listenzeile aus dem gemalten Streifen; `pad` = Textabstand (waagerecht, senkrecht).
static func _bar(pad_x: int, pad_y: int, tint: Color = Color.WHITE) -> SkinBarBox:
	var box := SkinArt.row_box(tint)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


## Einfarbiger Bildschirmgrund (kein Fenster, kein Kasten).
static func _flat_backdrop(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	return box


const WINDOW_INSET := Vector4(36.0, 28.0, 36.0, 28.0)
const BOARD_INSET := Vector4(16.0, 14.0, 16.0, 14.0)


static func _panels(theme: Theme) -> void:
	# Fenster, Karten und Flächen: Grund und Dornenrahmen (SkinWindowBox).
	theme.set_stylebox("panel", "PanelContainer", _window(WINDOW_INSET))
	theme.set_stylebox("panel", "Panel", _flat_backdrop(ThemeTokens.BG_APP))
	var night := SkinArt.TINT_NIGHT
	var day := SkinArt.TINT_DAY
	var variations := {
		&"CardPanel": _window(WINDOW_INSET),
		&"PlaceholderPanel": _window(WINDOW_INSET),
		&"DialogPanel": _window(Vector4(48.0, 36.0, 48.0, 36.0)),
		&"DrawerPanel": _window(WINDOW_INSET),
		&"ShowPanel": _window(Vector4(48.0, 36.0, 48.0, 36.0), night),
		&"SummaryPanel": _window(WINDOW_INSET),
		&"ListPanel": _window(Vector4(28.0, 22.0, 28.0, 22.0), Color.WHITE, true),
		&"SecretPanel": _window(WINDOW_INSET),
		&"CoverPanel": _window(Vector4(48.0, 36.0, 48.0, 36.0)),
		&"NightCardPanel": _window(Vector4(30.0, 24.0, 30.0, 24.0), night, true),
		&"BoardPanel": _window(BOARD_INSET, Color.WHITE, true),
		&"NightBoardPanel": _window(BOARD_INSET, night, true),
		&"DayBoardPanel": _window(BOARD_INSET, day, true),
		# Leisten, Plaketten und Listenzeilen: der gemalte Streifen (SkinBarBox).
		&"HeaderPanel": _bar(40, 8),
		&"BarPanel": _bar(28, 6),
		&"StatusBadge": _bar(32, 4),
		&"WarningBadge": _bar(28, 4),
		&"NightPanel": _bar(40, 8, night),
		&"DayPanel": _bar(40, 8, day),
		&"ToastPanel": _bar(48, 10),
		&"PersonRowPanel": _bar(40, 6),
		&"ListRow": _bar(40, 6),
		# Bildschirm-Hintergründe bleiben einfarbig (keine Fensterfläche).
		&"AppBackground": _flat_backdrop(ThemeTokens.BG_APP),
		&"NightBackdrop": _flat_backdrop(ThemeTokens.NIGHT_BACKDROP),
		&"DayBackdrop": _flat_backdrop(ThemeTokens.DAY_BACKDROP),
	}
	for name: StringName in variations:
		var base := &"Panel" if name in [&"AppBackground", &"NightBackdrop", &"DayBackdrop"] else &"PanelContainer"
		theme.set_type_variation(name, base)
		theme.set_stylebox("panel", name, variations[name])
	var divider := SkinArt.divider_box(ThemeTokens.MOON_SILVER_BRIGHT)  # hell, damit die Silberlinie auch auf Nachtblau klar liest
	divider.content_margin_top = DIVIDER_PAD  # Separator zeichnet die Box nur in Höhe ihrer Mindestgröße (Linie ca. 1,6-fach)
	divider.content_margin_bottom = DIVIDER_PAD
	theme.set_stylebox("separator", "HSeparator", divider)
	theme.set_constant("separation", "HSeparator", int(DIVIDER_PAD * 2.0))
	var overlay := StyleBoxFlat.new()
	overlay.bg_color = ThemeTokens.BG_OVERLAY
	theme.set_type_variation(&"OverlayDim", &"Panel")
	theme.set_stylebox("panel", &"OverlayDim", overlay)


static func _containers(theme: Theme) -> void:
	theme.set_constant("separation", "VBoxContainer", ThemeTokens.SPACE_M)
	theme.set_constant("separation", "HBoxContainer", ThemeTokens.SPACE_M)
	theme.set_type_variation(&"BoardColumn", &"VBoxContainer")  ## Cockpit: Leisten und Brett ohne Luft dazwischen
	theme.set_constant("separation", &"BoardColumn", ThemeTokens.BAR_GAP)
	theme.set_type_variation(&"BarRow", &"HBoxContainer")
	theme.set_constant("separation", &"BarRow", ThemeTokens.SPACE_S)
	theme.set_type_variation(&"ScreenColumn", &"VBoxContainer")
	theme.set_constant("separation", &"ScreenColumn", ThemeTokens.SPACE_L)
	theme.set_type_variation(&"ButtonRow", &"HBoxContainer")
	theme.set_constant("separation", &"ButtonRow", ThemeTokens.SPACE_XL)
	theme.set_type_variation(&"ScreenMargin", &"MarginContainer")
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		theme.set_constant(side, &"ScreenMargin", ThemeTokens.SCREEN_PADDING)


## Texteingaben (LineEdit, TextEdit): gemaltes Eingabefeld, im Fokus heller Mondsilber-Schein, gut lesbarer Platzhalter.
static func _inputs(theme: Theme) -> void:
	for type: StringName in [&"LineEdit", &"TextEdit"]:
		_input_boxes(theme, type)
		theme.set_color("font_color", type, ThemeTokens.TEXT_PRIMARY)
		theme.set_color("font_readonly_color", type, ThemeTokens.TEXT_DISABLED)
		theme.set_color("font_placeholder_color", type, ThemeTokens.TEXT_MUTED)
		theme.set_color("caret_color", type, ThemeTokens.MOON_SILVER_BRIGHT)
		theme.set_color("selection_color", type, Color(ThemeTokens.MOON_SILVER_DIM, 0.55))
		theme.set_font_size("font_size", type, ThemeTokens.FONT_BODY)


## Gemaltes Eingabefeld in allen Zuständen; der Fokus leuchtet (helle Tönung) statt eines Rahmens.
static func _input_boxes(theme: Theme, type: StringName) -> void:
	var glow := Color(ThemeTokens.MOON_SILVER_BRIGHT).lerp(Color.WHITE, 0.5) * 1.15
	glow.a = 1.0
	var states := {
		"normal": Color(ThemeTokens.MOON_SILVER).darkened(0.1),
		"focus": glow,
		"read_only": Color(ThemeTokens.TEXT_DISABLED),
	}
	for state: String in states:
		if type.ends_with("TextEdit"):
			# Mehrzeilig: eine gemalte Fläche (die Leiste würde bei mehreren Zeilen riesige Enden bekommen und die Spalte aufweiten).
			var area := SkinArt.window_box(states[state], true)
			area.content_margin_left = 28
			area.content_margin_right = 28
			area.content_margin_top = 20
			area.content_margin_bottom = 20
			theme.set_stylebox(state, type, area)
			continue
		var box := SkinArt.input_box(states[state])
		box.content_margin_left = 46  # Text und Platzhalter weg von den Dornen
		box.content_margin_right = 46
		box.content_margin_top = 12
		box.content_margin_bottom = 12
		box.max_height = 72.0
		theme.set_stylebox(state, type, box)


## Eingaben der Vorbereitung im Hain-Stil: gemaltes Feld, Fokus als Mondsilber-Schein, kein Gold.
static func _hain_inputs(theme: Theme) -> void:
	for base: StringName in [&"LineEdit", &"TextEdit"]:
		var type := StringName("Hain" + String(base))
		theme.set_type_variation(type, base)
		_input_boxes(theme, type)
		theme.set_color("font_color", type, ThemeTokens.PREP_CARD_TEXT)
		theme.set_color("font_placeholder_color", type, ThemeTokens.MOON_SILVER)
		theme.set_color("caret_color", type, ThemeTokens.MOON_SILVER_BRIGHT)
		theme.set_color("selection_color", type, Color(ThemeTokens.BLOOD_RED, 0.55))
		theme.set_font_size("font_size", type, ThemeTokens.FONT_BODY)


## Scrollleiste breit genug für Touch-Rückmeldung; Tooltips im Grimmhain-Stil.
static func _scrolling(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = ThemeTokens.BG_APP
	track.set_corner_radius_all(ThemeTokens.RADIUS_S)
	track.content_margin_left = ThemeTokens.SCROLLBAR_WIDTH / 2.0
	track.content_margin_right = ThemeTokens.SCROLLBAR_WIDTH / 2.0
	theme.set_stylebox("scroll", "VScrollBar", track)
	for state: Array in [["grabber", ThemeTokens.BORDER_SUBTLE], ["grabber_highlight", ThemeTokens.MOON_SILVER_DIM], ["grabber_pressed", ThemeTokens.MOON_SILVER]]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = state[1]
		grabber.set_corner_radius_all(ThemeTokens.RADIUS_S)
		theme.set_stylebox(state[0], "VScrollBar", grabber)
	theme.set_constant("scrollbar_h_separation", "ScrollContainer", ThemeTokens.SPACE_S)
	var plaque := SkinArt.plaque_box()
	plaque.content_margin_left = 36
	plaque.content_margin_right = 36
	plaque.content_margin_top = 14
	plaque.content_margin_bottom = 14
	theme.set_stylebox("panel", "TooltipPanel", plaque)
	theme.set_color("font_color", "TooltipLabel", ThemeTokens.TEXT_PRIMARY)
	theme.set_font_size("font_size", "TooltipLabel", ThemeTokens.FONT_BODY)
