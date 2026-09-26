extends TestCase
## BeginStep, SkipStep, CancelPrompt (B-11) im Nachtablauf.
## StartNight beginnt den ersten Nachtschritt selbst; jeder weitere Schritt und
## jeder erneute Beginn nach einem Abbruch verlangt BeginStep.

const PACK_STEP := "night:1:0:pack"


func _night_one() -> GameState:
	return Fixtures.play([Fixtures.start_manual(6, [1, 2]), Command.start_night()] as Array[Command])


func test_start_night_begins_first_step() -> void:
	var state := _night_one()
	assert_eq(RulesEngine.next_step_id(state), PACK_STEP, "erwarteter Schritt")
	assert_true(state.pending_prompt != null, "Rudel-Prompt offen")
	assert_eq(state.pending_prompt.step_id, PACK_STEP, "Prompt gehört zum Rudelschritt")
	assert_eq(state.night_plan, [&"pack"] as Array[StringName], "Nachtplan")
	apply_rejected(state, Command.begin_step(PACK_STEP), "step_already_active", "zweiter Beginn")


func test_cancel_prompt_and_begin_again_restores_state() -> void:
	# AS-A02 (Kernanteil): Abbruch stellt den Zustand vor Beginn des Schritts wieder her.
	var state := _night_one()
	apply_rejected(state, Command.cancel_prompt(1, ""), "reason_required", "ohne Grund")
	apply_rejected(state, Command.cancel_prompt(7, "falscher Prompt"), "prompt_mismatch", "falsche ID")
	var r := apply_ok(state, Command.cancel_prompt(1, "zu früh aufgerufen"), "Abbruch")
	var cancelled := events_of_type(r.events, "PromptCancelled")
	assert_eq(cancelled.size(), 1, "Abbruch-Ereignis")
	if cancelled.size() == 1:
		assert_eq(int(cancelled[0].data["prompt_id"]), 1, "betroffener Prompt")
		assert_eq(String(cancelled[0].data["step_id"]), PACK_STEP, "betroffener Schritt")
		assert_eq(String(cancelled[0].data["reason"]), "zu früh aufgerufen", "Abbruchgrund")
	var not_begun := r.state
	var hash_before_begin := not_begun.content_hash()
	assert_true(not_begun.pending_prompt == null, "kein Prompt offen")
	apply_rejected(not_begun, Command.end_night(), "night_steps_open", "Pflichtschritt nicht still übersprungen")
	apply_rejected(not_begun, Command.cancel_prompt(1, "nochmal"), "no_open_prompt", "nichts abzubrechen")
	apply_rejected(not_begun, Command.begin_step("night:1:1:pack"), "step_out_of_order", "falscher Schritt")
	var begun := apply_ok(not_begun, Command.begin_step(PACK_STEP), "erneuter Beginn")
	assert_eq(begun.state.pending_prompt.id, 2, "neuer Prompt mit neuer ID")
	assert_eq(events_of_type(begun.events, "StepBegun").size(), 1, "StepBegun-Ereignis")
	var again := apply_ok(begun.state, Command.cancel_prompt(2, "noch einmal"), "zweiter Abbruch")
	assert_eq(again.state.content_hash(), hash_before_begin, "fachlicher Hash wie vor dem Beginn")


func test_cancel_keeps_confirmed_changes() -> void:
	var run := RulesEngine.replay([
		Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night(),
		Command.nominate(3, 4), Command.decide_execution(4), Command.end_day(), Command.start_night(),
		Command.cancel_prompt(2, "Versehen"),
	] as Array[Command])
	assert_true(run.ok, "Befehlsfolge angenommen (%s @ %d)" % [run.error, run.failed_index])
	if run.ok:
		assert_eq(run.state.alive_ids(), [1, 2, 3, 5] as Array[int], "bestätigte Tode bleiben bestehen")
		assert_eq(run.state.night_number, 2, "Nacht 2 bleibt aktiv")


func test_skip_step_requires_reason_and_logs_event() -> void:
	var state := _night_one()
	apply_rejected(state, Command.skip_step(PACK_STEP, " "), "reason_required", "ohne Grund")
	apply_rejected(state, Command.skip_step("night:1:3:pack", "falsch"), "step_out_of_order", "falscher Schritt")
	var r := apply_ok(state, Command.skip_step(PACK_STEP, "Rudel einigt sich nicht"), "Überspringen")
	var skipped := events_of_type(r.events, "StepSkipped")
	assert_eq(skipped.size(), 1, "StepSkipped-Ereignis")
	if skipped.size() == 1:
		assert_eq(String(skipped[0].data["step_id"]), PACK_STEP, "übersprungener Schritt")
		assert_eq(String(skipped[0].data["reason"]), "Rudel einigt sich nicht", "Grund")
	assert_true(r.state.pending_prompt == null, "Prompt geschlossen")
	apply_rejected(r.state, Command.begin_step(PACK_STEP), "no_pending_step", "kein weiterer Schritt")
	var dawn := apply_ok(r.state, Command.end_night(), "Nacht endet")
	assert_eq(dawn.state.alive_ids().size(), 6, "übersprungener Angriff tötet niemanden")
	assert_eq(events_of_type(dawn.events, "NoNightKill").size(), 1, "kein Angriff protokolliert")


func test_skip_step_that_was_not_begun() -> void:
	var state := _night_one()
	var cancelled := apply_ok(state, Command.cancel_prompt(1, "Versehen"), "Abbruch").state
	var skipped := apply_ok(cancelled, Command.skip_step(PACK_STEP, "Spielleiter überspringt"), "Überspringen").state
	apply_ok(skipped, Command.end_night(), "Nacht endet")


func test_begin_step_outside_steps() -> void:
	var setup := Fixtures.play([Fixtures.start_manual(6, [1])] as Array[Command])
	apply_rejected(setup, Command.begin_step(PACK_STEP), "wrong_phase", "im Setup")
	var answered := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, [])] as Array[Command])
	apply_rejected(answered, Command.begin_step(PACK_STEP), "no_pending_step", "alle Schritte erledigt")
	apply_rejected(answered, Command.skip_step(PACK_STEP, "zu spät"), "no_pending_step", "nichts zu überspringen")


func test_steps_survive_save_load_and_replay() -> void:
	var commands: Array[Command] = [
		Fixtures.start_manual(6, [1, 2], 5), Command.start_night(), Command.cancel_prompt(1, "zu früh"),
		Command.begin_step(PACK_STEP),
	]
	var run_a := RulesEngine.replay(commands)
	var run_b := RulesEngine.replay(commands)
	assert_true(run_a.ok, "Befehlsfolge angenommen (%s)" % run_a.error)
	if not run_a.ok:
		return
	assert_eq(events_json(run_a.events), events_json(run_b.events), "Replay bytegleich")
	assert_eq(run_a.state.content_hash(), run_b.state.content_hash(), "gleicher State-Hash")
	var loaded := StateCodec.decode(StateCodec.encode(run_a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(loaded.state.content_hash(), run_a.state.content_hash(), "Hash nach Laden")
		assert_eq(loaded.state.pending_prompt.to_dict(), run_a.state.pending_prompt.to_dict(), "aktueller Schritt geladen")
		assert_eq(RulesEngine.next_step_id(loaded.state), PACK_STEP, "erwarteter Schritt nach Laden")
		var a := RulesEngine.apply(run_a.state, Command.skip_step(PACK_STEP, "Test"))
		var b := RulesEngine.apply(loaded.state, Command.skip_step(PACK_STEP, "Test"))
		assert_eq(events_json(b.events), events_json(a.events), "Fortsetzung nach Laden identisch")
