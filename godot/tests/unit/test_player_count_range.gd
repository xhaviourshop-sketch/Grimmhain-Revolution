extends TestCase
## Der Core-Slice unterstützt jede Personenzahl von 6 bis 24 allein mit
## `dorfbewohner` und `werwolf`. Es gibt keine fest verdrahtete Rollenkomposition
## (keine Obergrenze je Rolle); geprüft werden nur 6–24 Personen und je mindestens
## ein Werwolf und ein Dorfbewohner.


func _manual(count: int, wolves: int) -> Command:
	var wolf_ids: Array[int] = []
	for i: int in wolves:
		wolf_ids.append(i + 1)
	return Fixtures.start_manual(count, wolf_ids, count)


func _expect_valid_start(command: Command, count: int, wolves: int, label: String) -> GameState:
	var result := RulesEngine.apply(GameState.new(), command)
	assert_true(result.ok, "%s: Start angenommen (%s)" % [label, result.error])
	if not result.ok:
		return null
	var state := result.state
	assert_eq(state.alive_ids().size(), count, "%s: alle Personen leben" % label)
	assert_eq(state.seat_order.size(), count, "%s: Sitzreihenfolge vollständig" % label)
	var wolf_count := 0
	var village_count := 0
	for id: int in state.alive_ids():
		if state.players[id].role_id == RoleCatalog.WERWOLF and state.players[id].counts_as_wolf:
			wolf_count += 1
		elif state.players[id].role_id == RoleCatalog.DORFBEWOHNER and state.players[id].faction == Faction.VILLAGE:
			village_count += 1
	assert_eq(wolf_count, wolves, "%s: Anzahl Werwölfe" % label)
	assert_eq(village_count, count - wolves, "%s: Anzahl Dorfbewohner" % label)
	return state


func test_valid_games_with_16_20_24_players() -> void:
	# Rollenzahlen bewusst über den früheren Legacy-Grenzen (Werwolf 5, Dorfbewohner 10).
	for setup: Array in [[16, 4], [20, 6], [24, 8]]:
		var count: int = setup[0]
		var wolves: int = setup[1]
		_expect_valid_start(_manual(count, wolves), count, wolves, "%d Personen, %d Werwölfe (manuell)" % [count, wolves])
		_expect_valid_start(Fixtures.start_random(count, wolves, 4711), count, wolves, "%d Personen, %d Werwölfe (zufällig)" % [count, wolves])


func test_every_player_count_from_6_to_24_starts() -> void:
	for count: int in range(6, 25):
		var wolves := maxi(1, count / 4)
		var result := RulesEngine.apply(GameState.new(), _manual(count, wolves))
		assert_true(result.ok, "%d Personen: Start angenommen (%s)" % [count, result.error])


func test_extreme_compositions_are_not_limited() -> void:
	_expect_valid_start(_manual(24, 1), 24, 1, "24 Personen, 1 Werwolf, 23 Dorfbewohner")
	_expect_valid_start(_manual(24, 23), 24, 23, "24 Personen, 23 Werwölfe, 1 Dorfbewohner")


func test_24_player_game_runs_night_and_day() -> void:
	var run := RulesEngine.replay([
		_manual(24, 6),
		Command.start_night(),
		Command.answer_prompt(1, [24]),
		Command.end_night(),
		Command.nominate(7, 23),
		Command.decide_execution(23),
		Command.end_day(),
		Command.start_night(),
	] as Array[Command])
	assert_true(run.ok, "24er-Partie läuft (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	assert_eq(run.state.alive_ids().size(), 22, "zwei Tote")
	assert_eq(run.state.pending_prompt.allowed_ids.size(), 22, "Rudel wählt aus 22 Lebenden")
	var commands: Array[Command] = [_manual(24, 6), Command.start_night(), Command.answer_prompt(1, [24]), Command.end_night()]
	var saved := RulesEngine.replay(commands)
	var reloaded := StateCodec.decode(StateCodec.encode(saved.state, commands))
	assert_true(reloaded.ok, "24er-Spielstand lädt (%s)" % reloaded.error)
	if reloaded.ok:
		assert_eq(reloaded.state.content_hash(), saved.state.content_hash(), "24er-Spielstand: fachlicher Hash")


func test_bounds_and_minimum_roles_still_enforced() -> void:
	var over := RulesEngine.apply(GameState.new(), _manual(25, 6))
	assert_false(over.ok, "25 Personen abgelehnt")
	assert_eq(String(over.error), "player_count_out_of_range", "Fehlergrund 25 Personen")
	var under := RulesEngine.apply(GameState.new(), _manual(5, 1))
	assert_false(under.ok, "5 Personen abgelehnt")
	assert_eq(String(under.error), "player_count_out_of_range", "Fehlergrund 5 Personen")
	var no_wolf := RulesEngine.apply(GameState.new(), _manual(24, 0))
	assert_eq(String(no_wolf.error), "missing_wolf_role", "24 Personen ohne Werwolf")
	var no_village := RulesEngine.apply(GameState.new(), _manual(24, 24))
	assert_eq(String(no_village.error), "missing_village_role", "24 Personen ohne Dorfbewohner")
	var random_no_village := RulesEngine.apply(GameState.new(), Fixtures.start_random(16, 16, 1))
	assert_eq(String(random_no_village.error), "missing_village_role", "zufällige Verteilung ohne Dorfbewohner")
