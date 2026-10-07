extends TestCase
## Rachsüchtiger Wolf (RM-DR-106) und Zeitwächter (RM-DR-150):
##   E-35 (RM-DR-106.1): Er zählt als Wolf; ist er beim Wolfssieg der einzige lebende Wolf, wird statt des Wolfssiegs sein
##     Alleinsieg vorgeschlagen; leben andere Wölfe, gewinnen die Werwölfe ohne ihn.
##   E-36 (RM-DR-150.1–.4, RM-DR-113.2) mit DA-106: Der Zeitwächter entscheidet einmal je Leben auf seiner Kartenzahl 9,5;
##     Ja: alle späteren Nachtschritte entfallen, Früheres wirkt am Morgen normal, Fenrir/Cerberus wachsen nicht;
##     fällige Wirkungen früherer Nächte (Giftpranke, Pest-Ausbreitung) treten ein; Nachtnummer zählt weiter;
##     öffentliche Meldung am Morgen.
## Abgeleitet (delegierte Autorisierung, Decision Log DA-16 bis DA-20): feste Nächte 3, 6, 9 … (RM-DR-106.2/.3 nach
## Rollentext), Opfer ist eine andere lebende Person, die als Wolf zählt, Tod am Morgen mit eigener Ursache (kein
## Rudelangriff, Schutzengel wirkt nicht); leben nur noch Rachsüchtige Wölfe (mehrere), gewinnt noch niemand.

const RW := "rachsuechtiger-wolf"
const ZW := "zeitwaechter"
const D := "dorfbewohner"
const W := "werwolf"
const SE := "schutzengel"


func _state(roles: Array, dead: Array = []) -> GameState:
	var r := RulesEngine.replay(Fixtures.start_with_copies(roles, 1))  # Kopien gleicher Rollen entstehen nach dem Start (PE-07)
	assert_true(r.ok, "Start (%s)" % r.error)
	var s := r.state if r.ok else null
	for id: int in dead:
		if s != null and not s.open_candidates().is_empty():
			s = _ok(s, Command.create(Command.REJECT_WIN, {"reason": "Test"}), "weiter")
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Toter %d" % id)
	return s


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.owner == PendingPrompt.OWNER_WITCH:
		return Command.answer_choice(p.id, String(p.stage), p.stage in [&"confirm", &"reveal"])
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage == &"use":
		return Command.answer_choice(p.id, "use", false)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	if p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
		return Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
	if p.owner == &"feuerteufel":
		return Command.answer_prompt(p.id, Fixtures.pass_targets(s, p))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


func _night(s: GameState, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
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
			if answers.has(staged) and answers[staged] is bool:
				cmd = Command.answer_choice(p.id, String(p.stage), answers[staged])
			elif answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
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


func _dawn(s: GameState, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
	s = _night(s, answers, log)
	if s == null:
		return null
	var r := apply_ok(s, Command.end_night(), "Morgen")
	log.append_array(r.events)
	return r.state


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _deaths(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events_of_type(events, "SeatDied"):
		out.append([int(e.data["target_id"]), String(e.data["cause"])])
	return out


func _rejected_clean(s: GameState, c: Command, error: String, label: String) -> void:
	var before := CanonicalJson.stringify(s.to_dict())
	var r := RulesEngine.apply(s, c)
	assert_false(r.ok, "%s abgelehnt" % label)
	assert_eq(String(r.error), error, "%s: Fehlergrund" % label)
	assert_true(r.events.is_empty(), "%s: keine Ereignisse" % label)
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: Zustand unverändert" % label)


func _opened(events: Array[GameEvent], suffix: String) -> Array[GameEvent]:
	return events_of_type(events, "PromptOpened").filter(func(e: GameEvent) -> bool: return String(e.data["prompt"]["step_id"]).ends_with(suffix))


func _reasons(s: GameState) -> Array:
	return s.open_candidates().map(func(c: WinCandidate) -> String: return String(c.reason_key)) if s != null else []


# --- Rachsüchtiger Wolf ------------------------------------------------------------------------------

func test_lone_wolf_catalog() -> void:
	assert_true(RoleCatalog.has_role(&"rachsuechtiger-wolf"), "im Katalog")
	if not RoleCatalog.has_role(&"rachsuechtiger-wolf"):
		return
	assert_eq(RoleCatalog.faction_of(&"rachsuechtiger-wolf"), Faction.WOLVES, "Wölfe")
	assert_true(RoleCatalog.counts_as_wolf(&"rachsuechtiger-wolf"), "zählt als Wolf")
	assert_eq(RoleCatalog.night_priority(&"rachsuechtiger-wolf"), 22, "Legacy-Stufe 2.2")
	assert_true(RoleCatalog.stealable(&"rachsuechtiger-wolf"), "stehlbar")


func test_lone_wolf_kills_another_wolf_every_third_night() -> void:
	var s := _state([W, RW, SE, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"])
	var log: Array[GameEvent] = []
	s = _dawn(s, {}, log)
	s = _dawn(s, {}, log)
	assert_eq(_opened(log, "rachsuechtiger-wolf:2").size(), 0, "Nacht 1 und 2 kein Schritt")
	s = _ok(s, Command.decide_execution(-1), "keine")
	s = _ok(s, Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 3")
	for guard: int in 10:
		if s == null or (s.pending_prompt != null and s.pending_prompt.owner == &"rachsuechtiger-wolf"):
			break
		s = _ok(s, _auto(s) if s.pending_prompt != null and s.pending_prompt.owner != PendingPrompt.OWNER_GUARD else (Command.answer_prompt(s.pending_prompt.id, [1]) if s.pending_prompt != null else Command.begin_step(RulesEngine.next_step_id(s))), "bis zum Schritt")
	if s == null or s.pending_prompt == null:
		fail("kein Schritt in Nacht 3")
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [1] as Array[int], "nur andere lebende Wölfe")
	assert_eq([p.min_count, p.max_count], [0, 1], "freiwillig")
	_rejected_clean(s, Command.answer_prompt(p.id, [4]), "invalid_target", "Nicht-Wolf")
	_codec_same(s, "offener Prompt")
	s = _ok(s, Command.answer_prompt(p.id, [1]), "reißen")
	s = _night(s)
	var r := apply_ok(s, Command.end_night(), "Morgen 3") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[1, "LONE_WOLF_KILL"]], "Tod am Morgen trotz Schutzengel auf 1")
	assert_eq(r.state.players[1].death.source_id if r != null else -1, 2, "Quelle")
	# Nacht 4 und 5 kein Schritt, Nacht 6 ohne anderen Wolf: entfällt.
	log = []
	s = _dawn(_dawn(_dawn(r.state if r != null else null, {}, log), {}, log), {}, log)
	assert_eq(_opened(log, "rachsuechtiger-wolf:2").size(), 0, "kein Schritt in Nacht 4 bis 6")
	var dropped := events_of_type(log, "StepDropped").filter(func(e: GameEvent) -> bool: return String(e.data["step_id"]) == "night:6:0:rachsuechtiger-wolf:2" or String(e.data["step_id"]).ends_with("rachsuechtiger-wolf:2"))
	assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "no_decision", "Nacht 6: kein anderer Wolf")


func test_lone_wolf_wins_alone_only_as_last_wolf() -> void:
	# Mit einem anderen Wolf: Werwölfe gewinnen (ohne ihn), kein Alleinsieg.
	var s := _state([RW, W, D, "amalia", "detektiv", "wahnsinniger-kutscher"], [4, 5, 6])
	assert_eq(_reasons(s), ["wolf_parity"], "Wolfssieg mit anderem Wolf")
	# Er ist der einzige lebende Wolf: sein Alleinsieg statt des Wolfssiegs.
	s = _state([RW, W, D, "amalia", "detektiv", "wahnsinniger-kutscher"], [2, 4, 5, 6])
	var solo := s.open_candidates() if s != null else []
	assert_eq(_reasons(s), ["lone_wolf_last_wolf"], "Alleinsieg statt Wolfssieg")
	if solo.size() == 1:
		assert_eq((solo[0] as WinCandidate).beneficiary_ids, [1] as Array[int], "begünstigt er")
		assert_eq(String((solo[0] as WinCandidate).kind), "solo", "Einzelsieg")
	_codec_same(s, "Alleinsieg offen")
	# Zwei Rachsüchtige Wölfe als einzige Wölfe: noch kein Sieg (DA-18).
	s = _state([RW, RW, D, "amalia", "detektiv", "wahnsinniger-kutscher"], [4, 5, 6])
	assert_eq(_reasons(s), [], "keiner gewinnt, sie müssen sich reißen")


# --- Zeitwächter ------------------------------------------------------------------------------------

func test_time_warden_catalog_and_card_slot() -> void:
	assert_true(RoleCatalog.has_role(&"zeitwaechter"), "im Katalog")
	if not RoleCatalog.has_role(&"zeitwaechter"):
		return
	assert_eq(RoleCatalog.faction_of(&"zeitwaechter"), Faction.VILLAGE, "Dorf")
	assert_true(RoleCatalog.stealable(&"zeitwaechter"), "stehlbar")
	var s := _ok(_state([W, "schattenhund", ZW, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), Command.start_night(), "Nacht")
	assert_eq(s.night_plan if s != null else [] as Array[StringName], [&"schattenhund:2", &"pack", &"zeitwaechter:3"] as Array[StringName], "Kartenzahl 9,5: nach Schattenhund und Rudel (DA-106)")


func test_freeze_drops_later_steps_but_keeps_earlier_effects() -> void:
	# DA-106: Der Zeitwächter (9,5) friert erst nach dem Rudel (2,0) ein; dessen Opfer stirbt trotzdem.
	var s := _state([W, ZW, SE, "fenrir", "schwarze-witwe", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	var log: Array[GameEvent] = []
	s = _night(s, {"schutzengel:3@": [7], "pack@": [6], "zeitwaechter:2@use": true}, log)
	if s == null:
		return
	assert_eq(_opened(log, "zeitwaechter:2").size(), 1, "Frage einfrieren?")
	_codec_same(s, "eingefroren")
	var dawn := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_deaths(dawn.events), [[6, "NIGHT_KILL"]], "Rudelopfer vor dem Einfrieren stirbt")
	var public := events_of_type(dawn.events, "NightFrozen")
	assert_true(public.size() == 1 and public[0].visibility == Visibility.PUBLIC, "öffentliche Meldung")
	assert_eq(int(dawn.state.growth.get(4, 0)), 0, "Fenrir wächst nicht")
	# Einmal je Leben: in Nacht 2 kein Schritt mehr.
	log = []
	s = _dawn(dawn.state, {"pack@": [8]}, log)
	assert_eq(_opened(log, "zeitwaechter:2").size(), 0, "nur einmal")
	assert_eq(_deaths(log), [[8, "NIGHT_KILL"]], "Nacht 2 normal")
	assert_eq(int(s.growth.get(4, 0)) if s != null else 0, 1, "Fenrir wächst in Nacht 2")


func test_decline_keeps_ability_and_earlier_poison_still_due() -> void:
	# Giftpranke in Nacht 1 (fällig Nacht 3); in Nacht 3 friert der Zeitwächter ein: das Gift wirkt trotzdem.
	var s := _state(["giftwolf", ZW, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"zeitwaechter:2@use": false, "giftwolf:1@": [5]}, log)
	s = _dawn(s, {"zeitwaechter:2@use": false}, log)
	assert_eq(_opened(log, "zeitwaechter:2").size(), 2, "Verzicht behält die Fähigkeit")
	log = []
	s = _dawn(s, {"zeitwaechter:2@use": true}, log)
	assert_eq(_deaths(log), [[5, "WOLF_POISON"]], "fällige Giftpranke tritt ein")
	assert_eq(events_of_type(log, "NightFrozen").size(), 1, "eingefroren")


func test_load_rejects_frozen_outside_night() -> void:
	var s := _state([W, ZW, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	if s == null:
		return
	var d := s.to_dict()
	d["night_frozen"] = true
	assert_true(GameState.from_dict(d) == null, "eingefroren nur in der Nacht")


func test_win_confirmed_in_frozen_night_still_loads() -> void:
	# Regressionstest (Fuzz, andere Seeds): Siegbestätigung mitten in der eingefrorenen Nacht → Spielende bleibt ladbar.
	var s := _state([W, ZW, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _night(s, {"zeitwaechter:2@use": true})
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "letzter Wolf stirbt (Korrektur)")
	if s == null or s.open_candidates().is_empty():
		fail("Dorfsieg erwartet")
		return
	s = _ok(s, Command.confirm_win(s.open_candidates()[0].id), "Sieg bestätigt")
	_codec_same(s, "Spielende in eingefrorener Nacht")
