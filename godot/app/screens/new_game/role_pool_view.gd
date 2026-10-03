class_name RolePoolView
extends VBoxContainer
## Rollenübersicht des Vorschlags, nach Team gruppiert (Dorf, Wölfe, Einzelgänger): je Team Überschrift mit Teamsymbol und Zahl, darunter
## die Rollenmarken und eine Marke „Rolle hinzufügen“. Antippen einer Rolle meldet `role_pressed`, einer Plus-Marke `add_pressed`.
## Darunter „Besonderes“ in einfacher Sprache: Der Trugbilderwolf täuscht bei einer Prüfung eine andere Rolle vor (Zeile mit „ändern“), und
## der Schalter „Totenreichkarten“ (nötig für den Kartenschlucker). Reine Darstellung der Sicht `roles`; baut bei jeder Änderung neu auf
## und gibt den Fokus an dieselbe Rolle zurück.

signal role_pressed(role: StringName)
signal add_pressed(team: StringName)
signal decoy_change_requested(copy_id: int)
signal death_cards_toggled(on: bool)

const TEAMS: Array[StringName] = [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]

var _focus_key: String = ""


func _init() -> void:
	name = "RolePoolView"
	add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)


## `roles`: Sicht von PlayerSetup (counts, decoys, death_cards, act_roles, …). `act_has_cards`: Der Akt kennt Rollen mit Totenreichkarten.
func show_roles(roles: Dictionary, act_has_cards: bool) -> void:
	_remember_focus()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var counts: Dictionary = roles["counts"]
	for team: StringName in TEAMS:
		add_child(_team_group(team, counts))
	var decoys: Array = roles.get("decoys", [])
	var cards_on := bool(roles.get("death_cards", false))
	if not decoys.is_empty() or act_has_cards or cards_on:
		add_child(_specials(decoys, cards_on))
	_restore_focus.call_deferred()


func _team_group(team: StringName, counts: Dictionary) -> Control:
	var group := VBoxContainer.new()
	group.name = "Team_%s" % String(team)
	group.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	var total := 0
	var chips := HFlowContainer.new()
	chips.name = "Chips"
	chips.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_S)
	chips.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_S)
	for role: StringName in RolePresentation.sorted_roles():
		if SetupRoleCatalog.faction_of(role) != team:
			continue
		var count := int(counts.get(String(role), 0))
		if count <= 0:
			continue
		total += count
		var chip := RoleChip.new()
		chip.show_role(role, count)
		chip.pressed.connect(func() -> void: role_pressed.emit(role))
		chips.add_child(chip)
	var add := RoleChip.new()
	add.show_add(team)
	add.pressed.connect(func() -> void: add_pressed.emit(team))
	chips.add_child(add)
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	var symbol := TextureRect.new()
	symbol.name = "TeamSymbol"
	symbol.texture = NightArt.team(team)
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(symbol)
	var title := GrimmLabel.new()
	title.name = "TeamTitle"
	title.theme_type_variation = &"HainSectionLabel"
	title.wrap = false
	title.format_values = {"count": total}
	title.text_key = "ui.prep.roles.team.%s" % String(team)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	group.add_child(head)
	group.add_child(chips)
	return group


func _specials(decoys: Array, cards_on: bool) -> Control:
	var box := VBoxContainer.new()
	box.name = "Specials"
	box.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	var heading := GrimmLabel.new()
	heading.theme_type_variation = &"HainSectionLabel"
	heading.text_key = "ui.prep.roles.special.heading"
	box.add_child(heading)
	for entry: Variant in decoys:
		var decoy: Dictionary = entry
		var row := HBoxContainer.new()
		row.name = "Decoy_%d" % int(decoy["copy_id"])
		row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
		var text := GrimmLabel.new()
		text.name = "DecoyText"
		text.theme_type_variation = &"HainLabel"
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var appearance := str(decoy["appears_as"])
		text.format_values = {"number": decoy["number"], "role": StringName(RolePresentation.name_key(StringName(appearance))) if appearance != "" else &""}
		text.text_key = "ui.prep.roles.decoy.row" if appearance != "" else "ui.prep.roles.decoy.row_open"
		row.add_child(text)
		var change := GrimmButton.new()
		change.name = "DecoyChange"
		change.kind = GrimmButton.Kind.SECONDARY
		change.text_key = "ui.prep.roles.decoy.change"
		var copy_id := int(decoy["copy_id"])
		change.pressed.connect(func() -> void: decoy_change_requested.emit(copy_id))
		row.add_child(change)
		box.add_child(row)
	var cards_row := HBoxContainer.new()
	cards_row.name = "CardsRow"
	cards_row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	var cards_text := GrimmLabel.new()
	cards_text.theme_type_variation = &"HainLabel"
	cards_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cards_text.text_key = "ui.prep.roles.cards.hint"
	cards_row.add_child(cards_text)
	var cards := ChoiceButton.new()
	cards.name = "DeathCardsToggle"
	cards.text_key = "ui.prep.roles.cards"
	cards.custom_minimum_size.x = 280.0
	cards.set_pressed_no_signal(cards_on)
	cards.toggled.connect(func(on: bool) -> void: death_cards_toggled.emit(on))
	cards_row.add_child(cards)
	box.add_child(cards_row)
	return box


func _remember_focus() -> void:
	_focus_key = ""
	var owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if owner != null and is_ancestor_of(owner):
		_focus_key = String(owner.name)


func _restore_focus() -> void:
	if _focus_key == "" or not is_inside_tree():
		return
	var target := find_child(_focus_key, true, false) as Control
	if target != null and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus()
