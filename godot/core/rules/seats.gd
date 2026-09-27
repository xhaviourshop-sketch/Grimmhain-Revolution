class_name Seats
extends RefCounted
## Sitznachbarschaft (RM-DR-003, DECISION-LOG „Rollenaudit · … Sitznachbarn“): Nachbarn sind die
## nächsten lebenden Personen im Uhrzeigersinn und gegen den Uhrzeigersinn in `seat_order`; tote
## Plätze werden übersprungen. Maßgeblich ist der Sitz, nicht die Personen-ID (G-ID-1).


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
