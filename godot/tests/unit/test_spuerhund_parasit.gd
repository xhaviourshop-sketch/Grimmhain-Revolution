extends TestCase
## DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor, Spürhund, Parasit“ (28.09.2026).
##   Spürhund: jede Nacht freiwillig drei andere Lebende; ist eine Wolf oder Einzelsieg (wahre
##     Fraktion) ✓, sonst ✗ und er verliert die Fähigkeit (wird weiter aufgerufen). Priorität 6.8.
##   Parasit: jede Nacht freiwillig einen lebenden Wirt wählen oder behalten; mit lebendem Wirt
##     überlebt er jede Todesursache außer Spielleiterkorrekturen; stirbt der Wirt, stirbt er mit;
##     ohne Wirt normal verwundbar. Sieg bei höchstens drei Lebenden, wenn er lebt. Priorität 6.2.

const SH := "spuerhund"
const PA := "parasit"


func _start(roles: Array, appearances: Dictionary = {}) -> Command:
	var payload := Fixtures.start_roles(roles, 1).payload.duplicate(true)
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func test_production_roles() -> void:
	assert_eq(RoleCatalog.faction_of(&"spuerhund"), Faction.VILLAGE, "Spürhund: Dorf")
	assert_eq(RoleCatalog.night_priority(&"spuerhund"), 68, "Spürhund 6.8")
	assert_eq(RoleCatalog.faction_of(&"parasit"), Faction.SOLO, "Parasit: Einzelsieg")
	assert_eq(RoleCatalog.night_priority(&"parasit"), 62, "Parasit 6.2")
	assert_false(StepQueue.is_skippable("night:1:1:spuerhund:2") or StepQueue.is_skippable("night:1:1:parasit:2"), "Verzicht nur als Antwort")


# --- Spürhund -----------------------------------------------------------------------------------------

## Spürhund 2 prüft in Nacht 1 `targets`; liefert [Ergebnis ✓, Zustand nach „Gezeigt“].
func _sniff(roles: Array, targets: Array, appearances: Dictionary = {}) -> Array:
	var cmds: Array[Command] = [_start(roles, appearances), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"),
		Command.begin_step("night:1:1:spuerhund:2"), Command.answer_stage_targets(2, "targets", targets)]
	var run := _run(cmds, "Prüfung")
	if not run.ok:
		return [null, null]
	var hit: bool = run.state.pending_prompt.partial["hit"]
	cmds.append(Command.answer_choice(2, "shown", true))
	var done := _run(cmds, "Gezeigt")
	if done.ok:
		var actor := events_of_type(done.events, "HoundRevealed")
		assert_true(actor.size() == 1 and actor[0].actor_id == 2 and bool(actor[0].data["hit"]) == hit, "Ergebnis nur an den Spürhund")
	return [hit, done.state if done.ok else null]


func test_hound_hit_and_miss() -> void:
	var roles := ["werwolf", SH, "dorfbewohner", "amalia", "manipulator", "trugbilderwolf", "detektiv", "wahnsinniger-kutscher"]
	var app := {"6": "dorfbewohner"}
	assert_eq(_sniff(roles, [1, 3, 4], app)[0], true, "Wolf dabei: ✓")
	assert_eq(_sniff(roles, [5, 3, 4], app)[0], true, "Einzelsieg dabei: ✓")
	assert_eq(_sniff(roles, [6, 3, 4], app)[0], true, "Trugbilderwolf mit wahrer Fraktion: ✓")
	var miss := _sniff(roles, [3, 4, 7], app)
	assert_eq(miss[0], false, "nur Dorf: ✗")
	var s: GameState = miss[1]
	if s == null:
		return
	assert_true(InfoSteps.hound_lost(s.players[2]), "Fähigkeit verloren")
	for c: Command in [Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.skip_step("night:2:0:pack", "kein Opfer"),
			Command.begin_step("night:2:1:spuerhund:2")]:
		s = apply_ok(s, c, "Nacht 2").state
	assert_true(s.pending_prompt.partial.get("lost", false) == true and String(s.pending_prompt.stage) == "shown", "wird aufgerufen, ohne Fähigkeit")
	apply_rejected(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [1, 3, 4]), "stage_mismatch", "keine Prüfung mehr")
	s = apply_ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "nur aufgerufen").state
	var revived := apply_ok(s, _gm("kill", {"target_id": 2, "trigger_effects": false}), "Tod").state
	revived = apply_ok(revived, _gm("revive", {"target_id": 2}), "Wiederbelebung").state
	assert_false(InfoSteps.hound_lost(revived.players[2]), "Wiederbelebung gibt die Fähigkeit zurück")


func test_hound_exactly_three_and_invalid() -> void:
	var cmds: Array[Command] = [_start(["werwolf", SH, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), _gm("kill", {"target_id": 6, "trigger_effects": false}),
		Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.begin_step("night:1:1:spuerhund:2")]
	var s := _run(cmds, "Prompt").state
	if s == null:
		return
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [1, 3]), "invalid_target_count", "genau drei")
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [2, 3, 4]), "invalid_target", "nicht sich selbst")
	apply_rejected(s, Command.answer_stage_targets(2, "targets", [3, 4, 6]), "invalid_target", "keine Toten")
	apply_rejected(s, Command.answer_stage_targets(2, "targets", []), "invalid_target_count", "kein Verzicht: immer genau drei")
	var shown := apply_ok(s, Command.answer_stage_targets(2, "targets", [1, 3, 4]), "Prüfung").state
	var st: Dictionary = shown.to_dict()
	st["pending_prompt"]["partial"]["hit"] = false
	assert_true(GameState.from_dict(st) == null, "falsches Ergebnis beim Laden abgelehnt")


# --- Parasit ------------------------------------------------------------------------------------------

## Parasit 2 heftet sich in Nacht 1 an `host`; Rudel greift `victim` an (−1 = kein Opfer).
func _attach(roles: Array, host: int, victim: int = -1) -> Array[Command]:
	var pack: Command = Command.skip_step("night:1:0:pack", "kein Opfer") if victim < 0 else Command.answer_prompt(1, [victim])
	var cmds: Array[Command] = [_start(roles), Command.start_night(), pack]
	cmds.append_array([Command.begin_step("night:1:1:parasit:2"), Command.answer_prompt(2, [host]), Command.end_night()])
	return cmds


func test_parasite_immune_while_host_lives() -> void:
	var roles := ["werwolf", PA, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]
	var run := _run(_attach(roles, 3, 2), "Rudel auf Parasit")
	if not run.ok:
		return
	assert_true(run.state.players[2].alive, "Rudelangriff wirkt nicht")
	var prevented := events_of_type(run.events, "KillPrevented")
	assert_true(not prevented.is_empty() and (prevented[-1].data["sources"] as Array).has("parasit"), "abgefangen durch Wirt")
	var cmds := _attach(roles, 3)
	cmds.append_array([Command.nominate(4, 2), Command.decide_execution(2)])
	run = _run(cmds, "Lynch")
	if run.ok:
		assert_true(run.state.players[2].alive, "Hinrichtung wirkt nicht")
		assert_eq(String(run.state.day_step), "EXECUTION_DECIDED", "Hinrichtung des Tages gilt als erfolgt")
	var gm := _attach(roles, 3)
	gm.append(_gm("kill", {"target_id": 2, "trigger_effects": true}))
	run = _run(gm, "Korrektur")
	if run.ok:
		assert_false(run.state.players[2].alive, "Spielleiterkorrektur tötet")


func test_parasite_dies_with_host_and_is_normal_without() -> void:
	var roles := ["werwolf", PA, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]
	var cmds := _attach(roles, 3)
	cmds.append_array([Command.nominate(4, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Wirt stirbt")
	if run.ok:
		var d := run.state.players[2].death
		assert_true(d != null and String(d.cause) == "PARASITE_HOST" and d.source_id == 3, "stirbt mit seinem Wirt")
		assert_true(run.state.parasite_hosts.is_empty(), "Bindung beendet")
		var loaded := StateCodec.decode(StateCodec.encode(run.state, cmds))
		assert_true(loaded.ok, "Save/Load")
	var none: Array[Command] = [_start(roles), Command.start_night(), Command.answer_prompt(1, [2]), Command.begin_step("night:1:1:parasit:2"),
		Command.answer_prompt(2, []), Command.end_night()]
	run = _run(none, "ohne Wirt")
	if run.ok:
		assert_false(run.state.players[2].alive, "ohne Wirt normal verwundbar")


## B-06 (DA-93): Verliert der Parasit die Rolle, endet auch die Bindung an den Wirt; der Wirt stirbt dann ohne Folgen für ihn.
func test_parasite_losing_the_role_ends_the_bond() -> void:
	var roles := ["werwolf", PA, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]
	var cmds := _attach(roles, 3)
	cmds.append(_gm("set_role", {"target_id": 2, "role_id": "dorfbewohner"}))
	cmds.append_array([Command.nominate(4, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Rolle weg, Wirt stirbt")
	if run.ok:
		assert_true(run.state.parasite_hosts.is_empty(), "Bindung beendet")
		assert_true(run.state.players[2].alive, "frühere Parasit-Person lebt")


func test_parasite_changes_host() -> void:
	var roles := ["werwolf", PA, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]
	var cmds := _attach(roles, 3)
	cmds.append_array([Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.skip_step("night:2:0:pack", "kein Opfer"),
		Command.begin_step("night:2:1:parasit:2"), Command.answer_prompt(4, [5]), Command.end_night(), Command.nominate(4, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Wechsel")
	if run.ok:
		assert_true(run.state.players[2].alive, "alter Wirt stirbt, Parasit lebt (neuer Wirt 5)")
	var keep := _attach(roles, 3)
	keep.append_array([Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.skip_step("night:2:0:pack", "kein Opfer"),
		Command.begin_step("night:2:1:parasit:2"), Command.answer_prompt(4, []), Command.end_night(), Command.nominate(4, 3), Command.decide_execution(3)])
	run = _run(keep, "behalten")
	if run.ok:
		assert_false(run.state.players[2].alive, "ohne Wahl bleibt der alte Wirt")


func test_parasite_final_three() -> void:
	# 1 Werwolf, 2 Parasit (Wirt 3), 3–7 Dorf. Tote per Korrektur bis drei leben: 1, 2, 3.
	var cmds := _attach(["werwolf", PA, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 3)
	var s := _run(cmds, "Start").state
	if s == null:
		return
	for id: int in [4, 5, 6, 7]:
		s = apply_ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Tod %d" % id).state
		if id != 7:
			assert_true(s.open_candidates().is_empty() or not _kinds(s).has("parasite"), "vor drei Lebenden kein Parasit-Sieg")
	assert_true(_kinds(s).has("parasite"), "bei drei Lebenden Parasit-Kandidat")


func _kinds(s: GameState) -> Array:
	var out: Array = []
	for c: WinCandidate in s.open_candidates():
		out.append("parasite" if c.reason_key == &"parasite_final_three" else String(c.kind))
	return out
