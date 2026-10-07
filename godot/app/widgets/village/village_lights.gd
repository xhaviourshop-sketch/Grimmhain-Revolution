class_name VillageLights
extends VillagePart
## Licht (Teil A): Laternenschein auf dem Pflaster, flackernde Fenster, Wolfsschritt, Akt-Tönung, verlöschende Fenster.
## Technik: additive Sprites mit einer geteilten weichen Textur und einem geteilten Material (kein Light2D, kein Vollbild-Shader).
## Ein einziges `_process` für alle Lichter, nur wenn sichtbar und nicht reduziert. Rein kosmetisch.

static var WARM := Color.from_rgba8(255, 158, 66)          ## Kerzen- und Laternenlicht
static var WOLF_WARM := Color.from_rgba8(255, 92, 56)     ## Wolfsschritt: leicht rötlich
static var WALL_DARK := Color.from_rgba8(18, 14, 14)  ## Wand um ein erloschenes Fenster (deckt das gemalte Licht ab)
static var COLD_DARK := Color.from_rgba8(10, 18, 38)    ## Akt IV: dunkles Blau über dem gemalten warmen Licht
static var CORE_WARM := Color.from_rgba8(255, 217, 140)  ## heller Kern der Flamme
static var CORE_WOLF := Color.from_rgba8(255, 153, 115)
const NIGHT_SECONDS := 2.0
const WOLF_SECONDS := 1.5
const WINDOW_OUT_SECONDS := 3.0
const WOLF_LEVEL := 0.6                        ## Helligkeit im Wolfsschritt
const ACT_OFF_SHARE: Array[float] = [0.0, 0.0, 0.2, 0.4, 0.55]  ## Anteil dauerhaft dunkler Fenster je Akt (Index = Akt)
const SHUFFLE_SEED := 7341                     ## feste Reihenfolge, in der Fenster ausgehen
const LANTERN_GLOW := Vector2(230.0, 120.0)    ## Bildpixel, flach auf dem Pflaster
const LANTERN_GLOW_OFFSET := Vector2(0.0, 22.0)
const LANTERN_CORE := Vector2(34.0, 34.0)
const LANTERN_PEAK := 1.0
const WINDOW_GLOW_FACTOR := 3.4                ## Fensterschein: Vielfaches der Fenstergröße
const WINDOW_PEAK := 0.95
const TEX_SIZE := 64

static var _glow_tex: Texture2D = null
static var _box_tex: Texture2D = null
static var _add_mat: CanvasItemMaterial = null

class Spot:
	var is_window: bool = false
	var center := Vector2.ZERO       ## Bildpixel
	var size := Vector2.ZERO         ## Bildpixel (Fenster) oder Schein (Laterne)
	var glow: Sprite2D = null
	var core: Sprite2D = null        ## Laterne: kleiner heller Punkt
	var cover: Sprite2D = null       ## deckt das gemalte Licht ab (Fenster aus, Akt IV)
	var phase := Vector3.ZERO
	var speed := Vector3.ZERO
	var rank: int = 0                ## Reihenfolge, in der Fenster ausgehen
	var on: float = 1.0              ## 1 = brennt, 0 = erloschen
	var on_target: float = 1.0
	var placed: bool = false         ## sichtbar und ohne Sitzplatz im Weg

var _spots: Array[Spot] = []
var _built: bool = false
var _night_f: float = 0.0
var _wolf_f: float = 0.0
var _cold_f: float = 0.0
var _time: float = 0.0
var _sprites: Node2D = null


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_make_shared()
	_sprites = Node2D.new()
	add_child(_sprites)
	var seeded := RandomNumberGenerator.new()
	seeded.seed = SHUFFLE_SEED
	var ranks: Array[int] = []
	for i: int in VillageLightSpots.WINDOWS.size():
		ranks.append(i)
	for i: int in range(ranks.size() - 1, 0, -1):
		var j := seeded.randi_range(0, i)
		var t := ranks[i]
		ranks[i] = ranks[j]
		ranks[j] = t
	for i: int in VillageLightSpots.WINDOWS.size():
		var r := VillageLightSpots.WINDOWS[i]
		var s := _new_spot(true, r.position, r.size)
		s.rank = ranks[i]
	for p: Vector2 in VillageLightSpots.LANTERNS:
		_new_spot(false, p, LANTERN_GLOW)
	set_process(false)
	visible = false


func _new_spot(is_window: bool, center: Vector2, size: Vector2) -> Spot:
	var s := Spot.new()
	s.is_window = is_window
	s.center = center
	s.size = size
	s.phase = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
	s.speed = Vector3(rng.randf_range(1.3, 2.1), rng.randf_range(3.1, 4.6), rng.randf_range(7.0, 10.5))
	s.cover = _sprite(_box_tex if is_window else _glow_tex, false)
	s.glow = _sprite(_glow_tex, true)
	if not is_window:
		s.core = _sprite(_glow_tex, true)
	_spots.append(s)
	return s


func _sprite(tex: Texture2D, additive: bool) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex
	if additive:
		sp.material = _add_mat
	_sprites.add_child(sp)
	return sp


static func _make_shared() -> void:
	if _glow_tex != null:
		return
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.22, 0.55, 1.0])
	g.colors = PackedColorArray([_white(1.0), _white(0.75), _white(0.25), _white(0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = TEX_SIZE
	t.height = TEX_SIZE
	_glow_tex = t
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g2.colors = PackedColorArray([_white(1.0), _white(1.0), _white(0.0)])
	var b := GradientTexture2D.new()
	b.gradient = g2
	b.fill = GradientTexture2D.FILL_SQUARE
	b.fill_from = Vector2(0.5, 0.5)
	b.fill_to = Vector2(1.0, 0.5)
	b.width = TEX_SIZE
	b.height = TEX_SIZE
	_box_tex = b
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func _refresh(animated: bool) -> void:
	_ensure_built()
	var lit_now := enabled and night
	var go := animated and not reduced
	var n_target := 1.0 if lit_now else 0.0
	var w_target := 1.0 if wolf else 0.0
	var c_target := 1.0 if act_level >= 4 else 0.0
	if not go:
		_night_f = n_target
		_wolf_f = w_target
		_cold_f = c_target
	# Fenster: erloschen nach Akt-Anteil plus Toten, feste Reihenfolge
	var windows := VillageLightSpots.WINDOWS.size()
	var share: float = ACT_OFF_SHARE[clampi(act_level, 0, 4)]
	var off_count := mini(windows, roundi(share * windows) + maxi(dead_count, 0))
	for s: Spot in _spots:
		if s.is_window:
			s.on_target = 0.0 if s.rank < off_count else 1.0
			if not go or not lit_now or not _was_shown:
				s.on = s.on_target
	_was_shown = _was_shown or lit_now
	_night_target = n_target
	_wolf_target = w_target
	_cold_target = c_target
	_update_running()
	_apply()


var _was_shown: bool = false
var _night_target: float = 0.0
var _wolf_target: float = 0.0
var _cold_target: float = 0.0


func _update_running() -> void:
	visible = enabled and (_night_f > 0.0 or _night_target > 0.0)
	set_process(visible and not reduced)


func _relayout() -> void:
	_ensure_built()
	if map == null:
		return
	var s := map.scale()
	for sp: Spot in _spots:
		var pos := map.to_local(sp.center)
		var gsize := sp.size * s if not sp.is_window else sp.size * WINDOW_GLOW_FACTOR * s
		var gpos := pos
		if not sp.is_window:
			gpos += LANTERN_GLOW_OFFSET * s
		var rect := Rect2(gpos - gsize * 0.5, gsize)
		sp.placed = map.visible_px(sp.center, 30.0) and not map.hits_seat(rect)
		sp.glow.position = gpos
		sp.glow.scale = gsize / float(TEX_SIZE)
		if sp.is_window:
			sp.cover.position = pos
			sp.cover.scale = sp.size * 1.45 * s / float(TEX_SIZE)
		else:
			sp.cover.position = gpos
			sp.cover.scale = gsize * 1.15 / float(TEX_SIZE)
			sp.core.position = pos
			sp.core.scale = LANTERN_CORE * s / float(TEX_SIZE)
	_apply()


func _process(delta: float) -> void:
	_time += delta
	_night_f = move_toward(_night_f, _night_target, delta / NIGHT_SECONDS)
	_wolf_f = move_toward(_wolf_f, _wolf_target, delta / WOLF_SECONDS)
	_cold_f = move_toward(_cold_f, _cold_target, delta / WOLF_SECONDS)
	for sp: Spot in _spots:
		if sp.on != sp.on_target:
			sp.on = move_toward(sp.on, sp.on_target, delta / WINDOW_OUT_SECONDS)
	_apply()
	if _night_f <= 0.0 and _night_target <= 0.0:
		_update_running()


## Setzt Farbe und Helligkeit aller Sprites aus dem aktuellen Stand (Flackern nur ohne reduzierte Bewegung).
func _apply() -> void:
	if not _built or not visible:
		return
	var flame: Color = ThemeTokens.FIRE_GHOST_FLAME[3]
	var core_cold: Color = ThemeTokens.FIRE_GHOST_CORE[3]
	var level := lerpf(1.0, WOLF_LEVEL, _wolf_f)
	var tint := WARM.lerp(WOLF_WARM, _wolf_f).lerp(flame, _cold_f)
	for sp: Spot in _spots:
		var flick := 1.0
		if not reduced:
			var amp := 0.10 if sp.is_window else 0.2
			flick = 1.0 + amp * (0.5 * sin(_time * sp.speed.x + sp.phase.x) + 0.3 * sin(_time * sp.speed.y + sp.phase.y) + 0.2 * sin(_time * sp.speed.z + sp.phase.z))
		var lit := sp.on * _night_f
		var peak := WINDOW_PEAK if sp.is_window else LANTERN_PEAK
		var shown := sp.placed
		sp.glow.visible = shown and lit > 0.0
		sp.glow.modulate = _with_alpha(tint, peak * lit * level * flick)
		if sp.core != null:
			sp.core.visible = sp.glow.visible
			var core_tint := CORE_WARM.lerp(CORE_WOLF, _wolf_f).lerp(core_cold, _cold_f)
			sp.core.modulate = _with_alpha(core_tint, lit * level * flick)
		# Abdecken: erloschenes Fenster ganz dunkel; Akt IV dämpft das gemalte warme Licht zu Blau.
		var cover_a: float
		if sp.is_window:
			cover_a = (1.0 - sp.on) * 0.97 + sp.on * _cold_f * 0.7
			var cc := WALL_DARK.lerp(COLD_DARK, _cold_f * sp.on)
			sp.cover.modulate = _with_alpha(cc, cover_a * _night_f)
		else:
			cover_a = _cold_f * 0.6
			sp.cover.modulate = _with_alpha(COLD_DARK, cover_a * _night_f)
		sp.cover.visible = cover_a * _night_f > 0.01


static func _white(alpha: float) -> Color:
	var c := Color.from_rgba8(255, 255, 255)
	c.a = alpha
	return c


static func _with_alpha(c: Color, alpha: float) -> Color:
	var r := c
	r.a = alpha
	return r
