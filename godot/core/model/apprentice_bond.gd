class_name ApprenticeBond
extends RefCounted
## Bindung eines Lehrlings an einen Meister (rules-register.md §9, DR-11). Ein Datensatz je
## Auswahl; eine Person hat höchstens einen aktiven (`bound`) Datensatz.
##   bound      aktiv: Lehrling lebt, hat die Rolle `lehrling` und erbt beim Tod des Meisters
##   inherited  verbraucht: Erbe ausgeführt; `snapshot` hält den exakten Rollenzustand davor
##   expired    verfallen: Lehrling starb vor dem Erbe (auch Wiederbelebung reaktiviert nichts)
##   removed    entfernt: Spielleiterkorrektur oder Rollenwechsel weg von `lehrling`
## `options` sind die dem Lehrling gezeigten Rollen (nach Rollen-ID sortiert), `option_person_ids`
## die nur intern bekannte Zuordnung gleicher Länge; `master_id` = option_person_ids[chosen_index].
## Einzige Quelle für Bindung und Erbe; Prüfung gegen den übrigen Zustand in ApprenticeRules.

const STATUS_BOUND := &"bound"
const STATUS_INHERITED := &"inherited"
const STATUS_EXPIRED := &"expired"
const STATUS_REMOVED := &"removed"
const STATUSES: Array[StringName] = [STATUS_BOUND, STATUS_INHERITED, STATUS_EXPIRED, STATUS_REMOVED]
## Felder des Rollenzustands vor dem Erbe (exakte Rücknahme).
const SNAPSHOT_KEYS: Array[String] = ["role_id", "faction", "counts_as_wolf", "appears_as", "ability_uses"]

var id: int = 0
var apprentice_id: int = -1
var master_id: int = -1
var options: Array[String] = []
var option_person_ids: Array[int] = []
var chosen_index: int = -1
var status: StringName = STATUS_BOUND
var bound_night: int = 0         ## Nacht der Auswahl oder Korrektur
var bound_command: int = -1      ## Befehl der Bestätigung oder Korrektur
var inherited_role: StringName = &""  ## geerbte Rolle (nur `inherited`)
var inherit_order: int = -1      ## `order_index` des Todes des Meisters (−1 = Spielleiterkorrektur)
var inherit_command: int = -1    ## Befehl des Erbes (nur `inherited`)
var snapshot: Dictionary = {}    ## Rollenzustand des Lehrlings unmittelbar vor dem Erbe (nur `inherited`)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"apprentice_id": apprentice_id,
		"master_id": master_id,
		"options": options.duplicate(),
		"option_person_ids": option_person_ids.duplicate(),
		"chosen_index": chosen_index,
		"status": String(status),
		"bound_night": bound_night,
		"bound_command": bound_command,
		"inherited_role": String(inherited_role),
		"inherit_order": inherit_order,
		"inherit_command": inherit_command,
		"snapshot": snapshot.duplicate(true),
	}


## Strukturprüfung; Bezug zu Personen und Rollen prüft ApprenticeRules.state_is_consistent.
static func from_dict(d: Dictionary) -> ApprenticeBond:
	var b := ApprenticeBond.new()
	b.id = DictRead.get_int(d, "id")
	b.apprentice_id = DictRead.get_int(d, "apprentice_id", -1)
	b.master_id = DictRead.get_int(d, "master_id", -1)
	for item: Variant in DictRead.get_array(d, "options"):
		if not item is String:
			return null
		b.options.append(item)
	var ids: Variant = DictRead.to_int_array(DictRead.get_array(d, "option_person_ids"))
	if ids == null or not d.get("options") is Array or not d.get("option_person_ids") is Array:
		return null
	b.option_person_ids = ids
	b.chosen_index = DictRead.get_int(d, "chosen_index", -1)
	b.status = StringName(DictRead.get_string(d, "status"))
	b.bound_night = DictRead.get_int(d, "bound_night", -1)
	b.bound_command = DictRead.get_int(d, "bound_command", -1)
	b.inherited_role = StringName(DictRead.get_string(d, "inherited_role"))
	b.inherit_order = DictRead.get_int(d, "inherit_order", -2)
	b.inherit_command = DictRead.get_int(d, "inherit_command", -2)
	if not d.get("snapshot") is Dictionary:
		return null
	b.snapshot = (d["snapshot"] as Dictionary).duplicate(true)
	if b.id < 1 or b.apprentice_id < 1 or b.master_id < 1 or not STATUSES.has(b.status):
		return null
	if not [1, 3].has(b.options.size()) or b.option_person_ids.size() != b.options.size():
		return null
	if b.chosen_index < 0 or b.chosen_index >= b.options.size() or b.option_person_ids[b.chosen_index] != b.master_id:
		return null
	if b.bound_night < 0 or b.bound_command < 0:
		return null
	if b.status == STATUS_INHERITED:
		if b.inherited_role == &"" or b.inherit_order < -1 or b.inherit_command < 0 or b.snapshot.is_empty():
			return null
	elif b.inherited_role != &"" or b.inherit_order != -1 or b.inherit_command != -1 or not b.snapshot.is_empty():
		return null
	return b
