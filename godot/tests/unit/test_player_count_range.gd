extends TestCase
## Der Core unterstützt jede Personenzahl von 6 bis 24. Seit PE-07 (Regelversion 0.14) besteht jede
## Startbesetzung aus verschiedenen Rollen (Die Gebundenen ausgenommen); geprüft werden 6–24 Personen,
## mindestens eine Wolfsrolle und mindestens eine Dorfrolle. Die Besetzung ist frei, die Rollen wiederholen sich nicht.


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
	var seen := {}
	for id: int in state.alive_ids():
		assert_false(seen.has(state.players[id].role_id), "%s: jede Rolle höchstens einmal (%s)" % [label, state.players[id].role_id])
		seen[state.players[id].role_id] = true
		if state.players[id].counts_as_wolf:
			wolf_count += 1
		elif state.players[id].faction == Faction.VILLAGE:
			village_count += 1
	assert_eq(wolf_count, wolves, "%s: Anzahl Wolfsrollen" % label)
	assert_eq(village_count, count - wolves, "%s: Anzahl Dorfrollen" % label)
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


## Die Besetzung ist frei, solange die Rollen verschieden sind: 1 Wolfsrolle gegen 23 Dorfrollen und so viele Wolfsrollen,
## wie der Katalog ohne Wiederholung hergibt (der Trugbilderwolf braucht eine Scheinrolle und bleibt hier außen vor).
func test_extreme_compositions_are_not_limited() -> void:
	_expect_valid_start(_manual(24, 1), 24, 1, "24 Personen, 1 Wolfsrolle, 23 Dorfrollen")
	var most := 0
	for id: StringName in RoleCatalog.ROLES:
		if RoleCatalog.counts_as_wolf(id) and not RoleCatalog.requires_appearance(id):
			most += 1
	assert_true(most >= 6 and most < 24, "der Katalog hat mehr als eine Handvoll, aber weniger als 24 verschiedene Wolfsrollen (%d)" % most)
	_expect_valid_start(_manual(24, most), 24, most, "24 Personen, %d Wolfsrollen, %d Dorfrollen" % [most, 24 - most])


const UiGame := preload("res://tests/ui/ui_game.gd")


## 24 verschiedene Rollen (`Fixtures.unique_roles`, mit Nachtschritten). Gespielt über GameSession mit den Standardhandlungen der
## Cockpitkarte (UiGame): Das Rudel greift Person 2 (Dorfbewohner) an, Person 11 (Detektiv) wird hingerichtet.
func test_24_player_game_runs_night_and_day() -> void:
	var s := GameSession.new()
	assert_true(s.submit(Fixtures.start_roles(Fixtures.unique_roles(24), 24)).ok, "Start")
	assert_true(s.start_night().ok, "Nacht 1")
	var reached := false
	for i: int in 150:
		if str(UiGame.next_of(s).get("kind")) == "end_night":
			reached = true
			break
		if UiGame.step(s, {"pack/": [2]}) == "":
			fail("Nacht blockiert bei %s" % JSON.stringify(UiGame.next_of(s)).left(200))
			return
	assert_true(reached, "Nacht 1 endet")
	if not reached:
		return
	assert_true(s.end_night().ok, "Morgen")
	for i: int in 30:
		if str(UiGame.next_of(s).get("kind")) == "day":
			break
		if UiGame.step(s) == "":
			fail("Morgen blockiert bei %s" % JSON.stringify(UiGame.next_of(s)).left(200))
			return
	assert_eq(str(UiGame.next_of(s).get("kind")), "day", "Tag beginnt")
	var died: Array = s.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "SeatDied").map(func(e: Dictionary) -> int: return int((e["data"] as Dictionary)["target_id"]))
	assert_eq(died, [2], "Nacht 1: nur das Rudelopfer stirbt")
	var before_day := s.save_text()
	var nominated := s.nominate(3, 11)
	assert_true(nominated.ok, "3 nominiert 11 (%s)" % nominated.error)
	var decided := s.decide_execution(11)
	assert_true(decided.ok, "11 wird hingerichtet (%s)" % decided.error)
	assert_true(s.end_day().ok, "Tagesende")
	assert_true(s.start_night().ok, "Nacht 2")
	var state := RulesEngine.replay(s.commands()).state
	assert_eq(state.alive_ids().size(), 22, "zwei Tote")
	assert_false(state.alive_ids().has(2) or state.alive_ids().has(11), "2 und 11 sind tot")
	assert_true(state.night_plan.size() >= 1, "Nacht 2 hat Schritte")
	var other := GameSession.new()
	assert_eq(other.load_text(before_day), &"", "24er-Spielstand am Morgen lädt")
	assert_eq(RulesEngine.replay(other.commands()).state.content_hash(), other.state_hash(), "24er-Spielstand: fachlicher Hash gleich dem Replay")


func test_bounds_and_minimum_roles_still_enforced() -> void:
	var over := RulesEngine.apply(GameState.new(), _manual(25, 6))
	assert_false(over.ok, "25 Personen abgelehnt")
	assert_eq(String(over.error), "player_count_out_of_range", "Fehlergrund 25 Personen")
	var under := RulesEngine.apply(GameState.new(), _manual(5, 1))
	assert_false(under.ok, "5 Personen abgelehnt")
	assert_eq(String(under.error), "player_count_out_of_range", "Fehlergrund 5 Personen")
	var no_wolf := RulesEngine.apply(GameState.new(), _manual(24, 0))
	assert_eq(String(no_wolf.error), "missing_wolf_role", "24 Personen ohne Werwolf")
	# Ohne Dorfrolle: alle verschiedenen Wolfsrollen des Katalogs und Einzelsiegrollen.
	var no_village_roles: Array = []
	for id: StringName in RoleCatalog.ROLES:
		if RoleCatalog.counts_as_wolf(id) and not RoleCatalog.requires_appearance(id):
			no_village_roles.append(String(id))
	for id: StringName in RoleCatalog.ROLES:
		if no_village_roles.size() < 24 and RoleCatalog.faction_of(id) == Faction.SOLO:
			no_village_roles.append(String(id))
	assert_eq(no_village_roles.size(), 24, "genug verschiedene Rollen ohne Dorf")
	var no_village := RulesEngine.apply(GameState.new(), Fixtures.start_roles(no_village_roles))
	assert_eq(String(no_village.error), "missing_village_role", "24 Personen ohne Dorfrolle")
	var random_no_village := RulesEngine.apply(GameState.new(), Fixtures.start_random(16, 16, 1))
	assert_eq(String(random_no_village.error), "missing_village_role", "zufällige Verteilung ohne Dorfbewohner")
