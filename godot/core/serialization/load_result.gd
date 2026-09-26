class_name LoadResult
extends RefCounted
## Ergebnis von StateCodec.decode. Bei Fehler ist `state` null.

var ok: bool = false
var error: StringName = &""
var detail: String = ""  ## lesbare Zusatzinformation, z. B. gefundene und erwartete Version
var state: GameState = null
var commands: Array[Command] = []
var events: Array[GameEvent] = []  ## per Replay aus `commands` wiederhergestellt


static func failed(p_error: StringName, p_detail: String = "") -> LoadResult:
	var r := LoadResult.new()
	r.error = p_error
	r.detail = p_detail
	return r
