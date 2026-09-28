class_name SoloRules
extends RefCounted
## Einzelsiegrollen, Teil 1 (DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“, 28.09.2026):
##   Rattenfänger: Verzauberungen je Rattenfänger (`charms`); Sieg lebend bei allen anderen verzaubert.
##   Pestbringerin: Infektionen (`infected`, gemeinsam), Ausbreitung zu Beginn jeder Morgenauflösung auf einen
##     per Seed gezogenen nächsten lebenden Nachbarn; Sieg lebend bei allen anderen infiziert.
##   Prophet des Untergangs: Markierungen in Nacht 1 (`prophet_marks`), dauerhaft freigeschaltet, sobald alle
##     tot sind (`prophet_unlocked`); Sieg statt des Dorfes (WinRules).
##   Todesprediger: Vorhersage (`prophecies`); Tod zur vorhergesagten Phase → `preacher_wins`.
## Feuerteufel (Teil 2, E-05 bis E-11): höchstens eine Markierung je Feuerteufel (`fire_marks`), jede Nacht neu
##   oder behalten; sie erlischt mit dem Tod des Ziels, dem Tod oder Rollenverlust des Feuerteufels. Jeder
##   tatsächliche Tod eines markierten Ziels (mit Todesfolgen) verbrennt einmal dessen nächste lebende Nachbarn
##   ohne Feuerteufel (`CAUSE_BURN`); Mitsieg lebender Feuerteufel bei jedem erkannten Sieg (WinRules).
## Voodoo-Priester (Teil 3, E-12 bis E-15, E-20 bis E-23): höchstens eine lebende Puppe je Priester (`voodoo_dolls`);
##   die Umlenkung selbst steht in KillPipeline; Sieg allein lebend bei höchstens drei Lebenden.
## Einzelsiegrollen sind weder blockierbar (RM-DR-010) noch vom Fluch des Weisen betroffen.


static func _others_alive(s: GameState, id: int) -> Array[int]:
	var ids := s.alive_ids()
	ids.erase(id)
	return ids


static func charmed_by(s: GameState, piper_id: int) -> Array[int]:
	var out: Array[int] = []
	for c: Dictionary in s.charms:
		if int(c["piper_id"]) == piper_id:
			out.append(int(c["target_id"]))
	return out


## Rattenfänger: andere Lebende, die er noch nicht verzaubert hat.
static func charm_targets(s: GameState, piper_id: int) -> Array[int]:
	var done := charmed_by(s, piper_id)
	return _others_alive(s, piper_id).filter(func(id: int) -> bool: return not done.has(id))


static func piper_wins(s: GameState, id: int) -> bool:
	var p: Player = s.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.RATTENFAENGER and not _others_alive(s, id).is_empty() and charm_targets(s, id).is_empty()


## Pestbringerin: andere Lebende, die noch nicht infiziert sind.
static func pest_targets(s: GameState, id: int) -> Array[int]:
	return _others_alive(s, id).filter(func(o: int) -> bool: return not s.infected.has(o))


static func pest_wins(s: GameState, id: int) -> bool:
	var p: Player = s.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.PESTBRINGERIN and not _others_alive(s, id).is_empty() and pest_targets(s, id).is_empty()


static func infect(s: GameState, id: int) -> void:
	if not s.infected.has(id):
		s.infected.append(id)
		s.infected.sort()


## Zu Beginn der Morgenauflösung: jede lebende Infizierte steckt einen gezogenen nächsten lebenden Nachbarn an.
static func spread(ctx: RuleContext) -> void:
	var s := ctx.state
	for id: int in s.infected.duplicate():
		if not s.players[id].alive:
			continue
		var neighbours := Seats.living_neighbours(s, id)
		if neighbours.is_empty():
			continue
		var target := neighbours[s.rng.next_int(0, neighbours.size() - 1)]
		var fresh := not s.infected.has(target)
		infect(s, target)
		ctx.emit(GameEvent.PLAGUE_SPREAD, Visibility.GM, {"from_id": id, "target_id": target, "new": fresh, "night": s.night_number})


static func prophet_marks_of(s: GameState, prophet_id: int) -> Array[int]:
	var out: Array[int] = []
	for m: Dictionary in s.prophet_marks:
		if int(m["prophet_id"]) == prophet_id:
			out.append(int(m["target_id"]))
	return out


## Nacht 1 ohne Markierungen: markieren; freigeschaltet: töten; sonst kein Schritt.
static func prophet_marking(s: GameState, id: int) -> bool:
	return s.night_number == 1 and prophet_marks_of(s, id).is_empty() and not s.prophet_unlocked.has(id)


static func prophet_wins(s: GameState, id: int) -> bool:
	var p: Player = s.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.PROPHET and s.prophet_unlocked.has(id)


static func prophecy_of(s: GameState, preacher_id: int) -> Dictionary:
	for q: Dictionary in s.prophecies:
		if int(q["preacher_id"]) == preacher_id:
			return q
	return {}


## Todesprediger: nur künftige Phasen (Tag N folgt auf Nacht N; die laufende Nacht zählt nicht).
static func validate_prediction(s: GameState, value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var kind := DictRead.get_string(value, "kind")
	var number := DictRead.get_int(value, "number", -1)
	if kind == "night":
		return number > s.night_number and number <= 999
	return kind == "day" and number >= s.night_number and number <= 999


## Nach jedem Tod: Freischaltung von Propheten (Zustand, auch ohne Todesfolgen) und Vorhersage des Todespredigers.
static func on_death(ctx: RuleContext, target: Player, record: KillEvent, trigger_effects: bool) -> void:
	var s := ctx.state
	for id: int in s.players:
		if s.prophet_unlocked.has(id):
			continue
		var marks := prophet_marks_of(s, id)
		if marks.size() == RoleCatalog.PROPHET_MARKS and marks.all(func(m: int) -> bool: return not s.players[m].alive):
			s.prophet_unlocked.append(id)
			s.prophet_unlocked.sort()
			ctx.emit(GameEvent.PROPHET_UNLOCKED, Visibility.GM, {"prophet_id": id})
	if not trigger_effects or target.role_id != RoleCatalog.TODESPREDIGER or s.preacher_wins.has(target.id):
		return
	var q := prophecy_of(s, target.id)
	if q.is_empty():
		return
	var kind := "night" if (record.phase == Phase.NIGHT or record.phase == Phase.DAWN_RESOLUTION) else ("day" if record.phase == Phase.DAY else "")
	if kind == String(q["kind"]) and record.phase_number == int(q["number"]):
		s.preacher_wins.append(target.id)
		s.preacher_wins.sort()
		ctx.emit(GameEvent.PREACHER_FULFILLED, Visibility.GM, {"player_id": target.id, "kind": kind, "number": record.phase_number})

# --- Feuerteufel ----------------------------------------------------------------------------------

## Andere Lebende, die ein Feuerteufel markieren kann (RM-DR-131.6).
static func fire_targets(s: GameState, devil_id: int) -> Array[int]:
	return _others_alive(s, devil_id)


static func fire_mark_of(s: GameState, devil_id: int) -> int:
	for m: Dictionary in s.fire_marks:
		if int(m["devil_id"]) == devil_id:
			return int(m["target_id"])
	return GameState.NO_TARGET


## Setzt die einzige Markierung eines Feuerteufels (ersetzt eine bestehende), aufsteigend nach devil_id.
static func set_fire_mark(s: GameState, devil_id: int, target_id: int) -> void:
	drop_fire_mark(s, devil_id)
	s.fire_marks.append({"devil_id": devil_id, "target_id": target_id})
	s.fire_marks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["devil_id"]) < int(b["devil_id"]))


## Markierung eines Feuerteufels erlischt (Tod oder Rollenverlust, RM-DR-131.7).
static func drop_fire_mark(s: GameState, devil_id: int) -> void:
	s.fire_marks = s.fire_marks.filter(func(m: Dictionary) -> bool: return int(m["devil_id"]) != devil_id)


## Lebende Feuerteufel als Mitsieger jedes erkannten Siegs (RM-DR-131.5), aufsteigend.
static func fire_co_winners(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.alive_ids():
		if s.players[id].role_id == RoleCatalog.FEUERTEUFEL:
			out.append(id)
	out.sort()
	return out


## Nach jedem Tod: Die Markierung des Toten als Feuerteufel erlischt; alle Markierungen auf ihm sind verbraucht.
## Nur mit Todesfolgen brennt es genau einmal (RM-DR-131.1, .8): die nächsten lebenden Nachbarn ohne Feuerteufel
## (RM-DR-131.3, .4), im Uhrzeigersinn zuerst; Quelle ist der Feuerteufel mit der kleinsten ID.
static func fire_on_death(ctx: RuleContext, target: Player, trigger_effects: bool) -> void:
	var s := ctx.state
	drop_fire_mark(s, target.id)
	var devils: Array[int] = []
	for m: Dictionary in s.fire_marks:
		if int(m["target_id"]) == target.id:
			devils.append(int(m["devil_id"]))
	if devils.is_empty():
		return
	s.fire_marks = s.fire_marks.filter(func(m: Dictionary) -> bool: return int(m["target_id"]) != target.id)
	if not trigger_effects:
		return
	var victims := Seats.living_neighbours(s, target.id).filter(func(id: int) -> bool: return s.players[id].role_id != RoleCatalog.FEUERTEUFEL)
	ctx.emit(GameEvent.FIRE_BURNED, Visibility.GM, {"target_id": target.id, "devil_ids": devils, "victim_ids": victims})
	for id: int in victims:
		KillPipeline.request_kill(ctx, id, KillEvent.CAUSE_BURN, KillEvent.SOURCE_PLAYER, devils[0])

# --- Voodoo-Priester ------------------------------------------------------------------------------

## Lebende Puppe eines Priesters oder NO_TARGET.
static func doll_of(s: GameState, priest_id: int) -> int:
	for d: Dictionary in s.voodoo_dolls:
		if int(d["priest_id"]) == priest_id:
			return int(d["doll_id"])
	return GameState.NO_TARGET


static func give_doll(s: GameState, priest_id: int, doll_id: int) -> void:
	drop_priest_doll(s, priest_id)
	s.voodoo_dolls.append({"priest_id": priest_id, "doll_id": doll_id})
	s.voodoo_dolls.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["priest_id"]) < int(b["priest_id"]))


## Puppe eines Priesters endet (Verbrauch, Tod oder Rollenverlust des Priesters, RM-DR-132.6, .8).
static func drop_priest_doll(s: GameState, priest_id: int) -> void:
	s.voodoo_dolls = s.voodoo_dolls.filter(func(d: Dictionary) -> bool: return int(d["priest_id"]) != priest_id)


## Nach jedem Tod: Stirbt ein Priester oder eine Puppe, enden die betroffenen Puppen.
static func voodoo_on_death(s: GameState, dead_id: int) -> void:
	s.voodoo_dolls = s.voodoo_dolls.filter(func(d: Dictionary) -> bool: return int(d["priest_id"]) != dead_id and int(d["doll_id"]) != dead_id)


static func voodoo_wins(s: GameState, id: int) -> bool:
	var p: Player = s.players.get(id)
	return p != null and p.alive and p.role_id == RoleCatalog.VOODOO and s.alive_ids().size() <= RoleCatalog.VOODOO_MAX_LIVING


# --- Nekromant ------------------------------------------------------------------------------------

## Tote, die noch nicht geopfert wurden (gemeinsamer Vorrat, E-18, E-24), aufsteigend.
static func necro_pool(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.players:
		if not s.players[id].alive and not s.necro_sacrificed.has(id):
			out.append(id)
	out.sort()
	return out


## Rudelangriff dieser Nacht auf den Nekromanten, der ihn sonst töten würde (E-17, E-26): "pack", "pack2" oder "".
static func necro_attack_slot(s: GameState, necro_id: int) -> String:
	var p := s.players[necro_id]
	for slot: Array in [["pack", s.pack_target_id, s.plague_pierce_pending], ["pack2", s.pack_extra_target_id, true]]:
		if int(slot[1]) != necro_id:
			continue
		if KillPipeline.pack_protection(s, necro_id, bool(slot[2])) != &"" or KillPipeline.survives_any_death(s, p):
			return ""
		if not s.necro_shields.is_empty() or StepQueue.is_marked(s, necro_id):
			return ""
		if s.shadow_links.any(func(l: Dictionary) -> bool: return (int(l["walker_id"]) == necro_id and s.players[int(l["partner_id"])].alive) or (int(l["partner_id"]) == necro_id and s.players[int(l["walker_id"])].alive)):
			return ""
		return String(slot[0])
	return ""


## Andere Lebende als Umlenkziel.
static func necro_redirect_targets(s: GameState, necro_id: int) -> Array[int]:
	return _others_alive(s, necro_id)


## Ungenutzte Schilde eines Nekromanten erlöschen mit seinem Tod oder Rollenverlust (E-27).
static func necro_drop_shields(s: GameState, necro_id: int) -> void:
	s.necro_shields = s.necro_shields.filter(func(sh: Dictionary) -> bool: return int(sh["necro_id"]) != necro_id)


static func necro_sacrifice(s: GameState, dead: Array[int]) -> void:
	for id: int in dead:
		if not s.necro_sacrificed.has(id):
			s.necro_sacrificed.append(id)
	s.necro_sacrificed.sort()


static func necro_shield(ctx: RuleContext, necro_id: int, dead: Array[int]) -> void:
	var s := ctx.state
	necro_sacrifice(s, dead)
	s.necro_shields.append({"necro_id": necro_id, "night": s.night_number})
	ctx.emit(GameEvent.NECRO_SHIELD, Visibility.GM, {"necro_id": necro_id, "dead_ids": dead.duplicate(), "night": s.night_number})


static func necro_redirect(ctx: RuleContext, necro_id: int, dead: Array[int], target_id: int) -> void:
	var s := ctx.state
	necro_sacrifice(s, dead)
	var slot := necro_attack_slot(s, necro_id)
	if slot == "pack2":
		s.pack_extra_target_id = target_id
		s.pack_extra_redirect_from = necro_id
	else:
		s.pack_target_id = target_id
		s.pack_redirect_from = necro_id
	ctx.emit(GameEvent.NECRO_REDIRECTED, Visibility.GM, {"necro_id": necro_id, "dead_ids": dead.duplicate(), "target_id": target_id, "slot": slot, "night": s.night_number})


## Globaler Schild (E-16): verhindert den Tod, falls einer aktiv ist; der älteste wird verbraucht.
static func necro_shield_prevents(ctx: RuleContext, target_id: int, cause: StringName, source_kind: StringName) -> bool:
	var s := ctx.state
	if s.necro_shields.is_empty() or source_kind == KillEvent.SOURCE_GM:
		return false
	var shield: Dictionary = s.necro_shields.pop_front()
	ctx.emit(GameEvent.KILL_PREVENTED, Visibility.GM, {"target_id": target_id, "cause": cause, "source_kind": source_kind,
		"protection": RoleCatalog.NEKROMANT, "sources": [RoleCatalog.NEKROMANT], "necro_id": int(shield["necro_id"]), "night": s.night_number})
	return true


static func validate_name_wolf(s: GameState, p: Dictionary) -> StringName:
	var id := DictRead.get_int(p, "player_id", GameState.NO_TARGET)
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	if not s.players.has(id):
		return &"unknown_player"
	if not s.players[id].alive:
		return &"player_dead"
	if s.players[id].role_id != RoleCatalog.NEKROMANT:
		return &"not_necromancer"
	if int(s.necro_named.get(id, 0)) == s.day_number:
		return &"already_named_today"
	if not s.players.has(target) or target == id or not s.players[target].alive:
		return &"invalid_target"
	return &""


## Einmal je Tag, geheim; ein Treffer (zählt als Wolf, RM-DR-002.2) erfüllt den Alleinsieg dauerhaft (F-11).
static func name_wolf(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var id := int(p["player_id"])
	var target := int(p["target_id"])
	var hit := s.players[target].counts_as_wolf
	s.necro_named[id] = s.day_number
	if hit and not s.necro_wins.has(id):
		s.necro_wins.append(id)
		s.necro_wins.sort()
		s.win_check_pending = true
	ctx.emit(GameEvent.NECRO_NAMED, Visibility.GM, {"necro_id": id, "target_id": target, "hit": hit, "day": s.day_number})
