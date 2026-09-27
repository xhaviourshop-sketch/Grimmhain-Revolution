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
		results.append({"kind": String(Faction.VILLAGE), "reason_key": String(WinCandidate.REASON_NO_WOLVES_ALIVE), "reason_args": args.duplicate(), "beneficiary_ids": []})
	if wolves >= non_wolves:
		results.append({"kind": String(Faction.WOLVES), "reason_key": String(WinCandidate.REASON_WOLF_PARITY), "reason_args": args.duplicate(), "beneficiary_ids": []})
	for id: int in alive:
		if manipulator_wins(state, id):
			results.append({"kind": String(Faction.SOLO), "reason_key": String(WinCandidate.REASON_MANIPULATOR), "reason_args": {"living": alive.size()}, "beneficiary_ids": [id]})
	return results


## Einzelsiegbedingung des Manipulators für Person `id` (DR-12): exakt drei Lebende.
static func manipulator_wins(state: GameState, id: int) -> bool:
	var p: Player = state.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.MANIPULATOR and not p.ever_nominated and state.alive_ids().size() == 3


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
		candidate.status = WinCandidate.STATUS_OPEN
		candidate.detected_at_command = ctx.command_index
		s.win_candidates.append(candidate)
		ctx.emit(GameEvent.WIN_DETECTED, Visibility.GM, {"candidate": candidate.to_dict()})


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
		for b: int in c.beneficiary_ids:
			if not s.players.has(b):
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
			if c.kind != Faction.SOLO or c.beneficiary_ids.size() != 1 or not manipulator_wins(s, c.beneficiary_ids[0]):
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
