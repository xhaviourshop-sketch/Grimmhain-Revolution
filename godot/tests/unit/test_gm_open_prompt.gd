extends TestCase
## Entscheidung 5 (DECISION-LOG): Eine GmCorrection hinterlässt keinen widersprüchlichen
## offenen Prompt. Jede Korrektur des Spielerzustands bricht einen offenen Prompt mit
## Grund state_changed_by_gm_correction ab; der Schritt bleibt erneut ausführbar.

const PACK_STEP := "night:1:0:pack"
const REASON := "state_changed_by_gm_correction"


func _night_one() -> GameState:
	return Fixtures.play([Fixtures.start_manual(6, [1, 2]), Command.start_night()] as Array[Command])


func _expect_auto_cancel(r: CommandResult, prompt_id: int, step_id: String, label: String) -> void:
	var cancelled := events_of_type(r.events, "PromptCancelled")
	assert_eq(cancelled.size(), 1, "%s: Prompt abgebrochen" % label)
	if cancelled.size() == 1:
		assert_eq(int(cancelled[0].data["prompt_id"]), prompt_id, "%s: betroffener Prompt" % label)
		assert_eq(String(cancelled[0].data["step_id"]), step_id, "%s: betroffener Schritt" % label)
		assert_eq(String(cancelled[0].data["reason"]), REASON, "%s: Grund" % label)
	assert_true(r.state.pending_prompt == null, "%s: kein Prompt mehr offen" % label)
	assert_eq(RulesEngine.next_step_id(r.state), step_id, "%s: Schritt erneut ausführbar" % label)


func test_kill_removes_target_from_pack_prompt() -> void:
	var s := _night_one()
	assert_true(s.pending_prompt.allowed_ids.has(4), "4 ist zunächst wählbar")
	var r := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": false}), "Tod per Korrektur")
	_expect_auto_cancel(r, 1, PACK_STEP, "kill")
	apply_rejected(r.state, Command.answer_prompt(1, [4]), "no_open_prompt", "alter Prompt nimmt 4 nicht an")
	var begun := apply_ok(r.state, Command.begin_step(PACK_STEP), "Schritt neu beginnen").state
	assert_false(begun.pending_prompt.allowed_ids.has(4), "neuer Prompt ohne tote Person")
	apply_rejected(begun, Command.answer_prompt(begun.pending_prompt.id, [4]), "invalid_target", "4 nicht wählbar")
	for id: int in begun.pending_prompt.allowed_ids:
		assert_true(begun.players[id].alive, "Prompt verweist nur auf Lebende (%d)" % id)


func test_revive_reopens_step_with_new_target() -> void:
	var s := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, [6]),
		Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command])
	assert_false(s.pending_prompt.allowed_ids.has(6), "6 ist tot und nicht wählbar")
	var r := apply_ok(s, CorrectionFixtures.gm("revive", {"target_id": 6}), "Wiederbelebung")
	_expect_auto_cancel(r, 2, "night:2:0:pack", "revive")
	var begun := apply_ok(r.state, Command.begin_step("night:2:0:pack"), "neu beginnen").state
	assert_true(begun.pending_prompt.allowed_ids.has(6), "wiederbelebte Person wählbar")


func test_set_role_cancels_prompt() -> void:
	var r := apply_ok(_night_one(), CorrectionFixtures.gm("set_role", {"target_id": 3, "role_id": "werwolf"}), "Rollenkorrektur")
	_expect_auto_cancel(r, 1, PACK_STEP, "set_role")


func test_set_role_field_cancels_prompt() -> void:
	var r := apply_ok(_night_one(), CorrectionFixtures.gm("set_role_field", {"target_id": 1, "field": "appears_as", "value": "dorfbewohner"}), "Feldkorrektur")
	_expect_auto_cancel(r, 1, PACK_STEP, "set_role_field")


func test_execute_cancels_reaction_prompt() -> void:
	# Tag 1: Test-Sensenträger (3) hingerichtet, Reaktions-Prompt offen; dann Übersteuerung auf 4.
	var s := Fixtures.play([Fixtures.start_reaper_game(), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night(),
		Command.nominate(5, 3), Command.decide_execution(3), Command.begin_step("reaction:1")] as Array[Command])
	assert_true(s.pending_prompt != null and s.pending_prompt.allowed_ids.has(4), "Reaktions-Prompt mit 4 offen")
	var r := apply_ok(s, CorrectionFixtures.gm("execute", {"target_id": 4}), "Hinrichtung per Übersteuerung")
	_expect_auto_cancel(r, 2, "reaction:1", "execute")
	assert_eq(r.state.reactions.size(), 1, "Reaktion bleibt offen")
	var begun := apply_ok(r.state, Command.begin_step("reaction:1"), "Reaktion neu beginnen").state
	assert_false(begun.pending_prompt.allowed_ids.has(4), "Hingerichteter nicht mehr wählbar")


func test_declare_winner_still_requires_no_open_prompt() -> void:
	apply_rejected(_night_one(), CorrectionFixtures.gm("declare_winner", {"winner_kind": "village"}), "prompt_open", "Siegerklärung bei offenem Prompt")


func test_win_from_correction_not_confirmable_with_open_prompt() -> void:
	# Nacht 1, Rudel-Prompt offen; Korrektur erzeugt Parität (2:2). Der Prompt wird
	# abgebrochen, erst danach entsteht der Kandidat: nie Kandidat und Prompt zugleich.
	var s := _night_one()
	var r1 := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": false}), "Tod 3")
	var r2 := apply_ok(r1.state, CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": false}), "Tod 4")
	assert_true(sole_candidate(r2.state) != null, "Kandidat Werwölfe")
	assert_true(r2.state.pending_prompt == null, "kein offener Prompt neben dem Kandidaten")
	apply_rejected(r2.state, Command.begin_step(PACK_STEP), "win_candidate_open", "erst Kandidat entscheiden")


func test_auto_cancel_save_load_and_replay() -> void:
	var commands: Array[Command] = [Fixtures.start_manual(6, [1, 2], 9), Command.start_night(),
		CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": false}), Command.begin_step(PACK_STEP)]
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok, "angenommen (%s @ %d)" % [a.error, a.failed_index])
	if not a.ok:
		return
	assert_eq(events_json(a.events), events_json(b.events), "Replay bytegleich")
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(loaded.state.content_hash(), a.state.content_hash(), "Hash nach Laden")
		assert_eq(loaded.state.pending_prompt.to_dict(), a.state.pending_prompt.to_dict(), "neuer Prompt geladen")
