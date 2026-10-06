class_name CockpitLayers
extends RefCounted
## Ebenen über dem Cockpit, jeweils erst beim Öffnen aus aktuellen Daten gebaut und beim Schließen
## wieder entfernt (kein verstecktes Geheimnis im Baum):
##   private_drawer  Rollen je Person (Schublade rechts, klar als „Nur Spielleitung“ markiert)
##   log_drawer      Protokoll aller Ereignisse
##   show_card       Karte für die handelnde Person: nur die Positivliste des Prompts (`show`)
##   cover_panel     Sichtschutz über dem ganzen Cockpit
##   role_list       Rollenanzeige, neutrale Namensliste (nur Namen und Haken, nie Rollen), Antippen öffnet die Karte
##   role_card       Rollenanzeige, großes Bild der Rollenkarte ohne Text; ein Tipp schließt (und meldet „gesehen“)
## Jede Ebene hat einen `CloseLayerButton` (bzw. `UncoverButton`); die Ansicht verbindet ihn.
## Nichts scrollt (Feedback 8): Gezeigte Karte, Hinweiskarte und Rollenliste passen Schrift und Bild dem Platz an, Schubladen für
## privaten Bereich und Protokoll blättern mit „Davor/Danach“. Nur die Totenkarte (card_face) bleibt ein `DetailPanel`.


## `actions`: geheime Tagesaktionen [{action, player_id, name, seat}] als Buttons `SecretAction_*`
## (Metadaten action und player_id); die Ansicht verbindet sie.
## `hints`: Stimmhinweise [{person_id, seat, name, bonus, source_role}] (RM-DR-008) als Zeilen `VoteHint_<id>`.
## Die Personen stehen als gemalte Zeilen (ListRow) nur mit Namen; passen sie nicht auf eine Seite, blättert „Davor/Danach“.
static func private_drawer(seats: Array, actions: Array = [], hints: Array = []) -> Control:
	var drawer := _drawer("PrivateLayer", "ui.cockpit.private.heading", false)
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
	var used := 0.0
	if not hints.is_empty():
		_label(list, "ui.cockpit.private.vote_hints", {}, &"CaptionLabel")
		for h: Dictionary in hints:
			_label(list, "ui.cockpit.private.vote_hint", {"name": CockpitText.person(h), "bonus": int(h["bonus"]),
				"role": CockpitText.role_name(str(h["source_role"]))}, &"SectionLabel").name = "VoteHint_%d" % int(h["person_id"])
		used += 28.0 + 34.0 * hints.size()
	if not actions.is_empty():
		_label(list, "ui.cockpit.private.actions", {}, &"CaptionLabel")
		for a: Dictionary in actions:
			var b := _button("SecretAction_%s_%d" % [str(a["action"]), int(a["player_id"])], "ui.cockpit.private.action.%s" % str(a["action"]), GrimmButton.Kind.SECONDARY)
			b.format_values = {"name": CockpitText.person(a)}
			b.set_meta("action", str(a["action"]))
			b.set_meta("player_id", int(a["player_id"]))
			list.add_child(b)
		used += 28.0 + (ThemeTokens.BUTTON_SECONDARY_HEIGHT + ThemeTokens.SPACE_M) * actions.size()
	var pager := Pager.new()
	pager.setup(seats, _private_row, _private_row_height, _page_room(used + DRAWER_CHROME), false)
	list.add_child(pager)
	return drawer


## Eine Person der privaten Liste: Name, Rolle, Lager; darunter Anmerkungen (ursprüngliche Rolle, Scheinrolle).
static func _private_row(seat: Dictionary) -> Control:
	var row := _list_row("PrivateRow_%d" % int(seat["person_id"]))
	var column := row.get_child(0) as VBoxContainer
	var values := {"name": str(seat["name"]), "role": CockpitText.role_name(str(seat["role_id"])),
		"faction": StringName("ui.faction.%s" % str(seat["faction"]))}
	_label(column, "ui.cockpit.private.row" if bool(seat["alive"]) else "ui.cockpit.private.row_dead", values, &"SectionLabel")
	for note: Dictionary in seat.get("notes", []):
		_label(column, str(note["key"]), {"role": CockpitText.role_name(str(note.get("role_id", "")))}, &"CaptionLabel")
	return row


static func _private_row_height(seat: Dictionary) -> float:
	var h := LIST_ROW_HEIGHT + (28.0 if str(seat["name"]).length() > 10 else 0.0)
	for note: Dictionary in seat.get("notes", []):
		h += 22.0 * ceilf(float(TranslationServer.translate(str(note["key"])).length() + 12) / 38.0)
	return h


## Protokoll in Alltagssätzen (`GameSession.log_lines`), in der Reihenfolge des Geschehens; geöffnet wird die letzte Seite.
static func log_drawer(lines: Array) -> Control:
	var drawer := _drawer("LogLayer", "ui.cockpit.log.heading", false)
	var list := drawer.find_child("DrawerList", true, false) as VBoxContainer
	_label(list, "ui.cockpit.private.warning", {}, &"WarningLabel")
	if lines.is_empty():
		_label(list, "ui.cockpit.log.empty", {}, &"MutedLabel")
		return drawer
	var items: Array = []
	for i: int in lines.size():
		items.append({"index": i, "text": str(lines[i])})
	var pager := Pager.new()
	pager.setup(items, _log_row, _log_row_height, _page_room(DRAWER_CHROME), true)
	list.add_child(pager)
	return drawer


static func _log_row(item: Dictionary) -> Control:
	var row := _list_row("LogRow_%d" % int(item["index"]))
	var label := Label.new()
	label.add_to_group(&"user_content")  # fertiger Satz aus LogText mit Namen der Personen
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = str(item["text"])
	var column := row.get_child(0) as VBoxContainer
	if _log_row_height(item) > LIST_ROW_HEIGHT:
		for pad: int in 2:  # zwei Textzeilen: Innenabstand oben und unten, damit der Text nicht an den Dornen klebt
			var gap := Control.new()
			gap.custom_minimum_size.y = 8.0
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(gap)
			if pad == 0:
				column.add_child(label)
	else:
		column.add_child(label)
	return row


## Zeilen mit zwei Textzeilen bekommen Innenabstand, damit der Text nicht an den Dornen der Zeile klebt.
static func _log_row_height(item: Dictionary) -> float:
	var lines := ceilf(float(str(item["text"]).length() + 4) / 34.0)
	return LIST_ROW_HEIGHT if lines <= 1.0 else 30.0 + 27.0 * lines


const DRAWER_CHROME := 300.0  ## Rahmen, Titelzeile, Hinweis und Blätterleiste der Schublade
const LIST_ROW_HEIGHT := 46.0  ## Zeile mit einer Textzeile (ohne Abstand)


## Höhe für Listenzeilen auf einer Seite: Bildschirmhöhe minus `used`.
static func _page_room(used: float) -> float:
	var root := (Engine.get_main_loop() as SceneTree).root
	return maxf(root.get_visible_rect().size.y - used, 3.0 * LIST_ROW_HEIGHT)


## Gemalte Listenzeile (Theme ListRow) mit einer Spalte darin.
static func _list_row(node_name: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = node_name
	row.theme_type_variation = &"ListRow"
	row.add_child(VBoxContainer.new())
	return row


## Seitenweise Liste ohne Scrollen: baut nur die sichtbare Seite aus den Daten, „Davor“ und „Danach“ blättern.
class Pager extends VBoxContainer:
	var _items: Array = []
	var _build: Callable
	var _pages: Array = []  ## je Seite die Indizes der Einträge
	var _index: int = 0
	var _body: VBoxContainer = null
	var _prev: GrimmButton = null
	var _next: GrimmButton = null
	var _status: GrimmLabel = null

	## `weigh(item)` schätzt die Zeilenhöhe; Seiten füllen sich bis `room`. `last`: mit der letzten Seite beginnen.
	## `keep_next(item)` (optional): Zeilen, die mit der nächsten Zeile zusammenbleiben (Zwischentitel stehen nie allein am Seitenende).
	func setup(items: Array, build: Callable, weigh: Callable, room: float, last: bool, keep_next: Callable = Callable()) -> void:
		name = "Pager"
		_items = items
		_build = build
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
		var page: Array = []
		var used := 0.0
		for i: int in items.size():
			var h: float = float(weigh.call(items[i])) + float(ThemeTokens.SPACE_S)
			if not page.is_empty() and used + h > room:
				var carry: Array = []
				if keep_next.is_valid() and page.size() > 1 and bool(keep_next.call(items[page[page.size() - 1]])):
					carry.append(page.pop_back())
				_pages.append(page)
				page = carry
				used = 0.0
				for c: int in carry:
					used += float(weigh.call(items[c])) + float(ThemeTokens.SPACE_S)
			page.append(i)
			used += h
		if not page.is_empty():
			_pages.append(page)
		_body = VBoxContainer.new()
		_body.name = "PageBody"
		_body.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
		_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(_body)
		if _pages.size() > 1:
			var bar := HBoxContainer.new()
			bar.name = "PageBar"
			_prev = _nav("PrevPageButton", "ui.cockpit.log.prev", -1)
			_status = GrimmLabel.new()
			_status.theme_type_variation = &"CaptionLabel"
			_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_status.name = "PageStatus"
			_next = _nav("NextPageButton", "ui.cockpit.log.next", 1)
			bar.add_child(_prev)
			bar.add_child(_status)
			bar.add_child(_next)
			add_child(bar)
		show_page(_pages.size() - 1 if last else 0)

	func page_count() -> int:
		return _pages.size()

	## Indizes der Einträge auf Seite `i`.
	func page_indices(i: int) -> Array:
		return _pages[i]

	func _nav(node_name: String, key: String, step: int) -> GrimmButton:
		var b := GrimmButton.new()
		b.name = node_name
		b.kind = GrimmButton.Kind.COMPACT
		b.text_key = key
		b.pressed.connect(func() -> void: show_page(_index + step))
		return b

	func show_page(i: int) -> void:
		if _pages.is_empty():
			return
		_index = clampi(i, 0, _pages.size() - 1)
		for child: Node in _body.get_children():
			_body.remove_child(child)
			child.queue_free()
		for item_index: int in _pages[_index]:
			_body.add_child(_build.call(_items[item_index]) as Control)
		if _prev != null:
			_prev.disabled = _index == 0
			_next.disabled = _index == _pages.size() - 1
			_status.format_values = {"page": _index + 1, "total": _pages.size()}
			_status.text_key = "ui.cockpit.log.page"
		GroveWindow.dress(self)


## Teamsymbol vor einem gezeigten Ergebnis (DA-101): Zahl der Wölfe, Wolf ja/nein, Einzelsieg.
const SHOW_TEAMS := {"wolf_count": &"wolves", "is_wolf": &"wolves", "solo_count": &"solo", "solo": &"solo"}
const BARE_BUTTON_HEIGHT := 48.0  ## „Fertig“ unter der fensterlosen Karte: niedrig, damit das Bild rund 90 % der Höhe bekommt
const BARE_NAME_SIZE := 22  ## Name über der fensterlosen Karte: klein, das Bild nimmt die Höhe
const SHOW_ICON := 96.0
const SHOW_MARK := 112.0
const SHOW_NO_CAPTION: Array[String] = ["hit", "is_wolf"]  ## Ergebnisse, die ohne Beschriftung eindeutig sind (Treffer: Haken oder Kreuz)


## Ergebniszeichen der gezeigten Karte: Haken (Mondsilber) für Ja, Kreuz (Blutrot) für Nein. Gezeichnet im größten Quadrat der Fläche.
class ResultMark extends Control:
	var yes: bool = false

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var r := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)).grow(-side * 0.12)
		var width := maxf(side * 0.1, 6.0)
		if yes:
			draw_polyline(PackedVector2Array([r.position + Vector2(0.0, r.size.y * 0.55), r.position + Vector2(r.size.x * 0.38, r.size.y * 0.9),
				r.position + Vector2(r.size.x, r.size.y * 0.1)]), ThemeTokens.MOON_SILVER_BRIGHT, width, true)
		else:
			draw_line(r.position, r.end, ThemeTokens.BLOOD_RED, width, true)
			draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), ThemeTokens.BLOOD_RED, width, true)


## Karte für die handelnde Person: Titel (Rolle der Handelnden) und ausschließlich die freigegebenen Werte. Erhält nur
## diese beiden Angaben, nie den ganzen Prompt (Wahrheit, Teilantworten). Scrollt nie: Namen und Titel passen ihre Schrift an,
## das Rollenbild nimmt den übrigen Platz, Zeichen und Zahlen stehen in einer Reihe.
static func show_card(role_id: String, lines: Array) -> Control:
	if lines.is_empty():
		return null
	var tall := lines.any(func(line: Dictionary) -> bool: return str(line["kind"]) == "role")
	if tall:
		return _bare_show_card(lines)
	var layer := _window_layer("ShowLayer", 600.0, tall)
	var root: Control = layer[0]
	var column: VBoxContainer = layer[1]
	# Mit Kartenbild werden Titel und Name kleiner, damit das Bild so groß wie möglich wird (ohne Scrollen).
	var title := _fit_label(column, "ui.cockpit.show.heading", {"role": CockpitText.role_name(role_id)}, &"GothicTitleLabel",
		ThemeTokens.FONT_GOTHIC - 8 if tall else ThemeTokens.FONT_SHOW_TITLE)
	title.name = "ShowTitle"
	for line: Dictionary in lines:
		_show_line(column, line, ThemeTokens.FONT_SHOW - 14 if tall else ThemeTokens.FONT_SHOW)
	(layer[2] as VBoxContainer).add_child(_button("CloseLayerButton", "ui.cockpit.show.close", GrimmButton.Kind.PRIMARY))
	return root


## Karte mit Rollenbild ohne Fenster (Ausnahme von der Fensterregel, MARKE.md): Nachtgrund, oben klein der Name der Person, das Kartenbild
## nimmt fast die ganze Höhe, darunter nur „Fertig“.
static func _bare_show_card(lines: Array) -> Control:
	var root := _full_rect("ShowLayer")
	root.add_child(BlurBackdrop.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 4)
	root.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "BareContent"
	column.add_theme_constant_override(&"separation", 2)
	margin.add_child(column)
	var order := ["person", "persons", "role"]
	var sorted: Array = lines.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ia := order.find(str(a["kind"]))
		var ib := order.find(str(b["kind"]))
		return (ia if ia >= 0 else order.size()) < (ib if ib >= 0 else order.size()))
	for line: Dictionary in sorted:
		_show_line(column, line, BARE_NAME_SIZE)
	var done := _button("CloseLayerButton", "ui.cockpit.show.close", GrimmButton.Kind.PRIMARY)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.custom_minimum_size.y = BARE_BUTTON_HEIGHT
	column.add_child(done)
	return root


## Eine freigegebene Zeile: Namen als Text, Rolle als Kartenbild, Ja/Nein als Zeichen, Zahlen neben ihrem Teamsymbol.
static func _show_line(column: VBoxContainer, line: Dictionary, name_size: int = ThemeTokens.FONT_SHOW) -> void:
	var key := str(line["key"])
	var kind := str(line["kind"])
	match kind:
		"person", "persons":
			var names: Array[String] = []
			for v: Variant in (line["value"] as Array if kind == "persons" else [line["value"]]):
				var shown := CockpitText.person(v) if v is Dictionary else ""
				names.append(shown if shown != "" else TranslationServer.translate("ui.prompt.value.nobody"))
			if names.size() > 3:
				names = [", ".join(names)]
			for entry: String in names:
				_fit_label(column, "ui.cockpit.show.value", {"value": entry}, &"ShowValueLabel", name_size).name = "ShowName"
			return
		"role":
			var card := RoleCardImage.new()
			card.name = "ShowRoleCard"
			card.role_id = str(line["value"])
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			column.add_child(card)
			return
	var team: StringName = SHOW_TEAMS.get(key, &"")
	if team == &"" and not SHOW_NO_CAPTION.has(key):
		_fit_label(column, CockpitText.info_key(key), {}, &"ShowCaptionLabel", ThemeTokens.FONT_SHOW_CAPTION)
	var row := HBoxContainer.new()
	row.name = "ShowResult_%s" % key
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	column.add_child(row)
	if team != &"" and NightArt.team(team) != null:
		var icon := TextureRect.new()
		icon.texture = NightArt.team(team)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(SHOW_ICON, SHOW_ICON)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	if kind == "bool":
		# Ja/Nein als Zeichen (Haken bzw. Kreuz) statt Wort; die Bedienungshilfe nennt das Wort.
		var mark := ResultMark.new()
		mark.yes = bool(line["value"])
		mark.custom_minimum_size = Vector2(SHOW_MARK, SHOW_MARK)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mark.accessibility_name = TranslationServer.translate("ui.common.yes" if mark.yes else "ui.common.no")
		row.add_child(mark)
		return
	var value := GrimmLabel.new()
	value.theme_type_variation = &"ShowNumberLabel"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.wrap = false
	value.format_values = {"value": CockpitText.info_value(line)}
	value.text_key = "ui.cockpit.show.value"
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value)


## Hinweiskarte für die betroffene Person bzw. Gruppe (DI-04, DI-06, DI-07): nur der Kartentext mit den Werten,
## die die Betrachter erfahren dürfen (`CockpitView.notice_card`), nie Rollen anderer Personen. Bund-Bild der Liebenden bzw. Rivalen
## über dem Satz; Titel und Satz passen ihre Schrift an, nichts scrollt.
static func notice_card(card: Dictionary) -> Control:
	var picture := _bond_picture(str(card["text_key"]))
	var layer := _window_layer("NoticeLayer", 600.0, picture != null)
	var root: Control = layer[0]
	var column: VBoxContainer = layer[1]
	_fit_label(column, "ui.cockpit.notice.heading.group" if bool(card.get("group", false)) else "ui.cockpit.notice.heading", {}, &"GothicTitleLabel", ThemeTokens.FONT_GOTHIC)
	var viewers: Array = card.get("viewers", [])
	if picture != null and viewers.size() == 2:  # nur die Bindung von Loki nennt ihr Paar; andere Hinweise nie (DI-06)
		_fit_label(column, "ui.cockpit.notice.pair", {"first": CockpitText.person(viewers[0]), "second": CockpitText.person(viewers[1])},
			&"ShowCaptionLabel", ThemeTokens.FONT_SHOW).name = "NoticePair"
	if picture != null:
		picture.size_flags_stretch_ratio = 3.0
		column.add_child(picture)
	var text := _fit_label(column, str(card["text_key"]), CockpitText.notice_values(card.get("values", {})), &"ShowValueLabel", ThemeTokens.FONT_SHOW)
	text.name = "NoticeText"
	text.wrap = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.size_flags_stretch_ratio = 2.0
	text.custom_minimum_size.y = 120.0
	if str(card.get("notice_kind", "")) == "piper_new":  # die in dieser Nacht Verzauberten stehen unter dem Hinweis
		var names: Array[String] = []
		for v: Dictionary in viewers:
			names.append(CockpitText.person(v))
		_fit_label(column, "ui.notice.piper_new.names", {"names": ", ".join(names)}, &"ShowCaptionLabel", ThemeTokens.FONT_SHOW).name = "NoticeNames"
	(layer[2] as VBoxContainer).add_child(_button("CloseLayerButton", "ui.cockpit.notice.close", GrimmButton.Kind.PRIMARY))
	return root


## Bild der Loki-Bindung (`assets/ui/skin/bund_liebende.webp`, `bund_rivalen.webp`); fehlt es, bleibt die Karte ohne Bild.
static func _bond_picture(text_key: String) -> TextureRect:
	var file := "bund_liebende" if text_key.ends_with(".love") else "bund_rivalen" if text_key.ends_with(".rival") else ""
	var path := "res://assets/ui/skin/%s.webp" % file
	if file == "" or not ResourceLoader.exists(path):
		return null
	var picture := TextureRect.new()
	picture.name = "BondPicture"
	picture.texture = load(path) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0.0, 160.0)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return picture


const ROLE_COLUMN_WIDTH := 272.0
const ROLE_ROW_HEIGHT := 52.0
const ROLE_CHROME := Vector2(144.0, 290.0)  ## Rahmen, Titel, Fortschritt und „Fertig“ um die Zeilen (Breite, Höhe)


## Rollenanzeige, neutrale Liste (`CockpitView.role_show_list`): eine gemalte Zeile (ListRow) je Person, nur der Name, in Spalten
## nebeneinander, damit auch 24 Personen ohne Scrollen passen. Wer ihre Rolle schon gesehen hat, trägt einen Haken; die nächste
## offene Person ist markiert. Enthält keine Rolle.
static func role_list(list: Dictionary) -> Control:
	var persons: Array = list.get("persons", [])
	# So viele Zeilen je Spalte, wie die Höhe zulässt; die Spaltenzahl folgt daraus, die Spaltenbreite der Bildschirmbreite.
	var screen := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size
	var fit_rows := maxi(int((screen.y - ROLE_CHROME.y + ThemeTokens.SPACE_S) / (ROLE_ROW_HEIGHT + ThemeTokens.SPACE_S)), 3)
	var columns := maxi(ceili(float(persons.size()) / float(fit_rows)), 1)
	var per_column := maxi(ceili(float(persons.size()) / float(columns)), 1)
	var column_width := clampf((screen.x - ROLE_CHROME.x - (columns - 1) * ThemeTokens.SPACE_S) / columns, 140.0, ROLE_COLUMN_WIDTH)
	var layer := _window_layer("RoleListLayer", maxf(ThemeTokens.DIALOG_WIDE_WIDTH * 0.75, columns * (column_width + ThemeTokens.SPACE_S) + ROLE_CHROME.x - ThemeTokens.SPACE_S), false)
	var root: Control = layer[0]
	var column: VBoxContainer = layer[1]
	var heading := _label(column, "ui.cockpit.roles.heading", {}, &"HeadingLabel")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var progress := _label(column, "ui.cockpit.roles.progress", {"done": int(list.get("confirmed_count", 0)), "total": int(list.get("total", 0))}, &"CaptionLabel")
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid := HBoxContainer.new()
	grid.name = "RoleColumns"
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	column.add_child(grid)
	var next_id := int(list.get("next_id", -1))
	var rows: VBoxContainer = null
	for i: int in persons.size():
		if i % per_column == 0:
			rows = VBoxContainer.new()
			rows.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
			rows.custom_minimum_size.x = column_width
			grid.add_child(rows)
		var entry: Dictionary = persons[i]
		rows.add_child(_name_row(int(entry["person_id"]), str(entry["name"]), bool(entry["confirmed"]), int(entry["person_id"]) == next_id))
	(layer[2] as VBoxContainer).add_child(_button("CloseLayerButton", "ui.cockpit.roles.done", GrimmButton.Kind.SECONDARY))
	return root


## Gemalte Namenszeile: Fläche aus dem Theme (ListRow) mit dem Namen, darüber über die ganze Zeile eine unsichtbare Tippfläche (`RolePerson_<id>`).
static func _name_row(person_id: int, person_name: String, done: bool, is_next: bool) -> Control:
	var host := Control.new()
	host.custom_minimum_size.y = ROLE_ROW_HEIGHT
	var row := PanelContainer.new()
	row.theme_type_variation = &"ListRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(row)
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	row.add_child(content)
	var name_label := _fit_label(content, "ui.cockpit.roles.person", {"name": person_name}, &"SectionLabel", ThemeTokens.FONT_SUBTITLE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_next:
		var marker := _label(content, "ui.cockpit.roles.next_marker", {}, &"CaptionLabel")
		marker.name = "RolePersonNext_%d" % person_id
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.wrap = false
		marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if done:
		var mark := ResultMark.new()
		mark.yes = true
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.custom_minimum_size = Vector2(28.0, 28.0)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mark.accessibility_name = TranslationServer.translate("ui.common.yes")
		content.add_child(mark)
	var tap := _button("RolePerson_%d" % person_id, "", GrimmButton.Kind.SECONDARY)
	tap.set_meta("person_id", person_id)
	tap.set_meta(&"grove_skinned", true)  # keine zweite Knopffläche über der Zeile
	tap.accessibility_name = person_name
	tap.custom_minimum_size = Vector2.ZERO
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		tap.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	host.add_child(tap)
	return host


## Rollenanzeige, Karte einer Person (erst nach dem Antippen gebaut): nur das große Bild ihrer Rollenkarte, kein Text. Ein Tipp irgendwo
## schließt die Karte; war die Rolle noch nicht gesehen (`confirmed` false), gilt das Schließen als „gesehen“ (`ConfirmRoleButton`),
## sonst schließt `CloseRoleButton` nur.
static func role_card(card: Dictionary) -> Control:
	var root := _full_rect("RoleCardLayer")
	root.add_child(BlurBackdrop.new())  # Grund der Vollbildkarte: das Dorf dahinter, abgedunkelt und leicht unscharf
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, ThemeTokens.SAFE_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var image := RoleCardImage.new()
	image.name = "RoleCardPicture"
	image.role_id = str(card["role_id"])
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(image)
	var tap := _button("CloseRoleButton" if bool(card.get("confirmed", false)) else "ConfirmRoleButton", "", GrimmButton.Kind.SECONDARY)
	tap.set_meta(&"grove_skinned", true)
	tap.accessibility_name = TranslationServer.translate("ui.cockpit.roles.close")
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		tap.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	root.add_child(tap)
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

static func _drawer(node_name: String, heading_key: String, scrolling: bool = true) -> Control:
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
	close.custom_minimum_size.x = 200.0  # sonst frisst der Dornenrahmen die Breite und „Schließen“ wird winzig
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(close)
	var list := VBoxContainer.new()
	list.name = "DrawerList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	if scrolling:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(scroll)
		scroll.add_child(list)
	else:
		column.add_child(list)  # Seitenlisten blättern statt zu scrollen
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


## Fenster ohne Scrollen: Dornenrahmen am Rand mit Sicherheitsabstand; `tall` füllt die Höhe (für Bilder), sonst so hoch wie der
## Inhalt. [Wurzel, Inhaltsspalte, Aktionsspalte]
static func _window_layer(node_name: String, width: float, tall: bool) -> Array:
	var root := _full_rect(node_name)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, ThemeTokens.SAFE_MARGIN)
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ShowPanel"
	panel.custom_minimum_size.x = width
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_FILL if tall else Control.SIZE_SHRINK_CENTER
	GroveWindow.frame(panel)
	margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	panel.add_child(column)
	var content := VBoxContainer.new()
	content.name = "DetailContent"
	content.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	var actions := VBoxContainer.new()
	actions.name = "DetailActions"
	column.add_child(actions)
	return [root, content, actions]


## Beschriftung, die ihre Schrift an den Platz anpasst (FitLabel), mittig.
static func _fit_label(parent: Node, key: String, values: Dictionary, variation: StringName, max_size: int) -> FitLabel:
	var label := FitLabel.new()
	label.theme_type_variation = variation
	label.max_font_size = max_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.format_values = values
	label.text_key = key
	parent.add_child(label)
	return label


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
