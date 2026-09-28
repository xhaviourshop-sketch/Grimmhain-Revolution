extends TestCase
## Schicksalswolf / Fate Wolf (Rollentext; RM-DR-109.1–.3). Offene Punkte technisch/fachlich abgeleitet unter
## delegierter Autorisierung (Decision Log „Schicksalswolf, abgeleitete Regeln“, DA-11 bis DA-15):
##   - Nacht 1 (nur dann, RM-DR-014 = B): genau drei andere Lebende markieren (eigene Markierungen je Schicksalswolf)
##   - Zähler: markierte Personen unter den ersten drei verschiedenen Toten der Partie, jede Ursache, auch vor der
##     Markierung; Wiederbelebte bleiben auf ihrem Platz (RM-DR-109.3 A)
##   - nur Nacht 4 (RM-DR-109.1 A): eigener Schritt nach dem Rudel, bis zu so viele andere Lebende als Zusatzopfer
##   - Zusatzopfer sind Rudelangriffe am Morgen nach Rudel und Zusatzopfer des Rudelvaters (RM-DR-109.2 A: Schutz
##     wirkt, Ritter reagiert, der Nekromant kann umlenken)

const FW := "schicksalswolf"
const D := "dorfbewohner"
const W := "werwolf"
const SE := "schutzengel"
const NK := "nekromant"


func _state(roles: Array, dead: Array = []) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	var s := r.state if r.ok else null
	for id: int in dead:
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
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
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
			if answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
				cmd = Command.answer_prompt(p.id, [])
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


## Tag-Lynch ohne Siegprüfung-Störung: Nominierung und Hinrichtung.
func _lynch(s: GameState, nominator: int, target: int) -> GameState:
	s = _ok(s, Command.nominate(nominator, target), "Nominierung")
	return _ok(s, Command.decide_execution(target), "Hinrichtung")


## Bis zum Beginn von Nacht 4 ohne weitere Tode spielen.
func _to_night4(s: GameState) -> GameState:
	for i: int in 8:
		if s == null or s.night_number >= 3:
			break
		s = _dawn(s)
	return s


# --- Katalog und Markierung -------------------------------------------------------------------------

func test_catalog_entry() -> void:
	assert_true(RoleCatalog.has_role(&"schicksalswolf"), "im Katalog")
	if not RoleCatalog.has_role(&"schicksalswolf"):
		return
	assert_eq(RoleCatalog.faction_of(&"schicksalswolf"), Faction.WOLVES, "Wölfe")
	assert_true(RoleCatalog.counts_as_wolf(&"schicksalswolf"), "zählt als Wolf")
	assert_eq(RoleCatalog.night_priority(&"schicksalswolf"), 25, "Legacy-Stufe 2.5: nach dem Rudel, vor dem Nekromanten")
	assert_false(RoleCatalog.stealable(&"schicksalswolf"), "Grabräuber: markiert nur in Nacht 1")


func test_marks_three_other_living_in_night_one_only() -> void:
	var s := _state([FW, W, D, D, D, D, D, D], [8])
	s = _ok(s, Command.start_night(), "Nacht")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schicksalswolf") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(String(p.owner), FW, "Prompt des Schicksalswolfs")
	assert_eq(p.allowed_ids, [2, 3, 4, 5, 6, 7] as Array[int], "andere Lebende, auch Wölfe")
	assert_eq([p.min_count, p.max_count], [3, 3], "genau drei")
	_rejected_clean(s, Command.answer_prompt(p.id, [3, 4]), "invalid_target_count", "zwei")
	_rejected_clean(s, Command.answer_prompt(p.id, [1, 3, 4]), "invalid_target", "sich selbst")
	_rejected_clean(s, Command.answer_prompt(p.id, [3, 4, 8]), "invalid_target", "Toter")
	_codec_same(s, "offener Prompt")
	var r := apply_ok(s, Command.answer_prompt(p.id, [2, 3, 4]), "Markierung")
	for e: GameEvent in events_of_type(r.events, "FateMarked"):
		assert_true(e.visibility == Visibility.GM, "Markierung nur für den Spielleiter")
	assert_eq(r.state.fate_marks, [{"wolf_id": 1, "target_id": 2}, {"wolf_id": 1, "target_id": 3}, {"wolf_id": 1, "target_id": 4}], "gespeichert")
	s = _ok(r.state, Command.end_night(), "Morgen")
	var log: Array[GameEvent] = []
	s = _to_night4(s)
	s = _dawn(s, {}, log)
	assert_eq(_opened(log, "schicksalswolf:1").size(), 0, "kein Tod unter den ersten drei → kein Schritt in Nacht 4")
	assert_eq(s.night_number if s != null else 0, 4, "Nacht 4 gespielt")


func test_first_three_distinct_dead_count_including_before_marking() -> void:
	# 9 stirbt vor Nacht 1 (zählt, RM-DR-109.3 A); 3 stirbt, wird wiederbelebt und stirbt erneut (zählt einmal).
	var s := _state([FW, W, D, D, D, D, D, D, D], [9])
	s = _dawn(s, {"schicksalswolf:1@": [3, 4, 5], "pack@": [3]})
	s = _ok(s, _gm("revive", {"target_id": 3}), "3 lebt wieder")
	s = _lynch(s, 6, 3)
	if s == null:
		return
	assert_eq(s.fate_first_dead, [9, 3] as Array[int], "verschiedene Tote in Reihenfolge")
	s = _dawn(s, {"pack@": [4]})
	s = _dawn(s, {"pack@": [5]})  # vierter verschiedener Toter zählt nicht mehr
	if s == null:
		return
	assert_eq(s.fate_first_dead, [9, 3, 4] as Array[int], "nur die ersten drei")
	assert_eq(SoloRules.fate_bonus(s, 1), 2, "3 und 4 markiert und unter den ersten drei")
	_codec_same(s, "Zähler")


# --- Nacht 4 ---------------------------------------------------------------------------------------

func test_night_four_extra_victims_are_pack_attacks_with_protection() -> void:
	var s := _state([FW, W, SE, D, D, D, D, D, D, D])
	s = _dawn(s, {"schicksalswolf:1@": [4, 5, 6], "pack@": [4]})
	s = _dawn(s, {"pack@": [5]})
	s = _dawn(s, {"pack@": [7]})
	if s == null:
		return
	assert_eq(SoloRules.fate_bonus(s, 1), 2, "4 und 5 unter den ersten drei")
	var log: Array[GameEvent] = []
	s = _night(s, {"schutzengel:3@": [8], "schicksalswolf:1@": [8, 9]}, log)
	if s == null:
		return
	var steps := _opened(log, "schicksalswolf:1")
	assert_eq(steps.size(), 1, "Schritt in Nacht 4")
	if steps.size() == 1:
		assert_eq([int(steps[0].data["prompt"]["min_count"]), int(steps[0].data["prompt"]["max_count"])], [0, 2], "bis zu zwei Zusatzopfer")
	_codec_same(s, "Zusatzopfer gewählt")
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_deaths(r.events), [[9, "NIGHT_KILL"]], "Schutzengel rettet 8, 9 stirbt als Rudelangriff")
	assert_eq(String(r.state.players[9].death.source_kind), "pack", "Quelle Rudel")
	assert_eq(r.state.fate_kills, [], "nach dem Morgen geleert")
	# Nacht 5: kein Schritt mehr (nur Nacht 4, RM-DR-109.1 A).
	log = []
	s = _dawn(r.state, {}, log)
	assert_eq(_opened(log, "schicksalswolf:1").size(), 0, "verfällt nach Nacht 4")


func test_fate_victim_is_wolf_attack_for_knight() -> void:
	# Ritter 5 als Zusatzopfer: sein Schlag trifft den nächsten Wolf (Zusatzopfer = Wolfsangriff).
	var s := _state([W, FW, D, D, "ritter", D, D, D, D, D])
	s = _dawn(s, {"schicksalswolf:2@": [3, 4, 6], "pack@": [3]})
	s = _dawn(s)
	s = _dawn(s)
	if s == null:
		return
	var log: Array[GameEvent] = []
	s = _dawn(s, {"schicksalswolf:2@": [5]}, log)
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"], [2, "KNIGHT_STRIKE"]], "Ritter stirbt, nächster Wolf 2 fällt")


func test_necromancer_redirects_fate_victim() -> void:
	# Das Zusatzopfer ist der Nekromant 3; er stürbe und lenkt auf 6 um (RM-DR-109.2 A: Rudelangriff, E-17).
	var s := _state([FW, W, NK, D, D, D, D, D, D, D], [10])
	s = _dawn(s, {"schicksalswolf:1@": [4, 5, 6], "pack@": [4]})
	s = _dawn(s, {"pack@": [5]})
	s = _dawn(s, {"pack@": [7]})
	if s == null:
		return
	assert_eq(SoloRules.fate_bonus(s, 1), 2, "4 und 5 unter den ersten drei (10, 4, 5)")
	var log: Array[GameEvent] = []
	s = _dawn(s, {"schicksalswolf:1@": [3], "nekromant:3@targets": [4, 5, 7], "nekromant:3@redirect": [6]}, log)
	if s == null:
		return
	var redirected := events_of_type(log, "NecroRedirected")
	assert_true(redirected.size() == 1 and String(redirected[0].data["slot"]) == "fate:0", "Umlenkung des Zusatzopfers")
	assert_eq(_deaths(log), [[6, "NIGHT_KILL"]], "6 stirbt statt des Nekromanten")


func test_two_fate_wolves_own_marks_and_load_checks() -> void:
	var s := _state([FW, FW, D, D, D, D, D, D])
	s = _dawn(s, {"schicksalswolf:1@": [3, 4, 5], "schicksalswolf:2@": [5, 6, 7], "pack@": [5]})
	if s == null:
		return
	assert_eq([SoloRules.fate_bonus(s, 1), SoloRules.fate_bonus(s, 2)], [1, 1], "je eigener Zähler")
	_codec_same(s, "zwei Schicksalswölfe")
	var bad_cases := [
		["fate_marks", [{"wolf_id": 99, "target_id": 3}]],
		["fate_marks", [{"wolf_id": 1, "target_id": 1}]],
		["fate_first_dead", [5, 5]],
		["fate_first_dead", [3, 4, 5, 6]],
		["fate_kills", [{"wolf_id": 1, "target_id": 3, "redirect_from": -1}]],
	]
	for bad: Array in bad_cases:
		var d := s.to_dict()
		d[bad[0]] = bad[1]
		assert_true(GameState.from_dict(d) == null, "abgelehnt: %s" % str(bad))


func test_win_confirmed_after_fate_kills_chosen_still_loads() -> void:
	# Regressionstest: Zusatzopfer gewählt, dann Sieg noch in Nacht 4 bestätigt → Spielende bleibt ladbar.
	var s := _state([FW, W, D, D, D, D, D, D, D, D])
	s = _dawn(s, {"schicksalswolf:1@": [4, 5, 6], "pack@": [4]})
	s = _dawn(s)
	s = _dawn(s)
	s = _night(s, {"schicksalswolf:1@": [7]})
	if s == null or s.fate_kills.is_empty():
		fail("Zusatzopfer erwartet")
		return
	for id: int in [1, 2]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Wolf %d stirbt" % id)
	if s == null or s.open_candidates().is_empty():
		fail("Dorfsieg erwartet")
		return
	s = _ok(s, Command.confirm_win(s.open_candidates()[0].id), "Sieg bestätigt")
	_codec_same(s, "Spielende mit gewählten Zusatzopfern")
