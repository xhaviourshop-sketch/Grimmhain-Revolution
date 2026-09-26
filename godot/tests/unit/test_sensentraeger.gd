extends TestCase
## Produktionsrolle `sensentraeger` (Reaper), rules-register.md §7, DR-09, DR-14.
## Besetzung S6: 1, 2 Werwölfe; 3 Sensenträger; 4, 5, 6 Dorfbewohner.
## Besetzung S7: 1, 2 Werwölfe; 3, 4 Sensenträger; 5, 6, 7 Dorfbewohner.

const FORBIDDEN_PUBLIC := ["sensentraeger", "werwolf", "dorfbewohner", "reaction", "allowed", "hunter_shot", "cause", "role", "prompt", "targets"]


func _s6(seed_value: int = 1) -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"], seed_value)


func _s7() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "sensentraeger", "sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"])


## Nacht 1: Rudel tötet den Sensenträger (3).
func _killed_by_pack() -> Array[Command]:
	return [_s6(), Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night()]


## Tag 1: Sensenträger (3) hingerichtet, nachdem Nacht 1 ohne Opfer blieb.
func _executed() -> Array[Command]:
	return [_s6(), Command.start_night(), Command.answer_prompt(1, []), Command.end_night(), Command.nominate(4, 3), Command.decide_execution(3)]


## Typsichere Verkettung zweier Befehlslisten.
func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


# --- Rolle -----------------------------------------------------------------------

func test_is_production_role_without_test_mode() -> void:
	var r := apply_ok(GameState.new(), _s6(), "Spielaufbau ohne test_mode")
	if not r.ok:
		return
	var p := r.state.players[3]
	assert_eq(String(p.role_id), "sensentraeger", "Rolle")
	assert_eq(String(p.faction), "village", "Fraktion Dorf")
	assert_false(p.counts_as_wolf, "zählt nicht als Wolf")
	assert_eq(String(p.appears_as), "sensentraeger", "Erscheinung für Informationsrollen")


func test_has_no_night_step() -> void:
	var run := _replay_ok([_s6(), Command.start_night()] as Array[Command], "Nacht 1")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack"] as Array[StringName], "nur der Rudelschritt")


# --- Todesarten --------------------------------------------------------------------

func test_pack_kill_reacts_at_dawn() -> void:
	# AS-R15, Zusatz 1 und 7
	var run := _replay_ok(_killed_by_pack(), "Rudelangriff")
	if not run.ok:
		return
	var queued := events_of_type(run.events, "ReactionQueued")
	assert_eq(queued.size(), 1, "genau eine Reaktion")
	if queued.size() == 1:
		assert_eq(int(queued[0].data["reaction"]["owner_id"]), 3, "Besitzer")
		assert_eq(String(queued[0].visibility), "gm", "nur Spielleiter")
	assert_eq(String(run.state.phase), "DAWN_RESOLUTION", "Reaktion vor dem Morgenbericht")
	var begun := apply_ok(run.state, Command.begin_step("reaction:1"), "Reaktion").state
	assert_false(begun.pending_prompt.allowed_ids.has(3), "nicht sich selbst")
	assert_eq(begun.pending_prompt.allowed_ids, [1, 2, 4, 5, 6] as Array[int], "nur Lebende")
	var shot := apply_ok(begun, Command.answer_prompt(2, [1]), "Fluch")
	var died := events_of_type(shot.events, "SeatDied")
	assert_true(died.size() == 1 and String(died[0].data["cause"]) == "HUNTER_SHOT" and int(died[0].data["source_id"]) == 3
		and String(died[0].data["source_kind"]) == "player", "Tod durch Fluch, Quelle Sensenträger")
	var resolved := events_of_type(shot.events, "ReactionResolved")
	assert_true(resolved.size() == 1 and String(resolved[0].data["outcome"]) == "cursed" and int(resolved[0].data["target_id"]) == 1, "Fluch protokolliert")
	assert_eq(String(shot.state.phase), "DAY", "danach Tag")


func test_execution_reacts_immediately() -> void:
	# AS-R16, Zusatz 2
	var run := _replay_ok(_executed(), "Hinrichtung")
	if not run.ok:
		return
	assert_eq(String(run.state.phase), "DAY", "gleiche Tagesphase")
	assert_eq(RulesEngine.next_step_id(run.state), "reaction:1", "Reaktion sofort fällig")
	apply_rejected(run.state, Command.end_day(), "reaction_open", "Tagesende erst nach der Reaktion")
	var begun := apply_ok(run.state, Command.begin_step("reaction:1"), "Reaktion").state
	var done := apply_ok(begun, Command.answer_prompt(2, [1]), "Fluch auf Werwolf").state
	apply_ok(done, Command.end_day(), "Tagesende")


func test_gm_kill_with_effects() -> void:
	# AS-G01, Zusatz 3
	var day := Fixtures.play([_s6(), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])
	var r := apply_ok(day, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}), "GM-Tod mit Folgen")
	assert_eq(events_of_type(r.events, "ReactionQueued").size(), 1, "Reaktion eingereiht")
	assert_eq(RulesEngine.next_step_id(r.state), "reaction:1", "sofort am Tag")


func test_gm_kill_without_effects() -> void:
	# AS-G02, Zusatz 4
	var day := Fixtures.play([_s6(), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])
	var r := apply_ok(day, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": false}), "GM-Tod ohne Folgen")
	assert_eq(events_of_type(r.events, "ReactionQueued").size(), 0, "keine Reaktion")
	assert_true(r.state.reactions.is_empty(), "Warteschlange leer")


func test_gm_execute() -> void:
	# Zusatz 5
	var day := Fixtures.play([_s6(), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()] as Array[Command])
	var r := apply_ok(day, CorrectionFixtures.gm("execute", {"target_id": 3}), "Hinrichtung per Übersteuerung")
	assert_eq(events_of_type(r.events, "ReactionQueued").size(), 1, "Reaktion eingereiht")
	assert_eq(RulesEngine.next_step_id(r.state), "reaction:1", "sofort am Tag")


func test_night_death_by_poison_like_correction_reacts_at_dawn() -> void:
	# AS-R37: Tod in der Nacht (Gift folgt mit der Waldhexe; hier Spielleiterkorrektur in der Nacht).
	var run := _replay_ok([_s6(), Command.start_night(), Command.answer_prompt(1, []),
		CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true})] as Array[Command], "Nachttod")
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "Reaktion eingereiht")
	apply_rejected(run.state, Command.begin_step("reaction:1"), "no_pending_step", "nicht während der Nacht")
	var dawn := apply_ok(run.state, Command.end_night(), "Morgen").state
	assert_eq(String(dawn.phase), "DAWN_RESOLUTION", "Abarbeitung in der Morgenauflösung")
	assert_eq(RulesEngine.next_step_id(dawn), "reaction:1", "jetzt fällig")


# --- Antwort ---------------------------------------------------------------------

func test_decline() -> void:
	# AS-R17, Zusatz 6
	var s := RulesEngine.replay(_killed_by_pack()).state
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion").state
	apply_rejected(begun, Command.skip_step("reaction:1", "egal"), "step_not_skippable", "kein Überspringen")
	apply_rejected(begun, Command.cancel_prompt(2, "egal"), "prompt_not_cancellable", "kein Abbruch")
	var r := apply_ok(begun, Command.answer_prompt(2, []), "Verzicht")
	assert_eq(events_of_type(r.events, "SeatDied").size(), 0, "kein Tod")
	var resolved := events_of_type(r.events, "ReactionResolved")
	assert_true(resolved.size() == 1 and String(resolved[0].data["outcome"]) == "declined" and int(resolved[0].data["target_id"]) == -1,
		"eindeutiges Verzichtsereignis")
	assert_true(r.state.reactions.is_empty(), "Reaktion erledigt")


func test_dead_target_rejected() -> void:
	# Zusatz 8: Nur zum Zeitpunkt der Antwort lebende Personen sind gültig.
	var s := RulesEngine.replay(_killed_by_pack()).state
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion").state
	begun.players[5].alive = false  # zwischenzeitlicher Tod ohne Prompt-Neuberechnung
	apply_rejected(begun, Command.answer_prompt(2, [5]), "invalid_target", "tote Person")
	# Regulärer Weg: Tod per Korrektur bricht den Prompt ab, der neue Prompt enthält die Person nicht.
	var fresh := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion").state
	var killed := apply_ok(fresh, CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false}), "Tod per Korrektur").state
	apply_rejected(killed, Command.answer_prompt(2, [5]), "wrong_phase", "alter Prompt existiert nicht mehr")
	var again := apply_ok(killed, Command.begin_step("reaction:1"), "neu begonnen").state
	apply_rejected(again, Command.answer_prompt(again.pending_prompt.id, [5]), "invalid_target", "tote Person nicht wählbar")


func test_resolved_reaction_cannot_run_again() -> void:
	# Zusatz 10
	var s := RulesEngine.replay(_killed_by_pack()).state
	var begun := apply_ok(s, Command.begin_step("reaction:1"), "Reaktion").state
	var done := apply_ok(begun, Command.answer_prompt(2, [1]), "Fluch auf Werwolf").state
	apply_rejected(done, Command.begin_step("reaction:1"), "no_pending_step", "Reaktion erneut beginnen")
	apply_rejected(done, Command.answer_prompt(2, [5]), "wrong_phase", "alten Prompt erneut beantworten")
	# Einmal pro Person: Wiederbelebung und erneuter Tod lösen keine zweite Reaktion aus.
	var revived := apply_ok(done, CorrectionFixtures.gm("revive", {"target_id": 3}), "Wiederbelebung").state
	var again := apply_ok(revived, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}), "erneuter Tod")
	assert_eq(events_of_type(again.events, "ReactionQueued").size(), 0, "keine zweite Reaktion")


# --- Ketten und DR-14 -------------------------------------------------------------

func test_chain_of_two_reapers() -> void:
	# Zusatz 9
	var run := _replay_ok([_s7(), Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night(),
		Command.begin_step("reaction:1"), Command.answer_prompt(2, [4])] as Array[Command], "Kette")
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "zweite Reaktion hinten eingereiht")
	assert_eq(run.state.reactions[0].owner_id, 4, "Besitzer der Folgereaktion")
	assert_eq(String(run.state.phase), "DAWN_RESOLUTION", "Morgen bleibt offen")
	var begun := apply_ok(run.state, Command.begin_step("reaction:2"), "Folgereaktion").state
	var done := apply_ok(begun, Command.answer_prompt(3, []), "Verzicht")
	assert_eq(String(done.state.phase), "DAY", "Tag erst nach leerer Warteschlange")


func test_provisional_win_changed_by_curse() -> void:
	# Zusatz 16 und 17: S6, Nacht 1 tötet 6 (2:3), Nacht 2 tötet den Sensenträger (2:2).
	var run := _replay_ok([_s6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.answer_prompt(2, [3]),
		Command.end_night()] as Array[Command], "Parität vor Reaktion")
	if not run.ok:
		return
	var provisional := events_of_type(run.events, "WinStatusProvisional")
	assert_eq(String((provisional[provisional.size() - 1].data["results"] as Array)[0]["kind"]), "wolves", "vorläufig Werwölfe")
	assert_true(run.state.win_candidate == null, "kein Kandidat bei offener Reaktion")
	apply_rejected(run.state, Command.confirm_win(1), "reaction_open", "keine Bestätigung")
	var begun := apply_ok(run.state, Command.begin_step("reaction:1"), "Reaktion").state
	var cursed := apply_ok(begun, Command.answer_prompt(3, [2]), "Fluch auf Werwolf")
	var final_status := events_of_type(cursed.events, "WinStatusFinal")
	assert_true(final_status.size() == 1 and (final_status[0].data["results"] as Array).is_empty(), "verbindlich kein Sieg")
	assert_true(cursed.state.win_candidate == null, "kein Kandidat")


func test_no_final_candidate_while_chain_open() -> void:
	# S7: Nacht 1 tötet 5 (2:4); Tag 1 Hinrichtung 3 (2:3), Fluch auf 4 (2:2) → Folgereaktion offen.
	var run := _replay_ok([_s7(), Command.start_night(), Command.answer_prompt(1, [5]), Command.end_night(),
		Command.nominate(6, 3), Command.decide_execution(3), Command.begin_step("reaction:1"), Command.answer_prompt(2, [4])] as Array[Command], "Kette am Tag")
	if not run.ok:
		return
	assert_eq(run.state.alive_ids(), [1, 2, 6, 7] as Array[int], "Parität 2:2")
	assert_true(run.state.win_candidate == null, "kein Kandidat, solange Folgereaktion offen")
	assert_eq(events_of_type(run.events, "WinDetected").size(), 0, "nichts vorgelegt")
	var begun := apply_ok(run.state, Command.begin_step("reaction:2"), "Folgereaktion").state
	var declined := apply_ok(begun, Command.answer_prompt(3, []), "Verzicht")
	assert_eq(events_of_type(declined.events, "WinDetected").size(), 1, "erst nach leerer Warteschlange Kandidat")


# --- Randfälle -----------------------------------------------------------------

func test_revive_keeps_queued_reaction() -> void:
	# AS-R40, Zusatz 18
	var s := RulesEngine.replay(_executed()).state
	var r := apply_ok(s, CorrectionFixtures.gm("revive", {"target_id": 3}), "Wiederbelebung")
	assert_true(r.state.players[3].alive, "lebt wieder")
	assert_eq(r.state.reactions.size(), 1, "Reaktion bleibt")
	assert_eq(RulesEngine.next_step_id(r.state), "reaction:1", "weiterhin fällig")
	var full := RulesEngine.replay(_concat(_executed(), [CorrectionFixtures.gm("revive", {"target_id": 3})] as Array[Command]))
	assert_eq(events_of_type(full.events, "SeatDied").size(), 1, "früheres Todesereignis unverändert")


func test_dead_pack_victim_no_second_choice() -> void:
	# AS-R41, Zusatz 19
	var run := _replay_ok([_s6(), Command.start_night(), Command.answer_prompt(1, [4]),
		CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": false}), Command.end_night()] as Array[Command], "totes Rudelopfer")
	if not run.ok:
		return
	assert_eq(events_of_type(run.events, "KillIgnored").size(), 1, "Angriff ins Leere protokolliert")
	assert_eq(events_of_type(run.events, "PromptOpened").size(), 1, "Rudelwahl nicht erneut geöffnet")
	assert_eq(String(run.state.phase), "DAY", "Tag beginnt")
	assert_eq(run.state.alive_ids(), [1, 2, 3, 5, 6] as Array[int], "kein weiterer Tod")


# --- Save/Load, Replay, Geheimhaltung ---------------------------------------------

func test_save_load_states() -> void:
	# Zusatz 11–13: vor Beginn, mit offenem Prompt, nach dem Verzicht.
	var base := _killed_by_pack()
	var cases := {
		"vor Beginn": base,
		"Prompt offen": _concat(base, [Command.begin_step("reaction:1")] as Array[Command]),
		"nach Verzicht": _concat(base, [Command.begin_step("reaction:1"), Command.answer_prompt(2, [])] as Array[Command]),
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label])
		var run := _replay_ok(commands, label)
		if not run.ok:
			continue
		var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
		assert_true(loaded.ok, "%s: Laden (%s)" % [label, loaded.error])
		if loaded.ok:
			assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: Hash" % label)
			assert_eq(RulesEngine.next_step_id(loaded.state), RulesEngine.next_step_id(run.state), "%s: erwarteter Schritt" % label)
			assert_eq(events_json(loaded.events), events_json(run.events), "%s: Ereignisse" % label)


func test_replay_single_and_chain() -> void:
	# Zusatz 14 und 15
	var single := _concat(_killed_by_pack(), [Command.begin_step("reaction:1"), Command.answer_prompt(2, [4])] as Array[Command])
	var chain: Array[Command] = [_s7(), Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night(),
		Command.begin_step("reaction:1"), Command.answer_prompt(2, [4]), Command.begin_step("reaction:2"), Command.answer_prompt(3, [5])]
	for commands: Array[Command] in [single, chain]:
		var a := RulesEngine.replay(commands)
		var b := RulesEngine.replay(commands)
		assert_true(a.ok and b.ok, "Replay angenommen (%s)" % a.error)
		assert_eq(events_json(a.events), events_json(b.events), "Ereignisse bytegleich")
		assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich")


func test_no_secrets_in_public_or_foreign_events() -> void:
	var run := _replay_ok([_s7(), Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night(),
		Command.begin_step("reaction:1"), Command.answer_prompt(2, [4]), Command.begin_step("reaction:2"), Command.answer_prompt(3, []),
		Command.nominate(5, 1), Command.decide_execution(1), Command.end_day()] as Array[Command], "Partie")
	if not run.ok:
		return
	for type: String in ["ReactionQueued", "ReactionResolved", "SeatDied", "PromptOpened", "PromptAnswered", "StepBegun", "WinStatusProvisional"]:
		for e: GameEvent in events_of_type(run.events, type):
			assert_eq(String(e.visibility), "gm", "%s nur für Spielleiter" % type)
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			var leak := _find_forbidden(e.data)
			assert_eq(leak, "", "öffentliches %s ohne Geheimnis" % e.type)
		elif e.visibility == &"actor":
			assert_eq(int(e.data.get("player_id", e.actor_id)), e.actor_id, "%s nur über die eigene Person" % e.type)
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")


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


# --- Regression: kein Selbstziel nach Wiederbelebung ------------------------------

## Tag 1: Sensenträger (3) hingerichtet, per Korrektur wiederbelebt, Reaktion begonnen.
func _revived_with_open_reaction() -> Array[Command]:
	return _concat(_executed(), [CorrectionFixtures.gm("revive", {"target_id": 3}), Command.begin_step("reaction:1")] as Array[Command])


func test_revived_reaper_cannot_target_himself() -> void:
	var commands := _revived_with_open_reaction()
	var run := _replay_ok(commands, "Wiederbelebung mit offener Reaktion")
	if not run.ok:
		return
	var s := run.state
	assert_true(s.players[3].alive, "Sensenträger lebt wieder")
	assert_false(s.pending_prompt.allowed_ids.has(3), "Besitzer nicht in allowed_ids")
	assert_eq(s.pending_prompt.allowed_ids, [1, 2, 4, 5, 6] as Array[int], "alle anderen Lebenden wählbar")
	var events_before := events_json(run.events)
	apply_rejected(s, Command.answer_prompt(s.pending_prompt.id, [3]), "invalid_target", "manipulierte Antwort auf sich selbst")
	var rejected := RulesEngine.apply(s, Command.answer_prompt(s.pending_prompt.id, [3]))
	assert_true(rejected.events.is_empty(), "keine Ereignisse durch die Ablehnung")
	assert_eq(events_json(run.events), events_before, "Ereignisliste unverändert")
	var ok := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [1]), "andere lebende Person")
	var died := events_of_type(ok.events, "SeatDied")
	assert_true(died.size() == 1 and int(died[0].data["target_id"]) == 1 and int(died[0].data["source_id"]) == 3, "Fluch trifft das andere Ziel")


func test_revived_reaper_save_load_and_replay() -> void:
	var commands := _revived_with_open_reaction()
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok and b.ok, "Replay angenommen (%s)" % a.error)
	if not a.ok:
		return
	assert_eq(events_json(a.events), events_json(b.events), "Replay bytegleich")
	assert_eq(a.state.content_hash(), b.state.content_hash(), "State-Hash gleich")
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if not loaded.ok:
		return
	assert_eq(loaded.state.content_hash(), a.state.content_hash(), "Hash nach Laden")
	assert_eq(loaded.state.pending_prompt.to_dict(), a.state.pending_prompt.to_dict(), "offener Reaktions-Prompt geladen")
	assert_false(loaded.state.pending_prompt.allowed_ids.has(3), "Besitzer auch nach Laden nicht wählbar")
	apply_rejected(loaded.state, Command.answer_prompt(loaded.state.pending_prompt.id, [3]), "invalid_target", "Selbstziel nach Laden")
	var x := RulesEngine.apply(a.state, Command.answer_prompt(2, [4]))
	var y := RulesEngine.apply(loaded.state, Command.answer_prompt(2, [4]))
	assert_true(x.ok and y.ok, "Fortsetzung angenommen")
	assert_eq(events_json(y.events), events_json(x.events), "identische Fortsetzung")
