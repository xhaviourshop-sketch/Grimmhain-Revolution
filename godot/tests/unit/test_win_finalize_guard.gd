extends TestCase
## WinRules.finalize_if_ready darf keinen Kandidaten erzeugen, solange ein Prompt
## oder eine Reaktion offen ist (DR-14, Entscheidung 5).


## Zustand mit erfüllter Siegbedingung (Dorf: kein Wolf lebt) und ausstehender Prüfung.
func _winning_state() -> GameState:
	var s := Fixtures.play([Fixtures.start_manual(6, [1]), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])
	s.players[1].alive = false
	s.win_check_pending = true
	return s


func test_no_candidate_while_prompt_open() -> void:
	var s := _winning_state()
	var prompt := PendingPrompt.new()
	prompt.id = 99
	prompt.owner = PendingPrompt.OWNER_PACK
	prompt.step_id = "night:1:0:pack"
	prompt.allowed_ids = s.alive_ids()
	s.pending_prompt = prompt
	var ctx := RuleContext.new(s, s.command_count)
	WinRules.finalize_if_ready(ctx)
	assert_true(sole_candidate(s) == null, "kein Kandidat bei offenem Prompt")
	assert_true(s.win_check_pending, "Prüfung bleibt ausstehend")
	assert_eq(events_of_type(ctx.events, "WinStatusFinal").size(), 0, "keine verbindliche Prüfung")


func test_no_candidate_while_reaction_open() -> void:
	var s := _winning_state()
	var reaction := Reaction.new()
	reaction.id = 1
	reaction.owner_id = 2
	s.reactions.append(reaction)
	var ctx := RuleContext.new(s, s.command_count)
	WinRules.finalize_if_ready(ctx)
	assert_true(sole_candidate(s) == null, "kein Kandidat bei offener Reaktion")
	assert_true(s.win_check_pending, "Prüfung bleibt ausstehend")


func test_candidate_once_nothing_open() -> void:
	var s := _winning_state()
	var ctx := RuleContext.new(s, s.command_count)
	WinRules.finalize_if_ready(ctx)
	assert_true(sole_candidate(s) != null and String(sole_candidate(s).kind) == "village", "Kandidat Dorf")
	assert_false(s.win_check_pending, "Prüfung erledigt")
