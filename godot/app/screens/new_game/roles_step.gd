class_name RolesStep
extends PrepStep
## Schritt 3 „Rollen“: startet leer. Alle Rollen des gewählten Aktes stehen als Kacheln (nach Team gruppiert, Dorf, Wölfe, Einzelgänger); Antippen
## schaltet eine Rolle an oder aus, Werwolf und Die Gebundenen haben einen Zähler, langes Drücken zeigt die Beschreibung (DA-91). „Empfehlung
## übernehmen“ füllt die Auswahl mit dem Vorschlag des Aktes. Hinweise und Warnungen erscheinen erst mit der ersten Rolle. Sonderfälle (der Trugbilderwolf gibt sich
## bei Prüfungen als andere Rolle aus, Totenreichkarten) stehen als Zeile mit „ändern“ in einfacher Sprache. Die Zähler oben zeigen die
## Teams der tatsächlichen Auswahl. Blocker (Start technisch unmöglich) stehen als Satz an der Fußzeile, Warnungen (keine Einzelgängerrolle,
## Hinweise zur Besetzung) als Hinweiszeilen ohne Einfluss auf den Start (DA-89).
## Modus „App verteilt zufällig“: „Spiel starten“ verteilt und öffnet das Nachtbrett.
## Modus „Echte Karten – ich weise zu“: zweite Seite „Zuordnung“ mit dem Sitzring (Platz antippen, dann in der Rollenleiste die Rolle);
## die Plätze zeigen nur „zugeordnet“, nie die Rolle. Start erst, wenn alle zugeordnet sind. Die Wahrheit liegt in PlayerSetup.

signal start_requested

enum Page { POOL, ASSIGN }

const BAR_CHIP_SCALE := 1.6         ## Rollenwahl im Kartenmodus: große Marken

var _page: Page = Page.POOL
var _last_view: Dictionary = {}
var _bar_person: int = 0

var _proposal: GrimmButton
var _tabs: HBoxContainer
var _pool_tab: ChoiceButton
var _assign_tab: ChoiceButton
var _pool_page: ScrollContainer
var _pool_column: VBoxContainer
var _warnings: VBoxContainer
var _pool: RolePoolView
var _assign_page: Control
var _ring: GameSeatRing
var _progress: GrimmLabel
var _assign_hint: GrimmLabel
var _bar: PanelContainer
var _assign_card: PanelContainer
var _bar_title: GrimmLabel
var _bar_chips: HFlowContainer
var _bar_clear: GrimmButton
var _bar_close: GrimmButton
var _bar_scroll: ScrollContainer


func start(setup: PlayerSetup) -> void:
	_setup = setup
	name = "RolesStep"
	_tabs = _tab_row()
	add_child(_header())
	_pool_page = _build_pool_page()
	add_child(_pool_page)
	_assign_page = _build_assign_page()
	add_child(_assign_page)
	HainStyle.apply(self)
	_setup.changed.connect(_render)
	_show_page(Page.POOL)
	_render(_setup.view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _last_view.is_empty():
		_render(_last_view)


func entered() -> void:
	_show_page(Page.POOL)
	_render(_setup.view())


func default_focus() -> Control:
	return _proposal


func is_manual() -> bool:
	return str(_last_view.get("mode", "")) == String(DistributionDraft.MANUAL)


func page() -> Page:
	return _page


func ring() -> GameSeatRing:
	return _ring


func footer() -> Dictionary:
	var blockers: Array = _last_view.get("blockers", [])
	var hint := ""
	var values := {}
	var error := false
	if int(_last_view["roles"]["total"]) == 0:
		hint = "ui.prep.roles.empty_hint"  # Hilfszeile statt Blocker-Satz, solange nichts gewählt ist
	elif not blockers.is_empty():
		hint = _blocker_key(str(blockers[0]))
		values = _blocker_values(str(blockers[0]))
		error = true
	elif is_manual() and _page == Page.ASSIGN and not bool(_last_view.get("can_start", false)):
		var d: Dictionary = _last_view["distribution"]
		hint = "ui.prep.assign.progress"
		values = {"assigned": d["assigned_count"], "total": d["person_count"]}
	if is_manual() and _page == Page.POOL:
		return {"next_key": "ui.prep.next.assign", "next_enabled": blockers.is_empty(), "next_primary": true, "hint_key": hint, "hint_values": values, "hint_error": error}
	return {"next_key": "ui.prep.start", "next_enabled": bool(_last_view.get("can_start", false)), "next_primary": true, "hint_key": hint, "hint_values": values, "hint_error": error}


func activate_next() -> void:
	if is_manual() and _page == Page.POOL:
		if (_last_view.get("blockers", []) as Array).is_empty():
			_show_page(Page.ASSIGN)
			footer_changed.emit()
		return
	if bool(_last_view.get("can_start", false)):
		start_requested.emit()


## Zurück: erst die Rollenleiste, dann die Zuordnungsseite schließen; false = der Host geht zu den Namen.
func handle_back() -> bool:
	if _bar.visible:
		_close_bar()
		return true
	if _page == Page.ASSIGN:
		_show_page(Page.POOL)
		footer_changed.emit()
		return true
	return false


# --- Aufbau ----------------------------------------------------------------------------------------------

func _header() -> Control:
	var row := HBoxContainer.new()
	row.name = "RolesHeader"
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_L)
	row.add_child(_tabs)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_proposal = GrimmButton.new()
	_proposal.name = "ProposalButton"
	_proposal.kind = GrimmButton.Kind.SECONDARY
	_proposal.text_key = "ui.prep.roles.proposal"
	_proposal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_proposal.pressed.connect(func() -> void: _setup.apply_suggestion())
	row.add_child(_proposal)
	return row


func _tab_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "PageTabs"
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	var group := ButtonGroup.new()
	_pool_tab = ChoiceButton.new()
	_pool_tab.name = "PoolTab"
	_pool_tab.button_group = group
	_pool_tab.text_key = "ui.prep.tab.roles"
	_pool_tab.toggled.connect(func(on: bool) -> void:
		if on:
			_show_page(Page.POOL)
			footer_changed.emit())
	row.add_child(_pool_tab)
	_assign_tab = ChoiceButton.new()
	_assign_tab.custom_minimum_size.x = 340.0
	_assign_tab.name = "AssignTab"
	_assign_tab.button_group = group
	_assign_tab.text_key = "ui.prep.tab.assign"
	_assign_tab.toggled.connect(func(on: bool) -> void:
		if on:
			_show_page(Page.ASSIGN)
			footer_changed.emit())
	row.add_child(_assign_tab)
	return row


func _build_pool_page() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "PoolScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	_pool_column = VBoxContainer.new()
	_pool_column.name = "PoolColumn"
	_pool_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	scroll.add_child(_pool_column)
	_warnings = VBoxContainer.new()
	_warnings.name = "Warnings"
	_warnings.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	_pool_column.add_child(_warnings)
	_pool = RolePoolView.new()
	_pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool.role_toggled.connect(_on_role_toggled)
	_pool.count_step.connect(_on_count_step)
	_pool.info_requested.connect(_on_role_info)
	_pool.decoy_change_requested.connect(_on_decoy_change)
	_pool.death_cards_toggled.connect(func(on: bool) -> void: _setup.set_death_cards(on))
	_pool_column.add_child(_pool)
	return scroll


func _build_assign_page() -> Control:
	var page_control := Control.new()
	page_control.name = "AssignPage"
	page_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_control.clip_contents = true
	_ring = GameSeatRing.new()
	_ring.name = "SeatRing"
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := Control.new()
	center.name = "RingCenter"
	_ring.add_child(center)
	center.owner = _ring
	center.unique_name_in_owner = true
	page_control.add_child(_ring)
	_ring.seat_tapped.connect(_on_seat_tapped)
	var card := PanelContainer.new()
	_assign_card = card
	card.name = "AssignCard"
	card.theme_type_variation = &"CardPanel"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	card.add_child(column)
	_progress = GrimmLabel.new()
	_progress.name = "AssignProgress"
	_progress.theme_type_variation = &"HeadingLabel"
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_progress)
	_assign_hint = GrimmLabel.new()
	_assign_hint.name = "AssignHint"
	_assign_hint.theme_type_variation = &"CaptionLabel"
	_assign_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_assign_hint.text_key = "ui.prep.assign.hint"
	column.add_child(_assign_hint)
	center.add_child(card)
	_bar = _build_bar()
	page_control.add_child(_bar)
	return page_control


func _build_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.name = "RoleBar"
	bar.theme_type_variation = &"CardPanel"
	bar.visible = false
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Testrunde 1: das Fenster deckt den Sitzring ganz ab, der Platz ist schon gewählt
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	bar.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	_bar_title = GrimmLabel.new()
	_bar_title.name = "RoleBarTitle"
	_bar_title.theme_type_variation = &"HeadingLabel"
	_bar_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_bar_title)
	_bar_clear = GrimmButton.new()
	_bar_clear.name = "RoleBarClear"
	_bar_clear.kind = GrimmButton.Kind.SECONDARY
	_bar_clear.text_key = "ui.prep.assign.clear"
	_bar_clear.pressed.connect(_on_clear_pressed)
	head.add_child(_bar_clear)
	_bar_close = GrimmButton.new()
	_bar_close.name = "RoleBarClose"
	_bar_close.kind = GrimmButton.Kind.SECONDARY
	_bar_close.text_key = "ui.common.cancel"
	_bar_close.pressed.connect(_close_bar)
	head.add_child(_bar_close)
	column.add_child(head)
	_bar_scroll = ScrollContainer.new()
	_bar_scroll.name = "RoleBarScroll"
	_bar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_bar_scroll.custom_minimum_size.y = ThemeTokens.ROLE_CHIP_HEIGHT * 2 + ThemeTokens.SPACE_S
	_bar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bar_scroll.follow_focus = true
	column.add_child(_bar_scroll)
	_bar_chips = HFlowContainer.new()
	_bar_chips.name = "RoleBarChips"
	_bar_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_chips.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_S)
	_bar_chips.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_S)
	_bar_scroll.add_child(_bar_chips)
	return bar


# --- Darstellung ------------------------------------------------------------------------------------------

func _render(view: Dictionary) -> void:
	_last_view = view
	var roles: Dictionary = view["roles"]
	var manual := is_manual()
	_tabs.visible = manual
	if not manual and _page == Page.ASSIGN:
		_show_page(Page.POOL)
	var d: Dictionary = view["distribution"]
	_assign_tab.format_values = {"assigned": d["assigned_count"], "total": d["person_count"]}
	_assign_tab.text_key = "ui.prep.tab.assign"
	_assign_tab.disabled = not (view["blockers"] as Array).is_empty()
	if not (view["blockers"] as Array).is_empty() and _page == Page.ASSIGN:
		_show_page(Page.POOL)
	_pool.show_roles(roles, int(view["player_count"]), _act_has_cards(str(view["act"])))
	_render_warnings(view)
	_render_assign(view)
	footer_changed.emit()


func _act_has_cards(act: String) -> bool:
	for role: StringName in ActCatalog.roles(StringName(act)):
		if RoleCatalog.requires_cards(role):
			return true
	return false


func _render_warnings(view: Dictionary) -> void:
	for child: Node in _warnings.get_children():
		_warnings.remove_child(child)
		child.queue_free()
	var warnings: Array = view["warnings"] if int(view["roles"]["total"]) > 0 else []  # erst mit der ersten Rolle
	for code: Variant in warnings:
		var key := _warning_key(str(code))
		if key == "":
			continue
		var label := GrimmLabel.new()
		label.name = "Warning_%s" % str(code)
		label.theme_type_variation = &"HainLabel"
		label.text_key = key
		_warnings.add_child(label)
	_warnings.visible = _warnings.get_child_count() > 0


func _warning_key(code: String) -> String:
	if code == String(RolePoolDraft.WARNING_MISSING_SOLO):
		return "ui.prep.roles.warning.missing_solo"
	return "ui.setup.roles.hint.%s" % code


func _render_assign(view: Dictionary) -> void:
	var d: Dictionary = view["distribution"]
	var seats: Array = []
	var ids: Array = []
	var assigned: Array = []
	for entry: Variant in d["assignment"]:
		var person: Dictionary = entry
		seats.append({"person_id": person["person_id"], "seat": person["number"], "name": person["name"], "alive": true})
		ids.append(int(person["person_id"]))
		if bool(person["assigned"]):
			assigned.append(int(person["person_id"]))
	_ring.show_seats(seats)
	_ring.set_marking(true, ids, assigned, [])
	_progress.format_values = {"assigned": d["assigned_count"], "total": d["person_count"]}
	_progress.text_key = "ui.prep.assign.progress"
	if _bar.visible:
		_render_bar(view)


func _show_page(page_id: Page) -> void:
	_page = page_id
	_pool_page.visible = page_id == Page.POOL
	_assign_page.visible = page_id == Page.ASSIGN
	if page_id == Page.POOL:
		_close_bar()
	if _pool_tab != null and is_manual():
		(_pool_tab if page_id == Page.POOL else _assign_tab).set_pressed_no_signal(true)
		(_assign_tab if page_id == Page.POOL else _pool_tab).set_pressed_no_signal(false)


# --- Rollenaktionen ---------------------------------------------------------------------------------------

## Kachel angetippen: gewählte Rolle ganz abwählen (alle Kopien, ausdrücklich ohne Rückfrage), sonst eine Kopie wählen.
func _on_role_toggled(role: StringName) -> void:
	var count := int(_last_view["roles"]["counts"][String(role)])
	if count <= 0:
		_setup.add_role(role)
		return
	for i: int in count:
		_setup.remove_role(role)


## − oder + an einer Kachel mit Zähler; − bei einer Kopie wählt die Rolle ab.
func _on_count_step(role: StringName, delta: int) -> void:
	if delta > 0:
		_setup.add_role(role)
	else:
		_setup.remove_role(role)


## Langes Drücken: Rollenbeschreibung, dazu der Weg ins Lexikon.
func _on_role_info(role: StringName) -> void:
	var request := DialogRequest.create("ui.prep.roles.info.title", RolePresentation.short_key(role), "")
	request.title_values = {"role": StringName(RolePresentation.name_key(role))}
	request.options.append(DialogOption.create("RoleInfo", "ui.prep.roles.menu.info", {}, func() -> void: lexicon_requested.emit(role)))
	dialog_requested.emit(request)


func _on_decoy_change(copy_id: int) -> void:
	var roles: Dictionary = _last_view["roles"]
	var current := ""
	var number := 1
	for entry: Variant in roles["decoys"]:
		if int((entry as Dictionary)["copy_id"]) == copy_id:
			current = str((entry as Dictionary)["appears_as"])
			number = int((entry as Dictionary)["number"])
	var request := DialogRequest.create("ui.prep.decoy.title", "ui.prep.decoy.message", "")
	request.message_values = {"number": number}
	var options: Array = roles["appearance_options"]
	for role: StringName in RolePresentation.sorted_roles():
		if not options.has(String(role)):
			continue
		var is_current := String(role) == current
		var key := "ui.prep.decoy.current" if is_current else RolePresentation.name_key(role)
		var values := {"name": StringName(RolePresentation.name_key(role))} if is_current else {}
		request.options.append(DialogOption.create("Decoy_%s" % String(role).replace("-", "_"), key, values, func() -> void: _setup.set_decoy_appearance(copy_id, role)))
	dialog_requested.emit(request)


# --- Zuordnung (Echte Karten) -----------------------------------------------------------------------------

func _on_seat_tapped(person_id: int) -> void:
	_bar_person = person_id
	_bar.visible = true
	_ring.visible = false  # das Fenster ersetzt den Sitzring, der Platz ist schon gewählt
	_ring.set_chosen(person_id)
	_assign_card.visible = false
	_render_bar(_last_view)
	if _bar_chips.get_child_count() > 0:
		(_bar_chips.get_child(0) as Control).grab_focus(true)


func _render_bar(view: Dictionary) -> void:
	var d: Dictionary = view["distribution"]
	var person := {}
	for entry: Variant in d["assignment"]:
		if int((entry as Dictionary)["person_id"]) == _bar_person:
			person = entry
	if person.is_empty():
		_close_bar()
		return
	_bar_title.format_values = {"number": person["number"], "name": person["name"]}
	_bar_title.text_key = "ui.prep.assign.bar"
	_bar_clear.visible = bool(person["assigned"])
	for child: Node in _bar_chips.get_children():
		_bar_chips.remove_child(child)
		child.queue_free()
	for unit: Variant in d["remaining_units"]:
		var u: Dictionary = unit
		var chip := RoleChip.new()
		chip.team_tint = true
		chip.show_role(StringName(str(u["role_id"])), int(u["left"]))
		chip.set_scale_factor(BAR_CHIP_SCALE)
		chip.name = "Unit_%s" % str(u["unit"]).replace("-", "_").replace("#", "_")
		var key := StringName(str(u["unit"]))
		chip.pressed.connect(func() -> void: _assign(key))
		_bar_chips.add_child(chip)
	HainStyle.apply(_bar)


func _assign(unit: StringName) -> void:
	var person := _bar_person
	var result := _setup.assign_role(person, unit)
	if result.ok:
		_close_bar()


func _on_clear_pressed() -> void:
	var person := _bar_person
	if _setup.unassign_role(person).ok:
		_close_bar()


func _close_bar() -> void:
	if _bar == null:
		return
	_bar.visible = false
	_bar_person = 0
	_ring.visible = true
	_ring.set_chosen(0)
	_assign_card.visible = true


func bar_visible() -> bool:
	return _bar.visible


# --- Blocker in einfacher Sprache -------------------------------------------------------------------------

func _blocker_key(code: String) -> String:
	match code:
		"too_few_persons", "too_many_persons", "names_incomplete":
			return "ui.prep.blocker.names"
		"too_few_roles":
			return "ui.prep.blocker.too_few_roles_one" if int(_last_view.get("roles", {}).get("free", 0)) == 1 else "ui.prep.blocker.too_few_roles"
		"too_many_roles":
			return "ui.prep.blocker.too_many_roles_one" if int(_last_view.get("roles", {}).get("free", 0)) == -1 else "ui.prep.blocker.too_many_roles"
	return "ui.setup.roles.issue.%s" % code


func _blocker_values(code: String) -> Dictionary:
	var roles: Dictionary = _last_view.get("roles", {})
	match code:
		"too_few_roles":
			return {"count": int(roles.get("free", 0))}
		"too_many_roles":
			return {"count": -int(roles.get("free", 0))}
	return {}
