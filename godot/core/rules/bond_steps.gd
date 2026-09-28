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
##   Kutscher (ab 10 Toten, bis zur Nutzung): „targets“ (0 oder drei Tote), dann „wolf“ (einer davon).
##   Dr. Victor Frankenstein (bis zur Nutzung): „targets“ (0 oder ein Toter), dann „role“ (Index in `options`).
##   Hades (ab 2 Lichtern): „targets“ (0 oder eine andere Lebende als Opfer), dann „barrier“ (Ja/Nein), wenn danach
##     eine Barriere kaufbar ist; beides wird erst mit der letzten Antwort bezahlt (SoloRules.hades_act).
## Abbrechbar, nicht überspringbar; bestätigte Stufen bleiben bis zur letzten Antwort im Prompt.

const STAGE_TARGETS := &"targets"
const STAGE_MODE := &"mode"
const STAGE_GRANT := &"grant"
const STAGE_ALLY := &"ally"
const STAGE_WOLF := &"wolf"
const STAGE_ROLE := &"role"
const STAGE_PREDICTION := &"prediction"  ## Todesprediger: {"kind": "night"|"day", "number": n}
const STAGE_REDIRECT := &"redirect"  ## Nekromant: Umlenkziel (0 = Schild statt Umlenkung)
const STAGE_BARRIER := &"barrier"  ## Hades: Barriere kaufen (Ja/Nein)
const STAGES: Array[StringName] = [STAGE_TARGETS, STAGE_MODE, STAGE_GRANT, STAGE_ALLY, STAGE_WOLF, STAGE_ROLE, STAGE_PREDICTION, STAGE_REDIRECT, STAGE_BARRIER]
const OWNERS: Array[StringName] = [PendingPrompt.OWNER_LOKI, PendingPrompt.OWNER_RED, PendingPrompt.OWNER_LYKAON, PendingPrompt.OWNER_SWAPPER,
	PendingPrompt.OWNER_COACH, PendingPrompt.OWNER_FRANKENSTEIN, PendingPrompt.OWNER_PREACHER, PendingPrompt.OWNER_NECRO, PendingPrompt.OWNER_HADES]
## Rollen, deren erste Stufe Tote auswählt.
const REVIVERS: Array[StringName] = [PendingPrompt.OWNER_COACH, PendingPrompt.OWNER_FRANKENSTEIN, PendingPrompt.OWNER_NECRO]
const LOKI_USE_KEY := "loki:bind"
const LYCAON_USE_KEY := "koenig-lykaon:convert"
const SWAP_USE_KEY := "seelentauscher:swap"


static func _revive_key(role: StringName) -> String:
	return "%s:revive" % role


static func dead_ids(s: GameState) -> Array[int]:
	return _all_ids(s).filter(func(id: int) -> bool: return not s.players[id].alive)


## Kutscher (ab 10 Toten, mindestens drei Tote) und Frankenstein (mindestens ein Toter), je Leben einmal.
static func can_revive(s: GameState, p: Player) -> bool:
	if not p.alive or p.ability_uses.has(_revive_key(p.role_id)):
		return false
	var dead := dead_ids(s).size()
	if p.role_id == RoleCatalog.KUTSCHER:
		return dead >= RoleCatalog.COACH_MIN_DEAD and dead >= RoleCatalog.COACH_REVIVALS
	return p.role_id == RoleCatalog.FRANKENSTEIN and dead >= 1


## Frankenstein (W-04): Rollen, die gerade niemand hat (lebend oder tot), Dorfbewohner immer, keine Wolfsrolle.
static func frankenstein_options(s: GameState) -> Array[String]:
	var taken := {}
	for id: int in s.players:
		taken[s.players[id].role_id] = true
	var out: Array[String] = []
	for role: StringName in RoleCatalog.ROLES:
		if RoleCatalog.counts_as_wolf(role) or RoleCatalog.requires_appearance(role):
			continue
		if role == RoleCatalog.DORFBEWOHNER or not taken.has(role):
			out.append(String(role))
	out.sort()
	return out


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
	if owner == PendingPrompt.OWNER_PREACHER:
		return STAGE_PREDICTION
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
	if owner == PendingPrompt.OWNER_COACH:
		return [dead_ids(s), 0, RoleCatalog.COACH_REVIVALS]
	if owner == PendingPrompt.OWNER_FRANKENSTEIN:
		return [dead_ids(s), 0, 1]
	if owner == PendingPrompt.OWNER_NECRO:  # keine oder genau drei ungeopferte Tote (E-18)
		return [SoloRules.necro_pool(s), 0, RoleCatalog.NECRO_SACRIFICE]
	if owner == PendingPrompt.OWNER_PREACHER:
		return [[], 0, 0]
	if owner == PendingPrompt.OWNER_HADES:  # keins oder ein Opfer (E-30)
		return [SoloRules.hades_targets(s, actor_id), 0, 1]
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
	if prompt.stage == STAGE_MODE or prompt.stage == STAGE_GRANT or prompt.stage == STAGE_BARRIER:
		return &"" if (not p.has("targets") and p.get("choice") is bool) else &"invalid_answer"
	if prompt.stage == STAGE_PREDICTION:
		return &"" if (not p.has("targets") and SoloRules.validate_prediction(s, p.get("prediction"))) else &"invalid_prediction"
	if prompt.stage == STAGE_ROLE:
		var options: Array = DictRead.get_array(prompt.partial, "options")
		if p.has("targets") or not DictRead.is_int_like(p.get("option")) or int(p["option"]) < 0 or int(p["option"]) >= options.size():
			return &"invalid_answer"
		return &""
	if p.has("choice") or not p.get("targets") is Array:
		return &"invalid_answer"
	var targets: Variant = DictRead.to_int_array(p["targets"])
	if targets == null:
		return &"invalid_target"
	var seen: Array[int] = []
	var dead_allowed := prompt.owner == PendingPrompt.OWNER_SWAPPER
	var dead_only := REVIVERS.has(prompt.owner) and prompt.stage != STAGE_REDIRECT
	for t: int in targets:
		if seen.has(t) or not prompt.allowed_ids.has(t) or not s.players.has(t):
			return &"invalid_target"
		if (dead_only and s.players[t].alive) or (not dead_only and not dead_allowed and not s.players[t].alive):
			return &"invalid_target"
		seen.append(t)
	var n := seen.size()
	if n < prompt.min_count or n > prompt.max_count:
		return &"invalid_target_count"
	if prompt.stage == STAGE_TARGETS and prompt.max_count > 1 and n != 0 and n != prompt.max_count:
		return &"invalid_target_count"  # Loki, Seelentauscher, Kutscher: keiner oder alle
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
	if prompt.stage == STAGE_BARRIER:
		var kill := DictRead.get_int(prompt.partial, "target_id", GameState.NO_TARGET)
		SoloRules.hades_act(ctx, prompt.actor_id, kill, bool(p["choice"]))
		_finish(ctx, prompt, STAGE_BARRIER, {"choice": bool(p["choice"])})
		return
	if prompt.stage == STAGE_MODE or prompt.stage == STAGE_GRANT:
		_answer_choice(ctx, prompt, bool(p["choice"]))
		return
	if prompt.stage == STAGE_PREDICTION:
		var q: Dictionary = p["prediction"]
		var prophecy := {"preacher_id": prompt.actor_id, "kind": DictRead.get_string(q, "kind"), "number": DictRead.get_int(q, "number")}
		s.prophecies.append(prophecy)
		s.players[prompt.actor_id].ability_uses["todesprediger:predict"] = 1
		ctx.emit(GameEvent.PROPHECY_SET, Visibility.GM, prophecy.duplicate())
		_finish(ctx, prompt, STAGE_PREDICTION)
		return
	if prompt.stage == STAGE_ROLE:
		var options: Array = DictRead.get_array(prompt.partial, "options")
		_revive_frankenstein(ctx, prompt, DictRead.get_int(prompt.partial, "target_id"), StringName(options[int(p["option"])]))
		return
	var chosen: Array[int] = DictRead.to_int_array(p["targets"])
	if prompt.stage == STAGE_REDIRECT:
		var dead: Array[int] = []
		dead.assign(DictRead.get_array(prompt.partial, "dead_ids"))
		if chosen.is_empty():
			SoloRules.necro_shield(ctx, prompt.actor_id, dead)
		else:
			SoloRules.necro_redirect(ctx, prompt.actor_id, dead, chosen[0])
		_finish(ctx, prompt, STAGE_REDIRECT)
		return
	if prompt.stage == STAGE_WOLF:
		_revive_coach(ctx, prompt, chosen[0])
		return
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
	if prompt.owner == PendingPrompt.OWNER_HADES:
		var victim := chosen[0] if not chosen.is_empty() else GameState.NO_TARGET
		if SoloRules.hades_can_buy_barrier(s, prompt.actor_id, victim):
			prompt.partial = {"target_id": victim}
			var none_barrier: Array[int] = []
			_next_stage(ctx, prompt, STAGE_TARGETS, chosen, STAGE_BARRIER, none_barrier, 0)
			return
		SoloRules.hades_act(ctx, prompt.actor_id, victim, false)
		_finish(ctx, prompt, STAGE_TARGETS, {"declined": victim == GameState.NO_TARGET})
		return
	if chosen.is_empty():
		_finish(ctx, prompt, STAGE_TARGETS, {"declined": true})  # Loki oder Seelentauscher verzichtet
		return
	chosen.sort()
	if prompt.owner == PendingPrompt.OWNER_SWAPPER:
		_swap(ctx, prompt, chosen[0], chosen[1])
		return
	if prompt.owner == PendingPrompt.OWNER_COACH:
		prompt.partial = {"target_ids": chosen.duplicate()}
		_next_stage(ctx, prompt, STAGE_TARGETS, chosen, STAGE_WOLF, chosen.duplicate(), 1)
		return
	if prompt.owner == PendingPrompt.OWNER_NECRO:
		# Sterbendes Rudelopfer: Umlenkung oder (0) Schild; sonst sofort Schild (E-16, E-17, E-26).
		if SoloRules.necro_attack_slot(s, prompt.actor_id) == "":
			SoloRules.necro_shield(ctx, prompt.actor_id, chosen)
			_finish(ctx, prompt, STAGE_TARGETS)
			return
		prompt.partial = {"dead_ids": chosen.duplicate()}
		_next_stage(ctx, prompt, STAGE_TARGETS, chosen, STAGE_REDIRECT, SoloRules.necro_redirect_targets(s, prompt.actor_id), 0)
		prompt.max_count = 1
		return
	if prompt.owner == PendingPrompt.OWNER_FRANKENSTEIN:
		prompt.partial = {"target_id": chosen[0], "options": frankenstein_options(s)}
		var none_left: Array[int] = []
		_next_stage(ctx, prompt, STAGE_TARGETS, chosen, STAGE_ROLE, none_left, 0)
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


## Wiederbelebte Person: frische Einsätze, neue Rolle, private Mitteilung; öffentlich am Morgen (W-04).
static func _revived(ctx: RuleContext, id: int, role: StringName, by: StringName) -> void:
	var s := ctx.state
	RoleTransition.revive(s, id)
	if role != s.players[id].role_id:
		RoleTransition.change_role(s, id, role, &"", true)
	if not s.revived_tonight.has(id):
		s.revived_tonight.append(id)
	ctx.emit(GameEvent.REVIVAL_NOTICE, Visibility.ACTOR, {"role_id": String(s.players[id].role_id)}, id)
	ctx.emit(GameEvent.REVIVED_BY_ROLE, Visibility.GM, {"player_id": id, "role_id": String(s.players[id].role_id), "by": String(by), "night": s.night_number})


## Kutscher (W-02, W-03): drei Tote leben wieder, `wolf` wird Werwolf (Wächter am Tor blockiert).
static func _revive_coach(ctx: RuleContext, prompt: PendingPrompt, wolf: int) -> void:
	var s := ctx.state
	s.players[prompt.actor_id].ability_uses[_revive_key(RoleCatalog.KUTSCHER)] = 1
	var warden := Gatewarden.active(s)
	for id: Variant in DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids")):
		var role := s.players[int(id)].role_id
		if int(id) == wolf and not RoleCatalog.counts_as_wolf(role):
			role = RoleCatalog.DORFBEWOHNER if warden else RoleCatalog.WERWOLF
		_revived(ctx, int(id), role, RoleCatalog.KUTSCHER)
	if warden and not RoleCatalog.counts_as_wolf(s.players[wolf].role_id):
		ctx.emit(GameEvent.NEW_WOLF_BLOCKED, Visibility.GM, {"player_id": wolf, "from": String(s.players[wolf].role_id), "would_be": String(RoleCatalog.WERWOLF), "source": "coachman"})
	_finish(ctx, prompt, STAGE_WOLF)


## Frankenstein (W-04): eine tote Person lebt wieder mit der gewählten freien Rolle.
static func _revive_frankenstein(ctx: RuleContext, prompt: PendingPrompt, target: int, role: StringName) -> void:
	ctx.state.players[prompt.actor_id].ability_uses[_revive_key(RoleCatalog.FRANKENSTEIN)] = 1
	_revived(ctx, target, role, RoleCatalog.FRANKENSTEIN)
	_finish(ctx, prompt, STAGE_ROLE)


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
	if prompt.owner == PendingPrompt.OWNER_COACH:
		var picked: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
		return prompt.stage == STAGE_WOLF and picked != null and (picked as Array).size() == RoleCatalog.COACH_REVIVALS \
			and prompt.allowed_ids == Array(picked) and (picked as Array).all(func(id: int) -> bool: return s.players.has(id) and not s.players[id].alive)
	if prompt.owner == PendingPrompt.OWNER_NECRO:
		# Stufe 2 nur als sterbendes Rudelopfer mit drei ungeopferten Toten (E-17, E-26).
		var sacrificed: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "dead_ids"))
		if sacrificed == null or (sacrificed as Array).size() != RoleCatalog.NECRO_SACRIFICE:
			return false
		var pool := SoloRules.necro_pool(s)
		var sorted_dead := (sacrificed as Array).duplicate()
		sorted_dead.sort()
		return prompt.stage == STAGE_REDIRECT and sorted_dead == sacrificed and (sacrificed as Array).all(func(id: int) -> bool: return pool.has(id) and (sacrificed as Array).count(id) == 1) 			and SoloRules.necro_attack_slot(s, actor.id) != "" and prompt.allowed_ids == SoloRules.necro_redirect_targets(s, actor.id) and prompt.min_count == 0 and prompt.max_count == 1
	if prompt.owner == PendingPrompt.OWNER_HADES:
		var victim := DictRead.get_int(prompt.partial, "target_id", -2)
		return prompt.stage == STAGE_BARRIER and prompt.partial.size() == 1 and (victim == GameState.NO_TARGET or SoloRules.hades_targets(s, actor.id).has(victim)) 			and SoloRules.hades_can_buy_barrier(s, actor.id, victim) and prompt.allowed_ids.is_empty() and prompt.min_count == 0 and prompt.max_count == 0
	if prompt.owner == PendingPrompt.OWNER_FRANKENSTEIN:
		var dead := DictRead.get_int(prompt.partial, "target_id", -1)
		return prompt.stage == STAGE_ROLE and s.players.has(dead) and not s.players[dead].alive and prompt.allowed_ids.is_empty() \
			and DictRead.get_array(prompt.partial, "options") == Array(frankenstein_options(s))
	if prompt.stage != (STAGE_MODE if prompt.owner == PendingPrompt.OWNER_LOKI else STAGE_GRANT) or not prompt.allowed_ids.is_empty():
		return false
	var ids: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
	if ids == null or (ids as Array).size() != (2 if prompt.owner == PendingPrompt.OWNER_LOKI else 1):
		return false
	var allowed: Array = _first_stage_shape(s, prompt.owner, actor.id)[0]
	var sorted := (ids as Array).duplicate()
	sorted.sort()
	return sorted == ids and (ids as Array).all(func(id: int) -> bool: return allowed.has(id) and (ids as Array).count(id) == 1)
