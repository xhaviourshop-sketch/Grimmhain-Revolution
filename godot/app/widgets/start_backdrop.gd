class_name StartBackdrop
extends Control
## Lebendiger Hintergrund von Startbildschirm und Hauptmenü (DA-92), in Ebenen und mit einfachen Mitteln (kein Partikelsystem):
##   Bühne     start-hintergrund füllt den Bildschirm (cover, Ausschnitt oben bevorzugt), sehr langsamer Zoom 1,00 bis 1,04 hin und zurück
##   Mond      weiches additives Glühen, das atmet (Position im Bild gemessen)
##   Nebel     zwei Bänder aus start-nebel, unterschiedlich schnell nach links, nahtlos wiederholt, unten stärker
##   Augen     zwei rote Glutpunkte im Dunkel am Rand, blenden alle 8 bis 15 Sekunden etwa 1,5 Sekunden auf (nur Startbildschirm)
##   Schimmer  ganz selten ein sehr dezentes Aufhellen wie fernes Wetterleuchten (nur Startbildschirm)
##   Abdunklung `darkness` (Hauptmenü stärker), Randdämpfung, `fog_close` zieht den Nebel zu.
## Bei reduzierter Bewegung steht alles still. Reine Dekoration, kein Mausfang.

enum Mode { START, MENU }

const ART := "res://assets/start/start-hintergrund.webp"
const FOG := "res://assets/start/start-nebel.webp"
const IMAGE_SIZE := Vector2(1536.0, 1024.0)
const MOON_AT := Vector2(0.498, 0.086)    ## Mondmitte als Anteil des Bildes
const MOON_RADIUS := 0.058                 ## Mondradius als Anteil der Bildbreite
const EYES_AT: Array[Vector2] = [Vector2(0.123, 0.449), Vector2(0.15, 0.449)]  ## dunkle Wurzelhöhle links, im 4:3-Ausschnitt sichtbar
const VERTICAL_BIAS := 0.3                 ## 0 = Oberkante, 1 = Unterkante des Bildes bleibt sichtbar, wenn der Bildschirm flacher ist
const ZOOM_TO := 1.04
const ZOOM_SECONDS := 30.0
const EYES_PERIOD := Vector2(8.0, 15.0)
const EYES_FIRST := Vector2(3.0, 5.0)     ## das erste Aufblenden kommt früh, damit man die Augen kennenlernt
const FOG_OPEN_SECONDS := 0.8
const FLASH_PERIOD := Vector2(20.0, 40.0)

var mode: Mode = Mode.START
var animated: bool = true
var darkness: float = 0.0:
	set(value):
		darkness = value
		if _shade != null:
			_shade.color.a = value

var _stage: Control
var _moon: TextureRect
var _eyes: Array[TextureRect] = []
var _flash: ColorRect
var _shade: ColorRect
var _cover: ColorRect
var _fog_layers: Array[FogLayer] = []
var _closing: bool = false

## Vom Startbildschirm gesetzt: das nächste Hauptmenü-Backdrop taucht aus dem Nebel auf (einmalig).
static var fog_open_pending: bool = false


static func glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	var clear := ThemeTokens.TINT_NONE
	clear.a = 0.0
	var soft := ThemeTokens.TINT_NONE
	soft.a = 0.35
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([ThemeTokens.TINT_NONE, soft, clear])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


func _init(p_mode: Mode = Mode.START) -> void:
	mode = p_mode
	name = "StartBackdrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	darkness = 0.0 if mode == Mode.START else 0.6


func _ready() -> void:
	var base := ColorRect.new()
	base.name = "BackdropBase"
	base.color = ThemeTokens.START_SHADE
	_fill(base)
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = load(ART) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(art)
	_moon = _glow("MoonGlow", ThemeTokens.START_MOON_GLOW)
	if mode == Mode.START:
		for i: int in EYES_AT.size():
			var eye := _glow("Eye_%d" % i, ThemeTokens.START_EYES)
			eye.modulate.a = 0.0
			_eyes.append(eye)
	var fog_tex := load(FOG) as Texture2D
	_fog_layers.append(_fog_layer("FogFar", fog_tex, 0.74, 0.62, 0.2, -14.0, 0.0))
	_fog_layers.append(_fog_layer("FogNear", fog_tex, 0.9, 1.0, 0.3, -26.0, 700.0))
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.color = ThemeTokens.START_FLASH
	_flash.color.a = 0.0
	_flash.material = _additive()
	_fill(_flash)
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = ThemeTokens.START_SHADE
	_shade.color.a = darkness
	_fill(_shade)
	var edge := ColorRect.new()
	edge.name = "Vignette"
	var edge_material := ShaderMaterial.new()
	edge_material.shader = load("res://app/theme/night_vignette.gdshader") as Shader
	edge.material = edge_material
	_fill(edge)
	_cover = ColorRect.new()
	_cover.name = "FogCover"
	_cover.color = ThemeTokens.START_FOG_CLOSE
	_cover.color.a = 0.0
	_fill(_cover)
	resized.connect(_layout)
	_layout()
	if animated:
		_start_motion()
		if mode == Mode.MENU and fog_open_pending:
			fog_open_pending = false
			_fog_open(FOG_OPEN_SECONDS)
	else:
		fog_open_pending = false


## Bewegung an oder aus (reduzierte Bewegung). Vor dem Einhängen aufrufen.
func set_animated(on: bool) -> void:
	animated = on
	for layer: FogLayer in _fog_layers:
		layer.set_process(on)


## Nebel zieht zu (Übergang vom Startbildschirm ins Hauptmenü); wartet die Dauer ab. Ohne Bewegung sofort.
func fog_close(seconds: float = 0.6) -> void:
	if _closing:
		return
	_closing = true
	if not animated or not is_inside_tree():
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_cover, "color:a", 0.94, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for layer: FogLayer in _fog_layers:
		tween.tween_property(layer, "alpha", minf(layer.alpha * 2.6, 0.95), seconds)
	await tween.finished


## Hauptmenü taucht aus dem Nebel auf: Decke und Nebelbänder starten dicht und lichten sich.
func _fog_open(seconds: float) -> void:
	_cover.color.a = 0.94
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_cover, "color:a", 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for layer: FogLayer in _fog_layers:
		var target := layer.alpha
		layer.alpha = minf(target * 2.6, 0.95)
		tween.tween_property(layer, "alpha", target, seconds)


func _glow(node_name: String, color: Color) -> TextureRect:
	var glow := TextureRect.new()
	glow.name = node_name
	glow.texture = glow_texture()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.self_modulate = color
	glow.material = _additive()
	_stage.add_child(glow)
	return glow


static func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _fog_layer(node_name: String, tex: Texture2D, y_at: float, scale_factor: float, alpha: float, speed: float, start: float) -> FogLayer:
	var layer := FogLayer.new()
	layer.name = node_name
	layer.texture = tex
	layer.y_at = y_at
	layer.scale_factor = scale_factor
	layer.alpha = alpha
	layer.speed = speed
	layer.offset = start
	layer.set_process(animated)
	_fill(layer)
	return layer


func _fill(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(node)


## Bühne: Bild füllt den Bildschirm (cover); Mond und Augen sitzen an Bildkoordinaten.
func _layout() -> void:
	if _stage == null:
		return
	var s := maxf(size.x / IMAGE_SIZE.x, size.y / IMAGE_SIZE.y)
	_stage.size = IMAGE_SIZE * s
	_stage.position = Vector2((size.x - _stage.size.x) * 0.5, (size.y - _stage.size.y) * VERTICAL_BIAS)
	_stage.pivot_offset = _stage.size * 0.5
	var moon_side := MOON_RADIUS * _stage.size.x * 6.0
	_moon.size = Vector2(moon_side, moon_side)
	_moon.position = MOON_AT * _stage.size - _moon.size * 0.5
	var eye_side := 0.013 * _stage.size.x
	for i: int in _eyes.size():
		_eyes[i].size = Vector2(eye_side, eye_side)
		_eyes[i].position = EYES_AT[i] * _stage.size - _eyes[i].size * 0.5


func _start_motion() -> void:
	var zoom := create_tween().set_loops()
	zoom.tween_property(_stage, "scale", Vector2.ONE * ZOOM_TO, ZOOM_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom.tween_property(_stage, "scale", Vector2.ONE, ZOOM_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var breath := create_tween().set_loops()
	_moon.modulate.a = 0.12
	breath.tween_property(_moon, "modulate:a", 0.38, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath.tween_property(_moon, "modulate:a", 0.12, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if mode == Mode.START:
		_eyes_loop()
		_flash_loop()


func _eyes_loop() -> void:
	var period := EYES_FIRST
	while is_inside_tree():
		await get_tree().create_timer(randf_range(period.x, period.y)).timeout
		period = EYES_PERIOD
		if not is_inside_tree():
			return
		var blink := create_tween().set_parallel(true)
		for eye: TextureRect in _eyes:
			blink.tween_property(eye, "modulate:a", 1.0, 0.4)
			blink.chain().tween_interval(0.7)
			blink.chain().tween_property(eye, "modulate:a", 0.0, 0.4)
		await blink.finished


func _flash_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(FLASH_PERIOD.x, FLASH_PERIOD.y)).timeout
		if not is_inside_tree():
			return
		var flash := create_tween()
		flash.tween_property(_flash, "color:a", 0.09, 0.15)
		flash.tween_property(_flash, "color:a", 0.02, 0.2)
		flash.tween_property(_flash, "color:a", 0.07, 0.1)
		flash.tween_property(_flash, "color:a", 0.0, 0.9)
		await flash.finished


## Ein Nebelband: das Bild wiederholt sich waagerecht und wandert mit `speed` (Pixel je Sekunde, negativ = nach links).
class FogLayer extends Control:
	var texture: Texture2D
	var y_at: float = 0.8        ## Mitte des Bandes als Anteil der Höhe
	var scale_factor: float = 1.0
	var alpha: float = 0.2:
		set(value):
			alpha = value
			queue_redraw()
	var speed: float = -10.0
	var offset: float = 0.0

	func _process(delta: float) -> void:
		offset += speed * delta
		queue_redraw()

	func _draw() -> void:
		if texture == null:
			return
		var h := size.y * 0.5 * scale_factor
		var w := h * texture.get_width() / texture.get_height()
		var tint := ThemeTokens.TINT_NONE
		tint.a = alpha
		var x := fposmod(offset, w) - w
		var top := size.y * y_at - h * 0.5
		while x < size.x:
			draw_texture_rect(texture, Rect2(x, top, w, h), false, tint)
			x += w
