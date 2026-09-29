class_name MorningReport
extends RefCounted
## Morgenbericht der letzten Nacht aus den Ereignissen der Partie (Vertical Slice §4.6, DR-04).
## Getrennt in zwei Teile:
##   public   nur Werte aus einer Positivliste: Namen der Gestorbenen (Rolle nur mit der Setup-Option
##            `reveal_role_on_death`, und zwar die Rolle beim Tod aus `SeatDied`), Wiederbelebte und ausdrücklich öffentliche Hinweise
##            (Detektiv, Schutzgeist, eingefrorene Nacht, Glocken, Richter-Nominierung). Nie Ursache,
##            Quelle, Schutz oder andere Rollen.
##   private  aufgelöste Aktionen mit Gründen für die Spielleitung.
## Bereich: vom Beginn der letzten Nacht bis einschließlich des Befehls, mit dem der Tag begann
## (Glocken und Richter-Nominierung entstehen erst dabei).

## Ereignisse ohne eigenen Informationswert für den Bericht (Ablaufrauschen).
const QUIET_TYPES: Array[StringName] = [GameEvent.PHASE_CHANGED, GameEvent.PROMPT_OPENED, GameEvent.PROMPT_ANSWERED,
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
		entry["role_id"] = str(e.data["role_id"]) if s.reveal_role_on_death else ""
		out.append(entry)
	return out


static func _public(s: GameState, span: Array[GameEvent]) -> Dictionary:
	var deaths: Array = []
	var revived: Array = []
	var notices: Array = []
	for e: GameEvent in span:
		match e.type:
			GameEvent.SEAT_DIED:
				var entry := _person(s, int(e.data["target_id"]))
				entry["role_id"] = str(e.data["role_id"]) if s.reveal_role_on_death else ""
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
	return {"deaths": deaths, "revived": revived, "notices": notices, "reveal_roles": s.reveal_role_on_death}


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
			_:
				out.append({"key": "", "type": String(e.type), "data": d.duplicate(true)})
	return out


## Nachtschritt-ID "night:<n>:<i>:<schritt>[:<person>]" → Rolle bzw. Gruppe des Schritts.
static func _step_role(step_id: String) -> String:
	var parts := step_id.split(":")
	if parts.size() >= 4 and parts[0] == "night":
		return "pack" if parts[3] == "pack2" else parts[3]
	return "reaction" if step_id.begins_with("reaction:") else ""


static func _person(s: GameState, id: int) -> Dictionary:
	return PromptView.person_label(s, id)
