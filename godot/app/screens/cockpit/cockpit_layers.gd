class_name CockpitLayers
extends RefCounted
## Ebenen über dem Cockpit, jeweils erst beim Öffnen aus aktuellen Daten gebaut und beim Schließen
## wieder entfernt (kein verstecktes Geheimnis im Baum):
##   private_drawer  Rollen je Person (Schublade rechts, klar als „Nur Spielleitung“ markiert)
##   log_drawer      Protokoll aller Ereignisse
##   show_card       Karte für die handelnde Person: nur die Positivliste des Prompts (`show`)
##   cover_panel     Sichtschutz über dem ganzen Cockpit
## Jede Ebene hat einen `CloseLayerButton` (bzw. `UncoverButton`); die Ansicht verbindet ihn.


static func private_drawer(seats: Array) -> Control:
	var drawer := _drawer("PrivateLayer", "ui.cockpit.private.heading")
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
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
		var key := "ui.log.event.%s" % type
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


## Karte für die handelnde Person: Rollenname und ausschließlich die freigegebenen Werte.
static func show_card(next: Dictionary) -> Control:
	var lines: Array = next.get("show", [])
	if lines.is_empty():
		return null
	var root := _full_rect("ShowLayer")
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
	_label(column, "ui.cockpit.show.heading", {"role": CockpitText.role_name(str(next.get("role_id")))}, &"HeadingLabel")
	for line: Dictionary in lines:
		_label(column, CockpitText.info_key(str(line["key"])), {}, &"CaptionLabel")
		var value := GrimmLabel.new()
		value.theme_type_variation = &"ShowValueLabel"
		var shown: Variant = CockpitText.info_value(line)
		value.format_values = {"value": shown}
		value.text_key = "ui.cockpit.show.value"
		column.add_child(value)
	var close := _button("CloseLayerButton", "ui.cockpit.show.close", GrimmButton.Kind.PRIMARY)
	column.add_child(close)
	return root


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
