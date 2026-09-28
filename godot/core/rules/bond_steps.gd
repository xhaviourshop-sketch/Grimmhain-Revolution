class_name BondSteps
extends RefCounted
## Mehrstufige Bindungsschritte (DECISION-LOG „Rollenaudit · Bindungsrollen“, 28.09.2026):
##   Loki (nur Nacht 1): „targets“ (0 = Verzicht oder zwei verschiedene Lebende, er selbst erlaubt),
##     dann „mode“ (Ja = Liebende, Nein = Rivalen).
##   Rotkäppchen (jede Nacht): „targets“ (genau eine andere lebende Person), dann „grant“ (gewährt die
##     Person Zuflucht?). Ja: Todeskette ersetzt die bisherige, Apfel für die folgende Nacht; Nein: nichts.
## Abbrechbar, nicht überspringbar; bestätigte Stufen bleiben bis zur letzten Antwort im Prompt.

const STAGE_TARGETS := &"targets"
const STAGE_MODE := &"mode"
const STAGE_GRANT := &"grant"
const STAGES: Array[StringName] = [STAGE_TARGETS, STAGE_MODE, STAGE_GRANT]
const OWNERS: Array[StringName] = [PendingPrompt.OWNER_LOKI, PendingPrompt.OWNER_RED]
const LOKI_USE_KEY := "loki:bind"


static func _targets_for(s: GameState, owner: StringName, actor_id: int) -> Array[int]:
	var ids := s.alive_ids()
	if owner == PendingPrompt.OWNER_RED:
		ids.erase(actor_id)
	return ids


static func open(s: GameState, prompt: PendingPrompt, owner: StringName, actor_id: int) -> void:
	prompt.kind = PendingPrompt.KIND_BOND
	prompt.owner = owner
	prompt.actor_id = actor_id
	prompt.cancellable = true
	prompt.stage = STAGE_TARGETS
	prompt.partial = {}
	prompt.allowed_ids = _targets_for(s, owner, actor_id)
	prompt.min_count = 0 if owner == PendingPrompt.OWNER_LOKI else 1
	prompt.max_count = 2 if owner == PendingPrompt.OWNER_LOKI else 1


static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if prompt.stage != STAGE_TARGETS:
		return &"" if (not p.has("targets") and p.get("choice") is bool) else &"invalid_answer"
	if p.has("choice") or not p.get("targets") is Array:
		return &"invalid_answer"
	var targets: Variant = DictRead.to_int_array(p["targets"])
	if targets == null:
		return &"invalid_target"
	var seen: Array[int] = []
	for t: int in targets:
		if seen.has(t) or not prompt.allowed_ids.has(t) or not s.players.has(t) or not s.players[t].alive:
			return &"invalid_target"
		seen.append(t)
	var n := seen.size()
	if prompt.owner == PendingPrompt.OWNER_LOKI and n != 0 and n != 2:
		return &"invalid_target_count"
	if prompt.owner == PendingPrompt.OWNER_RED and n != 1:
		return &"invalid_target_count"
	return &""


static func _finish(ctx: RuleContext, prompt: PendingPrompt, stage: StringName, extra: Dictionary = {}) -> void:
	var s := ctx.state
	s.pending_prompt = null
	var data := {"prompt_id": prompt.id, "owner": prompt.owner, "stage": stage}
	data.merge(extra)
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, data)
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	var night := s.night_number
	if prompt.stage == STAGE_TARGETS:
		var chosen: Array[int] = DictRead.to_int_array(p["targets"])
		if chosen.is_empty():
			_finish(ctx, prompt, STAGE_TARGETS, {"declined": true})  # Loki verzichtet
			return
		chosen.sort()
		prompt.partial = {"target_ids": chosen.duplicate()}
		prompt.stage = STAGE_MODE if prompt.owner == PendingPrompt.OWNER_LOKI else STAGE_GRANT
		prompt.allowed_ids = []
		prompt.min_count = 0
		prompt.max_count = 0
		ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
			"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": STAGE_TARGETS, "answer": {"targets": chosen.duplicate()}, "next_stage": prompt.stage,
		})
		return
	var ids: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
	var yes := bool(p["choice"])
	if prompt.stage == STAGE_MODE:
		var kind := "love" if yes else "rival"
		s.loki_pairs.append({"loki_id": prompt.actor_id, "a": int(ids[0]), "b": int(ids[1]), "kind": kind, "ended": false})
		s.players[prompt.actor_id].ability_uses[LOKI_USE_KEY] = 1
		ctx.emit(GameEvent.LOKI_BOUND, Visibility.GM, {"loki_id": prompt.actor_id, "target_ids": ids.duplicate(), "kind": kind, "night": night})
		_finish(ctx, prompt, STAGE_MODE, {"choice": yes})
		return
	var partner := int(ids[0])
	if yes:
		s.red_chains = s.red_chains.filter(func(c: Dictionary) -> bool: return int(c["red_id"]) != prompt.actor_id)
		s.red_chains.append({"red_id": prompt.actor_id, "partner_id": partner})
		s.apples[partner] = night + 1
	ctx.emit(GameEvent.RED_REFUGE, Visibility.GM, {"red_id": prompt.actor_id, "target_id": partner, "granted": yes, "night": night})
	_finish(ctx, prompt, STAGE_GRANT, {"choice": yes})


## Ladeprüfung: Der Prompt gehört zum erwarteten Schritt und passt zum Zustand.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size() or prompt.kind != PendingPrompt.KIND_BOND:
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step) or StepQueue.step_role(key) != prompt.owner or StepQueue.step_actor(key) != prompt.actor_id:
		return false
	var actor: Player = s.players.get(prompt.actor_id)
	if actor == null or not actor.alive or actor.role_id != prompt.owner:
		return false
	if prompt.stage == STAGE_TARGETS:
		var count := 2 if prompt.owner == PendingPrompt.OWNER_LOKI else 1
		return prompt.partial.is_empty() and prompt.allowed_ids == _targets_for(s, prompt.owner, actor.id) \
			and prompt.min_count == (0 if prompt.owner == PendingPrompt.OWNER_LOKI else 1) and prompt.max_count == count
	if prompt.stage != (STAGE_MODE if prompt.owner == PendingPrompt.OWNER_LOKI else STAGE_GRANT) or not prompt.allowed_ids.is_empty():
		return false
	var ids: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
	if ids == null or (ids as Array).size() != (2 if prompt.owner == PendingPrompt.OWNER_LOKI else 1):
		return false
	var allowed := _targets_for(s, prompt.owner, actor.id)
	var sorted := (ids as Array).duplicate()
	sorted.sort()
	return sorted == ids and (ids as Array).all(func(id: int) -> bool: return allowed.has(id) and (ids as Array).count(id) == 1)
