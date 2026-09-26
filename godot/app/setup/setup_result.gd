class_name SetupResult
extends RefCounted
## Strukturiertes Ergebnis jeder Setup-Operation.
##   ok          angenommen
##   error       Fehlercode (&"" bei Erfolg): empty_name, invalid_characters, name_too_long,
##               too_many_persons, too_few_persons, unknown_person, invalid_entries, import_empty
##   entries     betroffene Importeinträge [{position (1-basiert), name, error}]
##   warnings    Hinweise ohne Ablehnung, derzeit &"duplicate_name"
##   person_ids  neu angelegte oder geänderte Personen
##   details     Zusatzwerte für Meldungen (max, current, incoming, missing …)
##   view        Sicht nach der Operation

var ok: bool = false
var error: StringName = &""
var entries: Array[Dictionary] = []
var warnings: Array[StringName] = []
var person_ids: Array[int] = []
var details: Dictionary = {}
var view: Dictionary = {}


static func success(p_view: Dictionary, p_ids: Array[int] = [], p_warnings: Array[StringName] = []) -> SetupResult:
	var r := SetupResult.new()
	r.ok = true
	r.view = p_view
	r.person_ids = p_ids
	r.warnings = p_warnings
	return r


static func failure(p_error: StringName, p_view: Dictionary, p_details: Dictionary = {}, p_entries: Array[Dictionary] = []) -> SetupResult:
	var r := SetupResult.new()
	r.error = p_error
	r.view = p_view
	r.details = p_details
	r.entries = p_entries
	return r
