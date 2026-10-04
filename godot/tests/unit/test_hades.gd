extends TestCase
## DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 4“ (28.09.2026), Hades:
##   RM-DR-144.2 (E-28) jeder tatsächliche Tod einer anderen Person außer Spielleiterkorrektur gibt jedem lebenden
##     Hades 1 Licht (eigener Vorrat), auch eigene Tötungen; abgefangene Tode geben nichts
##   RM-DR-144.1 (E-29) Alleinsieg, solange er lebt und mindestens 10 Lichter hat; kein Einlösen
##   RM-DR-144.4 (E-30) Tötung für 2 Lichter, höchstens einmal je Nacht, Tod am Morgen mit eigener Ursache; Rudelschutz
##     wirkt nicht, persönliche Schilde schon; die Lichter sind auch bei abgefangenem Tod verbraucht
##   RM-DR-144.3 (E-31) Barriere für 3 Lichter: höchstens eine aktive, verhindert seinen nächsten Tod jeder Ursache außer
##     Korrektur (auch Hinrichtung), kein Verfall, danach neu kaufbar; „Stimme x3“ entfällt
## Abgeleitet (delegierte Autorisierung): Hades handelt als letzter Nachtschritt (Legacy-Stufe 9.9); Tötung und Barriere
## in derselben Nacht sind erlaubt; Lichter und Barriere erlöschen mit Tod und Rollenverlust (wie E-10, E-22, E-27);
## die Barriere ist ein persönlicher Schild (vor dem Schild des Nekromanten und den Umlenkungen).

const H := "hades"
const D := "dorfbewohner"
const W := "werwolf"
const SE := "schutzengel"
const NK := "nekromant"
const VP := "voodoo-priester"


func _state(roles: Array, dead: Array = [], lights: Dictionary = {}) -> GameState:
	var r := RulesEngine.replay(Fixtures.start_with_copies(roles, 1))  # Kopien gleicher Rollen entstehen nach dem Start (PE-07)
	assert_true(r.ok, "Start (%s)" % r.error)
	var s := r.state if r.ok else null
	for id: int in dead:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Toter %d" % id)
	if s != null:
		for id: int in lights:
			s.hades_lights[id] = int(lights[id])
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
	if p.stage in [&"barrier", &"mode", &"grant"]:
		return Command.answer_choice(p.id, String(p.stage), false)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	if p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
		return Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
	if p.owner == &"feuerteufel":
		return Command.answer_prompt(p.id, Fixtures.pass_targets(s, p))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Antworten {"<rolle>:<id>@<stufe>" bzw. "pack@": Ziele oder bool}; Rudel ohne Antwort ohne Opfer.
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
			if answers.has(staged) and answers[staged] is bool:
				cmd = Command.answer_choice(p.id, String(p.stage), answers[staged])
			elif answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
				cmd = Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
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


func _lynch(s: GameState, nominator: int, target: int, log: Array[GameEvent] = []) -> GameState:
	s = _ok(s, Command.nominate(nominator, target), "Nominierung")
	if s == null:
		return null
	var r := apply_ok(s, Command.decide_execution(target), "Hinrichtung")
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


func _saves(events: Array[GameEvent], protection: String) -> Array[int]:
	var out: Array[int] = []
	for e: GameEvent in events_of_type(events, "KillPrevented"):
		if String(e.data.get("protection", "")) == protection:
			out.append(int(e.data["target_id"]))
	return out


func _rejected_clean(s: GameState, c: Command, error: String, label: String) -> void:
	var before := CanonicalJson.stringify(s.to_dict())
	var r := RulesEngine.apply(s, c)
	assert_false(r.ok, "%s abgelehnt" % label)
	assert_eq(String(r.error), error, "%s: Fehlergrund" % label)
	assert_true(r.events.is_empty(), "%s: keine Ereignisse" % label)
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: Zustand unverändert" % label)


func _hades_steps(events: Array[GameEvent]) -> Array[GameEvent]:
	return events_of_type(events, "PromptOpened").filter(func(e: GameEvent) -> bool: return String(e.data["prompt"]["owner"]) == H)


func _lights(s: GameState, id: int) -> int:
	return int(s.hades_lights.get(id, 0)) if s != null else -1


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entry() -> void:
	assert_true(RoleCatalog.has_role(&"hades"), "im Katalog")
	if not RoleCatalog.has_role(&"hades"):
		return
	assert_eq(RoleCatalog.faction_of(&"hades"), Faction.SOLO, "Einzelsieg")
	assert_false(RoleCatalog.counts_as_wolf(&"hades"), "kein Wolf")
	assert_eq(RoleCatalog.night_priority(&"hades"), 99, "Legacy-Stufe 9.9")
	for role: StringName in RoleCatalog.ROLES:
		if role != &"hades":
			assert_true(RoleCatalog.night_priority(role) < 99, "Hades handelt nach %s" % role)


# --- Lichter --------------------------------------------------------------------------------------

func test_lights_from_real_deaths_only_each_hades_own_pool() -> void:
	var s := _state([W, H, H, D, "amalia", "detektiv", SE, "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [4], "schutzengel:7@": [8]}, log)
	if s == null:
		return
	assert_eq([_lights(s, 2), _lights(s, 3)], [1, 1], "Rudelopfer: je 1 Licht")
	for e: GameEvent in events_of_type(log, "HadesLight"):
		assert_true(e.visibility == Visibility.GM, "Licht nur für den Spielleiter")
	assert_eq(events_of_type(log, "HadesLight").size(), 2, "ein Ereignis je Hades")
	s = _lynch(s, 5, 6)
	assert_eq([_lights(s, 2), _lights(s, 3)], [2, 2], "Hinrichtung: je 1 Licht")
	# Spielleiterkorrektur (auch mit Folgen) gibt nichts.
	s = _ok(s, _gm("kill", {"target_id": 9, "trigger_effects": true}), "Korrektur")
	assert_eq([_lights(s, 2), _lights(s, 3)], [2, 2], "Korrektur zählt nicht")
	# Abgefangener Tod: Schutzengel schützt 8 vor dem Rudel.
	log = []
	s = _dawn(s, {"pack@": [8], "schutzengel:7@": [8]}, log)
	assert_eq(_deaths(log), [], "8 überlebt")
	assert_eq([_lights(s, 2), _lights(s, 3)], [2, 2], "abgefangener Tod gibt nichts")
	# Stirbt Hades 3, erhält nur Hades 2 ein Licht; die Lichter von 3 erlöschen.
	s = _lynch(s, 5, 3)
	assert_eq(_lights(s, 2), 3, "Tod des anderen Hades zählt")
	assert_false(s.hades_lights.has(3) if s != null else true, "Lichter des Toten erloschen")
	_codec_same(s, "Lichter")


# --- Tötung ---------------------------------------------------------------------------------------

func test_kill_for_two_lights_dies_at_dawn_ignoring_pack_protection() -> void:
	var s := _state([W, H, SE, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"], [], {2: 2})
	var log: Array[GameEvent] = []
	s = _night(s, {"schutzengel:3@": [5], "hades:2@targets": [5]}, log)
	if s == null:
		return
	var steps := _hades_steps(log)
	assert_eq(steps.size(), 1, "ein Hades-Schritt")
	if steps.size() == 1:
		assert_eq(steps[0].data["prompt"]["allowed_ids"], [1, 3, 4, 5, 6, 7, 8, 9, 10], "andere Lebende")
	assert_true(s.players[5].alive, "Tod erst am Morgen")
	assert_eq(_lights(s, 2), 0, "2 Lichter bezahlt")
	var stages := events_of_type(log, "PromptStageAnswered").filter(func(e: GameEvent) -> bool: return String(e.data.get("next_stage", "")) == "barrier")
	assert_eq(stages.size(), 0, "ohne 3 übrige Lichter keine Barrierenfrage")
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_deaths(r.events), [[5, "HADES_KILL"]], "Schutzengel wirkt nicht gegen Hades")
	assert_eq(String(r.state.players[5].death.source_kind), "player", "Quelle Person")
	assert_eq(r.state.players[5].death.source_id, 2, "Quelle Hades")
	assert_eq(_lights(r.state, 2), 1, "eigene Tötung gibt ein Licht")


func test_kill_prevented_by_necromancer_shield_still_costs_lights() -> void:
	var s := _state([W, H, NK, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"], [8, 9, 10], {2: 2})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"nekromant:3@targets": [8, 9, 10], "hades:2@targets": [5]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [], "Schild fängt die Tötung ab")
	assert_eq(_saves(log, NK), [5] as Array[int], "durch den Nekromanten")
	assert_eq(_lights(s, 2), 0, "Lichter verbraucht, keine Erstattung, kein Licht")


func test_no_step_below_two_lights_and_invalid_answers() -> void:
	var s := _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [9], {2: 1})
	var log: Array[GameEvent] = []
	s = _dawn(s, {}, log)
	assert_eq(_hades_steps(log).size(), 0, "ein Licht: kein Schritt")
	if s == null:
		return
	s.hades_lights[2] = 2
	s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
	s = _ok(s, Command.end_day(), "Tagesende")
	s = _ok(s, Command.start_night(), "Nacht")
	s = _ok(s, Command.skip_step(s.pending_prompt.step_id, "Test: ruhige Nacht"), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Hades") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(String(p.owner), H, "Hades-Prompt")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [2]), "invalid_target", "sich selbst")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [9]), "invalid_target", "Toter")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [4, 5]), "invalid_target_count", "zwei Ziele")
	_rejected_clean(s, Command.answer_choice(p.id, "barrier", true), "stage_mismatch", "falsche Stufe")
	_codec_same(s, "offener Prompt")
	var cancelled := _ok(s, Command.cancel_prompt(p.id, "Test"), "Abbruch")
	assert_eq(_lights(cancelled, 2), 2, "Abbruch kostet nichts")


# --- Barriere -------------------------------------------------------------------------------------

func test_barrier_blocks_next_death_including_execution_not_correction() -> void:
	var s := _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [], {2: 3})
	var log: Array[GameEvent] = []
	s = _night(s, {"hades:2@targets": [], "hades:2@barrier": true}, log)
	if s == null:
		return
	assert_eq(s.hades_barriers, [2] as Array[int], "Barriere aktiv")
	assert_eq(_lights(s, 2), 0, "3 Lichter bezahlt")
	_codec_same(s, "Barriere")
	s = _ok(s, Command.end_night(), "Morgen")
	log = []
	s = _lynch(s, 3, 2, log)
	assert_eq(_deaths(log), [], "Hinrichtung verhindert")
	assert_eq(_saves(log, H), [2] as Array[int], "durch die Barriere")
	assert_eq(s.hades_barriers if s != null else [0], [] as Array[int], "Barriere verbraucht")
	# Neue Barriere; die Korrektur tötet trotzdem.
	s = _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [], {2: 3})
	s = _dawn(s, {"hades:2@targets": [], "hades:2@barrier": true})
	log = []
	var r := apply_ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Korrektur") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[2, "GM_CORRECTION"]], "Korrektur wirkt")
	assert_eq(r.state.hades_barriers if r != null else [0], [] as Array[int], "Barriere erloschen")


func test_only_one_barrier_kill_and_barrier_same_night() -> void:
	# Mit aktiver Barriere keine Barrierenfrage; Tötung und Barriere in derselben Nacht sind erlaubt.
	var s := _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [], {2: 5})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"hades:2@targets": [4], "hades:2@barrier": true}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[4, "HADES_KILL"]], "Tötung")
	assert_eq(s.hades_barriers, [2] as Array[int], "Barriere gekauft")
	assert_eq(_lights(s, 2), 1, "5 − 2 − 3 + 1 (eigene Tötung)")
	s.hades_lights[2] = 5
	log = []
	s = _dawn(s, {"hades:2@targets": []}, log)
	var stages := events_of_type(log, "PromptStageAnswered").filter(func(e: GameEvent) -> bool: return String(e.data.get("next_stage", "")) == "barrier")
	assert_eq(stages.size(), 0, "keine zweite Barriere")
	assert_eq(_lights(s, 2), 5, "Verzicht kostet nichts")


func test_barrier_holds_against_packfather_extra_and_martyr_stays_out() -> void:
	# Rudelangriff auf Hades mit Barriere: die Märtyrerin wird nicht gefragt, die Barriere rettet ihn.
	var s := _state([W, H, "maertyrerin", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"], [], {2: 3})
	s = _dawn(s, {"hades:2@targets": [], "hades:2@barrier": true})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "maertyrerin:3@": [2]}, log)
	if s == null:
		return
	var martyr := events_of_type(log, "StepDropped").filter(func(e: GameEvent) -> bool: return String(e.data["step_id"]).contains("maertyrerin"))
	assert_true(martyr.size() == 1 and String(martyr[0].data["reason"]) == "no_decision", "Märtyrerin: Hades stirbt nicht")
	assert_eq(_saves(log, H), [2] as Array[int], "Barriere fängt den Rudelangriff ab")
	assert_eq(_deaths(log), [], "Hades lebt")
	# Das durchdringende Zusatzopfer des Rudelvaters durchbricht die Barriere nicht (E-31: jede Ursache außer Korrektur).
	s = _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [], {2: 3})
	s = _dawn(s, {"hades:2@targets": [], "hades:2@barrier": true})
	s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
	s = _ok(s, Command.end_day(), "Tagesende")
	if s == null:
		return
	s.pack_bonus_pending = true  # wie nach dem Lynch eines Rudelvaters
	log = []
	s = _dawn(s, {"pack2@": [2]}, log)
	assert_eq(_saves(log, H), [2] as Array[int], "Barriere gegen das Zusatzopfer")
	assert_eq(_deaths(log), [], "Hades lebt")


# --- Sieg -----------------------------------------------------------------------------------------

func test_win_while_alive_with_ten_lights() -> void:
	var s := _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [], {2: 9})
	s = _dawn(s, {"pack@": [4], "hades:2@targets": []})
	if s == null:
		return
	assert_eq(_lights(s, 2), 10, "10 Lichter")
	var solo := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_HADES)
	assert_true(solo.size() == 1 and (solo[0] as WinCandidate).beneficiary_ids == ([2] as Array[int]), "Alleinsieg vorgeschlagen")
	_codec_same(s, "Sieg offen")
	s = _ok(s, Command.create(Command.REJECT_WIN, {"reason": "weiter"}), "abgelehnt")
	# Er gibt 2 aus (Tötung), erhält 1 zurück: 9 < 10, kein Hades-Kandidat mehr.
	s = _dawn(s, {"hades:2@targets": [5]})
	if s == null:
		return
	assert_eq(_lights(s, 2), 9, "10 − 2 + 1")
	assert_eq(s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_HADES).size(), 0, "unter 10 kein Sieg")


# --- Rollenverlust, Kopien, Umlenkung --------------------------------------------------------------

func test_role_loss_clears_lights_new_holder_starts_fresh() -> void:
	# Seelentauscher (80) vor Hades (99): 2 und 4 tauschen, der Schritt von 2 entfällt.
	var s := _state([W, H, "seelentauscher", D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise", "nachtwaechter", "ritter"], [], {2: 4})
	s.hades_barriers.append(2)
	var log: Array[GameEvent] = []
	s = _night(s, {"seelentauscher:3@targets": [2, 4]}, log)
	if s == null:
		return
	assert_eq(String(s.players[4].role_id), H, "4 ist Hades")
	assert_false(s.hades_lights.has(2) or s.hades_lights.has(4), "keine übernommenen Lichter")
	assert_eq(s.hades_barriers, [] as Array[int], "Barriere erloschen")
	assert_eq(_hades_steps(log).size(), 0, "kein Hades-Schritt")
	_codec_same(s, "nach Tausch")


func test_two_hades_barrier_absorbs_other_kill() -> void:
	# Hades 3 kauft in Nacht 1 die Barriere; in Nacht 2 tötet Hades 2 ihn: die Barriere fängt ab, niemand erhält ein Licht.
	var s := _state([W, H, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"], [], {3: 3})
	s = _dawn(s, {"hades:3@targets": [], "hades:3@barrier": true})
	if s == null:
		return
	s.hades_lights[2] = 2
	s.hades_lights[3] = 2
	var log: Array[GameEvent] = []
	s = _dawn(s, {"hades:2@targets": [3]}, log)
	if s == null:
		return
	# Nachttode: Wer eine Todesmarkierung hat, wacht in dieser Nacht nicht mehr auf, auch ein anderer Hades.
	var dropped := events_of_type(log, "StepDropped").filter(func(e: GameEvent) -> bool: return String(e.data["step_id"]).ends_with("hades:3"))
	assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "marked_for_death", "markierter Hades 3 handelt nicht mehr")
	assert_eq(_deaths(log), [], "Barriere von 3 fängt die Tötung ab")
	assert_eq(_saves(log, H), [3] as Array[int], "Hades-Barriere")
	assert_eq([_lights(s, 2), _lights(s, 3)], [0, 2], "keine neuen Lichter")
	assert_eq(s.hades_barriers, [] as Array[int], "verbraucht")


func test_kill_on_voodoo_priest_redirected_to_doll_gives_light() -> void:
	var s := _dawn(_state([W, H, VP, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"]), {"voodoo-priester:3@": [5]})
	if s == null:
		return
	s.hades_lights[2] = 2
	var log: Array[GameEvent] = []
	s = _dawn(s, {"hades:2@targets": [3]}, log)
	assert_eq(_deaths(log), [[5, "HADES_KILL"]], "Puppe stirbt statt des Priesters")
	assert_eq(_lights(s, 2), 1, "ein Licht für die Puppe")


func test_load_rejects_inconsistent_state() -> void:
	var s := _state([W, H, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter", "ritter"], [], {2: 4})
	if s == null:
		return
	s.hades_barriers.append(2)
	_codec_same(s, "Lichter und Barriere")
	var bad_cases := [
		["hades_lights", {"99": 1}],
		["hades_lights", {"4": 3}],
		["hades_lights", {"2": 0}],
		["hades_barriers", [4]],
		["hades_barriers", [2, 2]],
	]
	for bad: Array in bad_cases:
		var d := s.to_dict()
		d[bad[0]] = bad[1]
		assert_true(GameState.from_dict(d) == null, "abgelehnt: %s" % str(bad))
