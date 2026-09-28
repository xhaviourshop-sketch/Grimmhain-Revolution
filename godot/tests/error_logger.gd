class_name TestErrorLogger
extends Logger
## Zählt Laufzeitfehler (SCRIPT ERROR, Engine-Fehler, Shaderfehler) während der Tests. Der Runner
## wertet jeden Test, in dem ein solcher Fehler auftritt, als fehlgeschlagen. Warnungen zählen nicht.

var _mutex := Mutex.new()
var _messages: Array[String] = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
		error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var text := rationale if rationale != "" else code
	_mutex.lock()
	_messages.append("%s (%s:%d, %s)" % [text, file, line, function])
	_mutex.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


## Seit dem letzten Aufruf gesammelte Fehler; leert die Liste.
func take() -> Array[String]:
	_mutex.lock()
	var out := _messages.duplicate()
	_messages.clear()
	_mutex.unlock()
	return out
