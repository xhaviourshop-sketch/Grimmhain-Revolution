extends TestCase
## Kartenfamilie Abstimmung und Hinrichtung (schicksal_03/05/09/11/14, loki_01/02/13, segen_03/05/09, fluch_03/04/09/10/13, wende_03/09/11):
## je Karte die echte Wirkung auf Hinrichtung, Folgen und gespeicherte Tagesregeln. Stimmen werden am Tisch gezählt; die Tests
## tragen das Tischergebnis wie die Spielleitung als Befehl ein.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3]
const WOLF_OWNER := 3
const VILLAGE_OWNER := 14


func _game(specials: Dictionary = {}, seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value, specials)


func _persist(g: CardGame, label: String) -> void:
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)


func _nominate(g: CardGame, nominee: int, nominator: int = 4) -> void:
	g.do(Command.nominate(nominator, nominee), "nominate %d" % nominee)


func _decide(g: CardGame, target: int, extra: Dictionary = {}) -> CommandResult:
	var payload := {"target_id": target}
	payload.merge(extra)
	return g.attempt(Command.create(Command.DECIDE_EXECUTION, payload))


## Erste Person der Liste, deren Hinrichtung der Kern annimmt (manche Füllerrollen verlangen zusätzliche Angaben).
func _first_executable(g: CardGame, candidates: Array) -> int:
	for id: int in candidates:
		if _decide(g, id).ok:
			return id
	return -1


func test_schicksal_03_amnesty_cancels_the_execution_of_the_day() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_03")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(CardLynch.cancelled_today(g.state), "Hinrichtung entfällt")
	var rejected := _decide(g, 5)
	assert_false(rejected.ok, "Hinrichtung wird abgelehnt")
	assert_eq(String(rejected.error), "execution_cancelled_by_card", "Grund: Karte")
	assert_true(g.state.players[5].alive, "niemand starb")
	var none := _decide(g, GameState.NO_TARGET)
	assert_true(none.ok, "„keine Hinrichtung“ ist erlaubt")
	_persist(g, "schicksal_03")


func test_schicksal_05_mirror_kills_all_chosen_people_at_once() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_05")
	g.play_with([[5, 6]])
	assert_false(g.state.players[5].alive or g.state.players[6].alive, "beide gewählten Personen sind tot")
	assert_true(g.state.players[7].alive, "andere bleiben am Leben")
	assert_eq(g.events_of(GameEvent.CARD_ANNOUNCED).size(), 1, "öffentliche Ansage")
	_persist(g, "schicksal_05")


func test_schicksal_05_allows_an_empty_selection_without_deaths() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_05")
	var before := g.dead_ids()
	g.play_with([[]])
	assert_eq(g.dead_ids(), before, "niemand stirbt")


func test_schicksal_09_and_loki_01_count_the_votes_for_the_person_to_the_left() -> void:
	for card: StringName in [&"schicksal_09", &"loki_01"]:
		var g := _game()
		g.arm(VILLAGE_OWNER, card)
		g.play_with()
		g.skip_cards()
		_nominate(g, 5)
		var left := CardLynch.vote_target(g.state, 5)
		assert_eq(left, 6, "%s: lebende Person links von 5" % card)
		var res := _decide(g, 5)
		assert_true(res.ok, "%s: Hinrichtung angenommen" % card)
		assert_true(g.state.players[5].alive, "%s: die nominierte Person lebt" % card)
		assert_false(g.state.players[left].alive, "%s: die Person links stirbt" % card)
		if card == &"loki_01":
			assert_true(g.events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.EXECUTION_CONFIRMED).size() >= 1, "Hinrichtung protokolliert")
		_persist(g, String(card))


func test_loki_01_marks_the_day_result_as_secret_and_only_applies_today() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"loki_01")
	g.play_with()
	assert_true(g.has_effect("secret_result"), "geheimes Ergebnis gespeichert")
	assert_true(g.has_effect("lynch_shift_left"), "Stimmentausch gespeichert")
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.night(-1)
	g.skip_cards()
	assert_true(CardLynch.for_today(g.state, "lynch_shift_left").is_empty(), "am Folgetag keine Spiegelung mehr")


func test_schicksal_11_chain_reaction_requires_and_kills_the_runner_up() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_11")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	var missing := _decide(g, 5)
	assert_false(missing.ok, "ohne Zweitplatzierte keine Entscheidung")
	assert_eq(String(missing.error), "runner_up_required", "Grund: Zweitplatzierte fehlt")
	var invalid := _decide(g, 5, {"runner_up_id": 5})
	assert_false(invalid.ok, "dieselbe Person ist nicht zulässig")
	var valid := _decide(g, 5, {"runner_up_id": 8})
	assert_true(valid.ok, "mit Zweitplatzierter angenommen")
	assert_false(g.state.players[5].alive, "hingerichtet")
	assert_false(g.state.players[8].alive, "Zweitplatzierte stirbt mit")
	assert_false(g.has_effect("lynch_runner_up"), "Effekt verbraucht")
	_persist(g, "schicksal_11")


func test_schicksal_11_accepts_no_runner_up_when_the_table_has_none() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_11")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	var res := _decide(g, 5, {"runner_up_id": GameState.NO_TARGET})
	assert_true(res.ok, "keine zweite Person")
	assert_false(g.state.players[5].alive, "nur die Hingerichtete stirbt")


func test_schicksal_14_judge_chair_allows_any_living_person_as_the_target() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_14")
	g.play_with([6])
	g.skip_cards()
	assert_true(CardLynch.allows_unnominated(g.state), "jede lebende Person zulässig")
	var target := _first_executable(g, [9, 10, 11, 12])
	assert_ne(target, -1, "eine nicht nominierte Person ist hinrichtbar")
	assert_false(g.state.players[target].alive, "die Person stirbt")
	_persist(g, "schicksal_14")


func test_loki_13_executes_the_person_with_the_fewest_votes_without_a_nomination() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"loki_13")
	g.play_with()
	g.skip_cards()
	assert_true(CardLynch.allows_unnominated(g.state), "jede lebende Person zulässig")
	var target := _first_executable(g, [10, 11, 12, 9])
	assert_ne(target, -1, "Person mit den wenigsten Stimmen hinrichtbar")
	assert_false(g.state.players[target].alive, "stirbt")
	_persist(g, "loki_13")


func test_loki_02_silent_vote_opens_a_task_at_day_end_and_kills_for_too_few_nominations() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"loki_02")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, GameState.NO_TARGET).ok, "keine Hinrichtung")
	g.end_day()
	var p := g.state.pending_prompt
	assert_true(p != null and p.owner == PendingPrompt.OWNER_CARD and p.stage == &"ask", "Aufgabe: war die Frist eingehalten?")
	var before := g.dead_ids()
	g.do(Command.answer_choice(p.id, "ask", true), "in time")
	var died := g.dead_ids().filter(func(id: int) -> bool: return not before.has(id))
	assert_true(died.size() >= 1 and died.size() <= 5, "bei weniger als drei Nominierungen sterben eine bis fünf Personen")
	_persist(g, "loki_02")


func test_segen_03_village_reveals_the_role_and_the_village_decides() -> void:
	var g := _game({"5": "schutzengel"})
	g.arm(VILLAGE_OWNER, &"segen_03")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	var early := _decide(g, 5)
	assert_false(early.ok, "ohne Enthüllung nicht möglich")
	assert_eq(String(early.error), "card_reveal_required", "Grund: Enthüllung nötig")
	var reveal := _decide(g, 5, {"card_reveal": true})
	assert_true(reveal.ok, "Enthüllung angenommen")
	var revealed := g.events_of(GameEvent.CARD_ROLE_REVEALED)
	assert_eq(revealed.size(), 1, "öffentlich enthüllt")
	assert_eq(String(revealed[0].data["role_id"]), "schutzengel", "die wahre Rolle")
	assert_true(g.state.players[5].alive, "noch am Leben")
	assert_eq(g.state.day_step, Phase.DAY_NOMINATION, "der Tag ist unentschieden")
	var no_decision := _decide(g, 5)
	assert_false(no_decision.ok, "Entscheid des Dorfes fehlt")
	assert_eq(String(no_decision.error), "village_decision_required", "Grund: Dorf entscheidet")
	assert_true(_decide(g, 5, {"village_confirms": true}).ok, "Dorf bestätigt")
	assert_false(g.state.players[5].alive, "hingerichtet")
	_persist(g, "segen_03 bestätigt")


func test_segen_03_village_can_reject_the_execution_after_the_reveal() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"segen_03")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5, {"card_reveal": true}).ok, "Enthüllung")
	assert_true(_decide(g, 5, {"village_confirms": false}).ok, "Dorf lehnt ab")
	assert_true(g.state.players[5].alive, "keine Hinrichtung")
	assert_false(g.has_effect("lynch_reveal"), "Enthüllung gibt es nur im ersten Wahlgang")
	_nominate(g, 6, 7)
	assert_true(_decide(g, 6).ok, "zweiter Wahlgang ohne Enthüllung")
	assert_false(g.state.players[6].alive, "hingerichtet")


func test_segen_05_fluch_03_fluch_13_fluch_09_and_wende_09_store_their_table_rules() -> void:
	var cases := [
		[&"segen_05", VILLAGE_OWNER, [5], "vote_double_one"],
		[&"fluch_03", VILLAGE_OWNER, [], "vote_forbid"],
		[&"fluch_13", VILLAGE_OWNER, [], "vote_forbid_faction"],
		[&"fluch_09", VILLAGE_OWNER, [], "vote_zero_faction"],
		[&"wende_09", VILLAGE_OWNER, [], "vote_double_faction"],
		[&"fluch_03", WOLF_OWNER, [], "vote_forbid"],
	]
	for c: Array in cases:
		var g := _game()
		g.arm(int(c[1]), StringName(c[0]))
		g.play_with(c[2])
		var effects := CardEffects.effects(g.state, String(c[3]))
		assert_eq(effects.size(), 1, "%s: Effekt %s gespeichert" % [c[0], c[3]])
		if String(c[3]) == "vote_forbid":
			var banned: Array = effects[0]["data"]["ids"]
			var variant := CardCatalog.owner_variant(g.state.players[int(c[1])])
			assert_eq(banned.size(), 1, "%s: genau eine Person verliert die Stimme" % c[0])
			assert_eq(CardCatalog.owner_variant(g.state.players[int(banned[0])]), variant, "%s: aus der Fraktion der Besitzerin" % c[0])
		if String(c[0]) in ["fluch_09", "wende_09"]:
			assert_true(g.has_effect("secret_result"), "%s: Ergebnis wird geheim gehalten" % c[0])
		_persist(g, String(c[0]))


func test_segen_09_wolf_grants_two_pack_victims_after_a_wolf_execution() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_09")
	g.play_with()
	assert_true(g.has_effect("lynch_wolf_bonus"), "Effekt gespeichert")
	g.skip_cards()
	_nominate(g, 1)
	assert_true(_decide(g, 1).ok, "Wolf hingerichtet")
	assert_false(g.state.players[1].alive, "der Wolf starb")
	assert_true(g.has_effect("pack_bonus"), "Bonus für die Folgenacht")
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var p := g.state.pending_prompt
	assert_true(p != null and p.owner == PendingPrompt.OWNER_PACK and p.max_count == 2, "das Rudel darf zwei Opfer wählen")
	_persist(g, "segen_09 wolf")


func test_segen_09_village_and_wende_03_save_the_next_executed_villager() -> void:
	for card: StringName in [&"segen_09", &"wende_03"]:
		var g := _game()
		g.arm(VILLAGE_OWNER, card)
		g.play_with()
		assert_true(g.has_effect("lynch_save_village"), "%s: Effekt gespeichert" % card)
		g.skip_cards()
		_nominate(g, 5)
		assert_true(_decide(g, 5).ok, "%s: Entscheidung angenommen" % card)
		assert_true(g.state.players[5].alive, "%s: die Dorfperson überlebt" % card)
		assert_eq(g.events_of(GameEvent.EXECUTION_PREVENTED_BY_CARD).size(), 1, "%s: Verhinderung protokolliert" % card)
		_persist(g, String(card))


func test_wende_03_does_not_save_a_wolf() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"wende_03")
	g.play_with()
	g.skip_cards()
	_nominate(g, 1)
	assert_true(_decide(g, 1).ok, "Entscheidung angenommen")
	assert_false(g.state.players[1].alive, "ein Wolf wird nicht gerettet")


func test_fluch_04_village_keeps_executing_until_a_villager_was_chosen() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"fluch_04")
	g.play_with()
	g.skip_cards()
	_nominate(g, 1)
	_nominate(g, 5, 6)
	assert_true(_decide(g, 1).ok, "erste Hinrichtung (Wolf)")
	assert_false(g.state.players[1].alive, "Wolf tot")
	assert_eq(g.state.day_step, Phase.DAY_NOMINATION, "der Tag bleibt offen, solange keine Dorfperson gewählt wurde")
	assert_true(_decide(g, 5).ok, "zweite Hinrichtung (Dorfperson)")
	assert_false(g.state.players[5].alive, "Dorfperson tot")
	assert_eq(g.state.day_step, Phase.DAY_EXECUTION_DECIDED, "danach ist der Tag entschieden")
	assert_false(g.has_effect("lynch_until_village"), "Effekt verbraucht")
	_persist(g, "fluch_04 dorf")


func test_fluch_10_village_kills_a_random_villager_at_day_end_when_no_wolf_was_executed() -> void:
	var quiet := _game()
	quiet.arm(VILLAGE_OWNER, &"fluch_10")
	quiet.play_with()
	quiet.skip_cards()
	_nominate(quiet, 5)
	assert_true(_decide(quiet, 5).ok, "Dorfperson hingerichtet")
	var before := quiet.dead_ids()
	quiet.end_day()
	var died := quiet.dead_ids().filter(func(id: int) -> bool: return not before.has(id))
	assert_eq(died.size(), 1, "am Tagesende stirbt eine weitere Dorfperson")
	assert_eq(CardCatalog.owner_variant(quiet.state.players[died[0]]), CardCatalog.DORF, "eine Dorfperson")
	var wolf := _game()
	wolf.arm(VILLAGE_OWNER, &"fluch_10")
	wolf.play_with()
	wolf.skip_cards()
	_nominate(wolf, 1)
	assert_true(_decide(wolf, 1).ok, "Wolf hingerichtet")
	var wolf_before := wolf.dead_ids()
	wolf.end_day()
	assert_eq(wolf.dead_ids(), wolf_before, "bei einer Wolfshinrichtung stirbt niemand zusätzlich")
	_persist(wolf, "fluch_10 dorf")


func test_wende_11_village_redirects_a_villager_execution_to_a_random_wolf_on_the_next_day() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"wende_11")
	g.play_with()
	assert_true(g.has_effect("lynch_redirect_wolf"), "Effekt gespeichert")
	g.skip_cards()
	_nominate(g, 6)
	assert_true(_decide(g, 6).ok, "Entscheidung angenommen")
	assert_true(g.state.players[6].alive, "die Dorfperson überlebt")
	var dead_wolves := WOLVES.filter(func(id: int) -> bool: return not g.state.players[id].alive)
	assert_eq(dead_wolves.size(), 1, "stattdessen stirbt ein zufälliger Wolf")
	_persist(g, "wende_11")
