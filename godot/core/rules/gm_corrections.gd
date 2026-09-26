class_name GmCorrections
extends RefCounted
## Spielleiterkorrektur (G-GM-1, G-TOD-2). Verlangt bestätigte Warnung und Begründung,
## protokolliert Ziel, alten und neuen Wert. Keine Rücknahme früherer Befehle oder
## Ereignisse: Die Korrektur ist ein eigener, angehängter Befehl.
## Jede Korrektur des Spielerzustands bricht einen offenen Prompt ab
## (AUTO_CANCEL_REASON); der zugehörige Schritt bleibt erneut ausführbar. So verweist
## nie ein Prompt auf veraltete Ziele (DECISION-LOG, Korrekturrunde 26.09.2026).

const KILL := "kill"
const EXECUTE := "execute"            ## Hinrichtung ohne Nominierung (DR-03-Übersteuerung)
const REVIVE := "revive"
const SET_ROLE := "set_role"
const SET_ROLE_FIELD := "set_role_field"
const DECLARE_WINNER := "declare_winner"
const SET_PROTECTION := "set_protection"        ## Schutz der laufenden Nacht setzen oder ändern
const REMOVE_PROTECTION := "remove_protection"  ## Schutz der laufenden Nacht entfernen
const SET_WITCH_POTION := "set_witch_potion"    ## Heil- oder Gifttrank als verfügbar/verbraucht markieren
const SET_RESCUE := "set_rescue"                ## bestätigte Rettung der laufenden Nacht setzen oder ändern
const REMOVE_RESCUE := "remove_rescue"          ## bestätigte Rettung der laufenden Nacht entfernen
const WINNER_KINDS: Array[String] = ["village", "wolves", "solo", "none"]
## Einzeln korrigierbare Rollenfelder. `appears_as` trägt die Erscheinung gegenüber
## Informationsrollen, beim Trugbilderwolf die Scheinrolle (DR-08).
const CORRECTABLE_ROLE_FIELDS: Array[String] = ["appears_as"]
const AUTO_CANCEL_REASON := "state_changed_by_gm_correction"


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
	if kind == SET_PROTECTION or kind == REMOVE_PROTECTION:
		return _validate_protection(s, p, kind)
	if kind == SET_WITCH_POTION or kind == SET_RESCUE or kind == REMOVE_RESCUE:
		return _validate_witch(s, p, kind)
	if not [KILL, EXECUTE, REVIVE, SET_ROLE, SET_ROLE_FIELD].has(kind):
		return &"invalid_correction"
	if kind == EXECUTE:
		if s.phase != Phase.DAY:
			return &"wrong_phase"
		if s.day_step == Phase.DAY_ENDED:
			return &"day_already_ended"
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
		EXECUTE:
			if not player.alive:
				return &"player_dead"
		REVIVE:
			if player.alive:
				return &"player_alive"
		SET_ROLE_FIELD:
			var field := DictRead.get_string(p, "field")
			if not CORRECTABLE_ROLE_FIELDS.has(field):
				return &"field_not_correctable"
			var value: Variant = p.get("value")
			if not (value is String or value is StringName):
				return &"invalid_value"
			var role := StringName(value)
			if not RoleCatalog.has_role(role):
				return &"invalid_value"
			if role == player.get(field):
				return &"no_change"
		SET_ROLE:
			var role := StringName(DictRead.get_string(p, "role_id"))
			if not RoleCatalog.has_role(role):
				return &"unknown_role"
			if role == player.role_id:
				return &"no_change"
	return &""


## Schutzkorrektur nur in der laufenden Nacht und erst nach erledigtem Schritt des
## Schutzengels; Selbstschutz bleibt verboten.
static func _validate_protection(s: GameState, p: Dictionary, kind: String) -> StringName:
	if s.phase != Phase.NIGHT:
		return &"wrong_phase"
	var guardian := DictRead.get_int(p, "guardian_id", GameState.NO_TARGET)
	if not s.players.has(guardian):
		return &"unknown_player"
	if s.players[guardian].role_id != RoleCatalog.SCHUTZENGEL:
		return &"not_a_guardian"
	var index := s.night_plan.find(StepQueue.personal_step_key(RoleCatalog.SCHUTZENGEL, guardian))
	if index == -1:
		return &"no_guard_step"
	if index >= s.next_night_step:
		return &"step_not_completed"
	var current := Protections.of_guardian(s, guardian)
	if kind == REMOVE_PROTECTION:
		return &"no_change" if current == null else &""
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	if not s.players.has(target):
		return &"unknown_player"
	if not s.players[target].alive:
		return &"player_dead"
	if target == guardian:
		return &"invalid_target"
	if current != null and current.target_id == target:
		return &"no_change"
	return &""


## Waldhexe: Trankstatus jederzeit; Rettung nur in der laufenden Nacht, erst nach
## bestätigtem Waldhexenschritt und nur auf das aktuelle lebende Rudelopfer. Nach der
## Morgenauflösung gibt es keine Rettungskorrektur, also keine rückwirkende Wiederbelebung.
## Gift wird nicht hierüber abgebildet, sondern über `kill`.
static func _validate_witch(s: GameState, p: Dictionary, kind: String) -> StringName:
	var witch := DictRead.get_int(p, "witch_id", GameState.NO_TARGET)
	if not s.players.has(witch):
		return &"unknown_player"
	if s.players[witch].role_id != RoleCatalog.WALDHEXE:
		return &"not_a_witch"
	if kind == SET_WITCH_POTION:
		var potion := DictRead.get_string(p, "potion")
		if not WitchStep.POTIONS.has(potion) or not p.get("available") is bool:
			return &"invalid_correction"
		return &"no_change" if WitchStep.potion_available(s.players[witch], potion) == bool(p["available"]) else &""
	if s.phase != Phase.NIGHT:
		return &"wrong_phase"
	var action := WitchStep.action_of(s, witch)
	if action == null:
		var index := s.night_plan.find(StepQueue.personal_step_key(RoleCatalog.WALDHEXE, witch))
		return &"step_not_completed" if index >= s.next_night_step else &"no_witch_step"
	if kind == REMOVE_RESCUE:
		return &"no_change" if action.saved_id == GameState.NO_TARGET else &""
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	if not s.players.has(target):
		return &"unknown_player"
	if s.pack_target_id == GameState.NO_TARGET:
		return &"no_pack_target"
	if target != s.pack_target_id:
		return &"not_current_pack_target"
	if not s.players[target].alive:
		return &"player_dead"
	if action.saved_id == target:
		return &"no_change"
	return &""


static func execute(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var kind := DictRead.get_string(p, "kind")
	var reason := DictRead.get_string(p, "reason").strip_edges()
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	var trigger_effects := DictRead.get_bool(p, "trigger_effects")
	if kind != DECLARE_WINNER and s.pending_prompt != null:
		StepQueue.cancel_prompt(ctx, AUTO_CANCEL_REASON)
	match kind:
		KILL:
			_log(ctx, kind, target, {"alive": true}, {"alive": false}, reason, trigger_effects)
			KillPipeline.request_kill(ctx, target, KillEvent.CAUSE_GM_CORRECTION, KillEvent.SOURCE_GM, -1, trigger_effects)
		SET_PROTECTION, REMOVE_PROTECTION:
			var guardian := DictRead.get_int(p, "guardian_id", GameState.NO_TARGET)
			var current := Protections.of_guardian(s, guardian)
			var old := {"protected_id": current.target_id if current != null else GameState.NO_TARGET}
			if kind == SET_PROTECTION:
				Protections.set_protection(s, guardian, target)
			else:
				Protections.remove_protection(s, guardian)
			_log(ctx, kind, guardian, old, {"protected_id": target if kind == SET_PROTECTION else GameState.NO_TARGET}, reason, false)
		SET_WITCH_POTION:
			var witch := s.players[DictRead.get_int(p, "witch_id")]
			var potion := DictRead.get_string(p, "potion")
			var old := {"potion": potion, "available": WitchStep.potion_available(witch, potion)}
			WitchStep.set_potion_available(witch, potion, bool(p["available"]))
			_log(ctx, kind, witch.id, old, {"potion": potion, "available": bool(p["available"])}, reason, false)
		SET_RESCUE, REMOVE_RESCUE:
			# Nur die Rettung; der Trankstatus bleibt eine eigene Korrektur (SET_WITCH_POTION).
			var witch_id := DictRead.get_int(p, "witch_id")
			var action := WitchStep.action_of(s, witch_id)
			var old := {"saved_id": action.saved_id}
			action.saved_id = target if kind == SET_RESCUE else GameState.NO_TARGET
			_log(ctx, kind, witch_id, old, {"saved_id": action.saved_id}, reason, false)
		EXECUTE:
			_log(ctx, kind, target, {"alive": true}, {"alive": false}, reason, true)
			s.day_step = Phase.DAY_EXECUTION_DECIDED
			ctx.emit(GameEvent.EXECUTION_CONFIRMED, Visibility.PUBLIC, {"target_id": target, "day": s.day_number, "gm_override": true})
			KillPipeline.request_kill(ctx, target, KillEvent.CAUSE_LYNCH, KillEvent.SOURCE_GM)
		SET_ROLE_FIELD:
			var player := s.players[target]
			var field := DictRead.get_string(p, "field")
			var old := {field: player.get(field)}
			player.set(field, StringName(DictRead.get_string(p, "value")))
			_log(ctx, kind, target, old, {field: player.get(field)}, reason, false)
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
