class_name GameSession
extends RefCounted
## Anwendungsschicht zwischen UI und Regelkern (03 §3). Einzige Stelle der App, die einen
## `GameState` hält und `RulesEngine.apply` aufruft. Die UI liest nur `view()` (Kopie aus
## einfachen Werten) und sendet Befehle über `submit()`. Keine eigene Regel: Annahme,
## Ablehnung, Ereignisse und Folgezustand kommen unverändert aus dem Regelkern.
## Noch ohne Speichern, Undo und Setup (spätere Arbeitspakete).

signal events_applied(events: Array[GameEvent])  ## nach jedem angenommenen Befehl
signal command_rejected(error: StringName)        ## Befehl abgelehnt, Zustand unverändert
signal view_changed(view: Dictionary)             ## neue Sicht nach Annahme oder Reset

var _state: GameState = GameState.new()
var _commands: Array[Command] = []


## Reicht den Befehl an den Regelkern weiter und übernimmt bei Annahme den neuen Zustand.
func submit(command: Command) -> CommandResult:
	var result := RulesEngine.apply(_state, command)
	if not result.ok:
		command_rejected.emit(result.error)
		return result
	_state = result.state
	_commands.append(command)
	events_applied.emit(result.events)
	view_changed.emit(view())
	return result


## Lesbare Sicht für die Darstellung. Immer eine neue Kopie aus einfachen Werten.
func view() -> Dictionary:
	var started := _state.is_started()
	return {
		"has_game": started,
		"phase": String(_state.phase) if started else "",
		"night_number": _state.night_number,
		"day_number": _state.day_number,
		"player_count": _state.players.size(),
		"command_count": _commands.size(),
	}


## Angenommene Befehle in Reihenfolge (Kopie).
func commands() -> Array[Command]:
	return _commands.duplicate()


## Fachlicher Hash des aktuellen Zustands (Prüfung und spätere Speicheranzeige).
func state_hash() -> String:
	return _state.content_hash()


## Verwirft die Sitzung (kein Spielstand).
func reset() -> void:
	_state = GameState.new()
	_commands.clear()
	view_changed.emit(view())
