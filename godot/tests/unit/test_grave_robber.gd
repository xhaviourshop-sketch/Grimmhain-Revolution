extends TestCase
## DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 4“ (28.09.2026), Grabräuber:
##   RM-DR-156.1 (E-32) einmalig nachts eine tote Person wählen; ab der nächsten Nacht dauerhaft deren Nachtfähigkeit
##     (eigener Schritt, frische Einsätze); er bleibt Grabräuber mit eigener Siegbedingung
##   RM-DR-156.2 (E-33) Alleinsieg, wenn er lebt und höchstens drei Personen leben
##   RM-DR-156.3 (E-34) jede tote Person mit eigenem Nachtschritt, auch Wolfs- und Einzelsiegrollen; ohne Zähler oder
##     Zustände der Toten
## Abgeleitet (delegierte Autorisierung), siehe Decision Log „Grabräuber, abgeleitete Präzisierungen“:
##   - wählbar sind Rollen mit wiederkehrendem eigenem Nachtschritt eines Lebenden; nicht Nur-Nacht-1-Rollen (Loki,
##     Dorfchronistin, Todesprediger), der Prophet (markiert nur in Nacht 1), der Schutzgeist (handelt nur tot), Wolfskind
##     und Lehrling (ihre Fähigkeit ist ein eigener Rollenwechsel) und der Grabräuber selbst
##   - übernommen wird der Nachtschritt mit allen Wirkungen, die er erzeugt (Puppe, Markierung, Wirt, Schild, Lichter);
##     nicht Siegbedingung, Mitsieg, Fraktion, Wolfszählung, Todesreaktionen oder Tagesaktionen
##   - Blockade und Fluch des Weisen richten sich nach der handelnden Person (Einzelsieg: weder blockierbar noch verflucht)
##   - die Fähigkeit endet mit seinem Tod oder Rollenverlust; nach einer Wiederbelebung darf er frisch erneut stehlen

const GR := "grabraeuber"
const D := "dorfbewohner"
const W := "werwolf"
const WH := "waldhexe"
const VP := "voodoo-priester"


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
		return Command.answer_choice(p.id, String(p.stage), p.stage in [&"confirm", &"reveal"])
	if p.stage in [&"shown", &"use"]:
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"shown")
	if p.stage in [&"barrier", &"mode", &"grant"]:
		return Command.answer_choice(p.id, String(p.stage), false)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
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


func _rejected_clean(s: GameState, c: Command, error: String, label: String) -> void:
	var before := CanonicalJson.stringify(s.to_dict())
	var r := RulesEngine.apply(s, c)
	assert_false(r.ok, "%s abgelehnt" % label)
	assert_eq(String(r.error), error, "%s: Fehlergrund" % label)
	assert_true(r.events.is_empty(), "%s: keine Ereignisse" % label)
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: Zustand unverändert" % label)


func _opened(events: Array[GameEvent], step_suffix: String) -> Array[GameEvent]:
	return events_of_type(events, "PromptOpened").filter(func(e: GameEvent) -> bool: return String(e.data["prompt"]["step_id"]).ends_with(step_suffix))


## Startzustand am Beginn der Grabräuber-Nacht: Nacht 1 läuft bis zum Prompt des Grabräubers 2.
func _at_robber_prompt(roles: Array, dead: Array) -> GameState:
	var s := _state(roles, dead)
	s = _ok(s, Command.start_night(), "Nacht")
	for guard: int in 20:
		if s == null or (s.pending_prompt != null and s.pending_prompt.owner == &"grabraeuber"):
			return s
		if s.pending_prompt != null:
			s = _ok(s, _auto(s) if s.pending_prompt.owner != PendingPrompt.OWNER_PACK else Command.answer_prompt(s.pending_prompt.id, []), "vorher")
		else:
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
	fail("kein Grabräuber-Prompt")
	return null


# --- Katalog und Auswahl ---------------------------------------------------------------------------

func test_catalog_entry_and_stealable_roles() -> void:
	assert_true(RoleCatalog.has_role(&"grabraeuber"), "im Katalog")
	if not RoleCatalog.has_role(&"grabraeuber"):
		return
	assert_eq(RoleCatalog.faction_of(&"grabraeuber"), Faction.SOLO, "Einzelsieg")
	assert_false(RoleCatalog.counts_as_wolf(&"grabraeuber"), "kein Wolf")
	assert_eq(RoleCatalog.night_priority(&"grabraeuber"), 64, "Legacy-Stufe 6.4")
	for role: StringName in [&"waldhexe", &"schutzengel", &"das-orakel", &"schattenhund", &"giftwolf", &"voodoo-priester", &"hades", &"nekromant", &"feuerteufel", &"parasit", &"kutscher"]:
		assert_true(RoleCatalog.stealable(role), "stehlbar: %s" % role)
	for role: StringName in [&"dorfbewohner", &"werwolf", &"loki", &"dorfchronistin", &"todesprediger", &"prophet-des-untergangs", &"schutzgeist", &"wolfskind", &"lehrling", &"grabraeuber", &"die-gebundenen", &"die-ewigen", &"sensentraeger"]:
		assert_false(RoleCatalog.stealable(role), "nicht stehlbar: %s" % role)


func test_steal_offers_only_dead_with_stealable_ability_and_rejects_invalid() -> void:
	# 3 Waldhexe (tot), 4 Dorfbewohner (tot), 5 Loki (tot), 6 lebende Seherin; 2 ist der Grabräuber.
	var s := _at_robber_prompt([W, GR, WH, D, "loki", "das-orakel", D, D], [3, 4, 5])
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [3] as Array[int], "nur die tote Waldhexe")
	assert_eq([p.min_count, p.max_count], [0, 1], "eine oder keine")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [4]), "invalid_target", "Toter ohne Nachtschritt")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [6]), "invalid_target", "Lebende")
	_rejected_clean(s, Command.answer_stage_targets(p.id, "targets", [3, 5]), "invalid_target", "zwei")
	_codec_same(s, "offener Prompt")
	# Keine stehlbare tote Person: kein Schritt.
	var log: Array[GameEvent] = []
	_dawn(_state([W, GR, WH, D, D, D, D, D], [4]), {}, log)
	assert_eq(_opened(log, "grabraeuber:2").size(), 0, "ohne passende Tote kein Schritt")


func test_steal_witch_fresh_potions_from_next_night_stays_grave_robber() -> void:
	var s := _state([W, GR, WH, D, D, D, D, D], [3])
	var log: Array[GameEvent] = []
	s = _night(s, {"grabraeuber:2@targets": [3]}, log)
	if s == null:
		return
	assert_eq(String(s.players[2].role_id), GR, "bleibt Grabräuber")
	assert_eq(SoloRules.stolen_role(s, 2), &"waldhexe", "Fähigkeit übernommen")
	var notices := events_of_type(log, "GraveRobberNotice")
	assert_true(notices.size() == 1 and notices[0].visibility == Visibility.ACTOR and notices[0].actor_id == 2 and String(notices[0].data["role_id"]) == WH, "private Mitteilung der Fähigkeit")
	var robbed := events_of_type(log, "GraveRobbed")
	assert_true(robbed.size() == 1 and robbed[0].visibility == Visibility.GM, "Diebstahl nur für den Spielleiter")
	assert_eq(_opened(log, "waldhexe:2").size(), 0, "in derselben Nacht noch kein Hexenschritt")
	_codec_same(s, "nach Diebstahl")
	s = _ok(s, Command.end_night(), "Morgen")
	# Nächste Nacht: eigener Hexenschritt; der Grabräuber-Schritt ist verbraucht.
	log = []
	s = _night(s, {"pack@": [5]}, log)
	assert_eq(_opened(log, "grabraeuber:2").size(), 0, "nur einmal stehlen")
	assert_eq(_opened(log, "waldhexe:2").size(), 1, "Hexenschritt des Grabräubers")


func test_stolen_witch_heals_pack_victim() -> void:
	# Die Tote hatte ihren Heiltrank schon verbraucht; der Grabräuber beginnt frisch (E-34).
	var s := _state([W, GR, WH, D, D, D, D, D], [3])
	s.players[3].ability_uses["waldhexe:heal"] = 1
	s = _dawn(s, {"grabraeuber:2@targets": [3]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [5], "waldhexe:2@heal": true, "waldhexe:2@poison": false, "waldhexe:2@confirm": true}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [], "Heiltrank des Grabräubers rettet 5")
	assert_true(s.players[2].ability_uses.has("waldhexe:heal"), "eigener Einsatz verbraucht")


# --- Wirkungen übernommener Fähigkeiten ------------------------------------------------------------

func test_stolen_voodoo_doll_protects_robber_and_survives_load() -> void:
	var s := _state([W, GR, VP, D, D, D, D, D], [3])
	s = _dawn(s, {"grabraeuber:2@targets": [3]})
	s = _dawn(s, {"voodoo-priester:2@": [5]})
	if s == null:
		return
	assert_eq(s.voodoo_dolls, [{"priest_id": 2, "doll_id": 5}], "Puppe des Grabräubers")
	_codec_same(s, "Puppe")
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2]}, log)
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"]], "Puppe stirbt statt des Grabräubers")
	# Der Voodoo-Sieg wird nicht übernommen, nur die Puppe.
	if s == null:
		return
	for id: int in [4, 6, 7]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Tote")
	if s == null:
		return
	assert_false(SoloRules.voodoo_wins(s, 2), "kein Voodoo-Sieg für den Grabräuber")
	assert_true(WinRules.grave_robber_wins(s, 2), "eigener Sieg bei drei Lebenden")


func test_stolen_hades_collects_lights_and_kills_without_hades_win() -> void:
	var s := _state([W, GR, "hades", D, D, D, D, D, D, D], [3])
	s = _dawn(s, {"grabraeuber:2@targets": [3], "pack@": [4]})
	if s == null:
		return
	assert_eq(int(s.hades_lights.get(2, 0)), 1, "Lichter ab dem Diebstahl")
	s.hades_lights[2] = 10
	_codec_same(s, "Lichter des Grabräubers")
	assert_false(WinRules.evaluate(s).any(func(r: Dictionary) -> bool: return String(r["reason_key"]) == String(WinCandidate.REASON_HADES)), "kein Hades-Sieg")
	var log: Array[GameEvent] = []
	s = _dawn(s, {"hades:2@targets": [5], "hades:2@barrier": true}, log)
	assert_eq(_deaths(log), [[5, "HADES_KILL"]], "Tötung mit übernommener Fähigkeit")
	assert_eq(s.hades_barriers if s != null else [], [2] as Array[int], "Barriere des Grabräubers")
	log = []
	s = _ok(s, Command.nominate(6, 2), "Nominierung") if s != null else null
	var r := apply_ok(s, Command.decide_execution(2), "Hinrichtung") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [0], [], "Barriere rettet den Grabräuber")


func test_stolen_wolf_ability_blocks_village_but_robber_is_no_wolf() -> void:
	# Schattenhund gestohlen: Blockade aller Dorf-Nachtschritte; der Grabräuber zählt nicht als Wolf.
	var s := _state([W, GR, "schattenhund", "das-orakel", D, D, D, D], [3])
	s = _dawn(s, {"grabraeuber:2@targets": [3]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"schattenhund:2@use": true}, log)
	if s == null:
		return
	assert_false(s.players[2].counts_as_wolf, "kein Wolf")
	var dropped := events_of_type(log, "StepDropped").filter(func(e: GameEvent) -> bool: return String(e.data["step_id"]).ends_with("das-orakel:4"))
	assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "blocked", "Orakel blockiert")
	assert_true(s.players[2].ability_uses.has("schattenhund:block"), "einmal je Leben verbraucht")
	assert_false(s.night_wolf_ids.has(2), "nicht im Rudel")


func test_robber_with_village_ability_not_blocked_by_nightmare_wolf() -> void:
	var s := _state([W, GR, "schutzengel", "albtraumwolf", D, D, D, D], [3])
	s = _dawn(s, {"grabraeuber:2@targets": [3]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"albtraumwolf:4@": [2], "schutzengel:2@": [5], "pack@": [5]}, log)
	assert_eq(_deaths(log), [], "Einzelsiegperson ist nicht blockierbar; Schutz wirkt")


func test_stolen_fire_devil_mark_spares_robber() -> void:
	# Sitze 1–8: 2 Grabräuber mit Feuerfähigkeit markiert 3; stirbt 3, brennt 4, der Grabräuber 2 bleibt verschont.
	var s := _state([W, GR, D, D, "feuerteufel", D, D, D], [5])
	s = _dawn(s, {"grabraeuber:2@targets": [5]})
	s = _dawn(s, {"feuerteufel:2@": [3]})
	if s == null:
		return
	var r := apply_ok(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), "Ziel stirbt")
	assert_eq(_deaths(r.events), [[3, "GM_CORRECTION"], [4, "BURN"]], "4 brennt, der Grabräuber 2 nicht")


# --- Sieg, Kopien, Rollenverlust ------------------------------------------------------------------

func test_win_alone_alive_with_at_most_three_living() -> void:
	var s := _dawn(_state([W, GR, D, D, D, D], [4, 5]))
	if s == null:
		return
	s = _ok(s, Command.nominate(3, 6), "Nominierung")
	s = _ok(s, Command.decide_execution(6), "Hinrichtung")
	if s == null:
		return
	var robber := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_GRAVE_ROBBER)
	assert_true(robber.size() == 1 and (robber[0] as WinCandidate).beneficiary_ids == ([2] as Array[int]), "Alleinsieg bei drei Lebenden")
	_codec_same(s, "Sieg offen")
	assert_false(WinRules.grave_robber_wins(_state([W, GR, D, D, D, D], [2, 4, 5, 6]), 2), "tot kein Sieg")


func test_two_robbers_steal_same_role_independently() -> void:
	var s := _state([W, GR, GR, WH, D, D, D, D], [4])
	s = _dawn(s, {"grabraeuber:2@targets": [4], "grabraeuber:3@targets": [4]})
	if s == null:
		return
	assert_eq([SoloRules.stolen_role(s, 2), SoloRules.stolen_role(s, 3)], [&"waldhexe", &"waldhexe"], "beide")
	var log: Array[GameEvent] = []
	s = _night(s, {}, log)
	assert_eq(_opened(log, "waldhexe:2").size() + _opened(log, "waldhexe:3").size(), 2, "zwei eigene Hexenschritte")


func test_role_loss_or_death_ends_ability_revival_allows_new_theft() -> void:
	# Seelentausch (80) nach dem Diebstahl (64) in derselben Nacht: 2 wird Dorfbewohner, 4 wird Grabräuber ohne Fähigkeit.
	var s := _state([W, GR, WH, D, "seelentauscher", D, D, D], [3])
	s = _dawn(s, {"grabraeuber:2@targets": [3], "seelentauscher:5@targets": [2, 4]})
	if s == null:
		return
	assert_eq([String(s.players[2].role_id), String(s.players[4].role_id)], [D, GR], "getauscht")
	assert_eq([SoloRules.stolen_role(s, 2), SoloRules.stolen_role(s, 4)], [&"", &""], "Fähigkeit erloschen, keine Übernahme")
	var log: Array[GameEvent] = []
	s = _night(s, {"grabraeuber:4@targets": []}, log)
	assert_eq(_opened(log, "grabraeuber:4").size(), 1, "der neue Grabräuber darf stehlen")
	# Tod und Wiederbelebung.
	s = _dawn(_state([W, GR, WH, D, D, D, D, D], [3]), {"grabraeuber:2@targets": [3]})
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Grabräuber stirbt")
	assert_eq(SoloRules.stolen_role(s, 2) if s != null else &"x", &"", "Fähigkeit erlischt mit dem Tod")
	s = _ok(s, _gm("revive", {"target_id": 2}), "Wiederbelebung")
	log = []
	s = _night(s, {"grabraeuber:2@targets": [3]}, log)
	assert_eq(_opened(log, "grabraeuber:2").size(), 1, "frisch: erneut stehlen")
	assert_eq(SoloRules.stolen_role(s, 2) if s != null else &"", &"waldhexe", "neu gestohlen")


func test_replay_identical() -> void:
	var commands: Array[Command] = [Fixtures.start_roles([W, GR, VP, D, D, D, D, D], 7), _gm("kill", {"target_id": 3, "trigger_effects": false})]
	var s := RulesEngine.replay(commands).state
	# Befehle mitschreiben: Nacht mit Diebstahl, Nacht mit Puppe.
	var recorder := []
	s = _record_dawn(s, {"grabraeuber:2@targets": [3]}, recorder)
	s = _record_dawn(s, {"voodoo-priester:2@": [5], "pack@": [2]}, recorder)
	for c: Command in recorder:
		commands.append(c)
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok and b.ok, "Replay angenommen")
	if a.ok and b.ok:
		assert_eq(CanonicalJson.stringify(a.state.to_dict()), CanonicalJson.stringify(s.to_dict()), "Replay-Zustand wie gespielt")
		assert_eq(events_json(a.events), events_json(b.events), "identische Ereignisse")


func _record_dawn(s: GameState, answers: Dictionary, recorder: Array) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		for c: Command in [Command.decide_execution(-1), Command.end_day()]:
			recorder.append(c)
			s = _ok(s, c, "Tag")
	var start := Command.start_night()
	recorder.append(start)
	s = _ok(s, start, "Nacht")
	for guard: int in 40:
		if s == null:
			return null
		var cmd: Command = null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var staged := "%s@%s" % [p.step_id.get_slice(":", 3) + ":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else p.step_id.get_slice(":", 3), p.stage]
			if answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.answer_prompt(p.id, [])
			else:
				cmd = _auto(s)
		else:
			var step := RulesEngine.next_step_id(s)
			cmd = Command.end_night() if step == "" else Command.begin_step(step)
		recorder.append(cmd)
		s = _ok(s, cmd, "Befehl")
		if s != null and s.phase != Phase.NIGHT:
			return s
	return s


func test_load_rejects_inconsistent_state() -> void:
	var s := _dawn(_state([W, GR, WH, D, D, D, D, D], [3]), {"grabraeuber:2@targets": [3]})
	if s == null:
		return
	_codec_same(s, "Diebstahl")
	var bad_cases := [
		["grave_thefts", [{"robber_id": 4, "target_id": 3, "role_id": "waldhexe"}]],
		["grave_thefts", [{"robber_id": 2, "target_id": 3, "role_id": "dorfbewohner"}]],
		["grave_thefts", [{"robber_id": 2, "target_id": 99, "role_id": "waldhexe"}]],
		["grave_thefts", [{"robber_id": 2, "target_id": 3, "role_id": "waldhexe"}, {"robber_id": 2, "target_id": 3, "role_id": "waldhexe"}]],
	]
	for bad: Array in bad_cases:
		var d := s.to_dict()
		d[bad[0]] = bad[1]
		assert_true(GameState.from_dict(d) == null, "abgelehnt: %s" % str(bad))


func test_stolen_necromancer_shield_survives_load_and_protects() -> void:
	var s := _state([W, GR, "nekromant", D, D, D, D, D, D, D], [3, 8, 9, 10])
	s = _dawn(s, {"grabraeuber:2@targets": [3]})
	var log: Array[GameEvent] = []
	s = _night(s, {"nekromant:2@targets": [8, 9, 10], "pack@": [5]}, log)
	if s == null:
		return
	assert_eq(s.necro_shields, [{"necro_id": 2, "night": 2}], "Schild des Grabräubers")
	_codec_same(s, "Schild vor dem Morgen")
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_deaths(r.events), [], "Schild rettet das Rudelopfer")
	# Das Benennen am Tag ist keine Nachtfähigkeit und wird nicht übernommen.
	_rejected_clean(r.state, Command.name_wolf(2, 1), "not_necromancer", "Benennen")


func test_stolen_parasite_host_makes_robber_immune() -> void:
	var s := _state([W, GR, "parasit", D, D, D, D, D], [3])
	s = _dawn(s, {"grabraeuber:2@targets": [3]})
	s = _dawn(s, {"parasit:2@": [5]})
	if s == null:
		return
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2]}, log)
	assert_eq(_deaths(log), [], "mit lebendem Wirt unverwundbar")
	var r := apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Wirt stirbt") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[5, "GM_CORRECTION"], [2, "PARASITE_HOST"]], "stirbt mit dem Wirt")
