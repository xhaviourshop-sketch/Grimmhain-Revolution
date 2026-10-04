extends TestCase
## DI-03 (Antwort des Product Owners vom 29.09.2026, ändert DR-04): Sichtbare Folgen eines Todes werden
## öffentlich angesagt (`DeathEffect`, öffentlich), mit Effekt und Rolle zum Ereigniszeitpunkt, auch in
## Wiederbelebungsrunden. Erfasst sind Sensenträger, Ritter, Besessener Wolf, Wahnsinniger Kutscher,
## Fluch des Weisen, Liebeskummer, Rotkäppchen-Kette und die Verknüpfung des Schattenwanderers.
## Nur wirklich eingetretene Folgen; keine geheimen Wahlen (Dämonischer Wolf), keine Ursachen.

const EXPECTED_KEYS := ["effect", "replaced_id", "role_id", "source_id", "target_id"]


## Tag 1. Das Rudel tötet in Nacht 1 den Dorfbewohner (die Wölfe müssen jede Nacht töten); er wird sofort wiederbelebt, damit der Tag mit
## allen Lebenden beginnt wie in den Vorgaben der Tests.
func _day_one(roles: Array) -> GameState:
	var victim := roles.size() if Fixtures.INERT_ROLES.has(StringName(roles[roles.size() - 1])) else roles.find("dorfbewohner") + 1
	return Fixtures.play([Fixtures.start_roles(roles), Command.start_night(), Command.answer_prompt(1, [victim]), Command.end_night(),
		CorrectionFixtures.gm("revive", {"target_id": victim}, "Test")] as Array[Command])


## Wendet Befehle an; liefert alle Ereignisse und den Endzustand.
func _run(state: GameState, commands: Array[Command]) -> Dictionary:
	var events: Array[GameEvent] = []
	var s := state
	for c: Command in commands:
		var r := apply_ok(s, c, str(c.type))
		if not r.ok:
			return {"state": s, "events": events}
		s = r.state
		events.append_array(r.events)
	return {"state": s, "events": events}


func _effects(events: Array[GameEvent]) -> Array[GameEvent]:
	return events_of_type(events, "DeathEffect")


func _lynch(target: int, nominator: int, extra: Dictionary = {}) -> Array[Command]:
	var payload := {"target_id": target}
	payload.merge(extra)
	return [Command.nominate(nominator, target), Command.create(Command.DECIDE_EXECUTION, payload)] as Array[Command]


func _answer_open(state: GameState, targets: Array) -> Command:
	return Command.answer_prompt(state.pending_prompt.id, targets)


func _index_of(events: Array[GameEvent], type: String, key: String, value: int) -> int:
	for i: int in events.size():
		if String(events[i].type) == type and int(events[i].data.get(key, -99)) == value:
			return i
	return -1


func test_reaper_curse_is_announced_with_role_and_target() -> void:
	var day := _day_one(["werwolf", "blutwolf", "sensentraeger", "dorfbewohner", "amalia", "detektiv"])
	var first := _run(day, _lynch(3, 4))
	var st: GameState = first["state"]
	assert_true(st.pending_prompt == null and not st.reactions.is_empty(), "Reaktion des Sensenträgers eingereiht")
	assert_true(_effects(first["events"]).is_empty(), "vor der Antwort keine Ansage")
	st = _run(st, [Command.begin_step(RulesEngine.next_step_id(st))] as Array[Command])["state"]
	var second := _run(st, [_answer_open(st, [5])] as Array[Command])
	var effects := _effects(second["events"])
	assert_eq(effects.size(), 1, "genau eine Ansage")
	if effects.size() == 1:
		var e := effects[0]
		assert_eq(String(e.visibility), "public", "öffentlich")
		assert_eq(String(e.data["effect"]), "reaper_curse", "Effekt")
		assert_eq(int(e.data["source_id"]), 3, "Quelle")
		assert_eq(String(e.data["role_id"]), "sensentraeger", "Rolle zum Ereigniszeitpunkt")
		assert_eq(int(e.data["target_id"]), 5, "Ziel")
		var keys: Array = e.data.keys()
		keys.sort()
		assert_eq(keys, EXPECTED_KEYS, "nur die Positivliste, keine Ursache und keine Schutzangaben")
	var died := _index_of(second["events"], "SeatDied", "target_id", 5)
	var announced := _index_of(second["events"], "DeathEffect", "target_id", 5)
	assert_true(died != -1 and announced > died, "Ansage folgt dem Tod des Ziels")


func test_reaper_cannot_decline() -> void:
	# Die Karte des Sensenträgers kennt keinen Verzicht (DA Nachtschritte neu): ohne Ziel gibt es keine Antwort, also auch keine Ansage.
	var day := _day_one(["werwolf", "blutwolf", "sensentraeger", "dorfbewohner", "amalia", "detektiv"])
	var st: GameState = _run(day, _lynch(3, 4))["state"]
	st = _run(st, [Command.begin_step(RulesEngine.next_step_id(st))] as Array[Command])["state"]
	apply_rejected(st, Command.answer_prompt(st.pending_prompt.id, []), "invalid_target_count", "kein Verzicht")


func test_prevented_curse_is_not_announced() -> void:
	# Acht Personen: Das Rudel tötet in Nacht 1 den letzten Platz; ohne ihn entstünde mit drei Wölfen sofort Parität.
	var day := _day_one(["werwolf", "blutwolf", "sensentraeger", "fenrir", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	var s := day.duplicate_state()
	s.growth[4] = RoleCatalog.FENRIR_SHIELD_STAGE
	var st: GameState = _run(s, _lynch(3, 5))["state"]
	st = _run(st, [Command.begin_step(RulesEngine.next_step_id(st))] as Array[Command])["state"]
	var r := _run(st, [_answer_open(st, [4])] as Array[Command])
	assert_true(st.players[4].alive and (r["state"] as GameState).players[4].alive, "Fenrir überlebt (Schutz ab Stufe 3)")
	assert_true(_effects(r["events"]).is_empty(), "abgefangene Wirkung ohne Folge: keine Ansage")


func test_knight_strike_is_announced_after_the_wolf_dies() -> void:
	var roles := ["werwolf", "ritter", "dorfbewohner", "amalia", "detektiv", "blutwolf"]
	var st: GameState = Fixtures.play([Fixtures.start_roles(roles), Command.start_night()] as Array[Command])
	var r := _run(st, [Command.answer_prompt(st.pending_prompt.id, [2]), Command.end_night()] as Array[Command])
	var effects := _effects(r["events"])
	assert_eq(effects.size(), 1, "eine Ansage")
	if effects.size() == 1:
		assert_eq(String(effects[0].data["effect"]), "knight_strike", "Effekt")
		assert_eq(String(effects[0].data["role_id"]), "ritter", "Rolle")
		assert_eq(int(effects[0].data["source_id"]), 2, "Quelle")
		assert_eq(int(effects[0].data["target_id"]), 1, "mitgerissener Wolf")
	var wolf_died := _index_of(r["events"], "SeatDied", "target_id", 1)
	var announced := _index_of(r["events"], "DeathEffect", "target_id", 1)
	assert_true(wolf_died != -1 and announced > wolf_died, "Reihenfolge: Tod des Wolfs, dann Ansage")


func test_possessed_wolf_drag_is_announced() -> void:
	var day := _day_one(["werwolf", "besessener-wolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	var st: GameState = _run(day, _lynch(2, 3))["state"]
	st = _run(st, [Command.begin_step(RulesEngine.next_step_id(st))] as Array[Command])["state"]
	var r := _run(st, [_answer_open(st, [5])] as Array[Command])
	var effects := _effects(r["events"])
	assert_eq(effects.size(), 1, "eine Ansage")
	if effects.size() == 1:
		assert_eq(String(effects[0].data["effect"]), "possessed_drag", "Effekt")
		assert_eq(String(effects[0].data["role_id"]), "besessener-wolf", "Rolle")
		assert_eq(int(effects[0].data["target_id"]), 5, "Ziel")


func test_coachman_crash_announces_each_neighbour_in_order() -> void:
	var day := _day_one(["werwolf", "dorfbewohner", "wahnsinniger-kutscher", "amalia", "detektiv", "waechter-am-tor"])
	var r := _run(day, _lynch(3, 5))
	var effects := _effects(r["events"])
	assert_eq(effects.size(), 2, "zwei Nachbarn")
	if effects.size() == 2:
		var targets := [int(effects[0].data["target_id"]), int(effects[1].data["target_id"])]
		targets.sort()
		assert_eq(targets, [2, 4], "beide lebenden Nachbarn")
		for e: GameEvent in effects:
			assert_eq(String(e.data["effect"]), "coachman_crash", "Effekt")
			assert_eq(String(e.data["role_id"]), "wahnsinniger-kutscher", "Rolle")
			assert_eq(int(e.data["source_id"]), 3, "Quelle")


## PE-05: Liebeskummer, Kette und Verknüpfung nennen die Quellrolle, nie die Rolle einer beteiligten Person.
func test_heartbreak_and_chain_name_the_source_role() -> void:
	var day := _day_one(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	var loki := day.duplicate_state()
	loki.loki_pairs.append({"loki_id": 2, "a": 4, "b": 5, "kind": "love", "ended": false})
	var r := _run(loki, [CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command])
	var effects := _effects(r["events"])
	assert_eq(effects.size(), 1, "Liebeskummer angesagt")
	if effects.size() == 1:
		assert_eq(String(effects[0].data["effect"]), "heartbreak", "Effekt")
		assert_eq(int(effects[0].data["source_id"]), 4, "gestorbener Partner")
		assert_eq(int(effects[0].data["target_id"]), 5, "Liebeskummer")
		assert_eq(String(effects[0].data["role_id"]), "loki", "Quellrolle Loki, nicht die Rolle der Liebenden")
	var rivals := day.duplicate_state()
	rivals.loki_pairs.append({"loki_id": 2, "a": 4, "b": 5, "kind": "rival", "ended": false})
	var rr := _run(rivals, [CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command])
	assert_true(_effects(rr["events"]).is_empty(), "Rivalen haben keine Wirkung")
	var chained := day.duplicate_state()
	chained.red_chains.append({"red_id": 4, "partner_id": 5})
	var rc := _run(chained, [CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": true})] as Array[Command])
	var chain_effects := _effects(rc["events"])
	assert_eq(chain_effects.size(), 1, "Kette angesagt")
	if chain_effects.size() == 1:
		assert_eq(String(chain_effects[0].data["effect"]), "red_chain", "Effekt")
		assert_eq(int(chain_effects[0].data["target_id"]), 4, "Kettenpartner")
		assert_eq(String(chain_effects[0].data["role_id"]), "rotkaeppchen", "Quellrolle Rotkäppchen")
	var no_effects := _run(chained, [CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false})] as Array[Command])
	assert_true(_effects(no_effects["events"]).is_empty(), "Korrektur ohne Todesfolgen: keine Ansage")


func test_sage_curse_is_announced_only_with_a_length() -> void:
	var day := _day_one(["werwolf", "dorfbewohner", "der-weise", "amalia", "detektiv", "wahnsinniger-kutscher"])
	var cursed := _run(day, _lynch(3, 4, {"sage_curse": 2}))
	var effects := _effects(cursed["events"])
	assert_eq(effects.size(), 1, "Fluch angesagt")
	if effects.size() == 1:
		assert_eq(String(effects[0].data["effect"]), "sage_curse", "Effekt")
		assert_eq(String(effects[0].data["role_id"]), "der-weise", "Rolle")
		assert_eq(int(effects[0].data["source_id"]), 3, "Quelle")
		assert_false(effects[0].data.has("length"), "Länge nicht öffentlich (Entwurf, Randfall offen)")
	var none := _run(day, _lynch(3, 4, {"sage_curse": 0}))
	assert_true(_effects(none["events"]).is_empty(), "Länge 0: kein Fluch, keine Ansage")


func test_shadow_link_announces_redirect_and_intended_target() -> void:
	# Der Wahnsinnige Kutscher steht auf 6, nicht neben den Hingerichteten: seine eigene Ansage gehört nicht zu diesem Fall.
	var day := _day_one(["werwolf", "dorfbewohner", "amalia", "detektiv", "waechter-am-tor", "wahnsinniger-kutscher"])
	var s := day.duplicate_state()
	s.shadow_links.append({"walker_id": 4, "partner_id": 5})
	var r := _run(s, _lynch(4, 2))
	var effects := _effects(r["events"])
	assert_eq(effects.size(), 1, "eine Ansage")
	if effects.size() == 1:
		assert_eq(String(effects[0].data["effect"]), "shadow_link", "Effekt")
		assert_eq(int(effects[0].data["target_id"]), 5, "stirbt tatsächlich")
		assert_eq(int(effects[0].data["replaced_id"]), 4, "an Stelle von")
		assert_eq(String(effects[0].data["role_id"]), "schattenwanderer", "Quellrolle Schattenwanderer (PE-05)")
	var gm := day.duplicate_state()
	gm.shadow_links.append({"walker_id": 4, "partner_id": 5})
	var direct := _run(gm, [CorrectionFixtures.gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command])
	assert_true(_effects(direct["events"]).is_empty(), "Spielleiterkorrekturen werden nicht umgelenkt, keine Ansage")


func test_curse_redirected_by_shadow_link_keeps_both_effects_in_order() -> void:
	var day := _day_one(["werwolf", "blutwolf", "sensentraeger", "dorfbewohner", "amalia", "detektiv"])
	var s := day.duplicate_state()
	s.shadow_links.append({"walker_id": 4, "partner_id": 5})
	var st: GameState = _run(s, _lynch(3, 6))["state"]
	st = _run(st, [Command.begin_step(RulesEngine.next_step_id(st))] as Array[Command])["state"]
	var r := _run(st, [_answer_open(st, [4])] as Array[Command])
	var effects := _effects(r["events"])
	assert_eq(effects.size(), 2, "Fluch und Verknüpfung")
	if effects.size() == 2:
		assert_eq(String(effects[0].data["effect"]), "reaper_curse", "erst der Fluch")
		assert_eq(int(effects[0].data["target_id"]), 4, "Fluch nennt die gewählte Person")
		assert_eq(String(effects[1].data["effect"]), "shadow_link", "dann die Umlenkung")
		assert_eq(int(effects[1].data["target_id"]), 5, "es stirbt die verknüpfte Person")
		assert_eq(int(effects[1].data["replaced_id"]), 4, "an Stelle der gewählten")
	assert_true(not (r["state"] as GameState).players[5].alive and (r["state"] as GameState).players[4].alive, "Verknüpfte stirbt, Gewählte lebt")


func test_hidden_choices_and_ordinary_deaths_stay_silent() -> void:
	var day := _day_one(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	var r := _run(day, _lynch(3, 4))
	assert_true(_effects(r["events"]).is_empty(), "gewöhnliche Hinrichtung: keine Effektansage")
	var night := Fixtures.play([Fixtures.start_roles(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), Command.start_night()] as Array[Command])
	var killed := _run(night, [Command.answer_prompt(night.pending_prompt.id, [3]), Command.end_night()] as Array[Command])
	assert_true(_effects(killed["events"]).is_empty(), "Rudelangriff: keine Effektansage")


func test_announcements_survive_save_load_and_replay() -> void:
	var commands: Array[Command] = [Fixtures.start_roles(["werwolf", "dorfbewohner", "wahnsinniger-kutscher", "amalia", "detektiv", "waechter-am-tor"]),
		Command.start_night(), Command.answer_prompt(1, [2]), Command.end_night(), Command.nominate(5, 3), Command.create(Command.DECIDE_EXECUTION, {"target_id": 3})]
	var first := RulesEngine.replay(commands)
	assert_true(first.ok, "Replay")
	if not first.ok:
		return
	var again := RulesEngine.replay(commands)
	assert_eq(events_json(again.events), events_json(first.events), "bytegleiches Replay einschließlich Ansagen")
	var loaded := StateCodec.decode(StateCodec.encode(first.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(events_json(loaded.events), events_json(first.events), "Ansagen nach dem Laden identisch")
		assert_eq(_effects(loaded.events).size(), 2, "beide Nachbarn")
