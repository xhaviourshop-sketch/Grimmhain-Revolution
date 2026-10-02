extends TestCase
## Produktionsrolle `lehrling` (Apprentice), rules-register.md §9, DR-11.
## LS: 1 Werwolf; 2, 3 Dorfbewohner; 4 Sensenträger; 5 wechselnde Rolle (Standard Dorfbewohner); 6 Lehrling.
##     Nacht 1: Prompt 1 Lehrling (StartNight), danach Rudel.
## Kandidaten [1, 2, 4] ergeben die Optionen dorfbewohner (2), sensentraeger (4), werwolf (1).
## Neue Felder werden über die Serialisierung (`apprentices`) gelesen; der Prompt über `partial`.

const STEP_L := "night:1:0:lehrling:6"


func _start(roles: Array, appearances: Dictionary = {}, seed_value: int = 1) -> Command:
	var payload := Fixtures.start_roles(roles, seed_value).payload.duplicate(true)
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


## 1 Werwolf, 2 Dorfbewohner, 3 Füller, 4 Sensenträger, 5 `role5`, 6 Lehrling (PE-07: keine Rolle doppelt; bei `role5` gleich
## einem Füller rückt der Füller nach). Gleiche Rollen unter den Kandidaten gibt es erst nach einer Korrektur (`_equal_start`).
func _ls(role5: String = "amalia", seed_value: int = 1) -> Command:
	var appearances := {"5": "waldhexe"} if role5 == "trugbilderwolf" else {}
	var filler: String = Fixtures.village_fillers(1, ["dorfbewohner", "sensentraeger", role5])[0]
	return _start(["werwolf", "dorfbewohner", filler, "sensentraeger", role5, "lehrling"], appearances, seed_value)


## Wie `_ls`, aber 2, 3 und 5 sind Dorfbewohner: 3 und 5 werden nach dem Start durch Korrektur zu Dorfbewohnern (AS-L03).
func _equal_start(rest: Array[Command]) -> Array[Command]:
	return Fixtures.with_copies(["werwolf", "dorfbewohner", "dorfbewohner", "sensentraeger", "dorfbewohner", "lehrling"], rest, 1)


func _cands(prompt_id: int, ids: Array) -> Command:
	return Command.create(Command.ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": "candidates", "targets": ids})


func _opt(prompt_id: int, index: int) -> Command:
	return Command.create(Command.ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": "option", "option": index})


func _conf(prompt_id: int) -> Command:
	return Command.create(Command.ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": "confirm", "choice": true})


func _gm(kind: String, fields: Dictionary, reason: String = "Korrektur am Tisch") -> Command:
	return CorrectionFixtures.gm(kind, fields, reason)


func _kill(id: int, effects: bool = true) -> Command:
	return _gm("kill", {"target_id": id, "trigger_effects": effects})


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


## Wendet `c` an, protokolliert ihn in `log` und liefert den neuen Zustand (null bei Ablehnung).
func _step(s: GameState, c: Command, log: Array[Command], label: String = "") -> GameState:
	if s == null:
		fail("%s: kein Zustand" % label)
		return null
	var r := RulesEngine.apply(s, c)
	assert_true(r.ok, "%s: %s angenommen (%s)" % [label, c.type, r.error])
	if not r.ok:
		return null
	log.append(c)
	return r.state


func _steps(s: GameState, cmds: Array[Command], log: Array[Command], label: String = "") -> GameState:
	for c: Command in cmds:
		s = _step(s, c, log, label)
		if s == null:
			return null
	return s


## Antwort auf den offenen Prompt. `picks` = {Lehrling-ID: {"cands": [...], "master": id}}.
func _answer_for(s: GameState, p: PendingPrompt, picks: Dictionary) -> Command:
	var stage := str(p.to_dict().get("stage", ""))
	match String(p.owner):
		"pack", "reaction":
			return Command.answer_prompt(p.id, [])
		"schutzengel", "wolfskind":
			return Command.answer_prompt(p.id, [p.allowed_ids[0]])
		"waldhexe":
			return Command.answer_choice(p.id, stage, stage == "confirm")
		"das-orakel":
			return Command.answer_stage_targets(p.id, "target", [p.allowed_ids[0]]) if stage == "target" else Command.answer_choice(p.id, "shown", true)
		"lehrling":
			var pick: Dictionary = picks.get(p.actor_id, {})
			if stage == "candidates":
				return _cands(p.id, pick.get("cands", p.allowed_ids.slice(0, 3)))
			if stage == "option":
				var mapping: Array = p.partial.get("option_person_ids", [])
				var index := mapping.find(int(pick.get("master", -1)))
				return _opt(p.id, index if index >= 0 else 0)
			return _conf(p.id)
	return Command.end_night()


## Führt die laufende Nacht (und fällige Reaktionen am Morgen) zu Ende.
func _drive_night(s: GameState, log: Array[Command], picks: Dictionary = {}) -> GameState:
	var guard := 0
	while s != null and (s.phase == Phase.NIGHT or StepQueue.reactions_due(s)) and guard < 60:
		guard += 1
		var c: Command
		if s.pending_prompt != null:
			c = _answer_for(s, s.pending_prompt, picks)
		else:
			var next := RulesEngine.next_step_id(s)
			c = Command.end_night() if next == "" else Command.begin_step(next)
		s = _step(s, c, log, "Nacht")
	return s


## Tag ohne Hinrichtung beenden und die nächste Nacht beginnen.
func _next_night(s: GameState, log: Array[Command]) -> GameState:
	return _steps(s, [Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command], log, "nächste Nacht")


## Spielaufbau, Nacht 1 und Lehrling 6 an `master` gebunden (aus den Kandidaten `cands`).
## Danach ist der Rest der Nacht offen.
func _bound(master: int, cands: Array = [1, 2, 4], start: Command = null, log: Array[Command] = []) -> GameState:
	var s := _steps(GameState.new(), [start if start != null else _ls(), Command.start_night()] as Array[Command], log, "Aufbau")
	var guard := 0
	while s != null and guard < 20:
		guard += 1
		var p := s.pending_prompt
		if p == null:
			var next := RulesEngine.next_step_id(s)
			if next == "" or not next.contains("lehrling:6") and _bond(s, 6).size() > 0:
				break
			s = _step(s, Command.begin_step(next), log, "Schritt")
			continue
		if p.owner == &"lehrling" and p.actor_id == 6:
			s = _step(s, _answer_for(s, p, {6: {"cands": cands, "master": master}}), log, "Lehrling")
			if not _bond(s, 6).is_empty():
				break
		else:
			s = _step(s, _answer_for(s, p, {}), log, "anderer Schritt")
	return s


func _records(s: GameState) -> Array:
	return s.to_dict().get("apprentices", []) if s != null else []


## Aktuellste Bindung des Lehrlings `id` (Dictionary, leer wenn keine).
func _bond(s: GameState, id: int) -> Dictionary:
	var found := {}
	for r: Variant in _records(s):
		if int((r as Dictionary).get("apprentice_id", -1)) == id:
			found = r
	return found


func _stage(s: GameState) -> String:
	return str(s.pending_prompt.to_dict().get("stage", "")) if s != null and s.pending_prompt != null else ""


func _player(s: GameState, id: int) -> Dictionary:
	for p: Variant in s.to_dict()["players"]:
		if int((p as Dictionary)["id"]) == id:
			return p
	return {}


# --- 1–10 Auswahl -----------------------------------------------------------------------------------

func test_selection_flow() -> void:
	# 1, AS-L01, AS-L02, AS-L04
	var log: Array[Command] = []
	var s := _steps(GameState.new(), [_ls(), Command.start_night()] as Array[Command], log)
	if s == null:
		return
	assert_eq(s.night_plan, [&"lehrling:6", &"pack"] as Array[StringName], "Lehrlingsschritt vor dem Rudel")
	assert_eq(_stage(s), "candidates", "Spielleiterteil")
	assert_true(s.pending_prompt.actor_id == 6 and s.pending_prompt.allowed_ids == ([1, 2, 3, 4, 5] as Array[int])
		and s.pending_prompt.min_count == 3 and s.pending_prompt.max_count == 3 and s.pending_prompt.cancellable, "drei andere Lebende")
	var draws := s.rng.draws
	var o := _step(s, _cands(1, [1, 2, 4]), log)
	assert_eq(_stage(o), "option", "Lehrlingsteil")
	assert_eq(o.pending_prompt.partial.get("options"), ["dorfbewohner", "sensentraeger", "werwolf"], "nach Rollen-ID sortiert")
	assert_eq(o.pending_prompt.partial.get("option_person_ids"), [2, 4, 1], "interne Zuordnung")
	assert_eq(o.rng.draws, draws, "keine Ziehung ohne gleiche Rollen")
	assert_true(_records(o).is_empty(), "noch keine Bindung")
	var c := _step(o, _opt(1, 1), log)
	assert_eq(_stage(c), "confirm", "Bestätigung")
	var r := RulesEngine.apply(c, _conf(1))
	assert_true(r.ok, "Bestätigung angenommen (%s)" % r.error)
	if not r.ok:
		return
	var b := _bond(r.state, 6)
	assert_true(int(b.get("master_id", -1)) == 4 and str(b.get("status", "")) == "bound" and int(b.get("chosen_index", -1)) == 1
		and b.get("options") == ["dorfbewohner", "sensentraeger", "werwolf"] and b.get("option_person_ids") == [2, 4, 1], "geheime Bindung gespeichert")
	var bound := events_of_type(r.events, "ApprenticeBound")
	assert_true(bound.size() == 1 and String(bound[0].visibility) == "gm" and int(bound[0].data["master_id"]) == 4, "ApprenticeBound nur Spielleiter")
	assert_eq(String(r.state.players[6].role_id), "lehrling", "Rolle bleibt lehrling")
	assert_eq(String(r.state.night_step_status[0]), "done", "Schritt erledigt")
	assert_eq(RulesEngine.next_step_id(r.state), "night:1:1:pack", "danach das Rudel")


func test_apprentice_sees_only_roles() -> void:
	# 2, 3, AS-L02
	var log: Array[Command] = []
	var s := _bound(4, [1, 2, 4], null, log)
	if s == null:
		return
	s = _drive_night(s, log)
	var events := RulesEngine.replay(log).events
	var shown := events_of_type(events, "ApprenticeOptionsShown")
	assert_true(shown.size() == 1 and String(shown[0].visibility) == "actor" and shown[0].actor_id == 6
		and shown[0].data == {"options": ["dorfbewohner", "sensentraeger", "werwolf"]}, "nur Rollenoptionen")
	var chosen := events_of_type(events, "ApprenticeChoiceConfirmed")
	assert_true(chosen.size() == 1 and chosen[0].actor_id == 6
		and chosen[0].data == {"options": ["dorfbewohner", "sensentraeger", "werwolf"], "chosen_role": "sensentraeger"}, "nur Optionen und gewählte Rolle")
	for e: GameEvent in events:
		if e.visibility == &"actor" and e.actor_id == 6 and e.type != &"RoleAssigned":
			assert_false(_has_int(e.data), "%s an den Lehrling ohne IDs" % e.type)
			var text := _json(e.data)
			for name: String in ["\"A\"", "\"B\"", "\"D\"", "seat", "name", "portrait"]:
				assert_false(text.contains(name), "%s ohne Identitätsmerkmal %s" % [e.type, name])
		if e.visibility == &"public":
			var text := _json(e.data).to_lower()
			assert_false(text.contains("lehrling") or text.contains("apprentice") or text.contains("master") or text.contains("option"), "öffentliches %s ohne Lehrling" % e.type)


func _has_int(value: Variant) -> bool:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			if _has_int(value[k]):
				return true
	elif value is Array:
		for v: Variant in (value as Array):
			if _has_int(v):
				return true
	elif DictRead.is_int_like(value) and not value is bool:
		return true
	return false


func test_invalid_candidates_rejected() -> void:
	# 4, 5
	var s := Fixtures.play([_ls(), Command.start_night()] as Array[Command])
	if s == null:
		fail("Aufbau")
		return
	apply_rejected(s, _cands(1, [6, 1, 2]), "invalid_target", "Selbstwahl")
	apply_rejected(s, _cands(1, [1, 1, 2]), "invalid_target", "doppelt")
	apply_rejected(s, _cands(1, [1, 2, 99]), "invalid_target", "unbekannt")
	apply_rejected(s, _cands(1, [1, 2]), "invalid_target_count", "zu wenige")
	apply_rejected(s, _cands(1, [1, 2, 3, 5]), "invalid_target_count", "zu viele")
	apply_rejected(s, Command.answer_prompt(1, [1, 2, 3]), "stage_mismatch", "ohne Stufe")
	apply_rejected(s, _opt(1, 0), "stage_mismatch", "Option vor Kandidaten")
	var dead := Fixtures.play([_ls(), Command.start_night(), _kill(5, false), Command.begin_step(STEP_L)] as Array[Command])
	assert_true(dead != null and not dead.pending_prompt.allowed_ids.has(5), "Tote nicht angeboten")
	if dead != null:
		apply_rejected(dead, _cands(2, [1, 2, 5]), "invalid_target", "tote Person")
	var o := apply_ok(s, _cands(1, [1, 2, 4]), "Kandidaten").state
	apply_rejected(o, _opt(1, 3), "invalid_answer", "Option außerhalb")
	apply_rejected(o, _opt(1, -1), "invalid_answer", "negative Option")
	apply_rejected(o, Command.create(Command.ANSWER_PROMPT, {"prompt_id": 1, "stage": "option", "targets": [4]}), "invalid_answer", "Personen-ID statt Option")


func test_duplicate_roles_separately_bound() -> void:
	# 6, 7, AS-L03
	var s := Fixtures.play(_equal_start([Command.start_night()] as Array[Command]))
	if s == null:
		fail("Aufbau")
		return
	var draws := s.rng.draws
	var o := apply_ok(s, _cands(1, [2, 3, 5]), "drei Dorfbewohner").state
	assert_eq(o.pending_prompt.partial.get("options"), ["dorfbewohner", "dorfbewohner", "dorfbewohner"], "gleiche Rollen")
	var mapping: Array = o.pending_prompt.partial.get("option_person_ids", [])
	var sorted := mapping.duplicate()
	sorted.sort()
	assert_eq(sorted, [2, 3, 5], "jede Option an eine andere Person")
	assert_eq(o.rng.draws, draws, "Ziehung noch nicht verbraucht")
	var done := apply_ok(apply_ok(o, _opt(1, 1), "Option 1").state, _conf(1), "Bestätigung").state
	assert_eq(done.rng.draws, draws + 2, "zwei Ziehungen erst mit der Bestätigung")
	assert_eq(int(_bond(done, 6).get("master_id", -1)), int(mapping[1]), "gewählte Option gehört zu ihrer Person")
	var again := Fixtures.play(_equal_start([Command.start_night(), _cands(1, [2, 3, 5])] as Array[Command]))
	assert_eq(again.pending_prompt.partial.get("option_person_ids"), mapping, "gleicher Seed, gleiche Zuordnung")
	var loaded := StateCodec.decode(StateCodec.encode(o, _equal_start([Command.start_night(), _cands(1, [2, 3, 5])] as Array[Command])))
	assert_true(loaded.ok and loaded.state.pending_prompt.partial.get("option_person_ids") == mapping, "Save/Load behält die Zuordnung")


func test_cancel_restores_everything() -> void:
	# 8
	var s := Fixtures.play([_ls(), Command.start_night()] as Array[Command])
	if s == null:
		fail("Aufbau")
		return
	var base := apply_ok(s, Command.cancel_prompt(1, "zu früh"), "Abbruch vor Antwort").state
	var paths := {
		"nach Kandidaten": [_cands(1, [2, 3, 5])] as Array[Command],
		"nach Option": [_cands(1, [2, 3, 5]), _opt(1, 2)] as Array[Command],
	}
	for label: String in paths:
		var t := s
		for c: Command in paths[label]:
			t = apply_ok(t, c, label).state
		var c2 := apply_ok(t, Command.cancel_prompt(1, "falsch"), "%s: Abbruch" % label).state
		assert_eq(c2.content_hash(), base.content_hash(), "%s: Hash wie vor BeginStep" % label)
		assert_eq(_json(c2.rng.to_dict()), _json(base.rng.to_dict()), "%s: RNG unverändert" % label)
		assert_true(_records(c2).is_empty(), "%s: keine Bindung" % label)
		assert_eq(RulesEngine.next_step_id(c2), STEP_L, "%s: derselbe Schritt" % label)


func test_not_skippable() -> void:
	# 9
	var s := Fixtures.play([_ls(), Command.start_night()] as Array[Command])
	if s == null:
		fail("Aufbau")
		return
	apply_rejected(s, Command.skip_step(STEP_L, "keine Lust"), "step_not_skippable", "offen")
	var c := apply_ok(s, Command.cancel_prompt(1, "später"), "Abbruch").state
	apply_rejected(c, Command.skip_step(STEP_L, "keine Lust"), "step_not_skippable", "vor Beginn")


func test_multiple_apprentices_in_order() -> void:
	# 10
	var log: Array[Command] = []
	var s := _steps(GameState.new(), Fixtures.with_copies(["werwolf", "dorfbewohner", "amalia", "detektiv", "lehrling", "lehrling"], [Command.start_night()] as Array[Command]) as Array[Command], log)
	if s == null:
		return
	assert_eq(s.night_plan, [&"lehrling:5", &"lehrling:6", &"pack"] as Array[StringName], "nach Personen-ID")
	assert_eq(s.pending_prompt.actor_id, 5, "erster Lehrling zuerst")
	s = _drive_night(s, log)
	assert_true(str(_bond(s, 5).get("status", "")) == "bound" and str(_bond(s, 6).get("status", "")) == "bound", "beide gebunden")


func test_binding_persists_over_nights() -> void:
	# 11, 30
	var log: Array[Command] = []
	var s := _drive_night(_bound(4, [1, 2, 4], null, log), log)
	s = _next_night(s, log)
	if s == null:
		return
	assert_false(s.night_plan.has(&"lehrling:6"), "keine erneute Auswahl")
	assert_eq(str(_bond(s, 6)["status"]), "bound", "Bindung besteht")
	var loaded := StateCodec.decode(StateCodec.encode(s, log))
	assert_true(loaded.ok and loaded.state.content_hash() == s.content_hash(), "30: Save/Load mit aktiver Bindung")


# --- 12–17 Tod und Erbe ------------------------------------------------------------------------------

func test_inherits_current_role_at_death() -> void:
	# 12, 13, 14, AS-L05
	var log: Array[Command] = []
	var s := _bound(4, [1, 2, 4], null, log)
	s = _step(s, _gm("set_role", {"target_id": 4, "role_id": "waldhexe"}, "Rolle am Tisch getauscht"), log)
	s = _steps(s, [Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, [4])] as Array[Command], log)
	if s == null:
		return
	var r := RulesEngine.apply(s, Command.end_night())
	assert_true(r.ok, "Morgen")
	if not r.ok:
		return
	var p := r.state.players[6]
	assert_true(p.role_id == &"waldhexe" and p.original_role_id == &"lehrling" and p.faction == &"village", "erbt die Rolle zum Todeszeitpunkt")
	var changed := events_of_type(r.events, "RoleChanged")
	assert_true(changed.size() == 1 and String(changed[0].visibility) == "gm" and int(changed[0].data["player_id"]) == 6
		and str(changed[0].data["from"]) == "lehrling" and str(changed[0].data["to"]) == "waldhexe" and str(changed[0].data["by"]) == "master_death", "genau ein Erbe")
	assert_eq(str(_bond(r.state, 6)["status"]), "inherited", "Bindung verbraucht")
	var again := RulesEngine.replay(_concat(_concat(log, [Command.end_night()] as Array[Command]), [_gm("revive", {"target_id": 4}), _kill(4)] as Array[Command]))
	assert_true(again.ok, "Wiederbelebung und erneuter Tod")
	if again.ok:
		assert_eq(events_of_type(again.events, "RoleChanged").size(), 1, "14: kein zweites Erbe")
		assert_eq(String(again.state.players[6].role_id), "waldhexe", "Rolle bleibt")


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


func test_apprentice_dies_first() -> void:
	# 15, F, AS-L06
	var log: Array[Command] = []
	var s := _bound(2, [1, 2, 4], null, log)
	s = _steps(s, [_kill(6), _kill(2)] as Array[Command], log)
	if s == null:
		return
	assert_eq(str(_bond(s, 6)["status"]), "expired", "Bindung verfallen")
	assert_eq(String(s.players[6].role_id), "lehrling", "kein Erbe")
	s = _step(s, _gm("revive", {"target_id": 6}), log)
	assert_eq(str(_bond(s, 6)["status"]), "expired", "Wiederbelebung reaktiviert nichts")
	s = _next_night(_drive_night(s, log), log)
	if s != null:
		assert_true(s.night_plan.has(&"lehrling:6"), "ungebundener Lehrling wählt neu")


func test_inherited_reaction_applies_immediately() -> void:
	# 16, 22, AS-L16
	var log: Array[Command] = []
	var s := _drive_night(_bound(4, [1, 2, 4], null, log), log)
	s = _steps(s, [Command.nominate(2, 4), Command.decide_execution(4)] as Array[Command], log)
	if s == null:
		return
	assert_eq(String(s.players[6].role_id), "sensentraeger", "erbt Sensenträger")
	assert_eq(RulesEngine.next_step_id(s), "reaction:1", "Reaktion des Meisters")
	s = _steps(s, [Command.begin_step("reaction:1"), Command.answer_prompt(3, [6])] as Array[Command], log)
	if s == null:
		return
	assert_false(s.players[6].alive, "Lehrling stirbt")
	assert_eq(s.reactions.size(), 1, "eigene Reaktion eingereiht")
	if s.reactions.size() == 1:
		assert_eq(s.reactions[0].owner_id, 6, "Reaktion des Lehrlings")


func test_two_apprentices_same_master() -> void:
	# 17
	var log: Array[Command] = []
	var s := _steps(GameState.new(), Fixtures.with_copies(["werwolf", "dorfbewohner", "amalia", "sensentraeger", "lehrling", "lehrling"], [Command.start_night()] as Array[Command]) as Array[Command], log)
	s = _drive_night(s, log, {5: {"cands": [1, 2, 4], "master": 4}, 6: {"cands": [1, 2, 4], "master": 4}})
	if s == null:
		return
	var r := RulesEngine.apply(s, _kill(4))
	var changed := events_of_type(r.events, "RoleChanged")
	assert_true(changed.size() == 2 and int(changed[0].data["player_id"]) == 5 and int(changed[1].data["player_id"]) == 6, "stabil nach Personen-ID")


# --- 18–28 geerbte Rollen ----------------------------------------------------------------------------

func _inherit(role5: String, extra_before_kill: Array[Command] = [], log: Array[Command] = []) -> GameState:
	var s := _bound(5, [1, 4, 5], _ls(role5), log)
	s = _steps(s, extra_before_kill, log, role5)
	return _step(s, _kill(5), log, "Meister stirbt")


func test_inherit_villager_and_werewolf() -> void:
	# 18, 27, AS-L09
	var v := _bound(2, [1, 2, 4])
	var vr := RulesEngine.apply(v, _kill(2))
	assert_true(vr.ok and vr.state.players[6].role_id == &"dorfbewohner", "Dorfbewohner geerbt")
	var w := _bound(1, [1, 2, 4])
	var wr := RulesEngine.apply(w, _kill(1))
	if not wr.ok:
		fail("Werwolf-Erbe")
		return
	var p := wr.state.players[6]
	assert_true(p.role_id == &"werwolf" and p.faction == &"wolves" and p.counts_as_wolf, "zählt sofort als Wolf")
	var prov := events_of_type(wr.events, "WinStatusProvisional")
	assert_true(prov.size() == 1 and (prov[0].data["results"] as Array).is_empty(), "vorläufige Prüfung rechnet mit dem Lehrling als Wolf")
	assert_true(wr.state.open_candidates().is_empty(), "kein Dorfsieg nach dem Tod des einzigen ursprünglichen Wolfs")
	var types: Array[String] = []
	for e: GameEvent in wr.events:
		if ["SeatDied", "RoleChanged", "WinStatusProvisional"].has(String(e.type)):
			types.append(String(e.type))
	assert_eq(types, ["SeatDied", "RoleChanged", "WinStatusProvisional"] as Array[String], "Erbe vor der vorläufigen Siegprüfung")


func test_inherit_active_night_roles_next_night() -> void:
	# 19, 26, AS-L08
	for role: String in ["schutzengel", "das-orakel"]:
		var log: Array[Command] = []
		var s := _inherit(role, [], log)
		if s == null:
			continue
		assert_eq(String(s.players[6].role_id), role, "%s geerbt" % role)
		assert_false(s.night_plan.has(StringName("%s:6" % role)), "%s: nicht in der laufenden Nacht" % role)
		s = _next_night(_drive_night(s, log), log)
		if s != null:
			assert_true(s.night_plan.has(StringName("%s:6" % role)), "%s: ab der folgenden Nacht" % role)


func test_inherit_witch_fresh_potions() -> void:
	# 20, AS-L07, AS-L14
	var log: Array[Command] = []
	var s := _inherit("waldhexe", [_gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": false})] as Array[Command], log)
	if s == null:
		return
	assert_eq(String(s.players[6].role_id), "waldhexe", "Waldhexe geerbt")
	assert_true(s.players[6].ability_uses.is_empty(), "beide Tränke frisch")
	assert_eq(int(s.players[5].ability_uses.get("waldhexe:heal", 0)), 1, "Verbrauch bleibt beim Meister")
	s = _next_night(_drive_night(s, log), log)
	if s != null:
		assert_true(s.night_plan.has(&"waldhexe:6"), "Waldhexenschritt in der folgenden Nacht")


func test_inherit_mirror_fresh() -> void:
	# 21
	var s := _inherit("spiegelwolf", [_gm("set_mirror", {"target_id": 5, "available": false})] as Array[Command])
	if s != null:
		assert_true(s.players[6].role_id == &"spiegelwolf" and ExecutionRules.mirror_available(s.players[6]), "Spiegelung frisch")


func test_inherit_manipulator_keeps_nomination_status() -> void:
	# 23
	var log: Array[Command] = []
	var s := _drive_night(_bound(5, [1, 4, 5], _ls("manipulator"), log), log)
	s = _steps(s, [Command.nominate(2, 6), _kill(5), _kill(3), _kill(2)] as Array[Command], log)
	if s == null:
		return
	assert_true(s.players[6].role_id == &"manipulator" and s.players[6].ever_nominated, "Status bleibt an der Person")
	assert_eq(s.alive_ids().size(), 3, "drei leben")
	assert_true(s.open_candidates().is_empty(), "kein Manipulator-Sieg")


func test_inherit_decoy_appearance() -> void:
	# 24
	var s := _inherit("trugbilderwolf")
	if s == null:
		return
	var p := s.players[6]
	assert_true(p.role_id == &"trugbilderwolf" and p.appears_as == &"waldhexe" and p.counts_as_wolf, "gültige Scheinrolle übernommen")
	assert_eq(String(InformationRules.determine_role(p)), "waldhexe", "Informationsrollen sehen die geerbte Erscheinung")


func test_inherit_transformed_wolf_child() -> void:
	# 25, AS-L10, AS-L11
	var log: Array[Command] = []
	# Zwei Wölfe, damit der Tod des Vorbilds (Person 1) keinen Sieg auslöst.
	var s := _bound(5, [1, 4, 5], _start(["werwolf", "blutwolf", "dorfbewohner", "sensentraeger", "wolfskind", "lehrling"]), log)
	if s == null:
		return
	assert_eq(WolfChildRules.bond_of(s, 5).model_id, 1, "Wolfskind 5 wählt Vorbild 1")
	s = _steps(s, [_kill(1)] as Array[Command], log)
	if s == null:
		return
	assert_true(s.players[5].counts_as_wolf, "Meister ist verwandelt")
	s = _steps(s, [_kill(5)] as Array[Command], log)
	if s == null:
		return
	var p := s.players[6]
	assert_true(p.role_id == &"wolfskind" and not p.counts_as_wolf and p.faction == &"village" and p.appears_as == &"wolfskind", "unverwandelt geerbt")
	var b := WolfChildRules.bond_of(s, 6)
	assert_true(b != null and b.model_id == -1 and not b.transformed, "kein Vorbild übernommen")
	s = _next_night(_drive_night(s, log), log)
	if s != null:
		assert_true(s.night_plan.has(&"wolfskind:6"), "neuer Wolfskind-Schritt in der folgenden Nacht")
		assert_true(s.pending_prompt != null and s.pending_prompt.actor_id == 6 and not s.pending_prompt.allowed_ids.has(6), "neues Vorbild, nicht sich selbst")


func test_inherit_apprentice_again() -> void:
	# 28
	var log: Array[Command] = []
	var s := _steps(GameState.new(), Fixtures.with_copies(["werwolf", "dorfbewohner", "amalia", "sensentraeger", "lehrling", "lehrling"], [Command.start_night()] as Array[Command]) as Array[Command], log)
	s = _drive_night(s, log, {5: {"cands": [1, 2, 4], "master": 2}, 6: {"cands": [1, 4, 5], "master": 5}})
	if s == null:
		return
	s = _step(s, _kill(5), log)
	if s == null:
		return
	assert_eq(String(s.players[6].role_id), "lehrling", "erbt lehrling")
	assert_eq(str(_bond(s, 6)["status"]), "inherited", "alte Bindung verbraucht")
	assert_true(_bond(s, 5).get("status") == "expired", "Bindung des toten Meisters verfällt")
	assert_eq(RulesEngine.next_step_id(s), "", "kein eingeschobener Schritt am selben Tag")
	s = _next_night(s, log)
	if s != null:
		assert_true(s.night_plan.has(&"lehrling:6"), "neue Auswahl in der folgenden Nacht")


# --- 29–33 Save/Load, Replay, beschädigte Daten ------------------------------------------------------------

func test_save_load_every_stage_and_replay() -> void:
	# 29, 31, 32, AS-L12, AS-L13, AS-L15
	var full: Array[Command] = [_ls("amalia", 4711), Command.start_night(), _cands(1, [2, 3, 5]), _opt(1, 0), _conf(1), Command.begin_step("night:1:1:pack"),
		Command.answer_prompt(2, []), Command.end_night(), Command.decide_execution(-1), Command.end_day()]
	var run := RulesEngine.replay(full)
	assert_true(run.ok, "Ablauf (%s @ %d)" % [run.error, run.failed_index])
	if not run.ok:
		return
	var master := int(_bond(run.state, 6).get("master_id", -1))
	full.append(_kill(master))
	full.append(Command.start_night())
	for n: int in [2, 3, 4, 5, 8, 11]:
		var prefix := full.slice(0, n)
		var a := RulesEngine.replay(prefix)
		if not a.ok:
			fail("Präfix %d" % n)
			continue
		var loaded := StateCodec.decode(StateCodec.encode(a.state, prefix))
		assert_true(loaded.ok, "Präfix %d: Laden (%s)" % [n, loaded.error])
		if not loaded.ok:
			continue
		assert_eq(_json(loaded.state.to_dict()), _json(a.state.to_dict()), "Präfix %d: vollständiger Zustand" % n)
		var sa := a.state
		var sb := loaded.state
		var ea: Array[GameEvent] = []
		var eb: Array[GameEvent] = []
		for c: Command in full.slice(n):
			var ra := RulesEngine.apply(sa, c)
			var rb := RulesEngine.apply(sb, c)
			assert_true(ra.ok and rb.ok, "Präfix %d: %s (%s)" % [n, c.type, ra.error])
			if not (ra.ok and rb.ok):
				break
			sa = ra.state
			sb = rb.state
			ea.append_array(ra.events)
			eb.append_array(rb.events)
		assert_eq(events_json(eb), events_json(ea), "Präfix %d: identische Fortsetzung" % n)
		assert_eq(_json(sb.to_dict()), _json(sa.to_dict()), "Präfix %d: identischer Endzustand" % n)
	var x := RulesEngine.replay(full)
	var y := RulesEngine.replay(full)
	assert_true(x.ok and y.ok, "Replay")
	assert_eq(events_json(x.events), events_json(y.events), "Replay bytegleich")
	assert_eq(x.state.content_hash(), y.state.content_hash(), "State-Hash gleich")
	assert_eq(events_of_type(x.events, "RoleChanged").size(), 1, "Erbe im Replay")


func _tampered(commands: Array[Command], mutate: Callable) -> LoadResult:
	var doc: Dictionary = CanonicalJson.normalize(JSON.parse_string(StateCodec.encode(Fixtures.play(commands), commands)))
	var body: Dictionary = doc["state"]
	mutate.call(body)
	var hashed := body.duplicate(true)
	for key: String in GameState.HASH_EXCLUDED_KEYS:
		hashed.erase(key)
	doc["state_hash"] = CanonicalJson.sha256(hashed)
	doc.erase("integrity")
	doc["integrity"] = CanonicalJson.sha256(doc)
	return StateCodec.decode(CanonicalJson.stringify(doc))


func test_corrupt_saves_rejected() -> void:
	# 33
	var bound: Array[Command] = [_ls(), Command.start_night(), _cands(1, [1, 2, 4]), _opt(1, 1), _conf(1)]
	var option: Array[Command] = [_ls(), Command.start_night(), _cands(1, [2, 3, 5])]
	var inherited := _concat(bound, [_kill(4, true)] as Array[Command])
	var control := _tampered(bound, func(st: Dictionary) -> void: st["players"][0]["name"] = "Z")
	assert_eq(String(control.error), "replay_mismatch", "Kontrolle: Hash und Integrität werden passiert")
	var cases := {
		"unbekannter Meister": [bound, func(st: Dictionary) -> void:
			st["apprentices"][0]["master_id"] = 99
			st["apprentices"][0]["option_person_ids"][1] = 99],
		"Meister ist der Lehrling": [bound, func(st: Dictionary) -> void:
			st["apprentices"][0]["master_id"] = 6
			st["apprentices"][0]["option_person_ids"][1] = 6],
		"Zuordnung widerspricht Meister": [bound, func(st: Dictionary) -> void: st["apprentices"][0]["option_person_ids"] = [4, 2, 1]],
		"Optionen unsortiert": [bound, func(st: Dictionary) -> void: st["apprentices"][0]["options"] = ["werwolf", "sensentraeger", "dorfbewohner"]],
		"unbekannte Rolle": [bound, func(st: Dictionary) -> void: st["apprentices"][0]["options"][0] = "nicht-im-katalog"],
		"gebunden, aber tot": [bound, func(st: Dictionary) -> void: st["players"][5]["alive"] = false],
		"gebunden ohne Lehrlingsrolle": [bound, func(st: Dictionary) -> void:
			st["players"][5]["role_id"] = "dorfbewohner"
			st["players"][5]["appears_as"] = "dorfbewohner"],
		"zwei aktive Bindungen": [bound, func(st: Dictionary) -> void:
			var copy: Dictionary = (st["apprentices"][0] as Dictionary).duplicate(true)
			copy["id"] = 2
			(st["apprentices"] as Array).append(copy)],
		"unbekannter Status": [bound, func(st: Dictionary) -> void: st["apprentices"][0]["status"] = "irgendwas"],
		"Erbe ohne gültigen Schnappschuss": [inherited, func(st: Dictionary) -> void: st["apprentices"][0]["snapshot"]["role_id"] = "nicht-im-katalog"],
		"Prompt mit manipulierten Optionen": [option, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["options"] = ["dorfbewohner", "dorfbewohner", "werwolf"]],
		"Prompt mit manipulierter Zuordnung": [option, func(st: Dictionary) -> void:
			var m: Array = st["pending_prompt"]["partial"]["option_person_ids"]
			var tmp: Variant = m[0]
			m[0] = m[1]
			m[1] = tmp],
		"Prompt mit manipuliertem RNG": [option, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["rng_after"]["draws"] = 99],
		"Prompt mit Selbstkandidat": [option, func(st: Dictionary) -> void: st["pending_prompt"]["partial"]["candidates"] = [2, 3, 6]],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var result := _tampered(commands, cases[label][1])
		assert_false(result.ok, "%s: nicht geladen" % label)
		assert_eq(String(result.error), "state_invalid", "%s: Fehlergrund" % label)
		assert_true(result.state == null, "%s: kein teilweise geladener Zustand" % label)


# --- 34 Spielleiterkorrekturen ------------------------------------------------------------------------------

func test_gm_corrections() -> void:
	# 34: setzen, ändern, entfernen, Erbe auslösen, Erbe zurücknehmen
	var open: Array[Command] = [_ls(), Command.start_night()]
	var bound: Array[Command] = [_ls(), Command.start_night(), _cands(1, [1, 2, 4]), _opt(1, 1), _conf(1)]
	var cases := {
		"setzen": [open, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 2}, "Auswahl am Tisch"), {"master_id": -1}, {"master_id": 2}],
		"ändern": [bound, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 2}), {"master_id": 4}, {"master_id": 2}],
		"entfernen": [bound, _gm("remove_apprentice_master", {"apprentice_id": 6}), {"master_id": 4}, {"master_id": -1}],
		"Erbe auslösen": [bound, _gm("trigger_apprentice_inheritance", {"apprentice_id": 6}), {"role_id": "lehrling"}, {"role_id": "sensentraeger"}],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var s := Fixtures.play(commands)
		var r := RulesEngine.apply(s, cases[label][1])
		assert_true(r.ok, "%s: angenommen (%s)" % [label, r.error])
		if not r.ok:
			continue
		var logged := events_of_type(r.events, "GmCorrected")
		assert_true(logged.size() == 1 and _is_part(cases[label][2], logged[0].data["old"]) and _is_part(cases[label][3], logged[0].data["new"]), "%s: alter und neuer Wert" % label)
		commands.append(cases[label][1])
		_roundtrip(commands, label)
	var set := Fixtures.play(_concat(open, [_gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 2})] as Array[Command]))
	assert_true(set != null and str(_bond(set, 6)["status"]) == "bound" and RulesEngine.next_step_id(set) == "night:1:1:pack", "Auswahlschritt entfällt nach gesetzter Bindung")
	var removed := Fixtures.play(_concat(bound, [_gm("remove_apprentice_master", {"apprentice_id": 6})] as Array[Command]))
	assert_true(removed != null and str(_bond(removed, 6)["status"]) == "removed", "Bindung entfernt")
	# Rücknahme stellt den Zustand unmittelbar vor dem Erbe wieder her.
	var before := Fixtures.play(bound)
	var inherited := _concat(bound, [_kill(4)] as Array[Command])
	var s2 := Fixtures.play(inherited)
	var revert := _gm("revert_apprentice_inheritance", {"apprentice_id": 6}, "Erbe irrtümlich")
	var rr := RulesEngine.apply(s2, revert)
	assert_true(rr.ok, "Rücknahme angenommen (%s)" % rr.error)
	if rr.ok:
		assert_eq(_json(_player(rr.state, 6)), _json(_player(before, 6)), "Rollenzustand exakt wie vor dem Erbe")
		assert_eq(str(_bond(rr.state, 6)["status"]), "bound", "Bindung wieder aktiv")
		assert_eq(events_of_type(rr.events, "GmCorrected").size(), 1, "protokolliert")
		_roundtrip(_concat(inherited, [revert] as Array[Command]), "Rücknahme")
	# Ungültige Korrekturen
	var b := Fixtures.play(bound)
	apply_rejected(b, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 6}), "invalid_target", "Selbstbindung")
	apply_rejected(b, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 99}), "unknown_player", "unbekannt")
	apply_rejected(b, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 4}), "no_change", "gleicher Meister")
	apply_rejected(b, _gm("set_apprentice_master", {"apprentice_id": 5, "target_id": 4}), "not_an_apprentice", "kein Lehrling")
	apply_rejected(b, _gm("revert_apprentice_inheritance", {"apprentice_id": 6}), "no_inheritance", "nichts zurückzunehmen")
	apply_rejected(Fixtures.play(open), _gm("trigger_apprentice_inheritance", {"apprentice_id": 6}), "no_binding", "ohne Bindung")
	apply_rejected(Fixtures.play(open), _gm("remove_apprentice_master", {"apprentice_id": 6}), "no_binding", "ohne Bindung entfernen")
	apply_rejected(b, Command.gm_correction({"kind": "set_apprentice_master", "apprentice_id": 6, "target_id": 2, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(b, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 2}, " "), "reason_required", "ohne Begründung")
	var dead_target := apply_ok(b, _kill(2, false), "2 stirbt").state
	apply_rejected(dead_target, _gm("set_apprentice_master", {"apprentice_id": 6, "target_id": 2}), "player_dead", "totes Ziel")


func _is_part(expected: Dictionary, actual: Variant) -> bool:
	if not actual is Dictionary:
		return false
	for k: Variant in expected:
		if str((actual as Dictionary).get(k)) != str(expected[k]):
			return false
	return true


func _roundtrip(commands: Array[Command], label: String) -> void:
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_true(a.ok and b.ok, "%s: Replay (%s)" % [label, a.error])
	if not a.ok:
		return
	assert_eq(events_json(a.events), events_json(b.events), "%s: Replay bytegleich" % label)
	var loaded := StateCodec.decode(StateCodec.encode(a.state, commands))
	assert_true(loaded.ok and _json(loaded.state.to_dict()) == _json(a.state.to_dict()), "%s: Save/Load (%s)" % [label, loaded.error])
