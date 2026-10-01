extends TestCase
## Kartenfamilie Schutz, Umleitung und Todesketten (segen_01/07/11, wende_02/05, fluch_05/08/12, loki_12): je Variante die echte
## Wirkung über Befehle (Hinrichtung, Nacht, Rudelangriff); Fähigkeitstode werden über die Tötungsstufe des Kerns ausgelöst, weil
## der Test keine Rollen mit Tötungsfähigkeit braucht. Jede Karte endet mit Replay- und Ladeprüfung.

const COUNT := 12
const WOLVES: Array[int] = [1, 2, 3]
const WOLF_OWNER := 3
const VILLAGE_OWNER := 12


func _game(seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value)


## Tötung durch eine Rollenfähigkeit (Quelle Person) auf einer Kopie des Zustands.
func _ability_kill(g: CardGame, target: int, cause: StringName = KillEvent.CAUSE_WITCH_POISON) -> GameState:
	var s := g.state.duplicate_state()
	var ctx := RuleContext.new(s, s.command_count)
	KillPipeline.request_kill(ctx, target, cause, KillEvent.SOURCE_PLAYER, 5)
	return s


func _check_persistence(g: CardGame, label: String) -> void:
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)


func test_segen_01_wolf_swaps_the_next_wolf_death_for_a_villager() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_01")
	g.play_with()
	assert_true(g.has_effect("heal_swap_w"), "Effekt gespeichert")
	g.skip_cards()
	var before := g.dead_ids()
	g.lynch(1)
	assert_true(g.state.players[1].alive, "der gelynchte Wolf lebt")
	var died := g.dead_ids().filter(func(id: int) -> bool: return not before.has(id))
	assert_eq(died.size(), 1, "stattdessen stirbt genau eine Person")
	assert_true(CardCatalog.owner_variant(g.state.players[died[0]]) == CardCatalog.DORF, "eine Dorfperson")
	assert_false(g.has_effect("heal_swap_w"), "Effekt verbraucht")
	assert_eq(g.events_of(GameEvent.KILL_PREVENTED).size(), 1, "Verhinderung protokolliert")
	_check_persistence(g, "segen_01 wolf")


func test_segen_01_village_gives_a_shield_and_stops_the_next_pack_attack() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"segen_01")
	g.play_with()
	assert_true(g.has_effect("heal_hand_d"), "Effekt gespeichert")
	g.next_night(5)
	assert_true(g.state.players[5].alive, "Rudelangriff scheitert")
	assert_true((g.state.cardsys["shields"] as Array).has(5), "persönlicher Schild")
	assert_false(g.has_effect("heal_hand_d"), "Effekt verbraucht")
	g.next_night(5)
	assert_true(g.state.players[5].alive, "der Schild verhindert auch den zweiten Angriff")
	assert_false((g.state.cardsys["shields"] as Array).has(5), "Schild verbraucht")
	g.next_night(5)
	assert_false(g.state.players[5].alive, "danach stirbt die Person")
	_check_persistence(g, "segen_01 dorf")


func test_segen_07_wolf_negates_only_the_next_ability_kill_on_a_wolf() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_07")
	g.play_with()
	assert_true(g.has_effect("negate_ability_w"), "Effekt gespeichert")
	var first := _ability_kill(g, 1)
	assert_true(first.players[1].alive, "die Fähigkeit tötet den Wolf nicht")
	assert_true(CardEffects.effects(first, "negate_ability_w").is_empty(), "Effekt verbraucht")
	# Dorfpersonen und Hinrichtungen sind nicht betroffen.
	var villager := _ability_kill(g, 5)
	assert_false(villager.players[5].alive, "Dorfperson stirbt normal")
	g.skip_cards()
	g.lynch(2)
	assert_false(g.state.players[2].alive, "die Hinrichtung wird nicht negiert")
	_check_persistence(g, "segen_07 wolf")


func test_segen_07_village_reveals_zero_to_two_wolves_after_the_next_night_victim() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"segen_07")
	g.play_with()
	assert_true(g.has_effect("blood_pact_d"), "Effekt gespeichert")
	g.next_night(5, [], false)
	assert_true(g.state.pending_prompt != null and g.state.pending_prompt.owner == PendingPrompt.OWNER_CARD, "Aufgabe: Wölfe aufdecken")
	var p := g.state.pending_prompt
	assert_eq(p.min_count, 0, "null bis ...")
	assert_eq(p.max_count, 2, "... zwei Wölfe")
	assert_true(p.allowed_ids.has(1) and p.allowed_ids.has(2) and not p.allowed_ids.has(5), "nur lebende Wölfe")
	g.do(Command.answer_stage_targets(p.id, "pick", [1, 2]), "aufdecken")
	var announced := g.events_of(GameEvent.CARD_ANNOUNCED)
	assert_eq(announced.size(), 1, "öffentliche Ansage")
	assert_eq(announced[0].visibility, Visibility.PUBLIC, "öffentlich")
	assert_eq(announced[0].data["values"]["wolf_ids"], [1, 2], "aufgedeckte Wölfe")
	assert_false(g.has_effect("blood_pact_d"), "Effekt verbraucht")
	_check_persistence(g, "segen_07 dorf")


func test_segen_11_wolf_kills_the_nominator_when_a_wolf_is_lynched() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_11")
	g.play_with()
	assert_true(g.has_effect("lynch_swap_nominator"), "Effekt gespeichert")
	g.skip_cards()
	g.lynch(1, 5)
	assert_true(g.state.players[1].alive, "der Wolf überlebt")
	assert_false(g.state.players[5].alive, "die nominierende Person stirbt")
	assert_false(g.has_effect("lynch_swap_nominator"), "Effekt verbraucht")
	_check_persistence(g, "segen_11 wolf")


func test_segen_11_wolf_does_not_trigger_for_a_villager_lynch() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"segen_11")
	g.play_with()
	g.skip_cards()
	g.lynch(6, 5)
	assert_false(g.state.players[6].alive, "Dorfperson stirbt normal")
	assert_true(g.state.players[5].alive, "Nominierende lebt")
	assert_true(g.has_effect("lynch_swap_nominator"), "Effekt bleibt für die nächste Wolfshinrichtung")


func test_segen_11_village_redirects_the_pack_catch_to_a_wolf() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"segen_11")
	g.play_with()
	assert_true(g.has_effect("pack_catch_swap"), "Effekt gespeichert")
	g.next_night(5)
	assert_true(g.state.players[5].alive, "Dorfperson überlebt")
	var dead_wolves := [1, 2].filter(func(id: int) -> bool: return not g.state.players[id].alive)
	assert_eq(dead_wolves.size(), 1, "stattdessen stirbt ein lebender Wolf")
	assert_false(g.has_effect("pack_catch_swap"), "Effekt verbraucht")
	_check_persistence(g, "segen_11 dorf")


func test_wende_02_wolf_protects_a_wolf_from_the_next_two_executions() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"wende_02")
	g.play_with()
	assert_true(g.has_effect("protect_pick_pending"), "Auswahl in der nächsten Nacht vorgemerkt")
	g.next_night(-1, [[1]])
	assert_true(g.has_effect("lynch_immune"), "Schutz vor der Hinrichtung gespeichert")
	g.skip_cards()
	var before := g.dead_ids()
	g.lynch(1, 5)
	assert_true(g.state.players[1].alive, "geschützt")
	assert_eq(g.dead_ids(), before, "niemand starb")
	assert_eq(g.events_of(GameEvent.EXECUTION_PREVENTED_BY_CARD).size(), 1, "Verhinderung protokolliert")
	_check_persistence(g, "wende_02 wolf")


func test_wende_02_village_protects_a_villager_for_three_nights() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"wende_02")
	g.play_with()
	g.next_night(4, [[4]])
	assert_true(g.state.players[4].alive, "Nacht 1: geschützt")
	g.next_night(4)
	assert_true(g.state.players[4].alive, "Nacht 2: geschützt")
	g.next_night(4)
	assert_true(g.state.players[4].alive, "Nacht 3: geschützt")
	g.next_night(4)
	assert_false(g.state.players[4].alive, "Nacht 4: der Schutz ist abgelaufen")
	_check_persistence(g, "wende_02 dorf")


func test_wende_05_wolf_postpones_the_next_wolf_death_by_two_days() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"wende_05")
	g.play_with()
	assert_true(g.has_effect("defer_death"), "Effekt gespeichert")
	g.skip_cards()
	g.lynch(1, 5)
	assert_true(g.state.players[1].alive, "lebt vorerst")
	assert_true(CardHooks.deferred_ids(g.state).has(1), "Tod aufgeschoben")
	assert_false(g.has_effect("defer_death"), "Karte verbraucht")
	g.next_night()
	assert_true(g.state.players[1].alive, "Tag 2: noch am Leben")
	g.skip_cards()
	g.next_night()
	assert_false(g.state.players[1].alive, "am übernächsten Tag vollstreckt")
	assert_true(CardHooks.deferred_ids(g.state).is_empty(), "nichts mehr aufgeschoben")
	_check_persistence(g, "wende_05 wolf")


func test_wende_05_village_postpones_a_villager_death_and_counts_as_dead_for_wins() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"wende_05")
	g.play_with()
	g.skip_cards()
	g.lynch(6, 5)
	assert_true(g.state.players[6].alive, "lebt vorerst")
	assert_true(CardHooks.deferred_ids(g.state).has(6), "Tod aufgeschoben")
	var as_dead := g.state.duplicate_state()
	as_dead.players[6].alive = false
	assert_eq(CanonicalJson.stringify(WinRules.evaluate(g.state)), CanonicalJson.stringify(WinRules.evaluate(as_dead)), "Siegprüfung zählt die aufgeschobene Person bereits als tot")
	g.next_night()
	g.skip_cards()
	g.next_night()
	assert_false(g.state.players[6].alive, "vollstreckt")
	_check_persistence(g, "wende_05 dorf")


func test_fluch_05_pauses_protections_for_the_chosen_number_of_days() -> void:
	for faction: Array in [[WOLF_OWNER, 1, 5], [VILLAGE_OWNER, 5, 1]]:
		var g := _game()
		g.arm(int(faction[0]), &"fluch_05")
		g.play_with([1])  # Option 1 = zwei Tage
		var effects := CardEffects.effects(g.state, "protection_pause")
		assert_eq(effects.size(), 1, "Effekt gespeichert")
		assert_eq(int(effects[0]["to"]) - int(effects[0]["from"]), 2, "zwei Tage Dauer")
		assert_true(CardHooks.protections_paused(g.state, int(faction[1])), "Schutz der eigenen Fraktion ruht (Person %d)" % int(faction[1]))
		assert_false(CardHooks.protections_paused(g.state, int(faction[2])), "die andere Fraktion ist nicht betroffen")
		_check_persistence(g, "fluch_05 %d" % int(faction[0]))


func test_fluch_05_lets_personal_shields_rest() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"fluch_05")
	g.play_with([0])
	assert_true(CardHooks.protections_paused(g.state, 5), "Schutzwirkungen der Dorfpersonen ruhen")
	(g.state.cardsys["shields"] as Array).append(5)
	var s := _ability_kill(g, 5)
	assert_false(s.players[5].alive, "der ruhende Schild verhindert den Tod nicht")
	# Nach Ablauf (ein Tag) wirkt der Schild wieder.
	g.next_night()
	g.skip_cards()
	g.next_night()
	assert_false(CardHooks.protections_paused(g.state, 5), "nach einem Tag ist die Pause vorbei")
	var after := _ability_kill(g, 5)
	assert_true(after.players[5].alive, "der Schild wirkt wieder")


func test_fluch_08_wolf_chain_kills_the_wolf_to_the_right_when_an_ability_kills_a_wolf() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"fluch_08")
	g.play_with()
	assert_true(g.has_effect("chain_curse"), "Effekt gespeichert")
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var s := _ability_kill(g, 1)
	assert_false(s.players[1].alive, "der Wolf stirbt durch die Fähigkeit")
	assert_false(s.players[2].alive, "der Wolf rechts von ihm stirbt mit")
	assert_true(s.players[12].alive, "Dorfpersonen sind nicht betroffen")


func test_fluch_08_village_chain_kills_the_villager_to_the_left_after_a_pack_kill() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"fluch_08")
	g.play_with()
	g.next_night(5)
	assert_false(g.state.players[5].alive, "Opfer des Rudels tot")
	assert_false(g.state.players[6].alive, "die Dorfperson links von ihm stirbt mit")
	_check_persistence(g, "fluch_08 dorf")


func test_fluch_12_takes_another_random_member_of_the_faction() -> void:
	var wolf := _game()
	wolf.arm(WOLF_OWNER, &"fluch_12")
	wolf.play_with()
	wolf.skip_cards()
	wolf.lynch(1, 5)
	assert_false(wolf.state.players[1].alive and wolf.state.players[2].alive, "ein weiterer Wolf stirbt mit")
	assert_false(wolf.has_effect("double_leid"), "Effekt verbraucht")
	_check_persistence(wolf, "fluch_12 wolf")
	var village := _game()
	village.arm(VILLAGE_OWNER, &"fluch_12")
	village.play_with()
	village.skip_cards()
	var before := village.dead_ids()
	village.lynch(6, 5)
	var died := village.dead_ids().filter(func(id: int) -> bool: return not before.has(id))
	assert_eq(died.size(), 2, "zwei Dorfpersonen sterben")
	assert_true(died.has(6), "die gelynchte Person ist dabei")
	_check_persistence(village, "fluch_12 dorf")


func test_loki_12_asks_the_game_master_for_a_victim_of_the_other_side() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"loki_12")
	g.play_with()
	assert_true(g.has_effect("cosmic_balance"), "Effekt gespeichert")
	g.skip_cards()
	g.lynch(1, 5)
	assert_true(g.state.pending_prompt != null and g.state.pending_prompt.owner == PendingPrompt.OWNER_CARD, "Aufgabe: Opfer der anderen Seite")
	var prompt := g.state.pending_prompt
	assert_true(prompt.allowed_ids.has(6) and not prompt.allowed_ids.has(2), "nur Dorfpersonen wählbar")
	g.do(Command.answer_stage_targets(prompt.id, "pick", [6]), "Opfer")
	assert_false(g.state.players[6].alive, "Dorfperson stirbt zusätzlich")
	_check_persistence(g, "loki_12")
