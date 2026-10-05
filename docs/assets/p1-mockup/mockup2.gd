extends SceneTree
## P1 mockup V2 (scratch, not part of the project): rebuilds Spielfeld.png with the real parts.
## Run: godot --path godot --rendering-driver opengl3 -s <this file> -- [--only=<id prefix>] [--sizes=1024x768]

const WK := "C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Werwolf/Grimmhain Assets/"
var SP := ProjectSettings.globalize_path("res://").path_join("../docs/assets/p1-mockup/").simplify_path() + "/"
const BG_G1 := "C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/G1-village-night-v1.png"
const OUT := "C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/mockup-v2"
const NAMES: Array[String] = ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin-Maximilian", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgangamadeus", "Zoë"]
const GOLD := Color("#c9a84c")
const GOLD_DIM := Color("#7d6830")
const TEXT := Color("#ece7dc")
const MUTED := Color("#aaa393")
const RED := Color("#d6453a")
const TOKEN_D := 66.0
const TAB_W := 44.0
## order bar: file key, label
const ORDER := [["die-gebundenen", "Die Gebundenen"], ["wolfskind", "Wolfskind"], ["schutzengel", "Schutzengel"], ["werwolf", "Werwolf"],
	["rachsuechtiger-wolf", "Rachsüchtiger Wolf"], ["koenig-lykaon", "König Lykaon"], ["waldhexe", "Waldhexe"], ["rattenfaenger", "Rattenfänger"]]
const VARIANTS := [
	{"id": "V2-A-g2-leiste-voll", "card": "A", "faces": "g2", "bar": "full"},
	{"id": "V2-B-g2-leiste-voll", "card": "B", "faces": "g2", "bar": "full"},
	{"id": "V2-A-village-leiste-voll", "card": "A", "faces": "village", "bar": "full"},
	{"id": "V2-A-g2-leiste-eingeklappt", "card": "A", "faces": "g2", "bar": "collapsed"},
]
const SIZES: Array[Vector2i] = [Vector2i(1024, 768), Vector2i(1280, 800)]
const VILLAGE: Array[String] = ["Village_Young_Male", "Village_Young_Female", "Village_Middleaged_Male", "Village_Middleaged_Female", "Village_Old_Male", "Village_Old_Female"]

var _cache: Dictionary = {}
var _faces_g2: Array[String] = []
var _faces_vil: Array[String] = []
var _rects: Dictionary = {}


class Token2 extends Control:
	var d := 66.0
	var face: Texture2D
	var frame: Texture2D
	var overlay: Texture2D
	var dead := false
	var number := ""
	var label_text := ""
	var uv_scale := 0.62
	var uv_cy := 0.5

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := 10.0 + d * 0.5
		var c := Vector2(cx, cy)
		var rf := d * 0.36
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i: int in 48:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a), sin(a)) * rf)
			uvs.append(Vector2(0.5 + 0.5 * cos(a) * uv_scale, uv_cy + 0.5 * sin(a) * uv_scale))
		draw_colored_polygon(pts, Color(0.5, 0.5, 0.55) if dead else Color.WHITE, uvs, face)
		var r := Rect2(cx - d * 0.5, cy - d * 0.5, d, d)
		draw_texture_rect(frame, r, false)
		if overlay != null:
			draw_texture_rect(overlay, r, false)
		var font := ThemeDB.fallback_font
		if number != "":
			var nc := Vector2(cx, cy - d * 0.5 + 3.0)
			draw_circle(nc, 9.0, Color(0.03, 0.03, 0.05, 0.92))
			draw_arc(nc, 9.0, 0.0, TAU, 20, Color("#7d6830"), 1.2, true)
			var nw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2(nc.x - nw * 0.5, nc.y + 4.0), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ece7dc"))
		if label_text != "":
			var text := label_text
			while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > 78.0 and text.length() > 3:
				text = text.trim_suffix("…")
				text = text.left(text.length() - 1) + "…"
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var py := cy + d * 0.5 - 1.0
			var pill := StyleBoxFlat.new()
			pill.bg_color = Color(0.02, 0.03, 0.06, 0.62)
			pill.set_corner_radius_all(8)
			draw_style_box(pill, Rect2(cx - w * 0.5 - 6.0, py, w + 12.0, 17.0))
			draw_string(font, Vector2(cx - w * 0.5, py + 13.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#7a7770") if dead else Color("#ece7dc"))


class Glyph extends Control:
	var kind := ""

	func _draw() -> void:
		var col := Color("#c9a84c")
		var c := size * 0.5
		match kind:
			"moon":
				draw_circle(c, size.x * 0.4, col)
				draw_circle(c + Vector2(size.x * 0.18, -size.x * 0.1), size.x * 0.34, Color(0.05, 0.05, 0.08, 1.0))
			"hour":
				var w := size.x * 0.3
				var h := size.y * 0.42
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w, -h), c + Vector2(w, -h), c, c]), col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w, h), c + Vector2(w, h), c, c]), col)
			"chev":
				draw_colored_polygon(PackedVector2Array([Vector2(2, size.y * 0.3), Vector2(size.x - 2, size.y * 0.3), Vector2(size.x * 0.5, size.y * 0.75)]), col)
			"info":
				draw_arc(c, size.x * 0.42, 0.0, TAU, 24, col, 2.0, true)
				draw_string(ThemeDB.fallback_font, Vector2(c.x - 3.0, c.y + 6.0), "i", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for i: int in 10:
		_faces_g2.append(SP + "echt/face%02d.png" % i)
	for v: String in VILLAGE:
		_faces_vil.append(WK + v + ".png")
	var only := ""
	var sizes := SIZES
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
		elif arg.begins_with("--sizes="):
			var p := arg.trim_prefix("--sizes=").split("x")
			sizes = [Vector2i(int(p[0]), int(p[1]))]
	for size: Vector2i in sizes:
		for v: Dictionary in VARIANTS:
			if only != "" and not str(v["id"]).begins_with(only):
				continue
			await _shoot(OUT + "/P1-%s-%dx%d.png" % [v["id"], size.x, size.y], size, v)
	if only == "" or only == "tokens":
		await _shoot(OUT + "/P1-V2-token-groessentest-1280x800.png", Vector2i(1280, 800), {"id": "tokens", "tokens": true})
	quit(0)


func _tex(path: String, px: int) -> Texture2D:
	var key := "%s@%d" % [path, px]
	if _cache.has(key):
		return _cache[key]
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		printerr("Bild nicht ladbar: ", path)
		return null
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var m := maxi(img.get_width(), img.get_height())
	if m > px:
		var f := float(px) / float(m)
		img.resize(maxi(1, int(img.get_width() * f)), maxi(1, int(img.get_height() * f)), Image.INTERPOLATE_LANCZOS)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


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
	_rects.clear()
	_background(host, Vector2(size))
	if v.get("tokens", false):
		_token_test(host, Vector2(size))
	else:
		_build(host, Vector2(size), v)
	for i: int in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("ok  ", path.get_file(), "  ", image.get_size())
	root.remove_child(host)
	host.free()


func _background(host: Control, size: Vector2) -> void:
	var bg := TextureRect.new()
	bg.texture = _tex(BG_G1, 1920)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float warm = clamp((c.r - c.b) * 2.5, 0.0, 1.0);
	float floor_mask = smoothstep(0.30, 0.48, UV.y);
	vec3 cool = vec3(lum) * vec3(0.78, 0.9, 1.1);
	c.rgb = mix(c.rgb, cool, warm * floor_mask * 0.9);
	c.rgb *= 1.0 - floor_mask * 0.2;
	COLOR = c;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	bg.material = mat
	host.add_child(bg)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color.WHITE
	var sv := Shader.new()
	sv.code = """shader_type canvas_item;
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.58)) / vec2(0.5, 0.46);
	float d = length(p);
	float centre = 1.0 - smoothstep(0.35, 1.0, d);
	float edge = smoothstep(0.95, 1.5, d);
	COLOR = vec4(0.012, 0.02, 0.05, centre * 0.62 + edge * 0.3);
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sv
	shade.material = sm
	host.add_child(shade)


func _build(host: Control, size: Vector2, v: Dictionary) -> void:
	var full: bool = v["bar"] == "full"
	var bar_h := 6.0 + (130.0 if full else 56.0)
	_order_bar(host, size, full)
	_tab(host, "crop-protocol-tab-de", Vector2(0, 0), size, true)
	_tab(host, "crop-options-tab", Vector2(size.x - TAB_W, 0), size, false)
	_clock(host, size)
	_bottom_buttons(host, size)
	var board := Rect2(TAB_W + 10.0, bar_h + 8.0, size.x - 2.0 * (TAB_W + 10.0), size.y - bar_h - 16.0)
	var top_ext := TOKEN_D * 0.5 + 8.0
	var bot_ext := TOKEN_D * 0.5 + 22.0
	var a := board.size.x * 0.5 - 46.0
	var b := (board.size.y - top_ext - bot_ext) * 0.5
	var centre := Vector2(board.get_center().x, board.position.y + top_ext + b)
	var pts := _ring_points(24, centre, a, b)
	var states := {8: "active", 3: "selected", 18: "target", 5: "protected", 10: "poisoned", 14: "marked", 20: "silenced", 12: "dead", 17: "dead"}
	var overlay_files := {"active": "overlay-active", "selected": "overlay-selected", "target": "overlay-target", "protected": "overlay-protected",
		"poisoned": "ring-poisoned", "marked": "ring-marked", "silenced": "ring-silenced", "dead": "overlay-dead"}
	var g2: bool = v["faces"] == "g2"
	var faces := _faces_g2 if g2 else _faces_vil
	var seat_rects: Array[Rect2] = []
	for i: int in 24:
		var n := i + 1
		var t := Token2.new()
		t.d = TOKEN_D
		t.face = _tex(faces[(i * 3) % faces.size()] if g2 else faces[(i * 5) % faces.size()], 200)
		t.frame = _tex(WK + "player-frame-neutral.png", int(TOKEN_D))
		var st: String = states.get(n, "")
		if st != "":
			t.overlay = _tex(WK + overlay_files[st] + ".png", int(TOKEN_D))
		t.dead = st == "dead"
		t.number = str(n)
		t.label_text = NAMES[i]
		t.uv_scale = 0.62 if g2 else 0.74
		t.uv_cy = 0.5 if g2 else 0.42
		t.size = Vector2(96.0, TOKEN_D + 32.0)
		t.position = pts[i] - Vector2(48.0, 10.0 + TOKEN_D * 0.5)
		host.add_child(t)
		seat_rects.append(Rect2(pts[i] - Vector2(46.0, TOKEN_D * 0.5 + 8.0), Vector2(92.0, TOKEN_D + 30.0)))
	if v["card"] == "A":
		_card_a(host, centre, faces, g2)
	else:
		_card_b(host, centre)
	print("ring %s %dx%d: a=%.1f b=%.1f centre=%s board=%s" % [v["id"], int(size.x), int(size.y), a, b, centre, board])
	for k: String in _rects:
		var r: Rect2 = _rects[k]
		var hits := 0
		for sr: Rect2 in seat_rects:
			if r.intersects(sr):
				hits += 1
		print("   %-12s %s: %d Überschneidungen mit Plätzen" % [k, r, hits])


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


func _label(parent: Control, text: String, font_size: int, color: Color, pos: Vector2, w: float, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = align as HorizontalAlignment
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = pos
	l.size = Vector2(w, 0)
	parent.add_child(l)
	return l


func _plate(px_h: int, margin: int) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = _tex(WK + "nightorder-bar-frame.png", px_h * 6)
	var img_h := st.texture.get_height()
	var scale := float(px_h) / float(img_h)
	st.texture_margin_left = float(margin) / scale
	st.texture_margin_right = float(margin) / scale
	st.texture_margin_top = float(margin) / scale
	st.texture_margin_bottom = float(margin) / scale
	return st


func _order_bar(host: Control, size: Vector2, full: bool) -> void:
	var active := 3
	if full:
		var bw := minf(size.x - 2.0 * (TAB_W + 14.0), 840.0)
		var bh := 130.0
		var rect := Rect2((size.x - bw) * 0.5, 6.0, bw, bh)
		var p := Panel.new()
		p.position = rect.position
		p.size = rect.size
		var st := StyleBoxTexture.new()
		st.texture = _tex(WK + "nightorder-bar-frame.png", 700)
		var sc := float(st.texture.get_height()) / 336.0
		st.texture_margin_left = 60.0 * sc
		st.texture_margin_right = 60.0 * sc
		st.texture_margin_top = 50.0 * sc
		st.texture_margin_bottom = 50.0 * sc
		p.add_theme_stylebox_override("panel", st)
		host.add_child(p)
		var slot_h := 84.0
		var pitch := (bw - 90.0) / float(ORDER.size())
		var x0 := rect.position.x + 45.0
		for i: int in ORDER.size():
			var state := "inactive"
			if i < active:
				state = "done"
			elif i == active:
				state = "active"
			var sx := x0 + pitch * (float(i) + 0.5)
			var tex := _tex(SP + "echt2/slot-%s.png" % state, int(slot_h))
			var sw := float(tex.get_width())
			var icon := TextureRect.new()
			icon.texture = _tex(WK + "production-pilot/role-art/night-icons-256/night-icon-%s.webp" % ORDER[i][0], 64)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.size = Vector2(38, 38)
			icon.position = Vector2(sx - 19.0, rect.position.y + 6.0 + slot_h * 0.57 - 19.0)
			icon.modulate = Color(1.6, 1.6, 1.6) if state == "active" else Color(1.45, 1.45, 1.5)
			host.add_child(icon)
			var frame := TextureRect.new()
			frame.texture = tex
			frame.size = Vector2(sw, slot_h)
			frame.position = Vector2(sx - sw * 0.5, rect.position.y + 6.0)
			host.add_child(frame)
			_label(host, str(i + 1), 10, Color("#d9cfb8"), Vector2(sx - 10.0, rect.position.y + 6.0 + slot_h * 0.06), 20.0)
			var lc := RED if state == "active" else (Color("#8f897b") if state == "done" else Color("#b9ae98"))
			_label(host, ORDER[i][1], 11, lc, Vector2(sx - pitch * 0.5 + 2.0, rect.position.y + 6.0 + slot_h - 4.0), pitch - 4.0)
		for side: int in 2:
			var arrow := TextureRect.new()
			arrow.texture = _tex(WK + ("arrow-left.png" if side == 0 else "arrow-right.png"), 40)
			arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			arrow.size = Vector2(26, 26)
			arrow.position = Vector2(rect.position.x + (10.0 if side == 0 else bw - 36.0), rect.position.y + 40.0)
			host.add_child(arrow)
		_rects["order-bar"] = rect
	else:
		var rect := Rect2((size.x - 320.0) * 0.5, 6.0, 320.0, 52.0)
		var p := Panel.new()
		p.position = rect.position
		p.size = rect.size
		var st := StyleBoxTexture.new()
		st.texture = _tex(WK + "nightorder-bar-frame.png", 360)
		var sc := float(st.texture.get_height()) / 336.0
		st.texture_margin_left = 60.0 * sc
		st.texture_margin_right = 60.0 * sc
		st.texture_margin_top = 50.0 * sc
		st.texture_margin_bottom = 50.0 * sc
		p.add_theme_stylebox_override("panel", st)
		host.add_child(p)
		var icon := TextureRect.new()
		icon.texture = _tex(WK + "production-pilot/role-art/night-icons-256/night-icon-%s.webp" % ORDER[active][0], 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(36, 36)
		icon.position = rect.position + Vector2(52, 8)
		host.add_child(icon)
		_label(host, "%d · %s" % [active + 1, ORDER[active][1]], 17, RED, rect.position + Vector2(94, 12), 150.0, HORIZONTAL_ALIGNMENT_LEFT)
		for side: int in 2:
			var arrow := TextureRect.new()
			arrow.texture = _tex(WK + ("arrow-left.png" if side == 0 else "arrow-right.png"), 40)
			arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			arrow.size = Vector2(26, 26)
			arrow.position = rect.position + Vector2(14.0 if side == 0 else 280.0, 13)
			host.add_child(arrow)
		var ch := Glyph.new()
		ch.kind = "chev"
		ch.size = Vector2(16, 16)
		ch.position = rect.position + Vector2(rect.size.x * 0.5 - 8.0, rect.size.y - 12.0)
		host.add_child(ch)
		_rects["order-chip"] = rect


func _tab(host: Control, file: String, pos: Vector2, size: Vector2, left: bool) -> void:
	var tex := _tex(SP + "echt2/%s.png" % file, 400)
	var aspect := float(tex.get_width()) / float(tex.get_height())
	var h := TAB_W / aspect
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = Vector2(TAB_W, h)
	r.position = Vector2(pos.x, size.y * 0.5 - h * 0.5 + 20.0)
	host.add_child(r)
	_rects["tab-left" if left else "tab-right"] = Rect2(r.position, r.size)


func _clock(host: Control, size: Vector2) -> void:
	var rect := Rect2(8, size.y - 8 - 62, 150, 62)
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", _plate(62, 12))
	host.add_child(p)
	var m := Glyph.new()
	m.kind = "moon"
	m.size = Vector2(18, 18)
	m.position = rect.position + Vector2(18, 10)
	host.add_child(m)
	_label(host, "Nacht 2", 16, TEXT, rect.position + Vector2(42, 7), 100.0, HORIZONTAL_ALIGNMENT_LEFT)
	var hg := Glyph.new()
	hg.kind = "hour"
	hg.size = Vector2(18, 18)
	hg.position = rect.position + Vector2(18, 34)
	host.add_child(hg)
	_label(host, "02:45", 16, MUTED, rect.position + Vector2(42, 31), 100.0, HORIZONTAL_ALIGNMENT_LEFT)
	_rects["clock"] = rect


func _bottom_buttons(host: Control, size: Vector2) -> void:
	var next_t := _tex(SP + "echt2/crop-btn-next-step.png", 400)
	var nw := 200.0
	var nh := nw * float(next_t.get_height()) / float(next_t.get_width())
	var nr := Rect2(size.x - 8.0 - nw, size.y - 8.0 - nh, nw, nh)
	var n := TextureRect.new()
	n.texture = next_t
	n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	n.position = nr.position
	n.size = nr.size
	host.add_child(n)
	_label(host, "Nächster Schritt", 15, Color("#ece7dc"), nr.position + Vector2(8, nh * 0.5 - 10.0), nw - 40.0)
	var uw := 118.0
	var uh := 48.0
	var ur := Rect2(nr.position.x - 8.0 - uw, size.y - 8.0 - uh, uw, uh)
	var up := Panel.new()
	up.position = ur.position
	up.size = ur.size
	var ust := StyleBoxTexture.new()
	ust.texture = _tex(SP + "echt2/crop-btn-undo.png", 360)
	var us := float(ust.texture.get_height()) / 346.0
	ust.texture_margin_left = 150.0 * us
	ust.texture_margin_right = 150.0 * us
	up.add_theme_stylebox_override("panel", ust)
	host.add_child(up)
	_label(host, "Rückgängig", 13, MUTED, ur.position + Vector2(20, uh * 0.5 - 9.0), uw - 24.0)
	_rects["next"] = nr
	_rects["undo"] = ur
	print("   Tippfläche Nächster Schritt %.0fx%.0f, Rückgängig %.0fx%.0f" % [nr.size.x, nr.size.y, ur.size.x, ur.size.y])


## Variant A: like Spielfeld.png: role art in the oval frame, title, one line, target slot.
func _card_a(host: Control, centre: Vector2, faces: Array[String], g2: bool) -> void:
	var cw := 236.0
	var ch := 352.0
	var origin := centre - Vector2(cw * 0.5, ch * 0.5) + Vector2(0, 4)
	var art := TextureRect.new()
	art.texture = _tex(WK + "production-pilot/role-art/portraits-512/portrait-werwolf.webp", 512)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = origin + Vector2(cw * 0.15, ch * 0.06)
	art.size = Vector2(cw * 0.70, ch * 0.58)
	var msk := Shader.new()
	msk.code = "shader_type canvas_item;
void fragment() { vec4 c = texture(TEXTURE, UV); float d = length((UV - vec2(0.5)) / vec2(0.5)); COLOR = vec4(c.rgb, c.a * (1.0 - smoothstep(0.96, 1.0, d))); }"
	var mm := ShaderMaterial.new()
	mm.shader = msk
	art.material = mm
	host.add_child(art)
	var fade := ColorRect.new()
	fade.position = art.position + Vector2(0, art.size.y * 0.55)
	fade.size = Vector2(art.size.x, art.size.y * 0.45)
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() { float e = 1.0 - smoothstep(0.96, 1.0, length((vec2(UV.x, 0.55 + UV.y * 0.45) - vec2(0.5)) / vec2(0.5))); COLOR = vec4(0.03, 0.02, 0.04, smoothstep(0.0, 0.85, UV.y) * 0.93 * e); }"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	fade.material = mat
	fade.color = Color.WHITE
	host.add_child(fade)
	var frame := TextureRect.new()
	frame.texture = _tex(SP + "echt2/crop-action-frame-night.png", int(ch * 1.0))
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.position = origin
	frame.size = Vector2(cw, ch)
	host.add_child(frame)
	_label(host, "WERWOLF", 22, RED, origin + Vector2(0, ch * 0.405), cw)
	_label(host, "Wähle 1 Spieler", 15, TEXT, origin + Vector2(0, ch * 0.5), cw)
	var info := Glyph.new()
	info.kind = "info"
	info.size = Vector2(26, 26)
	info.position = origin + Vector2(cw - 44.0, 14.0)
	host.add_child(info)
	var zr := Rect2(origin + Vector2(cw * 0.06, ch * 0.66), Vector2(cw * 0.88, ch * 0.3))
	var zp := Panel.new()
	zp.position = zr.position
	zp.size = zr.size
	zp.add_theme_stylebox_override("panel", _plate(int(zr.size.y), 10))
	host.add_child(zp)
	var tk := Token2.new()
	tk.d = 50.0
	tk.face = _tex(faces[(17 * 3) % faces.size()] if g2 else faces[(17 * 5) % faces.size()], 200)
	tk.frame = _tex(WK + "player-frame-neutral.png", 50)
	tk.overlay = _tex(WK + "overlay-target.png", 50)
	tk.uv_scale = 0.62 if g2 else 0.74
	tk.uv_cy = 0.5 if g2 else 0.42
	tk.size = Vector2(96, 70)
	tk.position = zr.position + Vector2(zr.size.x * 0.5 - 48.0, 2.0)
	host.add_child(tk)
	_label(host, "Rosa · Ziel", 12, MUTED, zr.position + Vector2(0, zr.size.y - 20.0), zr.size.x)
	for side: int in 2:
		var arrow := TextureRect.new()
		arrow.texture = _tex(WK + ("arrow-left.png" if side == 0 else "arrow-right.png"), 40)
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.size = Vector2(26, 26)
		arrow.position = zr.position + Vector2(10.0 if side == 0 else zr.size.x - 36.0, zr.size.y * 0.3)
		host.add_child(arrow)
	_rects["card-A"] = Rect2(origin, Vector2(cw, ch))


## Variant B: compact G3 frame, title, one line, target chip, "Mehr". Confirmation lives in "Nächster Schritt".
func _card_b(host: Control, centre: Vector2) -> void:
	var w := 340.0
	var h := 150.0
	var p := Panel.new()
	p.size = Vector2(w, h)
	p.position = centre - Vector2(w * 0.5, h * 0.5)
	var st := StyleBoxTexture.new()
	st.texture = _tex(SP + "echt/frame.png", 400)
	st.texture_margin_left = 46
	st.texture_margin_right = 46
	st.texture_margin_top = 46
	st.texture_margin_bottom = 46
	p.add_theme_stylebox_override("panel", st)
	host.add_child(p)
	_label(host, "Werwolf", 24, RED, p.position + Vector2(0, 24), w)
	_label(host, "Wähle 1 Spieler", 16, TEXT, p.position + Vector2(0, 62), w)
	_label(host, "Ziel: Rosa", 15, GOLD, p.position + Vector2(0, 88), w)
	var more := Button.new()
	more.text = "Mehr"
	more.custom_minimum_size = Vector2(76, 48)
	more.size = Vector2(76, 48)
	more.position = p.position + Vector2(w - 76.0 - 40.0, h - 46.0 - 12.0)
	host.add_child(more)
	_rects["card-B"] = Rect2(p.position, p.size)


## Token size test: states x sizes on the real background.
func _token_test(host: Control, size: Vector2) -> void:
	var states := [["Normal", ""], ["Aktiv", "overlay-active"], ["Ausgewählt", "overlay-selected"], ["Ziel", "overlay-target"], ["Geschützt", "overlay-protected"],
		["Vergiftet", "ring-poisoned"], ["Markiert", "ring-marked"], ["Stumm", "ring-silenced"], ["Tot", "overlay-dead"]]
	var sizes := [88, 72, 64, 56, 48, 40]
	var y := 8.0
	for row: int in sizes.size():
		var d: int = sizes[row]
		_label(host, "Ø %d px" % d, 14, GOLD, Vector2(8, y + float(d) * 0.4), 60.0, HORIZONTAL_ALIGNMENT_LEFT)
		for col: int in states.size():
			var t := Token2.new()
			t.d = float(d)
			t.face = _tex(_faces_g2[(row * 3 + col * 7) % _faces_g2.size()], 200)
			t.frame = _tex(WK + "player-frame-neutral.png", d)
			if states[col][1] != "":
				t.overlay = _tex(WK + states[col][1] + ".png", d)
			t.dead = states[col][0] == "Tot"
			t.number = str(col + 1)
			t.label_text = states[col][0] if d >= 48 else ""
			t.size = Vector2(110, float(d) + 34.0)
			t.position = Vector2(70.0 + float(col) * 128.0, y)
			host.add_child(t)
		y += float(d) + 36.0
