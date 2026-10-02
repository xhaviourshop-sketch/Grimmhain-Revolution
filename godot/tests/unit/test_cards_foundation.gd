extends TestCase
## Totenreichkarten, Grundlage: Katalog, Option, Ziehung beim Tod, zwei Kartenfenster, Spielen, Aufbewahren, Tausch,
## Speichern, Laden und Replay (Umsetzungsauftrag 01.10.2026; Decision Log 1A, 3A und „Kartenfenster“).


func test_catalog_has_eighty_cards_with_all_variants() -> void:
	assert_eq(CardCatalog.ids().size(), 80, "80 Karten")
	var counts := {}
	for id: StringName in CardCatalog.ids():
		counts[CardCatalog.category(id)] = int(counts.get(CardCatalog.category(id), 0)) + 1
	assert_eq(counts, {&"segen": 14, &"fluch": 13, &"schicksal": 14, &"solo": 14, &"wende": 12, &"loki": 13}, "Karten je Kategorie")
	assert_eq(CardCatalog.pairs().size(), 39 * 2 + 27 + 14, "119 Varianten: 39 mit Wolf- und Dorftext, 27 neutral, 14 solo")
	for pair: Array in CardCatalog.pairs():
		assert_true(not CardCatalog.windows(pair[0], pair[1]).is_empty(), "%s/%s hat ein Fenster" % [pair[0], pair[1]])


func test_option_is_stored_and_defaults_to_off() -> void:
	var off := CardGame.started(self, 6, [1], 1, {}, {"death_cards": false})
	assert_false(off.state.death_cards, "ohne Option keine Karten")
	assert_true(off.state.cardsys.is_empty(), "ohne Option kein Kartenzustand")
	var on := CardGame.started(self, 6, [1])
	assert_true(on.state.death_cards, "mit Option")
	assert_eq((on.state.cardsys["records"] as Array).size(), 0, "noch keine Karte")
	assert_true(on.reload_equals(), "Speichern und Laden")
	assert_true(on.replay_equals(), "Replay")


func test_option_must_be_boolean_and_swallower_needs_cards() -> void:
	var bad := Command.start_game({"round_id": "x", "seed": 1, "assignment": "manual", "players": Fixtures.players(6), "seat_order": Fixtures.identity_order(6),
		"roles": Fixtures.filled_roles(6, [1]), "death_cards": "ja"})
	assert_eq(String(RulesEngine.apply(GameState.new(), bad).error), "invalid_death_cards", "nur Wahrheitswert")
	var roles := Fixtures.filled_roles(6, [1], {"5": "kartenschlucker"})
	var without := Command.start_game({"round_id": "x", "seed": 1, "assignment": "manual", "players": Fixtures.players(6), "seat_order": Fixtures.identity_order(6), "roles": roles})
	var r := RulesEngine.apply(GameState.new(), without)
	assert_false(r.ok, "Kartenschlucker ohne Totenreichkarten abgelehnt")
	assert_eq(String(r.error), "role_needs_death_cards", "Grund")
	var with := CardGame.started(self, 6, [1], 1, {"5": "kartenschlucker"})
	assert_eq(with.state.players[5].role_id, &"kartenschlucker", "mit Totenreichkarten zugelassen")
	assert_eq(RoleCatalog.faction_of(&"kartenschlucker"), Faction.SOLO, "Einzelsieg")


func test_a_night_death_draws_a_card_and_the_draw_is_reproducible() -> void:
	var first := CardGame.started(self, 6, [1], 5)
	first.night(4)
	first.settle()
	var rec := CardRules.held_of(first.state, 4)
	assert_false(rec.is_empty(), "Person 4 hat nach dem Tod eine Karte")
	assert_eq(String(rec["variant"]), "dorf" if CardCatalog.category(StringName(rec["card"])) in [&"segen", &"fluch", &"wende"] else String(rec["variant"]), "Variante nach Fraktion")
	var second := CardGame.started(self, 6, [1], 5)
	second.night(4)
	second.settle()
	assert_eq(CardRules.held_of(second.state, 4)["card"], rec["card"], "gleicher Seed, gleiche Karte")
	var drawn := events_of_type(first.events, "CardDrawn")
	assert_eq(drawn.size(), 1, "ein Ziehungsereignis")
	assert_eq(String(drawn[0].visibility), "gm", "Ziehung nur für die Spielleitung")
	assert_true(first.reload_equals() and first.replay_equals(), "Speichern, Laden und Replay")


func test_gm_correction_without_effects_gives_no_card_but_with_effects_does() -> void:
	var g := CardGame.started(self, 6, [1], 2)
	g.gm_kill(3, false)
	assert_true(CardRules.held_of(g.state, 3).is_empty(), "Korrektur ohne Todesfolgen: keine Karte")
	g.gm_kill(4, true)
	assert_false(CardRules.held_of(g.state, 4).is_empty() and CardRules.records(g.state).is_empty(), "Korrektur mit Todesfolgen: Karte")


func test_solo_persons_draw_only_neutral_and_solo_cards() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6, 7, 8]:
		var g := CardGame.started(self, 6, [1], seed_value, {"4": "rattenfaenger"}, {})
		g.gm_kill(4, true)
		var rec := CardRules.held_of(g.state, 4)
		if rec.is_empty():
			continue
		assert_true([&"schicksal", &"loki", &"solo"].has(CardCatalog.category(StringName(rec["card"]))), "Seed %d: Einzelsieg zieht nur neutrale und SOLO-Karten" % seed_value)
		assert_true(["neutral", "solo"].has(String(rec["variant"])), "Variante neutral oder solo")


func test_wolf_and_village_variants_follow_the_faction_at_death() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		var g := CardGame.started(self, 6, [1, 2], seed_value)
		g.gm_kill(2, true)
		g.gm_kill(3, true)
		var wolf := CardRules.held_of(g.state, 2)
		var village := CardRules.held_of(g.state, 3)
		if not wolf.is_empty() and [&"segen", &"fluch", &"wende"].has(CardCatalog.category(StringName(wolf["card"]))):
			assert_eq(String(wolf["variant"]), "wolf", "Wolf liest den Wolftext")
		if not village.is_empty() and [&"segen", &"fluch", &"wende"].has(CardCatalog.category(StringName(village["card"]))):
			assert_eq(String(village["variant"]), "dorf", "Dorf liest den Dorftext")
		assert_ne(String(village.get("card", "")), String(wolf.get("card", "x")), "keine Karte doppelt im Besitz")


func test_first_window_opens_before_the_discussion_and_blocks_the_day() -> void:
	var g := CardGame.started(self, 6, [1], 3)
	g.gm_kill(3, false)
	g.give(3, &"schicksal_13")
	g.night()
	assert_true(g.window_for(3), "Fenster 1 offen, Person 3 gefragt")
	assert_eq(CardRules.window_kind(g.state), CardCatalog.WIN_START, "Tagesbeginn")
	g.reject(Command.nominate(2, 4), "card_window_open", "keine Nominierung im Fenster")
	g.reject(Command.decide_execution(GameState.NO_TARGET), "card_window_open", "keine Hinrichtung im Fenster")
	g.reject(Command.end_day(), "card_window_open", "kein Tagesende im Fenster")
	g.reject(Command.card_act(4, "keep"), "not_current_card_owner", "nur die gefragte Person")
	g.do(Command.card_act(3, "keep"), "keep")
	assert_false(CardRules.window_open(g.state), "Fenster geschlossen")
	g.do(Command.nominate(2, 4), "Nominierung danach möglich")
	assert_false(CardRules.held_of(g.state, 3).is_empty(), "aufbewahrte Karte bleibt beim Besitzer")
	assert_true(g.reload_equals() and g.replay_equals(), "Laden und Replay")


func test_no_window_when_nobody_can_act() -> void:
	var g := CardGame.started(self, 6, [1], 3)
	g.night()
	assert_false(CardRules.window_open(g.state), "ohne Tote kein Fenster")
	g.end_day()
	assert_eq(g.state.day_step, Phase.DAY_ENDED, "Tag endet sofort ohne Fenster")


func test_playing_applies_the_effect_and_marks_the_card() -> void:
	var g := CardGame.started(self, 6, [1], 3)
	g.gm_kill(3, false)
	var rec := g.give(3, &"schicksal_13")
	g.night()
	g.do(Command.card_act(3, "play"), "play")
	assert_eq(String(CardRules.record_by_id(g.state, int(rec["id"]))["status"]), "played", "Karte gespielt")
	assert_eq(CardEffects.active(g.state, "silent_vote").size(), 1, "Tagesregel wirkt heute")
	assert_eq(events_of_type(g.events, "CardAnnounced").size(), 1, "öffentliche Ansage")
	assert_false(CardRules.window_open(g.state), "Fenster danach geschlossen")
	assert_true(CardRules.held_of(g.state, 3).is_empty(), "keine Karte mehr beim Besitzer")
	assert_true(g.reload_equals() and g.replay_equals(), "Laden und Replay")


func test_second_window_at_day_end_and_blocked_night_until_closed() -> void:
	var g := CardGame.started(self, 6, [1], 3)
	g.gm_kill(3, false)
	g.give(3, &"schicksal_01")
	g.night()
	g.do(Command.card_act(3, "keep"), "keep im ersten Fenster")
	g.do(Command.decide_execution(GameState.NO_TARGET), "keine Hinrichtung")
	g.do(Command.end_day(), "EndDay")
	assert_true(g.window_for(3), "zweites Fenster am Tagesende")
	assert_eq(CardRules.window_kind(g.state), CardCatalog.WIN_END, "Tagesende")
	assert_eq(g.state.day_step, Phase.DAY_CARDS_END, "Tagesende läuft")
	g.reject(Command.start_night(), "card_window_open", "keine Nacht im Fenster")
	g.do(Command.card_act(3, "play"), "play")
	assert_eq(g.state.day_step, Phase.DAY_ENDED, "Tag endet nach dem Fenster")
	var rules := CardEffects.effects(g.state, "no_role_talk")
	assert_eq(rules.size(), 1, "Nebelhorn: Tagesregel für den nächsten Tag")
	assert_eq(int(rules[0]["from"]), CardEffects.day_key(2), "gilt am Tag 2")
	g.do(Command.start_night(), "StartNight")
	assert_true(g.reload_equals() and g.replay_equals(), "Laden und Replay")


func test_close_window_keeps_every_remaining_card() -> void:
	var g := CardGame.started(self, 7, [1], 4)
	g.gm_kill(3, false)
	g.gm_kill(4, false)
	g.give(3, &"schicksal_13")
	g.give(4, &"schicksal_02")
	g.night()
	assert_eq(CardRules.candidates(g.state, CardCatalog.WIN_START), [3, 4], "beide gefragt, Reihenfolge nach Ziehreihenfolge")
	g.do(Command.card_close_window(), "Fenster schließen")
	assert_false(CardRules.window_open(g.state), "geschlossen")
	assert_false(CardRules.held_of(g.state, 3).is_empty() or CardRules.held_of(g.state, 4).is_empty(), "keine Karte verloren")
	assert_eq(CardRules.held_of(g.state, 3).is_empty(), false, "3 behält")
	assert_eq(CardRules.held_of(g.state, 4).is_empty(), false, "4 behält")


func test_first_window_only_cards_are_not_offered_at_day_end() -> void:
	var g := CardGame.started(self, 6, [1], 3)
	g.gm_kill(3, false)
	g.give(3, &"schicksal_13")  # nur Tagesbeginn
	g.night()
	g.do(Command.card_act(3, "keep"), "keep")
	g.end_day()
	assert_false(CardRules.window_open(g.state), "Stille Wahl ist am Tagesende nicht spielbar: kein zweites Fenster")
	assert_eq(g.state.day_step, Phase.DAY_ENDED, "Tag endet")


func test_exchange_needs_a_living_swallower_and_gives_one_stack() -> void:
	var g := CardGame.started(self, 7, [1], 6, {"5": "kartenschlucker"})
	g.gm_kill(3, false)
	g.give(3, &"schicksal_01")
	g.night()
	assert_true(g.window_for(3), "Fenster")
	g.do(Command.card_act(3, "exchange"), "Tausch")
	g.settle()
	assert_eq(SwallowerRules.total_of(g.state, 5), 1, "ein Stapel gesammelt")
	assert_eq(SwallowerRules.balance_of(g.state, 5), 1, "ein Stapel verfügbar")
	var records := CardRules.records(g.state)
	assert_eq(String(records[0]["status"]), "swapped", "Originalkarte getauscht")
	assert_eq(String(records[1]["status"]), "played", "Ersatzkarte sofort gespielt")
	assert_eq(String(records[1]["origin"]), "exchange", "Herkunft Tausch")
	assert_true(bool(records[1]["exchanged"]), "nicht erneut tauschbar")
	assert_true(g.reload_equals() and g.replay_equals(), "Laden und Replay")


func test_exchange_is_refused_without_a_living_swallower() -> void:
	var g := CardGame.started(self, 7, [1], 6)
	g.gm_kill(3, false)
	g.give(3, &"schicksal_01")
	g.night()
	g.reject(Command.card_act(3, "exchange"), "card_not_exchangeable", "ohne Kartenschlucker")
	var h := CardGame.started(self, 7, [1], 6, {"5": "kartenschlucker"})
	h.gm_kill(5, false)  # der Kartenschlucker ist tot
	h.gm_kill(3, false)
	h.give(3, &"schicksal_01")
	h.night()
	h.reject(Command.card_act(3, "exchange"), "card_not_exchangeable", "tot gilt nicht")


func test_an_unplayed_card_lapses_when_the_person_is_revived() -> void:
	var g := CardGame.started(self, 6, [1], 3)
	g.gm_kill(3, false)
	var rec := g.give(3, &"schicksal_01")
	g.gm_revive(3)
	assert_eq(String(CardRules.record_by_id(g.state, int(rec["id"]))["status"]), "lapsed", "Karte verfällt bei Wiederbelebung")
	assert_true(CardRules.held_of(g.state, 3).is_empty(), "nichts mehr beim Besitzer")


func test_win_check_waits_for_the_card_window() -> void:
	# Neun Personen, Wölfe 1 bis 3; zwei Dorfpersonen sind tot (drei gegen vier): der Nachttod von Person 6 ergibt Parität.
	var g := CardGame.started(self, 9, [1, 2, 3], 3)
	g.gm_kill(4, false)
	g.gm_kill(5, false)
	g.give(4, &"schicksal_13")
	g.night(6)
	assert_true(CardRules.window_open(g.state), "Fenster offen")
	assert_true(g.state.open_candidates().is_empty(), "Siegkandidat wartet auf das Fenster")
	g.do(Command.card_act(4, "keep"), "keep")
	if CardRules.window_open(g.state):
		g.close_window()  # die Karte der Nachtperson 6 ist je nach Zug ebenfalls spielbar: Fenster ausdrücklich schließen
	assert_false(CardRules.window_open(g.state), "Fenster geschlossen")
	assert_false(g.state.open_candidates().is_empty(), "nach dem Fenster entsteht der Kandidat")
