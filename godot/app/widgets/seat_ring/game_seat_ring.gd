class_name GameSeatRing
extends Control
## Sitzkreis des Cockpits: Porträtplätze der laufenden Partie im Uhrzeigersinn auf einer Ellipse (PortraitRingLayout),
## in der Mitte ein freier Bereich `%RingCenter`. Reine Darstellung:
##   show_seats(seats)            öffentliche Sitzdaten (ohne Rollen)
##   set_marks(marks)             geheime Zustandsabzeichen je Person (Person-ID → Arten), nur für die Spielleitung
##   set_secrets_visible(on)      aus bei „Verbergen“: keine Abzeichen, keine Statusringe, keine Hervorhebung handelnder Personen
##   set_marking(mode, allowed, selected, actors)
##                                mit Auswahlmodus: nur `allowed` antippbar, `selected` gold; ohne
##                                Auswahlmodus: handelnde Personen (`actors`) hervorgehoben.
## Meldet Antippen über `seat_tapped`; was daraus folgt, entscheidet die Ansicht.

signal seat_tapped(person_id: int)

var _tokens: Dictionary[int, GameSeatToken] = {}
var _order: Array[int] = []
var _selection_mode: bool = false
var _allowed: Array = []
var _selected: Array = []
var _actors: Array = []
var _marks: Dictionary = {}
var _secrets_visible: bool = true

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


## Geheime Zustandsabzeichen (Person-ID → Arten). Wirken nur, solange Geheimes sichtbar ist.
func set_marks(marks: Dictionary) -> void:
	_marks = marks.duplicate()
	_apply_states()


## „Verbergen“: ohne Geheimes zeigt der Kreis nur Namen, Porträts und tot oder lebendig (plus Bedienmarkierung der Zielwahl).
func set_secrets_visible(visible_secrets: bool) -> void:
	_secrets_visible = visible_secrets
	_apply_states()


func secrets_visible() -> bool:
	return _secrets_visible


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
		elif _actors.has(id) and _secrets_visible:
			state = &"actor"
		token.state = state
		token.secrets_visible = _secrets_visible
		token.marks = _marks.get(id, []) if _secrets_visible else []
		token.disabled = _selection_mode and not _allowed.has(id) and not _selected.has(id)


func _layout() -> void:
	if not is_node_ready():
		return
	var result := PortraitRingLayout.layout(_order.size(), size)
	var rects: Array = result["seats"]
	for i: int in _order.size():
		var r: Rect2 = rects[i]
		var token := _tokens[_order[i]]
		token.diameter = float(result["diameter"])
		token.plate_limit = float((result["plate_widths"] as Array)[i])
		token.plate_span = (result["plate_spans"] as Array)[i]
		token.position = r.position
		token.size = r.size
	var c: Rect2 = result["center"]
	_center.position = c.position
	_center.size = c.size
