extends TestCase
## Akt Classic, Gruppe A (DA-108): Selbstmörder, wildes Kind, Ritter mit dem verrosteten Schwert.
## Selbstmörder: Mechanik `selbstmoerder`; wildes Kind: Mechanik `wolfskind`, Wahl nur in Nacht 1;
## Ritter: eigene Classic-Regel (Tetanus statt sofortigem Tod), siehe ClassicRules.

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


func test_rusty_knight_infects_left_wolf_who_dies_next_night_after_the_victims() -> void:
	var cmds: Array[Command] = [_knight_start(), Command.start_night(), Command.answer_prompt(1, [2]),
		Command.end_night()]
	var run := _run(cmds, "Nacht 1")
	if not run.ok:
		return
	assert_false(run.state.players[2].alive, "Ritter gefressen")
	assert_true(run.state.players[4].alive and run.state.players[1].alive, "Wolf links lebt noch, kein Sofortschlag")
	assert_eq(events_of_type(run.events, "TetanusInfected").size(), 1, "Infektion protokolliert")
	cmds.append_array([Command.decide_execution(-1), Command.end_day(), Command.start_night(),
		Command.answer_prompt(2, [5]), Command.end_night()])
	var next := _run(cmds, "Nacht 2")
	if not next.ok:
		return
	var s := next.state
	assert_false(s.players[4].alive, "infizierter Wolf tot")
	assert_eq(s.players[4].death.cause, KillEvent.CAUSE_TETANUS, "Todesursache Tetanus")
	assert_true(s.players[4].death.order_index > s.players[5].death.order_index, "nach dem Rudelopfer")
	assert_true(s.players[1].alive, "der andere Wolf bleibt unberührt")


func test_rusty_knight_hanged_infects_nobody() -> void:
	var cmds: Array[Command] = [_knight_start(), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night(),
		Command.nominate(3, 2), Command.decide_execution(2)]
	var run := _run(cmds, "Ritter gehängt")
	if run.ok:
		assert_true(run.state.wolf_poisons.is_empty(), "keine Infektion bei Hinrichtung")
		assert_true(run.state.players[4].alive, "Wolf lebt")
