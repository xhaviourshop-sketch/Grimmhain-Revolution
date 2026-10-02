class_name SwallowerRules
extends RefCounted
## Kartenschlucker (72. Rolle, Decision Log „Kartenschlucker, Grundregeln“ und dritte Antwortrunde, 30.09.2026):
##   Stapel: Jeder zulässige Tausch einer Totenreichkarte gibt dem lebenden Kartenschlucker einen Stapel. Verfügbares
##     Guthaben (`balance`) und insgesamt gesammelte Stapel (`total`) sind getrennte Zahlen je Person. Stapel gehören
##     zur Person: Ein neuer Träger der Rolle beginnt bei null, beim bisherigen ruhen sie, Tod lässt sie bestehen.
##   Nachtaktion: Er wird jede Nacht geweckt und wählt genau eine Aktion (Kopfschütteln = nichts, zwei Finger = zwei Stapel
##     für eine Tötung, fünf Finger = fünf Stapel für einen Schild, zehn Finger = zehn Stapel für den Sieg). Zu wenig
##     Guthaben erlaubt die Aktion nicht; mit Guthaben unter zwei entfällt der Schritt wie bei jeder Rolle ohne Entscheidung.
##   Schild: höchstens einer je Person, bleibt bis zum Verbrauch (auch bei Rollenwechsel, Tod und Wiederbelebung), verhindert
##     jeden Tod außer Spielleiterkorrekturen und wird dabei verbraucht.
##   Tötung: Tod am Morgen (Todesmarkierung), Ursache KARTENSCHLUCKER_KILL, wirkt wie jede Rollenfähigkeit (Schutz, Schilde).
##   Sieg: Zehn Stapel allein lösen nichts aus; die Zehn-Finger-Aktion gibt zehn Stapel ab und macht den Sieg zum Kandidaten,
##     solange die Person lebt und die Rolle hält (Spielleiterbestätigung wie bei jedem Einzelsieg).
##   Ansage: In den Nächten 3, 6, 9 … nennt der Morgen öffentlich die Gesamtzahl aller gesammelten Stapel, ohne Käufe zu verraten.

const KILL_COST := 2
const SHIELD_COST := 5
const WIN_COST := 10
const ANNOUNCE_EVERY := 3

const STAGE_ACT := &"act"
const STAGE_TARGET := &"target"
const STAGES: Array[StringName] = [STAGE_ACT, STAGE_TARGET]

const OPT_NONE := "none"
const OPT_KILL := "kill"
const OPT_SHIELD := "shield"
const OPT_WIN := "win"


static func living_bearers(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.alive_ids():
		if s.players[id].role_id == RoleCatalog.KARTENSCHLUCKER:
			out.append(id)
	return out


static func _entry(s: GameState, id: int) -> Dictionary:
	return (s.cardsys["stacks"] as Dictionary).get(str(id), {"total": 0, "balance": 0})


static func total_of(s: GameState, id: int) -> int:
	return int(_entry(s, id)["total"]) if s.death_cards else 0


static func balance_of(s: GameState, id: int) -> int:
	return int(_entry(s, id)["balance"]) if s.death_cards else 0


static func has_shield(s: GameState, id: int) -> bool:
	return s.death_cards and (s.cardsys["shields"] as Array).has(id)


## Ein Stapel für den ersten lebenden Kartenschlucker (Tausch, 3A). Gibt dessen ID zurück oder -1.
static func gain_stack(ctx: RuleContext, n: int) -> int:
	var s := ctx.state
	var bearers := living_bearers(s)
	if bearers.is_empty():
		return -1
	var id := bearers[0]
	var e := _entry(s, id).duplicate()
	e["total"] = int(e["total"]) + n
	e["balance"] = int(e["balance"]) + n
	(s.cardsys["stacks"] as Dictionary)[str(id)] = e
	ctx.emit(GameEvent.CARD_STACK_GAINED, Visibility.GM, {"player_id": id, "total": e["total"], "balance": e["balance"]})
	return id


static func _pay(s: GameState, id: int, n: int) -> void:
	var e := _entry(s, id).duplicate()
	e["balance"] = int(e["balance"]) - n
	(s.cardsys["stacks"] as Dictionary)[str(id)] = e


## Aktionen, die der Person jetzt offenstehen, als Text-IDs in fester Reihenfolge; leer, wenn nur Nichtstun bliebe.
static func options(s: GameState, id: int) -> Array[String]:
	var out: Array[String] = []
	var balance := balance_of(s, id)
	if balance >= KILL_COST and not _others_alive(s, id).is_empty():
		out.append(OPT_KILL)
	if balance >= SHIELD_COST and not has_shield(s, id):
		out.append(OPT_SHIELD)
	if balance >= WIN_COST:
		out.append(OPT_WIN)
	if not out.is_empty():
		out.push_front(OPT_NONE)
	return out


static func _others_alive(s: GameState, id: int) -> Array[int]:
	var ids := s.alive_ids()
	ids.erase(id)
	return ids


## Plant der Nachtplan einen Schritt? Nur lebende Träger mit mindestens einer bezahlbaren Aktion (sonst nur Ansage).
static func has_decision(s: GameState, id: int) -> bool:
	return s.death_cards and not options(s, id).is_empty()


static func open(s: GameState, prompt: PendingPrompt, actor_id: int) -> void:
	prompt.owner = PendingPrompt.OWNER_SWALLOWER
	prompt.actor_id = actor_id
	prompt.stage = STAGE_ACT
	prompt.cancellable = true
	prompt.allowed_ids = []
	prompt.min_count = 0
	prompt.max_count = 0
	prompt.partial = {"options": options(s, actor_id)}


static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if prompt.stage == STAGE_ACT:
		var opts: Array = DictRead.get_array(prompt.partial, "options")
		if not DictRead.is_int_like(p.get("option")) or int(p["option"]) < 0 or int(p["option"]) >= opts.size():
			return &"invalid_option"
		return &""
	var targets: Variant = DictRead.to_int_array(DictRead.get_array(p, "targets"))
	if targets == null or not p.get("targets") is Array or (targets as Array).size() != 1:
		return &"invalid_target"
	if not prompt.allowed_ids.has((targets as Array)[0]) or not s.players[(targets as Array)[0]].alive:
		return &"invalid_target"
	return &""


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	var actor := prompt.actor_id
	if prompt.stage == STAGE_ACT:
		var choice := String((DictRead.get_array(prompt.partial, "options"))[int(p["option"])])
		ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": "act", "choice": choice})
		match choice:
			OPT_KILL:
				prompt.stage = STAGE_TARGET
				prompt.allowed_ids = _others_alive(s, actor)
				prompt.min_count = 1
				prompt.max_count = 1
				prompt.partial = {"choice": OPT_KILL}
				return
			OPT_SHIELD:
				_pay(s, actor, SHIELD_COST)
				(s.cardsys["shields"] as Array).append(actor)
				(s.cardsys["shields"] as Array).sort()
				ctx.emit(GameEvent.CARD_SWALLOWER_ACTED, Visibility.GM, {"player_id": actor, "action": OPT_SHIELD, "night": s.night_number})
			OPT_WIN:
				_pay(s, actor, WIN_COST)
				if not (s.cardsys["swallower_wins"] as Array).has(actor):
					(s.cardsys["swallower_wins"] as Array).append(actor)
					(s.cardsys["swallower_wins"] as Array).sort()
				s.win_check_pending = true
				ctx.emit(GameEvent.CARD_SWALLOWER_ACTED, Visibility.GM, {"player_id": actor, "action": OPT_WIN, "night": s.night_number})
			_:
				ctx.emit(GameEvent.CARD_SWALLOWER_ACTED, Visibility.GM, {"player_id": actor, "action": OPT_NONE, "night": s.night_number})
	else:
		var target: int = DictRead.to_int_array(DictRead.get_array(p, "targets"))[0]
		_pay(s, actor, KILL_COST)
		s.death_marks.append({"target_id": target, "source_id": actor, "cause": String(KillEvent.CAUSE_SWALLOWER_KILL)})
		ctx.emit(GameEvent.CARD_SWALLOWER_ACTED, Visibility.GM, {"player_id": actor, "action": OPT_KILL, "target_id": target, "night": s.night_number})
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": String(prompt.stage)})
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


## Ladeprüfung eines offenen Kartenschlucker-Prompts.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if not s.death_cards or s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size() or prompt.kind != PendingPrompt.KIND_PICK_PLAYERS:
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step) or StepQueue.step_role(key) != RoleCatalog.KARTENSCHLUCKER or StepQueue.step_actor(key) != prompt.actor_id:
		return false
	var actor: Player = s.players.get(prompt.actor_id)
	if actor == null or not actor.alive or actor.role_id != RoleCatalog.KARTENSCHLUCKER:
		return false
	if prompt.stage == STAGE_ACT:
		return prompt.partial.size() == 1 and DictRead.get_array(prompt.partial, "options") == Array(options(s, actor.id)) and prompt.allowed_ids.is_empty() and prompt.min_count == 0 and prompt.max_count == 0
	return prompt.stage == STAGE_TARGET and prompt.partial.size() == 1 and DictRead.get_string(prompt.partial, "choice") == OPT_KILL \
		and balance_of(s, actor.id) >= KILL_COST and prompt.allowed_ids == _others_alive(s, actor.id) and prompt.min_count == 1 and prompt.max_count == 1


## Schild (KS-06, KS-07): verhindert jeden Tod außer Spielleiterkorrekturen und wird dabei verbraucht.
static func shield_prevents(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName) -> bool:
	var s := ctx.state
	if not s.death_cards or source_kind == KillEvent.SOURCE_GM or not has_shield(s, target.id):
		return false
	if CardEffects.protections_paused(s, target.id):
		return false  # Gebrochener Schild (fluch_05) lässt auch gekaufte Schilde ruhen (achte Antwortrunde)
	(s.cardsys["shields"] as Array).erase(target.id)
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target.id, "cause": cause, "source_kind": source_kind,
		"protection": RoleCatalog.KARTENSCHLUCKER, "sources": [RoleCatalog.KARTENSCHLUCKER], "night": s.night_number})
	return true


## Morgenansage in den Nächten 3, 6, 9 …: öffentlich nur die Gesamtzahl aller gesammelten Stapel (KS-04, KS-08).
static func announce(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.death_cards or s.night_number % ANNOUNCE_EVERY != 0:
		return
	var bearers := living_bearers(s)
	if bearers.is_empty():
		return
	var total := 0
	for id: int in bearers:
		total += total_of(s, id)
	ctx.emit(GameEvent.SWALLOWER_ANNOUNCED, Visibility.PUBLIC, {"total": total, "night": s.night_number})


static func wins(s: GameState, id: int) -> bool:
	var p: Player = s.players.get(id)
	return s.death_cards and p != null and p.alive and p.role_id == RoleCatalog.KARTENSCHLUCKER and (s.cardsys["swallower_wins"] as Array).has(id)
