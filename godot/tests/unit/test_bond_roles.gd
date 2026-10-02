extends TestCase
## DECISION-LOG „Rollenaudit · Bindungsrollen“ (28.09.2026, B-01 bis B-08, R-01 bis R-04).
##   Loki (0.4, nur Nacht 1): freiwillig zwei verschiedene Lebende (auch selbst) als Liebende oder Rivalen;
##     Liebeskummer sofort (eigene Ursache), Rivalen nur Marker für die Witwe.
##   Schwarze Witwe (2.8, Wolf): jede Nacht eine andere Lebende; lebendes Paar → beide sterben am Morgen.
##   Schattenwanderer (2.6, Wolf): einmal je Leben verknüpfen; bei tatsächlichem Tod stirbt stattdessen der
##     andere (Ursache bleibt), danach verbraucht; Korrekturen nicht.
##   Rotkäppchen (7.4): jede Nacht Zuflucht bei einer anderen Lebenden; gewährt → Apfel (nur Folgenacht,
##     verdoppelt den nächsten Jede-Nacht-Schritt) und Todeskette bis zur nächsten gewährten Zuflucht.

const LO := "loki"
const SW := "schwarze-witwe"
const SH := "schattenwanderer"
const RK := "rotkaeppchen"
const D := "dorfbewohner"
const W := "werwolf"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage == &"grant" or p.stage == &"mode":
		return Command.answer_choice(p.id, String(p.stage), false)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Rudelopfer `victim`; `answers`: {"<rolle>:<id>" | "<rolle>:<id>@<stufe>": Antwort}; Antwort ist
## eine Zielliste oder bei Ja/Nein-Stufen ein bool. Endet vor EndNight, sammelt Ereignisse in `log`.
func _night(s: GameState, victim: int, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Tagesende")
	if s != null and s.phase != Phase.NIGHT:
		var started := apply_ok(s, Command.start_night(), "Nachtbeginn")
		log.append_array(started.events)
		s = started.state
	for guard: int in 60:
		if s == null:
			return null
		var cmd: Command = null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
			var staged := "%s@%s" % [key, p.stage]
			if p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.answer_prompt(p.id, [victim] if victim != -1 else [])
			elif answers.has(staged):
				var a: Variant = answers[staged]
				cmd = Command.answer_choice(p.id, String(p.stage), a) if a is bool else Command.answer_stage_targets(p.id, String(p.stage), a)
			elif answers.has(key) and p.stage == &"":
				var planned: Variant = answers[key]
				if planned is Array and not (planned as Array).is_empty() and planned[0] is Array:
					planned = (planned as Array).pop_front()  # je Durchlauf eine eigene Antwort (Apfel)
				cmd = Command.answer_prompt(p.id, planned)
			else:
				cmd = _auto(s)
		else:
			var step := RulesEngine.next_step_id(s)
			if step == "":
				return s
			cmd = Command.begin_step(step)
		var r := apply_ok(s, cmd, "Nachtbefehl")
		log.append_array(r.events)
		s = r.state
	fail("Nacht endet nicht")
	return null


func _dawn(s: GameState, victim: int, answers: Dictionary = {}) -> CommandResult:
	s = _night(s, victim, answers)
	return apply_ok(s, Command.end_night(), "Morgen") if s != null else null


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _died(events: Array[GameEvent], target: int) -> String:
	for e: GameEvent in events_of_type(events, "SeatDied"):
		if int(e.data["target_id"]) == target:
			return String(e.data["cause"])
	return ""


func _dropped_reason(events: Array[GameEvent], key: String) -> String:
	for e: GameEvent in events_of_type(events, "StepDropped"):
		if String(e.data["step_id"]).ends_with(":" + key):
			return String(e.data["reason"])
	return ""


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entries() -> void:
	var expect := {LO: [Faction.VILLAGE, false, 4], SW: [Faction.WOLVES, true, 28], SH: [Faction.WOLVES, true, 26], RK: [Faction.VILLAGE, false, 74]}
	for role: String in expect:
		assert_true(RoleCatalog.has_role(StringName(role)), "%s im Katalog" % role)
		if RoleCatalog.has_role(StringName(role)):
			assert_eq(RoleCatalog.faction_of(StringName(role)), expect[role][0], "%s Fraktion" % role)
			assert_eq(RoleCatalog.counts_as_wolf(StringName(role)), expect[role][1], "%s Wolf" % role)
			assert_eq(RoleCatalog.night_priority(StringName(role)), expect[role][2], "%s Priorität" % role)
	assert_true(RoleCatalog.first_night_only(&"loki"), "Loki nur Nacht 1")


# --- Loki -----------------------------------------------------------------------------------------

func test_loki_binds_once_in_night_one() -> void:
	var s := _state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	s = _ok(s, Command.start_night(), "Nacht 1")
	if s == null:
		return
	assert_eq(s.pending_prompt.owner, &"loki", "Loki vor dem Rudel")
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [1, 2, 3, 4, 5, 6, 7] as Array[int], "alle Lebenden, auch er selbst")
	assert_eq([p.min_count, p.max_count], [0, 2], "Verzicht oder zwei")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [3]), "invalid_target_count", "nur einer")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [2, 3]), "er selbst und 3")
	_codec_same(s, "Modus offen")
	s = _ok(s, Command.answer_choice(p.id, "mode", true), "Liebende")
	if s == null:
		return
	assert_eq(s.loki_pairs, [{"loki_id": 2, "a": 2, "b": 3, "kind": "love", "ended": false}], "Paar gespeichert")
	s = _ok(_night(s, -1), Command.end_night(), "Morgen")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 2")
	assert_false(s != null and s.night_plan.has(&"loki:2"), "nur Nacht 1")


func test_heartbreak_and_rivals() -> void:
	var s := _state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	var r := _dawn(s, -1, {"loki:2@targets": [3, 4], "loki:2@mode": true})
	if r == null:
		return
	var k := apply_ok(r.state, _gm("kill", {"target_id": 3, "trigger_effects": true}), "3 stirbt")
	assert_eq(_died(k.events, 4), "LOVER_HEARTBREAK", "4 stirbt an Liebeskummer")
	s = _ok(_ok(k.state, _gm("revive", {"target_id": 3}), "3 lebt"), _gm("revive", {"target_id": 4}), "4 lebt")
	k = apply_ok(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), "4 stirbt erneut")
	assert_eq(_died(k.events, 3), "", "Bindung bleibt beendet (RM-DR-011.2)")
	# Rivalen: keine eigene Wirkung.
	s = _state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	r = _dawn(s, -1, {"loki:2@targets": [5, 6], "loki:2@mode": false})
	k = apply_ok(r.state, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Rivale stirbt") if r != null else null
	assert_eq(_died(k.events, 6) if k != null else "x", "", "Rivalen sterben nicht mit")


func test_heartbreak_during_sage_curse() -> void:
	# B-08: Liebeskummer wirkt auch im Fluch des Weisen.
	var s := _state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	var r := _dawn(s, -1, {"loki:2@targets": [3, 4], "loki:2@mode": true})
	if r == null:
		return
	s = r.state
	s.sage_curse_from = 1
	s.sage_curse_to = 3
	var k := apply_ok(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), "3 stirbt im Fluch")
	assert_eq(_died(k.events, 4), "LOVER_HEARTBREAK", "Liebeskummer trotz Fluch")


# --- Schwarze Witwe -------------------------------------------------------------------------------

func test_black_widow_kills_living_pair_at_dawn() -> void:
	# 1 Witwe, 2 Loki, 3 Orakel (Liebende mit 4), 5/6 Rivalen nicht betroffen.
	var s := _state([SW, LO, "das-orakel", D, "amalia", "detektiv", "wahnsinniger-kutscher", W])
	var log: Array[GameEvent] = []
	s = _night(s, -1, {"loki:2@targets": [3, 4], "loki:2@mode": true, "schwarze-witwe:1": [4]}, log)
	if s == null:
		return
	assert_eq(_dropped_reason(log, "das-orakel:3"), "marked_for_death", "markierte Person wacht nicht mehr auf")
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_died(r.events, 4), "BLACK_WIDOW", "Ziel stirbt")
	assert_eq(_died(r.events, 3), "BLACK_WIDOW", "Partner stirbt durch die Witwe, nicht an Liebeskummer")


func test_black_widow_without_pair_does_nothing() -> void:
	var s := _state([SW, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", W])
	var r := _dawn(s, -1, {"loki:2@targets": [3, 4], "loki:2@mode": false, "schwarze-witwe:1": [5]})
	if r == null:
		return
	assert_eq(events_of_type(r.events, "SeatDied").size(), 0, "kein Paar, kein Tod")
	r = _dawn(r.state, -1, {"schwarze-witwe:1": [3]})
	assert_eq(_died(r.events, 3) if r != null else "", "BLACK_WIDOW", "Rivalen zählen für die Witwe")
	assert_eq(_died(r.events, 4) if r != null else "", "BLACK_WIDOW", "beide Rivalen")


# --- Schattenwanderer -----------------------------------------------------------------------------

func test_shadowwalker_takes_the_death_once() -> void:
	var s := _state([SH, W, D, "schutzengel", "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise"])
	var r := _dawn(s, -1, {"schattenwanderer:1": [3], "schutzengel:4": [5]})
	if r == null:
		return
	assert_eq(r.state.shadow_links, [{"walker_id": 1, "partner_id": 3}], "Verknüpfung")
	# Nacht 2: 3 geschützt → kein Tod, keine Umlenkung.
	r = _dawn(r.state, 3, {"schutzengel:4": [3]})
	if r == null:
		return
	assert_true(r.state.players[3].alive and r.state.players[1].alive and r.state.shadow_links.size() == 1, "Schutz: nichts umgelenkt")
	# Nacht 3: 3 ungeschützt → der Schattenwanderer stirbt stattdessen.
	r = _dawn(r.state, 3, {"schutzengel:4": [5]})
	if r == null:
		return
	assert_eq(_died(r.events, 1), "NIGHT_KILL", "Schattenwanderer stirbt mit der ursprünglichen Ursache")
	assert_true(r.state.players[3].alive and r.state.shadow_links.is_empty(), "3 lebt, Verknüpfung verbraucht")


func test_shadowwalker_redirects_lynch_not_gm_kill() -> void:
	var s := _state([SH, W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise", "nachtwaechter"])
	var r := _dawn(s, -1, {"schattenwanderer:1": [3]})
	if r == null:
		return
	var k := apply_ok(r.state, _gm("kill", {"target_id": 3, "trigger_effects": true}), "Korrektur")
	assert_true(not k.state.players[3].alive and k.state.players[1].alive, "Korrektur wird nicht umgelenkt")
	s = _ok(r.state, Command.nominate(4, 1), "Nominierung")
	k = apply_ok(s, Command.decide_execution(1), "Lynch des Schattenwanderers")
	assert_eq(_died(k.events, 3), "LYNCH", "Partner stirbt stattdessen durch Lynch")
	assert_eq(k.state.executions_count, 1, "Hinrichtung zählt")


# --- Rotkäppchen ----------------------------------------------------------------------------------

func test_red_riding_hood_chain_and_refusal() -> void:
	var s := _state([W, RK, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	var r := _dawn(s, -1, {"rotkaeppchen:2@targets": [3], "rotkaeppchen:2@grant": true})
	if r == null:
		return
	assert_eq(r.state.red_chains, [{"red_id": 2, "partner_id": 3}], "Kette nach gewährter Zuflucht")
	assert_eq(int(r.state.apples.get(3, 0)), 2, "Apfel für die Folgenacht")
	# Nacht 2: 4 lehnt ab → alte Kette bleibt.
	r = _dawn(r.state, -1, {"rotkaeppchen:2@targets": [4], "rotkaeppchen:2@grant": false})
	if r == null:
		return
	assert_eq(r.state.red_chains, [{"red_id": 2, "partner_id": 3}], "Ablehnung löst nichts")
	var k := apply_ok(r.state, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Rotkäppchen stirbt")
	assert_eq(_died(k.events, 3), "RED_CHAIN", "Partner stirbt mit")


func test_apple_doubles_next_every_night_step() -> void:
	# 3 Orakel erhält in Nacht 1 den Apfel → in Nacht 2 prüft es zweimal; in Nacht 3 wieder einmal.
	var s := _state([W, RK, "das-orakel", D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	var r := _dawn(s, -1, {"rotkaeppchen:2@targets": [3], "rotkaeppchen:2@grant": true})
	if r == null:
		return
	var log: Array[GameEvent] = []
	s = _night(r.state, -1, {"rotkaeppchen:2@targets": [4], "rotkaeppchen:2@grant": false}, log)
	if s == null:
		return
	assert_eq(s.night_plan.count(&"das-orakel:3"), 2, "Schritt doppelt")
	assert_eq(events_of_type(log, "InfoRevealed").size(), 2, "zwei Prüfungen")
	assert_false(s.apples.has(3), "Apfel verbraucht")
	_codec_same(s, "nach Apfel")
	r = apply_ok(s, Command.end_night(), "Morgen 2")
	s = _ok(_ok(r.state, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _night(s, -1)
	assert_eq(s.night_plan.count(&"das-orakel:3") if s != null else -1, 1, "danach wieder einfach")


func test_apple_doubles_guardian_and_is_void_for_single_result_roles() -> void:
	var s := _state([W, RK, "schutzengel", "korrupter-richter", D, "amalia", "detektiv"])
	var r := _dawn(s, -1, {"rotkaeppchen:2@targets": [3], "rotkaeppchen:2@grant": true})
	if r == null:
		return
	# Nacht 2: Schutzengel 3 schützt 5 und (Apfel) 6; das Rudel greift 6 an.
	s = r.state
	s.apples[4] = 2  # Richter mit Apfel: wirkungslos (R-04)
	var log: Array[GameEvent] = []
	var answers := {"schutzengel:3": [[5], [6]], "korrupter-richter:4": [5], "rotkaeppchen:2@targets": [5], "rotkaeppchen:2@grant": false}
	s = _night(s, 6, answers, log)
	if s == null:
		return
	assert_eq(s.night_plan.count(&"schutzengel:3"), 2, "Schutzengel doppelt")
	assert_eq(s.night_plan.count(&"korrupter-richter:4"), 1, "Richter nicht doppelt")
	r = apply_ok(s, Command.end_night(), "Morgen")
	assert_true(r.state.players[6].alive, "zweiter Schutz wirkt")
	# Apfel ungenutzt nach einer Nacht verfallen.
	assert_false(r.state.apples.has(4), "Apfel verfallen")
