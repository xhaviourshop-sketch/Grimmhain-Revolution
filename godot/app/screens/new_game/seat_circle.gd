class_name SeatCircle
extends Control
## Sitzkreis im Querformat: Plätze als Ring um einen Tisch, im Uhrzeigersinn nummeriert (Platz 1
## oben links: obere Reihe nach rechts, rechte Seite nach unten, untere Reihe nach links, linke Seite
## nach oben). Die Aufteilung auf Reihen und Seiten folgt aus Personenzahl und Fläche, sodass Namen
## lesbar bleiben (Mindestbreite je Platz) und sich nichts überlappt. In der Tischmitte liegt
## `TableCenter` mit Hinweisen und Bestätigung.
## Reine Darstellung: meldet Antippen, Ablegen und Abbrechen; tauschen entscheidet PlayerSetup.

signal seat_tapped(person_id: int)
signal swap_requested(source_id: int, target_id: int)
signal drag_begun(person_id: int)
signal drag_cancelled(person_id: int)

const TOKEN_SCRIPT := preload("res://app/screens/new_game/seat_token.gd")
const GAP := float(ThemeTokens.SPACE_S)
const TOKEN_HEIGHT := float(ThemeTokens.BUTTON_SECONDARY_HEIGHT)
const TOKEN_MIN_WIDTH := 120.0   ## etwa zwölf Zeichen in Kompaktschrift
const TOKEN_MAX_WIDTH := 220.0

var _tokens: Dictionary[int, SeatToken] = {}
var _order: Array[int] = []
var _selected_id: int = 0
var _dragging_id: int = 0
var _target_id: int = 0

@onready var _center: Control = %TableCenter


func _ready() -> void:
	resized.connect(_layout)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging_id != 0:
		drag_finished(get_viewport().gui_is_drag_successful())


## Plätze aus der Sitzsicht anzeigen. Symbole bleiben je Person erhalten und wandern beim Tausch.
func show_seats(seats: Array) -> void:
	var ids: Array[int] = []
	for seat: Variant in seats:
		ids.append(int((seat as Dictionary)["person_id"]))
	for id: int in _tokens.keys():
		if not ids.has(id):
			_tokens[id].queue_free()
			_tokens.erase(id)
	for seat: Variant in seats:
		var s: Dictionary = seat
		var id := int(s["person_id"])
		if not _tokens.has(id):
			_tokens[id] = _create_token(id)
		_tokens[id].show_seat(int(s["seat"]), str(s["name"]))
	_order = ids
	if not _tokens.has(_selected_id):
		_selected_id = 0
	_layout()
	_apply_states()


func tokens() -> Array[SeatToken]:
	var out: Array[SeatToken] = []
	for id: int in _order:
		out.append(_tokens[id])
	return out


func token_for(person_id: int) -> SeatToken:
	return _tokens.get(person_id, null)


func set_selected(person_id: int) -> void:
	_selected_id = person_id if _tokens.has(person_id) else 0
	_apply_states()


## Ende eines Ziehvorgangs (auch ohne Ablage auf einem Platz): Zustände zurücksetzen; ohne
## erfolgreiche Ablage `drag_cancelled` melden.
func drag_finished(successful: bool) -> void:
	var source := _dragging_id
	_dragging_id = 0
	_target_id = 0
	_apply_states()
	if not successful and source != 0:
		drag_cancelled.emit(source)


## Ablage auf freier Fläche des Kreises: kein Ziel (Hervorhebung weg), nicht annehmen.
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	_set_target(0)
	return false


func _create_token(person_id: int) -> SeatToken:
	var token := TOKEN_SCRIPT.new() as SeatToken
	token.name = "Seat_%d" % person_id
	token.setup(person_id)
	add_child(token)
	token.tapped.connect(seat_tapped.emit)
	token.drag_begun.connect(_on_drag_begun)
	token.drop_hovered.connect(_set_target)
	token.dropped.connect(_on_dropped)
	token.mouse_exited.connect(func() -> void:
		if _target_id == person_id:
			_set_target(0))
	return token


func _on_drag_begun(person_id: int) -> void:
	_dragging_id = person_id
	_selected_id = 0
	_apply_states()
	drag_begun.emit(person_id)


func _on_dropped(source_id: int, target_id: int) -> void:
	_dragging_id = 0
	_target_id = 0
	_apply_states()
	swap_requested.emit(source_id, target_id)


func _set_target(person_id: int) -> void:
	if _target_id != person_id:
		_target_id = person_id
		_apply_states()


func _apply_states() -> void:
	for id: int in _tokens:
		var state := &"normal"
		if id == _dragging_id:
			state = &"dragging"
		elif id == _target_id and _dragging_id != 0:
			state = &"target"
		elif id == _selected_id:
			state = &"selected"
		_tokens[id].state = state


# --- Anordnung ----------------------------------------------------------------------------------------

func _layout() -> void:
	if not is_node_ready():
		return
	var result := layout(_order.size(), size)
	var rects: Array = result["seats"]
	for i: int in _order.size():
		var token := _tokens[_order[i]]
		var r: Rect2 = rects[i]
		token.position = r.position
		token.size = r.size
	var center: Rect2 = result["center"]
	_center.position = center.position
	_center.size = center.size


## Platzrechtecke in Sitzreihenfolge und die freie Tischmitte für `count` Plätze in `area`.
## Wählt die Zahl der Plätze je Reihe so, dass die Plätze mindestens TOKEN_MIN_WIDTH breit sind,
## die Seiten passen und Reihen- und Seitenabstand möglichst ähnlich sind (ringförmiger Eindruck).
## `token_height` und `min_width` erlauben dem Cockpit kompaktere Plätze bei vielen Personen.
static func layout(count: int, area: Vector2, token_height: float = TOKEN_HEIGHT, min_width: float = TOKEN_MIN_WIDTH) -> Dictionary:
	var h := token_height
	var span := area.y - 2.0 * h - 2.0 * GAP
	var best := {}
	var best_score := INF
	for top: int in range(1, count + 1):
		var bottom := mini(top, count - top)
		var side := count - top - bottom
		var right := ceili(side / 2.0)
		var left := side - right
		if bottom < 1 or (count >= 4 and left < 1):
			continue
		var w := minf(TOKEN_MAX_WIDTH, (area.x - (top - 1) * GAP) / top)
		if w < min_width:
			break
		if right * h + (right + 1) * GAP > span:
			continue
		var score := absf(area.x / top - span / (right + 1))
		if score < best_score:
			best_score = score
			best = {"top": top, "bottom": bottom, "right": right, "left": left, "width": w}
	if best.is_empty():  # zu wenig Fläche: zwei Reihen, Mindestgröße für Touch
		var top := ceili(count / 2.0)
		best = {"top": top, "bottom": count - top, "right": 0, "left": 0,
				"width": maxf(float(ThemeTokens.TOUCH_MIN), (area.x - (top - 1) * GAP) / maxi(top, 1))}
	var w: float = best["width"]
	var seats: Array[Rect2] = []
	_row(seats, best["top"], w, 0.0, area.x, false, h)
	_column(seats, best["right"], w, area.x - w, area.y, false, h)
	_row(seats, best["bottom"], w, area.y - h, area.x, true, h)
	_column(seats, best["left"], w, 0.0, area.y, true, h)
	var inset_x := w + 2.0 * GAP if int(best["right"]) + int(best["left"]) > 0 else 0.0
	var center := Rect2(inset_x, h + 2.0 * GAP, area.x - 2.0 * inset_x, area.y - 2.0 * (h + 2.0 * GAP))
	return {"seats": seats, "center": center}


## true, wenn alle Plätze in `area` liegen (kein Rückfall auf zwei zu schmale Reihen nötig).
static func fits(result: Dictionary, area: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, area).grow(0.5)
	for r: Rect2 in result.get("seats", []):
		if not bounds.encloses(r) or r.size.x < TOKEN_MIN_WIDTH * 0.75:
			return false
	return true


static func _row(out: Array[Rect2], n: int, w: float, y: float, width: float, reverse: bool, h: float = TOKEN_HEIGHT) -> void:
	if n <= 0:
		return
	var gap := GAP if n == 1 else clampf((width - n * w) / (n - 1), GAP, w * 0.5)
	var x0 := (width - (n * w + (n - 1) * gap)) / 2.0
	var row: Array[Rect2] = []
	for i: int in n:
		row.append(Rect2(x0 + i * (w + gap), y, w, h))
	if reverse:
		row.reverse()
	out.append_array(row)


static func _column(out: Array[Rect2], n: int, w: float, x: float, height: float, reverse: bool, h: float = TOKEN_HEIGHT) -> void:
	if n <= 0:
		return
	var top := h + GAP
	var span := height - 2.0 * top
	var spacing := (span - n * h) / (n + 1)
	var column: Array[Rect2] = []
	for i: int in n:
		column.append(Rect2(x, top + spacing + i * (h + spacing), w, h))
	if reverse:
		column.reverse()
	out.append_array(column)
