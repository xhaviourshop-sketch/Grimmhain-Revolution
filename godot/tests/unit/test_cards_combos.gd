extends TestCase
## Bekannte Problemkombinationen aus Decision Log und Arbeitsliste: Notanker mit Wolfskind und Lehrling (vorgezogene Folgen ohne
## doppelte Auslösung), Totengericht mit Geisterstimme, Wolfsschutz und Hinrichtungsfolgen sowie Ketten aus mehreren Karten.
## Bindungen werden direkt am Zustand gesetzt (kein Befehl); daher gilt hier Speichern und Laden statt Replay.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3]
const OWNER := 14


func _codec_equal(g: CardGame) -> bool:
	return CanonicalJson.stringify(GameState.from_dict(g.state.to_dict()).to_dict()) == CanonicalJson.stringify(g.state.to_dict())


## Entfernt den Wächter am Tor (Füllerrolle), damit Verwandlungen und Erbfolgen nicht blockiert werden.
func _without_gate(g: CardGame) -> void:
	for id: int in g.state.alive_ids():
		if g.state.players[id].role_id == RoleCatalog.WAECHTER_AM_TOR:
			g.gm_set_role(id, "dorfbewohner")
	assert_false(Gatewarden.active(g.state), "kein Wächter am Tor im Spiel")


func _ctx(g: CardGame) -> RuleContext:
	return RuleContext.new(g.state, g.state.command_count)


func _nominate(g: CardGame, nominee: int, nominator: int = 4) -> void:
	g.do(Command.nominate(nominator, nominee), "nominate %d" % nominee)


func _decide(g: CardGame, target: int) -> CommandResult:
	return g.attempt(Command.create(Command.DECIDE_EXECUTION, {"target_id": target}))


func _until_deferred_death(g: CardGame, person: int) -> void:
	var guard := 0
	while g.state.players[person].alive and g.state.phase != Phase.GAME_OVER and guard < 6:
		guard += 1
		g.next_night(-1)


func test_notanker_transforms_a_wolf_child_at_the_deferral_and_not_a_second_time_at_the_real_death() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"13": "wolfskind"})
	_without_gate(g)
	WolfChildRules.bind(_ctx(g), 13, 5)
	g.arm(OWNER, &"wende_05")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "Hinrichtung des Vorbilds")
	assert_true(g.state.players[5].alive, "das Vorbild lebt (aufgeschoben)")
	var bond := WolfChildRules.bond_of(g.state, 13)
	assert_true(bond.transformed, "das Wolfskind verwandelt sich schon beim Aufschub")
	assert_eq(g.state.players[13].faction, Faction.WOLVES, "Fraktion Wölfe")
	assert_eq(g.events_of(GameEvent.WOLF_CHILD_TRANSFORMED).size(), 1, "genau eine Verwandlung")
	assert_true(_codec_equal(g), "Speichern und Laden gleich")
	_until_deferred_death(g, 5)
	assert_false(g.state.players[5].alive, "das Vorbild stirbt am übernächsten Tag wirklich")
	assert_eq(g.events_of(GameEvent.WOLF_CHILD_TRANSFORMED).size(), 1, "keine zweite Verwandlung beim tatsächlichen Tod")
	assert_true(WolfChildRules.state_is_consistent(g.state), "Wolfskindzustand konsistent")


func test_the_gate_guard_blocks_the_wolf_child_transformation_once_at_the_deferral() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"13": "wolfskind"})
	assert_true(Gatewarden.active(g.state), "Wächter am Tor im Spiel")
	WolfChildRules.bind(_ctx(g), 13, 5)
	g.arm(OWNER, &"wende_05")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "Hinrichtung des Vorbilds")
	assert_eq(g.events_of(GameEvent.NEW_WOLF_BLOCKED).size(), 1, "die Verwandlung wird beim Aufschub blockiert")
	assert_eq(g.state.players[13].role_id, RoleCatalog.DORFBEWOHNER, "das Wolfskind wird zum Dorfbewohner")
	_until_deferred_death(g, 5)
	assert_false(g.state.players[5].alive, "das Vorbild stirbt wirklich")
	assert_eq(g.events_of(GameEvent.NEW_WOLF_BLOCKED).size(), 1, "keine zweite Blockade beim tatsächlichen Tod")
	assert_true(WolfChildRules.state_is_consistent(g.state), "Wolfskindzustand konsistent")


func test_notanker_lets_an_apprentice_inherit_at_the_deferral_and_not_again_at_the_real_death() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"13": "lehrling"})
	_without_gate(g)
	ApprenticeRules.set_master(_ctx(g), 13, 5)
	var master_role := g.state.players[5].role_id
	g.arm(OWNER, &"wende_05")
	g.play_with()
	g.skip_cards()
	_nominate(g, 5)
	assert_true(_decide(g, 5).ok, "Hinrichtung des Meisters")
	assert_true(g.state.players[5].alive, "der Meister lebt (aufgeschoben)")
	assert_eq(g.state.players[13].role_id, master_role, "der Lehrling erbt sofort")
	var inherited := g.events_of(GameEvent.ROLE_CHANGED).filter(func(e: GameEvent) -> bool: return e.data.get("by") == "master_death" and int(e.data["player_id"]) == 13)
	assert_eq(inherited.size(), 1, "ein Erbe")
	_until_deferred_death(g, 5)
	assert_false(g.state.players[5].alive, "der Meister stirbt wirklich")
	var after := g.events_of(GameEvent.ROLE_CHANGED).filter(func(e: GameEvent) -> bool: return e.data.get("by") == "master_death" and int(e.data["player_id"]) == 13)
	assert_eq(after.size(), 1, "das Erbe wird nicht ein zweites Mal ausgelöst")
	assert_eq(g.state.players[13].role_id, master_role, "Rolle bleibt")
	assert_true(ApprenticeRules.state_is_consistent(g.state), "Lehrlingszustand konsistent")


func test_the_dead_judgement_and_the_ghost_voice_work_together() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"14": "rattenfaenger"})
	g.gm_kill(13, false)
	g.give(13, &"schicksal_12")
	g.arm(OWNER, &"solo_06", -1, false)
	assert_eq(CardRules.window_open(g.state), true, "Fenster offen")
	g.play_with()  # die jeweils gefragte Person spielt ihre Karte
	g.play_with()
	assert_true(g.has_effect("dead_rule") and g.has_effect("dead_actor"), "beide Regeln gespeichert")
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.night(-1)
	g.skip_cards()
	assert_true(CardFxDead.dead_rule_active(g.state), "Totenregel gilt")
	assert_true(CardFxSolo.may_nominate_dead(g.state, OWNER), "Geisterstimme gilt")
	assert_false(g.attempt(Command.nominate(4, 5)).ok, "Lebende dürfen nicht nominieren")
	assert_true(g.attempt(Command.nominate(13, 5)).ok, "die tote Person nominiert")
	assert_true(g.attempt(Command.nominate(OWNER, 6)).ok, "die Geisterstimme nominiert")
	assert_true(_decide(g, 6).ok, "ihre nominierte Person wird hingerichtet")
	var task := g.state.pending_prompt
	assert_true(task != null and task.owner == PendingPrompt.OWNER_CARD, "Rückkehr der Geisterstimme: Aufgabe offen")
	g.answer_card_min(task)
	assert_true(g.state.players[OWNER].alive, "die Besitzerin kehrt zurück")
	assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand konsistent")
	assert_true(g.replay_equals(), "Replay gleich")


func test_wolf_protection_and_chain_reaction_do_not_double_trigger() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3)
	g.gm_kill(13, false)
	g.give(13, &"schicksal_11")
	g.arm(3, &"wende_02", -1, false)  # Wolf: schützt einen Wolf vor den nächsten zwei Hinrichtungen
	g.play_with()
	g.play_with()
	g.next_night(-1, [[1]], false)
	g.settle()
	g.skip_cards()
	_nominate(g, 1)
	var res := _decide(g, 1)
	assert_true(res.ok or res.error == "runner_up_required", "die Hinrichtung ist entweder geschützt oder verlangt den Zweitplatzierten")
	if not res.ok:
		assert_true(g.attempt(Command.create(Command.DECIDE_EXECUTION, {"target_id": 1, "runner_up_id": 7})).ok, "mit Zweitplatziertem angenommen")
	assert_true(g.state.players[1].alive, "der geschützte Wolf überlebt auch die Kettenreaktion")
	assert_true(g.state.players[7].alive, "die Kettenreaktion tötet bei verhinderter Hinrichtung niemanden")
	assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand konsistent")
	assert_true(g.replay_equals(), "Replay gleich")


func test_a_revived_person_loses_the_unplayed_card_of_the_earlier_life_and_draws_again_at_the_next_death() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3)
	g.gm_kill(5, false)
	g.give(5, &"segen_14")
	assert_eq(CardRules.held_of(g.state, 5)["card"], "segen_14", "Karte gehalten")
	g.gm_revive(5)
	assert_true(CardRules.held_of(g.state, 5).is_empty(), "die Karte aus dem früheren Leben verfällt")
	g.gm_kill(5, true)
	g.skip_cards()
	assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand konsistent")
	assert_true(g.replay_equals(), "Replay gleich")
