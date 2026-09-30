extends TestCase
## Rollenanzeige (Spezifikation vertical-slice-flow.md §2, AS-A04): `ConfirmRoleShown(person)` speichert, dass eine
## Person ihre Rolle gesehen hat. Der Fortschritt ist Teil des Spielstands (`roles_shown`: Person → Rolle zum Zeitpunkt
## der Bestätigung), damit Neustart, Rückgängig und Replay ihn gleich behandeln. Reine Darstellung: keine Spielressource,
## kein Zufall, keine Pflicht vor `StartNight`.

const W := "werwolf"
const D := "dorfbewohner"


func _state(roles: Array = [D, W, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state


func test_confirm_records_person_and_role() -> void:
	var s := _state()
	assert_eq(s.roles_shown.size(), 0, "zu Beginn niemand bestätigt")
	var r := apply_ok(s, Command.confirm_role_shown(2), "Bestätigung Person 2")
	assert_eq(r.state.roles_shown, {2: &"werwolf"}, "Person und Rolle gespeichert")
	assert_eq(r.events.size(), 1, "genau ein Ereignis")
	assert_eq(String(r.events[0].type), "RoleShownConfirmed", "Ereignisart")
	assert_eq(String(r.events[0].visibility), "gm", "nur Spielleiter")
	assert_eq(s.roles_shown.size(), 0, "Ausgangszustand unverändert")


func test_invalid_person_is_rejected_without_change() -> void:
	var s := _state()
	var before := CanonicalJson.stringify(s.to_dict())
	for bad: Variant in [99, 0, -1, "2", null, 1.5]:
		var r := RulesEngine.apply(s, Command.create(Command.CONFIRM_ROLE_SHOWN, {"person_id": bad}))
		assert_false(r.ok, "ungültige Person %s abgelehnt" % str(bad))
		assert_eq(String(r.error), "unknown_player", "Fehlergrund für %s" % str(bad))
		assert_eq(r.events.size(), 0, "keine Ereignisse")
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "Zustand unverändert")
	assert_false(RulesEngine.apply(s, Command.create(Command.CONFIRM_ROLE_SHOWN, {})).ok, "fehlende Person abgelehnt")


func test_double_confirmation_is_rejected() -> void:
	var s := apply_ok(_state(), Command.confirm_role_shown(3), "erste Bestätigung").state
	var before := CanonicalJson.stringify(s.to_dict())
	var again := RulesEngine.apply(s, Command.confirm_role_shown(3))
	assert_false(again.ok, "zweite Bestätigung derselben Rolle abgelehnt")
	assert_eq(String(again.error), "role_already_confirmed", "Fehlergrund")
	assert_eq(again.events.size(), 0, "keine Ereignisse")
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "Zustand unverändert")


func test_role_change_makes_confirmation_stale_and_allows_new_one() -> void:
	var s := _state()
	s = apply_ok(s, Command.confirm_role_shown(1), "Bestätigung Dorfbewohner").state
	assert_false(RoleShownRules.pending_ids(s).has(1), "Person 1 gilt als bestätigt")
	s = apply_ok(s, CorrectionFixtures.gm("set_role", {"target_id": 1, "role_id": "seelentauscher"}), "Rollenwechsel per Korrektur").state
	assert_true(RoleShownRules.pending_ids(s).has(1), "nach dem Rollenwechsel wieder unbestätigt")
	var r := apply_ok(s, Command.confirm_role_shown(1), "erneute Bestätigung der neuen Rolle")
	assert_eq(r.state.roles_shown[1], &"seelentauscher", "neue Rolle gespeichert")
	assert_false(RoleShownRules.pending_ids(r.state).has(1), "wieder bestätigt")


func test_resume_continues_with_first_unconfirmed_person_in_seat_order() -> void:
	# AS-A04: 3 von 6 Personen bestätigt, Neustart, Fortsetzung bei der vierten (Sitzreihenfolge, nicht ID).
	var start := Command.start_game({"round_id": "seat", "seed": 1, "assignment": "manual", "players": Fixtures.players(6),
		"seat_order": [4, 1, 6, 2, 5, 3], "roles": {"1": D, "2": W, "3": "amalia", "4": "detektiv", "5": "wahnsinniger-kutscher", "6": "waechter-am-tor"}})
	var commands: Array[Command] = [start, Command.confirm_role_shown(4), Command.confirm_role_shown(1), Command.confirm_role_shown(6)]
	var loaded := StateCodec.decode(StateCodec.encode(RulesEngine.replay(commands).state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	assert_eq(RoleShownRules.pending_ids(loaded.state), [2, 5, 3] as Array[int], "offen in Sitzreihenfolge")
	assert_eq(loaded.state.roles_shown, {4: &"detektiv", 1: &"dorfbewohner", 6: &"waechter-am-tor"}, "Fortschritt nach dem Laden")


func test_save_load_and_replay_agree() -> void:
	var commands: Array[Command] = [Fixtures.start_roles([D, W, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 5), Command.confirm_role_shown(2), Command.start_night(),
		Command.confirm_role_shown(5)]
	var state := RulesEngine.replay(commands).state
	var loaded := StateCodec.decode(StateCodec.encode(state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(state.to_dict()), "gleicher Zustand")
	assert_eq(state.content_hash(), RulesEngine.replay(commands).state.content_hash(), "Replay gleicher Hash")
	var without: Array[Command] = commands.slice(0, 3)
	assert_ne(RulesEngine.replay(without).state.content_hash(), state.content_hash(), "Bestätigung ändert den Hash")


func test_no_obligation_before_start_night_and_allowed_later() -> void:
	var s := _state()
	assert_true(apply_ok(s, Command.start_night(), "StartNight ohne jede Bestätigung").ok, "keine Pflicht")
	var night := RulesEngine.apply(s, Command.start_night()).state
	assert_true(RulesEngine.apply(night, Command.confirm_role_shown(3)).ok, "auch während der Nacht möglich")


func test_confirmation_consumes_no_resources_or_randomness() -> void:
	var s := _state()
	var after := apply_ok(s, Command.confirm_role_shown(2), "Bestätigung").state
	var a := s.to_dict()
	var b := after.to_dict()
	for key: String in ["roles_shown", "command_count"]:
		a.erase(key)
		b.erase(key)
	a.erase("next_ids")
	b.erase("next_ids")
	assert_eq(CanonicalJson.stringify(b), CanonicalJson.stringify(a), "nur roles_shown und Zähler ändern sich")
	assert_eq(CanonicalJson.stringify(after.rng.to_dict()), CanonicalJson.stringify(s.rng.to_dict()), "Zufallsgenerator unverändert")


func test_not_allowed_before_game_start_or_after_game_over() -> void:
	assert_false(RulesEngine.apply(GameState.new(), Command.confirm_role_shown(1)).ok, "vor dem Start abgelehnt")
	var s := apply_ok(_state(), CorrectionFixtures.gm("declare_winner", {"winner_kind": "village"}), "Spielende").state
	var r := RulesEngine.apply(s, Command.confirm_role_shown(1))
	assert_false(r.ok, "nach Spielende abgelehnt")
	assert_eq(String(r.error), "game_over", "Fehlergrund")


func test_public_events_never_carry_the_role() -> void:
	var r := apply_ok(_state(), Command.confirm_role_shown(2), "Bestätigung")
	for e: GameEvent in r.events:
		assert_ne(String(e.visibility), "public", "kein öffentliches Ereignis")


func test_undo_sequence_by_replay_removes_confirmation() -> void:
	var commands: Array[Command] = [Fixtures.start_roles([D, W, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 1), Command.confirm_role_shown(2)]
	var undone: Array[Command] = commands.slice(0, 1)
	assert_true(RulesEngine.replay(undone).state.roles_shown.is_empty(), "Rückgängig entfernt die Bestätigung")
	assert_eq(RulesEngine.replay(commands).state.roles_shown.size(), 1, "Wiederholen stellt sie her")
