class_name RolePoolView
extends VBoxContainer
## Rollenwahl des Aktes als Kachelraster (DA-91). Kopfzeile: „x / N Rollen gewählt“ groß, daneben die Zähler Dorf, Wölfe, Einzelgänger der
## tatsächlichen Auswahl. Darunter alle Rollen des Aktes als `RoleTile`, nach Team gruppiert. Antippen schaltet an oder aus, Werwolf und
## Die Gebundenen tragen gewählt „×N“ mit − und +, langes Drücken zeigt die Rollenbeschreibung. Darunter „Besonderes“ in einfacher Sprache:
## Der Trugbilderwolf täuscht bei einer Prüfung eine andere Rolle vor (Zeile mit „ändern“) und der Schalter „Totenreichkarten“ (nötig für
## den Kartenschlucker). Reine Darstellung der Sicht `roles`; baut bei jeder Änderung neu auf und gibt den Fokus an dieselbe Kachel zurück.

signal role_toggled(role: StringName)
signal count_step(role: StringName, delta: int)
signal info_requested(role: StringName)
signal decoy_change_requested(copy_id: int)
signal death_cards_toggled(on: bool)

const TEAMS: Array[StringName] = [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]
const TILE_SCALE := 1.05  ## Kachelgröße (Höhe 59): Akt I passt bei 1024x768 ohne Scrollen

var _focus_key: String = ""


func _init() -> void:
	name = "RolePoolView"
	add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)


## `roles`: Sicht von PlayerSetup (counts, limits, decoys, death_cards, act_roles, …), `target`: Zielzahl der Runde,
## `act_has_cards`: Der Akt kennt Rollen mit Totenreichkarten.
func show_roles(roles: Dictionary, target: int, act_has_cards: bool) -> void:
	_remember_focus()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var counts: Dictionary = roles["counts"]
	var in_act: Array = roles["act_roles"]
	var cards_on := bool(roles.get("death_cards", false))
	var team_totals := {String(Faction.VILLAGE): 0, String(Faction.WOLVES): 0, String(Faction.SOLO): 0}
	var total := 0
	for key: Variant in counts:
		var n := int(counts[key])
		total += n
		var team := String(SetupRoleCatalog.faction_of(StringName(str(key))))
		team_totals[team] = int(team_totals.get(team, 0)) + n
	add_child(_head(total, target, team_totals))
	for team: StringName in TEAMS:
		var group := _team_group(team, counts, roles, in_act, cards_on)
		if group != null:
			add_child(group)
	var decoys: Array = roles.get("decoys", [])
	if not decoys.is_empty() or act_has_cards or cards_on:
		add_child(_specials(decoys, cards_on))
	_restore_focus.call_deferred()


func _head(total: int, target: int, team_totals: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "CountHead"
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_L)
	var title := GrimmLabel.new()
	title.name = "SelectedCount"
	title.theme_type_variation = &"HainHeadingLabel"
	title.wrap = false
	title.format_values = {"count": total, "total": target}
	title.text_key = "ui.prep.roles.selected"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	for team: StringName in TEAMS:
		var counter := TeamCounter.new()
		counter.setup(team)
		counter.show_count(int(team_totals.get(String(team), 0)))
		row.add_child(counter)
	return row


func _team_group(team: StringName, counts: Dictionary, roles: Dictionary, in_act: Array, cards_on: bool) -> Control:
	var group := VBoxContainer.new()
	group.name = "Team_%s" % String(team)
	group.add_theme_constant_override(&"separation", ThemeTokens.SPACE_XS)
	var tiles := HFlowContainer.new()
	tiles.name = "Tiles"
	tiles.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_S)
	tiles.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_S)
	for role: StringName in RolePresentation.sorted_roles():
		if SetupRoleCatalog.faction_of(role) != team or not in_act.has(String(role)):
			continue
		var count := int(counts.get(String(role), 0))
		var unlimited := RoleCatalog.max_copies(role) == RoleCatalog.UNLIMITED
		var tile := RoleTile.new()
		tile.set_scale_factor(TILE_SCALE)
		tile.show_tile(role, count, unlimited, cards_on or not RoleCatalog.requires_cards(role))
		tile.toggled_role.connect(func(r: StringName) -> void: role_toggled.emit(r))
		tile.count_step.connect(func(r: StringName, delta: int) -> void: count_step.emit(r, delta))
		tile.info_requested.connect(func(r: StringName) -> void: info_requested.emit(r))
		tiles.add_child(tile)
	if tiles.get_child_count() == 0:
		group.queue_free()
		return null
	var title := GrimmLabel.new()
	title.name = "TeamTitle"
	title.theme_type_variation = &"HainCaptionLabel"
	title.wrap = false
	title.text_key = "ui.prep.team.%s" % String(team)
	group.add_child(title)
	group.add_child(tiles)
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
