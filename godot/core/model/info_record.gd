class_name InfoRecord
extends RefCounted
## Abgeschlossene Information einer Informationsrolle (G-INF-1, DR-07): Wahrheit,
## ermitteltes und gezeigtes Ergebnis getrennt. Entsteht erst mit der Bestätigung
## „Gezeigt“ und bleibt als Protokoll der ganzen Partie im Spielzustand.

var id: int = 0                    ## fortlaufende Informations-ID
var oracle_id: int = -1            ## prüfende Person
var target_id: int = -1            ## geprüfte Person
var night: int = 0
var truth_role: StringName = &""       ## tatsächliche `role_id` des Ziels zum Prüfzeitpunkt
var determined_role: StringName = &""  ## InformationRules.determine_role
var shown_role: StringName = &""       ## dem Orakel gezeigtes Ergebnis
var overridden: bool = false           ## gezeigt weicht durch Übersteuerung von ermittelt ab
var override_reason: String = ""
var command_index: int = 0         ## Befehl der Bestätigung „Gezeigt“


func to_dict() -> Dictionary:
	return {
		"id": id,
		"oracle_id": oracle_id,
		"target_id": target_id,
		"night": night,
		"truth_role": String(truth_role),
		"determined_role": String(determined_role),
		"shown_role": String(shown_role),
		"overridden": overridden,
		"override_reason": override_reason,
		"command_index": command_index,
	}


## Strukturprüfung; ob die Personen existieren, prüft GameState.from_dict.
static func from_dict(d: Dictionary) -> InfoRecord:
	var r := InfoRecord.new()
	r.id = DictRead.get_int(d, "id")
	r.oracle_id = DictRead.get_int(d, "oracle_id", -1)
	r.target_id = DictRead.get_int(d, "target_id", -1)
	r.night = DictRead.get_int(d, "night")
	r.truth_role = StringName(DictRead.get_string(d, "truth_role"))
	r.determined_role = StringName(DictRead.get_string(d, "determined_role"))
	r.shown_role = StringName(DictRead.get_string(d, "shown_role"))
	r.overridden = DictRead.get_bool(d, "overridden")
	r.override_reason = DictRead.get_string(d, "override_reason")
	r.command_index = DictRead.get_int(d, "command_index", -1)
	if r.id < 1 or r.oracle_id < 1 or r.target_id < 1 or r.oracle_id == r.target_id or r.night < 1 or r.command_index < 0:
		return null
	for role: StringName in [r.truth_role, r.determined_role, r.shown_role]:
		if not RoleCatalog.has_role(role):
			return null
	if r.overridden != (r.shown_role != r.determined_role) or (r.overridden and r.override_reason.strip_edges() == ""):
		return null
	return r
