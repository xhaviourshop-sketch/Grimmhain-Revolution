extends TestCase
## Kombinationen der Einzelsiegrollen Teil 2/3 (Feuerteufel, Voodoo-Priester, Nekromant) mit Schattenwanderer und
## persönlichen Schilden: vollständig aufgelöste Ketten mit Ursache, Quelle, Ziel, Ereignisreihenfolge und
## Siegprüfung erst nach der ganzen Kette (DR-14). Dazu gezielte Feuerteufel-Regressionen für seltene Mechaniken
## (Apfel, Lehrling-Erbe, Seelentausch, Brand an Märtyrerin, Schattenwanderer und Ewigen).

const NK := "nekromant"
const D := "dorfbewohner"
const W := "werwolf"
const SE := "schutzengel"
const VP := "voodoo-priester"
const FT := "feuerteufel"


func _state(roles: Array, dead: Array = []) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	var s := r.state if r.ok else null
	for id: int in dead:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Toter %d" % id)
	return s


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
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Antworten {"<rolle>:<id>@<stufe>" bzw. "pack@": Ziele}; Rudel ohne Antwort ohne Opfer. Endet vor EndNight.
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
			if answers.has(staged) and answers[staged] is Callable:
				cmd = (answers[staged] as Callable).call(p)
			elif answers.has(staged):
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


func _dawn(s: GameState, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
	s = _night(s, answers, log)
	if s == null:
		return null
	var r := apply_ok(s, Command.end_night(), "Morgen")
	log.append_array(r.events)
	return r.state


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _deaths(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events_of_type(events, "SeatDied"):
		out.append([int(e.data["target_id"]), String(e.data["cause"])])
	return out


func _shield_saves(events: Array[GameEvent]) -> Array[int]:
	var out: Array[int] = []
	for e: GameEvent in events_of_type(events, "KillPrevented"):
		if String(e.data.get("protection", "")) == NK:
			out.append(int(e.data["target_id"]))
	return out


func _rejected_clean(s: GameState, c: Command, error: String, label: String) -> void:
	var before := CanonicalJson.stringify(s.to_dict())
	var r := RulesEngine.apply(s, c)
	assert_false(r.ok, "%s abgelehnt" % label)
	assert_eq(String(r.error), error, "%s: Fehlergrund" % label)
	assert_true(r.events.is_empty(), "%s: keine Ereignisse" % label)
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: Zustand unverändert" % label)



func _types(events: Array[GameEvent], wanted: Array) -> Array:
	var out: Array = []
	for e: GameEvent in events:
		if wanted.has(String(e.type)):
			out.append(String(e.type))
	return out


func test_necro_redirect_to_priest_doll_burns_last_wolf_then_village_wins() -> void:
	# Sitze 1–10: 1 Dorf, 2 Nekromant, 3 Priester, 4 Dorf, 5 Feuerteufel, 6 Dorf, 7 letzter Wolf, 8–10 tot.
	var s := _state([D, NK, VP, D, FT, D, W, D, D, D], [8, 9, 10])
	s = _dawn(s, {"voodoo-priester:3@": [6], "feuerteufel:5@": [6]})
	var log: Array[GameEvent] = []
	s = _night(s, {"pack@": [2], "nekromant:2@targets": [8, 9, 10], "nekromant:2@redirect": [3]}, log)
	if s == null:
		return
	var dawn := apply_ok(s, Command.end_night(), "Morgen")
	var ev := dawn.events
	assert_eq(_deaths(ev), [[6, "NIGHT_KILL"], [7, "BURN"]], "Puppe stirbt am Rudelangriff, der letzte Wolf verbrennt")
	var died := events_of_type(ev, "SeatDied")
	if died.size() == 2:
		assert_eq(String(died[0].data["source_kind"]), "pack", "Puppe: Quelle Rudel")
		assert_eq([String(died[1].data["source_kind"]), int(died[1].data["source_id"])], ["player", 5], "Brand: Quelle Feuerteufel 5")
	var redirect := events_of_type(ev, "KillPrevented")
	assert_true(redirect.size() == 1 and String(redirect[0].data["protection"]) == VP and int(redirect[0].data["target_id"]) == 3 and int(redirect[0].data["redirected_to"]) == 6, "Priester 3 → Puppe 6")
	assert_eq(_types(ev, ["KillPrevented", "SeatDied", "FireBurned", "WinStatusProvisional", "WinStatusFinal", "WinDetected"]),
		["KillPrevented", "SeatDied", "FireBurned", "SeatDied", "WinStatusProvisional", "WinStatusProvisional", "WinStatusFinal", "WinDetected"],
		"Reihenfolge: Umlenkung, Tod, Brand, Tod (Todesfolgen vor dem vorläufigen Status wie beim Kutscher), je Tod ein vorläufiger Status, verbindliche Prüfung erst nach der ganzen Kette")
	var open := dawn.state.open_candidates()
	assert_eq(open.size(), 1, "ein Kandidat")
	if open.size() == 1:
		assert_eq(open[0].reason_key, WinCandidate.REASON_NO_WOLVES_ALIVE, "Dorfsieg")
		assert_eq(open[0].co_winner_ids, [5] as Array[int], "Feuerteufel gewinnt mit")
	assert_true(dawn.state.players[2].alive and dawn.state.players[3].alive, "Nekromant und Priester leben")
	assert_eq(dawn.state.voodoo_dolls, [], "Puppe verbraucht")
	assert_eq(dawn.state.fire_marks, [], "Markierung verbraucht")
	_codec_same(dawn.state, "nach Kette")


func test_shield_before_shadow_link_and_after_personal_shield() -> void:
	# Schattenwanderer 3 verknüpft sich mit 5; Schild aktiv; das Rudel greift 5 an → Schild verhindert, Verknüpfung bleibt.
	var s := _state([W, NK, "schattenwanderer", D, D, D, D, D, D, D], [8, 9, 10])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"schattenwanderer:3@": [5], "nekromant:2@targets": [8, 9, 10], "pack@": [5]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [], "niemand stirbt")
	assert_eq(_shield_saves(log), [5] as Array[int], "Schild vor der Verknüpfung")
	assert_eq(s.shadow_links.size(), 1, "Verknüpfung ungenutzt")
	# Rudelvater (persönlicher Schild) wird vom Brand getroffen: er überlebt selbst, der Schild bleibt für den nächsten Tod.
	s = _state([W, NK, D, "rudelvater", FT, D, D, D, D, D], [8, 9, 10])
	s = _dawn(s, {"feuerteufel:5@": [3], "nekromant:2@targets": [8, 9, 10]})
	if s == null:
		return
	var r := apply_ok(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), "Ziel stirbt per Korrektur (Schild greift nicht)")
	assert_eq(_deaths(r.events), [[3, "GM_CORRECTION"]], "nur das Ziel stirbt")
	var prevented := events_of_type(r.events, "KillPrevented")
	assert_eq(prevented.map(func(e: GameEvent) -> String: return String(e.data["protection"])), ["rudelvater", "nekromant"], "erst persönlicher Schild (4), dann globaler Schild (2)")


# --- Feuerteufel-Regressionen ------------------------------------------------------------------------

func test_fire_devil_apple_doubles_step_one_mark_remains() -> void:
	var s := _dawn(_state([W, FT, D, D, D, D, D]), {"feuerteufel:2@": [4]})
	if s == null:
		return
	s.apples[2] = 2  # Apfel für Nacht 2 (R-02, R-03)
	var picks := [5, 6]
	var log: Array[GameEvent] = []
	s = _night(s, {"feuerteufel:2@": func(p: PendingPrompt) -> Command: return Command.answer_prompt(p.id, [picks.pop_front()])}, log)
	if s == null:
		return
	assert_eq(s.night_plan.count(&"feuerteufel:2"), 2, "Schritt verdoppelt")
	assert_eq(events_of_type(log, "AppleUsed").size(), 1, "Apfel verbraucht")
	assert_eq(events_of_type(log, "FireMarked").size(), 2, "zwei Wahlen")
	assert_eq(s.fire_marks, [{"devil_id": 2, "target_id": 6}], "höchstens eine Markierung: die zweite Wahl gilt (E-06)")


func test_fire_devil_inherited_by_apprentice_starts_without_mark() -> void:
	# Lehrling 3 bindet an Feuerteufel 2; Feuerteufel markiert 6, stirbt am Tag; 3 erbt ohne Markierung.
	var candidates := func(p: PendingPrompt) -> Command: return Command.answer_stage_targets(p.id, "candidates", [2, 4, 5])
	var option := func(p: PendingPrompt) -> Command: return Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "option", "option": (p.partial["options"] as Array).find(FT)})
	var confirm := func(p: PendingPrompt) -> Command: return Command.answer_choice(p.id, "confirm", true)
	var s := _dawn(_state([W, FT, "lehrling", D, D, D, D, D]), {"lehrling:3@candidates": candidates, "lehrling:3@option": option, "lehrling:3@confirm": confirm, "feuerteufel:2@": [6]})
	if s == null:
		return
	assert_eq(s.fire_marks, [{"devil_id": 2, "target_id": 6}], "Meister hat markiert")
	s = _ok(s, Command.nominate(4, 2), "Nominierung")
	s = _ok(s, Command.decide_execution(2), "Feuerteufel hingerichtet")
	if s == null:
		return
	assert_eq(String(s.players[3].role_id), FT, "Lehrling erbt die Rolle")
	assert_eq(s.fire_marks, [], "Markierung des Meisters erloschen, Erbe ohne Markierung (E-10)")
	var r := apply_ok(s, _gm("kill", {"target_id": 6, "trigger_effects": true}), "altes Ziel stirbt")
	assert_eq(events_of_type(r.events, "FireBurned").size(), 0, "kein Brand aus der alten Markierung")
	s = _dawn(r.state, {"feuerteufel:3@": [5]})
	assert_eq(s.fire_marks if s != null else [], [{"devil_id": 3, "target_id": 5}], "Erbe markiert selbst")


func test_fire_devil_soul_swap_removes_mark() -> void:
	# Feuerteufel 2 (76) markiert 5, danach tauscht der Seelentauscher 3 (80) die Rollen von 2 und 4.
	var s := _dawn(_state([W, FT, "seelentauscher", D, D, D, D, D]), {"feuerteufel:2@": [5], "seelentauscher:3@targets": [2, 4]})
	if s == null:
		return
	assert_eq(String(s.players[4].role_id), FT, "4 ist jetzt Feuerteufel")
	assert_eq(s.fire_marks, [], "Markierung mit dem Rollenverlust erloschen (E-10)")
	var r := apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "früheres Ziel stirbt")
	assert_eq(events_of_type(r.events, "FireBurned").size(), 0, "kein Brand")


func test_burn_hits_martyr_shadow_walker_link_and_eternal() -> void:
	# Märtyrerin 4 neben dem Ziel 5 verbrennt.
	var s := _dawn(_state([W, FT, D, "maertyrerin", D, D, D, D]), {"feuerteufel:2@": [5]})
	var r := apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Ziel stirbt") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[5, "GM_CORRECTION"], [6, "BURN"], [4, "BURN"]], "Märtyrerin verbrennt")
	# Schattenwanderer 6 (verknüpft mit 4) neben dem Ziel 5: sein Brandtod trifft 4 (B-04), Quelle bleibt der Feuerteufel.
	s = _dawn(_state([W, FT, D, D, D, "schattenwanderer", D, D]), {"schattenwanderer:6@": [4], "feuerteufel:2@": [5]})
	r = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Ziel stirbt") if s != null else null
	if r != null:
		assert_eq(_deaths(r.events), [[5, "GM_CORRECTION"], [4, "BURN"]], "Umlenkung auf 4; 4 ist danach schon tot")
		assert_eq(r.state.players[4].death.source_id, 2, "Quelle Feuerteufel")
		assert_true(r.state.players[6].alive, "Schattenwanderer lebt")
	# Die Ewigen 4 neben dem Ziel 5 verbrennen.
	s = _dawn(_state([W, FT, D, "die-ewigen", D, D, D, D]), {"feuerteufel:2@": [5]})
	r = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Ziel stirbt") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[5, "GM_CORRECTION"], [6, "BURN"], [4, "BURN"]], "Ewige verbrennt")


# --- Interaktionslücken (Rollenaudit 28.09.2026) -----------------------------------------------------

func test_necro_redirects_packfather_extra_victim_piercing() -> void:
	# Zusatzopfer des Rudelvaters (pack2) ist der Nekromant 2: er lenkt auf 6 um. Der Angriff bleibt durchdringend,
	# der Schutzengel 5 auf 6 hilft nicht (RM-DR-005, RM-DR-112); ausgelöst wird der zweite Rudelschritt.
	var s := _state([W, NK, D, D, SE, D, D, D, D, D], [8, 9, 10])
	if s == null:
		return
	s.pack_bonus_pending = true  # wie nach dem Lynch eines Rudelvaters
	var log: Array[GameEvent] = []
	s = _dawn(s, {"schutzengel:5@": [6], "pack2@": [2], "nekromant:2@targets": [8, 9, 10], "nekromant:2@redirect": [6]}, log)
	if s == null:
		return
	var redirected := events_of_type(log, "NecroRedirected")
	assert_true(redirected.size() == 1 and String(redirected[0].data["slot"]) == "pack2" and int(redirected[0].data["target_id"]) == 6, "Umlenkung des Zusatzopfers")
	assert_eq(_deaths(log), [[6, "NIGHT_KILL"]], "neues Ziel stirbt trotz Schutzengel (durchdringend)")
	assert_eq(String(s.players[6].death.source_kind), "pack", "Rudelangriff")
	assert_true(s.players[2].alive, "Nekromant lebt")


func test_necro_attacked_by_pack_and_packfather_redirects_first_only() -> void:
	# Beide Rudelangriffe treffen den Nekromanten: er entscheidet einmal (sein Schritt), für den ersten Angriff, der ihn
	# töten würde (Rudel); das Zusatzopfer trifft ihn danach und tötet ihn.
	var s := _state([W, NK, D, D, D, D, D, D, D, D], [8, 9, 10])
	if s == null:
		return
	s.pack_bonus_pending = true
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "pack2@": [2], "nekromant:2@targets": [8, 9, 10], "nekromant:2@redirect": [5]}, log)
	var redirected := events_of_type(log, "NecroRedirected")
	assert_true(redirected.size() == 1 and String(redirected[0].data["slot"]) == "pack", "Umlenkung des ersten Angriffs")
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"], [2, "NIGHT_KILL"]], "5 statt des Nekromanten, dann das Zusatzopfer")


func test_doom_warden_judges_necro_who_redirects_back_to_original_victim() -> void:
	# Vollständiger Ablauf: Rudel wählt 4; der Verdammniswächter 3 (23) erhält das einzige mögliche Angebot, den
	# Nekromanten 2, und wählt ihn; der Nekromant (30) würde sterben und lenkt auf 4 um. Das Urteil bestimmt das
	# Rudelopfer und ist kein Kettenglied (E-20 nennt Puppe, Schattenwanderer, Nekromant): 4 darf Ziel sein.
	var s := _state([W, NK, "verdammniswaechter", D, D, D, D, D, D, D], [5, 6, 7, 8, 9, 10])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [4], "verdammniswaechter:3@": [2], "nekromant:2@targets": [5, 6, 7], "nekromant:2@redirect": [4]}, log)
	if s == null:
		return
	var judged := events_of_type(log, "DoomJudged")
	assert_true(judged.size() == 1 and int(judged[0].data["offer_id"]) == 2 and int(judged[0].data["chosen_id"]) == 2, "Urteil auf den Nekromanten")
	assert_eq(_types(log, ["DoomJudged", "NecroRedirected", "SeatDied"]), ["DoomJudged", "NecroRedirected", "SeatDied"], "Reihenfolge")
	assert_eq(_deaths(log), [[4, "NIGHT_KILL"]], "ursprüngliches Opfer stirbt doch")
	assert_true(s.players[2].alive and s.players[3].alive, "Nekromant und Wächter leben")
	_codec_same(s, "nach Urteil und Umlenkung")


func test_necro_redirect_through_two_priests_to_second_doll() -> void:
	# Priester 3 hat Priester 4 als Puppe, 4 hat 5. Rudel → Nekromant 2 → 3 → 4 → 5: 5 stirbt, beide Puppen verbraucht.
	var s := _dawn(_state([W, NK, VP, VP, D, D, D, D, D, D], [8, 9, 10]), {"voodoo-priester:3@": [4], "voodoo-priester:4@": [5]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [8, 9, 10], "nekromant:2@redirect": [3]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"]], "Ende der Kette stirbt")
	var hops: Array = []
	for e: GameEvent in events_of_type(log, "KillPrevented"):
		hops.append([int(e.data["target_id"]), int(e.data.get("redirected_to", -1))])
	assert_eq(hops, [[3, 4], [4, 5]], "Puppe von 3, dann Puppe von 4")
	assert_eq(s.voodoo_dolls, [], "beide Puppen verbraucht")


func test_necro_redirect_through_two_priests_never_returns_to_necro() -> void:
	# Priester 4 hat den Nekromanten 2 als Puppe: Kette 2 → 3 → 4, 2 ist schon betroffen (E-20) → 4 stirbt.
	var s := _dawn(_state([W, NK, VP, VP, D, D, D, D, D, D], [8, 9, 10]), {"voodoo-priester:3@": [4], "voodoo-priester:4@": [2]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [8, 9, 10], "nekromant:2@redirect": [3]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[4, "NIGHT_KILL"]], "zweiter Priester stirbt, keine Rückkehr")
	assert_true(s.players[2].alive and s.players[3].alive, "Nekromant und erster Priester leben")
	assert_eq(s.voodoo_dolls, [], "Puppe von 3 verbraucht, Puppe von 4 endet mit seinem Tod")
