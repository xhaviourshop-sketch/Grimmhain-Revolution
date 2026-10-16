extends TestCase
## Nachtlauf Regeln: Eine per Totenreichkarte für eine Nacht geliehene Voodoo-Fähigkeit legt eine Puppe an. Der Zustand muss
## danach ladbar sein (wie bei der geliehenen Feuerteufel-Markierung), und die Puppe endet mit der geliehenen Fähigkeit.

const D := "dorfbewohner"


func _lent_night() -> GameState:
	var cmd := Fixtures.start_roles(["werwolf", D, "amalia", "detektiv", "nachtwaechter", "waechter-am-tor"])
	cmd.payload["death_cards"] = true
	var r := RulesEngine.apply(GameState.new(), cmd)
	assert_true(r.ok, "Start mit Totenreichkarten (%s)" % r.error)
	if not r.ok:
		return null
	var s: GameState = r.state
	(s.cardsys["abilities"] as Array).append({"player_id": 2, "role_id": "voodoo-priester", "night": 1})
	r = RulesEngine.apply(s, Command.start_night())
	assert_true(r.ok, "Nacht 1 (%s)" % r.error)
	s = r.state
	for i: int in 12:
		if s.phase != Phase.NIGHT or (s.pending_prompt == null and StepQueue.next_step_id(s) == ""):
			break
		var c: Command
		if s.pending_prompt == null:
			c = Command.begin_step(StepQueue.next_step_id(s))
		elif s.pending_prompt.owner == PendingPrompt.OWNER_PACK:
			c = Command.answer_prompt(s.pending_prompt.id, [6])
		elif String(s.pending_prompt.stage) == "shown":
			c = Command.answer_choice(s.pending_prompt.id, "shown", true)
		else:
			c = Command.answer_prompt(s.pending_prompt.id, [3])
		r = RulesEngine.apply(s, c)
		assert_true(r.ok, "Schritt %d: %s (%s)" % [i, c.type, r.error])
		if not r.ok:
			return null
		s = r.state
	return s


func test_doll_of_a_lent_voodoo_step_survives_save_and_load() -> void:
	var s := _lent_night()
	if s == null:
		return
	assert_eq(SoloRules.doll_of(s, 2), 3, "die geliehene Fähigkeit hat die Puppe vergeben")
	assert_true(GameState.from_dict(s.to_dict()) != null, "Zustand mit der Puppe ist ladbar")


func test_doll_ends_when_the_lent_ability_ends() -> void:
	var s := _lent_night()
	if s == null:
		return
	s.night_number = 2  # die Karte galt nur für Nacht 1
	CardRules.begin_night(RuleContext.new(s, s.command_count))
	assert_eq(SoloRules.doll_of(s, 2), GameState.NO_TARGET, "die Puppe endet mit der geliehenen Fähigkeit")
	assert_true(GameState.from_dict(s.to_dict()) != null, "Zustand ohne Puppe ist ladbar")
