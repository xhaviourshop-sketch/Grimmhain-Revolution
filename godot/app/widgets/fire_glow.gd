class_name FireGlow
extends Control
## Lodernde Flammen statt gleichmäßigem Glühen für den gewählten Akt (Testrunde 1). Wie `SelectionGlow` folgt der Schein der Form eines
## Hain-Teils (weichgezeichnete Alpha-Kanten als Neun-Felder-Raster hinter dem Rahmen), aber ein Shader lässt ihn mit Rauschen flackern und nach
## oben züngeln, dazu wenige Funken (CPUParticles2D, höchstens 40 Teilchen). Die Stärke wächst linear mit der Stufe des Aktes (Akt II doppelt, III dreifach, IV vierfach, siehe unten). Nicht gewählt: kein Knoten sichtbar, keine Teilchen. Bei reduzierter Bewegung steht die
## Flamme still und es gibt keine Funken. Fängt keine Eingaben ab.

const MAX_SPARKS := 40
## Stärke je Stufe als Vielfaches von Akt I (Feedback 5): Akt II doppelt, Akt III dreifach, Akt IV vierfach (Reichweite = Flammenhöhe und Fläche,
## Hitze, Helligkeit, Bewegung, Funkenzahl). Funken steigen langsam und treiben leicht zur Seite.
const BASE_REACH := 28.0  ## Reichweite über den Rahmen in logischen Einheiten bei Stufe 1
const MAX_REACH := 16.0   ## Obergrenze der Reichweite (Feedback 8): das Feuer bleibt an seiner Karte und läuft nicht in die Nachbarkarte
const BASE_STRENGTH := 1.0
const BASE_BRIGHT := 0.4
const BASE_AMP := 0.35
const BASE_SPEED := 0.7
const BASE_SPARKS := 8
const SPARK_SPEED := Vector2(14.0, 30.0)  ## Funkentempo bei Stufe 1 (kleinste, größte); höhere Stufen steigen etwas schneller
const SPARK_LIFETIME := 3.0
const SPARK_SCALE := Vector2(0.05, 0.1)  ## Größe im Verhältnis zum weichen Glühbild (128 Pixel)
## Stile: Farben je Stufe I bis IV und Besonderheiten. `ghost`: blaues Geisterfeuer. `ember`: Glut mit Rauch (ruhiger, rote Glut, graue Rauchfahnen).
## Standard (DA-101): Akt I bis III `fire`, Akt IV `ghost` mit denselben Stärkewerten der Stufe 4.
const STYLES := {
	&"fire": {"flame": ThemeTokens.FIRE_FLAME, "core": ThemeTokens.FIRE_CORE, "calm": 1.0, "dim": 1.0, "lift": 1.0, "smoke": false},
	&"ghost": {"flame": ThemeTokens.FIRE_GHOST_FLAME, "core": ThemeTokens.FIRE_GHOST_CORE, "calm": 1.0, "dim": 0.38, "lift": 1.0, "smoke": false, "soften": 0.6},
	&"ember": {"flame": ThemeTokens.FIRE_EMBER_FLAME, "core": ThemeTokens.FIRE_EMBER_CORE, "calm": 0.45, "dim": 0.6, "lift": 0.25, "smoke": true},
}
static var style: StringName = &"fire"  ## aktiver Stil; nur das Screenshot-Werkzeug stellt ihn um
const TOP_LEVEL_STYLE := &"ghost"  ## Stil der höchsten Stufe (Akt IV), solange der Standardstil `fire` gilt
const SHADER := """
shader_type canvas_item;
uniform vec4 flame_color : source_color = vec4(1.0, 0.3, 0.05, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.75, 0.25, 1.0);
uniform float strength = 1.0;
uniform float amp = 0.5;
uniform float speed = 1.0;
uniform float animate = 1.0;
uniform float bright = 1.0;
uniform float lift = 0.0;  // Flammenhöhe als Anteil der Bildhöhe
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
	float t = TIME * speed * animate;
	vec2 p = FRAGCOORD.xy * vec2(0.045, 0.028);
	float n = fbm(vec2(p.x, p.y + t * 1.6)) + 0.35 * fbm(vec2(p.x * 1.7 + 4.0, p.y * 1.3 + t * 2.4));
	n = clamp(n / 1.35, 0.0, 1.0);
	// Zungen: die Flamme liest den Schein von weiter unten ab, je nach Rauschen verschieden hoch (so wächst sie über den Rahmen hinaus nach oben).
	float tongue_noise = noise(vec2(FRAGCOORD.x * 0.035, t * 1.1));
	float off = lift * (0.2 + 0.8 * n * (0.5 + 0.5 * tongue_noise));
	float a = max(texture(TEXTURE, UV).a, max(texture(TEXTURE, UV + vec2(0.0, off * 0.5)).a * 0.9, texture(TEXTURE, UV + vec2(0.0, off)).a * 0.75));
	float heat = a * strength;  // nah am Rahmen heißer, nach außen kühler
	float tongue = heat * (1.0 - amp * 0.6 + amp * 1.6 * n);  // das Rauschen bestimmt, wie weit die Zungen reichen
	float k = smoothstep(0.12, 0.5, tongue);
	float haze = clamp(a * 0.3 * strength, 0.0, 0.45);
	vec3 col = mix(flame_color.rgb, core_color.rgb, smoothstep(0.7, 2.4, tongue)) * (0.7 + 0.3 * bright);
	COLOR = vec4(col, clamp(max(k, haze) * bright, 0.0, 1.0));
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
var _smoke: CPUParticles2D = null


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
	var params := _params(fire.level)
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
		fire.material = _material(params, reach * density * 0.6 * float(params["lift"]) / float(tex.get_height()))
	fire._build_sparks(params)
	fire.visible = false
	return fire


## Werte einer Stufe (1 bis 4) im aktiven Stil: jede Größe wächst linear mit der Stufe, Akt IV ist also viermal so stark wie Akt I.
static func _params(p_level: int) -> Dictionary:
	var l := float(clampi(p_level, 1, 4))
	var active := TOP_LEVEL_STYLE if style == &"fire" and int(l) == 4 else style
	var def: Dictionary = STYLES[active] if STYLES.has(active) else STYLES[&"fire"]
	var calm := float(def["calm"])
	var flame: Color = (def["flame"] as Array)[int(l) - 1]
	var core: Color = (def["core"] as Array)[int(l) - 1]
	core = core.lerp(flame, float(def.get("soften", 0.0)))  # kein weißer Kern: das Geisterfeuer soll nicht grell sein
	return {"reach": minf(BASE_REACH * l, MAX_REACH), "strength": BASE_STRENGTH * l, "bright": BASE_BRIGHT * l * float(def["dim"]), "lift": float(def["lift"]), "amp": BASE_AMP * l * calm, "speed": BASE_SPEED * l * calm,
		"sparks": BASE_SPARKS * int(l), "velocity": SPARK_SPEED * (0.75 + 0.25 * l), "smoke": bool(def["smoke"]),
		"flame": flame, "core": core}


static func _material(params: Dictionary, lift: float) -> ShaderMaterial:
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
	m.set_shader_parameter("bright", params["bright"])
	m.set_shader_parameter("lift", lift)
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
	_sparks.lifetime_randomness = 0.6
	_sparks.emitting = false
	_sparks.direction = Vector2.UP
	_sparks.spread = 28.0
	_sparks.gravity = Vector2(0.0, -6.0)
	var velocity: Vector2 = params["velocity"]
	_sparks.initial_velocity_min = velocity.x
	_sparks.initial_velocity_max = velocity.y
	_sparks.damping_min = 4.0  # bremst die Funken ab, sie schweben statt zu schießen
	_sparks.damping_max = 10.0
	_sparks.tangential_accel_min = -6.0  # leichtes Treiben zur Seite, keine Kreisbahnen
	_sparks.tangential_accel_max = 6.0
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
	if bool(params["smoke"]):
		_smoke = CPUParticles2D.new()
		_smoke.name = "Smoke"
		_smoke.amount = count
		_smoke.lifetime = 5.0
		_smoke.lifetime_randomness = 0.4
		_smoke.emitting = false
		_smoke.direction = Vector2.UP
		_smoke.spread = 18.0
		_smoke.gravity = Vector2(0.0, -4.0)
		_smoke.initial_velocity_min = 8.0
		_smoke.initial_velocity_max = 20.0
		_smoke.scale_amount_min = 0.5
		_smoke.scale_amount_max = 1.0
		_smoke.texture = StartBackdrop.glow_texture()
		_smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		var puff := Gradient.new()
		puff.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		puff.colors = PackedColorArray([ThemeTokens.SMOKE_EDGE, ThemeTokens.SMOKE_MID, ThemeTokens.SMOKE_END])
		_smoke.color_ramp = puff
		add_child(_smoke)
	resized.connect(_place_sparks)
	_place_sparks()


## Funken steigen aus der ganzen Oberkante des Rahmens auf.
func _place_sparks() -> void:
	if _sparks == null:
		return
	_sparks.position = Vector2(size.x * 0.5, offset_top * -1.0 + 4.0)
	_sparks.emission_rect_extents = Vector2(maxf(size.x * 0.5 - 20.0, 4.0), 3.0)
	if _smoke != null:
		_smoke.position = _sparks.position
		_smoke.emission_rect_extents = _sparks.emission_rect_extents


func _apply_motion() -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("animate", 1.0 if animated else 0.0)
	if _sparks != null:
		_sparks.emitting = visible and animated
	if _smoke != null:
		_smoke.emitting = visible and animated
