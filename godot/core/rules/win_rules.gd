class_name WinRules
extends RefCounted
## Einzige Siegprüfung (A-17, G-SIEG-1/2/4). Erzeugt höchstens einen Kandidaten,
## nie direkt einen Sieger.
##   Dorf:      kein lebender Mensch zählt als Wolf.
##   Werwölfe:  lebende Wölfe ≥ lebende Nicht-Wölfe.
## Beide Bedingungen gelten nur gleichzeitig, wenn niemand lebt. Diesen Fall regelt
## DR-02 (offen); bis dahin entsteht dort kein automatischer Kandidat.


## Liefert {} oder {kind, reason_key, reason_args}.
static func evaluate(state: GameState) -> Dictionary:
	var wolves := 0
	var non_wolves := 0
	for id: int in state.alive_ids():
		if state.players[id].counts_as_wolf:
			wolves += 1
		else:
			non_wolves += 1
	var args := {"wolves": wolves, "non_wolves": non_wolves}
	if wolves + non_wolves == 0:
		return {}
	if wolves == 0:
		return {"kind": Faction.VILLAGE, "reason_key": WinCandidate.REASON_NO_WOLVES_ALIVE, "reason_args": args}
	if wolves >= non_wolves:
		return {"kind": Faction.WOLVES, "reason_key": WinCandidate.REASON_WOLF_PARITY, "reason_args": args}
	return {}


## Legt bei Bedarf einen offenen Kandidaten an. Ein offener Kandidat oder ein
## bestätigter Sieger wird nie überschrieben.
static func check(ctx: RuleContext) -> void:
	var s := ctx.state
	if s.win_candidate != null or s.winner != null:
		return
	var result := evaluate(s)
	if result.is_empty():
		return
	var candidate := WinCandidate.new()
	candidate.id = s.next_candidate_id
	s.next_candidate_id += 1
	candidate.kind = result["kind"]
	candidate.reason_key = result["reason_key"]
	candidate.reason_args = result["reason_args"]
	candidate.status = WinCandidate.STATUS_OPEN
	candidate.detected_at_command = ctx.command_index
	s.win_candidate = candidate
	ctx.emit(GameEvent.WIN_DETECTED, Visibility.GM, {"candidate": candidate.to_dict()})
