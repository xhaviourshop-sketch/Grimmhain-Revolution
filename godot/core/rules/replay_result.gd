class_name ReplayResult
extends RefCounted
## Ergebnis von RulesEngine.replay. Bei Fehler zeigt `failed_index` auf den
## abgelehnten Befehl; `state`/`events` enthalten den Stand davor.

var ok: bool = false
var error: StringName = &""
var failed_index: int = -1
var state: GameState = null
var events: Array[GameEvent] = []
