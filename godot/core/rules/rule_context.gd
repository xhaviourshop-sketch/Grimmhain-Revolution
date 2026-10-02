class_name RuleContext
extends RefCounted
## Arbeitskontext während der Anwendung eines Befehls: veränderbare Zustandskopie
## plus Sammelstelle für Ereignisse. Regeln ändern den Zustand nur hierüber.

var state: GameState
var command_index: int
var events: Array[GameEvent] = []
var deaths: int = 0
var card_depth: int = 0  ## > 0, solange eine Totenreichkarte tötet: Folgen dieses Tods lösen keine Karte erneut aus (Kosmisches Gleichgewicht)


func _init(p_state: GameState, p_command_index: int) -> void:
	state = p_state
	command_index = p_command_index


func emit(type: StringName, visibility: StringName, data: Dictionary = {}, actor_id: int = -1) -> void:
	var e := GameEvent.new()
	e.index = state.next_event_index
	state.next_event_index += 1
	e.command_index = command_index
	e.type = type
	e.visibility = visibility
	e.actor_id = actor_id
	e.data = CanonicalJson.normalize(data)
	events.append(e)
