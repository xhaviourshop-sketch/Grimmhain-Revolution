class_name BondSteps
extends RefCounted
## Mehrstufige Wahlschritte (DECISION-LOG „Rollenaudit · Bindungsrollen“ und „· Verwandlungsrollen“):
##   Loki (nur Nacht 1): „targets“ (0 = Verzicht oder zwei verschiedene Lebende, er selbst erlaubt),
##     dann „mode“ (Ja = Liebende, Nein = Rivalen).
##   Rotkäppchen (jede Nacht): „targets“ (genau eine andere lebende Person), dann „grant“ (gewährt die
##     Person Zuflucht?). Ja: Todeskette ersetzt die bisherige, Apfel für die folgende Nacht; Nein: nichts.
##   König Lykaon (bis zur Nutzung): „ally“ (ein anderer lebender Wolf; höchstens dreimal 0 = verschieben),
##     dann „targets“ (eine lebende Dorfperson) → Trugbilderwolf mit alter Rolle als Scheinrolle.
##   Seelentauscher (bis zur Nutzung): „targets“ (0 oder zwei verschiedene Personen, lebend oder tot).
## Abbrechbar, nicht überspringbar; bestätigte Stufen bleiben bis zur letzten Antwort im Prompt.

const STAGE_TARGETS := &"targets"
const STAGE_MODE := &"mode"
const STAGE_GRANT := &"grant"
const STAGE_ALLY := &"ally"
const STAGES: Array[StringName] = [STAGE_TARGETS, STAGE_MODE, STAGE_GRANT, STAGE_ALLY]
const OWNERS: Array[StringName] = [PendingPrompt.OWNER_LOKI, PendingPrompt.OWNER_RED, PendingPrompt.OWNER_LYKAON, PendingPrompt.OWNER_SWAPPER]
const LOKI_USE_KEY := "loki:bind"
const LYCAON_USE_KEY := "koenig-lykaon:convert"
const SWAP_USE_KEY := "seelentauscher:swap"


static func lycaon_skips(p: Player) -> int:
	var n := 0
	for i: int in range(1, RoleCatalog.LYCAON_MAX_SKIPS + 1):
		if p.ability_uses.has("koenig-lykaon:skip%d" % i):
			n += 1
	return n


## Lykaon: andere lebende Wölfe als mögliche Verbündete.
static func lycaon_allies(s: GameState, actor_id: int) -> Array[int]:
	return s.alive_ids().filter(func(id: int) -> bool: return id != actor_id and s.players[id].counts_as_wolf)


## Lykaon: lebende Personen der Fraktion Dorf.
static func lycaon_targets(s: GameState) -> Array[int]:
	return s.alive_ids().filter(func(id: int) -> bool: return s.players[id].faction == Faction.VILLAGE)


static func _all_ids(s: GameState) -> Array[int]:
	var ids: Array[int] = []
	ids.assign(s.players.keys())
	ids.sort()
	return ids


static func _first_stage(owner: StringName) -> StringName:
	return STAGE_ALLY if owner == PendingPrompt.OWNER_LYKAON else STAGE_TARGETS


## Auswahl, Mindest- und Höchstzahl der ersten Stufe: [allowed, min, max].
static func _first_stage_shape(s: GameState, owner: StringName, actor_id: int) -> Array:
	match owner:
		PendingPrompt.OWNER_LOKI:
			return [s.alive_ids(), 0, 2]
		PendingPrompt.OWNER_RED:
			var others := s.alive_ids()
			others.erase(actor_id)
			return [others, 1, 1]
		PendingPrompt.OWNER_LYKAON:
			var must := lycaon_skips(s.players[actor_id]) >= RoleCatalog.LYCAON_MAX_SKIPS
			return [lycaon_allies(s, actor_id), 1 if must else 0, 1]
	return [_all_ids(s), 0, 2]


static func open(s: GameState, prompt: PendingPrompt, owner: StringName, actor_id: int) -> void:
	prompt.kind = PendingPrompt.KIND_BOND
	prompt.owner = owner
	prompt.actor_id = actor_id
	prompt.cancellable = true
	prompt.stage = _first_stage(owner)
	prompt.partial = {}
	var shape := _first_stage_shape(s, owner, actor_id)
	prompt.allowed_ids.assign(shape[0])
	prompt.min_count = shape[1]
	prompt.max_count = shape[2]


static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if prompt.stage == STAGE_MODE or prompt.stage == STAGE_GRANT:
		return &"" if (not p.has("targets") and p.get("choice") is bool) else &"invalid_answer"
	if p.has("choice") or not p.get("targets") is Array:
		return &"invalid_answer"
	var targets: Variant = DictRead.to_int_array(p["targets"])
	if targets == null:
		return &"invalid_target"
	var seen: Array[int] = []
	var dead_allowed := prompt.owner == PendingPrompt.OWNER_SWAPPER
	for t: int in targets:
		if seen.has(t) or not prompt.allowed_ids.has(t) or not s.players.has(t) or (not dead_allowed and not s.players[t].alive):
			return &"invalid_target"
		seen.append(t)
	var n := seen.size()
	if n < prompt.min_count or n > prompt.max_count:
		return &"invalid_target_count"
	if prompt.max_count == 2 and n == 1:
		return &"invalid_target_count"  # Loki und Seelentauscher: keiner oder zwei
	return &""


static func _finish(ctx: RuleContext, prompt: PendingPrompt, stage: StringName, extra: Dictionary = {}) -> void:
	var s := ctx.state
	s.pending_prompt = null
	var data := {"prompt_id": prompt.id, "owner": prompt.owner, "stage": stage}
	data.merge(extra)
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, data)
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


static func _next_stage(ctx: RuleContext, prompt: PendingPrompt, answered: StringName, chosen: Array[int], next: StringName, allowed: Array[int], count: int) -> void:
	prompt.stage = next
	prompt.allowed_ids = allowed
	prompt.min_count = count
	prompt.max_count = count
	ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
		"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": answered, "answer": {"targets": chosen.duplicate()}, "next_stage": next,
	})


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	if prompt.stage == STAGE_MODE or prompt.stage == STAGE_GRANT:
		_answer_choice(ctx, prompt, bool(p["choice"]))
		return
	var chosen: Array[int] = DictRead.to_int_array(p["targets"])
	if prompt.stage == STAGE_ALLY:
		if chosen.is_empty():
			# Lykaon verschiebt (höchstens dreimal, V-08/V-09).
			var actor := s.players[prompt.actor_id]
			actor.ability_uses["koenig-lykaon:skip%d" % (lycaon_skips(actor) + 1)] = 1
			_finish(ctx, prompt, STAGE_ALLY, {"declined": true})
			return
		prompt.partial = {"ally_id": chosen[0]}
		_next_stage(ctx, prompt, STAGE_ALLY, chosen, STAGE_TARGETS, lycaon_targets(s), 1)
		return
	if prompt.owner == PendingPrompt.OWNER_LYKAON:
		_convert(ctx, prompt, int(prompt.partial["ally_id"]), chosen[0])
		return
	if chosen.is_empty():
		_finish(ctx, prompt, STAGE_TARGETS, {"declined": true})  # Loki oder Seelentauscher verzichtet
		return
	chosen.sort()
	if prompt.owner == PendingPrompt.OWNER_SWAPPER:
		_swap(ctx, prompt, chosen[0], chosen[1])
		return
	prompt.partial = {"target_ids": chosen.duplicate()}
	var none: Array[int] = []
	_next_stage(ctx, prompt, STAGE_TARGETS, chosen, STAGE_MODE if prompt.owner == PendingPrompt.OWNER_LOKI else STAGE_GRANT, none, 0)


static func _answer_choice(ctx: RuleContext, prompt: PendingPrompt, yes: bool) -> void:
	var s := ctx.state
	var night := s.night_number
	var ids: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
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


## König Lykaon (V-03): Ziel wird Trugbilderwolf mit alter Rolle als Scheinrolle; Wächter am Tor blockiert.
static func _convert(ctx: RuleContext, prompt: PendingPrompt, ally: int, target: int) -> void:
	var s := ctx.state
	var from := s.players[target].role_id
	s.players[prompt.actor_id].ability_uses[LYCAON_USE_KEY] = 1
	ctx.emit(GameEvent.LYCAON_CONVERTED, Visibility.GM, {"lycaon_id": prompt.actor_id, "ally_id": ally, "target_id": target, "from": String(from), "night": s.night_number})
	if Gatewarden.active(s):
		Gatewarden.block(ctx, target, RoleCatalog.TRUGBILDERWOLF, "lycaon")
	else:
		RoleTransition.change_role(s, target, RoleCatalog.TRUGBILDERWOLF, from, true)
		s.win_check_pending = true
		ctx.emit(GameEvent.LYCAON_NOTICE, Visibility.ACTOR, {"role_id": String(RoleCatalog.TRUGBILDERWOLF)}, target)
	_finish(ctx, prompt, STAGE_TARGETS)


## Seelentauscher (V-04 bis V-06): Rollen wie beim Lehrling-Erbe tauschen; Wächter prüft auch Tote.
static func _swap(ctx: RuleContext, prompt: PendingPrompt, a: int, b: int) -> void:
	var s := ctx.state
	var warden := Gatewarden.active(s)
	var pa := s.players[a]
	var pb := s.players[b]
	var ra := pa.role_id
	var rb := pb.role_id
	var app_a := pa.appears_as if RoleCatalog.requires_appearance(ra) else &""
	var app_b := pb.appears_as if RoleCatalog.requires_appearance(rb) else &""
	s.players[prompt.actor_id].ability_uses[SWAP_USE_KEY] = 1
	RoleTransition.change_role(s, a, rb, app_b, true)
	RoleTransition.change_role(s, b, ra, app_a, true)
	s.win_check_pending = true
	ctx.emit(GameEvent.SOULS_SWAPPED, Visibility.GM, {"swapper_id": prompt.actor_id, "ids": [a, b], "roles": [String(rb), String(ra)], "night": s.night_number})
	for entry: Array in [[a, rb, ra], [b, ra, rb]]:
		if warden and RoleCatalog.counts_as_wolf(entry[1]) and not RoleCatalog.counts_as_wolf(entry[2]):
			Gatewarden.block(ctx, entry[0], entry[1], "soul_swap")
		elif s.players[int(entry[0])].alive:
			ctx.emit(GameEvent.SOUL_SWAP_REVEALED, Visibility.ACTOR, {"role_id": String(entry[1])}, entry[0])
	_finish(ctx, prompt, STAGE_TARGETS)


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
	if prompt.stage == _first_stage(prompt.owner):
		var shape := _first_stage_shape(s, prompt.owner, actor.id)
		return prompt.partial.is_empty() and prompt.allowed_ids == Array(shape[0]) and prompt.min_count == shape[1] and prompt.max_count == shape[2]
	if prompt.owner == PendingPrompt.OWNER_LYKAON:
		var ally := DictRead.get_int(prompt.partial, "ally_id", -1)
		return prompt.stage == STAGE_TARGETS and lycaon_allies(s, actor.id).has(ally) and prompt.allowed_ids == lycaon_targets(s) and prompt.min_count == 1 and prompt.max_count == 1
	if prompt.owner == PendingPrompt.OWNER_SWAPPER:
		return false  # einstufig
	if prompt.stage != (STAGE_MODE if prompt.owner == PendingPrompt.OWNER_LOKI else STAGE_GRANT) or not prompt.allowed_ids.is_empty():
		return false
	var ids: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
	if ids == null or (ids as Array).size() != (2 if prompt.owner == PendingPrompt.OWNER_LOKI else 1):
		return false
	var allowed: Array = _first_stage_shape(s, prompt.owner, actor.id)[0]
	var sorted := (ids as Array).duplicate()
	sorted.sort()
	return sorted == ids and (ids as Array).all(func(id: int) -> bool: return allowed.has(id) and (ids as Array).count(id) == 1)
