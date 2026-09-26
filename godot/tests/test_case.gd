class_name TestCase
extends RefCounted
## Basisklasse für headless Tests. Jede Methode mit Präfix `test_` wird vom
## Runner (tests/run_tests.gd) aufgerufen. Fehlschläge werden gesammelt, nicht geworfen.

var failures: Array[String] = []
var assertions: int = 0


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
