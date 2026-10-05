class_name RolePreviewScreen
extends BaseScreen
## Rollen-Vorschau (Einstellungen > „Rollen-Vorschau“, Feedback 7): Liste aller Rollen nach Team; ein Tippen baut mit `RolePreview` eine
## Wegwerf-Partie und zeigt nacheinander die echten Bildschirme der Spielleitung (das echte Cockpit in einer eigenen Sitzung). Unten eine
## Leiste, klar als Vorschau markiert: Zurück, Weiter, Rolle davor/danach, Name und „Bildschirm n von m“, „Sonderfall“ bei Rollen mit
## Warnungen. Nichts wird gespeichert: die Vorschau-Sitzung hat kein automatisches Speichern und keine Historie mit Pfad; echte Spielstände
## und die laufende Partie bleiben unberührt.

const BAR_HEIGHT := 64.0

@onready var _layout: Control = %Layout
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


func _build_list() -> void:
	_list.add_child(_label("ui.preview.hint", &"MutedLabel"))
	for team: StringName in [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]:
		_list.add_child(_label(RolePresentation.faction_key(team), &"SectionLabel"))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_S)
		flow.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_S)
		_list.add_child(flow)
		for i: int in _roles.size():
			var role := _roles[i]
			if SetupRoleCatalog.faction_of(role) != team:
				continue
			var b := GrimmButton.new()
			b.name = "PreviewRole_%s" % String(role)
			b.kind = GrimmButton.Kind.COMPACT
			b.wrap = false
			b.icon = NightArt.role_symbol(String(role))
			b.expand_icon = true
			b.custom_minimum_size = Vector2(230.0, ThemeTokens.TOUCH_MIN)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var gap := str((_plans[role] as Dictionary)["gap"])
			b.format_values = {"name": StringName(RolePresentation.name_key(role))}
			b.text_key = "ui.preview.role_gap" if gap != "" else "ui.preview.role"
			if gap != "":
				b.tooltip_text = tr("ui.preview.gap.%s" % gap)
			b.pressed.connect(open_role.bind(i))
			flow.add_child(b)


## Steuerleiste der Vorschau (unten): Vorschau-Zeichen, Rolle davor, Zurück, Name und Position, Weiter, Rolle danach, Sonderfall, Liste.
func _build_bar() -> void:
	_bar = PanelContainer.new()
	_bar.name = "PreviewBar"
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokens.BG_APP
	style.border_color = ThemeTokens.BLOOD_RED
	style.border_width_top = 3
	style.content_margin_left = ThemeTokens.SPACE_S
	style.content_margin_right = ThemeTokens.SPACE_S
	style.content_margin_top = ThemeTokens.SPACE_XS
	style.content_margin_bottom = ThemeTokens.SPACE_XS
	_bar.add_theme_stylebox_override("panel", style)
	_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bar.offset_top = -BAR_HEIGHT
	_stage.add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_bar.add_child(row)
	var tag := _label("ui.preview.tag", &"ErrorLabel")
	tag.name = "PreviewTag"
	tag.wrap = false  # einzeilig: sonst bricht der Text Zeichen für Zeichen um und die Leiste wird hoch
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	_stage.add_child(_cockpit)
	_stage.move_child(_cockpit, 0)
	_cockpit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cockpit.offset_bottom = -BAR_HEIGHT
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
		_stage.remove_child(_cockpit)
		_cockpit.queue_free()
	_cockpit = null
	_ctx = null
