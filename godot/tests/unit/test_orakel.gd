extends TestCase
## Produktionsrolle `das-orakel` (The Oracle), rules-register.md §4, DR-07.
## O6:  1, 2 Werwölfe; 3 Schutzengel; 4 Orakel; 5, 6 Dorfbewohner.
## O6R: wie O6, aber 5 Sensenträger.
## B6:  1, 2 Werwölfe; 3 Schutzengel; 4 Orakel; 5 Waldhexe; 6 Dorfbewohner
##      (entspricht B6 aus acceptance-scenarios.md ohne Trugbilderwolf).
## Nacht 1 in O6: Prompt 1 Schutzengel, Prompt 2 Rudel, Prompt 3 Orakel.
## Die Tests greifen über Befehlsnutzdaten und die Serialisierung auf neue Felder zu.

const PACK_1 := "night:1:1:pack"
const ORACLE_1 := "night:1:2:das-orakel:4"
const ORACLE_PROMPT := 3
const OVERRIDE := &"OverrideShownRole"
const FORBIDDEN_PUBLIC := ["orakel", "oracle", "info", "truth", "determined", "shown", "role", "werwolf", "dorfbewohner",
	"schutzengel", "waldhexe", "sensentraeger", "target", "stage", "allowed", "override"]


func _o6() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "das-orakel", "dorfbewohner", "dorfbewohner"])


func _o6r() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "das-orakel", "sensentraeger", "dorfbewohner"])


func _b6() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "das-orakel", "waldhexe", "dorfbewohner"])


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## Nacht 1 bis zum begonnenen Orakelschritt: Schutz auf 6, Rudel ohne Opfer.
func _to_oracle(start: Command = null) -> Array[Command]:
	return [start if start != null else _o6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1),
		Command.answer_prompt(2, []), Command.begin_step(ORACLE_1)]


func _target(id: int, prompt_id: int = ORACLE_PROMPT) -> Command:
	return Command.answer_stage_targets(prompt_id, "target", [id])


func _shown(prompt_id: int = ORACLE_PROMPT) -> Command:
	return Command.answer_choice(prompt_id, "shown", true)


func _override(role: String, reason: String = "Spielleiter übersteuert", confirmed: Variant = true, prompt_id: int = ORACLE_PROMPT) -> Command:
	var payload := {"prompt_id": prompt_id, "shown_role": role, "reason": reason}
	if confirmed != null:
		payload["confirmed"] = confirmed
	return Command.create(OVERRIDE, payload)


## Vollständige Prüfung von `target` in Nacht 1, optional mit Übersteuerung.
func _check(target: int, override_role: String = "", start: Command = null) -> Array[Command]:
	var out := _to_oracle(start)
	out.append(_target(target))
	if override_role != "":
		out.append(_override(override_role))
	out.append(_shown())
	return out


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _stage(s: GameState) -> String:
	return str(s.pending_prompt.to_dict().get("stage", "")) if s.pending_prompt != null else ""


func _records(s: GameState) -> Array:
	return s.to_dict().get("info_records", [])


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


func _expect_info(s: GameState, truth: String, determined: String, shown: String, label: String) -> void:
	var p := s.pending_prompt.partial if s.pending_prompt != null else {}
	assert_eq(str(p.get("truth_role", "")), truth, "%s: Wahrheit" % label)
	assert_eq(str(p.get("determined_role", "")), determined, "%s: ermittelt" % label)
	assert_eq(str(p.get("shown_role", "")), shown, "%s: gezeigt" % label)


# --- 1–9 Rolle, Nachtplan, Ablauf -----------------------------------------------------

func test_production_role() -> void:
	# 1
	var r := apply_ok(GameState.new(), _o6(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	var p := r.state.players[4]
	assert_eq(String(p.role_id), "das-orakel", "Rolle")
	assert_eq(String(p.faction), "village", "Dorf")
	assert_false(p.counts_as_wolf, "kein Wolf")
	assert_eq(String(p.appears_as), "das-orakel", "normale Erscheinung")


func test_night_order_guard_pack_witch_oracle() -> void:
	# 2
	var run := _replay_ok([_b6(), Command.start_night()] as Array[Command], "B6 Nacht 1")
	if run.ok:
		assert_eq(run.state.night_plan, [&"schutzengel:3", &"pack", &"waldhexe:5", &"das-orakel:4"] as Array[StringName], "Schutzengel, Rudel, Waldhexe, Orakel")


func test_multiple_oracles_by_id() -> void:
	# 3
	var s := Fixtures.play([Fixtures.start_roles(["werwolf", "werwolf", "das-orakel", "dorfbewohner", "das-orakel", "dorfbewohner"]),
		Command.start_night()] as Array[Command])
	assert_eq(s.night_plan, [&"pack", &"das-orakel:3", &"das-orakel:5"] as Array[StringName], "nach Personen-ID")
	s = apply_ok(s, Command.answer_prompt(1, []), "Rudel").state
	s = apply_ok(s, Command.begin_step("night:1:1:das-orakel:3"), "erstes Orakel").state
	assert_eq(int(s.pending_prompt.actor_id), 3, "erstes Orakel handelt")
	s = apply_ok(apply_ok(s, _target(6, 2), "Ziel").state, _shown(2), "Gezeigt").state
	assert_eq(RulesEngine.next_step_id(s), "night:1:2:das-orakel:5", "zweites Orakel folgt")


func test_no_step_without_living_oracle() -> void:
	# 4: Orakel stirbt in Nacht 1 durch das Rudel.
	var commands: Array[Command] = [_o6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1),
		Command.answer_prompt(2, [4]), Command.begin_step(ORACLE_1), _target(5), _shown(), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var run := _replay_ok(commands, "Nacht 2")
	if run.ok:
		assert_eq(run.state.night_plan, [&"schutzengel:3", &"pack"] as Array[StringName], "kein Orakelschritt")


func test_dead_oracle_before_step_does_not_act() -> void:
	# 5
	var s := Fixtures.play(_to_oracle().slice(0, 5))
	var r := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": false}), "Orakel stirbt")
	var dropped := events_of_type(r.events, "StepDropped")
	assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "actor_dead", "Schritt entfällt")
	assert_eq(RulesEngine.next_step_id(r.state), "", "kein Schritt mehr")


func test_role_change_before_step() -> void:
	# 6
	var s := Fixtures.play(_to_oracle().slice(0, 5))
	var r := apply_ok(s, CorrectionFixtures.gm("set_role", {"target_id": 4, "role_id": "dorfbewohner"}), "Orakel wird Dorfbewohner")
	var dropped := events_of_type(r.events, "StepDropped")
	assert_true(dropped.size() == 1 and String(dropped[0].data["step_id"]) == ORACLE_1 and String(dropped[0].data["reason"]) == "actor_role_changed", "actor_role_changed")
	assert_true(r.state.pending_prompt == null and _records(r.state).is_empty(), "keine Prüfung")
	apply_ok(r.state, Command.end_night(), "Nacht endet")


func test_new_oracle_during_night_acts_next_night() -> void:
	# 7
	var s := Fixtures.play([_o6(), Command.start_night(), Command.answer_prompt(1, [6])] as Array[Command])
	var r := apply_ok(s, CorrectionFixtures.gm("set_role", {"target_id": 5, "role_id": "das-orakel"}), "5 wird Orakel")
	assert_eq(r.state.night_plan, s.night_plan, "Nachtplan unverändert")
	var rest: Array[Command] = [Command.begin_step(PACK_1), Command.answer_prompt(2, []), Command.begin_step(ORACLE_1), _target(6), _shown(),
		Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var state := r.state
	for c: Command in rest:
		var step := apply_ok(state, c, "Fortsetzung")
		if not step.ok:
			return
		if state.phase == Phase.NIGHT and state.night_number == 1:
			assert_false(RulesEngine.next_step_id(step.state).ends_with("das-orakel:5"), "kein Schritt für 5 in Nacht 1")
		state = step.state
	assert_true(state.night_plan.has(&"das-orakel:5"), "Schritt ab der folgenden Nacht")


func test_not_skippable() -> void:
	# 8
	var open := Fixtures.play(_to_oracle())
	apply_rejected(open, Command.skip_step(ORACLE_1, "Orakel schläft"), "step_not_skippable", "offener Prompt")
	var cancelled := apply_ok(open, Command.cancel_prompt(ORACLE_PROMPT, "später"), "Abbruch").state
	apply_rejected(cancelled, Command.skip_step(ORACLE_1, "Orakel schläft"), "step_not_skippable", "vor Beginn")


func test_cancel_discards_everything_and_reoffers() -> void:
	# 9
	var before_begin := Fixtures.play(_to_oracle().slice(0, 5))
	var paths := {
		"Zielwahl offen": [] as Array[Command],
		"nach Zielwahl": [_target(1)] as Array[Command],
		"nach Übersteuerung": [_target(1), _override("dorfbewohner")] as Array[Command],
	}
	for label: String in paths:
		var s := Fixtures.play(_concat(_to_oracle(), paths[label]))
		assert_true(s != null, "%s: erreicht" % label)
		if s == null:
			continue
		var c := apply_ok(s, Command.cancel_prompt(ORACLE_PROMPT, "falsches Ziel"), "%s: Abbruch" % label).state
		assert_eq(c.content_hash(), before_begin.content_hash(), "%s: Hash wie vor BeginStep" % label)
		assert_true(_records(c).is_empty(), "%s: keine Information" % label)
		assert_eq(RulesEngine.next_step_id(c), ORACLE_1, "%s: derselbe Schritt" % label)
		var again := apply_ok(c, Command.begin_step(ORACLE_1), "%s: neu begonnen" % label).state
		assert_eq(_stage(again), "target", "%s: wieder Zielwahl" % label)
		assert_true(again.pending_prompt.partial.is_empty(), "%s: keine alten Werte" % label)
		var other := apply_ok(again, _target(5, again.pending_prompt.id), "%s: anderes Ziel" % label).state
		assert_eq(int(other.pending_prompt.partial.get("target_id", 0)), 5, "%s: neues Ziel" % label)


# --- 10–17 Zielwahl und Informationsregel -----------------------------------------------

func test_no_self_target() -> void:
	# 10, 11, AS-R33
	var s := Fixtures.play(_to_oracle())
	assert_eq(_stage(s), "target", "Zielwahl")
	assert_eq(s.pending_prompt.allowed_ids, [1, 2, 3, 5, 6] as Array[int], "andere lebende Personen")
	assert_true(s.pending_prompt.min_count == 1 and s.pending_prompt.max_count == 1, "genau eine Person")
	apply_rejected(s, _target(4), "invalid_target", "manipulierte Selbstwahl")
	apply_rejected(s, Command.answer_stage_targets(ORACLE_PROMPT, "target", [1, 2]), "invalid_target_count", "zwei Ziele")
	apply_rejected(s, Command.answer_prompt(ORACLE_PROMPT, [1]), "stage_mismatch", "ohne Stufe")


func test_dead_target_rejected() -> void:
	# 12
	var s := Fixtures.play(_concat(_to_oracle().slice(0, 5), [CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}),
		Command.begin_step(ORACLE_1)] as Array[Command]))
	assert_false(s.pending_prompt.allowed_ids.has(6), "Tote nicht angeboten")
	apply_rejected(s, _target(6), "invalid_target", "totes Ziel")
	apply_rejected(s, _target(99), "invalid_target", "unbekanntes Ziel")


func test_villager_true_information() -> void:
	# 13, AS-R09
	var s := apply_ok(Fixtures.play(_to_oracle()), _target(5), "Ziel 5").state
	assert_eq(_stage(s), "shown", "Bestätigungsstufe Gezeigt")
	_expect_info(s, "dorfbewohner", "dorfbewohner", "dorfbewohner", "Dorfbewohner")
	assert_true(_records(s).is_empty(), "noch keine abgeschlossene Information")


func test_werewolf_determined_as_werewolf() -> void:
	# 14, AS-R10
	var s := apply_ok(Fixtures.play(_to_oracle()), _target(1), "Ziel 1").state
	_expect_info(s, "werwolf", "werwolf", "werwolf", "Werwolf")


func test_special_wolf_determined_as_werewolf() -> void:
	# 15: direkt aufgebauter Testzustand, Sensenträger zählt als Wolf (Sonderwolf ohne Produktionsrolle).
	var s := Fixtures.play(_to_oracle(_o6r()))
	s.players[5].counts_as_wolf = true
	var r := apply_ok(s, _target(5), "Ziel Sonderwolf").state
	_expect_info(r, "sensentraeger", "werwolf", "werwolf", "Sonderwolf")


func test_non_wolf_actual_role() -> void:
	# 16
	var s := apply_ok(Fixtures.play(_to_oracle()), _target(3), "Ziel 3").state
	_expect_info(s, "schutzengel", "schutzengel", "schutzengel", "Schutzengel")


func test_stored_appearance_priority() -> void:
	# 17: gespeicherte Erscheinung vor Wolfsregel und tatsächlicher Rolle.
	var cases := {"Nicht-Wolf": [5, "waldhexe", "dorfbewohner"], "Wolf": [1, "dorfbewohner", "werwolf"]}
	for label: String in cases:
		var target: int = cases[label][0]
		var start: Array[Command] = [_o6(), CorrectionFixtures.gm("set_role_field", {"target_id": target, "field": "appears_as", "value": cases[label][1]}, "Testaufbau")]
		var s := Fixtures.play(_concat(start, _to_oracle().slice(1)))
		var r := apply_ok(s, _target(target), label).state
		_expect_info(r, cases[label][2], cases[label][1], cases[label][1], label)


# --- 18–24 Übersteuerung und Bestätigung ------------------------------------------------

func test_override_changes_only_shown() -> void:
	# 18, AS-R13 Grundlage
	var s := apply_ok(Fixtures.play(_to_oracle()), _target(1), "Ziel 1").state
	var r := apply_ok(s, _override("dorfbewohner", "Spielbalance"), "Übersteuerung")
	_expect_info(r.state, "werwolf", "werwolf", "dorfbewohner", "übersteuert")
	assert_true(bool(r.state.pending_prompt.partial.get("overridden", false)), "als übersteuert markiert")
	assert_eq(str(r.state.pending_prompt.partial.get("override_reason", "")), "Spielbalance", "Grund gespeichert")
	assert_eq(events_of_type(r.events, "PromptCancelled").size(), 0, "Prompt bleibt offen")
	assert_eq(_stage(r.state), "shown", "weiter Bestätigungsstufe")
	assert_true(_records(r.state).is_empty(), "noch nicht final")
	var logged := events_of_type(r.events, "InfoOverridden")
	assert_true(logged.size() == 1 and str(logged[0].data["old_shown_role"]) == "werwolf" and str(logged[0].data["new_shown_role"]) == "dorfbewohner"
		and str(logged[0].data["reason"]) == "Spielbalance" and String(logged[0].visibility) == "gm", "alter und neuer Wert protokolliert")


func test_override_validation() -> void:
	# 19, 20, 21
	var open := Fixtures.play(_to_oracle())
	apply_rejected(open, _override("dorfbewohner"), "stage_mismatch", "vor der Zielwahl")
	var s := apply_ok(open, _target(1), "Ziel 1").state
	apply_rejected(s, _override("dorfbewohner", "x", null), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, _override("dorfbewohner", "x", false), "confirmation_required", "Bestätigung false")
	apply_rejected(s, _override("dorfbewohner", ""), "reason_required", "ohne Begründung")
	apply_rejected(s, _override("dorfbewohner", "   "), "reason_required", "leere Begründung")
	for bad: String in ["test-sensentraeger", "nicht-im-katalog", "unbekannt", ""]:
		apply_rejected(s, _override(bad), "unknown_role", "gezeigter Wert '%s'" % bad)
	apply_rejected(s, _override("werwolf"), "no_change", "gleicher Wert")
	apply_rejected(s, _override("dorfbewohner", "x", true, 9), "prompt_mismatch", "falscher Prompt")
	var done := apply_ok(s, _shown(), "Gezeigt").state
	apply_rejected(done, _override("dorfbewohner"), "no_open_prompt", "nach Bestätigung")
	var witch := Fixtures.play([_b6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1), Command.answer_prompt(2, []),
		Command.begin_step("night:1:2:waldhexe:5")] as Array[Command])
	apply_rejected(witch, _override("dorfbewohner"), "not_overridable", "fremder Prompt")


func test_shown_before_target_rejected() -> void:
	# 22
	var s := Fixtures.play(_to_oracle())
	apply_rejected(s, _shown(), "stage_mismatch", "Gezeigt ohne Zielwahl")
	var t := apply_ok(s, _target(5), "Ziel").state
	apply_rejected(t, Command.answer_choice(ORACLE_PROMPT, "shown", false), "invalid_answer", "Gezeigt nur mit Ja")
	apply_rejected(t, _target(6), "stage_mismatch", "zweite Zielwahl")


func test_final_confirmation_single_record() -> void:
	# 23, 24
	var commands := _check(5)
	var before := Fixtures.play(commands.slice(0, commands.size() - 1))
	var r := apply_ok(before, commands[commands.size() - 1], "Gezeigt")
	var records := _records(r.state)
	assert_eq(records.size(), 1, "genau ein Informationsdatensatz")
	if records.size() == 1:
		var rec: Dictionary = records[0]
		assert_true(int(rec["id"]) == 1 and int(rec["oracle_id"]) == 4 and int(rec["target_id"]) == 5 and int(rec["night"]) == 1
			and str(rec["truth_role"]) == "dorfbewohner" and str(rec["determined_role"]) == "dorfbewohner" and str(rec["shown_role"]) == "dorfbewohner"
			and not bool(rec["overridden"]) and str(rec["override_reason"]) == "", "Datensatzfelder")
	assert_eq(events_of_type(r.events, "InfoRecorded").size(), 1, "ein Audit-Ereignis")
	assert_eq(events_of_type(r.events, "InfoRevealed").size(), 1, "ein Ereignis für das Orakel")
	assert_true(r.state.pending_prompt == null, "Prompt geschlossen")
	assert_eq(String(r.state.night_step_status[2]), "done", "Schritt erledigt")
	apply_rejected(r.state, _shown(), "no_open_prompt", "doppelte Bestätigung")
	apply_rejected(r.state, Command.begin_step(ORACLE_1), "no_pending_step", "Schritt nicht erneut")


# --- 25–31 Save/Load und Replay -----------------------------------------------------------

func _load_roundtrip(commands: Array[Command], label: String) -> LoadResult:
	var run := _replay_ok(commands, label)
	if not run.ok:
		return null
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Laden (%s %s)" % [label, loaded.error, loaded.detail])
	if not loaded.ok:
		return null
	assert_eq(_json(loaded.state.to_dict()), _json(run.state.to_dict()), "%s: vollständiger Zustand" % label)
	assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: State-Hash" % label)
	return loaded


func _continue_both(original: GameState, loaded: GameState, rest: Array[Command], label: String) -> void:
	var a := original
	var b := loaded
	var ea: Array[GameEvent] = []
	var eb: Array[GameEvent] = []
	for c: Command in rest:
		var ra := RulesEngine.apply(a, c)
		var rb := RulesEngine.apply(b, c)
		assert_true(ra.ok and rb.ok, "%s: %s angenommen (%s)" % [label, c.type, ra.error])
		if not (ra.ok and rb.ok):
			return
		a = ra.state
		b = rb.state
		ea.append_array(ra.events)
		eb.append_array(rb.events)
	assert_eq(events_json(eb), events_json(ea), "%s: identische Fortsetzung" % label)
	assert_eq(_json(b.to_dict()), _json(a.to_dict()), "%s: identischer Endzustand" % label)


func test_save_load_at_every_stage() -> void:
	# 25–29 (Zielwahl und Berechnung geschehen in einem Befehl, daher ist 26 = 27)
	var full := _check(1, "dorfbewohner")
	full.append(Command.end_night())
	var base := _to_oracle().size()
	var points := {
		"vor der Zielwahl": base,
		"nach Zielwahl und Berechnung": base + 1,
		"nach Übersteuerung": base + 2,
		"nach Gezeigt": base + 3,
	}
	for label: String in points:
		var n: int = points[label]
		var prefix := full.slice(0, n)
		var loaded := _load_roundtrip(prefix, label)
		if loaded == null:
			continue
		assert_eq(_stage(loaded.state), _stage(Fixtures.play(prefix)), "%s: dieselbe Stufe" % label)
		_continue_both(Fixtures.play(prefix), loaded.state, full.slice(n), label)


func test_replay_with_and_without_override() -> void:
	# 30, 31, AS-R14
	for override_role: String in ["", "dorfbewohner"]:
		var label := "mit Übersteuerung" if override_role != "" else "ohne Übersteuerung"
		var commands := _check(1, override_role)
		commands.append(Command.end_night())
		var a := RulesEngine.replay(commands)
		var b := RulesEngine.replay(commands)
		assert_true(a.ok and b.ok, "%s: Replay angenommen (%s @ %d)" % [label, a.error, a.failed_index])
		assert_eq(events_json(a.events), events_json(b.events), "%s: Ereignisse bytegleich" % label)
		assert_eq(_json(a.state.to_dict()), _json(b.state.to_dict()), "%s: Zustand bytegleich" % label)
		assert_eq(a.state.content_hash(), b.state.content_hash(), "%s: State-Hash" % label)
		assert_eq(a.state.rng.to_dict(), Fixtures.play([_o6()] as Array[Command]).rng.to_dict(), "%s: keine Zufallsziehung" % label)


# --- 32–34 Sichtbarkeit ------------------------------------------------------------------

func test_actor_event_contains_only_shown() -> void:
	# 32, 33
	var run := _replay_ok(_check(1, "dorfbewohner"), "Übersteuerte Prüfung")
	if not run.ok:
		return
	var revealed := events_of_type(run.events, "InfoRevealed")
	assert_eq(revealed.size(), 1, "ein Ereignis für das Orakel")
	if revealed.size() == 1:
		var e := revealed[0]
		assert_eq(String(e.visibility), "actor", "nur handelnde Person")
		assert_eq(e.actor_id, 4, "Orakel")
		var keys: Array = e.data.keys()
		keys.sort()
		assert_eq(keys, ["info_id", "night", "shown_role", "target_id"], "nur gezeigtes Ergebnis und Bezug")
		assert_eq(str(e.data["shown_role"]), "dorfbewohner", "gezeigtes Ergebnis")
		assert_false(_json(e.data).contains("werwolf"), "keine Wahrheit hinter der Übersteuerung")
	var audit := events_of_type(run.events, "InfoRecorded")
	assert_eq(audit.size(), 1, "ein Audit-Ereignis")
	if audit.size() == 1:
		assert_eq(String(audit[0].visibility), "gm", "nur Spielleiter")
		var rec: Dictionary = audit[0].data["info"]
		assert_true(str(rec["truth_role"]) == "werwolf" and str(rec["determined_role"]) == "werwolf" and str(rec["shown_role"]) == "dorfbewohner"
			and bool(rec["overridden"]) and str(rec["override_reason"]) == "Spielleiter übersteuert", "vollständiger interner Datensatz")
	for e: GameEvent in run.events:
		if e.visibility == &"actor" and e.actor_id == 4:
			assert_false(_json(e.data).contains("werwolf"), "%s: kein Wolfswissen für das Orakel" % e.type)


func test_no_oracle_information_in_public_events() -> void:
	# 34
	var run := _replay_ok(_concat(_check(1, "dorfbewohner"), [Command.end_night(), Command.decide_execution(-1), Command.end_day()] as Array[Command]), "Partie")
	if not run.ok:
		return
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			assert_eq(_find_forbidden(e.data), "", "öffentliches %s ohne Orakelinformation" % e.type)
			assert_false(_contains_int(e.data, 4), "öffentliches %s ohne Orakel-ID" % e.type)
		elif e.visibility == &"actor":
			assert_true(e.actor_id >= 1, "%s adressiert eine Person" % e.type)
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")
	for type: String in ["PromptOpened", "PromptStageAnswered", "InfoOverridden", "InfoRecorded", "PromptAnswered"]:
		for e: GameEvent in events_of_type(run.events, type):
			assert_eq(String(e.visibility), "gm", "%s nur für Spielleiter" % type)


# --- 35–36 Erscheinung und Waldhexe ---------------------------------------------------------

func test_witch_rescue_still_true_role() -> void:
	# 35: Orakel 4 erscheint als werwolf, wird Rudelopfer und von der Waldhexe gerettet.
	var s := Fixtures.play([_b6(), CorrectionFixtures.gm("set_role_field", {"target_id": 4, "field": "appears_as", "value": "werwolf"}, "Testaufbau"),
		Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1), Command.answer_prompt(2, [4]),
		Command.begin_step("night:1:2:waldhexe:5"), Command.answer_choice(3, "heal", true)] as Array[Command])
	assert_true(s != null and s.pending_prompt != null, "Waldhexe hat gerettet")
	if s != null and s.pending_prompt != null:
		assert_eq(str(s.pending_prompt.partial.get("victim_role", "")), "das-orakel", "tatsächliche Rolle, nicht appears_as")


func test_corrected_appearance_affects_later_checks() -> void:
	# 36: Nacht 1 prüft 5 (dorfbewohner); am Tag erscheint 5 als werwolf; Nacht 2 prüft erneut.
	var commands := _concat(_check(5), [Command.end_night(),
		CorrectionFixtures.gm("set_role_field", {"target_id": 5, "field": "appears_as", "value": "werwolf"}, "Scheinrolle korrigiert"),
		Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.answer_prompt(4, [6]),
		Command.begin_step("night:2:1:pack"), Command.answer_prompt(5, []), Command.begin_step("night:2:2:das-orakel:4"),
		_target(5, 6), _shown(6)] as Array[Command])
	var run := _replay_ok(commands, "zwei Nächte")
	if not run.ok:
		return
	var records := _records(run.state)
	assert_eq(records.size(), 2, "zwei Informationen")
	if records.size() == 2:
		assert_eq(str(records[0]["determined_role"]), "dorfbewohner", "Nacht 1")
		assert_true(str(records[1]["determined_role"]) == "werwolf" and str(records[1]["truth_role"]) == "dorfbewohner", "Nacht 2 nach Korrektur")
	var again := RulesEngine.replay(commands)
	assert_eq(events_json(again.events), events_json(run.events), "deterministisch")


# --- 37–38 Beschädigte Zustände -------------------------------------------------------------

func _tampered(commands: Array[Command], mutate: Callable) -> LoadResult:
	var state := Fixtures.play(commands)
	var doc: Dictionary = CanonicalJson.normalize(JSON.parse_string(StateCodec.encode(state, commands)))
	var body: Dictionary = doc["state"]
	mutate.call(body)
	var hashed := body.duplicate(true)
	for key: String in GameState.HASH_EXCLUDED_KEYS:
		hashed.erase(key)
	doc["state_hash"] = CanonicalJson.sha256(hashed)
	doc.erase("integrity")
	doc["integrity"] = CanonicalJson.sha256(doc)
	return StateCodec.decode(CanonicalJson.stringify(doc))


func _expect_state_invalid(result: LoadResult, label: String) -> void:
	assert_false(result.ok, "%s: nicht geladen" % label)
	assert_eq(String(result.error), "state_invalid", "%s: Fehlergrund" % label)
	assert_true(result.state == null, "%s: kein teilweise geladener Zustand" % label)


func test_corrupt_prompt_states_rejected() -> void:
	# 37
	var at_target := _to_oracle()
	var at_shown := _concat(_to_oracle(), [_target(5)] as Array[Command])
	var control := _tampered(at_shown, func(st: Dictionary) -> void: st["players"][0]["name"] = "Z")
	assert_eq(String(control.error), "replay_mismatch", "Kontrolle: Hash und Integrität werden passiert")
	var cases := {
		"unbekanntes Orakel": [at_target, func(st: Dictionary) -> void: st["pending_prompt"]["actor_id"] = 99],
		"nicht mehr Orakel": [at_target, func(st: Dictionary) -> void:
			st["players"][3]["role_id"] = "dorfbewohner"
			st["players"][3]["appears_as"] = "dorfbewohner"],
		"unbekanntes Ziel": [at_shown, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["target_id"] = 99],
		"totes Ziel": [at_shown, func(st: Dictionary) -> void: st["players"][4]["alive"] = false],
		"Selbstziel": [at_shown, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["target_id"] = 4],
		"Wahrheit passt nicht": [at_shown, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["truth_role"] = "schutzengel"],
		"ermittelt widerspricht Regel": [at_shown, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["determined_role"] = "werwolf"],
		"gezeigt fehlt": [at_shown, func(st: Dictionary) -> void: (st["pending_prompt"]["partial"] as Dictionary).erase("shown_role")],
		"Übersteuerung ohne Grund": [at_shown, func(st: Dictionary) -> void:
			st["pending_prompt"]["partial"]["shown_role"] = "werwolf"
			st["pending_prompt"]["partial"]["overridden"] = true
			st["pending_prompt"]["partial"]["override_reason"] = ""],
		"Stufe ohne Werte": [at_target, func(st: Dictionary) -> void: st["pending_prompt"]["stage"] = "shown"],
		"Step-ID andere Nacht": [at_target, func(st: Dictionary) -> void: st["pending_prompt"]["step_id"] = "night:2:2:das-orakel:4"],
		"Nacht widerspricht": [at_target, func(st: Dictionary) -> void: st["night_number"] = 2],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		_expect_state_invalid(_tampered(commands, cases[label][1]), label)


func test_corrupt_info_records_rejected() -> void:
	# 38
	var done := _check(5)
	var cases := {
		"unbekanntes Orakel": func(st: Dictionary) -> void: st["info_records"][0]["oracle_id"] = 99,
		"unbekanntes Ziel": func(st: Dictionary) -> void: st["info_records"][0]["target_id"] = 99,
		"unbekannte Wahrheit": func(st: Dictionary) -> void: st["info_records"][0]["truth_role"] = "unbekannt",
		"unbekannt ermittelt": func(st: Dictionary) -> void: st["info_records"][0]["determined_role"] = "",
		"unbekannt gezeigt": func(st: Dictionary) -> void: st["info_records"][0]["shown_role"] = "nicht-im-katalog",
		"Übersteuerung ohne Grund": func(st: Dictionary) -> void: st["info_records"][0]["overridden"] = true,
	}
	for label: String in cases:
		_expect_state_invalid(_tampered(done, cases[label]), label)


# --- Hilfen Leak-Test ------------------------------------------------------------------------

func _contains_int(value: Variant, needle: int) -> bool:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			if _contains_int(value[k], needle):
				return true
	elif value is Array:
		for v: Variant in (value as Array):
			if _contains_int(v, needle):
				return true
	elif DictRead.is_int_like(value):
		return int(value) == needle
	return false


func _find_forbidden(value: Variant) -> String:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			var hit := _match(String(k))
			if hit == "":
				hit = _find_forbidden(value[k])
			if hit != "":
				return hit
	elif value is Array:
		for v: Variant in (value as Array):
			var hit := _find_forbidden(v)
			if hit != "":
				return hit
	elif value is String or value is StringName:
		return _match(String(value))
	return ""


func _match(text: String) -> String:
	for bad: String in FORBIDDEN_PUBLIC:
		if text.to_lower().contains(bad):
			return "%s (%s)" % [text, bad]
	return ""
