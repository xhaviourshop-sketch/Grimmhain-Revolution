extends TestCase
## Hinweis bei fünf Toten (DI-09, NQ-01): Er gehört zum ersten Erreichen von fünf öffentlich Toten, wird höchstens einmal
## gemeldet und ist nur berechtigt, wenn dann eine lebende Person die Rolle Selbstmörder hat (auch geerbt). Er ist eine reine
## Darstellungsmeldung von GameSession (`cue_requested`): keine Wirkung auf den Zustand, kein Zufall, kein Name, keine Meldung
## beim Laden, Rückgängig, Wiederholen oder Neuzeichnen.
## 12 Personen: 1 Werwolf, 2 Blutwolf, 3 Selbstmörder, 4–12 wirkungsarme Dorfrollen (4 Dorfbewohner, 5 Amalia, 6 Detektiv,
## 7 Wahnsinniger Kutscher, 8 Wächter am Tor, 9 Der Weise, 10 Nachtwächter, 11 Ritter, 12 Dorfwache).

const SM := "selbstmoerder"


func _roles() -> Array:
	return ["werwolf", "blutwolf", SM] + Fixtures.village_fillers(9)


## Selbstmörder auf Platz 6, Kutscher auf Platz 7: Die Nachbarn des Kutschers sind 6 (Selbstmörder) und 8.
func _roles_sm_next_to_coachman() -> Array:
	return ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", SM, "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter", "dorfwache"]


func _roles_without_sm() -> Array:
	return ["werwolf", "blutwolf", "dorfbewohner"] + Fixtures.village_fillers(9, ["dorfbewohner"])


func _kill(id: int, effects: bool = false) -> Command:
	return CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": effects}, "Test")


## Sitzung mit Zähler der Hinweise; danach Nacht 1 und Tag 1. Das Rudel muss jede Nacht töten: Sein Opfer (der Dorfbewohner) wird am Tag
## wiederbelebt, damit die Zählung der Toten wie vorgesehen bei null beginnt.
func _day(roles: Array, cues: Array) -> GameSession:
	var s := GameSession.new()
	s.cue_requested.connect(func(cue: StringName) -> void: cues.append(String(cue)))
	assert_true(s.submit(Fixtures.start_roles(roles, 1)).ok, "Start")
	assert_true(s.submit(Command.start_night()).ok, "Nacht 1")
	var victim := roles.find("dorfbewohner") + 1
	assert_true(s.submit(Command.answer_prompt(1, [victim])).ok, "Opfer ohne Bedeutung")
	assert_true(s.submit(Command.end_night()).ok, "Tag 1")
	_revive(s, victim)
	assert_eq(String(s.view()["phase"]), "DAY", "Tag")
	return s


func _kills(s: GameSession, ids: Array, effects: bool = false) -> void:
	for id: int in ids:
		assert_true(s.submit(_kill(id, effects)).ok, "%d getötet" % id)


func test_living_death_seeker_gives_one_hint_at_the_fifth_death_only() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [4, 5, 6, 9])
	assert_eq(cues, [], "bei vier Toten kein Hinweis")
	_kills(s, [10])
	assert_eq(cues, ["five_dead"], "genau ein Hinweis bei der fünften Person, nur mit der Kennung")
	_kills(s, [11, 12])
	assert_eq(cues, ["five_dead"], "weitere Tote lösen nichts aus")


func test_dead_death_seeker_gives_no_hint() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [3, 4, 5, 6, 9, 10, 11])
	assert_eq(cues, [], "Selbstmörder ist tot: kein Hinweis, auch bei sieben Toten")


func test_no_death_seeker_in_the_game_gives_no_hint() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10, 11])
	assert_eq(cues, [], "keine Selbstmörder-Rolle: kein Hinweis")


func test_death_seeker_role_created_later_counts_when_alive() -> void:
	# Spielleiterkorrektur setzt die Rolle: zählt wie jede aktuelle Rolle (Rolle von Person 12 wird Selbstmörder, Person 3 stirbt).
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle gesetzt")
	_kills(s, [4, 5, 6, 9, 10])
	assert_eq(cues, ["five_dead"], "aktuell lebende Person mit der Rolle zählt")


func test_inherited_death_seeker_role_counts_and_dead_heir_does_not() -> void:
	for heir_alive: bool in [true, false]:
		var cues: Array = []
		var s := GameSession.new()
		s.cue_requested.connect(func(cue: StringName) -> void: cues.append(String(cue)))
		# 1 Werwolf, 2 Blutwolf, 3 Selbstmörder (Meister), 4 Lehrling, 5–12 wirkungsarme Dorfrollen.
		var roles: Array = ["werwolf", "blutwolf", SM, "lehrling"] + Fixtures.village_fillers(8, ["dorfbewohner"])
		for c: Command in _night_one_with_bound_apprentice(roles):
			assert_true(s.submit(c).ok, "Vorbereitung %s angenommen" % c.type)
		assert_eq(String(s.view()["phase"]), "DAY", "Tag 1 erreicht")
		if not heir_alive:
			_kills(s, [4])  # Lehrling stirbt zuerst: kein Erbe
		_kills(s, [3], true)  # Meister stirbt; ein lebender Lehrling erbt den Selbstmörder
		_kills(s, [5, 6, 7, 8] if heir_alive else [5, 6, 7])
		assert_eq(cues, ["five_dead"] if heir_alive else [], "geerbte Rolle einer lebenden Person zählt, ein toter Erbe nicht (Erbe lebt: %s)" % heir_alive)
		if heir_alive:
			assert_eq(String(s.private_seats()[3]["role_id"]), SM, "Lehrling ist jetzt Selbstmörder")


## Nacht 1 mit Bindung des Lehrlings (4) an den Selbstmörder (3) bis Tag 1 (Befehlsliste, am Zustand geführt). Das Rudel tötet 5; die
## Person wird am Tag wiederbelebt, damit die Zählung der Toten bei null beginnt.
func _night_one_with_bound_apprentice(roles: Array) -> Array[Command]:
	var log: Array[Command] = [Fixtures.start_roles(roles, 1), Command.start_night()]
	var state := RulesEngine.apply(GameState.new(), log[0]).state
	state = RulesEngine.apply(state, log[1]).state
	var guard := 0
	while state.phase == Phase.NIGHT and guard < 40:
		guard += 1
		var c: Command
		var p := state.pending_prompt
		if p == null:
			var next := RulesEngine.next_step_id(state)
			c = Command.end_night() if next == "" else Command.begin_step(next)
		elif p.owner == &"lehrling":
			c = Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "master", "targets": [3]})
		elif p.owner == &"pack":
			c = Command.answer_prompt(p.id, [5])
		else:
			c = Command.answer_prompt(p.id, Fixtures.pass_targets(state, p))
		var r := RulesEngine.apply(state, c)
		assert_true(r.ok, "Nachtbefehl %s angenommen (%s)" % [c.type, r.error])
		if not r.ok:
			break
		state = r.state
		log.append(c)
	log.append(CorrectionFixtures.gm("revive", {"target_id": 5}, "Test"))
	return log


func test_death_chain_gives_one_hint_and_uses_the_final_state() -> void:
	# Die Hinrichtung des Wahnsinnigen Kutschers (7) nimmt seine Nachbarn 6 und 8 mit: drei Tode in einem Befehl.
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [4, 5, 9])
	assert_eq(cues, [], "drei Tote: noch kein Hinweis")
	assert_true(s.nominate(1, 7).ok, "Nominierung")
	assert_true(s.decide_execution(7).ok, "Hinrichtung mit Todeskette")
	assert_eq(cues, ["five_dead"], "die Kette überschreitet fünf Tote: genau ein Hinweis")
	# Stirbt der Selbstmörder in derselben Kette, ist er im Endzustand tot: kein Hinweis.
	var other: Array = []
	var t := _day(_roles_sm_next_to_coachman(), other)
	_kills(t, [3, 4, 9])
	assert_true(t.nominate(1, 7).ok, "Nominierung")
	assert_true(t.decide_execution(7).ok, "Hinrichtung, Kette trifft den Selbstmörder")
	assert_eq(other, [], "Selbstmörder in der Kette gestorben: kein Hinweis")


func test_hint_is_given_at_the_morning_when_the_fifth_person_dies_in_the_night() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [4, 5, 9, 10])
	assert_true(s.decide_execution(-1).ok, "keine Hinrichtung")
	assert_true(s.end_day().ok, "Tag beendet")
	assert_true(s.start_night().ok, "Nacht 2")
	for guard: int in 10:  # andere Nachtschritte (Nacht 2) beantworten, bis der Rudelschritt offen ist
		var next: Dictionary = s.cockpit_view()["next"]
		if str(next["kind"]) == "prompt" and str(next["owner"]) == "pack":
			assert_true(s.answer_targets([6]).ok, "Rudelopfer 6")
			break
		if str(next["kind"]) == "prompt":
			assert_true(s.answer_targets([] if int(next["min"]) == 0 else [int(next["allowed_ids"][0])]).ok, "anderer Schritt beantwortet")
		elif str(next["kind"]) == "begin_step":
			assert_true(s.begin_next_step().ok, "Schritt begonnen")
		else:
			break
	assert_eq(cues, [], "in der Nacht nichts, Tode werden erst am Morgen öffentlich")
	assert_true(s.end_night().ok, "Morgen")
	assert_eq(int(s.summary()["alive_count"]), 7, "fünf Tote nach dem Morgen")
	assert_eq(cues, ["five_dead"], "der Hinweis kommt mit der Morgenauflösung")


func test_hint_is_given_only_once_even_after_revival_and_a_new_fifth_death() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	assert_eq(cues, ["five_dead"], "erster Hinweis")
	assert_true(s.submit(CorrectionFixtures.gm("revive", {"target_id": 10}, "Test")).ok, "Wiederbelebung: vier Tote")
	_kills(s, [11])
	assert_eq(cues, ["five_dead"], "erneut fünf Tote: kein zweiter Hinweis")


func _revive(s: GameSession, id: int) -> void:
	assert_true(s.submit(CorrectionFixtures.gm("revive", {"target_id": id}, "Test")).ok, "%d wiederbelebt" % id)


## Entscheidung B: Ein erfolgloser erster Versuch (kein lebender Selbstmörder) verbraucht den Hinweis nicht.
func test_unsuccessful_first_crossing_does_not_use_up_the_hint() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [3, 4, 5, 6, 9])
	assert_eq(cues, [], "erste Schwelle ohne lebenden Selbstmörder: kein Hinweis")
	_revive(s, 3)  # vier Tote, Selbstmörder lebt
	_kills(s, [10])
	assert_eq(cues, ["five_dead"], "zweite Schwelle mit lebendem Selbstmörder: genau ein Hinweis")
	_kills(s, [11, 12])
	assert_eq(cues, ["five_dead"], "weitere Tode: keine zweite Auslösung")
	_revive(s, 10)
	_kills(s, [10])
	assert_eq(cues, ["five_dead"], "nach der Auslösung bleibt die Einmal-Regel")


func test_unsuccessful_crossing_with_no_death_seeker_in_the_game_stays_silent_through_revivals() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	_revive(s, 10)
	_kills(s, [10, 11])
	assert_eq(cues, [], "ohne Selbstmörder-Rolle nie ein Hinweis")


## Rollenübernahme: Der Meister (3) stirbt erst ohne Wirkung, wird wiederbelebt und stirbt dann mit Wirkung; der Lehrling (4) erbt.
func test_inherited_role_counts_at_the_second_crossing() -> void:
	var cues: Array = []
	var s := GameSession.new()
	s.cue_requested.connect(func(cue: StringName) -> void: cues.append(String(cue)))
	var roles: Array = ["werwolf", "blutwolf", SM, "lehrling"] + Fixtures.village_fillers(8, ["dorfbewohner"])
	for c: Command in _night_one_with_bound_apprentice(roles):
		assert_true(s.submit(c).ok, "Vorbereitung %s angenommen" % c.type)
	_kills(s, [3, 5, 6, 7, 8])  # Meister ohne Wirkung tot: Lehrling ist noch kein Selbstmörder
	assert_eq(cues, [], "erste Schwelle: niemand lebt als Selbstmörder")
	_revive(s, 3)
	_kills(s, [3], true)  # fünf Tote wieder erreicht, der Lehrling erbt in derselben Kette
	assert_eq(String(s.private_seats()[3]["role_id"]), SM, "Lehrling ist jetzt Selbstmörder")
	assert_eq(cues, ["five_dead"], "geerbte Rolle einer lebenden Person löst beim zweiten Erreichen aus")


func test_second_crossing_after_save_and_load_gives_exactly_one_hint() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [3, 4, 5, 6, 9])
	_revive(s, 3)
	var loaded_cues: Array = []
	var loaded := GameSession.new()
	loaded.cue_requested.connect(func(cue: StringName) -> void: loaded_cues.append(String(cue)))
	assert_eq(loaded.load_text(s.save_text()), &"", "zwischen den Schwellen gespeichert und geladen")
	assert_eq(loaded_cues, [], "Laden meldet nichts")
	_kills(loaded, [10])
	assert_eq(loaded_cues, ["five_dead"], "nach dem Laden: zweites Erreichen löst genau einmal aus")
	_kills(loaded, [11])
	assert_eq(loaded_cues, ["five_dead"], "weitere Tode: keine zweite Auslösung")
	# Nach der tatsächlichen Auslösung gespeichert: der Hinweis bleibt verbraucht.
	var again: Array = []
	var reloaded := GameSession.new()
	reloaded.cue_requested.connect(func(cue: StringName) -> void: again.append(String(cue)))
	assert_eq(reloaded.load_text(loaded.save_text()), &"", "nach der Auslösung geladen")
	_revive(reloaded, 10)
	_revive(reloaded, 11)  # vier Tote
	_kills(reloaded, [10])
	assert_eq(again, [], "nach Laden einer ausgelösten Partie bleibt die Einmal-Regel")


func test_undo_of_the_successful_second_crossing_allows_it_again_and_redo_stays_silent() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [3, 4, 5, 6, 9])
	_revive(s, 3)
	_kills(s, [10])
	assert_eq(cues, ["five_dead"], "Auslösung")
	assert_true(s.undo(), "zurückgenommen")
	assert_true(s.redo(), "wiederholt")
	assert_eq(cues, ["five_dead"], "Wiederholen meldet nichts")
	_kills(s, [11])
	assert_eq(cues, ["five_dead"], "nach Wiederholen bleibt der Hinweis verbraucht")
	var r: Array = []
	var t := _day(_roles(), r)
	_kills(t, [3, 4, 5, 6, 9])
	_revive(t, 3)
	_kills(t, [10])
	assert_true(t.undo(), "zweites Erreichen zurückgenommen")
	_kills(t, [11])
	assert_eq(r, ["five_dead", "five_dead"], "zurückgenommene Auslösung zählt nicht: das neue Erreichen löst erneut aus")


## Entscheidung 6B (Decision Log): Sind schon fünf Personen tot und erhält danach eine lebende Person die Rolle Selbstmörder
## (Spielleiterkorrektur oder Rollenübernahme), darf der Hinweis genau einmal kommen, sofern er noch nicht ausgelöst wurde.
func test_role_gain_while_five_are_already_dead_gives_exactly_one_hint() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	assert_eq(cues, [], "fünf Tote, kein Selbstmörder: kein Hinweis, nichts verbraucht")
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle gesetzt")
	assert_eq(cues, ["five_dead"], "lebende Person erhält die Rolle: genau ein Hinweis")
	_kills(s, [11])
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 8, "role_id": SM}, "Test")).ok, "zweite Rolle gesetzt")
	assert_eq(cues, ["five_dead"], "weitere Befehle und Rollenwechsel lösen keinen zweiten Hinweis aus")
	assert_false(JSON.stringify(cues).contains("selbst"), "der Hinweis trägt nur seine Kennung")


func test_role_gain_by_a_dead_person_or_under_five_dead_gives_no_hint() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 4, "role_id": SM}, "Test")).ok, "tote Person erhält die Rolle")
	assert_eq(cues, [], "eine tote Person mit der Rolle reicht nicht")
	var under: Array = []
	var t := _day(_roles_without_sm(), under)
	_kills(t, [4, 5, 6, 9])
	assert_true(t.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle bei vier Toten")
	assert_eq(under, [], "unter fünf Toten keine Auslösung durch die Rolle")
	_kills(t, [10])
	assert_eq(under, ["five_dead"], "das Erreichen von fünf löst danach wie gewohnt aus")


func test_role_gain_after_save_and_load_gives_exactly_one_hint() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	var loaded_cues: Array = []
	var loaded := GameSession.new()
	loaded.cue_requested.connect(func(cue: StringName) -> void: loaded_cues.append(String(cue)))
	assert_eq(loaded.load_text(s.save_text()), &"", "vor der Rollenübernahme gespeichert und geladen")
	assert_eq(loaded_cues, [], "Laden meldet nichts")
	assert_true(loaded.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle nach dem Laden")
	assert_eq(loaded_cues, ["five_dead"], "genau ein Hinweis nach dem Laden")
	# Nach der Auslösung gespeichert: bleibt verbraucht.
	var again: Array = []
	var reloaded := GameSession.new()
	reloaded.cue_requested.connect(func(cue: StringName) -> void: again.append(String(cue)))
	assert_eq(reloaded.load_text(loaded.save_text()), &"", "nach der Auslösung geladen")
	assert_true(reloaded.submit(CorrectionFixtures.gm("set_role", {"target_id": 8, "role_id": SM}, "Test")).ok, "weitere Rolle")
	assert_eq(again, [], "bereits ausgelöster Hinweis bleibt verbraucht")


func test_role_gain_undo_and_redo() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle")
	assert_true(s.undo(), "zurückgenommen")
	assert_true(s.redo(), "wiederholt")
	assert_eq(cues, ["five_dead"], "Wiederholen meldet nichts")
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 8, "role_id": SM}, "Test")).ok, "weitere Rolle")
	assert_eq(cues, ["five_dead"], "nach Wiederholen bleibt der Hinweis verbraucht")
	var r: Array = []
	var t := _day(_roles_without_sm(), r)
	_kills(t, [4, 5, 6, 9, 10])
	assert_true(t.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle")
	assert_true(t.undo(), "Auslösung zurückgenommen")
	assert_true(t.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle erneut")
	assert_eq(r, ["five_dead", "five_dead"], "zurückgenommene Auslösung zählt nicht")


## Rollenübernahme in der Nacht: Der Meister (3) stirbt am Tag ohne Wirkung; fünf Tote, kein lebender Selbstmörder.
## In der Nacht erbt der Lehrling nicht (Meister ist schon tot); die Berechtigung entsteht durch eine Korrektur in der Nacht und
## wird erst mit der Morgenauflösung öffentlich.
func test_role_gained_during_the_night_is_announced_at_the_morning() -> void:
	var cues: Array = []
	var s := _day(_roles_without_sm(), cues)
	_kills(s, [4, 5, 6, 9, 10])
	assert_true(s.decide_execution(-1).ok, "keine Hinrichtung")
	assert_true(s.end_day().ok, "Tag beendet")
	assert_true(s.start_night().ok, "Nacht 2")
	assert_true(s.submit(CorrectionFixtures.gm("set_role", {"target_id": 12, "role_id": SM}, "Test")).ok, "Rolle in der Nacht")
	assert_eq(cues, [], "in der Nacht nichts, nichts an geheimen Änderungen öffentlich")
	for guard: int in 12:
		var next: Dictionary = s.cockpit_view()["next"]
		if str(next["kind"]) == "prompt":
			assert_true(s.answer_targets([] if int(next["min"]) == 0 else [int(next["allowed_ids"][0])]).ok, "Schritt beantwortet")
		elif str(next["kind"]) == "begin_step":
			assert_true(s.begin_next_step().ok, "Schritt begonnen")
		else:
			break
	assert_eq(cues, [], "bis zum Nachtende nichts")
	assert_true(s.end_night().ok, "Morgen")
	assert_eq(cues, ["five_dead"], "der Hinweis kommt mit der Morgenauflösung, genau einmal")


## NICHT ENTSCHIEDEN (Decision Log, Entscheidung 6B): Wird ein toter Selbstmörder wiederbelebt und bleiben dabei fünf oder mehr
## Personen tot, ist das keine Rollenübernahme und kein neues Erreichen der Schwelle. Das ist das bisherige Verhalten, keine Regel.
func test_open_case_reviving_the_death_seeker_while_five_stay_dead_is_unchanged() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [3, 4, 5, 6, 9, 10])
	assert_eq(cues, [], "sechs Tote, Selbstmörder tot: kein Hinweis")
	_revive(s, 3)
	assert_eq(cues, [], "ungeklärter Sonderfall: Wiederbelebung bei weiter fünf Toten löst nichts aus")


func test_no_hint_on_load_undo_redo_or_repeated_rendering() -> void:
	var cues: Array = []
	var s := _day(_roles(), cues)
	_kills(s, [4, 5, 6, 9])
	_kills(s, [10])
	assert_eq(cues, ["five_dead"], "Hinweis durch den Befehl")
	for i: int in 5:
		s.cockpit_view()
		s.view()
		s.private_seats()
	assert_eq(cues, ["five_dead"], "wiederholtes Rendern meldet nichts")
	# Laden: kein Hinweis beim Laden und keiner beim nächsten Tod.
	var loaded_cues: Array = []
	var loaded := GameSession.new()
	loaded.cue_requested.connect(func(cue: StringName) -> void: loaded_cues.append(String(cue)))
	assert_eq(loaded.load_text(s.save_text()), &"", "geladen")
	_kills(loaded, [11])
	assert_eq(loaded_cues, [], "nach dem Laden weder beim Laden noch danach (fünf Tote waren schon öffentlich)")
	# Ein geladener Stand mit vier Toten meldet den Hinweis beim fünften Tod genau einmal.
	var early := _day(_roles(), [])
	_kills(early, [4, 5, 6, 9])
	var early_cues: Array = []
	var resumed := GameSession.new()
	resumed.cue_requested.connect(func(cue: StringName) -> void: early_cues.append(String(cue)))
	assert_eq(resumed.load_text(early.save_text()), &"", "Stand mit vier Toten geladen")
	_kills(resumed, [10])
	assert_eq(early_cues, ["five_dead"], "geladene Partie: Hinweis beim fünften Tod")
	# Rückgängig und Wiederholen melden nichts; der zurückgenommene fünfte Tod darf später erneut auslösen.
	var hint: Array = []
	var u := _day(_roles(), hint)
	_kills(u, [4, 5, 6, 9, 10])
	assert_eq(hint, ["five_dead"], "Hinweis")
	assert_true(u.undo(), "fünfter Tod zurückgenommen")
	assert_true(u.redo(), "Wiederholen")
	assert_eq(hint, ["five_dead"], "Rückgängig und Wiederholen melden nichts")
	_kills(u, [11])
	assert_eq(hint, ["five_dead"], "nach Wiederholen ist der Hinweis verbraucht")
	var retract: Array = []
	var r := _day(_roles(), retract)
	_kills(r, [4, 5, 6, 9, 10])
	assert_true(r.undo(), "fünfter Tod zurückgenommen")
	_kills(r, [11])
	assert_eq(retract, ["five_dead", "five_dead"], "der zurückgenommene Hinweis zählt nicht: der neue fünfte Tod löst erneut aus")


func test_hint_has_no_effect_on_state_random_or_events() -> void:
	var with_listener := GameSession.new()
	var heard: Array = []
	with_listener.cue_requested.connect(func(cue: StringName) -> void: heard.append(cue))
	var silent := GameSession.new()
	var commands: Array[Command] = [Fixtures.start_roles(_roles(), 1), Command.start_night(), Command.answer_prompt(1, [4]), Command.end_night(),
		CorrectionFixtures.gm("revive", {"target_id": 4}, "Test")]
	for id: int in [4, 5, 6, 9, 10, 11]:
		commands.append(_kill(id))
	for c: Command in commands:
		with_listener.submit(c)
		silent.submit(c)
	assert_eq(heard, [PresentationCue.FIVE_DEAD], "Hinweis gehört")
	assert_eq(with_listener.state_hash(), silent.state_hash(), "gleicher Zustand einschließlich gespeichertem Zufallsgenerator")
	assert_eq(with_listener.save_text(), silent.save_text(), "gleicher Spielstand")
	assert_eq(JSON.stringify(with_listener.event_log()), JSON.stringify(silent.event_log()), "gleiche Ereignisse, kein neues Ereignis durch den Hinweis")
	assert_false((load("res://core/events/game_event.gd") as GDScript).get_script_constant_map().keys().any(func(k: Variant) -> bool: return str(k).contains("FIVE") or str(k).contains("CUE")),
		"kein Regelereignis für den Hinweis")
