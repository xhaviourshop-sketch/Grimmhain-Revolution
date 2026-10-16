extends TestCase
## Nachtlauf Regeln: Zustand, den eine per Totenreichkarte für eine Nacht geliehene Fähigkeit anlegt (Voodoo-Puppe, Nekromanten-Schild),
## muss ladbar sein (wie bei der geliehenen Feuerteufel-Markierung); die Puppe endet mit der geliehenen Fähigkeit.

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


## Nekromant (geliehen für Nacht 1) opfert drei Tote und erhält den Schild: der Zustand muss ladbar bleiben.
func test_shield_of_a_lent_necromancer_survives_save_and_load() -> void:
	var cmd := Fixtures.start_roles(["werwolf", D, "amalia", "detektiv", "nachtwaechter", "waechter-am-tor", "wahnsinniger-kutscher"])
	cmd.payload["death_cards"] = true
	var r := RulesEngine.apply(GameState.new(), cmd)
	assert_true(r.ok, "Start mit Totenreichkarten (%s)" % r.error)
	if not r.ok:
		return
	var s: GameState = r.state
	for dead_id: int in [3, 4, 5]:
		var k := KillEvent.new()
		k.target_id = dead_id
		k.cause = KillEvent.CAUSE_NIGHT_KILL
		k.source_kind = KillEvent.SOURCE_PACK
		k.phase = Phase.NIGHT
		k.phase_number = 1
		k.order_index = s.next_death_order
		s.next_death_order += 1
		s.players[dead_id].alive = false
		s.players[dead_id].death = k
	(s.cardsys["abilities"] as Array).append({"player_id": 2, "role_id": "nekromant", "night": 1})
	for c: Command in [Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:nekromant:2")]:
		r = RulesEngine.apply(s, c)
		assert_true(r.ok, "%s (%s)" % [c.type, r.error])
		if not r.ok:
			return
		s = r.state
	r = RulesEngine.apply(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [3, 4, 5]))
	assert_true(r.ok, "Opfer der drei Toten (%s)" % r.error)
	if not r.ok:
		return
	assert_eq(s.necro_shields.size() + r.state.necro_shields.size(), 1, "der geliehene Nekromant hält einen Schild")
	assert_true(GameState.from_dict(r.state.to_dict()) != null, "Zustand mit dem Schild ist ladbar")
