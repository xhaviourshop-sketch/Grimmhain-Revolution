extends TestCase
## Akt Classic, Gruppe C (DA-108): Urwolf und Weißer Wolf. Beide zählen als Werwolf (Rudel); eigene Regeln stehen in
## ClassicWolfRules bzw. als Classic-Parameter am Katalogeintrag (Rachsüchtiger Wolf als Mechanik).

const UW := "classic-urwolf"
const WW := "classic-weisser-wolf"
const D := "classic-dorfbewohner"
const W := "classic-werwolf"


func _gm_kill(s: GameState, id: int) -> GameState:
	if s != null and not s.open_candidates().is_empty():
		s = apply_ok(s, Command.create(Command.REJECT_WIN, {"reason": "Test"}), "weiter").state
	return apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false}, "Test"), "Toter %d" % id).state


## Spielt Nacht 1 bis zum Urwolf-Schritt; das Rudel wählt `victim`. Liefert den Zustand mit offener Frage des Urwolfs.
func _until_urwolf_prompt(s: GameState, victim: int) -> GameState:
	for guard: int in 8:
		if s.pending_prompt == null:
			if StepQueue.next_step_id(s) == "":
				return s
			var br := RulesEngine.apply(s, Command.begin_step(StepQueue.next_step_id(s)))
			assert_true(br.ok, "begin %s step=%s plan=%s" % [br.error, StepQueue.next_step_id(s), s.night_plan])
			if not br.ok:
				return s
			s = br.state
		elif s.pending_prompt.owner == PendingPrompt.OWNER_PACK:
			s = apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [victim]), "Rudel").state
		else:
			return s
	return s


func test_urwolf_turns_the_victim_once_instead_of_killing() -> void:
	var r := RulesEngine.replay([Fixtures.start_roles([UW, W, D, D, D, D, D, D]), Command.start_night()])
	assert_true(r.ok, "Start %s" % r.error)
	var s := r.state
	assert_true(s != null, "Start")
	var plan: Array = s.night_plan.map(func(k: StringName) -> String: return String(k))
	assert_eq(plan, ["pack", "classic-urwolf:1"], "Urwolf-Schritt direkt hinter dem Rudel")
	s = _until_urwolf_prompt(s, 3)
	assert_eq(s.pending_prompt.owner, PendingPrompt.OWNER_URWOLF, "Frage des Urwolfs")
	s = apply_ok(s, Command.answer_choice(s.pending_prompt.id, "use", true), "Verwandeln").state
	assert_eq(s.players[3].role_id, RoleCatalog.CLASSIC_WERWOLF, "Opfer ist Werwolf")
	assert_true(s.players[3].counts_as_wolf and s.players[3].alive, "lebt und zählt als Wolf")
	assert_eq(s.pack_target_id, GameState.NO_TARGET, "kein Opfer mehr")
	assert_true(ClassicWolfRules.ready_ids(s).is_empty(), "einmalig verbraucht")
	assert_true(s.players[3].alive and s.death_marks.is_empty(), "Opfer lebt, kein Tod vorgemerkt")


func test_urwolf_step_drops_when_victim_is_a_wolf() -> void:
	var r := RulesEngine.replay([Fixtures.start_roles([UW, W, D, D, D, D, D, D]), Command.start_night()])
	assert_true(r.ok, "Start %s" % r.error)
	var s := r.state
	s = _until_urwolf_prompt(s, 2)
	assert_true(s.pending_prompt == null or s.pending_prompt.owner != PendingPrompt.OWNER_URWOLF, "Wolf als Opfer: keine Frage")
	assert_false(s.players[1].ability_uses.has(ClassicWolfRules.USE_KEY), "Fähigkeit bleibt unverbraucht")


func test_white_wolf_strikes_every_second_night_and_wins_only_alone() -> void:
	var r := RulesEngine.replay([Fixtures.start_roles([WW, W, D, D, D, D]), Command.start_night()])
	assert_true(r.ok, "Start %s" % r.error)
	var s := r.state
	assert_false(SoloRules.lone_night(s, 1), "Nacht 1 kein Zusatzschritt")
	s.night_number = 2
	assert_true(SoloRules.lone_night(s, 1), "Nacht 2 ein Zusatzschritt")
	s.night_number = 3
	assert_false(SoloRules.lone_night(s, 1), "Nacht 3 keiner")
	assert_eq(SoloRules.lone_targets(s, 1), [2, 3, 4, 5, 6], "jede andere lebende Person, auch ein Werwolf")
	s.night_number = 1
	s = _gm_kill(s, 2)
	s = _gm_kill(s, 3)
	s = _gm_kill(s, 4)
	s = _gm_kill(s, 5)
	assert_true(s.open_candidates().is_empty(), "mit einem Dorfbewohner am Leben kein Sieg")
	s = _gm_kill(s, 6)
	var wins := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_LONE_WOLF)
	assert_eq(wins.size(), 1, "allein: Einzelsieg wird vorgeschlagen")
	assert_eq(wins[0].beneficiary_ids, [1], "Weißer Wolf gewinnt")
