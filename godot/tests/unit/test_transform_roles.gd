extends TestCase
## DECISION-LOG „Rollenaudit · Verwandlungsrollen“ (28.09.2026, V-01 bis V-09).
##   Dämonischer Wolf: Todesreaktion bei jedem Tod mit Folgen: eine andere lebende Person verfluchen oder
##     verzichten; nur Rollenauskünfte (Orakel) zeigen „Werwolf“; bis zum Rollenwechsel.
##   König Lykaon (2.4): jede Nacht bis zur Nutzung, wenn ein anderer Wolf lebt: Verbündeter, dann eine
##     lebende Dorfperson → Trugbilderwolf mit alter Rolle als Scheinrolle; höchstens drei Verzichte.
##   Seelentauscher (8.0): einmal je Leben zwei Personen (lebend oder tot, auch er) tauschen die Rollen wie beim
##     Lehrling-Erbe; lebende Betroffene erfahren es privat; Wächter am Tor prüft auch Tote.

const DW := "daemonischer-wolf"
const KL := "koenig-lykaon"
const ST := "seelentauscher"
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
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm")  # keine Tränke
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage == &"grant" or p.stage == &"mode":
		return Command.answer_choice(p.id, String(p.stage), false)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht ohne Rudelopfer; `answers`: {"<rolle>:<id>@<stufe>": Zielliste}; sammelt Ereignisse in `log`.
func _night(s: GameState, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Tagesende")
	if s != null and s.phase != Phase.NIGHT:
		var started := apply_ok(s, Command.start_night(), "Nachtbeginn")
		log.append_array(started.events)
		s = started.state
	for guard: int in 60:
		if s == null:
			return null
		var cmd: Command = null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
			var staged := "%s@%s" % [key, p.stage]
			if answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.answer_prompt(p.id, [])
			else:
				cmd = _auto(s)
		else:
			var step := RulesEngine.next_step_id(s)
			if step == "":
				return s
			cmd = Command.begin_step(step)
		var r := apply_ok(s, cmd, "Nachtbefehl")
		log.append_array(r.events)
		s = r.state
	fail("Nacht endet nicht")
	return null


## Bis zum offenen Prompt von `owner` (Nacht wird bei Bedarf begonnen), andere Schritte ohne Wirkung.
func _to_owner(s: GameState, owner: StringName) -> GameState:
	if s != null and s.phase != Phase.NIGHT:
		if s.phase == Phase.DAY and s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine")
		if s != null and s.phase == Phase.DAY and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Ende")
		s = _ok(s, Command.start_night(), "Nacht")
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			if s.pending_prompt.owner == owner:
				return s
			s = _ok(s, _auto(s), "ohne Wirkung")
		elif RulesEngine.next_step_id(s) == "":
			fail("%s nicht erreicht" % owner)
			return null
		else:
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
	return null


## Nacht 1 ohne Aktionen, dann Tag 1.
func _day(s: GameState) -> GameState:
	return _ok(_night(s), Command.end_night(), "Morgen")


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _dropped_reason(events: Array[GameEvent], key: String) -> String:
	for e: GameEvent in events_of_type(events, "StepDropped"):
		if String(e.data["step_id"]).ends_with(":" + key):
			return String(e.data["reason"])
	return ""


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entries() -> void:
	var expect := {DW: [Faction.WOLVES, true, 0], KL: [Faction.WOLVES, true, 24], ST: [Faction.VILLAGE, false, 80]}
	for role: String in expect:
		assert_true(RoleCatalog.has_role(StringName(role)), "%s im Katalog" % role)
		if RoleCatalog.has_role(StringName(role)):
			assert_eq(RoleCatalog.faction_of(StringName(role)), expect[role][0], "%s Fraktion" % role)
			assert_eq(RoleCatalog.counts_as_wolf(StringName(role)), expect[role][1], "%s Wolf" % role)
			assert_eq(RoleCatalog.night_priority(StringName(role)), expect[role][2], "%s Priorität" % role)
	assert_false(RoleCatalog.first_night_only(&"koenig-lykaon"), "Lykaon nicht nur Nacht 1 (V-08)")


# --- Dämonischer Wolf -----------------------------------------------------------------------------

func test_demon_curses_on_any_death_only_role_information_sees_it() -> void:
	var s := _day(_state([DW, W, D, "das-orakel", "waldlaeufer", "amalia", "detektiv", "wahnsinniger-kutscher"]))
	var r := apply_ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "Dämon stirbt (jede Ursache)")
	assert_eq(r.state.reactions.size(), 1, "Todesreaktion eingereiht")
	s = _ok(r.state, Command.begin_step(RulesEngine.next_step_id(r.state)), "Reaktion")
	if s == null:
		return
	assert_false(s.pending_prompt.allowed_ids.has(1), "nicht er selbst")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [3]), "verflucht 3")
	if s == null:
		return
	assert_true(s.players[3].cursed, "3 verflucht")
	assert_false(s.players[3].counts_as_wolf, "zählt nicht als Wolf")
	assert_eq(InformationRules.determine_role(s.players[3]), &"werwolf", "Orakel sieht Werwolf")
	assert_eq(InfoSteps.living_wolf_count(s), 1, "Waldläufer zählt wahr")
	_codec_same(s, "Fluch")
	s = _ok(s, _gm("kill", {"target_id": 3, "trigger_effects": false}), "3 tot")
	s = _ok(s, _gm("revive", {"target_id": 3}), "3 wiederbelebt")
	assert_true(s != null and s.players[3].cursed, "Wiederbelebung löscht den Fluch nicht")
	s = _ok(s, _gm("set_role", {"target_id": 3, "role_id": "doktor"}), "Rollenwechsel")
	assert_true(s != null and not s.players[3].cursed, "Rollenwechsel löscht den Fluch")


func test_demon_may_decline_and_needs_effects() -> void:
	var s := _day(_state([DW, W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]))
	var quiet := apply_ok(s, _gm("kill", {"target_id": 1, "trigger_effects": false}), "ohne Folgen")
	assert_true(quiet.state.reactions.is_empty(), "ohne Todesfolgen keine Reaktion")
	var r := apply_ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "mit Folgen")
	s = _ok(r.state, Command.begin_step(RulesEngine.next_step_id(r.state)), "Reaktion")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Verzicht") if s != null else null
	if s != null:
		for id: int in s.players:
			assert_false(s.players[id].cursed, "niemand verflucht (%d)" % id)


# --- König Lykaon ---------------------------------------------------------------------------------

func test_lycaon_converts_village_person_into_decoy_wolf() -> void:
	var s := _state([KL, W, "das-orakel", D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise"])
	var log: Array[GameEvent] = []
	s = _night(s, {"koenig-lykaon:1@ally": [2], "koenig-lykaon:1@targets": [3]}, log)
	if s == null:
		return
	var p := s.players[3]
	assert_eq(p.role_id, &"trugbilderwolf", "3 ist Trugbilderwolf")
	assert_eq(p.appears_as, &"das-orakel", "Scheinrolle = alte Rolle")
	assert_true(p.counts_as_wolf, "zählt als Wolf")
	assert_eq(_dropped_reason(log, "das-orakel:3"), "actor_role_changed", "alte Rolle handelt nicht mehr")
	assert_false(s.night_wolf_ids.has(3), "wacht erst ab der Folgenacht mit dem Rudel")
	var chose := events_of_type(log, "LycaonConverted")
	assert_true(chose.size() == 1 and int(chose[0].data["ally_id"]) == 2, "Verbündeter protokolliert")
	s = _ok(s, Command.end_night(), "Morgen")
	s = _night(s)
	assert_true(s != null and s.night_wolf_ids.has(3), "Nacht 2: im Rudel")
	assert_false(s != null and s.night_plan.has(&"koenig-lykaon:1"), "einmal je Leben")


func test_lycaon_targets_and_gatewarden() -> void:
	var s := _to_owner(_state([KL, W, "manipulator", D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise"]), &"koenig-lykaon")
	if s == null:
		return
	assert_eq(s.pending_prompt.allowed_ids, [2] as Array[int], "Verbündeter: andere lebende Wölfe")
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "ally", [2]), "Verbündeter")
	assert_false(s != null and s.pending_prompt.allowed_ids.has(3), "Einzelsieg ist kein Ziel")
	# Wächter am Tor: das Ziel wird Dorfbewohner.
	var t := _state([KL, W, "waechter-am-tor", D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise"])
	t = _night(t, {"koenig-lykaon:1@ally": [2], "koenig-lykaon:1@targets": [4]})
	if t != null:
		assert_eq(t.players[4].role_id, &"dorfbewohner", "blockiert")
		assert_false(t.players[4].counts_as_wolf, "kein neuer Wolf")


func test_lycaon_postpones_at_most_three_times() -> void:
	var s := _state([KL, W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "nachtwaechter", "der-weise"])
	for night: int in 3:
		s = _night(s, {"koenig-lykaon:1@ally": []})
		if s == null:
			return
		assert_eq(s.players[3].role_id, &"dorfbewohner", "Nacht %d: verschoben" % (night + 1))
		s = _ok(s, Command.end_night(), "Morgen")
	s = _to_owner(s, &"koenig-lykaon")
	if s == null:
		return
	assert_eq(s.pending_prompt.min_count, 1, "vierte Gelegenheit: Pflicht")
	apply_rejected(s, Command.answer_stage_targets(s.pending_prompt.id, "ally", []), "invalid_target_count", "kein Verzicht mehr")


func test_lycaon_without_ally_does_not_count() -> void:
	var s := _state([KL, W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "nachtwaechter", "der-weise"])
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": false}), "kein Verbündeter")
	var log: Array[GameEvent] = []
	s = _night(s, {}, log)
	assert_eq(_dropped_reason(log, "koenig-lykaon:1"), "no_decision", "ohne Verbündeten entfällt der Schritt")
	assert_false(s != null and s.players[1].ability_uses.has("koenig-lykaon:skip1"), "zählt nicht als Verzicht")


# --- Seelentauscher -------------------------------------------------------------------------------

func test_soul_swapper_swaps_with_fresh_roles_and_tells_the_living() -> void:
	var s := _state([W, ST, "waldhexe", "wolfskind", D, "amalia", "detektiv"])
	# Waldhexe ohne Gifttrank und ohne Rudelopfer: ihr Schritt entfällt vor dem Tausch.
	s = _ok(s, _gm("set_witch_potion", {"witch_id": 3, "potion": "poison", "available": false}), "Gift verbraucht")
	var log: Array[GameEvent] = []
	# Nacht 1: Wolfskind 4 wählt 5 als Vorbild; Waldhexe verzichtet; der Seelentauscher tauscht 3 und 4.
	s = _night(s, {"wolfskind:4@": [5], "seelentauscher:2@targets": [3, 4]}, log)
	if s == null:
		return
	assert_eq(s.players[3].role_id, &"wolfskind", "3 ist Wolfskind")
	assert_eq(WolfChildRules.bond_of(s, 3).model_id, -1, "ohne Vorbild")
	assert_eq(s.players[4].role_id, &"waldhexe", "4 ist Waldhexe")
	assert_true(WitchStep.potion_available(s.players[4], "heal") and WitchStep.potion_available(s.players[4], "poison"), "frische Tränke")
	var told := events_of_type(log, "SoulSwapRevealed")
	assert_eq(told.size(), 2, "beide erfahren es")
	for e: GameEvent in told:
		assert_true(e.visibility == Visibility.ACTOR, "privat")
	_codec_same(s, "nach Tausch")
	s = _ok(s, Command.end_night(), "Morgen")
	s = _night(s)
	assert_false(s != null and s.night_plan.has(&"seelentauscher:2"), "einmal je Leben")


func test_soul_swapper_with_the_dead_and_gatewarden() -> void:
	var s := _state([W, ST, D, "amalia", "detektiv", "waechter-am-tor", "wahnsinniger-kutscher", "blutwolf"])
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": false}), "Wolf 1 tot")
	s = _night(s, {"seelentauscher:2@targets": [1, 2]})
	if s == null:
		return
	assert_eq(s.players[1].role_id, &"seelentauscher", "der Tote erhält den Seelentauscher")
	assert_eq(s.players[2].role_id, &"dorfbewohner", "Wächter: statt Werwolf Dorfbewohner")
	# Ohne Wächter: ein Toter kann eine Wolfsrolle erhalten; mit Wächter nicht (V-06).
	var t := _state([W, ST, D, "amalia", "detektiv", "waechter-am-tor", "wahnsinniger-kutscher", "blutwolf"])
	t = _ok(t, _gm("kill", {"target_id": 3, "trigger_effects": false}), "3 tot")
	t = _night(t, {"seelentauscher:2@targets": [3, 8]})
	if t != null:
		assert_eq(t.players[3].role_id, &"dorfbewohner", "toter Empfänger einer Wolfsrolle wird Dorfbewohner")
		assert_eq(t.players[8].role_id, &"dorfbewohner", "8 erhält die Rolle von 3")
