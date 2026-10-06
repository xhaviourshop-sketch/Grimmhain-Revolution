class_name RuleBook
extends PanelContainer
## Allgemeines Regelbuch: Inhaltsverzeichnis mit zwölf Kapiteln, darunter das gewählte Kapitel seitenweise (nichts scrollt,
## „Davor/Danach“ blättert) mit Vor- und Zurück-Knöpfen für die Kapitel. Die Inhalte kommen ausschließlich aus den Übersetzungen (RulebookCatalog); das Regelbuch kennt keine
## Partie, keine Personen und keinen Spielstand. Öffnen, Blättern, Sprachwechsel und Schließen senden daher nie einen Befehl und
## verbrauchen keinen Zufall. Der Sprachknopf wechselt die App-Sprache; das geöffnete Kapitel bleibt.
## Ebenen (Cockpit) entstehen über `layer()`; der Schließen-Button heißt dort wie im Lexikon `CloseLayerButton`.

signal close_requested

var settings: AppSettings = null

var _chapter: int = -1
var _show_close: bool = true
var _title: GrimmLabel
var _back_to_toc: GrimmButton
var _language: GrimmButton
var _close: GrimmButton
var _toc_scroll: ScrollContainer
var _chapter_host: VBoxContainer
var _pager: CockpitLayers.Pager = null
var _footer: HBoxContainer
var _prev: GrimmButton
var _next: GrimmButton
var _position: GrimmLabel


## `show_close`: eigener Schließen-Button (Ebenen); in der eigenen Ansicht schließt die Kopfzeile.
func _init(p_settings: AppSettings = null, show_close: bool = true) -> void:
	settings = p_settings
	_show_close = show_close
	name = "RuleBook"
	theme_type_variation = &"CardPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(head)
	_back_to_toc = _button("RulebookBackToTocButton", "ui.rulebook.back_to_toc")
	_back_to_toc.pressed.connect(show_toc)
	head.add_child(_back_to_toc)
	_title = GrimmLabel.new()
	_title.name = "RulebookTitleLabel"
	_title.theme_type_variation = &"HeadingLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_language = _button("RulebookLanguageButton", "ui.rulebook.language")
	_language.pressed.connect(_toggle_language)
	_language.visible = settings != null
	head.add_child(_language)
	_close = _button("CloseLayerButton", "ui.rulebook.close")
	_close.pressed.connect(close_requested.emit)
	_close.visible = show_close
	head.add_child(_close)
	_build_toc(column)
	_chapter_host = VBoxContainer.new()
	_chapter_host.name = "RulebookChapterHost"
	_chapter_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_chapter_host)
	_build_footer(column)
	show_toc()


## Ebene über einer Ansicht (Abdunklung und Regelbuch mit Rand); `chapter` öffnet gleich ein Kapitel (Index ab 0), -1 das Verzeichnis.
static func layer(p_settings: AppSettings, chapter: int = -1) -> Control:
	var book := RuleBook.new(p_settings)
	if chapter >= 0:
		book.open_chapter(chapter)
	return RoleLexicon.overlay(book, "RulebookLayer")


func current_chapter() -> int:
	return _chapter


func is_chapter_open() -> bool:
	return _chapter >= 0


## Kapitel (Index ab 0) öffnen; ungültige Indizes bleiben im Verzeichnis.
func open_chapter(index: int) -> void:
	if index < 0 or index >= RulebookCatalog.count():
		return
	_chapter = index
	_build_chapter()
	_toc_scroll.visible = false
	_chapter_host.visible = true
	_footer.visible = true
	_back_to_toc.visible = true
	_title.visible = true
	_title.text_key = RulebookCatalog.title_key(index)
	_prev.disabled = index == 0
	_next.disabled = index == RulebookCatalog.count() - 1
	_position.format_values = {"number": index + 1, "total": RulebookCatalog.count()}
	_position.text_key = "ui.rulebook.chapter_of"
	_focus(_back_to_toc)


func show_toc() -> void:
	_chapter = -1
	_clear_chapter()
	_toc_scroll.visible = true
	_chapter_host.visible = false
	_footer.visible = false
	_back_to_toc.visible = false
	_title.text_key = "ui.rulebook.title"
	_title.visible = _show_close  # eigene Ansicht: die Kopfzeile trägt den Titel


## Kapiteltexte des offenen Kapitels in Reihenfolge (Überschrift zuerst), für Tests.
func chapter_texts() -> Array[String]:
	var out: Array[String] = []
	if _chapter >= 0:
		for i: int in RulebookCatalog.kinds(_chapter).length():
			out.append(tr(RulebookCatalog.block_key(_chapter, i)))
	return out


## Anzahl der Seiten des offenen Kapitels (0 im Verzeichnis).
func page_count() -> int:
	return _pager.page_count() if _pager != null else 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _title != null and _chapter >= 0:
		_title.text_key = RulebookCatalog.title_key(_chapter)
		_build_chapter()  # andere Sprache, andere Textlängen: Seiten neu einteilen
	elif what == NOTIFICATION_ENTER_TREE and _chapter >= 0:
		_build_chapter()  # erst im Baum gilt das Theme mit den echten Schriften


func _build_toc(column: VBoxContainer) -> void:
	_toc_scroll = ScrollContainer.new()
	_toc_scroll.name = "RulebookTocScroll"
	_toc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_toc_scroll.follow_focus = true
	_toc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_toc_scroll)
	var list := VBoxContainer.new()
	list.name = "RulebookToc"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_toc_scroll.add_child(list)
	var intro := GrimmLabel.new()
	intro.name = "RulebookIntroLabel"
	intro.theme_type_variation = &"MutedLabel"
	intro.text_key = "ui.rulebook.intro"
	list.add_child(intro)
	for i: int in RulebookCatalog.count():
		var b := _button("RulebookChapter_%s" % RulebookCatalog.chapter_id(i), "ui.rulebook.toc.entry", true)
		b.format_values = {"number": i + 1, "title": StringName(RulebookCatalog.title_key(i))}
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(open_chapter.bind(i))
		list.add_child(b)


func _build_footer(column: VBoxContainer) -> void:
	_footer = HBoxContainer.new()
	_footer.name = "RulebookFooter"
	_footer.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(_footer)
	_prev = _button("RulebookPrevButton", "ui.rulebook.prev")
	_prev.pressed.connect(func() -> void: open_chapter(_chapter - 1))
	_footer.add_child(_prev)
	_position = GrimmLabel.new()
	_position.name = "RulebookPositionLabel"
	_position.theme_type_variation = &"MutedLabel"
	_position.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_position.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_position.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(_position)
	_next = _button("RulebookNextButton", "ui.rulebook.next")
	_next.pressed.connect(func() -> void: open_chapter(_chapter + 1))
	_footer.add_child(_next)


const CHAPTER_CHROME := 350.0  ## Rahmen, Kopfzeile, Blätterleiste und Kapitelleiste des Regelbuchs
const SIDE_CHROME := 72.0 + 2.0 * ThemeTokens.SPACE_L  ## Fensterrand links und rechts


func _clear_chapter() -> void:
	_pager = null
	for child: Node in _chapter_host.get_children():
		_chapter_host.remove_child(child)
		child.queue_free()


## Kapitel in Seiten einteilen (Höhen aus den echten Schriften); Zwischentitel bleiben bei ihrem Absatz.
func _build_chapter() -> void:
	_clear_chapter()
	var root_size := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size
	var width := root_size.x - SIDE_CHROME
	var kinds := RulebookCatalog.kinds(_chapter)
	var blocks: Array = []
	for i: int in kinds.length():
		blocks.append({"index": i, "heading": kinds[i] == "h"})
	_pager = CockpitLayers.Pager.new()
	_pager.setup(blocks, _block_label,
		func(block: Dictionary) -> float: return text_height(self, tr(RulebookCatalog.block_key(_chapter, int(block["index"]))),
			&"SectionLabel" if bool(block["heading"]) else &"Label", width),
		maxf(root_size.y - CHAPTER_CHROME, 200.0), false, func(block: Dictionary) -> bool: return bool(block["heading"]))
	_chapter_host.add_child(_pager)


func _block_label(block: Dictionary) -> Control:
	var label := GrimmLabel.new()
	label.name = "Block%02d" % (int(block["index"]) + 1)
	label.text_key = RulebookCatalog.block_key(_chapter, int(block["index"]))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bool(block["heading"]):
		label.theme_type_variation = &"SectionLabel"
	return label


## Höhe eines umbrochenen Textes in der Schrift von `type` bei Breite `width` (für die Seiteneinteilung ohne Scrollen).
static func text_height(node: Control, text: String, type: StringName, width: float) -> float:
	var font := node.get_theme_font(&"font", type)
	var font_size := node.get_theme_font_size(&"font_size", type)
	var block := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y
	var lines := roundf(block / font.get_height(font_size))
	return block + lines * float(node.get_theme_constant(&"line_spacing", type)) + 4.0  # Zeilenabstand des Labels zählt je Zeile


func _toggle_language() -> void:
	if settings == null:
		return
	settings.set_language("en" if settings.language == "de" else "de")


func _focus(target: Control) -> void:
	if target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


## Kompakter Button. `wrap` nur für Zeilen, deren Breite der Container vorgibt (Verzeichnis); Kopf- und Fußknöpfe behalten ihre Textbreite.
func _button(node_name: String, key: String, wrap: bool = false) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = wrap
	b.text_key = key
	return b
