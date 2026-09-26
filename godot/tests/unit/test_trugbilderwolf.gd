extends TestCase
## Produktionsrolle `trugbilderwolf` (Decoy Wolf), rules-register.md §5, DR-08.
## B6T: 1 Werwolf; 2 Trugbilderwolf (Scheinrolle waldhexe); 3 Schutzengel; 4 Orakel;
##      5 Waldhexe; 6 Dorfbewohner (B6 aus acceptance-scenarios.md).
## Nacht 1 in B6T: Prompt 1 Schutzengel, 2 Rudel, 3 Waldhexe, 4 Orakel.
## Neue Setup-Felder: `appearances` {"<id>": Scheinrolle} (manuell) und
## `role_entries` [{role_id, appears_as?}] (zufällig, Rolle und Scheinrolle gekoppelt).

const PACK_1 := "night:1:1:pack"
const WITCH_1 := "night:1:2:waldhexe:5"
const ORACLE_1 := "night:1:3:das-orakel:4"
const B6_ROLES := ["werwolf", "trugbilderwolf", "schutzengel", "das-orakel", "waldhexe", "dorfbewohner"]


func _manual(roles: Array, appearances: Dictionary, seed_value: int = 1) -> Command:
	var payload := Fixtures.start_roles(roles, seed_value).payload.duplicate(true)
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


func _random(entries: Array, seed_value: int = 1) -> Command:
	return Command.start_game({
		"round_id": "test-round", "seed": seed_value, "assignment": "random",
		"players": Fixtures.players(entries.size()), "seat_order": Fixtures.identity_order(entries.size()), "role_entries": entries,
	})


func _b6t(appearance: String = "waldhexe") -> Command:
	return _manual(B6_ROLES, {"2": appearance})


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## Eine Nacht in B6T ohne Rudelopfer: Schutz auf 5, Waldhexe verzichtet, Orakel prüft `target`.
## `first_prompt` = ID des Schutzengel-Prompts dieser Nacht.
func _night(n: int, first_prompt: int, target: int, override_role: String = "") -> Array[Command]:
	var out: Array[Command] = [Command.start_night(), Command.answer_prompt(first_prompt, [5]),
		Command.begin_step("night:%d:1:pack" % n), Command.answer_prompt(first_prompt + 1, []),
		Command.begin_step("night:%d:2:waldhexe:5" % n), Command.answer_choice(first_prompt + 2, "poison", false),
		Command.answer_choice(first_prompt + 2, "confirm", true), Command.begin_step("night:%d:3:das-orakel:4" % n),
		Command.answer_stage_targets(first_prompt + 3, "target", [target])]
	if override_role != "":
		out.append(Command.override_shown_role(first_prompt + 3, override_role, "Spielleiter übersteuert"))
	out.append(Command.answer_choice(first_prompt + 3, "shown", true))
	return out


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _records(s: GameState) -> Array:
	return s.to_dict().get("info_records", [])


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


## Ablehnung beim Spielaufbau: kein Zustand, kein RNG-Fortschritt, keine Ereignisse.
func _setup_rejected(c: Command, error: String, label: String) -> void:
	var r := RulesEngine.apply(GameState.new(), c)
	assert_true(r.events.is_empty(), "%s: keine Ereignisse" % label)
	apply_rejected(GameState.new(), c, error, label)


# --- 1–5 Rolle und Nacht ------------------------------------------------------------------

func test_production_role() -> void:
	# 1, 2, 6
	var r := apply_ok(GameState.new(), _b6t(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	var p := r.state.players[2]
	assert_eq(String(p.role_id), "trugbilderwolf", "tatsächliche Rolle")
	assert_eq(String(p.original_role_id), "trugbilderwolf", "Ausgangsrolle")
	assert_eq(String(p.faction), "wolves", "Fraktion Werwölfe")
	assert_true(p.counts_as_wolf, "zählt als Wolf")
	assert_eq(String(p.appears_as), "waldhexe", "Scheinrolle aus dem Spielaufbau")
	assert_eq(String(r.state.players[6].appears_as), "dorfbewohner", "andere Personen normal")


func test_no_personal_night_step() -> void:
	# 3
	var run := _replay_ok([_b6t(), Command.start_night()] as Array[Command], "Nacht 1")
	if run.ok:
		assert_eq(run.state.night_plan, [&"schutzengel:3", &"pack", &"waldhexe:5", &"das-orakel:4"] as Array[StringName], "nur Rudelschritt")


func test_alone_creates_pack_step() -> void:
	# 4
	var start := _manual(["trugbilderwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], {"1": "dorfbewohner"})
	var run := _replay_ok([start, Command.start_night()] as Array[Command], "einziger Wolf")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack"] as Array[StringName], "Rudelschritt existiert")
		assert_eq(String(run.state.pending_prompt.owner), "pack", "Rudel wählt")


func test_takes_part_in_pack_with_werewolves() -> void:
	# 5: Nach Hinrichtung des Werwolfs bleibt der Trugbilderwolf das Rudel.
	var commands := _concat([_b6t()] as Array[Command], _night(1, 1, 6))
	commands.append_array([Command.end_night(), Command.nominate(3, 1), Command.decide_execution(1), Command.end_day(), Command.start_night()] as Array[Command])
	var run := _replay_ok(commands, "Nacht 2 ohne Werwolf")
	if run.ok:
		assert_false(run.state.players[1].alive, "Werwolf tot")
		assert_true(run.state.night_plan.has(&"pack"), "Rudelschritt durch den Trugbilderwolf")


# --- 6–13 Spielaufbau ----------------------------------------------------------------------

func test_manual_setup_validation() -> void:
	# 7–10
	_setup_rejected(_manual(B6_ROLES, {}), "appearance_required", "ohne Scheinrolle")
	for bad: String in ["werwolf", "trugbilderwolf"]:
		_setup_rejected(_b6t(bad), "invalid_appearance", "Wolfsrolle %s" % bad)
	for bad: String in ["unbekannt", "test-sensentraeger", "", "spiegelwolf"]:
		_setup_rejected(_b6t(bad), "invalid_appearance", "Scheinrolle '%s'" % bad)
	_setup_rejected(_manual(B6_ROLES, {"2": 5}), "invalid_appearance", "keine Zeichenkette")
	_setup_rejected(_manual(B6_ROLES, {"2": "waldhexe", "6": "schutzengel"}), "appearance_not_allowed", "Eintrag für Dorfbewohner")
	_setup_rejected(_manual(B6_ROLES, {"2": "waldhexe", "99": "schutzengel"}), "appearance_not_allowed", "unbekannte Person")
	var mixed := _b6t().payload.duplicate(true)
	mixed["role_entries"] = [{"role_id": "werwolf"}]
	_setup_rejected(Command.start_game(mixed), "invalid_assignment", "manuell mit role_entries")
	# Rolle, die in der Partie nicht vorkommt, ist als Scheinrolle erlaubt.
	apply_ok(GameState.new(), _b6t("sensentraeger"), "Scheinrolle ohne Rolleninhaber")


func test_random_setup_validation() -> void:
	# Zufällige Rolleninstanz mit ungültiger Konfiguration
	var d := {"role_id": "dorfbewohner"}
	_setup_rejected(_random([{"role_id": "trugbilderwolf"}, d, d, d, d, d]), "appearance_required", "ohne Scheinrolle")
	_setup_rejected(_random([{"role_id": "trugbilderwolf", "appears_as": "werwolf"}, d, d, d, d, d]), "invalid_appearance", "Wolfsrolle")
	_setup_rejected(_random([{"role_id": "trugbilderwolf", "appears_as": "trugbilderwolf"}, d, d, d, d, d]), "invalid_appearance", "sich selbst")
	_setup_rejected(_random([{"role_id": "trugbilderwolf", "appears_as": ""}, d, d, d, d, d]), "invalid_appearance", "leer")
	_setup_rejected(_random([{"role_id": "werwolf"}, {"role_id": "dorfbewohner", "appears_as": "waldhexe"}, d, d, d, d]), "appearance_not_allowed", "Scheinrolle für Dorfbewohner")
	_setup_rejected(_random([{"role_id": "werwolf", "extra": 1}, d, d, d, d, d]), "invalid_role_entry", "unbekanntes Feld")
	_setup_rejected(_random(["werwolf", d, d, d, d, d]), "invalid_role_entry", "kein Eintrag")
	_setup_rejected(_random([{"appears_as": "waldhexe"}, d, d, d, d, d]), "invalid_role_entry", "ohne role_id")
	var pool := Fixtures.start_random(6, 1, 1).payload.duplicate(true)
	pool["role_pool"] = ["trugbilderwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
	_setup_rejected(Command.start_game(pool), "appearance_required", "role_pool ohne Kopplung")
	var both := _random([{"role_id": "werwolf"}, d, d, d, d, d]).payload.duplicate(true)
	both["role_pool"] = ["werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
	_setup_rejected(Command.start_game(both), "invalid_assignment", "role_pool und role_entries")
	var appearances := _random([{"role_id": "werwolf"}, d, d, d, d, d]).payload.duplicate(true)
	appearances["appearances"] = {"1": "waldhexe"}
	_setup_rejected(Command.start_game(appearances), "invalid_assignment", "appearances bei Zufall")


func test_random_setup_couples_role_and_appearance() -> void:
	# 11, 12
	var d := {"role_id": "dorfbewohner"}
	var single := [{"role_id": "trugbilderwolf", "appears_as": "waldhexe"}, d, d, d, d, {"role_id": "werwolf"}]
	var holders := {}
	for seed_value: int in range(1, 21):
		var s := Fixtures.play([_random(single, seed_value)] as Array[Command])
		assert_true(s != null, "Seed %d angenommen" % seed_value)
		if s == null:
			continue
		for id: int in s.players:
			var p := s.players[id]
			if p.role_id == &"trugbilderwolf":
				holders[id] = true
				assert_eq(String(p.appears_as), "waldhexe", "Seed %d: Scheinrolle bei ihrer Instanz" % seed_value)
			else:
				assert_eq(p.appears_as, p.role_id, "Seed %d: keine Scheinrolle bei %d" % [seed_value, id])
	assert_true(holders.size() > 1, "verschiedene Seeds geben die Rolle an verschiedene Personen")
	var double := [{"role_id": "trugbilderwolf", "appears_as": "waldhexe"}, {"role_id": "trugbilderwolf", "appears_as": "schutzengel"}, d, d, d, {"role_id": "das-orakel"}]
	for seed_value: int in [3, 11]:
		var a := Fixtures.play([_random(double, seed_value)] as Array[Command])
		var b := Fixtures.play([_random(double, seed_value)] as Array[Command])
		assert_eq(_json(a.to_dict()), _json(b.to_dict()), "Seed %d: identische Zuordnung" % seed_value)
		var seen: Array[String] = []
		for id: int in a.players:
			if a.players[id].role_id == &"trugbilderwolf":
				seen.append(String(a.players[id].appears_as))
		seen.sort()
		assert_eq(seen, ["schutzengel", "waldhexe"] as Array[String], "Seed %d: beide Scheinrollen je Instanz" % seed_value)


func test_random_compatibility_and_replay() -> void:
	# 13: role_entries ohne Scheinrolle verteilt wie role_pool; Replay bytegleich.
	var pool_state := Fixtures.play([Fixtures.start_random(8, 2, 4711)] as Array[Command])
	var entries: Array = []
	for i: int in 8:
		entries.append({"role_id": "werwolf" if i < 2 else "dorfbewohner"})
	var entry_state := Fixtures.play([_random(entries, 4711)] as Array[Command])
	for id: int in pool_state.players:
		assert_eq(entry_state.players[id].role_id, pool_state.players[id].role_id, "gleiche Verteilung für Person %d" % id)
	var commands: Array[Command] = [_random([{"role_id": "trugbilderwolf", "appears_as": "waldhexe"}, {"role_id": "werwolf"}, {"role_id": "schutzengel"},
		{"role_id": "das-orakel"}, {"role_id": "dorfbewohner"}, {"role_id": "dorfbewohner"}], 99), Command.start_night()]
	var a := RulesEngine.replay(commands)
	var b := RulesEngine.replay(commands)
	assert_eq(events_json(a.events), events_json(b.events), "Ereignisse bytegleich")
	assert_eq(_json(a.state.to_dict()), _json(b.state.to_dict()), "Zustand bytegleich")


# --- 14–19 Orakel und Waldhexe ----------------------------------------------------------------

func test_two_decoys_keep_own_appearance() -> void:
	# 14
	var start := _manual(["trugbilderwolf", "trugbilderwolf", "dorfbewohner", "das-orakel", "dorfbewohner", "dorfbewohner"], {"1": "waldhexe", "2": "schutzengel"})
	var s := Fixtures.play([start, Command.start_night()] as Array[Command])
	assert_eq(s.night_plan, [&"pack", &"das-orakel:4"] as Array[StringName], "ein gemeinsamer Rudelschritt")
	assert_true(s.players[1].counts_as_wolf and s.players[2].counts_as_wolf, "beide zählen als Wolf")
	s = apply_ok(apply_ok(s, Command.answer_prompt(1, []), "Rudel").state, Command.begin_step("night:1:1:das-orakel:4"), "Orakel").state
	var first := apply_ok(s, Command.answer_stage_targets(2, "target", [1]), "prüft 1").state
	var second := apply_ok(s, Command.answer_stage_targets(2, "target", [2]), "prüft 2").state
	assert_eq(str(first.pending_prompt.partial["determined_role"]), "waldhexe", "Scheinrolle von 1")
	assert_eq(str(second.pending_prompt.partial["determined_role"]), "schutzengel", "Scheinrolle von 2")
	assert_eq(str(second.pending_prompt.partial["truth_role"]), "trugbilderwolf", "Wahrheit")


func test_oracle_information() -> void:
	# 15, 16, 17, AS-R11
	var run := _replay_ok(_concat([_b6t()] as Array[Command], _night(1, 1, 2)), "Orakel prüft 2")
	if not run.ok:
		return
	var rec: Dictionary = _records(run.state)[0] if _records(run.state).size() == 1 else {}
	assert_true(str(rec.get("truth_role")) == "trugbilderwolf" and str(rec.get("determined_role")) == "waldhexe" and str(rec.get("shown_role")) == "waldhexe"
		and not bool(rec.get("overridden", true)), "Wahrheit, ermittelt, gezeigt")
	assert_eq(run.state.rng.draws, 0, "keine Zufallsziehung")
	var revealed := events_of_type(run.events, "InfoRevealed")
	assert_true(revealed.size() == 1 and revealed[0].actor_id == 4 and str(revealed[0].data["shown_role"]) == "waldhexe"
		and not _json(revealed[0].data).contains("trugbilderwolf"), "Orakel sieht nur die Scheinrolle")
	var audit := events_of_type(run.events, "InfoRecorded")
	assert_true(audit.size() == 1 and String(audit[0].visibility) == "gm" and str(audit[0].data["info"]["truth_role"]) == "trugbilderwolf"
		and str(audit[0].data["info"]["determined_role"]) == "waldhexe", "GM-Audit vollständig")


func test_oracle_override_only_shown() -> void:
	# 18, AS-R12
	var run := _replay_ok(_concat([_b6t()] as Array[Command], _night(1, 1, 2, "werwolf")), "Übersteuerung")
	if not run.ok:
		return
	var rec: Dictionary = _records(run.state)[0]
	assert_true(str(rec["truth_role"]) == "trugbilderwolf" and str(rec["determined_role"]) == "waldhexe" and str(rec["shown_role"]) == "werwolf"
		and bool(rec["overridden"]), "nur gezeigt geändert")
	var revealed := events_of_type(run.events, "InfoRevealed")
	assert_true(revealed.size() == 1 and not _json(revealed[0].data).contains("waldhexe") and not _json(revealed[0].data).contains("trugbilderwolf"), "keine Wahrheit, kein ermitteltes Ergebnis")


func test_witch_sees_true_role() -> void:
	# 19
	var s := Fixtures.play([_b6t(), Command.start_night(), Command.answer_prompt(1, [5]), Command.begin_step(PACK_1), Command.answer_prompt(2, [2]),
		Command.begin_step(WITCH_1), Command.answer_choice(3, "heal", true)] as Array[Command])
	assert_true(s != null and s.pending_prompt != null, "Waldhexe rettet 2")
	if s != null and s.pending_prompt != null:
		assert_eq(str(s.pending_prompt.partial.get("victim_role", "")), "trugbilderwolf", "tatsächliche Rolle")


# --- 20–21 Sieg ---------------------------------------------------------------------------------

func test_parity_counts_decoy() -> void:
	# 20: Nacht 1 stirbt 6, Tag 1 wird 3 hingerichtet: 2 Wölfe gegen 2.
	var night: Array[Command] = [_b6t(), Command.start_night(), Command.answer_prompt(1, [5]), Command.begin_step(PACK_1), Command.answer_prompt(2, [6]),
		Command.begin_step(WITCH_1), Command.answer_choice(3, "heal", false), Command.answer_choice(3, "poison", false), Command.answer_choice(3, "confirm", true),
		Command.begin_step(ORACLE_1), Command.answer_stage_targets(4, "target", [3]), Command.answer_choice(4, "shown", true), Command.end_night(),
		Command.nominate(4, 3), Command.decide_execution(3)]
	var run := _replay_ok(night, "Parität")
	if run.ok:
		assert_true(run.state.win_candidate != null and String(run.state.win_candidate.kind) == "wolves", "Wolfssieg durch Parität")
		assert_eq(int(run.state.win_candidate.reason_args["wolves"]), 2, "Trugbilderwolf zählt als Wolf")


func test_last_decoy_dies_village_wins() -> void:
	# 21
	var start := _manual(["trugbilderwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], {"1": "dorfbewohner"})
	var run := _replay_ok([start, Command.start_night(), Command.answer_prompt(1, []), Command.end_night(), Command.nominate(2, 1),
		Command.decide_execution(1)] as Array[Command], "letzter Wolf")
	if run.ok:
		assert_true(run.state.win_candidate != null and String(run.state.win_candidate.kind) == "village", "Dorfsieg")


# --- 22–30 Korrekturen ----------------------------------------------------------------------------

func test_correct_appearance() -> void:
	# 22–24, AS-R13
	var s := Fixtures.play([_b6t()] as Array[Command])
	var r := apply_ok(s, CorrectionFixtures.gm("set_role_field", {"target_id": 2, "field": "appears_as", "value": "dorfbewohner"}, "Scheinrolle geändert"), "gültig")
	var logged := events_of_type(r.events, "GmCorrected")
	assert_true(logged.size() == 1 and str(logged[0].data["old"]["appears_as"]) == "waldhexe" and str(logged[0].data["new"]["appears_as"]) == "dorfbewohner", "alter und neuer Wert")
	for bad: String in ["werwolf", "trugbilderwolf", "unbekannt", "test-sensentraeger", ""]:
		apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 2, "field": "appears_as", "value": bad}), "invalid_value", "Scheinrolle '%s'" % bad)
	apply_rejected(s, Command.gm_correction({"kind": "set_role_field", "target_id": 2, "field": "appears_as", "value": "dorfbewohner", "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, CorrectionFixtures.gm("set_role_field", {"target_id": 2, "field": "appears_as", "value": "dorfbewohner"}, ""), "reason_required", "ohne Begründung")


## Nacht 1 prüft das Orakel 2, am Tag wird die Scheinrolle korrigiert, Nacht 2 prüft erneut.
func _correction_across_nights() -> Array[Command]:
	var commands := _concat([_b6t()] as Array[Command], _night(1, 1, 2))
	commands.append_array([Command.end_night(),
		CorrectionFixtures.gm("set_role_field", {"target_id": 2, "field": "appears_as", "value": "dorfbewohner"}, "Scheinrolle geändert"),
		Command.decide_execution(-1), Command.end_day()] as Array[Command])
	commands.append_array(_night(2, 5, 2))
	return commands


func test_correction_affects_only_later_checks() -> void:
	# 25, 26, 33
	var commands := _correction_across_nights()
	var run := _replay_ok(commands, "zwei Nächte")
	if not run.ok:
		return
	var records := _records(run.state)
	assert_eq(records.size(), 2, "zwei Informationen")
	if records.size() == 2:
		assert_eq(str(records[0]["determined_role"]), "waldhexe", "alte Information unverändert")
		assert_eq(str(records[1]["determined_role"]), "dorfbewohner", "spätere Prüfung mit neuer Scheinrolle")
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "Laden mit historischer Information (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(_json(loaded.state.to_dict()), _json(run.state.to_dict()), "vollständiger Zustand")
	var mid := commands.slice(0, _concat([_b6t()] as Array[Command], _night(1, 1, 2)).size() + 2)
	var mid_loaded := StateCodec.decode(StateCodec.encode(Fixtures.play(mid), mid))
	assert_true(mid_loaded.ok and String(mid_loaded.state.players[2].appears_as) == "dorfbewohner", "Save/Load direkt nach der Korrektur")


func test_correction_cancels_open_oracle_prompt() -> void:
	var commands := _concat([_b6t()] as Array[Command], _night(1, 1, 2))
	commands.resize(commands.size() - 1)  # vor „Gezeigt“
	var s := Fixtures.play(commands)
	var r := apply_ok(s, CorrectionFixtures.gm("set_role_field", {"target_id": 2, "field": "appears_as", "value": "dorfbewohner"}), "Korrektur bei offener Prüfung")
	assert_eq(events_of_type(r.events, "PromptCancelled").size(), 1, "kein widersprüchlicher Prompt")
	var again := apply_ok(apply_ok(r.state, Command.begin_step(ORACLE_1), "neu").state, Command.answer_stage_targets(5, "target", [2]), "erneut prüfen").state
	assert_eq(str(again.pending_prompt.partial["determined_role"]), "dorfbewohner", "neue Scheinrolle")


func test_set_role_to_decoy() -> void:
	# 27, 28, 30
	var s := Fixtures.play([_b6t()] as Array[Command])
	apply_rejected(s, CorrectionFixtures.gm("set_role", {"target_id": 6, "role_id": "trugbilderwolf"}), "appearance_required", "ohne Scheinrolle")
	apply_rejected(s, CorrectionFixtures.gm("set_role", {"target_id": 6, "role_id": "trugbilderwolf", "appears_as": "werwolf"}), "invalid_appearance", "Wolfsrolle")
	apply_rejected(s, CorrectionFixtures.gm("set_role", {"target_id": 6, "role_id": "schutzengel", "appears_as": "waldhexe"}), "appearance_not_allowed", "Scheinrolle für andere Rolle")
	var r := apply_ok(s, CorrectionFixtures.gm("set_role", {"target_id": 6, "role_id": "trugbilderwolf", "appears_as": "das-orakel"}), "wird Trugbilderwolf")
	var p := r.state.players[6]
	assert_true(p.role_id == &"trugbilderwolf" and p.faction == &"wolves" and p.counts_as_wolf and p.appears_as == &"das-orakel", "alle Rollenfelder gemeinsam")
	var logged := events_of_type(r.events, "GmCorrected")
	assert_true(logged.size() == 1 and str(logged[0].data["new"]["appears_as"]) == "das-orakel" and bool(logged[0].data["new"]["counts_as_wolf"]), "protokolliert")
	# 30: 3 Wölfe gegen 3 Nicht-Wölfe → Paritätskandidat nach der Rollenänderung.
	assert_true(r.state.win_candidate != null and String(r.state.win_candidate.kind) == "wolves", "Siegprüfung mit neuem Wolfsstatus")


func test_set_role_away_from_decoy() -> void:
	# 29, 30
	var start := _manual(["trugbilderwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"], {"1": "waldhexe"})
	var r := apply_ok(Fixtures.play([start] as Array[Command]), CorrectionFixtures.gm("set_role", {"target_id": 1, "role_id": "dorfbewohner"}), "kein Trugbilderwolf mehr")
	var p := r.state.players[1]
	assert_true(p.role_id == &"dorfbewohner" and p.appears_as == &"dorfbewohner" and not p.counts_as_wolf and p.faction == &"village", "normale Erscheinung")
	assert_true(r.state.win_candidate != null and String(r.state.win_candidate.kind) == "village", "kein Wolf mehr: Dorfsieg-Kandidat")


# --- 31–34 Save/Load und Replay ---------------------------------------------------------------------

func _roundtrip(commands: Array[Command], label: String) -> LoadResult:
	var run := _replay_ok(commands, label)
	if not run.ok:
		return null
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Laden (%s %s)" % [label, loaded.error, loaded.detail])
	if loaded.ok:
		assert_eq(_json(loaded.state.to_dict()), _json(run.state.to_dict()), "%s: vollständiger Zustand" % label)
		assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: State-Hash" % label)
	return loaded if loaded.ok else null


func test_save_load_points() -> void:
	# 31, 32
	var after_setup := _roundtrip([_b6t()] as Array[Command], "nach Setup")
	if after_setup != null:
		assert_eq(String(after_setup.state.players[2].appears_as), "waldhexe", "Scheinrolle geladen")
	var checked := _concat([_b6t()] as Array[Command], _night(1, 1, 2))
	var after_check := _roundtrip(checked, "nach Orakelprüfung")
	if after_check != null:
		var a := RulesEngine.apply(Fixtures.play(checked), Command.end_night())
		var b := RulesEngine.apply(after_check.state, Command.end_night())
		assert_eq(events_json(b.events), events_json(a.events), "identische Fortsetzung")


func test_replay_two_decoys() -> void:
	# 34
	var manual := _manual(["trugbilderwolf", "trugbilderwolf", "dorfbewohner", "das-orakel", "dorfbewohner", "dorfbewohner"], {"1": "waldhexe", "2": "schutzengel"})
	var random := _random([{"role_id": "trugbilderwolf", "appears_as": "waldhexe"}, {"role_id": "trugbilderwolf", "appears_as": "schutzengel"},
		{"role_id": "dorfbewohner"}, {"role_id": "das-orakel"}, {"role_id": "dorfbewohner"}, {"role_id": "dorfbewohner"}], 5)
	for start: Command in [manual, random]:
		var commands: Array[Command] = [start, Command.start_night()]
		var loaded := _roundtrip(commands, "zwei Trugbilderwölfe")
		var a := RulesEngine.replay(commands)
		assert_eq(events_json(a.events), events_json(RulesEngine.replay(commands).events), "Replay bytegleich")
		if loaded != null:
			for id: int in a.state.players:
				assert_eq(loaded.state.players[id].appears_as, a.state.players[id].appears_as, "Scheinrolle von %d nicht vertauscht" % id)


# --- 35–37 Beschädigte Spielstände ---------------------------------------------------------------------

## Manipuliert Zustand (und optional das Dokument) eines gültigen Spielstands; Hash und Integrität erneuert.
func _tampered(commands: Array[Command], mutate_state: Callable, mutate_doc: Callable = Callable()) -> LoadResult:
	var doc: Dictionary = CanonicalJson.normalize(JSON.parse_string(StateCodec.encode(Fixtures.play(commands), commands)))
	var body: Dictionary = doc["state"]
	if mutate_state.is_valid():
		mutate_state.call(body)
	if mutate_doc.is_valid():
		mutate_doc.call(doc)
	var hashed := body.duplicate(true)
	for key: String in GameState.HASH_EXCLUDED_KEYS:
		hashed.erase(key)
	doc["state_hash"] = CanonicalJson.sha256(hashed)
	doc.erase("integrity")
	doc["integrity"] = CanonicalJson.sha256(doc)
	return StateCodec.decode(CanonicalJson.stringify(doc))


func _expect_load_error(result: LoadResult, expected: String, label: String) -> void:
	assert_false(result.ok, "%s: nicht geladen" % label)
	assert_eq(String(result.error), expected, "%s: Fehlergrund" % label)
	assert_true(result.state == null, "%s: kein teilweise geladener Zustand" % label)


func test_corrupt_saves_rejected() -> void:
	var base: Array[Command] = [_b6t(), Command.start_night()]
	var none := Callable()
	_expect_load_error(_tampered(base, func(st: Dictionary) -> void: st["players"][0]["name"] = "Z"), "replay_mismatch", "Kontrolle")
	var state_cases := {
		"leere Scheinrolle": func(st: Dictionary) -> void: st["players"][1]["appears_as"] = "",
		"unbekannte Scheinrolle": func(st: Dictionary) -> void: st["players"][1]["appears_as"] = "unbekannt",
		"Wolfsrolle als Scheinrolle": func(st: Dictionary) -> void: st["players"][1]["appears_as"] = "werwolf",
		"sich selbst als Scheinrolle": func(st: Dictionary) -> void: st["players"][1]["appears_as"] = "trugbilderwolf",
		"Nicht-Trugbilderwolf mit unbekannter Erscheinung": func(st: Dictionary) -> void: st["players"][5]["appears_as"] = "unbekannt",
	}
	for label: String in state_cases:
		_expect_load_error(_tampered(base, state_cases[label]), "state_invalid", label)
	# Setup-Daten im gespeicherten Befehl: falsche Person, verlorene Kopplung, Vertauschung.
	_expect_load_error(_tampered(base, none, func(doc: Dictionary) -> void: doc["commands"][0]["payload"]["appearances"]["6"] = "schutzengel"),
		"replay_rejected", "Scheinrolle für Dorfbewohner im Setup")
	var two: Array[Command] = [_random([{"role_id": "trugbilderwolf", "appears_as": "waldhexe"}, {"role_id": "trugbilderwolf", "appears_as": "schutzengel"},
		{"role_id": "dorfbewohner"}, {"role_id": "das-orakel"}, {"role_id": "dorfbewohner"}, {"role_id": "dorfbewohner"}], 5)]
	_expect_load_error(_tampered(two, none, func(doc: Dictionary) -> void: (doc["commands"][0]["payload"]["role_entries"][0] as Dictionary).erase("appears_as")),
		"replay_rejected", "Kopplung verloren")
	_expect_load_error(_tampered(two, none, func(doc: Dictionary) -> void:
		doc["commands"][0]["payload"]["role_entries"][0]["appears_as"] = "schutzengel"
		doc["commands"][0]["payload"]["role_entries"][1]["appears_as"] = "waldhexe"), "replay_mismatch", "vertauschte Scheinrollen im Setup")
	_expect_load_error(_tampered(two, func(st: Dictionary) -> void:
		var decoys: Array = []
		for p: Dictionary in st["players"]:
			if p["role_id"] == "trugbilderwolf":
				decoys.append(p)
		var tmp: Variant = decoys[0]["appears_as"]
		decoys[0]["appears_as"] = decoys[1]["appears_as"]
		decoys[1]["appears_as"] = tmp), "replay_mismatch", "vertauschte Scheinrollen im Zustand")


# --- 38–39 Sichtbarkeit --------------------------------------------------------------------------------

func test_no_appearance_leaks() -> void:
	# Scheinrolle sensentraeger kommt sonst in der Partie nicht vor.
	var commands := _concat([_b6t("sensentraeger")] as Array[Command], _night(1, 1, 6))
	commands.append_array([Command.end_night(), Command.nominate(3, 2), Command.decide_execution(2), Command.end_day()] as Array[Command])
	var run := _replay_ok(commands, "Partie")
	if not run.ok:
		return
	var public_count := 0
	for e: GameEvent in run.events:
		var text := _json(e.data)
		if e.visibility == &"public":
			public_count += 1
			assert_false(text.contains("sensentraeger") or text.contains("trugbilderwolf") or text.contains("appears"), "öffentliches %s ohne Rolle oder Scheinrolle" % e.type)
		elif e.visibility == &"actor":
			assert_false(text.contains("sensentraeger") or text.contains("appears"), "%s an %d ohne Scheinrolle" % [e.type, e.actor_id])
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")
	var own := events_of_type(run.events, "RoleAssigned")
	for e: GameEvent in own:
		if e.actor_id == 2:
			assert_eq(str(e.data["role_id"]), "trugbilderwolf", "eigene Rollenanzeige mit tatsächlicher Rolle")
