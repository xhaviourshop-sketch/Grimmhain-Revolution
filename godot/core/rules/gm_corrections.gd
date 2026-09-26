class_name GmCorrections
extends RefCounted
## Spielleiterkorrektur (G-GM-1, G-TOD-2). Verlangt bestätigte Warnung und Begründung,
## protokolliert Ziel, alten und neuen Wert. Keine Rücknahme früherer Befehle oder
## Ereignisse: Die Korrektur ist ein eigener, angehängter Befehl.
## Die Scheinrolle des Trugbilderwolfs ist nicht korrigierbar (DECISION-LOG).

const KILL := "kill"
const REVIVE := "revive"
const SET_ROLE := "set_role"
const DECLARE_WINNER := "declare_winner"
const WINNER_KINDS: Array[String] = ["village", "wolves", "solo", "none"]


static func validate(s: GameState, p: Dictionary) -> StringName:
	if not (p.get("confirmed") is bool and bool(p["confirmed"])):
		return &"confirmation_required"
	if DictRead.get_string(p, "reason").strip_edges() == "":
		return &"reason_required"
	var kind := DictRead.get_string(p, "kind")
	if kind == DECLARE_WINNER:
		if not WINNER_KINDS.has(DictRead.get_string(p, "winner_kind")):
			return &"invalid_correction"
		if s.pending_prompt != null:
			return &"prompt_open"
		if not s.reactions.is_empty():
			return &"reaction_open"
		return &""
	if not [KILL, REVIVE, SET_ROLE].has(kind):
		return &"invalid_correction"
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	if not s.players.has(target):
		return &"unknown_player"
	var player := s.players[target]
	match kind:
		KILL:
			if not player.alive:
				return &"player_dead"
			if not p.get("trigger_effects") is bool:
				return &"invalid_correction"  # Folgen müssen ausdrücklich gewählt werden
		REVIVE:
			if player.alive:
				return &"player_alive"
		SET_ROLE:
			var role := StringName(DictRead.get_string(p, "role_id"))
			if not RoleCatalog.has_role(role) or RoleCatalog.is_test_only(role):
				return &"unknown_role"
			if role == player.role_id:
				return &"no_change"
	return &""


static func execute(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var kind := DictRead.get_string(p, "kind")
	var reason := DictRead.get_string(p, "reason").strip_edges()
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	var trigger_effects := DictRead.get_bool(p, "trigger_effects")
	match kind:
		KILL:
			_log(ctx, kind, target, {"alive": true}, {"alive": false}, reason, trigger_effects)
			KillPipeline.request_kill(ctx, target, KillEvent.CAUSE_GM_CORRECTION, KillEvent.SOURCE_GM, -1, trigger_effects)
		REVIVE:
			var player := s.players[target]
			var old := {"alive": false, "death": player.death.to_dict() if player.death != null else null}
			player.alive = true
			player.death = null
			_log(ctx, kind, target, old, {"alive": true, "death": null}, reason, false)
			s.win_check_pending = true
		SET_ROLE:
			var player := s.players[target]
			var old := _role_fields(player)
			var role := StringName(DictRead.get_string(p, "role_id"))
			player.role_id = role
			player.faction = RoleCatalog.faction_of(role)
			player.counts_as_wolf = RoleCatalog.counts_as_wolf(role)
			player.appears_as = RoleCatalog.appears_as(role)
			_log(ctx, kind, target, old, _role_fields(player), reason, false)
			s.win_check_pending = true
		DECLARE_WINNER:
			var winner := WinCandidate.new()
			winner.id = s.next_candidate_id
			s.next_candidate_id += 1
			winner.kind = StringName(DictRead.get_string(p, "winner_kind"))
			winner.reason_key = WinCandidate.REASON_GM_DECLARED
			winner.status = WinCandidate.STATUS_CONFIRMED
			winner.detected_at_command = ctx.command_index
			winner.resolved_at_command = ctx.command_index
			_log(ctx, kind, GameState.NO_TARGET, {"winner": null}, {"winner": winner.to_dict()}, reason, false)
			s.winner = winner
			s.win_check_pending = false
			s.provisional_win = []
			ctx.emit(GameEvent.WIN_CONFIRMED, Visibility.PUBLIC, {"winner": winner.to_dict()})
			PhaseMachine.enter(ctx, Phase.GAME_OVER)


static func _role_fields(player: Player) -> Dictionary:
	return {
		"role_id": player.role_id,
		"faction": player.faction,
		"counts_as_wolf": player.counts_as_wolf,
		"appears_as": player.appears_as,
	}


static func _log(ctx: RuleContext, kind: String, target: int, old: Dictionary, new: Dictionary, reason: String, trigger_effects: bool) -> void:
	ctx.emit(GameEvent.GM_CORRECTED, Visibility.GM, {
		"kind": kind, "target_id": target, "old": old, "new": new, "reason": reason, "trigger_effects": trigger_effects,
	})
