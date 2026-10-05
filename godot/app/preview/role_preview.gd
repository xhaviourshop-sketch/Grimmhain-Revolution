class_name RolePreview
extends RefCounted
## Rollen-Vorschau (Einstellungen, Feedback 7): baut für eine Rolle eine Wegwerf-Partie mit 10 deutschen Vornamen und spielt sie mit
## einfachen Standardantworten über die echten Befehle der Sitzung, bis die Bildschirme der Rolle erreicht sind. Ergebnis sind Haltepunkte
## (`stops`): je Haltepunkt die Befehle bis dorthin und die Art des Bildschirms. Die Ansicht spielt die Befehle in eine eigene Sitzung
## ein und zeigt das echte Cockpit; nichts wird gespeichert. Keine Regel: zulässig ist, was der Regelkern annimmt.
##   night  Nachtkarte der Rolle (jede Stufe ihres Schritts, auch Hinweise der Rolle)
##   show   Fenster „Karte zeigen“ mit dem Ergebnis
##   morning Morgenbericht nach der Nacht der Rolle
##   day    Tageskarte
##   death  nach der Hinrichtung der Person mit der Rolle (Tageskarte mit Tod bzw. Reaktion der Rolle)

const NAMES: Array[String] = ["Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix", "Emma", "Lukas", "Sophie", "Ben"]
const VILLAGE_FILL: Array[String] = ["dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "der-weise",
	"waechter-am-tor", "ritter"]
const WOLF_FILL: Array[String] = ["werwolf", "blutwolf", "rudelvater"]
const PEOPLE := 10
const MAX_NIGHTS := 7
const SEED := 20261005
const MAX_ACTIONS := 600
## Rollen, deren Fähigkeit Hinrichtungen braucht: jeden Tag vor ihrem Schritt eine Hinrichtung (Dorf- bzw. Wolfsperson, nie die Rolle).
const EXECUTE_DAILY := {"henker": "village", "kopfgeldjaeger": "wolf"}
## Rollen, die erst als Tote handeln: zuerst die Hinrichtung, dann die Nächte.
const ACTS_DEAD: Array[String] = ["schutzgeist"]
## Rollen, die werdende Wölfe sind oder machen: ohne Wächter am Tor (wie die Testbesetzungen).
const BECOMES_WOLF: Array[String] = ["wolfskind", "lehrling", "koenig-lykaon", "kutscher", "seelentauscher"]


## Besetzung: Person 1 hat die Rolle (Die Gebundenen: Personen 1 und 2), dazu Wölfe und wirkungsarme Dorfrollen bis 10 Personen.
static func cast(role: String) -> Array[String]:
	var out: Array[String] = [role]
	if role == String(RoleCatalog.DIE_GEBUNDENEN):
		out.append(role)
	var wolves := 1 if RoleCatalog.counts_as_wolf(StringName(role)) else 2
	for w: String in WOLF_FILL:
		if wolves > 0 and not out.has(w):
			out.append(w)
			wolves -= 1
	for v: String in VILLAGE_FILL:
		if out.size() >= PEOPLE:
			break
		if out.has(v) or (v == "waechter-am-tor" and BECOMES_WOLF.has(role)):
			continue
		out.append(v)
	return out


static func holders(role: String) -> Array[int]:
	var out: Array[int] = [1]
	if role == String(RoleCatalog.DIE_GEBUNDENEN):
		out.append(2)
	return out


static func start_command(role: String) -> Command:
	var roles := cast(role)
	var players: Array = []
	var map := {}
	var order: Array[int] = []
	var appearances := {}
	for i: int in roles.size():
		players.append({"id": i + 1, "name": NAMES[i]})
		map[str(i + 1)] = roles[i]
		order.append(i + 1)
		if RoleCatalog.requires_appearance(StringName(roles[i])):
			appearances[str(i + 1)] = "waldhexe"
	var payload := {"round_id": "rollen-vorschau", "seed": SEED, "assignment": "manual", "players": players, "seat_order": order, "roles": map}
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


## Haltepunkte der Rolle: {stops: [{kind, commands}], gap: "" oder Grund (Schlüssel `ui.preview.gap.<grund>`)}.
static func plan(role: String) -> Dictionary:
	var s := GameSession.new()
	if not s.submit(start_command(role)).ok:
		return {"stops": [], "gap": "start"}
	var own := holders(role)
	var stops: Array = []
	var needs_night := SetupRoleCatalog.night_priority(StringName(role)) > 0
	var acted := false
	var died := false
	if ACTS_DEAD.has(role):
		_to_day(s, role, own)
		died = _execute(s, own[0])
		if died:
			stops.append(_stop("death", s))
	for i: int in MAX_ACTIONS:
		var next := effective(s)
		var kind := str(next.get("kind"))
		if kind in ["game_over", "win_decision", "none", ""]:
			break
		if kind == "prompt" and _mine(next, role, own):
			stops.append(_stop("night", s))
			if str(next.get("answer")) == "ack" and not (next.get("show", []) as Array).is_empty():
				stops.append(_stop("show", s))
			acted = true
			if not _answer(s, next, own, true):
				break
			continue
		if kind == "notice" and CockpitText.help_role(next) == role:
			stops.append(_stop("night", s))
		if kind == "day":
			var night := int((s.cockpit_view() as Dictionary).get("night_number", 0))
			if needs_night and not acted and night < MAX_NIGHTS and not died:
				_daily_execution(s, role, own)
				if not _next_night(s):
					break
				continue
			if died:
				stops.append(_stop("morning", s))
				stops.append(_stop("day", s))
				break
			stops.append(_stop("morning", s))
			stops.append(_stop("day", s))
			if _execute(s, own[0]):
				stops.append(_stop("death", s))
				var after := effective(s)
				if str(after.get("kind")) == "prompt" and _mine(after, role, own):
					stops.append(_stop("death", s))  # die Reaktion der Rolle auf ihren Tod
			break
		if not _default_step(s, next, own):
			break
	var gap := ""
	if stops.is_empty():
		gap = "unreached"
	elif needs_night and not acted:
		gap = "night"
	return {"stops": stops, "gap": gap}


## Nächste Handlung wie die Karte sie zeigt: ein Schritt mit Prompt-Vorschau gilt als offener Prompt.
static func effective(s: GameSession) -> Dictionary:
	var n: Dictionary = (s.cockpit_view() as Dictionary).get("next", {})
	if str(n.get("kind")) == "begin_step" and not (n.get("preview", {}) as Dictionary).is_empty():
		var pv: Dictionary = (n["preview"] as Dictionary).duplicate()
		pv["kind"] = "prompt"
		pv["needs_begin"] = true
		return pv
	return n


static func _stop(kind: String, s: GameSession) -> Dictionary:
	return {"kind": kind, "commands": s.commands().duplicate()}


static func _mine(n: Dictionary, role: String, own: Array[int]) -> bool:
	var owner := str(n.get("owner", ""))
	var actors: Array = n.get("actor_ids", [])
	if owner == "pack" or owner == "pack2":
		# Das Rudel ist der Schritt der Wölfe ohne eigenen Nachtschritt.
		return RoleCatalog.counts_as_wolf(StringName(role)) and SetupRoleCatalog.night_priority(StringName(role)) <= 0 and own.any(func(id: int) -> bool: return actors.has(id))
	if owner == "card" or owner == "kartenschlucker" and role != "kartenschlucker":
		return false
	return owner == role or own.any(func(id: int) -> bool: return actors.has(id))


## Standardhandlung für fremde Karten: das Rudel tötet eine Dorfperson (nie die Rolle), sonst Verzicht bzw. „Nein“.
static func _default_step(s: GameSession, next: Dictionary, own: Array[int]) -> bool:
	match str(next.get("kind")):
		"start_night":
			return s.start_night().ok
		"begin_step":
			return s.begin_next_step().ok
		"notice":
			return s.ack_notice(int(next["notice_id"])).ok
		"end_night":
			return s.end_night().ok
		"end_day":
			return s.end_day().ok
		"card_window":
			return s.card_close_window().ok
		"prompt":
			return _answer(s, next, own, false)
	return false


## Antwort auf einen Prompt; `mine`: die Rolle nutzt ihre Fähigkeit (Ja, Personen wählen), sonst möglichst Verzicht.
static func _answer(s: GameSession, next: Dictionary, own: Array[int], mine: bool) -> bool:
	if bool(next.get("needs_begin", false)) and not s.begin_next_step().ok:
		return false
	var allowed: Array = next.get("allowed_ids", [])
	match str(next.get("answer")):
		"targets":
			var counts: Array = next.get("counts", [])
			var want := 0
			for c: Variant in counts:
				if int(c) > 0:
					want = int(c)
					break
			var pack := str(next.get("owner")) in ["pack", "pack2"]
			if not mine and not pack and counts.has(0):
				return s.answer_targets([]).ok
			var picks: Array = allowed.filter(func(id: Variant) -> bool: return not own.has(int(id)))
			if pack:
				picks.reverse()  # das Rudel trifft die hinteren Dorfpersonen, die Rolle bleibt am Leben
			if picks.size() < want:
				picks = allowed.duplicate()
			return s.answer_targets(picks.slice(0, want)).ok
		"choice":
			return s.answer_choice(mine).ok
		"ack":
			return s.answer_choice(true).ok
		"option":
			return s.answer_option(0).ok
		"prediction":
			var minimum: Dictionary = next.get("prediction_min", {})
			return s.answer_prediction("night", int(minimum.get("night", 1))).ok
	return false


static func _to_day(s: GameSession, role: String, own: Array[int]) -> void:
	for i: int in MAX_ACTIONS:
		var next := effective(s)
		if str(next.get("kind")) in ["day", "game_over", "win_decision", "none", ""]:
			return
		if not _default_step(s, next, own):
			return


## Hinrichtung von `target` nach einer Nominierung durch die erste andere lebende Person; Pflichtangaben mit „Nein“ bzw. 0.
static func _execute(s: GameSession, target: int) -> bool:
	if str(effective(s).get("kind")) != "day":
		return false
	var seats: Array = (s.cockpit_view() as Dictionary).get("seats", [])
	var nominator := -1
	for seat: Dictionary in seats:
		if bool(seat["alive"]) and int(seat["person_id"]) != target:
			nominator = int(seat["person_id"])
			break
	if nominator == -1 or not s.nominate(nominator, target).ok:
		return false
	return s.decide_execution(target, {"cerberus_defend": false, "sage_curse": 0, "village_confirms": false}).ok


## Henker und Kopfgeldjäger brauchen Hinrichtungen: eine lebende Dorf- bzw. Wolfsperson, nie die Rolle selbst.
static func _daily_execution(s: GameSession, role: String, own: Array[int]) -> void:
	if not EXECUTE_DAILY.has(role):
		return
	var want_wolf := str(EXECUTE_DAILY[role]) == "wolf"
	for seat: Dictionary in (s.cockpit_view() as Dictionary).get("seats", []):
		var id := int(seat["person_id"])
		if bool(seat["alive"]) and not own.has(id) and RoleCatalog.counts_as_wolf(StringName(str(cast(role)[id - 1]))) == want_wolf:
			_execute(s, id)
			return


static func _next_night(s: GameSession) -> bool:
	if str(effective(s).get("kind")) == "day" and not s.decide_execution(-1).ok:
		return false
	return s.end_day().ok and s.start_night().ok


# --- Sonderfall ------------------------------------------------------------------------------------

## Zustand des Sonderfalls für die Nachtkarte: macht die Warnungen der Rolle sichtbar (NightWarnings.kinds_for_role). Wählbare Personen
## werden geschützt, verflucht oder als Liebende verbunden; eine blockierbare Rolle wird blockiert (ihr Schritt entfällt, die nächste Karte
## trägt die Warnung). Nur in der Wegwerf-Partie der Vorschau.
static func apply_special(s: GameSession, role: String) -> bool:
	var kinds := NightWarnings.kinds_for_role(role)
	if kinds.is_empty():
		return false
	var next := effective(s)
	var own := holders(role)
	var allowed: Array = (next.get("allowed_ids", []) as Array).filter(func(id: Variant) -> bool: return not own.has(int(id)))
	var targeted := kinds.has("protected") or kinds.has("lovers") or kinds.has("cursed")
	if targeted and str(next.get("answer")) == "targets" and not allowed.is_empty():
		return s.preview_special(kinds.filter(func(k: String) -> bool: return k != "blocked"), allowed, own[0])
	return kinds.has("blocked") and s.preview_special(["blocked"], [], own[0])
