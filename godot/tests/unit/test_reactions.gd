extends TestCase
## Persistente Reaktionswarteschlange mit minimalem Test-Sensenträger
## (`test-sensentraeger`, nur mit test_mode). Besetzung: 1, 2 Werwölfe;
## 3 Test-Sensenträger; 4–6 Dorfbewohner.


## Nacht 1: Das Rudel tötet den Test-Sensenträger (ID 3). Ergebnis: Morgenauflösung mit offener Reaktion.
func _reaper_killed_at_dawn() -> Array[Command]:
	return [Fixtures.start_reaper_game(), Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night()]


func test_death_queues_reaction_and_blocks_other_commands() -> void:
	# AS-A03 (Kernanteil): offene Pflichtreaktion blockiert Phasenwechsel und Siegbestätigung.
	var run := RulesEngine.replay(_reaper_killed_at_dawn())
	assert_true(run.ok, "Befehle angenommen (%s)" % run.error)
	if not run.ok:
		return
	var s := run.state
	assert_eq(String(s.phase), "DAWN_RESOLUTION", "Morgenauflösung bleibt offen")
	assert_eq(s.reactions.size(), 1, "eine Reaktion eingereiht")
	assert_eq(events_of_type(run.events, "ReactionQueued").size(), 1, "ReactionQueued-Ereignis")
	assert_eq(RulesEngine.next_step_id(s), "reaction:1", "erwarteter Schritt ist die Reaktion")
	apply_rejected(s, Command.nominate(4, 5), "reaction_open", "Nominierung")
	apply_rejected(s, Command.start_night(), "reaction_open", "Nachtbeginn")
	apply_rejected(s, Command.end_day(), "reaction_open", "Tagesende")
	apply_rejected(s, Command.confirm_win(1), "reaction_open", "Siegbestätigung")
	apply_rejected(s, Command.skip_step("reaction:1", "keine Lust"), "step_not_skippable", "Pflichtreaktion überspringen")
	apply_rejected(s, Command.begin_step("reaction:2"), "step_out_of_order", "falsche Reaktion")


func test_reaction_prompt_resolves_with_kill() -> void:
	var s := RulesEngine.replay(_reaper_killed_at_dawn()).state
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion beginnen")
	var prompt := begun.state.pending_prompt
	assert_true(prompt != null, "Reaktions-Prompt offen")
	if prompt == null:
		return
	assert_eq(String(prompt.owner), "reaction", "Prompt gehört zur Reaktion")
	assert_eq(prompt.step_id, "reaction:1", "Schritt-ID")
	assert_false(prompt.cancellable, "Pflichtreaktion ist nicht abbrechbar")
	assert_eq(prompt.allowed_ids, [1, 2, 4, 5, 6] as Array[int], "nur Lebende wählbar")
	apply_rejected(begun.state, Command.cancel_prompt(prompt.id, "doch nicht"), "prompt_not_cancellable", "Abbruch")
	var shot := apply_ok(begun.state, Command.answer_prompt(prompt.id, [1]), "Fluch")
	var died := events_of_type(shot.events, "SeatDied")
	assert_eq(died.size(), 1, "ein Tod")
	if died.size() == 1:
		assert_eq(int(died[0].data["target_id"]), 1, "Ziel")
		assert_eq(String(died[0].data["cause"]), "HUNTER_SHOT", "Ursache")
		assert_eq(String(died[0].data["source_kind"]), "player", "Quelle ist eine Person")
		assert_eq(int(died[0].data["source_id"]), 3, "Quelle ist der Sensenträger")
	assert_eq(events_of_type(shot.events, "ReactionResolved").size(), 1, "ReactionResolved-Ereignis")
	assert_true(shot.state.reactions.is_empty(), "Warteschlange leer")
	assert_eq(String(shot.state.phase), "DAY", "danach beginnt der Tag")


func test_reaction_can_be_declined() -> void:
	var s := RulesEngine.replay(_reaper_killed_at_dawn()).state
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion beginnen").state
	var declined := apply_ok(begun, Command.answer_prompt(begun.pending_prompt.id, []), "Verzicht")
	assert_eq(events_of_type(declined.events, "SeatDied").size(), 0, "kein Tod")
	var resolved := events_of_type(declined.events, "ReactionResolved")
	assert_eq(resolved.size(), 1, "Verzicht protokolliert")
	if resolved.size() == 1:
		assert_eq(int(resolved[0].data["target_id"]), -1, "kein Ziel")
	assert_eq(String(declined.state.phase), "DAY", "Tag beginnt")


func test_chained_reactions_in_fifo_order() -> void:
	var start := Fixtures.start_roles(["werwolf", "werwolf", "test-sensentraeger", "test-sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 1, true)
	var run := RulesEngine.replay([start, Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night(),
		Command.begin_step("reaction:1"), Command.answer_prompt(2, [4])] as Array[Command])
	assert_true(run.ok, "Kette angenommen (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	assert_eq(String(run.state.phase), "DAWN_RESOLUTION", "zweite Reaktion hält die Morgenauflösung offen")
	assert_eq(run.state.reactions.size(), 1, "Folgereaktion eingereiht")
	assert_eq(RulesEngine.next_step_id(run.state), "reaction:2", "Folgereaktion ist der nächste Schritt")
	var done := apply_ok(run.state, Command.begin_step("reaction:2"), "zweite Reaktion").state
	var day := apply_ok(done, Command.answer_prompt(3, []), "Verzicht")
	assert_eq(String(day.state.phase), "DAY", "Tag nach vollständiger Abarbeitung")


func test_multiple_pending_reactions_keep_order() -> void:
	# Zwei Tode während einer offenen Reaktion: stabile Reihenfolge nach Einreihung.
	var start := Fixtures.start_roles(["werwolf", "werwolf", "test-sensentraeger", "test-sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 1, true)
	var run := RulesEngine.replay([start, Command.start_night(), Command.answer_prompt(1, []), Command.end_night(),
		CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}),
		CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command])
	assert_true(run.ok, "Korrekturen angenommen (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 2, "zwei offene Reaktionen")
	assert_eq(run.state.reactions[0].owner_id, 3, "erste Reaktion gehört zu 3")
	assert_eq(run.state.reactions[1].owner_id, 4, "zweite Reaktion gehört zu 4")
	apply_rejected(run.state, Command.begin_step("reaction:2"), "step_out_of_order", "Reihenfolge nicht überspringbar")
	apply_ok(run.state, Command.begin_step("reaction:1"), "erste zuerst")


func test_night_death_reacts_at_dawn() -> void:
	# DR-09: Tod in der Nacht → Reaktion in der Morgenauflösung.
	var run := RulesEngine.replay([Fixtures.start_reaper_game(), Command.start_night(),
		CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}), Command.answer_prompt(1, [])] as Array[Command])
	assert_true(run.ok, "Nacht angenommen (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "Reaktion wartet")
	apply_rejected(run.state, Command.begin_step("reaction:1"), "no_pending_step", "nachts nicht abzuarbeiten")
	var dawn := apply_ok(run.state, Command.end_night(), "Nacht endet")
	assert_eq(String(dawn.state.phase), "DAWN_RESOLUTION", "Reaktion hält den Morgen offen")
	assert_eq(RulesEngine.next_step_id(dawn.state), "reaction:1", "jetzt abzuarbeiten")


func test_reaction_after_execution_is_immediate() -> void:
	var run := RulesEngine.replay([Fixtures.start_reaper_game(), Command.start_night(), Command.answer_prompt(1, []),
		Command.end_night(), Command.nominate(4, 3), Command.decide_execution(3)] as Array[Command])
	assert_true(run.ok, "Hinrichtung angenommen (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	assert_eq(RulesEngine.next_step_id(run.state), "reaction:1", "Reaktion sofort am Tag")
	apply_rejected(run.state, Command.end_day(), "reaction_open", "Tagesende blockiert")


func test_open_reaction_survives_save_load() -> void:
	# AS-A03: Neustart mit offener Reaktion, einmal eingereiht und einmal begonnen.
	for with_prompt: bool in [false, true]:
		var commands := _reaper_killed_at_dawn()
		if with_prompt:
			commands.append(Command.begin_step("reaction:1"))
		var run := RulesEngine.replay(commands)
		var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
		var label := "mit Prompt" if with_prompt else "eingereiht"
		assert_true(loaded.ok, "%s: Laden (%s)" % [label, loaded.error])
		if not loaded.ok:
			continue
		assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: fachlicher Hash" % label)
		assert_eq(loaded.state.reactions.size(), 1, "%s: Reaktion weiterhin offen" % label)
		apply_rejected(loaded.state, Command.end_day(), "reaction_open", "%s: Phasenwechsel blockiert" % label)
		apply_rejected(loaded.state, Command.confirm_win(1), "reaction_open", "%s: Siegbestätigung blockiert" % label)
		var next: Command = Command.answer_prompt(2, [4]) if with_prompt else Command.begin_step("reaction:1")
		var a := RulesEngine.apply(run.state, next)
		var b := RulesEngine.apply(loaded.state, next)
		assert_true(a.ok and b.ok, "%s: Fortsetzung angenommen" % label)
		assert_eq(events_json(b.events), events_json(a.events), "%s: identische Ereignisse" % label)
		assert_eq(b.state.content_hash(), a.state.content_hash(), "%s: identischer Hash" % label)


func test_reaction_replay_is_deterministic() -> void:
	var commands := _reaper_killed_at_dawn()
	commands.append_array([Command.begin_step("reaction:1"), Command.answer_prompt(2, [4])] as Array[Command])
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok and b.ok, "Replay angenommen")
	assert_eq(events_json(a.events), events_json(b.events), "Ereignisse bytegleich")
	assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich")


func test_test_role_requires_test_mode() -> void:
	var cmd := Fixtures.start_roles(["werwolf", "werwolf", "test-sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 1, false)
	apply_rejected(GameState.new(), cmd, "unknown_role", "Testrolle ohne test_mode")
