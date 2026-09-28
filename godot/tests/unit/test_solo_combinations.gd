extends TestCase
## Kombinationen der Einzelsiegrollen Teil 2/3 (Feuerteufel, Voodoo-Priester, Nekromant) mit Schattenwanderer und
## persönlichen Schilden: vollständig aufgelöste Ketten mit Ursache, Quelle, Ziel, Ereignisreihenfolge und
## Siegprüfung erst nach der ganzen Kette (DR-14).

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
