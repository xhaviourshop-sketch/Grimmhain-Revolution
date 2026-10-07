class_name VillageLife
extends VillagePart
## Leben (Teil C): Fledermäuse (nachts) und Krähen (tags) fliegen als kleiner Schwarm über den Dachrand, am Tag stehen Menschengruppen
## und der Galgen am Platzrand. Rein kosmetisch. Nichts darf in einen Sitzplatz ragen. Ein gemeinsamer `_process` für Wiegen, Atmen
## und Schwarm; er läuft nur, solange etwas sichtbar ist. Nachts ohne Schwarm wartet nur ein Timer.

const FLYERS := preload("res://assets/village/flyers.webp")
const CROWD := preload("res://assets/village/crowd.webp")
const GALLOWS := preload("res://assets/village/gallows.webp")

const FADE_SECONDS := 2.0
const FLOCK_WAIT_MIN := 30.0
const FLOCK_WAIT_MAX := 90.0
const FLY_FPS := 12.0
const FLYER_CELL := 90.5
## Ausschnitte der sechs Gruppen (x0, y0, x1, y1) im Bild crowd.webp.
const CROWD_REGIONS: Array[Rect2] = [
	Rect2(24, 33, 201, 216), Rect2(277, 28, 211, 221), Rect2(526, 3, 231, 248),
	Rect2(19, 262, 217, 227), Rect2(269, 257, 243, 240), Rect2(512, 263, 231, 222),
]
## Standplätze der Gruppen (Fußpunkt in Dorfbild-Pixeln, Tagbild): Pflaster direkt vor der Hausreihe, außerhalb des Sitzrings.
## Format: x, y, Region, gespiegelt (0/1).
const CROWD_SPOTS: Array[Vector4] = [
	Vector4(300, 215, 0, 0), Vector4(860, 118, 3, 1), Vector4(1250, 215, 2, 0), Vector4(1410, 430, 5, 1),
	Vector4(1395, 640, 0, 0), Vector4(480, 905, 4, 1), Vector4(1160, 915, 1, 1), Vector4(330, 430, 1, 0),
	Vector4(335, 660, 5, 0), Vector4(1050, 130, 4, 0), Vector4(640, 120, 2, 1), Vector4(1330, 800, 3, 0),
	Vector4(400, 810, 3, 1),
]
const CROWD_HEIGHT := 105.0          ## Bildpixel; Personen etwa so groß wie eine Haustür
const GALLOWS_FOOT := Vector2(836.0, 925.0)
const GALLOWS_HEIGHT := 150.0
## Farbtöne ohne Farbliteral (Theme-Datei gehört nicht zu diesem Teil): leicht abgedunkelt und bläulich entsättigt.
var CROWD_TINT := Color.from_hsv(0.58, 0.1, 0.82)

class Folk:
	extends RefCounted
	var sprite: Sprite2D
	var shadow: Sprite2D
	var spot: Vector2
	var base_scale: float = 1.0
	var flip: bool = false
	var fits: bool = false
	var phase_a: float = 0.0
	var phase_b: float = 0.0

class Flyer:
	extends RefCounted
	var sprite: Sprite2D
	var phase: float = 0.0
	var lane: float = 0.0
	var lag: float = 0.0
	var wave_phase: float = 0.0
	var span: float = 1.0

var _crowd_root: Node2D = null
var _flock_root: Node2D = null
var _folk: Array[Folk] = []
var _gallows: Sprite2D = null
var _gallows_shadow: Sprite2D = null
var _shadow_tex: GradientTexture2D = null
var _crowd_tween: Tween = null
var _timer: Timer = null
var _time: float = 0.0
var _flock: Array[Flyer] = []
var _flock_a := Vector2.ZERO
var _flock_b := Vector2.ZERO
var _flock_t: float = 0.0
var _flock_dur: float = 4.0
var _flock_bats: bool = true
var _bat_frames: Array[AtlasTexture] = []
var _crow_frames: Array[AtlasTexture] = []
var _built: bool = false


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	set_process(false)
	_refresh(false)


func _refresh(animated: bool) -> void:
	if not is_inside_tree():
		return
	var crowd_on := enabled and day
	if crowd_on:
		_build()
		_relayout()
	_fade_crowd(crowd_on, animated and not reduced)
	_update_flock_schedule()
	_update_process()


## Schwarm sofort starten (Aufnahmen und Tests); ignoriert Wartezeit, nicht `enabled` und `reduced`.
func spawn_flock_now() -> void:
	if not enabled or reduced or not (night or day) or map == null:
		return
	_build()
	_start_flock()
	_update_process()


func _relayout() -> void:
	if not _built or map == null:
		return
	var s := map.scale()
	for f: Folk in _folk:
		var region := CROWD_REGIONS[int(f.sprite.get_meta("region"))]
		var k := CROWD_HEIGHT * s / region.size.y
		f.base_scale = k
		var foot := map.to_local(f.spot)
		var w := region.size.x * k
		var h := region.size.y * k
		var rect := Rect2(foot.x - w * 0.5, foot.y - h, w, h + 6.0 * s)
		var inside := map.visible_px(f.spot, 4.0) and Rect2(Vector2.ZERO, map.area).encloses(rect)
		f.fits = inside and not map.hits_seat(rect)
		f.sprite.position = foot
		f.sprite.scale = Vector2(k, k)
		f.shadow.position = foot + Vector2(0, 2.0 * s)
		f.shadow.scale = Vector2(w * 0.5 / 32.0, 6.0 * s / 32.0)
		f.sprite.visible = f.fits
		f.shadow.visible = f.fits
	_place_gallows(s)


func _place_gallows(s: float) -> void:
	var foot := map.to_local(GALLOWS_FOOT)
	var size := GALLOWS.get_size()
	var shown := false
	for shrink: float in [1.0, 0.85, 0.7, 0.6]:
		var k := GALLOWS_HEIGHT * shrink * s / size.y
		var rect := Rect2(foot.x - size.x * k * 0.5, foot.y - size.y * k, size.x * k, size.y * k)
		if not map.hits_seat(rect):
			_gallows.position = foot
			_gallows.scale = Vector2(k, k)
			_gallows_shadow.position = foot + Vector2(0, 2.0 * s)
			_gallows_shadow.scale = Vector2(size.x * k * 0.4 / 32.0, 7.0 * s / 32.0)
			shown = true
			break
	_gallows.visible = shown
	_gallows_shadow.visible = shown


func _build() -> void:
	if _built:
		return
	_built = true
	_shadow_tex = GradientTexture2D.new()
	_shadow_tex.width = 64
	_shadow_tex.height = 64
	_shadow_tex.fill = GradientTexture2D.FILL_RADIAL
	_shadow_tex.fill_from = Vector2(0.5, 0.5)
	_shadow_tex.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.from_hsv(0.0, 0.0, 0.0, 0.38), Color.from_hsv(0.0, 0.0, 0.0, 0.0)])
	_shadow_tex.gradient = grad
	_crowd_root = Node2D.new()
	_crowd_root.modulate.a = 0.0
	_crowd_root.visible = false
	add_child(_crowd_root)
	var spot_rng := RandomNumberGenerator.new()
	spot_rng.seed = 4711
	for v: Vector4 in CROWD_SPOTS:
		var f := Folk.new()
		f.spot = Vector2(v.x, v.y)
		f.flip = v.w > 0.5
		f.phase_a = spot_rng.randf() * TAU
		f.phase_b = spot_rng.randf() * TAU
		f.shadow = _shadow_sprite()
		_crowd_root.add_child(f.shadow)
		var atlas := AtlasTexture.new()
		atlas.atlas = CROWD
		atlas.region = CROWD_REGIONS[int(v.z)]
		var sp := Sprite2D.new()
		sp.texture = atlas
		sp.centered = false
		sp.offset = Vector2(-atlas.region.size.x * 0.5, -atlas.region.size.y)
		sp.flip_h = f.flip
		sp.modulate = CROWD_TINT
		sp.set_meta("region", int(v.z))
		f.sprite = sp
		_crowd_root.add_child(sp)
		_folk.append(f)
	_gallows_shadow = _shadow_sprite()
	_crowd_root.add_child(_gallows_shadow)
	_gallows = Sprite2D.new()
	_gallows.texture = GALLOWS
	_gallows.centered = false
	_gallows.offset = Vector2(-GALLOWS.get_size().x * 0.5, -GALLOWS.get_size().y)
	_gallows.modulate = CROWD_TINT
	_crowd_root.add_child(_gallows)
	_flock_root = Node2D.new()
	add_child(_flock_root)
	for i: int in 6:
		for row: int in 2:
			var a := AtlasTexture.new()
			a.atlas = FLYERS
			a.region = Rect2(i * FLYER_CELL, row * FLYER_CELL, FLYER_CELL, FLYER_CELL)
			(_bat_frames if row == 0 else _crow_frames).append(a)


func _shadow_sprite() -> Sprite2D:
	var sh := Sprite2D.new()
	sh.texture = _shadow_tex
	return sh


func _fade_crowd(on: bool, animated: bool) -> void:
	if not _built:
		return
	if _crowd_tween != null and _crowd_tween.is_valid():
		_crowd_tween.kill()
	var target := 1.0 if on else 0.0
	if animated:
		_crowd_root.visible = true
		_crowd_tween = create_tween()
		_crowd_tween.tween_property(_crowd_root, "modulate:a", target, FADE_SECONDS)
		_crowd_tween.finished.connect(_after_fade)
	else:
		_crowd_root.modulate.a = target
		_after_fade()


func _after_fade() -> void:
	_crowd_root.visible = _crowd_root.modulate.a > 0.001
	_update_process()


# ---------- Schwarm ----------

func _update_flock_schedule() -> void:
	var allowed := enabled and not reduced and (night or day)
	if not allowed:
		_timer.stop()
		_end_flock()
		return
	if _flock_active() and _flock_bats != night:
		_end_flock()
	if not _flock_active() and _timer.is_stopped():
		_timer.start(rng.randf_range(FLOCK_WAIT_MIN, FLOCK_WAIT_MAX))


func _on_timer() -> void:
	if enabled and not reduced and (night or day):
		_start_flock()
		_update_process()


func _flock_active() -> bool:
	return not _flock.is_empty()


## Flugbahn: von Rand zu Rand oberhalb der Dachreihe, bevorzugt ohne Sitzplatz zu kreuzen.
func _start_flock() -> void:
	if _flock_active() or map == null:
		return
	var a := map.area
	var lanes: Array[float] = [0.015, 0.05, 0.085, 0.12]
	lanes.shuffle()
	var left_to_right := rng.randf() < 0.5
	var chosen := -1.0
	for y: float in lanes:
		var band := Rect2(-40.0, a.y * y - 40.0, a.x + 80.0, 100.0)
		if not map.hits_seat(band):
			chosen = y
			break
	if chosen < 0.0:
		chosen = lanes[0]
	var y0 := a.y * chosen
	var x0 := -60.0 if left_to_right else a.x + 60.0
	var x1 := a.x + 60.0 if left_to_right else -60.0
	_flock_a = Vector2(x0, y0 + rng.randf_range(-6.0, 6.0))
	_flock_b = Vector2(x1, y0 + rng.randf_range(-6.0, 6.0))
	_flock_dur = rng.randf_range(3.5, 5.0)
	_flock_t = 0.0
	_flock_bats = night
	var frames := _bat_frames if night else _crow_frames
	var n := rng.randi_range(3, 6)
	var s := map.scale()
	for i: int in n:
		var fl := Flyer.new()
		fl.sprite = Sprite2D.new()
		fl.sprite.texture = frames[0]
		fl.phase = rng.randf() * 6.0
		fl.lane = rng.randf_range(-22.0, 22.0)
		fl.lag = rng.randf_range(0.0, 0.18)
		fl.wave_phase = rng.randf() * TAU
		var span := rng.randf_range(22.0, 32.0) if night else rng.randf_range(26.0, 34.0)
		fl.span = span / 66.0 * minf(s / 0.816, 1.4)
		fl.sprite.scale = Vector2(fl.span, fl.span)
		fl.sprite.modulate = Color.from_hsv(0.6, 0.0, 1.0, 0.95) if night else Color.from_hsv(0.6, 0.06, 0.88, 0.95)
		_flock_root.add_child(fl.sprite)
		_flock.append(fl)


func _end_flock() -> void:
	for fl: Flyer in _flock:
		fl.sprite.queue_free()
	_flock.clear()


func _step_flock(delta: float) -> void:
	_flock_t += delta
	var dir := (_flock_b - _flock_a).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var frames := _bat_frames if _flock_bats else _crow_frames
	var done := true
	for fl: Flyer in _flock:
		var p := clampf(_flock_t / _flock_dur - fl.lag, -0.2, 1.2)
		if p < 1.1:
			done = false
		var pos := _flock_a.lerp(_flock_b, p)
		var wave := sin(_flock_t * 4.0 + fl.wave_phase) * 5.0
		fl.sprite.position = pos + normal * (fl.lane + wave)
		var heading := dir.rotated(cos(_flock_t * 4.0 + fl.wave_phase) * 0.18)
		fl.sprite.rotation = heading.angle() + PI * 0.5
		fl.sprite.texture = frames[int(_flock_t * FLY_FPS + fl.phase) % 6]
		fl.sprite.visible = p > -0.19 and p < 1.19
	if done:
		_end_flock()
		_update_flock_schedule()
		_update_process()


# ---------- Takt ----------

func _update_process() -> void:
	var crowd_live := _built and _crowd_root.visible and not reduced
	set_process(crowd_live or _flock_active())


func _process(delta: float) -> void:
	_time += delta
	if _built and _crowd_root.visible and not reduced:
		for f: Folk in _folk:
			if not f.fits:
				continue
			f.sprite.rotation = sin(_time * 0.7 + f.phase_a) * deg_to_rad(1.0)
			var b := 1.0 + 0.015 * sin(_time * 0.9 + f.phase_b)
			f.sprite.scale = Vector2(f.base_scale * b, f.base_scale * b)
	if _flock_active():
		_step_flock(delta)
	if not _flock_active() and not (_built and _crowd_root.visible and not reduced):
		set_process(false)
