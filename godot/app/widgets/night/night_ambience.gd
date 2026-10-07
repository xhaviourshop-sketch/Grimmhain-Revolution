class_name NightAmbience
extends Node
## Lebendiges Dorf im Cockpit-Hintergrund (rein kosmetisch, nichts im Spielstand, kein Regelkern). Blendet zwischen Nacht- und Tagbild
## (deckungsgleich) und verteilt den Stand an die drei Dorf-Ebenen: Licht (`VillageLights`), Bewegung (`VillageMotion`) und Leben
## (`VillageLife`). Die Einstellung „Effekte“ schaltet alle drei Ebenen ab; das Tagbild blendet trotzdem, es ist der Hintergrund selbst.
## Das Cockpit meldet nur Phase, Wolfsschritt, Akt, Tote, Sitzplätze und Einstellungen.

const DAY_FADE_SECONDS := 2.0

var _day_art: TextureRect = null
var _map := VillageMap.new()
var _parts: Array[VillagePart] = []
var _night: bool = false
var _day: bool = false
var _reduced: bool = false
var _phase_known: bool = false
var _day_tween: Tween = null


## Verbindet Tagbild und Dorf-Ebene (`layer`, volle Fläche hinter allen Bedienflächen) und legt die drei Ebenen an.
func configure(day_art: TextureRect, layer: Control) -> void:
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


func _on_resized(layer: Control) -> void:
	_map.area = layer.size
	for part: VillagePart in _parts:
		part._relayout()
