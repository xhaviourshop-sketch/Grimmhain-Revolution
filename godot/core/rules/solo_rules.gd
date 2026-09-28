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
