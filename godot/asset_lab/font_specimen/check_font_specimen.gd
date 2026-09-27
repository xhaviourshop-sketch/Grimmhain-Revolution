extends SceneTree
## Prüft das Schriftmuster in 1024×768 und 1280×800 und erzeugt auf Wunsch Screenshots.
## Nicht Teil der App und nicht Teil der Testsuite (tests/run_tests.gd lädt es nicht).
##
## Nur Prüfung (headless möglich, keine Bilder):
##   <godot> --headless --path godot -s res://asset_lab/font_specimen/check_font_specimen.gd
## Prüfung und Screenshots (echter Renderer nötig, z. B. in der Cloud):
##   xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://asset_lab/font_specimen/check_font_specimen.gd -- --shots
## Screenshots landen in docs/evidence/asset-lab/font-specimen/ und müssen danach im
## Assetregister erfasst werden (node tools/check-asset-register.js --suggest).
##
## Geprüft je Seite und Größe (logische Größe = Fenstergröße, ohne Skalierung, ungünstigster Fall):
## - jede Beschriftung liegt vollständig im Fenster
## - einzeilige Beschriftungen und Buttons sind nicht schmaler als ihr Text
## - umbrechende Beschriftungen zeigen alle Zeilen
## - die Seite passt ohne Scrollen

const SCENE := "res://asset_lab/font_specimen/font_specimen.tscn"
const SIZES := [Vector2i(1024, 768), Vector2i(1280, 800)]
const SLUGS := ["titles-card", "explanation", "sizes-names"]


func _initialize() -> void:
	var shots := OS.get_cmdline_user_args().has("--shots")
	var headless := DisplayServer.get_name() == "headless"
	if shots and headless:
		printerr("Screenshots brauchen einen Renderer (xvfb-run). Headless läuft nur die Prüfung.")
		shots = false
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../docs/evidence/asset-lab/font-specimen").simplify_path()
	if shots:
		DirAccess.make_dir_recursive_absolute(out_dir)
	var problems: Array[String] = []
	var n := 0
	for size: Vector2i in SIZES:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		for attempt: int in 20:
			root.size = size
			await process_frame
			if root.get_visible_rect().size == Vector2(size):
				break
		var specimen := (load(SCENE) as PackedScene).instantiate() as Control
		root.add_child(specimen)
		await _frames(4)
		if n == 0:
			print("Schriften: ", specimen.get("font_notes"))
		for page: int in int(specimen.call("page_count")):
			specimen.call("show_page", page)
			await _frames(6)
			var tag := "%dx%d Seite %d" % [size.x, size.y, page + 1]
			problems.append_array(_check(specimen, tag, Rect2(Vector2.ZERO, Vector2(size))))
			if shots:
				var file := out_dir.path_join("%02d-%s-%dx%d.png" % [page + 1, SLUGS[page], size.x, size.y])
				var err := root.get_texture().get_image().save_png(file)
				if err != OK:
					problems.append("%s: Screenshot nicht gespeichert (%s)" % [tag, error_string(err)])
				else:
					print("Screenshot ", file)
			n += 1
		specimen.queue_free()
		await _frames(2)
	for p: String in problems:
		printerr(p)
	print("%d Ansichten geprüft, %d Befunde, Renderer: %s" % [n, problems.size(), "headless" if headless else RenderingServer.get_video_adapter_name()])
	quit(0 if problems.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _check(specimen: Control, tag: String, view: Rect2) -> Array[String]:
	var out: Array[String] = []
	var scroll := specimen.find_child("PageScroll", true, false) as ScrollContainer
	if scroll != null and scroll.get_v_scroll_bar().visible:
		out.append("%s: Seite passt nicht ohne Scrollen" % tag)
	for node: Node in _visible_controls(specimen):
		var c := node as Control
		var rect := c.get_global_rect()
		if c is Label or c is Button:
			if not view.grow(0.5).encloses(rect):
				out.append("%s: außerhalb des Fensters: %s %s" % [tag, _text(c), rect])
		if c is Label:
			var l := c as Label
			if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
				if l.get_minimum_size().x > l.size.x + 0.5:
					out.append("%s: einzeilig abgeschnitten: %s" % [tag, _text(l)])
			elif l.get_visible_line_count() < l.get_line_count():
				out.append("%s: Zeilen verdeckt (%d von %d): %s" % [tag, l.get_visible_line_count(), l.get_line_count(), _text(l)])
		elif c is Button:
			var b := c as Button
			if b.get_minimum_size().x > b.size.x + 0.5 or b.get_minimum_size().y > b.size.y + 0.5:
				out.append("%s: Button zu klein für Text: %s" % [tag, _text(b)])
	return out


func _visible_controls(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in node.get_children():
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		if child is Control:
			out.append(child)
		out.append_array(_visible_controls(child))
	return out


func _text(c: Control) -> String:
	var t := str(c.get("text"))
	return "„%s“" % (t.substr(0, 40) + ("…" if t.length() > 40 else ""))
