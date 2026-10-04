extends TestCase
## Kartenfamilie Nachtablauf und Wolfsangriff (segen_03/04/13, fluch_02/04/07/10, wende_03/06/12, schicksal_06, loki_03): je Variante
## die echte Wirkung auf Nachtplan, Rudelwahl und Morgenauflösung. Fähigkeitstode in der Nacht laufen über die Tötungsstufe des Kerns.

const COUNT := 12
const WOLVES: Array[int] = [1, 2, 3]
const WOLF_OWNER := 3
const VILLAGE_OWNER := 12


func _game(specials: Dictionary = {}, seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value, specials)


func _ability_kill(source: Variant, target: int) -> GameState:
	var s: GameState = (source as CardGame).state.duplicate_state() if source is CardGame else (source as GameState).duplicate_state()
	var ctx := RuleContext.new(s, s.command_count)
	KillPipeline.request_kill(ctx, target, KillEvent.CAUSE_WITCH_POISON, KillEvent.SOURCE_PLAYER, 5)
	return s


func _check_persistence(g: CardGame, label: String) -> void:
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)


func _pack_index(s: GameState) -> int:
	return s.night_plan.find(StepQueue.PACK)


func test_segen_03_wolf_lets_the_pack_review_and_change_the_target() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_03")
	g.play_with()
	assert_true(g.has_effect("pack_review"), "Effekt gespeichert")
	g.next_night(5, [[8]])
	assert_true(g.state.players[5].alive, "ursprüngliches Ziel überlebt")
	assert_false(g.state.players[8].alive, "das Rudel hat das Ziel gewechselt")
	assert_false(g.has_effect("pack_review"), "Effekt verbraucht")
	_check_persistence(g, "segen_03 wolf")


func test_segen_03_wolf_shows_the_victims_role_and_keeps_the_target_without_a_change() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_03")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var p := g.state.pending_prompt
	assert_eq(p.owner, PendingPrompt.OWNER_PACK, "Rudelwahl")
	g.do(Command.answer_prompt(p.id, [5]), "Rudel wählt 5")
	var review := g.state.pending_prompt
	assert_true(review != null and review.owner == PendingPrompt.OWNER_CARD, "Prüfung durch das Rudel")
	var spec: Dictionary = review.partial["spec"]
	assert_eq(int(spec["victim_id"]), 5, "Opfer genannt")
	assert_eq(String(spec["victim_role"]), String(g.state.players[5].role_id), "Rolle des Opfers für das Rudel")
	g.do(Command.answer_stage_targets(review.id, "pick", []), "keine Änderung")
	assert_eq(g.state.pack_target_id, 5, "Ziel bleibt")


func test_segen_04_and_wende_03_wolf_let_the_pack_choose_two_victims() -> void:
	for card: StringName in [&"segen_04", &"wende_03"]:
		var g := _game()
		g.arm(WOLF_OWNER, card)
		g.play_with()
		g.skip_cards()
		g.end_day()
		g.skip_cards()
		g.do(Command.start_night(), "StartNight")
		var p := g.state.pending_prompt
		assert_eq(p.max_count, 2, "%s: bis zu zwei Ziele" % card)
		g.do(Command.answer_prompt(p.id, [5, 6]), "zwei Ziele")
		g.settle()
		g.night_rest()
		assert_false(g.state.players[5].alive or g.state.players[6].alive, "%s: beide Ziele sterben" % card)
		_check_persistence(g, String(card))


func test_segen_04_village_removes_all_wolf_kills() -> void:
	var g := _game({"2": "giftwolf"})
	g.arm(VILLAGE_OWNER, &"segen_04")
	g.play_with()
	assert_true(g.has_effect("pack_sleep_wide"), "Effekt gespeichert")
	var before := g.dead_ids()
	g.next_night(5)
	assert_eq(g.dead_ids(), before, "niemand stirbt: keine Wolfstötung")
	_check_persistence(g, "segen_04 dorf")


func test_wende_06_village_and_fluch_07_wolf_remove_the_pack_step() -> void:
	for pair: Array in [[VILLAGE_OWNER, &"wende_06"], [WOLF_OWNER, &"fluch_07"]]:
		var g := _game()
		g.arm(int(pair[0]), StringName(pair[1]))
		g.play_with()
		g.skip_cards()
		g.end_day()
		g.skip_cards()
		g.do(Command.start_night(), "StartNight")
		assert_true(g.state.pending_prompt == null or g.state.pending_prompt.owner != PendingPrompt.OWNER_PACK, "%s: keine Rudelwahl" % pair[1])
		var before := g.dead_ids()
		g.night_rest()
		assert_eq(g.dead_ids(), before, "%s: niemand stirbt" % pair[1])
		assert_true(g.state.pack_target_id == GameState.NO_TARGET, "%s: kein Rudelziel" % pair[1])
		_check_persistence(g, String(pair[1]))


func test_wende_06_wolf_blocks_every_ability_kill_on_a_wolf_for_the_whole_night() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"wende_06")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var first := _ability_kill(g, 1)
	assert_true(first.players[1].alive, "erste Fähigkeit wirkungslos")
	var second := _ability_kill(first, 2)
	assert_true(second.players[2].alive, "auch die nächste: der Schutz hält die ganze Nacht")
	var villager := _ability_kill(g, 5)
	assert_false(villager.players[5].alive, "Dorfpersonen sind nicht geschützt")


func test_segen_13_wolf_fails_only_the_first_harmful_ability_on_a_wolf() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_13")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var first := _ability_kill(g, 1)
	assert_true(first.players[1].alive, "die erste Fähigkeit missglückt")
	var second := _ability_kill(first, 2)
	assert_false(second.players[2].alive, "die zweite wirkt")


func test_segen_13_village_wakes_the_pack_first_and_announces_the_victim() -> void:
	var g := _game({"5": "schutzengel"})
	g.arm(VILLAGE_OWNER, &"segen_13")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	assert_eq(_pack_index(g.state), 0, "das Rudel steht vor allen anderen Schritten")
	var p := g.state.pending_prompt
	g.do(Command.answer_prompt(p.id, [8]), "Rudel einigt sich")
	var announced := g.events_of(GameEvent.CARD_ANNOUNCED)
	assert_eq(announced.size(), 1, "öffentliche Ansage nach der Einigung")
	assert_eq(announced[0].data["values"]["victim_id"], 8, "Opfer angesagt")
	_check_persistence(g, "segen_13 dorf")


func test_wende_12_wolf_calls_the_pack_after_the_wolf_abilities() -> void:
	var g := _game({"2": "giftwolf", "5": "schutzengel"})
	g.arm(WOLF_OWNER, &"wende_12")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var poison := g.state.night_plan.find(&"giftwolf:2") if g.state.night_plan.has(&"giftwolf:2") else -1
	var pack := _pack_index(g.state)
	assert_true(pack > 0, "Rudel nicht mehr zuerst")
	for i: int in g.state.night_plan.size():
		var key := String(g.state.night_plan[i])
		if key.begins_with("giftwolf"):
			assert_true(i < pack, "Wolfsfähigkeit vor dem Rudel")
	assert_true(poison == -1 or poison < pack, "Reihenfolge")
	_check_persistence(g, "wende_12 wolf")


func test_wende_12_village_asks_the_game_master_one_question() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"wende_12")
	var spec_stage := ""
	g.do(Command.card_act(VILLAGE_OWNER, "play"), "play")
	var p := g.state.pending_prompt
	spec_stage = String(p.stage)
	assert_eq(spec_stage, "confirm", "Bestätigung, dass die Frage beantwortet wurde")
	g.do(Command.answer_choice(p.id, "confirm", true), "beantwortet")
	assert_true(g.state.pending_prompt == null, "danach nichts offen")
	_check_persistence(g, "wende_12 dorf")


func test_fluch_02_wolf_lets_the_game_master_redirect_the_attack() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"fluch_02")
	g.play_with()
	g.next_night(5, [[8]])
	assert_true(g.state.players[5].alive, "gewähltes Ziel überlebt")
	assert_false(g.state.players[8].alive, "umgelenkt auf das Ziel der Spielleitung")
	_check_persistence(g, "fluch_02 wolf")


func test_fluch_02_village_forces_a_false_oracle_answer() -> void:
	var g := _game({"6": "das-orakel"})
	g.arm(VILLAGE_OWNER, &"fluch_02")
	g.play_with([6])
	assert_true(g.has_effect("false_info"), "Effekt gespeichert")
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var guard := 0
	while guard < 20 and g.state.phase == Phase.NIGHT:
		guard += 1
		var p := g.state.pending_prompt
		if p != null and p.owner == PendingPrompt.OWNER_ORACLE and p.stage == &"shown":
			var rejected := g.attempt(Command.answer_choice(p.id, "shown", true))
			assert_false(rejected.ok, "ohne Übersteuerung nicht bestätigbar")
			assert_eq(String(rejected.error), "false_info_required", "Grund: falsche Auskunft nötig")
			g.do(Command.override_shown_role(p.id, "dorfbewohner", "Falsche Fährte"), "übersteuern")
			g.do(Command.answer_choice(p.id, "shown", true), "gezeigt")
			break
		if p != null and p.owner == PendingPrompt.OWNER_PACK:
			g.do(Command.skip_step(p.step_id, "Test: ruhige Nacht"), "Rudel")
		elif p != null:
			g.answer_default(p)
		elif RulesEngine.next_step_id(g.state) != "":
			g.do(Command.begin_step(RulesEngine.next_step_id(g.state)), "begin")
		else:
			break
	assert_false(g.has_effect("false_info"), "Effekt verbraucht")
	assert_true(g.events_of(GameEvent.INFO_OVERRIDDEN).size() >= 1, "Übersteuerung protokolliert")
	_check_persistence(g, "fluch_02 dorf")


func test_fluch_04_wolf_forces_the_pack_to_choose_one_of_its_own() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"fluch_04")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var p := g.state.pending_prompt
	assert_eq(p.owner, PendingPrompt.OWNER_PACK, "Rudelwahl")
	assert_true(p.allowed_ids.all(func(id: int) -> bool: return CardCatalog.owner_variant(g.state.players[id]) == CardCatalog.WOLF), "nur Wölfe wählbar")
	assert_eq(p.min_count, 1, "Wahl ist Pflicht")
	var rejected := g.attempt(Command.answer_prompt(p.id, [5]))
	assert_false(rejected.ok, "eine Dorfperson ist nicht wählbar")
	g.do(Command.answer_prompt(p.id, [2]), "eigener Wolf")
	g.night_rest()
	assert_false(g.state.players[2].alive, "der Wolf stirbt")


func test_fluch_10_wolf_asks_whether_the_pack_caught_a_strong_role() -> void:
	var caught_no := _game()
	caught_no.arm(WOLF_OWNER, &"fluch_10")
	caught_no.play_with()
	caught_no.next_night(5, [], false)
	var task := caught_no.state.pending_prompt
	assert_true(task != null and task.owner == PendingPrompt.OWNER_CARD, "Aufgabe: Schlechtes Omen")
	assert_eq(task.stage, &"ask", "Frage: starke Rolle erwischt?")
	caught_no.do(Command.answer_choice(task.id, "ask", false), "nein")
	var pick := caught_no.state.pending_prompt
	assert_eq(pick.stage, &"pick", "dann die Wahl des Wolfs")
	caught_no.do(Command.answer_stage_targets(pick.id, "pick", [1]), "Wolf 1")
	assert_false(caught_no.state.players[1].alive, "der Wolf stirbt")
	_check_persistence(caught_no, "fluch_10 nein")
	var caught_yes := _game()
	caught_yes.arm(WOLF_OWNER, &"fluch_10")
	caught_yes.play_with()
	caught_yes.next_night(5, [], false)
	caught_yes.do(Command.answer_choice(caught_yes.state.pending_prompt.id, "ask", true), "ja")
	assert_true(caught_yes.state.pending_prompt == null and caught_yes.state.players[1].alive and caught_yes.state.players[2].alive, "kein Wolf stirbt")


func test_schicksal_06_and_loki_03_skip_the_next_night_completely() -> void:
	for card: StringName in [&"schicksal_06", &"loki_03"]:
		var g := _game({"5": "schutzengel"})
		g.arm(VILLAGE_OWNER, card)
		g.play_with()
		var night_before := g.state.night_number
		var before := g.dead_ids()
		g.next_night(8)
		assert_eq(g.state.night_number, night_before + 1, "%s: die Nacht zählt" % card)
		assert_eq(g.dead_ids(), before, "%s: kein Tod" % card)
		assert_eq(g.events_of(GameEvent.NIGHT_SKIPPED_BY_CARD).size(), 1, "%s: öffentliche Ansage" % card)
		assert_false(g.has_effect("night_skip") and CardEffects.active(g.state, "night_skip").size() > 0 and g.state.phase == Phase.NIGHT, "%s: Nacht vorbei" % card)
		g.skip_cards()
		g.next_night(8)
		assert_false(g.state.players[8].alive, "%s: die Nacht danach läuft wieder normal" % card)
		_check_persistence(g, String(card))
