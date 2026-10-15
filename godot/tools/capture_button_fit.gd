extends SceneTree
## Misst die echten Text-Pixel aller sichtbaren Knöpfe gegen den gemalten Innenbereich ihres Rahmenbilds und legt Screenshots ab.
## Braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_button_fit.gd -- --out=<Ordner> [--size=1180x820] [--lang=en] [--tag=vorher]
## Text-Pixel = Differenz zwischen Bild mit Text und Bild mit unsichtbarer Schrift (Unterlängen und Umlaute zählen mit).
## Innenbereich = die deckenden Zeilen der Rahmenbild-Mitte (ohne Dornen-Enden), abzüglich des Randes; bei Rahmenbildern ohne SkinBarBox
## (Laschen, Fenster) die Knopffläche selbst. Fundstellen als Zeilen "FUND ..." auf der Konsole.
var OUT := "user://shots"
var SIZE := Vector2i(1024, 768)
var LANG := "de"
var TAG := "nachher"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia"]
const ROLES := ["werwolf", "blutwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner", "amalia"]
const EDGE := -1  ## Messtoleranz in Pixeln: 1 px Überstand ist Rundung und Kantenglättung (der Innenbereich ist selbst eine Messung am Rahmenbild)
var _findings: Array[String] = []
var _checked: int = 0


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
		elif a.begins_with("--size="):
			var p := a.trim_prefix("--size=").split("x")
			SIZE = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--lang="):
			LANG = a.trim_prefix("--lang=")
		elif a.begins_with("--tag="):
			TAG = a.trim_prefix("--tag=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = SIZE
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language(LANG)
	var tmp := OS.get_temp_dir().path_join("grimmhain-capfit")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	for id: StringName in [&"main_menu", &"settings", &"new_game", &"continue", &"lexicon", &"rulebook", &"history"]:
		shell.navigate(id)
		await _fr(6)
		await _measure(String(id))
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(4)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": "capfit", "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	await _fr(10)
	await _measure("cockpit-start")
	ctx.session.start_night()
	await _fr(12)
	await _measure("cockpit-nacht")
	var game: GDScript = load("res://tests/ui/ui_game.gd")
	for i: int in 30:
		var undo := _screen().find_child("DockUndoButton", true, false) as Control
		if undo != null and undo.is_visible_in_tree():
			await _measure("cockpit-undo")
			break
		if str(game.call("step", ctx.session)) == "":
			break
		await _fr(4)
	game.call("to_day", ctx.session)
	shell.navigate(&"cockpit")
	await _fr(15)
	await _measure("cockpit-tag")
	var day_undo := _screen().find_child("DockUndoButton", true, false) as Control
	if day_undo != null:
		day_undo.visible = true  # im Tag erscheint „Rückgängig“ nur nach einer Aktion; hier erzwungen, um das Maß zu prüfen
		await _fr(6)
		await _measure("cockpit-tag-undo")
	for tool: String in ["LogButton", "OptionsButton"]:
		var b := _screen().find_child(tool, true, false) as BaseButton
		if b != null and b.is_visible_in_tree():
			b.pressed.emit()
			await _fr(10)
			await _measure("cockpit-" + tool)
			b.pressed.emit()  # die Lasche schaltet das Fenster wieder zu
			await _fr(8)
	print("GEPRUEFT %d" % _checked)
	print("FUNDE %d" % _findings.size())
	for f: String in _findings:
		print(f)
	quit(0)


func _screen() -> Control:
	return shell.current_screen()


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
	await RenderingServer.frame_post_draw


func _buttons(node: Node, out: Array[Control]) -> void:
	if (node is BaseButton or (node is Label and (node as Label).get_theme_stylebox(&"normal") is SkinBarBox)) and (node as Control).is_visible_in_tree():
		out.append(node as Control)
	for c: Node in node.get_children():
		_buttons(c, out)


## Alle Farb-Überschreibungen und Themefarben der Schrift eines Knopfes, damit sie unsichtbar gemacht und wieder hergestellt werden können.
const COLOR_NAMES := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]


func _measure(label: String) -> void:
	var screen := _screen()
	var buttons: Array[Control] = []
	_buttons(screen, buttons)
	var texts: Array[Control] = []
	for b: Control in buttons:
		if (b is Button or b is Label) and _text_of(b) != "" and b.get_global_rect().size.x > 2.0:
			var type := b.theme_type_variation if b.theme_type_variation != &"" else (&"Button" if b is Button else &"Label")
			if b.get_theme_color(&"font_color", type).a >= 0.05:
				texts.append(b)
	var shot_name := "%s-%s-%dx%d-%s" % [TAG, label, SIZE.x, SIZE.y, LANG]
	var with_text := root.get_texture().get_image()
	if label in ["cockpit-start", "cockpit-nacht", "cockpit-tag", "cockpit-undo", "cockpit-tag-undo", "main_menu"]:
		with_text.save_png(OUT.path_join(shot_name + ".png"))
	var saved: Dictionary = {}
	for b: Control in texts:
		var kept: Dictionary = {}
		for cn: String in COLOR_NAMES:
			kept[cn] = true
			b.add_theme_color_override(cn, Color(0, 0, 0, 0))
		saved[b] = kept
	await _fr(2)
	var without_text := root.get_texture().get_image()
	for b: Control in texts:
		for cn: String in COLOR_NAMES:
			b.remove_theme_color_override(cn)
	await _fr(1)
	for b: Control in texts:
		var logical := b.get_global_rect()
		var rect := Rect2i(root.get_final_transform() * logical)  # Bildpunkte (Inhaltsskalierung des Fensters)
		rect = rect.intersection(Rect2i(Vector2i.ZERO, with_text.get_size()))
		if label.begins_with("cockpit-") and label.ends_with("Button") and b.name in [&"DockUndoButton", &"PrivateButton"]:
			continue  # liegt unter dem noch offenen Fenster; dort wird die Schrift des Fensters gemessen, nicht dieses Knopfes
		_checked += 1
		var ink_px := _ink_box(with_text, without_text, rect)
		if ink_px.size == Vector2i.ZERO:
			continue
		var back := root.get_final_transform().affine_inverse()
		var ink := Rect2i(back * Rect2(ink_px))
		var inner := _inner_area(b, Rect2i(logical), without_text)
		var ctext := _text_of(b).replace("\n", " ")
		var bad: Array[String] = []
		if ink.position.x < inner.position.x + EDGE:
			bad.append("links %d px über den Rand" % (inner.position.x + EDGE - ink.position.x))
		if ink.end.x > inner.end.x - EDGE:
			bad.append("rechts %d px über den Rand" % (ink.end.x - (inner.end.x - EDGE)))
		if ink.position.y < inner.position.y + EDGE:
			bad.append("oben %d px über den Rand" % (inner.position.y + EDGE - ink.position.y))
		if ink.end.y > inner.end.y - EDGE:
			bad.append("unten %d px über den Rand" % (ink.end.y - (inner.end.y - EDGE)))
		if b is Button and not ctext.contains(" ") and ink.size.y > b.get_theme_font(&"font").get_height(b.get_theme_font_size(&"font_size")) * 1.5:
			bad.append("Wort mitten umgebrochen")
		if not bad.is_empty():
			_findings.append("FUND %s %dx%d %s %s \"%s\": %s (Schrift %s, Innen %s, Größe %d, Knopf %s)" % [label, SIZE.x, SIZE.y, LANG, b.name, ctext.left(30), ", ".join(bad), ink, inner, b.get_theme_font_size(&"font_size"), b.size])


func _text_of(c: Control) -> String:
	return (c as Button).text if c is Button else (c as Label).text


func _ink_box(a: Image, b: Image, rect: Rect2i) -> Rect2i:
	var x0 := 100000
	var y0 := 100000
	var x1 := -1
	var y1 := -1
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			if absf(pa.r - pb.r) + absf(pa.g - pb.g) + absf(pa.b - pb.b) > 0.12:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i()
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Sichtbarer Innenbereich: bei einer gemalten Leiste (SkinBarBox) die deckende Bandhöhe der Bildmitte und die Breite ohne Dornen-Enden;
## sonst die Knopffläche.
func _inner_area(b: Control, rect: Rect2i, _without_text: Image) -> Rect2i:
	var box := b.get_theme_stylebox(&"normal")
	if not (box is SkinBarBox):
		return rect
	var bar := box as SkinBarBox
	var tex := bar.texture.get_image()
	var bar_h := minf(float(rect.size.y), bar.max_height) if bar.max_height > 0.0 else float(rect.size.y)
	var scale := bar_h / bar.fit_height
	var h := tex.get_height() * scale
	var top := rect.position.y + (rect.size.y - h) * 0.5
	var mid := tex.get_width() / 2
	var first := -1
	var last := -1
	for y: int in tex.get_height():
		if tex.get_pixel(mid, y).a > 0.9:
			if first < 0:
				first = y
			last = y
	var end := bar.end_width * scale
	return Rect2i(Vector2i(int(rect.position.x + end * 0.85), int(top + first * scale)), Vector2i(int(rect.size.x - end * 1.7), int((last - first + 1) * scale)))
