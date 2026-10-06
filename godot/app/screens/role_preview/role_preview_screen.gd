class_name RolePreviewScreen
extends BaseScreen
## Rollen-Vorschau (Einstellungen > „Rollen-Vorschau“, Feedback 7): Liste aller Rollen nach Team; ein Tippen baut mit `RolePreview` eine
## Wegwerf-Partie und zeigt nacheinander die echten Bildschirme der Spielleitung (das echte Cockpit in einer eigenen Sitzung). Unten eine
## Leiste, klar als Vorschau markiert: Davor, Danach, Rolle davor/danach, Name und „Bildschirm n von m“, „Sonderfall“ bei Rollen mit
## Warnungen. Nichts wird gespeichert: die Vorschau-Sitzung hat kein automatisches Speichern und keine Historie mit Pfad; echte Spielstände
## und die laufende Partie bleiben unberührt.

const ROW_INSET_RIGHT := 36.0  ## rechts weiter, die Dornen reichen dort tiefer in den Knopf
const ROW_MIN_FONT := 14  ## kleinste Schrift der Rollennamen
const ROW_WRAP_BELOW := 19  ## Einzeiler kleiner als das: zweizeilig setzen
const ROW_TWO_LINE_FONT := 16  ## größte Schrift bei zwei Zeilen (passt mit vollem Zeilenabstand in ROW_MIN)
const ROW_MAX_FONT := 20  ## größte Schrift eines Einzeilers
const BAR_INSET := 20.0  ## Abstand der Knopfreihe zu den Rahmenspitzen der Steuerleiste
const COLUMNS := 4  ## Spalten je Team-Seite in der Rollenliste
const ROW_MIN := 52.0  ## Zeilenhöhe: Daumengröße (ThemeTokens.TOUCH_MIN)
const ROW_INSET := 26.0  ## Abstand von den Dornen-Enden des Knopfes bis zu Symbol und Name
const ICON_SIZE := 32.0

@onready var _layout: Control = %Layout
@onready var _stage_column: VBoxContainer = %StageColumn
@onready var _list: VBoxContainer = %RoleList
@onready var _stage: Control = %Stage

var _roles: Array[StringName] = []
var _pages: Dictionary = {}  ## Team → Seite der Rollenliste
var _page_labels: Dictionary = {}  ## Team → Namensschilder der Seite (eine gemeinsame Schriftgröße)
var _page_fit: Dictionary = {}  ## Team → Breitensumme beim letzten Einpassen
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
	_stage.clip_contents = true  # das Cockpit bekommt genau die Bildschirmbreite


## Zurück: offene Vorschau schließt zur Liste, sonst zu den Einstellungen.
func handle_back() -> bool:
	if _index != -1:
		close_preview()
		return true
	return false


## Rollenliste ohne Scrollen: drei Reiter (Dorf, Wölfe, Einzelsieg), jede Seite zeigt nur ihr Team, alphabetisch und spaltenweise in
## `COLUMNS` Spalten mit Zeilen von Daumengröße. Das größte Team (Dorf, 39 Rollen) füllt 10 Zeilen und passt auf eine Seite.
func _build_list() -> void:
	_list.add_child(_label("ui.preview.hint", &"MutedLabel"))
	var tabs := HBoxContainer.new()
	tabs.name = "TeamTabs"
	tabs.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	_list.add_child(tabs)
	var group := ButtonGroup.new()
	for team: StringName in [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]:
		var members: Array[StringName] = []
		for role: StringName in _roles:
			if SetupRoleCatalog.faction_of(role) == team:
				members.append(role)
		members.sort_custom(func(a: StringName, b: StringName) -> bool: return tr(RolePresentation.name_key(a)).naturalnocasecmp_to(tr(RolePresentation.name_key(b))) < 0)
		var rows := ceili(float(members.size()) / float(COLUMNS))
		var page := HBoxContainer.new()
		page.name = "Team_%s" % String(team)
		page.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
		page.visible = team == Faction.VILLAGE
		_list.add_child(page)
		_pages[team] = page
		var column_boxes: Array[VBoxContainer] = []
		for c: int in COLUMNS:
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			box.add_theme_constant_override(&"separation", 0)
			page.add_child(box)
			column_boxes.append(box)
		for n: int in members.size():
			column_boxes[n / rows].add_child(_role_button(members[n]))
		var tab := GrimmButton.new()
		tab.name = "PreviewTab_%s" % String(team)
		tab.kind = GrimmButton.Kind.COMPACT
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = team == Faction.VILLAGE
		tab.wrap = false
		tab.text_key = RolePresentation.faction_key(team)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.toggled.connect(func(on: bool) -> void: (_pages[team] as Control).visible = on)
		tabs.add_child(tab)


## Eine Zeile der Rollenliste: gemalter Knopf (ohne eigenen Text), darüber Symbol und Name.
func _role_button(role: StringName) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = "PreviewRole_%s" % String(role)
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = false
	b.custom_minimum_size = Vector2(0.0, ROW_MIN)
	var gap := str((_plans[role] as Dictionary)["gap"])
	if gap != "":
		b.tooltip_text = tr("ui.preview.gap.%s" % gap)
	b.pressed.connect(open_role.bind(_roles.find(role)))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.clip_contents = true
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = ROW_INSET
	row.offset_right = -ROW_INSET_RIGHT
	row.offset_top = 1.0
	row.offset_bottom = -1.0
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	b.add_child(row)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = NightArt.role_symbol(String(role))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, 0.0)
	row.add_child(icon)
	var label := GrimmLabel.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_key = RolePresentation.name_key(role)
	label.wrap = false
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var team := SetupRoleCatalog.faction_of(role)
	label.add_theme_color_override(&"font_color", ThemeTokens.team_read_color(team))
	(_page_labels.get_or_add(team, []) as Array).append(label)
	label.resized.connect(_fit_page.bind(team))
	row.add_child(label)
	return b


## Namen einer Teamseite: eine Schriftgröße für die ganze Seite (die kleinste, die der längste Name braucht), damit lange Namen nicht
## einzeln kleiner wirken. Jeder Name steht einzeilig; passt der Einzeiler nicht in Listengröße, bei Leerzeichen lieber zweizeilig
## (Zeilen in etwa gleich lang) als deutlich kleiner, sonst nur kleiner bis `ROW_MIN_FONT`.
func _fit_page(team: StringName) -> void:
	var labels: Array = _page_labels.get(team, [])
	var signature := 0.0
	for label: GrimmLabel in labels:
		if label.size.x <= 0.0:
			return
		signature += label.size.x
	if _page_fit.has(team) and is_equal_approx(float(_page_fit[team]), signature):
		return
	_page_fit[team] = signature
	var sizes: Array[int] = []
	var texts: Array[String] = []
	for label: GrimmLabel in labels:
		var fitted := _fit_role_name(label)
		texts.append(str(fitted["text"]))
		sizes.append(int(fitted["size"]))
	var page_size: int = sizes.min()
	for i: int in labels.size():
		var label: GrimmLabel = labels[i]
		label.text = texts[i]
		label.add_theme_font_size_override(&"font_size", page_size)
		label.add_theme_constant_override(&"line_spacing", 0)  # voller Zeilenabstand: Umlaute in zwei Zeilen werden nicht beschnitten


## Text und größte passende Schrift eines einzelnen Namens bei der Breite seiner Zeile.
func _fit_role_name(label: GrimmLabel) -> Dictionary:
	var full := tr(label.text_key)
	var width := label.size.x
	var font := label.get_theme_font(&"font")
	var one := FitLabel.best_size(font, full, Vector2(width, 0.0), ROW_MAX_FONT, ROW_MIN_FONT, false)
	var text := full
	var chosen := one
	if one < ROW_WRAP_BELOW and full.contains(" "):
		var best := ""
		var best_diff := INF
		for i: int in full.length():
			if full[i] == " ":
				var diff := absf(font.get_string_size(full.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x - font.get_string_size(full.substr(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
				if diff < best_diff:
					best_diff = diff
					best = full.substr(0, i) + "\n" + full.substr(i + 1)
		var longest := ""
		for line: String in best.split("\n"):
			if line.length() > longest.length():
				longest = line
		var two := FitLabel.best_size(font, longest, Vector2(width, 0.0), ROW_TWO_LINE_FONT, ROW_MIN_FONT, false)
		if two > one:
			text = best
			chosen = two
	return {"text": text, "size": chosen}


## Steuerleiste der Vorschau (unten, unter dem Cockpit, nimmt ihm genau ihre Höhe): Vorschau-Zeichen, Rolle davor, Schritt davor,
## Name und Position, Schritt danach, Rolle danach, Sonderfall, Liste.
func _build_bar() -> void:
	_stage_column.add_theme_constant_override(&"separation", 0)
	_bar = PanelContainer.new()
	_bar.name = "PreviewBar"
	_bar.theme_type_variation = &"BarPanel"
	_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	_stage_column.add_child(_bar)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	_bar.add_child(column)
	# Kopfzeile: Vorschau-Zeichen links (mit Abstand zum Rand), Rolle und Bildschirm daneben; die Knöpfe darunter müssen in 1024 px passen.
	var top := Control.new()  # Abstand zur oberen Zierleiste der Leiste
	top.custom_minimum_size.y = ThemeTokens.SPACE_S
	column.add_child(top)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(head)
	var tag := _label("ui.preview.tag", &"HainCaptionLabel")
	tag.name = "PreviewTag"
	tag.wrap = false  # einzeilig: sonst bricht der Text Zeichen für Zeichen um und die Leiste wird hoch
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin := Control.new()
	margin.custom_minimum_size.x = ThemeTokens.SPACE_M
	head.add_child(margin)
	head.add_child(tag)
	_position = _label("", &"")
	_position.name = "PreviewPosition"
	_position.wrap = false
	_position.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_position.clip_text = true
	_position.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_position.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_position.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_position)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(row)
	var lead := Control.new()  # Abstand zur Rahmenspitze der Leiste, damit der erste Knopf sie nicht überlagert
	lead.custom_minimum_size.x = BAR_INSET
	row.add_child(lead)
	row.add_child(_bar_button("PreviewPrevRole", "ui.preview.prev_role", _step_role.bind(-1), "◀"))
	row.add_child(_bar_button("PreviewBack", "ui.preview.back", _step_stop.bind(-1)))
	var gap := Control.new()  # schiebt „Danach“ und die rechten Knöpfe nach rechts
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	row.add_child(_bar_button("PreviewNext", "ui.preview.next", _step_stop.bind(1)))
	row.add_child(_bar_button("PreviewNextRole", "ui.preview.next_role", _step_role.bind(1), "▶"))
	_special_button = _bar_button("PreviewSpecial", "ui.preview.special", _toggle_special)
	_special_button.toggle_mode = true
	row.add_child(_special_button)
	row.add_child(_bar_button("PreviewList", "ui.preview.list", close_preview))
	var trail := Control.new()
	trail.custom_minimum_size.x = BAR_INSET
	row.add_child(trail)


## Mit `symbol` zeigt der Knopf nur das Zeichen (spart Breite, die Leiste muss in 1024 px passen); der Text steht dann im Tooltip.
func _bar_button(node_name: String, key: String, action: Callable, symbol: String = "") -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = false
	if symbol == "":
		b.text_key = key
	else:
		b.text = symbol
		b.tooltip_text = tr(key)
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
	_position.text = _position.text.replace("
", " · ")  # eine Zeile in der Kopfzeile der Leiste
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
