class_name RoundStep
extends PrepStep
## Schritt 1 „Runde“: große Plus/Minus-Auswahl der Spielerzahl (6 bis 24), Zähler Dorf/Wölfe/Einzelgänger des Vorschlags, die vier
## Akt-Karten (fertige Rollen-Sets) und der Schalter „App verteilt zufällig“ / „Echte Karten – ich weise zu“. Alles ist vorbelegt und
## sofort änderbar; Weiter ist aktiv, solange der gewählte Akt die Zahl trägt. Die Wahrheit liegt in PlayerSetup, dieser Schritt
## stellt nur dar und ruft Operationen auf. Der Schalter steht links unter den Teamzählern, damit er bei 1024x768 ohne Scrollen sichtbar ist.
## Die Seite scrollt, wenn das Fenster zu niedrig ist; nichts wird abgeschnitten.

signal next_requested

var _minus: GlyphButton
var _plus: GlyphButton
var _value: GrimmLabel
var _teams: Dictionary[StringName, TeamCounter] = {}
var _cards: Dictionary[StringName, ActCard] = {}
var _random: ChoiceButton
var _manual: ChoiceButton
var _last_view: Dictionary = {}
var _scroll: ScrollContainer
var animated: bool = true:  ## aus bei reduzierter Bewegung (Feuer der Akt-Karten steht still)
	set(value):
		animated = value
		for card: ActCard in _cards.values():
			card.animated = value


func start(setup: PlayerSetup) -> void:
	_setup = setup
	name = "RoundStep"
	_scroll = ScrollContainer.new()
	_scroll.name = "RoundScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	add_child(_scroll)
	var columns := HBoxContainer.new()
	columns.name = "RoundColumns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XL)
	_scroll.add_child(columns)
	var left := VBoxContainer.new()
	left.name = "CountColumn"
	left.custom_minimum_size.x = ThemeTokens.PREP_COUNT_COLUMN_WIDTH
	left.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	left.add_child(_count_block())
	left.add_child(_team_counters())
	left.add_child(_modes())
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.name = "ChoiceColumn"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	right.add_child(_heading("ActsHeading", "ui.prep.act.heading"))
	right.add_child(_acts())
	columns.add_child(right)
	_setup.changed.connect(_render)
	_render(_setup.view())


func default_focus() -> Control:
	return _cards.get(StringName(str(_last_view.get("act", "akt1"))), _plus)


func footer() -> Dictionary:
	return {"next_key": "ui.prep.next.names", "next_enabled": true, "next_primary": true, "hint_key": "", "hint_values": {}, "hint_error": false}


func activate_next() -> void:
	next_requested.emit()


func _count_block() -> Control:
	var block := VBoxContainer.new()
	block.name = "CountBlock"
	block.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	block.add_child(_heading("CountHeading", "ui.prep.round.heading"))
	var counter := HBoxContainer.new()
	counter.name = "Counter"
	counter.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	_minus = _round_button("MinusButton", "minus", "ui.prep.round.minus")
	_minus.pressed.connect(func() -> void: _change(-1))
	counter.add_child(_minus)
	_value = GrimmLabel.new()
	_value.name = "CountValue"
	_value.theme_type_variation = &"HainCounterLabel"
	_value.wrap = false
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.custom_minimum_size.x = float(ThemeTokens.COUNTER_VALUE_FONT) * 1.7
	counter.add_child(_value)
	_plus = _round_button("PlusButton", "plus", "ui.prep.round.plus")
	_plus.pressed.connect(func() -> void: _change(1))
	counter.add_child(_plus)
	block.add_child(counter)
	var range_hint := GrimmLabel.new()
	range_hint.name = "CountRange"
	range_hint.theme_type_variation = &"HainCaptionLabel"
	range_hint.format_values = {"min": PersonNameRules.MIN_PERSONS, "max": PersonNameRules.MAX_PERSONS}
	range_hint.text_key = "ui.prep.round.range"
	block.add_child(range_hint)
	return block


func _team_counters() -> Control:
	var teams := VBoxContainer.new()
	teams.name = "TeamCounters"
	teams.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	teams.add_child(_heading("RecommendedHeading", "ui.prep.round.recommended"))
	for team: StringName in [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]:
		var counter_view := TeamCounter.new()
		counter_view.setup(team)
		teams.add_child(counter_view)
		_teams[team] = counter_view
	return teams


func _acts() -> Control:
	var row := GridContainer.new()
	row.name = "ActCards"
	row.columns = 2
	row.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_M)
	row.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_M)
	for act: StringName in ActCatalog.ACT_IDS:
		var card := ActCard.new()
		card.setup(act)
		card.pressed.connect(func() -> void: _setup.set_act(act))
		row.add_child(card)
		_cards[act] = card
	return row


func _modes() -> Control:
	var row := VBoxContainer.new()
	row.name = "ModeRow"
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	var group := ButtonGroup.new()
	_random = _mode_button(group, "RandomModeButton", "ui.prep.mode.random")
	_manual = _mode_button(group, "ManualModeButton", "ui.prep.mode.manual")
	_random.toggled.connect(func(on: bool) -> void:
		if on:
			_setup.set_distribution_mode(DistributionDraft.RANDOM))
	_manual.toggled.connect(func(on: bool) -> void:
		if on:
			_setup.set_distribution_mode(DistributionDraft.MANUAL))
	row.add_child(_random)
	row.add_child(_manual)
	return row


func _mode_button(group: ButtonGroup, node_name: String, key: String) -> ChoiceButton:
	var button := ChoiceButton.new()
	button.name = node_name
	button.button_group = group
	button.text_key = key
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _round_button(node_name: String, glyph: String, key: String) -> GlyphButton:
	var button := GlyphButton.new()
	button.name = node_name
	button.glyph = glyph
	button.text_key = key
	button.tooltip_text = tr(key)
	button.custom_minimum_size = Vector2(ThemeTokens.COUNTER_BUTTON_SIZE, ThemeTokens.COUNTER_BUTTON_SIZE)
	return button


func _heading(node_name: String, key: String) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.name = node_name
	label.theme_type_variation = &"HainSectionLabel"
	label.text_key = key
	return label


func _change(delta: int) -> void:
	_setup.set_player_count(int(_last_view.get("player_count", PersonNameRules.MIN_PERSONS)) + delta)


func _render(view: Dictionary) -> void:
	_last_view = view
	var count := int(view["player_count"])
	_value.format_values = {"value": count}
	_value.text_key = "ui.prep.number"
	_minus.disabled = count <= int(view["min_persons"])
	_plus.disabled = count >= int(view["max_persons"])
	var teams: Dictionary = view["proposal_teams"]
	for team: StringName in _teams:
		_teams[team].show_count(int(teams.get(String(team), -1)) if not teams.is_empty() else -1)
	for entry: Variant in view["acts"]:
		var act: Dictionary = entry
		var card := _cards[StringName(str(act["id"]))]
		card.show_state(bool(act["selected"]), int(act["capacity"]))
	var manual := str(view["mode"]) == String(DistributionDraft.MANUAL)
	if _manual.button_pressed != manual:
		_manual.set_pressed_no_signal(manual)
	if _random.button_pressed == manual:
		_random.set_pressed_no_signal(not manual)
	footer_changed.emit()
