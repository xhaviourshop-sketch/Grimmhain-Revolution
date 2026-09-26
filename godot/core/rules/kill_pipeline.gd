class_name KillPipeline
extends RefCounted
## Grundlegende Tötungs-Pipeline (A-16, 03 §5.4) ohne Abfangregeln:
##   1. Ziel tot? → abbrechen (protokolliert)
##   2. Tod anwenden → KillEvent mit Ursache, Quelle, Ziel, Zeitpunkt, Abfangstatus
##   3. Ereignis SeatDied
##   4. Todesfolgen: Reaktion der Rolle einreihen (nur mit trigger_effects, G-TOD-2)
##   5. vorläufiger Siegstatus (DR-14); die verbindliche Prüfung folgt am Befehlsende,
##      sobald keine Reaktion mehr offen ist
## Abfangregeln (Schutz, Rettung, Spiegelung) kommen mit B-04.


static func request_kill(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName, source_id: int = -1, trigger_effects: bool = true) -> KillEvent:
	var s := ctx.state
	var target: Player = s.players.get(target_id)
	if target == null or not target.alive:
		ctx.emit(GameEvent.KILL_IGNORED, Visibility.GM, {
			"target_id": target_id, "cause": cause, "reason": "target_not_alive",
		})
		return null
	var record := KillEvent.new()
	record.target_id = target_id
	record.cause = cause
	record.source_kind = source_kind
	record.source_id = source_id
	record.phase = s.phase
	record.phase_number = s.night_number if (s.phase == Phase.NIGHT or s.phase == Phase.DAWN_RESOLUTION) else s.day_number
	record.order_index = s.next_death_order
	s.next_death_order += 1
	target.alive = false
	target.death = record
	ctx.deaths += 1
	# Nur Spielleiter: Was öffentlich verkündet wird, entscheidet DR-04 (offen).
	ctx.emit(GameEvent.SEAT_DIED, Visibility.GM, record.to_dict())
	if trigger_effects:
		_queue_reaction(ctx, target, record)
	WinRules.record_provisional(ctx, record)
	return record


## Reiht die Todesreaktion der Rolle ein (falls vorhanden). Reihenfolge = Einreihung.
static func _queue_reaction(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	var kind := RoleCatalog.death_reaction(target.role_id)
	if kind == &"":
		return
	var s := ctx.state
	var reaction := Reaction.new()
	reaction.id = s.next_reaction_id
	s.next_reaction_id += 1
	reaction.kind = kind
	reaction.owner_id = target.id
	reaction.trigger_order = record.order_index
	s.reactions.append(reaction)
	ctx.emit(GameEvent.REACTION_QUEUED, Visibility.GM, {"reaction": reaction.to_dict()})
