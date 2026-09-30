extends TestCase
## Produktionsrolle `manipulator` (rules-register.md §10, DR-12) und Kandidatenmenge (DR-02, DR-14).
## MA6:   1 Werwolf; 2 Manipulator; 3–6 Dorfbewohner.
## MA6WR: 1, 2 Werwölfe; 3 Manipulator; 4 Sensenträger; 5, 6 Dorfbewohner.
##        Parität und Manipulator gleichzeitig entstehen über eine Reaktionskette am Tag
##        (bei vier Lebenden wäre sonst bereits 2:2 Parität).
## MA6MM: 1 Werwolf; 2, 3 Manipulatoren; 4–6 Dorfbewohner.
## MA6R:  1 Werwolf; 2 Manipulator; 3 Sensenträger; 4–6 Dorfbewohner.
## Kandidaten und Nominierungsstatus werden über die Serialisierung gelesen
## (`win_candidates`, `players[].ever_nominated`).

const MANIPULATOR_REASON := "manipulator_three_alive"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles)


func _ma6() -> Command:
	return _start(["werwolf", "manipulator", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])


func _ma6wr() -> Command:
	return _start(["werwolf", "blutwolf", "manipulator", "sensentraeger", "dorfbewohner", "amalia"])


## Tag 1: 6 stirbt, Sensenträger 4 stirbt, sein Fluch trifft 5 → 1, 2, 3 leben:
## Kandidaten Wolfsparität (ID 1) und Manipulator 3 (ID 2).
func _parity_and_solo() -> Array[Command]:
	return _concat(_to_day(_ma6wr()), [_kill(6), _kill(4), Command.begin_step("reaction:1"), Command.answer_prompt(2, [5])] as Array[Command])


## Zwei Manipulatoren (3 ist eine Kopie, PE-07: entsteht nach dem Start durch Korrektur), danach die Tode `ids`.
func _ma6mm_kills(ids: Array) -> Array[Command]:
	var kills: Array[Command] = []
	for id: Variant in ids:
		kills.append(_kill(int(id)))
	return Fixtures.with_copies(["werwolf", "manipulator", "manipulator", "dorfbewohner", "amalia", "detektiv"], kills)


func _ma6r() -> Command:
	return _start(["werwolf", "manipulator", "sensentraeger", "dorfbewohner", "amalia", "detektiv"])


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## Nacht 1 ohne Opfer, danach Tag 1 (nur Rudelschritt im Nachtplan).
func _to_day(start: Command) -> Array[Command]:
	return [start, Command.start_night(), Command.answer_prompt(1, []), Command.end_night()]


func _gm(kind: String, fields: Dictionary, reason: String = "Korrektur am Tisch") -> Command:
	return CorrectionFixtures.gm(kind, fields, reason)


func _kill(id: int) -> Command:
	return _gm("kill", {"target_id": id, "trigger_effects": true})


func _kills(start: Command, ids: Array) -> Array[Command]:
	var out: Array[Command] = [start]
	for id: Variant in ids:
		out.append(_kill(int(id)))
	return out


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _candidates(s: GameState, status: String = "open") -> Array:
	var out: Array = []
	for c: Variant in s.to_dict().get("win_candidates", []):
		if str((c as Dictionary).get("status", "")) == status:
			out.append(c)
	return out


## Kompakte Beschreibung offener Kandidaten: "kind:reason:[begünstigte]".
func _describe(s: GameState) -> Array[String]:
	var out: Array[String] = []
	for c: Variant in _candidates(s):
		var d: Dictionary = c
		out.append("%s:%s:%s" % [d["kind"], d["reason_key"], _json(d.get("beneficiary_ids", []))])
	return out


func _ever(s: GameState, id: int) -> Variant:
	for p: Variant in s.to_dict()["players"]:
		if int((p as Dictionary)["id"]) == id:
			return (p as Dictionary).get("ever_nominated")
	return null


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


func _reject_all(reason: String = "Spiel geht weiter") -> Command:
	return Command.create(Command.REJECT_WIN, {"reason": reason})


# --- 1–5 Rolle -----------------------------------------------------------------------------------

func test_production_role() -> void:
	# 1, 2, 3
	var r := apply_ok(GameState.new(), _ma6(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	var p := r.state.players[2]
	assert_true(p.role_id == &"manipulator" and p.faction == &"solo" and not p.counts_as_wolf and p.appears_as == &"manipulator", "Rollenfelder")
	assert_eq(_ever(r.state, 2), false, "nie nominiert")
	var n := _replay_ok([_ma6(), Command.start_night()] as Array[Command], "Nacht 1")
	if n.ok:
		assert_eq(n.state.night_plan, [&"pack"] as Array[StringName], "kein Nachtschritt")


func test_oracle_and_witch() -> void:
	# 4, 5
	var start := _start(["werwolf", "manipulator", "dorfbewohner", "das-orakel", "waldhexe", "amalia"])
	var o := Fixtures.play([start, Command.start_night(), Command.answer_prompt(1, []), Command.begin_step("night:1:1:waldhexe:5"),
		Command.answer_choice(2, "poison", false), Command.answer_choice(2, "confirm", true), Command.begin_step("night:1:2:das-orakel:4"),
		Command.answer_stage_targets(3, "target", [2])] as Array[Command])
	assert_true(o != null and o.pending_prompt != null and str(o.pending_prompt.partial["determined_role"]) == "manipulator", "Orakel ermittelt manipulator")
	var w := Fixtures.play([start, Command.start_night(), Command.answer_prompt(1, [2]), Command.begin_step("night:1:1:waldhexe:5"),
		Command.answer_choice(2, "heal", true)] as Array[Command])
	assert_true(w != null and w.pending_prompt != null and str(w.pending_prompt.partial["victim_role"]) == "manipulator", "Waldhexe sieht manipulator")


# --- 6–17 Nominierungstod und Status ---------------------------------------------------------------

func test_nomination_kills_manipulator() -> void:
	# 6–11, AS-R24
	var s := Fixtures.play(_to_day(_ma6()))
	var r := apply_ok(s, Command.nominate(3, 2), "Nominierung des Manipulators")
	assert_eq(r.state.nominations.size(), 1, "6: Nominierung gespeichert")
	assert_eq(_ever(r.state, 2), true, "7: jemals nominiert")
	var recorded := events_of_type(r.events, "NominationRecorded")
	var died := events_of_type(r.events, "SeatDied")
	assert_true(recorded.size() == 1 and died.size() == 1 and recorded[0].index < died[0].index, "Nominierung vor dem Tod")
	var p := r.state.players[2]
	assert_false(p.alive, "8: stirbt sofort")
	if p.death != null:
		assert_eq(String(p.death.cause), "MANIPULATOR_NOMINATED", "8: Ursache")
		assert_true(String(p.death.source_kind) == "player" and int(p.death.source_id) == 3, "9: Quelle nominierende Person")
	assert_true(r.state.phase == &"DAY" and r.state.day_step == &"NOMINATION", "10: Tag bleibt aktiv")
	apply_ok(r.state, Command.nominate(4, 5), "11: weitere Nominierung")


func test_execution_is_lynch() -> void:
	# 12, 13
	var fresh := apply_ok(Fixtures.play(_to_day(_ma6())), _gm("execute", {"target_id": 2}), "Hinrichtung ohne Nominierung")
	assert_eq(String(fresh.state.players[2].death.cause), "LYNCH", "12: nur LYNCH")
	assert_eq(_ever(fresh.state, 2), false, "Hinrichtung ist keine Nominierung")
	var revived := Fixtures.play(_concat(_to_day(_ma6()), [Command.nominate(3, 2), _gm("revive", {"target_id": 2})] as Array[Command]))
	var r := apply_ok(revived, Command.decide_execution(2), "13: Hinrichtung nach Wiederbelebung")
	assert_eq(String(r.state.players[2].death.cause), "LYNCH", "13: normale Hinrichtung")


func test_nomination_death_transforms_wolf_child() -> void:
	# 14
	var start := _start(["werwolf", "manipulator", "dorfbewohner", "amalia", "detektiv", "wolfskind"])
	var run := _replay_ok([start, Command.start_night(), Command.answer_prompt(1, [2]), Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, []),
		Command.end_night(), Command.nominate(3, 2)] as Array[Command], "Wolfskind")
	if run.ok:
		assert_true(run.state.players[6].counts_as_wolf, "Wolfskind verwandelt")


func test_nominated_revived_never_candidate() -> void:
	# 15, 20
	var run := _replay_ok(_concat(_to_day(_ma6()), [Command.nominate(3, 2), _gm("revive", {"target_id": 2}), _kill(4), _kill(5), _kill(6)] as Array[Command]), "drei Lebende")
	if not run.ok:
		return
	assert_eq(run.state.alive_ids(), [1, 2, 3] as Array[int], "genau drei leben")
	assert_eq(_describe(run.state), [] as Array[String], "kein Solo-Kandidat nach Nominierung")
	var again := apply_ok(Fixtures.play(_concat(_to_day(_ma6()), [Command.nominate(3, 2), _gm("revive", {"target_id": 2}), Command.decide_execution(-1),
		Command.end_day(), Command.start_night(), Command.answer_prompt(2, []), Command.end_night()] as Array[Command])), Command.nominate(4, 2), "erneute Nominierung")
	assert_eq(String(again.state.players[2].death.cause), "MANIPULATOR_NOMINATED", "stirbt erneut durch Nominierung")


func test_status_survives_role_changes() -> void:
	# 16, 17
	var start := _start(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	var commands := _concat(_to_day(start), [Command.nominate(3, 2), _gm("set_role", {"target_id": 2, "role_id": "manipulator"})] as Array[Command])
	var s := Fixtures.play(commands)
	assert_eq(_ever(s, 2), true, "17: vor der Rolle nominiert")
	assert_true(s.players[2].faction == &"solo" and not s.players[2].counts_as_wolf and s.players[2].appears_as == &"manipulator", "Rollenwechsel zum Manipulator")
	var away := apply_ok(s, _gm("set_role", {"target_id": 2, "role_id": "dorfbewohner"}), "weg").state
	var back := apply_ok(away, _gm("set_role", {"target_id": 2, "role_id": "manipulator"}), "zurück").state
	assert_eq(_ever(back, 2), true, "16: Status bleibt über Rollenwechsel")
	var three := _replay_ok(_concat(commands, [_kill(4), _kill(5), _kill(6)] as Array[Command]), "drei Lebende")
	if three.ok:
		assert_eq(_describe(three.state), [] as Array[String], "17: nicht siegberechtigt")


# --- 18–26 Kandidaten ---------------------------------------------------------------------------------

func test_exactly_three_alive() -> void:
	# 18, 19, 20, AS-R25
	var four := _replay_ok(_kills(_ma6(), [3, 4]), "vier Lebende")
	if four.ok:
		assert_eq(_describe(four.state), [] as Array[String], "19: vier Lebende")
	var three := _replay_ok(_kills(_ma6(), [3, 4, 5]), "drei Lebende")
	if not three.ok:
		return
	assert_eq(_describe(three.state), ["solo:%s:[2]" % MANIPULATOR_REASON] as Array[String], "18: Solo-Kandidat für Person 2")
	var c: Dictionary = _candidates(three.state)[0]
	assert_true(int(c["id"]) >= 1 and int(c["detected_at_command"]) == 3 and int(c["resolved_at_command"]) == -1, "Kandidatendaten")
	var two := _replay_ok(_concat(_kills(_ma6(), [3, 4, 5]), [_reject_all(), _kill(6)] as Array[Command]), "zwei Lebende")
	if two.ok:
		assert_eq(_describe(two.state), ["wolves:wolf_parity:[]"] as Array[String], "20: bei zwei Lebenden nur Parität")


func test_jump_from_four_to_two() -> void:
	# 21, 22, AS-R26, AS-R36
	var s := Fixtures.play(_concat(_to_day(_ma6r()), [_kill(5), _kill(6)] as Array[Command]))
	assert_eq(s.alive_ids(), [1, 2, 3, 4] as Array[int], "vier leben")
	var r := apply_ok(s, _kill(3), "Sensenträger stirbt")
	var prov := events_of_type(r.events, "WinStatusProvisional")
	assert_true(prov.size() == 1 and _json(prov[0].data).contains(MANIPULATOR_REASON), "22: vorläufig Manipulator bei drei")
	assert_eq(events_of_type(r.events, "WinStatusFinal").size(), 0, "keine verbindliche Prüfung bei offener Reaktion")
	assert_eq(_describe(r.state), [] as Array[String], "keine Kandidaten bei offener Reaktion")
	var begun := apply_ok(r.state, Command.begin_step("reaction:1"), "Reaktion").state
	var curse := apply_ok(begun, Command.answer_prompt(2, [4]), "Fluch auf 4")
	var prov2 := events_of_type(curse.events, "WinStatusProvisional")
	assert_true(prov2.size() == 1 and not _json(prov2[0].data).contains(MANIPULATOR_REASON), "22: Bedingung verschwindet")
	assert_eq(_describe(curse.state), ["wolves:wolf_parity:[]"] as Array[String], "21: kein endgültiger Manipulator-Kandidat")


func test_simultaneous_candidates() -> void:
	# 23, 24, 25, 26, AS-R34
	var cases := {
		"Manipulator und Parität": [_parity_and_solo(), ["wolves:wolf_parity:[]", "solo:%s:[3]" % MANIPULATOR_REASON]],
		"Manipulator und Dorf": [_kills(_ma6(), [3, 4, 1]), ["village:no_wolves_alive:[]", "solo:%s:[2]" % MANIPULATOR_REASON]],
		"zwei Manipulatoren": [_ma6mm_kills([4, 5, 6]), ["solo:%s:[2]" % MANIPULATOR_REASON, "solo:%s:[3]" % MANIPULATOR_REASON]],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var a := _replay_ok(commands, label)
		if not a.ok:
			continue
		var expected: Array[String] = []
		expected.assign(cases[label][1])
		assert_eq(_describe(a.state), expected, "%s: Kandidaten in stabiler Reihenfolge" % label)
		var ids: Array = []
		for c: Variant in _candidates(a.state):
			ids.append(int((c as Dictionary)["id"]))
		assert_eq(ids.size(), expected.size(), "%s: eigene IDs" % label)
		assert_eq(events_of_type(a.events, "WinDetected").size(), expected.size(), "%s: je Kandidat ein Ereignis" % label)
		var b := RulesEngine.replay(commands)
		assert_eq(events_json(b.events), events_json(a.events), "%s: deterministisch" % label)
		apply_rejected(a.state, Command.end_night(), "win_candidate_open", "%s: blockiert andere Befehle" % label)


func test_confirm_one_of_many() -> void:
	# 27, 28, 29
	var s := Fixtures.play(_parity_and_solo())
	var open := _candidates(s)
	assert_eq(open.size(), 2, "zwei offen")
	if open.size() != 2:
		return
	var solo_id := int((open[1] as Dictionary)["id"])
	apply_rejected(s, Command.confirm_win(99), "win_candidate_mismatch", "unbekannte Kandidaten-ID")
	var r := apply_ok(s, Command.confirm_win(solo_id), "Manipulator bestätigen")
	assert_eq(String(r.state.phase), "GAME_OVER", "Spielende")
	var confirmed := _candidates(r.state, "confirmed")
	assert_true(confirmed.size() == 1 and int((confirmed[0] as Dictionary)["id"]) == solo_id and (confirmed[0] as Dictionary)["beneficiary_ids"] == [3], "29: konkrete Person")
	var others := _candidates(r.state, "not_chosen")
	assert_true(others.size() == 1 and int((others[0] as Dictionary)["resolved_at_command"]) == s.command_count, "28: übriger Kandidat nachvollziehbar geschlossen")
	assert_eq(_candidates(r.state).size(), 0, "nichts mehr offen")
	assert_eq(int(r.state.to_dict()["winner_id"]), solo_id, "Gewinner verweist auf den bestätigten Kandidaten")
	assert_eq(events_of_type(r.events, "WinConfirmed").size(), 1, "ein Siegereignis")


func test_reject_all_together() -> void:
	# 30, 31, 32
	var s := Fixtures.play(_parity_and_solo())
	var first := int((_candidates(s)[0] as Dictionary)["id"])
	apply_rejected(s, Command.reject_win(first, ""), "reason_required", "ohne Grund")
	apply_rejected(s, Command.reject_win(99, "x"), "win_candidate_mismatch", "fremde ID")
	var r := apply_ok(s, Command.reject_win(first, "Tisch spielt weiter"), "gemeinsam ablehnen (kompatibel mit ID)")
	assert_eq(_candidates(r.state).size(), 0, "keiner bleibt offen")
	var rejected := _candidates(r.state, "rejected")
	assert_eq(rejected.size(), 2, "beide abgelehnt")
	for c: Variant in rejected:
		assert_eq(str((c as Dictionary)["rejection_reason"]), "Tisch spielt weiter", "Grund gespeichert")
	var next := apply_ok(r.state, Command.decide_execution(-1), "32: Partie läuft weiter")
	assert_eq(_candidates(next.state).size(), 0, "32: kein sofortiges Wiederangebot")
	var without_id := apply_ok(s, _reject_all(), "ohne Kandidaten-ID")
	assert_eq(_candidates(without_id.state, "rejected").size(), 2, "auch ohne ID alle abgelehnt")


func test_nobody_alive_and_declare_winner() -> void:
	# 33, 34, AS-R35
	var start := _start(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	var commands: Array[Command] = [start, _kill(2), _kill(3), _kill(4), _kill(5), _reject_all(), _kill(6), _reject_all(), _kill(1)]
	var run := _replay_ok(commands, "niemand lebt")
	if not run.ok:
		return
	assert_eq(run.state.alive_ids().size(), 0, "niemand lebt")
	assert_eq(_candidates(run.state).size(), 0, "33: kein Kandidat")
	var final_events := events_of_type(RulesEngine.apply(Fixtures.play(commands.slice(0, commands.size() - 1)), commands[commands.size() - 1]).events, "WinStatusFinal")
	assert_true(final_events.size() == 1 and bool(final_events[0].data["requires_gm_decision"]), "Spielleiter entscheidet")
	var declared := apply_ok(run.state, _gm("declare_winner", {"winner_kind": "village"}), "34: Siegerklärung")
	assert_eq(String(declared.state.phase), "GAME_OVER", "Spielende")
	var confirmed := _candidates(declared.state, "confirmed")
	assert_true(confirmed.size() == 1 and str((confirmed[0] as Dictionary)["reason_key"]) == "gm_declared", "erklärter Sieger")


# --- 35–37 Statuskorrektur --------------------------------------------------------------------------------

func test_set_ever_nominated() -> void:
	# 35, 36, 37
	var base := _concat(_to_day(_ma6()), [Command.nominate(3, 2), _gm("revive", {"target_id": 2}), _kill(4), _kill(5), _kill(6)] as Array[Command])
	var s := Fixtures.play(base)
	assert_eq(_describe(s), [] as Array[String], "ohne Kandidat")
	var off := apply_ok(s, _gm("set_ever_nominated", {"target_id": 2, "value": false}, "Nominierung war ungültig"), "36: auf false")
	assert_eq(_ever(off.state, 2), false, "korrigiert")
	var log1 := events_of_type(off.events, "GmCorrected")
	assert_true(log1.size() == 1 and log1[0].data["old"] == {"ever_nominated": true} and log1[0].data["new"] == {"ever_nominated": false}, "alt und neu")
	assert_eq(_describe(off.state), ["solo:%s:[2]" % MANIPULATOR_REASON] as Array[String], "37: Kandidat hinzugefügt")
	assert_eq(off.state.nominations.size(), 1, "historische Nominierung bleibt")
	var rejected := apply_ok(off.state, _reject_all(), "ablehnen").state
	var on := apply_ok(rejected, _gm("set_ever_nominated", {"target_id": 2, "value": true}), "35: auf true")
	assert_eq(_ever(on.state, 2), true, "wieder nominiert")
	assert_eq(_describe(on.state), [] as Array[String], "37: Kandidat entfällt")
	apply_rejected(on.state, _gm("set_ever_nominated", {"target_id": 2, "value": true}), "no_change", "unverändert")
	apply_rejected(on.state, _gm("set_ever_nominated", {"target_id": 99, "value": true}), "unknown_player", "unbekannt")
	apply_rejected(on.state, _gm("set_ever_nominated", {"target_id": 2, "value": "ja"}), "invalid_correction", "kein Wahrheitswert")
	apply_rejected(on.state, Command.gm_correction({"kind": "set_ever_nominated", "target_id": 2, "value": false, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(on.state, _gm("set_ever_nominated", {"target_id": 2, "value": false}, ""), "reason_required", "ohne Begründung")


# --- 38–46 Save/Load und Replay --------------------------------------------------------------------------

func _roundtrip(commands: Array[Command], label: String) -> LoadResult:
	var run := _replay_ok(commands, label)
	if not run.ok:
		return null
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Laden (%s %s)" % [label, loaded.error, loaded.detail])
	if not loaded.ok:
		return null
	assert_eq(_json(loaded.state.to_dict()), _json(run.state.to_dict()), "%s: vollständiger Zustand" % label)
	assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: State-Hash" % label)
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(run.events), "%s: Replay bytegleich" % label)
	return loaded


func test_save_load_and_replay() -> void:
	var two := _parity_and_solo()
	var cases := {
		"nach Nominierungstod": [_concat(_to_day(_ma6()), [Command.nominate(3, 2)] as Array[Command]), Command.nominate(4, 5)],
		"mehrere offene Kandidaten": [two, Command.confirm_win(2)],
		"nach Manipulator-Sieg": [_concat(two, [Command.confirm_win(2)] as Array[Command]), null],
		"nach gemeinsamer Ablehnung": [_concat(two, [_reject_all()] as Array[Command]), Command.decide_execution(-1)],
		"nach Statuskorrektur": [_concat(_kills(_ma6(), [3, 4]), [_gm("set_ever_nominated", {"target_id": 2, "value": true})] as Array[Command]), _kill(5)],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var loaded := _roundtrip(commands, label)
		if loaded == null or cases[label][1] == null:
			continue
		var next: Command = cases[label][1]
		var a := RulesEngine.apply(Fixtures.play(commands), next)
		var b := RulesEngine.apply(loaded.state, next)
		assert_true(a.ok and b.ok, "%s: Fortsetzung angenommen (%s)" % [label, a.error])
		assert_eq(events_json(b.events), events_json(a.events), "%s: identische Fortsetzung" % label)
		assert_eq(_json(b.state.to_dict()), _json(a.state.to_dict()), "%s: identischer Endzustand" % label)
	var won := Fixtures.play(_concat(two, [Command.confirm_win(2)] as Array[Command]))
	assert_true(won != null and (_candidates(won, "confirmed")[0] as Dictionary)["beneficiary_ids"] == [3], "bestätigter Manipulator nach Replay")


# --- AS-E01 Beispielrunde ------------------------------------------------------------------------------

func test_as_e01_full_round() -> void:
	# A werwolf, B trugbilderwolf (Scheinrolle schutzengel), C schutzengel, D das-orakel, E waldhexe, G sensentraeger, M manipulator.
	var payload := Fixtures.start_roles(["werwolf", "trugbilderwolf", "schutzengel", "das-orakel", "waldhexe", "sensentraeger", "manipulator"], 4711).payload.duplicate(true)
	payload["appearances"] = {"2": "schutzengel"}
	var commands: Array[Command] = [Command.start_game(payload), Command.start_night(),
		Command.answer_prompt(1, [4]),                                    # C schützt D
		Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, [6]),  # Rudel wählt G
		Command.begin_step("night:1:2:waldhexe:5"), Command.answer_choice(3, "heal", false), Command.answer_choice(3, "poison", false),
		Command.answer_choice(3, "confirm", true),                        # E sieht G und verzichtet
		Command.begin_step("night:1:3:das-orakel:4"), Command.answer_stage_targets(4, "target", [2]), Command.answer_choice(4, "shown", true),
		Command.end_night(), Command.begin_step("reaction:1"), Command.answer_prompt(5, [1]),  # G stirbt, verflucht A
		Command.nominate(4, 2), Command.decide_execution(2)]              # D nominiert B, Hinrichtung B
	var run := _replay_ok(commands, "AS-E01")
	if not run.ok:
		return
	var records: Array = run.state.to_dict()["info_records"]
	assert_true(records.size() == 1 and str((records[0] as Dictionary)["shown_role"]) == "schutzengel", "D erhält die Scheinrolle")
	assert_eq(run.state.alive_ids(), [3, 4, 5, 7] as Array[int], "C, D, E, M leben")
	assert_eq(_describe(run.state), ["village:no_wolves_alive:[]"] as Array[String], "nur Dorf, kein Manipulator bei vier Lebenden")
	var won := apply_ok(run.state, Command.confirm_win(int((_candidates(run.state)[0] as Dictionary)["id"])), "ConfirmWin")
	assert_eq(String(won.state.phase), "GAME_OVER", "Spielende")
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(run.events), "gleiche Eventliste bei Wiederholung")


# --- 47–51 Beschädigte Zustände ---------------------------------------------------------------------------

func _tampered(commands: Array[Command], mutate: Callable) -> LoadResult:
	var doc: Dictionary = CanonicalJson.normalize(JSON.parse_string(StateCodec.encode(Fixtures.play(commands), commands)))
	var body: Dictionary = doc["state"]
	mutate.call(body)
	var hashed := body.duplicate(true)
	for key: String in GameState.HASH_EXCLUDED_KEYS:
		hashed.erase(key)
	doc["state_hash"] = CanonicalJson.sha256(hashed)
	doc.erase("integrity")
	doc["integrity"] = CanonicalJson.sha256(doc)
	return StateCodec.decode(CanonicalJson.stringify(doc))


func test_corrupt_states_rejected() -> void:
	var two := _parity_and_solo()
	var won := _concat(two, [Command.confirm_win(2)] as Array[Command])
	var rejected := _concat(two, [_reject_all()] as Array[Command])
	var control := _tampered(two, func(st: Dictionary) -> void: st["players"][0]["name"] = "Z")
	assert_eq(String(control.error), "replay_mismatch", "Kontrolle: Hash und Integrität werden passiert")
	var reaction := {"id": 1, "kind": "curse", "owner_id": 4, "trigger_order": 1}
	var prompt := {"id": 9, "kind": "pick_players", "owner": "pack", "actor_id": -1, "min_count": 0, "max_count": 1, "allowed_ids": [1, 2, 3],
		"partial": {}, "cancellable": true, "step_id": "night:1:0:pack", "stage": ""}
	var cases := {
		"ever_nominated kein Wahrheitswert": [two, func(st: Dictionary) -> void: st["players"][0]["ever_nominated"] = "ja"],
		"unbekannte begünstigte Person": [two, func(st: Dictionary) -> void: st["win_candidates"][1]["beneficiary_ids"] = [99]],
		"Manipulator-Kandidat für Nicht-Manipulator": [two, func(st: Dictionary) -> void: st["win_candidates"][1]["beneficiary_ids"] = [1]],
		"Manipulator-Kandidat für tote Person": [two, func(st: Dictionary) -> void: st["win_candidates"][1]["beneficiary_ids"] = [4]],
		"Manipulator-Kandidat bei vier Lebenden": [two, func(st: Dictionary) -> void: st["players"][3]["alive"] = true],
		"doppelte Kandidaten-ID": [two, func(st: Dictionary) -> void: st["win_candidates"][1]["id"] = st["win_candidates"][0]["id"]],
		"doppelter semantischer Kandidat": [two, func(st: Dictionary) -> void:
			var copy: Dictionary = (st["win_candidates"][1] as Dictionary).duplicate(true)
			copy["id"] = 3
			(st["win_candidates"] as Array).append(copy)],
		"mehrere bestätigte Kandidaten": [won, func(st: Dictionary) -> void: st["win_candidates"][0]["status"] = "confirmed"],
		"Gewinner passt nicht": [won, func(st: Dictionary) -> void: st["winner_id"] = st["win_candidates"][0]["id"]],
		"offene Kandidaten neben Prompt": [two, func(st: Dictionary) -> void: st["pending_prompt"] = prompt],
		"offene Kandidaten neben Reaktion": [two, func(st: Dictionary) -> void: st["reactions"] = [reaction]],
		"offene Kandidaten in GAME_OVER": [two, func(st: Dictionary) -> void: st["phase"] = "GAME_OVER"],
		"Gewinner außerhalb GAME_OVER": [won, func(st: Dictionary) -> void: st["phase"] = "SETUP"],
		"abgelehnt als offen gespeichert": [rejected, func(st: Dictionary) -> void: st["win_candidates"][0]["status"] = "open"],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var result := _tampered(commands, cases[label][1])
		assert_false(result.ok, "%s: nicht geladen" % label)
		assert_eq(String(result.error), "state_invalid", "%s: Fehlergrund" % label)
		assert_true(result.state == null, "%s: kein teilweise geladener Zustand" % label)


# --- 52–54 Sichtbarkeit -------------------------------------------------------------------------------------

func test_visibility() -> void:
	var run := _replay_ok(_concat(_to_day(_ma6()), [Command.nominate(3, 2), Command.nominate(4, 5), Command.decide_execution(5), Command.end_day()] as Array[Command]), "Partie")
	if not run.ok:
		return
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			var text := _json(e.data).to_lower()
			assert_false(text.contains("manipulator") or text.contains("solo") or text.contains("cause") or text.contains("role"), "52: öffentliches %s ohne Rolle" % e.type)
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")
	for e: GameEvent in events_of_type(run.events, "NominationRecorded"):
		var keys: Array = e.data.keys()
		keys.sort()
		assert_eq(keys, ["day", "nominator_id", "nominee_id"], "53: Nominierung nur mit öffentlichen Personen")
		assert_eq(String(e.visibility), "public", "Nominierung öffentlich")
	for e: GameEvent in events_of_type(run.events, "SeatDied"):
		assert_eq(String(e.visibility), "gm", "Todesdetails GM-intern")
	var cand := _replay_ok(_parity_and_solo(), "Kandidaten")
	if cand.ok:
		var detected := events_of_type(cand.events, "WinDetected")
		for e: GameEvent in detected:
			assert_eq(String(e.visibility), "gm", "54: Kandidaten nur für den Spielleiter")
			var c: Dictionary = e.data["candidate"]
			assert_true(c.has("reason_key") and c.has("reason_args") and c.has("beneficiary_ids"), "54: vollständige Gründe")
		for e: GameEvent in cand.events:
			if e.visibility == &"public":
				assert_false(_json(e.data).contains("manipulator"), "offene Kandidaten nicht öffentlich")
