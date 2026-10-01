class_name CardLynch
extends RefCounted
## Hinrichtung und Totenreichkarten: Haken in `RulesEngine` (DecideExecution) und `ExecutionRules`. Stimmen werden weiterhin am
## Tisch gezählt; der Kern nimmt nur die nötigen Ergebnisse entgegen (Person mit den wenigsten oder zweitmeisten Stimmen,
## Entscheid des Dorfes) und setzt die mechanischen Folgen um. Effekte gelten für den Tag `data.day`; Spielleiterkorrekturen
## (Quelle `gm`) umgehen alle Karteneffekte.
##   lynch_cancel          die Hinrichtung des Tages entfällt (Amnestie; Martyrium der Wölfe): nur „keine Hinrichtung“
##   lynch_immune          eine Person kann nicht hingerichtet werden (Verzweiflungsschrei, Wolf)
##   lynch_save_village    trifft die Hinrichtung eine Dorfperson, wird sie verhindert (Gerechter Zorn, Wendepunkt)
##   lynch_wolf_bonus      stirbt ein Wolf durch die Hinrichtung, darf das Rudel in der Folgenacht zwei Opfer reißen
##   lynch_swap_nominator  stirbt ein Wolf durch die Hinrichtung, stirbt stattdessen die nominierende Person
##   lynch_redirect_wolf   trifft die Hinrichtung eine Dorfperson, trifft sie stattdessen einen zufälligen Wolf
##   lynch_shift_left      die Stimmen zählen für die Person links neben der nominierten (Stimmentausch, Spiegelwelt)
##   lynch_fewest          die Person mit den wenigsten Stimmen stirbt, nicht die mit den meisten (Verhexte Lynch)
##   lynch_runner_up       stirbt jemand durch die Hinrichtung, stirbt auch die Person mit den zweitmeisten Stimmen
##   lynch_reveal          vor dem Vollzug wird die Rolle der Person öffentlich enthüllt, das Dorf entscheidet (Wachsame Augen)
##   lynch_until_village   so lange hinrichten, bis eine Dorfperson ausgewählt wurde (Verrat)
##   multi_lynch           n Hinrichtungen an diesem Tag (Chaosgeist)
##   temp_judge            eine Richterin verhängt das Urteil allein: jede lebende Person ist zulässig (Richterstuhl)
##   bad_omen_day          wurde heute kein Wolf hingerichtet, stirbt am Tagesende eine zufällige Dorfperson (Schlechtes Omen)

static func for_today(s: GameState, kind: String) -> Array:
	var out: Array = []
	if not s.death_cards or s.phase != Phase.DAY:
		return out
	for e: Dictionary in CardEffects.effects(s, kind):
		if int(e["data"].get("day", -1)) == s.day_number:
			out.append(e)
	return out


static func cancelled_today(s: GameState) -> bool:
	return not for_today(s, "lynch_cancel").is_empty()


## Jede lebende Person ist Hinrichtungsziel (Verhexte Lynch: Person mit den wenigsten Stimmen; Richterstuhl).
static func allows_unnominated(s: GameState) -> bool:
	return not for_today(s, "lynch_fewest").is_empty() or not for_today(s, "temp_judge").is_empty()


static func _needs_runner_up(s: GameState) -> bool:
	return not for_today(s, "lynch_runner_up").is_empty()


static func _reveal_effect(s: GameState) -> Dictionary:
	var list := for_today(s, "lynch_reveal")
	return list[0] if not list.is_empty() else {}


# --- Validierung ---------------------------------------------------------------------------------------------------

## Zusatzprüfungen der Hinrichtung (nach den Prüfungen des Kerns).
static func validate(s: GameState, p: Dictionary, target: int) -> StringName:
	if not s.death_cards:
		return &""
	if target != GameState.NO_TARGET and cancelled_today(s):
		return &"execution_cancelled_by_card"
	if target == GameState.NO_TARGET:
		return &""
	var reveal := _reveal_effect(s)
	if not reveal.is_empty():
		if p.has("card_reveal"):
			if not p["card_reveal"] is bool or int(reveal["data"].get("revealed_for", -1)) != -1:
				return &"invalid_card_reveal"
		elif int(reveal["data"].get("revealed_for", -1)) == -1:
			return &"card_reveal_required"
		else:
			if int(reveal["data"]["revealed_for"]) != target:
				return &"card_reveal_target_changed"
			if not p.get("village_confirms") is bool:
				return &"village_decision_required"
	elif p.has("card_reveal") or p.has("village_confirms"):
		return &"no_card_reveal"
	if _needs_runner_up(s) and not (p.has("card_reveal") and bool(p["card_reveal"])):
		var runner := DictRead.get_int(p, "runner_up_id", -2)
		if not p.has("runner_up_id") or (runner != GameState.NO_TARGET and (not s.players.has(runner) or not s.players[runner].alive or runner == target)):
			return &"runner_up_required"
	return &""


# --- Entscheidung -------------------------------------------------------------------------------------------------

## Karten, die die Entscheidung selbst übernehmen: Enthüllung vor dem Vollzug und Ablehnung durch das Dorf (Wachsame Augen).
## true: Der Befehl ist vollständig behandelt (keine Hinrichtung, Tag nicht entschieden).
static func handle_decision(ctx: RuleContext, p: Dictionary) -> bool:
	var s := ctx.state
	var target := int(p["target_id"])
	if not s.death_cards or target == GameState.NO_TARGET:
		return false
	var reveal := _reveal_effect(s)
	if reveal.is_empty():
		return false
	if p.has("card_reveal"):
		reveal["data"]["revealed_for"] = target
		ctx.emit(GameEvent.CARD_ROLE_REVEALED, Visibility.PUBLIC, {"person_id": target, "role_id": String(s.players[target].role_id), "card_id": "segen_03", "before_execution": true})
		return true
	CardEffects.remove_effect(s, int(reveal["id"]))  # Enthüllung und Ablehnung gibt es nur im ersten Wahlgang (zehnte Antwortrunde)
	if not bool(p["village_confirms"]):
		ctx.emit(GameEvent.CARD_ANNOUNCED, Visibility.PUBLIC, {"card_id": "segen_03", "variant": "dorf", "values": {"rejected_id": target}, "stage": "rejected"})
		return true
	return false


## Nach einer Entscheidung, die den Tag als entschieden markiert hat: Karten, die weitere Hinrichtungen verlangen, halten ihn offen.
static func after_decision(ctx: RuleContext, target: int, _payload: Dictionary) -> void:
	var s := ctx.state
	if not s.death_cards or target == GameState.NO_TARGET:
		return
	var open := false
	CardFxSolo.after_decision(s)
	var until := for_today(s, "lynch_until_village")
	if not until.is_empty():
		var chosen_is_village := CardCatalog.owner_variant(s.players[target]) == CardCatalog.DORF
		if chosen_is_village:
			CardEffects.remove_effect(s, int(until[0]["id"]))  # Auswahl einer Dorfperson genügt, auch wenn ein Schild den Tod verhindert
		elif _further_nominations_possible(s):
			open = true
	for e: Dictionary in for_today(s, "multi_lynch"):
		e["data"]["done"] = int(e["data"]["done"]) + 1
		if int(e["data"]["done"]) < int(e["data"]["n"]) and _further_nominations_possible(s):
			open = true
		else:
			CardEffects.remove_effect(s, int(e["id"]))
	if open and s.day_step == Phase.DAY_EXECUTION_DECIDED:
		s.day_step = Phase.DAY_NOMINATION


## Noch eine nominierte lebende Person, die heute nicht schon hingerichtet wurde (sonst endet der Tag mit „keine Hinrichtung“).
static func _further_nominations_possible(s: GameState) -> bool:
	for n: Nomination in s.nominations_on_day(s.day_number):
		if s.players[n.nominee_id].alive:
			return true
	return false


# --- Vorschau und Ausführung ---------------------------------------------------------------------------------------

## Person, deren Tod die Hinrichtung nach den Stimmenkarten meint (Stimmentausch, Spiegelwelt): die lebende Person links der genannten.
static func vote_target(s: GameState, target_id: int) -> int:
	if not s.death_cards or for_today(s, "lynch_shift_left").is_empty():
		return target_id
	var start := s.seat_order.find(target_id)
	var n := s.seat_order.size()
	for k: int in range(1, n):
		var id := s.seat_order[posmod(start + k, n)]
		if s.players[id].alive:
			return id
	return target_id


## Zusätzliche Eingriffe nach der Spiegelung: gibt {death_target_id, reason, random_wolf} zurück; `random_wolf` heißt, dass die
## Person erst bei der Ausführung gezogen wird (die Vorschau zeigt „zufälliger Wolf“).
static func redirect(s: GameState, nominee: int, death_target: int, mirrored: bool) -> Dictionary:
	var out := {"death_target_id": death_target, "reason": "", "random_wolf": false}
	if not s.death_cards or mirrored:
		return out
	var variant := CardCatalog.owner_variant(s.players[death_target])
	if variant == CardCatalog.WOLF and not for_today(s, "lynch_swap_nominator").is_empty():
		for n: Nomination in s.nominations_on_day(s.day_number):
			if n.nominee_id == nominee and not n.by_judge and s.players[n.nominator_id].alive:
				out["death_target_id"] = n.nominator_id
				out["reason"] = "swap_nominator"
				return out
	if variant == CardCatalog.DORF and not for_today(s, "lynch_redirect_wolf").is_empty() and not CardEffects.living_of_variant(s, CardCatalog.WOLF).is_empty():
		out["random_wolf"] = true
		out["reason"] = "redirect_wolf"
	return out


## Verhinderung der Hinrichtung durch eine Karte (kein Todesereignis, keine Ersatzperson, Tagesablauf bleibt).
## true: verhindert; dann ist der Effekt verbraucht und ein Ereignis protokolliert.
static func prevented(ctx: RuleContext, death_target: int) -> bool:
	var s := ctx.state
	if not s.death_cards:
		return false
	var protected := CardHooks.protections_paused(s, death_target)
	if not protected:
		for e: Dictionary in CardEffects.active(s, "lynch_immune"):
			if int(e["data"]["person_id"]) == death_target:
				ctx.emit(GameEvent.EXECUTION_PREVENTED_BY_CARD, Visibility.GM, {"target_id": death_target, "card_id": e["card"], "day": s.day_number})
				return true
	if CardCatalog.owner_variant(s.players[death_target]) == CardCatalog.DORF:
		var saved := for_today(s, "lynch_save_village")
		if not saved.is_empty():
			CardEffects.remove_effect(s, int(saved[0]["id"]))
			ctx.emit(GameEvent.EXECUTION_PREVENTED_BY_CARD, Visibility.GM, {"target_id": death_target, "card_id": saved[0]["card"], "day": s.day_number})
			return true
	return false


## Folgen einer Hinrichtung, die einen Tod verursacht hat (`record` ist nicht null): Gerechter Zorn (Wolf), Kettenreaktion,
## Schlechtes Omen (Verfolgung der Wolfshinrichtung).
static func after_execution(ctx: RuleContext, p: Dictionary, record: KillEvent) -> void:
	var s := ctx.state
	if not s.death_cards or record == null:
		return
	var died: Player = s.players[record.target_id]
	if CardCatalog.owner_variant(died) == CardCatalog.WOLF:
		for e: Dictionary in for_today(s, "lynch_wolf_bonus"):
			var rec := {"card": e["card"], "variant": e["variant"], "owner": int(e["owner"])}
			CardEffects.add_effect(ctx, rec, "pack_bonus", CardEffects.night_key(s.day_number + 1), CardEffects.night_key(s.day_number + 1), {"night": s.day_number + 1, "bonus": 1})
			CardEffects.remove_effect(s, int(e["id"]))
		for e: Dictionary in for_today(s, "bad_omen_day"):
			e["data"]["wolf_executed"] = true
	for e: Dictionary in for_today(s, "lynch_runner_up"):
		var runner := DictRead.get_int(p, "runner_up_id", GameState.NO_TARGET)
		CardEffects.remove_effect(s, int(e["id"]))
		if runner != GameState.NO_TARGET and s.players.has(runner) and s.players[runner].alive:
			ctx.card_depth += 1
			KillPipeline.request_kill(ctx, runner, KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(e["owner"]))
			ctx.card_depth -= 1
	CardFxSolo.after_execution(ctx, record)


## Tagesende: Schlechtes Omen (Dorf) und Stille Abstimmung prüfen ihre Bedingung.
static func on_day_end(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in for_today(s, "bad_omen_day"):
		CardEffects.remove_effect(s, int(e["id"]))
		if not bool(e["data"].get("wolf_executed", false)):
			var victim := CardEffects.random_of(s, CardEffects.living_of_variant(s, CardCatalog.DORF))
			if victim != -1:
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, victim, KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(e["owner"]))
				ctx.card_depth -= 1
	for e: Dictionary in for_today(s, "short_vote"):
		CardEffects.remove_effect(s, int(e["id"]))
		CardEffects.add_task(s, "short_vote_check", {"owner": int(e["owner"]), "card": e["card"]})
