extends TestCase
## AS-C05, AS-C06: gleiche Befehlsliste + gleicher Seed → bytegleiche Eventliste.


func _build_commands(seed_value: int) -> Array[Command]:
	# Rollen werden zufällig über den Seed verteilt. Die Ziele werden aus einem
	# Probelauf gewählt, damit die Befehlsliste für diesen Seed gültig ist.
	var start := Fixtures.start_random(8, 2, seed_value)
	var probe := RulesEngine.apply(GameState.new(), start)
	var villagers: Array[int] = []
	var wolves: Array[int] = []
	for id: int in probe.state.alive_ids():
		if probe.state.players[id].counts_as_wolf:
			wolves.append(id)
		else:
			villagers.append(id)
	return [
		start,
		Command.start_night(),
		Command.answer_prompt(1, [villagers[0]]),
		Command.end_night(),
		Command.nominate(villagers[1], villagers[2]),
		Command.nominate(villagers[2], wolves[0]),
		Command.decide_execution(villagers[2]),
		Command.end_day(),
		Command.start_night(),
		Command.answer_prompt(2, [villagers[3]]),
		Command.end_night(),
		Command.nominate(villagers[1], wolves[0]),
		Command.decide_execution(wolves[0]),
		Command.end_day(),
	]


func _events_json(events: Array[GameEvent]) -> String:
	var list: Array = []
	for e: GameEvent in events:
		list.append(e.to_dict())
	return CanonicalJson.stringify(list)


func test_same_seed_same_events_bytewise() -> void:
	var commands := _build_commands(4711)
	var run_a := RulesEngine.replay(commands)
	var run_b := RulesEngine.replay(commands)
	assert_true(run_a.ok, "Lauf A vollständig angenommen (%s @ %d)" % [run_a.error, run_a.failed_index])
	assert_true(run_b.ok, "Lauf B vollständig angenommen")
	assert_true(run_a.events.size() > 10, "Eventliste nicht trivial")
	assert_eq(_events_json(run_a.events), _events_json(run_b.events), "Eventliste bytegleich")
	assert_eq(run_a.state.content_hash(), run_b.state.content_hash(), "Endzustand identisch")
	assert_eq(CanonicalJson.stringify(run_a.state.to_dict()), CanonicalJson.stringify(run_b.state.to_dict()), "Endzustand bytegleich")


func test_replay_of_serialized_commands_is_identical() -> void:
	# Befehle überleben JSON (Zahlen kommen als float zurück) ohne Abweichung.
	var commands := _build_commands(4711)
	var serialized: Array = []
	for c: Command in commands:
		serialized.append(c.to_dict())
	var restored: Array[Command] = []
	for d: Variant in JSON.parse_string(CanonicalJson.stringify(serialized)):
		restored.append(Command.from_dict(d))
	var original := RulesEngine.replay(commands)
	var replayed := RulesEngine.replay(restored)
	assert_true(replayed.ok, "wiederhergestellte Befehle angenommen")
	assert_eq(_events_json(replayed.events), _events_json(original.events), "Eventliste nach JSON-Rundreise bytegleich")


func test_random_assignment_uses_seed() -> void:
	var a := RulesEngine.apply(GameState.new(), Fixtures.start_random(8, 2, 4711))
	var b := RulesEngine.apply(GameState.new(), Fixtures.start_random(8, 2, 4711))
	assert_true(a.ok and b.ok, "StartGame angenommen")
	var roles_a: Array[String] = []
	var roles_b: Array[String] = []
	var wolf_count := 0
	for id: int in a.state.alive_ids():
		roles_a.append(String(a.state.players[id].role_id))
		roles_b.append(String(b.state.players[id].role_id))
		if a.state.players[id].counts_as_wolf:
			wolf_count += 1
	assert_eq(roles_a, roles_b, "gleiche Zuordnung bei gleichem Seed")
	assert_eq(wolf_count, 2, "Rollenpool vollständig verteilt (2 Wolfsrollen: Werwolf, Blutwolf)")
	assert_true(a.state.rng.draws > 0, "Ziehposition wird mitgezählt")


func test_other_seed_is_stored() -> void:
	var result := RulesEngine.apply(GameState.new(), Fixtures.start_random(8, 2, 4712))
	assert_true(result.ok, "StartGame angenommen")
	assert_eq(result.state.rng.seed_value, 4712, "gespeicherter Seed")
	assert_eq(str(result.state.to_dict()["rng"]["seed"]), "4712", "Seed im serialisierten Zustand")
	# Mindestens einer von mehreren Seeds liefert eine andere Zuordnung als 4711.
	var base := RulesEngine.apply(GameState.new(), Fixtures.start_random(8, 2, 4711)).state
	var differs := false
	for s: int in [4712, 4713, 4714, 4715]:
		var other := RulesEngine.apply(GameState.new(), Fixtures.start_random(8, 2, s)).state
		for id: int in base.alive_ids():
			if other.players[id].role_id != base.players[id].role_id:
				differs = true
	assert_true(differs, "Seed beeinflusst die Zuordnung")
