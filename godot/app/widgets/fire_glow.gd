class_name FireGlow
extends Control
## Lodernde Flammen statt gleichmäßigem Glühen für den gewählten Akt (Testrunde 1). Wie `SelectionGlow` folgt der Schein der Form eines
## Hain-Teils (weichgezeichnete Alpha-Kanten als Neun-Felder-Raster hinter dem Rahmen), aber ein Shader lässt ihn mit Rauschen flackern und nach
## oben züngeln, dazu wenige Funken (CPUParticles2D, höchstens 60 Teilchen). Die Stärke steigt mit der Stufe des Aktes: schon Akt 1 lodert kräftig mit Funken (Rückmeldung iPad-Test), danach
## mehr Glut, höhere Flammen, unruhigeres Flackern und mehr Funken; Akt 4 ist am stärksten. Nicht gewählt: kein Knoten sichtbar, keine Teilchen. Bei reduzierter Bewegung steht die
## Flamme still und es gibt keine Funken. Fängt keine Eingaben ab.

const MAX_SPARKS := 60
## Je Stufe: Stärke, Rauschanteil, Tempo, Reichweite über den Rahmen (logische Einheiten), Funken, Funkentempo (kleinste, größte), Flammenfarbe, Kernfarbe
const LEVELS := {
	1: {"strength": 1.6, "amp": 1.0, "speed": 2.6, "reach": 34.0, "sparks": 28, "velocity": Vector2(60.0, 130.0), "flame": ThemeTokens.FIRE_FLAME[0], "core": ThemeTokens.FIRE_CORE[0]},
	2: {"strength": 1.9, "amp": 1.15, "speed": 3.2, "reach": 42.0, "sparks": 36, "velocity": Vector2(75.0, 160.0), "flame": ThemeTokens.FIRE_FLAME[1], "core": ThemeTokens.FIRE_CORE[1]},
	3: {"strength": 2.2, "amp": 1.3, "speed": 3.9, "reach": 50.0, "sparks": 46, "velocity": Vector2(90.0, 190.0), "flame": ThemeTokens.FIRE_FLAME[2], "core": ThemeTokens.FIRE_CORE[2]},
	4: {"strength": 2.6, "amp": 1.5, "speed": 4.6, "reach": 58.0, "sparks": 60, "velocity": Vector2(110.0, 230.0), "flame": ThemeTokens.FIRE_FLAME[3], "core": ThemeTokens.FIRE_CORE[3]},
}
const SPARK_LIFETIME := 1.3
const SPARK_SCALE := Vector2(0.05, 0.1)  ## Größe im Verhältnis zum weichen Glühbild (128 Pixel)
const SHADER := """
shader_type canvas_item;
uniform vec4 flame_color : source_color = vec4(1.0, 0.3, 0.05, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.75, 0.25, 1.0);
uniform float strength = 1.0;
uniform float amp = 0.5;
uniform float speed = 1.0;
uniform float animate = 1.0;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	return noise(p) * 0.6 + noise(p * 2.1 + 7.3) * 0.3 + noise(p * 4.3 + 3.1) * 0.1;
}
void fragment() {
	float a = texture(TEXTURE, UV).a;
	float t = TIME * speed * animate;
	vec2 p = FRAGCOORD.xy * vec2(0.045, 0.028);
	float n = fbm(vec2(p.x, p.y + t * 1.6)) + 0.35 * fbm(vec2(p.x * 1.7 + 4.0, p.y * 1.3 + t * 2.4));
	n = clamp(n / 1.35, 0.0, 1.0);
	float heat = a * strength;  // nah am Rahmen heißer, nach außen kühler
	float tongue = heat * (1.0 - amp * 0.6 + amp * 1.6 * n);  // das Rauschen bestimmt, wie weit die Zungen reichen
	float k = smoothstep(0.12, 0.5, tongue);
	float haze = clamp(a * 0.3 * strength, 0.0, 0.45);
	vec3 col = mix(flame_color.rgb, core_color.rgb, smoothstep(0.35, 0.95, tongue));
	COLOR = vec4(col, clamp(max(k, haze), 0.0, 1.0));
}
"""

static var _shader: Shader = null

var level: int = 1
var animated: bool = true:
	set(value):
		animated = value
		_apply_motion()
var _box: GroveStyleBox = null
var _sparks: CPUParticles2D = null


## Hängt (einmal) ein Feuer an `host` und schaltet es. `part`/`margins`: Hain-Teil und dessen Neun-Felder-Ränder wie bei `SelectionGlow`.
static func set_on(host: Control, part: String, margins: Vector4, on: bool, p_level: int, p_animated: bool = true) -> void:
	var fire := host.get_node_or_null("FireGlow") as FireGlow
	if fire == null:
		if not on:
			return
		fire = create(part, margins, p_level)
		host.add_child(fire)
	fire.animated = p_animated
	fire.visible = on and fire._box != null
	fire._apply_motion()


static func create(part: String, margins: Vector4, p_level: int) -> FireGlow:
	var fire := FireGlow.new()
	fire.name = "FireGlow"
	fire.level = clampi(p_level, 1, 4)
	fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire.show_behind_parent = true
	var params: Dictionary = LEVELS[fire.level]
	var reach := float(params["reach"])
	fire.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fire.offset_left = -reach
	fire.offset_top = -reach
	fire.offset_right = reach
	fire.offset_bottom = reach
	var density := GroveArtData.TEXTURE_SCALE
	var tex := SelectionGlow.glow_texture_for(part, density, reach)
	if tex != null:
		fire._box = GroveStyleBox.make(tex, margins + Vector4.ONE * reach * density)
		fire._box.px_per_unit = density
		fire.material = _material(params)
	fire._build_sparks(params)
	fire.visible = false
	return fire


static func _material(params: Dictionary) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("flame_color", params["flame"])
	m.set_shader_parameter("core_color", params["core"])
	m.set_shader_parameter("strength", params["strength"])
	m.set_shader_parameter("amp", params["amp"])
	m.set_shader_parameter("speed", params["speed"])
	return m


func _draw() -> void:
	if _box != null:
		draw_style_box(_box, Rect2(Vector2.ZERO, size))


func _build_sparks(params: Dictionary) -> void:
	var count := mini(int(params["sparks"]), MAX_SPARKS)
	if count <= 0:
		return
	_sparks = CPUParticles2D.new()
	_sparks.name = "Sparks"
	_sparks.amount = count
	_sparks.lifetime = SPARK_LIFETIME
	_sparks.emitting = false
	_sparks.direction = Vector2.UP
	_sparks.spread = 35.0
	_sparks.gravity = Vector2(0.0, -25.0)
	var velocity: Vector2 = params["velocity"]
	_sparks.initial_velocity_min = velocity.x
	_sparks.initial_velocity_max = velocity.y
	_sparks.scale_amount_min = SPARK_SCALE.x
	_sparks.scale_amount_max = SPARK_SCALE.y
	_sparks.texture = StartBackdrop.glow_texture()
	_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparks.emission_rect_extents = Vector2(40.0, 3.0)
	var fade := Gradient.new()
	var warm: Color = params["core"]
	var cool: Color = params["flame"]
	cool.a = 0.0
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	fade.colors = PackedColorArray([warm, cool])
	_sparks.color_ramp = fade
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sparks.material = additive
	add_child(_sparks)
	resized.connect(_place_sparks)
	_place_sparks()


## Funken steigen aus der ganzen Oberkante des Rahmens auf.
func _place_sparks() -> void:
	if _sparks == null:
		return
	_sparks.position = Vector2(size.x * 0.5, offset_top * -1.0 + 4.0)
	_sparks.emission_rect_extents = Vector2(maxf(size.x * 0.5 - 20.0, 4.0), 3.0)


func _apply_motion() -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("animate", 1.0 if animated else 0.0)
	if _sparks != null:
		_sparks.emitting = visible and animated
