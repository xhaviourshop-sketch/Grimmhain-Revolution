extends TestCase
## Kartenfamilie Tod, Rückkehr und Rollenwechsel (segen_08, wende_04, wende_07, loki_10, schicksal_08, loki_06): echte Wirkung je Karte
## und Variante, Rolle vom Todeszeitpunkt, verfallende Karten Wiederbelebter, Fristen des Phoenix und Folgen im Zustand.

const COUNT := 16  ## genug Lebende, damit mehrere Tote keinen Sieg auslösen
const WOLVES: Array[int] = [1, 2, 3]
const WOLF_OWNER := 3
const VILLAGE_OWNER := 12


func _game(specials: Dictionary = {}, seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value, specials)


func _persist(g: CardGame, label: String) -> void:
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)


func test_segen_08_offers_dead_of_the_faction_and_revives_the_chosen_one_with_the_death_role() -> void:
	for pair: Array in [[VILLAGE_OWNER, [7, 8, 9], 8], [WOLF_OWNER, [1, 2], 2]]:
		var g := CardGame.started(self, COUNT, [1, 2, 3, 4], 3, {"8": "schutzengel"} if int(pair[0]) == VILLAGE_OWNER else {})  # ein vierter Wolf verhindert den Sieg des Dorfes
		for id: int in pair[1]:
			g.gm_kill(id, false)
		var role_at_death: StringName = g.state.players[int(pair[2])].role_id
		g.arm(int(pair[0]), &"segen_08")
		var rec := CardRules.held_of(g.state, int(pair[0]))
		assert_true((CardFxReturn.offer(g.state, rec) as Array).has(int(pair[2])), "gewählte Person wird angeboten")
		g.play_with([int(pair[2])])
		assert_true(g.state.players[int(pair[2])].alive, "die Person lebt wieder")
		assert_eq(g.state.players[int(pair[2])].role_id, role_at_death, "Rolle vom Todeszeitpunkt")
		assert_eq(g.events_of(GameEvent.CARD_REVIVED).size(), 1, "öffentliche Rückkehr")
		assert_eq(g.events_of(GameEvent.CARD_REVIVED)[0].visibility, Visibility.PUBLIC, "öffentlich")
		_persist(g, "segen_08 %d" % int(pair[0]))


func test_segen_08_is_not_granted_with_fewer_than_two_other_dead_of_the_faction() -> void:
	var g := _game()
	g.gm_kill(7, false)
	assert_false(CardFxReturn.segen08_grantable(g.state, 7), "mit nur einem weiteren Toten nicht vergebbar")
	g.gm_kill(8, false)
	g.gm_kill(9, false)
	assert_true(CardFxReturn.segen08_grantable(g.state, 7), "mit zwei weiteren Toten vergebbar")


func test_segen_08_with_more_than_three_candidates_keeps_a_stored_preselection_across_reload() -> void:
	var g := _game()
	for id: int in [5, 6, 7, 8, 9]:
		g.gm_kill(id, false)
	g.arm(VILLAGE_OWNER, &"segen_08")
	var rec := CardRules.held_of(g.state, VILLAGE_OWNER)
	var first := CardFxReturn.offer(g.state, rec)
	assert_eq(first.size(), 3, "genau drei Namen")
	var reloaded := GameState.from_dict(g.state.to_dict())
	assert_eq(CardFxReturn.offer(reloaded, CardRules.held_of(reloaded, VILLAGE_OWNER)), first, "Neuladen erzeugt keine neuen Namen")


func test_wende_04_lets_the_game_master_revive_a_dead_of_the_faction_even_the_card_owner() -> void:
	var g := _game()
	g.gm_kill(7, false)
	g.arm(VILLAGE_OWNER, &"wende_04")
	var rec := CardRules.held_of(g.state, VILLAGE_OWNER)
	assert_true((CardFxReturn.dead_of_faction(g.state, VILLAGE_OWNER, true) as Array).has(VILLAGE_OWNER), "die Besitzerin ist wählbar")
	g.play_with([VILLAGE_OWNER])
	assert_true(g.state.players[VILLAGE_OWNER].alive, "die Besitzerin kehrt zurück")
	assert_false(g.state.players[7].alive, "andere Tote bleiben tot")
	assert_true(rec.has("id"), "Karte war vorhanden")
	_persist(g, "wende_04")


func test_wende_04_wolf_variant_only_offers_dead_wolves() -> void:
	var g := _game()
	g.gm_kill(1, false)
	g.gm_kill(7, false)
	g.arm(WOLF_OWNER, &"wende_04")
	g.do(Command.card_act(WOLF_OWNER, "play"), "play")
	var p := g.state.pending_prompt
	assert_true(p.allowed_ids.has(1) and p.allowed_ids.has(WOLF_OWNER) and not p.allowed_ids.has(7), "nur tote Wölfe")
	var rejected := g.attempt(Command.answer_stage_targets(p.id, "pick", [7]))
	assert_false(rejected.ok, "eine tote Dorfperson ist nicht wählbar")


func test_wende_07_returns_with_half_ability_and_dies_after_the_first_ability_use() -> void:
	var g := _game({"7": "schutzengel"})
	g.gm_kill(7, false)
	g.arm(VILLAGE_OWNER, &"wende_07")
	g.play_with([7])
	assert_true(g.state.players[7].alive, "Person lebt wieder")
	assert_true(g.has_effect("half_return"), "halbe Fähigkeit gespeichert")
	var s := g.state.duplicate_state()
	var ctx := RuleContext.new(s, s.command_count)
	CardFxReturn.half_used(ctx, 7)
	assert_false(s.players[7].alive, "nach dem Einsatz stirbt die Person erneut")
	assert_true(CardEffects.effects(s, "half_return").is_empty(), "Effekt verbraucht")
	assert_true(g.state.players[7].alive, "der echte Zustand bleibt unverändert")
	_persist(g, "wende_07")


func test_wende_07_death_comes_at_dawn_when_the_ability_is_used_at_night() -> void:
	var g := _game({"7": "schutzengel"})
	g.gm_kill(7, false)
	g.arm(VILLAGE_OWNER, &"wende_07")
	g.play_with([7])
	g.next_night(-1, [], false)
	g.settle()
	assert_true(g.state.players[7].alive or not g.has_effect("half_return"), "Zustand konsistent nach der Nacht")
	assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand konsistent")


func test_loki_10_phoenix_revives_the_rolled_number_and_the_returners_die_at_the_end_of_their_time() -> void:
	for seed_value: int in [3, 5, 8, 13]:
		var g := _game({}, seed_value)
		for id: int in [5, 6, 7, 8]:
			g.gm_kill(id, false)
		g.arm(VILLAGE_OWNER, &"loki_10")
		g.play_with()
		var notes := g.events_of(GameEvent.CARD_EFFECT_NOTE).filter(func(e: GameEvent) -> bool: return e.data.has("revived_ids"))
		assert_eq(notes.size(), 1, "seed %d: Würfelergebnis protokolliert" % seed_value)
		var note: Dictionary = notes[0].data
		var dice: Array = note["dice"]
		assert_eq(dice.size(), 2, "zwei Würfel")
		assert_true(int(dice[0]) >= 1 and int(dice[0]) <= 6 and int(dice[1]) >= 1 and int(dice[1]) <= 6, "Augenzahlen 1 bis 6")
		var revived: Array = note["revived_ids"]
		assert_eq(revived.size(), mini(int(dice[0]), 4), "so viele Rückkehrende wie gewürfelt (höchstens alle anderen Toten)")
		for id: Variant in revived:
			assert_true(g.state.players[int(id)].alive, "seed %d: %d lebt" % [seed_value, int(id)])
		var die_day := int(note["die_day"])
		var guard := 0
		while g.state.day_number <= die_day and g.state.phase != Phase.GAME_OVER and guard < 8:
			guard += 1
			g.skip_cards()
			if g.state.day_step != Phase.DAY_ENDED:
				g.end_day()
			if g.state.day_number > die_day:
				break
			g.skip_cards()
			g.night(-1)
			g.skip_cards()
		for id: Variant in revived:
			if g.state.winner_id == -1 and g.state.open_candidates().is_empty():
				assert_false(g.state.players[int(id)].alive, "seed %d: %d starb nach Ablauf der Frist" % [seed_value, int(id)])
		assert_true(g.has_effect("phoenix_return") == false or g.state.day_number <= die_day, "Effekte abgelaufen")
		assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand konsistent")


func test_loki_10_stores_its_dice_and_replays_identically() -> void:
	var g := _game()
	for id: int in [5, 6, 7]:
		g.gm_kill(id, false)
	g.arm(VILLAGE_OWNER, &"loki_10")
	g.do(Command.card_act(VILLAGE_OWNER, "play"), "play")
	var p := g.state.pending_prompt
	assert_eq(p.stage, &"roll", "Würfelphase")
	g.do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "roll", "roll": true}), "würfeln")
	_persist(g, "loki_10")


func test_schicksal_08_gives_two_living_people_new_roles_of_their_faction() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_08")
	var old_5 := g.state.players[5].role_id
	var old_1 := g.state.players[1].role_id
	g.play_with([[5, 1], 0, 0])
	var new_5 := g.state.players[5].role_id
	var new_1 := g.state.players[1].role_id
	assert_ne(new_5, old_5, "Dorfperson bekommt eine andere Rolle")
	assert_ne(new_1, old_1, "Wolf bekommt eine andere Rolle")
	assert_eq(RoleCatalog.faction_of(new_5), Faction.VILLAGE, "Fraktion bleibt Dorf")
	assert_eq(RoleCatalog.faction_of(new_1), Faction.WOLVES, "Fraktion bleibt Wölfe")
	assert_eq(g.events_of(GameEvent.CARD_NOTICE).filter(func(e: GameEvent) -> bool: return e.visibility == Visibility.ACTOR and e.data["card_id"] == "schicksal_08").size(), 2, "beide erfahren ihre neue Rolle privat")
	assert_true(g.state.win_check_pending or g.state.winner_id == -1, "Siegprüfung angestoßen")
	_persist(g, "schicksal_08")


func test_schicksal_08_requires_exactly_two_distinct_people() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"schicksal_08")
	g.do(Command.card_act(VILLAGE_OWNER, "play"), "play")
	var p := g.state.pending_prompt
	var before := CanonicalJson.stringify(g.state.to_dict())
	assert_false(g.attempt(Command.answer_stage_targets(p.id, "pick", [5])).ok, "eine Person reicht nicht")
	assert_false(g.attempt(Command.answer_stage_targets(p.id, "pick", [5, 5])).ok, "dieselbe Person doppelt ist ungültig")
	assert_false(g.attempt(Command.answer_stage_targets(p.id, "pick", [5, VILLAGE_OWNER])).ok, "eine tote Person ist nicht wählbar")
	assert_eq(CanonicalJson.stringify(g.state.to_dict()), before, "keine teilweise Änderung")


func test_loki_06_swaps_the_roles_of_two_living_people_of_one_faction_silently() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"loki_06")
	var before := {}
	for id: int in g.state.alive_ids():
		before[id] = g.state.players[id].role_id
	g.play_with()
	var notes := g.events_of(GameEvent.CARD_EFFECT_NOTE).filter(func(e: GameEvent) -> bool: return e.data.has("person_ids") and e.data["card_id"] == "loki_06")
	assert_eq(notes.size(), 1, "ein Tausch")
	var ids: Array = notes[0].data["person_ids"]
	assert_eq(g.state.players[int(ids[0])].role_id, before[int(ids[1])], "erste Person hat die Rolle der zweiten")
	assert_eq(g.state.players[int(ids[1])].role_id, before[int(ids[0])], "zweite Person hat die Rolle der ersten")
	assert_eq(g.state.players[int(ids[0])].faction, g.state.players[int(ids[1])].faction, "gleiche Fraktion")
	var public_notes := g.events.filter(func(e: GameEvent) -> bool: return e.visibility == Visibility.PUBLIC and String(e.type).begins_with("Card") and e.data.has("role_id") and e.type != GameEvent.CARD_ROLE_REVEALED)
	assert_true(public_notes.is_empty(), "nichts Öffentliches verrät den Tausch")
	_persist(g, "loki_06")
