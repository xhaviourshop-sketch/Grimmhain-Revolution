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


## Sitzung mit Zähler der Hinweise; danach Nacht 1 ohne Opfer und Tag 1.
func _day(roles: Array, cues: Array) -> GameSession:
	var s := GameSession.new()
	s.cue_requested.connect(func(cue: StringName) -> void: cues.append(String(cue)))
	assert_true(s.submit(Fixtures.start_roles(roles, 1)).ok, "Start")
	assert_true(s.submit(Command.start_night()).ok, "Nacht 1")
	assert_true(s.submit(Command.answer_prompt(1, [])).ok, "kein Opfer")
	assert_true(s.submit(Command.end_night()).ok, "Tag 1")
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


## Nacht 1 mit Bindung des Lehrlings (4) an den Selbstmörder (3), ohne Opfer, bis Tag 1 (Befehlsliste, am Zustand geführt).
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
			var stage := str(p.to_dict().get("stage", ""))
			if stage == "candidates":
				c = Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "candidates", "targets": [3, 1, 2]})
			elif stage == "option":
				var mapping: Array = p.partial.get("option_person_ids", [])
				c = Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "option", "option": maxi(0, mapping.find(3))})
			else:
				c = Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "confirm", "choice": true})
		else:
			c = Command.answer_prompt(p.id, [])
		var r := RulesEngine.apply(state, c)
		assert_true(r.ok, "Nachtbefehl %s angenommen (%s)" % [c.type, r.error])
		if not r.ok:
			break
		state = r.state
		log.append(c)
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
	# Ohne berechtigten ersten Zeitpunkt entsteht später keiner (abgeleitet: der Hinweis gehört zum ersten Erreichen).
	var late: Array = []
	var t := _day(_roles(), late)
	_kills(t, [3, 4, 5, 6, 9])
	assert_true(t.submit(CorrectionFixtures.gm("revive", {"target_id": 3}, "Test")).ok, "Selbstmörder wiederbelebt: vier Tote")
	_kills(t, [10])
	assert_eq(late, [], "fünf Tote ein zweites Mal: kein Hinweis, der erste Zeitpunkt war nicht berechtigt")


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
	var commands: Array[Command] = [Fixtures.start_roles(_roles(), 1), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()]
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
