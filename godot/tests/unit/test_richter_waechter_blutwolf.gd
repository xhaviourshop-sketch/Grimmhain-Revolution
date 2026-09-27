extends TestCase
## DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor …“ (28.09.2026) und
## „Querschnittsfragen“ (RM-DR-008, RM-DR-012).
##   Blutwolf: „Seine Stimme zählt +1 für jeden direkten toten Nachbarn.“ Nur Hinweis (VoteHints).
##   Korrupter Richter: nachts freiwillig eine lebende Person markieren (auch sich selbst); bei
##     Tagesbeginn gilt sie als vom Richter nominiert (öffentlich ohne Richter, intern normal);
##     „+1 Stimme“ als Hinweis; bei Nachtbeginn wird die Markierung gelöscht.
##   Wächter am Tor: „Solange er lebt, werden neu entstehende Werwölfe blockiert — der betroffene
##     Spieler wird stattdessen zum Dorfbewohner.“ Jeder Weg ins Rudel außer Spielleiterkorrekturen;
##     die Person erfährt es privat.

const BL := "blutwolf"
const KR := "korrupter-richter"
const WT := "waechter-am-tor"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _hints(s: GameState) -> Array:
	var out: Array = []
	for h: Dictionary in VoteHints.hints(s):
		out.append([int(h["player_id"]), int(h["bonus"]), String(h["source_role"])])
	return out


func test_production_roles() -> void:
	assert_eq(RoleCatalog.faction_of(&"blutwolf"), Faction.WOLVES, "Blutwolf: Wölfe")
	assert_true(RoleCatalog.counts_as_wolf(&"blutwolf"), "Blutwolf zählt als Wolf")
	assert_eq(RoleCatalog.faction_of(&"korrupter-richter"), Faction.VILLAGE, "Richter: Dorf")
	assert_eq(RoleCatalog.night_priority(&"korrupter-richter"), 15, "Richter 1.5")
	assert_eq(RoleCatalog.faction_of(&"waechter-am-tor"), Faction.VILLAGE, "Wächter: Dorf")


# --- Blutwolf ----------------------------------------------------------------------------------------

func test_blood_wolf_hint_counts_direct_dead_neighbours() -> void:
	# Blutwolf 3; direkte Nachbarsitze 2 und 4.
	var roles := ["werwolf", "dorfbewohner", BL, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
	var s := _run([_start(roles)] as Array[Command], "Start").state
	assert_eq(_hints(s), [], "ohne tote Nachbarn kein Hinweis")
	s = apply_ok(s, _gm("kill", {"target_id": 2, "trigger_effects": false}), "2 tot").state
	assert_eq(_hints(s), [[3, 1, BL]], "+1")
	s = apply_ok(s, _gm("kill", {"target_id": 4, "trigger_effects": false}), "4 tot").state
	assert_eq(_hints(s), [[3, 2, BL]], "+2")
	s = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": false}), "5 tot, nicht direkt").state
	assert_eq(_hints(s), [[3, 2, BL]], "nur direkte Nachbarn")
	s = apply_ok(s, _gm("revive", {"target_id": 2}), "2 wiederbelebt").state
	assert_eq(_hints(s), [[3, 1, BL]], "live berechnet")
	s = apply_ok(s, _gm("kill", {"target_id": 3, "trigger_effects": false}), "Blutwolf tot").state
	assert_eq(_hints(s), [], "toter Blutwolf: kein Hinweis")


# --- Korrupter Richter --------------------------------------------------------------------------------

## Richter 2 markiert in Nacht 1 `target` (-1 = Verzicht); danach Tag 1.
func _judge_day(roles: Array, target: int) -> Array[Command]:
	return [_start(roles), Command.start_night(), Command.answer_prompt(1, [] if target < 0 else [target]),
		Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night()]


func test_judge_mark_becomes_hidden_nomination_with_hint() -> void:
	var cmds := _judge_day(["werwolf", KR, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 4)
	var run := _run(cmds, "Markierung")
	if not run.ok:
		return
	var noms := run.state.nominations_on_day(1)
	assert_true(noms.size() == 1 and noms[0].nominator_id == 2 and noms[0].nominee_id == 4, "Richter nominiert 4")
	assert_true(run.state.players[4].ever_nominated, "Nominierungsstatus")
	var public := []
	for e: GameEvent in run.events:
		if e.visibility == Visibility.PUBLIC and String(e.type).contains("Nomination"):
			public.append(e)
	assert_eq(public.size(), 1, "eine öffentliche Nominierung")
	if public.size() == 1:
		assert_true(int(public[0].data["nominee_id"]) == 4 and not public[0].data.has("nominator_id"), "öffentlich ohne Richter")
	var gm := events_of_type(run.events, "JudgeNominated")
	assert_true(gm.size() == 1 and gm[0].visibility == Visibility.GM and int(gm[0].data["judge_id"]) == 2, "Spielleiter sieht den Richter")
	assert_eq(_hints(run.state), [[4, 1, KR]], "+1 Stimme als Hinweis")
	apply_rejected(run.state, Command.nominate(2, 5), "already_nominated_today", "Richter hat heute nominiert")
	apply_rejected(run.state, Command.nominate(3, 4), "already_nominee_today", "4 ist schon nominiert")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
	assert_true(loaded.ok and events_json(loaded.events) == events_json(run.events), "Save/Load und Replay")


func test_judge_decline_self_mark_and_clear() -> void:
	var none := _run(_judge_day(["werwolf", KR, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], -1), "Verzicht")
	if none.ok:
		assert_eq(none.state.nominations_on_day(1).size(), 0, "ohne Markierung keine Nominierung")
	var self_mark := _run(_judge_day(["werwolf", KR, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 2), "selbst")
	if not self_mark.ok:
		return
	assert_eq(self_mark.state.nominations_on_day(1)[0].nominee_id, 2, "Selbstmarkierung erlaubt")
	var next := apply_ok(self_mark.state, Command.decide_execution(-1), "keine Hinrichtung").state
	next = apply_ok(next, Command.end_day(), "Tagesende").state
	next = apply_ok(next, Command.start_night(), "Nacht 2").state
	assert_true(next.judge_marks.is_empty(), "Markierung bei Nachtbeginn gelöscht")


func test_judge_mark_kills_manipulator_and_mirror_hits_judge() -> void:
	var manip := _run(_judge_day(["werwolf", KR, "manipulator", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 3), "Manipulator")
	if manip.ok:
		var d := manip.state.players[3].death
		assert_true(d != null and String(d.cause) == "MANIPULATOR_NOMINATED" and d.source_id == 2, "Manipulator stirbt, Quelle Richter")
	var cmds := _judge_day(["spiegelwolf", KR, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], 1)
	cmds.append(Command.decide_execution(1))
	var run := _run(cmds, "Spiegelung")
	if run.ok:
		assert_true(run.state.players[1].alive and String(run.state.players[2].death.cause) == "SPIEGELWOLF_RETALIATE", "Spiegelung trifft den Richter")


func test_judge_or_target_dead_by_morning_no_nomination() -> void:
	var cmds: Array[Command] = [_start(["werwolf", KR, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), Command.start_night(),
		Command.answer_prompt(1, [4]), Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, [4]), Command.end_night()]
	var run := _run(cmds, "Ziel tot")
	if run.ok:
		assert_eq(run.state.nominations_on_day(1).size(), 0, "tote Markierte wird nicht nominiert")
	var judge_dead: Array[Command] = [_start(["werwolf", KR, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), Command.start_night(),
		Command.answer_prompt(1, [4]), Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, [2]), Command.end_night()]
	run = _run(judge_dead, "Richter tot")
	if run.ok:
		assert_eq(run.state.nominations_on_day(1).size(), 0, "toter Richter nominiert nicht")


# --- Wächter am Tor -----------------------------------------------------------------------------------

func test_gatewarden_blocks_wolf_child_transformation() -> void:
	# 1 Werwolf, 2 Wächter, 3 Wolfskind → Vorbild 4; 5–7 Dorf. 4 stirbt am Tag.
	var cmds: Array[Command] = [_start(["werwolf", WT, "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, [4]), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(),
		Command.nominate(5, 4), Command.decide_execution(4)]
	var run := _run(cmds, "Wächter lebt")
	if not run.ok:
		return
	var p := run.state.players[3]
	assert_true(p.role_id == &"dorfbewohner" and not p.counts_as_wolf and p.faction == Faction.VILLAGE, "wird Dorfbewohner statt Wolf")
	assert_true(WolfChildRules.bond_of(run.state, 3) == null, "kein Wolfskind-Datensatz mehr")
	var actor := events_of_type(run.events, "NewWolfBlockedNotice")
	assert_true(actor.size() == 1 and actor[0].visibility == Visibility.ACTOR and actor[0].actor_id == 3, "nur sie erfährt es")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
	assert_true(loaded.ok, "Save/Load")
	# Ohne lebenden Wächter normale Verwandlung.
	var dead: Array[Command] = [_start(["werwolf", WT, "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		_gm("kill", {"target_id": 2, "trigger_effects": false}), Command.start_night(), Command.answer_prompt(1, [4]),
		Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(), Command.nominate(5, 4), Command.decide_execution(4)]
	run = _run(dead, "Wächter tot")
	if run.ok:
		assert_true(run.state.players[3].counts_as_wolf, "Verwandlung ohne Wächter")


func test_gatewarden_blocks_apprentice_wolf_inheritance_only() -> void:
	# 1 Werwolf, 2 Wächter, 3 Lehrling wählt den Werwolf; 1 stirbt → 3 wird Dorfbewohner.
	var cmds: Array[Command] = [_start(["werwolf", WT, "lehrling", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_stage_targets(1, "candidates", [1, 5, 6])]
	var run := _run(cmds, "Kandidaten")
	if not run.ok:
		return
	var options: Array = run.state.pending_prompt.partial["options"]
	cmds.append_array([Command.create(Command.ANSWER_PROMPT, {"prompt_id": 1, "stage": "option", "option": options.find("werwolf")}),
		Command.answer_choice(1, "confirm", true), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(),
		Command.nominate(5, 1), Command.decide_execution(1)])
	run = _run(cmds, "Erbe")
	if run.ok:
		assert_true(run.state.players[3].role_id == &"dorfbewohner" and not run.state.players[3].counts_as_wolf, "Erbe einer Wolfsrolle blockiert")
		var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
		assert_true(loaded.ok, "Save/Load nach blockiertem Erbe (%s)" % loaded.error)


func test_gatewarden_ignores_gm_corrections() -> void:
	var cmds: Array[Command] = [_start(["werwolf", WT, "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		_gm("set_wolf_model", {"child_id": 3, "target_id": 4}), _gm("transform_wolf_child", {"child_id": 3}), _gm("set_role", {"target_id": 5, "role_id": "werwolf"})]
	var run := _run(cmds, "Korrekturen")
	if run.ok:
		assert_true(run.state.players[3].counts_as_wolf and run.state.players[5].counts_as_wolf, "Spielleiterkorrekturen werden nicht blockiert")
