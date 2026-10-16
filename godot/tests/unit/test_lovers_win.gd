extends TestCase
## Nachtlauf Regeln: Bleibt ein gemischtes Liebespaar (Wolf und Dorfperson) als Letzte übrig, gewinnt die Partei "Liebende"
## statt der Wölfe nach Parität.


const ROLES := ["werwolf", "dorfbewohner", "loki", "detektiv", "amalia", "nachtwaechter"]


func _state_with_pair(roles: Array, alive_ids: Array, kind: String = "love") -> GameState:
	var r := RulesEngine.apply(GameState.new(), Fixtures.start_roles(roles))
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return null
	var s: GameState = r.state
	s.loki_pairs.append({"loki_id": 3, "a": 1, "b": 2, "kind": kind, "ended": false})
	for id: int in s.players.keys():
		if alive_ids.has(id):
			continue
		var k := KillEvent.new()
		k.target_id = id
		k.cause = KillEvent.CAUSE_NIGHT_KILL
		k.source_kind = KillEvent.SOURCE_PACK
		k.phase = Phase.NIGHT
		k.phase_number = 1
		k.order_index = s.next_death_order
		s.next_death_order += 1
		s.players[id].alive = false
		s.players[id].death = k
	return s


func _reasons(roles: Array, alive_ids: Array, kind: String = "love") -> Array:
	var s := _state_with_pair(roles, alive_ids, kind)
	if s == null:
		return []
	return WinRules.evaluate(s).map(func(r: Dictionary) -> String: return "%s:%s" % [r["kind"], r["reason_key"]])


func test_mixed_pair_as_last_two_wins_instead_of_the_wolves() -> void:
	var s := _state_with_pair(ROLES, [1, 2])
	if s == null:
		return
	assert_eq(_reasons(ROLES, [1, 2]), ["lovers:lovers_last_two"], "nur der Liebendensieg")
	s.win_check_pending = true
	WinRules.finalize_if_ready(RuleContext.new(s, s.command_count))
	var c: WinCandidate = s.open_candidates()[0]
	assert_eq(c.beneficiary_ids, [1, 2] as Array[int], "beide Liebenden sind begünstigt")
	assert_true(GameState.from_dict(s.to_dict()) != null, "Zustand mit dem Kandidaten ist ladbar")
	var confirmed := RulesEngine.apply(s, Command.confirm_win(c.id))
	assert_true(confirmed.ok, "Bestätigung (%s)" % confirmed.error)
	assert_eq(WinRules.winner_ids(confirmed.state, confirmed.state.winner()), [1, 2] as Array[int], "beide gewinnen")


func test_other_constellations_keep_the_faction_rules() -> void:
	assert_eq(_reasons(ROLES, [1, 2], "rival"), ["wolves:wolf_parity"], "Rivalen sind keine Liebenden")
	assert_eq(_reasons(ROLES, [1, 2, 4]), [], "drei Lebende: noch kein Sieg")
	assert_eq(_reasons(["dorfbewohner", "amalia", "loki", "detektiv", "nachtwaechter", "werwolf"], [1, 2]), ["village:no_wolves_alive"], "zwei Dörfler: Dorfsieg")
	assert_eq(_reasons(["werwolf", "werwolf", "loki", "detektiv", "amalia", "nachtwaechter"], [1, 2]), ["wolves:wolf_parity"], "zwei Wölfe: Wolfssieg")
