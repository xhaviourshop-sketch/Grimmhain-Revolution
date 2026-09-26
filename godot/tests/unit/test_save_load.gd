extends TestCase
## AS-C07: Speichern und Laden verändern den fachlichen Hash nicht.


func _commands_until_night_two() -> Array[Command]:
	return [
		Fixtures.start_manual(6, [1, 2], 99),
		Command.start_night(),
		Command.answer_prompt(1, [6]),
		Command.end_night(),
		Command.nominate(3, 5),
		Command.decide_execution(5),
		Command.end_day(),
		Command.start_night(),  # Nacht 2, Rudel-Prompt ist offen
	]


func test_save_load_keeps_content_hash() -> void:
	var commands := _commands_until_night_two()
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "Partie bis Nacht 2 gespielt")
	assert_eq(String(run.state.phase), "NIGHT", "mitten in Nacht 2")
	assert_eq(run.state.night_number, 2, "Nacht 2")
	assert_true(run.state.pending_prompt != null, "offener Prompt vorhanden")

	var text := StateCodec.encode(run.state, commands)
	var loaded := StateCodec.decode(text)
	assert_true(loaded.ok, "Laden erfolgreich (%s)" % loaded.error)
	assert_eq(loaded.state.content_hash(), run.state.content_hash(), "fachlicher Hash vor und nach dem Laden")
	assert_eq(loaded.commands.size(), commands.size(), "Befehlsliste vollständig")
	assert_eq(loaded.state.pending_prompt.to_dict(), run.state.pending_prompt.to_dict(), "offener Prompt überlebt Laden")
	assert_eq(StateCodec.encode(loaded.state, loaded.commands), text, "erneutes Speichern ist bytegleich")


func test_save_contains_versions() -> void:
	var commands := _commands_until_night_two()
	var run := RulesEngine.replay(commands)
	var doc: Dictionary = JSON.parse_string(StateCodec.encode(run.state, commands))
	assert_eq(String(doc["format"]), "grimmhain-save", "Formatkennung")
	assert_eq(int(doc["schema_version"]), 1, "schema_version")
	assert_eq(String(doc["rules_version"]), String(GameState.RULES_VERSION), "rules_version")
	assert_eq(String(doc["state_hash"]), run.state.content_hash(), "state_hash = fachlicher Hash")
	assert_true(String(doc["integrity"]).begins_with("sha256:"), "Integritätsprüfsumme vorhanden")


func test_loaded_game_continues_identically() -> void:
	var commands := _commands_until_night_two()
	var run := RulesEngine.replay(commands)
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	var next := Command.answer_prompt(2, [4])
	var from_original := RulesEngine.apply(run.state, next)
	var from_loaded := RulesEngine.apply(loaded.state, next)
	assert_true(from_original.ok and from_loaded.ok, "Folgebefehl auf beiden Zuständen angenommen")
	assert_eq(from_loaded.state.content_hash(), from_original.state.content_hash(), "gleicher Zustand nach Folgebefehl")
	assert_eq(CanonicalJson.stringify(from_loaded.events[0].to_dict()), CanonicalJson.stringify(from_original.events[0].to_dict()), "gleiches Ereignis nach Folgebefehl")
	assert_eq(loaded.events.size(), run.events.size(), "Ereignisprotokoll per Replay wiederhergestellt")


func test_rng_position_survives_save() -> void:
	var start := Fixtures.start_random(8, 2, 4711)
	var run := RulesEngine.replay([start] as Array[Command])
	var loaded := StateCodec.decode(StateCodec.encode(run.state, [start] as Array[Command]))
	assert_true(loaded.ok, "Laden erfolgreich")
	assert_eq(loaded.state.rng.draws, run.state.rng.draws, "Ziehposition")
	assert_eq(loaded.state.rng.randi_range(0, 1000000), run.state.rng.randi_range(0, 1000000), "nächste Ziehung identisch")
