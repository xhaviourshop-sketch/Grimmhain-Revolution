class_name LogText
extends RefCounted
## Protokoll in Alltagssprache (Feedback 8): aus einem Ereignis und dem Zustand entsteht genau ein Satz, zum Beispiel
## „Nacht 1: Anna hat die Rolle Wolfskind.“ oder „Tag 2: Ben wurde hingerichtet.“ Nie ein Typname, eine Nummer, ein Schlüssel
## oder ein Feldname. Personen stehen mit ihrem Namen aus dem Zustand (Personen-ID ist die Identität, nie ein Sitzplatz).
## Reine Auswertung, ändert nichts. NUR für das Spielleiter-Protokoll und den Partiebericht (dort nach Sichtbarkeit gefiltert):
## Die Sätze nennen auch geheime Vorgänge (Rollen, Schutz, verdeckte Nominierungen). Öffentliche Ansichten bleiben bei ihren
## eigenen Positivlisten (MorningReport, GameReport „public“) und verwenden diese Klasse nicht.
##
## API:
##   LogText.line(event, state, when = "") -> String   ein Ereignis (GameEvent oder Wörterbuch aus event_log()) als Satz;
##                                                     `when` ist ein optionaler Zeitraum („Nacht 2“, siehe `when_of`).
##   LogText.lines(events, state) -> Array[String]     ganze Folge mit „Nacht N:“/„Tag N:“ vor jedem Satz; lässt technische
##                                                     und noch nicht beschriebene Ereignisse aus (kein Rauschen im Protokoll).
##   LogText.when_of(event) -> String                  „Nacht N“/„Tag N“ nach einem Phasenwechsel, sonst "".

## Ereignisse, die nur den Ablauf der App betreffen und im Protokoll nie erscheinen.
const _SILENT: Array[StringName] = [
	GameEvent.STEP_BEGUN, GameEvent.STEP_SKIPPED, GameEvent.STEP_DROPPED, GameEvent.NIGHT_STEP_SKIPPED, GameEvent.PROMPT_OPENED,
	GameEvent.PROMPT_ANSWERED, GameEvent.PROMPT_STAGE_ANSWERED, GameEvent.PROMPT_CANCELLED, GameEvent.REACTION_QUEUED,
	GameEvent.REACTION_RESOLVED, GameEvent.WIN_DETECTED, GameEvent.WIN_STATUS_PROVISIONAL, GameEvent.WIN_STATUS_FINAL,
	GameEvent.NOTICE_QUEUED, GameEvent.NOTICE_ACKED, GameEvent.NOTICE_DROPPED, GameEvent.ROLE_SHOWN_CONFIRMED,
]


static func line(event: Variant, state: GameState, when: String = "") -> String:
	var e := _dict(event)
	var text := _sentence(str(e.get("type", "")), e.get("data", {}) as Dictionary, state)
	if text == "":
		text = text_of("ui.log.unknown")
	return text_of("ui.log.with_when", {"when": when, "text": text}) if when != "" else text


static func lines(events: Array, state: GameState) -> Array[String]:
	var out: Array[String] = []
	var when := ""
	for raw: Variant in events:
		var e := _dict(raw)
		var now := when_of(e)
		if now != "":
			when = now
		var text := _sentence(str(e.get("type", "")), e.get("data", {}) as Dictionary, state)
		if text == "":
			continue
		out.append(text_of("ui.log.with_when", {"when": when, "text": text}) if when != "" else text)
	return out


static func when_of(event: Variant) -> String:
	var e := _dict(event)
	if str(e.get("type", "")) != String(GameEvent.PHASE_CHANGED):
		return ""
	var d := e.get("data", {}) as Dictionary
	match StringName(str(d.get("to", ""))):
		Phase.NIGHT:
			return text_of("ui.log.when.night", {"n": int(d.get("night_number", 0))})
		Phase.DAY:
			return text_of("ui.log.when.day", {"n": int(d.get("day_number", 0))})
	return ""


## Sätze, die auch der Partiebericht verwendet (eine Quelle für beide).
static func executed(name: String) -> String:
	return text_of("ui.log.line.executed", {"name": name})


static func no_execution() -> String:
	return text_of("ui.log.line.no_execution")


static func revived(name: String) -> String:
	return text_of("ui.log.line.revived", {"name": name})


## Tod mit Namen, auf Wunsch mit Rolle (Rollen-ID, "" ohne Rolle).
static func died(name: String, role_id: String = "") -> String:
	if role_id == "":
		return text_of("ui.log.line.died", {"name": name})
	return text_of("ui.log.line.died_role", {"name": name, "role": CockpitText.role_name(role_id)})


## Text zu einem Schlüssel; StringName-Werte gelten als Übersetzungsschlüssel.
static func text_of(key: String, values: Dictionary = {}) -> String:
	var text := str(TranslationServer.translate(key))
	if values.is_empty():
		return text
	var out := {}
	for k: Variant in values:
		var v: Variant = values[k]
		out[k] = str(TranslationServer.translate(String(v))) if v is StringName else v
	return text.format(out)


static func _dict(event: Variant) -> Dictionary:
	if event is GameEvent:
		return (event as GameEvent).to_dict()
	return event as Dictionary if event is Dictionary else {}


static func _name(s: GameState, d: Dictionary, field: String) -> String:
	var id := int(d.get(field, GameState.NO_TARGET))
	return s.players[id].name if s != null and s.players.has(id) else text_of("ui.log.someone")


## Satz zu einem Ereignis; "" für technische und noch nicht beschriebene Typen.
static func _sentence(type: String, d: Dictionary, s: GameState) -> String:
	if _SILENT.has(StringName(type)):
		return ""
	match StringName(type):
		GameEvent.GAME_STARTED:
			return text_of("ui.log.line.game_started", {"count": (d.get("player_ids", []) as Array).size()})
		GameEvent.ROLE_ASSIGNED:
			return text_of("ui.log.line.role_assigned", {"name": _name(s, d, "player_id"), "role": CockpitText.role_name(str(d.get("role_id", "")))})
		GameEvent.PHASE_CHANGED:
			match StringName(str(d.get("to", ""))):
				Phase.NIGHT:
					return text_of("ui.log.line.night_begins")
				Phase.DAY:
					return text_of("ui.log.line.day_begins")
				Phase.GAME_OVER:
					return text_of("ui.log.line.game_over")
			return ""
		GameEvent.SEAT_DIED:
			var cause := "ui.cause.%s" % str(d.get("cause", "")).to_lower()
			if CockpitText.has_key(cause):
				return text_of("ui.log.line.died_cause", {"name": _name(s, d, "target_id"), "cause": StringName(cause)})
			return died(_name(s, d, "target_id"))
		GameEvent.KILL_PREVENTED:
			return text_of("ui.log.line.saved", {"name": _name(s, d, "target_id")})
		GameEvent.PROTECTION_SET:
			return text_of("ui.log.line.protected", {"guardian": _name(s, d, "guardian_id"), "name": _name(s, d, "target_id")})
		GameEvent.NO_NIGHT_KILL:
			return text_of("ui.log.line.no_night_kill")
		GameEvent.NOMINATION_RECORDED:
			return text_of("ui.log.line.nominated", {"nominator": _name(s, d, "nominator_id"), "nominee": _name(s, d, "nominee_id")})
		GameEvent.JUDGE_NOMINATION_PUBLIC:
			return text_of("ui.log.line.nominated_hidden", {"nominee": _name(s, d, "nominee_id")})
		GameEvent.JUDGE_NOMINATED:
			return text_of("ui.log.line.judge_nominated", {"judge": _name(s, d, "judge_id"), "nominee": _name(s, d, "nominee_id")})
		GameEvent.EXECUTION_CONFIRMED:
			return executed(_name(s, d, "target_id"))
		GameEvent.EXECUTION_REDIRECTED:
			return text_of("ui.log.line.redirected", {"name": _name(s, d, "target_id"), "other": _name(s, d, "death_target_id")})
		GameEvent.NO_EXECUTION:
			return no_execution()
		GameEvent.DAY_ENDED:
			return text_of("ui.log.line.day_ended")
		GameEvent.PLAYER_REVIVED:
			return revived(_name(s, d, "player_id"))
		GameEvent.ROLE_CHANGED:
			return text_of("ui.log.line.role_changed", {"name": _name(s, d, "player_id"), "role": CockpitText.role_name(str(d.get("to", "")))})
		GameEvent.WOLF_CHILD_TRANSFORMED:
			return text_of("ui.log.line.wolf_child", {"name": _name(s, d, "child_id")})
		GameEvent.WIN_CONFIRMED:
			var side := str((d.get("winner", {}) as Dictionary).get("kind", "none"))
			return text_of("ui.log.line.win_confirmed", {"side": StringName("ui.cockpit.win.kind.%s" % (side if ["village", "wolves", "solo"].has(side) else "none"))})
		GameEvent.WIN_REJECTED:
			return text_of("ui.log.line.win_rejected")
		GameEvent.GM_CORRECTED:
			if int(d.get("target_id", GameState.NO_TARGET)) != GameState.NO_TARGET and s != null and s.players.has(int(d["target_id"])):
				return text_of("ui.log.line.corrected", {"name": _name(s, d, "target_id")})
			return text_of("ui.log.line.corrected_general")
	return ""
