extends TestCase
## DI-02 (Antwort des Product Owners vom 29.09.2026): Aufrufpolitik als reine Abfrage des Kernzustands.
##   Ohne Wiederbelebung: aufgedeckte tote Rollen werden nicht mehr aufgerufen.
##   Verbrauchte oder entfallene Fähigkeiten: die Rolle wird trotzdem aufgerufen, ohne etwas auszuführen.
##   Mit Wiederbelebung: auch tote Rollen werden aufgerufen.
## Tarnaufrufe sind nur Ansage: Sie ändern weder Zustand noch Zufall (Hash gleich, Seed-Position gleich).

const W := "werwolf"
const D := "dorfbewohner"


func _night_state(roles: Array) -> GameState:
	var commands := Fixtures.start_with_copies(roles, 3)
	commands.append(Command.start_night())
	var r := RulesEngine.replay(commands)
	assert_true(r.ok, "Start und Nacht (%s)" % r.error)
	return r.state if r.ok else null


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


## Leere Antwort auf den Rudelschritt = ruhige Nacht (SkipStep mit Grund; die Karte kennt keinen "Kein Opfer"-Knopf).
func _answer(s: GameState, targets: Array) -> GameState:
	if targets.is_empty() and s.pending_prompt.owner == PendingPrompt.OWNER_PACK:
		return _ok(s, Command.skip_step(s.pending_prompt.step_id, "Test: ruhige Nacht"), "Rudel übersprungen")
	return _ok(s, Command.answer_prompt(s.pending_prompt.id, targets), "Antwort")


func _begin(s: GameState) -> GameState:
	return _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt beginnen")


func test_non_revival_round_calls_living_roles_only() -> void:
	var s := _night_state([W, "blutwolf", "schutzengel", "waldhexe", "das-orakel", D])
	var called := CallPolicy.called_roles(s)
	for role: StringName in [&"schutzengel", &"waldhexe", &"das-orakel"]:
		assert_true(called.has(role), "%s wird aufgerufen" % role)
	assert_false(called.has(&"werwolf"), "Rudel ist ein eigener Schritt, keine Rolle mit Platz")
	var killed := s.duplicate_state()
	killed.players[3].alive = false
	killed.players[3].death = KillEvent.new()
	assert_false(CallPolicy.called_roles(killed).has(&"schutzengel"), "aufgedeckte tote Rolle wird nicht mehr aufgerufen")
	assert_true(CallPolicy.called_roles(killed).has(&"waldhexe"), "lebende Rolle bleibt")


## Zwei Personen mit derselben Rolle entstehen im Spiel (Korrektur, Verwandlung, Erbe), nicht im Start (PE-07).
func test_second_holder_keeps_the_role_called() -> void:
	var s := _night_state([W, "blutwolf", "schutzengel", "schutzengel", "das-orakel", D])
	s.players[3].alive = false
	s.players[3].death = KillEvent.new()
	assert_true(CallPolicy.called_roles(s).has(&"schutzengel"), "solange eine Person die Rolle lebend hält")


func test_revival_round_keeps_calling_dead_roles() -> void:
	var s := _night_state([W, "blutwolf", "schutzengel", "kutscher", "das-orakel", D])
	assert_true(s.revival_round, "Wiederbelebungsrunde")
	s.players[3].alive = false
	s.players[3].death = KillEvent.new()
	assert_true(CallPolicy.called_roles(s).has(&"schutzengel"), "tote Rolle wird weiter aufgerufen")
	assert_true(CallPolicy.called_roles(s).has(&"kutscher"), "Rolle ohne Schritt heute wird aufgerufen")


func test_used_up_role_is_announced_at_its_place_without_a_step() -> void:
	var fresh := RulesEngine.replay([Fixtures.start_roles([W, "blutwolf", "schutzengel", "waldhexe", "das-orakel", D], 3)] as Array[Command]).state
	fresh.players[4].ability_uses["waldhexe:heal"] = 1
	fresh.players[4].ability_uses["waldhexe:poison"] = 1
	var running := _ok(fresh, Command.start_night(), "Nacht")
	assert_false(running.night_plan.has(&"waldhexe:4"), "verbrauchte Waldhexe hat keinen Schritt")
	# Schutzengel und Rudel erledigen; vor dem Orakel steht die Waldhexe als Tarnaufruf.
	running = _answer(running, [6])
	running = _begin(running)
	running = _answer(running, [])
	assert_eq(RulesEngine.next_step_id(running).get_slice(":", 3), "das-orakel", "nächster echter Schritt: Orakel")
	assert_eq(CallPolicy.decoy_calls(running), [&"waldhexe"] as Array[StringName], "Waldhexe wird ohne Fähigkeit aufgerufen")


func test_dropped_step_is_still_announced() -> void:
	# Der Schattenhund blockiert alle Dorfschritte: Schutzengel, Waldhexe und Orakel entfallen, werden aber angesagt.
	var s := _night_state(["werwolf", "schattenhund", "schutzengel", "waldhexe", "das-orakel", D])
	assert_eq(s.pending_prompt.owner, &"schattenhund", "Schattenhund handelt zuerst")
	s = _ok(s, Command.answer_choice(s.pending_prompt.id, "use", true), "Schattenhund blockiert")
	assert_eq(RulesEngine.next_step_id(s).get_slice(":", 3), "pack", "Schutzengel entfallen, Rudel folgt")
	assert_eq(CallPolicy.decoy_calls(s), [&"schutzengel"] as Array[StringName], "entfallener Schutzengel wird angesagt")
	s = _begin(s)
	s = _answer(s, [6])
	assert_eq(RulesEngine.next_step_id(s), "", "Waldhexe und Orakel entfallen, keine Schritte mehr")
	assert_eq(CallPolicy.decoy_calls(s), [&"waldhexe", &"das-orakel"] as Array[StringName], "entfallene Schritte vor dem Ende der Nacht")


func test_trailing_calls_before_end_of_night() -> void:
	var s := _night_state([W, "blutwolf", "kutscher", D, "amalia", "detektiv"])
	s = _answer(s, [])
	assert_eq(RulesEngine.next_step_id(s), "", "kein Schritt mehr")
	assert_eq(CallPolicy.decoy_calls(s), [&"kutscher"] as Array[StringName], "Rolle nach dem letzten Schritt wird angesagt")


func test_group_roles_and_first_night_roles_are_called_after_their_night() -> void:
	var s := _night_state(["werwolf", "die-gebundenen", "die-gebundenen", "dorfchronistin", D, "amalia"])
	var guard := 0
	while guard < 30 and s != null and (s.pending_prompt != null or RulesEngine.next_step_id(s) != ""):
		guard += 1
		if s.pending_prompt != null:
			var p := s.pending_prompt
			if p.stage == &"shown":
				s = _ok(s, Command.answer_choice(p.id, String(p.stage), true), "Prompt")
			else:
				s = _answer(s, Fixtures.pass_targets(s, p))
		else:
			s = _begin(s)
	s = _ok(s, Command.end_night(), "Morgen")
	s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
	s = _ok(s, Command.end_day(), "Tagesende")
	s = _ok(s, Command.start_night(), "Nacht 2")
	var calls := CallPolicy.decoy_calls(s) if s.pending_prompt == null else CallPolicy.called_roles(s)
	assert_true(calls.has(&"die-gebundenen") and calls.has(&"dorfchronistin"), "Nur-Nacht-1-Rollen und Gruppen werden weiter aufgerufen")


func test_decoys_are_ordered_by_night_position() -> void:
	var s := _night_state([W, "schattenhund", "schutzengel", "waldhexe", "das-orakel", "kutscher"])
	var called := CallPolicy.called_roles(s)
	var positions: Array[int] = []
	for role: StringName in called:
		positions.append(CallPolicy.slot_priority(role))
	var sorted := positions.duplicate()
	sorted.sort()
	assert_eq(positions, sorted, "nach Nachtposition sortiert")


func test_calls_do_not_touch_state_or_randomness() -> void:
	var s := _night_state([W, "blutwolf", "schutzengel", "waldhexe", "das-orakel", "kutscher"])
	var before := s.content_hash()
	var rng_before := CanonicalJson.stringify(s.rng.to_dict())
	for i: int in 5:
		CallPolicy.called_roles(s)
		CallPolicy.decoy_calls(s)
	assert_eq(s.content_hash(), before, "Zustand unverändert")
	assert_eq(CanonicalJson.stringify(s.rng.to_dict()), rng_before, "Zufallsposition unverändert")


func test_same_state_gives_same_calls_after_replay_and_load() -> void:
	var commands: Array[Command] = [Fixtures.start_roles([W, "blutwolf", "schutzengel", "waldhexe", "das-orakel", "kutscher"], 3), Command.start_night()]
	var first := RulesEngine.replay(commands)
	var loaded := StateCodec.decode(StateCodec.encode(first.state, commands))
	assert_true(loaded.ok, "Laden")
	if loaded.ok:
		assert_eq(CallPolicy.called_roles(loaded.state), CallPolicy.called_roles(first.state), "gleiche Aufrufe nach dem Laden")
		assert_eq(CallPolicy.decoy_calls(loaded.state), CallPolicy.decoy_calls(first.state), "gleiche Tarnaufrufe nach dem Laden")
	var prefix := RulesEngine.replay(commands.slice(0, 1))
	assert_eq(CallPolicy.decoy_calls(prefix.state), [] as Array[StringName], "außerhalb der Nacht keine Tarnaufrufe")
