class_name WinRules
extends RefCounted
## Einzige Siegprüfung (A-17, G-SIEG-1/2/4) mit zwei Stufen nach DR-14:
##   vorläufig:   nach jedem Tod (Ereignis WinStatusProvisional), beendet nichts
##   verbindlich: erst wenn keine Reaktion mehr offen ist (WinStatusFinal);
##                nur dann entsteht ein Kandidat zur Spielleiterbestätigung
## Bedingungen:
##   Dorf:      kein lebender Mensch zählt als Wolf.
##   Werwölfe:  lebende Wölfe ≥ lebende Nicht-Wölfe.
## DR-02: Sind mehrere Bedingungen zugleich erfüllt (im Core-Slice nur, wenn niemand
## lebt), gibt es keine automatische Priorität und keinen automatischen Kandidaten;
## der Spielleiter erklärt das Ergebnis per GmCorrection „declare_winner“.


## Alle erfüllten Siegbedingungen: [{kind, reason_key, reason_args}], stabil sortiert.
static func evaluate(state: GameState) -> Array:
	var wolves := 0
	var non_wolves := 0
	for id: int in state.alive_ids():
		if state.players[id].counts_as_wolf:
			wolves += 1
		else:
			non_wolves += 1
	var args := {"wolves": wolves, "non_wolves": non_wolves}
	var results: Array = []
	if wolves == 0:
		results.append({"kind": String(Faction.VILLAGE), "reason_key": String(WinCandidate.REASON_NO_WOLVES_ALIVE), "reason_args": args.duplicate()})
	if wolves >= non_wolves:
		results.append({"kind": String(Faction.WOLVES), "reason_key": String(WinCandidate.REASON_WOLF_PARITY), "reason_args": args.duplicate()})
	return results


## Nach jedem Tod: vorläufigen Status berechnen und die verbindliche Prüfung vormerken.
static func record_provisional(ctx: RuleContext, death: KillEvent) -> void:
	var s := ctx.state
	s.provisional_win = evaluate(s)
	s.win_check_pending = true
	ctx.emit(GameEvent.WIN_STATUS_PROVISIONAL, Visibility.GM, {
		"after_death": death.order_index, "living": s.alive_ids().size(), "results": s.provisional_win,
	})


## Am Ende jedes Befehls: verbindliche Prüfung, sobald sie aussteht und weder eine
## Reaktion noch ein Prompt offen ist. Ein offener Kandidat oder ein bestätigter Sieger
## wird nie überschrieben.
static func finalize_if_ready(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.win_check_pending or not s.reactions.is_empty() or s.pending_prompt != null:
		return
	if s.winner != null or s.win_candidate != null:
		return
	var results := evaluate(s)
	s.win_check_pending = false
	s.provisional_win = []
	ctx.emit(GameEvent.WIN_STATUS_FINAL, Visibility.GM, {
		"living": s.alive_ids().size(), "results": results, "requires_gm_decision": results.size() > 1,
	})
	if results.size() != 1:
		return
	var result: Dictionary = results[0]
	var candidate := WinCandidate.new()
	candidate.id = s.next_candidate_id
	s.next_candidate_id += 1
	candidate.kind = StringName(result["kind"])
	candidate.reason_key = StringName(result["reason_key"])
	candidate.reason_args = result["reason_args"]
	candidate.status = WinCandidate.STATUS_OPEN
	candidate.detected_at_command = ctx.command_index
	s.win_candidate = candidate
	ctx.emit(GameEvent.WIN_DETECTED, Visibility.GM, {"candidate": candidate.to_dict()})
