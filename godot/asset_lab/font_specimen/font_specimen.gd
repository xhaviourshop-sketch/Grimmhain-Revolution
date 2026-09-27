extends Control
## Schriftmuster · interne Vorschau (Asset-Lab, keine Spieloberfläche, keine Stilentscheidung).
## Vergleicht Cinzel und IM FELL English mit der Godot-Standardschrift auf dem Grimmhain-Theme.
##
## Isolation: kein class_name, kein Autoload, keine Verbindung zum Regelkern, keine Änderung an
## project.godot oder app/. Theme und Tokens werden nur gelesen (ThemeFactory.build()).
##
## Schriften: werden zur Laufzeit aus <Repo>/assets/fonts/ geladen, nicht ins Godot-Projekt kopiert.
## Grund: dort liegen Datei, Lizenztext (OFL-*.txt) und Registerzeile zusammen; test_ui_theme.gd
## verlangt ausdrücklich keine Schriftdatei unter godot/. Vor der Nutzung wird der SHA-256 gegen den
## Registereintrag geprüft. Fehlt eine Datei oder weicht sie ab, zeigt das Muster die
## Standardschrift und benennt den Ersatz sichtbar. Funktioniert nur beim Start aus dem Repository
## (Editor oder Kommandozeile), nicht in einem exportierten Build; das ist für das Lab gewollt.

const FONT_DIR := "../assets/fonts"
## [Schlüssel, Datei, SHA-256 laut docs/masterplan/asset-register.csv]
const FONT_FILES := [
	["cinzel_regular", "Cinzel-Regular.ttf", "6e67a440d19a22e7a14631e7fb8efb71cdf43fde8adf040b7935ac2b38519ab0"],
	["cinzel_bold", "Cinzel-Bold.ttf", "f606ab3a8a0a75863022676ea496478bb0f4d520ae8c40b6050df3d6dbffad20"],
	["fell_regular", "IMFellEnglish-Regular.ttf", "ac506157d2920e96b9f95297207b439cb707fcaff9fb22ecefd23e40e5c338c9"],
	["fell_italic", "IMFellEnglish-Italic.ttf", "542953606df87ff01db1eab9c70a8cc7834f92b3eb2072c2cd00e16e0f82a43a"],
]

const PAGES := ["Titel und Karte", "Erklärung DE/EN", "Größen und Namen"]

const TEXT_DE := "In der Nacht ruft die App jede Rolle einzeln auf. Tippe auf eine Person, um sie auszuwählen, und bestätige danach."
const TEXT_EN := "At night the app calls each role in turn. Tap a person to select them, then confirm."
const CARD_NAME := "Maximilian-Alexander Großkreutz-Hoffmann"
const CARD_INFO := "Fiktive Beispielinformation: Diese Person hat heute Nacht einen Schlüssel gefunden."
const CARD_ACTION := "Auswahl bestätigen"
const SIZE_SAMPLE := "Mäßig trübe Nächte"
const SIZES := [16, 20, 24, 30]
const NAMES := [
	"Maximilian-Alexander Großkreutz-Hoffmann",
	"Anne-Sophie Oberhäußer",
	"Özlem Çelik-Schäfer",
	"Jürgen Straßenmeister",
	"Zoë Müller-Lüdenscheidt",
]

var fonts: Dictionary = {}          ## Schlüssel -> Font (nur geladene, geprüfte Dateien)
var font_notes: Array[String] = []   ## sichtbare Hinweise zu Ersatz und Prüfung
var _pages: Array[Control] = []
var _page_buttons: Array[Button] = []
var _current_page := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeFactory.build()
	_load_fonts()
	_build()
	show_page(0)


## Anzahl der Seiten (für das Prüf- und Screenshot-Skript).
func page_count() -> int:
	return PAGES.size()


func show_page(index: int) -> void:
	_current_page = clampi(index, 0, PAGES.size() - 1)
	for i: int in _pages.size():
		_pages[i].visible = i == _current_page
		_page_buttons[i].button_pressed = i == _current_page


# --- Schriften ------------------------------------------------------------------------------------

func _load_fonts() -> void:
	var base := ProjectSettings.globalize_path("res://").path_join(FONT_DIR).simplify_path()
	for entry: Array in FONT_FILES:
		var key: String = entry[0]
		var file: String = entry[1]
		var expected: String = entry[2]
		var path := base.path_join(file)
		if not FileAccess.file_exists(path):
			font_notes.append("%s fehlt, Ersatz: Standardschrift" % file)
			continue
		var actual := FileAccess.get_sha256(path)
		if actual != expected:
			font_notes.append("%s weicht vom Registereintrag ab (SHA-256), Ersatz: Standardschrift" % file)
			continue
		var font := FontFile.new()
		if font.load_dynamic_font(path) != OK:
			font_notes.append("%s nicht ladbar, Ersatz: Standardschrift" % file)
			continue
		fonts[key] = font
	if font_notes.is_empty():
		font_notes.append("Alle vier Schriftdateien geladen, SHA-256 entspricht dem Register")


## Geprüfte Schrift oder null (dann gilt die Standardschrift des Themes).
func font_or_null(key: String) -> Font:
	return fonts.get(key) as Font


func _default_font_name() -> String:
	var f := ThemeDB.fallback_font
	return f.get_font_name() if f != null and f.get_font_name() != "" else "Godot-Standardschrift"


## Beschriftung einer Schriftspalte, benennt einen Ersatz ausdrücklich.
func _font_label(title: String, key: String) -> String:
	if key == "":
		return "%s (%s, eingebaut)" % [title, _default_font_name()]
	if font_or_null(key) == null:
		return "%s · ERSATZ: Standardschrift" % title
	return title


# --- Aufbau ---------------------------------------------------------------------------------------

func _build() -> void:
	var bg := Panel.new()
	bg.theme_type_variation = &"AppBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, ThemeTokens.SCREEN_PADDING)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", ThemeTokens.SPACE_M)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", ThemeTokens.SPACE_S)
	column.add_child(header)
	var heading := _label("Schriftmuster", ThemeTokens.FONT_HEADING, null)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var group := ButtonGroup.new()
	for i: int in PAGES.size():
		var b := Button.new()
		b.text = PAGES[i]
		b.theme_type_variation = &"CompactButton"
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size.y = ThemeTokens.TOUCH_MIN
		b.pressed.connect(show_page.bind(i))
		header.add_child(b)
		_page_buttons.append(b)

	var note := _label("Interne Vorschau, keine Stilentscheidung und keine Releasefreigabe. " + " · ".join(font_notes),
		ThemeTokens.FONT_CAPTION, null, true)
	note.theme_type_variation = &"CaptionLabel"
	column.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var pages := VBoxContainer.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pages)
	for page: Control in [_page_titles(), _page_explanation(), _page_sizes()]:
		pages.add_child(page)
		_pages.append(page)


## Seite 1: Titel und Beispielkarte, Cinzel gegen IM FELL English.
func _page_titles() -> Control:
	var row := _columns()
	for candidate: Array in [["Cinzel Bold / Regular", "cinzel_bold", "cinzel_regular"],
			["IM FELL English Regular", "fell_regular", "fell_regular"]]:
		var col := _column(row)
		col.add_child(_caption(_font_label(candidate[0], candidate[1])))
		var title := _label("Grimmhain", ThemeTokens.FONT_TITLE - 8, font_or_null(candidate[1]))
		title.add_theme_color_override("font_color", ThemeTokens.GOLD)
		col.add_child(title)
		col.add_child(_label("Die Nacht beginnt", ThemeTokens.FONT_HEADING, font_or_null(candidate[2])))
		col.add_child(_card(font_or_null(candidate[1]), font_or_null(candidate[2])))
	return row


## Beispielkarte: Name in der Kandidatenschrift, Information in der Standardschrift, großer Button.
func _card(name_font: Font, button_font: Font) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", ThemeTokens.SPACE_M)
	card.add_child(box)
	box.add_child(_label(CARD_NAME, ThemeTokens.FONT_SUBTITLE, name_font, true))
	var info := _label(CARD_INFO, ThemeTokens.FONT_BODY, null, true)
	info.theme_type_variation = &"MutedLabel"
	box.add_child(info)
	var action := Button.new()
	action.text = CARD_ACTION
	action.theme_type_variation = &"PrimaryButton"
	action.custom_minimum_size.y = ThemeTokens.BUTTON_PRIMARY_HEIGHT
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if button_font != null:
		action.add_theme_font_override("font", button_font)
	box.add_child(action)
	return card


## Seite 2: dieselbe Erklärung DE und EN in drei Schriften, Lesegröße FONT_BODY.
func _page_explanation() -> Control:
	var row := _columns()
	for candidate: Array in [["Standardschrift", ""], ["IM FELL English", "fell_regular"], ["Cinzel", "cinzel_regular"]]:
		var col := _column(row)
		var font: Font = font_or_null(candidate[1]) if candidate[1] != "" else null
		col.add_child(_caption(_font_label(candidate[0], candidate[1])))
		col.add_child(_caption("DE · %d px" % ThemeTokens.FONT_BODY))
		col.add_child(_label(TEXT_DE, ThemeTokens.FONT_BODY, font, true))
		col.add_child(_caption("EN · %d px" % ThemeTokens.FONT_BODY))
		col.add_child(_label(TEXT_EN, ThemeTokens.FONT_BODY, font, true))
	return row


## Seite 3: Größenstufen und lange Namen mit Umlauten und ß.
func _page_sizes() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", ThemeTokens.SPACE_L)
	var candidates := [["Standard", ""], ["IM FELL English", "fell_regular"], ["Cinzel", "cinzel_regular"]]

	var sizes := GridContainer.new()
	sizes.columns = 4
	sizes.add_theme_constant_override("h_separation", ThemeTokens.SPACE_M)
	sizes.add_theme_constant_override("v_separation", ThemeTokens.SPACE_S)
	box.add_child(sizes)
	sizes.add_child(_size_caption("Größe"))
	for c: Array in candidates:
		sizes.add_child(_caption(_font_label(c[0], c[1])))
	for px: int in SIZES:
		sizes.add_child(_size_caption("%d px" % px))
		for c: Array in candidates:
			var cell := _label(SIZE_SAMPLE, px, font_or_null(c[1]) if c[1] != "" else null, true)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sizes.add_child(cell)

	var names := GridContainer.new()
	names.columns = 3
	names.add_theme_constant_override("h_separation", ThemeTokens.SPACE_M)
	names.add_theme_constant_override("v_separation", ThemeTokens.SPACE_S)
	box.add_child(names)
	for c: Array in candidates:
		names.add_child(_caption("Spielernamen · %s · %d px" % [c[0], ThemeTokens.FONT_BODY]))
	for n: String in NAMES:
		for c: Array in candidates:
			var cell := _label(n, ThemeTokens.FONT_BODY, font_or_null(c[1]) if c[1] != "" else null, true)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			names.add_child(cell)
	return box


# --- Bausteine ------------------------------------------------------------------------------------

func _columns() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ThemeTokens.SPACE_L)
	return row


func _column(row: HBoxContainer) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 1.0
	col.add_theme_constant_override("separation", ThemeTokens.SPACE_S)
	row.add_child(col)
	return col


func _caption(text: String) -> Label:
	var l := _label(text, ThemeTokens.FONT_CAPTION, null, true)
	l.theme_type_variation = &"CaptionLabel"
	return l


## Schmale erste Spalte der Größentabelle (bricht nicht um, dehnt sich nicht).
func _size_caption(text: String) -> Label:
	var l := _label(text, ThemeTokens.FONT_CAPTION, null)
	l.theme_type_variation = &"CaptionLabel"
	return l


func _label(text: String, px: int, font: Font, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px)
	if font != null:
		l.add_theme_font_override("font", font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 1  # Umbruch statt Verbreiterung der Spalte
	return l
