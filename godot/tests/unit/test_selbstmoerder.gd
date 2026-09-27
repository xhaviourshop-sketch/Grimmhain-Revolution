extends TestCase
## Rolle `selbstmoerder` (Death Seeker). Rollentext: „Gewinnt, sobald 5+ Tote sind und er am Tage
## gelyncht wird.“ Entscheidungen (DECISION-LOG „Rollenaudit“ und „Nachfragen“, 27.09.2026):
## gezählt werden die Personen, die unmittelbar vor seiner Hinrichtung tot sind, mindestens 5
## (RM-DR-138.1, er selbst wäre der sechste); Wiederbelebte zählen nicht (RM-DR-138.3); ein
## abgelehnter Sieg wird nach jeder späteren Zustandsänderung erneut vorgeschlagen (RM-DR-138.4),
## auch nach seiner Wiederbelebung (F-11). Hinrichtung = Ursache LYNCH, auch per Spielleiter
## (Korrekturrunde 4); Tod durch Spiegelung ist keine Hinrichtung (RM-DR-138.5).
## Personen: 1, 2 Werwolf; 3 Selbstmörder; 4–12 Dorfbewohner (12 Personen).

const SM := "selbstmoerder"
const REASON := "death_seeker_lynched"


func _roles() -> Array:
	return ["werwolf", "werwolf", SM, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner",
		"dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _kill(id: int, effects: bool = true) -> Command:
	return _gm("kill", {"target_id": id, "trigger_effects": effects})


## Bis Tag 1, danach `dead` Personen per Korrektur tot.
func _day_with_dead(dead: Array, roles: Array = []) -> Array[Command]:
	var out: Array[Command] = [Fixtures.start_roles(roles if not roles.is_empty() else _roles(), 1), Command.start_night(),
		Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]
	for id: int in dead:
		out.append(_kill(id))
	return out


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _open(s: GameState) -> Array:
	var out: Array = []
	for c: WinCandidate in s.open_candidates():
		out.append([String(c.kind), String(c.reason_key), c.beneficiary_ids.duplicate()])
	out.sort_custom(func(a: Array, b: Array) -> bool: return str(a) < str(b))
	return out


func _roundtrip(run: ReplayResult, commands: Array[Command], label: String) -> void:
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Spielstand lädt (%s)" % [label, loaded.error])
	if loaded.ok:
		assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(run.state.to_dict()), "%s: Zustand identisch" % label)
		assert_eq(events_json(loaded.events), events_json(run.events), "%s: Replay-Ereignisse identisch" % label)


func test_production_role() -> void:
	var role := StringName(SM)
	assert_true(RoleCatalog.has_role(role), "im Katalog")
	assert_eq(RoleCatalog.faction_of(role), Faction.SOLO, "Einzelsieg")
	assert_false(RoleCatalog.counts_as_wolf(role), "zählt nicht als Wolf")
	assert_eq(RoleCatalog.night_priority(role), 0, "kein Nachtschritt")
	assert_true(WinCandidate.REASONS.has(StringName(REASON)), "eigener Siegesgrund")


func test_lynched_with_five_dead_wins() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7, 8])
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3)])
	var run := _run(cmds, "5 Tote vorher")
	if not run.ok:
		return
	assert_eq(_open(run.state), [["solo", REASON, [3]]], "Selbstmörder-Sieg (er ist der sechste Tote)")
	_roundtrip(run, cmds, "Kandidat")


func test_four_dead_is_not_enough() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7])
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3)])
	var run := _run(cmds, "4 Tote vorher")
	if run.ok:
		assert_eq(_open(run.state), [], "kein Sieg: er selbst zählt nicht mit")


func test_revived_do_not_count() -> void:
	# RM-DR-138.3: nur aktuell Tote. 5 starben, eine wurde wiederbelebt → 4.
	var cmds := _day_with_dead([4, 5, 6, 7, 8])
	cmds.append_array([_gm("revive", {"target_id": 8}), Command.nominate(9, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Wiederbelebung")
	if run.ok:
		assert_eq(_open(run.state), [], "Wiederbelebte zählt nicht")


func test_gm_execute_counts_as_lynch() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7, 8])
	cmds.append(_gm("execute", {"target_id": 3}))
	var run := _run(cmds, "Spielleiter-Hinrichtung")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "Hinrichtung per Korrektur ist LYNCH")


func test_other_deaths_do_not_win() -> void:
	# Tod bei ≥ 5 Toten, aber nicht durch Hinrichtung: Korrektur-Tötung, Rudel, Gift → kein Sieg.
	var base := _day_with_dead([4, 5, 6, 7, 8])
	var gm_kill := base.duplicate()
	gm_kill.append(_kill(3))
	var run := _run(gm_kill, "Korrektur-Tötung")
	if run.ok:
		assert_eq(_open(run.state), [], "Korrektur-Tötung ist keine Hinrichtung")
	var pack := base.duplicate()
	pack.append_array([Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.answer_prompt(2, [3]), Command.end_night()])
	run = _run(pack, "Rudel")
	if run.ok:
		assert_eq(_open(run.state), [], "Rudelopfer gewinnt nicht")


func test_mirror_death_is_not_his_execution() -> void:
	# RM-DR-138.5: Er nominiert den Spiegelwolf, dessen Hinrichtung wird auf ihn umgelenkt.
	var roles := _roles()
	roles[1] = "spiegelwolf"
	var cmds := _day_with_dead([4, 5, 6, 7, 8], roles)
	cmds.append_array([Command.nominate(3, 2), Command.decide_execution(2)])
	var run := _run(cmds, "Spiegelung")
	if not run.ok:
		return
	assert_eq(String(run.state.players[3].death.cause), "SPIEGELWOLF_RETALIATE", "stirbt durch Spiegelung")
	assert_eq(_open(run.state), [], "kein Selbstmörder-Sieg")


func test_rejected_offered_again_after_change_and_after_revive() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7, 8])
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3), Command.create(Command.REJECT_WIN, {"reason": "weiter"})])
	var run := _run(cmds, "abgelehnt")
	if not run.ok:
		return
	assert_eq(_open(run.state), [], "nach Ablehnung zunächst kein offener Kandidat")
	var after_death := cmds.duplicate()
	after_death.append(_kill(10))
	run = _run(after_death, "weiterer Tod")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "nach weiterem Tod erneut vorgeschlagen (RM-DR-138.4)")
	var after_revive := cmds.duplicate()
	after_revive.append(_gm("revive", {"target_id": 3}))
	run = _run(after_revive, "Wiederbelebung")
	if run.ok:
		assert_true(run.state.players[3].alive, "lebt wieder")
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "erfüllter Sieg bleibt nach Wiederbelebung (F-11)")
		_roundtrip(run, after_revive, "nach Wiederbelebung")


func test_simultaneous_with_other_wins() -> void:
	# Letzter Wolf lebt nicht mehr: Dorf und Selbstmörder gleichzeitig (DR-02, ohne Priorität).
	var cmds := _day_with_dead([1, 4, 5, 6, 7])
	cmds.append_array([_kill(2), Command.create(Command.REJECT_WIN, {"reason": "Dorfsieg später"})])
	var run := _run(cmds, "Dorf offen")
	if not run.ok:
		return
	# Tote vor der Hinrichtung: 1, 2, 4, 5, 6, 7 = 6.
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3)])
	run = _run(cmds, "Hinrichtung")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]], ["village", "no_wolves_alive", []]], "beide gleichzeitig")


func test_two_death_seekers_only_lynched_wins() -> void:
	var roles := _roles()
	roles[3] = SM
	var cmds := _day_with_dead([5, 6, 7, 8, 9], roles)
	cmds.append_array([Command.nominate(10, 3), Command.decide_execution(3)])
	var run := _run(cmds, "zwei")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "nur der hingerichtete")


func test_apprentice_inherits_and_wins_when_lynched() -> void:
	var roles := _roles()
	roles[3] = "lehrling"
	var cmds: Array[Command] = [Fixtures.start_roles(roles, 1), Command.start_night(), Command.answer_stage_targets(1, "candidates", [1, 3, 5])]
	var run := _run(cmds, "Kandidaten")
	if not run.ok:
		return
	var options: Array = run.state.pending_prompt.partial["options"]
	cmds.append_array([Command.create(Command.ANSWER_PROMPT, {"prompt_id": 1, "stage": "option", "option": options.find(SM)}),
		Command.answer_choice(1, "confirm", true), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(), _kill(3)])
	for id: int in [5, 6, 7, 8]:
		cmds.append(_kill(id))
	cmds.append_array([Command.nominate(9, 4), Command.decide_execution(4)])
	run = _run(cmds, "Erbe hingerichtet")
	if run.ok:
		assert_eq(String(run.state.players[4].death.cause), "LYNCH", "Erbe hingerichtet")
		assert_eq(_open(run.state), [["solo", REASON, [4]]], "Erbe gewinnt (5 Tote vorher: 3, 5, 6, 7, 8)")


func test_six_players_lynch_when_last_alive() -> void:
	# 6 Personen: bei 5 Toten lebt nur er; Selbstnominierung und Hinrichtung → niemand lebt, kein automatischer Sieger (DR-02).
	# Zwischendurch entstehende Siegvorschläge (Parität, Dorf) werden abgelehnt.
	var s := RulesEngine.replay(_day_with_dead([], ["werwolf", "werwolf", SM, "dorfbewohner", "dorfbewohner", "dorfbewohner"])).state
	for id: int in [1, 4, 5, 2, 6]:
		s = apply_ok(s, _kill(id), "Tod %d" % id).state
		if not s.open_candidates().is_empty():
			s = apply_ok(s, Command.create(Command.REJECT_WIN, {"reason": "weiter"}), "Ablehnung").state
	s = apply_ok(s, Command.nominate(3, 3), "Selbstnominierung").state
	s = apply_ok(s, Command.decide_execution(3), "Hinrichtung").state
	assert_eq(s.alive_ids().size(), 0, "niemand lebt")
	assert_eq(_open(s), [], "kein automatischer Sieger, Spielleiter erklärt (DR-02)")
	assert_eq(s.death_seeker_wins, [3] as Array[int], "Bedingung trotzdem festgehalten")


func test_corrupt_states_rejected_on_load() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7, 8])
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Kandidat")
	if not run.ok:
		return
	var unknown: Dictionary = run.state.to_dict()
	unknown["death_seeker_wins"] = [99]
	assert_true(GameState.from_dict(unknown) == null, "unbekannte Person abgelehnt")
	var missing: Dictionary = run.state.to_dict()
	missing["death_seeker_wins"] = []
	assert_true(GameState.from_dict(missing) == null, "Kandidat ohne erfüllte Bedingung abgelehnt")
