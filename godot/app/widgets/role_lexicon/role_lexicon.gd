class_name RoleLexicon
extends PanelContainer
## Allgemeines Rollenlexikon: Liste aller Katalogrollen mit Suche (Rollenname in der gewählten Sprache) und
## Fraktionsfilter, darunter der Eintrag einer Rolle. Die Inhalte kommen ausschließlich aus den Übersetzungen
## (RolePresentation.lexicon_key) und dem Rollenkatalog; das Lexikon kennt keine Partie, keine Personen und keinen
## Spielstand. Öffnen, Suchen, Filtern und Schließen senden daher nie einen Befehl und verbrauchen keinen Zufall.
## Sprachwechsel über den eigenen Sprachknopf behält die geöffnete Rolle, Suche und Filter.
## Ebenen (Setup, Cockpit) entstehen über `layer()`; der Schließen-Button heißt dort `CloseLayerButton`.

signal close_requested

const FILTER_ALL := &"all"

var settings: AppSettings = null

var _role: StringName = &""
var _show_close: bool = true
var _faction: StringName = FILTER_ALL
var _title: GrimmLabel
var _back_to_list: GrimmButton
var _language: GrimmButton
var _close: GrimmButton
var _list_view: VBoxContainer
var _search: LineEdit
var _filters: Dictionary = {}
var _empty: GrimmLabel
var _rows: Dictionary = {}
var _list_scroll: ScrollContainer
var _entry_scroll: ScrollContainer
var _entry: VBoxContainer


## `show_close`: eigener Schließen-Button (Ebenen); in der eigenen Ansicht schließt die Kopfzeile.
func _init(p_settings: AppSettings = null, show_close: bool = true) -> void:
	settings = p_settings
	_show_close = show_close
	name = "RoleLexicon"
	theme_type_variation = &"CardPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(head)
	_back_to_list = _button("LexiconBackToListButton", "ui.lexicon.back_to_list")
	_back_to_list.pressed.connect(show_list)
	head.add_child(_back_to_list)
	_title = GrimmLabel.new()
	_title.name = "LexiconTitleLabel"
	_title.theme_type_variation = &"HeadingLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_language = _button("LexiconLanguageButton", "ui.lexicon.language")
	_language.pressed.connect(_toggle_language)
	_language.visible = settings != null
	head.add_child(_language)
	_close = _button("CloseLayerButton", "ui.lexicon.close")
	_close.pressed.connect(close_requested.emit)
	_close.visible = show_close
	head.add_child(_close)
	_build_list(column)
	_entry_scroll = ScrollContainer.new()
	_entry_scroll.name = "LexiconEntryScroll"
	_entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_entry_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_entry_scroll)
	show_list()


## Ebene über einer Ansicht: Abdunklung und Lexikon mit Rand; `role` öffnet gleich den Eintrag.
static func layer(p_settings: AppSettings, role: StringName = &"") -> Control:
	var lexicon := RoleLexicon.new(p_settings)
	if role != &"":
		lexicon.open_role(role)
	return overlay(lexicon, "LexiconLayer")


## Abdunklung mit Rand um einen Hilfeinhalt (Lexikon, Regelbuch): eine Ebene über dem Cockpit oder Setup.
static func overlay(content: Control, layer_name: String) -> Control:
	var root := Control.new()
	root.name = layer_name
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := Panel.new()
	dim.name = "Dim"
	dim.theme_type_variation = &"OverlayDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, ThemeTokens.SPACE_L)
	root.add_child(margin)
	margin.add_child(content)
	return root


func current_role() -> StringName:
	return _role


func is_entry_open() -> bool:
	return _role != &""


## Eintrag einer Katalogrolle öffnen; unbekannte IDs bleiben in der Liste.
func open_role(role: StringName) -> void:
	if not SetupRoleCatalog.has_role(role):
		return
	_role = role
	_build_entry()
	_list_view.visible = false
	_entry_scroll.visible = true
	_entry_scroll.scroll_vertical = 0
	_back_to_list.visible = true
	_title.visible = true
	_title.text_key = RolePresentation.name_key(role)
	_focus(_back_to_list)


func show_list() -> void:
	_role = &""
	for child: Node in _entry_scroll.get_children():
		_entry_scroll.remove_child(child)
		child.queue_free()
	_entry = null
	_list_view.visible = true
	_entry_scroll.visible = false
	_back_to_list.visible = false
	_title.text_key = "ui.lexicon.title"
	_title.visible = _show_close  # eigene Ansicht: die Kopfzeile trägt den Titel
	_apply_filter()


func set_search(text: String) -> void:
	_search.text = text
	_apply_filter()


func set_faction(faction: StringName) -> void:
	_faction = faction
	for f: Variant in _filters:
		(_filters[f] as GrimmButton).set_pressed_no_signal(f == faction)
	_apply_filter()


## Sichtbare Rollen der Liste in Anzeigereihenfolge (für Tests und Fokus).
func visible_roles() -> Array[StringName]:
	var out: Array[StringName] = []
	for role: StringName in RolePresentation.sorted_roles():
		if (_rows[role] as Control).visible:
			out.append(role)
	return out


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _search != null:
		_search.placeholder_text = tr("ui.lexicon.search")
		_apply_filter()


func _build_list(column: VBoxContainer) -> void:
	_list_view = VBoxContainer.new()
	_list_view.name = "LexiconListView"
	_list_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_view.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(_list_view)
	_search = LineEdit.new()
	_search.name = "LexiconSearchField"
	_search.custom_minimum_size.y = ThemeTokens.INPUT_HEIGHT
	_search.clear_button_enabled = true
	_search.placeholder_text = tr("ui.lexicon.search")
	_search.text_changed.connect(func(_t: String) -> void: _apply_filter())
	_list_view.add_child(_search)
	var filters := HFlowContainer.new()
	filters.name = "LexiconFilters"
	_list_view.add_child(filters)
	var group := ButtonGroup.new()
	for f: StringName in [FILTER_ALL] + RolePresentation.FACTION_ORDER:
		var b := _button("LexiconFilter_%s" % String(f), "ui.lexicon.filter.all" if f == FILTER_ALL else RolePresentation.faction_key(f))
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = f == _faction
		b.toggled.connect(func(on: bool) -> void:
			if on:
				set_faction(f))
		filters.add_child(b)
		_filters[f] = b
	_empty = GrimmLabel.new()
	_empty.name = "LexiconEmptyLabel"
	_empty.theme_type_variation = &"MutedLabel"
	_empty.text_key = "ui.lexicon.empty"
	_list_view.add_child(_empty)
	_list_scroll = ScrollContainer.new()
	_list_scroll.name = "LexiconListScroll"
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_view.add_child(_list_scroll)
	var list := VBoxContainer.new()
	list.name = "LexiconRoleList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(list)
	for role: StringName in RolePresentation.sorted_roles():
		var b := _button("LexiconRole_%s" % String(role), "ui.lexicon.row", true)
		b.format_values = {"name": StringName(RolePresentation.name_key(role)),
			"faction": StringName(RolePresentation.faction_key(SetupRoleCatalog.faction_of(role)))}
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(open_role.bind(role))
		list.add_child(b)
		_rows[role] = b


func _build_entry() -> void:
	for child: Node in _entry_scroll.get_children():
		_entry_scroll.remove_child(child)
		child.queue_free()
	_entry = VBoxContainer.new()
	_entry.name = "LexiconEntry"
	_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_entry_scroll.add_child(_entry)
	_label(_entry, "ui.lexicon.faction", &"CaptionLabel").format_values = {
		"faction": StringName(RolePresentation.faction_key(SetupRoleCatalog.faction_of(_role)))}
	_label(_entry, RolePresentation.short_key(_role), &"MutedLabel").name = "LexiconShortLabel"
	var fields: Array[String] = RolePresentation.LEXICON_FIELDS.duplicate()
	var open_key := RolePresentation.lexicon_key(_role, RolePresentation.LEXICON_OPEN)
	if TranslationServer.translate(open_key) != StringName(open_key):
		fields.append(RolePresentation.LEXICON_OPEN)
	for field: String in fields:
		var open := field == RolePresentation.LEXICON_OPEN
		_label(_entry, RolePresentation.lexicon_caption_key(field), &"WarningLabel" if open else &"CaptionLabel").name = "LexiconCaption_%s" % field
		_label(_entry, RolePresentation.lexicon_key(_role, field), &"WarningLabel" if open else &"").name = "LexiconField_%s" % field


func _apply_filter() -> void:
	if _search == null:
		return
	var query := _search.text.strip_edges().to_lower()
	var any := false
	for role: StringName in RolePresentation.sorted_roles():
		var fits := _faction == FILTER_ALL or SetupRoleCatalog.faction_of(role) == _faction
		if fits and query != "":
			fits = tr(RolePresentation.name_key(role)).to_lower().contains(query)
		(_rows[role] as Control).visible = fits
		any = any or fits
	_empty.visible = not any
	_list_scroll.visible = any


func _toggle_language() -> void:
	if settings == null:
		return
	settings.set_language("en" if settings.language == "de" else "de")


func _focus(target: Control) -> void:
	if target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


## Kompakter Button. `wrap` nur für Zeilen, deren Breite der Container vorgibt; Kopf- und Filterknöpfe behalten
## ihre Textbreite (sonst bricht ein Fließcontainer jeden Buchstaben um und die Liste rutscht aus dem Bild).
func _button(node_name: String, key: String, wrap: bool = false) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = wrap
	b.text_key = key
	return b


func _label(parent: Node, key: String, variation: StringName) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.text_key = key
	if variation != &"":
		label.theme_type_variation = variation
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label
