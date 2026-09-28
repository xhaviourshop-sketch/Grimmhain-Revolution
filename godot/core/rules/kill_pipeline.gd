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


## `pierce`: Angriff durchdringt Schutzengel, Waldhexenrettung und Dorfwache (RM-DR-005), keine Schilde.
## `chain`: bereits betroffene Personen dieser Umlenkungskette (E-20: jede Person höchstens einmal).
static func request_kill(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName, source_id: int = -1, trigger_effects: bool = true, pierce: bool = false, chain: Array[int] = []) -> KillEvent:
	var s := ctx.state
	var target: Player = s.players.get(target_id)
	if target == null or not target.alive:
		ctx.emit(GameEvent.KILL_IGNORED, Visibility.GM, {
			"target_id": target_id, "cause": cause, "reason": "target_not_alive",
		})
		return null
	if _prevented_by_protection(ctx, target_id, cause, source_kind, pierce):
		return null
	if _parasite_immune(ctx, target, cause, source_kind):
		return null
	if _packfather_survives(ctx, target, cause, source_kind):
		return null
	if _fenrir_survives(ctx, target, cause, source_kind):
		return null
	# Nekromant (E-16): globaler Schild nach Schutz und persönlichen Schilden, vor den Umlenkungen (E-12, B-07).
	if SoloRules.necro_shield_prevents(ctx, target_id, cause, source_kind):
		return null
	var next_chain: Array[int] = chain.duplicate()
	next_chain.append(target_id)
	# Voodoo-Priester (E-12, E-23): Die eigene Puppe wirkt vor einer fremden Verknüpfung; die Puppe ist verbraucht.
	var doll := SoloRules.doll_of(s, target_id) if target.role_id == RoleCatalog.VOODOO and source_kind != KillEvent.SOURCE_GM else GameState.NO_TARGET
	if doll != GameState.NO_TARGET and s.players[doll].alive and not next_chain.has(doll):
		SoloRules.drop_priest_doll(s, target_id)
		ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target_id, "cause": cause, "source_kind": source_kind,
			"protection": RoleCatalog.VOODOO, "sources": [RoleCatalog.VOODOO], "redirected_to": doll, "night": s.night_number})
		return request_kill(ctx, doll, cause, source_kind, source_id, trigger_effects, pierce, next_chain)
	# Schattenwanderer (B-04, B-07): ein tatsächlicher Tod trifft stattdessen die verknüpfte Person.
	var swapped := BondRules.shadow_partner(s, target_id, source_kind, next_chain)
	if swapped != GameState.NO_TARGET:
		ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target_id, "cause": cause, "source_kind": source_kind,
			"protection": RoleCatalog.SCHATTENWANDERER, "sources": [RoleCatalog.SCHATTENWANDERER], "redirected_to": swapped, "night": s.night_number})
		return request_kill(ctx, swapped, cause, source_kind, source_id, trigger_effects, pierce, next_chain)
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
		_bounty_credit(ctx, target, record)
		_detective_hint(ctx, target)
		_queue_reaction(ctx, target, record, s.players.size() - dead_before)
		_knight_strike(ctx, target, record)
	_end_parasite_bonds(ctx, target, trigger_effects)
	s.wolf_poisons = s.wolf_poisons.filter(func(e: Dictionary) -> bool: return int(e["target_id"]) != target.id)
	s.death_marks = s.death_marks.filter(func(m: Dictionary) -> bool: return int(m["target_id"]) != target.id)
	BondRules.on_death(ctx, target, trigger_effects)
	SoloRules.on_death(ctx, target, record, trigger_effects)
	SoloRules.voodoo_on_death(s, target.id)
	SoloRules.necro_drop_shields(s, target.id)
	if trigger_effects and target.role_id == RoleCatalog.RUDELVATER and cause == KillEvent.CAUSE_LYNCH:
		s.pack_bonus_pending = true
	if trigger_effects and target.role_id == RoleCatalog.SEUCHENWOLF:
		s.plague_pierce_pending = true
	WinRules.record_death_seeker(ctx, target, record, dead_before)
	if trigger_effects:
		_coachman_crash(ctx, target, record)
	SoloRules.fire_on_death(ctx, target, trigger_effects)
	WinRules.record_provisional(ctx, record)
	return record


## Abfangstufe: Schutz eines Schutzengels und Rettung einer Waldhexe dieser Nacht
## verhindern ausschließlich den Rudelangriff (`NIGHT_KILL`, Quelle Rudel). Greifen beide,
## entsteht genau ein `KillPrevented` mit beiden Quellen (`sources`, `guardian_ids`,
## `rescuer_ids`); `protection` nennt die erste Quelle. Kein Tod, keine Reaktion, kein
## vorläufiger Siegstatus.
static func _prevented_by_protection(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName, pierce: bool) -> bool:
	if cause != KillEvent.CAUSE_NIGHT_KILL or source_kind != KillEvent.SOURCE_PACK:
		return false
	var s := ctx.state
	var kind := pack_protection(s, target_id, pierce)
	if kind == &"":
		return false
	if kind != GuardRoles.REPEATABLE:
		_use_one_time_protection(ctx, target_id, kind)
		return true
	var night := s.night_number
	var guardians := Protections.guardians_of(s, target_id, night)
	var rescuers := WitchStep.rescuers_of(s, target_id, night)
	var immune := _guard_immune(s, target_id)
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


## Dorfwache: der Rudelangriff tötet sie nicht (RM-DR-119), außer ihre Fähigkeit ruht (Fluch des Weisen).
static func _guard_immune(s: GameState, target_id: int) -> bool:
	return s.players[target_id].role_id == RoleCatalog.DORFWACHE and not GuardRoles.silenced(s, target_id)


## Welche Schutzwirkung einen Rudelangriff auf `target_id` jetzt abfinge (reine Abfrage, S-10/S-11):
## wiederholbare zuerst (Schutzengel, Waldhexenrettung, Dorfwache; nicht bei Durchdringung), sonst genau eine
## einmalige in der Reihenfolge Schmiedewaffe (auch gegen Durchdringung), Schild des Schutzgeists, Rettung
## des Weisen; &"" ohne Schutz.
static func pack_protection(s: GameState, target_id: int, pierce: bool) -> StringName:
	var night := s.night_number
	if not pierce and (not Protections.guardians_of(s, target_id, night).is_empty() or not WitchStep.rescuers_of(s, target_id, night).is_empty() or _guard_immune(s, target_id)):
		return GuardRoles.REPEATABLE
	if s.weapons.any(func(w: Dictionary) -> bool: return int(w["holder_id"]) == target_id):
		return RoleCatalog.DORFSCHMIED
	if pierce:
		return &""
	if s.shields.any(func(sh: Dictionary) -> bool: return int(sh["holder_id"]) == target_id and int(sh["night"]) < night):
		return RoleCatalog.SCHUTZGEIST
	var p := s.players[target_id]
	if p.role_id == RoleCatalog.DER_WEISE and not p.ability_uses.has(GuardRoles.SAGE_USE_KEY) and not GuardRoles.silenced(s, target_id):
		return RoleCatalog.DER_WEISE
	return &""


## Verbraucht die einmalige Schutzwirkung `kind` für `target_id` und protokolliert die Rettung.
static func _use_one_time_protection(ctx: RuleContext, target_id: int, kind: StringName) -> void:
	var s := ctx.state
	var data := {"target_id": target_id, "cause": KillEvent.CAUSE_NIGHT_KILL, "source_kind": KillEvent.SOURCE_PACK, "protection": kind,
		"sources": [kind], "night": s.night_number}
	match kind:
		RoleCatalog.DORFSCHMIED:
			for i: int in s.weapons.size():
				if int(s.weapons[i]["holder_id"]) == target_id:
					data["smith_id"] = int(s.weapons[i]["smith_id"])
					s.weapons.remove_at(i)
					break
		RoleCatalog.SCHUTZGEIST:
			for i: int in s.shields.size():
				if int(s.shields[i]["holder_id"]) == target_id and int(s.shields[i]["night"]) < s.night_number:
					data["spirit_id"] = int(s.shields[i]["source_id"])
					s.shields.remove_at(i)
					break
		RoleCatalog.DER_WEISE:
			s.players[target_id].ability_uses[GuardRoles.SAGE_USE_KEY] = 1
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, data)
	# Die Waffe tötet dabei einen Wolf; der Spielleiter wählt ihn (Reaktion), sofern ein anderer Wolf lebt.
	if kind == RoleCatalog.DORFSCHMIED and s.alive_ids().any(func(id: int) -> bool: return id != target_id and s.players[id].counts_as_wolf):
		_enqueue(ctx, target_id, Reaction.KIND_SMITH, s.next_death_order)


## true, wenn die Person einen Rudelangriff jetzt durch einen persönlichen Schild überlebt (Parasit mit
## lebendem Wirt, Fenrir ab Stufe 3); für die Frage der Märtyrerin.
static func survives_any_death(s: GameState, p: Player) -> bool:
	if p.role_id == RoleCatalog.PARASIT:
		var host := host_of(s, p.id)
		return host != GameState.NO_TARGET and s.players[host].alive
	return p.role_id == RoleCatalog.FENRIR and not p.ability_uses.has("fenrir:survive") and int(s.growth.get(p.id, 0)) >= RoleCatalog.FENRIR_SHIELD_STAGE


## Rudelvater (RM-DR-112): überlebt einmal je Leben einen Tod, der weder Rudelangriff noch Lynch
## noch Spielleiterkorrektur ist.
static func _packfather_survives(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName) -> bool:
	if target.role_id != RoleCatalog.RUDELVATER or source_kind == KillEvent.SOURCE_GM or cause == KillEvent.CAUSE_LYNCH:
		return false
	if cause == KillEvent.CAUSE_NIGHT_KILL and source_kind == KillEvent.SOURCE_PACK:
		return false
	if target.ability_uses.has("rudelvater:survive"):
		return false
	target.ability_uses["rudelvater:survive"] = 1
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {
		"target_id": target.id, "cause": cause, "source_kind": source_kind, "protection": RoleCatalog.RUDELVATER,
		"sources": [RoleCatalog.RUDELVATER], "night": ctx.state.night_number,
	})
	return true


## Fenrir (RM-DR-125): ab Stufe 3 überlebt er einmal je Leben jeden Tod außer Spielleiterkorrekturen.
static func _fenrir_survives(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName) -> bool:
	if target.role_id != RoleCatalog.FENRIR or source_kind == KillEvent.SOURCE_GM or target.ability_uses.has("fenrir:survive"):
		return false
	if int(ctx.state.growth.get(target.id, 0)) < RoleCatalog.FENRIR_SHIELD_STAGE:
		return false
	target.ability_uses["fenrir:survive"] = 1
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {
		"target_id": target.id, "cause": cause, "source_kind": source_kind, "protection": RoleCatalog.FENRIR,
		"sources": [RoleCatalog.FENRIR], "night": ctx.state.night_number,
	})
	return true


static func host_of(s: GameState, parasite_id: int) -> int:
	for b: Dictionary in s.parasite_hosts:
		if int(b["parasite_id"]) == parasite_id:
			return int(b["host_id"])
	return GameState.NO_TARGET


## Parasit (RM-DR-157): Mit lebendem Wirt verhindert er jeden Tod außer Spielleiterkorrekturen
## (Quelle `gm`) und dem Tod durch seinen Wirt (`PARASITE_HOST`).
static func _parasite_immune(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName) -> bool:
	if target.role_id != RoleCatalog.PARASIT or source_kind == KillEvent.SOURCE_GM or cause == KillEvent.CAUSE_PARASITE_HOST:
		return false
	var host := host_of(ctx.state, target.id)
	if host == GameState.NO_TARGET or not ctx.state.players[host].alive:
		return false
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {
		"target_id": target.id, "cause": cause, "source_kind": source_kind, "protection": RoleCatalog.PARASIT,
		"sources": [RoleCatalog.PARASIT], "host_id": host, "night": ctx.state.night_number,
	})
	return true


## Tod einer Person beendet ihre Parasit-Bindungen (RM-DR-011.2): stirbt der Parasit, verliert er
## den Wirt; stirbt ein Wirt (mit Folgen), stirbt sein Parasit mit.
static func _end_parasite_bonds(ctx: RuleContext, target: Player, trigger_effects: bool) -> void:
	var s := ctx.state
	var orphans: Array[int] = []
	var kept: Array = []
	for b: Dictionary in s.parasite_hosts:
		if int(b["parasite_id"]) == target.id:
			continue
		if int(b["host_id"]) == target.id:
			orphans.append(int(b["parasite_id"]))
			continue
		kept.append(b)
	s.parasite_hosts = kept
	if not trigger_effects:
		return
	for id: int in orphans:
		request_kill(ctx, id, KillEvent.CAUSE_PARASITE_HOST, KillEvent.SOURCE_PLAYER, target.id)


## Kopfgeldjäger (I-04): jeder Lynch-Tod einer Person, die als Wolf zählt, gibt jedem lebenden
## Kopfgeldjäger eine Liste für eine folgende Nacht.
static func _bounty_credit(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	if record.cause != KillEvent.CAUSE_LYNCH or not target.counts_as_wolf:
		return
	var s := ctx.state
	for id: int in s.alive_ids():
		if s.players[id].role_id == RoleCatalog.KOPFGELDJAEGER and not GuardRoles.silenced(s, id):
			s.bounty_credits[id] = int(s.bounty_credits.get(id, 0)) + 1


## Detektiv (I-10, I-14): Stirbt eine Person, die als Wolf zählt, während ein Detektiv lebt, und lebt
## danach (nach Verwandlungen und Erbe) ein anderer Wolf, wird die Richtung vom Platz des Toten zum
## nächsten lebenden Wolf öffentlich; nachts erst in der Morgenauflösung. Ein Hinweis je Tod.
static func _detective_hint(ctx: RuleContext, target: Player) -> void:
	var s := ctx.state
	if not target.counts_as_wolf or not s.alive_ids().any(func(id: int) -> bool: return s.players[id].role_id == RoleCatalog.DETEKTIV and not GuardRoles.silenced(s, id)):
		return
	var direction := Seats.wolf_direction(s, target.id)
	if direction == "none":
		return
	ctx.emit(GameEvent.DETECTIVE_RECORDED, Visibility.GM, {"anchor_id": target.id, "direction": direction})
	if s.phase == Phase.NIGHT:
		s.detective_hints.append({"anchor_id": target.id, "direction": direction})
	else:
		ctx.emit(GameEvent.DETECTIVE_HINT, Visibility.PUBLIC, {"anchor_id": target.id, "direction": direction})


## Wahnsinniger Kutscher: Stirbt er durch Hinrichtung (LYNCH), sterben seine nächsten lebenden
## Nachbarn mit (im Uhrzeigersinn zuerst), Ursache `COACHMAN_CRASH`, Quelle der Kutscher.
static func _coachman_crash(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	if record.cause != KillEvent.CAUSE_LYNCH or target.role_id != RoleCatalog.WAHNSINNIGER_KUTSCHER or GuardRoles.silenced(ctx.state, target.id):
		return
	for id: int in Seats.living_neighbours(ctx.state, target.id):
		request_kill(ctx, id, KillEvent.CAUSE_COACHMAN_CRASH, KillEvent.SOURCE_PLAYER, target.id)


## Reiht die Todesreaktion der Rolle ein (falls vorhanden). Reihenfolge = Einreihung.
## Höchstens eine Todesreaktion pro Person und Rolle in der Partie (`ability_uses`).
## `alive_before`: Lebende unmittelbar vor diesem Tod, die Person eingeschlossen (Besessener Wolf).
static func _queue_reaction(ctx: RuleContext, target: Player, record: KillEvent, alive_before: int) -> void:
	var kind := RoleCatalog.death_reaction(target.role_id)
	if kind == &"" or GuardRoles.silenced(ctx.state, target.id):
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
	if target.role_id != RoleCatalog.RITTER or record.cause != KillEvent.CAUSE_NIGHT_KILL or GuardRoles.silenced(ctx.state, target.id):
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
