class_name TargetSlot
extends HBoxContainer
## Zielplatz der Aktionskarte (Variante A, P3): zeigt die gewählte Person als Porträt mit Namen, Pfeile wechseln zur vorherigen oder
## nächsten wählbaren Person. Reine Darstellung: Der Wechsel wird als `stepped(direction)` gemeldet, die Ansicht wählt über denselben Weg
## wie das Antippen eines Platzes (die Regelprüfung bleibt beim Regelkern). Bei mehreren erlaubten Zielen ohne Pfeile (Mehrfachwahl) steht nur
## die Liste der Namen. Namen und Beschriftungen immer aus Daten und Übersetzung, nie aus Bildern.

signal stepped(direction: int)

const PORTRAIT := 40.0

var _left: TextureButton
var _right: TextureButton
var _face: TextureRect
var _name: FitLabel


func _init() -> void:
	name = "TargetSlot"
	add_theme_constant_override("separation", ThemeTokens.SPACE_S)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_left = _arrow("TargetPrevButton", "arrow_left", -1)
	_face = TextureRect.new()
	_face.name = "TargetFace"
	_face.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_face)
	_name = FitLabel.new()
	_name.name = "TargetNameLabel"
	_name.min_font_size = 14
	_name.max_font_size = ThemeTokens.FONT_SUBTITLE  # fest, siehe ActionCard.FIT_MAX
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.theme_type_variation = &"SectionLabel"
	add_child(_name)
	_right = _arrow("TargetNextButton", "arrow_right", 1)


func _arrow(node_name: String, art: String, direction: int) -> TextureButton:
	var b := TextureButton.new()
	b.name = node_name
	b.texture_normal = GroveSkin.texture(art)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void: stepped.emit(direction))
	add_child(b)
	return b


## `selected`: gewählte Person als {person_id, seat, name} oder leer; `names`: Text bei Mehrfachwahl (leer = Einzelwahl);
## `can_step`: Pfeile anzeigen (Einzelwahl mit mindestens zwei wählbaren Personen); `label_key`: Beschriftung mit `{name}`
## („Opfer: Anna“, „Ziel: Anna“). Der Name steht mittig, nie mit Sitzplatznummer.
func show_selection(selected: Dictionary, names: String, can_step: bool, label_key: String = "ui.cockpit.card.target.named") -> void:
	_left.visible = can_step
	_right.visible = can_step
	if names != "":
		_face.visible = false
		_name.format_values = {"name": names}
		_name.text_key = "ui.cockpit.card.target.plain"
		return
	_face.visible = not selected.is_empty()
	if selected.is_empty():
		_name.text_key = "ui.cockpit.card.target.none"
		return
	_face.texture = NightArt.portrait(int(selected["person_id"]))
	_name.format_values = {"name": str(selected["name"])}
	_name.text_key = label_key
