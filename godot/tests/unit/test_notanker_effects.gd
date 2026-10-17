extends TestCase
## Notanker (wende_05, Entscheidung Markus 17.10.2026): Der aufgeschobene Tod löst bei der Vollstreckung die vollen Todesfolgen aus
## (Jäger schießt, Liebespartner stirbt mit, Totenreichkarte). Wolfskind-Verwandlung und Lehrling-Erbe geschahen schon beim Aufschub
## (test_cards_combos). Die Bindung wird direkt am Zustand gesetzt (kein Befehl), daher Speichern und Laden statt Replay.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3]
const OWNER := 14
const HUNTER := 13
const LOVER := 6


func test_executed_deferred_death_triggers_full_effects() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {str(HUNTER): "sensentraeger", "12": "loki"})
	g.state.loki_pairs.append({"loki_id": 12, "a": LOVER, "b": HUNTER, "kind": "love", "ended": false})
	g.arm(OWNER, &"wende_05")
	g.play_with()
	g.skip_cards()
	g.do(Command.nominate(4, HUNTER), "nominate")
	assert_true(g.attempt(Command.create(Command.DECIDE_EXECUTION, {"target_id": HUNTER})).ok, "Hinrichtung")
	assert_true(g.state.players[HUNTER].alive, "aufgeschoben: lebt noch")
	assert_true(g.state.reactions.is_empty(), "beim Aufschub noch kein Schuss")
	var guard := 0
	while g.state.players[HUNTER].alive and g.state.phase != Phase.GAME_OVER and guard < 6:
		guard += 1
		g.next_night(-1)
	assert_false(g.state.players[HUNTER].alive, "Tod am übernächsten Tag vollstreckt")
	assert_false(g.state.players[LOVER].alive, "Liebespartner stirbt mit")
	assert_eq(g.state.reactions.map(func(r: Reaction) -> int: return r.owner_id), [HUNTER], "der Sensenträger darf schießen")
	assert_true(CardHooks.deferred_ids(g.state).is_empty(), "kein aufgeschobener Tod mehr offen")
	assert_true(GameState.from_dict(g.state.to_dict()) != null, "Stand ladbar")
