class_name MorningReport
extends RefCounted
## Morgenbericht der letzten Nacht aus den Ereignissen der Partie (Vertical Slice §4.6, DR-04).
## Getrennt in zwei Teile:
##   public   nur Werte aus einer Positivliste: Namen der Gestorbenen (Rolle nur mit der Setup-Option
##            Runden ohne Wiederbelebung, und zwar die Rolle beim Tod aus `SeatDied`), Wiederbelebte, angesagte
##            Todeseffekte (`DeathEffect`, DI-03, mit Rolle zum Ereigniszeitpunkt) und ausdrücklich öffentliche Hinweise
##            (Detektiv, Schutzgeist, eingefrorene Nacht, Glocken, Richter-Nominierung). Nie Ursache,
##            Quelle, Schutz oder andere Rollen.
##   private  aufgelöste Aktionen mit Gründen für die Spielleitung.
## Bereich: vom Beginn der letzten Nacht bis einschließlich des Befehls, mit dem der Tag begann
## (Glocken und Richter-Nominierung entstehen erst dabei).

## Ereignisse ohne eigenen Informationswert für den Bericht (Ablaufrauschen).
const QUIET_TYPES: Array[StringName] = [GameEvent.DEATH_EFFECT, GameEvent.NOTICE_QUEUED, GameEvent.NOTICE_ACKED, GameEvent.NOTICE_DROPPED, GameEvent.PHASE_CHANGED, GameEvent.PROMPT_OPENED, GameEvent.PROMPT_ANSWERED,
	GameEvent.PROMPT_STAGE_ANSWERED, GameEvent.STEP_BEGUN, GameEvent.WIN_STATUS_PROVISIONAL, GameEvent.WIN_STATUS_FINAL,
	GameEvent.KILL_IGNORED, GameEvent.REACTION_QUEUED]


static func build(s: GameState, events: Array[GameEvent]) -> Dictionary:
	if s.phase != Phase.DAY and s.phase != Phase.DAWN_RESOLUTION:
		return {}
	var night_at := -1
	var day_at := -1
	for i: int in range(events.size() - 1, -1, -1):
		var e := events[i]
		if e.type != GameEvent.PHASE_CHANGED:
			continue
		var to := StringName(str(e.data.get("to")))
		if to == Phase.DAY and day_at == -1:
			day_at = i
		elif to == Phase.NIGHT:
			night_at = i
			break
	if night_at == -1:
		return {}
	var last := events.size() - 1
	if day_at != -1:
		last = day_at
		while last + 1 < events.size() and events[last + 1].command_index == events[day_at].command_index:
			last += 1
	var span := events.slice(night_at, last + 1)
	return {
		"night_number": int(events[night_at].data.get("night_number", 0)),
		"complete": day_at != -1,
		"public": _public(s, span),
		"private": _private(s, span),
	}


## Öffentliche Tode des laufenden Tages (nach dem Befehl, mit dem der Tag begann): Name, Platz und
## Rolle nur mit der Setup-Option. Für die Ansage nach Nominierung, Hinrichtung oder Reaktion.
static func day_deaths(s: GameState, events: Array[GameEvent]) -> Array:
	if s.phase != Phase.DAY:
		return []
	var start := -1
	for i: int in range(events.size() - 1, -1, -1):
		if events[i].type == GameEvent.PHASE_CHANGED and StringName(str(events[i].data.get("to"))) == Phase.DAY:
			start = i
			break
	if start == -1:
		return []
	var day_command := events[start].command_index
	var out: Array = []
	for i: int in range(start + 1, events.size()):
		var e := events[i]
		if e.command_index == day_command or e.type != GameEvent.SEAT_DIED:
			continue
		var entry := _person(s, int(e.data["target_id"]))
		entry["role_id"] = str(e.data["role_id"]) if not s.revival_round else ""
		out.append(entry)
	return by_seat(out)


## Öffentliche Kartenereignisse des laufenden Tages (nach dem Befehl, mit dem der Tag begann), in Ereignisreihenfolge.
static func day_cards(s: GameState, events: Array[GameEvent]) -> Array:
	if s.phase != Phase.DAY or not s.death_cards:
		return []
	var start := -1
	for i: int in range(events.size() - 1, -1, -1):
		if events[i].type == GameEvent.PHASE_CHANGED and StringName(str(events[i].data.get("to"))) == Phase.DAY:
			start = i
			break
	if start == -1:
		return []
	var day_command := events[start].command_index
	var span: Array[GameEvent] = []
	for i: int in range(start + 1, events.size()):
		if events[i].command_index != day_command and events[i].visibility == Visibility.PUBLIC:
			span.append(events[i])
	return CardView.public_lines(s, span)


## Öffentlich angesagte Todeseffekte des laufenden Tages (nach dem Befehl, mit dem der Tag begann), in Ereignisreihenfolge.
static func day_effects(s: GameState, events: Array[GameEvent]) -> Array:
	if s.phase != Phase.DAY:
		return []
	var start := -1
	for i: int in range(events.size() - 1, -1, -1):
		if events[i].type == GameEvent.PHASE_CHANGED and StringName(str(events[i].data.get("to"))) == Phase.DAY:
			start = i
			break
	if start == -1:
		return []
	var day_command := events[start].command_index
	var span: Array[GameEvent] = []
	for i: int in range(start + 1, events.size()):
		if events[i].command_index != day_command:
			span.append(events[i])
	return effects_of(s, span)


## Angesagte Todeseffekte aus den Ereignissen: nur die Positivliste (Effekt, Rolle, Quelle, Ziele, ersetzte Person).
## Mehrere Nachbarn desselben Kutscherunfalls erscheinen als eine Ansage mit mehreren Zielen.
static func effects_of(s: GameState, span: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in span:
		if e.type != GameEvent.DEATH_EFFECT:
			continue
		var d := e.data
		var effect := str(d["effect"])
		var source_id := int(d["source_id"])
		var target_id := int(d["target_id"])
		if not out.is_empty() and effect == "coachman_crash" and str(out.back()["effect"]) == effect and int(out.back()["source_id"]) == source_id:
			(out.back()["targets"] as Array).append(_person(s, target_id))
			continue
		out.append({"effect": effect, "role_id": str(d["role_id"]), "source_id": source_id,
			"source": _person(s, source_id) if source_id != GameState.NO_TARGET else {},
			"targets": [_person(s, target_id)] if target_id != GameState.NO_TARGET else [],
			"replaced": _person(s, int(d["replaced_id"])) if int(d["replaced_id"]) != GameState.NO_TARGET else {}})
	return out


## Öffentlicher und privater Teil für einen beliebigen Ereignisabschnitt (Abschlussbericht): dieselben Positivlisten wie der
## Morgenbericht, ohne den Bezug auf die letzte Nacht.
static func public_of(s: GameState, span: Array[GameEvent]) -> Dictionary:
	return _public(s, span)


static func private_of(s: GameState, span: Array[GameEvent]) -> Array:
	return _private(s, span)


static func _public(s: GameState, span: Array[GameEvent]) -> Dictionary:
	var deaths: Array = []
	var revived: Array = []
	var notices: Array = []
	for e: GameEvent in span:
		match e.type:
			GameEvent.SEAT_DIED:
				var entry := _person(s, int(e.data["target_id"]))
				entry["role_id"] = str(e.data["role_id"]) if not s.revival_round else ""
				deaths.append(entry)
			GameEvent.PLAYER_REVIVED:
				revived.append(_person(s, int(e.data["player_id"])))
			GameEvent.DETECTIVE_HINT:
				notices.append({"key": "ui.morning.notice.detective", "person": _person(s, int(e.data["anchor_id"])), "direction": str(e.data["direction"])})
			GameEvent.GHOST_WOLF_ALERT:
				notices.append({"key": "ui.morning.notice.ghost"})
			GameEvent.NIGHT_FROZEN:
				notices.append({"key": "ui.morning.notice.frozen"})
			GameEvent.ALARM_BELLS:
				notices.append({"key": "ui.morning.notice.bells"})
			GameEvent.JUDGE_NOMINATION_PUBLIC:
				notices.append({"key": "ui.morning.notice.judge", "person": _person(s, int(e.data["nominee_id"]))})
	return {"deaths": by_seat(deaths), "revived": revived, "notices": notices, "effects": effects_of(s, span), "reveal_roles": not s.revival_round,
		"cards": CardView.public_lines(s, span)}


static func _private(s: GameState, span: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in span:
		if QUIET_TYPES.has(e.type) or e.visibility == Visibility.ACTOR:
			continue
		var d := e.data
		match e.type:
			GameEvent.SEAT_DIED:
				out.append({"key": "ui.morning.private.death", "person": _person(s, int(d["target_id"])), "cause": str(d["cause"]),
					"role_id": str(d["role_id"])})
			GameEvent.KILL_PREVENTED:
				out.append({"key": "ui.morning.private.saved", "person": _person(s, int(d["target_id"])), "role_id": str(d.get("protection", ""))})
			GameEvent.NO_NIGHT_KILL:
				out.append({"key": "ui.morning.private.no_attack"})
			GameEvent.STEP_SKIPPED:
				out.append({"key": "ui.morning.private.step_skipped", "role_id": _step_role(str(d["step_id"])), "reason": str(d["reason"])})
			GameEvent.STEP_DROPPED:
				out.append({"key": "ui.morning.private.step_dropped", "role_id": _step_role(str(d["step_id"])), "drop": str(d["reason"])})
			GameEvent.REACTION_RESOLVED:
				out.append({"key": "ui.morning.private.reaction.%s" % str(d["outcome"]), "person": _person(s, int(d["owner_id"])),
					"target": _person(s, int(d["target_id"])) if int(d["target_id"]) != GameState.NO_TARGET else {}})
			GameEvent.ROLE_CHANGED, GameEvent.WOLF_CHILD_TRANSFORMED:
				var who := int(d.get("player_id", d.get("child_id", GameState.NO_TARGET)))
				out.append({"key": "ui.morning.private.role_changed", "person": _person(s, who), "role_id": String(s.players[who].role_id) if s.players.has(who) else ""})
			GameEvent.NIGHT_STEP_SKIPPED:
				out.append({"key": "ui.morning.private.step_dropped", "role_id": "pack", "drop": str(d["reason"])})
			GameEvent.LOKI_BOUND:
				var pair: Array = d["target_ids"]
				out.append({"key": "ui.morning.private.lovers" if str(d["kind"]) == "love" else "ui.morning.private.rivals",
					"person": _person(s, int(pair[0])), "target": _person(s, int(pair[1]))})
			GameEvent.CHARMED:
				for id: Variant in d["target_ids"]:
					out.append({"key": "ui.morning.private.charmed", "person": _person(s, int(id))})
			GameEvent.PROTECTION_SET:
				out.append({"key": "ui.morning.private.protected", "person": _person(s, int(d["target_id"]))})
			GameEvent.WOLF_POISONED:
				out.append({"key": "ui.morning.private.wolf_poisoned", "person": _person(s, int(d["target_id"]))})
			GameEvent.INFECTED:
				out.append({"key": "ui.morning.private.infected", "person": _person(s, int(d["target_id"]))})
			GameEvent.PARASITE_ATTACHED:
				if int(d["host_id"]) > 0:
					out.append({"key": "ui.morning.private.parasite_host", "person": _person(s, int(d["host_id"]))})
			GameEvent.VOODOO_DOLL_GIVEN:
				if int(d["doll_id"]) > 0:
					out.append({"key": "ui.morning.private.voodoo_doll", "person": _person(s, int(d["doll_id"]))})
			_:
				# Alle übrigen Ereignisse stehen im Protokoll; der Bericht nennt nur, was die Spielleitung am Morgen wissen muss,
				# und zeigt nie Rohdaten (Ereignisnamen, Schlüssel).
				out.append({"key": "", "type": String(e.type)})
	return out


## Nachtschritt-ID "night:<n>:<i>:<schritt>[:<person>]" → Rolle bzw. Gruppe des Schritts.
static func _step_role(step_id: String) -> String:
	var parts := step_id.split(":")
	if parts.size() >= 4 and parts[0] == "night":
		return "pack" if parts[3] == "pack2" else parts[3]
	return "reaction" if step_id.begins_with("reaction:") else ""


## Öffentliche Ansagen von Toten stehen nach Sitzplatz, nie in Auflösungsreihenfolge: Gift, Markierung und Rudel würden
## sonst die Todesursache verraten (DR-04, Audit S-01). Gleicher Platz bleibt stabil nach Personen-ID.
static func by_seat(entries: Array) -> Array:
	var out := entries.duplicate()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["seat"]) != int(b["seat"]):
			return int(a["seat"]) < int(b["seat"])
		return int(a["person_id"]) < int(b["person_id"]))
	return out


static func _person(s: GameState, id: int) -> Dictionary:
	return PromptView.person_label(s, id)
