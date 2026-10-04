extends TestCase
## DECISION-LOG „Rollenaudit · Wiederbelebungsrollen“ (28.09.2026, W-01 bis W-04).
##   Kutscher (3.8): ab einer Nacht mit mindestens 10 Toten, freiwillig, einmal je Leben: drei Tote wählen, einer
##     davon wird Werwolf (Wächter am Tor blockiert); die anderen behalten ihre Rolle mit frischen Einsätzen.
##   Dr. Victor Frankenstein (3.6): jede Nacht bis zur Nutzung, freiwillig: eine tote Person mit einer Rolle, die
##     gerade niemand hat (Dorfbewohner immer, keine Wolfsrolle), wiederbeleben.
##   Beide: private Mitteilung der neuen Rolle, Handeln ab der Folgenacht, öffentlich sichtbar am Morgen.

const KU := "kutscher"
const FR := "dr-victor-frankenstein"
const D := "dorfbewohner"
const W := "werwolf"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.owner == PendingPrompt.OWNER_WITCH:
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm")
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	if p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
		return Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
	if p.owner == &"feuerteufel":
		return Command.answer_prompt(p.id, Fixtures.pass_targets(s, p))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Bis zum offenen Prompt von `owner`; andere Schritte ohne Wirkung. Null, wenn er nicht kommt.
func _to_owner(s: GameState, owner: StringName, log: Array[GameEvent] = []) -> GameState:
	if s != null and s.phase != Phase.NIGHT:
		if s.phase == Phase.DAY and s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine")
		if s != null and s.phase == Phase.DAY and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Ende")
		var started := apply_ok(s, Command.start_night(), "Nacht")
		log.append_array(started.events)
		s = started.state
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			if s.pending_prompt.owner == owner:
				return s
			var r := apply_ok(s, _auto(s), "ohne Wirkung")
			log.append_array(r.events)
			s = r.state
		elif RulesEngine.next_step_id(s) == "":
			return null
		else:
			var b := apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
			log.append_array(b.events)
			s = b.state
	return null


## Rest der Nacht ohne Wirkung, dann Morgen.
func _dawn(s: GameState) -> CommandResult:
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			s = _ok(s, _auto(s), "ohne Wirkung")
		elif RulesEngine.next_step_id(s) != "":
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
		else:
			return apply_ok(s, Command.end_night(), "Morgen")
	return null


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _kill(s: GameState, ids: Array) -> GameState:
	for id: Variant in ids:
		s = _ok(s, _gm("kill", {"target_id": int(id), "trigger_effects": false}), "tot %d" % int(id))
	return s


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entries() -> void:
	for pair: Array in [[KU, 38], [FR, 36]]:
		assert_true(RoleCatalog.has_role(StringName(pair[0])), "%s im Katalog" % pair[0])
		if RoleCatalog.has_role(StringName(pair[0])):
			assert_eq(RoleCatalog.faction_of(StringName(pair[0])), Faction.VILLAGE, "%s Dorf" % pair[0])
			assert_eq(RoleCatalog.night_priority(StringName(pair[0])), pair[1], "%s Priorität" % pair[0])


# --- Kutscher -------------------------------------------------------------------------------------

func test_coachman_revives_three_one_becomes_wolf() -> void:
	# 1 W, 2 Kutscher, 3 Orakel, 4 Waldhexe, 5–16 Dorfbewohner (6 Doktor).
	var roles := [W, KU, "das-orakel", "waldhexe", D, "doktor", "amalia", "detektiv", "wahnsinniger-kutscher"] + Fixtures.extra_village(6) + ["der-weise"]
	var s := _kill(_state(roles), [6, 7, 8, 9, 10, 11, 12, 13, 14])
	s = _ok(s, Command.start_night(), "9 Tote")
	assert_false(s != null and s.night_plan.has(&"kutscher:2"), "unter 10 Toten kein Schritt")
	var r := _dawn(s)
	s = _kill(r.state, [15]) if r != null else null
	var log: Array[GameEvent] = []
	s = _to_owner(s, &"kutscher", log)
	if s == null:
		fail("Kutscher nicht erreicht")
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as Array[int], "nur Tote")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [6, 7]), "invalid_target_count", "genau drei")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [6, 7, 8]), "drei Tote")
	if s == null:
		return
	assert_eq(s.pending_prompt.allowed_ids, [6, 7, 8] as Array[int], "Wolf unter den dreien")
	_codec_same(s, "Wolfswahl offen")
	r = apply_ok(s, Command.answer_stage_targets(p.id, "wolf", [7]), "7 wird Wolf")
	s = r.state
	assert_true(s.players[6].alive and s.players[7].alive and s.players[8].alive, "wiederbelebt")
	assert_eq(s.players[6].role_id, &"doktor", "Rolle bleibt")
	assert_eq(s.players[7].role_id, &"werwolf", "einer wird Wolf")
	assert_eq(events_of_type(r.events, "RevivalNotice").size(), 3, "alle drei privat informiert")
	assert_eq(events_of_type(r.events, "PlayerRevived").size(), 0, "nachts noch nicht öffentlich")
	r = _dawn(s)
	if r == null:
		return
	var pub := events_of_type(r.events, "PlayerRevived")
	assert_eq(pub.size(), 3, "am Morgen öffentlich")
	for e: GameEvent in pub:
		assert_true(e.visibility == Visibility.PUBLIC and not e.data.has("role_id"), "ohne Rolle")
	s = _to_owner(r.state, &"doktor")
	assert_true(s != null and s.night_wolf_ids.has(7), "neuer Wolf im Rudel der Folgenacht")


func test_coachman_gatewarden_and_decline() -> void:
	var roles := [W, KU, "waechter-am-tor", D] + Fixtures.extra_village(10) + ["amalia", "detektiv"]
	var s := _kill(_state(roles), [5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
	s = _to_owner(s, &"kutscher")
	if s == null:
		fail("Kutscher nicht erreicht")
		return
	var declined := _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", []), "Verzicht")
	assert_false(declined != null and declined.players[2].ability_uses.has("kutscher:revive"), "Verzicht verbraucht nichts")
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [5, 6, 7]), "drei")
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "wolf", [5]), "5 Wolf")
	if s != null:
		assert_eq(s.players[5].role_id, &"dorfbewohner", "Wächter am Tor blockiert den neuen Wolf")


# --- Frankenstein ---------------------------------------------------------------------------------

func test_frankenstein_revives_with_unassigned_role() -> void:
	var s := _kill(_state([W, FR, "das-orakel", "ritter", D, "amalia", "detektiv"]), [3])
	s = _to_owner(s, &"dr-victor-frankenstein")
	if s == null:
		fail("Frankenstein nicht erreicht")
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [3] as Array[int], "nur Tote")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [3]), "Orakel 3")
	if s == null:
		return
	var options: Array = s.pending_prompt.partial.get("options", [])
	assert_true(options.has("dorfbewohner") and options.has("doktor"), "freie Rollen und Dorfbewohner")
	for taken: String in ["werwolf", "das-orakel", "ritter", "dr-victor-frankenstein", "trugbilderwolf", "giftwolf"]:
		assert_false(options.has(taken), "nicht angeboten: %s" % taken)
	_codec_same(s, "Rollenwahl offen")
	var r := apply_ok(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "role", "option": options.find("doktor")}), "Doktor")
	s = r.state
	assert_true(s.players[3].alive and s.players[3].role_id == &"doktor", "wiederbelebt als Doktor")
	var notice := events_of_type(r.events, "RevivalNotice")
	assert_true(notice.size() == 1 and notice[0].visibility == Visibility.ACTOR and notice[0].actor_id == 3, "privat")
	assert_false(s.night_plan.has(&"doktor:3"), "handelt erst ab der Folgenacht")
	r = _dawn(s)
	assert_eq(events_of_type(r.events, "PlayerRevived").size() if r != null else -1, 1, "öffentlich am Morgen")
	s = _to_owner(r.state, &"doktor") if r != null else null
	assert_true(s != null, "Folgenacht: Doktor-Schritt")
	assert_false(s != null and s.night_plan.has(&"dr-victor-frankenstein:2"), "einmal je Leben")
