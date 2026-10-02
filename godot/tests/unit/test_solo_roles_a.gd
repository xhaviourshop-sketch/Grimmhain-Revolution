extends TestCase
## DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“ (28.09.2026, E-01 bis E-04).
##   Rattenfänger (4.2): jede Nacht 1 oder 2 andere lebende Unverzauberte; Sieg lebend, wenn alle anderen
##     Lebenden verzaubert sind.
##   Pestbringerin (7.2): jede Nacht eine andere gesunde Lebende infizieren; jeden Morgen steckt jede lebende
##     Infizierte einen per Seed gezogenen nächsten lebenden Nachbarn an; Sieg lebend bei Totalinfektion.
##   Prophet des Untergangs (8.6): Nacht 1 drei andere markieren; alle tot → dauerhaft freigeschaltet, jede Nacht
##     freiwillig töten (Tod am Morgen); freigeschaltet und lebend ohne lebenden Wolf: Sieg statt des Dorfes.
##   Todesprediger (6.6, nur Nacht 1): geheime Vorhersage einer künftigen Nacht oder eines Tages; Tod genau dann →
##     Sieg erfüllt (wird fortan vorgeschlagen).

const RF := "rattenfaenger"
const PB := "pestbringerin"
const PR := "prophet-des-untergangs"
const TP := "todesprediger"
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
	if p.owner == PendingPrompt.OWNER_WITCH:
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm")
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Antworten {"<rolle>:<id>": Ziele}; alle anderen Schritte ohne Wirkung. Endet vor EndNight.
func _night(s: GameState, answers: Dictionary = {}) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Tagesende")
	if s != null and s.phase != Phase.NIGHT:
		s = _ok(s, Command.start_night(), "Nachtbeginn")
	for guard: int in 60:
		if s == null:
			return null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
			if answers.has(key) and p.stage == &"":
				s = _ok(s, Command.answer_prompt(p.id, answers[key]), "Antwort %s" % key)
			elif answers.has(key):
				s = _ok(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": String(p.stage), "prediction": answers[key]}), "Vorhersage")
			else:
				s = _ok(s, _auto(s), "ohne Wirkung %s" % key)
			continue
		var step := RulesEngine.next_step_id(s)
		if step == "":
			return s
		s = _ok(s, Command.begin_step(step), "Schritt %s" % step)
	fail("Nacht endet nicht")
	return null


func _dawn(s: GameState, answers: Dictionary = {}) -> CommandResult:
	s = _night(s, answers)
	return apply_ok(s, Command.end_night(), "Morgen") if s != null else null


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _solo_winners(s: GameState, reason: StringName) -> Array[int]:
	var out: Array[int] = []
	for c: WinCandidate in s.open_candidates():
		if c.reason_key == reason:
			out.append(c.beneficiary_ids[0])
	return out


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entries() -> void:
	for pair: Array in [[RF, 42], [PB, 72], [PR, 86], [TP, 66]]:
		assert_true(RoleCatalog.has_role(StringName(pair[0])), "%s im Katalog" % pair[0])
		if RoleCatalog.has_role(StringName(pair[0])):
			assert_eq(RoleCatalog.faction_of(StringName(pair[0])), Faction.SOLO, "%s Einzelsieg" % pair[0])
			assert_eq(RoleCatalog.night_priority(StringName(pair[0])), pair[1], "%s Priorität" % pair[0])
	assert_true(RoleCatalog.first_night_only(&"todesprediger"), "Todesprediger nur Nacht 1")


# --- Rattenfänger ---------------------------------------------------------------------------------

func test_pied_piper_charms_and_wins_after_last_uncharmed_dies() -> void:
	var r := _dawn(_state([W, RF, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), {"rattenfaenger:2": [3, 4]})
	if r == null:
		return
	assert_eq(r.state.charms.size(), 2, "zwei verzaubert")
	r = _dawn(r.state, {"rattenfaenger:2": [1, 5]})
	if r == null:
		return
	var s := r.state
	assert_eq(s.charms.size(), 4, "vier verzaubert, auch der Wolf")
	_codec_same(s, "Verzauberung")
	# Die letzte unverzauberte Person wird gelyncht → Sieg (bei jeder Siegprüfung, nicht nur nach Verzauberung).
	s = _ok(s, Command.nominate(3, 6), "Nominierung")
	s = _ok(s, Command.decide_execution(6), "letzte Unverzauberte gelyncht")
	assert_eq(_solo_winners(s, WinCandidate.REASON_PIED_PIPER) if s != null else [0], [2] as Array[int], "Rattenfänger gewinnt")


func test_pied_piper_targets_and_dead_piper() -> void:
	var s := _state([W, RF, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _ok(s, Command.start_night(), "Nacht")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Rattenfänger") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [1, 3, 4, 5, 6] as Array[int], "andere Lebende")
	assert_eq([p.min_count, p.max_count], [1, 2], "1 oder 2")
	apply_rejected(s, Command.answer_prompt(p.id, [2]), "invalid_target", "nicht er selbst")
	# Toter Rattenfänger gewinnt nie.
	var t := _state([W, RF, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	t.charms = [{"piper_id": 2, "target_id": 1}, {"piper_id": 2, "target_id": 3}, {"piper_id": 2, "target_id": 4}, {"piper_id": 2, "target_id": 5}, {"piper_id": 2, "target_id": 6}]
	t = _ok(t, _gm("kill", {"target_id": 2, "trigger_effects": false}), "Rattenfänger tot")
	assert_eq(_solo_winners(t, WinCandidate.REASON_PIED_PIPER) if t != null else [0], [] as Array[int], "nur lebend")


# --- Pestbringerin --------------------------------------------------------------------------------

func test_plague_bringer_infects_and_spreads_to_living_neighbours() -> void:
	var s := _state([W, PB, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	var r := _dawn(s, {"pestbringerin:2": [5]})
	if r == null:
		return
	s = r.state
	assert_true(s.infected.has(5), "Ziel infiziert")
	assert_eq(s.infected.size(), 2, "am Morgen ein Nachbar angesteckt")
	var spread := events_of_type(r.events, "PlagueSpread")
	assert_true(spread.size() == 1 and [4, 6].has(int(spread[0].data["target_id"])), "nächster lebender Nachbar")
	# Replay gleich (Seed).
	var again := _dawn(_state([W, PB, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), {"pestbringerin:2": [5]})
	assert_eq(again.state.infected if again != null else [], s.infected, "gleicher Seed, gleiche Ansteckung")
	_codec_same(s, "Infektion")


func test_plague_bringer_wins_alive_with_all_others_infected() -> void:
	var s := _state([W, PB, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	var r := _dawn(s, {"pestbringerin:2": [3]})
	if r == null:
		return
	s = r.state
	s.infected = [1, 3, 4, 5] as Array[int]
	s = _ok(s, Command.nominate(3, 6), "Nominierung")
	s = _ok(s, Command.decide_execution(6), "letzte Gesunde gelyncht")
	assert_eq(_solo_winners(s, WinCandidate.REASON_PLAGUE) if s != null else [0], [2] as Array[int], "Pestbringerin gewinnt")


# --- Prophet des Untergangs ----------------------------------------------------------------------

func test_prophet_marks_unlocks_kills_and_replaces_village_win() -> void:
	var s := _state([W, PR, D, "amalia", "detektiv", "wahnsinniger-kutscher", "schutzengel", "waechter-am-tor"])
	var r := _dawn(s, {"prophet-des-untergangs:2": [3, 4, 5]})
	if r == null:
		return
	s = r.state
	assert_eq(s.prophet_marks.size(), 3, "drei Markierte")
	for id: int in [3, 4, 5]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Markierter %d tot" % id)
	assert_true(s != null and s.prophet_unlocked.has(2), "freigeschaltet")
	s = _ok(s, _gm("revive", {"target_id": 3}), "Markierter wiederbelebt")
	assert_true(s != null and s.prophet_unlocked.has(2), "dauerhaft")
	# Nacht 2: Schutzengel schützt 6, der Prophet tötet 6 → Tod am Morgen trotz Schutz.
	r = _dawn(s, {"schutzengel:7": [6], "prophet-des-untergangs:2": [6]})
	if r == null:
		return
	var died := events_of_type(r.events, "SeatDied").filter(func(e: GameEvent) -> bool: return int(e.data["target_id"]) == 6)
	assert_true(died.size() == 1 and String(died[0].data["cause"]) == "PROPHET_KILL", "Prophetentötung am Morgen")
	# Letzter Wolf stirbt → Sieg des Propheten statt des Dorfes.
	s = _ok(r.state, _gm("kill", {"target_id": 1, "trigger_effects": true}), "letzter Wolf tot")
	if s == null:
		return
	assert_eq(_solo_winners(s, WinCandidate.REASON_PROPHET), [2] as Array[int], "Prophet gewinnt")
	assert_false(s.open_candidates().any(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_NO_WOLVES_ALIVE), "kein Dorfsieg")


# --- Todesprediger --------------------------------------------------------------------------------

func test_death_preacher_wins_on_predicted_day() -> void:
	var s := _state([W, TP, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	s = _ok(s, Command.start_night(), "Nacht 1")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Todesprediger") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	apply_rejected(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "prediction", "prediction": {"kind": "night", "number": 1}}), "invalid_prediction", "nicht die laufende Nacht")
	apply_rejected(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "prediction", "prediction": {"kind": "abend", "number": 2}}), "invalid_prediction", "nur Nacht oder Tag")
	var r := apply_ok(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "prediction", "prediction": {"kind": "day", "number": 1}}), "Tag 1")
	for e: GameEvent in r.events:
		assert_true(e.visibility != Visibility.PUBLIC, "geheim")
	s = _ok(r.state, Command.end_night(), "Morgen")
	s = _ok(s, Command.nominate(3, 2), "Nominierung")
	s = _ok(s, Command.decide_execution(2), "Lynch an Tag 1")
	assert_eq(_solo_winners(s, WinCandidate.REASON_DEATH_PREACHER) if s != null else [0], [2] as Array[int], "Vorhersage erfüllt")


func test_death_preacher_wrong_phase_does_not_win() -> void:
	var s := _state([W, TP, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	var r := _dawn(s, {"todesprediger:2": {"kind": "night", "number": 2}})
	if r == null:
		return
	s = _ok(r.state, Command.nominate(3, 2), "Nominierung")
	s = _ok(s, Command.decide_execution(2), "Lynch an Tag 1")
	assert_eq(_solo_winners(s, WinCandidate.REASON_DEATH_PREACHER) if s != null else [0], [] as Array[int], "falscher Zeitpunkt")
