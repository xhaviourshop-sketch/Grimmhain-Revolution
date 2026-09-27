extends TestCase
## Rolle `siegreicher-wolf` (Victorious Wolf). Regelquelle: Rollentext „Solange er lebt, zählt
## er für die Siegbedingung wie zwei Werwölfe“ (js/core/roles.js, DE/EN gleich, Legacy-Code
## `countLivingWolfPower` gleich), Auslegung docs/role-migration/10-next-decisions.md „Zur
## Kenntnis“: Doppelzählung nur in der Wolfsparität (G-SIEG-2), nicht bei „kein Wolf lebt“
## (G-SIEG-1) und nicht bei Personenzählungen (Manipulator: genau drei Lebende, DR-12).
## Wölfe-Fraktion, zählt als Wolf, kein eigener Nachtschritt, Teil des Rudels (G-PH-6).

const SW := "siegreicher-wolf"


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


func _kinds(s: GameState) -> Array[String]:
	var out: Array[String] = []
	for c: WinCandidate in s.open_candidates():
		out.append(String(c.kind))
	return out


func _roundtrip(run: ReplayResult, commands: Array[Command], label: String) -> void:
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Spielstand lädt (%s)" % [label, loaded.error])
	if loaded.ok:
		assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(run.state.to_dict()), "%s: Zustand nach Laden identisch" % label)
		assert_eq(events_json(loaded.events), events_json(run.events), "%s: Replay-Ereignisse identisch" % label)


func test_production_role() -> void:
	var role := StringName(SW)
	assert_true(RoleCatalog.has_role(role), "im Katalog")
	assert_eq(RoleCatalog.faction_of(role), Faction.WOLVES, "Wölfe")
	assert_true(RoleCatalog.counts_as_wolf(role), "zählt als Wolf")
	assert_eq(RoleCatalog.night_priority(role), 0, "kein eigener Nachtschritt")
	assert_eq(RoleCatalog.appears_as(role), role, "normale Erscheinung")
	assert_false(RoleCatalog.is_valid_appearance(role), "keine zulässige Scheinrolle eines Trugbilderwolfs")
	assert_eq(RoleCatalog.parity_weight(role), 2, "Paritätsgewicht zwei")
	assert_eq(RoleCatalog.parity_weight(&"werwolf"), 1, "Werwolf zählt einfach")
	assert_eq(RoleCatalog.max_copies(role), RoleCatalog.UNLIMITED, "keine eigene Obergrenze (RM-DR-016)")


func test_alone_forms_pack_and_oracle_sees_werwolf() -> void:
	# G-PH-6 / Legacy-Bug F2: Rudelschritt auch ohne `werwolf`; DR-07: Sonderwolf erscheint als Werwolf.
	var run := _run([_start([SW, "das-orakel", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), Command.start_night()] as Array[Command], "Start")
	if not run.ok:
		return
	assert_eq(run.state.night_plan, [&"pack", &"das-orakel:2"] as Array[StringName], "Rudel aus dem Siegreichen Wolf, danach Orakel")
	assert_eq(InformationRules.determine_role(run.state.players[1]), &"werwolf", "Orakel ermittelt Werwolf")


func test_counts_twice_for_parity() -> void:
	# 1 Siegreicher Wolf; 2–6 Dorfbewohner. Stärke 2 gegen 3 → kein Sieg; 2 gegen 2 → Wolfssieg.
	var cmds: Array[Command] = [_start([SW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(2), _kill(3)]
	var run := _run(cmds, "zwei Tote")
	if not run.ok:
		return
	assert_eq(run.state.open_candidates().size(), 0, "2 gegen 3: kein Sieg")
	cmds.append(_kill(4))
	run = _run(cmds, "drei Tote")
	if not run.ok:
		return
	var c := sole_candidate(run.state)
	assert_true(c != null and String(c.kind) == "wolves", "2 gegen 2: Wolfssieg")
	if c != null:
		assert_eq(int(c.reason_args["wolves"]), 2, "Paritätswert zählt doppelt")
		assert_eq(int(c.reason_args["non_wolves"]), 2, "Nicht-Wölfe")
	_roundtrip(run, cmds, "Parität")


func test_dead_counts_zero_and_village_needs_no_living_wolf() -> void:
	# 1 Siegreicher Wolf; 2 Werwolf; 3–7 Dorfbewohner.
	var cmds: Array[Command] = [_start([SW, "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(1), _kill(3), _kill(4)]
	var run := _run(cmds, "Siegreicher tot")
	if not run.ok:
		return
	# Lebend: 2 (Werwolf), 5, 6, 7 → 1 gegen 3; lebte er, wären es 3 gegen 3.
	assert_eq(run.state.open_candidates().size(), 0, "toter Siegreicher zählt nicht")
	cmds.append(_kill(2))
	run = _run(cmds, "letzter Wolf tot")
	if run.ok:
		assert_eq(_kinds(run.state), ["village"] as Array[String], "Dorfsieg erst ohne lebenden Wolf")


func test_multiple_copies_each_count_twice() -> void:
	# 1, 2 Siegreicher Wolf; 3–7 Dorfbewohner. Nach einem Tod: 4 gegen 4.
	var cmds: Array[Command] = [_start([SW, SW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(3)]
	var run := _run(cmds, "zwei Kopien")
	if not run.ok:
		return
	var c := sole_candidate(run.state)
	assert_true(c != null and String(c.kind) == "wolves" and int(c.reason_args["wolves"]) == 4, "jede Kopie zählt doppelt")


func test_revived_counts_twice_again() -> void:
	var cmds: Array[Command] = [_start([SW, "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		_kill(1), _kill(3), _kill(4), _gm("revive", {"target_id": 1})]
	var run := _run(cmds, "Wiederbelebung")
	if not run.ok:
		return
	# Lebend: 1 (2), 2 (1), 5, 6, 7 → 3 gegen 3.
	var c := sole_candidate(run.state)
	assert_true(c != null and String(c.kind) == "wolves" and int(c.reason_args["wolves"]) == 3, "wiederbelebt zählt wieder doppelt")
	_roundtrip(run, cmds, "Wiederbelebung")


func test_apprentice_inherits_and_counts_twice_immediately() -> void:
	# Korrekturrunde 2: Siegbedingungen der geerbten Rolle gelten sofort.
	# 1 Siegreicher; 2 Werwolf; 3 Lehrling; 4–8 Dorfbewohner. Nacht 1: Lehrling wählt den Siegreichen.
	var cmds: Array[Command] = [_start([SW, "werwolf", "lehrling", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_stage_targets(1, "candidates", [1, 2, 4])]
	var run := _run(cmds, "Kandidaten")
	if not run.ok:
		return
	var options: Array = run.state.pending_prompt.partial["options"]
	cmds.append_array([Command.create(Command.ANSWER_PROMPT, {"prompt_id": 1, "stage": "option", "option": options.find(SW)}),
		Command.answer_choice(1, "confirm", true), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(), _kill(1)])
	run = _run(cmds, "Erbe")
	if not run.ok:
		return
	assert_eq(String(run.state.players[3].role_id), SW, "Lehrling erbt")
	assert_eq(run.state.open_candidates().size(), 0, "3 gegen 5: kein Sieg")
	cmds.append_array([_kill(4), _kill(5)])
	run = _run(cmds, "Parität mit Erbe")
	if not run.ok:
		return
	var c := sole_candidate(run.state)
	assert_true(c != null and String(c.kind) == "wolves" and int(c.reason_args["wolves"]) == 3, "Erbe zählt sofort doppelt")
	_roundtrip(run, cmds, "Erbe")


func test_role_correction_recomputes_parity() -> void:
	var cmds: Array[Command] = [_start([SW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(2), _kill(3),
		_gm("set_role", {"target_id": 1, "role_id": "werwolf"}), _kill(4)]
	var run := _run(cmds, "Korrektur")
	if run.ok:
		# Lebend: 1 (Werwolf), 5, 6 → 1 gegen 2.
		assert_eq(run.state.open_candidates().size(), 0, "nach Rollenkorrektur einfach gezählt")


func test_manipulator_counts_persons_not_weight() -> void:
	# DR-12 zählt Personen: 1 Siegreicher, 2 Manipulator, 3 Dorfbewohner leben → genau drei Lebende.
	var cmds: Array[Command] = [_start([SW, "manipulator", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), _kill(4), _kill(5), _kill(6)]
	var run := _run(cmds, "drei Lebende")
	if not run.ok:
		return
	var kinds := _kinds(run.state)
	kinds.sort()
	# Parität 2 gegen 2 (Wolfssieg) und Manipulator (drei Personen) gleichzeitig, ohne Priorität (DR-02).
	assert_eq(kinds, ["solo", "wolves"] as Array[String], "Manipulator und Wölfe gleichzeitig")


func test_no_secret_in_public_events() -> void:
	var cmds: Array[Command] = [_start([SW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), Command.start_night(),
		Command.answer_prompt(1, [2]), Command.end_night(), Command.nominate(3, 1), Command.decide_execution(1)]
	var run := _run(cmds, "Partie")
	if not run.ok:
		return
	for e: GameEvent in run.events:
		if e.visibility == Visibility.PUBLIC:
			assert_false(CanonicalJson.stringify(e.data).contains(SW), "öffentliches %s nennt die Rolle nicht" % e.type)
