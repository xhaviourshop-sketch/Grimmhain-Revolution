class_name NightOneInfo
extends RefCounted
## Informationsschritte nur in Nacht 1 (DECISION-LOG „Rollenaudit“, RM-DR-014 = B):
##   Dorfchronistin: persönlicher Schritt; Anzahl der Personen mit Einzelsiegrolle, lebend und tot (F-09).
##   Die Gebundenen: ein gemeinsamer Schritt; jede lebende Gebundene erfährt die anderen lebenden (F-08).
## Prompt mit genau einer Stufe „Gezeigt“ (nur Ja), abbrechbar, nicht überspringbar. Der Spielleiter
## sieht die Information im Prompt; mit „Gezeigt“ erhält jede betroffene Person ein eigenes
## ACTOR-Ereignis, der Spielleiter einen Datensatz. Öffentlich wird nichts.

const STAGE_SHOWN := &"shown"
const STAGES: Array[StringName] = [STAGE_SHOWN]


static func solo_count(s: GameState) -> int:
	var n := 0
	for id: int in s.players:
		if s.players[id].faction == Faction.SOLO:
			n += 1
	return n


static func living_bound(s: GameState) -> Array:
	var out: Array = []
	for id: int in s.alive_ids():
		if s.players[id].role_id == RoleCatalog.DIE_GEBUNDENEN:
			out.append(id)
	return out


## Füllt den Prompt für den erwarteten Schritt (`owner` Chronistin mit `actor_id` oder Gebundene).
static func open(s: GameState, prompt: PendingPrompt, owner: StringName, actor_id: int) -> void:
	prompt.kind = PendingPrompt.KIND_INFO_SHOWN
	prompt.owner = owner
	prompt.actor_id = actor_id
	prompt.stage = STAGE_SHOWN
	prompt.allowed_ids = []
	prompt.min_count = 0
	prompt.max_count = 0
	prompt.cancellable = true
	prompt.partial = _partial(s, owner)


static func _partial(s: GameState, owner: StringName) -> Dictionary:
	if owner == PendingPrompt.OWNER_CHRONICLER:
		return {"solo_count": solo_count(s)}
	return {"bound_ids": living_bound(s)}


static func validate_answer(prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if p.has("targets") or not (p.get("choice") is bool and bool(p["choice"])):
		return &"invalid_answer"  # „Gezeigt“ kennt nur Ja; zurück per CancelPrompt
	return &""


static func answer(ctx: RuleContext) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": STAGE_SHOWN})
	if prompt.owner == PendingPrompt.OWNER_CHRONICLER:
		var count := DictRead.get_int(prompt.partial, "solo_count")
		ctx.emit(GameEvent.CHRONICLE_RECORDED, Visibility.GM, {"chronicler_id": prompt.actor_id, "solo_count": count, "night": s.night_number})
		ctx.emit(GameEvent.CHRONICLE_REVEALED, Visibility.ACTOR, {"solo_count": count, "night": s.night_number}, prompt.actor_id)
	else:
		var bound: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "bound_ids"))
		ctx.emit(GameEvent.BOUND_RECORDED, Visibility.GM, {"bound_ids": bound.duplicate(), "night": s.night_number})
		for id: int in bound:
			var others: Array = []
			for other: int in bound:
				if other != id:
					others.append(other)
			ctx.emit(GameEvent.BOUND_REVEALED, Visibility.ACTOR, {"other_bound_ids": others, "night": s.night_number}, id)
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


## Ladeprüfung: Der Prompt gehört zum erwarteten Schritt und zeigt die aktuelle Information.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.night_number != 1 or s.next_night_step >= s.night_plan.size():
		return false
	if prompt.kind != PendingPrompt.KIND_INFO_SHOWN or prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty():
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step):
		return false
	if prompt.owner == PendingPrompt.OWNER_CHRONICLER:
		var p: Player = s.players.get(prompt.actor_id)
		if StepQueue.step_role(key) != RoleCatalog.DORFCHRONISTIN or StepQueue.step_actor(key) != prompt.actor_id:
			return false
		if p == null or not p.alive or p.role_id != RoleCatalog.DORFCHRONISTIN:
			return false
		return DictRead.get_int(prompt.partial, "solo_count", -1) == solo_count(s)
	if key != StepQueue.BOUND or prompt.actor_id != -1:
		return false
	var stored: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "bound_ids"))
	return stored != null and Array(stored) == living_bound(s)
