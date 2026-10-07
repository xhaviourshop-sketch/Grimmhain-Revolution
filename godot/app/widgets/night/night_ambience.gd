class_name NightAmbience
extends Node
## Lebendiges Dorf im Cockpit-Hintergrund (rein kosmetisch, nichts im Spielstand, kein Regelkern). Blendet zwischen Nacht- und Tagbild
## (deckungsgleich) und verteilt den Stand an die drei Dorf-Ebenen: Licht (`VillageLights`), Bewegung (`VillageMotion`) und Leben
## (`VillageLife`). Die Einstellung „Effekte“ schaltet alle drei Ebenen ab; das Tagbild blendet trotzdem, es ist der Hintergrund selbst.
## Das Cockpit meldet nur Phase, Wolfsschritt, Akt, Tote, Sitzplätze und Einstellungen.

const DAY_FADE_SECONDS := 2.0

var _day_art: TextureRect = null
var _tone: ShaderMaterial = null  ## Tönung der gemalten Lichter im Nachtbild (Wolfsschritt, Akt IV)
var _wolf_level: float = 0.0
var _cold_level: float = 0.0
var _tone_tween: Tween = null
var _map := VillageMap.new()
var _parts: Array[VillagePart] = []
var _night: bool = false
var _day: bool = false
var _reduced: bool = false
var _phase_known: bool = false
var _day_tween: Tween = null


## Verbindet Nacht- und Tagbild und Dorf-Ebene (`layer`, volle Fläche hinter allen Bedienflächen) und legt die drei Ebenen an.
func configure(night_art: TextureRect, day_art: TextureRect, layer: Control) -> void:
	_tone = ShaderMaterial.new()
	_tone.shader = load("res://app/theme/village_light_tone.gdshader") as Shader
	_tone.set_shader_parameter("cold_color", ThemeTokens.FIRE_GHOST_FLAME[2])
	night_art.material = _tone
	_day_art = day_art
	_day_art.modulate.a = 0.0
	for part: VillagePart in [VillageLights.new(), VillageMotion.new(), VillageLife.new()]:
		part.map = _map
		layer.add_child(part)
		_parts.append(part)
	_parts[0].name = "Lights"
	_parts[1].name = "Motion"
	_parts[2].name = "Life"
	layer.resized.connect(_on_resized.bind(layer))
	_on_resized(layer)


## Effekte ein oder aus (Einstellung „Effekte“).
func set_enabled(on: bool, animated: bool = true) -> void:
	for part: VillagePart in _parts:
		part.enabled = on
	_refresh(animated)


## Reduzierte Bewegung: Ebenen stehen still, Übergänge sofort.
func set_reduced_motion(on: bool) -> void:
	_reduced = on
	for part: VillagePart in _parts:
		part.reduced = on
	_refresh(false)


## Phase des Hintergrunds: "night", "day" oder "".
func set_phase(group: String, animated: bool = true) -> void:
	_night = group == "night"
	_day = group == "day"
	for part: VillagePart in _parts:
		part.night = _night
		part.day = _day
	var go := animated and _phase_known and not _reduced and is_inside_tree()
	_phase_known = true
	_fade_day(go)
	_refresh(go)


## Wolfsschritt läuft (Rudel oder König Lykaon).
func set_wolf(active: bool) -> void:
	if _parts.is_empty() or _parts[0].wolf == active:
		return
	for part: VillagePart in _parts:
		part.wolf = active
	_refresh(not _reduced)


## Akt I bis IV der Partie und Zahl der Toten. Ändert sich etwas, reagieren die Ebenen.
func set_game(act_level: int, dead_count: int) -> void:
	if _parts.is_empty() or (_parts[0].act_level == act_level and _parts[0].dead_count == dead_count):
		return
	for part: VillagePart in _parts:
		part.act_level = act_level
		part.dead_count = dead_count
	_refresh(not _reduced)


## Zahl der Spieler; wirkt beim nächsten Sitzplatzbericht (`set_seat_rects`).
func set_players(count: int) -> void:
	for part: VillagePart in _parts:
		part.player_count = count


## Sitzplätze (Porträt und Name) in globalen Koordinaten; nichts aus dem Dorf darf hineinragen.
func set_seat_rects(global_rects: Array[Rect2], layer: Control) -> void:
	var inv := layer.get_global_transform().affine_inverse()
	var local: Array[Rect2] = []
	for r: Rect2 in global_rects:
		local.append(inv * r)
	_map.set_blocked(local)
	for part: VillagePart in _parts:
		part._relayout()


func _fade_day(animated: bool) -> void:
	if _day_art == null:
		return
	if _day_tween != null and _day_tween.is_valid():
		_day_tween.kill()
	var target := 1.0 if _day else 0.0
	if animated:
		_day_tween = create_tween()
		_day_tween.tween_property(_day_art, "modulate:a", target, DAY_FADE_SECONDS)
	else:
		_day_art.modulate.a = target


func _refresh(animated: bool) -> void:
	for part: VillagePart in _parts:
		part._refresh(animated)
	_retone(animated)


## Gemalte Lichter: im Wolfsschritt gedimmt und rötlich, in Akt IV kalt. Mit „Effekte aus“ unverändert.
func _retone(animated: bool) -> void:
	if _tone == null or _parts.is_empty():
		return
	var on := _parts[0].enabled and _night
	var wolf_target := 1.0 if (on and _parts[0].wolf) else 0.0
	var cold_target := 1.0 if (on and _parts[0].act_level >= 4) else 0.0
	if is_equal_approx(wolf_target, _wolf_level) and is_equal_approx(cold_target, _cold_level):
		return
	if _tone_tween != null and _tone_tween.is_valid():
		_tone_tween.kill()
	if animated and is_inside_tree():
		_tone_tween = create_tween().set_parallel()
		_tone_tween.tween_method(_set_wolf_level, _wolf_level, wolf_target, ThemeTokens.VILLAGE_LIGHT_FADE_SECONDS)
		_tone_tween.tween_method(_set_cold_level, _cold_level, cold_target, DAY_FADE_SECONDS)
	else:
		_set_wolf_level(wolf_target)
		_set_cold_level(cold_target)


func _set_wolf_level(value: float) -> void:
	_wolf_level = value
	_tone.set_shader_parameter("gain", lerpf(1.0, ThemeTokens.VILLAGE_WOLF_GAIN, value))
	_tone.set_shader_parameter("tint", ThemeTokens.TINT_NONE.lerp(ThemeTokens.VILLAGE_WOLF_TINT, value))


func _set_cold_level(value: float) -> void:
	_cold_level = value
	_tone.set_shader_parameter("cold", value)


func _on_resized(layer: Control) -> void:
	_map.area = layer.size
	for part: VillagePart in _parts:
		part._relayout()
