class_name InfoSteps
extends RefCounted
## Informationsschritte ohne Tötung (DECISION-LOG „Rollenaudit“, 27.09.2026):
##   Dorfchronistin (nur Nacht 1): Anzahl der Personen mit Einzelsiegrolle, lebend und tot (F-09).
##   Die Gebundenen (nur Nacht 1, ein gemeinsamer Schritt): die anderen lebenden Gebundenen (F-08).
##   Waldläufer (jede Nacht): Anzahl lebender Personen, die als Wolf zählen (RM-DR-147).
##   Doktor (jede Nacht): zwei andere Lebende, gleiche aktuelle Fraktion ja/nein (RM-DR-145).
## Prompt mit Stufe „Gezeigt“ (nur Ja), beim Doktor vorher „targets“. Abbrechbar, nicht
## überspringbar. Der Spielleiter sieht die Information im Prompt; mit „Gezeigt“ erhält jede
## betroffene Person ein eigenes ACTOR-Ereignis, der Spielleiter einen Datensatz.

const STAGE_TARGETS := &"targets"
const STAGE_SHOWN := &"shown"
const STAGES: Array[StringName] = [STAGE_TARGETS, STAGE_SHOWN]
const OWNERS: Array[StringName] = [PendingPrompt.OWNER_CHRONICLER, PendingPrompt.OWNER_BOUND, PendingPrompt.OWNER_RANGER, PendingPrompt.OWNER_DOCTOR]
const FIRST_NIGHT_OWNERS: Array[StringName] = [PendingPrompt.OWNER_CHRONICLER, PendingPrompt.OWNER_BOUND]


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


static func living_wolf_count(s: GameState) -> int:
	var n := 0
	for id: int in s.alive_ids():
		if s.players[id].counts_as_wolf:
			n += 1
	return n


## RM-DR-145: gleiche aktuelle Fraktion; zwei Einzelsiegpersonen gelten als ein Team.
static func same_team(s: GameState, a: int, b: int) -> bool:
	return s.players[a].faction == s.players[b].faction


static func _others_alive(s: GameState, actor_id: int) -> Array[int]:
	var allowed := s.alive_ids()
	allowed.erase(actor_id)
	return allowed


## Füllt den Prompt für den erwarteten Schritt von `owner` (Person `actor_id` oder −1 für Gebundene).
static func open(s: GameState, prompt: PendingPrompt, owner: StringName, actor_id: int) -> void:
	prompt.kind = PendingPrompt.KIND_INFO_SHOWN
	prompt.owner = owner
	prompt.actor_id = actor_id
	prompt.cancellable = true
	if owner == PendingPrompt.OWNER_DOCTOR:
		prompt.stage = STAGE_TARGETS
		prompt.allowed_ids = _others_alive(s, actor_id)
		prompt.min_count = 2
		prompt.max_count = 2
		prompt.partial = {}
		return
	_enter_shown(prompt)
	prompt.partial = _info(s, owner)


static func _enter_shown(prompt: PendingPrompt) -> void:
	prompt.stage = STAGE_SHOWN
	prompt.allowed_ids = []
	prompt.min_count = 0
	prompt.max_count = 0


static func _info(s: GameState, owner: StringName) -> Dictionary:
	match owner:
		PendingPrompt.OWNER_CHRONICLER:
			return {"solo_count": solo_count(s)}
		PendingPrompt.OWNER_RANGER:
			return {"wolf_count": living_wolf_count(s)}
	return {"bound_ids": living_bound(s)}


static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if prompt.stage == STAGE_TARGETS:
		if p.has("choice") or not p.get("targets") is Array:
			return &"invalid_answer"
		var targets: Variant = DictRead.to_int_array(p["targets"])
		if targets == null:
			return &"invalid_target"
		var list: Array[int] = targets
		var seen: Array[int] = []
		for t: int in list:
			if t == prompt.actor_id or seen.has(t) or not prompt.allowed_ids.has(t) or not s.players.has(t) or not s.players[t].alive:
				return &"invalid_target"
			seen.append(t)
		if list.size() != 2:
			return &"invalid_target_count"
		return &""
	if p.has("targets") or not (p.get("choice") is bool and bool(p["choice"])):
		return &"invalid_answer"  # „Gezeigt“ kennt nur Ja; zurück per CancelPrompt
	return &""


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	if prompt.stage == STAGE_TARGETS:
		var targets: Array[int] = DictRead.to_int_array(p["targets"])
		prompt.partial = {"target_ids": [targets[0], targets[1]], "same_team": same_team(s, targets[0], targets[1])}
		_enter_shown(prompt)
		ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
			"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": STAGE_TARGETS, "answer": {"targets": [targets[0], targets[1]]}, "next_stage": STAGE_SHOWN,
		})
		return
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": STAGE_SHOWN})
	var night := s.night_number
	match prompt.owner:
		PendingPrompt.OWNER_CHRONICLER:
			var count := DictRead.get_int(prompt.partial, "solo_count")
			ctx.emit(GameEvent.CHRONICLE_RECORDED, Visibility.GM, {"chronicler_id": prompt.actor_id, "solo_count": count, "night": night})
			ctx.emit(GameEvent.CHRONICLE_REVEALED, Visibility.ACTOR, {"solo_count": count, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_RANGER:
			var wolves := DictRead.get_int(prompt.partial, "wolf_count")
			ctx.emit(GameEvent.RANGER_RECORDED, Visibility.GM, {"ranger_id": prompt.actor_id, "wolf_count": wolves, "night": night})
			ctx.emit(GameEvent.RANGER_REVEALED, Visibility.ACTOR, {"wolf_count": wolves, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_DOCTOR:
			var ids: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
			var same := DictRead.get_bool(prompt.partial, "same_team")
			ctx.emit(GameEvent.DOCTOR_RECORDED, Visibility.GM, {"doctor_id": prompt.actor_id, "target_ids": ids.duplicate(), "same_team": same, "night": night})
			ctx.emit(GameEvent.DOCTOR_REVEALED, Visibility.ACTOR, {"target_ids": ids.duplicate(), "same_team": same, "night": night}, prompt.actor_id)
		_:
			var bound: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "bound_ids"))
			ctx.emit(GameEvent.BOUND_RECORDED, Visibility.GM, {"bound_ids": bound.duplicate(), "night": night})
			for id: int in bound:
				var others: Array = []
				for other: int in bound:
					if other != id:
						others.append(other)
				ctx.emit(GameEvent.BOUND_REVEALED, Visibility.ACTOR, {"other_bound_ids": others, "night": night}, id)
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


## Ladeprüfung: Der Prompt gehört zum erwarteten Schritt und zeigt die aktuelle Information.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size() or prompt.kind != PendingPrompt.KIND_INFO_SHOWN:
		return false
	if FIRST_NIGHT_OWNERS.has(prompt.owner) and s.night_number != 1:
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step):
		return false
	if prompt.owner == PendingPrompt.OWNER_BOUND:
		if key != StepQueue.BOUND or prompt.actor_id != -1 or prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty():
			return false
		var stored: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "bound_ids"))
		return stored != null and Array(stored) == living_bound(s)
	var actor: Player = s.players.get(prompt.actor_id)
	if StepQueue.step_role(key) != prompt.owner or StepQueue.step_actor(key) != prompt.actor_id:
		return false
	if actor == null or not actor.alive or actor.role_id != prompt.owner:
		return false
	if prompt.owner == PendingPrompt.OWNER_DOCTOR and prompt.stage == STAGE_TARGETS:
		return prompt.partial.is_empty() and prompt.allowed_ids == _others_alive(s, actor.id) and prompt.min_count == 2 and prompt.max_count == 2
	if prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty():
		return false
	if prompt.owner == PendingPrompt.OWNER_DOCTOR:
		var ids: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
		if ids == null or (ids as Array).size() != 2:
			return false
		var a: int = ids[0]
		var b: int = ids[1]
		for t: int in [a, b]:
			if t == actor.id or not s.players.has(t) or not s.players[t].alive:
				return false
		return a != b and prompt.partial.get("same_team") is bool and bool(prompt.partial["same_team"]) == same_team(s, a, b)
	if prompt.owner == PendingPrompt.OWNER_CHRONICLER:
		return DictRead.get_int(prompt.partial, "solo_count", -1) == solo_count(s)
	return DictRead.get_int(prompt.partial, "wolf_count", -1) == living_wolf_count(s)
