extends TestCase
## DECISION-LOG „Rollenaudit · Fenrir, Cerberus, Henker“ (28.09.2026).
##   Fenrir: Stufe +1 je Morgen, an dem er lebt; ab Stufe 3 überlebt er einmal jeden Tod außer Korrektur.
##   Cerberus: +1 Kopf je Morgen (max. 3); bei 3 Köpfen fragt die Hinrichtung „abwehren?“ (Feld
##     `cerberus_defend`); Ja: überlebt, Köpfe 0, Hinrichtung gilt als erfolgt.
##   Henker: ab 3 Hinrichtungen der Partie (jede bestätigte, auch ohne Tod) markiert er nachts freiwillig
##     eine Person; sie stirbt zusätzlich bei der Hinrichtung des Folgetags, wenn er dann lebt.

const FE := "fenrir"
const CE := "cerberus"
const HE := "henker"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


## Nacht ohne Aktionen (Rudel ohne Opfer, übrige Schritte: Verzicht) bis zum Tag.
func _quiet_night(s: GameState) -> GameState:
	if s == null:
		return null
	if s.phase != Phase.NIGHT:
		s = _ok(s, Command.start_night(), "Nachtbeginn")
	var guard := 0
	while s != null and (s.pending_prompt != null or RulesEngine.next_step_id(s) != ""):
		guard += 1
		if guard > 30:
			fail("Nacht endet nicht")
			return null
		if s.pending_prompt == null:
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
		else:
			s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Verzicht")
	return _ok(s, Command.end_night(), "Morgen")


func _end_day(s: GameState) -> GameState:
	if s != null and s.day_step != Phase.DAY_EXECUTION_DECIDED:
		s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
	return _ok(s, Command.end_day(), "Tagesende")


func _start_state(roles: Array) -> GameState:
	var r := RulesEngine.replay([_start(roles)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _execute(s: GameState, target: int, defend: Variant = null) -> CommandResult:
	var payload := {"target_id": target}
	if defend != null:
		payload["cerberus_defend"] = defend
	return RulesEngine.apply(s, Command.create(Command.DECIDE_EXECUTION, payload))


func test_production_roles() -> void:
	for role: StringName in [&"fenrir", &"cerberus"]:
		assert_eq(RoleCatalog.faction_of(role), Faction.WOLVES, "%s Wölfe" % role)
		assert_true(RoleCatalog.counts_as_wolf(role), "%s zählt als Wolf" % role)
	assert_eq(RoleCatalog.faction_of(&"henker"), Faction.VILLAGE, "Henker Dorf")
	assert_eq(RoleCatalog.night_priority(&"henker"), 78, "Henker 7.8")


# --- Fenrir ---------------------------------------------------------------------------------------

func test_fenrir_grows_and_survives_once_from_stage_three() -> void:
	var s := _start_state([FE, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"])
	for night: int in [1, 2]:
		s = _quiet_night(s)
		if s == null:
			return
		assert_eq(int(s.growth.get(1, 0)), night, "Stufe nach Nacht %d" % night)
		s = _end_day(s)
	s = _quiet_night(s)
	if s == null:
		return
	assert_eq(int(s.growth.get(1, 0)), 3, "Stufe 3")
	s = _ok(s, Command.nominate(2, 1), "Nominierung")
	var r := _execute(s, 1)
	assert_true(r.ok and r.state.players[1].alive, "überlebt die Hinrichtung einmal")
	s = _end_day(r.state)
	s = _quiet_night(s)
	s = _ok(s, Command.nominate(2, 1), "Nominierung 2")
	r = _execute(s, 1)
	assert_true(r.ok and not r.state.players[1].alive, "zweite Hinrichtung tötet")
	var after := r.state
	if not after.open_candidates().is_empty():
		after = _ok(after, Command.create(Command.REJECT_WIN, {"reason": "weiter"}), "Dorfsieg abgelehnt")
	var revived := _ok(after, _gm("revive", {"target_id": 1}), "Wiederbelebung")
	assert_eq(int(revived.growth.get(1, 0)), 0, "Wiederbelebung setzt die Stufe zurück")


func test_fenrir_below_three_and_gm_kill() -> void:
	var s := _start_state([FE, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	s = _quiet_night(s)
	s = _ok(s, Command.nominate(2, 1), "Nominierung")
	var r := _execute(s, 1)
	assert_true(r.ok and not r.state.players[1].alive, "Stufe 1: Hinrichtung tötet")


# --- Cerberus -------------------------------------------------------------------------------------

func _cerberus_three(roles: Array) -> GameState:
	var s := _start_state(roles)
	for i: int in 3:
		s = _quiet_night(s)
		if i < 2:
			s = _end_day(s)
	return s


func test_cerberus_heads_and_defence() -> void:
	var roles := [CE, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"]
	var s := _cerberus_three(roles)
	if s == null:
		return
	assert_eq(int(s.growth.get(1, 0)), 3, "drei Köpfe")
	s = _ok(s, Command.nominate(2, 1), "Nominierung")
	var missing := _execute(s, 1)
	assert_true(not missing.ok and String(missing.error) == "cerberus_decision_required", "Entscheidung „abwehren?“ nötig")
	var defend := _execute(s, 1, true)
	assert_true(defend.ok and defend.state.players[1].alive, "abgewehrt")
	if defend.ok:
		assert_eq(int(defend.state.growth.get(1, 0)), 0, "Köpfe auf 0")
		assert_eq(String(defend.state.day_step), "EXECUTION_DECIDED", "Hinrichtung des Tages gilt als erfolgt")
		assert_eq(defend.state.executions_count, 1, "zählt als Hinrichtung")
	var accept := _execute(s, 1, false)
	assert_true(accept.ok and not accept.state.players[1].alive, "ohne Abwehr stirbt er")


func test_cerberus_heads_cap_at_three() -> void:
	var s := _cerberus_three([CE, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	s = _end_day(s)
	s = _quiet_night(s)
	if s != null:
		assert_eq(int(s.growth.get(1, 0)), 3, "höchstens drei Köpfe")


# --- Henker ---------------------------------------------------------------------------------------

## Henker 2; drei Hinrichtungen an Tag 1–3 (Personen 9, 10, 11), danach Nacht 4. 12 Personen (vorher 14).
func _hangman_active() -> GameState:
	# 12 Personen (PE-07: verschiedene Rollen; außer den drei Sonderrollen gibt es nur neun Dorfrollen ohne Nachtschritt).
	var s := _start_state(["werwolf", HE, "dorfbewohner", "selbstmoerder", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor",
		"nachtwaechter", "ritter", "dorfwache", "der-weise"])  # 9, 10, 11 werden hingerichtet: kein Weiser (verlangt einen Fluch)
	for victim: int in [9, 10, 11]:
		s = _quiet_night(s)
		if s == null:
			return null
		assert_false(s.night_plan.has(&"henker:2"), "vor drei Hinrichtungen kein Henker-Schritt")
		s = _ok(s, Command.nominate(3, victim), "Nominierung")
		s = _ok(s, Command.decide_execution(victim), "Hinrichtung")
		s = _end_day(s)
	s = _ok(s, Command.start_night(), "Nacht 4")
	return s


func test_hangman_marks_after_three_executions() -> void:
	var s := _hangman_active()
	if s == null:
		return
	assert_eq(s.executions_count, 3, "drei Hinrichtungen")
	assert_true(s.night_plan.has(&"henker:2"), "Henker jetzt aktiv")
	# Nacht 4: Henker markiert den Selbstmörder 4; Tag: Hinrichtung von 5 → 4 stirbt zusätzlich, kein Selbstmörder-Sieg.
	while s.pending_prompt != null or RulesEngine.next_step_id(s) != "":
		if s.pending_prompt == null:
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
		elif StepQueue.step_kind(s.pending_prompt.step_id) == &"henker":
			assert_true(s.pending_prompt.min_count == 0 and not s.pending_prompt.allowed_ids.has(2), "freiwillig, andere Lebende")
			s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Markierung 4")
		else:
			s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Verzicht")
	s = _ok(s, Command.end_night(), "Morgen")
	for id: int in [6, 7]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Tod %d" % id)
	s = _ok(s, Command.nominate(3, 5), "Nominierung 5")
	var r := RulesEngine.apply(s, Command.decide_execution(5))
	assert_true(r.ok, "Hinrichtung")
	if not r.ok:
		return
	var d := r.state.players[4].death
	assert_true(d != null and String(d.cause) == "HANGMAN_EXTRA" and d.source_id == 2, "Markierte stirbt zusätzlich")
	var solo := false
	for c: WinCandidate in r.state.open_candidates():
		solo = solo or c.reason_key == &"death_seeker_lynched"
	assert_false(solo, "Henker-Tod ist keine Hinrichtung des Selbstmörders (RM-DR-138.2)")


func test_hangman_mark_expires_and_needs_living_hangman() -> void:
	var s := _hangman_active()
	if s == null:
		return
	while s.pending_prompt != null or RulesEngine.next_step_id(s) != "":
		if s.pending_prompt == null:
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
		elif StepQueue.step_kind(s.pending_prompt.step_id) == &"henker":
			s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [5]), "Markierung 5")
		else:
			s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Verzicht")
	s = _ok(s, Command.end_night(), "Morgen")
	var dead_hangman := _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": false}), "Henker tot")
	dead_hangman = _ok(dead_hangman, Command.nominate(3, 6), "Nominierung")
	dead_hangman = _ok(dead_hangman, Command.decide_execution(6), "Hinrichtung")
	assert_true(dead_hangman != null and dead_hangman.players[5].alive, "toter Henker: keine Zusatzhinrichtung")
	var skipped := _end_day(s)
	skipped = _quiet_night(skipped)
	skipped = _ok(skipped, Command.nominate(3, 6), "Nominierung Tag 5")
	skipped = _ok(skipped, Command.decide_execution(6), "Hinrichtung Tag 5")
	assert_true(skipped != null and skipped.players[5].alive, "Markierung verfällt ohne Hinrichtung am Folgetag")
