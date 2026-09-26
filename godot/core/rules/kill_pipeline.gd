class_name KillPipeline
extends RefCounted
## Grundlegende Tötungs-Pipeline (A-16, 03 §5.4) ohne Abfangregeln:
##   1. Ziel tot? → abbrechen (protokolliert)
##   2. Tod anwenden → KillEvent mit Ursache, Quelle, Ziel, Zeitpunkt, Abfangstatus
##   3. Ereignis SeatDied
## Die Siegprüfung folgt am Ende des Befehls (RulesEngine), sobald ein Tod eintrat.
## Abfangregeln (Schutz, Rettung, Spiegelung) und Folgetode kommen mit B-04/B-06.


static func request_kill(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName, source_id: int = -1) -> KillEvent:
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
	return record
