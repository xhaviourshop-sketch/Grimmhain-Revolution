class_name GameReport
extends RefCounted
## Abschlussbericht einer beendeten Partie (Paket D) aus Zustand und Ereignissen. Reine Auswertung: kein Befehl, kein Zufall,
## keine neue Regel und keine Rekonstruktion durch eigene Regeln; es werden nur vorhandene Ereignisse und die vorhandenen
## Positivlisten (MorningReport, DeathEffect, Nominierungen) gelesen. Ergebnis ist ein Wörterbuch aus einfachen Werten
## (JSON-tauglich, ohne Übersetzung), das erst beim Anzeigen und Exportieren in eine Sprache gesetzt wird (ReportText):
##   game_id, players, names (Sitzreihenfolge), nights, days, revival_round,
##   winner {side, reason_key, reason_args, names, co_names}  (die Einzelheiten nur in der Spielleiterfassung),
##   roles [{seat, name, role_id, original_role_id, alive}]   (nur Spielleiterfassung),
##   entries [{vis: "public"|"gm", kind, ...}] in zeitlicher Reihenfolge.
## Öffentlich sind nur Angaben, die die Partie ohnehin am Tisch bekannt gemacht hat: Namen, Nächte und Tage, Nominierungen
## (ohne den Nominierenden einer Richter-Nominierung), Hinrichtungen, Tode (Rolle nur in Runden ohne Wiederbelebung, und zwar
## die Rolle beim Tod), angesagte Todeseffekte, ausdrücklich öffentliche Hinweise und die Siegseite. Ob Siegbedingung,
## Gewinnernamen und Rollen aller Personen nach dem Spielende öffentlich werden, ist nicht entschieden und wird deshalb
## ausgelassen (NQ-07); sie stehen nur im Spielleiterbericht. Eine Spielzeit wird nicht erfasst und deshalb nie behauptet.

const VERSION := 1


## Leer, solange kein Sieg bestätigt ist.
static func build(s: GameState, events: Array[GameEvent]) -> Dictionary:
	var winner := s.winner()
	if s.phase != Phase.GAME_OVER or winner == null:
		return {}
	var names: Array = []
	for id: int in s.seat_order:
		names.append(s.players[id].name)
	var roles: Array = []
	for i: int in s.seat_order.size():
		var p: Player = s.players[s.seat_order[i]]
		roles.append({"seat": i + 1, "name": p.name, "role_id": String(p.role_id), "original_role_id": String(p.original_role_id), "alive": p.alive})
	var entries: Array = []
	var other := 0
	var i := 0
	while i < events.size():
		var e := events[i]
		if e.type != GameEvent.PHASE_CHANGED or StringName(str(e.data.get("to"))) != Phase.NIGHT:
			i += 1
			continue
		var night := int(e.data.get("night_number", 0))
		var day_at := _next_phase(events, i + 1, Phase.DAY)
		var last := events.size() - 1
		if day_at != -1:
			last = day_at
			while last + 1 < events.size() and events[last + 1].command_index == events[day_at].command_index:
				last += 1
		var span := events.slice(i, last + 1)
		entries.append({"vis": "public", "kind": "night", "number": night})
		entries.append({"vis": "public", "kind": "morning", "night": night, "report": MorningReport.public_of(s, span)})
		var private_lines: Array = []
		for line: Dictionary in MorningReport.private_of(s, span):
			if str(line.get("key", "")) == "":
				if str(line.get("type", "")) != String(GameEvent.GM_CORRECTED):
					other += 1  # technische Einzelereignisse: nicht als rohe Daten im Bericht (Korrekturen stehen eigens im Bericht)
			else:
				private_lines.append(line)
		if not private_lines.is_empty():
			entries.append({"vis": "gm", "kind": "night_private", "night": night, "lines": private_lines})
		_corrections(s, span, entries)
		var next_night := _next_phase(events, last + 1, Phase.NIGHT)
		var day_end := next_night if next_night != -1 else events.size()
		if day_at != -1:
			entries.append({"vis": "public", "kind": "day", "number": int(events[day_at].data.get("day_number", 0))})
			_day(s, events.slice(last + 1, day_end), entries)
		i = day_end
	entries.append({"vis": "public", "kind": "win", "side": String(winner.kind)})
	var names_of := func(ids: Array[int]) -> Array:
		var out: Array = []
		for id: int in ids:
			out.append(s.players[id].name if s.players.has(id) else "")
		return out
	return {
		"version": VERSION,
		"game_id": s.round_id,
		"players": s.players.size(),
		"names": names,
		"nights": s.night_number,
		"days": s.day_number,
		"revival_round": s.revival_round,
		"winner": {"side": String(winner.kind), "reason_key": String(winner.reason_key), "reason_args": winner.reason_args.duplicate(true),
			"names": names_of.call(winner.beneficiary_ids), "co_names": names_of.call(winner.co_winner_ids)},
		"roles": roles,
		"other_events": other,
		"entries": entries,
	}


static func _next_phase(events: Array[GameEvent], from: int, to: StringName) -> int:
	for i: int in range(from, events.size()):
		if events[i].type == GameEvent.PHASE_CHANGED and StringName(str(events[i].data.get("to"))) == to:
			return i
	return -1


## Ereignisse eines Tages nach der Morgenansage bis zur nächsten Nacht.
static func _day(s: GameState, span: Array[GameEvent], entries: Array) -> void:
	for e: GameEvent in span:
		var d := e.data
		match e.type:
			GameEvent.NOMINATION_RECORDED:
				entries.append({"vis": "public", "kind": "nomination", "nominator": _name(s, int(d["nominator_id"])), "nominee": _name(s, int(d["nominee_id"]))})
			GameEvent.JUDGE_NOMINATION_PUBLIC:
				entries.append({"vis": "public", "kind": "nomination_hidden", "nominee": _name(s, int(d["nominee_id"]))})
			GameEvent.JUDGE_NOMINATED:
				entries.append({"vis": "gm", "kind": "judge_nominator", "judge": _name(s, int(d["judge_id"])), "nominee": _name(s, int(d["nominee_id"]))})
			GameEvent.EXECUTION_CONFIRMED:
				entries.append({"vis": "public", "kind": "execution", "name": _name(s, int(d["target_id"]))})
				if bool(d.get("gm_override", false)):
					entries.append({"vis": "gm", "kind": "execution_override", "name": _name(s, int(d["target_id"]))})
			GameEvent.NO_EXECUTION:
				entries.append({"vis": "public", "kind": "no_execution"})
			GameEvent.EXECUTION_REDIRECTED:
				entries.append({"vis": "gm", "kind": "execution_redirected", "name": _name(s, int(d["target_id"])), "other": _name(s, int(d["death_target_id"]))})
			GameEvent.SEAT_DIED:
				entries.append({"vis": "public", "kind": "death", "name": _name(s, int(d["target_id"])), "role_id": str(d["role_id"]) if not s.revival_round else ""})
				entries.append({"vis": "gm", "kind": "death_cause", "name": _name(s, int(d["target_id"])), "cause": str(d["cause"]), "role_id": str(d["role_id"])})
			GameEvent.PLAYER_REVIVED:
				entries.append({"vis": "public", "kind": "revived", "name": _name(s, int(d["player_id"]))})
	var effects := MorningReport.effects_of(s, span)
	if not effects.is_empty():
		entries.append({"vis": "public", "kind": "effects", "effects": effects})
	_corrections(s, span, entries)


static func _corrections(s: GameState, span: Array[GameEvent], entries: Array) -> void:
	for e: GameEvent in span:
		if e.type == GameEvent.GM_CORRECTED:
			var d := e.data
			entries.append({"vis": "gm", "kind": "correction", "what": str(d.get("kind", "")), "name": _name(s, int(d.get("target_id", GameState.NO_TARGET))), "reason": str(d.get("reason", ""))})
		elif e.type == GameEvent.WIN_REJECTED:
			entries.append({"vis": "gm", "kind": "win_rejected", "reason": str(e.data.get("reason", ""))})


static func _name(s: GameState, id: int) -> String:
	return s.players[id].name if s.players.has(id) else ""
