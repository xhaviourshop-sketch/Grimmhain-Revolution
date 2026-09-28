extends TestCase
## DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 3“ (28.09.2026), Nekromant:
##   RM-DR-142.1 (E-16) globaler Schild: verhindert den nächsten Tod irgendeiner Person (jede Ursache außer Korrektur,
##     auch Hinrichtung), verfällt mit Beginn der nächsten Nacht
##   RM-DR-142.2 (E-17) nur beim Rudelangriff auf ihn freiwillig drei Tote opfern und auf eine andere Lebende umlenken;
##     für das neue Ziel ein Rudelangriff (dessen Schutz wirkt)
##   RM-DR-142.3 (E-18) gemeinsamer Vorrat: jede tote Person einmal
##   RM-DR-142.4/.5 (E-19) einmal je Tag geheim einen Wolf benennen (`counts_as_wolf`), Treffer = Alleinsieg; keine Übung
##   RM-DR-142.6 (E-24) ein Vorrat für alle Nekromanten; jeder Schild verhindert einen Tod
##   RM-DR-142.7 (E-25) Entscheidung nach dem Verdammniswächter, vor der Märtyrerin
##   RM-DR-142.8 (E-26) Umlenkung nur, wenn er sonst stürbe
##   RM-DR-132.6 (E-20) Umlenkungsketten: jede Person höchstens einmal
## Abgeleitet: Der Schild ist eine Schutzwirkung; er greift nach Schutz und persönlichen Schilden und vor den
## Umlenkungen (E-12, B-07: Umlenkung erst nach allen Schutzwirkungen).

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


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entry() -> void:
	assert_true(RoleCatalog.has_role(&"nekromant"), "im Katalog")
	if not RoleCatalog.has_role(&"nekromant"):
		return
	assert_eq(RoleCatalog.faction_of(&"nekromant"), Faction.SOLO, "Einzelsieg")
	assert_eq(RoleCatalog.night_priority(&"nekromant"), 30, "Legacy-Stufe 3.0: nach Verdammniswächter (23), vor Märtyrerin (90)")
	assert_true(RoleCatalog.night_priority(&"verdammniswaechter") < 30 and 30 < RoleCatalog.night_priority(&"maertyrerin"), "E-25")


# --- Schild ---------------------------------------------------------------------------------------

func test_shield_prevents_next_death_of_anyone_once() -> void:
	var s := _state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"nekromant:2@targets": [7, 8, 9], "pack@": [4]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [], "Rudelopfer 4 überlebt")
	assert_eq(_shield_saves(log), [4] as Array[int], "Schild verhindert den Tod")
	assert_eq(s.necro_shields, [], "Schild verbraucht")
	assert_eq(s.necro_sacrificed, [7, 8, 9] as Array[int], "drei Tote geopfert")
	for e: GameEvent in log:
		if e.type in ["NecroShield", "NecroRedirected"]:
			assert_true(e.visibility == Visibility.GM, "nur Spielleiter")
	# Am selben Tag stirbt der Hingerichtete: der Schild ist schon verbraucht.
	s = _ok(s, Command.nominate(3, 5), "Nominierung")
	var r := apply_ok(s, Command.decide_execution(5), "Hinrichtung") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[5, "LYNCH"]], "zweiter Tod nicht verhindert")


func test_shield_blocks_execution_and_expires_with_next_night() -> void:
	var s := _state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9])
	s = _dawn(s, {"nekromant:2@targets": [7, 8, 9]})
	s = _ok(s, Command.nominate(3, 5), "Nominierung")
	var r := apply_ok(s, Command.decide_execution(5), "Hinrichtung") if s != null else null
	if r == null:
		return
	assert_eq(_deaths(r.events), [], "Hinrichtung verhindert (E-16)")
	assert_eq(_shield_saves(r.events), [5] as Array[int], "durch den Schild")
	assert_true(r.state.players[5].alive, "5 lebt")
	# Ungenutzt verfällt der Schild mit der nächsten Nacht.
	s = _state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9])
	s = _dawn(s, {"nekromant:2@targets": [7, 8, 9]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [4]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[4, "NIGHT_KILL"]], "abgelaufener Schild schützt nicht")


func test_shared_pool_each_dead_once_and_invalid_answers() -> void:
	var s := _state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9, 10])
	s = _ok(s, Command.start_night(), "Nacht")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Nekromant") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [7, 8, 9, 10] as Array[int], "nur Tote")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [7, 8]), "invalid_target_count", "zwei Tote")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [3, 7, 8]), "invalid_target", "Lebende")
	_codec_same(s, "offener Prompt")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [7, 8, 9]), "Schild")
	s = _ok(s, Command.end_night(), "Morgen")
	# Nächste Nacht: nur noch 10 im Vorrat; auch ein wiederbelebter und erneut gestorbener Geopferter zählt nicht.
	s = _ok(s, _gm("revive", {"target_id": 7}), "7 lebt")
	s = _ok(s, _gm("kill", {"target_id": 7, "trigger_effects": false}), "7 wieder tot")
	var log: Array[GameEvent] = []
	s = _dawn(s, {}, log)
	var dropped := events_of_type(log, "StepDropped").filter(func(e: GameEvent) -> bool: return String(e.data["step_id"]).contains("nekromant"))
	assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "no_decision", "zu wenige ungeopferte Tote")


func test_two_necromancers_share_pool_and_shields_count() -> void:
	var s := _state([W, NK, NK, D, D, D, D, D, D, D, D, D], [7, 8, 9, 10, 11, 12])
	var log: Array[GameEvent] = []
	s = _night(s, {"nekromant:2@targets": [7, 8, 9], "nekromant:3@targets": [10, 11, 12], "pack@": [4]}, log)
	if s == null:
		return
	var offered := events_of_type(log, "PromptOpened").filter(func(e: GameEvent) -> bool: return String(e.data["prompt"]["owner"]) == NK)
	assert_true(offered.size() == 2 and offered[1].data["prompt"]["allowed_ids"] == [10, 11, 12], "zweiter Nekromant: nur ungeopferte Tote")
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_shield_saves(r.events), [4] as Array[int], "erster Schild")
	assert_eq(r.state.necro_shields.size(), 1, "zweiter Schild noch aktiv (E-24)")
	s = _ok(r.state, Command.nominate(4, 5), "Nominierung")
	r = apply_ok(s, Command.decide_execution(5), "Hinrichtung") if s != null else null
	assert_eq(_shield_saves(r.events) if r != null else [], [5] as Array[int], "zweiter Schild")


# --- Umlenkung ------------------------------------------------------------------------------------

func test_redirect_pack_attack_to_another_person() -> void:
	var s := _state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": [5]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"]], "neues Ziel stirbt")
	assert_eq(String(s.players[5].death.source_kind), "pack", "als Rudelangriff")
	assert_true(s.players[2].alive, "Nekromant lebt")
	assert_eq(s.necro_shields, [], "kein Schild")
	assert_eq(s.necro_sacrificed, [7, 8, 9] as Array[int], "Tote geopfert")
	# Schutz des neuen Ziels wirkt.
	s = _state([W, NK, SE, D, D, D, D, D, D, D], [7, 8, 9])
	log = []
	s = _dawn(s, {"schutzengel:3@": [5], "pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": [5]}, log)
	assert_eq(_deaths(log), [], "Schutzengel schützt das neue Ziel")
	# Verzicht auf die Umlenkung: dann entsteht der Schild und rettet ihn.
	s = _state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9])
	log = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": []}, log)
	assert_eq(_deaths(log), [], "Schild statt Umlenkung")
	assert_eq(_shield_saves(log), [2] as Array[int], "Schild rettet den Nekromanten")


func test_no_redirect_when_he_would_not_die() -> void:
	# Schutzengel schützt den Nekromanten: nach den Toten gibt es keine Umlenkungsstufe, der Schild entsteht.
	var s := _state([W, NK, SE, D, D, D, D, D, D, D], [7, 8, 9])
	var log: Array[GameEvent] = []
	s = _night(s, {"schutzengel:3@": [2], "pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": [5]}, log)
	if s == null:
		return
	var stages := events_of_type(log, "PromptStageAnswered").filter(func(e: GameEvent) -> bool: return String(e.data.get("next_stage", "")) == "redirect")
	assert_eq(stages.size(), 0, "keine Frage nach Umlenkung (E-26)")
	assert_eq(s.necro_shields.size(), 1, "Schild errichtet")
	# Ein zuvor errichteter Schild eines anderen Nekromanten verhindert seinen Tod: ebenfalls keine Umlenkung.
	s = _state([W, NK, NK, D, D, D, D, D, D, D, D, D], [7, 8, 9, 10, 11, 12])
	log = []
	s = _night(s, {"pack@": [3], "nekromant:2@targets": [7, 8, 9], "nekromant:3@targets": [10, 11, 12], "nekromant:3@redirect": [5]}, log)
	stages = events_of_type(log, "PromptStageAnswered").filter(func(e: GameEvent) -> bool: return String(e.data.get("next_stage", "")) == "redirect")
	assert_eq(stages.size(), 0, "aktiver Schild: keine Umlenkung")


func test_martyr_sees_redirected_victim() -> void:
	# E-25: Der Nekromant lenkt vor der Märtyrerin um; sie opfert sich für das neue Ziel 5.
	var s := _state([W, NK, "maertyrerin", D, D, D, D, D, D, D], [7, 8, 9])
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": [5], "maertyrerin:3@": [5]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[3, "MARTYR_SACRIFICE"]], "Märtyrerin stirbt für das neue Ziel")
	assert_true(s.players[2].alive and s.players[5].alive, "Nekromant und neues Ziel leben")


# --- Wolf benennen --------------------------------------------------------------------------------

func test_name_wolf_once_per_day_secret_and_win() -> void:
	var s := _state([W, NK, D, D, D, D, D])
	s = _dawn(s)
	if s == null:
		return
	var miss := apply_ok(s, Command.name_wolf(2, 3), "Fehlversuch")
	for e: GameEvent in miss.events:
		assert_true(e.visibility == Visibility.GM, "geheim: %s" % e.type)
	s = miss.state
	assert_eq(s.necro_wins, [] as Array[int], "kein Sieg")
	_rejected_clean(s, Command.name_wolf(2, 1), "already_named_today", "zweiter Versuch am selben Tag")
	_rejected_clean(s, Command.name_wolf(3, 1), "not_necromancer", "andere Rolle")
	s = _dawn(s)
	if s == null:
		return
	_rejected_clean(s, Command.name_wolf(2, 2), "invalid_target", "sich selbst")
	s = _ok(s, Command.name_wolf(2, 1), "Treffer")
	if s == null:
		return
	assert_eq(s.necro_wins, [2] as Array[int], "Sieg erfüllt")
	var solo := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_NECROMANCER)
	assert_true(solo.size() == 1 and (solo[0] as WinCandidate).beneficiary_ids == ([2] as Array[int]), "Alleinsieg vorgeschlagen")
	_codec_same(s, "Sieg")
	# Nachts nicht; ein nur verfluchter Dorfbewohner ist kein Treffer.
	var t := _dawn(_state([W, NK, D, D, D, D, D]))
	if t == null:
		return
	t.players[4].cursed = true
	t = _ok(t, Command.name_wolf(2, 4), "Verfluchter")
	assert_eq(t.necro_wins if t != null else [0], [] as Array[int], "Fluch zählt nicht als Wolf")
	t = _night(t)
	if t != null:
		_rejected_clean(t, Command.name_wolf(2, 1), "wrong_phase", "nachts")


# --- Ketten und Kombinationen -----------------------------------------------------------------------

func test_redirect_to_priest_with_necromancer_doll_does_not_return() -> void:
	# Priester 3 hat den Nekromanten 2 als Puppe. Das Rudel greift 2 an, 2 lenkt auf 3 um; 3s Puppe ist 2
	# (schon betroffen, E-20) → 3 stirbt.
	var s := _dawn(_state([W, NK, VP, D, D, D, D, D, D, D], [7, 8, 9]), {"voodoo-priester:3@": [2]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": [3]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[3, "NIGHT_KILL"]], "Priester stirbt, keine Rückkehr zum Nekromanten")
	assert_true(s.players[2].alive, "Nekromant lebt")


func test_redirect_onto_fire_devil_target_burns_neighbours() -> void:
	var s := _dawn(_state([W, NK, D, FT, D, D, D, D, D, D], [8, 9, 10]), {"feuerteufel:4@": [5]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2], "nekromant:2@targets": [8, 9, 10], "nekromant:2@redirect": [5]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"], [6, "BURN"]], "Brand nach umgelenktem Rudelangriff; Feuerteufel 4 verschont")


func test_shield_acts_before_doll_and_after_personal_shields() -> void:
	# Schild vor der Puppe: Priester 3 (Puppe 5) wird angegriffen; der Schild verhindert seinen Tod, die Puppe bleibt.
	var s := _dawn(_state([W, NK, VP, D, D, D, D, D, D, D], [7, 8, 9]), {"voodoo-priester:3@": [5]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"nekromant:2@targets": [7, 8, 9], "pack@": [3]}, log)
	if s == null:
		return
	assert_eq(_shield_saves(log), [3] as Array[int], "Schild rettet den Priester")
	assert_eq(s.voodoo_dolls, [{"priest_id": 3, "doll_id": 5}], "Puppe nicht verbraucht")
	# Persönlicher Schild zuerst: Der Rudelvater überlebt einen Brand selbst, der Schild bleibt.
	s = _dawn(_state([W, NK, D, "rudelvater", FT, D, D, D, D, D], [8, 9, 10]), {"feuerteufel:5@": [3], "nekromant:2@targets": [8, 9, 10]})
	if s == null:
		return
	var r := apply_ok(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), "Ziel des Feuerteufels stirbt (Korrektur)")
	# Brand: Nachbarn 4 (Rudelvater, überlebt selbst) und 2 (Nekromant, Schild).
	assert_eq(_shield_saves(r.events), [2] as Array[int], "Schild nur für den Nekromanten, nicht für den Rudelvater")
	assert_true(r.state.players[4].alive and r.state.players[2].alive, "beide leben")


func test_load_rejects_inconsistent_state() -> void:
	var s := _dawn(_state([W, NK, D, D, D, D, D, D, D, D], [7, 8, 9]), {"nekromant:2@targets": [7, 8, 9]})
	if s == null:
		return
	_codec_same(s, "Schild")
	var bad_cases := [
		["necro_sacrificed", [9, 7]],
		["necro_sacrificed", [7, 7]],
		["necro_shields", [{"necro_id": 99, "night": 1}]],
		["necro_shields", [{"necro_id": 2, "night": 7}]],
		["necro_wins", [99]],
	]
	for bad: Array in bad_cases:
		var d := s.to_dict()
		d[bad[0]] = bad[1]
		assert_true(GameState.from_dict(d) == null, "abgelehnt: %s" % str(bad))
