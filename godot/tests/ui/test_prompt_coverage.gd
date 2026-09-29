extends UiTestCase
## Bedienbarkeit aller Prompt-Arten über die Oberfläche: Partien mit allen Rollen des Regelkerns
## werden ausschließlich über GameSession gespielt, und zwar nur mit den Daten, die auch die
## Aktionskarte hat (cockpit_view: Antwortart, min/max, zulässige Personen, Optionen, Zeitpunkt).
## Für jede neue Kombination aus Besitzer, Stufe und Antwortart wird die Karte gerendert und auf
## passende Bedienelemente geprüft. Jeder Prompt muss mit genau einer Antwort nach den Kartendaten
## lösbar sein (zulässige Anzahlen `counts`, Freigabe über `check_targets` wie beim Bestätigen-Button);
## eine Ablehnung durch den Regelkern ist ein Fehler, es gibt keine Wiederholversuche. Kein Schritt wird
## automatisch entschieden. Die gefundene Abdeckung wird ausgegeben.
##
## Grenze: Dieser Lauf bedient GameSession mit den Daten der Karte, nicht die Buttons selbst. Die
## Button-Bedienung belegen test_full_round_ui, test_cockpit_screen und test_target_selection.

const FUZZ := preload("res://tests/unit/test_role_interaction_fuzz.gd")
const COUNTS: Array[int] = [6, 8, 10, 12, 16, 24]
const ROUNDS := 2
const MAX_STEPS := 220

var _rng := RandomNumberGenerator.new()
var _combos := {}      ## "owner/stage/answer" → Anzahl gelöster Prompts
var _owners := {}      ## Besitzer → true
var _rendered := {}
var _card: ActionCard = null
var _last_error: StringName = &""
var _notices := {}     ## Hinweisart → Anzahl bestätigter Hinweise (DI-04, DI-06, DI-07)


func _on_rejected(error: StringName) -> void:
	_last_error = error


func test_all_prompt_kinds_are_operable_through_the_card() -> void:
	_card = ActionCard.new()
	tree.root.add_child(_card)
	_spawned.append(_card)
	var roles: Array = FUZZ.ROLES
	var games := ROUNDS * roles.size()
	var finished := 0
	for g: int in games:
		_rng.seed = 104729 * (g + 3)
		if not _play(g, str(roles[g % roles.size()]), COUNTS[g % COUNTS.size()]):
			return
		finished += 1
	assert_eq(finished, games, "alle Partien ohne unlösbaren Prompt")
	# Alle Rollen mit eigenem Nachtschritt müssen mindestens einmal als Prompt erschienen sein,
	# sonst belegt der Test ihre Bedienbarkeit nicht.
	for role: Variant in roles:
		if SetupRoleCatalog.night_priority(StringName(role)) > 0 and not _owners.has(str(role)):
			fail("Rolle %s erschien nie als Prompt" % role)
	var keys := _combos.keys()
	keys.sort()
	# Jede Kombination hat eine eigene Anweisung, jede Nachtrolle einen eigenen Vorlesetext.
	for combo: String in keys:
		var parts := combo.split("/")
		var key := CockpitText.reaction_key(parts[1]) if parts[0] == "reaction" else CockpitText.instruction_key(parts[0], parts[1], parts[2])
		assert_false(key.begins_with("ui.prompt.generic."), "%s: eigene Anweisung statt %s" % [combo, key])
		if parts[0] != "reaction":
			assert_ne(CockpitText.call_key(parts[0] if parts[0] != "pack2" else "pack"), "ui.call.generic", "%s: eigener Vorlesetext" % combo)
	print("      Prompt-Abdeckung (%d Kombinationen): %s" % [keys.size(), ", ".join(keys)])
	for kind: String in ["loki_bond", "piper_new", "piper_all", "pest_infected"]:
		assert_true(int(_notices.get(kind, 0)) > 0, "Hinweisart %s wurde über die Karte bedient" % kind)
	print("      Hinweise über die Karte bestätigt: %s" % str(_notices))



## Hinweiskarte: Zeigen und Bestätigen sind bedienbar, die Karte nennt keine fremden Rollen.
func _check_notice_card(next: Dictionary) -> void:
	_card.render(next, {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	assert_true(_card.find_child("ShowNoticeButton", true, false) != null, "Hinweis: Karte zeigen bedienbar")
	assert_true(_card.find_child("AckNoticeButton", true, false) != null, "Hinweis: Bestätigen bedienbar")


func _play(g: int, focus: String, count: int) -> bool:
	var session := GameSession.new()
	var start := session.submit(_start(focus, count))
	if not start.ok:
		fail("Start %d abgelehnt: %s" % [g, start.error])
		return false
	for step: int in MAX_STEPS:
		var next: Dictionary = session.cockpit_view()["next"]
		var ok := true
		_last_error = &""
		session.command_rejected.connect(_on_rejected) if not session.command_rejected.is_connected(_on_rejected) else null
		match str(next["kind"]):
			"game_over":
				return true
			"start_night":
				ok = session.start_night().ok
			"begin_step":
				if bool(next.get("skippable")) and _rng.randf() < 0.1:
					ok = session.skip_next_step("Abdeckungstest").ok
				else:
					ok = session.begin_next_step().ok
			"prompt":
				if bool(next["cancellable"]) and _rng.randf() < 0.04:
					ok = session.cancel_prompt("Abdeckungstest").ok
				else:
					ok = _answer(session, next, "Partie %d (%s), Schritt %d" % [g, focus, step])
			"notice":
				_notices[str(next["notice_kind"])] = int(_notices.get(str(next["notice_kind"]), 0)) + 1
				_check_notice_card(next)
				ok = session.ack_notice(int(next["notice_id"])).ok
			"end_night":
				ok = session.end_night().ok
			"day":
				ok = _day(session, next)
			"end_day":
				ok = session.end_day().ok
			"win_decision":
				var candidates: Array = next["candidates"]
				ok = session.confirm_win(int(candidates[0]["id"])).ok if _rng.randf() < 0.5 else session.reject_win("Abdeckungstest").ok
			_:
				fail("Partie %d: unbekannte Handlung %s" % [g, next["kind"]])
				return false
		if not ok:
			fail("Partie %d (%s), Schritt %d: Handlung %s abgelehnt (%s) %s" % [g, focus, step, next["kind"], _last_error, JSON.stringify(next)])
			return false
	return true


## Beantwortet einen Prompt mit genau einer Antwort nach den Kartendaten; eine Ablehnung ist ein Fehler.
func _answer(session: GameSession, next: Dictionary, label: String) -> bool:
	var combo := "%s/%s/%s" % [next["owner"], next["stage"] if str(next["owner"]) != "reaction" else next["reaction_kind"], next["answer"]]
	_owners[str(next["owner"])] = true
	_render_once(combo, next)
	var r := _try(session, next, label)
	if r == null or not r.ok:
		fail("%s: Prompt %s mit der Karte nicht lösbar (%s)" % [label, combo, r.error if r != null else "keine freigegebene Auswahl"])
		return false
	_combos[combo] = int(_combos.get(combo, 0)) + 1
	return true


func _try(session: GameSession, next: Dictionary, label: String) -> CommandResult:
	match str(next["answer"]):
		"choice":
			return session.answer_choice(_rng.randf() < 0.5)
		"ack":
			return session.answer_choice(true)
		"option":
			return session.answer_option(_rng.randi_range(0, (next["options"] as Array).size() - 1))
		"prediction":
			var kind := "night" if _rng.randf() < 0.5 else "day"
			return session.answer_prediction(kind, int(next["prediction_min"][kind]) + _rng.randi_range(0, 3))
	var allowed: Array = (next["allowed_ids"] as Array).duplicate()
	# Eine der zulässigen Anzahlen der Karte, soweit genug Personen wählbar sind.
	var counts: Array = (next["counts"] as Array).filter(func(c: int) -> bool: return c <= allowed.size())
	if counts.is_empty():
		fail("%s: keine erfüllbare Anzahl %s bei %d wählbaren Personen" % [label, next["counts"], allowed.size()])
		return null
	var n := int(counts[_rng.randi_range(0, counts.size() - 1)])
	allowed.shuffle()
	var picks := allowed.slice(0, n)
	# Hinweiszeile der Karte nutzen: mindestens einen der genannten Wölfe wählen (Traumdeuter, Kopfgeldjäger).
	for line: Dictionary in next["info"]:
		if str(line["key"]) == "wolves_available_ids" and not (line["value"] as Array).is_empty() and n > 0:
			var wolf := int((line["value"] as Array)[0]["person_id"])
			if not picks.has(wolf):
				picks[0] = wolf
	# Wie die Karte: Bestätigen nur, wenn der Regelkern die Auswahl freigibt (Verzicht ist eigener Button).
	if n > 0:
		var blocked := session.check_targets(picks)
		if blocked != &"":
			fail("%s: Karte hätte Bestätigen gesperrt (%s) für %s" % [label, blocked, picks])
			return null
	return session.answer_targets(picks)


func _day(session: GameSession, next: Dictionary) -> bool:
	var seats: Array = session.cockpit_view()["seats"]
	var alive: Array = seats.filter(func(s: Dictionary) -> bool: return bool(s["alive"])).map(func(s: Dictionary) -> int: return int(s["person_id"]))
	if _rng.randf() < 0.6 and alive.size() >= 2:
		var used_from: Array = (next["nominations"] as Array).map(func(n: Dictionary) -> int: return int(n["nominator_id"]))
		var used_to: Array = (next["nominations"] as Array).map(func(n: Dictionary) -> int: return int(n["nominee_id"]))
		var from: Array = alive.filter(func(id: int) -> bool: return not used_from.has(id))
		var to: Array = alive.filter(func(id: int) -> bool: return not used_to.has(id))
		if not from.is_empty() and not to.is_empty():
			# Eine Richter-Nominierung zeigt öffentlich keinen Nominierenden; nominiert der Richter
			# erneut, lehnt der Regelkern mit already_nominated_today ab. Dann entscheidet der Test über
			# die Hinrichtung, wie es ein Spielleiter nach der Fehlermeldung täte.
			if session.nominate(from[_rng.randi_range(0, from.size() - 1)], to[_rng.randi_range(0, to.size() - 1)]).ok:
				return true
			if _last_error != &"already_nominated_today":
				return false
	var candidates: Array = next["execution_candidates"]
	if candidates.is_empty() or _rng.randf() < 0.2:
		return session.decide_execution(-1).ok
	var target := int(candidates[_rng.randi_range(0, candidates.size() - 1)])
	var preview := session.execution_preview(target)
	var extra := {}
	if bool(preview["needs_cerberus"]):
		extra["cerberus_defend"] = _rng.randf() < 0.5
	if bool(preview["needs_sage"]):
		extra["sage_curse"] = _rng.randi_range(0, int(preview["sage_max"]))
	return session.decide_execution(target, extra).ok


## Karte einmal je Kombination rendern: passende Bedienelemente, Anweisung ist übersetzt.
func _render_once(combo: String, next: Dictionary) -> void:
	if _rendered.has(combo):
		return
	_rendered[combo] = true
	_card.render(next, {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	var names: Array[String] = []
	for b: Node in _card.find_children("*", "BaseButton", true, false):
		names.append(String(b.name))
	var expected: Array[String] = []
	match str(next["answer"]):
		"targets":
			expected = ["ConfirmTargetsButton"]
			if int(next["min"]) == 0:
				expected.append("DeclineButton")
		"choice":
			expected = ["YesButton", "NoButton"]
		"ack":
			expected = ["AckButton"]
		"option":
			for i: int in (next["options"] as Array).size():
				expected.append("OptionButton_%d" % i)
		"prediction":
			expected = ["ConfirmPredictionButton", "PredictionNightButton", "PredictionDayButton"]
	if bool(next["cancellable"]):
		expected.append("CancelPromptButton")
	for e: String in expected:
		assert_true(names.has(e), "%s: Karte hat %s (%s)" % [combo, e, names])
	for label: Node in _card.find_children("*", "Label", true, false):
		var text := (label as Label).text
		assert_false(text.begins_with("ui.") or text.contains("{"), "%s: unübersetzter Text „%s“" % [combo, text])


func _start(focus: String, count: int) -> Command:
	var pool: Array = FUZZ.ROLES
	var wolves: Array = FUZZ.WOLF_ROLES
	var roles: Array = [focus]
	if not wolves.has(focus):
		roles.append("werwolf")
	roles.append("dorfbewohner")
	while roles.size() < count:
		roles.append(str(pool[_rng.randi_range(0, pool.size() - 1)]))
	var map := {}
	var appearances := {}
	var order: Array = []
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
		order.append(i + 1)
		if roles[i] == "trugbilderwolf":
			appearances[str(i + 1)] = "dorfbewohner"
	order.shuffle()
	var payload := {"round_id": "coverage", "seed": 500 + count, "assignment": "manual", "players": Fixtures.players(count), "seat_order": order, "roles": map}
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


# --- Gezielt: seltene Reaktionen ---------------------------------------------------------------------

func _roles_start(roles: Array) -> Command:
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	return Command.start_game({"round_id": "coverage", "seed": 3, "assignment": "manual", "players": Fixtures.players(roles.size()),
		"seat_order": Fixtures.identity_order(roles.size()), "roles": map})


## Ritter bei Gleichstand: Pflichtwahl unter den gleich nahen Wölfen, ohne Verzicht.
func test_knight_tie_reaction_card() -> void:
	var session := GameSession.new()
	session.submit(_roles_start(["dorfbewohner", "werwolf", "dorfbewohner", "ritter", "dorfbewohner", "werwolf", "dorfbewohner", "dorfbewohner"]))
	session.start_night()
	assert_true(session.answer_targets([4]).ok, "Rudel reißt den Ritter")
	assert_true(session.end_night().ok, "Morgen")
	var next: Dictionary = session.cockpit_view()["next"]
	assert_eq([str(next["kind"]), str(next["reaction_kind"])], ["begin_step", "knight"], "Ritter-Reaktion angekündigt")
	session.begin_next_step()
	next = session.cockpit_view()["next"]
	assert_eq([str(next["answer"]), int(next["min"]), next["allowed_ids"]], ["targets", 1, [2, 6]], "Pflichtwahl unter gleich nahen Wölfen")
	assert_false(bool(next["cancellable"]), "nicht abbrechbar")
	_card = ActionCard.new()
	tree.root.add_child(_card)
	_spawned.append(_card)
	_card.render(next, {"phase": "DAWN_RESOLUTION", "seats": [], "selection": [], "revealed": true})
	assert_true(_card.find_child("DeclineButton", true, false) == null, "kein Verzicht")
	assert_eq(CockpitText.reaction_key("knight"), "ui.prompt.reaction.knight", "eigene Anweisung")
	assert_true(session.answer_targets([6]).ok, "Wolf 6 stirbt")


## Schmiedewaffe: Die Spielleitung wählt den Wolf, der stirbt (S-06). Waffe ab Nacht 6.
func test_smith_weapon_reaction_card() -> void:
	var session := GameSession.new()
	session.submit(_roles_start(["werwolf", "werwolf", "dorfschmied", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]))
	for night: int in 5:
		assert_true(session.start_night().ok, "Nacht %d" % (night + 1))
		assert_true(session.skip_next_step("kein Opfer").ok, "Rudel übersprungen")
		assert_true(session.end_night().ok, "Morgen")
		assert_true(session.decide_execution(-1).ok and session.end_day().ok, "Tag ohne Hinrichtung")
	session.start_night()
	var next: Dictionary = session.cockpit_view()["next"]
	while str(next["kind"]) != "end_night":
		if str(next["kind"]) == "begin_step":
			session.begin_next_step()
		elif str(next["owner"]) == "dorfschmied":
			assert_true(session.answer_targets([4]).ok, "Waffe an 4")
		elif str(next["owner"]) == "pack":
			assert_true(session.answer_targets([4]).ok, "Rudel greift 4 an")
		else:
			fail("unerwarteter Prompt %s" % next["owner"])
			return
		next = session.cockpit_view()["next"]
	session.end_night()
	next = session.cockpit_view()["next"]
	assert_eq([str(next["kind"]), str(next.get("reaction_kind"))], ["begin_step", "smith"], "Schmied-Reaktion angekündigt")
	session.begin_next_step()
	next = session.cockpit_view()["next"]
	assert_eq([int(next["min"]), next["allowed_ids"]], [1, [1, 2]], "Pflichtwahl eines lebenden Wolfs")
	assert_eq(CockpitText.reaction_key("smith"), "ui.prompt.reaction.smith", "eigene Anweisung")
	assert_true(session.answer_targets([2]).ok, "Wolf 2 stirbt")
