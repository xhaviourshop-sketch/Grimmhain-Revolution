class_name SoloRules
extends RefCounted
## Einzelsiegrollen, Teil 1 (DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“, 28.09.2026):
##   Rattenfänger: Verzauberungen je Rattenfänger (`charms`); Sieg lebend bei allen anderen verzaubert.
##   Pestbringerin: Infektionen (`infected`, gemeinsam), Ausbreitung zu Beginn jeder Morgenauflösung auf einen
##     per Seed gezogenen nächsten lebenden Nachbarn; Sieg lebend bei allen anderen infiziert.
##   Prophet des Untergangs: Markierungen in Nacht 1 (`prophet_marks`), dauerhaft freigeschaltet, sobald alle
##     tot sind (`prophet_unlocked`); Sieg statt des Dorfes (WinRules).
##   Todesprediger: Vorhersage (`prophecies`); Tod zur vorhergesagten Phase → `preacher_wins`.
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
