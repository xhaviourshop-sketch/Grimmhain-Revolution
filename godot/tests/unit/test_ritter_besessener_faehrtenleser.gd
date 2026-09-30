extends TestCase
## Rollen aus DECISION-LOG „Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser“ (27.09.2026).
##   Besessener Wolf: „Reißt beim Tod (bei ≥5 Spielern) einen weiteren mit in den Tod.“ Mindestens 5
##     Lebende unmittelbar vor seinem Tod (er eingeschlossen); Reaktion: andere lebende Person (auch
##     Wolf) oder Verzicht; Tag sofort, Nacht am Morgen; einmal pro Leben (Wiederbelebung setzt zurück).
##   Ritter: „Tötet beim Sterben in der Nacht den nächstliegenden Werwolf.“ Nur Tod durch Wolfsangriff;
##     nächste lebende Person, die als Wolf zählt, Abstand in Sitzen inklusive toter Plätze; bei
##     Gleichstand wählt der Spielleiter (Reaktion); einmal pro Leben.
##   Fährtenleser: „Wacht jede Nacht auf und darf einmal im Spiel erfahren, in welche Richtung der
##     nächstliegende Wolf von ihm sitzt: links oder rechts.“ Jede Nacht „jetzt nutzen?“ bis zur
##     Nutzung, danach kein Schritt; links = nächster Platz im Uhrzeigersinn; Abstand wie beim Ritter;
##     Gleichstand „gleich weit“. Priorität 5.2 (Legacy-Stufe).

const BW := "besessener-wolf"
const RI := "ritter"
const FL := "faehrtenleser"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _deaths(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events_of_type(events, "SeatDied"):
		out.append([int(e.data["target_id"]), String(e.data["cause"])])
	return out


func _last(cmds: Array[Command]) -> CommandResult:
	var before := RulesEngine.replay(cmds.slice(0, cmds.size() - 1))
	assert_true(before.ok, "Vorlauf angenommen (%s @ %d)" % [before.error, before.failed_index])
	return apply_ok(before.state, cmds[cmds.size() - 1], "letzter Befehl") if before.ok else null


func test_production_roles() -> void:
	assert_eq(RoleCatalog.faction_of(&"besessener-wolf"), Faction.WOLVES, "Besessener: Wölfe")
	assert_true(RoleCatalog.counts_as_wolf(&"besessener-wolf"), "Besessener zählt als Wolf")
	assert_eq(RoleCatalog.faction_of(&"ritter"), Faction.VILLAGE, "Ritter: Dorf")
	assert_eq(RoleCatalog.faction_of(&"faehrtenleser"), Faction.VILLAGE, "Fährtenleser: Dorf")
	assert_eq(RoleCatalog.night_priority(&"faehrtenleser"), 52, "Fährtenleser 5.2")
	assert_eq(RoleCatalog.night_priority(&"ritter") + RoleCatalog.night_priority(&"besessener-wolf"), 0, "Ritter und Besessener ohne Schritt")


# --- Besessener Wolf ----------------------------------------------------------------------------------

func _bw_day(roles: Array) -> Array[Command]:
	return [_start(roles), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]


func test_possessed_lynched_drags_chosen_person() -> void:
	var cmds := _bw_day([BW, "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	cmds.append_array([Command.nominate(3, 1), Command.decide_execution(1)])
	var run := _run(cmds, "Lynch")
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "Mitnahme als Reaktion eingereiht (6 Lebende)")
	cmds.append(Command.begin_step("reaction:1"))
	run = _run(cmds, "Reaktion")
	if not run.ok:
		return
	var p := run.state.pending_prompt
	assert_true(p.allowed_ids.has(2) and not p.allowed_ids.has(1) and p.min_count == 0 and not p.cancellable, "auch Wölfe wählbar, Verzicht erlaubt, nicht abbrechbar")
	cmds.append(Command.answer_prompt(p.id, [2]))
	var r := _last(cmds)
	if r != null:
		assert_eq(_deaths(r.events), [[2, "POSSESSED_DRAG"]], "mitgerissen")
		assert_eq(r.state.players[2].death.source_id, 1, "Quelle Besessener")
		var loaded := StateCodec.decode(StateCodec.encode(r.state, cmds))
		assert_true(loaded.ok, "Save/Load")


func test_possessed_threshold_five_living_including_him() -> void:
	var roles := [BW, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]
	var five := _bw_day(roles)
	five.append_array([_gm("kill", {"target_id": 6, "trigger_effects": false}), _gm("kill", {"target_id": 7, "trigger_effects": false}),
		Command.nominate(3, 1), Command.decide_execution(1)])
	var run := _run(five, "5 Lebende")
	if run.ok:
		assert_eq(run.state.reactions.size(), 1, "5 Lebende inklusive ihm: Mitnahme")
	var four := _bw_day(roles)
	four.append_array([_gm("kill", {"target_id": 5, "trigger_effects": false}), _gm("kill", {"target_id": 6, "trigger_effects": false}),
		_gm("kill", {"target_id": 7, "trigger_effects": false}), Command.nominate(3, 1), Command.decide_execution(1)])
	run = _run(four, "4 Lebende")
	if run.ok:
		assert_eq(run.state.reactions.size(), 0, "4 Lebende: keine Mitnahme")


func test_possessed_night_death_at_dawn_decline_and_revive() -> void:
	# Rudel frisst den Besessenen: Reaktion am Morgen, Verzicht; Wiederbelebung, zweiter Tod → erneut.
	var cmds: Array[Command] = [_start([BW, "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), Command.start_night(),
		Command.answer_prompt(1, [1]), Command.end_night()]
	var run := _run(cmds, "Nacht")
	if not run.ok:
		return
	assert_eq(RulesEngine.next_step_id(run.state), "reaction:1", "Reaktion am Morgen fällig")
	cmds.append_array([Command.begin_step("reaction:1"), Command.answer_prompt(2, []), _gm("revive", {"target_id": 1}), _gm("kill", {"target_id": 1, "trigger_effects": true})])
	run = _run(cmds, "zweiter Tod")
	if run.ok:
		assert_eq(run.state.reactions.size(), 1, "nach Wiederbelebung erneut")


# --- Ritter -------------------------------------------------------------------------------------------

## Sitzkreis = ID. Rudel frisst den Ritter `knight`; `dead` sterben vorher per Korrektur.
func _knight_night(roles: Array, knight: int, dead: Array = []) -> Array[Command]:
	var cmds: Array[Command] = [_start(roles)]
	for id: int in dead:
		cmds.append(_gm("kill", {"target_id": id, "trigger_effects": false}))
	cmds.append_array([Command.start_night(), Command.answer_prompt(1, [knight]), Command.end_night()])
	return cmds


func test_knight_strikes_nearest_wolf_counting_dead_seats() -> void:
	# Ritter 4; links 3 tot, 2 Wolf (Abstand 2 mit Totem); rechts 5 Wolf (Abstand 1) → 5 stirbt sofort.
	var roles := ["dorfbewohner", "werwolf", "amalia", RI, "blutwolf", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]
	var cmds := _knight_night(roles, 4, [3])
	var r := _last(cmds)
	if r == null:
		return
	assert_eq(_deaths(r.events), [[4, "NIGHT_KILL"], [5, "KNIGHT_STRIKE"]], "Ritter stirbt, nächster Wolf 5 stirbt mit")
	assert_eq(r.state.players[5].death.source_id, 4, "Quelle Ritter")
	assert_eq(r.state.reactions.size(), 0, "keine Wahl ohne Gleichstand")


func test_knight_ignores_cursed_villager() -> void:
	# RM-DR-136.2 (Decision Log Runde 3 „Ritter, Ziel“: wer als Wolf zählt) mit V-01/V-02 (Fluch nur für
	# Rollenauskünfte): Ritter 4, rechts 5 verfluchter Dorfbewohner (Abstand 1), links 2 Wolf (Abstand 2).
	var roles := ["dorfbewohner", "werwolf", "amalia", RI, "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]
	var start := _run([_start(roles)] as Array[Command], "Start")
	if start == null or not start.ok:
		return
	var s := start.state
	s.players[5].cursed = true
	s = apply_ok(s, Command.start_night(), "Nacht").state
	s = apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Rudel frisst den Ritter").state
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_deaths(r.events), [[4, "NIGHT_KILL"], [2, "KNIGHT_STRIKE"]], "echter Wolf stirbt, der Verfluchte nicht")


func test_knight_tie_gm_chooses() -> void:
	# Ritter 4; Wolf 2 (Abstand 2) und Wolf 6 (Abstand 2) → Spielleiter wählt.
	var roles := ["dorfbewohner", "werwolf", "amalia", RI, "detektiv", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor"]
	var cmds := _knight_night(roles, 4)
	var run := _run(cmds, "Gleichstand")
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "Gleichstand wird als Wahl eingereiht")
	cmds.append(Command.begin_step("reaction:1"))
	run = _run(cmds, "Wahl")
	if not run.ok:
		return
	var p := run.state.pending_prompt
	assert_eq(p.allowed_ids, [2, 6] as Array[int], "nur die gleich nahen Wölfe")
	assert_true(p.min_count == 1 and not p.cancellable, "Pflichtwahl")
	apply_rejected(run.state, Command.answer_prompt(p.id, []), "invalid_target_count", "kein Verzicht")
	apply_rejected(run.state, Command.answer_prompt(p.id, [3]), "invalid_target", "kein anderer")
	cmds.append(Command.answer_prompt(p.id, [6]))
	var r := _last(cmds)
	if r != null:
		assert_eq(_deaths(r.events), [[6, "KNIGHT_STRIKE"]], "gewählter Wolf stirbt")


func test_knight_only_wolf_attack_and_revive() -> void:
	var roles := ["dorfbewohner", "werwolf", "amalia", RI, "blutwolf", "detektiv", "waldhexe", "wahnsinniger-kutscher"]
	# Gift der Waldhexe: kein Ritterschlag.
	var poison: Array[Command] = [_start(roles), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"),
		Command.begin_step("night:1:1:waldhexe:7"), Command.answer_choice(2, "poison", true), Command.answer_stage_targets(2, "poison_target", [4]),
		Command.answer_choice(2, "confirm", true), Command.end_night()]
	var run := _run(poison, "Gift")
	if run.ok:
		assert_true(run.state.players[5].alive and run.state.players[2].alive, "Gift löst nichts aus")
	# Lynch: kein Ritterschlag.
	var lynch: Array[Command] = [_start(roles), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"),
		Command.begin_step("night:1:1:waldhexe:7"), Command.answer_choice(2, "poison", false), Command.answer_choice(2, "confirm", true),
		Command.end_night(), Command.nominate(1, 4), Command.decide_execution(4)]
	run = _run(lynch, "Lynch")
	if run.ok:
		assert_true(run.state.players[5].alive, "Hinrichtung löst nichts aus")


func test_knight_revived_strikes_again() -> void:
	var roles := ["dorfbewohner", "werwolf", "amalia", RI, "blutwolf", "detektiv", "rudelvater", "wahnsinniger-kutscher"]
	var cmds := _knight_night(roles, 4)
	cmds.append_array([_gm("revive", {"target_id": 4}), Command.decide_execution(-1), Command.end_day(), Command.start_night(),
		Command.answer_prompt(2, [4]), Command.end_night()])
	var run := _run(cmds, "zweiter Tod")
	if run.ok:
		assert_eq(String(run.state.players[5].death.cause), "KNIGHT_STRIKE", "erster Schlag traf 5")
		assert_true(not run.state.players[2].alive or not run.state.players[7].alive, "zweiter Schlag nach Wiederbelebung")


# --- Fährtenleser -------------------------------------------------------------------------------------

## Fährtenleser 4 nutzt in Nacht 1 seine Fähigkeit; liefert die gezeigte Richtung.
func _track(roles: Array, dead: Array = []) -> String:
	var cmds: Array[Command] = [_start(roles)]
	for id: int in dead:
		cmds.append(_gm("kill", {"target_id": id, "trigger_effects": false}))
	cmds.append_array([Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.begin_step("night:1:1:faehrtenleser:4"),
		Command.answer_choice(2, "use", true)])
	var run := _run(cmds, "Nutzung")
	if not run.ok:
		return ""
	var direction := String(run.state.pending_prompt.partial["direction"])
	cmds.append(Command.answer_choice(2, "shown", true))
	var done := _run(cmds, "Gezeigt")
	if done.ok:
		var actor := events_of_type(done.events, "TrackerRevealed")
		assert_true(actor.size() == 1 and actor[0].actor_id == 4 and String(actor[0].data["direction"]) == direction, "nur der Fährtenleser")
	return direction


func test_tracker_direction_left_is_clockwise() -> void:
	# Wolf 6 im Uhrzeigersinn (Abstand 2), Wolf 1 gegen den Uhrzeigersinn (Abstand 3) → links.
	assert_eq(_track(["werwolf", "dorfbewohner", "amalia", FL, "detektiv", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor"]), "left", "links = Uhrzeigersinn")
	# Nur Wolf 2 gegen den Uhrzeigersinn → rechts.
	assert_eq(_track(["dorfbewohner", "werwolf", "amalia", FL, "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), "right", "rechts")
	# 5 tot, Wolf 6 (Abstand 2 mit totem Platz) und Wolf 2 (Abstand 2) → gleich weit.
	assert_eq(_track(["dorfbewohner", "werwolf", "amalia", FL, "detektiv", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor"], [5]), "equal", "gleich weit, tote Plätze zählen")


func test_tracker_asks_each_night_until_used() -> void:
	var roles := ["werwolf", "dorfbewohner", "amalia", FL, "detektiv", "wahnsinniger-kutscher"]
	var cmds: Array[Command] = [_start(roles), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"),
		Command.begin_step("night:1:1:faehrtenleser:4"), Command.answer_choice(2, "use", false), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var run := _run(cmds, "Nacht 2")
	if not run.ok:
		return
	assert_true(run.state.night_plan.has(&"faehrtenleser:4"), "nach Verzicht erneut gefragt")
	cmds.append_array([Command.skip_step("night:2:0:pack", "kein Opfer"), Command.begin_step("night:2:1:faehrtenleser:4"),
		Command.answer_choice(4, "use", true), Command.answer_choice(4, "shown", true), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night()])
	run = _run(cmds, "Nacht 3")
	if not run.ok:
		return
	assert_false(run.state.night_plan.has(&"faehrtenleser:4"), "nach Nutzung kein Schritt mehr")
	var st: Dictionary = run.state.to_dict()
	cmds.append_array([Command.skip_step("night:3:0:pack", "kein Opfer"), Command.end_night(), _gm("kill", {"target_id": 4, "trigger_effects": false}),
		_gm("revive", {"target_id": 4}), Command.decide_execution(-1), Command.end_day(), Command.start_night()])
	run = _run(cmds, "nach Wiederbelebung")
	if run.ok:
		assert_true(run.state.night_plan.has(&"faehrtenleser:4"), "Wiederbelebung setzt die Nutzung zurück")
	assert_true(st.size() > 0, "Zustand vorhanden")


func test_tracker_corrupt_direction_rejected() -> void:
	var s := _run([_start(["werwolf", "dorfbewohner", "amalia", FL, "detektiv", "wahnsinniger-kutscher"]), Command.start_night(),
		Command.skip_step("night:1:0:pack", "kein Opfer"), Command.begin_step("night:1:1:faehrtenleser:4"), Command.answer_choice(2, "use", true)] as Array[Command], "Prompt").state
	if s == null:
		return
	var st: Dictionary = s.to_dict()
	st["pending_prompt"]["partial"]["direction"] = "left"
	assert_true(GameState.from_dict(st) == null, "falsche Richtung beim Laden abgelehnt")
	apply_rejected(s, Command.skip_step("night:1:1:faehrtenleser:4", "nein"), "step_not_skippable", "Verzicht nur als Antwort")
