class_name RolePreviewScreen
extends BaseScreen
## Rollen-Vorschau (Einstellungen > „Rollen-Vorschau“, Feedback 7): Liste aller Rollen nach Team; ein Tippen baut mit `RolePreview` eine
## Wegwerf-Partie und zeigt nacheinander die echten Bildschirme der Spielleitung (das echte Cockpit in einer eigenen Sitzung). Unten eine
## Leiste, klar als Vorschau markiert: Davor, Danach, Rolle davor/danach, Name und „Bildschirm n von m“, „Sonderfall“ bei Rollen mit
## Warnungen. Nichts wird gespeichert: die Vorschau-Sitzung hat kein automatisches Speichern und keine Historie mit Pfad; echte Spielstände
## und die laufende Partie bleiben unberührt.

const COLUMNS := 5  ## Spalten je Team in der Rollenliste
const ROW_MIN := 30.0  ## Mindesthöhe einer Listenzeile; darunter passt die Liste nicht mehr ohne Scrollen auf 1024x768
const ROW_INSET := 20.0  ## Abstand von den Dornen-Enden des Knopfes bis zu Symbol und Name
const ICON_SIZE := 24.0

@onready var _layout: Control = %Layout
@onready var _stage_column: VBoxContainer = %StageColumn
@onready var _list: VBoxContainer = %RoleList
@onready var _stage: Control = %Stage

var _roles: Array[StringName] = []
var _plans: Dictionary = {}  ## Rolle → Plan (Haltepunkte, Lücke), beim Öffnen der Liste einmal berechnet
var _index: int = -1  ## Rolle der laufenden Vorschau
var _stop: int = 0
var _special: bool = false
var _ctx: AppContext = null
var _cockpit: BaseScreen = null
var _bar: PanelContainer = null
var _position: GrimmLabel = null
var _special_button: GrimmButton = null


func _setup() -> void:
	for role: StringName in RolePresentation.sorted_roles():
		_roles.append(role)
		_plans[role] = RolePreview.plan(String(role))
	_build_list()
	_build_bar()
	_stage.visible = false


## Zurück: offene Vorschau schließt zur Liste, sonst zu den Einstellungen.
func handle_back() -> bool:
	if _index != -1:
		close_preview()
		return true
	return false


## Rollenliste ohne Scrollen: je Team ein Abschnitt, die Rollen alphabetisch spaltenweise in `COLUMNS` Spalten. Die Abschnitte teilen die
## Höhe nach ihrer Zeilenzahl; jede Zeile ist ein gemalter Knopf mit Symbol und Namen, der Name passt sich seinem Platz an.
func _build_list() -> void:
	_list.add_child(_label("ui.preview.hint", &"MutedLabel"))
	for team: StringName in [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]:
		var members: Array[StringName] = []
		for role: StringName in _roles:
			if SetupRoleCatalog.faction_of(role) == team:
				members.append(role)
		members.sort_custom(func(a: StringName, b: StringName) -> bool: return tr(RolePresentation.name_key(a)).naturalnocasecmp_to(tr(RolePresentation.name_key(b))) < 0)
		var rows := ceili(float(members.size()) / float(COLUMNS))
		var section := VBoxContainer.new()
		section.name = "Team_%s" % String(team)
		section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		section.size_flags_stretch_ratio = float(rows)
		section.add_theme_constant_override(&"separation", 0)
		_list.add_child(section)
		section.add_child(_label(RolePresentation.faction_key(team), &"SectionLabel"))
		var columns := HBoxContainer.new()
		columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
		columns.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
		section.add_child(columns)
		var column_boxes: Array[VBoxContainer] = []
		for c: int in COLUMNS:
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override(&"separation", 0)
			columns.add_child(box)
			column_boxes.append(box)
		for n: int in members.size():
			column_boxes[n / rows].add_child(_role_button(members[n]))


## Eine Zeile der Rollenliste: gemalter Knopf (ohne eigenen Text), darüber Symbol und Name.
func _role_button(role: StringName) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = "PreviewRole_%s" % String(role)
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = false
	b.custom_minimum_size = Vector2(0.0, ROW_MIN)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var gap := str((_plans[role] as Dictionary)["gap"])
	if gap != "":
		b.tooltip_text = tr("ui.preview.gap.%s" % gap)
	b.pressed.connect(open_role.bind(_roles.find(role)))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = ROW_INSET
	row.offset_right = -ROW_INSET
	row.offset_top = 2.0
	row.offset_bottom = -2.0
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	b.add_child(row)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = NightArt.role_symbol(String(role))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, 0.0)
	row.add_child(icon)
	var label := FitLabel.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_key = RolePresentation.name_key(role)
	label.max_font_size = ThemeTokens.FONT_COMPACT
	label.min_font_size = 11
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return b


## Steuerleiste der Vorschau (unten, unter dem Cockpit, nimmt ihm genau ihre Höhe): Vorschau-Zeichen, Rolle davor, Schritt davor,
## Name und Position, Schritt danach, Rolle danach, Sonderfall, Liste.
func _build_bar() -> void:
	_stage_column.add_theme_constant_override(&"separation", 0)
	_bar = PanelContainer.new()
	_bar.name = "PreviewBar"
	_bar.theme_type_variation = &"BarPanel"
	_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	_stage_column.add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_bar.add_child(row)
	var tag := _label("ui.preview.tag", &"HainCaptionLabel")
	tag.name = "PreviewTag"
	tag.wrap = false  # einzeilig: sonst bricht der Text Zeichen für Zeichen um und die Leiste wird hoch
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var margin := Control.new()  # Abstand zum Leistenrand, sonst klebt das Zeichen an der Dornenkante
	margin.custom_minimum_size.x = ThemeTokens.SPACE_M
	row.add_child(margin)
	row.add_child(tag)
	for spec: Array in [["PreviewPrevRole", "ui.preview.prev_role", _step_role.bind(-1)], ["PreviewBack", "ui.preview.back", _step_stop.bind(-1)]]:
		row.add_child(_bar_button(spec[0], spec[1], spec[2]))
	_position = _label("", &"")
	_position.name = "PreviewPosition"
	_position.wrap = false
	_position.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_position.clip_text = true
	_position.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_position.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_position.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_position)
	row.add_child(_bar_button("PreviewNext", "ui.preview.next", _step_stop.bind(1)))
	row.add_child(_bar_button("PreviewNextRole", "ui.preview.next_role", _step_role.bind(1)))
	_special_button = _bar_button("PreviewSpecial", "ui.preview.special", _toggle_special)
	_special_button.toggle_mode = true
	row.add_child(_special_button)
	row.add_child(_bar_button("PreviewList", "ui.preview.list", close_preview))


func _bar_button(node_name: String, key: String, action: Callable) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = false
	b.text_key = key
	b.custom_minimum_size = Vector2(0.0, ThemeTokens.TOUCH_MIN)
	b.pressed.connect(action)
	return b


func _label(key: String, variation: StringName) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.theme_type_variation = variation
	label.text_key = key
	return label


## Öffnet die Vorschau der Rolle `index` beim ersten Bildschirm.
func open_role(index: int) -> void:
	_index = index
	_stop = 0
	_special = false
	_layout.visible = false
	_stage.visible = true
	_show_stop()


func close_preview() -> void:
	_drop_cockpit()
	_index = -1
	_stage.visible = false
	_layout.visible = true


func current_role() -> String:
	return String(_roles[_index]) if _index != -1 else ""


func stop_count() -> int:
	return (_plan()["stops"] as Array).size() if _index != -1 else 0


func cockpit() -> BaseScreen:
	return _cockpit


func _plan() -> Dictionary:
	return _plans[_roles[_index]]


func _step_stop(direction: int) -> void:
	if _index == -1:
		return
	_stop = clampi(_stop + direction, 0, maxi(stop_count() - 1, 0))
	_show_stop()


func _step_role(direction: int) -> void:
	if _index == -1:
		return
	open_role(posmod(_index + direction, _roles.size()))


## Sonderfall: springt zum ersten Nachtbildschirm der Rolle und löst ihre Warnung im Zustand der Vorschau aus (erneut tippen: aus).
func _toggle_special() -> void:
	if _index == -1:
		return
	_special = not _special
	if _special:
		var stops: Array = _plan()["stops"]
		for i: int in stops.size():
			if str((stops[i] as Dictionary)["kind"]) == "night":
				_stop = i
				break
	_show_stop()


## Baut die Vorschau-Sitzung neu aus den Befehlen des Haltepunkts und zeigt das echte Cockpit darüber.
func _show_stop() -> void:
	_drop_cockpit()
	var role := current_role()
	var stops: Array = _plan()["stops"]
	var kinds := NightWarnings.kinds_for_role(role)
	_special_button.visible = not kinds.is_empty()
	_special_button.set_pressed_no_signal(_special)
	_ctx = AppContext.new(context.settings)
	# Nichts speichern: kein automatisches Speichern, Ablage in einem eigenen Ordner, Historie nur im Speicher.
	_ctx.session.events_applied.disconnect(_ctx._on_events_applied)
	_ctx.session.state_replaced.disconnect(_ctx.autosave)
	_ctx.saves.base_dir = "user://preview-scratch"
	var stop: Dictionary = stops[_stop] if not stops.is_empty() else {"kind": "none", "commands": [RolePreview.start_command(role)]}
	for c: Command in stop["commands"]:
		_ctx.session.submit(c)
	if _special and str(stop["kind"]) == "night":
		RolePreview.apply_special(_ctx.session, role)
	_cockpit = (load(ScreenIds.scene_path(ScreenIds.COCKPIT)) as PackedScene).instantiate() as BaseScreen
	_cockpit.setup(_ctx)
	_stage_column.add_child(_cockpit)
	_stage_column.move_child(_cockpit, 0)
	_cockpit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cockpit.navigate_requested.connect(func(_id: StringName) -> void: close_preview.call_deferred())
	_cockpit.back_requested.connect(close_preview, CONNECT_DEFERRED)
	_cockpit.dialog_requested.connect(dialog_requested.emit)
	_cockpit.status_message_requested.connect(status_message_requested.emit)
	_position.format_values = {"role": StringName(RolePresentation.name_key(StringName(role))), "n": mini(_stop + 1, maxi(stops.size(), 1)), "total": maxi(stops.size(), 1)}
	_position.text_key = "ui.preview.position" if not stops.is_empty() else "ui.preview.empty"
	_apply_ui(str(stop["kind"]))


## Bildschirme, die eine Bedienung brauchen: „Karte zeigen“ öffnet das Fenster, die Tageskarte folgt auf den Morgenbericht.
func _apply_ui(kind: String) -> void:
	var press := {"show": "ShowCardButton", "day": "ContinueDayButton"}
	if not press.has(kind):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _cockpit == null:
		return
	var b := _cockpit.find_child(str(press[kind]), true, false) as BaseButton
	if b != null and not b.disabled:
		b.pressed.emit()


func _drop_cockpit() -> void:
	if _cockpit != null and is_instance_valid(_cockpit):
		_stage_column.remove_child(_cockpit)
		_cockpit.queue_free()
	_cockpit = null
	_ctx = null
