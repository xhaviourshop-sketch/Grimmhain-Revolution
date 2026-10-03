class_name TeamCounter
extends HBoxContainer
## Zähler eines Teams (Dorf, Wölfe, Einzelgänger): Teamsymbol im Mondsilber, große Zahl und Teamname. Reine Darstellung. Ohne Zahl (der
## gewählte Akt trägt die Personenzahl nicht) steht ein Gedankenstrich. Der Name des Teams steht immer als Text neben dem Symbol.

var team: StringName = &""
var _symbol: TextureRect
var _value: GrimmLabel
var _caption: GrimmLabel
var _shown: int = -1


func _init() -> void:
	add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)


func setup(p_team: StringName) -> void:
	team = p_team
	name = "TeamCounter_%s" % String(team)
	_symbol = TextureRect.new()
	_symbol.name = "TeamSymbol"
	_symbol.texture = NightArt.team(team)
	_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_symbol.custom_minimum_size = Vector2(ThemeTokens.TEAM_SYMBOL_SIZE, ThemeTokens.TEAM_SYMBOL_SIZE)
	_symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_symbol)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(column)
	_value = GrimmLabel.new()
	_value.name = "TeamValue"
	_value.theme_type_variation = &"HainHeadingLabel"
	_value.wrap = false
	column.add_child(_value)
	_caption = GrimmLabel.new()
	_caption.name = "TeamCaption"
	_caption.theme_type_variation = &"HainCaptionLabel"
	_caption.wrap = false
	_caption.text_key = "ui.prep.team.%s" % String(team)
	column.add_child(_caption)
	show_count(-1)


## `count` < 0: keine Angabe.
func show_count(count: int) -> void:
	_value.format_values = {"value": count if count >= 0 else "–"}
	_value.text_key = "ui.prep.number"
	_shown = count
	_symbol.modulate = ThemeTokens.TINT_NONE if count >= 0 else ThemeTokens.TINT_DEAD


func value() -> int:
	return _shown
