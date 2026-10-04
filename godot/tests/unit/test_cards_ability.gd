extends TestCase
## Kartenfamilie Fähigkeiten sperren, wiederholen, verleihen (segen_06/12/14, fluch_01, wende_01/08/10/11, schicksal_07/10, loki_07/08):
## je Karte und Variante die echte Wirkung auf den Nachtplan, die Anzeige des Orakels und die Einsätze. Zustände, die nur durch
## Rollenspiel entstehen (verbrauchte Einsätze, Schilde), werden im Test gezielt gesetzt und über das Laden geprüft.

const COUNT := 12
const WOLVES: Array[int] = [1, 2, 3]
const WOLF_OWNER := 3
const VILLAGE_OWNER := 12


func _game(specials: Dictionary = {}, seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value, specials)


func _night_plan_after_play(g: CardGame) -> Array[StringName]:
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	return g.state.night_plan


func _check_reload(g: CardGame, label: String) -> void:
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)


func test_segen_06_wolf_shows_the_oracle_a_random_village_role_for_the_next_wolf() -> void:
	var g := _game({"6": "das-orakel"})
	g.arm(WOLF_OWNER, &"segen_06")
	g.play_with()
	assert_true(g.has_effect("oracle_cloak"), "Effekt gespeichert")
	_night_plan_after_play(g)
	var guard := 0
	var seen := false
	while guard < 20 and g.state.phase == Phase.NIGHT and not seen:
		guard += 1
		var p := g.state.pending_prompt
		if p == null:
			g.do(Command.begin_step(RulesEngine.next_step_id(g.state)), "begin")
		elif p.owner == PendingPrompt.OWNER_ORACLE and p.stage == &"target":
			g.do(Command.answer_stage_targets(p.id, "target", [1]), "Orakel prüft den Wolf")
			var shown := g.state.pending_prompt
			assert_eq(shown.stage, &"shown", "Anzeige")
			assert_ne(String(shown.partial["shown_role"]), String(g.state.players[1].role_id), "nicht die wahre Rolle des Wolfs")
			assert_true(CardCatalog.owner_variant(Player.new()) != &"" and RoleCatalog.faction_of(StringName(shown.partial["shown_role"])) == Faction.VILLAGE, "eine Dorfrolle")
			assert_eq(String(shown.partial["override_reason"]), "card", "Grund: Karte")
			seen = true
		elif p.owner == PendingPrompt.OWNER_PACK:
			g.do(Command.skip_step(p.step_id, "Test: ruhige Nacht"), "Rudel")
		else:
			g.answer_default(p)
	assert_true(seen, "Orakel hat geprüft")
	assert_false(g.has_effect("oracle_cloak"), "Effekt verbraucht")
	_check_reload(g, "segen_06 wolf")


func test_segen_06_village_blinds_the_pack_so_a_random_person_dies() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"segen_06")
	g.play_with()
	assert_true(g.has_effect("pack_blind"), "Effekt gespeichert")
	g.next_night(5)
	var notes := g.events_of(GameEvent.CARD_EFFECT_NOTE).filter(func(e: GameEvent) -> bool: return e.data.has("blind_victim_id"))
	assert_eq(notes.size(), 1, "das Rudel traf eine zufällige Wahl")
	var victim := int(notes[0].data["blind_victim_id"])
	assert_true(g.state.players.has(victim) and victim != VILLAGE_OWNER, "zufälliges lebendes Opfer")
	var attacked := g.events.filter(func(e: GameEvent) -> bool: return (e.type == GameEvent.KILL_PREVENTED or e.type == GameEvent.SEAT_DIED) and int(e.data.get("target_id", e.data.get("player_id", -1))) == victim)
	assert_false(attacked.is_empty(), "das Rudel griff genau diese Person an (gestorben oder durch eine Schutzrolle verhindert)")
	_check_reload(g, "segen_06 dorf")


func test_segen_12_gives_the_last_dead_roles_ability_for_the_next_night() -> void:
	var wolf := _game({"3": "giftwolf"})
	wolf.arm(WOLF_OWNER, &"segen_12")
	wolf.play_with([[7]])
	assert_eq((wolf.state.cardsys["abilities"] as Array).size(), 1, "zusätzliche Fähigkeit gespeichert")
	var plan := _night_plan_after_play(wolf)
	assert_true(plan.has(&"giftwolf:7"), "Schritt für die gewählte Person mit der Fähigkeit des toten Wolfs")
	_check_reload(wolf, "segen_12 wolf")
	var village := _game({"12": "schutzengel"})
	village.arm(VILLAGE_OWNER, &"segen_12")
	village.play_with([[6]])
	var village_plan := _night_plan_after_play(village)
	assert_true(village_plan.has(&"schutzengel:6"), "Dorf: Schritt mit der Fähigkeit des toten Dorfmitglieds")


func test_segen_14_shows_the_game_then_grants_a_repeat_or_double_use() -> void:
	var g := _game({"6": "schutzengel"})
	g.arm(VILLAGE_OWNER, &"segen_14")
	g.do(Command.card_act(VILLAGE_OWNER, "play"), "play")
	var p := g.state.pending_prompt
	assert_eq(p.stage, &"confirm", "Einsicht ins Spiel zuerst")
	g.do(Command.answer_choice(p.id, "confirm", true), "gesehen")
	assert_true(g.state.pending_prompt.stage == &"pick", "dann die Personenwahl")
	g.answer_card(g.state.pending_prompt, [6] if g.state.pending_prompt.allowed_ids.has(6) else null)
	assert_eq(g.state.pending_prompt.stage, &"option", "dann wiederholt oder zweimal")
	g.answer_card(g.state.pending_prompt, 1)
	assert_true(g.state.apples.has(6), "zusätzlicher Einsatz (Apfel) für die Nacht vorgemerkt")
	_check_reload(g, "segen_14")


func test_fluch_01_makes_a_random_member_lose_the_night_ability() -> void:
	var g := _game({"6": "schutzengel"})
	g.arm(VILLAGE_OWNER, &"fluch_01")
	g.play_with()
	var effects := CardEffects.effects(g.state, "lose_ability")
	assert_eq(effects.size(), 1, "Effekt gespeichert")
	assert_eq(int(effects[0]["data"]["person_id"]), 6, "die einzige Person mit Nachtschritt")
	_night_plan_after_play(g)
	g.night_rest()
	var dropped := g.events_of(GameEvent.STEP_DROPPED).filter(func(e: GameEvent) -> bool: return String(e.data["reason"]) == "card_blocked")
	assert_eq(dropped.size(), 1, "der Schritt entfällt durch die Karte")
	_check_reload(g, "fluch_01")


func test_wende_01_and_wende_08_grant_an_extra_use_to_the_chosen_person() -> void:
	for card: StringName in [&"wende_01", &"wende_08"]:
		var g := _game({"6": "schutzengel"})
		g.arm(VILLAGE_OWNER, card)
		g.play_with([6])
		assert_true(g.state.apples.has(6), "%s: weiterer Einsatz vorgemerkt" % card)
		_check_reload(g, String(card))


func test_wende_10_deactivates_the_chosen_ability_for_one_night() -> void:
	var wolf := _game({"6": "schutzengel"})
	wolf.arm(WOLF_OWNER, &"wende_10")
	wolf.play_with([6])
	assert_true(wolf.has_effect("lose_ability"), "Schutzfähigkeit gesperrt")
	_night_plan_after_play(wolf)
	wolf.night_rest()
	assert_eq(wolf.events_of(GameEvent.STEP_DROPPED).filter(func(e: GameEvent) -> bool: return String(e.data["reason"]) == "card_blocked").size(), 1, "Schutzengel-Schritt entfällt")
	var village := _game({"2": "giftwolf"})
	village.arm(VILLAGE_OWNER, &"wende_10")
	village.play_with([2])
	_night_plan_after_play(village)
	village.night_rest()
	assert_eq(village.events_of(GameEvent.STEP_DROPPED).filter(func(e: GameEvent) -> bool: return String(e.data["reason"]) == "card_blocked").size(), 1, "Wolfsfähigkeit entfällt")


func test_schicksal_07_blocks_the_first_ability_of_the_leading_team() -> void:
	var g := _game({"6": "schutzengel", "7": "doktor"})
	g.arm(VILLAGE_OWNER, &"schicksal_07")
	g.play_with([0])  # Dorf liegt vorne
	assert_true(g.has_effect("block_first"), "Effekt gespeichert")
	_night_plan_after_play(g)
	g.night_rest()
	var dropped := g.events_of(GameEvent.STEP_DROPPED).filter(func(e: GameEvent) -> bool: return String(e.data["reason"]) == "card_blocked")
	assert_eq(dropped.size(), 1, "genau die erste Fähigkeit des Dorfes entfällt")
	assert_true(String(dropped[0].data["step_id"]).contains("schutzengel"), "der Schutzengel kommt zuerst")
	_check_reload(g, "schicksal_07")


func test_schicksal_10_restores_one_spent_use_of_a_living_member() -> void:
	var g := _game({"6": "waldhexe"})
	g.state.players[6].ability_uses["waldhexe:heal"] = 1
	g.arm(VILLAGE_OWNER, &"schicksal_10")
	g.play_with()
	assert_false(g.state.players[6].ability_uses.has("waldhexe:heal"), "der verbrauchte Einsatz ist zurück")
	# Der Einsatz wurde im Test direkt gesetzt (kein Befehl), daher gilt hier nur Speichern und Laden des Zustands, kein Replay.
	assert_eq(CanonicalJson.stringify(GameState.from_dict(g.state.to_dict()).to_dict()), CanonicalJson.stringify(g.state.to_dict()), "Zustand speicherbar")


func test_loki_07_clears_all_protections_and_returns_all_uses() -> void:
	var g := _game({"6": "waldhexe"})
	# Verbrauchter Heiltrank per Korrektur (ein Befehl): Mit Rudelopfer fragt die Waldhexe sonst im Replay erneut nach dem Heiltrank.
	g.do(Command.gm_correction({"kind": "set_witch_potion", "witch_id": 6, "potion": "heal", "available": false, "reason": "Test", "confirmed": true}), "Heiltrank verbraucht")
	g.arm(VILLAGE_OWNER, &"loki_07")
	(g.state.cardsys["shields"] as Array).append(5)
	g.play_with()
	assert_true((g.state.cardsys["shields"] as Array).is_empty(), "Schilde aufgehoben")
	assert_true(g.state.players[6].ability_uses.is_empty(), "Einsätze zurück")
	assert_true(g.reload_equals(), "Laden gleich")


func test_loki_08_names_a_proxy_who_uses_the_owners_ability() -> void:
	var g := _game({"12": "schutzengel"})
	g.arm(VILLAGE_OWNER, &"loki_08")
	g.play_with([[6]])
	var plan := _night_plan_after_play(g)
	assert_true(plan.has(&"schutzengel:6"), "Stellvertretung führt die Fähigkeit aus")
	_check_reload(g, "loki_08")


func test_wende_11_wolf_gives_a_wolf_kings_lykaons_transformation() -> void:
	var g := _game()
	g.arm(WOLF_OWNER, &"wende_11")
	g.play_with([2])
	var plan := _night_plan_after_play(g)
	assert_true(plan.has(&"koenig-lykaon:2"), "Lykaon-Schritt für den gewählten Wolf")
	_check_reload(g, "wende_11 wolf")
