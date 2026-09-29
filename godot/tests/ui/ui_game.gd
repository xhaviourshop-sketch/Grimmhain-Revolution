extends RefCounted
## Gemeinsamer Helfer der Oberflächentests zu DI-01 bis DI-09: baut Partien (Personen A, B, C … mit den IDs
## 1, 2, 3 …, Sitzreihenfolge 1 bis n) und spielt sie über GameSession mit den Daten der Cockpitkarte, ohne
## eigene Regel. Jeder Schritt ist genau eine Standardhandlung der nächsten Karte.


static func start(roles: Array, seed_value: int = 7, appearances: Dictionary = {}) -> Command:
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	var payload := {"round_id": "test-round", "seed": seed_value, "assignment": "manual", "players": Fixtures.players(roles.size()),
		"seat_order": Fixtures.identity_order(roles.size()), "roles": map}
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


static func session(roles: Array, seed_value: int = 7, appearances: Dictionary = {}) -> GameSession:
	var s := GameSession.new()
	var r := s.submit(start(roles, seed_value, appearances))
	assert(r.ok)
	return s


static func next_of(s: GameSession) -> Dictionary:
	return (s.cockpit_view() as Dictionary).get("next", {})


## Eine Standardhandlung der nächsten Karte. `answers`: {"<besitzer>/<stufe>": Zielliste oder bool} für gezielte Antworten.
## Liefert die Art der behandelten Karte oder "" bei Ablehnung.
static func step(s: GameSession, answers: Dictionary = {}) -> String:
	var next := next_of(s)
	var kind := str(next.get("kind", ""))
	var ok := true
	match kind:
		"start_night":
			ok = s.start_night().ok
		"begin_step":
			ok = s.begin_next_step().ok
		"notice":
			ok = s.ack_notice(int(next["notice_id"])).ok
		"end_night":
			ok = s.end_night().ok
		"day":
			ok = s.decide_execution(-1).ok
		"end_day":
			ok = s.end_day().ok
		"win_decision":
			ok = s.confirm_win(int((next["candidates"] as Array)[0]["id"])).ok
		"prompt":
			ok = _answer(s, next, answers)
		_:
			return ""
	return kind if ok else ""


static func _answer(s: GameSession, next: Dictionary, answers: Dictionary) -> bool:
	var key := "%s/%s" % [str(next["owner"]), str(next["stage"])]
	var planned: Variant = answers.get(key)
	match str(next["answer"]):
		"targets":
			if planned is Array:
				return s.answer_targets(planned).ok
			var counts: Array = next.get("counts", [])
			var n := int(counts[0]) if not counts.is_empty() else int(next["min"])
			return s.answer_targets((next["allowed_ids"] as Array).slice(0, n)).ok
		"choice":
			return s.answer_choice(bool(planned) if planned is bool else false).ok
		"ack":
			return s.answer_choice(true).ok
		"option":
			return s.answer_option(0).ok
	return false


## Spielt Standardhandlungen, bis `stop` für die nächste Karte wahr ist. Liefert false bei Ablehnung oder ohne Ende.
static func run_until(s: GameSession, stop: Callable, answers: Dictionary = {}, max_steps: int = 200) -> bool:
	for i: int in max_steps:
		if stop.call(next_of(s)):
			return true
		if step(s, answers) == "":
			return false
	return false


## Bis zur Tagesphase der laufenden Nacht (Karte „day“), ohne Hinrichtung und ohne weitere Wahl.
static func to_day(s: GameSession, answers: Dictionary = {}) -> bool:
	return run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "day", answers)


## Tag ohne Hinrichtung beenden und die nächste Nacht beginnen; hält vor der ersten Karte der Nacht.
static func to_next_night_first_card(s: GameSession) -> bool:
	if str(next_of(s).get("kind")) == "day" and not s.decide_execution(-1).ok:
		return false
	return s.end_day().ok and s.start_night().ok
