extends TestCase
## DECISION-LOG „Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf“ (28.09.2026)
## mit den Querschnittsentscheidungen (RM-DR-004 Rudelangriff, RM-DR-005 Durchdringung, RM-DR-010 Blockade).
##   Schattenhund (Priorität 0.1): jede Nacht „jetzt blockieren?“ bis zur Nutzung (je Leben); blockiert
##     alle aktiven Dorf-Nachtschritte dieser Nacht.
##   Albtraumwolf (Priorität 0.2): jede Nacht freiwillig eine andere lebende Person; deren aktiver
##     Dorf-Nachtschritt entfällt.
##   Giftwolf (Priorität 2.7): freiwillig, zwei Ladungen je Leben, eine pro Nacht; Ziel erfährt es sofort
##     privat und stirbt in der Morgenauflösung nach Nacht N+2; nichts hebt es auf.
##   Rudelvater: überlebt einmal je Leben einen Tod, der weder Rudelangriff noch Lynch noch Korrektur
##     ist; nach seinem Lynch folgt in der nächsten Nacht ein zweiter Rudelschritt, der Schutz durchdringt.
##   Seuchenwolf: nach seinem Tod durchdringt der nächste tatsächliche Rudelangriff Schutz (verbraucht).

const SH := "schattenhund"
const AW := "albtraumwolf"
const GW := "giftwolf"
const RV := "rudelvater"
const SW := "seuchenwolf"


func _start(roles: Array) -> Command:
	return Fixtures.start_roles(roles, 1)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


## Beantwortet alle Schritte der laufenden Nacht mit `choices` {Schrittart: Antwort-Befehlsfabrik}
## und beendet sie; unbekannte Schritte: Rudel ohne Opfer, sonst erste erlaubte Person.
func _night(s: GameState, answers: Dictionary, label: String) -> GameState:
	var guard := 0
	while s != null and (s.pending_prompt != null or RulesEngine.next_step_id(s) != ""):
		guard += 1
		if guard > 40:
			fail("%s: Nacht endet nicht" % label)
			return null
		if s.pending_prompt == null:
			s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), label).state
			continue
		var p := s.pending_prompt
		var kind := StepQueue.step_kind(p.step_id)
		var c: Command
		if answers.has(String(kind)):
			c = (answers[String(kind)] as Callable).call(p)
		elif kind == StepQueue.PACK or kind == StepQueue.PACK2:
			c = Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
		elif p.stage == &"use":
			c = Command.answer_choice(p.id, "use", false)
		else:
			c = Command.answer_prompt(p.id, [p.allowed_ids[0]] if p.min_count > 0 else [])
		s = apply_ok(s, c, "%s: %s" % [label, kind]).state
	return apply_ok(s, Command.end_night(), "%s: Morgen" % label).state if s != null else null


func _day(s: GameState) -> GameState:
	s = apply_ok(s, Command.decide_execution(-1), "keine Hinrichtung").state
	s = apply_ok(s, Command.end_day(), "Tagesende").state
	return apply_ok(s, Command.start_night(), "Nachtbeginn").state


func test_production_roles() -> void:
	for role: StringName in [&"schattenhund", &"albtraumwolf", &"giftwolf", &"rudelvater", &"seuchenwolf"]:
		assert_eq(RoleCatalog.faction_of(role), Faction.WOLVES, "%s Wölfe" % role)
		assert_true(RoleCatalog.counts_as_wolf(role), "%s zählt als Wolf" % role)
	assert_eq(RoleCatalog.night_priority(&"schattenhund"), 1, "Schattenhund zuerst")
	assert_eq(RoleCatalog.night_priority(&"albtraumwolf"), 2, "Albtraumwolf danach")
	assert_eq(RoleCatalog.night_priority(&"giftwolf"), 27, "Giftwolf nach dem Rudel")


# --- Schattenhund ---------------------------------------------------------------------------------

func test_shadow_hound_blocks_all_village_steps_once() -> void:
	# 1 Schattenhund, 2 Schutzengel, 3 Orakel, 4 Waldläufer, 5–7 Dorf.
	var s := _run([_start([SH, "schutzengel", "das-orakel", "waldlaeufer", "dorfbewohner", "amalia", "detektiv"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	assert_eq(s.night_plan[0], &"schattenhund:1", "Schattenhund vor allen Dorfrollen")
	var r := apply_ok(s, Command.answer_choice(s.pending_prompt.id, "use", true), "blockieren")
	var dropped := events_of_type(r.events, "StepDropped")
	var reasons := {}
	for e: GameEvent in dropped:
		reasons[String(e.data["step_id"]).get_slice(":", 3)] = String(e.data["reason"])
	assert_eq(reasons.get("schutzengel", ""), "blocked", "Schutzengel blockiert")
	assert_eq(RulesEngine.next_step_id(r.state), "night:1:2:pack", "Rudel nicht blockiert")
	s = _night(r.state, {}, "Nacht 1")
	if s == null:
		return
	for key: StringName in [&"das-orakel:3", &"waldlaeufer:4"]:
		assert_eq(String(s.night_step_status[s.night_plan.find(key)]), "skipped", "%s blockiert" % key)
	s = _day(s)
	assert_false(s.night_plan.has(&"schattenhund:1"), "nach Nutzung kein Schritt mehr")
	assert_true(s.night_plan.has(&"schutzengel:2"), "Blockade nur für eine Nacht")


func test_shadow_hound_declines_and_asks_again() -> void:
	var s := _run([_start([SH, "schutzengel", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	s = _night(s, {}, "Nacht 1")
	s = _day(s)
	assert_true(s != null and s.night_plan.has(&"schattenhund:1"), "nach Verzicht erneut gefragt")


# --- Albtraumwolf ---------------------------------------------------------------------------------

func test_nightmare_wolf_blocks_one_village_person() -> void:
	# 1 Albtraumwolf, 2 Orakel, 3 Orakel, 4–6 Dorf. Blockiert 2 → nur Orakel 3 prüft.
	# Das zweite Orakel entsteht nach dem Start durch Korrektur (PE-07).
	var s := _run(Fixtures.with_copies([AW, "das-orakel", "das-orakel", "dorfbewohner", "amalia", "detektiv"], [Command.start_night()] as Array[Command], 1), "Start").state
	if s == null:
		return
	assert_eq(s.night_plan[0], &"albtraumwolf:1", "Albtraumwolf vor den Dorfrollen")
	var p := s.pending_prompt
	assert_true(p.min_count == 1 and not p.allowed_ids.has(1), "Pflicht (kein Verzicht), andere Lebende")
	var r := apply_ok(s, Command.answer_prompt(p.id, [2]), "blockiert 2").state
	r = apply_ok(r, Command.begin_step("night:1:1:pack"), "Rudel").state
	var after := apply_ok(r, Command.skip_step(r.pending_prompt.step_id, "Test: ruhige Nacht"), "kein Opfer")
	var dropped := events_of_type(after.events, "StepDropped")
	assert_true(not dropped.is_empty() and String(dropped[0].data["step_id"]) == "night:1:2:das-orakel:2" and String(dropped[0].data["reason"]) == "blocked", "Orakel 2 blockiert")
	assert_eq(RulesEngine.next_step_id(after.state), "night:1:3:das-orakel:3", "Orakel 3 handelt")


# --- Giftwolf -------------------------------------------------------------------------------------

func test_poison_wolf_delayed_unstoppable_death() -> void:
	# 1 Giftwolf, 2 Schutzengel (schützt 3), 3–7 Dorf. Nacht 1: Giftpranke auf 3.
	var s := _run([_start([GW, "schutzengel", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	s = apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [3]), "Schutz auf 3").state
	s = apply_ok(s, Command.begin_step("night:1:1:pack"), "Rudel").state
	s = apply_ok(s, Command.skip_step(s.pending_prompt.step_id, "Test: ruhige Nacht"), "kein Opfer").state
	s = apply_ok(s, Command.begin_step("night:1:2:giftwolf:1"), "Giftwolf").state
	var r := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [3]), "Giftpranke auf 3")
	var notice := events_of_type(r.events, "WolfPoisonNotice")
	assert_true(notice.size() == 1 and notice[0].visibility == Visibility.ACTOR and notice[0].actor_id == 3, "Ziel erfährt es sofort privat")
	s = apply_ok(r.state, Command.end_night(), "Morgen 1").state
	assert_true(s.players[3].alive, "lebt nach Nacht 1")
	s = _day(s)
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [3]), "giftwolf": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [])}, "Nacht 2")
	assert_true(s != null and s.players[3].alive, "lebt nach Nacht 2")
	s = _day(s)
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [3]), "giftwolf": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [])}, "Nacht 3")
	if s == null:
		return
	var d := s.players[3].death
	assert_true(d != null and String(d.cause) == "WOLF_POISON" and d.source_id == 1 and d.phase_number == 3, "stirbt am Morgen nach Nacht 3 trotz Schutz")


func test_poison_wolf_two_charges_one_per_night() -> void:
	var s := _run([_start([GW, "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	var paw := func(target: int) -> Callable:
		return func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [target])
	var one_per_night := func(p: PendingPrompt) -> Command:
		assert_true(p.max_count == 1 and p.min_count == 0, "höchstens eine Giftpranke pro Nacht, freiwillig")
		return Command.answer_prompt(p.id, [2])
	s = _night(s, {"giftwolf": one_per_night}, "Nacht 1")
	s = _day(s)
	s = _night(s, {"giftwolf": paw.call(3)}, "Nacht 2")
	s = _day(s)
	if s == null:
		return
	assert_false(s.night_plan.has(&"giftwolf:1"), "nach zwei Ladungen kein Schritt")
	assert_true(GameState.from_dict(s.to_dict()) != null, "Zustand mit offenen Giftwolf-Vergiftungen ladbar")


# --- Rudelvater -----------------------------------------------------------------------------------

func test_packfather_survives_first_other_death() -> void:
	# 1 Rudelvater, 2 Werwolf, 3 Waldhexe, 4–8 Dorf. Hexe vergiftet 1 → überlebt; zweites Mal (per Korrektur-Trank) stirbt er.
	var s := _run([_start([RV, "werwolf", "waldhexe", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	var poison1 := func(p: PendingPrompt) -> Command: return Command.answer_choice(p.id, String(p.stage), p.stage != &"heal") if p.stage != &"poison_target" else Command.answer_stage_targets(p.id, "poison_target", [1])
	s = _night(s, {"waldhexe": poison1}, "Nacht 1")
	if s == null:
		return
	assert_true(s.players[1].alive, "überlebt das Gift einmal")
	assert_true(s.players[1].ability_uses.has("rudelvater:survive"), "Überleben verbraucht")
	var gm := apply_ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "Korrektur").state
	assert_false(gm.players[1].alive, "Spielleitertötung wirkt immer")


func test_packfather_lynch_gives_piercing_second_pack_step() -> void:
	# 1 Rudelvater, 2 Werwolf, 3 Schutzengel, 4 Dorfwache, 5–8 Dorf. Tag 1: Lynch des Rudelvaters.
	var s := _run([_start([RV, "werwolf", "schutzengel", "dorfwache", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [5])}, "Nacht 1")
	s = apply_ok(s, Command.nominate(5, 1), "Nominierung").state
	s = apply_ok(s, Command.decide_execution(1), "Lynch").state
	s = apply_ok(s, Command.end_day(), "Tagesende").state
	s = apply_ok(s, Command.start_night(), "Nacht 2").state
	assert_true(s.night_plan.has(&"pack") and s.night_plan.has(&"pack2"), "zweiter Rudelschritt")
	assert_true(s.night_plan.find(&"pack2") == s.night_plan.find(&"pack") + 1, "direkt nach dem Rudel")
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [6]),
		"pack": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [4]),
		"pack2": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [6])}, "Nacht 2")
	if s == null:
		return
	assert_true(s.players[4].alive, "erster Angriff: Dorfwache immun")
	assert_false(s.players[6].alive, "Zusatzopfer durchdringt den Schutzengel")
	s = _day(s)
	assert_false(s.night_plan.has(&"pack2"), "nur eine Nacht")


func test_guard_is_killed_by_poison_paw() -> void:
	# RM-DR-119.1 über RM-DR-004: Die Giftpranke ist kein Wolfsangriff; die Dorfwache stirbt daran.
	var s := _run([_start([GW, "dorfwache", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), Command.start_night()] as Array[Command], "Start").state
	var quiet_pack := func(p: PendingPrompt) -> Command: return Command.skip_step(p.step_id, "Test: ruhige Nacht")
	var no_paw := func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [])
	s = _night(s, {"giftwolf": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [2]), "pack": quiet_pack}, "Nacht 1")
	s = _day(s)
	s = _night(s, {"giftwolf": no_paw, "pack": quiet_pack}, "Nacht 2")
	s = _day(s)
	s = _night(s, {"giftwolf": no_paw, "pack": quiet_pack}, "Nacht 3")
	if s == null:
		return
	var d := s.players[2].death
	assert_true(d != null and String(d.cause) == "WOLF_POISON", "Dorfwache stirbt an der Giftpranke")


func test_piercing_second_pack_attack_kills_guard() -> void:
	# RM-DR-119.2 über RM-DR-005: Das durchdringende Zusatzopfer des Rudelvaters durchdringt die Dorfwache.
	var s := _run([_start([RV, "werwolf", "schutzengel", "dorfwache", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [5])}, "Nacht 1")
	s = apply_ok(s, Command.nominate(5, 1), "Nominierung").state
	s = apply_ok(s, Command.decide_execution(1), "Lynch des Rudelvaters").state
	s = apply_ok(s, Command.end_day(), "Tagesende").state
	s = apply_ok(s, Command.start_night(), "Nacht 2").state
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [4]),
		"pack": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [6]),
		"pack2": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [4])}, "Nacht 2")
	if s == null:
		return
	var d := s.players[4].death
	assert_true(d != null and String(d.cause) == "NIGHT_KILL", "durchdringendes Zusatzopfer tötet Dorfwache trotz Immunität und Schutzengel")


# --- Seuchenwolf ----------------------------------------------------------------------------------

func test_blight_wolf_next_pack_attack_pierces_once() -> void:
	# 1 Seuchenwolf, 2 Werwolf, 3 Schutzengel, 4–8 Dorf. Tag 1: Lynch des Seuchenwolfs.
	var s := _run([_start([SW, "werwolf", "schutzengel", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), Command.start_night()] as Array[Command], "Start").state
	if s == null:
		return
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [4])}, "Nacht 1")
	s = apply_ok(s, Command.nominate(4, 1), "Nominierung").state
	s = apply_ok(s, Command.decide_execution(1), "Lynch").state
	s = apply_ok(s, Command.end_day(), "Tagesende").state
	s = apply_ok(s, Command.start_night(), "Nacht 2").state
	# Nacht 2 ohne Rudelopfer: verbraucht nichts.
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [5])}, "Nacht 2")
	s = _day(s)
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [5]),
		"pack": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [5])}, "Nacht 3")
	if s == null:
		return
	assert_false(s.players[5].alive, "Rudelangriff durchdringt den Schutz")
	s = _day(s)
	s = _night(s, {"schutzengel": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [6]),
		"pack": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [6])}, "Nacht 4")
	if s != null:
		assert_true(s.players[6].alive, "danach wirkt Schutz wieder")
