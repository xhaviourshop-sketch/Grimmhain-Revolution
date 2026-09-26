class_name LoadResult
extends RefCounted
## Ergebnis von StateCodec.decode. Bei Fehler ist `state` null.

var ok: bool = false
var error: StringName = &""
var state: GameState = null
var commands: Array[Command] = []
var events: Array[GameEvent] = []  ## per Replay aus `commands` wiederhergestellt


static func failed(p_error: StringName) -> LoadResult:
	var r := LoadResult.new()
	r.error = p_error
	return r
