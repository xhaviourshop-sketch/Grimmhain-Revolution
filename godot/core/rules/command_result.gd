class_name CommandResult
extends RefCounted
## Ergebnis von RulesEngine.apply. Bei Ablehnung ist `state` null und `events` leer.

var ok: bool = false
var error: StringName = &""
var state: GameState = null
var events: Array[GameEvent] = []


static func accepted(p_state: GameState, p_events: Array[GameEvent]) -> CommandResult:
	var r := CommandResult.new()
	r.ok = true
	r.state = p_state
	r.events = p_events
	return r


static func rejected(p_error: StringName) -> CommandResult:
	var r := CommandResult.new()
	r.error = p_error
	return r
