class_name KillPipeline
extends RefCounted
## Grundlegende Tötungs-Pipeline (A-16, 03 §5.4) ohne Abfangregeln:
##   1. Ziel tot? → abbrechen (protokolliert)
##   2. Tod anwenden → KillEvent mit Ursache, Quelle, Ziel, Zeitpunkt, Abfangstatus
##   3. Ereignis SeatDied
##   4. Todesfolgen (nur mit trigger_effects, G-TOD-2): zuerst unmittelbare Folgen ohne
##      Entscheidung (Verwandlung von Wolfskindern, DR-10), dann Reaktion der Rolle einreihen
##   5. vorläufiger Siegstatus (DR-14); die verbindliche Prüfung folgt am Befehlsende,
##      sobald keine Reaktion mehr offen ist
## Abfangregeln (vor Schritt 2, nur Rudelangriff): Schutzengel und Rettung der Waldhexe;
## Spiegelung folgt.


static func request_kill(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName, source_id: int = -1, trigger_effects: bool = true) -> KillEvent:
	var s := ctx.state
	var target: Player = s.players.get(target_id)
	if target == null or not target.alive:
		ctx.emit(GameEvent.KILL_IGNORED, Visibility.GM, {
			"target_id": target_id, "cause": cause, "reason": "target_not_alive",
		})
		return null
	if _prevented_by_protection(ctx, target_id, cause, source_kind):
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
		WolfChildRules.on_death(ctx, record)
		_queue_reaction(ctx, target, record)
	WinRules.record_provisional(ctx, record)
	return record


## Abfangstufe: Schutz eines Schutzengels und Rettung einer Waldhexe dieser Nacht
## verhindern ausschließlich den Rudelangriff (`NIGHT_KILL`, Quelle Rudel). Greifen beide,
## entsteht genau ein `KillPrevented` mit beiden Quellen (`sources`, `guardian_ids`,
## `rescuer_ids`); `protection` nennt die erste Quelle. Kein Tod, keine Reaktion, kein
## vorläufiger Siegstatus.
static func _prevented_by_protection(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName) -> bool:
	if cause != KillEvent.CAUSE_NIGHT_KILL or source_kind != KillEvent.SOURCE_PACK:
		return false
	var night := ctx.state.night_number
	var guardians := Protections.guardians_of(ctx.state, target_id, night)
	var rescuers := WitchStep.rescuers_of(ctx.state, target_id, night)
	if guardians.is_empty() and rescuers.is_empty():
		return false
	var sources: Array[StringName] = []
	if not guardians.is_empty():
		sources.append(RoleCatalog.SCHUTZENGEL)
	if not rescuers.is_empty():
		sources.append(RoleCatalog.WALDHEXE)
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {
		"target_id": target_id, "cause": cause, "source_kind": source_kind, "protection": sources[0], "sources": sources,
		"guardian_id": guardians[0] if not guardians.is_empty() else GameState.NO_TARGET, "guardian_ids": guardians,
		"rescuer_ids": rescuers, "night": night,
	})
	return true


## Reiht die Todesreaktion der Rolle ein (falls vorhanden). Reihenfolge = Einreihung.
## Höchstens eine Todesreaktion pro Person und Rolle in der Partie (`ability_uses`).
static func _queue_reaction(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	var kind := RoleCatalog.death_reaction(target.role_id)
	if kind == &"":
		return
	var use_key := "%s:death_reaction" % target.role_id
	if int(target.ability_uses.get(use_key, 0)) >= 1:
		return
	target.ability_uses[use_key] = int(target.ability_uses.get(use_key, 0)) + 1
	var s := ctx.state
	var reaction := Reaction.new()
	reaction.id = s.next_reaction_id
	s.next_reaction_id += 1
	reaction.kind = kind
	reaction.owner_id = target.id
	reaction.trigger_order = record.order_index
	s.reactions.append(reaction)
	ctx.emit(GameEvent.REACTION_QUEUED, Visibility.GM, {"reaction": reaction.to_dict()})
