class_name CardHooks
extends RefCounted
## Haken der Totenreichkarten im Spielablauf: Stellen, an denen KillPipeline, Nachtplan, Morgenauflösung und Hinrichtung
## aktive Karteneffekte befragen. Alles ist nur wirksam, wenn die Partie mit Totenreichkarten läuft (`GameState.death_cards`).
## Die Karten selbst (Eingaben, Effekt anlegen) stehen in den Familien CardFx*.
##
## Todesarten: „Rollenfähigkeit“ sind alle Tötungen mit Quelle Person außer Todesketten (Liebeskummer, Kette, Kutscherunfall,
## Feuer, Parasit) und Kartentoden (siebte bis zwölfte Antwortrunde: Gift ausdrücklich eingeschlossen, Todesketten und
## Kartentode bleiben möglich).

const ABILITY_CAUSES: Array[StringName] = [
	KillEvent.CAUSE_WITCH_POISON, KillEvent.CAUSE_WOLF_POISON, KillEvent.CAUSE_HANGMAN_EXTRA, KillEvent.CAUSE_WARRIOR_WRONG,
	KillEvent.CAUSE_BLOOD_SACRIFICE, KillEvent.CAUSE_SMITH_WEAPON, KillEvent.CAUSE_PROPHET_KILL, KillEvent.CAUSE_HADES_KILL,
	KillEvent.CAUSE_LONE_WOLF_KILL, KillEvent.CAUSE_HUNTER_SHOT, KillEvent.CAUSE_KNIGHT_STRIKE, KillEvent.CAUSE_POSSESSED_DRAG,
	KillEvent.CAUSE_BLACK_WIDOW, KillEvent.CAUSE_SWALLOWER_KILL, KillEvent.CAUSE_SPIEGELWOLF_RETALIATE,
]


static func is_pack_kill(cause: StringName, source_kind: StringName) -> bool:
	return cause == KillEvent.CAUSE_NIGHT_KILL and source_kind == KillEvent.SOURCE_PACK


static func is_ability_kill(cause: StringName) -> bool:
	return ABILITY_CAUSES.has(cause)


static func night_time(s: GameState) -> bool:
	return s.phase == Phase.NIGHT or s.phase == Phase.DAWN_RESOLUTION


## Gebrochener Schild (fluch_05): Schutzwirkungen auf Personen dieser Fraktion ruhen derzeit.
static func protections_paused(s: GameState, person_id: int) -> bool:
	if not s.death_cards:
		return false
	var variant := String(CardCatalog.owner_variant(s.players[person_id]))
	for e: Dictionary in CardEffects.active(s, "protection_pause"):
		if String(e["data"]["faction"]) == variant:
			return true
	return false


## Schutz durch „Verzweiflungsschrei“ (Dorf) gegen den Rudelangriff: wiederholbar wie der Schutzengel, durchdrungen von „pierce“.
static func pack_protected(s: GameState, target_id: int, pierce: bool) -> bool:
	if not s.death_cards or pierce or protections_paused(s, target_id):
		return false
	for e: Dictionary in CardEffects.active(s, "pack_protect"):
		if int(e["data"]["person_id"]) == target_id:
			return true
	return false


static func card_protection_exists(s: GameState, target_id: int) -> bool:
	return pack_protected(s, target_id, false)


## Nächste lebende Person der Fraktionsvariante in Richtung `step` (+1 Uhrzeigersinn = „links“, −1 = „rechts“) ab `from_id`.
static func next_living_of(s: GameState, from_id: int, step: int, variant: StringName) -> int:
	var start := s.seat_order.find(from_id)
	var n := s.seat_order.size()
	for k: int in range(1, n):
		var id := s.seat_order[posmod(start + step * k, n)]
		if id != from_id and s.players[id].alive and CardCatalog.owner_variant(s.players[id]) == variant:
			return id
	return -1


# --- Abfangen vor dem Tod -------------------------------------------------------------------------------------

## Karteneffekte, die einen Tod verhindern, umleiten oder aufschieben. Aufruf in KillPipeline nach den Schutzwirkungen.
## true: Der Tod ist behandelt (verhindert, durch einen anderen Tod ersetzt oder aufgeschoben).
static func intercept(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName, source_id: int, trigger_effects: bool, pierce: bool, chain: Array[int], shadow: bool) -> bool:
	var s := ctx.state
	if not s.death_cards or source_kind == KillEvent.SOURCE_GM:
		return false
	var variant := CardCatalog.owner_variant(target)
	var ability := is_ability_kill(cause)
	var pack := is_pack_kill(cause, source_kind)
	var night := night_time(s)
	# 1. Verhinderungen
	if variant == CardCatalog.WOLF and ability:
		for e: Dictionary in CardEffects.effects(s, "negate_ability_w"):  # segen_07: die nächste Sonderfähigkeit, die einen Wolf töten würde, wird negiert
			return _prevent(ctx, target, cause, source_kind, e, "segen_07")
		if night:
			for e: Dictionary in CardEffects.active(s, "wolf_ability_immunity"):  # wende_06: diese Nacht kann keine Fähigkeit einen Wolf töten
				return _prevent(ctx, target, cause, source_kind, e, "wende_06", false)
			for e: Dictionary in CardEffects.active(s, "first_fail_w"):  # segen_13: die erste schädliche Fähigkeit auf einen Wolf missglückt
				return _prevent(ctx, target, cause, source_kind, e, "segen_13")
	# 2. Umleitungen und Ersatz
	if pack and variant == CardCatalog.DORF:
		for e: Dictionary in CardEffects.effects(s, "heal_hand_d"):  # segen_01 (Dorf): Angriff verhindert, persönlicher Schild
			if not (s.cardsys["shields"] as Array).has(target.id):
				(s.cardsys["shields"] as Array).append(target.id)
				(s.cardsys["shields"] as Array).sort()
			return _prevent(ctx, target, cause, source_kind, e, "segen_01")
		for e: Dictionary in CardEffects.active(s, "pack_catch_swap"):  # segen_11 (Dorf): stattdessen stirbt ein Wolf
			var wolf := CardEffects.random_of(s, CardEffects.living_of_variant(s, CardCatalog.WOLF))
			if wolf != -1:
				CardEffects.remove_effect(s, int(e["id"]))
				ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target.id, "cause": cause, "source_kind": source_kind, "protection": &"card_segen_11",
					"sources": [&"card_segen_11"], "redirected_to": wolf, "night": s.night_number})
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, wolf, KillEvent.CAUSE_CARD_SUBSTITUTE, KillEvent.SOURCE_PLAYER, int(e["owner"]))
				ctx.card_depth -= 1
				return true
	if variant == CardCatalog.WOLF and ctx.card_depth == 0 and not KillEvent.CARD_CAUSES.has(cause):
		for e: Dictionary in CardEffects.effects(s, "heal_swap_w"):  # segen_01 (Wolf): stattdessen stirbt eine zufällige Dorfperson
			var villager := CardEffects.random_of(s, CardEffects.living_of_variant(s, CardCatalog.DORF))
			if villager != -1:
				CardEffects.remove_effect(s, int(e["id"]))
				ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target.id, "cause": cause, "source_kind": source_kind, "protection": &"card_segen_01",
					"sources": [&"card_segen_01"], "redirected_to": villager, "night": s.night_number})
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, villager, KillEvent.CAUSE_CARD_SUBSTITUTE, KillEvent.SOURCE_PLAYER, int(e["owner"]))
				ctx.card_depth -= 1
				return true
	# 3. Aufschieben (Notanker): der nächste Tod in den eigenen Reihen, Todesfolgen von Wolfskind und Lehrling schon jetzt
	if trigger_effects and (variant == CardCatalog.WOLF or variant == CardCatalog.DORF) and not _is_deferred(s, target.id):
		for e: Dictionary in CardEffects.effects(s, "defer_death"):
			if String(e["data"]["faction"]) == String(variant):
				_defer(ctx, target, cause, source_kind, source_id, e)
				return true
	return false


static func _prevent(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName, e: Dictionary, card: String, consume: bool = true) -> bool:
	if consume:
		CardEffects.remove_effect(ctx.state, int(e["id"]))
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target.id, "cause": cause, "source_kind": source_kind, "protection": StringName("card_%s" % card),
		"sources": [StringName("card_%s" % card)], "night": ctx.state.night_number})
	return true


# --- Notanker: aufgeschobener Tod -----------------------------------------------------------------------------------

static func _is_deferred(s: GameState, person_id: int) -> bool:
	return deferred_ids(s).has(person_id)


## Personen mit aufgeschobenem Tod: handeln bis zum Tod normal, zählen für Siegbedingungen aber bereits als tot.
static func deferred_ids(s: GameState) -> Array[int]:
	var out: Array[int] = []
	if not s.death_cards:
		return out
	for e: Dictionary in CardEffects.effects(s, "deferred_death"):
		out.append(int(e["data"]["person_id"]))
	return out


static func _defer(ctx: RuleContext, target: Player, cause: StringName, source_kind: StringName, source_id: int, notanker: Dictionary) -> void:
	var s := ctx.state
	CardEffects.remove_effect(s, int(notanker["id"]))
	# Der Tod wird am übernächsten Tag vollstreckt: am Tag des Spielens gezählt ab dem folgenden Tag.
	var due_day := s.day_number + 2 if s.phase == Phase.DAY else s.night_number + 1
	var rec := {"card": "wende_05", "variant": String(notanker["variant"]), "owner": int(notanker["owner"])}
	CardEffects.add_effect(ctx, rec, "deferred_death", CardEffects.now_key(s), CardEffects.FOREVER,
		{"person_id": target.id, "due_day": due_day, "cause": String(cause), "source_kind": String(source_kind), "source_id": source_id})
	ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": "wende_05", "deferred_id": target.id, "due_day": due_day, "cause": String(cause)})
	# Wolfskind-Verwandlung und Lehrling-Erbe geschehen schon beim Aufschub, vor der Siegprüfung (achte und neunte Antwortrunde).
	var record := KillEvent.new()
	record.target_id = target.id
	record.cause = cause
	record.source_kind = source_kind
	record.source_id = source_id
	record.phase = s.phase
	record.phase_number = s.night_number if night_time(s) else s.day_number
	record.order_index = s.next_death_order
	WolfChildRules.on_death(ctx, record)
	ApprenticeRules.on_master_death(ctx, record)
	s.win_check_pending = true


## Tagesbeginn: fällige aufgeschobene Tode werden vollstreckt.
static func execute_due_deferrals(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.effects(s, "deferred_death"):
		if int(e["data"]["due_day"]) > s.day_number:
			continue
		CardEffects.remove_effect(s, int(e["id"]))
		var id := int(e["data"]["person_id"])
		if s.players[id].alive:
			KillPipeline.request_kill(ctx, id, StringName(e["data"]["cause"]), StringName(e["data"]["source_kind"]), int(e["data"]["source_id"]), false)


# --- Folgen eines Todes ---------------------------------------------------------------------------------------------

## Karteneffekte, die auf einen eingetretenen Tod reagieren: Doppeltes Leid, Kettenfluch, Kosmisches Gleichgewicht.
static func after_death(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	var s := ctx.state
	if not s.death_cards or record.source_kind == KillEvent.SOURCE_GM:
		return
	CardFxSolo.after_death(ctx, target, record)
	var variant := CardCatalog.owner_variant(target)
	var by_card := KillEvent.CARD_CAUSES.has(record.cause) or ctx.card_depth > 0
	# fluch_12: stirbt als Nächstes ein Mitglied der Fraktion, stirbt ein weiteres zufälliges mit (ein Schild verhindert, kein Ersatz)
	for e: Dictionary in CardEffects.effects(s, "double_leid"):
		if String(e["data"]["faction"]) == String(variant) and variant != CardCatalog.SOLO:
			CardEffects.remove_effect(s, int(e["id"]))
			var others := CardEffects.living_of_variant(s, variant)
			var victim := CardEffects.random_of(s, others)
			if victim != -1:
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, victim, KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(e["owner"]))
				ctx.card_depth -= 1
			break
	if by_card:
		return
	# fluch_08: heute Nacht stirbt ein Wolf durch eine Sonderfähigkeit bzw. ein Dorfmitglied durch die Wölfe: der Nachbar stirbt mit
	for e: Dictionary in CardEffects.active(s, "chain_curse"):
		var wolf_case := String(e["data"]["faction"]) == "wolf" and variant == CardCatalog.WOLF and is_ability_kill(record.cause)
		var village_case := String(e["data"]["faction"]) == "dorf" and variant == CardCatalog.DORF and is_pack_kill(record.cause, record.source_kind)
		if wolf_case or village_case:
			var step := int(e["data"]["direction"])
			var neighbour := next_living_of(s, target.id, step, variant)
			if neighbour != -1:
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, neighbour, KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(e["owner"]))
				ctx.card_depth -= 1
	# loki_12: jeder passende Tod während der Wirkungsdauer löst einen zusätzlichen Tod der anderen Fraktion aus (Wahl der Spielleitung)
	if variant == CardCatalog.WOLF or variant == CardCatalog.DORF:
		for e: Dictionary in CardEffects.active(s, "cosmic_balance"):
			if _is_cosmic_consequence(s, record, int(e["owner"])):
				continue
			var other := CardCatalog.DORF if variant == CardCatalog.WOLF else CardCatalog.WOLF
			CardEffects.add_task(s, "cosmic_victim", {"owner": int(e["owner"]), "card": "loki_12"}, {"faction": String(other)})


## Folgt der Tod aus dem zusätzlichen Opfer dieses Kosmischen Gleichgewichts (etwa dem Schuss eines Sensenträgers, der als dieses Opfer
## starb)? Das Opfer ist erkennbar an Ursache Kartenkette mit der Besitzerin als Quelle; spätere Reaktionen laufen ohne Kartentiefe
## und hängen über die Quelle an diesem Tod, auch über mehrere Glieder.
static func _is_cosmic_consequence(s: GameState, record: KillEvent, owner_id: int) -> bool:
	var source_id := record.source_id
	var hops := 0
	while record.source_kind == KillEvent.SOURCE_PLAYER and hops <= s.players.size():
		hops += 1
		var source: Player = s.players.get(source_id)
		if source == null or source.death == null:
			return false
		record = source.death
		if record.cause == KillEvent.CAUSE_CARD_CHAIN and record.source_id == owner_id:
			return true
		source_id = record.source_id
	return false


# --- Nacht: Rudel, Reihenfolge, Ausfall -----------------------------------------------------------------------------

const LAST_PACK_PRIORITY := 29


## Karteneffekte der laufenden Nacht auf das Rudel.
static func pack_rules(s: GameState) -> Dictionary:
	var r := {"sleep": false, "sleep_wide": false, "bonus": 0, "must_wolf": false, "first": false, "last": false, "blind": false}
	if not s.death_cards:
		return r
	r["sleep"] = not CardEffects.active(s, "pack_sleep").is_empty()
	r["sleep_wide"] = not CardEffects.active(s, "pack_sleep_wide").is_empty()
	r["blind"] = not CardEffects.active(s, "pack_blind").is_empty()
	r["must_wolf"] = not CardEffects.active(s, "pack_must_wolf").is_empty()
	r["first"] = not CardEffects.active(s, "pack_first").is_empty()
	r["last"] = not CardEffects.active(s, "pack_last").is_empty()
	for e: Dictionary in CardEffects.active(s, "pack_bonus"):
		r["bonus"] = int(r["bonus"]) + int(e["data"].get("bonus", 1))
	return r


## Das gemeinsame Rudelopfer entfällt in dieser Nacht (kein Rudelschritt).
static func pack_suppressed(s: GameState) -> bool:
	var r := pack_rules(s)
	return bool(r["sleep"]) or bool(r["sleep_wide"]) or bool(r["blind"])


static func pack_sleep_wide(s: GameState) -> bool:
	return bool(pack_rules(s)["sleep_wide"])


## Platz des Rudelschritts im Nachtplan: [Priorität, Reihenfolge]. „Als erstes“ nach dem Zeitwächter, „als letztes“ hinter den
## Wolfsfähigkeiten (Aufrufreihenfolge, KS-35); Schritte, die das Rudelopfer brauchen, rücken dahinter (guard_priority).
static func pack_slot(s: GameState) -> Array:
	var r := pack_rules(s)
	if bool(r["first"]):
		return [0, 1 << 20]
	if bool(r["last"]):
		return [LAST_PACK_PRIORITY, 0]
	return [RoleCatalog.PACK_PRIORITY, 0]


## Priorität eines Schritts, der das Rudelopfer braucht (Verdammniswächter), wenn das Rudel als letztes ruft.
static func guard_priority(s: GameState, priority: int) -> int:
	return maxi(priority, LAST_PACK_PRIORITY + 1) if s.death_cards and bool(pack_rules(s)["last"]) else priority


## Rudel-Prompt der Nacht: zusätzliche Ziele (Stille Nacht, Wendepunkt) und Zwang zu einer eigenen Wolfsperson (Verrat).
static func shape_pack_prompt(s: GameState, prompt: PendingPrompt) -> void:
	if not s.death_cards:
		return
	var r := pack_rules(s)
	prompt.max_count = 1 + int(r["bonus"])
	if bool(r["must_wolf"]):
		var wolves := CardEffects.living_of_variant(s, CardCatalog.WOLF)
		if not wolves.is_empty():
			prompt.allowed_ids = wolves
			prompt.min_count = 1
	prompt.max_count = mini(prompt.max_count, prompt.allowed_ids.size())
	prompt.min_count = mini(prompt.min_count, prompt.max_count)


## Rudel hat gewählt: erstes Ziel ist das Rudelopfer, weitere sind zusätzliche Opfer ohne Durchdringung.
static func record_pack_targets(s: GameState, targets: Array[int]) -> void:
	if not s.death_cards:
		return
	s.cardsys["pack_extra"] = targets.slice(1) if targets.size() > 1 else []


## Morgen: zusätzliche Rudelopfer der Karten (jedes Opfer einzeln gegen Schutzwirkungen).
static func resolve_extra_victims(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.death_cards:
		return
	var extras: Array = (s.cardsys["pack_extra"] as Array).duplicate()
	s.cardsys["pack_extra"] = []
	for id: Variant in extras:
		KillPipeline.request_kill(ctx, int(id), KillEvent.CAUSE_NIGHT_KILL, KillEvent.SOURCE_PACK, -1, true, false)


## Die laufende Nacht fällt aus (Zeitsprung, Zeitwarp).
static func night_skipped(s: GameState) -> bool:
	return s.death_cards and (s.phase == Phase.NIGHT or s.phase == Phase.DAWN_RESOLUTION) and not CardEffects.active(s, "night_skip").is_empty()


# --- Nachtfähigkeiten: Sperren und Orakel ---------------------------------------------------------------------------

## Der Nachtschritt `index` ist durch eine Karte blockiert: „verliert diese Nacht seine Sonderfähigkeit“ (Blinder Fleck,
## Schicksalsumkehr) oder die erste gewählte Fähigkeit des führenden Teams (Gleichgewicht).
static func step_blocked(s: GameState, index: int) -> bool:
	if not s.death_cards:
		return false
	var actor := StepQueue.step_actor(s.night_plan[index])
	if actor == -1:
		return false
	for e: Dictionary in CardEffects.active(s, "lose_ability"):
		if int(e["data"]["person_id"]) == actor:
			return true
	for e: Dictionary in CardEffects.active(s, "block_first"):
		return first_block_index(s, String(e["data"]["faction"])) == index
	return false


## Index des ersten Nachtschritts einer Person der führenden Fraktion, der sonst ausgeführt würde (Gleichgewicht).
static func first_block_index(s: GameState, leader: String) -> int:
	var faction := Faction.VILLAGE if leader == "village" else Faction.WOLVES
	for j: int in s.night_plan.size():
		var actor := StepQueue.step_actor(s.night_plan[j])
		if actor == -1:
			continue
		# Ein bereits ausgeführter oder durch die Karte gestrichener erster Schritt bleibt der blockierte; der nächste rückt nicht nach.
		if s.players[actor].faction == faction and StepQueue.core_drop_reason(s, j) == &"":
			return j
	return -1


## Orakel sieht eine Person, die als Wolf gilt: Schattenmantel (Wolf) und die erste missglückende Fähigkeit (Schattenvorteil, Wolf)
## zeigen stattdessen eine zufällige lebende Dorfrolle. Gibt die gezeigte Rolle oder &"" zurück (nichts geändert).
static func oracle_cloak(ctx: RuleContext, target: Player) -> StringName:
	var s := ctx.state
	if not s.death_cards or not target.counts_as_wolf:
		return &""
	var effect: Dictionary = {}
	for e: Dictionary in CardEffects.effects(s, "oracle_cloak"):
		effect = e
		break
	if effect.is_empty():
		for e: Dictionary in CardEffects.active(s, "first_fail_w"):
			effect = e
			break
	if effect.is_empty():
		return &""
	CardEffects.remove_effect(s, int(effect["id"]))
	var roles: Array = []
	for id: int in CardEffects.living_of_variant(s, CardCatalog.DORF):
		if not roles.has(s.players[id].role_id):
			roles.append(s.players[id].role_id)
	if roles.is_empty():
		roles = [RoleCatalog.DORFBEWOHNER]
	roles.sort()
	return StringName(roles[s.rng.next_int(0, roles.size() - 1)])


## Falsche Fährte (Dorf): Die Rollenauskunft dieser Orakel-Person muss in dieser Nacht verfälscht werden.
static func false_info_pending(s: GameState, oracle_id: int) -> bool:
	if not s.death_cards:
		return false
	for e: Dictionary in CardEffects.active(s, "false_info"):
		if int(e["data"]["person_id"]) == oracle_id:
			return true
	return false


static func consume_false_info(s: GameState, oracle_id: int) -> void:
	for e: Dictionary in CardEffects.active(s, "false_info"):
		if int(e["data"]["person_id"]) == oracle_id:
			CardEffects.remove_effect(s, int(e["id"]))
			return
