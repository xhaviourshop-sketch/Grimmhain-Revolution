extends TestCase
## DR-04 / G-TOD-5: Die Setup-Option „Rolle beim Tod aufdecken“ (`reveal_role_on_death`) ist Teil von
## StartGame und gilt für die ganze Partie. Sie ändert keine Regel, nur die öffentliche Todesansage
## der Anwendungsschicht. Ohne Angabe gilt „Nein“.


func _start(extra: Dictionary) -> Command:
	var payload := {"round_id": "test-round", "seed": 1, "assignment": "manual", "players": Fixtures.players(6),
		"seat_order": Fixtures.identity_order(6), "roles": {"1": "werwolf", "2": "dorfbewohner", "3": "dorfbewohner", "4": "dorfbewohner", "5": "dorfbewohner", "6": "dorfbewohner"}}
	payload.merge(extra)
	return Command.start_game(payload)


func test_default_is_no_reveal() -> void:
	var r := apply_ok(GameState.new(), _start({}), "Start ohne Angabe")
	if r.ok:
		assert_false(r.state.reveal_role_on_death, "Standard: Rolle nicht aufdecken")


func test_setting_is_stored_and_survives_save_load_and_replay() -> void:
	var commands: Array[Command] = [_start({"reveal_role_on_death": true}), Command.start_night()]
	var replayed := RulesEngine.replay(commands)
	assert_true(replayed.ok, "Replay")
	if not replayed.ok:
		return
	assert_true(replayed.state.reveal_role_on_death, "Einstellung übernommen")
	var started := events_of_type(replayed.events, "GameStarted")
	assert_true(started.size() == 1 and started[0].data.get("reveal_role_on_death") == true, "im Startereignis protokolliert")
	var loaded := StateCodec.decode(StateCodec.encode(replayed.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_true(loaded.state.reveal_role_on_death, "nach dem Laden erhalten")
		assert_eq(loaded.state.content_hash(), replayed.state.content_hash(), "gleicher Hash")
	var other := RulesEngine.replay([_start({}), Command.start_night()] as Array[Command])
	assert_ne(other.state.content_hash(), replayed.state.content_hash(), "Einstellung gehört zum fachlichen Zustand")


func test_invalid_value_is_rejected() -> void:
	for bad: Variant in ["ja", 1, null, {}]:
		apply_rejected(GameState.new(), _start({"reveal_role_on_death": bad}), "invalid_reveal_setting", "Wert %s" % str(bad))


func test_load_rejects_non_bool_setting() -> void:
	var state := RulesEngine.replay([_start({"reveal_role_on_death": true})] as Array[Command]).state
	var d := state.to_dict()
	d["reveal_role_on_death"] = "true"
	assert_true(GameState.from_dict(d) == null, "ungültiger Wert wird beim Laden abgelehnt")
