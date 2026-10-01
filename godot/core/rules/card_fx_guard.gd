class_name CardFxGuard
extends RefCounted
## Kartenfamilie „Schutz, Umleitung und Todesketten“ (Arbeitsliste Gruppe 2; Decision Log fünfte bis zwölfte Antwortrunde).
## Die Karte legt einen Effekt an; die Wirkung entsteht in `CardHooks` (Abfangen vor dem Tod, Folgen nach dem Tod) und in
## der Hinrichtungsauflösung (`CardLynch`):
##   segen_01 Heilende Hand   Wolf: der nächste Tod eines Wolfs trifft stattdessen eine zufällige Dorfperson.
##                            Dorf: der nächste Rudelangriff auf eine Dorfperson scheitert, sie erhält einen persönlichen Schild.
##   segen_07 Blutpakt        Wolf: die nächste Sonderfähigkeit, die einen Wolf töten würde, wird negiert.
##                            Dorf: nach dem nächsten nächtlichen Opfer deckt die Spielleitung null bis zwei Wölfe öffentlich auf.
##   segen_11 Spiegelschutz   Wolf: wird am Tag der nächsten Hinrichtung ein Wolf gelyncht, stirbt die nominierende Person.
##                            Dorf: erwischt das Rudel in der Folgenacht eine Dorfperson, stirbt stattdessen ein Wolf (Generator).
##   wende_02 Verzweiflungsschrei  die Kartenspielerin wählt in der nächsten Nacht geheim das Ziel: Dorf Schutz gegen Rudelangriffe
##                            (diese und die nächsten zwei Nächte), Wolf Schutz vor der Hinrichtung (die nächsten zwei Tage).
##   wende_05 Notanker        der nächste Tod in den eigenen Reihen wird auf den übernächsten Tag verschoben (zählt für Siege als tot).
##   fluch_05 Gebrochener Schild  Schutzwirkungen der Fraktion ruhen 1 bis 3 Tage (Tag des Spielens ist Tag 1); Dauer wählt die Spielleitung.
##   fluch_08 Kettenfluch     heute Nacht: stirbt ein Wolf durch eine Sonderfähigkeit (Wolf) bzw. eine Dorfperson durch die Wölfe (Dorf),
##                            stirbt die nächste lebende Person der Fraktion rechts (Wolf) bzw. links (Dorf) mit.
##   fluch_12 Doppeltes Leid  der nächste Tod in der Fraktion reißt ein weiteres zufälliges Mitglied mit (ein Schild verhindert, kein Ersatz).
##   loki_12 Kosmisches Gleichgewicht  bis Ende der kommenden Nacht löst jeder Wolfs- bzw. Dorf-Tod einen zusätzlichen Tod der anderen
##                            Fraktion aus (Spielleitung wählt, Kartentode lösen nicht erneut aus).

const TASK_PROTECT_PICK := "protect_pick"
const TASK_BLOOD_PACT := "blood_pact_reveal"
const TASK_COSMIC := "cosmic_victim"
const TASKS: Array[String] = [TASK_PROTECT_PICK, TASK_BLOOD_PACT, TASK_COSMIC]


static func _faction(rec: Dictionary) -> String:
	return String(rec["variant"])


static func playable(s: GameState, rec: Dictionary, _window: StringName) -> bool:
	match StringName(rec["card"]):
		&"segen_11":
			return true
		&"wende_02":
			return not _pick_pool(s, StringName(rec["variant"])).is_empty()
		&"fluch_08", &"fluch_12", &"wende_05":
			return true
	return true


static func next_stage(_s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	if StringName(rec["card"]) == &"fluch_05" and not got.has("days"):
		return {"stage": "option", "key": "days", "options": ["1", "2", "3"], "option_kind": "days"}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	var now := CardEffects.now_key(s)
	var tomorrow_night := CardEffects.next_night(s)
	var f := _faction(rec)
	match StringName(rec["card"]):
		&"segen_01":
			CardEffects.add_effect(ctx, rec, "heal_swap_w" if f == "wolf" else "heal_hand_d", now, CardEffects.FOREVER)
		&"segen_07":
			CardEffects.add_effect(ctx, rec, "negate_ability_w" if f == "wolf" else "blood_pact_d", now, CardEffects.FOREVER)
		&"segen_11":
			if f == "wolf":
				var day := CardEffects.lynch_day(s, window)
				CardEffects.add_effect(ctx, rec, "lynch_swap_nominator", now, CardEffects.day_key(day), {"day": day})
			else:
				CardEffects.add_effect(ctx, rec, "pack_catch_swap", now, CardEffects.night_key(tomorrow_night), {"night": tomorrow_night})
		&"wende_02":
			CardEffects.add_effect(ctx, rec, "protect_pick_pending", now, CardEffects.night_key(tomorrow_night), {"night": tomorrow_night, "faction": f})
		&"wende_05":
			CardEffects.add_effect(ctx, rec, "defer_death", now, CardEffects.FOREVER, {"faction": f})
		&"fluch_05":
			var days := int(String(got["days"]))
			CardEffects.add_effect(ctx, rec, "protection_pause", CardEffects.day_key(s.day_number), CardEffects.day_key(s.day_number + days - 1), {"faction": f, "days": days})
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "faction": f, "days": days})
		&"fluch_08":
			CardEffects.add_effect(ctx, rec, "chain_curse", CardEffects.night_key(tomorrow_night), CardEffects.night_key(tomorrow_night),
				{"faction": f, "direction": -1 if f == "wolf" else 1, "night": tomorrow_night})
		&"fluch_12":
			CardEffects.add_effect(ctx, rec, "double_leid", now, CardEffects.FOREVER, {"faction": f})
		&"loki_12":
			CardEffects.add_effect(ctx, rec, "cosmic_balance", now, CardEffects.night_key(tomorrow_night), {"night": tomorrow_night})


# --- Aufgaben ---------------------------------------------------------------------------------------------------

static func _pick_pool(s: GameState, variant: StringName) -> Array[int]:
	return CardEffects.living_of_variant(s, CardCatalog.WOLF if variant == CardCatalog.WOLF else CardCatalog.DORF)


static func task_stage(s: GameState, task: Dictionary, got: Dictionary) -> Dictionary:
	if got.has("target_id") or got.has("targets"):
		return {}
	match String(task["kind"]):
		TASK_PROTECT_PICK:
			var pool := _pick_pool(s, StringName(task["data"]["faction"]))
			if pool.is_empty():
				return {}
			return {"stage": "pick", "key": "target_id", "allowed": pool, "min": 1, "max": 1}
		TASK_BLOOD_PACT:
			var wolves := CardEffects.living_of_variant(s, CardCatalog.WOLF)
			if wolves.is_empty():
				return {}
			return {"stage": "pick", "key": "targets", "allowed": wolves, "min": 0, "max": mini(2, wolves.size())}
		TASK_COSMIC:
			var pool2 := CardEffects.living_of_variant(s, StringName(task["data"]["faction"]))
			if pool2.is_empty():
				return {}
			return {"stage": "pick", "key": "target_id", "allowed": pool2, "min": 1, "max": 1}
	return {}


static func task_apply(ctx: RuleContext, task: Dictionary, got: Dictionary) -> void:
	var s := ctx.state
	var rec := {"card": task["card"], "variant": String(task["data"].get("faction", "")), "owner": int(task["owner"])}
	match String(task["kind"]):
		TASK_PROTECT_PICK:
			if not got.has("target_id"):
				return
			var target := int(got["target_id"])
			var f := String(task["data"]["faction"])
			rec["variant"] = f
			if f == "dorf":
				# Schutz diese und die nächsten zwei Nächte gegen Rudelangriffe
				CardEffects.add_effect(ctx, rec, "pack_protect", CardEffects.night_key(s.night_number), CardEffects.night_key(s.night_number + 2), {"person_id": target})
			else:
				# Schutz vor der Hinrichtung in den nächsten zwei Tagesphasen
				CardEffects.add_effect(ctx, rec, "lynch_immune", CardEffects.day_key(s.night_number), CardEffects.day_key(s.night_number + 1), {"person_id": target})
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": "wende_02", "protected_id": target, "faction": f})
		TASK_BLOOD_PACT:
			var ids: Array = got.get("targets", [])
			ctx.emit(GameEvent.CARD_ANNOUNCED, Visibility.PUBLIC, {"card_id": "segen_07", "variant": "dorf", "values": {"wolf_ids": ids.duplicate()}})
		TASK_COSMIC:
			if not got.has("target_id"):
				return
			ctx.card_depth += 1
			KillPipeline.request_kill(ctx, int(got["target_id"]), KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(task["owner"]))
			ctx.card_depth -= 1


## Nachtbeginn: Verzweiflungsschrei fragt die Kartenspielerin nach dem Ziel (geheim, Aufgabe der Spielleitung).
static func on_night_start(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.effects(s, "protect_pick_pending"):
		if int(e["data"]["night"]) == s.night_number:
			CardEffects.add_task(s, TASK_PROTECT_PICK, {"owner": int(e["owner"]), "card": e["card"]}, {"faction": String(e["data"]["faction"])})
			CardEffects.remove_effect(s, int(e["id"]))


## Ende der Morgenauflösung: Blutpakt (Dorf) deckt nach dem nächtlichen Opfer null bis zwei Wölfe auf.
static func on_dawn_end(ctx: RuleContext, had_victim: bool) -> void:
	var s := ctx.state
	if not had_victim:
		return
	for e: Dictionary in CardEffects.effects(s, "blood_pact_d"):
		CardEffects.remove_effect(s, int(e["id"]))
		CardEffects.add_task(s, TASK_BLOOD_PACT, {"owner": int(e["owner"]), "card": e["card"]})
		break
