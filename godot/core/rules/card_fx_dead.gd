class_name CardFxDead
extends RefCounted
## Kartenfamilie „Tote handeln“ (Arbeitsliste Gruppe 6): Tote nominieren, stimmen oder zeigen am Tisch; die Spielleitung trägt das
## Ergebnis ein, der Kern setzt die Folgen um.
##   segen_10 Totenurteil     die toten Wölfe (Dorf: die toten Dorfpersonen) wählen heimlich; die Spielleitung trägt das Opfer ein, es stirbt
##                            noch in der kommenden Nacht (Todesmarkierung am Morgen, Ursache CARD_EFFECT)
##   schicksal_12 Totengericht / solo_13 Das Totenreich regiert  der nächste Tag (zwei Tage) wird von den Toten geleitet:
##                            nur tote Personen dürfen nominieren, lebende hören schweigend zu
##   loki_05 Totenerwachen    alle Toten zeigen gleichzeitig auf eine lebende Person; die meistgenannte (bei Gleichstand alle) stirbt sofort
## Eine Person im Totenreich nominiert wie jede andere höchstens einmal je Tag; Hinrichtungsziel bleibt eine lebende nominierte Person.


static func playable(s: GameState, rec: Dictionary, _window: StringName) -> bool:
	match StringName(rec["card"]):
		&"segen_10":
			return not _targets(s, StringName(rec["variant"])).is_empty()
		&"loki_05":
			return not s.alive_ids().is_empty()
	return true


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	match StringName(rec["card"]):
		&"segen_10":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _targets(s, StringName(rec["variant"])), "min": 1, "max": 1}
		&"loki_05":
			if not got.has("targets"):
				return {"stage": "pick", "key": "targets", "allowed": s.alive_ids(), "min": 1, "max": s.alive_ids().size()}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, _window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	match StringName(rec["card"]):
		&"segen_10":
			var target := int(got["target_id"])
			s.death_marks.append({"target_id": target, "source_id": int(rec["owner"]), "cause": String(KillEvent.CAUSE_CARD_EFFECT)})
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "marked_id": target})
		&"schicksal_12":
			_dead_rule(ctx, rec, s.day_number + 1, s.day_number + 1)
		&"solo_13":
			_dead_rule(ctx, rec, s.day_number + 1, s.day_number + 2)
		&"loki_05":
			var victims: Array = got["targets"]
			CardEffects.announce(ctx, rec, {"victim_ids": victims.duplicate()})
			ctx.card_depth += 1
			for id: Variant in victims:
				KillPipeline.request_kill(ctx, int(id), KillEvent.CAUSE_CARD_EFFECT, KillEvent.SOURCE_PLAYER, int(rec["owner"]))
			ctx.card_depth -= 1


static func _targets(s: GameState, variant: StringName) -> Array[int]:
	# Wolf: ein Dorfbewohner stirbt; Dorf: ein Werwolf stirbt.
	return CardEffects.living_of_variant(s, CardCatalog.DORF if variant == CardCatalog.WOLF else CardCatalog.WOLF)


static func _dead_rule(ctx: RuleContext, rec: Dictionary, from_day: int, to_day: int) -> void:
	CardEffects.add_effect(ctx, rec, "dead_rule", CardEffects.now_key(ctx.state), CardEffects.day_key(to_day), {"from_day": from_day, "to_day": to_day})
	CardEffects.announce(ctx, rec, {"from_day": from_day, "to_day": to_day})


## Tage, an denen nur Tote nominieren und abstimmen dürfen.
static func dead_rule_active(s: GameState) -> bool:
	if not s.death_cards or s.phase != Phase.DAY:
		return false
	for e: Dictionary in CardEffects.effects(s, "dead_rule"):
		if int(e["data"]["from_day"]) <= s.day_number and s.day_number <= int(e["data"]["to_day"]):
			return true
	return false
