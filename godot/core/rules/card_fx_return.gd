class_name CardFxReturn
extends RefCounted
## Kartenfamilie „Tod, Rückkehr und Rollenwechsel“ (Arbeitsliste Gruppe 1; Decision Log vierte bis siebte Antwortrunde):
##   segen_08 Zweites Leben   Besitzerin wählt aus bis zu drei angebotenen toten Personen ihrer Fraktion (Vergabe nur bei
##                            mindestens zwei anderen Toten derselben Fraktion; Angebot gespeichert, ungültige Namen ersetzt)
##   wende_04 Wiedergeburt    die Spielleitung wählt eine tote Person der Fraktion, auch die Kartenspielerin
##   wende_07 Befreiung       die Kartenspielerin wählt; die Person stirbt erst nach dem einmaligen Fähigkeitseinsatz erneut
##   loki_10 Phoenix          zwei App-Würfel: Anzahl der Zurückkehrenden und Lebensdauer in Tagen (1, 1, 2, 2, 3, 3)
##   schicksal_08 Neuer Anfang  zwei Lebende erhalten eine neue Rolle ihrer Fraktion, frischer Start
##   loki_06 Rollenroulette   zwei zufällige Lebende derselben Fraktion tauschen still ihre Rollen
## Rückkehr: Rolle vom Todeszeitpunkt (auch wenn jemand sie inzwischen hat), begrenzte Einsätze zurück, Karte verfällt.
## Technische Entscheidungen dieses Auftrags: Lebensdauer zählt den Tag des Spielens als ersten Tag und endet nach der
## Hinrichtung und den Todeseffekten des letzten Tages (Phoenix, siebte Antwortrunde); Einsatz bei Befreiung = abgeschlossener
## eigener Nachtschritt mit Auswahl, Ja oder Bestätigung, oder eine Tagesaktion (Amalia, Nekromant); ein Verzicht zählt nicht.

const PHOENIX_DAYS: Array[int] = [1, 1, 2, 2, 3, 3]


static func playable(s: GameState, rec: Dictionary, _window: StringName) -> bool:
	match StringName(rec["card"]):
		&"segen_08":
			return not offer(s, rec).is_empty()
		&"wende_04", &"wende_07":
			return not dead_of_faction(s, int(rec["owner"]), true).is_empty()
		&"loki_10":
			return not _others_dead(s, int(rec["owner"])).is_empty()
		&"schicksal_08":
			return s.alive_ids().size() >= 2
		&"loki_06":
			return not _swap_group(s, false).is_empty()
	return false


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	match StringName(rec["card"]):
		&"segen_08":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": offer(s, rec), "min": 1, "max": 1}
		&"wende_04", &"wende_07":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": dead_of_faction(s, int(rec["owner"]), true), "min": 1, "max": 1}
		&"loki_10":
			if not got.has("dice"):
				return {"stage": "roll", "key": "dice", "count": 2}
		&"schicksal_08":
			if not got.has("targets"):
				return {"stage": "pick", "key": "targets", "allowed": s.alive_ids(), "min": 2, "max": 2}
			var picked: Array = got["targets"]
			for i: int in 2:
				var key := "role_%d" % i
				if not got.has(key):
					return {"stage": "option", "key": key, "options": role_options(s, int(picked[i])), "option_kind": "role", "person_id": int(picked[i])}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	match StringName(rec["card"]):
		&"segen_08", &"wende_04":
			revive(ctx, rec, int(got["target_id"]))
		&"wende_07":
			var target := int(got["target_id"])
			revive(ctx, rec, target)
			CardEffects.add_effect(ctx, rec, "half_return", CardEffects.now_key(s), CardEffects.FOREVER, {"person_id": target})
		&"loki_10":
			var dice: Array = got["dice"]
			var count := int(dice[0])
			var days: int = PHOENIX_DAYS[int(dice[1]) - 1]
			var pool := _others_dead(s, int(rec["owner"]))
			var chosen: Array = s.rng.shuffled(pool).slice(0, mini(count, pool.size()))
			chosen.sort()
			# Tag des Spielens zählt als erster Tag; Ausnahme: im zweiten Fenster mit einem Tag Lebensdauer bis zum Ende des Folgetags.
			var die_day := s.day_number + days - 1
			if window == CardCatalog.WIN_END and days == 1:
				die_day = s.day_number + 1
			for id: Variant in chosen:
				revive(ctx, rec, int(id))
				CardEffects.add_effect(ctx, rec, "phoenix_return", CardEffects.now_key(s), CardEffects.day_key(die_day), {"person_id": int(id), "die_day": die_day})
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "revived_ids": chosen.duplicate(), "dice": dice.duplicate(), "days": days, "die_day": die_day})
		&"schicksal_08":
			var picked: Array = got["targets"]
			for i: int in 2:
				var id := int(picked[i])
				var role := StringName(got["role_%d" % i])
				RoleTransition.change_role(s, id, role, &"", true)
				ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(role)}, id)
			s.win_check_pending = true
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "person_ids": picked.duplicate(), "roles": [got["role_0"], got["role_1"]]})
		&"loki_06":
			var group := _swap_group(s, true)
			var ids: Array = s.rng.shuffled(group).slice(0, 2)
			ids.sort()
			var a := int(ids[0])
			var b := int(ids[1])
			var ra := s.players[a].role_id
			var rb := s.players[b].role_id
			var app_a := s.players[a].appears_as if RoleCatalog.requires_appearance(ra) else &""
			var app_b := s.players[b].appears_as if RoleCatalog.requires_appearance(rb) else &""
			RoleTransition.change_role(s, a, rb, app_b, true)
			RoleTransition.change_role(s, b, ra, app_a, true)
			s.win_check_pending = true
			ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(rb)}, a)
			ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(ra)}, b)
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "person_ids": ids.duplicate(), "roles": [String(rb), String(ra)]})


# --- Bausteine -----------------------------------------------------------------------------------------------

## Tote Personen derselben Fraktionsvariante wie der Besitzer; `with_owner` nimmt die Besitzerin selbst auf.
static func dead_of_faction(s: GameState, owner_id: int, with_owner: bool) -> Array[int]:
	var variant := CardCatalog.owner_variant(s.players[owner_id])
	var out: Array[int] = []
	for id: int in s.players:
		if not s.players[id].alive and (with_owner or id != owner_id) and CardCatalog.owner_variant(s.players[id]) == variant:
			out.append(id)
	out.sort()
	return out


static func _others_dead(s: GameState, owner_id: int) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.players:
		if not s.players[id].alive and id != owner_id:
			out.append(id)
	out.sort()
	return out


## Vergabebedingung von „Zweites Leben“: mindestens zwei andere Tote derselben Fraktion.
static func segen08_grantable(s: GameState, owner_id: int) -> bool:
	return dead_of_faction(s, owner_id, false).size() >= 2


## Angebot von „Zweites Leben“: bis zu drei passende Namen; die gespeicherte Vorauswahl bleibt, ungültig gewordene Namen
## werden deterministisch durch die kleinsten noch gültigen IDs ersetzt (technische Entscheidung, KS-38).
static func offer(s: GameState, rec: Dictionary) -> Array[int]:
	var valid := dead_of_faction(s, int(rec["owner"]), false)
	var out: Array[int] = []
	for id: Variant in rec["pre"]:
		if valid.has(int(id)) and out.size() < CardRules.MAX_PRESELECT:
			out.append(int(id))
	for id: int in valid:
		if out.size() >= CardRules.MAX_PRESELECT:
			break
		if not out.has(id):
			out.append(id)
	out.sort()
	return out


## Zufällige Vorauswahl bei mehr als drei passenden Personen (gespeicherter Generator); Neuladen erzeugt keine neuen Namen.
static func prepare(ctx: RuleContext, rec: Dictionary) -> void:
	if StringName(rec["card"]) != &"segen_08" or not (rec["pre"] as Array).is_empty():
		return
	var valid := dead_of_faction(ctx.state, int(rec["owner"]), false)
	if valid.size() > CardRules.MAX_PRESELECT:
		var picked: Array = ctx.state.rng.shuffled(valid).slice(0, CardRules.MAX_PRESELECT)
		picked.sort()
		rec["pre"] = picked


## Wiederbelebung durch eine Karte: Rolle vom Todeszeitpunkt, begrenzte Einsätze zurück, Karte aus dem früheren Leben verfällt.
static func revive(ctx: RuleContext, rec: Dictionary, person_id: int) -> void:
	var s := ctx.state
	RoleTransition.revive(s, person_id)
	ctx.emit(GameEvent.CARD_REVIVED, Visibility.PUBLIC, {"person_id": person_id, "day": s.day_number, "card_id": rec["card"]})
	ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(s.players[person_id].role_id)}, person_id)
	ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "revived_id": person_id, "role_id": String(s.players[person_id].role_id)})


## Rollenauswahl für „Neuer Anfang“: Rollen der Fraktion der Person ohne die jetzige und ohne Rollen mit Pflicht-Scheinrolle.
static func role_options(s: GameState, person_id: int) -> Array[String]:
	var current := s.players[person_id].role_id
	var faction := s.players[person_id].faction
	var out: Array[String] = []
	for id: Variant in RoleCatalog.ROLES:
		var role := StringName(id)
		if role != current and RoleCatalog.faction_of(role) == faction and not RoleCatalog.requires_appearance(role) and not RoleCatalog.requires_cards(role):
			out.append(String(role))
	return out


## Lebende Personen einer Tauschgruppe (Dorf oder Wölfe, keine Einzelsiegrollen, mindestens zwei): `choose` zieht die Gruppe aus dem Generator.
static func _swap_group(s: GameState, choose: bool) -> Array[int]:
	var groups: Array = []
	for variant: StringName in [CardCatalog.DORF, CardCatalog.WOLF]:
		var members := CardEffects.living_of_variant(s, variant)
		if members.size() >= 2:
			groups.append(members)
	if groups.is_empty():
		return []
	if not choose:
		return groups[0]
	return groups[s.rng.next_int(0, groups.size() - 1)] if groups.size() > 1 else groups[0]


# --- Fristen und Einsatz ---------------------------------------------------------------------------------------

## Tagesende: Rückkehrer des Phoenix, deren Frist heute endet, sterben (nach Hinrichtung und Todeseffekten, vor dem zweiten Fenster).
static func on_day_end(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.effects(s, "phoenix_return"):
		var id := int(e["data"]["person_id"])
		if int(e["data"]["die_day"]) > s.day_number:
			continue
		CardEffects.remove_effect(s, int(e["id"]))
		if s.players[id].alive:
			ctx.card_depth += 1
			KillPipeline.request_kill(ctx, id, KillEvent.CAUSE_CARD_EXPIRY, KillEvent.SOURCE_PLAYER, int(e["owner"]))
			ctx.card_depth -= 1


## Eine Person mit halber Fähigkeit (Befreiung) hat ihre Fähigkeit eingesetzt: Tod am Morgen bzw. sofort am Tag.
static func half_used(ctx: RuleContext, person_id: int) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.effects(s, "half_return"):
		if int(e["data"]["person_id"]) != person_id:
			continue
		CardEffects.remove_effect(s, int(e["id"]))
		if not s.players[person_id].alive:
			return
		ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": e["card"], "half_return_ended": person_id})
		if s.phase == Phase.NIGHT:
			s.death_marks.append({"target_id": person_id, "source_id": int(e["owner"]), "cause": String(KillEvent.CAUSE_CARD_EXPIRY)})
		else:
			ctx.card_depth += 1
			KillPipeline.request_kill(ctx, person_id, KillEvent.CAUSE_CARD_EXPIRY, KillEvent.SOURCE_PLAYER, int(e["owner"]))
			ctx.card_depth -= 1
		return
