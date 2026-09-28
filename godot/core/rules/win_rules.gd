class_name WinRules
extends RefCounted
## Einzige Siegprüfung (A-17, G-SIEG-1/2/4, DR-12) mit zwei Stufen nach DR-14:
##   vorläufig:   nach jedem Tod (Ereignis WinStatusProvisional), beendet nichts
##   verbindlich: erst wenn weder Reaktion noch Prompt offen ist (WinStatusFinal);
##                dann entsteht aus dem endgültigen Zustand die gesamte Kandidatenmenge
## Bedingungen (stabile Reihenfolge: Dorf, Werwölfe, Manipulatoren nach Personen-ID):
##   Dorf:        kein lebender Mensch zählt als Wolf.
##   Werwölfe:    Paritätswert lebender Wölfe ≥ lebende Nicht-Wölfe (Siegreicher Wolf zählt 2).
##   Manipulator: genau drei Personen leben, er lebt und wurde in der Partie nie nominiert;
##                je Manipulator ein eigener personenbezogener Kandidat.
##   Selbstmörder: bei seiner Hinrichtung waren mindestens 5 Personen tot (gespeichert, gilt fort; RM-DR-138).
##   Doppelspion: kein Wolf lebt und er lebt; je Person ein Kandidat, der Dorfsieg entfällt dann (RM-DR-155).
## Die Ewigen (I-12, I-15): Ist die begünstigte Person eines Einzelsiegs von den Ewigen mit Ja geprüft,
## stehen alle Personen mit der Rolle Die Ewigen (lebend oder tot) nach ihr in `beneficiary_ids`.
## Feuerteufel (RM-DR-131.5): Jeder erkannte Sieg nennt alle lebenden Feuerteufel in `co_winner_ids`
## (nicht bei einer Siegerklärung durch den Spielleiter); sie haben keine eigene Siegbedingung.
## DR-02: Mehrere gleichzeitige Kandidaten ohne automatische Priorität; der Spielleiter
## bestätigt genau einen oder lehnt alle ab. Lebt niemand, entsteht kein Kandidat; der
## Spielleiter erklärt das Ergebnis per GmCorrection „declare_winner“.


## Alle erfüllten Siegbedingungen: [{kind, reason_key, reason_args, beneficiary_ids}].
static func evaluate(state: GameState) -> Array:
	var alive := state.alive_ids()
	var living_wolves := 0
	var wolves := 0  # Paritätswert: Siegreicher Wolf zählt doppelt (RoleCatalog.parity_weight)
	var non_wolves := 0
	for id: int in alive:
		var p: Player = state.players[id]
		if p.counts_as_wolf:
			living_wolves += 1
			wolves += RoleCatalog.parity_weight(p.role_id)
		else:
			non_wolves += 1
	var args := {"wolves": wolves, "non_wolves": non_wolves}
	var results: Array = []
	if living_wolves == 0:
		# RM-DR-155.3: Lebt ein Doppelspion, wird statt des Dorfsiegs nur sein Sieg je Person vorgeschlagen.
		# Freigeschaltete Propheten (E-03) ersetzen den Dorfsieg wie der Doppelspion.
		var agents: Array = []
		for id: int in alive:
			if double_agent_wins(state, id):
				agents.append([id, WinCandidate.REASON_DOUBLE_AGENT])
			elif SoloRules.prophet_wins(state, id):
				agents.append([id, WinCandidate.REASON_PROPHET])
		if agents.is_empty():
			results.append({"kind": String(Faction.VILLAGE), "reason_key": String(WinCandidate.REASON_NO_WOLVES_ALIVE), "reason_args": args.duplicate(), "beneficiary_ids": []})
		for agent: Array in agents:
			results.append({"kind": String(Faction.SOLO), "reason_key": String(agent[1]), "reason_args": {"living": alive.size()}, "beneficiary_ids": [agent[0]]})
	if wolves >= non_wolves:
		results.append({"kind": String(Faction.WOLVES), "reason_key": String(WinCandidate.REASON_WOLF_PARITY), "reason_args": args.duplicate(), "beneficiary_ids": []})
	# RM-DR-138.4, F-11: ein erfüllter Selbstmörder-Sieg wird bei jeder Prüfung vorgeschlagen.
	for id: int in state.death_seeker_wins:
		results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_DEATH_SEEKER), "reason_args": {"min_dead": DEATH_SEEKER_MIN_DEAD}, "beneficiary_ids": [id]})
	for id: int in alive:
		if SoloRules.voodoo_wins(state, id):
			results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_VOODOO), "reason_args": {"living": alive.size()}, "beneficiary_ids": [id]})
	for id: int in alive:
		if parasite_wins(state, id):
			results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_PARASITE), "reason_args": {"living": alive.size()}, "beneficiary_ids": [id]})
	for id: int in state.preacher_wins:
		results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_DEATH_PREACHER), "reason_args": {}, "beneficiary_ids": [id]})
	for id: int in alive:
		if SoloRules.piper_wins(state, id):
			results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_PIED_PIPER), "reason_args": {"living": alive.size()}, "beneficiary_ids": [id]})
		if SoloRules.pest_wins(state, id):
			results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_PLAGUE), "reason_args": {"living": alive.size()}, "beneficiary_ids": [id]})
	for id: int in alive:
		if manipulator_wins(state, id):
			results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_MANIPULATOR), "reason_args": {"living": alive.size()}, "beneficiary_ids": [id]})
	for result: Dictionary in results:
		if result["kind"] == String(Faction.SOLO):
			(result["beneficiary_ids"] as Array).append_array(eternal_co_winners(state, int(result["beneficiary_ids"][0])))
	var devils := SoloRules.fire_co_winners(state)
	if not devils.is_empty():
		for result: Dictionary in results:
			result["co_winner_ids"] = devils.duplicate()
	return results


## Mitsieger eines Einzelsiegs von `beneficiary`: alle Ewigen, wenn sie ihn mit Ja geprüft haben.
static func eternal_co_winners(state: GameState, beneficiary: int) -> Array[int]:
	var out: Array[int] = []
	if not state.eternal_finds.has(beneficiary):
		return out
	var ids: Array[int] = []
	ids.assign(state.players.keys())
	ids.sort()
	for id: int in ids:
		if id != beneficiary and state.players[id].role_id == RoleCatalog.DIE_EWIGEN:
			out.append(id)
	return out


## Einzelsiegbedingung des Manipulators für Person `id` (DR-12): exakt drei Lebende.
static func manipulator_wins(state: GameState, id: int) -> bool:
	var p: Player = state.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.MANIPULATOR and not p.ever_nominated and state.alive_ids().size() == 3


## Parasit (RM-DR-157): er lebt und höchstens drei Personen leben.
static func parasite_wins(state: GameState, id: int) -> bool:
	var p: Player = state.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.PARASIT and state.alive_ids().size() <= 3


## Mindestzahl Toter unmittelbar vor der Hinrichtung des Selbstmörders (Rollentext „5+ Tote“, RM-DR-138.1).
const DEATH_SEEKER_MIN_DEAD := 5


## Hält den erfüllten Sieg fest, wenn ein Selbstmörder hingerichtet wird (Ursache LYNCH, auch
## per Spielleiter), während mindestens 5 Personen tot sind; er selbst zählt nicht mit.
static func record_death_seeker(ctx: RuleContext, target: Player, record: KillEvent, dead_before: int) -> void:
	var s := ctx.state
	if record.cause != KillEvent.CAUSE_LYNCH or target.role_id != RoleCatalog.SELBSTMOERDER or dead_before < DEATH_SEEKER_MIN_DEAD:
		return
	if not s.death_seeker_wins.has(target.id):
		s.death_seeker_wins.append(target.id)
		s.death_seeker_wins.sort()
	ctx.emit(GameEvent.DEATH_SEEKER_FULFILLED, Visibility.GM, {"player_id": target.id, "dead_before": dead_before, "order_index": record.order_index})


## Einzelsieg des Doppelspions für Person `id` (RM-DR-155.1): er lebt und kein Wolf lebt.
static func double_agent_wins(state: GameState, id: int) -> bool:
	var p: Player = state.players.get(id)
	if p == null or not p.alive or p.role_id != RoleCatalog.DOPPELSPION:
		return false
	for other: int in state.alive_ids():
		if state.players[other].counts_as_wolf:
			return false
	return true


## Nach jedem Tod: vorläufigen Status berechnen und die verbindliche Prüfung vormerken.
static func record_provisional(ctx: RuleContext, death: KillEvent) -> void:
	var s := ctx.state
	s.provisional_win = evaluate(s)
	s.win_check_pending = true
	ctx.emit(GameEvent.WIN_STATUS_PROVISIONAL, Visibility.GM, {
		"after_death": death.order_index, "living": s.alive_ids().size(), "results": s.provisional_win,
	})


## Am Ende jedes Befehls: verbindliche Prüfung, sobald sie aussteht und weder eine
## Reaktion noch ein Prompt offen ist. Offene Kandidaten oder ein bestätigter Sieger
## werden nie überschrieben.
static func finalize_if_ready(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.win_check_pending or not s.reactions.is_empty() or s.pending_prompt != null:
		return
	if s.winner_id != -1 or not s.open_candidates().is_empty():
		return
	var results := evaluate(s)
	var living := s.alive_ids().size()
	s.win_check_pending = false
	s.provisional_win = []
	ctx.emit(GameEvent.WIN_STATUS_FINAL, Visibility.GM, {
		"living": living, "results": results, "requires_gm_decision": living == 0 and not results.is_empty(),
	})
	if living == 0:
		return
	for result: Dictionary in results:
		var candidate := WinCandidate.new()
		candidate.id = s.next_candidate_id
		s.next_candidate_id += 1
		candidate.kind = StringName(result["kind"])
		candidate.reason_key = StringName(result["reason_key"])
		candidate.reason_args = result["reason_args"]
		candidate.beneficiary_ids.assign(result["beneficiary_ids"])
		candidate.co_winner_ids.assign(result.get("co_winner_ids", []))
		candidate.status = WinCandidate.STATUS_OPEN
		candidate.detected_at_command = ctx.command_index
		s.win_candidates.append(candidate)
		ctx.emit(GameEvent.WIN_DETECTED, Visibility.GM, {"candidate": candidate.to_dict()})


## Einzelsieg: erste Person begünstigt, danach genau ihre Mitsieger (Die Ewigen).
static func _beneficiaries_ok(s: GameState, c: WinCandidate) -> bool:
	return not c.beneficiary_ids.is_empty() and c.beneficiary_ids.slice(1) == eternal_co_winners(s, c.beneficiary_ids[0])


## Einzelsiege aus Teil 1 (E-01 bis E-04): gilt die Bedingung für `id` noch?
static func _solo_holds(s: GameState, reason: StringName, id: int) -> bool:
	match reason:
		WinCandidate.REASON_PIED_PIPER:
			return SoloRules.piper_wins(s, id)
		WinCandidate.REASON_PLAGUE:
			return SoloRules.pest_wins(s, id)
		WinCandidate.REASON_PROPHET:
			return SoloRules.prophet_wins(s, id)
		WinCandidate.REASON_VOODOO:
			return SoloRules.voodoo_wins(s, id)
	return s.preacher_wins.has(id)


## Ladeprüfung der Kandidatenmenge gegen den übrigen Zustand.
static func state_is_consistent(s: GameState) -> bool:
	var ids := {}
	var open_keys := {}
	var confirmed: Array[WinCandidate] = []
	var has_open := false
	for c: WinCandidate in s.win_candidates:
		if ids.has(c.id) or c.id >= s.next_candidate_id:
			return false
		ids[c.id] = true
		for b: int in c.beneficiary_ids + c.co_winner_ids:
			if not s.players.has(b):
				return false
		var sorted_co := c.co_winner_ids.duplicate()
		sorted_co.sort()
		if sorted_co != c.co_winner_ids or c.co_winner_ids.any(func(b: int) -> bool: return c.beneficiary_ids.has(b) or c.co_winner_ids.count(b) > 1):
			return false
		# Offene und bestätigte erkannte Siege nennen genau die lebenden Feuerteufel (Zustand ist dann eingefroren).
		if (c.status == WinCandidate.STATUS_OPEN or c.status == WinCandidate.STATUS_CONFIRMED):
			var expected: Array[int] = []
			if c.reason_key != WinCandidate.REASON_GM_DECLARED:
				expected = SoloRules.fire_co_winners(s)
			if c.co_winner_ids != expected:
				return false
		if c.status == WinCandidate.STATUS_CONFIRMED:
			confirmed.append(c)
		if c.status == WinCandidate.STATUS_OPEN:
			has_open = true
			if open_keys.has(c.semantic_key()):
				return false
			open_keys[c.semantic_key()] = true
		# Offene und bestätigte Manipulator-Kandidaten müssen zum Zustand passen (danach ändert sich nichts).
		if c.reason_key == WinCandidate.REASON_MANIPULATOR and (c.status == WinCandidate.STATUS_OPEN or c.status == WinCandidate.STATUS_CONFIRMED):
			if c.kind != Faction.SOLO or not _beneficiaries_ok(s, c) or not manipulator_wins(s, c.beneficiary_ids[0]):
				return false
		if c.reason_key == WinCandidate.REASON_PARASITE and (c.status == WinCandidate.STATUS_OPEN or c.status == WinCandidate.STATUS_CONFIRMED):
			if c.kind != Faction.SOLO or not _beneficiaries_ok(s, c) or not parasite_wins(s, c.beneficiary_ids[0]):
				return false
		if c.reason_key == WinCandidate.REASON_DEATH_SEEKER and (c.status == WinCandidate.STATUS_OPEN or c.status == WinCandidate.STATUS_CONFIRMED):
			if c.kind != Faction.SOLO or not _beneficiaries_ok(s, c) or not s.death_seeker_wins.has(c.beneficiary_ids[0]):
				return false
		if [WinCandidate.REASON_PIED_PIPER, WinCandidate.REASON_PLAGUE, WinCandidate.REASON_PROPHET, WinCandidate.REASON_DEATH_PREACHER, WinCandidate.REASON_VOODOO].has(c.reason_key) 				and (c.status == WinCandidate.STATUS_OPEN or c.status == WinCandidate.STATUS_CONFIRMED):
			if c.kind != Faction.SOLO or not _beneficiaries_ok(s, c) or not _solo_holds(s, c.reason_key, c.beneficiary_ids[0]):
				return false
		if c.reason_key == WinCandidate.REASON_DOUBLE_AGENT and (c.status == WinCandidate.STATUS_OPEN or c.status == WinCandidate.STATUS_CONFIRMED):
			if c.kind != Faction.SOLO or not _beneficiaries_ok(s, c) or not double_agent_wins(s, c.beneficiary_ids[0]):
				return false
	if confirmed.size() > 1:
		return false
	if confirmed.size() == 1:
		if s.winner_id != confirmed[0].id or s.phase != Phase.GAME_OVER:
			return false
	elif s.winner_id != -1 or s.phase == Phase.GAME_OVER:
		return false
	if has_open and (s.pending_prompt != null or not s.reactions.is_empty() or s.phase == Phase.GAME_OVER):
		return false
	return true
