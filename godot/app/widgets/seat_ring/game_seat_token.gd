class_name GameSeatToken
extends GrimmButton
## Ein Platz im Cockpit-Sitzkreis: Platznummer und Name, bei Toten zusätzlich „†“, bei heutiger
## Nominierung ein Zeichen. Zeigt nie eine Rolle. Zustände über die Theme-Variation; Information
## hängt nie allein an der Farbe: Text trägt Tod („†“), Nominierung („(N)“), wählbares Ziel („›“), Auswahl („✓“)
## und handelnde Person („•“); deaktiviert = nicht wählbar.

signal tapped(person_id: int)

const STATE_VARIATIONS := {
	&"normal": &"SeatButton",
	&"dead": &"SeatDeadButton",
	&"allowed": &"SeatTargetButton",
	&"selected": &"SeatSelectedButton",
	&"actor": &"SeatActorButton",
}

var person_id: int = 0
## Textzeichen je Zustand; zusätzlich zur Farbe, damit Ziel, Auswahl und handelnde Person ohne Farbsehen erkennbar sind.
const STATE_MARKS := {&"allowed": "› ", &"selected": "✓ ", &"actor": "• "}

var alive: bool = true
var _nominated: bool = false
var _seat: Dictionary = {}
var state: StringName = &"normal":
	set(value):
		state = value
		theme_type_variation = STATE_VARIATIONS.get(value, &"SeatButton")
		_show()


func setup(p_person_id: int) -> void:
	person_id = p_person_id
	kind = Kind.COMPACT
	wrap = false
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	pressed.connect(func() -> void: tapped.emit(person_id))
	state = &"normal"


## Anschlussstelle für spätere Porträts (öffentliches Bild der Person, nie ein Rollenbild). Bis dahin leer.
func set_portrait(texture: Texture2D) -> void:
	icon = texture
	expand_icon = texture != null


## Öffentliche Sitzdaten: {seat, name, alive, nominated_today}.
func show_seat(seat: Dictionary) -> void:
	alive = bool(seat.get("alive", true))
	_nominated = bool(seat.get("nominated_today", false))
	_seat = seat
	tooltip_text = str(seat["name"])
	_show()


func _show() -> void:
	if _seat.is_empty():
		return
	format_values = {"mark": STATE_MARKS.get(state, ""), "number": int(_seat["seat"]), "name": str(_seat["name"])}
	var key := "ui.cockpit.seat.alive"
	if not alive:
		key = "ui.cockpit.seat.dead"
	elif _nominated:
		key = "ui.cockpit.seat.nominated"
	text_key = key
