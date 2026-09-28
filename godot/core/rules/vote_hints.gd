class_name VoteHints
extends RefCounted
## Stimmhinweise für die Spielleiteransicht (DECISION-LOG „Querschnittsfragen“, RM-DR-008): Stimmen
## werden nicht digital gezählt; der Kern berechnet nur, welche Boni der Spielleiter bei der
## physischen Zählung einrechnen soll. Reine Abfrage ohne Zustandsänderung, nur für den Spielleiter.
##   Blutwolf: +1 je direkt benachbartem toten Platz, solange er lebt.
##   Korrupter Richter: +1 auf die heute von ihm nominierte lebende Person.


## [{player_id, bonus, source_role, source_id}] aufsteigend nach Personen-ID.
static func hints(s: GameState) -> Array:
	var out: Array = []
	var n := s.seat_order.size()
	for id: int in s.alive_ids():
		if s.players[id].role_id != RoleCatalog.BLUTWOLF:
			continue
		var seat := s.seat_order.find(id)
		var dead := 0
		for step: int in [1, -1]:
			var neighbour := s.seat_order[posmod(seat + step, n)]
			if neighbour != id and not s.players[neighbour].alive:
				dead += 1
		if dead > 0:
			out.append({"player_id": id, "bonus": dead, "source_role": String(RoleCatalog.BLUTWOLF), "source_id": id})
	for nom: Nomination in s.nominations_on_day(s.day_number):
		if nom.by_judge and s.players[nom.nominee_id].alive:
			out.append({"player_id": nom.nominee_id, "bonus": 1, "source_role": String(RoleCatalog.KORRUPTER_RICHTER), "source_id": nom.nominator_id})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["player_id"]) < int(b["player_id"]))
	return out
