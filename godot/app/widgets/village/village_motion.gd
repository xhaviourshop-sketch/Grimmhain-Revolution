class_name VillageMotion
extends VillagePart
## Bewegung (Teil B): Rauch aus Schornsteinen und ein ziehender Wolkenschatten. Wenige Sprites, ein gemeinsamer `_process`,
## der nur läuft, solange die Ebene sichtbar ist und Bewegung erlaubt ist. Bäume wiegen bewusst nicht (siehe Bericht zu Teil B).

const SMOKE: Texture2D = preload("res://assets/village/smoke.webp")
const CHIMNEYS: Array[Vector2] = [Vector2(1405, 66), Vector2(1385, 783), Vector2(1185, 858), Vector2(437, 832), Vector2(503, 850)]
const PUFFS := 3                  ## versetzte Kopien je Schornstein
const PERIOD := 9.0               ## Sekunden je Rauchzug
const START_H := 60.0             ## Bildpixel: Höhe der Fahne an der Esse
const END_H := 210.0              ## Bildpixel: Höhe am Ende des Aufstiegs
const RISE := 170.0               ## Bildpixel Aufstieg
const DRIFT := 50.0               ## Bildpixel Wehen nach rechts
const SMOKE_ALPHA := 0.95
const NIGHT_SIZE := 1.25          ## nachts breitere, dichtere Fahne
const CLOUD_TRAVEL := 25.0        ## Sekunden für einen Zug über das Bild
const FADE := 2.0

var _smoke_tint_night: Color = Color.from_hsv(0.6, 0.12, 1.5)   ## nachts heller (kühles Mondlicht), aber nicht leuchtend
var _smoke_tint_day: Color = ThemeTokens.TINT_NONE
var _chimneys: Array[Dictionary] = []   ## {"p": Vector2 lokal, "puffs": Array[TextureRect]}
var _cloud: TextureRect = null
var _vis: float = 0.0
var _tone: float = 0.0            ## 0 Tag, 1 Nacht
var _time: float = 0.0
var _cloud_wait: float = 15.0
var _cloud_t: float = -1.0
var _cloud_y: float = 0.4
var _tween: Tween = null


func _init() -> void:
	super._init()
	clip_contents = true
	visible = false
	set_process(false)
	var tex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var shade: Color = ThemeTokens.TINT_NONE.darkened(1.0)
	var alphas: Array[float] = [0.42, 0.24, 0.0]
	var cols := PackedColorArray()
	for al: float in alphas:
		var c: Color = shade
		c.a = al
		cols.append(c)
	grad.colors = cols
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	_cloud = TextureRect.new()
	_cloud.texture = tex
	_cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cloud.stretch_mode = TextureRect.STRETCH_SCALE
	_cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cloud.visible = false
	add_child(_cloud)
	for i: int in CHIMNEYS.size():
		var puffs: Array[TextureRect] = []
		for k: int in PUFFS:
			var t := TextureRect.new()
			t.texture = SMOKE
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_SCALE
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.visible = false
			add_child(t)
			puffs.append(t)
		_chimneys.append({"p": Vector2.ZERO, "puffs": puffs, "on": false, "k": 1.0})


func _refresh(animated: bool) -> void:
	var want_vis := 1.0 if (enabled and (night or day)) else 0.0
	var want_tone := 1.0 if night else 0.0
	if _tween != null:
		_tween.kill()
		_tween = null
	var was_visible := visible
	if want_vis > 0.0:
		visible = true
	if animated and is_inside_tree() and not reduced and (was_visible or want_vis > 0.0):
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(self, "_vis", want_vis, FADE)
		_tween.tween_property(self, "_tone", want_tone, FADE)
		_tween.finished.connect(_apply)
		set_process(true)
	else:
		_vis = want_vis
		_tone = want_tone
	_apply()
	_relayout()


## Sichtbarkeit und Prozess nachziehen; einmal Standbild zeichnen, wenn Bewegung reduziert ist.
func _apply() -> void:
	var tweening := _tween != null and _tween.is_valid() and _tween.is_running()
	visible = _vis > 0.001 or tweening
	set_process(visible and not reduced)
	if visible:
		_update_smoke()
		_update_cloud()


func _relayout() -> void:
	if map == null:
		return
	var sc := map.scale()
	for c: Dictionary in _chimneys:
		c["on"] = false
	for i: int in CHIMNEYS.size():
		var img := CHIMNEYS[i]
		var p := map.to_local(img)
		_chimneys[i]["p"] = p
		_chimneys[i]["k"] = 0.0
		if not map.visible_px(img, 0.0):
			continue
		# Größte Fahne wählen, die in keinen Sitzplatz ragt; sonst bleibt der Schornstein ohne Rauch.
		for k: float in [1.0, 0.8, 0.62, 0.5, 0.4, 0.32]:
			var half_w := END_H * 0.25 * k
			var col := Rect2(p.x - 12.0 * sc * k, p.y - (RISE + END_H) * 0.85 * k * sc, (DRIFT * k + half_w + 12.0) * sc, (RISE + END_H) * 0.85 * k * sc)
			if not map.hits_seat(col):
				_chimneys[i]["k"] = k
				_chimneys[i]["on"] = true
				break
	if visible:
		_update_smoke()
		_update_cloud()


func _process(delta: float) -> void:
	_time += delta
	_update_smoke()
	if _cloud_t >= 0.0:
		_cloud_t += delta / CLOUD_TRAVEL
		if _cloud_t >= 1.0:
			_cloud_t = -1.0
			_cloud_wait = rng.randf_range(40.0, 90.0)
	elif not reduced and enabled:
		_cloud_wait -= delta
		if _cloud_wait <= 0.0:
			launch_cloud()
	_update_cloud()


## Wolkenschatten sofort losschicken (Aufnahmen, Tests).
func launch_cloud() -> void:
	_cloud_t = 0.0
	_cloud_y = rng.randf_range(0.25, 0.7)


func _update_smoke() -> void:
	if map == null:
		return
	var sc := map.scale()
	var tint := _smoke_tint_day.lerp(_smoke_tint_night, _tone)
	for c: Dictionary in _chimneys:
		var puffs: Array = c["puffs"]
		var on: bool = c["on"]
		var k: float = c["k"]
		for n: int in puffs.size():
			var t: TextureRect = puffs[n]
			if not on or _vis <= 0.001:
				t.visible = false
				continue
			var ph := fmod(_time / PERIOD + float(n) / float(PUFFS) + _chimney_phase(c), 1.0)
			if reduced:
				ph = 0.2 + 0.25 * float(n)   # Standbild: drei Stufen übereinander
			var h := lerpf(START_H, END_H, ph) * sc * k * lerpf(1.0, NIGHT_SIZE, _tone)
			var w := h * float(SMOKE.get_width()) / float(SMOKE.get_height())
			var base: Vector2 = c["p"]
			var pos := base + Vector2(DRIFT * ph * sc * k, -RISE * ph * sc * k)
			t.size = Vector2(w, h)
			t.position = pos - Vector2(w * 0.5, h)
			var a := minf(ph / 0.12, 1.0) * minf((1.0 - ph) / 0.5, 1.0) * SMOKE_ALPHA
			if reduced:
				a *= 0.7
			t.modulate = tint
			t.modulate.a = clampf(a, 0.0, SMOKE_ALPHA) * _vis
			t.visible = true


func _chimney_phase(c: Dictionary) -> float:
	var p: Vector2 = c["p"]
	return fmod(absf(p.x * 0.0137 + p.y * 0.0071), 1.0)


func _update_cloud() -> void:
	if map == null:
		return
	if reduced or not enabled or _cloud_t < 0.0 or _vis <= 0.001:
		_cloud.visible = false
		return
	var sc := map.scale()
	var w := 780.0 * sc
	var h := 420.0 * sc
	_cloud.size = Vector2(w, h)
	var x := lerpf(-w, size.x, _cloud_t)
	_cloud.position = Vector2(x, _cloud_y * size.y - h * 0.5)
	_cloud.modulate.a = _vis
	_cloud.visible = true
