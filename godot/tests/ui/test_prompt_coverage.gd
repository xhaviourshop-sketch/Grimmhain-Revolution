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
const FOCUS_ID := 1    ## Personen-ID der Fokusrolle in _start()

var _rng := RandomNumberGenerator.new()
var _focus := ""       ## Fokusrolle der laufenden Partie
var _focus_hit := {}       ## Rollen, die in ihrer eigenen Fokuspartie als Prompt erschienen
var _scenario := false     ## Erreichbarkeitsszenario: kein zufälliges Überspringen/Abbrechen, feste Tagespolitik
var _scenario_day := "none"    ## Szenario-Tag: "none" (keine Hinrichtung), "execute" oder "wolf_first"
var _scenario_wolves: Array = []
var _combos := {}      ## "owner/stage/answer" → Anzahl gelöster Prompts
var _owners := {}      ## Besitzer → true
var _rendered := {}
var _card: ActionCard = null
var _last_error: StringName = &""
var _notices := {}     ## Hinweisart → Anzahl bestätigter Hinweise (DI-04, DI-06, DI-07)


## Mischen ausschließlich über den seedbaren Generator dieses Tests. `Array.shuffle()` nutzt den globalen,
## bei jedem Start zufällig gesetzten Generator und machte die Partien (und damit die Abdeckung) von Lauf zu Lauf verschieden (B-01).
func _shuffle(items: Array) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp


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
		var focus_role := str(roles[g % roles.size()])
		var seen_before := _owners.duplicate()
		_owners.clear()
		var played := _play(g, focus_role, COUNTS[g % COUNTS.size()])
		if _owners.has(focus_role):
			_focus_hit[focus_role] = true
		_owners.merge(seen_before)
		if not played:
			return
		finished += 1
	assert_eq(finished, games, "alle Partien ohne unlösbaren Prompt")
	# Alle Rollen mit eigenem Nachtschritt müssen mindestens einmal als Prompt erschienen sein,
	# sonst belegt der Test ihre Bedienbarkeit nicht.
	for role: Variant in roles:
		if SetupRoleCatalog.has_night_step(StringName(role)) and not _owners.has(str(role)):
			fail("Rolle %s erschien nie als Prompt" % role)
	# Zusätzlich darf keine Pflichtabdeckung allein von Füllrollen anderer Partien leben: Jede Nachtrolle erschien entweder
	# in ihrer eigenen Fokuspartie oder hat ein festes Szenario (REACH_SCENARIOS, geprüft im eigenen Test).
	for role: Variant in roles:
		if SetupRoleCatalog.has_night_step(StringName(role)) and not _focus_hit.has(str(role)) and not REACH_SCENARIOS.has(str(role)):
			fail("Rolle %s erschien in keiner eigenen Fokuspartie und hat kein festes Szenario" % role)
	var keys := _combos.keys()
	keys.sort()
	# Jede Kombination hat eine eigene Kurz-Aktion (Mini-Nachtkarte), jede Nachtrolle einen eigenen Vorlesetext.
	for combo: String in keys:
		var parts := combo.split("/")
		var probe := {"owner": "reaction", "reaction_kind": parts[1]} if parts[0] == "reaction" else {"owner": parts[0], "stage": parts[1], "answer": parts[2]}
		var key := CockpitText.night_short_key(probe)
		assert_false(key.begins_with("ui.night.generic."), "%s: eigene Kurz-Aktion statt %s" % [combo, key])
		if parts[0] != "reaction":
			assert_ne(CockpitText.call_key(parts[0] if parts[0] != "pack2" else "pack"), "ui.call.generic", "%s: eigener Vorlesetext" % combo)
	print("      Prompt-Abdeckung (%d Kombinationen): %s" % [keys.size(), ", ".join(keys)])
	for kind: String in ["loki_bond", "piper_new", "pest_infected"]:
		assert_true(int(_notices.get(kind, 0)) > 0, "Hinweisart %s wurde über die Karte bedient" % kind)
	print("      Hinweise über die Karte bestätigt: %s" % str(_notices))



## Hinweiskarte: Zeigen ist bedienbar (Schließen bestätigt), die Karte nennt keine fremden Rollen.
func _check_notice_card(next: Dictionary) -> void:
	_card.render(next, {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	assert_true(_card.find_child("ShowNoticeButton", true, false) != null, "Hinweis: Karte zeigen bedienbar")
	assert_true(_card.find_child("AckNoticeButton", true, false) == null, "Hinweis: Schließen der gezeigten Karte bestätigt, kein eigener Knopf")


func _play(g: int, focus: String, count: int) -> bool:
	var session := GameSession.new()
	var start := session.submit(_start(focus, count))
	if not start.ok:
		fail("Start %d abgelehnt: %s" % [g, start.error])
		return false
	return _run(session, g, focus, false)


## Spielt eine gestartete Partie mit den Kartendaten. Mit `stop_on_focus` endet der Lauf, sobald die Fokusrolle als
## Prompt bedient wurde (Erreichbarkeitsszenarien); sonst läuft die Partie bis zum Ende oder zu MAX_STEPS.
func _run(session: GameSession, g: int, focus: String, stop_on_focus: bool) -> bool:
	_focus = focus
	for step: int in MAX_STEPS:
		if stop_on_focus and _owners.has(focus):
			return true
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
				# Die Fokusrolle wird nie übersprungen oder abgebrochen: Sonst hinge ihre Abdeckung am Zufall.
				if bool(next.get("skippable")) and str(next.get("role_id", "")) != focus and not _scenario and _rng.randf() < 0.1:
					ok = session.skip_next_step("Abdeckungstest").ok
				else:
					ok = session.begin_next_step().ok
			"prompt":
				if bool(next["cancellable"]) and str(next["owner"]) != focus and not _scenario and _rng.randf() < 0.04:
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
	return not stop_on_focus or _owners.has(focus)


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
	# Die Spielleitung hält die Fokusperson (Personen-ID 1) am Leben, solange andere wählbar sind: Sonst stürbe sie
	# je nach Zufallswahl vor ihrem ersten Schritt und ihre Abdeckung hinge am Zufall (B-01).
	if str(next["owner"]) != _focus and allowed.has(FOCUS_ID) and allowed.size() > 1 + int((next["counts"] as Array).max()):
		allowed.erase(FOCUS_ID)
	# Eine der zulässigen Anzahlen der Karte, soweit genug Personen wählbar sind.
	var counts: Array = (next["counts"] as Array).filter(func(c: int) -> bool: return c <= allowed.size())
	if counts.is_empty():
		fail("%s: keine erfüllbare Anzahl %s bei %d wählbaren Personen" % [label, next["counts"], allowed.size()])
		return null
	var n := int(counts[_rng.randi_range(0, counts.size() - 1)])
	_shuffle(allowed)
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
	if _scenario:
		return _scenario_execution(session, next)
	var seats: Array = session.cockpit_view()["seats"]
	var alive: Array = seats.filter(func(s: Dictionary) -> bool: return bool(s["alive"])).map(func(s: Dictionary) -> int: return int(s["person_id"]))
	if _rng.randf() < 0.6 and alive.size() >= 2:
		var used_from: Array = (next["nominations"] as Array).map(func(n: Dictionary) -> int: return int(n["nominator_id"]))
		var used_to: Array = (next["nominations"] as Array).map(func(n: Dictionary) -> int: return int(n["nominee_id"]))
		var from: Array = alive.filter(func(id: int) -> bool: return not used_from.has(id))
		var to: Array = alive.filter(func(id: int) -> bool: return not used_to.has(id) and id != FOCUS_ID)
		if not from.is_empty() and not to.is_empty():
			# Eine Richter-Nominierung zeigt öffentlich keinen Nominierenden; nominiert der Richter
			# erneut, lehnt der Regelkern mit already_nominated_today ab. Dann entscheidet der Test über
			# die Hinrichtung, wie es ein Spielleiter nach der Fehlermeldung täte.
			if session.nominate(from[_rng.randi_range(0, from.size() - 1)], to[_rng.randi_range(0, to.size() - 1)]).ok:
				return true
			if _last_error != &"already_nominated_today":
				return false
	var candidates: Array = (next["execution_candidates"] as Array).filter(func(id: int) -> bool: return id != FOCUS_ID)
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
			# Feste Anzahl wird beim Tippen sofort übernommen (kein Bestätigen); Verzicht nur, wo die Anzahl 0 zulässt.
			if not CockpitText.auto_commit(next):
				expected = ["ConfirmTargetsButton"]
			if (next["counts"] as Array).has(0):
				expected.append("DeclineButton")
		"choice":
			expected = ["YesButton", "NoButton"]
		"ack":
			expected.append("AckButton" if (str(next.get("owner")) == "card" or not names.has("ShowCardButton")) else "ShowCardButton")
		"option":
			for i: int in (next["options"] as Array).size():
				expected.append("OptionButton_%d" % i)
		"prediction":
			expected = ["ConfirmPredictionButton", "PredictionNightButton", "PredictionDayButton"]
	if bool(next["cancellable"]) and str(next.get("owner")) == "card":  # Abbrechen gibt es nur noch bei Karteneingaben
		expected.append("CancelPromptButton")
	for e: String in expected:
		assert_true(names.has(e), "%s: Karte hat %s (%s)" % [combo, e, names])
	for label: Node in _card.find_children("*", "Label", true, false):
		var text := (label as Label).text
		assert_false(text.begins_with("ui.") or text.contains("{"), "%s: unübersetzter Text „%s“" % [combo, text])


func _start(focus: String, count: int) -> Command:
	var pool: Array = FUZZ.ROLES
	var wolves: Array = FUZZ.WOLF_ROLES
	# PE-07: jede Rolle höchstens einmal beim Start; gezogene, schon vergebene Rollen weichen auf die nächste freie des Pools aus.
	var roles: Array = [focus]
	if not wolves.has(focus):
		FUZZ.add_unique(roles, ["werwolf"], 0)
	FUZZ.add_unique(roles, ["dorfbewohner"], 0)
	while roles.size() < count:
		FUZZ.add_unique(roles, pool, _rng.randi_range(0, pool.size() - 1))
	var map := {}
	var appearances := {}
	var order: Array = []
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
		order.append(i + 1)
		if roles[i] == "trugbilderwolf":
			appearances[str(i + 1)] = "dorfbewohner"
	_shuffle(order)
	var payload := {"round_id": "coverage", "seed": 500 + count, "assignment": "manual", "players": Fixtures.players(count), "seat_order": order, "roles": map}
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


# --- Erreichbarkeit: feste Szenarien statt Zufallsglück (B-01) ------------------------------------------

## Nachtrollen, deren Schritt an eine Bedingung des Regelkerns geknüpft ist, die eine Mischpartie nur zufällig herstellt
## (StepQueue.build_night_plan): Tote, Hinrichtungen, Nachtnummer, Kopfgeld, Tod der Rolle. Je Rolle ein Szenario mit
## Fokusrolle (Person 1), einem Werwolf (`wolves` weitere) und Dorfbewohnern; `kills` sind Spielleiterkorrekturen
## (`kill`, ohne Todeseffekte) vor der ersten Nacht, `day` die Tagespolitik. Die Karte muss den Schritt nach wenigen
## Nächten tatsächlich als Prompt zeigen.
const REACH_SCENARIOS := {
	"koenig": {"count": 8, "kills": [4, 5, 6, 7, 8]},              # mehr Tote als Lebende (InfoSteps.king_condition)
	"kutscher": {"count": 24, "kills": [4, 5, 6, 7, 8, 9, 10, 11, 12, 13]},  # mindestens 10 Tote (COACH_MIN_DEAD)
	"dr-victor-frankenstein": {"count": 8, "kills": [4]},          # mindestens ein Toter
	"schutzgeist": {"count": 8, "kills": [1]},                     # handelt nur tot, ab der folgenden Nacht
	"hades": {"count": 10, "day": "execute"},                      # zwei Lichter aus zwei echten Toden
	"henker": {"count": 12, "day": "execute"},                     # mindestens drei Hinrichtungen
	"kopfgeldjaeger": {"count": 10, "wolves": 1, "day": "wolf_first"},  # ein gelynchter Wolf gibt eine Liste
	"rachsuechtiger-wolf": {"count": 8},                           # nur jede dritte Nacht
	"dorfchronistin": {"count": 8},                                # nur Nacht 1
	"loki": {"count": 8},
	"nekromant": {"count": 8},
	"grabraeuber": {"count": 8},
}


func _scenario_start(focus: String, count: int, extra_wolves: int) -> Command:
	# Fokusrolle, ein Werwolf, `extra_wolves` weitere Wolfsrollen, der Rest verschiedene wirkungsarme Dorfrollen (PE-07).
	var roles: Array = [focus, "werwolf"]
	_scenario_wolves = [2]
	for role: String in Fixtures.wolf_fillers(extra_wolves + 1, [focus]).slice(1):
		roles.append(role)
		_scenario_wolves.append(roles.size())
	for role: String in Fixtures.village_fillers(count - roles.size(), roles):
		roles.append(role)
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	return Command.start_game({"round_id": "reach", "seed": 7, "assignment": "manual", "players": Fixtures.players(count),
		"seat_order": Fixtures.identity_order(count), "roles": map})


## Tagespolitik der Szenarien ohne Zufall: keine Hinrichtung, oder täglich die erste zulässige Person (Fokusperson
## ausgenommen), im Modus "wolf_first" zuerst ein Wolf.
func _scenario_execution(session: GameSession, next: Dictionary) -> bool:
	if _scenario_day == "none":
		return session.decide_execution(-1).ok
	var seats: Array = session.cockpit_view()["seats"]
	var alive: Array = seats.filter(func(x: Dictionary) -> bool: return bool(x["alive"])).map(func(x: Dictionary) -> int: return int(x["person_id"]))
	var candidates: Array = (next["execution_candidates"] as Array).filter(func(id: int) -> bool: return id != FOCUS_ID)
	if candidates.is_empty():
		# Erst nominieren (Fokusperson wird nie nominiert), dann in der nächsten Tagesrunde hinrichten.
		var pool: Array = alive.filter(func(id: int) -> bool: return id != FOCUS_ID)
		if _scenario_day == "wolf_first":
			var wolves: Array = pool.filter(func(id: int) -> bool: return _scenario_wolves.has(id))
			pool = wolves if not wolves.is_empty() else pool
		var used: Array = (next["nominations"] as Array).map(func(n: Dictionary) -> int: return int(n["nominee_id"]))
		pool = pool.filter(func(id: int) -> bool: return not used.has(id))
		var nominators: Array = (next["nominations"] as Array).map(func(n: Dictionary) -> int: return int(n["nominator_id"]))
		if pool.is_empty():
			return session.decide_execution(-1).ok
		var nominator := -1
		for id: Variant in alive:
			if int(id) != int(pool[0]) and not nominators.has(int(id)):
				nominator = int(id)
				break
		if nominator == -1:
			return session.decide_execution(-1).ok
		return session.nominate(nominator, int(pool[0])).ok
	var target := int(candidates[0])
	var preview := session.execution_preview(target)
	var extra := {}
	if bool(preview["needs_cerberus"]):
		extra["cerberus_defend"] = false
	if bool(preview["needs_sage"]):
		extra["sage_curse"] = 0
	return session.decide_execution(target, extra).ok


## Spielt ein Szenario und meldet, ob die Fokusrolle als Prompt bedient wurde.
func _reach(focus: String, spec: Dictionary) -> bool:
	_owners.clear()
	_scenario = true
	_scenario_day = str(spec.get("day", "none"))
	_rng.seed = 7
	var session := GameSession.new()
	var start := session.submit(_scenario_start(focus, int(spec["count"]), int(spec.get("wolves", 0))))
	if not start.ok:
		fail("Szenario %s: Start abgelehnt (%s)" % [focus, start.error])
		_scenario = false
		return false
	for id: Variant in spec.get("kills", []):
		var killed := session.submit(CorrectionFixtures.gm("kill", {"target_id": int(id), "trigger_effects": false}, "Szenario"))
		if not killed.ok:
			fail("Szenario %s: Korrektur kill %s abgelehnt (%s)" % [focus, id, killed.error])
			_scenario = false
			return false
	var reached := _run(session, 900 + int(spec["count"]), focus, true)
	_scenario = false
	return reached


func test_conditional_night_roles_are_reachable_in_fixed_scenarios() -> void:
	_card = ActionCard.new()
	tree.root.add_child(_card)
	_spawned.append(_card)
	for focus: String in REACH_SCENARIOS:
		assert_true(_reach(focus, REACH_SCENARIOS[focus]), "Szenario %s: Schritt der Rolle wurde als Prompt erreicht" % focus)


## Regression B-01: Die Abdeckungspartien dürfen nicht vom globalen Zufallsgenerator abhängen, der bei jedem
## Start anders gesetzt ist. Dieselbe Partie muss unter verschiedenen globalen Seeds dieselben Prompts liefern.
func test_coverage_games_do_not_depend_on_the_global_random_generator() -> void:
	_card = ActionCard.new()
	tree.root.add_child(_card)
	_spawned.append(_card)
	var roles: Array = FUZZ.ROLES
	var g := roles.find("koenig")
	var signatures: Array = []
	for global_seed: int in [1, 2, 3, 4]:
		seed(global_seed)
		_rng.seed = 104729 * (g + 3)
		_combos.clear()
		_owners.clear()
		_play(g, "koenig", COUNTS[g % COUNTS.size()])
		var keys := _combos.keys()
		keys.sort()
		signatures.append(",".join(keys) + "|" + ",".join(_owners.keys()))
	for i: int in signatures.size():
		assert_eq(signatures[i], signatures[0], "Partie unter globalem Seed %d wie unter Seed 1" % (i + 1))


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
	session.submit(_roles_start(["dorfbewohner", "werwolf", "amalia", "ritter", "detektiv", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor"]))
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
	assert_true(CockpitText.has_key("ui.night.reaction.knight.title"), "eigener Titel")
	assert_true(session.answer_targets([6]).ok, "Wolf 6 stirbt")


## Schmiedewaffe: Die Spielleitung wählt den Wolf, der stirbt (S-06). Waffe ab Nacht 6.
func test_smith_weapon_reaction_card() -> void:
	var session := GameSession.new()
	session.submit(_roles_start(["werwolf", "blutwolf", "dorfschmied", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"]))
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
	assert_true(CockpitText.has_key("ui.night.reaction.smith.title"), "eigener Titel")
	assert_true(session.answer_targets([2]).ok, "Wolf 2 stirbt")
