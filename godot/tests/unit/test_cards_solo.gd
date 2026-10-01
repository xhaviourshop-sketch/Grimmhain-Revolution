extends TestCase
## Kartenfamilie Solo (solo_01 bis solo_14): die Besitzerin ist eine tote Einzelsiegperson (Rattenfänger). Je Karte die echte Wirkung,
## die Folgen bei Hinrichtung und Tod, stille Mitsieger und der Fortgang nach Aufgaben der Spielleitung.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3, 4]
const OWNER := 14
const CAST := {"14": "rattenfaenger"}


func _game(seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value, CAST)


func _armed(card: StringName, seed_value: int = 3) -> CardGame:
	var g := _game(seed_value)
	g.arm(OWNER, card)
	return g


func _persist(g: CardGame, label: String) -> void:
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)


func _decide(g: CardGame, target: int, extra: Dictionary = {}) -> CommandResult:
	var payload := {"target_id": target}
	payload.merge(extra)
	return g.attempt(Command.create(Command.DECIDE_EXECUTION, payload))


func _nominate(g: CardGame, nominee: int, nominator: int = 4) -> void:
	g.do(Command.nominate(nominator, nominee), "nominate %d" % nominee)


func _candidate(kind: StringName) -> WinCandidate:
	var c := WinCandidate.new()
	c.kind = kind
	return c


func _cowinner_ids(g: CardGame, kind: StringName) -> Array:
	return CardFxSolo.cowinners(g.state, _candidate(kind)).map(func(d: Dictionary) -> int: return int(d["person_id"]))


func test_solo_01_projection_returns_the_owner_with_the_role_of_the_executed_person() -> void:
	var g := _armed(&"solo_01")
	var role := g.state.players[5].role_id
	g.play_with([5])
	assert_true(g.has_effect("projection"), "Zettel gespeichert")
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "Hinrichtung")
	assert_true(g.state.players[OWNER].alive, "die Kartenspielerin kehrt zurück")
	assert_eq(g.state.players[OWNER].role_id, role, "mit der Rolle der Hingerichteten")
	assert_false(g.has_effect("projection"), "Zettel verbraucht")
	_persist(g, "solo_01")


func test_solo_01_is_consumed_by_any_other_execution() -> void:
	var g := _armed(&"solo_01")
	g.play_with([5])
	g.skip_cards()
	_nominate(g, 6)
	assert_true(_decide(g, 6).ok, "andere Hinrichtung")
	assert_false(g.state.players[OWNER].alive, "keine Rückkehr")
	assert_false(g.has_effect("projection"), "Zettel verbraucht")


func test_solo_02_prophecy_makes_the_owner_a_silent_cowinner_of_the_predicted_team() -> void:
	var g := _armed(&"solo_02")
	g.play_with([1])  # Option 1 = Wölfe
	assert_true(g.has_effect("prophecy"), "Tipp gespeichert")
	assert_true(_cowinner_ids(g, Faction.WOLVES).has(OWNER), "Wölfe gewinnen: Mitsiegerin")
	assert_false(_cowinner_ids(g, Faction.VILLAGE).has(OWNER), "Dorf gewinnt: keine Mitsiegerin")
	_persist(g, "solo_02")


func test_solo_03_and_solo_12_announce_three_extra_votes_publicly() -> void:
	for card: StringName in [&"solo_03", &"solo_12"]:
		var g := _armed(card)
		g.play_with([5])
		var announced := g.events_of(GameEvent.CARD_ANNOUNCED)
		assert_eq(announced.size(), 1, "%s: öffentliche Ansage" % card)
		assert_eq(int(announced[0].data["values"]["extra_votes"]), 3, "%s: plus drei Stimmen" % card)
		assert_eq(int(announced[0].data["values"]["person_id"]), 5, "%s: gegen die gewählte Person" % card)
		_persist(g, String(card))


func test_solo_04_apocalyptic_exit_kills_the_partner_when_one_of_the_pair_dies() -> void:
	var g := _armed(&"solo_04")
	g.play_with([[5, 6]])
	assert_true(g.has_effect("death_bond"), "Band gespeichert")
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "Hinrichtung")
	assert_false(g.state.players[5].alive, "erste Person tot")
	assert_false(g.state.players[6].alive, "die verbundene Person stirbt nach")
	assert_eq(String(g.state.players[6].death.cause), String(KillEvent.CAUSE_CARD_CHAIN), "Ursache: Kettentod")
	assert_false(g.has_effect("death_bond"), "Band verbraucht")
	_persist(g, "solo_04")


func test_solo_05_legacy_lets_the_heir_inherit_the_ability_and_the_owner_wins_with_the_heir() -> void:
	var g := _armed(&"solo_05")
	g.play_with([8])
	assert_true(g.has_effect("legacy"), "Erbe gespeichert")
	var granted := (g.state.cardsys["abilities"] as Array).filter(func(a: Dictionary) -> bool: return int(a["player_id"]) == 8)
	assert_eq(granted.size(), 1, "dauerhafte zusätzliche Fähigkeit")
	assert_eq(int(granted[0]["night"]), CardFxSolo.PERM, "dauerhaft")
	assert_true(_cowinner_ids(g, Faction.VILLAGE).has(OWNER), "der Erbe gehört zu den Siegern: Mitsiegerin")
	assert_false(_cowinner_ids(g, Faction.WOLVES).has(OWNER), "die Wölfe gewinnen: der Erbe nicht dabei")
	_persist(g, "solo_05")


func test_solo_06_ghost_voice_lets_the_owner_nominate_and_return_when_her_nominee_is_executed() -> void:
	var g := _armed(&"solo_06")
	g.play_with()
	assert_true(CardFxSolo.may_nominate_dead(g.state, OWNER) or g.has_effect("dead_actor"), "Geisterstimme gespeichert")
	g.skip_cards()
	assert_true(CardFxSolo.may_nominate_dead(g.state, OWNER), "die tote Besitzerin darf nominieren")
	assert_false(CardFxSolo.may_nominate_dead(g.state, 13), "andere Tote nicht")
	_nominate(g, 5, OWNER)
	assert_true(_decide(g, 5).ok, "ihre nominierte Person wird hingerichtet")
	var task := g.state.pending_prompt
	assert_true(task != null and task.owner == PendingPrompt.OWNER_CARD and task.stage == &"option", "Aufgabe: neue Einzelsiegrolle")
	g.do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": task.id, "stage": "option", "option": 0}), "Rolle")
	assert_true(g.state.players[OWNER].alive, "die Kartenspielerin kehrt zurück")
	assert_false(g.has_effect("dead_actor"), "Effekt verbraucht")
	_persist(g, "solo_06")


func test_solo_07_martyrdom_stops_the_pack_for_the_village_and_the_execution_for_the_wolves() -> void:
	var village := _armed(&"solo_07")
	village.play_with([0])
	village.skip_cards()
	village.end_day()
	village.skip_cards()
	village.do(Command.start_night(), "StartNight")
	assert_true(village.state.pending_prompt == null or village.state.pending_prompt.owner != PendingPrompt.OWNER_PACK, "kein Rudelangriff")
	var wolves := _armed(&"solo_07")
	wolves.play_with([1])
	wolves.skip_cards()
	_nominate(wolves, 5)
	var rejected := _decide(wolves, 5)
	assert_false(rejected.ok, "die nächste Hinrichtung entfällt")
	assert_eq(String(rejected.error), "execution_cancelled_by_card", "Grund: Karte")
	_persist(wolves, "solo_07")


func test_solo_08_silent_witness_makes_the_owner_cowinner_when_the_chosen_person_wins() -> void:
	var g := _armed(&"solo_08")
	g.play_with([1])
	assert_true(_cowinner_ids(g, Faction.WOLVES).has(OWNER), "der gewählte Wolf gewinnt: Mitsiegerin")
	assert_false(_cowinner_ids(g, Faction.VILLAGE).has(OWNER), "das Dorf gewinnt: nicht")
	_persist(g, "solo_08")


func test_solo_09_chaos_spirit_rolls_the_number_of_executions_of_the_day() -> void:
	var g := _armed(&"solo_09")
	g.play_with()
	var effects := CardEffects.effects(g.state, "multi_lynch")
	assert_eq(effects.size(), 1, "Würfelergebnis gespeichert")
	var n := int(effects[0]["data"]["n"])
	assert_true(n >= 1 and n <= 6, "Würfelwert 1 bis 6")
	g.skip_cards()
	_nominate(g, 5)
	_nominate(g, 6, 7)
	assert_true(_decide(g, 5).ok, "erste Hinrichtung")
	if n >= 2:
		assert_eq(g.state.day_step, Phase.DAY_NOMINATION, "der Tag bleibt für weitere Hinrichtungen offen")
	else:
		assert_eq(g.state.day_step, Phase.DAY_EXECUTION_DECIDED, "eine Hinrichtung genügt")
	_persist(g, "solo_09")


func test_solo_10_lonely_inheritance_notes_the_first_death_after_playing() -> void:
	var g := _armed(&"solo_10")
	g.play_with([[1], [6]])
	g.state.win_check_pending = false
	assert_true(g.has_effect("legacy_notes"), "Zettel gespeichert")
	g.skip_cards()
	_nominate(g, 6)
	assert_true(_decide(g, 6).ok, "Hinrichtung")
	var note: Dictionary = CardEffects.effects(g.state, "legacy_notes")[0]
	assert_eq(int(note["data"]["first_dead_id"]), 6, "erste Tote nach dem Spielen")
	assert_true(g.events_of(GameEvent.CARD_EFFECT_NOTE).any(func(e: GameEvent) -> bool: return e.data.get("card_id") == "solo_10" and bool(e.data.get("matches", false))), "Vermutung stimmte")
	assert_true(_cowinner_ids(g, Faction.WOLVES).has(OWNER), "Sieger und erste Tote stimmen: posthume Mitsiegerin")
	assert_false(_cowinner_ids(g, Faction.VILLAGE).has(OWNER), "anderer Sieger: nicht")
	_persist(g, "solo_10")


func test_solo_11_judge_from_the_beyond_executes_a_further_nominee_when_the_village_agrees() -> void:
	var g := _armed(&"solo_11")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "erste Hinrichtung")
	var task := g.state.pending_prompt
	assert_true(task != null and task.owner == PendingPrompt.OWNER_CARD and task.stage == &"pick", "Aufgabe: weitere Nominierung")
	g.do(Command.answer_stage_targets(task.id, "pick", [7]), "weitere Person")
	g.do(Command.answer_choice(g.state.pending_prompt.id, "ask", true), "Dorf stimmt zu")
	assert_false(g.state.players[7].alive, "zusätzlich hingerichtet")
	_persist(g, "solo_11")


func test_solo_11_judge_does_nothing_when_the_village_disagrees() -> void:
	var g := _armed(&"solo_11")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "erste Hinrichtung")
	var task := g.state.pending_prompt
	g.do(Command.answer_stage_targets(task.id, "pick", [7]), "weitere Person")
	g.do(Command.answer_choice(g.state.pending_prompt.id, "ask", false), "Dorf lehnt ab")
	assert_true(g.state.players[7].alive, "niemand zusätzlich hingerichtet")


func test_solo_12_family_bond_wins_when_the_chosen_person_is_among_the_last_two() -> void:
	var g := _armed(&"solo_12")
	g.play_with([5])
	assert_false(CardFxSolo.family_bond_wins(g.state, 5), "noch viele Lebende")
	var late := g.state.duplicate_state()
	for id: int in late.alive_ids():
		if id != 5 and id != 6:
			late.players[id].alive = false
	assert_true(CardFxSolo.family_bond_wins(late, 5), "unter den letzten zwei: Kandidat")
	assert_false(CardFxSolo.family_bond_wins(late, 6), "nur die gewählte Person zählt")
	assert_true(g.state.win_check_pending or g.state.winner_id == -1, "Siegprüfung angestoßen")
	_persist(g, "solo_12")


func test_solo_13_the_realm_of_the_dead_rules_for_two_days() -> void:
	var g := _armed(&"solo_13")
	g.play_with()
	var effects := CardEffects.effects(g.state, "dead_rule")
	assert_eq(effects.size(), 1, "Regel gespeichert")
	assert_eq(int(effects[0]["data"]["to_day"]) - int(effects[0]["data"]["from_day"]), 1, "zwei Tage")
	_persist(g, "solo_13")


func test_solo_14_betrayal_or_fraternization_kills_a_neighbour_only_when_the_other_agrees() -> void:
	for agrees: bool in [true, false]:
		var g := _armed(&"solo_14")
		g.do(Command.card_act(OWNER, "play"), "play")
		var p := g.state.pending_prompt
		assert_true(p.allowed_ids.size() >= 1 and p.allowed_ids.size() <= 2, "nur lebende Nachbarn")
		var accused: int = p.allowed_ids[0]
		g.do(Command.answer_stage_targets(p.id, "pick", [accused]), "beschuldigt")
		g.do(Command.answer_choice(g.state.pending_prompt.id, "ask", agrees), "Zustimmung")
		assert_eq(g.state.players[accused].alive, not agrees, "stirbt nur bei Zustimmung (%s)" % agrees)
		assert_eq(g.events_of(GameEvent.CARD_ANNOUNCED).size(), 1, "öffentliche Ansage")
		_persist(g, "solo_14 %s" % agrees)
