class_name TestCase
extends RefCounted
## Basisklasse für headless Tests. Jede Methode mit Präfix `test_` wird vom
## Runner (tests/run_tests.gd) aufgerufen. Fehlschläge werden gesammelt, nicht geworfen.

var failures: Array[String] = []
var assertions: int = 0


## DI-03: Das öffentliche `DeathEffect` ist die ausdrückliche Ausnahme der Geheimhaltungstests (es nennt Effekt und
## Rolle zum Ereigniszeitpunkt). Andere öffentliche Ereignisse bleiben streng. Die Ausnahme gilt nur für genau diese
## Positivliste von Feldern; jedes weitere Feld macht den Test rot.
const DEATH_EFFECT_KEYS: Array = ["effect", "replaced_id", "role_id", "source_id", "target_id"]


func is_death_effect_exception(e: GameEvent) -> bool:
	if String(e.type) != "DeathEffect":
		return false
	var keys: Array = e.data.keys()
	keys.sort()
	assert_eq(keys, DEATH_EFFECT_KEYS, "DeathEffect nur mit der Positivliste")
	assert_eq(String(e.visibility), "public", "DeathEffect öffentlich")
	return true


func fail(message: String) -> void:
	assertions += 1
	failures.append(message)


func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: erwartet <%s>, erhalten <%s>" % [message, str(expected), str(actual)])


func assert_ne(actual: Variant, unexpected: Variant, message: String) -> void:
	assertions += 1
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		failures.append("%s: Wert darf nicht <%s> sein" % [message, str(unexpected)])


# --- Hilfen für Regelkern-Tests -------------------------------------------------

## Wendet einen Befehl an und erwartet Annahme. Liefert das Ergebnis (bei Ablehnung ok = false).
func apply_ok(state: GameState, command: Command, label: String) -> CommandResult:
	var result := RulesEngine.apply(state, command)
	assert_true(result.ok, "%s: %s angenommen (Fehler: %s)" % [label, command.type, result.error])
	return result


## Erwartet Ablehnung mit genau diesem Fehlergrund und unverändertem Zustand.
func apply_rejected(state: GameState, command: Command, expected_error: String, label: String) -> void:
	var before := CanonicalJson.stringify(state.to_dict())
	var result := RulesEngine.apply(state, command)
	assert_false(result.ok, "%s: %s abgelehnt" % [label, command.type])
	assert_eq(String(result.error), expected_error, "%s: Fehlergrund" % label)
	assert_eq(CanonicalJson.stringify(state.to_dict()), before, "%s: Zustand unverändert" % label)


func events_of_type(events: Array[GameEvent], type: String) -> Array[GameEvent]:
	var out: Array[GameEvent] = []
	for e: GameEvent in events:
		if String(e.type) == type:
			out.append(e)
	return out


func events_json(events: Array[GameEvent]) -> String:
	var list: Array = []
	for e: GameEvent in events:
		list.append(e.to_dict())
	return CanonicalJson.stringify(list)


## Der einzige offene Siegkandidat oder null (keiner oder mehrere offen).
func sole_candidate(state: GameState) -> WinCandidate:
	var open := state.open_candidates()
	return open[0] if open.size() == 1 else null
