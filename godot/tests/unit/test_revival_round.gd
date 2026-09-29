extends TestCase
## DI-01 (Antwort des Product Owners vom 29.09.2026, ersetzt DR-04 „frei wählbare Rollenaufdeckung“):
## Ob eine Partie eine Wiederbelebungsrunde ist, folgt allein aus der Startbesetzung. Direkte
## Wiederbelebungsrollen (Kutscher, Dr. Victor Frankenstein) lösen den Modus aus; Erbe, Tausch,
## Diebstahl und Korrekturen tun es nicht. Der Modus ist Teil von StartGame-Zustand und bleibt
## während der Partie stabil. Es gibt keine Setup-Option `reveal_role_on_death` mehr.


func _roles_start(roles: Array) -> Command:
	return Fixtures.start_roles(roles)


const PLAIN := ["werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]


func test_plain_game_is_no_revival_round() -> void:
	var r := apply_ok(GameState.new(), _roles_start(PLAIN), "Start ohne Wiederbelebung")
	if r.ok:
		assert_false(r.state.revival_round, "keine Wiederbelebungsrunde")


func test_each_direct_revival_role_triggers_the_mode() -> void:
	for role: String in ["kutscher", "dr-victor-frankenstein"]:
		var roles := PLAIN.duplicate()
		roles[2] = role
		var r := apply_ok(GameState.new(), _roles_start(roles), "Start mit %s" % role)
		if r.ok:
			assert_true(r.state.revival_round, "%s löst die Wiederbelebungsrunde aus" % role)


func test_indirect_carriers_do_not_trigger_the_mode() -> void:
	for role: String in ["lehrling", "seelentauscher", "grabraeuber"]:
		var roles := PLAIN.duplicate()
		roles[2] = role
		var r := apply_ok(GameState.new(), _roles_start(roles), "Start mit %s" % role)
		if r.ok:
			assert_false(r.state.revival_round, "%s allein löst den Modus nicht aus" % role)


func test_random_assignment_derives_from_the_dealt_roles() -> void:
	var pool: Array = ["werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "kutscher"]
	var command := Command.start_game({"round_id": "test-round", "seed": 7, "assignment": "random", "players": Fixtures.players(6),
		"seat_order": Fixtures.identity_order(6), "role_pool": pool})
	var r := apply_ok(GameState.new(), command, "Zufallsverteilung mit Kutscher")
	if r.ok:
		assert_true(r.state.revival_round, "aus der Startbesetzung abgeleitet, unabhängig von der Person")


func _day_one(roles: Array) -> GameState:
	return Fixtures.play([_roles_start(roles), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])


func test_mode_stays_stable_through_the_game() -> void:
	# Ohne Wiederbelebungsrolle: weder eine Wiederbelebung noch ein Rollenwechsel zum Kutscher ändert den Modus.
	var day := _day_one(PLAIN)
	assert_true(day != null, "Tag 1 erreicht")
	if day == null:
		return
	var killed := apply_ok(day, CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": true}), "Person 4 stirbt (Korrektur)")
	var revived := apply_ok(killed.state, CorrectionFixtures.gm("revive", {"target_id": 4}), "Korrektur revive")
	var recast := apply_ok(revived.state, CorrectionFixtures.gm("set_role", {"target_id": 5, "role_id": "kutscher"}), "Korrektur set_role Kutscher")
	assert_false(killed.state.revival_round or revived.state.revival_round or recast.state.revival_round, "manuelle Korrekturen lösen den Modus nicht aus")
	# Mit Wiederbelebungsrolle: Tod und Rollenwechsel der Rolleninhaberin ändern den Modus ebenfalls nicht.
	var roles := PLAIN.duplicate()
	roles[2] = "kutscher"
	var day_r := _day_one(roles)
	assert_true(day_r != null and day_r.revival_round, "Wiederbelebungsrunde am Tag 1")
	if day_r == null:
		return
	var dead := apply_ok(day_r, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}), "Kutscherin stirbt")
	var changed := apply_ok(dead.state, CorrectionFixtures.gm("set_role", {"target_id": 3, "role_id": "dorfbewohner"}), "Rolle wechselt")
	assert_true(dead.state.revival_round and changed.state.revival_round, "der Modus gehört zur Startbesetzung und bleibt bestehen")


func test_old_reveal_option_is_rejected_for_any_value() -> void:
	for value: Variant in [true, false, "ja", 1, null]:
		var payload := Command.start_game({"round_id": "test-round", "seed": 1, "assignment": "manual", "players": Fixtures.players(6),
			"seat_order": Fixtures.identity_order(6), "roles": _map(PLAIN), "reveal_role_on_death": value})
		apply_rejected(GameState.new(), payload, "reveal_option_removed", "Option mit Wert %s" % str(value))


func _map(roles: Array) -> Dictionary:
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	return map


func test_mode_is_stored_logged_saved_and_replayed() -> void:
	var roles := PLAIN.duplicate()
	roles[1] = "dr-victor-frankenstein"
	var commands: Array[Command] = [_roles_start(roles), Command.start_night()]
	var replayed := RulesEngine.replay(commands)
	assert_true(replayed.ok, "Replay")
	if not replayed.ok:
		return
	assert_true(replayed.state.revival_round, "abgeleitet")
	var started := events_of_type(replayed.events, "GameStarted")
	assert_true(started.size() == 1 and started[0].data.get("revival_round") == true, "im Startereignis protokolliert")
	assert_false(started[0].data.has("reveal_role_on_death"), "kein altes Feld im Ereignis")
	var loaded := StateCodec.decode(StateCodec.encode(replayed.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_true(loaded.state.revival_round, "nach dem Laden erhalten")
		assert_eq(loaded.state.content_hash(), replayed.state.content_hash(), "gleicher Hash")
	var other := RulesEngine.replay([_roles_start(PLAIN), Command.start_night()] as Array[Command])
	assert_ne(other.state.content_hash(), replayed.state.content_hash(), "Modus gehört zum fachlichen Zustand")


func test_load_rejects_non_bool_mode() -> void:
	var state := RulesEngine.replay([_roles_start(PLAIN)] as Array[Command]).state
	var d := state.to_dict()
	d["revival_round"] = "true"
	assert_true(GameState.from_dict(d) == null, "ungültiger Wert wird beim Laden abgelehnt")
	var old := state.to_dict()
	old.erase("revival_round")
	old["reveal_role_on_death"] = true
	assert_true(GameState.from_dict(old) == null, "altes Feld ohne neues wird nicht stillschweigend übernommen")


func test_schema_12_save_is_refused_with_a_clear_message_not_reinterpreted() -> void:
	# Die gespeicherte Bedeutung der Aufdeckung hat sich geändert (Schema 13). Ein älterer Spielstand wird
	# ausdrücklich abgelehnt (keine Migration, keine stille Neubewertung); die Datei bleibt unberührt.
	var commands: Array[Command] = [_roles_start(PLAIN), Command.start_night()]
	var state := RulesEngine.replay(commands).state
	var doc: Variant = JSON.parse_string(StateCodec.encode(state, commands))
	assert_true(doc is Dictionary, "Speicherdokument lesbar")
	(doc as Dictionary)["schema_version"] = 12
	var result := StateCodec.decode(JSON.stringify(doc))
	assert_false(result.ok, "Schema 12 wird nicht geladen")
	assert_eq(result.error, &"unsupported_schema_version", "klarer Fehlergrund")
	assert_true(result.detail.contains("12"), "Meldung nennt das gefundene Schema")
	assert_eq(GameState.SCHEMA_VERSION, 13, "Schema 13")
