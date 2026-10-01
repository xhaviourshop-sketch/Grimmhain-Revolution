class_name InfoSteps
extends RefCounted
## Informationsschritte ohne Tötung (DECISION-LOG „Rollenaudit“, 27.09.2026):
##   Dorfchronistin (nur Nacht 1): Anzahl der Personen mit Einzelsiegrolle, lebend und tot (F-09).
##   Die Gebundenen (nur Nacht 1, ein gemeinsamer Schritt): die anderen lebenden Gebundenen (F-08).
##   Waldläufer (jede Nacht): Anzahl lebender Personen, die als Wolf zählen (RM-DR-147).
##   Doktor (jede Nacht): zwei andere Lebende, gleiche aktuelle Fraktion ja/nein (RM-DR-145).
##   Fährtenleser (jede Nacht bis zur Nutzung, je Leben einmal): Stufe „use“ (ja/nein), dann Richtung (RM-DR-146).
##   Spürhund (jede Nacht): drei andere Lebende oder Verzicht; ✓ bei Wolf/Einzelsieg, ✗ kostet die Fähigkeit.
## Informationsrollen (DECISION-LOG „Rollenaudit · Informationsrollen“, 28.09.2026):
##   Traumdeuter (jede Nacht), Kopfgeldjäger (je offener Liste): der Spielleiter wählt drei andere Lebende,
##     mindestens eine zählt als Wolf; gezeigt werden nur die Namen („mindestens ein Wolf“).
##   König (einmal je Leben, sobald mehr Tote als Lebende): eine andere lebende Dorfperson mit wahrer Rolle.
##   Kriegerin des Lichts (einmal je Leben, Verzicht möglich): Wolf ja/nein; nein → Todesmarkierung für sie.
##   Blutpriester (einmal je Leben, Verzicht möglich): Opfer (Todesmarkierung), dann 0–3 lebende Wölfe.
##   Die Ewigen (jede Nacht, ein gemeinsamer Schritt): eine Person außerhalb der Ewigen, Einzelsieg ja/nein.
## Alle Verzauberten (PE-06, ein gemeinsamer Schritt nach jedem Aufruf des Rattenfängers): Die Spielleitung sieht die
##   lebenden Verzauberten, sie öffnen die Augen und erkennen einander. Keine Karte für die Personen, keine Wirkung.
## Prompt mit Stufe „Gezeigt“ (nur Ja), beim Doktor vorher „targets“. Abbrechbar, nicht
## überspringbar. Der Spielleiter sieht die Information im Prompt; mit „Gezeigt“ erhält jede
## betroffene Person ein eigenes ACTOR-Ereignis, der Spielleiter einen Datensatz.

const STAGE_TARGETS := &"targets"
const STAGE_USE := &"use"
const TRACKER_USE_KEY := "faehrtenleser:track"
const HOUND_LOST_KEY := "spuerhund:lost"
const STAGE_SHOWN := &"shown"
const STAGE_REVEAL := &"reveal"  ## Blutpriester: 0–3 lebende Wölfe nennen
const STAGES: Array[StringName] = [STAGE_TARGETS, STAGE_USE, STAGE_SHOWN, STAGE_REVEAL]
const KING_USE_KEY := "koenig:learn"
const WARRIOR_USE_KEY := "kriegerin-des-lichts:attack"
const BLOOD_USE_KEY := "blutpriester:sacrifice"
const BLOOD_MAX_REVEAL := 3
## Auswahl von drei Personen mit mindestens einem Wolf (Traumdeuter, Kopfgeldjäger).
const TRIPLE_OWNERS: Array[StringName] = [PendingPrompt.OWNER_DREAMER, PendingPrompt.OWNER_BOUNTY]
## Freiwillige Einmal-Aktion: 0 Ziele = Verzicht (nichts verbraucht).
const OPTIONAL_OWNERS: Array[StringName] = [PendingPrompt.OWNER_WARRIOR, PendingPrompt.OWNER_BLOOD]
const OWNERS: Array[StringName] = [PendingPrompt.OWNER_CHRONICLER, PendingPrompt.OWNER_BOUND, PendingPrompt.OWNER_RANGER, PendingPrompt.OWNER_DOCTOR, PendingPrompt.OWNER_TRACKER, PendingPrompt.OWNER_HOUND,
	PendingPrompt.OWNER_DREAMER, PendingPrompt.OWNER_BOUNTY, PendingPrompt.OWNER_KING, PendingPrompt.OWNER_WARRIOR, PendingPrompt.OWNER_BLOOD, PendingPrompt.OWNER_ETERNAL, PendingPrompt.OWNER_PIPER_ALL]
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


static func tracker_used(p: Player) -> bool:
	return int(p.ability_uses.get(TRACKER_USE_KEY, 0)) >= 1


static func hound_lost(p: Player) -> bool:
	return int(p.ability_uses.get(HOUND_LOST_KEY, 0)) >= 1


## Spürhund: ✓, wenn eine der Personen (wahre aktuelle Fraktion) Wolf oder Einzelsieg ist.
static func hound_hit(s: GameState, ids: Array) -> bool:
	for id: Variant in ids:
		if s.players[int(id)].faction != Faction.VILLAGE:
			return true
	return false


static func _others_alive(s: GameState, actor_id: int) -> Array[int]:
	var allowed := s.alive_ids()
	allowed.erase(actor_id)
	return allowed


## Traumdeuter/Kopfgeldjäger: mindestens drei andere Lebende, darunter ein Wolf (I-01, I-06).
static func triple_possible(s: GameState, actor_id: int) -> bool:
	var others := _others_alive(s, actor_id)
	return others.size() >= 3 and others.any(func(id: int) -> bool: return s.players[id].counts_as_wolf)


static func _wolves_in(s: GameState, ids: Array) -> Array[int]:
	var out: Array[int] = []
	for id: Variant in ids:
		if s.players[int(id)].counts_as_wolf:
			out.append(int(id))
	out.sort()
	return out


## König (I-03): strikt mehr Tote als Lebende.
static func king_condition(s: GameState) -> bool:
	return s.players.size() - s.alive_ids().size() > s.alive_ids().size()


## König: andere lebende Personen der aktuellen Fraktion Dorf.
static func king_candidates(s: GameState, actor_id: int) -> Array[int]:
	return _others_alive(s, actor_id).filter(func(id: int) -> bool: return s.players[id].faction == Faction.VILLAGE)


static func used(p: Player, key: String) -> bool:
	return int(p.ability_uses.get(key, 0)) >= 1


static func living_eternal(s: GameState) -> Array[int]:
	return s.alive_ids().filter(func(id: int) -> bool: return s.players[id].role_id == RoleCatalog.DIE_EWIGEN)


## Lebende Ewige, die in dieser Nacht handeln können (nicht blockiert, nicht todesmarkiert).
static func awake_eternal(s: GameState) -> Array[int]:
	return living_eternal(s).filter(func(id: int) -> bool: return not s.blocked_ids.has(id) and not StepQueue.is_marked(s, id))


## Die Ewigen prüfen eine lebende Person, die nicht zu den Ewigen gehört (I-11).
static func eternal_targets(s: GameState) -> Array[int]:
	return s.alive_ids().filter(func(id: int) -> bool: return s.players[id].role_id != RoleCatalog.DIE_EWIGEN)


static func _living_wolves_except(s: GameState, actor_id: int) -> Array[int]:
	return _wolves_in(s, _others_alive(s, actor_id))


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
	if owner == PendingPrompt.OWNER_HOUND:
		if hound_lost(s.players[actor_id]):
			_enter_shown(prompt)
			prompt.partial = {"lost": true}
			return
		prompt.stage = STAGE_TARGETS
		prompt.allowed_ids = _others_alive(s, actor_id)
		prompt.min_count = 0
		prompt.max_count = 3
		prompt.partial = {}
		return
	if owner == PendingPrompt.OWNER_TRACKER:
		prompt.stage = STAGE_USE
		prompt.allowed_ids = []
		prompt.min_count = 0
		prompt.max_count = 0
		prompt.partial = {}
		return
	if TRIPLE_OWNERS.has(owner) or owner == PendingPrompt.OWNER_KING or OPTIONAL_OWNERS.has(owner) or owner == PendingPrompt.OWNER_ETERNAL:
		prompt.stage = STAGE_TARGETS
		prompt.partial = {}
		prompt.allowed_ids = _targets_for(s, owner, actor_id)
		var count := 3 if TRIPLE_OWNERS.has(owner) else 1
		prompt.min_count = 0 if OPTIONAL_OWNERS.has(owner) else count
		prompt.max_count = count
		return
	_enter_shown(prompt)
	prompt.partial = _info(s, owner)


static func _targets_for(s: GameState, owner: StringName, actor_id: int) -> Array[int]:
	if owner == PendingPrompt.OWNER_KING:
		return king_candidates(s, actor_id)
	if owner == PendingPrompt.OWNER_ETERNAL:
		return eternal_targets(s)
	return _others_alive(s, actor_id)


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
		PendingPrompt.OWNER_PIPER_ALL:
			return {"charmed_ids": SoloRules.charmed_living(s)}
	return {"bound_ids": living_bound(s)}


## Zulässige Anzahlen der aktuellen Stufe. Spürhund: keiner oder genau drei (Verzicht).
static func target_counts(prompt: PendingPrompt) -> Array[int]:
	if prompt.stage == STAGE_TARGETS and prompt.owner == PendingPrompt.OWNER_HOUND:
		return [0, prompt.max_count]
	return prompt.count_range()


## Zufallsknopf (RM-DR-015.2) nur für die Spielleiterwahl dieser Stufen: Traumdeuter und Kopfgeldjäger (drei andere
## Lebende mit mindestens einem Wolf), König (eine Person der Fraktion Dorf), Blutpriester-Aufdeckung (0 bis 3 Wölfe).
## Die Opferwahl des Blutpriesters ist seine eigene Entscheidung und bleibt ohne Zufall.
static func random_supported(prompt: PendingPrompt) -> bool:
	if prompt == null or not OWNERS.has(prompt.owner):
		return false
	if prompt.stage == STAGE_TARGETS:
		return TRIPLE_OWNERS.has(prompt.owner) or prompt.owner == PendingPrompt.OWNER_KING
	return prompt.stage == STAGE_REVEAL and prompt.owner == PendingPrompt.OWNER_BLOOD


## Vorschlag aus einer Kopie des gespeicherten Generators; `s` bleibt unverändert. Alle zulässigen Ergebnisse werden
## stabil nach Personen-ID aufgezählt und genau eines mit einer einzigen Ziehung gewählt (gleich wahrscheinlich, keine
## Wiederholungsschleife). Ergebnis {targets, rng_after} oder {} (keine Zufallswahl oder kein zulässiges Ergebnis).
static func random_choice(s: GameState) -> Dictionary:
	var prompt := s.pending_prompt
	if not random_supported(prompt):
		return {}
	var ids: Array[int] = prompt.allowed_ids.filter(func(id: int) -> bool: return id != prompt.actor_id and s.players.has(id) and s.players[id].alive)
	ids.sort()
	var results: Array = []
	if TRIPLE_OWNERS.has(prompt.owner):
		for a: int in ids.size():
			for b: int in range(a + 1, ids.size()):
				for c: int in range(b + 1, ids.size()):
					var triple := [ids[a], ids[b], ids[c]]
					if not _wolves_in(s, triple).is_empty():
						results.append(triple)
	elif prompt.owner == PendingPrompt.OWNER_KING:
		for id: int in ids:
			results.append([id])
	else:
		var wolves := _wolves_in(s, ids)
		results.append([])
		for size: int in range(1, mini(BLOOD_MAX_REVEAL, wolves.size()) + 1):
			results.append_array(_subsets(wolves, size))
	if results.is_empty():
		return {}
	var probe := SeededRng.from_dict(s.rng.to_dict())
	var picked: Array = results[probe.next_int(0, results.size() - 1)]
	return {"targets": picked, "rng_after": probe.to_dict()}


## Teilmengen fester Größe in stabiler Reihenfolge (Eingabe aufsteigend).
static func _subsets(items: Array[int], size: int, start: int = 0) -> Array:
	if size == 0:
		return [[]]
	var out: Array = []
	for i: int in range(start, items.size() - size + 1):
		for rest: Array in _subsets(items, size - 1, i + 1):
			out.append([items[i]] + rest)
	return out


static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if p.has("random"):
		if not (p["random"] is bool and bool(p["random"])) or not random_supported(prompt):
			return &"random_not_supported"
		var drawn := random_choice(s)
		var sent: Variant = DictRead.to_int_array(DictRead.get_array(p, "targets"))
		# Nur genau das Ergebnis des gespeicherten Generators gilt; veraltete oder veränderte Vorschläge nicht.
		if drawn.is_empty() or sent == null or sent != DictRead.to_int_array(drawn["targets"]):
			return &"random_mismatch"
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
		if not target_counts(prompt).has(list.size()):
			return &"invalid_target_count"
		if TRIPLE_OWNERS.has(prompt.owner) and _wolves_in(s, list).is_empty():
			return &"no_wolf_selected"  # Freigabe erst mit mindestens einem Wolf (I-01)
		return &""
	if prompt.stage == STAGE_REVEAL:
		if p.has("choice") or not p.get("targets") is Array:
			return &"invalid_answer"
		var picks: Variant = DictRead.to_int_array(p["targets"])
		if picks == null or (picks as Array).size() > BLOOD_MAX_REVEAL:
			return &"invalid_target" if picks == null else &"invalid_target_count"
		var chosen: Array[int] = []
		for t: int in picks:
			if chosen.has(t) or not prompt.allowed_ids.has(t) or not s.players.has(t) or not s.players[t].alive or not s.players[t].counts_as_wolf:
				return &"invalid_target"
			chosen.append(t)
		return &""
	if prompt.stage == STAGE_USE:
		return &"" if (not p.has("targets") and p.get("choice") is bool) else &"invalid_answer"
	if p.has("targets") or not (p.get("choice") is bool and bool(p["choice"])):
		return &"invalid_answer"  # „Gezeigt“ kennt nur Ja; zurück per CancelPrompt
	return &""


## Verzicht in dieser Nacht: keine Information, nichts verbraucht.
static func _decline(ctx: RuleContext, prompt: PendingPrompt) -> void:
	var s := ctx.state
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": STAGE_TARGETS, "declined": true})
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


static func _stage_done(ctx: RuleContext, prompt: PendingPrompt, stage: StringName, answer_data: Dictionary, next_stage: StringName) -> void:
	ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
		"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": stage, "answer": answer_data, "next_stage": next_stage,
	})


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	if DictRead.get_bool(p, "random"):
		s.rng = SeededRng.from_dict(random_choice(s)["rng_after"])  # Generatorfortschritt der bestätigten Ziehung
	if prompt.stage == STAGE_TARGETS and (TRIPLE_OWNERS.has(prompt.owner) or prompt.owner == PendingPrompt.OWNER_KING or OPTIONAL_OWNERS.has(prompt.owner) or prompt.owner == PendingPrompt.OWNER_ETERNAL):
		var chosen: Array[int] = DictRead.to_int_array(p["targets"])
		if chosen.is_empty():
			_decline(ctx, prompt)
			return
		var target := chosen[0]
		match prompt.owner:
			PendingPrompt.OWNER_KING:
				prompt.partial = {"target_id": target, "role_id": String(s.players[target].role_id)}
			PendingPrompt.OWNER_WARRIOR:
				prompt.partial = {"target_id": target, "is_wolf": s.players[target].counts_as_wolf}
			PendingPrompt.OWNER_ETERNAL:
				prompt.partial = {"target_id": target, "solo": s.players[target].faction == Faction.SOLO}
			PendingPrompt.OWNER_BLOOD:
				prompt.partial = {"victim_id": target}
				prompt.stage = STAGE_REVEAL
				prompt.allowed_ids = _living_wolves_except(s, prompt.actor_id)
				prompt.min_count = 0
				prompt.max_count = BLOOD_MAX_REVEAL
				_stage_done(ctx, prompt, STAGE_TARGETS, {"targets": [target]}, STAGE_REVEAL)
				return
			_:
				prompt.partial = {"target_ids": chosen.duplicate()}
		_enter_shown(prompt)
		_stage_done(ctx, prompt, STAGE_TARGETS, {"targets": chosen.duplicate()}, STAGE_SHOWN)
		return
	if prompt.stage == STAGE_REVEAL:
		var revealed: Array[int] = DictRead.to_int_array(p["targets"])
		revealed.sort()
		prompt.partial = {"victim_id": DictRead.get_int(prompt.partial, "victim_id"), "revealed_ids": revealed}
		_enter_shown(prompt)
		_stage_done(ctx, prompt, STAGE_REVEAL, {"targets": revealed.duplicate()}, STAGE_SHOWN)
		return
	if prompt.stage == STAGE_TARGETS and prompt.owner == PendingPrompt.OWNER_HOUND:
		var picks: Array[int] = DictRead.to_int_array(p["targets"])
		if picks.is_empty():
			_decline(ctx, prompt)
			return
		prompt.partial = {"target_ids": [picks[0], picks[1], picks[2]], "hit": hound_hit(s, picks)}
		_enter_shown(prompt)
		ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
			"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": STAGE_TARGETS, "answer": {"targets": picks.duplicate()}, "next_stage": STAGE_SHOWN,
		})
		return
	if prompt.stage == STAGE_TARGETS:
		var targets: Array[int] = DictRead.to_int_array(p["targets"])
		prompt.partial = {"target_ids": [targets[0], targets[1]], "same_team": same_team(s, targets[0], targets[1])}
		_enter_shown(prompt)
		ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
			"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": STAGE_TARGETS, "answer": {"targets": [targets[0], targets[1]]}, "next_stage": STAGE_SHOWN,
		})
		return
	if prompt.stage == STAGE_USE and bool(p["choice"]):
		prompt.partial = {"direction": Seats.wolf_direction(s, prompt.actor_id)}
		_enter_shown(prompt)
		ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
			"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": STAGE_USE, "answer": {"choice": true}, "next_stage": STAGE_SHOWN,
		})
		return
	var answered := prompt.stage
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": answered})
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
		PendingPrompt.OWNER_HOUND:
			# Ohne Fähigkeit nur aufgerufen; sonst Ergebnis an ihn, ✗ kostet die Fähigkeit (bis zur Wiederbelebung).
			if not DictRead.get_bool(prompt.partial, "lost"):
				var ids: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
				var hit := DictRead.get_bool(prompt.partial, "hit")
				if not hit:
					s.players[prompt.actor_id].ability_uses[HOUND_LOST_KEY] = 1
				ctx.emit(GameEvent.HOUND_RECORDED, Visibility.GM, {"hound_id": prompt.actor_id, "target_ids": ids.duplicate(), "hit": hit, "night": night})
				ctx.emit(GameEvent.HOUND_REVEALED, Visibility.ACTOR, {"target_ids": ids.duplicate(), "hit": hit, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_TRACKER:
			# Verzicht („use“ = nein) verbraucht nichts; „Gezeigt“ verbraucht die Nutzung dieses Lebens.
			if answered == STAGE_SHOWN:
				var direction := DictRead.get_string(prompt.partial, "direction")
				s.players[prompt.actor_id].ability_uses[TRACKER_USE_KEY] = 1
				ctx.emit(GameEvent.TRACKER_RECORDED, Visibility.GM, {"tracker_id": prompt.actor_id, "direction": direction, "night": night})
				ctx.emit(GameEvent.TRACKER_REVEALED, Visibility.ACTOR, {"direction": direction, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_DREAMER, PendingPrompt.OWNER_BOUNTY:
			var ids: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
			var dreamer := prompt.owner == PendingPrompt.OWNER_DREAMER
			if not dreamer:
				_use_bounty(s, prompt.actor_id)
			ctx.emit(GameEvent.DREAM_RECORDED if dreamer else GameEvent.BOUNTY_RECORDED, Visibility.GM,
				{"actor_id": prompt.actor_id, "target_ids": ids.duplicate(), "wolf_ids": _wolves_in(s, ids), "night": night})
			ctx.emit(GameEvent.DREAM_REVEALED if dreamer else GameEvent.BOUNTY_REVEALED, Visibility.ACTOR, {"target_ids": ids.duplicate(), "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_KING:
			var seen := DictRead.get_int(prompt.partial, "target_id")
			var role := DictRead.get_string(prompt.partial, "role_id")
			s.players[prompt.actor_id].ability_uses[KING_USE_KEY] = 1
			ctx.emit(GameEvent.KING_RECORDED, Visibility.GM, {"king_id": prompt.actor_id, "target_id": seen, "role_id": role, "night": night})
			ctx.emit(GameEvent.KING_REVEALED, Visibility.ACTOR, {"target_id": seen, "role_id": role, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_WARRIOR:
			var attacked := DictRead.get_int(prompt.partial, "target_id")
			var is_wolf := DictRead.get_bool(prompt.partial, "is_wolf")
			s.players[prompt.actor_id].ability_uses[WARRIOR_USE_KEY] = 1
			if not is_wolf:
				# Irrtum: sie stirbt in der Morgenauflösung und wacht in dieser Nacht nicht mehr auf.
				s.death_marks.append({"target_id": prompt.actor_id, "source_id": prompt.actor_id, "cause": String(KillEvent.CAUSE_WARRIOR_WRONG)})
			ctx.emit(GameEvent.WARRIOR_RECORDED, Visibility.GM, {"warrior_id": prompt.actor_id, "target_id": attacked, "is_wolf": is_wolf, "night": night})
			ctx.emit(GameEvent.WARRIOR_REVEALED, Visibility.ACTOR, {"target_id": attacked, "is_wolf": is_wolf, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_BLOOD:
			var victim := DictRead.get_int(prompt.partial, "victim_id")
			var revealed: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "revealed_ids"))
			s.players[prompt.actor_id].ability_uses[BLOOD_USE_KEY] = 1
			s.death_marks.append({"target_id": victim, "source_id": prompt.actor_id, "cause": String(KillEvent.CAUSE_BLOOD_SACRIFICE)})
			ctx.emit(GameEvent.BLOOD_RECORDED, Visibility.GM, {"priest_id": prompt.actor_id, "victim_id": victim, "revealed_ids": revealed.duplicate(), "night": night})
			ctx.emit(GameEvent.BLOOD_REVEALED, Visibility.ACTOR, {"revealed_ids": revealed.duplicate(), "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_ETERNAL:
			var checked := DictRead.get_int(prompt.partial, "target_id")
			var solo := DictRead.get_bool(prompt.partial, "solo")
			if solo and not s.eternal_finds.has(checked):
				s.eternal_finds.append(checked)
				s.eternal_finds.sort()
			var awake := awake_eternal(s)
			ctx.emit(GameEvent.ETERNAL_RECORDED, Visibility.GM, {"eternal_ids": awake.duplicate(), "target_id": checked, "solo": solo, "night": night})
			for id: int in awake:
				ctx.emit(GameEvent.ETERNAL_REVEALED, Visibility.ACTOR, {"target_id": checked, "solo": solo, "night": night}, id)
		PendingPrompt.OWNER_DOCTOR:
			var ids: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
			var same := DictRead.get_bool(prompt.partial, "same_team")
			ctx.emit(GameEvent.DOCTOR_RECORDED, Visibility.GM, {"doctor_id": prompt.actor_id, "target_ids": ids.duplicate(), "same_team": same, "night": night})
			ctx.emit(GameEvent.DOCTOR_REVEALED, Visibility.ACTOR, {"target_ids": ids.duplicate(), "same_team": same, "night": night}, prompt.actor_id)
		PendingPrompt.OWNER_PIPER_ALL:
			pass  # nur Erkennen am Tisch; kein Zustand außer dem erledigten Schritt
		_:
			var bound: Array = DictRead.to_int_array(DictRead.get_array(prompt.partial, "bound_ids"))
			ctx.emit(GameEvent.BOUND_RECORDED, Visibility.GM, {"bound_ids": bound.duplicate(), "night": night})
			for id: int in bound:
				if s.blocked_ids.has(id):
					continue  # Albtraumwolf: diese Gebundene erfährt in dieser Nacht nichts
				var others: Array = []
				for other: int in bound:
					if other != id:
						others.append(other)
				ctx.emit(GameEvent.BOUND_REVEALED, Visibility.ACTOR, {"other_bound_ids": others, "night": night}, id)
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


## Kopfgeldjäger: eine offene Liste verbrauchen (gezeigt oder verfallen).
static func _use_bounty(s: GameState, id: int) -> void:
	var left := int(s.bounty_credits.get(id, 0)) - 1
	if left > 0:
		s.bounty_credits[id] = left
	else:
		s.bounty_credits.erase(id)


## Kopfgeldjäger ohne genug Ziele: die Liste verfällt mit privatem Hinweis (I-04).
static func expire_bounty(ctx: RuleContext, id: int) -> void:
	_use_bounty(ctx.state, id)
	ctx.emit(GameEvent.BOUNTY_EXPIRED, Visibility.ACTOR, {"night": ctx.state.night_number}, id)


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
	if prompt.owner == PendingPrompt.OWNER_PIPER_ALL:
		if key != StepQueue.PIPER_ALL or prompt.actor_id != -1 or prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty():
			return false
		var charmed: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "charmed_ids"))
		return charmed != null and prompt.partial.size() == 1 and Array(charmed) == Array(SoloRules.charmed_living(s))
	if prompt.owner == PendingPrompt.OWNER_ETERNAL:
		if key != StepQueue.ETERNAL or prompt.actor_id != -1:
			return false
		if prompt.stage == STAGE_TARGETS:
			return prompt.partial.is_empty() and prompt.allowed_ids == eternal_targets(s) and prompt.min_count == 1 and prompt.max_count == 1
		var checked := DictRead.get_int(prompt.partial, "target_id", -1)
		return prompt.stage == STAGE_SHOWN and prompt.allowed_ids.is_empty() and eternal_targets(s).has(checked) \
			and prompt.partial.get("solo") is bool and bool(prompt.partial["solo"]) == (s.players[checked].faction == Faction.SOLO)
	var actor: Player = s.players.get(prompt.actor_id)
	if StepQueue.step_role(key) != prompt.owner or StepQueue.step_actor(key) != prompt.actor_id:
		return false
	if actor == null or not actor.alive or not SoloRules.acts_as(s, actor.id, prompt.owner):
		return false
	if prompt.owner == PendingPrompt.OWNER_HOUND:
		if hound_lost(actor):
			return prompt.stage == STAGE_SHOWN and prompt.allowed_ids.is_empty() and prompt.partial == {"lost": true}
		if prompt.stage == STAGE_TARGETS:
			return prompt.partial.is_empty() and prompt.allowed_ids == _others_alive(s, actor.id) and prompt.min_count == 0 and prompt.max_count == 3
		var picks: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
		if picks == null or (picks as Array).size() != 3 or not prompt.allowed_ids.is_empty():
			return false
		for t: int in picks:
			if t == actor.id or not s.players.has(t) or not s.players[t].alive or (picks as Array).count(t) > 1:
				return false
		return prompt.partial.get("hit") is bool and bool(prompt.partial["hit"]) == hound_hit(s, picks)
	if prompt.owner == PendingPrompt.OWNER_TRACKER:
		if tracker_used(actor) or not prompt.allowed_ids.is_empty():
			return false
		if prompt.stage == STAGE_USE:
			return prompt.partial.is_empty()
		return prompt.stage == STAGE_SHOWN and DictRead.get_string(prompt.partial, "direction") == Seats.wolf_direction(s, actor.id)
	if [PendingPrompt.OWNER_DREAMER, PendingPrompt.OWNER_BOUNTY, PendingPrompt.OWNER_KING, PendingPrompt.OWNER_WARRIOR, PendingPrompt.OWNER_BLOOD].has(prompt.owner):
		return _matches_new_owner(s, prompt, actor)
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


## Ladeprüfung für Traumdeuter, Kopfgeldjäger, König, Kriegerin und Blutpriester.
static func _matches_new_owner(s: GameState, prompt: PendingPrompt, actor: Player) -> bool:
	var owner := prompt.owner
	if prompt.stage == STAGE_TARGETS:
		var count := 3 if TRIPLE_OWNERS.has(owner) else 1
		return prompt.partial.is_empty() and prompt.allowed_ids == _targets_for(s, owner, actor.id) \
			and prompt.min_count == (0 if OPTIONAL_OWNERS.has(owner) else count) and prompt.max_count == count
	if owner == PendingPrompt.OWNER_BLOOD:
		var victim := DictRead.get_int(prompt.partial, "victim_id", -1)
		if not _others_alive(s, actor.id).has(victim):
			return false
		if prompt.stage == STAGE_REVEAL:
			return prompt.partial.size() == 1 and prompt.allowed_ids == _living_wolves_except(s, actor.id) and prompt.min_count == 0 and prompt.max_count == BLOOD_MAX_REVEAL
		var revealed: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "revealed_ids"))
		if prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty() or revealed == null or (revealed as Array).size() > BLOOD_MAX_REVEAL:
			return false
		var sorted := (revealed as Array).duplicate()
		sorted.sort()
		return sorted == revealed and _wolves_in(s, revealed) == Array(revealed) and (revealed as Array).all(func(id: int) -> bool: return _others_alive(s, actor.id).has(id) and (revealed as Array).count(id) == 1)
	if prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty():
		return false
	if TRIPLE_OWNERS.has(owner):
		var ids: Variant = DictRead.to_int_array(DictRead.get_array(prompt.partial, "target_ids"))
		if ids == null or (ids as Array).size() != 3 or _wolves_in(s, ids).is_empty():
			return false
		return (ids as Array).all(func(id: int) -> bool: return _others_alive(s, actor.id).has(id) and (ids as Array).count(id) == 1)
	var target := DictRead.get_int(prompt.partial, "target_id", -1)
	if owner == PendingPrompt.OWNER_KING:
		return king_candidates(s, actor.id).has(target) and DictRead.get_string(prompt.partial, "role_id") == String(s.players[target].role_id)
	return _others_alive(s, actor.id).has(target) and prompt.partial.get("is_wolf") is bool and bool(prompt.partial["is_wolf"]) == s.players[target].counts_as_wolf
