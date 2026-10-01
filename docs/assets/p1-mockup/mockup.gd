extends SceneTree
## P1 scratch mockup (not part of the project): 24 seats on a 4:3 board, three seat layouts.
## Run: godot --path godot --rendering-driver opengl3 -s <this file> -- [--out=<dir>] [--bg=<img>] [--portraits=<a,b,c>] [--tag=<suffix>]

const ASSETS := "C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui/app/public/assets/"
const NAMES: Array[String] = ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin-Maximilian", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgangamadeus", "Zoë"]
const PORTRAIT_FILES: Array[String] = ["Village_Young_Male", "Village_Old_Female", "Village_Middleaged_Male", "Village_Young_Female",
	"Village_Old_Male", "Village_Middleaged_Female", "Solo_Male", "Solo_Female"]
const GOLD := Color("#c9a84c")
const GOLD_DIM := Color("#7d6830")
const MOON := Color("#8fa8e0")
const BAR_H := 52.0
## inward: odd seats move towards the centre (below 60 px = offset, above = second ring scale 0.66)
const VARIANTS := [
	{"id": "V1-einring-schild84", "label": "Einring, Schild 84 px", "portrait": 60.0, "plate": 84.0, "font": 14, "inward": 0.0},
	{"id": "V1b-einring-nummer-badge", "label": "Einring, Nummer als Badge, Schild 84 px", "portrait": 60.0, "plate": 84.0, "font": 14, "inward": 0.0, "badge": true},
	{"id": "V1c-seitenleisten", "label": "V1b + Seitenleisten, Phase, Timer, Legende", "portrait": 60.0, "plate": 84.0, "font": 14, "inward": 0.0, "badge": true, "bars": true},
	{"id": "V2-versetzter-ring-name100", "label": "Versetzter Ring, Name 100 px", "portrait": 54.0, "plate": 100.0, "font": 15, "inward": 44.0},
	{"id": "V3-zwei-ringe-schild104", "label": "Zwei Ringe, Schild 104 px", "portrait": 56.0, "plate": 104.0, "font": 15, "inward": 120.0},
]
const SIZES: Array[Vector2i] = [Vector2i(1024, 768), Vector2i(1280, 800)]

var _bg: Texture2D
var _frame: Texture2D
var _vignette := false
var _portraits: Array[Texture2D] = []


class MockSeat extends Control:
	var tex: Texture2D
	var portrait_px := 60.0
	var plate_w := 84.0
	var font_size := 14
	var label_text := ""
	var state := "normal"
	var badge := ""

	func _draw() -> void:
		var gold := Color("#c9a84c")
		var c := Vector2(size.x * 0.5, portrait_px * 0.5)
		var r := portrait_px * 0.5
		var tint := Color.WHITE
		var ring := Color("#7d6830")
		match state:
			"allowed": ring = gold
			"selected": ring = Color("#f3de9f")
			"actor": ring = Color("#8fa8e0")
			"dead":
				tint = Color(0.45, 0.45, 0.5)
				ring = Color("#4a4d58")
		if state == "selected" or state == "actor":
			draw_circle(c, r + 7.0, Color(ring.r, ring.g, ring.b, 0.28))
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i: int in 48:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 2.0))
			uvs.append(Vector2(0.5 + 0.5 * cos(a) * 0.92, 0.46 + 0.5 * sin(a) * 0.92))
		draw_colored_polygon(pts, tint, uvs, tex)
		draw_arc(c, r - 1.0, 0.0, TAU, 48, ring, 3.0 if state != "normal" else 2.0, true)
		if state == "dead":
			draw_line(c + Vector2(-r * 0.5, -r * 0.5), c + Vector2(r * 0.5, r * 0.5), Color("#9b3a3a"), 3.0, true)
			draw_line(c + Vector2(r * 0.5, -r * 0.5), c + Vector2(-r * 0.5, r * 0.5), Color("#9b3a3a"), 3.0, true)
		var font := ThemeDB.fallback_font
		if badge != "":
			var bc := Vector2(c.x - r * 0.72, c.y - r * 0.72)
			draw_circle(bc, 10.0, Color(0.04, 0.05, 0.09, 0.92))
			draw_arc(bc, 10.0, 0.0, TAU, 24, ring, 1.5, true)
			var bw := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(font, Vector2(bc.x - bw * 0.5, bc.y + 4.5), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ece7dc"))
		var text := label_text
		var max_w := plate_w - 10.0
		while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_w and text.length() > 3:
			text = text.trim_suffix("…")
			text = text.left(text.length() - 1) + "…"
		var plate := Rect2((size.x - plate_w) * 0.5, portrait_px + 3.0, plate_w, 22.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.05, 0.09, 0.82)
		sb.set_corner_radius_all(11)
		sb.border_color = ring
		sb.set_border_width_all(1)
		draw_style_box(sb, plate)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var col := Color("#ece7dc") if state != "dead" else Color("#8a877f")
		draw_string(font, Vector2(plate.position.x + (plate_w - w) * 0.5, plate.position.y + 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


func _initialize() -> void:
	var out := "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/mockup-platzhalter"
	var bg_path := ASSETS + "bg/bg-village-night.webp"
	var portrait_paths: Array[String] = []
	for f: String in PORTRAIT_FILES:
		portrait_paths.append(ASSETS + "portraits/" + f + ".png")
	var tag := ""
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--bg="):
			bg_path = arg.trim_prefix("--bg=")
		elif arg.begins_with("--frame="):
			_frame = _load(arg.trim_prefix("--frame="), 1024)
		elif arg == "--vignette":
			_vignette = true
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
		elif arg.begins_with("--tag="):
			tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--portraits="):
			portrait_paths.clear()
			for p: String in arg.trim_prefix("--portraits=").split(","):
				portrait_paths.append(p)
	DirAccess.make_dir_recursive_absolute(out)
	_bg = _load(bg_path, 1920)
	for p: String in portrait_paths:
		_portraits.append(_load(p, 160))
	for size: Vector2i in SIZES:
		for v: Dictionary in VARIANTS:
			if only != "" and not str(v["id"]).begins_with(only):
				continue
			await _shoot(out.path_join("P1-%s%s-%dx%d.png" % [v["id"], tag, size.x, size.y]), size, v)
	quit(0)


func _load(path: String, max_side: int) -> Texture2D:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		printerr("Bild nicht ladbar: ", path)
		return null
	var m := maxi(img.get_width(), img.get_height())
	if m > max_side:
		var f := float(max_side) / float(m)
		img.resize(int(img.get_width() * f), int(img.get_height() * f), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _shoot(path: String, size: Vector2i, v: Dictionary) -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for attempt: int in 20:
		root.size = size
		await process_frame
		if root.get_visible_rect().size == Vector2(size):
			break
	var host := Control.new()
	host.theme = ThemeFactory.build()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	_build(host, Vector2(size), v)
	for i: int in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("ok  ", path.get_file(), "  ", image.get_size())
	root.remove_child(host)
	host.free()


func _build(host: Control, size: Vector2, v: Dictionary) -> void:
	var bg := TextureRect.new()
	bg.texture = _bg
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.25)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _vignette:
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.56)) / vec2(0.5, 0.46);
	float d = length(p);
	float centre = 1.0 - smoothstep(0.35, 1.0, d);
	float edge = smoothstep(0.95, 1.5, d);
	COLOR = vec4(0.012, 0.02, 0.05, centre * 0.62 + edge * 0.3);
}"""
		var mat := ShaderMaterial.new()
		mat.shader = sh
		shade.material = mat
		shade.color = Color.WHITE
	host.add_child(shade)
	_bar(host, Rect2(12, 8, size.x - 24, BAR_H - 8), "Nacht 1 · Schritt 2 von 11 erledigt", "24 von 24 leben")
	if not v.get("bars", false):
		_tools(host, Rect2(12, size.y - BAR_H, size.x - 24, BAR_H - 8))
	var board := Rect2(12, BAR_H + 6, size.x - 24, size.y - 2.0 * BAR_H - 12)
	var portrait: float = v["portrait"]
	var plate: float = v["plate"]
	var outer_a := board.size.x * 0.5 - maxf(portrait * 0.5 + 6.0, plate * 0.5)
	var top_ext := portrait * 0.5
	var bot_ext := portrait * 0.5 + 27.0 - 4.0
	var outer_b := (board.size.y - top_ext - bot_ext) * 0.5
	var centre := Vector2(board.get_center().x, board.position.y + top_ext + outer_b)
	var outer := _ring_points(24, centre, outer_a, outer_b)
	var inward: float = v["inward"]
	var seat_rects: Array[Rect2] = []
	for i: int in 24:
		var p: Vector2 = outer[i]
		if inward > 0.0 and i % 2 == 1:
			if inward < 60.0:
				p -= (p - centre).normalized() * inward
			else:
				p = centre + (p - centre) * 0.66
		var seat := MockSeat.new()
		seat.tex = _portraits[(i * 3) % _portraits.size()]
		seat.portrait_px = portrait
		seat.plate_w = plate
		seat.font_size = int(v["font"])
		if v.get("badge", false):
			seat.badge = str(i + 1)
			seat.label_text = NAMES[i]
		else:
			seat.label_text = "%d %s" % [i + 1, NAMES[i]]
		seat.state = "allowed"
		if i == 7:
			seat.state = "actor"
		if i == 2:
			seat.state = "selected"
		if i == 11 or i == 16:
			seat.state = "dead"
		seat.size = Vector2(maxf(portrait, plate), portrait + 27.0)
		seat.position = p - Vector2(seat.size.x * 0.5, portrait * 0.5)
		host.add_child(seat)
		seat_rects.append(Rect2(seat.position, seat.size))
	_card(host, centre)
	print("ring %s %dx%d: a=%.1f b=%.1f centre=%s" % [v["id"], int(size.x), int(size.y), outer_a, outer_b, centre])
	if v.get("bars", false):
		var rects := _side_bars(host, size)
		for r: Rect2 in rects:
			var hits := 0
			for sr: Rect2 in seat_rects:
				if r.intersects(sr):
					hits += 1
			print("   bereich %s: %d Überschneidungen mit Plätzen" % [r, hits])
	var lbl := Label.new()
	lbl.text = "%s · %dx%d (Platzhalter-Bilder, Mockup)" % [v["label"], int(size.x), int(size.y)]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(1, 1, 1, 0.55)
	lbl.position = Vector2(size.x - 330, size.y - 22)
	host.add_child(lbl)


## Points spread by arc length on an ellipse, clockwise, seat 1 just left of the top centre.
func _ring_points(count: int, centre: Vector2, a: float, b: float) -> Array[Vector2]:
	var samples := 2000
	var cum: Array[float] = [0.0]
	var prev := Vector2(0, -b)
	for i: int in range(1, samples + 1):
		var t := -PI * 0.5 + TAU * float(i) / float(samples)
		var pt := Vector2(cos(t) * a, sin(t) * b)
		cum.append(cum[i - 1] + prev.distance_to(pt))
		prev = pt
	var total: float = cum[samples]
	var out: Array[Vector2] = []
	for k: int in count:
		var target := total * float(k) / float(count) - total / float(count) * 0.5
		if target < 0.0:
			target += total
		var idx := 0
		while idx < samples and cum[idx] < target:
			idx += 1
		var t := -PI * 0.5 + TAU * float(idx) / float(samples)
		out.append(centre + Vector2(cos(t) * a, sin(t) * b))
	return out


func _bar(host: Control, r: Rect2, left: String, right: String) -> void:
	var p := PanelContainer.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.14, 0.82)
	sb.border_color = GOLD_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	p.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	p.add_child(row)
	var l := Label.new()
	l.text = left
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var rl := Label.new()
	rl.text = right
	rl.add_theme_color_override("font_color", Color("#aaa393"))
	row.add_child(rl)
	host.add_child(p)


func _tools(host: Control, r: Rect2) -> void:
	var p := PanelContainer.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.14, 0.82)
	sb.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	p.add_child(row)
	for t: String in ["Protokoll", "Rollen", "Spielleitung", "Verbergen", "Lexikon", "Regelbuch"]:
		var b := Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(110, 40)
		row.add_child(b)
	host.add_child(p)


## Compact action card: title, one instruction line, one primary button. Details behind "Mehr".
func _card(host: Control, centre: Vector2) -> void:
	var w := 300.0
	var h := 150.0
	if _frame != null:
		w = 340.0
		h = 176.0
	var p := PanelContainer.new()
	p.size = Vector2(w, h)
	p.position = centre - Vector2(w * 0.5, h * 0.5)
	var sb: StyleBox = StyleBoxFlat.new()
	if _frame != null:
		var st := StyleBoxTexture.new()
		st.texture = _frame
		st.texture_margin_left = 46
		st.texture_margin_right = 46
		st.texture_margin_top = 46
		st.texture_margin_bottom = 46
		st.content_margin_left = 34
		st.content_margin_right = 34
		st.content_margin_top = 22
		st.content_margin_bottom = 22
		sb = st
	else:
		var f := sb as StyleBoxFlat
		f.bg_color = Color(0.06, 0.07, 0.11, 0.86)
		f.border_color = GOLD
		f.set_border_width_all(2)
		f.set_corner_radius_all(10)
		f.content_margin_left = 16
		f.content_margin_right = 16
		f.content_margin_top = 12
		f.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	p.add_child(col)
	var title := Label.new()
	title.text = "Wolfskind"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var instr := Label.new()
	instr.text = "Tippe das gewählte Vorbild an."
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_font_size_override("font_size", 17)
	col.add_child(instr)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var more := Button.new()
	more.text = "Mehr"
	more.custom_minimum_size = Vector2(72, 48)
	row.add_child(more)
	var ok := Button.new()
	ok.text = "Bestätigen"
	ok.theme_type_variation = &"PrimaryButton"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 48)
	row.add_child(ok)
	host.add_child(p)


const BAR_W := 52.0  ## side bar width (48 px touch cell + 2 px margin each side)


## Placeholder side bars and the phase block; returns the occupied rects for the overlap check.
func _side_bars(host: Control, size: Vector2) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var left_icons: Array[String] = ["log", "roles", "gm", "hide"]
	var right_icons: Array[String] = ["settings", "sound", "help"]
	rects.append(_icon_bar(host, Vector2(6, BAR_H + 6), left_icons))
	rects.append(_icon_bar(host, Vector2(size.x - 6 - BAR_W, BAR_H + 6), right_icons))
	var block := Rect2(8, size.y - 8 - 134, 132, 134)
	var col := VBoxContainer.new()
	col.position = block.position
	col.size = block.size
	col.add_theme_constant_override("separation", 6)
	var phase := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.14, 0.86)
	sb.border_color = GOLD_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	phase.add_theme_stylebox_override("panel", sb)
	var pl := Label.new()
	pl.text = "Nacht 1"
	pl.add_theme_color_override("font_color", GOLD)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var timer := Label.new()
	timer.text = "–:––"
	timer.add_theme_font_size_override("font_size", 22)
	timer.add_theme_color_override("font_color", Color("#aaa393"))
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	pv.add_child(pl)
	pv.add_child(timer)
	phase.add_child(pv)
	phase.custom_minimum_size = Vector2(0, 68)
	col.add_child(phase)
	var legend := Button.new()
	legend.text = "Legende"
	legend.custom_minimum_size = Vector2(0, 48)
	col.add_child(legend)
	host.add_child(col)
	rects.append(Rect2(block.position, Vector2(block.size.x, 68 + 6 + 48)))
	return rects


func _icon_bar(host: Control, pos: Vector2, icons: Array[String]) -> Rect2:
	var h := float(icons.size()) * 48.0 + float(icons.size() - 1) * 4.0 + 8.0
	var panel := Panel.new()
	panel.position = pos
	panel.size = Vector2(BAR_W, h)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.14, 0.86)
	sb.border_color = GOLD_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	host.add_child(panel)
	for i: int in icons.size():
		var ic := MockIcon.new()
		ic.kind = icons[i]
		ic.position = pos + Vector2(2, 4 + float(i) * 52.0)
		ic.size = Vector2(48, 48)
		host.add_child(ic)
	return Rect2(pos, panel.size)


class MockIcon extends Control:
	var kind := ""

	func _draw() -> void:
		var col := Color("#c9a84c")
		var c := size * 0.5
		match kind:
			"log":
				for i: int in 3:
					draw_line(Vector2(14, 15 + i * 9), Vector2(34, 15 + i * 9), col, 2.0, true)
			"roles":
				draw_circle(c + Vector2(0, -6), 6.0, col)
				draw_arc(c + Vector2(0, 14), 11.0, PI, TAU, 16, col, 3.0, true)
			"gm":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 10), c + Vector2(-11, -4), c + Vector2(-5, 2), c + Vector2(0, -10), c + Vector2(5, 2), c + Vector2(11, -4), c + Vector2(11, 10)]), col)
			"hide":
				draw_arc(c, 11.0, PI * 1.15, PI * 1.85, 12, col, 2.0, true)
				draw_arc(c, 11.0, PI * 0.15, PI * 0.85, 12, col, 2.0, true)
				draw_circle(c, 4.0, col)
				draw_line(c + Vector2(-12, 12), c + Vector2(12, -12), Color("#9b3a3a"), 2.0, true)
			"settings":
				draw_arc(c, 8.0, 0.0, TAU, 20, col, 3.0, true)
				for i: int in 8:
					var d := Vector2.from_angle(TAU * float(i) / 8.0)
					draw_line(c + d * 10.0, c + d * 14.0, col, 3.0, true)
			"sound":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -4), c + Vector2(-6, -4), c + Vector2(2, -11), c + Vector2(2, 11), c + Vector2(-6, 4), c + Vector2(-12, 4)]), col)
				draw_arc(c + Vector2(2, 0), 8.0, -0.8, 0.8, 8, col, 2.0, true)
			"help":
				var f := ThemeDB.fallback_font
				draw_string(f, Vector2(c.x - 7, c.y + 9), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)
