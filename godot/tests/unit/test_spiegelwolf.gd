extends TestCase
## Produktionsrolle `spiegelwolf` (Mirror Wolf), rules-register.md §11, DR-13.
## M6:  1 Werwolf; 2 Spiegelwolf; 3, 4, 5, 6 Dorfbewohner. Nacht 1: Prompt 1 Rudel.
## M6R: wie M6, aber 3 Sensenträger.
## Die zentrale Hinrichtungsauflösung wird per Skriptpfad angesprochen, damit die
## Tests vor ihrer Umsetzung ladbar bleiben.

const EXECUTION_RULES := "res://core/rules/execution_rules.gd"
const FORBIDDEN_PUBLIC := ["spiegel", "mirror", "redirect", "retaliate", "werwolf", "dorfbewohner", "sensentraeger", "role", "cause"]


func _m6() -> Command:
	return Fixtures.start_roles(["werwolf", "spiegelwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])


func _m6r() -> Command:
	return Fixtures.start_roles(["werwolf", "spiegelwolf", "sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"])


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## Nacht 1 ohne Opfer, danach Tag 1 (nur Rudelschritt im Nachtplan).
func _to_day(start: Command = null) -> Array[Command]:
	return [start if start != null else _m6(), Command.start_night(), Command.answer_prompt(1, []), Command.end_night()]


func _day1(nominator: int, nominee: int, start: Command = null) -> Array[Command]:
	return _concat(_to_day(start), [Command.nominate(nominator, nominee)] as Array[Command])


func _gm(kind: String, fields: Dictionary, reason: String = "Korrektur am Tisch") -> Command:
	return CorrectionFixtures.gm(kind, fields, reason)


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _uses(s: GameState, id: int) -> int:
	return int(s.players[id].ability_uses.get("spiegelwolf:mirror", 0))


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


func _preview(s: GameState, target: int, source_kind: String = "village") -> Dictionary:
	if not ResourceLoader.exists(EXECUTION_RULES):
		fail("ExecutionRules fehlt")
		return {}
	var script: Script = load(EXECUTION_RULES)
	var result: Variant = script.call("preview", s, target, StringName(source_kind))
	return result if result is Dictionary else {}


func _types(events: Array[GameEvent], only: Array) -> Array[String]:
	var out: Array[String] = []
	for e: GameEvent in events:
		if only.has(String(e.type)):
			out.append(String(e.type))
	return out


## Prüft: Spiegelwolf lebt, `victim` starb durch Spiegelung mit Quelle 2.
func _expect_mirrored(s: GameState, victim: int, label: String) -> void:
	assert_true(s.players[2].alive, "%s: Spiegelwolf lebt" % label)
	assert_false(s.players[victim].alive, "%s: %d stirbt" % [label, victim])
	if s.players[victim].death != null:
		assert_eq(String(s.players[victim].death.cause), "SPIEGELWOLF_RETALIATE", "%s: Ursache" % label)
		assert_eq(String(s.players[victim].death.source_kind), "player", "%s: Quellenart" % label)
		assert_eq(int(s.players[victim].death.source_id), 2, "%s: Quelle Spiegelwolf" % label)


func _expect_lynched(s: GameState, label: String) -> void:
	assert_false(s.players[2].alive, "%s: Spiegelwolf stirbt" % label)
	if s.players[2].death != null:
		assert_eq(String(s.players[2].death.cause), "LYNCH", "%s: normaler Hinrichtungstod" % label)


# --- 1–6 Rolle -------------------------------------------------------------------------------------

func test_production_role() -> void:
	# 1, 2, 3, 4
	var r := apply_ok(GameState.new(), _m6(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	var p := r.state.players[2]
	assert_true(p.role_id == &"spiegelwolf" and p.faction == &"wolves" and p.counts_as_wolf and p.appears_as == &"spiegelwolf", "Rollenfelder")
	var n := _replay_ok([_m6(), Command.start_night()] as Array[Command], "Nacht 1")
	if n.ok:
		assert_eq(n.state.night_plan, [&"pack"] as Array[StringName], "kein eigener Schritt")
	var alone := _replay_ok([Fixtures.start_roles(["spiegelwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night()] as Array[Command], "allein")
	if alone.ok:
		assert_eq(alone.state.night_plan, [&"pack"] as Array[StringName], "allein erzeugt er den Rudelschritt")


func test_oracle_sees_werewolf() -> void:
	# 5, AS-R10
	var s := Fixtures.play([Fixtures.start_roles(["werwolf", "spiegelwolf", "dorfbewohner", "das-orakel", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, []), Command.begin_step("night:1:1:das-orakel:4"), Command.answer_stage_targets(2, "target", [2])] as Array[Command])
	assert_true(s != null and s.pending_prompt != null, "Orakel hat geprüft")
	if s != null and s.pending_prompt != null:
		assert_true(str(s.pending_prompt.partial["truth_role"]) == "spiegelwolf" and str(s.pending_prompt.partial["determined_role"]) == "werwolf", "Wahrheit spiegelwolf, ermittelt werwolf")


func test_witch_sees_true_role() -> void:
	# 6
	var s := Fixtures.play([Fixtures.start_roles(["werwolf", "spiegelwolf", "dorfbewohner", "dorfbewohner", "waldhexe", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, [2]), Command.begin_step("night:1:1:waldhexe:5"), Command.answer_choice(2, "heal", true)] as Array[Command])
	assert_true(s != null and s.pending_prompt != null and str(s.pending_prompt.partial.get("victim_role", "")) == "spiegelwolf", "tatsächliche Rolle")


# --- 7–13 Spiegelung --------------------------------------------------------------------------------

func test_mirror_on_execution() -> void:
	# 7–12, AS-R28
	var s := Fixtures.play(_day1(4, 2))
	assert_true(s != null, "Tag 1 mit Nominierung erreicht")
	if s == null:
		return
	assert_eq(_uses(s, 2), 0, "17: Nominierung verbraucht nichts")
	var r := apply_ok(s, Command.decide_execution(2), "Hinrichtung von 2")
	_expect_mirrored(r.state, 4, "Spiegelung")
	assert_eq(_uses(r.state, 2), 1, "genau einmal verbraucht")
	assert_eq(String(r.state.day_step), "EXECUTION_DECIDED", "Hinrichtung des Tages gilt als erfolgt")
	assert_eq(events_of_type(r.events, "SeatDied").size(), 1, "genau ein Tod")
	var redirected := events_of_type(r.events, "ExecutionRedirected")
	assert_eq(redirected.size(), 1, "Umleitung protokolliert")
	if redirected.size() == 1:
		var d: Dictionary = redirected[0].data
		assert_true(int(d["target_id"]) == 2 and int(d["death_target_id"]) == 4 and int(d["nominator_id"]) == 4 and int(d["mirror_wolf_id"]) == 2
			and bool(d["mirror_used"]), "ursprüngliches und tatsächliches Ziel, Nominierende, Spiegelwolf, Verbrauch")
		assert_eq(String(redirected[0].visibility), "gm", "nur Spielleiter")
	apply_ok(r.state, Command.end_day(), "Tag endet")


func test_revive_resets_mirror() -> void:
	# 12, 13, 32, AS-R29
	var commands := _concat(_day1(4, 2), [Command.decide_execution(2), Command.end_day(), Command.start_night(), Command.answer_prompt(2, []),
		Command.end_night(), Command.nominate(3, 2), Command.decide_execution(2)] as Array[Command])
	var day2 := _replay_ok(commands, "zweite Hinrichtung")
	if not day2.ok:
		return
	_expect_lynched(day2.state, "Tag 2")
	commands.append_array([_gm("revive", {"target_id": 2}), Command.end_day(), Command.start_night(), Command.answer_prompt(3, []), Command.end_night(),
		Command.nominate(5, 2)] as Array[Command])
	var before := _replay_ok(commands, "nach Wiederbelebung")
	if not before.ok:
		return
	# Decision Log „Rollenaudit · Wiederbelebung …“ ersetzt Punkt 32: die Wiederbelebung setzt die Spiegelung zurück.
	assert_eq(_uses(before.state, 2), 0, "Wiederbelebung setzt die Spiegelung zurück")
	var r := apply_ok(before.state, Command.decide_execution(2), "dritte Hinrichtung")
	assert_true(r.state.players[2].alive and not r.state.players[5].alive, "nach Wiederbelebung spiegelt er erneut auf die nominierende Person")
	assert_eq(events_of_type(r.events, "ExecutionRedirected").size(), 1, "Spiegelung")


# --- 14–22 Fälle ohne Spiegelung, Selbstnominierung, GM -----------------------------------------------

func test_no_nomination_and_foreign_nominations() -> void:
	# 14, 15, 16, 21, AS-R31
	var cases := {
		"keine Nominierung": _to_day(),
		"Nominierung aus früherem Tag": _concat(_day1(4, 2), [Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.answer_prompt(2, []), Command.end_night()] as Array[Command]),
		"andere Person nominiert": _day1(4, 3),
	}
	for label: String in cases:
		var s := Fixtures.play(cases[label])
		var r := apply_ok(s, _gm("execute", {"target_id": 2}, "Hinrichtung am Tisch"), label)
		_expect_lynched(r.state, label)
		assert_eq(_uses(r.state, 2), 0, "%s: nichts verbraucht" % label)
		assert_eq(events_of_type(r.events, "ExecutionRedirected").size(), 0, "%s: keine Umleitung" % label)
		var skipped := events_of_type(r.events, "MirrorNotTriggered")
		assert_true(skipped.size() == 1 and String(skipped[0].visibility) == "gm", "%s: Grund GM-intern" % label)


func test_dead_nominator_no_mirror() -> void:
	# 17, AS-R30 (endgültige Regel: keine Spiegelung, normaler Tod)
	var s := Fixtures.play(_concat(_day1(4, 2), [_gm("kill", {"target_id": 4, "trigger_effects": false})] as Array[Command]))
	var r := apply_ok(s, Command.decide_execution(2), "Hinrichtung")
	_expect_lynched(r.state, "Nominierende tot")
	assert_eq(_uses(r.state, 2), 0, "nicht verbraucht")
	var skipped := events_of_type(r.events, "MirrorNotTriggered")
	assert_true(skipped.size() == 1 and str(skipped[0].data["reason"]) == "nominator_dead", "Grund")


func test_self_nomination() -> void:
	# 18, 42
	var commands := _concat(_day1(2, 2), [Command.decide_execution(2)] as Array[Command])
	var run := _replay_ok(commands, "Selbstnominierung")
	if not run.ok:
		return
	assert_false(run.state.players[2].alive, "Spiegelwolf stirbt")
	assert_eq(String(run.state.players[2].death.cause), "SPIEGELWOLF_RETALIATE", "Ursache Spiegelung")
	assert_eq(int(run.state.players[2].death.source_id), 2, "Quelle er selbst")
	assert_eq(_uses(run.state, 2), 1, "verbraucht")
	assert_eq(events_of_type(run.events, "SeatDied").size(), 1, "genau ein Tod")
	assert_eq(events_of_type(run.events, "ExecutionRedirected").size(), 1, "eine Umleitung, keine Rekursion")
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(run.events), "Replay bytegleich")


func test_no_execution_and_rejected_consume_nothing() -> void:
	# 19, 20
	var s := Fixtures.play(_day1(4, 2))
	var none := apply_ok(s, Command.decide_execution(-1), "keine Hinrichtung")
	assert_eq(_uses(none.state, 2), 0, "keine Hinrichtung verbraucht nichts")
	apply_rejected(s, Command.decide_execution(3), "not_nominated_today", "abgelehnte Hinrichtung")
	apply_rejected(Fixtures.play(_to_day()), Command.decide_execution(2), "not_nominated_today", "ohne Nominierung")


func test_gm_execute_with_nomination_mirrors() -> void:
	# 22
	var r := apply_ok(Fixtures.play(_day1(4, 2)), _gm("execute", {"target_id": 2}, "Übersteuerung"), "GM-Hinrichtung")
	_expect_mirrored(r.state, 4, "GM mit Nominierung")
	assert_eq(_uses(r.state, 2), 1, "verbraucht")


# --- 23–27 Folgewirkungen -------------------------------------------------------------------------------

func test_mirror_target_reaper_reacts() -> void:
	# 23, 43
	var commands := _concat(_day1(3, 2, _m6r()), [Command.decide_execution(2)] as Array[Command])
	var run := _replay_ok(commands, "Spiegelziel Sensenträger")
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "Reaktion eingereiht")
	assert_eq(RulesEngine.next_step_id(run.state), "reaction:1", "am Tag sofort fällig")
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(run.events), "Replay bytegleich")


func test_event_order_with_child_and_reaper() -> void:
	# 24, 25: 3 ist Sensenträger und Vorbild des Wolfskinds 6.
	var start := Fixtures.start_roles(["werwolf", "spiegelwolf", "sensentraeger", "dorfbewohner", "dorfbewohner", "wolfskind"])
	var s := Fixtures.play([start, Command.start_night(), Command.answer_prompt(1, [3]), Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, []),
		Command.end_night(), Command.nominate(3, 2)] as Array[Command])
	var r := apply_ok(s, Command.decide_execution(2), "Hinrichtung")
	assert_eq(_types(r.events, ["ExecutionConfirmed", "ExecutionRedirected", "SeatDied", "WolfChildTransformed", "ReactionQueued", "WinStatusProvisional"]),
		["ExecutionConfirmed", "ExecutionRedirected", "SeatDied", "WolfChildTransformed", "ReactionQueued", "WinStatusProvisional"] as Array[String], "Reihenfolge")
	assert_true(r.state.players[6].counts_as_wolf, "Wolfskind verwandelt")
	assert_eq(events_of_type(r.events, "WinStatusFinal").size(), 0, "verbindliche Prüfung erst nach der Reaktion")


func test_guard_and_witch_do_not_prevent_mirror() -> void:
	# 26, 27: 4 war nachts geschützt und gerettet.
	var start := Fixtures.start_roles(["werwolf", "spiegelwolf", "schutzengel", "dorfbewohner", "waldhexe", "dorfbewohner"])
	var commands: Array[Command] = [start, Command.start_night(), Command.answer_prompt(1, [4]), Command.begin_step("night:1:1:pack"), Command.answer_prompt(2, [4]),
		Command.begin_step("night:1:2:waldhexe:5"), Command.answer_choice(3, "heal", true), Command.answer_choice(3, "reveal", true),
		Command.answer_choice(3, "poison", false), Command.answer_choice(3, "confirm", true), Command.end_night(), Command.nominate(4, 2), Command.decide_execution(2)]
	var run := _replay_ok(commands, "Schutz und Rettung")
	if run.ok:
		_expect_mirrored(run.state, 4, "trotz Schutz und Rettung")


# --- 28–29 Vorschau ------------------------------------------------------------------------------------

func test_preview_is_pure_and_matches() -> void:
	var cases := {
		"Spiegelung": [_day1(4, 2), true, 4, "SPIEGELWOLF_RETALIATE"],
		"Selbstnominierung": [_day1(2, 2), true, 2, "SPIEGELWOLF_RETALIATE"],
		"Nominierende tot": [_concat(_day1(4, 2), [_gm("kill", {"target_id": 4, "trigger_effects": false})] as Array[Command]), false, 2, "LYNCH"],
		"kein Spiegelwolf": [_day1(4, 3), false, 3, "LYNCH"],
	}
	for label: String in cases:
		var s := Fixtures.play(cases[label][0])
		var before := _json(s.to_dict())
		var target: int = 3 if label == "kein Spiegelwolf" else 2
		var p := _preview(s, target)
		assert_eq(_json(s.to_dict()), before, "%s: Vorschau verändert nichts" % label)
		assert_eq(bool(p.get("redirected", false)), cases[label][1], "%s: Spiegelung ja/nein" % label)
		assert_eq(int(p.get("death_target_id", -1)), cases[label][2], "%s: erwartetes Todesziel" % label)
		assert_eq(str(p.get("cause", "")), cases[label][3], "%s: erwartete Ursache" % label)
		assert_eq(int(p.get("target_id", -1)), target, "%s: ursprüngliches Ziel" % label)
		assert_true(str(p.get("reason", "")) != "", "%s: Grund" % label)
		var r := apply_ok(s, Command.decide_execution(target), "%s: Ausführung" % label)
		var died := events_of_type(r.events, "SeatDied")
		assert_true(died.size() == 1 and int(died[0].data["target_id"]) == int(p.get("death_target_id", -2))
			and str(died[0].data["cause"]) == str(p.get("cause", "")), "%s: Vorschau stimmt mit Ausführung überein" % label)


# --- 30–36 Korrekturen, Rollenwechsel, Sieg ---------------------------------------------------------------

func test_gm_mirror_status() -> void:
	# 30, 31
	var s := Fixtures.play(_to_day())
	var used := apply_ok(s, _gm("set_mirror", {"target_id": 2, "available": false}, "Spiegelung am Tisch verbraucht"), "verbraucht")
	assert_eq(_uses(used.state, 2), 1, "verbraucht")
	var log1 := events_of_type(used.events, "GmCorrected")
	assert_true(log1.size() == 1 and log1[0].data["old"] == {"mirror_available": true} and log1[0].data["new"] == {"mirror_available": false}, "alt und neu")
	assert_eq(events_of_type(used.events, "WinStatusFinal").size(), 0, "keine Siegprüfung")
	var back := apply_ok(used.state, _gm("set_mirror", {"target_id": 2, "available": true}), "verfügbar")
	assert_eq(_uses(back.state, 2), 0, "verfügbar")
	apply_rejected(back.state, _gm("set_mirror", {"target_id": 2, "available": true}), "no_change", "unverändert")
	apply_rejected(s, _gm("set_mirror", {"target_id": 3, "available": false}), "not_a_mirror_wolf", "kein Spiegelwolf")
	apply_rejected(s, _gm("set_mirror", {"target_id": 99, "available": false}), "unknown_player", "unbekannt")
	apply_rejected(s, _gm("set_mirror", {"target_id": 2, "available": "nein"}), "invalid_correction", "kein Wahrheitswert")
	apply_rejected(s, Command.gm_correction({"kind": "set_mirror", "target_id": 2, "available": false, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, _gm("set_mirror", {"target_id": 2, "available": false}, ""), "reason_required", "ohne Begründung")
	# Verbrauchte Spiegelung: die nächste Hinrichtung ist normal.
	var r := apply_ok(apply_ok(used.state, Command.nominate(4, 2), "Nominierung").state, Command.decide_execution(2), "Hinrichtung")
	_expect_lynched(r.state, "nach Korrektur verbraucht")


func test_role_changes() -> void:
	# 33, 34
	var s := Fixtures.play(_to_day())
	var to := apply_ok(s, _gm("set_role", {"target_id": 3, "role_id": "spiegelwolf"}), "wird Spiegelwolf")
	var p := to.state.players[3]
	assert_true(p.faction == &"wolves" and p.counts_as_wolf and p.appears_as == &"spiegelwolf", "Rollenfelder")
	assert_eq(events_of_type(to.events, "WinStatusFinal").size(), 1, "Siegprüfung angestoßen")
	var used := apply_ok(Fixtures.play(_day1(4, 2)), Command.decide_execution(2), "Spiegelung").state
	var away := apply_ok(used, _gm("set_role", {"target_id": 2, "role_id": "dorfbewohner"}), "weg").state
	assert_true(away.players[2].faction == &"village" and not away.players[2].counts_as_wolf and away.players[2].appears_as == &"dorfbewohner", "normale Rolle")
	var again := apply_ok(away, _gm("set_role", {"target_id": 2, "role_id": "spiegelwolf"}), "zurück").state
	assert_eq(_uses(again, 2), 1, "Nutzung bleibt personenbezogen erhalten")


func test_parity_and_village_win() -> void:
	# 35, 36
	var parity := _replay_ok([_m6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.end_night(), Command.nominate(3, 2), Command.decide_execution(2)] as Array[Command], "Parität")
	if parity.ok:
		assert_true(sole_candidate(parity.state) != null and String(sole_candidate(parity.state).kind) == "wolves" and int(sole_candidate(parity.state).reason_args["wolves"]) == 2, "Spiegelwolf zählt")
	var alone := Fixtures.start_roles(["spiegelwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])
	var village := _replay_ok([alone, Command.start_night(), Command.answer_prompt(1, []), Command.end_night(), _gm("execute", {"target_id": 1})] as Array[Command], "letzter Wolf")
	if village.ok:
		assert_true(sole_candidate(village.state) != null and String(sole_candidate(village.state).kind) == "village", "Dorfsieg")


# --- 37–44 Save/Load, Replay, beschädigte Zustände ---------------------------------------------------------

func _roundtrip(commands: Array[Command], label: String) -> LoadResult:
	var run := _replay_ok(commands, label)
	if not run.ok:
		return null
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Laden (%s %s)" % [label, loaded.error, loaded.detail])
	if not loaded.ok:
		return null
	assert_eq(_json(loaded.state.to_dict()), _json(run.state.to_dict()), "%s: vollständiger Zustand" % label)
	assert_eq(loaded.state.content_hash(), run.state.content_hash(), "%s: State-Hash" % label)
	return loaded


func test_save_load_points() -> void:
	# 37–41
	var mirrored := _concat(_day1(4, 2), [Command.decide_execution(2)] as Array[Command])
	var cases := {
		"vor der Hinrichtung": [_day1(4, 2), Command.decide_execution(2)],
		"nach Spiegelung": [mirrored, Command.end_day()],
		"nach Wiederbelebung": [_concat(mirrored, [_gm("revive", {"target_id": 4})] as Array[Command]), Command.end_day()],
		"nach Nutzungskorrektur": [_concat(_day1(4, 2), [_gm("set_mirror", {"target_id": 2, "available": false})] as Array[Command]), Command.decide_execution(2)],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var loaded := _roundtrip(commands, label)
		if loaded == null:
			continue
		var next: Command = cases[label][1]
		var a := RulesEngine.apply(Fixtures.play(commands), next)
		var b := RulesEngine.apply(loaded.state, next)
		assert_true(a.ok and b.ok, "%s: Fortsetzung angenommen" % label)
		assert_eq(events_json(b.events), events_json(a.events), "%s: identische Fortsetzung" % label)
		assert_eq(_json(b.state.to_dict()), _json(a.state.to_dict()), "%s: identischer Endzustand" % label)
	var run := _replay_ok(mirrored, "Spiegelung")
	if run.ok:
		assert_eq(events_json(RulesEngine.replay(mirrored).events), events_json(run.events), "41: Replay bytegleich")
		assert_false(_json(run.state.to_dict()).contains("redirect"), "keine gespeicherten Umleitungsdaten")


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


func test_corrupt_states_rejected() -> void:
	# 44
	var mirrored := _concat(_day1(4, 2), [Command.decide_execution(2)] as Array[Command])
	var control := _tampered(mirrored, func(st: Dictionary) -> void: st["players"][0]["name"] = "Z")
	assert_eq(String(control.error), "replay_mismatch", "Kontrolle: Hash und Integrität werden passiert")
	var cases := {
		"negativer Nutzungswert": func(st: Dictionary) -> void: st["players"][1]["ability_uses"]["spiegelwolf:mirror"] = -1,
		"Nutzungswert größer 1": func(st: Dictionary) -> void: st["players"][1]["ability_uses"]["spiegelwolf:mirror"] = 2,
		"nicht ganzzahlig": func(st: Dictionary) -> void: st["players"][1]["ability_uses"]["spiegelwolf:mirror"] = 0.5,
		"unbekannter Schlüssel": func(st: Dictionary) -> void: st["players"][1]["ability_uses"]["spiegelwolf:unbekannt"] = 1,
		"Nominierung auf unbekannte Person": func(st: Dictionary) -> void: st["nominations"][0]["nominator_id"] = 99,
		"Todesquelle unbekannt": func(st: Dictionary) -> void: st["players"][3]["death"]["source_id"] = 99,
	}
	for label: String in cases:
		var result := _tampered(mirrored, cases[label])
		assert_false(result.ok, "%s: nicht geladen" % label)
		assert_eq(String(result.error), "state_invalid", "%s: Fehlergrund" % label)
		assert_true(result.state == null, "%s: kein teilweise geladener Zustand" % label)


# --- 45–46 Sichtbarkeit ----------------------------------------------------------------------------------

func test_no_secrets_in_public_or_other_actor_events() -> void:
	var run := _replay_ok(_concat(_day1(4, 2), [Command.decide_execution(2), Command.end_day()] as Array[Command]), "Partie")
	if not run.ok:
		return
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			assert_eq(_find_forbidden(e.data), "", "öffentliches %s ohne Rolle oder Umleitung" % e.type)
		elif e.visibility == &"actor" and e.actor_id != 2:
			var text := _json(e.data)
			assert_false(text.contains("spiegel") or text.contains("mirror") or text.contains("redirect"), "%s an %d ohne Spiegelinformation" % [e.type, e.actor_id])
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")
	for type: String in ["ExecutionRedirected", "SeatDied"]:
		for e: GameEvent in events_of_type(run.events, type):
			assert_eq(String(e.visibility), "gm", "%s nur für Spielleiter" % type)


func _find_forbidden(value: Variant) -> String:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			var hit := _match(String(k))
			if hit == "":
				hit = _find_forbidden(value[k])
			if hit != "":
				return hit
	elif value is Array:
		for v: Variant in (value as Array):
			var hit := _find_forbidden(v)
			if hit != "":
				return hit
	elif value is String or value is StringName:
		return _match(String(value))
	return ""


func _match(text: String) -> String:
	for bad: String in FORBIDDEN_PUBLIC:
		if text.to_lower().contains(bad):
			return "%s (%s)" % [text, bad]
	return ""
