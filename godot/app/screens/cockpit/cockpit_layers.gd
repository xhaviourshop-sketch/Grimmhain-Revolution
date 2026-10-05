class_name CockpitLayers
extends RefCounted
## Ebenen über dem Cockpit, jeweils erst beim Öffnen aus aktuellen Daten gebaut und beim Schließen
## wieder entfernt (kein verstecktes Geheimnis im Baum):
##   private_drawer  Rollen je Person (Schublade rechts, klar als „Nur Spielleitung“ markiert)
##   log_drawer      Protokoll aller Ereignisse
##   show_card       Karte für die handelnde Person: nur die Positivliste des Prompts (`show`)
##   cover_panel     Sichtschutz über dem ganzen Cockpit
##   role_list       Rollenanzeige, neutrale Personenliste (nur Namen und Bestätigungsstand, nie Rollen)
##   role_card       Rollenanzeige, Karte einer Person: neutrale Vorderseite oder (nach bewusster Aktion) Rolle und Kurztext
## Jede Ebene hat einen `CloseLayerButton` (bzw. `UncoverButton`); die Ansicht verbindet ihn.
## Karten- und Ansageebenen (show_card, notice_card, role_card, card_face) sind `DetailPanel`s: der Text scrollt,
## die Buttons stehen in einem festen Bereich darunter.


## `actions`: geheime Tagesaktionen [{action, player_id, name, seat}] als Buttons `SecretAction_*`
## (Metadaten action und player_id); die Ansicht verbindet sie.
## `hints`: Stimmhinweise [{person_id, seat, name, bonus, source_role}] (RM-DR-008) als Zeilen `VoteHint_<id>`.
static func private_drawer(seats: Array, actions: Array = [], hints: Array = []) -> Control:
	var drawer := _drawer("PrivateLayer", "ui.cockpit.private.heading")
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
	if not hints.is_empty():
		_label(list, "ui.cockpit.private.vote_hints", {}, &"CaptionLabel")
		for h: Dictionary in hints:
			_label(list, "ui.cockpit.private.vote_hint", {"name": CockpitText.person(h), "bonus": int(h["bonus"]),
				"role": CockpitText.role_name(str(h["source_role"]))}, &"SectionLabel").name = "VoteHint_%d" % int(h["person_id"])
	if not actions.is_empty():
		_label(list, "ui.cockpit.private.actions", {}, &"CaptionLabel")
		for a: Dictionary in actions:
			var b := _button("SecretAction_%s_%d" % [str(a["action"]), int(a["player_id"])], "ui.cockpit.private.action.%s" % str(a["action"]), GrimmButton.Kind.SECONDARY)
			b.format_values = {"name": CockpitText.person(a)}
			b.set_meta("action", str(a["action"]))
			b.set_meta("player_id", int(a["player_id"]))
			list.add_child(b)
	for seat: Dictionary in seats:
		var row := VBoxContainer.new()
		row.name = "PrivateRow_%d" % int(seat["person_id"])
		var values := {"seat": int(seat["seat"]), "name": str(seat["name"]), "role": CockpitText.role_name(str(seat["role_id"])),
			"faction": StringName("ui.faction.%s" % str(seat["faction"]))}
		_label(row, "ui.cockpit.private.row" if bool(seat["alive"]) else "ui.cockpit.private.row_dead", values, &"SectionLabel")
		for note: Dictionary in seat.get("notes", []):
			_label(row, str(note["key"]), {"role": CockpitText.role_name(str(note.get("role_id", "")))}, &"CaptionLabel")
		list.add_child(row)
	return drawer


static func log_drawer(events: Array, seats: Array) -> Control:
	var drawer := _drawer("LogLayer", "ui.cockpit.log.heading")
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
	if events.is_empty():
		_label(list, "ui.cockpit.log.empty", {}, &"MutedLabel")
	var shown := 0
	# Neueste zuerst; ältere Einträge bleiben im Spielstand, die Liste zeigt die letzten 200.
	for i: int in range(events.size() - 1, -1, -1):
		if shown >= 200:
			break
		var e: Dictionary = events[i]
		var row := VBoxContainer.new()
		row.name = "LogRow_%d" % int(e["index"])
		var type := str(e["type"])
		var key := "ui.log.event.%s" % CockpitText.snake(type)
		_label(row, key if CockpitText.has_key(key) else "ui.log.event.generic",
			{"index": int(e["index"]), "type": type, "visibility": StringName("ui.log.visibility.%s" % str(e["visibility"]))}, &"SectionLabel")
		var details := _details(e.get("data", {}), seats)
		if details != "":
			var detail := Label.new()
			detail.add_to_group(&"user_content")
			detail.theme_type_variation = &"CaptionLabel"
			detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail.text = details
			row.add_child(detail)
		list.add_child(row)
		shown += 1
	return drawer


## Karte für die handelnde Person: Rollenname und ausschließlich die freigegebenen Werte. Erhält nur
## diese beiden Angaben, nie den ganzen Prompt (Wahrheit, Teilantworten).
static func show_card(role_id: String, lines: Array) -> Control:
	if lines.is_empty():
		return null
	var layer := _detail_layer("ShowLayer")
	var root: Control = layer[0]
	var panel: DetailPanel = layer[1]
	var column := panel.content
	var title := _label(column, "ui.cockpit.show.heading", {"role": CockpitText.role_name(role_id)}, &"GothicTitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", ThemeTokens.FONT_SHOW_TITLE)
	for line: Dictionary in lines:
		_label(column, CockpitText.info_key(str(line["key"])), {}, &"ShowCaptionLabel").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var value := GrimmLabel.new()
		value.theme_type_variation = &"ShowNumberLabel"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var shown: Variant = CockpitText.info_value(line)
		value.format_values = {"value": shown}
		value.text_key = "ui.cockpit.show.value"
		column.add_child(value)
	panel.actions.add_child(_button("CloseLayerButton", "ui.cockpit.show.close", GrimmButton.Kind.PRIMARY))
	return root


## Hinweiskarte für die betroffene Person bzw. Gruppe (DI-04, DI-06, DI-07): nur der Kartentext mit den Werten,
## die die Betrachter erfahren dürfen (`CockpitView.notice_card`), nie Rollen anderer Personen.
static func notice_card(card: Dictionary) -> Control:
	var layer := _detail_layer("NoticeLayer")
	var root: Control = layer[0]
	var panel: DetailPanel = layer[1]
	var column := panel.content
	_label(column, "ui.cockpit.notice.heading.group" if bool(card.get("group", false)) else "ui.cockpit.notice.heading", {}, &"GothicTitleLabel").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var picture := _bond_picture(str(card["text_key"]))
	if picture != null:
		column.add_child(picture)
	_label(column, str(card["text_key"]), CockpitText.notice_values(card.get("values", {})), &"ShowValueLabel").name = "NoticeText"
	panel.actions.add_child(_button("CloseLayerButton", "ui.cockpit.notice.close", GrimmButton.Kind.PRIMARY))
	return root


## Bild der Loki-Bindung (`assets/ui/bund-liebende.png`, `bund-rivalen.png`), solange das Bild fehlt, bleibt die Karte ohne Bild.
static func _bond_picture(text_key: String) -> TextureRect:
	var file := "bund-liebende" if text_key.ends_with(".love") else "bund-rivalen" if text_key.ends_with(".rival") else ""
	var path := "res://assets/ui/%s.png" % file
	if file == "" or not ResourceLoader.exists(path):
		return null
	var picture := TextureRect.new()
	picture.name = "BondPicture"
	picture.texture = load(path) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0.0, 160.0)
	return picture


## Rollenanzeige, neutrale Liste (`CockpitView.role_show_list`): eine Schaltfläche je Person, die nächste offene Person
## ist hervorgehoben. Enthält keine Rolle.
static func role_list(list: Dictionary) -> Control:
	var root := _full_rect("RoleListLayer")
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ShowPanel"
	panel.custom_minimum_size.x = ThemeTokens.DIALOG_WIDE_WIDTH
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"ScreenColumn"
	panel.add_child(column)
	_label(column, "ui.cockpit.roles.heading", {}, &"HeadingLabel")
	_label(column, "ui.cockpit.roles.hint", {}, &"MutedLabel")
	_label(column, "ui.cockpit.roles.progress", {"done": int(list.get("confirmed_count", 0)), "total": int(list.get("total", 0))}, &"CaptionLabel")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = ThemeTokens.SPACE_M * 20
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var next_id := int(list.get("next_id", -1))
	for entry: Dictionary in list.get("persons", []):
		var id := int(entry["person_id"])
		var is_next := id == next_id
		var key := "ui.cockpit.roles.person_done" if bool(entry["confirmed"]) else ("ui.cockpit.roles.person_next" if is_next else "ui.cockpit.roles.person")
		var b := _button("RolePerson_%d" % id, key, GrimmButton.Kind.PRIMARY if is_next else GrimmButton.Kind.SECONDARY)
		b.format_values = {"seat": int(entry["seat"]), "name": str(entry["name"])}
		b.set_meta("person_id", id)
		if is_next:
			var marker := _label(rows, "ui.cockpit.roles.next_marker", {}, &"CaptionLabel")
			marker.name = "RolePersonNext_%d" % id
		rows.add_child(b)
	column.add_child(_button("CloseLayerButton", "ui.cockpit.roles.done", GrimmButton.Kind.SECONDARY))
	return root


## Rollenanzeige, Karte einer Person. Ohne `role_id` (neutrale Vorderseite) steht nur der Name auf der Karte; mit `role_id`
## (erst nach der bewussten Aktion gebaut) Rolle und Kurztext dieser Person, sonst nichts. Bereits bestätigte Personen
## können nachlesen und schließen ohne Befehl; sonst bestätigt „Gesehen“, „Ohne Bestätigung“ schließt nur.
static func role_card(card: Dictionary, revealed: bool) -> Control:
	var layer := _detail_layer("RoleCardLayer")
	var root: Control = layer[0]
	var panel: DetailPanel = layer[1]
	var column := panel.content
	var values := {"seat": int(card["seat"]), "name": str(card["name"])}
	if not revealed:
		_label(column, "ui.cockpit.roles.front.heading", values, &"HeadingLabel")
		_label(column, "ui.cockpit.roles.front.text", values, &"MutedLabel")
		panel.actions.add_child(_button("RevealRoleButton", "ui.cockpit.roles.reveal", GrimmButton.Kind.PRIMARY))
		panel.actions.add_child(_button("CancelRoleButton", "ui.cockpit.roles.cancel", GrimmButton.Kind.SECONDARY))
		return root
	var role := str(card["role_id"])
	_label(column, "ui.cockpit.roles.card.heading", values, &"HeadingLabel")
	_label(column, "ui.cockpit.roles.role_value", {"role": CockpitText.role_name(role)}, &"ShowValueLabel").name = "RoleName"
	_label(column, RolePresentation.short_key(StringName(role)), {}, &"MutedLabel").name = "RoleShort"
	if bool(card.get("confirmed", false)):
		panel.actions.add_child(_button("CloseRoleButton", "ui.cockpit.roles.close", GrimmButton.Kind.PRIMARY))
	else:
		panel.actions.add_child(_button("ConfirmRoleButton", "ui.cockpit.roles.confirm", GrimmButton.Kind.PRIMARY))
		panel.actions.add_child(_button("CloseWithoutConfirmButton", "ui.cockpit.roles.close_unconfirmed", GrimmButton.Kind.SECONDARY))
	return root


## Karte der toten Person zum Zeigen am Tisch: Name der Besitzerin, Name der Karte und ihr Text (Regeltext der Fraktionsvariante).
static func card_face(card: Dictionary, owner: Dictionary) -> Control:
	if card.is_empty():
		return null
	var layer := _detail_layer("CardLayer")
	var root: Control = layer[0]
	var panel: DetailPanel = layer[1]
	var column := panel.content
	_label(column, "ui.cards.face.heading", {"name": str(owner.get("name", ""))}, &"CaptionLabel")
	_label(column, str(card["name_key"]), {}, &"GothicTitleLabel").name = "CardFaceName"
	var value := _label(column, str(card["text_key"]), {}, &"ShowValueLabel")
	value.name = "CardFaceText"
	panel.actions.add_child(_button("CloseLayerButton", "ui.cockpit.show.close", GrimmButton.Kind.PRIMARY))
	return root


## Überblick aller Karten der Partie (nur Spielleitung): wem gehört welche Karte, welchen Status hat sie; dazu die Zahlen der Kartenschlucker.
static func cards_drawer(cards: Array, swallowers: Array) -> Control:
	var drawer := _drawer("CardsLayer", "ui.cards.overview.heading")
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
	for s: Dictionary in swallowers:
		_label(list, "ui.cards.overview.swallower", {"name": CockpitText.person(s["person"]), "balance": int(s["balance"]), "total": int(s["total"]),
			"shield": StringName("ui.common.yes" if bool(s["shield"]) else "ui.common.no")}, &"SectionLabel").name = "SwallowerRow_%d" % int((s["person"] as Dictionary)["person_id"])
	if cards.is_empty():
		_label(list, "ui.cards.overview.empty", {}, &"MutedLabel")
	for c: Dictionary in cards:
		var row := VBoxContainer.new()
		row.name = "CardRow_%d" % int(c["record_id"])
		_label(row, "ui.cards.overview.row", {"name": CockpitText.person(c["owner"]), "card": StringName(str(c["name_key"])), "status": StringName(str(c["status_key"]))}, &"SectionLabel")
		_label(row, str(c["text_key"]), {}, &"CaptionLabel")
		list.add_child(row)
	return drawer


## Spielleitung: Rückgängig/Wiederholen mit Klartext, Korrekturen, Partie verlassen oder verwerfen,
## Änderungen der letzten Korrektur. `options`: {undo, redo, day (bool), last_change (Ereignisse)}.
static func gm_drawer(options: Dictionary, seats: Array) -> Control:
	var drawer := _drawer("GmLayer", "ui.cockpit.gm.heading")
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
	var change: Array = options.get("last_change", [])
	if not change.is_empty():
		_label(list, "ui.cockpit.gm.last_change", {}, &"CaptionLabel")
		for e: Dictionary in change:
			_label(list, "ui.morning.private.other", {"type": str(e["type"]), "details": _details(e.get("data", {}), seats)}, &"SectionLabel")
	_label(list, "ui.cockpit.gm.history", {}, &"CaptionLabel")
	for pair: Array in [["UndoButton", "undo", "ui.cockpit.gm.undo"], ["RedoButton", "redo", "ui.cockpit.gm.redo"]]:
		var label := CockpitText.command_label(options.get(pair[1], {}))
		var b := _button(pair[0], pair[2], GrimmButton.Kind.SECONDARY)
		b.format_values = {"what": _format(label)}
		b.disabled = (options.get(pair[1], {}) as Dictionary).is_empty()
		list.add_child(b)
	_label(list, "ui.cockpit.gm.corrections", {}, &"CaptionLabel")
	var kinds: Array = ["kill", "revive", "set_role", "status", "declare_winner"]
	if bool(options.get("day", false)):
		kinds.insert(4, "execute")
	for kind: String in kinds:
		var b := _button("GmKind_%s" % kind, "ui.cockpit.gm.start.%s" % kind, GrimmButton.Kind.SECONDARY)
		b.set_meta("gm_kind", kind)
		list.add_child(b)
	_label(list, "ui.cockpit.gm.game", {}, &"CaptionLabel")
	list.add_child(_button("LeaveGameButton", "ui.cockpit.gm.leave", GrimmButton.Kind.SECONDARY))
	list.add_child(_button("DiscardGameButton", "ui.cockpit.gm.discard", GrimmButton.Kind.DANGER))
	return drawer


## Text einer Beschreibung {key, values} (für Platzhalter in Buttons; Rollen übersetzt).
static func _format(label: Dictionary) -> String:
	var values := GrimmLabel.translated_values(Engine.get_main_loop().root, label["values"])
	return TranslationServer.translate(str(label["key"])).format(values)


static func cover_panel() -> Control:
	var root := _full_rect("CoverLayer")
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CoverPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	var center := CenterContainer.new()
	panel.add_child(center)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"ScreenColumn"
	center.add_child(column)
	_label(column, "ui.cockpit.cover.heading", {}, &"HeadingLabel")
	_label(column, "ui.cockpit.cover.message", {}, &"MutedLabel")
	column.add_child(_button("UncoverButton", "ui.cockpit.cover.resume", GrimmButton.Kind.PRIMARY))
	return root


# --- Bausteine --------------------------------------------------------------------------------------

static func _drawer(node_name: String, heading_key: String) -> Control:
	var root := _full_rect(node_name)
	var dim := Panel.new()
	dim.name = "Dim"
	dim.theme_type_variation = &"OverlayDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "Drawer"
	panel.theme_type_variation = &"DrawerPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -ThemeTokens.DRAWER_WIDTH
	root.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := _label(head, heading_key, {}, &"HeadingLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := _button("CloseLayerButton", "ui.cockpit.layer.close", GrimmButton.Kind.SECONDARY)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "DrawerList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	scroll.add_child(list)
	# Tippen neben die Schublade schließt sie (02 §4 Navigationsregel 2).
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
			close.pressed.emit())
	return root


## Ebene mit zentriertem `DetailPanel`: [Wurzel, Panel]. Text in `panel.content`, Buttons in `panel.actions`.
static func _detail_layer(node_name: String) -> Array:
	var root := _full_rect(node_name)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := DetailPanel.new()
	center.add_child(panel)
	return [root, panel]


static func _full_rect(node_name: String) -> Control:
	var root := Control.new()
	root.name = node_name
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return root


static func _label(parent: Node, key: String, values: Dictionary, variation: StringName) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.format_values = values
	label.text_key = key
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


static func _button(node_name: String, key: String, kind: GrimmButton.Kind) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = kind
	b.text_key = key
	return b


## Ereignisdaten als lesbare Zeile: Personen mit Platz und Name, Rollen als Namen, sonst Rohwert.
static func _details(data: Dictionary, seats: Array) -> String:
	var parts: Array = []
	var keys := data.keys()
	keys.sort()
	for k: Variant in keys:
		var key := str(k)
		var value: Variant = data[k]
		var text := ""
		if key.ends_with("_id") and (value is int or value is float):
			text = CockpitText.names_of([int(value)], seats) if int(value) >= 1 else "–"
		elif key.ends_with("_ids") and value is Array:
			text = CockpitText.names_of(value, seats)
		elif key.contains("role") and value is String and value != "":
			text = TranslationServer.translate(String(CockpitText.role_name(value)))
		elif value is Dictionary or value is Array:
			text = JSON.stringify(value)
		else:
			text = str(value)
		parts.append("%s: %s" % [key, text])
	return " · ".join(parts)
