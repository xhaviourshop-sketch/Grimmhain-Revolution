class_name CardFxVote
extends RefCounted
## Kartenfamilie „Abstimmung und Lynch“ (Arbeitsliste Gruppe 5; Decision Log neunte bis zwölfte Antwortrunde). Stimmen werden
## weiterhin am Tisch gezählt. Die Karte legt einen Effekt für die Hinrichtung des Tages `lynch_day` an (CardLynch, CardHooks):
##   Hinrichtung selbst:  segen_03 D Wachsame Augen, segen_09 Gerechter Zorn, fluch_04 D Verrat, fluch_10 D Schlechtes Omen,
##                        wende_03 D Wendepunkt, wende_11 D Schicksalswende, schicksal_03 Amnestie, schicksal_09 Stimmentausch,
##                        schicksal_11 Kettenreaktion, schicksal_14 Richterstuhl, loki_01 Spiegelwelt, loki_02 Stille Abstimmung,
##                        loki_13 Verhexte Lynch (die Spielleitung trägt das Tischergebnis ein, der Kern setzt die Folgen um)
##   Stimmenmodifikatoren (Anzeige am Tisch): segen_05 Wahre Stimme, fluch_03 Lähmung, fluch_09 Verlorene Stimme, fluch_13 Lähmungswelle,
##                        wende_09 Rückenwind
##   Sofortwirkung:       schicksal_05 Spiegel: wer keine Stimme erhält, stirbt sofort (die Spielleitung trägt diese Personen ein).
## Der Tag der Wirkung: im ersten Fenster die Hinrichtung desselben Tages, im zweiten die des Folgetages (siebte Antwortrunde, KS-56);
## „heute“-Karten sind nur im ersten Fenster spielbar.

const TASK_SHORT_VOTE := "short_vote_check"
const TASKS: Array[String] = [TASK_SHORT_VOTE]


static func playable(s: GameState, rec: Dictionary, window: StringName) -> bool:
	var variant := StringName(rec["variant"])
	match StringName(rec["card"]):
		&"schicksal_03":
			return s.day_step != Phase.DAY_EXECUTION_DECIDED
		&"schicksal_05":
			return s.alive_ids().size() >= 2
		&"schicksal_14":
			return not s.alive_ids().is_empty()
		&"segen_05", &"fluch_03":
			return not _members(s, variant).is_empty()
		&"wende_11":
			return not CardEffects.living_of_variant(s, CardCatalog.WOLF).is_empty()
		&"fluch_04", &"fluch_10", &"wende_03":
			return s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED
	return true


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	var variant := StringName(rec["variant"])
	match StringName(rec["card"]):
		&"schicksal_05":
			if not got.has("targets"):
				return {"stage": "pick", "key": "targets", "allowed": s.alive_ids(), "min": 0, "max": s.alive_ids().size()}
		&"schicksal_14":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": s.alive_ids(), "min": 1, "max": 1}
		&"segen_05":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _members(s, variant), "min": 1, "max": 1}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	var f := String(rec["variant"])
	var day := CardEffects.lynch_day(s, window)
	var today := s.day_number
	var now := CardEffects.now_key(s)
	var to_key := CardEffects.day_key(day)
	match StringName(rec["card"]):
		&"schicksal_03":
			CardEffects.add_effect(ctx, rec, "lynch_cancel", now, CardEffects.day_key(today), {"day": today})
			CardEffects.announce(ctx, rec)
		&"schicksal_05":
			var none: Array = got["targets"]
			CardEffects.announce(ctx, rec, {"victim_ids": none.duplicate()})
			ctx.card_depth += 1
			for id: Variant in none:
				KillPipeline.request_kill(ctx, int(id), KillEvent.CAUSE_CARD_EFFECT, KillEvent.SOURCE_PLAYER, int(rec["owner"]))
			ctx.card_depth -= 1
		&"schicksal_09":
			CardEffects.add_effect(ctx, rec, "lynch_shift_left", now, to_key, {"day": day})
			CardEffects.announce(ctx, rec, {"day": day})
		&"loki_01":
			CardEffects.add_effect(ctx, rec, "lynch_shift_left", now, CardEffects.day_key(today), {"day": today})
			CardEffects.add_effect(ctx, rec, "secret_result", now, CardEffects.day_key(today), {"day": today})
			CardEffects.announce(ctx, rec)
		&"schicksal_11":
			CardEffects.add_effect(ctx, rec, "lynch_runner_up", now, to_key, {"day": day})
			CardEffects.announce(ctx, rec, {"day": day})
		&"schicksal_14":
			var judge := int(got["target_id"])
			CardEffects.add_effect(ctx, rec, "temp_judge", now, CardEffects.day_key(today), {"day": today, "judge_id": judge})
			CardEffects.announce(ctx, rec, {"judge_id": judge})
		&"loki_02":
			CardEffects.add_effect(ctx, rec, "short_vote", now, CardEffects.day_key(today), {"day": today})
			CardEffects.announce(ctx, rec)
		&"loki_13":
			CardEffects.add_effect(ctx, rec, "lynch_fewest", now, CardEffects.day_key(today), {"day": today})
			CardEffects.announce(ctx, rec)
		&"segen_03":
			CardEffects.add_effect(ctx, rec, "lynch_reveal", now, to_key, {"day": day, "revealed_for": -1})
		&"segen_05":
			var person := int(got["target_id"])
			CardEffects.add_effect(ctx, rec, "vote_double_one", now, CardEffects.day_key(today), {"day": today, "person_id": person})
			CardEffects.announce(ctx, rec, {"person_id": person})
		&"segen_09":
			CardEffects.add_effect(ctx, rec, "lynch_wolf_bonus" if f == "wolf" else "lynch_save_village", now, to_key, {"day": day})
		&"fluch_03":
			var chosen := CardEffects.random_of(s, _members(s, StringName(f)))
			CardEffects.add_effect(ctx, rec, "vote_forbid", now, to_key, {"day": day, "ids": [chosen]})
			CardEffects.announce(ctx, rec, {"person_ids": [chosen], "day": day})
		&"fluch_13":
			CardEffects.add_effect(ctx, rec, "vote_forbid_faction", now, to_key, {"day": day, "faction": f, "active_only": f == "dorf"})
			CardEffects.announce(ctx, rec, {"day": day})
		&"fluch_09":
			CardEffects.add_effect(ctx, rec, "vote_zero_faction", now, to_key, {"day": day, "faction": f})
			CardEffects.add_effect(ctx, rec, "secret_result", now, to_key, {"day": day})
			CardEffects.announce(ctx, rec, {"day": day})
		&"wende_09":
			CardEffects.add_effect(ctx, rec, "vote_double_faction", now, to_key, {"day": day, "faction": f})
			CardEffects.add_effect(ctx, rec, "secret_result", now, to_key, {"day": day})
			CardEffects.announce(ctx, rec, {"day": day})
		&"fluch_04":
			CardEffects.add_effect(ctx, rec, "lynch_until_village", now, CardEffects.day_key(today), {"day": today})
			CardEffects.announce(ctx, rec)
		&"fluch_10":
			CardEffects.add_effect(ctx, rec, "bad_omen_day", now, CardEffects.day_key(today), {"day": today, "wolf_executed": false})
		&"wende_03":
			CardEffects.add_effect(ctx, rec, "lynch_save_village", now, CardEffects.day_key(today), {"day": today})
			CardEffects.announce(ctx, rec)
		&"wende_11":
			CardEffects.add_effect(ctx, rec, "lynch_redirect_wolf", now, to_key, {"day": day})


static func _members(s: GameState, variant: StringName) -> Array[int]:
	return CardEffects.living_of_variant(s, CardCatalog.WOLF if variant == CardCatalog.WOLF else CardCatalog.DORF)


# --- Aufgabe: Stille Abstimmung ---------------------------------------------------------------------------------

static func task_stage(_s: GameState, task: Dictionary, got: Dictionary) -> Dictionary:
	if String(task["kind"]) == TASK_SHORT_VOTE and not got.has("in_time"):
		return {"stage": "ask", "key": "in_time"}
	return {}


## Stille Abstimmung (loki_02): weniger als drei Nominierungen heute: 1 bis 5 zufällige Personen sterben; sonst, wenn die Frist von
## 60 Sekunden verstrichen ist, alle Nominierten.
static func task_apply(ctx: RuleContext, task: Dictionary, got: Dictionary) -> void:
	var s := ctx.state
	var nominated: Array[int] = []
	for n: Nomination in s.nominations_on_day(s.day_number):
		if s.players[n.nominee_id].alive and not nominated.has(n.nominee_id):
			nominated.append(n.nominee_id)
	var victims: Array = []
	if s.nominations_on_day(s.day_number).size() < 3:
		var count := s.rng.next_int(1, 5)
		victims = s.rng.shuffled(s.alive_ids()).slice(0, mini(count, s.alive_ids().size()))
	elif not bool(got.get("in_time", true)):
		victims = nominated
	victims.sort()
	ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": "loki_02", "victim_ids": victims.duplicate(), "nominations": s.nominations_on_day(s.day_number).size()})
	ctx.card_depth += 1
	for id: Variant in victims:
		KillPipeline.request_kill(ctx, int(id), KillEvent.CAUSE_CARD_EFFECT, KillEvent.SOURCE_PLAYER, int(task["owner"]))
	ctx.card_depth -= 1
