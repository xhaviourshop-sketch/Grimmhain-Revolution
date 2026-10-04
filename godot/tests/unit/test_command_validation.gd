extends TestCase
## A-13, A-15: Befehle werden vor der Anwendung geprüft; abgelehnte Befehle ändern nichts.


func _players_with_roles(count: int, roles: Array) -> Command:
	var map := {}
	for i: int in count:
		map[str(i + 1)] = roles[i]
	return Command.start_game({
		"round_id": "v", "seed": 1, "assignment": "manual",
		"players": Fixtures.players(count), "seat_order": Fixtures.identity_order(count), "roles": map,
	})


func _expect_reject(state: GameState, command: Command, expected: String, label: String) -> void:
	var before := CanonicalJson.stringify(state.to_dict())
	var result := RulesEngine.apply(state, command)
	assert_false(result.ok, "%s: abgelehnt" % label)
	assert_eq(String(result.error), expected, "%s: Fehlergrund" % label)
	assert_true(result.events.is_empty(), "%s: keine Ereignisse" % label)
	assert_eq(CanonicalJson.stringify(state.to_dict()), before, "%s: Zustand unverändert" % label)


func test_player_count_limits() -> void:
	var five: Array = ["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]
	_expect_reject(GameState.new(), _players_with_roles(5, five), "player_count_out_of_range", "5 Personen")
	var many: Array = []
	for i: int in 25:
		many.append("werwolf" if i < 5 else "dorfbewohner")
	_expect_reject(GameState.new(), _players_with_roles(25, many), "player_count_out_of_range", "25 Personen")


func test_role_rules() -> void:
	var unknown: Array = ["werwolf", "nicht-im-katalog", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
	_expect_reject(GameState.new(), _players_with_roles(6, unknown), "unknown_role", "Rolle außerhalb des Core-Slice")
	var no_wolf: Array = ["dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]  # verschieden (PE-07), sonst greift schon die Startgrenze
	_expect_reject(GameState.new(), _players_with_roles(6, no_wolf), "missing_wolf_role", "ohne Wolf")
	var no_village: Array = ["werwolf", "blutwolf", "rudelvater", "seuchenwolf", "cerberus", "fenrir"]
	_expect_reject(GameState.new(), _players_with_roles(6, no_village), "missing_village_role", "ohne Dorfbewohner")


func test_setup_payload_checks() -> void:
	var cmd := Fixtures.start_manual(6, [1])
	var dup_players := cmd.payload.duplicate(true)
	(dup_players["players"] as Array)[1]["id"] = 1
	_expect_reject(GameState.new(), Command.start_game(dup_players), "duplicate_player_id", "doppelte ID")
	var missing_role := cmd.payload.duplicate(true)
	(missing_role["roles"] as Dictionary).erase("6")
	_expect_reject(GameState.new(), Command.start_game(missing_role), "role_count_mismatch", "Rolle fehlt")
	var empty_name := cmd.payload.duplicate(true)
	(empty_name["players"] as Array)[0]["name"] = "  "
	_expect_reject(GameState.new(), Command.start_game(empty_name), "invalid_player", "leerer Name")
	var bad_seed := cmd.payload.duplicate(true)
	bad_seed["seed"] = -5
	_expect_reject(GameState.new(), Command.start_game(bad_seed), "invalid_seed", "negativer Seed")
	var bad_assignment := cmd.payload.duplicate(true)
	bad_assignment["assignment"] = "irgendwie"
	_expect_reject(GameState.new(), Command.start_game(bad_assignment), "invalid_assignment", "unbekannte Verteilung")
	var started := Fixtures.play([cmd] as Array[Command])
	_expect_reject(started, cmd, "game_already_started", "zweiter Start")


func test_phase_transitions_only_in_order() -> void:
	var fresh := GameState.new()
	_expect_reject(fresh, Command.start_night(), "game_not_started", "Nacht vor Spielstart")
	_expect_reject(fresh, Command.end_night(), "wrong_phase", "Nachtende im Setup")
	_expect_reject(fresh, Command.nominate(1, 2), "wrong_phase", "Nominierung im Setup")
	var started := Fixtures.play([Fixtures.start_manual(6, [1])] as Array[Command])
	assert_eq(String(started.phase), "SETUP", "nach StartGame bleibt die Phase SETUP (Rollenanzeige)")
	_expect_reject(started, Command.end_day(), "wrong_phase", "Tagesende im Setup")
	_expect_reject(started, Command.answer_prompt(1, [2]), "wrong_phase", "Antwort ohne Nacht")
	var night := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night()] as Array[Command])
	_expect_reject(night, Command.start_night(), "wrong_phase", "zweite Nacht während der Nacht")
	_expect_reject(night, Command.decide_execution(2), "wrong_phase", "Hinrichtung nachts")
	var day := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night()] as Array[Command])
	assert_eq(String(day.phase), "DAY", "nach der Morgenauflösung ist Tag")
	_expect_reject(day, Command.start_night(), "day_not_ended", "Nacht vor Tagesende")
	_expect_reject(day, Command.answer_prompt(1, []), "wrong_phase", "Prompt-Antwort am Tag")


func test_unknown_command() -> void:
	_expect_reject(GameState.new(), Command.from_dict({"type": "CastVote", "payload": {}}), "unknown_command", "unbekannter Befehl")


func test_apply_does_not_mutate_input_state() -> void:
	var state := Fixtures.play([Fixtures.start_manual(6, [1])] as Array[Command])
	var before := state.content_hash()
	var result := RulesEngine.apply(state, Command.start_night())
	assert_true(result.ok, "StartNight angenommen")
	assert_eq(state.content_hash(), before, "Eingangszustand bleibt unverändert")
	assert_ne(result.state.content_hash(), before, "neuer Zustand ist verändert")
