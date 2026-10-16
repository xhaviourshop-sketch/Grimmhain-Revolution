extends TestCase
## Nachtlauf Regeln: Ist ein Feuerteufel selbst die begünstigte Person eines Einzelsiegs (Totenreichkarte Familienbande), darf er nicht
## zusätzlich als Mitsieger im Kandidaten stehen; sonst lässt sich der Spielstand nicht mehr laden.


func _state_with_devil_as_family_bond_winner() -> GameState:
	var cmd := Fixtures.start_roles(["werwolf", "dorfbewohner", "feuerteufel", "amalia", "detektiv", "nachtwaechter"])
	cmd.payload["death_cards"] = true
	var r := RulesEngine.apply(GameState.new(), cmd)
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return null
	var s: GameState = r.state
	for dead_id: int in [1, 2, 4, 5, 6]:
		var k := KillEvent.new()
		k.target_id = dead_id
		k.cause = KillEvent.CAUSE_NIGHT_KILL
		k.source_kind = KillEvent.SOURCE_PACK
		k.phase = Phase.NIGHT
		k.phase_number = 1
		k.order_index = s.next_death_order
		s.next_death_order += 1
		s.players[dead_id].alive = false
		s.players[dead_id].death = k
	var sys: Dictionary = s.cardsys
	(sys["effects"] as Array).append({"id": int(sys["next_effect"]), "card": "solo_12", "variant": "solo", "owner": 2, "kind": "family_bond", "from": 0,
		"to": 1099511627776, "data": {"extra_votes": 3, "person_id": 3}})
	sys["next_effect"] = int(sys["next_effect"]) + 1
	return s


func test_the_devil_is_no_cowinner_of_his_own_win() -> void:
	var s := _state_with_devil_as_family_bond_winner()
	if s == null:
		return
	for result: Dictionary in WinRules.evaluate(s):
		var overlap: Array = (result["beneficiary_ids"] as Array).filter(func(id: int) -> bool: return (result.get("co_winner_ids", []) as Array).has(id))
		assert_eq(overlap, [], "%s: niemand ist zugleich begünstigt und Mitsieger" % result["reason_key"])
	s.win_check_pending = true
	WinRules.finalize_if_ready(RuleContext.new(s, s.command_count))
	assert_false(s.open_candidates().is_empty(), "Kandidaten erkannt")
	assert_true(GameState.from_dict(s.to_dict()) != null, "Zustand mit den Kandidaten ist ladbar")
