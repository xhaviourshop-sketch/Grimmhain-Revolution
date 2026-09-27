class_name KillPipeline
extends RefCounted
## Grundlegende Tötungs-Pipeline (A-16, 03 §5.4) ohne Abfangregeln:
##   1. Ziel tot? → abbrechen (protokolliert)
##   2. Tod anwenden → KillEvent mit Ursache, Quelle, Ziel, Zeitpunkt, Abfangstatus
##   3. Ereignis SeatDied
##   4. eine aktive Bindung eines toten Lehrlings verfällt (immer, DR-11)
##   5. Todesfolgen (nur mit trigger_effects, G-TOD-2): zuerst unmittelbare Folgen ohne
##      Entscheidung (Verwandlung von Wolfskindern, DR-10; danach Erbe gebundener Lehrlinge,
##      DR-11, stabil nach Personen-ID), dann Reaktion der Rolle einreihen
##   6. vorläufiger Siegstatus (DR-14); die verbindliche Prüfung folgt am Befehlsende,
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
	var dead_before := s.players.size() - s.alive_ids().size()  # nur aktuell Tote (RM-DR-138.3)
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
	ApprenticeRules.on_own_death(s, target_id)
	if trigger_effects:
		WolfChildRules.on_death(ctx, record)
		ApprenticeRules.on_master_death(ctx, record)
		_queue_reaction(ctx, target, record, s.players.size() - dead_before)
		_knight_strike(ctx, target, record)
	WinRules.record_death_seeker(ctx, target, record, dead_before)
	if trigger_effects:
		_coachman_crash(ctx, target, record)
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
	# Dorfwache: der Rudelangriff tötet sie nicht (RM-DR-119, Rollentext); sonst keine Wirkung.
	var immune := ctx.state.players[target_id].role_id == RoleCatalog.DORFWACHE
	if guardians.is_empty() and rescuers.is_empty() and not immune:
		return false
	var sources: Array[StringName] = []
	if immune:
		sources.append(RoleCatalog.DORFWACHE)
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


## Wahnsinniger Kutscher: Stirbt er durch Hinrichtung (LYNCH), sterben seine nächsten lebenden
## Nachbarn mit (im Uhrzeigersinn zuerst), Ursache `COACHMAN_CRASH`, Quelle der Kutscher.
static func _coachman_crash(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	if record.cause != KillEvent.CAUSE_LYNCH or target.role_id != RoleCatalog.WAHNSINNIGER_KUTSCHER:
		return
	for id: int in Seats.living_neighbours(ctx.state, target.id):
		request_kill(ctx, id, KillEvent.CAUSE_COACHMAN_CRASH, KillEvent.SOURCE_PLAYER, target.id)


## Reiht die Todesreaktion der Rolle ein (falls vorhanden). Reihenfolge = Einreihung.
## Höchstens eine Todesreaktion pro Person und Rolle in der Partie (`ability_uses`).
## `alive_before`: Lebende unmittelbar vor diesem Tod, die Person eingeschlossen (Besessener Wolf).
static func _queue_reaction(ctx: RuleContext, target: Player, record: KillEvent, alive_before: int) -> void:
	var kind := RoleCatalog.death_reaction(target.role_id)
	if kind == &"":
		return
	if kind == Reaction.KIND_POSSESSED and alive_before < RoleCatalog.POSSESSED_MIN_LIVING:
		return
	var use_key := "%s:death_reaction" % target.role_id
	if int(target.ability_uses.get(use_key, 0)) >= 1:
		return
	target.ability_uses[use_key] = int(target.ability_uses.get(use_key, 0)) + 1
	_enqueue(ctx, target.id, kind, record.order_index)


## Ritter: stirbt er durch den Rudelangriff, stirbt sofort der nächste Wolf (Abstand in Sitzen
## einschließlich toter Plätze); bei Gleichstand wählt der Spielleiter (Reaktion). Einmal je Leben.
static func _knight_strike(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	if target.role_id != RoleCatalog.RITTER or record.cause != KillEvent.CAUSE_NIGHT_KILL:
		return
	var use_key := "ritter:death_reaction"
	if int(target.ability_uses.get(use_key, 0)) >= 1:
		return
	var wolves := Seats.closest_wolves(ctx.state, target.id)
	if wolves.is_empty():
		return
	target.ability_uses[use_key] = 1
	if wolves.size() == 1:
		request_kill(ctx, wolves[0], KillEvent.CAUSE_KNIGHT_STRIKE, KillEvent.SOURCE_PLAYER, target.id)
	else:
		_enqueue(ctx, target.id, Reaction.KIND_KNIGHT, record.order_index)


static func _enqueue(ctx: RuleContext, owner_id: int, kind: StringName, trigger_order: int) -> void:
	var s := ctx.state
	var reaction := Reaction.new()
	reaction.id = s.next_reaction_id
	s.next_reaction_id += 1
	reaction.kind = kind
	reaction.owner_id = owner_id
	reaction.trigger_order = trigger_order
	s.reactions.append(reaction)
	ctx.emit(GameEvent.REACTION_QUEUED, Visibility.GM, {"reaction": reaction.to_dict()})
