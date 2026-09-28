extends TestCase
## Rolle `doppelspion` (Double Agent). Rollentext: „Wacht gemeinsam mit den Werwölfen auf.
## Gewinnt alleine, wenn alle Werwölfe tot sind. Der Angriff des Rachsüchtigen Wolfs verpufft an ihm.“
## Entscheidungen (DECISION-LOG „Rollenaudit“, 27.09.2026): gewinnt nur lebend (RM-DR-155.1);
## lebt ein Doppelspion, wenn kein Wolf mehr lebt, wird nur sein Sieg je Person vorgeschlagen,
## nicht der Dorfsieg (RM-DR-155.3); beim Rudel keine Rollennennung (RM-DR-155.4, nur Ansage);
## Parität: zählt als Nicht-Wolf (RM-DR-155.2, G-SIEG-2). Orakel: tatsächliche Rolle (DR-07).
## Der Rachsüchtige Wolf ist noch nicht im Kern; diese Wechselwirkung folgt mit ihm.

const DS := "doppelspion"
const REASON := "double_agent_no_wolves"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _kill(id: int) -> Command:
	return _gm("kill", {"target_id": id, "trigger_effects": true})


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


## [kind, reason_key, beneficiary_ids] aller offenen Kandidaten, sortiert.
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
	var role := StringName(DS)
	assert_true(RoleCatalog.has_role(role), "im Katalog")
	assert_eq(RoleCatalog.faction_of(role), Faction.SOLO, "Einzelsieg")
	assert_false(RoleCatalog.counts_as_wolf(role), "zählt nicht als Wolf")
	assert_eq(RoleCatalog.night_priority(role), 0, "kein eigener Nachtschritt")
	assert_eq(RoleCatalog.appears_as(role), role, "normale Erscheinung")
	assert_true(WinCandidate.REASONS.has(StringName(REASON)), "eigener Siegesgrund")
	var run := _run([_start(["werwolf", DS, "das-orakel", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), Command.start_night()] as Array[Command], "Start")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack", &"das-orakel:3"] as Array[StringName], "kein Doppelspion-Schritt, Rudel unverändert")
		assert_eq(InformationRules.determine_role(run.state.players[2]), StringName(DS), "Orakel ermittelt Doppelspion (DR-07)")


func test_last_wolf_dies_only_double_agent_offered() -> void:
	# 1 Werwolf; 2 Doppelspion; 3–6 Dorfbewohner. Hinrichtung des letzten Wolfs.
	var cmds: Array[Command] = [_start(["werwolf", DS, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night(), Command.nominate(3, 1), Command.decide_execution(1)]
	var run := _run(cmds, "Hinrichtung")
	if not run.ok:
		return
	assert_eq(_open(run.state), [["solo", REASON, [2]]], "nur der Doppelspion, kein Dorfsieg")
	cmds.append(Command.confirm_win(run.state.open_candidates()[0].id))
	var done := _run(cmds, "Bestätigung")
	if done.ok:
		assert_eq(String(done.state.phase), "GAME_OVER", "Spielende")
		assert_eq(done.state.winner().beneficiary_ids, [2] as Array[int], "Doppelspion gewinnt allein")
	_roundtrip(run, cmds.slice(0, cmds.size() - 1), "Kandidat offen")


func test_dead_double_agent_village_wins() -> void:
	# RM-DR-155.1: nur lebend. Doppelspion stirbt vorher → Dorfsieg.
	var cmds: Array[Command] = [_start(["werwolf", DS, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(2), _kill(1)]
	var run := _run(cmds, "tot")
	if run.ok:
		assert_eq(_open(run.state), [["village", "no_wolves_alive", []]], "Dorfsieg")


func test_two_double_agents_each_own_candidate() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DS, DS, "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(1)]
	var run := _run(cmds, "zwei")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [2]], ["solo", REASON, [3]]], "je Person ein Kandidat, kein Dorfsieg")


func test_one_of_two_dead_only_living_offered() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DS, DS, "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(2), _kill(1)]
	var run := _run(cmds, "einer tot")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "nur der lebende")


func test_counts_as_non_wolf_for_parity() -> void:
	# 1 Werwolf; 2 Doppelspion; 3–6 Dorf. Nach drei Toten: 1 Wolf gegen 2 Nicht-Wölfe → kein Sieg; nach vier: 1 gegen 1.
	var cmds: Array[Command] = [_start(["werwolf", DS, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(3), _kill(4), _kill(5)]
	var run := _run(cmds, "drei Tote")
	if not run.ok:
		return
	# Lebend: 1, 2, 6 → 1 gegen 2.
	assert_eq(_open(run.state), [], "kein Sieg")
	cmds.append(_kill(6))
	run = _run(cmds, "vier Tote")
	if run.ok:
		assert_eq(_open(run.state), [["wolves", "wolf_parity", []]], "Doppelspion zählt als Nicht-Wolf in der Parität")


func test_manipulator_and_double_agent_together() -> void:
	# Lebend nach Toden: 2 Doppelspion, 3 Manipulator, 4 Dorfbewohner; kein Wolf → beide Einzelsiege, kein Dorfsieg.
	var cmds: Array[Command] = [_start(["werwolf", DS, "manipulator", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(5), _kill(6)]
	var run := _run(cmds, "vier Lebende")
	if not run.ok:
		return
	cmds.append(_kill(1))
	run = _run(cmds, "drei Lebende ohne Wolf")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [2]], ["solo", "manipulator_three_alive", [3]]], "beide Einzelsiege gleichzeitig (DR-02)")


func test_apprentice_inherits_double_agent() -> void:
	# 1 Werwolf; 2 Doppelspion; 3 Lehrling; 4–7 Dorfbewohner.
	var cmds: Array[Command] = [_start(["werwolf", DS, "lehrling", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_stage_targets(1, "candidates", [1, 2, 4])]
	var run := _run(cmds, "Kandidaten")
	if not run.ok:
		return
	var options: Array = run.state.pending_prompt.partial["options"]
	cmds.append_array([Command.create(Command.ANSWER_PROMPT, {"prompt_id": 1, "stage": "option", "option": options.find(DS)}),
		Command.answer_choice(1, "confirm", true), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(), _kill(2)])
	run = _run(cmds, "Erbe")
	if not run.ok:
		return
	assert_eq(String(run.state.players[3].role_id), DS, "Lehrling erbt Doppelspion")
	cmds.append(_kill(1))
	run = _run(cmds, "letzter Wolf")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "Erbe gewinnt als Doppelspion")
		_roundtrip(run, cmds, "Erbe")


func test_rejected_is_offered_again_after_change() -> void:
	# Decision Log „Spielende“: ein erfüllter Sieg wird nach Ablehnung bei der nächsten Änderung erneut vorgeschlagen.
	var cmds: Array[Command] = [_start(["werwolf", DS, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(1)]
	var run := _run(cmds, "Kandidat")
	if not run.ok:
		return
	cmds.append_array([Command.create(Command.REJECT_WIN, {"reason": "weiter"}), _kill(3)])
	run = _run(cmds, "nach Ablehnung und weiterem Tod")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [2]]], "erneut vorgeschlagen")


func test_corrupt_candidate_rejected_on_load() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DS, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(1)]
	var run := _run(cmds, "Kandidat")
	if not run.ok:
		return
	var st: Dictionary = run.state.to_dict()
	st["players"][0]["alive"] = true
	st["players"][0].erase("death")
	st["players"][0]["death"] = null
	assert_true(GameState.from_dict(st) == null, "Doppelspion-Kandidat bei lebendem Wolf wird beim Laden abgelehnt")


func test_no_secret_in_public_events() -> void:
	var cmds: Array[Command] = [_start(["werwolf", DS, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night(), Command.nominate(4, 1), Command.decide_execution(1)]
	var run := _run(cmds, "Partie")
	if run.ok:
		for e: GameEvent in run.events:
			if e.visibility == Visibility.PUBLIC:
				assert_false(CanonicalJson.stringify(e.data).contains(DS), "öffentliches %s nennt die Rolle nicht" % e.type)
