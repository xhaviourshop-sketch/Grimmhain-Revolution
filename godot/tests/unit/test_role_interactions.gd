extends TestCase
## Semantische Wechselwirkungen mehrerer Rollen des Regelkerns (Rollenaudit,
## docs/role-migration/11-role-audit-status.md §4). Jede Prüfung nennt die beteiligten
## Regeln; Einzelverhalten steht in den Rollentests, hier nur Dreier- und Mehrfachfälle.


func _start(roles: Array, appearances: Dictionary = {}) -> Command:
	var payload := Fixtures.start_roles(roles, 1).payload.duplicate(true)
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Interaktionstest")


## Wendet `c` an, protokolliert Befehl und Ereignisse; null bei Ablehnung.
func _do(s: GameState, c: Command, log: Array[Command], events: Array[GameEvent], label: String) -> GameState:
	if s == null:
		return null
	var r := RulesEngine.apply(s, c)
	assert_true(r.ok, "%s: %s angenommen (%s)" % [label, c.type, r.error])
	if not r.ok:
		return null
	log.append(c)
	events.append_array(r.events)
	return r.state


## Lehrling: Kandidaten wählen, Option mit Rolle `role` wählen, bestätigen.
func _apprentice(s: GameState, candidates: Array, role: String, log: Array[Command], events: Array[GameEvent]) -> GameState:
	var id := s.pending_prompt.id
	s = _do(s, Command.answer_stage_targets(id, "candidates", candidates), log, events, "Lehrling Kandidaten")
	if s == null:
		return null
	var options: Array = s.pending_prompt.partial["options"]
	s = _do(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": id, "stage": "option", "option": options.find(role)}), log, events, "Lehrling Option")
	return _do(s, Command.answer_choice(id, "confirm", true), log, events, "Lehrling bestätigt")


## Beginnt den erwarteten Schritt, falls noch kein Prompt offen ist.
func _begin(s: GameState, log: Array[Command], events: Array[GameEvent]) -> GameState:
	if s == null or s.pending_prompt != null:
		return s
	return _do(s, Command.begin_step(RulesEngine.next_step_id(s)), log, events, "Schritt beginnen")


func _types(events: Array[GameEvent], only: Array) -> Array[String]:
	var out: Array[String] = []
	for e: GameEvent in events:
		if only.has(String(e.type)):
			out.append(String(e.type))
	return out


func _deaths(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events:
		if e.type == GameEvent.SEAT_DIED:
			out.append([int(e.data["target_id"]), String(e.data["cause"])])
	return out


func _roundtrip_and_replay(s: GameState, log: Array[Command], events: Array[GameEvent], label: String) -> void:
	if s == null:
		return
	var loaded := StateCodec.decode(StateCodec.encode(s, log))
	assert_true(loaded.ok, "%s: Spielstand lädt (%s)" % [label, loaded.error])
	if loaded.ok:
		assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: geladener Zustand identisch" % label)
		assert_eq(events_json(loaded.events), events_json(events), "%s: Replay-Ereignisse identisch" % label)


# --- Tod mit drei unmittelbaren Folgen ---------------------------------------------------------------

## Ein Tod löst Wolfskind-Verwandlung, Lehrling-Erbe und die Reaktion des Meisters aus.
## DR-10/DR-11/Lehrling-Eintrag: Verwandlung → Erbe → Reaktion einreihen → vorläufiger Sieg.
## Der geerbte Sensenträger reagiert sofort mit eigenem, frischem Einsatz (Korrekturrunde 2).
## Siegkandidat erst nach der vollständigen Reaktionskette (DR-14).
func test_one_death_transforms_inherits_and_reacts_in_order() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1, 2 Werwolf; 3 Sensenträger (Vorbild und Meister); 4 Wolfskind; 5 Lehrling; 6 Dorfbewohner
	var s := _do(GameState.new(), _start(["werwolf", "werwolf", "sensentraeger", "wolfskind", "lehrling", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	assert_eq(String(s.pending_prompt.step_id), "night:1:0:wolfskind:4", "Wolfskind zuerst")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [3]), log, ev, "Vorbild 3")
	s = _begin(s, log, ev)
	s = _apprentice(s, [1, 3, 6], "sensentraeger", log, ev)
	s = _begin(s, log, ev)
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [3]), log, ev, "Rudel tötet 3")
	var before := ev.size()
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	if s == null:
		return
	var dawn := ev.slice(before)
	assert_eq(_types(dawn, ["SeatDied", "WolfChildTransformed", "RoleChanged", "ReactionQueued", "WinStatusProvisional"]),
		["SeatDied", "WolfChildTransformed", "RoleChanged", "ReactionQueued", "WinStatusProvisional"] as Array[String], "Reihenfolge der Todesfolgen")
	assert_true(s.players[4].counts_as_wolf, "Wolfskind verwandelt")
	assert_eq(String(s.players[5].role_id), "sensentraeger", "Lehrling erbt Sensenträger")
	assert_eq(s.open_candidates().size(), 0, "kein Kandidat bei offener Reaktion trotz Wolfsparität")
	# Meister 3 verflucht den Erben 5; dessen geerbte Reaktion wird sofort eingereiht.
	s = _begin(s, log, ev)
	before = ev.size()
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [5]), log, ev, "Fluch von 3 auf 5")
	if s == null:
		return
	assert_eq(_deaths(ev.slice(before)), [[5, "HUNTER_SHOT"]], "Erbe stirbt am Fluch")
	assert_eq(s.reactions.size(), 1, "geerbte Reaktion eingereiht")
	assert_eq(s.reactions[0].owner_id, 5, "Reaktion gehört dem Erben")
	assert_eq(s.open_candidates().size(), 0, "weiterhin kein Kandidat")
	s = _begin(s, log, ev)
	assert_false(s.pending_prompt.allowed_ids.has(5), "Erbe zielt nie auf sich selbst")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [4]), log, ev, "Fluch von 5 auf das verwandelte Wolfskind")
	if s == null:
		return
	assert_eq(String(s.phase), "DAY", "Tag nach vollständiger Kette")
	# Lebend: 1, 2 (Wölfe), 6 → Wölfe 2 ≥ 1: genau ein Kandidat Werwölfe.
	var open := s.open_candidates()
	assert_eq(open.size(), 1, "genau ein Kandidat nach der Kette")
	if open.size() == 1:
		assert_eq(String(open[0].kind), "wolves", "Wolfssieg")
	_roundtrip_and_replay(s, log, ev, "Kette")


# --- Spiegelung trifft gebundene Personen -----------------------------------------------------------

## Die Spiegelung tötet die nominierende Person: Deren Wolfskind verwandelt sich, deren Lehrling
## erbt. Ein Wolfskind mit dem überlebenden Spiegelwolf als Vorbild bleibt unverwandelt (DR-13).
func test_mirror_death_triggers_child_and_apprentice_of_nominator_only() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1 Spiegelwolf; 2 Werwolf; 3 Dorfbewohner (nominiert); 4 Wolfskind → 3; 5 Lehrling → 3; 6 Wolfskind → 1; 7, 8 Dorfbewohner
	var s := _do(GameState.new(), _start(["spiegelwolf", "werwolf", "dorfbewohner", "wolfskind", "lehrling", "wolfskind", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [3]), log, ev, "Wolfskind 4 → 3")
	s = _begin(s, log, ev)
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [1]), log, ev, "Wolfskind 6 → 1")
	s = _begin(s, log, ev)
	s = _apprentice(s, [1, 2, 3], "dorfbewohner", log, ev)
	s = _do(s, Command.skip_step(RulesEngine.next_step_id(s), "kein Opfer"), log, ev, "Rudel ohne Opfer")
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	s = _do(s, Command.nominate(3, 1), log, ev, "3 nominiert den Spiegelwolf")
	var before := ev.size()
	s = _do(s, Command.decide_execution(1), log, ev, "Hinrichtung 1")
	if s == null:
		return
	var day := ev.slice(before)
	assert_eq(_deaths(day), [[3, "SPIEGELWOLF_RETALIATE"]], "nur die nominierende Person stirbt")
	assert_true(s.players[1].alive, "Spiegelwolf überlebt")
	assert_true(s.players[4].counts_as_wolf, "Wolfskind der nominierenden Person verwandelt")
	assert_false(s.players[6].counts_as_wolf, "Wolfskind des Spiegelwolfs bleibt unverwandelt")
	assert_eq(String(s.players[5].role_id), "dorfbewohner", "Lehrling erbt die Rolle der nominierenden Person")
	assert_eq(_types(day, ["ExecutionRedirected", "SeatDied", "WolfChildTransformed", "RoleChanged", "WinStatusProvisional"]),
		["ExecutionRedirected", "SeatDied", "WolfChildTransformed", "RoleChanged", "WinStatusProvisional"] as Array[String], "Reihenfolge")
	# Lebend: 1, 2, 4 Wölfe; 5, 6, 7, 8 andere → kein Kandidat.
	assert_eq(s.open_candidates().size(), 0, "kein Siegkandidat")
	_roundtrip_and_replay(s, log, ev, "Spiegelung")


# --- Manipulator als Meister und Vorbild ------------------------------------------------------------

## Der nominierte Manipulator stirbt sofort; sein Wolfskind verwandelt sich, sein Lehrling erbt
## die Rolle ohne dessen Nominierungsstatus und kann später bei drei Lebenden gewinnen (DR-12).
func test_nominated_manipulator_passes_role_to_unnominated_apprentice() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1, 2 Werwolf; 3 Manipulator; 4 Wolfskind → 3; 5 Lehrling → 3; 6, 7, 8 Dorfbewohner
	var s := _do(GameState.new(), _start(["werwolf", "werwolf", "manipulator", "wolfskind", "lehrling", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [3]), log, ev, "Wolfskind → 3")
	s = _begin(s, log, ev)
	s = _apprentice(s, [3, 6, 1], "manipulator", log, ev)
	s = _do(s, Command.skip_step(RulesEngine.next_step_id(s), "kein Opfer"), log, ev, "Rudel ohne Opfer")
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	var before := ev.size()
	s = _do(s, Command.nominate(6, 3), log, ev, "Nominierung des Manipulators")
	if s == null:
		return
	assert_eq(_deaths(ev.slice(before)), [[3, "MANIPULATOR_NOMINATED"]], "Manipulator stirbt bei Nominierung")
	assert_true(s.players[4].counts_as_wolf, "Wolfskind verwandelt")
	assert_eq(String(s.players[5].role_id), "manipulator", "Lehrling erbt Manipulator")
	assert_false(s.players[5].ever_nominated, "Erbe gilt als nie nominiert")
	s = _do(s, Command.decide_execution(-1), log, ev, "keine Hinrichtung")
	for id: int in [1, 2, 6, 7]:
		s = _do(s, _gm("kill", {"target_id": id, "trigger_effects": true}), log, ev, "Tod %d" % id)
		if s == null:
			return
		if id != 7:
			assert_eq(s.open_candidates().size(), 0, "kein Kandidat vor drei Lebenden (nach %d)" % id)
	# Lebend: 4 (Wolf), 5 (Manipulator), 8 → Wölfe 1 < 2, genau drei Lebende.
	var open := s.open_candidates()
	assert_eq(open.size(), 1, "genau ein Kandidat")
	if open.size() == 1:
		assert_eq(String(open[0].kind), "solo", "Einzelsieg")
		assert_eq(open[0].beneficiary_ids, [5] as Array[int], "der Erbe gewinnt")
	_roundtrip_and_replay(s, log, ev, "Manipulator-Erbe")


# --- Schutz, Gift und Verwandlung in derselben Nacht --------------------------------------------------

## Schutzengel schützt das Vorbild vor dem Rudel, die Waldhexe vergiftet es: Gift wirkt trotz
## Schutz sofort (Waldhexe-Eintrag), das Wolfskind verwandelt sich noch in der Nacht, der
## Rudelangriff am Morgen trifft einen Toten und wird ignoriert (genau ein Tod, erste Ursache).
func test_protected_model_poisoned_transforms_once_at_night() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1, 2 Werwolf; 3 Schutzengel; 4 Waldhexe; 5 Wolfskind → 6; 6, 7, 8 Dorfbewohner
	var s := _do(GameState.new(), _start(["werwolf", "werwolf", "schutzengel", "waldhexe", "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [6]), log, ev, "Wolfskind → 6")
	s = _begin(s, log, ev)
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [6]), log, ev, "Schutz auf 6")
	s = _begin(s, log, ev)
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [6]), log, ev, "Rudel auf 6")
	s = _begin(s, log, ev)
	var w := s.pending_prompt.id
	s = _do(s, Command.answer_choice(w, "heal", false), log, ev, "nicht heilen")
	s = _do(s, Command.answer_choice(w, "poison", true), log, ev, "vergiften")
	s = _do(s, Command.answer_stage_targets(w, "poison_target", [6]), log, ev, "Giftziel 6")
	var before := ev.size()
	s = _do(s, Command.answer_choice(w, "confirm", true), log, ev, "bestätigen")
	if s == null:
		return
	assert_eq(_deaths(ev.slice(before)), [[6, "WITCH_POISON"]], "Gift tötet trotz Schutz sofort")
	assert_eq(String(s.phase), "NIGHT", "noch Nacht")
	assert_true(s.players[5].counts_as_wolf, "Wolfskind verwandelt sich sofort")
	before = ev.size()
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	if s == null:
		return
	var dawn := ev.slice(before)
	assert_eq(_deaths(dawn), [], "kein zweiter Tod am Morgen")
	assert_eq(_types(dawn, ["KillIgnored", "KillPrevented"]), ["KillIgnored"] as Array[String], "Rudelangriff auf Toten ignoriert, kein Schutzverbrauch")
	_roundtrip_and_replay(s, log, ev, "Schutz und Gift")


# --- 24 Personen mit mehreren Kopien ------------------------------------------------------------------

## 24 Personen, jede Rolle mit Nachtschritt doppelt: Nachtplan nach Priorität, dann Personen-ID;
## in Nacht 2 entfallen Wolfskind- und Lehrlingsschritte der gebundenen Personen.
## Speichern und Laden nach jedem Befehl setzt identisch fort.
func test_24_players_multiple_copies_night_plan_and_save_load() -> void:
	var roles := ["dorfbewohner", "waldhexe", "werwolf", "das-orakel", "lehrling", "schutzengel", "wolfskind", "werwolf",
		"sensentraeger", "trugbilderwolf", "dorfbewohner", "spiegelwolf", "manipulator", "waldhexe", "schutzengel", "das-orakel",
		"lehrling", "wolfskind", "sensentraeger", "dorfbewohner", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	var s := _do(GameState.new(), _start(roles, {"10": "das-orakel"}), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	if s == null:
		return
	assert_eq(s.night_plan, [&"wolfskind:7", &"wolfskind:18", &"lehrling:5", &"lehrling:17", &"schutzengel:6", &"schutzengel:15",
		&"pack", &"waldhexe:2", &"waldhexe:14", &"das-orakel:4", &"das-orakel:16"] as Array[StringName], "Nachtplan Nacht 1")
	s = _drive_night_with_save_load(s, log, ev)
	if s == null:
		return
	s = _do(s, Command.end_night(), log, ev, "Morgen 1")
	s = _do(s, Command.decide_execution(-1), log, ev, "keine Hinrichtung")
	s = _do(s, Command.end_day(), log, ev, "Tagesende")
	s = _do(s, Command.start_night(), log, ev, "Nacht 2")
	if s == null:
		return
	var expected: Array[StringName] = []
	for key: StringName in [&"schutzengel:6", &"schutzengel:15", &"pack", &"waldhexe:2", &"waldhexe:14", &"das-orakel:4", &"das-orakel:16"]:
		var actor := StepQueue.step_actor(key)
		if key == &"pack" or (s.players[actor].alive and s.players[actor].role_id == StepQueue.step_role(key)):
			expected.append(key)
	assert_eq(s.night_plan, expected, "Nacht 2 ohne erledigte Auswahlschritte")
	_roundtrip_and_replay(s, log, ev, "24 Personen")


## Antwortet deterministisch auf alle Schritte der Nacht; nach jedem Befehl wird der Stand
## gespeichert, geladen und mit dem geladenen Zustand fortgesetzt.
func _drive_night_with_save_load(s: GameState, log: Array[Command], ev: Array[GameEvent]) -> GameState:
	var guard := 0
	while s != null and (s.pending_prompt != null or RulesEngine.next_step_id(s) != ""):
		guard += 1
		if guard > 80:
			fail("Nacht endet nicht")
			return null
		var c: Command
		var p := s.pending_prompt
		if p == null:
			c = Command.begin_step(RulesEngine.next_step_id(s))
		elif p.owner == PendingPrompt.OWNER_APPRENTICE:
			match String(p.stage):
				"candidates":
					var picks: Array = []
					for id: int in s.alive_ids():
						if id != p.actor_id and picks.size() < 3:
							picks.append(id)
					c = Command.answer_stage_targets(p.id, "candidates", picks)
				"option":
					c = Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": "option", "option": 0})
				_:
					c = Command.answer_choice(p.id, "confirm", true)
		elif p.owner == PendingPrompt.OWNER_WITCH:
			match String(p.stage):
				"heal":
					c = Command.answer_choice(p.id, "heal", true)
				"poison":
					c = Command.answer_choice(p.id, "poison", false)
				_:
					c = Command.answer_choice(p.id, String(p.stage), true)
		elif p.owner == PendingPrompt.OWNER_ORACLE:
			if String(p.stage) == "target":
				c = Command.answer_stage_targets(p.id, "target", [p.allowed_ids[0]])
			else:
				c = Command.answer_choice(p.id, "shown", true)
		else:
			c = Command.answer_prompt(p.id, [p.allowed_ids[p.allowed_ids.size() - 1]])
		s = _do(s, c, log, ev, "Nacht")
		if s == null:
			return null
		var loaded := StateCodec.decode(StateCodec.encode(s, log))
		assert_true(loaded.ok, "Laden nach %s (%s)" % [c.type, loaded.error])
		if not loaded.ok:
			return null
		assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(s.to_dict()), "geladener Zustand nach %s" % c.type)
		s = loaded.state
	return s


# --- Rudel ohne lebenden Wolf -------------------------------------------------------------------------

## G-PH-6: Der Rudelschritt existiert nur, solange mindestens eine lebende Person als Wolf zählt.
## Stirbt der letzte Wolf in der Nacht vor dem Rudelschritt, entfällt dieser protokolliert
## (wie ein persönlicher Schritt einer toten Person) und niemand wird angegriffen.
func test_pack_step_dropped_when_last_wolf_died_during_night() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1 Werwolf; 2 Schutzengel; 3–6 Dorfbewohner
	var s := _do(GameState.new(), _start(["werwolf", "schutzengel", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), log, ev, "letzter Wolf stirbt per Korrektur")
	if s == null:
		return
	var open := s.open_candidates()
	assert_eq(open.size(), 1, "Dorfsieg wird vorgeschlagen")
	s = _do(s, Command.create(Command.REJECT_WIN, {"reason": "Nacht zu Ende spielen"}), log, ev, "Sieg abgelehnt")
	s = _begin(s, log, ev)
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [3]), log, ev, "Schutz")
	if s == null:
		return
	assert_eq(RulesEngine.next_step_id(s), "", "kein Rudelschritt ohne lebenden Wolf")
	var dropped := events_of_type(ev, "StepDropped")
	assert_eq(dropped.size(), 1, "Rudelschritt protokolliert entfallen")
	if dropped.size() == 1:
		assert_eq(String(dropped[0].data["step_id"]), "night:1:1:pack", "entfallener Schritt")
		assert_eq(String(dropped[0].data["reason"]), "no_living_wolf", "Grund")
	s = _do(s, Command.end_night(), log, ev, "Morgen ohne Angriff")
	_roundtrip_and_replay(s, log, ev, "Rudel ohne Wolf")
