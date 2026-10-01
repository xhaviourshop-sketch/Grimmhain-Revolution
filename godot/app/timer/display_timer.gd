class_name DisplayTimer
extends RefCounted
## Anzeige-Timer für Tagphase, Diskussion und (optional) Nacht (DECISIONS.md, „Einstellbarer Anzeige-Timer“). Reine Anzeige:
## Er sendet nie einen Befehl, ändert keinen Spielzustand, zieht keinen Zufall und hat bei Ablauf keine Regelwirkung.
## Außerhalb des Regelkerns und des Spielstands (`core`): Er gehört zur Oberfläche und wird als eigener Block `ui` in der
## Hülle der Speicherdatei abgelegt (SaveService). Gespeichert werden nur Zahlen: Dauer je Phasengruppe, Restzeit, Pausenzustand.
## Keine Wanduhrzeit, deshalb kein Zeitsprung nach Laden oder Fortsetzen.
##
## Phasengruppen: "day" (Morgenauflösung und Tag, inklusive Diskussion) und "night". Je Gruppe stellt die Spielleitung die
## Dauer ein (0 = nicht eingestellt, Standard: nichts erfunden). Beim Wechsel der Gruppe beginnt die Restzeit mit der Dauer der
## neuen Gruppe und steht still, bis die Spielleitung startet. Bei Ablauf bleibt die Anzeige auf 0 stehen (kein Signal, kein Ton).

signal changed

const GROUP_DAY := &"day"
const GROUP_NIGHT := &"night"
const MAX_SECONDS := 6 * 3600
const STEP_SECONDS := 60

var durations: Dictionary = {"day": 0, "night": 0}  ## eingestellte Dauer je Gruppe in Sekunden, 0 = nicht eingestellt
var remaining: float = 0.0                           ## Restzeit der aktuellen Gruppe in Sekunden
var running: bool = false
var group: StringName = &""                          ## Gruppe, zu der `remaining` gehört; leer außerhalb von Tag und Nacht


## Gruppe zu einer Phase (String aus der Cockpit-Sicht) oder leer.
static func group_of_phase(phase: String) -> StringName:
	if phase == "NIGHT":
		return GROUP_NIGHT
	if phase == "DAY" or phase == "DAWN_RESOLUTION":
		return GROUP_DAY
	return &""


## Anzeige „M:SS“ (bzw. „H:MM:SS“ ab einer Stunde); negative Werte zeigen 0:00.
static func format_seconds(seconds: float) -> String:
	var total := maxi(0, ceili(seconds))
	var h := floori(total / 3600.0)
	var m := floori((total % 3600) / 60.0)
	var s := total % 60
	return "%d:%02d:%02d" % [h, m, s] if h > 0 else "%d:%02d" % [m, s]


func duration() -> int:
	return int(durations.get(String(group), 0)) if group != &"" else 0


## Eine Dauer ist eingestellt, wenn die aktuelle Gruppe eine hat.
func is_set() -> bool:
	return duration() > 0


func is_expired() -> bool:
	return is_set() and remaining <= 0.0


## Phasenwechsel: bei neuer Gruppe beginnt die Restzeit mit deren Dauer, gestoppt. Gleiche Gruppe: unverändert.
func switch_group(new_group: StringName) -> void:
	if new_group == group:
		return
	group = new_group
	remaining = float(duration())
	running = false
	changed.emit()


## Stellt die Dauer einer Gruppe ein (0 bis MAX_SECONDS). Gilt sie für die aktuelle Gruppe, beginnt die Restzeit neu, gestoppt.
func set_duration(for_group: StringName, seconds: int) -> bool:
	if for_group != GROUP_DAY and for_group != GROUP_NIGHT:
		return false
	var clamped := clampi(seconds, 0, MAX_SECONDS)
	durations[String(for_group)] = clamped
	if for_group == group:
		remaining = float(clamped)
		running = false
	changed.emit()
	return true


func adjust_duration(for_group: StringName, delta_seconds: int) -> bool:
	return set_duration(for_group, int(durations.get(String(for_group), 0)) + delta_seconds)


func start() -> void:
	if not is_set() or running:
		return
	if remaining <= 0.0:
		remaining = float(duration())
	running = true
	changed.emit()


func pause() -> void:
	if not running:
		return
	running = false
	changed.emit()


func toggle() -> void:
	if running:
		pause()
	else:
		start()


## Restzeit zurück auf die Dauer, gestoppt.
func reset() -> void:
	remaining = float(duration())
	running = false
	changed.emit()


## Neue Partie: alles leer.
func clear() -> void:
	durations = {"day": 0, "night": 0}
	remaining = 0.0
	running = false
	group = &""
	changed.emit()


## Lässt `delta` Sekunden vergehen (vom Cockpit je Frame, nur solange es sichtbar ist). Ablauf: Anzeige bleibt auf 0, Timer steht.
## Meldet `changed` nur bei einem Zustandswechsel (Ablauf), nicht je Frame; die Anzeige liest `remaining` selbst.
func tick(delta: float) -> void:
	if not running or delta <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0:
		running = false
		changed.emit()


## Nur Zahlen und Wahrheitswerte; leer, solange nichts eingestellt wurde (die Datei bleibt dann unverändert).
func to_dict() -> Dictionary:
	if int(durations["day"]) == 0 and int(durations["night"]) == 0:
		return {}
	return {"timer": {"day": int(durations["day"]), "night": int(durations["night"]), "group": String(group),
		"remaining": snappedf(remaining, 0.001), "running": running}}


## Übernimmt einen gespeicherten Block. Ungültige Werte werden als Ganzes abgelehnt (false, Timer bleibt wie er war).
func from_dict(ui: Dictionary) -> bool:
	if not ui.has("timer"):
		clear()
		return true
	var t: Variant = ui["timer"]
	if not t is Dictionary:
		return false
	var d: Dictionary = t
	for key: String in ["day", "night"]:
		if not _is_whole(d.get(key)) or int(d[key]) < 0 or int(d[key]) > MAX_SECONDS:
			return false
	if not (d.get("group") is String) or not ["", "day", "night"].has(d["group"]):
		return false
	if not (d.get("remaining") is float or d.get("remaining") is int) or not is_finite(float(d["remaining"])):
		return false
	if not d.get("running") is bool:
		return false
	var loaded_group := StringName(str(d["group"]))
	var limit := float(int(d[str(d["group"])])) if loaded_group != &"" else 0.0
	var rest := float(d["remaining"])
	if rest < 0.0 or rest > limit:
		return false
	durations = {"day": int(d["day"]), "night": int(d["night"])}
	group = loaded_group
	remaining = rest
	running = bool(d["running"]) and rest > 0.0
	changed.emit()
	return true


static func _is_whole(v: Variant) -> bool:
	return (v is int) or (v is float and is_finite(v) and v == floorf(v))
