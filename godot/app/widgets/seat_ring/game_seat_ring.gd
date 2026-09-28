class_name GameSeatRing
extends Control
## Sitzkreis des Cockpits: Plätze der laufenden Partie im Uhrzeigersinn (Anordnung wie im Setup,
## SeatCircle.layout), in der Mitte ein freier Bereich `%RingCenter`. Reine Darstellung:
##   show_seats(seats)            öffentliche Sitzdaten (ohne Rollen)
##   set_marking(mode, allowed, selected, actors)
##                                mit Auswahlmodus: nur `allowed` antippbar, `selected` gold; ohne
##                                Auswahlmodus: handelnde Personen (`actors`) hervorgehoben.
## Meldet Antippen über `seat_tapped`; was daraus folgt, entscheidet die Ansicht.

signal seat_tapped(person_id: int)

const COMPACT_FROM := 13            ## ab so vielen Personen kompakte Platzhöhe
## Mindestbreiten je Stufe: zuerst lesbarere Plätze, dann schmalere, bevor SeatCircle auf zwei Reihen
## zurückfällt (etwa zehn bzw. acht Zeichen Name neben der Platznummer).
const TOKEN_WIDTH_STEPS: Array[float] = [120.0, 104.0, 96.0]

var _tokens: Dictionary[int, GameSeatToken] = {}
var _order: Array[int] = []
var _selection_mode: bool = false
var _allowed: Array = []
var _selected: Array = []
var _actors: Array = []

@onready var _center: Control = %RingCenter


func _ready() -> void:
	resized.connect(_layout)


func show_seats(seats: Array) -> void:
	var ids: Array[int] = []
	for seat: Variant in seats:
		ids.append(int((seat as Dictionary)["person_id"]))
	for id: int in _tokens.keys():
		if not ids.has(id):
			_tokens[id].queue_free()
			_tokens.erase(id)
	for seat: Variant in seats:
		var d: Dictionary = seat
		var id := int(d["person_id"])
		if not _tokens.has(id):
			var token := GameSeatToken.new()
			token.name = "Seat_%d" % id
			token.setup(id)
			token.tapped.connect(_on_tapped)
			add_child(token)
			_tokens[id] = token
		_tokens[id].show_seat(d)
	_order = ids
	_layout()
	_apply_states()


## Auswahlmodus an (`allowed` nicht leer oder `selection_mode`) oder aus.
func set_marking(selection_mode: bool, allowed: Array, selected: Array, actors: Array) -> void:
	_selection_mode = selection_mode
	_allowed = allowed.duplicate()
	_selected = selected.duplicate()
	_actors = actors.duplicate()
	_apply_states()


func clear_marking() -> void:
	set_marking(false, [], [], [])


func tokens() -> Array[GameSeatToken]:
	var out: Array[GameSeatToken] = []
	for id: int in _order:
		out.append(_tokens[id])
	return out


func token_for(person_id: int) -> GameSeatToken:
	return _tokens.get(person_id, null)


func center() -> Control:
	return _center


func _on_tapped(person_id: int) -> void:
	if _selection_mode and not _allowed.has(person_id):
		return
	seat_tapped.emit(person_id)


func _apply_states() -> void:
	for id: int in _tokens:
		var token := _tokens[id]
		var state := &"normal" if token.alive else &"dead"
		if _selection_mode:
			if _selected.has(id):
				state = &"selected"
			elif _allowed.has(id):
				state = &"allowed"
		elif _actors.has(id):
			state = &"actor"
		token.state = state
		token.disabled = _selection_mode and not _allowed.has(id) and not _selected.has(id)


func _layout() -> void:
	if not is_node_ready():
		return
	var height := float(ThemeTokens.TOUCH_MIN) if _order.size() >= COMPACT_FROM else float(ThemeTokens.BUTTON_SECONDARY_HEIGHT)
	var result := {}
	for width: float in TOKEN_WIDTH_STEPS:
		result = SeatCircle.layout(_order.size(), size, height, width)
		if SeatCircle.fits(result, size):
			break
	var rects: Array = result["seats"]
	for i: int in _order.size():
		var r: Rect2 = rects[i]
		_tokens[_order[i]].position = r.position
		_tokens[_order[i]].size = r.size
	var c: Rect2 = result["center"]
	_center.position = c.position
	_center.size = c.size
