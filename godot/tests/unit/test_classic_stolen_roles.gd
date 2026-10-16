extends TestCase
## Nachtlauf Regeln: Stiehlt der Grabräuber (oder eine Totenreichkarte verleiht) eine Classic-Rolle, läuft der Schritt über die
## Mechanik der Rolle (wie bei der eigenen Classic-Rolle). Vorher fiel der Schritt auf die Schutzengel-Abfrage zurück.

const MECH_OF := {"classic-seherin": "das-orakel", "classic-hexe": "waldhexe", "classic-fuchs": "spuerhund",
	"classic-floetenspieler": "rattenfaenger", "classic-engel": "schutzengel"}


func _robbed_state(stolen: String) -> GameState:
	var r := RulesEngine.apply(GameState.new(), Fixtures.start_roles(["werwolf", "grabraeuber", stolen, "dorfbewohner", "amalia", "detektiv", "nachtwaechter", "waechter-am-tor"]))
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return null
	var s: GameState = r.state
	var k := KillEvent.new()
	k.target_id = 3
	k.cause = KillEvent.CAUSE_NIGHT_KILL
	k.source_kind = KillEvent.SOURCE_PACK
	k.phase = Phase.NIGHT
	k.phase_number = 1
	k.order_index = s.next_death_order
	s.next_death_order += 1
	s.players[3].alive = false
	s.players[3].death = k
	SoloRules.grave_steal(RuleContext.new(s, s.command_count), 2, 3)
	return s


func test_a_robber_of_a_classic_role_acts_through_its_mechanic() -> void:
	for stolen: String in MECH_OF:
		var mech: String = MECH_OF[stolen]
		var s := _robbed_state(stolen)
		if s == null:
			return
		var r := RulesEngine.apply(s, Command.start_night())
		assert_true(r.ok, "%s: Nacht (%s)" % [stolen, r.error])
		if not r.ok:
			return
		s = r.state
		assert_true(s.night_plan.has(StringName("%s:2" % mech)), "%s: der Plan nennt den Schritt %s" % [stolen, mech])
		for i: int in 6:
			if s.pending_prompt != null and s.pending_prompt.owner != PendingPrompt.OWNER_PACK:
				break
			var c := Command.begin_step(StepQueue.next_step_id(s)) if s.pending_prompt == null else Command.answer_prompt(s.pending_prompt.id, [8])
			r = RulesEngine.apply(s, c)
			assert_true(r.ok, "%s: %s (%s)" % [stolen, c.type, r.error])
			if not r.ok:
				return
			s = r.state
		assert_true(s.pending_prompt != null and String(s.pending_prompt.owner) == mech, "%s: die Abfrage gehört zu %s statt zum Schutzengel (ist: %s)" % [stolen, mech, "-" if s.pending_prompt == null else s.pending_prompt.owner])
		assert_true(GameState.from_dict(s.to_dict()) != null, "%s: Zustand ladbar" % stolen)


func test_a_card_granting_a_classic_role_stores_its_mechanic() -> void:
	var cmd := Fixtures.start_roles(["werwolf", "dorfbewohner", "amalia", "detektiv", "nachtwaechter", "waechter-am-tor"])
	cmd.payload["death_cards"] = true
	var r := RulesEngine.apply(GameState.new(), cmd)
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return
	r = RulesEngine.apply(r.state, Command.start_night())
	assert_true(r.ok, "Nacht 1 (%s)" % r.error)
	if not r.ok:
		return
	var s: GameState = r.state
	CardFxAbility.grant_role(RuleContext.new(s, s.command_count), {"card": "test"}, 2, &"classic-seherin", 1)
	var abilities: Array = s.cardsys["abilities"]
	assert_eq(abilities.size(), 1, "eine verliehene Fähigkeit")
	assert_eq(String(abilities[0]["role_id"]) if not abilities.is_empty() else "", "das-orakel", "gespeichert unter der Mechanik")
	assert_true(SoloRules.acts_as(s, 2, RoleCatalog.ORAKEL), "die Person handelt als Orakel")
	assert_true(GameState.from_dict(s.to_dict()) != null, "Zustand ladbar")


## Wie das Wolfskind des Grundspiels kann auch das wilde Kind (Mechanik Wolfskind) nicht gestohlen oder geliehen werden:
## seine Fähigkeit ist ein eigener Rollenwechsel in Nacht 1.
func test_the_wild_child_cannot_be_stolen_like_the_base_game_wolf_child() -> void:
	assert_false(RoleCatalog.stealable(RoleCatalog.WOLFSKIND), "Wolfskind des Grundspiels")
	assert_false(RoleCatalog.stealable(RoleCatalog.CLASSIC_WILDES_KIND), "wildes Kind")


## Nachtlauf Regeln: Die gestohlene Classic-Seherin sieht wie die eigene die wahre Rolle, auch bei Sonderwölfen (nicht die Scheinrolle).
func test_a_robber_of_the_classic_seer_sees_the_true_role() -> void:
	var r := RulesEngine.apply(GameState.new(), Fixtures.start_roles(["werwolf", "grabraeuber", "classic-seherin", "classic-urwolf", "amalia", "detektiv", "nachtwaechter", "waechter-am-tor"]))
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return
	var s: GameState = r.state
	var urwolf := s.players[4]
	assert_eq(InformationRules.determine_role(urwolf, s.players[2], s), RoleCatalog.WERWOLF, "vor dem Diebstahl: Scheinrolle Werwolf")
	s = _robbed_state("classic-seherin")
	s.players[1].role_id = &"classic-urwolf"
	assert_eq(InformationRules.determine_role(s.players[1], s.players[2], s), &"classic-urwolf", "Grabräuber mit Seherin sieht die wahre Rolle")
	assert_eq(InformationRules.determine_role(s.players[1], s.players[4], s), RoleCatalog.WERWOLF, "andere Personen sehen weiter die Scheinrolle")
