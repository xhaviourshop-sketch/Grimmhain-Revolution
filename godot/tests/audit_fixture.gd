extends RefCounted
## Gemeinsame Hilfen für die Regressionstests der Audit-Reparaturen (AUDIT-2026-10-02, Paket A).
## Per `preload` eingebunden, keine eigene Klasse: kein class_name-Import nötig.


static func start(t: TestCase, roles: Array, cards: bool = false, seed_value: int = 1) -> GameState:
	var payload := Fixtures.start_roles(roles, seed_value).payload.duplicate(true)
	if cards:
		payload["death_cards"] = true
	var r := RulesEngine.apply(GameState.new(), Command.start_game(payload))
	t.assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


static func gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


static func ok(t: TestCase, s: GameState, c: Command, label: String) -> GameState:
	return t.apply_ok(s, c, label).state if s != null else null


static func auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.owner == PendingPrompt.OWNER_WITCH:
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm")
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Spielt die Nacht bis vor EndNight. `answers`: "<rolle>:<id>@<stufe>" -> Zielliste | Callable(prompt) -> Command;
## "pack@" -> Rudelopfer. Unbeantwortete Schritte beantwortet `auto`.
static func night(t: TestCase, s: GameState, answers: Dictionary = {}) -> GameState:
	if s != null and s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = ok(t, s, Command.decide_execution(-1), "no execution")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = ok(t, s, Command.end_day(), "end day")
	if s != null and s.phase != Phase.NIGHT:
		s = ok(t, s, Command.start_night(), "start night")
	for guard: int in 80:
		if s == null:
			return null
		var cmd: Command = null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
			var staged := "%s@%s" % [key, p.stage]
			if answers.has(staged) and answers[staged] is Callable:
				cmd = (answers[staged] as Callable).call(p)
			elif answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.answer_prompt(p.id, [])
			else:
				cmd = auto(s)
		else:
			var step := RulesEngine.next_step_id(s)
			if step == "":
				return s
			cmd = Command.begin_step(step)
		s = ok(t, s, cmd, "night command")
	t.fail("Nacht endet nicht")
	return null


static func dawn(t: TestCase, s: GameState, answers: Dictionary = {}) -> GameState:
	s = night(t, s, answers)
	return ok(t, s, Command.end_night(), "end night") if s != null else null


## Wie der Speicherpfad: ein Zustand muss sich nach Rundreise über `to_dict` wieder laden lassen.
static func reloads(s: GameState) -> bool:
	return GameState.from_dict(s.to_dict()) != null
