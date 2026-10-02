class_name CardFxSolo
extends RefCounted
## Kartenfamilie „Solo“ (solo_01 bis solo_14; solo_13 steht in CardFxDead). Technische bzw. redaktionelle Entscheidungen
## dieses Auftrags, soweit der Regeltext (docs/role-migration/14-totenkarten-arbeitsliste.md) etwas offen lässt:
##   solo_01 Todesprojektion  die Spielleitung trägt den Zettel ein (lebende Person); stirbt sie bei der nächsten tatsächlichen
##                            Hinrichtung, kehrt die Kartenspielerin mit deren Rolle und Fraktion zurück (frische Einsätze);
##                            jede andere Hinrichtung verbraucht den Zettel.
##   solo_02 Schwarze Prophezeiung  Tipp Dorf, Wölfe oder Einzelsieg; stimmt er mit dem bestätigten Sieger überein, wird die Person
##                            im Abschlussbericht als stille Mitsiegerin geführt.
##   solo_03 Racheschwur      die Spielleitung trägt die Person ein; die Stimmen am Tisch werden öffentlich angesagt (+3 gegen sie),
##                            bis sie stirbt. Kein Zählwerk im Kern: Stimmen werden am Tisch gezählt.
##   solo_04 Apokalyptischer Abgang  zwei lebende Personen werden verbunden; stirbt eine bis Ende der vierten folgenden Nacht,
##                            stirbt die andere sofort nach (Kartentod, Schilde greifen).
##   solo_05 Vermächtnis      die gewählte lebende Person erbt die Nachtfähigkeit der Kartenspielerin dauerhaft zusätzlich (soweit
##                            übertragbar); gehört sie zu den Gewinnern, gewinnt die Kartenspielerin mit.
##   solo_06 Geisterstimme    drei Tage lang darf die Kartenspielerin nominieren und mitstimmen (Stimme doppelt, am Tisch);
##                            wird dadurch jemand hingerichtet, den sie nominiert hat, kehrt sie mit einer neuen Einzelsiegrolle zurück.
##   solo_07 Martyrium        Dorf: die nächste Nacht ohne Rudelangriff. Wölfe: die nächste Hinrichtung entfällt.
##   solo_08 Stiller Zeuge    die Spielleitung trägt die gefährlichste Person ein; gewinnt sie, gewinnt die Kartenspielerin mit.
##   solo_09 Chaosgeist       App-Würfel: so viele Hinrichtungen heute (mindestens eine; endet ohne weitere Nominierte).
##   solo_10 Einsames Erbe    zwei Zettel: Person, die gewinnt, und erste Person, die nach dem Spielen stirbt. Posthumer Sieg, wenn beide stimmen.
##   solo_11 Richter aus dem Totenreich  nach jeder Abstimmung des Tages: eine weitere Nominierung; stimmen mindestens 50 Prozent zu, wird die Person hingerichtet.
##   solo_12 Familienbande    +3 Stimmen (am Tisch); gehört die Person zu den letzten zwei Lebenden, gewinnt sie (Kandidat) und die Kartenspielerin mit.
##   solo_14 Verrat oder Verbrüderung  die Kartenspielerin beschuldigt einen lebenden Nachbarn; stimmt der andere zu, stirbt der Beschuldigte.

const TASK_REBIRTH := "solo_rebirth"
const TASK_JUDGE := "solo_judge"
const TEAMS: Array[String] = ["village", "wolves", "solo"]
const FAMILY_FRONT := 2  ## „unter den letzten zwei Lebenden“
const PERM := -1  ## Nacht-Schlüssel einer dauerhaft verliehenen Fähigkeit


static func playable(s: GameState, rec: Dictionary, _window: StringName) -> bool:
	var owner := int(rec["owner"])
	match StringName(rec["card"]):
		&"solo_01", &"solo_03", &"solo_05", &"solo_08", &"solo_10", &"solo_12":
			return not _others(s, owner).is_empty()
		&"solo_04":
			return _others(s, owner).size() >= 2
		&"solo_14":
			return not Seats.living_neighbours(s, owner).is_empty()
		&"solo_09", &"solo_11":
			return s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED
		&"solo_07":
			return true
	return true


static func _others(s: GameState, owner: int) -> Array[int]:
	return s.alive_ids().filter(func(id: int) -> bool: return id != owner)


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	var owner := int(rec["owner"])
	match StringName(rec["card"]):
		&"solo_01", &"solo_03", &"solo_05", &"solo_08", &"solo_12":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _others(s, owner), "min": 1, "max": 1}
		&"solo_02":
			if not got.has("team"):
				return {"stage": "option", "key": "team", "options": TEAMS.duplicate(), "option_kind": "team"}
		&"solo_04":
			if not got.has("targets"):
				return {"stage": "pick", "key": "targets", "allowed": _others(s, owner), "min": 2, "max": 2}
		&"solo_07":
			if not got.has("side"):
				return {"stage": "option", "key": "side", "options": ["village", "wolves"], "option_kind": "side"}
		&"solo_09":
			if not got.has("dice"):
				return {"stage": "roll", "key": "dice", "count": 1}
		&"solo_10":
			if not got.has("winner_id"):
				return {"stage": "pick", "key": "winner_id", "allowed": s.alive_ids(), "min": 1, "max": 1}
			if not got.has("next_dead_id"):
				return {"stage": "pick", "key": "next_dead_id", "allowed": s.alive_ids(), "min": 1, "max": 1}
		&"solo_14":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": Seats.living_neighbours(s, owner), "min": 1, "max": 1}
			if not got.has("agrees"):
				return {"stage": "ask", "key": "agrees"}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	var owner := int(rec["owner"])
	var now := CardEffects.now_key(s)
	var day := CardEffects.lynch_day(s, window)
	match StringName(rec["card"]):
		&"solo_01":
			CardEffects.add_effect(ctx, rec, "projection", now, CardEffects.FOREVER, {"person_id": int(got["target_id"])})
		&"solo_02":
			CardEffects.add_effect(ctx, rec, "prophecy", now, CardEffects.FOREVER, {"team": String(got["team"])})
		&"solo_03":
			var cursed := int(got["target_id"])
			CardEffects.add_effect(ctx, rec, "vote_curse", now, CardEffects.FOREVER, {"person_id": cursed, "extra_votes": 3})
			CardEffects.announce(ctx, rec, {"person_id": cursed, "extra_votes": 3})
		&"solo_04":
			var pair: Array = (got["targets"] as Array).duplicate()
			pair.sort()
			var last_night := CardEffects.next_night(s) + 3
			CardEffects.add_effect(ctx, rec, "death_bond", now, CardEffects.night_key(last_night), {"ids": pair})
			CardEffects.announce(ctx, rec, {"person_ids": pair, "until_night": last_night})
		&"solo_05":
			var heir := int(got["target_id"])
			var role := s.players[owner].role_id
			if RoleCatalog.stealable(role) and RoleCatalog.night_priority(role) > 0:
				(s.cardsys["abilities"] as Array).append({"player_id": heir, "role_id": String(role), "night": PERM})
			CardEffects.add_effect(ctx, rec, "legacy", now, CardEffects.FOREVER, {"heir_id": heir})
			ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(role)}, heir)
		&"solo_06":
			CardEffects.add_effect(ctx, rec, "dead_actor", now, CardEffects.day_key(s.day_number + 2), {"from_day": s.day_number, "to_day": s.day_number + 2})
			CardEffects.announce(ctx, rec, {"to_day": s.day_number + 2})
		&"solo_07":
			var side := String(got["side"])
			if side == "village":
				var n := CardEffects.next_night(s)
				CardEffects.add_effect(ctx, rec, "pack_sleep", CardEffects.night_key(n), CardEffects.night_key(n), {"night": n})
			else:
				CardEffects.add_effect(ctx, rec, "lynch_cancel", now, CardEffects.day_key(day), {"day": day})
			CardEffects.announce(ctx, rec, {"side": side})
		&"solo_08":
			CardEffects.add_effect(ctx, rec, "witness", now, CardEffects.FOREVER, {"person_id": int(got["target_id"])})
		&"solo_09":
			var count := clampi(int((got["dice"] as Array)[0]), 1, 6)
			CardEffects.add_effect(ctx, rec, "multi_lynch", now, CardEffects.day_key(s.day_number), {"day": s.day_number, "n": count, "done": 0})
			CardEffects.announce(ctx, rec, {"count": count})
		&"solo_10":
			CardEffects.add_effect(ctx, rec, "legacy_notes", now, CardEffects.FOREVER,
				{"winner_id": int(got["winner_id"]), "next_dead_id": int(got["next_dead_id"]), "first_dead_id": -1})
		&"solo_11":
			CardEffects.add_effect(ctx, rec, "solo_judge", now, CardEffects.day_key(s.day_number), {"day": s.day_number})
			CardEffects.announce(ctx, rec)
		&"solo_12":
			var chosen := int(got["target_id"])
			CardEffects.add_effect(ctx, rec, "family_bond", now, CardEffects.FOREVER, {"person_id": chosen, "extra_votes": 3})
			CardEffects.announce(ctx, rec, {"person_id": chosen, "extra_votes": 3})
			s.win_check_pending = true
		&"solo_14":
			var accused := int(got["target_id"])
			CardEffects.announce(ctx, rec, {"accused_id": accused, "agreed": bool(got["agrees"])})
			if bool(got["agrees"]) and s.players[accused].alive:
				ctx.card_depth += 1
				KillPipeline.request_kill(ctx, accused, KillEvent.CAUSE_CARD_EFFECT, KillEvent.SOURCE_PLAYER, owner)
				ctx.card_depth -= 1


# --- Aufgaben ------------------------------------------------------------------------------------------------------

static func task_stage(s: GameState, task: Dictionary, got: Dictionary) -> Dictionary:
	match String(task["kind"]):
		TASK_REBIRTH:
			if not got.has("role"):
				var options := CardFxReturn.role_options(s, int(task["owner"]))
				if options.is_empty():
					return {}
				return {"stage": "option", "key": "role", "options": options, "option_kind": "role", "person_id": int(task["owner"])}
		TASK_JUDGE:
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": s.alive_ids(), "min": 0, "max": 1}
			if got["target_id"] is int and not got.has("agrees"):
				return {"stage": "ask", "key": "agrees"}
	return {}


static func task_apply(ctx: RuleContext, task: Dictionary, got: Dictionary) -> void:
	var s := ctx.state
	var owner := int(task["owner"])
	match String(task["kind"]):
		TASK_REBIRTH:
			if s.players[owner].alive:
				return
			CardFxReturn.revive(ctx, {"card": "solo_06", "variant": "solo", "owner": owner}, owner)
			if got.has("role"):
				RoleTransition.change_role(s, owner, StringName(got["role"]), &"", true)
		TASK_JUDGE:
			if not got.has("target_id") or not bool(got.get("agrees", false)):
				return
			var target := int(got["target_id"])
			if s.players.has(target) and s.players[target].alive:
				ctx.emit(GameEvent.EXECUTION_CONFIRMED, Visibility.PUBLIC, {"target_id": target, "day": s.day_number, "gm_override": false, "card_id": "solo_11"})
				ExecutionRules.execute(ctx, target, KillEvent.SOURCE_VILLAGE)


# --- Haken ----------------------------------------------------------------------------------------------------------

## Folgen einer Hinrichtung, die einen Tod verursacht hat: Todesprojektion, Geisterstimme.
static func after_execution(ctx: RuleContext, record: KillEvent) -> void:
	var s := ctx.state
	if not s.death_cards or record == null:
		return
	for e: Dictionary in CardEffects.effects(s, "projection"):
		var person := int(e["data"]["person_id"])
		var owner := int(e["owner"])
		CardEffects.remove_effect(s, int(e["id"]))  # jede tatsächliche Hinrichtung verbraucht den Zettel
		if record.target_id == person and not s.players[owner].alive:
			var source: Player = s.players[person]
			CardFxReturn.revive(ctx, e, owner)
			RoleTransition.change_role(s, owner, source.role_id, source.appears_as, true)
	for e: Dictionary in CardEffects.effects(s, "dead_actor"):
		var owner := int(e["owner"])
		if s.players[owner].alive or int(e["data"]["to_day"]) < s.day_number:
			continue
		for n: Nomination in s.nominations_on_day(s.day_number):
			if n.nominator_id == owner and n.nominee_id == record.target_id and not n.by_judge:
				CardEffects.remove_effect(s, int(e["id"]))
				CardEffects.add_task(s, TASK_REBIRTH, e)
				break


## Tod einer Person: Todesband und der Zettel „erster Toter“ des Einsamen Erbes.
static func after_death(ctx: RuleContext, target: Player, record: KillEvent) -> void:
	var s := ctx.state
	if not s.death_cards:
		return
	for e: Dictionary in CardEffects.active(s, "death_bond"):
		var ids: Array = e["data"]["ids"]
		if not ids.has(target.id):
			continue
		var other := int(ids[1]) if int(ids[0]) == target.id else int(ids[0])
		CardEffects.remove_effect(s, int(e["id"]))
		if s.players.has(other) and s.players[other].alive:
			ctx.card_depth += 1
			KillPipeline.request_kill(ctx, other, KillEvent.CAUSE_CARD_CHAIN, KillEvent.SOURCE_PLAYER, int(e["owner"]))
			ctx.card_depth -= 1
	for e: Dictionary in CardEffects.effects(s, "legacy_notes"):
		if int(e["data"]["first_dead_id"]) == -1 and target.id != int(e["owner"]):
			e["data"]["first_dead_id"] = target.id
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": "solo_10", "first_dead_id": target.id, "matches": target.id == int(e["data"]["next_dead_id"])})
	if record.cause == KillEvent.CAUSE_LYNCH:
		pass


## Nach der Hinrichtung: Richter aus dem Totenreich fragt nach der weiteren Nominierung.
static func after_decision(s: GameState) -> void:
	if not s.death_cards:
		return
	for e: Dictionary in CardLynch.for_today(s, "solo_judge"):
		CardEffects.add_task(s, TASK_JUDGE, e)
		CardEffects.remove_effect(s, int(e["id"]))  # einmal je Karte


## Verstorbene Person darf nominieren: Geisterstimme (nur die Besitzerin, drei Tage).
static func may_nominate_dead(s: GameState, person_id: int) -> bool:
	if not s.death_cards or s.phase != Phase.DAY:
		return false
	for e: Dictionary in CardEffects.effects(s, "dead_actor"):
		if int(e["owner"]) == person_id and int(e["data"]["from_day"]) <= s.day_number and s.day_number <= int(e["data"]["to_day"]):
			return true
	return false


# --- Siege ----------------------------------------------------------------------------------------------------------

## Person gewinnt mit dem bestätigten Kandidaten: Begünstigte oder Mitglieder der siegenden Seite (Dorf, Wölfe).
static func person_wins(s: GameState, chosen: WinCandidate, person_id: int) -> bool:
	if chosen.beneficiary_ids.has(person_id):
		return true
	if not s.players.has(person_id):
		return false
	var variant := CardCatalog.owner_variant(s.players[person_id])
	if chosen.kind == Faction.VILLAGE:
		return variant == CardCatalog.DORF
	if chosen.kind == Faction.WOLVES:
		return variant == CardCatalog.WOLF
	return false


## Stille Mitsieger und posthume Sieger einer bestätigten Entscheidung: [{person_id, card_id}].
static func cowinners(s: GameState, chosen: WinCandidate) -> Array:
	var out: Array = []
	if not s.death_cards or chosen == null:
		return out
	for e: Dictionary in CardEffects.effects(s, "prophecy"):
		if String(e["data"]["team"]) == String(chosen.kind):
			out.append({"person_id": int(e["owner"]), "card_id": String(e["card"])})
	for e: Dictionary in CardEffects.effects(s, "legacy"):
		if person_wins(s, chosen, int(e["data"]["heir_id"])):
			out.append({"person_id": int(e["owner"]), "card_id": String(e["card"])})
	for e: Dictionary in CardEffects.effects(s, "witness"):
		if person_wins(s, chosen, int(e["data"]["person_id"])):
			out.append({"person_id": int(e["owner"]), "card_id": String(e["card"])})
	for e: Dictionary in CardEffects.effects(s, "legacy_notes"):
		if person_wins(s, chosen, int(e["data"]["winner_id"])) and int(e["data"]["first_dead_id"]) == int(e["data"]["next_dead_id"]):
			out.append({"person_id": int(e["owner"]), "card_id": String(e["card"])})
	for e: Dictionary in CardEffects.effects(s, "family_bond"):
		if person_wins(s, chosen, int(e["data"]["person_id"])):
			out.append({"person_id": int(e["owner"]), "card_id": String(e["card"])})
	return out


## Familienbande: die gewählte Person lebt und gehört zu den letzten zwei Lebenden.
static func family_bond_wins(s: GameState, person_id: int) -> bool:
	if not s.death_cards or not s.players.has(person_id) or not s.players[person_id].alive or s.alive_ids().size() > FAMILY_FRONT:
		return false
	for e: Dictionary in CardEffects.effects(s, "family_bond"):
		if int(e["data"]["person_id"]) == person_id:
			return true
	return false
