extends TestCase
## Kartenschlucker im Kern: Optionen nach Guthaben, Nachtschritt, Tötung, Schild, Sieg, Ansage, ungültige Eingaben ohne Teiländerung
## und Zusammenspiel mit Schutz- und Rollenwechselkarten. Stapel werden hier direkt gesetzt; der Erwerb über den Kartentausch prüft
## `test_cards_foundation`, der Ablauf über die Oberfläche `test_cards_ui`.

const COUNT := 12
const WOLVES: Array[int] = [1, 2, 3]
const BEARER := 4


func _game(stacks: int = 0, seed_value: int = 3) -> CardGame:
	var g := CardGame.started(self, COUNT, WOLVES, seed_value, {"4": "kartenschlucker"})
	_set_stacks(g, BEARER, stacks)
	return g


## Stapel werden direkt gesetzt (kein Befehl): daher gilt hier Speichern und Laden des Zustands statt Replay.
func _codec_equal(g: CardGame) -> bool:
	return CanonicalJson.stringify(GameState.from_dict(g.state.to_dict()).to_dict()) == CanonicalJson.stringify(g.state.to_dict())


func _set_stacks(g: CardGame, id: int, n: int) -> void:
	(g.state.cardsys["stacks"] as Dictionary)[str(id)] = {"total": n, "balance": n}


## Beginnt die Nacht und bringt den Ablauf bis zum Prompt des Kartenschluckers (oder zum Ende der Nacht ohne ihn).
func _to_swallower(g: CardGame, victim: int = -1) -> PendingPrompt:
	g.do(Command.start_night(), "StartNight")
	var guard := 0
	while g.state.phase == Phase.NIGHT and guard < 40:
		guard += 1
		var p := g.state.pending_prompt
		if p != null:
			if p.owner == PendingPrompt.OWNER_SWALLOWER:
				return p
			if p.owner == PendingPrompt.OWNER_PACK:
				g.do(Command.answer_prompt(p.id, [victim] if victim != -1 else Fixtures.pass_targets(g.state, p)), "Rudel")
			else:
				g.answer_default(p)
		elif RulesEngine.next_step_id(g.state) != "":
			g.do(Command.begin_step(RulesEngine.next_step_id(g.state)), "begin")
		else:
			return null
	return null


func _finish(g: CardGame) -> void:
	var guard := 0
	while g.state.phase == Phase.NIGHT and guard < 40 and g.state.open_candidates().is_empty():
		guard += 1
		var p := g.state.pending_prompt
		if p != null:
			if p.owner == PendingPrompt.OWNER_PACK:
				g.do(Command.answer_prompt(p.id, Fixtures.pass_targets(g.state, p)), "Rudel")
			else:
				g.answer_default(p)
		elif RulesEngine.next_step_id(g.state) != "":
			g.do(Command.begin_step(RulesEngine.next_step_id(g.state)), "begin")
		else:
			g.do(Command.end_night(), "EndNight")
	g.settle()


func _act(g: CardGame, prompt: PendingPrompt, option: String) -> void:
	var options: Array = prompt.partial["options"]
	g.do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": prompt.id, "stage": "act", "option": options.find(option)}), "act %s" % option)


func test_options_follow_the_available_balance_in_a_fixed_order() -> void:
	var g := _game()
	var expected := {0: [], 1: [], 2: ["none", "kill"], 4: ["none", "kill"], 5: ["none", "kill", "shield"], 9: ["none", "kill", "shield"], 10: ["none", "kill", "shield", "win"]}
	for n: int in expected:
		_set_stacks(g, BEARER, n)
		assert_eq(SwallowerRules.options(g.state, BEARER), Array(expected[n], TYPE_STRING, "", null), "Optionen bei %d Stapeln" % n)
	_set_stacks(g, BEARER, 7)
	(g.state.cardsys["shields"] as Array).append(BEARER)
	assert_eq(SwallowerRules.options(g.state, BEARER), Array(["none", "kill"], TYPE_STRING, "", null), "ein vorhandener Schild wird nicht noch einmal angeboten")


func test_the_night_step_exists_only_with_an_affordable_action() -> void:
	var poor := _game(1)
	assert_true(_to_swallower(poor) == null, "mit einem Stapel kein Prompt")
	var rich := _game(2)
	var p := _to_swallower(rich)
	assert_true(p != null and p.owner == PendingPrompt.OWNER_SWALLOWER and p.stage == &"act", "mit zwei Stapeln wird er geweckt")
	assert_eq(p.partial["options"], ["none", "kill"], "Optionen im Prompt")


func test_kill_costs_two_stacks_and_the_victim_dies_in_the_morning() -> void:
	var g := _game(3)
	var p := _to_swallower(g)
	_act(g, p, "kill")
	var target := g.state.pending_prompt
	assert_eq(target.stage, &"target", "Zielwahl")
	assert_false(target.allowed_ids.has(BEARER), "nicht auf sich selbst")
	g.do(Command.answer_stage_targets(target.id, "target", [7]), "Ziel")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 1, "zwei Stapel bezahlt")
	assert_eq(SwallowerRules.total_of(g.state, BEARER), 3, "gesammelte Stapel bleiben")
	assert_true(g.state.players[7].alive, "noch am Leben")
	_finish(g)
	assert_false(g.state.players[7].alive, "am Morgen tot")
	assert_eq(String(g.state.players[7].death.cause), String(KillEvent.CAUSE_SWALLOWER_KILL), "Ursache: Kartenschlucker")
	assert_true(_codec_equal(g), "Speichern und Laden gleich")


func test_a_shield_blocks_the_swallower_kill_like_any_ability_kill() -> void:
	var g := _game(2)
	(g.state.cardsys["shields"] as Array).append(7)
	var p := _to_swallower(g)
	_act(g, p, "kill")
	g.do(Command.answer_stage_targets(g.state.pending_prompt.id, "target", [7]), "Ziel")
	_finish(g)
	assert_true(g.state.players[7].alive, "der Schild verhindert den Tod")
	assert_false((g.state.cardsys["shields"] as Array).has(7), "Schild verbraucht")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 0, "die Stapel sind trotzdem bezahlt")


func test_shield_costs_five_and_stops_exactly_one_death_but_not_a_gm_correction() -> void:
	var g := _game(5)
	var p := _to_swallower(g)
	_act(g, p, "shield")
	assert_true(SwallowerRules.has_shield(g.state, BEARER), "Schild vorhanden")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 0, "fünf Stapel bezahlt")
	_finish(g)
	var s := g.state.duplicate_state()
	var ctx := RuleContext.new(s, s.command_count)
	KillPipeline.request_kill(ctx, BEARER, KillEvent.CAUSE_WITCH_POISON, KillEvent.SOURCE_PLAYER, 5)
	assert_true(s.players[BEARER].alive, "der erste Tod wird verhindert")
	assert_false(SwallowerRules.has_shield(s, BEARER), "Schild verbraucht")
	KillPipeline.request_kill(ctx, BEARER, KillEvent.CAUSE_WITCH_POISON, KillEvent.SOURCE_PLAYER, 5)
	assert_false(s.players[BEARER].alive, "der zweite Tod gelingt")
	var gm := g.state.duplicate_state()
	g.state = gm
	g.gm_kill(BEARER, true)
	assert_false(g.state.players[BEARER].alive, "Spielleiterkorrekturen umgehen den Schild")


func test_win_costs_ten_and_makes_the_swallower_a_win_candidate_while_alive() -> void:
	var g := _game(10)
	var p := _to_swallower(g)
	_act(g, p, "win")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 0, "zehn Stapel abgegeben")
	assert_true(SwallowerRules.wins(g.state, BEARER), "Sieg vorgemerkt")
	_finish(g)
	var candidates := g.state.open_candidates()
	assert_true(candidates.any(func(c: WinCandidate) -> bool: return c.beneficiary_ids.has(BEARER)), "Siegkandidat (Spielleiterbestätigung nötig)")
	assert_true(_codec_equal(g), "Speichern und Laden gleich")


func test_ten_collected_stacks_alone_trigger_nothing() -> void:
	var g := _game(10)
	assert_false(SwallowerRules.wins(g.state, BEARER), "ohne Aktion kein Sieg")
	g.state.win_check_pending = true
	assert_false(WinRules.evaluate(g.state).any(func(r: Dictionary) -> bool: return (r["beneficiary_ids"] as Array).has(BEARER)), "kein Ergebnis allein durch Stapel")


func test_invalid_answers_are_rejected_without_any_change() -> void:
	var g := _game(3)
	var p := _to_swallower(g)
	var before := CanonicalJson.stringify(g.state.to_dict())
	for bad: Dictionary in [
		{"prompt_id": p.id, "stage": "act", "option": 2},
		{"prompt_id": p.id, "stage": "act", "option": -1},
		{"prompt_id": p.id, "stage": "act", "option": "kill"},
		{"prompt_id": p.id, "stage": "target", "targets": [7]},
		{"prompt_id": p.id, "stage": "act"},
	]:
		assert_false(g.attempt(Command.create(Command.ANSWER_PROMPT, bad)).ok, "abgelehnt: %s" % CanonicalJson.stringify(bad))
	assert_eq(CanonicalJson.stringify(g.state.to_dict()), before, "kein Teilzustand")
	_act(g, p, "kill")
	var target := g.state.pending_prompt
	var before_target := CanonicalJson.stringify(g.state.to_dict())
	for bad_targets: Array in [[], [4], [7, 8], [99]]:
		assert_false(g.attempt(Command.answer_stage_targets(target.id, "target", bad_targets)).ok, "Ziele %s abgelehnt" % str(bad_targets))
	assert_eq(CanonicalJson.stringify(g.state.to_dict()), before_target, "keine Änderung nach falschen Zielen")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 3, "erst die gültige Wahl bezahlt")


func test_doing_nothing_keeps_all_stacks() -> void:
	var g := _game(6)
	var p := _to_swallower(g)
	_act(g, p, "none")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 6, "Guthaben unverändert")
	_finish(g)
	assert_eq(g.events_of(GameEvent.CARD_SWALLOWER_ACTED).size(), 1, "Nichtstun ist protokolliert")


func test_public_announcement_names_only_the_total_in_nights_three_six_and_nine() -> void:
	var g := _game(0)
	(g.state.cardsys["stacks"] as Dictionary)[str(BEARER)] = {"total": 4, "balance": 1}  # ein Stapel: kein Nachtschritt
	var announced_nights: Array = []
	for night_number: int in 6:
		g.next_night(-1)
		if g.state.phase == Phase.GAME_OVER:
			break
	assert_true(g.events_of(GameEvent.SWALLOWER_ANNOUNCED).size() >= 1, "mindestens eine Ansage in sechs Nächten")
	for e: GameEvent in g.events_of(GameEvent.SWALLOWER_ANNOUNCED):
		announced_nights.append(int(e.data["night"]))
		assert_eq(e.visibility, Visibility.PUBLIC, "öffentlich")
		assert_eq(e.data.keys().size(), 2, "nur Gesamtzahl und Nacht, keine Käufe")
		assert_true(e.data.has("total"), "Gesamtzahl")
	for n: int in announced_nights:
		assert_eq(n % 3, 0, "nur in den Nächten 3, 6, 9")


func test_stacks_stay_with_the_person_when_the_role_changes_and_a_new_bearer_starts_at_zero() -> void:
	var g := _game(6)
	g.gm_set_role(BEARER, "dorfbewohner")
	assert_eq(SwallowerRules.balance_of(g.state, BEARER), 6, "die Stapel ruhen bei der Person")
	assert_true(SwallowerRules.options(g.state, BEARER).size() > 0, "Optionen rechnerisch vorhanden, aber ohne Rolle kein Nachtschritt")
	assert_eq(SwallowerRules.living_bearers(g.state).size(), 0, "kein lebender Träger mehr")
	g.gm_set_role(5, "kartenschlucker")
	assert_eq(SwallowerRules.balance_of(g.state, 5), 0, "neuer Träger beginnt bei null")
	assert_eq(SwallowerRules.total_of(g.state, BEARER), 6, "gesammelte Stapel des früheren Trägers bleiben")


func test_a_broken_shield_card_has_no_exception_for_a_bought_shield_of_a_paused_faction() -> void:
	# Der Schild bleibt beim Rollenwechsel (Decision Log); die Person zählt dann zur Fraktion, deren Schutz pausiert.
	var g := _game(0)
	(g.state.cardsys["shields"] as Array).append(BEARER)
	g.gm_set_role(BEARER, "dorfbewohner")
	g.arm(12, &"fluch_05")
	g.play_with([0])
	assert_true(CardHooks.protections_paused(g.state, BEARER), "Schutz der Dorfpersonen ruht")
	var paused := g.state.duplicate_state()
	KillPipeline.request_kill(RuleContext.new(paused, paused.command_count), BEARER, KillEvent.CAUSE_WITCH_POISON, KillEvent.SOURCE_PLAYER, 5)
	assert_false(paused.players[BEARER].alive, "der ruhende Schild verhindert nichts")
	var solo := _game(0)
	(solo.state.cardsys["shields"] as Array).append(BEARER)
	solo.arm(12, &"fluch_05")
	solo.play_with([0])
	assert_false(CardHooks.protections_paused(solo.state, BEARER), "die Einzelsiegrolle gehört weder zu Dorf noch zu Wölfen")
