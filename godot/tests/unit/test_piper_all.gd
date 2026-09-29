extends TestCase
## PE-06 (Antwort des Product Owners vom 29.09.2026) mit DI-02 und DI-06: „Alle Verzauberten“ ist ein eigener Nachtschritt
## direkt hinter dem Rattenfänger. Er folgt auf jeden Aufruf des Rattenfängers, auch auf einen Tarnaufruf, solange es lebende
## Verzauberte gibt; ohne Aufruf des Rattenfängers entfällt er. Reihenfolge bei neuer Verzauberung: Rattenfänger → Hinweis an
## die neu Verzauberten → alle Verzauberten → nächster Schritt. Der Schritt verzaubert nicht, zieht keinen Zufall und
## verbraucht nichts. Eine Rolle gibt es in der Partie nur einmal (Antwort vom 29.09.2026), daher genau ein Folgeschritt.

const W := "werwolf"
const D := "dorfbewohner"
const RF := "rattenfaenger"
const HX := "waldhexe"
const PIPER_ALL := "piper-all"
const CHOICE_STAGES := ["heal", "poison", "use", "mode", "grant", "barrier"]


func _start(roles: Array) -> Array[Command]:
	return [Fixtures.start_roles(roles, 1), Command.start_night()] as Array[Command]


func _state(commands: Array[Command]) -> GameState:
	var r := RulesEngine.replay(commands)
	assert_true(r.ok, "Replay (%s)" % r.error)
	return r.state if r.ok else null


## Standardbefehl für den offenen Prompt oder den nächsten Schritt. `answers`: {"<schritt>" | "<schritt>@<stufe>": Antwort}.
func _next_command(s: GameState, answers: Dictionary) -> Command:
	var p := s.pending_prompt
	if p == null:
		var step := RulesEngine.next_step_id(s)
		return Command.begin_step(step) if step != "" else null
	var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
	var staged := "%s@%s" % [key, p.stage]
	if answers.has(staged):
		var a: Variant = answers[staged]
		return Command.answer_choice(p.id, String(p.stage), a) if a is bool else Command.answer_stage_targets(p.id, String(p.stage), a)
	if CHOICE_STAGES.has(String(p.stage)):
		return Command.answer_choice(p.id, String(p.stage), false)
	if ["confirm", "shown", "reveal"].has(String(p.stage)):
		return Command.answer_choice(p.id, String(p.stage), true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, answers.get(key, p.allowed_ids.slice(0, p.min_count)))


## Spielt Standardbefehle an `commands` an, bis `stop` wahr ist oder die Nacht keinen Schritt mehr hat.
func _run(commands: Array[Command], answers: Dictionary, stop: Callable) -> GameState:
	var s := _state(commands)
	for guard: int in 80:
		if s == null or stop.call(s):
			return s
		var c := _next_command(s, answers)
		if c == null:
			return s
		var r := apply_ok(s, c, "Nachtbefehl %s" % c.type)
		if not r.ok:
			return null
		commands.append(c)
		s = r.state
	fail("Nacht endet nicht")
	return null


## Nacht beenden, Tag ohne Hinrichtung, `day_commands` am Tag, nächste Nacht beginnen.
func _next_night(commands: Array[Command], day_commands: Array[Command] = []) -> GameState:
	var s := _state(commands)
	if s == null:
		return null
	for n: Dictionary in s.notices.duplicate():
		commands.append(Command.ack_notice(int(n["id"])))
	commands.append(Command.end_night())
	commands.append(Command.decide_execution(-1))
	commands.append_array(day_commands)
	commands.append(Command.end_day())
	commands.append(Command.start_night())
	return _state(commands)


func _at_piper_all(s: GameState) -> bool:
	return s.pending_prompt == null and RulesEngine.next_step_id(s).ends_with(":" + PIPER_ALL)


func _at_owner(owner: String) -> Callable:
	return func(s: GameState) -> bool: return s.pending_prompt != null and String(s.pending_prompt.owner) == owner


func _notices_of(s: GameState, kind: String) -> Array:
	return s.notices.filter(func(n: Dictionary) -> bool: return String(n["kind"]) == kind)


func _kill(id: int) -> Command:
	return CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false})


# --- A. Neue Verzauberung -------------------------------------------------------------------------------

func test_new_charm_runs_piper_then_new_notice_then_all_then_next_step() -> void:
	var commands := _start([W, RF, D, D, D, D, D, "das-orakel"])
	var s := _state(commands)
	if s == null:
		return
	var piper_index := s.night_plan.find(&"rattenfaenger:2")
	assert_true(piper_index >= 0, "Rattenfänger im Nachtplan")
	assert_eq(s.night_plan.find(StringName(PIPER_ALL)), piper_index + 1, "Folgeschritt direkt hinter dem Rattenfänger")
	s = _run(commands, {"rattenfaenger:2": [4, 5]}, _at_piper_all)
	if s == null:
		return
	assert_eq(_notices_of(s, "piper_new").size(), 1, "Hinweis an die neu Verzauberten")
	assert_eq(_notices_of(s, "piper_new")[0]["viewer_ids"], [4, 5], "nur die neu Verzauberten")
	assert_eq(s.notices.size(), 1, "kein zusätzlicher Hinweis „alle Verzauberten“")
	assert_eq(CallPolicy.decoy_calls(s), [] as Array[StringName], "nach echtem Aufruf kein Tarnaufruf des Rattenfängers")
	var begun := apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Folgeschritt beginnen")
	var p := begun.state.pending_prompt
	assert_true(p != null and p.owner == &"piper-all" and p.stage == &"shown" and p.actor_id == -1, "Bestätigungskarte der Spielleitung")
	if p == null:
		return
	assert_eq(p.partial, {"charmed_ids": [4, 5]}, "alle lebenden Verzauberten")
	assert_eq(p.allowed_ids, [] as Array[int], "keine Auswahl")
	var charms_before := begun.state.charms.duplicate(true)
	var rng_before := CanonicalJson.stringify(begun.state.rng.to_dict())
	var done := apply_ok(begun.state, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	assert_eq(done.state.charms, charms_before, "keine neue Verzauberung")
	assert_eq(CanonicalJson.stringify(done.state.rng.to_dict()), rng_before, "kein Zufall")
	assert_eq(done.state.night_step_status[piper_index + 1], StepQueue.STATUS_DONE, "Schritt erledigt")
	assert_eq(RulesEngine.next_step_id(done.state).get_slice(":", 3), "das-orakel", "danach der nächste Nachtschritt")
	for e: GameEvent in begun.events + done.events:
		assert_eq(String(e.visibility), "gm", "nur Ereignisse für die Spielleitung: %s" % e.type)


func test_second_night_lists_all_living_charmed_but_notifies_only_the_new_one() -> void:
	var commands := _start([W, RF, D, D, D, D, D])
	_run(commands, {"rattenfaenger:2": [3, 4]}, func(_s: GameState) -> bool: return false)
	_next_night(commands, [_kill(3)] as Array[Command])
	var s := _run(commands, {"rattenfaenger:2": [5]}, _at_piper_all)
	if s == null:
		return
	assert_eq(_notices_of(s, "piper_new")[0]["viewer_ids"], [5], "nur die neu Verzauberte erhält den Hinweis")
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Folgeschritt").state
	assert_eq(s.pending_prompt.partial, {"charmed_ids": [4, 5]}, "alle lebenden Verzauberten, die Tote nicht")


# --- B/C. Kein neuer Zauber, Tarnaufruf -----------------------------------------------------------------

func test_poisoned_piper_is_a_decoy_call_followed_by_all_charmed() -> void:
	var commands := _start([W, RF, HX, D, D, D, D])
	_run(commands, {"rattenfaenger:2": [4, 5]}, func(_s: GameState) -> bool: return false)
	_next_night(commands)
	var s := _run(commands, {"waldhexe:3@poison": true, "waldhexe:3@poison_target": [2]}, _at_piper_all)
	if s == null:
		return
	var piper_index := s.night_plan.find(&"rattenfaenger:2")
	assert_eq(s.night_step_status[piper_index], StepQueue.STATUS_SKIPPED, "Rattenfänger handelt nicht (Gift)")
	assert_eq(CallPolicy.decoy_calls(s), [&"rattenfaenger"] as Array[StringName], "Tarnaufruf vor „Alle Verzauberten“")
	assert_true(_notices_of(s, "piper_new").is_empty(), "keine neu Verzauberten")
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Folgeschritt").state
	assert_eq(s.pending_prompt.partial, {"charmed_ids": [4, 5]}, "alle Verzauberten erkennen einander")
	s = apply_ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Gezeigt").state
	assert_false(CallPolicy.decoy_calls(s).has(&"rattenfaenger"), "Rattenfänger wird nicht ein zweites Mal angesagt")
	assert_eq(s.charms.size(), 2, "keine Verzauberung")


func test_nightmare_block_does_not_stop_the_piper() -> void:
	# RM-DR-010: Blockaden treffen nur Dorfrollen; der Rattenfänger handelt, der Folgeschritt folgt.
	var commands := _start([W, "albtraumwolf", RF, D, D, D, D])
	var s := _run(commands, {"albtraumwolf:2": [3], "rattenfaenger:3": [5]}, _at_piper_all)
	assert_true(s != null and s.blocked_ids.has(3), "Rattenfänger vom Albtraumwolf getroffen")
	if s == null:
		return
	assert_eq(s.charms.size(), 1, "trotzdem verzaubert")
	assert_true(_at_piper_all(s), "Folgeschritt steht an")


func test_dead_piper_in_revival_round_is_called_as_decoy_with_follow_up() -> void:
	var commands := _start([W, RF, "kutscher", D, D, D, D])
	_run(commands, {"rattenfaenger:2": [4, 5]}, func(_s: GameState) -> bool: return false)
	var s := _next_night(commands, [_kill(2)] as Array[Command])
	if s == null:
		return
	assert_true(s.revival_round, "Wiederbelebungsrunde")
	assert_false(s.night_plan.has(&"rattenfaenger:2"), "toter Rattenfänger hat keinen Schritt")
	assert_true(s.night_plan.has(StringName(PIPER_ALL)), "aber einen Folgeschritt")
	s = _run(commands, {}, _at_piper_all)
	assert_true(s != null and CallPolicy.decoy_calls(s).has(&"rattenfaenger"), "Tarnaufruf des Rattenfängers vor dem Folgeschritt")


func test_frozen_night_still_follows_the_decoy_call() -> void:
	# Technische Ableitung: Der Zeitwächter lässt alle Fähigkeiten entfallen, die Rollen werden aber weiter angesagt (DI-02).
	# „Alle Verzauberten“ ist keine Fähigkeit, sondern folgt auf den Aufruf (PE-06).
	var commands := _start([W, RF, "zeitwaechter", D, D, D, D])
	_run(commands, {"rattenfaenger:2": [4]}, func(_s: GameState) -> bool: return false)
	_next_night(commands)
	var s := _run(commands, {"zeitwaechter:3@use": true}, _at_piper_all)
	assert_true(s != null and s.night_frozen, "Nacht eingefroren")
	if s == null:
		return
	assert_true(CallPolicy.decoy_calls(s).has(&"rattenfaenger"), "Tarnaufruf des Rattenfängers")
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Folgeschritt").state
	assert_eq(s.pending_prompt.partial, {"charmed_ids": [4]}, "Verzauberte erkennen einander")


# --- D. Aufruf entfällt -----------------------------------------------------------------------------------

func test_dead_piper_without_revival_has_no_follow_up() -> void:
	var commands := _start([W, RF, D, D, D, D, D])
	_run(commands, {"rattenfaenger:2": [3, 4]}, func(_s: GameState) -> bool: return false)
	var s := _next_night(commands, [_kill(2)] as Array[Command])
	if s == null:
		return
	assert_false(s.revival_round, "keine Wiederbelebungsrunde")
	assert_false(s.night_plan.has(StringName(PIPER_ALL)), "kein Folgeschritt ohne Aufruf")
	s = _run(commands, {}, func(_s: GameState) -> bool: return false)
	assert_true(s != null and RulesEngine.next_step_id(s) == "", "Nacht zu Ende")
	assert_false(CallPolicy.decoy_calls(s).has(&"rattenfaenger"), "kein Aufruf des toten Rattenfängers")
	assert_true(s.notices.is_empty(), "keine Hinweise")


func test_no_living_charmed_drops_the_follow_up_without_orphan() -> void:
	var commands := _start([W, RF, HX, D, D, D, D])
	_run(commands, {"rattenfaenger:2": [4, 5]}, func(_s: GameState) -> bool: return false)
	_next_night(commands, [_kill(4), _kill(5)] as Array[Command])
	var log_start := commands.size()
	var s := _run(commands, {"waldhexe:3@poison": true, "waldhexe:3@poison_target": [2]}, func(_s: GameState) -> bool: return false)
	if s == null:
		return
	assert_eq(RulesEngine.next_step_id(s), "", "kein offener Schritt")
	assert_eq(s.night_step_status[s.night_plan.find(StringName(PIPER_ALL))], StepQueue.STATUS_SKIPPED, "Folgeschritt entfällt")
	assert_eq(CallPolicy.decoy_calls(s), [&"rattenfaenger"] as Array[StringName], "Tarnaufruf vor dem Ende der Nacht bleibt")
	var dropped := events_of_type(RulesEngine.replay(commands).events, "StepDropped").filter(
		func(e: GameEvent) -> bool: return str(e.data["step_id"]).ends_with(":" + PIPER_ALL))
	assert_eq(dropped.size(), 1, "Wegfall protokolliert")
	if dropped.size() == 1:
		assert_eq(str(dropped[0].data["reason"]), "no_decision", "Grund: keine lebenden Verzauberten")
		assert_eq(String(dropped[0].visibility), "gm", "nur für die Spielleitung")
	assert_true(log_start < commands.size(), "Nacht gespielt")


# --- E. Speichern, Fortsetzen, Rückgängig ------------------------------------------------------------------

func _assert_resumes(commands: Array[Command], label: String) -> void:
	var live := _state(commands)
	if live == null:
		return
	var loaded := StateCodec.decode(StateCodec.encode(live, commands))
	assert_true(loaded.ok, "%s: Laden (%s)" % [label, loaded.error])
	if not loaded.ok:
		return
	assert_eq(loaded.state.content_hash(), live.content_hash(), "%s: gleicher Hash" % label)
	assert_eq(RulesEngine.next_step_id(loaded.state), RulesEngine.next_step_id(live), "%s: gleicher nächster Schritt" % label)
	assert_eq(loaded.state.notices, live.notices, "%s: gleiche Hinweise" % label)
	assert_eq(CallPolicy.decoy_calls(loaded.state), CallPolicy.decoy_calls(live), "%s: gleiche Tarnaufrufe" % label)
	if live.pending_prompt != null:
		assert_eq(loaded.state.pending_prompt.to_dict(), live.pending_prompt.to_dict(), "%s: gleicher offener Prompt" % label)


func test_save_and_resume_at_every_interruption_point() -> void:
	var commands := _start([W, RF, D, D, D, D, D, "das-orakel"])
	_run(commands, {}, _at_owner("rattenfaenger"))
	var before_piper := commands.slice(0, commands.size() - 1)  # vor BeginStep des Rattenfängers
	_assert_resumes(before_piper, "vor dem Rattenfänger")
	var s := _run(commands, {"rattenfaenger:2": [4, 5]}, _at_piper_all)
	if s == null:
		return
	_assert_resumes(commands, "nach der Aktion, vor „Neu Verzauberte“")
	commands.append(Command.ack_notice(int(s.notices[0]["id"])))
	_assert_resumes(commands, "zwischen „Neu Verzauberte“ und „Alle Verzauberten“")
	s = _state(commands)
	assert_true(s.notices.is_empty() and _at_piper_all(s), "danach genau der Folgeschritt")
	commands.append(Command.begin_step(RulesEngine.next_step_id(s)))
	_assert_resumes(commands, "Karte „Alle Verzauberten“ offen")
	s = _state(commands)
	var answer := Command.answer_choice(s.pending_prompt.id, "shown", true)
	commands.append(answer)
	_assert_resumes(commands, "nach der Bestätigung")
	s = _state(commands)
	assert_eq(RulesEngine.next_step_id(s).get_slice(":", 3), "das-orakel", "nach dem Neustart weiter mit dem nächsten Schritt")
	# Doppelte oder veraltete Bestätigung wird abgelehnt und ändert nichts.
	var rejected := RulesEngine.apply(s, answer)
	assert_false(rejected.ok, "zweite Bestätigung abgelehnt")
	assert_eq(s.night_step_status.count(StepQueue.STATUS_DONE), _state(commands).night_step_status.count(StepQueue.STATUS_DONE), "kein weiterer Schritt erledigt")
	var stale := RulesEngine.apply(s, Command.begin_step("night:1:%d:%s" % [s.night_plan.find(StringName(PIPER_ALL)), PIPER_ALL]))
	assert_false(stale.ok, "veralteter Schritt kann nicht erneut begonnen werden")
	# Rückgängig per Replay ohne die Bestätigung: Karte wieder offen, gleiche Liste.
	var undone := _state(commands.slice(0, commands.size() - 1))
	assert_true(undone.pending_prompt != null and undone.pending_prompt.owner == &"piper-all", "nach Rückgängig wieder offen")
	assert_eq(undone.pending_prompt.partial, {"charmed_ids": [4, 5]}, "gleiche Personen")
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(RulesEngine.replay(commands).events), "bytegleiches Replay")


func test_stale_answer_after_state_change_is_rejected() -> void:
	var commands := _start([W, RF, D, D, D, D, D])
	var s := _run(commands, {"rattenfaenger:2": [4, 5]}, _at_piper_all)
	if s == null:
		return
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Folgeschritt").state
	var old_id := s.pending_prompt.id
	s = apply_ok(s, Command.cancel_prompt(old_id, "zurück"), "Karte geschlossen").state
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "neu geöffnet").state
	assert_ne(s.pending_prompt.id, old_id, "neue Prompt-ID")
	assert_false(RulesEngine.apply(s, Command.answer_choice(old_id, "shown", true)).ok, "Bestätigung der alten Karte abgelehnt")


func test_load_rejects_a_tampered_list() -> void:
	var commands := _start([W, RF, D, D, D, D, D])
	var s := _run(commands, {"rattenfaenger:2": [4, 5]}, _at_piper_all)
	if s == null:
		return
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Folgeschritt").state
	var d := s.to_dict()
	assert_true(GameState.from_dict(d) != null, "unverändert ladbar")
	var bad := d.duplicate(true)
	(bad["pending_prompt"] as Dictionary)["partial"] = {"charmed_ids": [4, 5, 6]}
	assert_true(GameState.from_dict(bad) == null, "Liste passt nicht zum Zustand")


func test_old_rules_version_is_marked_incompatible() -> void:
	var commands := _start([W, RF, D, D, D, D, D])
	var s := _state(commands)
	var text := StateCodec.encode(s, commands).replace(String(GameState.RULES_VERSION), "grimmhain-core-0.12")
	var loaded := StateCodec.decode(text)
	assert_false(loaded.ok, "Stand der Regelversion 0.12 wird nicht geladen")
	assert_eq(loaded.error, &"unsupported_rules_version", "als andere Regelversion erkannt")
