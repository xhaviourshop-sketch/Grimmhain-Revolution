class_name GameSeatToken
extends GrimmButton
## Ein Platz im Cockpit-Sitzkreis: Platznummer und Name, bei Toten zusätzlich „†“, bei heutiger
## Nominierung ein Zeichen. Zeigt nie eine Rolle. Zustände über die Theme-Variation; Information
## hängt nie allein an der Farbe (Text trägt Tod und Nominierung, deaktiviert = nicht wählbar).

signal tapped(person_id: int)

const STATE_VARIATIONS := {
	&"normal": &"SeatButton",
	&"dead": &"SeatDeadButton",
	&"allowed": &"SeatTargetButton",
	&"selected": &"SeatSelectedButton",
	&"actor": &"SeatActorButton",
}

var person_id: int = 0
var alive: bool = true
var state: StringName = &"normal":
	set(value):
		state = value
		theme_type_variation = STATE_VARIATIONS.get(value, &"SeatButton")


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


## Öffentliche Sitzdaten: {seat, name, alive, nominated_today}.
func show_seat(seat: Dictionary) -> void:
	alive = bool(seat.get("alive", true))
	format_values = {"number": int(seat["seat"]), "name": str(seat["name"])}
	var key := "ui.cockpit.seat.alive"
	if not alive:
		key = "ui.cockpit.seat.dead"
	elif bool(seat.get("nominated_today", false)):
		key = "ui.cockpit.seat.nominated"
	text_key = key
	tooltip_text = str(seat["name"])
