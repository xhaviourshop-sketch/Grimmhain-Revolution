class_name CardFxNight
extends RefCounted
## Kartenfamilie „Nachtablauf und Wolfsangriff“ (Arbeitsliste Gruppe 3; Decision Log neunte bis zwölfte Antwortrunde,
## KS-106/107 des Umsetzungsauftrags). Die Karte legt einen Effekt für die kommende Nacht an; `CardHooks.pack_rules` und die
## Nachtschritt-Haken werten ihn aus:
##   segen_03 Wachsame Augen  Wolf: nach der Rudelwahl erfährt das Rudel die Rolle des Opfers und darf das Ziel wechseln.
##                            Dorf: (Hinrichtung, siehe CardFxVote)
##   segen_04 Stille Nacht    Wolf: das Rudel wählt zusätzlich ein zweites Ziel. Dorf: keine Wolfstötungen (Rudelangriff und
##                            zusätzliche aktive Wolfstötungen), andere Wolfsfähigkeiten bleiben.
##   segen_13 Schattenvorteil Wolf: die erste schädliche Fähigkeit auf einen Wolf missglückt (Tötung, Rollenprüfung des Orakels).
##                            Dorf: das Rudel wird zuerst geweckt, sein Opfer wird nach der Einigung öffentlich angesagt.
##   fluch_02 Falsche Fährte  Wolf: die Spielleitung lenkt den Rudelangriff auf ein Ziel ihrer Wahl um.
##                            Dorf: die Rollenauskunft des Orakels einer gewählten Dorfperson wird verfälscht.
##   fluch_04 Verrat (Wolf)   das Rudel muss eine eigene Wolfsperson wählen; sonst bleibt alles wie üblich.
##   fluch_07 Alptraum (Wolf) die gemeinsamen Rudelangriffe entfallen; eigene Tötungsfähigkeiten einzelner Wölfe bleiben.
##   fluch_10 Schlechtes Omen (Wolf)  erwischt das Rudel keine starke Rolle (Urteil der Spielleitung), entscheidet sie über einen Wolfstod.
##   wende_03 Wendepunkt (Wolf) das Rudel wählt in einem Schritt zwei verschiedene Personen.
##   wende_06 Trotz           Wolf: diese Nacht kann keine Rollenfähigkeit einen Wolf töten. Dorf: das Rudel kann kein Opfer wählen.
##   wende_12 Geheimrat (Wolf) das Rudel wird als letztes aufgerufen; stumme Hinweise der toten Person (Gesten, kein Sprechen).
##   schicksal_06 Zeitsprung, loki_03 Zeitwarp  die nächste Nacht fällt aus; Nachtnummer und Fristen laufen weiter, Aktionen und
##                            Ansagen entfallen, bereits fälliges Gift wirkt am Ende dieser Nacht (KS-106, KS-109).
## „Heute Nacht“ und „Folgenacht“ meinen immer die nächste Nacht nach dem Spielen (siebte Antwortrunde, KS-56).

const TASK_REVIEW := "pack_review"
const TASK_REDIRECT := "pack_redirect"
const TASK_OMEN := "bad_omen_pick"
const TASKS: Array[String] = [TASK_REVIEW, TASK_REDIRECT, TASK_OMEN]


static func playable(s: GameState, rec: Dictionary, _window: StringName) -> bool:
	match StringName(rec["card"]):
		&"fluch_04":
			return not CardEffects.living_of_variant(s, CardCatalog.WOLF).is_empty()
		&"fluch_02":
			if StringName(rec["variant"]) == CardCatalog.DORF:
				return not _oracles(s).is_empty()
	return true


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	if StringName(rec["card"]) == &"fluch_02" and StringName(rec["variant"]) == CardCatalog.DORF and not got.has("target_id"):
		return {"stage": "pick", "key": "target_id", "allowed": _oracles(s), "min": 1, "max": 1}
	if StringName(rec["card"]) == &"wende_12" and StringName(rec["variant"]) == CardCatalog.DORF and not got.has("done"):
		return {"stage": "confirm", "key": "done"}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	var n := CardEffects.next_night(s)
	var from_key := CardEffects.night_key(n)
	var f := String(rec["variant"])
	match StringName(rec["card"]):
		&"segen_03":
			CardEffects.add_effect(ctx, rec, "pack_review", from_key, from_key, {"night": n})
		&"segen_04":
			CardEffects.add_effect(ctx, rec, "pack_bonus" if f == "wolf" else "pack_sleep_wide", from_key, from_key, {"night": n, "bonus": 1})
		&"segen_13":
			CardEffects.add_effect(ctx, rec, "first_fail_w" if f == "wolf" else "pack_first", from_key, from_key, {"night": n})
			if f == "dorf":
				CardEffects.add_effect(ctx, rec, "pack_announce", from_key, from_key, {"night": n})
		&"fluch_02":
			if f == "wolf":
				CardEffects.add_effect(ctx, rec, "pack_redirect", from_key, from_key, {"night": n})
			else:
				CardEffects.add_effect(ctx, rec, "false_info", from_key, from_key, {"night": n, "person_id": int(got["target_id"])})
		&"fluch_04":
			CardEffects.add_effect(ctx, rec, "pack_must_wolf", from_key, from_key, {"night": n})
		&"fluch_07":
			CardEffects.add_effect(ctx, rec, "pack_sleep", from_key, from_key, {"night": n})
		&"fluch_10":
			CardEffects.add_effect(ctx, rec, "bad_omen_w", from_key, from_key, {"night": n})
		&"wende_03":
			CardEffects.add_effect(ctx, rec, "pack_bonus", from_key, from_key, {"night": n, "bonus": 1})
		&"wende_06":
			CardEffects.add_effect(ctx, rec, "wolf_ability_immunity" if f == "wolf" else "pack_sleep", from_key, from_key, {"night": n})
		&"wende_12":
			if f == "wolf":
				CardEffects.add_effect(ctx, rec, "pack_last", from_key, from_key, {"night": n})
			else:
				ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "question_answered": true})
		&"schicksal_06", &"loki_03":
			CardEffects.add_effect(ctx, rec, "night_skip", from_key, from_key, {"night": n})
			CardEffects.announce(ctx, rec, {"night": n})


## Lebende Dorfpersonen, deren Rolle (oder gestohlene Fähigkeit) das Orakel ist.
static func _oracles(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.alive_ids():
		if s.players[id].faction == Faction.VILLAGE and SoloRules.ability_role(s, id) == RoleCatalog.ORAKEL:
			out.append(id)
	return out


# --- Aufgaben --------------------------------------------------------------------------------------------------

static func task_stage(s: GameState, task: Dictionary, got: Dictionary) -> Dictionary:
	match String(task["kind"]):
		TASK_REVIEW:
			if not got.has("target_id"):
				var allowed := s.alive_ids()
				return {"stage": "pick", "key": "target_id", "allowed": allowed, "min": 0, "max": 1, "victim_id": s.pack_target_id,
					"victim_role": String(s.players[s.pack_target_id].role_id) if s.pack_target_id != GameState.NO_TARGET and s.players.has(s.pack_target_id) else ""}
		TASK_REDIRECT:
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": s.alive_ids(), "min": 1, "max": 1}
		TASK_OMEN:
			if not got.has("caught"):
				return {"stage": "ask", "key": "caught"}
			if not bool(got["caught"]) and not got.has("target_id"):
				var wolves := CardEffects.living_of_variant(s, CardCatalog.WOLF)
				if wolves.is_empty():
					return {}
				return {"stage": "pick", "key": "target_id", "allowed": wolves, "min": 0, "max": 1}
	return {}


static func task_apply(ctx: RuleContext, task: Dictionary, got: Dictionary) -> void:
	var s := ctx.state
	match String(task["kind"]):
		TASK_REVIEW, TASK_REDIRECT:
			if got.has("target_id") and typeof(got["target_id"]) == TYPE_INT and s.players.has(int(got["target_id"])) and int(got["target_id"]) != s.pack_target_id:
				ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": task["card"], "pack_target_from": s.pack_target_id, "pack_target_to": int(got["target_id"])})
				s.pack_target_id = int(got["target_id"])
		TASK_OMEN:
			if got.has("target_id") and typeof(got["target_id"]) == TYPE_INT:
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, int(got["target_id"]), KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(task["owner"]))
				ctx.card_depth -= 1


## Nach der Rudelwahl: Prüfung durch das Rudel (Wachsame Augen), Umlenkung (Falsche Fährte), öffentliche Ansage (Schattenvorteil).
static func after_pack_answer(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.active(s, "pack_review"):
		CardEffects.add_task(s, TASK_REVIEW, {"owner": int(e["owner"]), "card": e["card"]})
		CardEffects.remove_effect(s, int(e["id"]))
		break
	for e: Dictionary in CardEffects.active(s, "pack_redirect"):
		CardEffects.add_task(s, TASK_REDIRECT, {"owner": int(e["owner"]), "card": e["card"]})
		CardEffects.remove_effect(s, int(e["id"]))
		break
	for e: Dictionary in CardEffects.active(s, "pack_announce"):
		ctx.emit(GameEvent.CARD_ANNOUNCED, Visibility.PUBLIC, {"card_id": "segen_13", "variant": "dorf", "values": {"victim_id": s.pack_target_id, "extra_ids": (s.cardsys["pack_extra"] as Array).duplicate()}})
		CardEffects.remove_effect(s, int(e["id"]))
		break


## Ende der Morgenauflösung: Schlechtes Omen (Wolf).
static func on_dawn_end(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.active(s, "bad_omen_w"):
		CardEffects.remove_effect(s, int(e["id"]))
		CardEffects.add_task(s, TASK_OMEN, {"owner": int(e["owner"]), "card": e["card"]})
		break
