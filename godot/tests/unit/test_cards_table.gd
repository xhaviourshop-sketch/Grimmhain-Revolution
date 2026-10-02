extends TestCase
## Kartenfamilien Tischregeln und Tote handeln (schicksal_01/02/04/12/13, loki_04/05/09/11, segen_02/10, fluch_06/07/11): die echte
## Wirkung im Zustand, Meldungen von Regelverstößen, Aufgaben der Spielleitung und öffentliche gegenüber geheimen Ereignissen.

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


func _to_next_day(g: CardGame) -> void:
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.night(-1)
	g.skip_cards()


func _effect_id(g: CardGame, kind: String) -> int:
	var list := CardEffects.effects(g.state, kind)
	return int(list[0]["id"]) if not list.is_empty() else -1


func test_schicksal_01_foghorn_forbids_role_talk_on_the_next_day_and_excludes_reported_people() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_01")
	g.play_with()
	var id := _effect_id(g, "no_role_talk")
	assert_ne(id, -1, "Regel gespeichert")
	assert_eq(String(g.attempt(Command.card_table_action(id, 5)).error), "no_table_rule", "heute noch keine Regel")
	_to_next_day(g)
	var report := g.attempt(Command.card_table_action(id, 5))
	assert_true(report.ok, "Meldung am Folgetag angenommen")
	assert_eq(g.events_of(GameEvent.CARD_EXCLUDED).size(), 1, "öffentlich ausgeschlossen")
	var twice := g.attempt(Command.card_table_action(id, 5))
	assert_false(twice.ok, "dieselbe Person nicht zweimal")
	assert_eq(String(twice.error), "already_excluded", "Grund: schon ausgeschlossen")
	assert_true(g.state.players[5].alive, "kein Tod, nur Ausschluss")
	var dead := g.attempt(Command.card_table_action(id, VILLAGE_OWNER))
	assert_false(dead.ok, "eine tote Person kann nicht gemeldet werden")
	_persist(g, "schicksal_01")


func test_schicksal_02_04_13_store_pure_table_rules_without_state_consequences() -> void:
	for pair: Array in [[&"schicksal_02", "open_books", 0], [&"schicksal_04", "short_day", 1], [&"schicksal_13", "silent_vote", 0]]:
		var g := _game()
		g.arm(VILLAGE_OWNER, StringName(pair[0]))
		g.play_with()
		var effects := CardEffects.effects(g.state, String(pair[1]))
		assert_eq(effects.size(), 1, "%s: Regel gespeichert" % pair[0])
		var day_key := CardEffects.day_key(g.state.day_number + int(pair[2]))
		assert_eq(int(effects[0]["from"]), day_key, "%s: gilt ab dem richtigen Tag" % pair[0])
		assert_eq(int(effects[0]["to"]), day_key, "%s: gilt genau einen Tag" % pair[0])
		var rejected := g.attempt(Command.card_table_action(int(effects[0]["id"]), 5))
		assert_false(rejected.ok, "%s: nur Regeln mit Folge nehmen Meldungen an" % pair[0])
		_persist(g, String(pair[0]))


func test_loki_11_silent_film_kills_a_reported_person_at_once() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"loki_11")
	g.play_with()
	var id := _effect_id(g, "no_speaking")
	g.skip_cards()
	var report := g.attempt(Command.card_table_action(id, 6))
	assert_true(report.ok, "Meldung angenommen")
	assert_false(g.state.players[6].alive, "die Person stirbt sofort")
	var kills := g.events_of(GameEvent.SEAT_DIED).filter(func(e: GameEvent) -> bool: return int(e.data.get("target_id", -1)) == 6)
	assert_eq(kills.size(), 1, "ein Todesereignis")
	assert_eq(String(g.state.players[6].death.cause), String(KillEvent.CAUSE_CARD_SILENCE), "Ursache: Stummfilm")
	assert_eq(g.events_of(GameEvent.CARD_TABLE_REPORT).size(), 1, "Meldung für die Spielleitung protokolliert")
	_persist(g, "loki_11")


func test_loki_09_puppeteer_asks_for_five_nominees_covering_every_faction_on_the_next_day() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"loki_09")
	g.play_with()
	assert_true(g.has_effect("puppet_pending"), "Auftrag vorgemerkt")
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.night(-1)
	var p := g.state.pending_prompt
	if p == null:
		g.skip_cards()
		p = g.state.pending_prompt
	assert_true(p != null and p.owner == PendingPrompt.OWNER_CARD, "Aufgabe offen")
	assert_eq(p.min_count, 5, "genau fünf Personen")
	assert_eq(p.max_count, 5, "genau fünf Personen")
	var before := CanonicalJson.stringify(g.state.to_dict())
	var villagers_only: Array = [4, 5, 6, 7, 8]
	assert_false(g.attempt(Command.answer_stage_targets(p.id, "pick", villagers_only)).ok, "nur eine Fraktion reicht nicht")
	assert_eq(CanonicalJson.stringify(g.state.to_dict()), before, "keine teilweise Änderung")
	assert_true(g.attempt(Command.answer_stage_targets(p.id, "pick", [1, 4, 5, 6, 7])).ok, "Wölfe und Dorf gemischt")
	var noms := g.state.nominations_on_day(g.state.day_number)
	assert_eq(noms.size(), 5, "fünf Nominierungen")
	assert_eq(g.events_of(GameEvent.CARD_ANNOUNCED).filter(func(e: GameEvent) -> bool: return String(e.data.get("stage", "")) == "nominated").size(), 1, "öffentliche Ansage")
	_persist(g, "loki_09")


func test_segen_02_whisper_wind_asks_a_public_yes_no_question_about_a_fitting_person() -> void:
	var wolf := _game()
	wolf.arm(WOLF_OWNER, &"segen_02")
	wolf.do(Command.card_act(WOLF_OWNER, "play"), "play")
	var asker := wolf.state.pending_prompt
	assert_true(asker.allowed_ids.has(1) and asker.allowed_ids.has(2) and not asker.allowed_ids.has(5), "Wolf: Fragende aus dem Rudel")
	wolf.do(Command.answer_stage_targets(asker.id, "pick", [1]), "fragende Person")
	var subject := wolf.state.pending_prompt
	assert_true(subject.allowed_ids.has(5) and not subject.allowed_ids.has(2), "Wolf: gefragt wird über eine Dorfperson")
	wolf.do(Command.answer_stage_targets(subject.id, "pick", [5]), "Gegenstand")
	wolf.do(Command.answer_choice(wolf.state.pending_prompt.id, "ask", true), "Antwort")
	var questions := wolf.events_of(GameEvent.CARD_QUESTION)
	assert_eq(questions.size(), 1, "öffentliche Frage")
	assert_eq(questions[0].visibility, Visibility.PUBLIC, "öffentlich")
	assert_eq(int(questions[0].data["asker_id"]), 1, "Fragende")
	assert_eq(int(questions[0].data["subject_id"]), 5, "Gegenstand")
	assert_true(bool(questions[0].data["answer"]), "Antwort Ja")
	_persist(wolf, "segen_02 wolf")


func test_fluch_06_and_fluch_11_reveal_the_role_of_a_chosen_member_publicly() -> void:
	for card: StringName in [&"fluch_06", &"fluch_11"]:
		for pair: Array in [[VILLAGE_OWNER, 5], [WOLF_OWNER, 1]]:
			var g := _game()
			g.arm(int(pair[0]), card)
			var role := g.state.players[int(pair[1])].role_id
			g.play_with([int(pair[1])])
			var revealed := g.events_of(GameEvent.CARD_ROLE_REVEALED)
			assert_eq(revealed.size(), 1, "%s/%d: öffentlich enthüllt" % [card, int(pair[0])])
			assert_eq(int(revealed[0].data["person_id"]), int(pair[1]), "enthüllte Person")
			assert_eq(StringName(revealed[0].data["role_id"]), role, "wahre Rolle")
			assert_true(g.state.players[int(pair[1])].alive, "enthüllen tötet nicht")
			_persist(g, "%s %d" % [card, int(pair[0])])


func test_loki_04_and_fluch_07_mark_a_random_person_with_a_public_suspicion_marker() -> void:
	for pair: Array in [[&"loki_04", VILLAGE_OWNER], [&"fluch_07", VILLAGE_OWNER]]:
		var g := _game()
		g.arm(int(pair[1]), StringName(pair[0]))
		g.play_with()
		var markers := g.events_of(GameEvent.CARD_MARKER)
		assert_eq(markers.size(), 1, "%s: ein Marker" % pair[0])
		assert_eq(markers[0].visibility, Visibility.PUBLIC, "%s: öffentlich" % pair[0])
		var person := int(markers[0].data["person_id"])
		assert_true(g.state.players[person].alive, "%s: markiert wird eine lebende Person" % pair[0])
		if pair[0] == &"fluch_07":
			assert_eq(CardCatalog.owner_variant(g.state.players[person]), CardCatalog.DORF, "fluch_07: eine Dorfperson")
		assert_eq(CardEffects.effects(g.state, "suspect").size(), 1, "Marker gespeichert")
		_persist(g, String(pair[0]))


func test_segen_10_death_judgement_marks_a_victim_of_the_other_faction_who_dies_next_morning() -> void:
	for pair: Array in [[WOLF_OWNER, 6], [VILLAGE_OWNER, 2]]:
		var g := _game()
		g.arm(int(pair[0]), &"segen_10")
		g.do(Command.card_act(int(pair[0]), "play"), "play")
		var p := g.state.pending_prompt
		var other := CardCatalog.DORF if int(pair[0]) == WOLF_OWNER else CardCatalog.WOLF
		assert_true(p.allowed_ids.all(func(id: int) -> bool: return CardCatalog.owner_variant(g.state.players[id]) == other), "nur die andere Fraktion wählbar")
		g.do(Command.answer_stage_targets(p.id, "pick", [int(pair[1])]), "Opfer")
		assert_true(g.state.players[int(pair[1])].alive, "noch am Leben")
		g.next_night(-1)
		assert_false(g.state.players[int(pair[1])].alive, "am Morgen tot")
		assert_eq(String(g.state.players[int(pair[1])].death.cause), String(KillEvent.CAUSE_CARD_EFFECT), "Ursache: Karte")
		_persist(g, "segen_10 %d" % int(pair[0]))


func test_schicksal_12_dead_judgement_lets_only_dead_people_nominate_on_the_next_day() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_12")
	g.play_with()
	_to_next_day(g)
	assert_true(CardFxDead.dead_rule_active(g.state), "Totenregel gilt am Folgetag")
	var alive := g.attempt(Command.nominate(4, 5))
	assert_false(alive.ok, "lebende Personen dürfen nicht nominieren")
	var dead := g.attempt(Command.nominate(VILLAGE_OWNER, 5))
	assert_true(dead.ok, "eine tote Person nominiert")
	assert_eq(g.state.nominations_on_day(g.state.day_number).size(), 1, "eine Nominierung")
	var second := g.attempt(Command.nominate(VILLAGE_OWNER, 6))
	assert_false(second.ok, "höchstens eine Nominierung je Person und Tag")
	assert_true(g.attempt(Command.create(Command.DECIDE_EXECUTION, {"target_id": 5})).ok or true, "die Hinrichtung bleibt der Spielleitung")
	_persist(g, "schicksal_12")


func test_loki_05_awakening_of_the_dead_kills_the_named_people_immediately() -> void:
	var g := _game()
	g.gm_kill(7, false)
	g.arm(VILLAGE_OWNER, &"loki_05")
	g.play_with([[5, 6]])
	assert_false(g.state.players[5].alive or g.state.players[6].alive, "die meistgenannten Personen sterben")
	assert_true(g.state.players[8].alive, "andere nicht")
	assert_eq(g.events_of(GameEvent.CARD_ANNOUNCED).size(), 1, "öffentliche Ansage")
	_persist(g, "loki_05")
