class_name Seats
extends RefCounted
## Sitznachbarschaft (RM-DR-003, DECISION-LOG „Rollenaudit · … Sitznachbarn“): Nachbarn sind die
## nächsten lebenden Personen im Uhrzeigersinn und gegen den Uhrzeigersinn in `seat_order`; tote
## Plätze werden übersprungen. Maßgeblich ist der Sitz, nicht die Personen-ID (G-ID-1).


## Nächste lebende Person, die als Wolf zählt, je Richtung mit Abstand in Sitzen einschließlich
## toter Plätze (Ritter, Fährtenleser): {"cw": ID oder −1, "cw_dist": n, "ccw": ID oder −1, "ccw_dist": n}.
## „Links“ aus Sicht der Person am Tisch ist der Uhrzeigersinn (`cw`, RM-DR-146.1).
static func nearest_wolves(s: GameState, player_id: int) -> Dictionary:
	var out := {"cw": -1, "cw_dist": 0, "ccw": -1, "ccw_dist": 0}
	var start := s.seat_order.find(player_id)
	var n := s.seat_order.size()
	if start == -1:
		return out
	for dir: Array in [[1, "cw"], [-1, "ccw"]]:
		for k: int in range(1, n):
			var id := s.seat_order[posmod(start + int(dir[0]) * k, n)]
			if id != player_id and s.players[id].alive and s.players[id].counts_as_wolf:
				out[dir[1]] = id
				out[String(dir[1]) + "_dist"] = k
				break
	return out


## Die nächsten Wölfe (einer oder bei Gleichstand zwei), leer ohne lebenden Wolf.
static func closest_wolves(s: GameState, player_id: int) -> Array[int]:
	var w := nearest_wolves(s, player_id)
	var out: Array[int] = []
	var cw: int = w["cw"]
	var ccw: int = w["ccw"]
	if cw == -1 and ccw == -1:
		return out
	if ccw == -1 or (cw != -1 and int(w["cw_dist"]) < int(w["ccw_dist"])):
		out.append(cw)
	elif cw == -1 or int(w["ccw_dist"]) < int(w["cw_dist"]):
		out.append(ccw)
	else:
		out.append(cw)
		if ccw != cw:
			out.append(ccw)
	out.sort()
	return out


## Richtung des nächsten Wolfs für den Fährtenleser: "left" (Uhrzeigersinn), "right", "equal" oder "none".
static func wolf_direction(s: GameState, player_id: int) -> String:
	var w := nearest_wolves(s, player_id)
	if int(w["cw"]) == -1 and int(w["ccw"]) == -1:
		return "none"
	if int(w["ccw"]) == -1 or (int(w["cw"]) != -1 and int(w["cw_dist"]) < int(w["ccw_dist"])):
		return "left"
	if int(w["cw"]) == -1 or int(w["ccw_dist"]) < int(w["cw_dist"]):
		return "right"
	return "equal"


## [nächste lebende Person im Uhrzeigersinn, gegen den Uhrzeigersinn] ohne `player_id`, ohne
## Doppelte (bei nur einer anderen lebenden Person genau ein Eintrag), leer ohne andere Lebende.
static func living_neighbours(s: GameState, player_id: int) -> Array[int]:
	var out: Array[int] = []
	var start := s.seat_order.find(player_id)
	var n := s.seat_order.size()
	if start == -1:
		return out
	for step: int in [1, -1]:
		for k: int in range(1, n):
			var id := s.seat_order[posmod(start + step * k, n)]
			if id != player_id and s.players[id].alive:
				if not out.has(id):
					out.append(id)
				break
	return out
