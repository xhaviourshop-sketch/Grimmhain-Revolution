extends TestCase
## Akt Classic, Gruppe A (DA-108): Selbstmörder, wildes Kind, Ritter mit dem verrosteten Schwert.
## Selbstmörder: Mechanik `selbstmoerder`; wildes Kind: Mechanik `wolfskind`, Wahl nur in Nacht 1;
## Ritter: eigene Classic-Regel (Spielleiter wählt Links oder Rechts, der Wolf dort stirbt am Morgen), siehe ClassicRules.

const SM := "classic-selbstmoerder"
const KID := "classic-wildes-kind"
const KNIGHT := "classic-ritter"
const REASON := "death_seeker_lynched"


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _open(s: GameState) -> Array:
	var out: Array = []
	for c: WinCandidate in s.open_candidates():
		out.append([String(c.kind), String(c.reason_key), c.beneficiary_ids.duplicate()])
	return out


# --- Der Selbstmörder ---------------------------------------------------------------------------

func _day_with_dead(dead: Array) -> Array[Command]:
	var roles: Array = ["classic-werwolf", "classic-werwolf", SM]
	for i: int in 9:
		roles.append("classic-dorfbewohner")
	var out: Array[Command] = [Fixtures.start_roles(roles), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]
	for id: int in dead:
		out.append(_gm("kill", {"target_id": id, "trigger_effects": true}))
	return out


func test_death_seeker_wins_when_hanged_after_five_dead() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7, 8])
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3)])
	var run := _run(cmds, "5 Tote")
	if run.ok:
		assert_eq(_open(run.state), [["solo", REASON, [3]]], "Sieg des Selbstmörders allein")
		assert_eq(run.state.players[3].appears_as, &"classic-selbstmoerder", "Classic-Erscheinung")


func test_death_seeker_with_four_dead_does_not_win() -> void:
	var cmds := _day_with_dead([4, 5, 6, 7])
	cmds.append_array([Command.nominate(9, 3), Command.decide_execution(3)])
	var run := _run(cmds, "4 Tote")
	if run.ok:
		assert_eq(_open(run.state), [], "zu früh gehängt: kein Sieg")


# --- Das wilde Kind -----------------------------------------------------------------------------

func _kid_start() -> Command:
	return Fixtures.start_roles(["classic-werwolf", "classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner", KID])


func test_wild_child_becomes_classic_werewolf_when_model_dies() -> void:
	var cmds: Array[Command] = [_kid_start(), Command.start_night(), Command.answer_prompt(1, [4]),
		Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, [4]), Command.end_night()]
	var run := _run(cmds, "Vorbild stirbt")
	if not run.ok:
		return
	var kid: Player = run.state.players[6]
	assert_eq(kid.role_id, &"classic-wildes-kind", "Rolle bleibt")
	assert_true(kid.counts_as_wolf and kid.faction == Faction.WOLVES, "zählt als Wolf")
	assert_eq(kid.appears_as, &"classic-werwolf", "erscheint als Classic-Werwolf")
	assert_true(WolfChildRules.state_is_consistent(run.state), "Zustand konsistent")


func test_wild_child_chooses_model_only_on_night_one() -> void:
	var cmds: Array[Command] = [_kid_start(), Command.start_night(), Command.answer_prompt(1, [4]),
		Command.begin_step("night:1:1:pack"), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(),
		_gm("remove_wolf_model", {"child_id": 6}), Command.decide_execution(-1), Command.end_day(), Command.start_night()]
	var run := _run(cmds, "Nacht 2")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack"] as Array[StringName], "keine zweite Vorbildwahl")


# --- Der Ritter mit dem verrosteten Schwert -----------------------------------------------------

## Sitze 1 bis 8 in Reihenfolge. Ritter auf 2; links von ihm (Uhrzeigersinn) sitzt zuerst Dorf 3, dann Werwolf 4. Werwolf 1 sitzt rechts.
func _knight_start() -> Command:
	return Fixtures.start_roles(["classic-werwolf", KNIGHT, "classic-dorfbewohner", "classic-werwolf", "classic-dorfbewohner",
		"classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner"])


func _knight_morning(pick: int) -> Array[Command]:
	return [_knight_start(), Command.start_night(), Command.answer_prompt(1, [2]), Command.end_night(), Command.begin_step("reaction:1"), Command.answer_prompt(2, [pick])]


func test_rusty_knight_killed_at_night_gm_picks_direction_and_that_wolf_dies() -> void:
	var cmds: Array[Command] = [_knight_start(), Command.start_night(), Command.answer_prompt(1, [2]), Command.end_night(), Command.begin_step("reaction:1")]
	var run := _run(cmds, "Morgen")
	if not run.ok:
		return
	assert_false(run.state.players[2].alive, "Ritter gefressen")
	assert_eq(run.state.phase, Phase.DAWN_RESOLUTION, "Fenster noch in der Morgenphase, vor dem Tag")
	var p := run.state.pending_prompt
	assert_eq(p.allowed_ids, [4, 1] as Array[int], "links Wolf 4, rechts Wolf 1")
	assert_true(p.min_count == 1 and not p.cancellable, "Pflichtwahl")
	for pick: int in [4, 1]:
		var res := _run(_knight_morning(pick), "Wahl %d" % pick)
		if res.ok:
			var other := 1 if pick == 4 else 4
			assert_false(res.state.players[pick].alive, "gewählter Wolf stirbt")
			assert_eq(res.state.players[pick].death.cause, KillEvent.CAUSE_KNIGHT_STRIKE, "Ursache Schlag des Ritters")
			assert_true(res.state.players[other].alive, "der andere Wolf lebt")
			assert_true(res.state.wolf_poisons.is_empty(), "keine Tetanus-Infektion mehr")
			assert_eq(res.state.phase, Phase.DAY, "danach beginnt der Tag")


func test_rusty_knight_single_wolf_dies_without_question_and_village_wins() -> void:
	var cmds: Array[Command] = [Fixtures.start_roles(["classic-dorfbewohner", KNIGHT, "classic-dorfbewohner", "classic-werwolf", "classic-dorfbewohner",
		"classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner"]), Command.start_night(), Command.answer_prompt(1, [2]), Command.end_night()]
	var run := _run(cmds, "ein Wolf")
	if not run.ok:
		return
	assert_true(run.state.reactions.is_empty(), "keine Frage bei einem Wolf")
	assert_false(run.state.players[4].alive, "der Wolf stirbt")
	assert_eq(run.state.players[4].death.cause, KillEvent.CAUSE_KNIGHT_STRIKE, "Ursache Schlag des Ritters")
	assert_false(run.state.open_candidates().is_empty(), "Siegprüfung nach beiden Toden: Dorf gewinnt")


func test_rusty_knight_with_no_living_wolf_triggers_nothing() -> void:
	var s := RulesEngine.replay([_knight_start()]).state
	s.players[1].alive = false
	s.players[4].alive = false
	assert_true(ClassicRules.rusty_choices(s, 2).is_empty(), "kein Wolf wählbar")
	var ctx := RuleContext.new(s, s.command_count)
	KillPipeline.request_kill(ctx, 2, KillEvent.CAUSE_NIGHT_KILL, KillEvent.SOURCE_PACK, -1)
	assert_true(s.reactions.is_empty(), "kein Fenster")
	assert_eq(s.alive_ids().size(), 5, "nur der Ritter ist gestorben")


func test_rusty_knight_hanged_triggers_nothing() -> void:
	var cmds: Array[Command] = [_knight_start(), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night(),
		Command.nominate(3, 2), Command.decide_execution(2)]
	var run := _run(cmds, "Ritter gehängt")
	if run.ok:
		assert_true(run.state.wolf_poisons.is_empty() and run.state.reactions.is_empty(), "keine Wirkung bei Hinrichtung")
		assert_true(run.state.players[4].alive and run.state.players[1].alive, "beide Wölfe leben")
