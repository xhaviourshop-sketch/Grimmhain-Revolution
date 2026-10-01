class_name CardFxAbility
extends RefCounted
## Kartenfamilie „Fähigkeiten sperren, wiederholen, verdoppeln“ (Arbeitsliste Gruppe 4; KS-107, KS-108 des Auftrags):
##   segen_06 Schattenmantel  Wolf: der nächste Wolf, den das Orakel sieht, erscheint ihm als zufällige lebende Dorfrolle.
##                            Dorf: in der Folgenacht ist das Rudel geblendet, ein zufälliges Opfer (auch ein Wolf) ersetzt
##                            die normale Zielwahl des Rudels (KS-107).
##   segen_12 Geisterhand     eine gewählte Person erhält für die nächste Nacht zusätzlich die Fähigkeit der zuletzt verstorbenen
##                            Person der Fraktion, frisch mit verfügbaren Einsätzen (KS-108).
##   segen_14 Eiserner Wille  Einsicht ins Spiel für die Besitzerin; eine gewählte Person darf ihre Fähigkeit erneut oder zweimal einsetzen.
##   fluch_01 Blinder Fleck   eine zufällige Person der Fraktion verliert diese Nacht ihre Sonderfähigkeit (das Rudel bleibt).
##   wende_01 Letzter Atemzug / wende_08 Auserwählt  eine gewählte Person darf ihre Fähigkeit diese Nacht erneut bzw. zweimal einsetzen.
##   wende_10 Schicksalsumkehr  Wolf: die Schutzfähigkeit einer gewählten Dorfperson ruht eine Nacht. Dorf: die Fähigkeit eines gewählten Wolfs.
##   schicksal_07 Gleichgewicht  die Spielleitung bestimmt und verkündet, wer vorne liegt; dessen erste gewählte Nachtfähigkeit wird blockiert.
##   schicksal_10 Anarchie    eine zufällige verbrauchte Einmalfähigkeit einer lebenden Person der Fraktion wird wieder verfügbar.
##   loki_07 Totale Anarchie  alle Schutzwirkungen werden aufgehoben, alle verbrauchten Einsätze kehren für alle zurück.
##   wende_11 Schicksalswende (Wolf)  ein gewählter Wolf erhält in der nächsten Nacht genau eine Gelegenheit, König Lykaons Verwandlung zu nutzen.
## Mechanik zusätzlicher Einsätze: `grant_extra_use` (Apfel für jede-Nacht-Rollen, frische Einsätze für Einmal-Rollen). Zusätzliche
## Fähigkeiten einer anderen Rolle sind `GameState.cardsys.abilities` (nur Rollen, die auch der Grabräuber stehlen kann).

const LEADERS: Array[String] = ["village", "wolves"]
## Schutzfähigkeiten mit Nachtschritt (Schicksalsumkehr, Wolfsvariante).
const PROTECTIVE_ROLES: Array[StringName] = [RoleCatalog.SCHUTZENGEL, RoleCatalog.WALDHEXE, RoleCatalog.MAERTYRERIN, RoleCatalog.DORFSCHMIED,
	RoleCatalog.VERDAMMNISWAECHTER, RoleCatalog.SCHUTZGEIST]


static func playable(s: GameState, rec: Dictionary, _window: StringName) -> bool:
	var variant := StringName(rec["variant"])
	match StringName(rec["card"]):
		&"fluch_01":
			return not _members(s, variant).is_empty()
		&"wende_01", &"wende_08", &"segen_14":
			return not _grant_targets(s, variant, int(rec["owner"]), StringName(rec["card"])).is_empty()
		&"wende_10":
			return not _hexable(s, variant).is_empty()
		&"schicksal_10":
			return not _anarchy_pairs(s, variant).is_empty()
		&"segen_12":
			return _last_dead_role(s, variant) != &"" and not s.alive_ids().is_empty()
		&"wende_11":
			return variant == CardCatalog.DORF or not CardEffects.living_of_variant(s, CardCatalog.WOLF).is_empty()
		&"loki_08":
			return RoleCatalog.stealable(s.players[int(rec["owner"])].role_id) and not s.alive_ids().is_empty()
	return true


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	var variant := StringName(rec["variant"])
	match StringName(rec["card"]):
		&"segen_12":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": s.alive_ids(), "min": 1, "max": 1}
		&"segen_14":
			if not got.has("seen"):
				return {"stage": "confirm", "key": "seen"}
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _grant_targets(s, variant, int(rec["owner"]), &"segen_14"), "min": 1, "max": 1}
			if not got.has("mode"):
				return {"stage": "option", "key": "mode", "options": ["again", "twice"], "option_kind": "mode"}
		&"wende_01", &"wende_08":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _grant_targets(s, variant, int(rec["owner"]), StringName(rec["card"])), "min": 1, "max": 1}
		&"wende_10":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _hexable(s, variant), "min": 1, "max": 1}
		&"schicksal_07":
			if not got.has("leader"):
				return {"stage": "option", "key": "leader", "options": LEADERS.duplicate(), "option_kind": "leader"}
		&"loki_08":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": s.alive_ids(), "min": 1, "max": 1}
		&"wende_11":
			if variant == CardCatalog.WOLF and not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": CardEffects.living_of_variant(s, CardCatalog.WOLF), "min": 1, "max": 1}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, _window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	var variant := StringName(rec["variant"])
	var n := CardEffects.next_night(s)
	var now := CardEffects.now_key(s)
	var night_from := CardEffects.night_key(n)
	match StringName(rec["card"]):
		&"segen_06":
			if variant == CardCatalog.WOLF:
				CardEffects.add_effect(ctx, rec, "oracle_cloak", now, CardEffects.FOREVER)
			else:
				CardEffects.add_effect(ctx, rec, "pack_blind", night_from, night_from, {"night": n})
		&"segen_12":
			var target := int(got["target_id"])
			var role := _last_dead_role(s, variant)
			grant_role(ctx, rec, target, role, n)
		&"segen_14":
			grant_extra_use(ctx, rec, int(got["target_id"]), n)
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "granted_id": int(got["target_id"]), "mode": got["mode"]})
		&"wende_01", &"wende_08":
			grant_extra_use(ctx, rec, int(got["target_id"]), n)
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "granted_id": int(got["target_id"])})
		&"fluch_01":
			var pool := _members(s, variant)
			var with_step := pool.filter(func(id: int) -> bool: return _has_repeatable(s, id))
			var chosen := CardEffects.random_of(s, with_step if not with_step.is_empty() else pool)
			CardEffects.add_effect(ctx, rec, "lose_ability", night_from, night_from, {"night": n, "person_id": chosen})
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "blocked_id": chosen, "night": n})
		&"wende_10":
			var victim := int(got["target_id"])
			CardEffects.add_effect(ctx, rec, "lose_ability", night_from, night_from, {"night": n, "person_id": victim})
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "blocked_id": victim, "night": n})
		&"schicksal_07":
			var leader := String(got["leader"])
			CardEffects.add_effect(ctx, rec, "block_first", night_from, night_from, {"night": n, "faction": leader})
			CardEffects.announce(ctx, rec, {"leader": leader})
		&"schicksal_10":
			var pairs := _anarchy_pairs(s, variant)
			var pick: Array = pairs[s.rng.next_int(0, pairs.size() - 1)]
			(s.players[int(pick[0])].ability_uses as Dictionary).erase(String(pick[1]))
			ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "restored_id": int(pick[0]), "ability": String(pick[1])})
			ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "ability": String(pick[1])}, int(pick[0]))
		&"loki_07":
			_total_anarchy(ctx, rec)
		&"loki_08":
			# Redaktionelle Entscheidung dieses Auftrags: Die Spielleitung bestimmt, wer die Nachtfähigkeit der Karteninhaberin in der
			# nächsten Nacht ausführt (Stellvertretung); so entscheidet sie, ob die Fähigkeit durchgeht oder ein anderes Ziel trifft.
			var proxy := int(got["target_id"])
			grant_role(ctx, rec, proxy, s.players[int(rec["owner"])].role_id, n)
		&"wende_11":
			if variant == CardCatalog.WOLF:
				var wolf := int(got["target_id"])
				grant_role(ctx, rec, wolf, RoleCatalog.KOENIG_LYKAON, n)


# --- Bausteine -----------------------------------------------------------------------------------------------------

static func _members(s: GameState, variant: StringName) -> Array[int]:
	return CardEffects.living_of_variant(s, CardCatalog.WOLF if variant == CardCatalog.WOLF else CardCatalog.DORF)


static func _has_repeatable(s: GameState, id: int) -> bool:
	var role := SoloRules.ability_role(s, id)
	return RoleCatalog.night_priority(role) > 0 and not RoleCatalog.first_night_only(role)


## Personen der Fraktion, die einen weiteren Einsatz erhalten können: lebende mit eigenem Nachtschritt.
static func _grant_targets(s: GameState, variant: StringName, _owner: int, _card: StringName) -> Array[int]:
	return _members(s, variant).filter(func(id: int) -> bool: return _has_repeatable(s, id))


## Zusätzlicher Einsatz in der nächsten Nacht: Apfel (Rollen, die jede Nacht wirken, höchstens einmal je Nacht verdoppelt)
## und frische Einsätze der eigenen Rolle (Einmalfähigkeiten, die schon verbraucht sind).
static func grant_extra_use(ctx: RuleContext, rec: Dictionary, person_id: int, night: int) -> void:
	var s := ctx.state
	var role := SoloRules.ability_role(s, person_id)
	if RoleCatalog.APPLE_ROLES.has(role):
		s.apples[person_id] = night
	var p := s.players[person_id]
	for key: String in p.ability_uses.keys():
		if key.begins_with("%s:" % role):
			p.ability_uses.erase(key)
	ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(role)}, person_id)


## Verleiht eine zusätzliche Nachtfähigkeit einer anderen Rolle für `night` (frische Einsätze). Gleiche Rolle: wie ein weiterer Einsatz.
static func grant_role(ctx: RuleContext, rec: Dictionary, person_id: int, role: StringName, night: int) -> void:
	var s := ctx.state
	if SoloRules.ability_role(s, person_id) == role or not RoleCatalog.stealable(role):
		grant_extra_use(ctx, rec, person_id, night)
		return
	var p := s.players[person_id]
	for key: String in p.ability_uses.keys():
		if key.begins_with("%s:" % role):
			p.ability_uses.erase(key)
	(s.cardsys["abilities"] as Array).append({"player_id": person_id, "role_id": String(role), "night": night})
	ctx.emit(GameEvent.CARD_NOTICE, Visibility.ACTOR, {"card_id": rec["card"], "role_id": String(role)}, person_id)
	ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "granted_id": person_id, "role_id": String(role), "night": night})


## Rolle der zuletzt verstorbenen Person der Fraktion (Todesreihenfolge), deren Fähigkeit übertragbar ist; &"" ohne sie.
static func _last_dead_role(s: GameState, variant: StringName) -> StringName:
	var best_role := &""
	var best_order := -1
	var v := CardCatalog.WOLF if variant == CardCatalog.WOLF else CardCatalog.DORF
	for id: int in s.players:
		var p := s.players[id]
		if p.alive or p.death == null or CardCatalog.owner_variant(p) != v or not RoleCatalog.stealable(p.role_id):
			continue
		if p.death.order_index > best_order:
			best_order = p.death.order_index
			best_role = p.role_id
	return best_role


## Schicksalsumkehr: Wolf wählt eine Dorfperson mit aktiver Schutzfähigkeit, Dorf einen Wolf mit Nachtfähigkeit.
static func _hexable(s: GameState, variant: StringName) -> Array[int]:
	var out: Array[int] = []
	if variant == CardCatalog.WOLF:
		for id: int in CardEffects.living_of_variant(s, CardCatalog.DORF):
			if PROTECTIVE_ROLES.has(SoloRules.ability_role(s, id)):
				out.append(id)
	else:
		for id: int in CardEffects.living_of_variant(s, CardCatalog.WOLF):
			if _has_repeatable(s, id):
				out.append(id)
	return out


## Anarchie: lebende Personen der Fraktion mit verbrauchtem Einsatz ihrer Rolle: [[Person, Schlüssel]].
static func _anarchy_pairs(s: GameState, variant: StringName) -> Array:
	var out: Array = []
	for id: int in s.alive_ids():
		var p := s.players[id]
		if CardCatalog.owner_variant(p) != variant:
			continue
		var keys: Array = p.ability_uses.keys()
		keys.sort()
		for key: Variant in keys:
			if String(key).begins_with("%s:" % p.role_id) and not String(key).ends_with("death_reaction"):
				out.append([id, String(key)])
	return out


## Totale Anarchie: alle Schutzwirkungen fallen, alle verbrauchten Einsätze kehren für alle zurück.
static func _total_anarchy(ctx: RuleContext, rec: Dictionary) -> void:
	var s := ctx.state
	s.protections.clear()
	for a: WitchAction in s.witch_actions:
		a.saved_id = GameState.NO_TARGET
	s.shields.clear()
	s.weapons.clear()
	s.necro_shields.clear()
	s.martyr_saves.clear()
	s.hades_barriers.clear()
	(s.cardsys["shields"] as Array).clear()
	for e: Dictionary in (s.cardsys["effects"] as Array).duplicate():
		if ["pack_protect", "lynch_immune"].has(String(e["kind"])):
			CardEffects.remove_effect(s, int(e["id"]))
	for id: int in s.players:
		var p := s.players[id]
		if p.alive:
			p.ability_uses.clear()
	CardEffects.announce(ctx, rec)
	ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": rec["card"], "protections_cleared": true, "uses_restored": true})


# --- Haken im Nachtplan und bei Orakel-Prüfungen ----------------------------------------------------------------

## Zusätzliche Fähigkeit dieser Nacht (Person, Rolle) für den Nachtplan.
static func night_abilities(s: GameState) -> Array:
	var out: Array = []
	if not s.death_cards:
		return out
	for a: Dictionary in s.cardsys["abilities"]:
		if (int(a["night"]) == s.night_number or int(a["night"]) == CardFxSolo.PERM) and s.players[int(a["player_id"])].alive:
			out.append([int(a["player_id"]), StringName(a["role_id"])])
	return out
