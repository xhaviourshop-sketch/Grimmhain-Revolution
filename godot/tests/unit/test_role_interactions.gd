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
## Schutz, als Todesmarkierung erst am Morgen (Decision Log „Nachttode“) und vor dem Rudelangriff;
## das Wolfskind verwandelt sich dann, der Rudelangriff trifft einen Toten (genau ein Tod, erste Ursache).
func test_protected_model_poisoned_transforms_once_at_dawn() -> void:
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
	assert_eq(_deaths(ev.slice(before)), [], "in der Nacht nur Markierung")
	assert_eq(String(s.phase), "NIGHT", "noch Nacht")
	assert_false(s.players[5].counts_as_wolf, "Wolfskind noch unverwandelt")
	before = ev.size()
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	if s == null:
		return
	var dawn := ev.slice(before)
	assert_eq(_deaths(dawn), [[6, "WITCH_POISON"]], "Gift trotz Schutz, genau ein Tod")
	assert_true(s.players[5].counts_as_wolf, "Wolfskind verwandelt sich am Morgen")
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


# --- Gift als Todesmarkierung (Decision Log „Nachfragen … Nachttode“) ------------------------------

## Eine vergiftete Person stirbt erst in der Morgenauflösung, wacht aber in dieser Nacht nicht
## mehr auf: ihr späterer Orakelschritt entfällt mit Grund `marked_for_death`. Das Rudelopfer ist
## nachts nicht sicher tot (Rettung möglich) und prüft als Orakel weiter.
func test_poisoned_person_loses_later_step_pack_victim_keeps_it() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1, 2 Werwolf; 3 Waldhexe; 4 Orakel (vergiftet); 5 Orakel (Rudelopfer); 6–8 Dorfbewohner
	var s := _do(GameState.new(), _start(["werwolf", "werwolf", "waldhexe", "das-orakel", "das-orakel", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [5]), log, ev, "Rudel auf Orakel 5")
	s = _begin(s, log, ev)
	var w := s.pending_prompt.id
	s = _do(s, Command.answer_choice(w, "heal", false), log, ev, "nicht heilen")
	s = _do(s, Command.answer_choice(w, "poison", true), log, ev, "vergiften")
	s = _do(s, Command.answer_stage_targets(w, "poison_target", [4]), log, ev, "Giftziel Orakel 4")
	var before := ev.size()
	s = _do(s, Command.answer_choice(w, "confirm", true), log, ev, "bestätigen")
	if s == null:
		return
	assert_eq(_deaths(ev.slice(before)), [], "Gift tötet nicht in der Nacht")
	assert_true(s.players[4].alive, "vergiftetes Orakel lebt bis zum Morgen")
	var dropped := events_of_type(ev.slice(before), "StepDropped")
	assert_eq(dropped.size(), 1, "Schritt des vergifteten Orakels entfällt")
	if dropped.size() == 1:
		assert_eq(String(dropped[0].data["step_id"]), "night:1:2:das-orakel:4", "entfallener Schritt")
		assert_eq(String(dropped[0].data["reason"]), "marked_for_death", "Grund")
	assert_eq(RulesEngine.next_step_id(s), "night:1:3:das-orakel:5", "Rudelopfer prüft weiter")
	s = _begin(s, log, ev)
	s = _do(s, Command.answer_stage_targets(s.pending_prompt.id, "target", [1]), log, ev, "Orakel 5 prüft 1")
	s = _do(s, Command.answer_choice(s.pending_prompt.id, "shown", true), log, ev, "gezeigt")
	before = ev.size()
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	if s == null:
		return
	assert_eq(_deaths(ev.slice(before)), [[4, "WITCH_POISON"], [5, "NIGHT_KILL"]], "am Morgen: erst Gift, dann Rudel")
	var poison_death := s.players[4].death
	assert_eq(String(poison_death.phase), "DAWN_RESOLUTION", "Gifttod in der Morgenauflösung")
	assert_eq(poison_death.source_id, 3, "Quelle Waldhexe")
	_roundtrip_and_replay(s, log, ev, "Giftmarkierung")


## Stirbt die Waldhexe nach ihrer Bestätigung noch in der Nacht, bleibt ihr Gift bestehen
## (Decision Log Schutzengel: bestätigte Aktionen bleiben).
func test_poison_mark_survives_witch_death() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	var s := _do(GameState.new(), _start(["werwolf", "werwolf", "waldhexe", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, Command.skip_step(RulesEngine.next_step_id(s), "kein Opfer"), log, ev, "Rudel ohne Opfer")
	s = _begin(s, log, ev)
	var w := s.pending_prompt.id
	s = _do(s, Command.answer_choice(w, "poison", true), log, ev, "vergiften")
	s = _do(s, Command.answer_stage_targets(w, "poison_target", [4]), log, ev, "Giftziel 4")
	s = _do(s, Command.answer_choice(w, "confirm", true), log, ev, "bestätigen")
	s = _do(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), log, ev, "Waldhexe stirbt")
	var before := ev.size()
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	if s != null:
		assert_eq(_deaths(ev.slice(before)), [[4, "WITCH_POISON"]], "Gift wirkt trotzdem")


## Decision Log „Rollenaudit“ (F-10): Der Rudelschritt entfällt, wenn niemand mehr lebt, der zu
## Beginn der Nacht als Wolf zählte. Ein in dieser Nacht verwandeltes Wolfskind wacht erst in der
## folgenden Nacht mit dem Rudel.
func test_pack_dropped_when_only_newly_transformed_wolf_lives() -> void:
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	# 1 Werwolf; 2 Wolfskind → 3; 3–7 Dorfbewohner. Nacht 2: Korrektur tötet 1 und 3 vor dem Rudel.
	var s := _do(GameState.new(), _start(["werwolf", "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), log, ev, "Start")
	s = _do(s, Command.start_night(), log, ev, "Nacht 1")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, [3]), log, ev, "Vorbild 3")
	s = _do(s, Command.skip_step(RulesEngine.next_step_id(s), "kein Opfer"), log, ev, "Rudel ohne Opfer")
	s = _do(s, Command.end_night(), log, ev, "Morgen")
	s = _do(s, Command.decide_execution(-1), log, ev, "keine Hinrichtung")
	s = _do(s, Command.end_day(), log, ev, "Tagesende")
	s = _do(s, Command.start_night(), log, ev, "Nacht 2")
	if s == null:
		return
	assert_eq(RulesEngine.next_step_id(s), "night:2:0:pack", "Rudelschritt geplant")
	s = _do(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), log, ev, "Vorbild stirbt, Wolfskind verwandelt sich")
	s = _do(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), log, ev, "letzter Wolf vom Nachtbeginn stirbt")
	if s == null:
		return
	assert_true(s.players[2].counts_as_wolf, "Wolfskind zählt als Wolf")
	if not s.open_candidates().is_empty():
		s = _do(s, Command.create(Command.REJECT_WIN, {"reason": "weiter"}), log, ev, "Siegvorschlag abgelehnt")
	assert_eq(RulesEngine.next_step_id(s), "", "kein Rudelschritt in dieser Nacht")
	var dropped := events_of_type(ev, "StepDropped")
	assert_true(not dropped.is_empty() and String(dropped[-1].data["step_id"]) == "night:2:0:pack" and String(dropped[-1].data["reason"]) == "no_living_wolf", "protokolliert")
	s = _do(s, Command.end_night(), log, ev, "Morgen ohne Angriff")
	s = _do(s, Command.decide_execution(-1), log, ev, "keine Hinrichtung")
	s = _do(s, Command.end_day(), log, ev, "Tagesende")
	s = _do(s, Command.start_night(), log, ev, "Nacht 3")
	if s != null:
		assert_true(s.night_plan.has(&"pack"), "verwandeltes Wolfskind bildet ab Nacht 3 das Rudel")
	_roundtrip_and_replay(s, log, ev, "Rudel-Snapshot")


# --- Wiederbelebung setzt Fähigkeiten zurück (Decision Log „Rollenaudit · Wiederbelebung …“) -------------

## Jede Wiederbelebung setzt alle begrenzten Einsätze der Person zurück (Tränke, Spiegelung,
## Todesreaktion); Nominierungsstatus bleibt.
func test_revive_resets_all_limited_abilities() -> void:
	# 1 Werwolf; 2 Waldhexe; 3 Spiegelwolf; 4 Sensenträger; 5–8 Dorfbewohner.
	var s := _do(GameState.new(), _start(["werwolf", "waldhexe", "spiegelwolf", "sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), [], [], "Start")
	for c: Command in [_gm("set_witch_potion", {"witch_id": 2, "potion": "heal", "available": false}),
			_gm("set_witch_potion", {"witch_id": 2, "potion": "poison", "available": false}),
			_gm("set_mirror", {"target_id": 3, "available": false}), _gm("set_ever_nominated", {"target_id": 4, "value": true})]:
		s = apply_ok(s, c, "Einsätze verbraucht").state
	for c: Command in [Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]:
		s = apply_ok(s, c, "bis zum Tag").state
	var log: Array[Command] = []
	var ev: Array[GameEvent] = []
	for id: int in [2, 3]:
		s = _do(s, _gm("kill", {"target_id": id, "trigger_effects": false}), log, ev, "Tod %d" % id)
		s = _do(s, _gm("revive", {"target_id": id}), log, ev, "Wiederbelebung %d" % id)
	if s == null:
		return
	assert_true(WitchStep.potion_available(s.players[2], "heal") and WitchStep.potion_available(s.players[2], "poison"), "Tränke wieder verfügbar")
	assert_true(ExecutionRules.mirror_available(s.players[3]), "Spiegelung wieder verfügbar")
	# Sensenträger: Fluch nach erstem Tod eingelöst, Wiederbelebung, zweiter Tod → erneute Reaktion.
	s = _do(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), log, ev, "Sensenträger stirbt")
	s = _do(s, Command.begin_step(RulesEngine.next_step_id(s)), log, ev, "Reaktion")
	s = _do(s, Command.answer_prompt(s.pending_prompt.id, []), log, ev, "Verzicht")
	s = _do(s, _gm("revive", {"target_id": 4}), log, ev, "Wiederbelebung Sensenträger")
	s = _do(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), log, ev, "zweiter Tod")
	if s == null:
		return
	assert_eq(s.reactions.size(), 1, "Todesreaktion nach Wiederbelebung erneut")
	assert_true(s.players[4].ever_nominated, "Nominierungsstatus bleibt")


## Regression (Fuzztest): Lebt außer Schutzengel bzw. Wolfskind niemand mehr, kann ihr Pflichtschritt
## („eine andere lebende Person“) nicht beantwortet werden; er entfällt protokolliert wie beim Orakel
## (Decision Log: „Ein … Schritt ohne mögliche Entscheidung entfällt ebenso“), statt die Nacht zu blockieren.
func test_guard_and_wolf_child_without_other_living_are_dropped() -> void:
	for role: String in ["schutzengel", "wolfskind"]:
		var s := _do(GameState.new(), _start(["werwolf", role, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]), [], [], "Start")
		for id: int in [1, 3, 4, 5, 6]:
			s = apply_ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "%s: Tod %d" % [role, id]).state
			if not s.open_candidates().is_empty():
				s = apply_ok(s, Command.create(Command.REJECT_WIN, {"reason": "weiter"}), "Ablehnung").state
		var night := apply_ok(s, Command.start_night(), "%s: Nacht allein" % role)
		assert_eq(RulesEngine.next_step_id(night.state), "", "%s: kein unbeantwortbarer Schritt" % role)
		var dropped := events_of_type(night.events, "StepDropped")
		assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "no_decision", "%s: protokolliert entfallen" % role)
		apply_ok(night.state, Command.end_night(), "%s: Nacht endet" % role)


# --- Paket 3: feste Szenarien aus gemeinsam genutzten Mechaniken (N-11) ------------------------------------
# Abgeleitet aus Todespipeline, Umlenkung, Siegkandidaten, Wiederbelebung und öffentlicher Todesansage. Jede Prüfung
# nennt die Regelquelle und prüft Reihenfolge und Endzustand; Speichern/Laden und Replay an der kritischen Stelle.
# Gespielt über GameSession mit den Kartendaten (UiGame); den Bedienweg selbst belegen die UI-Rollentests.

const UiGame := preload("res://tests/ui/ui_game.gd")


func _session(roles: Array, appearances: Dictionary = {}) -> GameSession:
	return UiGame.session(roles, 7, appearances)


func _play_until(s: GameSession, answers: Dictionary, kind: String, max_steps: int = 150) -> bool:
	for i: int in max_steps:
		if str(UiGame.next_of(s).get("kind")) == kind:
			return true
		if UiGame.step(s, answers) == "":
			fail("Ablauf blockiert bei %s" % JSON.stringify(UiGame.next_of(s)).left(200))
			return false
	fail("%s nicht erreicht" % kind)
	return false


func _log_types(s: GameSession, types: Array) -> Array:
	return s.event_log().filter(func(e: Dictionary) -> bool: return types.has(str(e["type"]))).map(func(e: Dictionary) -> String: return str(e["type"]))


func _died(s: GameSession) -> Array:
	return s.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "SeatDied").map(func(e: Dictionary) -> int: return int((e["data"] as Dictionary)["target_id"]))


func _session_roundtrip(s: GameSession, label: String) -> void:
	var other := GameSession.new()
	assert_eq(other.load_text(s.save_text()), &"", "%s: Laden" % label)
	assert_eq(other.state_hash(), s.state_hash(), "%s: gleicher Zustand nach Laden" % label)
	assert_eq(RulesEngine.replay(s.commands()).state.content_hash(), s.state_hash(), "%s: Replay gleich" % label)
	assert_eq(JSON.stringify(other.cockpit_view()["next"]), JSON.stringify(s.cockpit_view()["next"]), "%s: gleiche nächste Handlung" % label)


## Umlenkung gegen Immunität: E-12/E-20 (die Puppe stirbt statt des Priesters, mit ursprünglicher Ursache) und RM-DR-119
## (Rudelangriff tötet die Dorfwache nicht). Erwartet: Umlenkung auf die Puppe, dort Immunität, niemand stirbt.
func test_p3_voodoo_doll_is_guard_nobody_dies() -> void:
	var s := _session(["voodoo-priester", "werwolf", "dorfwache", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	if not _play_until(s, {"voodoo-priester/": [3], "pack/": [1]}, "end_night"):
		return
	_session_roundtrip(s, "vor der Morgenauflösung")
	assert_true(s.end_night().ok, "Morgen")
	assert_eq(_died(s), [], "niemand stirbt")
	var prevented := s.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "KillPrevented").map(func(e: Dictionary) -> String: return str((e["data"] as Dictionary)["protection"]))
	assert_eq(prevented, ["voodoo-priester", "dorfwache"], "erst Umlenkung, dann Immunität")


## Mehrere Umlenkungen ohne Schleife: B-04/B-07 (Schattenwanderer lenkt einmal um), jede Person höchstens einmal in einer
## Umlenkungskette (wie E-21). Zwei Schattenwanderer, gegenseitig verknüpft: Der Tod geht genau einmal weiter.
func test_p3_mutual_shadow_links_redirect_once_without_loop() -> void:
	var s := _session(["werwolf", "schattenwanderer", "schattenwanderer", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	s.start_night()
	for guard: int in 30:
		var n := UiGame.next_of(s)
		if str(n.get("kind")) == "end_night":
			break
		if str(n.get("kind")) == "prompt" and str(n.get("owner")) == "schattenwanderer":
			assert_true(s.answer_targets([3] if int((n["actor_ids"] as Array)[0]) == 2 else [2]).ok, "Verknüpfung")
		elif str(n.get("kind")) == "prompt" and str(n.get("owner")) == "pack":
			assert_true(s.answer_targets([2]).ok, "Rudel greift 2 an")
		elif UiGame.step(s) == "":
			fail("blockiert")
			return
	assert_true(s.end_night().ok, "Morgen ohne Endlosschleife")
	assert_eq(_died(s), [3], "nur der Verknüpfte stirbt")
	var st := RulesEngine.replay(s.commands()).state
	assert_true(st.players[2].alive, "angegriffener Schattenwanderer lebt")


## Wirt und Puppe: RM-DR-157 (Parasit stirbt mit dem Wirt) und E-12 (Puppe stirbt statt des Priesters). Der Rudelangriff
## auf den Wirt (Priester) trifft die Puppe; Wirt und Parasit leben.
func test_p3_parasite_host_protected_by_voodoo_doll() -> void:
	var s := _session(["parasit", "voodoo-priester", "dorfbewohner", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	if not _play_until(s, {"parasit/": [2], "voodoo-priester/": [3], "pack/": [2]}, "day"):
		return
	assert_eq(_died(s), [3], "Puppe stirbt")
	var st := RulesEngine.replay(s.commands()).state
	assert_true(st.players[1].alive and st.players[2].alive, "Parasit und Wirt leben")


## Konkurrierende Siege: DR-02 und Decision Log „Siegkandidaten“ (Kandidatenmenge ohne Priorität, Spielleiter bestätigt genau
## einen). Drei Lebende ohne Wolf: Dorf, Voodoo-Priester, Grabräuber und Parasit sind gleichzeitig Kandidaten.
func test_p3_simultaneous_solo_wins_form_one_candidate_set() -> void:
	var s := _session(["parasit", "voodoo-priester", "grabraeuber", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	if not _play_until(s, {"parasit/": [2]}, "end_night"):
		return
	for id: int in [5, 6, 7, 4]:
		assert_true(s.gm_correction({"kind": "kill", "target_id": id, "trigger_effects": false, "reason": "Szenario"}).ok, "%d tot" % id)
	var n := UiGame.next_of(s)
	assert_eq(str(n.get("kind")), "win_decision", "Siegentscheidung")
	var reasons: Array = (n.get("candidates", []) as Array).map(func(c: Dictionary) -> String: return str(c["reason_key"]))
	reasons.sort()
	assert_eq(reasons, ["grave_robber_final_three", "no_wolves_alive", "parasite_final_three", "voodoo_final_three"], "vier Kandidaten ohne Priorität")
	_session_roundtrip(s, "offene Kandidaten")
	var chosen := int(((n["candidates"] as Array).filter(func(c: Dictionary) -> bool: return str(c["reason_key"]) == "voodoo_final_three")[0] as Dictionary)["id"])
	assert_true(s.confirm_win(chosen).ok, "Spielleitung bestätigt genau einen")
	assert_eq(str(UiGame.next_of(s).get("kind")), "game_over", "Spielende")
	assert_eq(str(((UiGame.next_of(s)["winner"] as Dictionary)["reason_key"])), "voodoo_final_three", "gewählter Sieger")


## Private Information gegen öffentliche Todesansage: DI-08 (Scheinrolle nur für Rollenauskünfte) und DR-04/Entscheidung
## 29.09.2026 (Rolle beim Tod nur in Runden ohne Wiederbelebung). Öffentlich erscheint die wahre Rolle, nie die Scheinrolle;
## beim Grabräuber die eigene Rolle, nicht die gestohlene Fähigkeit.
func test_p3_public_death_names_true_role_not_appearance_or_stolen_ability() -> void:
	var s := _session(["trugbilderwolf", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], {"1": "das-orakel"})
	if not _play_until(s, {}, "day"):
		return
	assert_true(s.nominate(3, 1).ok and s.decide_execution(1).ok, "Trugbilderwolf gehängt")
	var deaths := s.day_deaths()
	assert_eq(str((deaths[0] as Dictionary)["role_id"]), "trugbilderwolf", "wahre Rolle")
	assert_false(JSON.stringify(deaths).contains("das-orakel"), "keine Scheinrolle")
	var g := _session(["grabraeuber", "werwolf", "das-orakel", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	assert_true(g.gm_correction({"kind": "kill", "target_id": 3, "trigger_effects": false, "reason": "Szenario"}).ok, "Orakel tot")
	if not _play_until(g, {"grabraeuber/targets": [3]}, "day"):
		return
	assert_true(g.nominate(4, 1).ok and g.decide_execution(1).ok, "Grabräuber gehängt")
	assert_eq(str((g.day_deaths()[0] as Dictionary)["role_id"]), "grabraeuber", "eigene Rolle, nicht die gestohlene")


## Kettentod und Todesreaktion: Loki-Liebeskummer (B-01/B-02) trifft einen Sensenträger, dessen Reaktion (DR-09) folgt erst
## danach; öffentliche Effekte in dieser Reihenfolge (DA-23), Siegprüfung erst nach der Reaktion (DR-14). Speichern mit
## offener Reaktion setzt identisch fort.
func test_p3_heartbreak_then_reaper_reaction_in_order_with_save_load() -> void:
	var s := _session(["loki", "werwolf", "werwolf", "sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	if not _play_until(s, {"loki/targets": [4, 5], "loki/mode": true, "pack/": [5]}, "end_night"):
		return
	assert_true(s.end_night().ok, "Morgen")
	var n := UiGame.next_of(s)
	assert_eq([str(n.get("kind")), str(n.get("reaction_kind"))], ["begin_step", "curse"], "Reaktion des Sensenträgers offen")
	assert_eq(_died(s), [5, 4], "erst das Opfer, dann der Liebeskummer")
	_session_roundtrip(s, "offene Reaktion")
	assert_true(s.begin_next_step().ok and s.answer_targets([2]).ok, "Sensenträger reißt Wolf 2")
	assert_eq(_died(s), [5, 4, 2], "Reaktion nach der Kette")
	var effects: Array = s.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "DeathEffect").map(func(e: Dictionary) -> String: return str((e["data"] as Dictionary)["effect"]))
	assert_eq(effects.size(), 2, "zwei angesagte Effekte: %s" % str(effects))
	assert_eq(str(effects[0]) if not effects.is_empty() else "", "heartbreak", "Liebeskummer zuerst angesagt")


## Wiederbelebung und verbrauchte Fähigkeit: W-02/W-03 (Kutscher belebt drei Tote, einer wird Werwolf) und „Wiederbelebung
## setzt alle begrenzten Einsätze zurück“ (Decision Log W). Eine Kriegerin, die ihren Angriff verbraucht hat und starb,
## hat nach der Wiederbelebung (ohne Wolfswahl) im nächsten Leben wieder ihren Schritt.
func test_p3_coach_revival_restores_one_shot_ability() -> void:
	var roles: Array = ["kutscher", "werwolf", "werwolf", "kriegerin-des-lichts"]
	for i: int in 20:
		roles.append("dorfbewohner")
	var s := _session(roles)
	if not _play_until(s, {"kriegerin-des-lichts/targets": [5]}, "day"):
		return
	var st := RulesEngine.replay(s.commands()).state
	assert_false(st.players[4].alive, "Kriegerin nach Irrtum tot")
	assert_true(InfoSteps.used(st.players[4], InfoSteps.WARRIOR_USE_KEY), "Angriff verbraucht")
	for id: int in [6, 7, 8, 9, 10, 11, 12, 13, 14]:
		assert_true(s.gm_correction({"kind": "kill", "target_id": id, "trigger_effects": false, "reason": "Szenario"}).ok, "%d tot" % id)
	if not _play_until(s, {}, "start_night") or not s.start_night().ok:
		return
	if not _play_until(s, {"kutscher/targets": [4, 6, 7], "kutscher/wolf": [6]}, "day"):
		return
	st = RulesEngine.replay(s.commands()).state
	assert_true(st.players[4].alive, "Kriegerin wiederbelebt")
	assert_eq(st.players[4].role_id, &"kriegerin-des-lichts", "behält ihre Rolle (nicht zum Wolf gewählt)")
	assert_false(InfoSteps.used(st.players[4], InfoSteps.WARRIOR_USE_KEY), "Einsatz zurückgesetzt")
	assert_eq(st.players[6].role_id, &"werwolf", "gewählte Person wird Werwolf")
	_session_roundtrip(s, "nach Wiederbelebung")
	assert_true(_play_until(s, {}, "start_night") and s.start_night().ok, "nächste Nacht")
	var steps: Array = RulesEngine.replay(s.commands()).state.night_plan.map(func(k: StringName) -> String: return String(k))
	assert_true(steps.any(func(k: String) -> bool: return k.contains("kriegerin-des-lichts")), "Kriegerin hat wieder einen Schritt")


## Rollenwechsel gegen Geheimnis: DI-08 (die Scheinrolle kennt nur die Spielleitung) und V-04 bis V-06 (Seelentausch mit
## frischen Rollen). Der Seelentauscher tauscht einen Trugbilderwolf mit einer Dorfperson: Die Scheinrolle geht mit der Rolle
## über; kein Hinweis an eine Person (actor) und kein öffentliches Ereignis nennt sie.
func test_p3_soul_swap_moves_appearance_without_telling_anyone() -> void:
	var s := _session(["seelentauscher", "trugbilderwolf", "dorfbewohner", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner"], {"2": "das-orakel"})
	if not _play_until(s, {"seelentauscher/targets": [2, 3]}, "end_night"):
		return
	var st := RulesEngine.replay(s.commands()).state
	assert_eq([st.players[3].role_id, st.players[3].appears_as], [&"trugbilderwolf", &"das-orakel"], "Scheinrolle geht mit der Rolle über")
	assert_eq(st.players[2].role_id, &"dorfbewohner", "Tauschpartner wird Dorfbewohner")
	var told := s.event_log().filter(func(e: Dictionary) -> bool: return str(e["visibility"]) in ["actor", "public"])
	assert_true(told.any(func(e: Dictionary) -> bool: return str(e["type"]) == "SoulSwapRevealed"), "Betroffene erfahren ihre neue Rolle")
	for e: Dictionary in told:
		assert_false(JSON.stringify(e["data"]).contains("das-orakel"), "%s nennt keine Scheinrolle" % str(e["type"]))
