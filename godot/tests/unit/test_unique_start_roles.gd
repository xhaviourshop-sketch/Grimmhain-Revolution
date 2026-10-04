extends TestCase
## PE-07 (Option B): Bei Spielbeginn höchstens eine Kopie je Rolle, auch der Dorfbewohner.
## Ausnahmen ohne Obergrenze (1 bis Personenzahl): Die Gebundenen und, seit DA-90, der Werwolf. Später durch Verwandlung,
## Erbe, Tausch oder Korrektur entstehende gleiche Rollen sind nicht Gegenstand dieser Grenze.


func _manual(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 5)


func _random(pool: Array) -> Command:
	return Command.start_game({
		"round_id": "unique", "seed": 99, "assignment": "random",
		"players": Fixtures.players(pool.size()), "seat_order": Fixtures.identity_order(pool.size()), "role_pool": pool,
	})


func _expect_reject(command: Command, expected: String, label: String) -> void:
	var state := GameState.new()
	var before := CanonicalJson.stringify(state.to_dict())
	var result := RulesEngine.apply(state, command)
	assert_false(result.ok, "%s: abgelehnt" % label)
	assert_eq(String(result.error), expected, "%s: Fehlergrund" % label)
	assert_true(result.events.is_empty(), "%s: keine Ereignisse" % label)
	assert_eq(CanonicalJson.stringify(state.to_dict()), before, "%s: Zustand und Zufall unverändert" % label)


func _expect_start(command: Command, label: String) -> GameState:
	var result := RulesEngine.apply(GameState.new(), command)
	assert_true(result.ok, "%s: Start angenommen (%s)" % [label, result.error])
	return result.state if result.ok else null


func test_catalog_limit_is_one_except_the_bound_and_the_werewolf() -> void:
	for id: Variant in RoleCatalog.ROLES:
		var unlimited := StringName(id) == RoleCatalog.DIE_GEBUNDENEN or StringName(id) == RoleCatalog.WERWOLF
		var expected := RoleCatalog.UNLIMITED if unlimited else 1
		assert_eq(RoleCatalog.max_copies(StringName(id)), expected, "Höchstzahl %s" % id)


func test_two_villagers_are_rejected() -> void:
	_expect_reject(_manual(["werwolf", "dorfbewohner", "dorfbewohner", "das-orakel", "waldhexe", "schutzengel"]),
		"role_limit_exceeded", "zwei Dorfbewohner (manuell)")
	_expect_reject(_random(["werwolf", "dorfbewohner", "dorfbewohner", "das-orakel", "waldhexe", "schutzengel"]),
		"role_limit_exceeded", "zwei Dorfbewohner (zufällig)")


func test_three_werewolves_start_count_for_the_win_and_reload() -> void:
	var roles := ["werwolf", "werwolf", "werwolf", "das-orakel", "waldhexe", "schutzengel", "sensentraeger"]
	for command: Command in [_manual(roles), _random(roles)]:
		var state := _expect_start(command, "drei Werwölfe")
		if state != null:
			assert_eq(state.players.values().filter(func(p: Player) -> bool: return p.role_id == RoleCatalog.WERWOLF).size(), 3, "drei Werwölfe in der Partie")
	var cmds: Array[Command] = [_manual(roles)]
	for id: int in [1, 2]:
		cmds.append(CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": true}, "Test"))
	var run := RulesEngine.replay(cmds)
	assert_true(run.ok, "zwei Werwölfe getötet (%s)" % run.error)
	if not run.ok:
		return
	assert_eq(run.state.open_candidates().size(), 0, "ein Werwolf lebt: kein Dorfsieg")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
	assert_true(loaded.ok, "Spielstand lädt (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(run.state.to_dict()), "Zustand nach Laden identisch")
	cmds.append(CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}, "Test"))
	run = RulesEngine.replay(cmds)
	assert_true(run.ok, "dritter Werwolf getötet (%s)" % run.error)
	if run.ok:
		var kinds: Array[String] = []
		for c: WinCandidate in run.state.open_candidates():
			kinds.append(String(c.kind))
		assert_eq(kinds, ["village"] as Array[String], "Dorfsieg erst mit dem letzten Werwolf")


func test_two_equal_special_roles_are_rejected() -> void:
	_expect_reject(_manual(["werwolf", "das-orakel", "das-orakel", "dorfbewohner", "waldhexe", "schutzengel"]),
		"role_limit_exceeded", "zwei Orakel")
	_expect_reject(_manual(["werwolf", "rattenfaenger", "rattenfaenger", "dorfbewohner", "waldhexe", "schutzengel"]),
		"role_limit_exceeded", "zwei Rattenfänger")
	var decoys := Command.start_game({
		"round_id": "unique", "seed": 3, "assignment": "random",
		"players": Fixtures.players(6), "seat_order": Fixtures.identity_order(6),
		"role_entries": [{"role_id": "trugbilderwolf", "appears_as": "dorfbewohner"}, {"role_id": "trugbilderwolf", "appears_as": "das-orakel"},
			{"role_id": "dorfbewohner"}, {"role_id": "waldhexe"}, {"role_id": "schutzengel"}, {"role_id": "das-orakel"}],
	})
	_expect_reject(decoys, "role_limit_exceeded", "zwei Trugbilderwölfe mit verschiedenen Scheinrollen")


func test_limit_is_checked_before_missing_factions() -> void:
	_expect_reject(_manual(["dorfbewohner", "dorfbewohner", "das-orakel", "waldhexe", "schutzengel", "doktor"]),
		"role_limit_exceeded", "Dublette ohne Wolf")


func test_the_bound_may_appear_any_number_of_times() -> void:
	var one := _expect_start(_manual(["werwolf", "die-gebundenen", "dorfbewohner", "das-orakel", "waldhexe", "schutzengel"]), "eine Gebundene")
	if one != null:
		assert_eq(one.players[2].role_id, RoleCatalog.DIE_GEBUNDENEN, "eine Gebundene")
	var four := _expect_start(_manual(["werwolf", "die-gebundenen", "die-gebundenen", "die-gebundenen", "die-gebundenen", "dorfbewohner"]), "vier Gebundene")
	if four != null:
		assert_eq(four.players.values().filter(func(p: Player) -> bool: return p.role_id == RoleCatalog.DIE_GEBUNDENEN).size(), 4, "vier Gebundene")
	var pool: Array = ["werwolf"]
	for i: int in 23:
		pool.append("die-gebundenen")
	_expect_start(_random(pool), "23 Gebundene, zufällig")
	_expect_reject(_manual(["die-gebundenen", "die-gebundenen", "die-gebundenen", "die-gebundenen", "die-gebundenen", "die-gebundenen"]),
		"missing_wolf_role", "nur Gebundene: sonstige Pflichtregeln gelten weiter")


func test_unique_starts_with_6_and_24_persons() -> void:
	for count: int in [6, 24]:
		var roles := Fixtures.unique_roles(count)
		var manual := _expect_start(_manual(roles), "%d Personen (manuell)" % count)
		if manual != null:
			assert_eq(manual.alive_ids().size(), count, "%d Personen leben" % count)
		var random := _expect_start(_random(roles), "%d Personen (zufällig)" % count)
		if random != null:
			var assigned: Array = random.players.values().map(func(p: Player) -> String: return String(p.role_id))
			assigned.sort()
			var expected := roles.duplicate()
			expected.sort()
			assert_eq(assigned, expected, "%d Personen: zufällig nur die bestätigte Besetzung verteilt" % count)


func test_every_person_count_has_a_unique_start() -> void:
	for count: int in range(6, 25):
		var roles := Fixtures.unique_roles(count)
		var seen := {}
		for r: Variant in roles:
			assert_false(seen.has(r), "%d Personen: %s nur einmal" % [count, r])
			seen[r] = true
		_expect_start(_manual(roles), "%d Personen" % count)
