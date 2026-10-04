class_name SelectionGlow
extends Control
## Weiches rotes Glühen für „ausgewählt“ in der Vorbereitung. Es folgt der Form eines Hain-Teils: Aus den Alpha-Kanten der Textur
## (card_frame, button_*, name_plate_*) wird einmal ein weichgezeichnetes Schein-Bild berechnet (Rand um `PAD` erweitert, außerhalb der
## Form stark, innen kaum) und wie das Teil als Neun-Felder-Raster gezeichnet. Ein kleiner Shader färbt es blutrot und lässt es etwa
## alle zwei Sekunden sanft pulsieren. Das Glühen liegt hinter dem Rahmen (`show_behind_parent`) und fängt keine Eingaben ab.

const PAD := 14.0                  ## so weit reicht der Schein über die Fläche hinaus (logische Einheiten)
const DOWNSCALE := 4               ## Rechenauflösung: Der Schein ist weich, ein Viertel genügt (schnell auch im Browser)
const BLUR_RADIUS := 3             ## Rechenpixel je Durchgang
const PASSES := 4
const SHADER := """
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(0.82, 0.1, 0.14, 1.0);
uniform float period = 2.0;
uniform float strength = 0.55;
void fragment() {
	float a = texture(TEXTURE, UV).a;
	float pulse = 0.78 + 0.22 * sin(TIME * 6.28318 / period);
	COLOR = vec4(glow_color.rgb, clamp(a * pulse * strength, 0.0, 1.0));
}
"""

static var _textures: Dictionary = {}
static var _shader: Shader = null

var _box: GroveStyleBox = null


## `part`: Name des Hain-Teils, `margins`: dessen Neun-Felder-Ränder (GroveArtData).
## `inset`: Abstand der geglühten Form zum Rand des Trägers (links, oben, rechts, unten).
## `color`: Farbe des Glühens, ohne Angabe (Alpha 0) das Blutrot des Shaders.
static func create(part: String, margins: Vector4, inset: Vector4 = Vector4.ZERO, color: Color = ThemeTokens.INVISIBLE) -> SelectionGlow:
	var glow := SelectionGlow.new()
	glow.name = "SelectionGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.show_behind_parent = true
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = inset.x - PAD
	glow.offset_top = inset.y - PAD
	glow.offset_right = PAD - inset.z
	glow.offset_bottom = PAD - inset.w
	var tex := _glow_texture(part)
	if tex != null:
		var grown := Vector4.ONE * PAD * GroveArtData.TEXTURE_SCALE
		glow._box = GroveStyleBox.make(tex, margins + grown)
		glow.material = _material()
		if color.a > 0.0:
			(glow.material as ShaderMaterial).set_shader_parameter("glow_color", color)
	glow.visible = false
	return glow


## Hängt ein Glühen an `host` (einmal) und schaltet es; ohne Bild (Teil fehlt) bleibt es unsichtbar.
static func set_on(host: Control, part: String, margins: Vector4, on: bool, inset: Vector4 = Vector4.ZERO, color: Color = ThemeTokens.INVISIBLE) -> void:
	var glow := host.get_node_or_null("SelectionGlow") as SelectionGlow
	if glow == null:
		if not on:
			return
		glow = create(part, margins, inset, color)
		host.add_child(glow)
	glow.visible = on and glow._box != null


func _draw() -> void:
	if _box != null:
		draw_style_box(_box, Rect2(Vector2.ZERO, size))


static func _material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	return m


static func _glow_texture(part: String) -> Texture2D:
	if _textures.has(part):
		return _textures[part]
	var source := GroveSkin.texture(part)
	var result: Texture2D = null
	if source != null:
		var img := source.get_image()
		if img != null:
			result = ImageTexture.create_from_image(_blurred(img))
	_textures[part] = result
	return result


## Alpha des Teils, um den Schein-Rand erweitert und weichgezeichnet; innerhalb der Form stark abgeschwächt (Schein liegt hinter dem Rahmen).
static func _blurred(src: Image) -> Image:
	var pad := int(PAD * GroveArtData.TEXTURE_SCALE)
	var full_w := src.get_width() + pad * 2
	var full_h := src.get_height() + pad * 2
	var small := src.duplicate() as Image
	small.convert(Image.FORMAT_RGBA8)
	small.resize(maxi(1, src.get_width() / DOWNSCALE), maxi(1, src.get_height() / DOWNSCALE), Image.INTERPOLATE_BILINEAR)
	var pad_s := pad / DOWNSCALE
	var w := small.get_width() + pad_s * 2
	var h := small.get_height() + pad_s * 2
	var original := PackedFloat32Array()
	original.resize(w * h)
	for y: int in small.get_height():
		for x: int in small.get_width():
			original[(y + pad_s) * w + x + pad_s] = small.get_pixel(x, y).a
	var a := original.duplicate()
	for pass_index: int in PASSES:
		a = _box_blur(a, w, h, true)
		a = _box_blur(a, w, h, false)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in h:
		for x: int in w:
			var i := y * w + x
			var alpha := clampf(a[i] * 1.25, 0.0, 1.0) * (1.0 - 0.9 * original[i])
			var pixel := ThemeTokens.TINT_NONE
			pixel.a = alpha
			out.set_pixel(x, y, pixel)
	out.resize(full_w, full_h, Image.INTERPOLATE_BILINEAR)
	return out


static func _box_blur(data: PackedFloat32Array, w: int, h: int, horizontal: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(w * h)
	var lines := h if horizontal else w
	var length := w if horizontal else h
	var window := float(BLUR_RADIUS * 2 + 1)
	for line: int in lines:
		var sum := 0.0
		for k: int in range(-BLUR_RADIUS, BLUR_RADIUS + 1):
			sum += _at(data, w, line, k, length, horizontal)
		for pos: int in length:
			var index := line * w + pos if horizontal else pos * w + line
			out[index] = sum / window
			sum += _at(data, w, line, pos + BLUR_RADIUS + 1, length, horizontal) - _at(data, w, line, pos - BLUR_RADIUS, length, horizontal)
	return out


static func _at(data: PackedFloat32Array, w: int, line: int, pos: int, length: int, horizontal: bool) -> float:
	if pos < 0 or pos >= length:
		return 0.0
	return data[line * w + pos] if horizontal else data[pos * w + line]
