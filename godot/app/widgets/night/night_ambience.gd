class_name NightAmbience
extends Node
## Nacht-Atmosphäre im Cockpit-Hintergrund (rein kosmetisch, nichts im Spielstand, kein Regelkern):
## Bodennebel, vorbeiziehende Wolke vor dem Mond, wenige leuchtende Fenster mit langsamem Verlöschen in tiefer Nacht und der rote
## Wolfsschimmer während eines Wolfsschritts. Zufall nur über den eigenen Generator, nicht über den Spielzufall.
## Das Cockpit meldet nur Phase, Wolfsschritt und Einstellungen; alle Uniforms und Tweens liegen hier.

const WINDOW_COUNT := 47            ## Fensterinseln der ID-Karte (1 bis 47)
const LIT_MIN := 4                  ## so viele Fenster leuchten pro Nacht (4 bis 8)
const LIT_MAX := 8
const LIT_KEEP := 2                 ## in tiefer Nacht bleiben mindestens so viele an
const DEEP_NIGHT_SECONDS := 120.0   ## ab hier verlöschen Fenster einzeln
const WINDOW_OFF_MIN := 40.0        ## Abstand zwischen zwei Verlöschen
const WINDOW_OFF_MAX := 90.0
const WINDOW_OFF_SECONDS := 1.5
const CLOUD_GAP_MIN := 20.0         ## Abstand zwischen zwei Wolken
const CLOUD_GAP_MAX := 60.0
const CLOUD_PASS_MIN := 5.0         ## Dauer eines Vorbeizugs
const CLOUD_PASS_MAX := 8.0
const CLOUD_TRAVEL := 0.22          ## Weg des Flecks in Bildbreiten

var _art: ShaderMaterial = null
var _fog: ColorRect = null
var _wolf: ColorRect = null
var _enabled: bool = true
var _reduced: bool = false
var _night: bool = false
var _phase_known: bool = false
var _fx: float = 0.0                ## 0 Tag oder aus, 1 volle Nacht-Atmosphäre
var _wolf_level: float = 0.0        ## 0 bis 1
var _wolf_active: bool = false
var _cloud: float = 0.0
var _cloud_x: float = 0.0
var _lit: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _night_time: float = 0.0
var _next_off: float = 0.0
var _next_cloud: float = 0.0
var _fx_tween: Tween = null
var _wolf_tween: Tween = null
var _cloud_tween: Tween = null
var _off_tween: Tween = null


func _init() -> void:
	_rng.randomize()
	_lit.resize(WINDOW_COUNT + 1)
	_lit.fill(1.0)
	set_process(false)


## Verbindet die Ebenen des Hintergrunds. Nebel und Wolfsschimmer bekommen hier ihr Material.
func configure(art: ShaderMaterial, fog: ColorRect, wolf: ColorRect) -> void:
	_art = art
	_fog = fog
	_wolf = wolf
	var fog_mat := ShaderMaterial.new()
	fog_mat.shader = load("res://app/theme/night_fog.gdshader") as Shader
	_fog.material = fog_mat
	var wolf_mat := ShaderMaterial.new()
	wolf_mat.shader = load("res://app/theme/night_wolf_glow.gdshader") as Shader
	wolf_mat.set_shader_parameter("glow_color", ThemeTokens.BLOOD_GLOW)
	wolf_mat.set_shader_parameter("max_alpha", ThemeTokens.WOLF_GLOW_ALPHA)
	wolf_mat.set_shader_parameter("pulse_seconds", ThemeTokens.WOLF_GLOW_PULSE_SECONDS)
	_wolf.material = wolf_mat
	_art.set_shader_parameter("cloud_dim", ThemeTokens.NIGHT_CLOUD_DIM)
	_apply()


## Effekte ein oder aus (Einstellung). Aus: Nebel, Wolke und Wolfsschimmer weg, alle Fenster statisch im vollen Schein wie zuvor.
func set_enabled(on: bool, animated: bool = true) -> void:
	_enabled = on
	_retarget(animated)


## Reduzierte Bewegung: Nebel und Fensterlicht stehen, keine Wolke, der Wolfsschimmer glimmt ohne Puls.
func set_reduced_motion(on: bool) -> void:
	_reduced = on
	_retarget(false)


## Phase des Hintergrunds: "night", "day" oder "". Eine neue Nacht wählt neue Fenster.
func set_phase(group: String, animated: bool = true) -> void:
	var was_night := _night
	_night = group == "night"
	if _night and not was_night:
		_pick_windows()
	_retarget(animated and _phase_known)
	_phase_known = true


## Wolfsschritt läuft (Rudel oder König Lykaon): roter Schimmer am Rand.
func set_wolf(active: bool) -> void:
	if active == _wolf_active:
		return
	_wolf_active = active
	_tween_wolf(true)


func _process(delta: float) -> void:
	_night_time += delta
	_next_cloud -= delta
	if _next_cloud <= 0.0:
		_next_cloud = _rng.randf_range(CLOUD_GAP_MIN, CLOUD_GAP_MAX)
		_start_cloud()
	if _night_time >= DEEP_NIGHT_SECONDS:
		_next_off -= delta
		if _next_off <= 0.0:
			_next_off = _rng.randf_range(WINDOW_OFF_MIN, WINDOW_OFF_MAX)
			_put_out_window()


## Gewünschten Stand aus Einstellung und Phase ableiten und dorthin blenden.
func _retarget(animated: bool) -> void:
	var target := 1.0 if (_enabled and _night) else 0.0
	_kill(_fx_tween)
	if animated and not _reduced and is_inside_tree() and not is_equal_approx(_fx, target):
		_fx_tween = create_tween()
		_fx_tween.tween_method(_set_fx, _fx, target, ThemeTokens.NIGHT_FX_FADE_SECONDS)
	else:
		_set_fx(target)
	var moving := _enabled and _night and not _reduced
	if moving and not is_processing():
		_next_cloud = _rng.randf_range(CLOUD_GAP_MIN, CLOUD_GAP_MAX)
		_next_off = _rng.randf_range(WINDOW_OFF_MIN, WINDOW_OFF_MAX)
	if not moving:
		_kill(_cloud_tween)
		_cloud = 0.0
	set_process(moving)
	_tween_wolf(animated)
	_apply()


func _set_fx(value: float) -> void:
	_fx = value
	_apply()


func _tween_wolf(animated: bool) -> void:
	_kill(_wolf_tween)
	var target := 1.0 if (_wolf_active and _enabled and _night) else 0.0
	if animated and not _reduced and is_inside_tree():
		_wolf_tween = create_tween()
		_wolf_tween.tween_method(_set_wolf_level, _wolf_level, target, ThemeTokens.WOLF_GLOW_FADE_SECONDS)
	else:
		_set_wolf_level(target)


func _set_wolf_level(value: float) -> void:
	_wolf_level = value
	_apply()


## Wählt 4 bis 8 der 47 Fenster für diese Nacht und setzt die Nachtuhr zurück.
func _pick_windows() -> void:
	_kill(_off_tween)
	_night_time = 0.0
	_lit.fill(0.0)
	var ids: Array[int] = []
	for i in range(1, WINDOW_COUNT + 1):
		ids.append(i)
	var count := _rng.randi_range(LIT_MIN, LIT_MAX)
	for _n in count:
		var pick := _rng.randi_range(0, ids.size() - 1)
		_lit[ids[pick]] = 1.0
		ids.remove_at(pick)


## Lässt ein leuchtendes Fenster weich verlöschen; es bleiben mindestens `LIT_KEEP` an.
func _put_out_window() -> void:
	var on: Array[int] = []
	for i in range(1, WINDOW_COUNT + 1):
		if _lit[i] > 0.5:
			on.append(i)
	if on.size() <= LIT_KEEP:
		return
	var id: int = on[_rng.randi_range(0, on.size() - 1)]
	_kill(_off_tween)
	_off_tween = create_tween()
	_off_tween.tween_method(_set_window.bind(id), 1.0, 0.0, WINDOW_OFF_SECONDS)


func _set_window(value: float, id: int) -> void:
	_lit[id] = value
	_apply()


func _start_cloud() -> void:
	_kill(_cloud_tween)
	_cloud_tween = create_tween()
	_cloud_tween.tween_method(_set_cloud_progress, 0.0, 1.0, _rng.randf_range(CLOUD_PASS_MIN, CLOUD_PASS_MAX))
	_cloud_tween.finished.connect(_set_cloud_progress.bind(0.0))


## Fortschritt 0 bis 1: Abdunklung steigt und fällt weich, der Fleck zieht von rechts nach links über den Mond.
func _set_cloud_progress(progress: float) -> void:
	_cloud = sin(progress * PI)
	_cloud_x = (0.5 - progress) * CLOUD_TRAVEL
	_apply()


## Schreibt den Stand in die Uniforms. Tag und „aus“: alle Fenster wie bisher im vollen Schein, ohne Flackern.
func _apply() -> void:
	if _art == null:
		return
	var levels := PackedFloat32Array()
	levels.resize(WINDOW_COUNT + 1)
	for i in levels.size():
		levels[i] = lerpf(1.0, _lit[i], _fx)
	_art.set_shader_parameter("window_level", levels)
	_art.set_shader_parameter("animate", 0.0 if (_reduced or _fx < 0.01) else 1.0)
	_art.set_shader_parameter("cloud", _cloud * _fx)
	_art.set_shader_parameter("cloud_x", _cloud_x)
	var fog_mat := _fog.material as ShaderMaterial
	_fog.visible = _fx > 0.001
	fog_mat.set_shader_parameter("strength", ThemeTokens.NIGHT_FOG_STRENGTH * _fx)
	fog_mat.set_shader_parameter("animate", 0.0 if _reduced else 1.0)
	var wolf_mat := _wolf.material as ShaderMaterial
	_wolf.visible = _wolf_level * _fx > 0.001
	wolf_mat.set_shader_parameter("strength", _wolf_level * _fx)
	wolf_mat.set_shader_parameter("animate", 0.0 if _reduced else 1.0)


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
