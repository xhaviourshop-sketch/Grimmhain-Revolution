extends TestCase
## Abschlusscheck der Totenreichkarten: nur die Lücken der besonders fehleranfälligen Abläufe, die andere Kartentests nicht
## belegen (wiederholtes Bestätigen beim Tausch, Phoenix-Fristen mit Ausschluss der Besitzerin und Ausnahme am Tagesende, Meister im
## Notanker, Schild gegen Kettentod, Kosmisches Gleichgewicht ohne Wiederauslösung). Alles über reguläre Befehle, Replay inklusive.

const COUNT := 16
const WOLVES: Array[int] = [1, 2, 3]
const WOLF_OWNER := 3
const VILLAGE_OWNER := 12


func _game(specials: Dictionary = {}, seed_value: int = 3) -> CardGame:
	return CardGame.started(self, COUNT, WOLVES, seed_value, specials)


func _persist(g: CardGame, label: String) -> void:
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)


func _state_text(g: CardGame) -> String:
	return CanonicalJson.stringify(g.state.to_dict())


# --- A: Kartentausch ----------------------------------------------------------------------------------------------

func test_exchange_cannot_be_confirmed_a_second_time() -> void:
	var g := CardGame.started(self, 7, [1], 6, {"5": "kartenschlucker"})
	g.gm_kill(3, false)
	g.give(3, &"schicksal_01")
	g.night()
	g.do(Command.card_act(3, "exchange"), "Tausch")
	g.settle()
	var effects_after := CardEffects.effects(g.state, "no_role_talk").size()
	assert_eq(SwallowerRules.total_of(g.state, 5), 1, "ein Stapel nach dem Tausch")
	var records_after := CardRules.records(g.state).size()
	var before := _state_text(g)
	for action: String in ["exchange", "play", "keep"]:
		assert_false(g.attempt(Command.card_act(3, action)).ok, "zweites Bestätigen (%s) abgelehnt" % action)
	assert_eq(_state_text(g), before, "kein Teilzustand durch wiederholtes Bestätigen")
	assert_eq(SwallowerRules.total_of(g.state, 5), 1, "kein zweiter Stapel")
	assert_eq(SwallowerRules.balance_of(g.state, 5), 1, "kein zweites Guthaben")
	assert_eq(CardRules.records(g.state).size(), records_after, "keine weitere Karte")
	assert_eq(CardEffects.effects(g.state, "no_role_talk").size(), effects_after, "keine Doppelwirkung")
	_persist(g, "Tausch zweimal bestätigt")


# --- B: Phoenix ---------------------------------------------------------------------------------------------------

## Spielt den Phoenix der Besitzerin 12 und liefert Würfelnotiz und Tag des Spielens. `at_day_end` spielt im zweiten Fenster.
func _phoenix(seed_value: int, at_day_end: bool) -> Array:
	var g := CardGame.started(self, COUNT, WOLVES, seed_value)
	for id: int in [5, 6, 7, 8]:
		g.gm_kill(id, false)
	g.arm(VILLAGE_OWNER, &"loki_10", -1, not at_day_end)
	if at_day_end:
		g.reach(VILLAGE_OWNER)
		g.do(Command.card_act(VILLAGE_OWNER, "keep"), "keep im ersten Fenster")
		g.skip_cards()
		g.end_day()
		if not g.window_for(VILLAGE_OWNER):
			return [g, {}, 0]
	var played_on := g.state.day_number
	g.play_with()
	var notes := g.events_of(GameEvent.CARD_EFFECT_NOTE).filter(func(e: GameEvent) -> bool: return e.data.has("revived_ids"))
	return [g, notes[0].data if notes.size() == 1 else {}, played_on]


func test_phoenix_stores_the_roll_excludes_the_owner_and_expires_exactly_on_time() -> void:
	var days_seen := {}
	for seed_value: int in range(1, 25):
		var r := _phoenix(seed_value, false)
		var g: CardGame = r[0]
		var note: Dictionary = r[1]
		assert_false(note.is_empty(), "seed %d: genau ein Würfelergebnis" % seed_value)
		if note.is_empty():
			return
		var revived: Array = note["revived_ids"]
		var days := int(note["days"])
		days_seen[days] = true
		assert_false(revived.has(VILLAGE_OWNER) or g.state.players[VILLAGE_OWNER].alive, "seed %d: die Besitzerin kehrt nicht zurück" % seed_value)
		assert_eq(revived.size(), mini(int((note["dice"] as Array)[0]), 4), "seed %d: so viele wie gewürfelt" % seed_value)
		var die_day := int(note["die_day"])
		assert_eq(die_day, int(r[2]) + days - 1, "seed %d: Frist ohne Ausnahme im ersten Fenster" % seed_value)
		var guard := 0
		while g.state.day_number < die_day and guard < 6:
			guard += 1
			g.next_night()
			for id: Variant in revived:
				assert_true(g.state.players[int(id)].alive, "seed %d: %d lebt vor Fristende (Tag %d)" % [seed_value, int(id), g.state.day_number])
		assert_eq(g.state.day_number, die_day, "seed %d: Fristtag erreicht" % seed_value)
		g.skip_cards()
		g.end_day()
		for id: Variant in revived:
			assert_false(g.state.players[int(id)].alive, "seed %d: %d starb am Ende des Fristtags" % [seed_value, int(id)])
		assert_false(g.has_effect("phoenix_return"), "seed %d: Fristeffekt entfernt" % seed_value)
		_persist(g, "phoenix seed %d" % seed_value)
	assert_true(days_seen.has(1) and days_seen.has(2) and days_seen.has(3), "alle Fristen 1, 2 und 3 Tage kamen vor (%s)" % str(days_seen.keys()))


func test_phoenix_played_at_day_end_with_one_day_lives_until_the_end_of_the_next_day() -> void:
	var proven := 0
	for seed_value: int in range(1, 40):
		var r := _phoenix(seed_value, true)
		var g: CardGame = r[0]
		var note: Dictionary = r[1]
		if note.is_empty() or int(note["days"]) != 1:
			continue
		proven += 1
		var played_on: int = r[2]
		var revived: Array = note["revived_ids"]
		assert_eq(int(note["die_day"]), played_on + 1, "seed %d: Ausnahme, Ende des Folgetags" % seed_value)
		g.night()
		assert_eq(g.state.day_number, played_on + 1, "Folgetag")
		for id: Variant in revived:
			assert_true(g.state.players[int(id)].alive, "seed %d: %d lebt am Folgetag" % [seed_value, int(id)])
		g.skip_cards()
		g.end_day()
		for id: Variant in revived:
			assert_false(g.state.players[int(id)].alive, "seed %d: %d starb am Ende des Folgetags" % [seed_value, int(id)])
		_persist(g, "phoenix am Tagesende seed %d" % seed_value)
		if proven >= 3:
			break
	assert_true(proven >= 1, "mindestens ein Fall mit einem Lebenstag im zweiten Fenster (%d)" % proven)


# --- C: Notanker und Lehrling -------------------------------------------------------------------------------------

func test_notanker_master_keeps_acting_and_the_win_check_counts_him_as_dead() -> void:
	var g := CardGame.started(self, 14, WOLVES, 3, {"13": "lehrling", "5": "schutzengel"})
	for id: int in g.state.alive_ids():
		if g.state.players[id].role_id == RoleCatalog.WAECHTER_AM_TOR:
			g.gm_set_role(id, "dorfbewohner")
	ApprenticeRules.set_master(RuleContext.new(g.state, g.state.command_count), 13, 5)
	g.arm(14, &"wende_05")
	g.play_with()
	g.skip_cards()
	g.do(Command.nominate(4, 5), "nominate")
	assert_true(g.attempt(Command.create(Command.DECIDE_EXECUTION, {"target_id": 5})).ok, "Hinrichtung des Meisters")
	assert_true(g.state.players[5].alive, "der Meister lebt (aufgeschoben)")
	var as_dead := g.state.duplicate_state()
	as_dead.players[5].alive = false
	assert_eq(CanonicalJson.stringify(WinRules.evaluate(g.state)), CanonicalJson.stringify(WinRules.evaluate(as_dead)), "Siegprüfung zählt den Meister bereits als tot")
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var meets_master := false
	var guard := 0
	while g.state.phase == Phase.NIGHT and guard < 40:
		guard += 1
		var p := g.state.pending_prompt
		if p != null and p.actor_id == 5:
			meets_master = true
			break
		if p != null:
			if p.owner == PendingPrompt.OWNER_PACK:
				g.do(Command.skip_step(p.step_id, "Test: ruhige Nacht"), "Rudel")
			else:
				g.answer_default(p)
		elif RulesEngine.next_step_id(g.state) != "":
			g.do(Command.begin_step(RulesEngine.next_step_id(g.state)), "begin")
		else:
			break
	assert_true(meets_master, "der aufgeschobene Meister wird in der Nacht weiterhin gefragt")


# --- E: Schild und Todesketten -------------------------------------------------------------------------------------

func test_personal_shield_stops_the_additional_fluch_12_death_without_a_substitute() -> void:
	var g := _game()
	g.arm(VILLAGE_OWNER, &"fluch_12")
	g.play_with()
	g.skip_cards()
	var shielded: Array = []
	for id: int in g.state.alive_ids():
		if id != 6 and g.state.players[id].faction == Faction.VILLAGE:
			shielded.append(id)
	(g.state.cardsys["shields"] as Array).append_array(shielded)
	var before_dead := g.dead_ids()
	g.lynch(6, 5)
	var died := g.dead_ids().filter(func(id: int) -> bool: return not before_dead.has(id))
	assert_eq(died, [6], "nur die gelynchte Person stirbt, kein Ersatzopfer")
	assert_eq((g.state.cardsys["shields"] as Array).size(), shielded.size() - 1, "genau ein Schild verbraucht")
	assert_false(g.has_effect("double_leid"), "Karte verbraucht")
	assert_true(g.state.pending_prompt == null, "keine offene Ersatzwahl")
	# Schilde wurden direkt gesetzt (kein Befehl): daher gilt Speichern und Laden des Zustands statt Replay.
	assert_eq(CanonicalJson.stringify(GameState.from_dict(g.state.to_dict()).to_dict()), _state_text(g), "Speichern und Laden gleich")
	assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand konsistent")


func test_cosmic_balance_does_not_trigger_again_for_its_own_direct_and_indirect_deaths() -> void:
	var g := _game({"8": "sensentraeger"})
	g.arm(WOLF_OWNER, &"loki_12")
	g.play_with()
	g.skip_cards()
	g.lynch(1, 5)
	var task := g.state.pending_prompt
	assert_true(task != null and task.owner == PendingPrompt.OWNER_CARD, "Aufgabe: Opfer der anderen Seite")
	assert_true(task.allowed_ids.has(8), "der Sensenträger ist wählbar")
	g.do(Command.answer_stage_targets(task.id, "pick", [8]), "Opfer: Sensenträger")
	assert_false(g.state.players[8].alive, "der Sensenträger starb durch die Karte")
	var guard := 0
	while guard < 12 and (g.state.pending_prompt != null or StepQueue.reactions_due(g.state)):
		guard += 1
		var p := g.state.pending_prompt
		assert_false(p != null and p.owner == PendingPrompt.OWNER_CARD, "keine zweite Aufgabe des Kosmischen Gleichgewichts")
		if p == null:
			g.do(Command.begin_step(RulesEngine.next_step_id(g.state)), "Reaktion")
		elif p.owner == PendingPrompt.OWNER_REACTION:
			g.do(Command.answer_prompt(p.id, [p.allowed_ids[0]]), "der Sensenträger schießt")
		else:
			g.answer_default(p)
	assert_true((g.state.cardsys["tasks"] as Array).is_empty(), "keine Aufgabe in der Warteschlange")
	var shot := g.state.players.values().filter(func(p: Player) -> bool: return not p.alive and p.death != null and p.death.cause == KillEvent.CAUSE_HUNTER_SHOT)
	assert_eq(shot.size(), 1, "die Folge des Sensenträgers (Schuss) fand statt und löste nichts Weiteres aus")
	assert_eq(g.dead_ids().size(), 4, "genau vier Tote: Besitzerin, gelynchter Wolf, Sensenträger, Opfer des Schusses")
	_persist(g, "kosmisches Gleichgewicht ohne Wiederauslösung")
