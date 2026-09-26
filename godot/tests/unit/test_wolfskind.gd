extends TestCase
## Produktionsrolle `wolfskind` (Wolf Child), rules-register.md §8, DR-10.
## K6:  1, 2 Werwölfe; 3, 4, 5 Dorfbewohner; 6 Wolfskind. K6one: wie K6, aber 2 Dorfbewohner.
##      Nacht 1: Prompt 1 Wolfskind (StartNight), Prompt 2 Rudel.
## K7R: 1, 2 Werwölfe; 3 Sensenträger; 4, 5, 6 Dorfbewohner; 7 Wolfskind.
## K8:  1, 2 Werwölfe; 3 Schutzengel; 4 Orakel; 5 Waldhexe; 6, 7 Dorfbewohner; 8 Wolfskind.
##      Nacht 1: 1 Wolfskind, 2 Schutzengel, 3 Rudel, 4 Waldhexe, 5 Orakel.
## Neue Felder werden über die Serialisierung (`wolf_children`) gelesen.

const CHILD_1 := "night:1:0:wolfskind:6"
const PACK_1 := "night:1:1:pack"
const FORBIDDEN_PUBLIC := ["wolfskind", "model", "vorbild", "transform", "werwolf", "dorfbewohner", "role", "cause", "wolf_child", "bound", "targets"]


func _k6() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "wolfskind"])


## K6 mit nur einem Werwolf (1): Verwandlungen erzeugen keine sofortige Parität.
func _k6one() -> Command:
	return Fixtures.start_roles(["werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "wolfskind"])


func _k7r() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner", "wolfskind"])


func _k8() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "das-orakel", "waldhexe", "dorfbewohner", "dorfbewohner", "wolfskind"])


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## K6 Nacht 1: Wolfskind 6 wählt `model`; danach ist der Rudelschritt erwartet (nicht begonnen).
func _bound(model: int, start: Command = null) -> Array[Command]:
	return [start if start != null else _k6(), Command.start_night(), Command.answer_prompt(1, [model])]


func _gm(kind: String, fields: Dictionary, reason: String = "Korrektur am Tisch") -> Command:
	return CorrectionFixtures.gm(kind, fields, reason)


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _bond(s: GameState, child: int) -> Dictionary:
	for b: Variant in s.to_dict().get("wolf_children", []):
		if int((b as Dictionary)["child_id"]) == child:
			return b
	return {}


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


func _types(events: Array[GameEvent], only: Array) -> Array[String]:
	var out: Array[String] = []
	for e: GameEvent in events:
		if only.has(String(e.type)):
			out.append(String(e.type))
	return out


func _expect_unturned(p: Player, label: String) -> void:
	assert_true(p.role_id == &"wolfskind" and p.faction == &"village" and not p.counts_as_wolf and p.appears_as == &"wolfskind", "%s: unverwandelt" % label)


func _expect_turned(p: Player, label: String) -> void:
	assert_true(p.role_id == &"wolfskind" and p.faction == &"wolves" and p.counts_as_wolf and p.appears_as == &"werwolf", "%s: verwandelt, Rolle bleibt" % label)


# --- 1–11 Rolle, Nachtschritt, Vorbildwahl ----------------------------------------------------

func test_production_role() -> void:
	# 1, 2
	var r := apply_ok(GameState.new(), _k6(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	_expect_unturned(r.state.players[6], "Start")
	var b := _bond(r.state, 6)
	assert_true(not b.is_empty() and int(b["model_id"]) == -1 and not bool(b["transformed"]), "Zustand ohne Vorbild")


func test_step_priority_before_guard_and_pack() -> void:
	# 3, 5
	var s := Fixtures.play([_k8(), Command.start_night()] as Array[Command])
	assert_eq(s.night_plan, [&"wolfskind:8", &"schutzengel:3", &"pack", &"waldhexe:5", &"das-orakel:4"] as Array[StringName], "Wolfskind zuerst")
	assert_eq(int(s.pending_prompt.actor_id), 8, "Wolfskind handelt in Nacht 1")
	assert_eq(s.pending_prompt.allowed_ids, [1, 2, 3, 4, 5, 6, 7] as Array[int], "andere lebende Personen")
	assert_true(s.pending_prompt.min_count == 1 and s.pending_prompt.max_count == 1, "genau eine Person")


func test_multiple_children_by_id() -> void:
	# 4
	var s := Fixtures.play([Fixtures.start_roles(["werwolf", "werwolf", "wolfskind", "dorfbewohner", "wolfskind", "dorfbewohner"]), Command.start_night()] as Array[Command])
	assert_eq(s.night_plan, [&"wolfskind:3", &"wolfskind:5", &"pack"] as Array[StringName], "nach Personen-ID")


func test_invalid_model_rejected() -> void:
	# 6, 7, AS-R38
	var s := Fixtures.play([_k6(), Command.start_night()] as Array[Command])
	apply_rejected(s, Command.answer_prompt(1, [6]), "invalid_target", "Selbstwahl")
	apply_rejected(s, Command.answer_prompt(1, []), "invalid_target_count", "keine Wahl")
	var r := apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": false}), "5 stirbt")
	var again := apply_ok(r.state, Command.begin_step(CHILD_1), "neu begonnen").state
	assert_false(again.pending_prompt.allowed_ids.has(5), "Tote nicht angeboten")
	apply_rejected(again, Command.answer_prompt(2, [5]), "invalid_target", "totes Vorbild")


func test_cancel_restores_hash_and_reoffers() -> void:
	# 8, 9
	var s := Fixtures.play([_k6(), Command.start_night()] as Array[Command])
	var cancelled := apply_ok(s, Command.cancel_prompt(1, "zu früh"), "Abbruch").state
	var again := apply_ok(cancelled, Command.begin_step(CHILD_1), "erneut").state
	var twice := apply_ok(again, Command.cancel_prompt(2, "nochmal"), "zweiter Abbruch").state
	assert_eq(twice.content_hash(), cancelled.content_hash(), "Hash wie vor BeginStep")
	assert_eq(int(_bond(twice, 6)["model_id"]), -1, "keine Bindung")
	assert_eq(RulesEngine.next_step_id(twice), CHILD_1, "derselbe Schritt")


func test_not_skippable() -> void:
	# 10
	var s := Fixtures.play([_k6(), Command.start_night()] as Array[Command])
	apply_rejected(s, Command.skip_step(CHILD_1, "Kind schläft"), "step_not_skippable", "offen")
	var c := apply_ok(s, Command.cancel_prompt(1, "später"), "Abbruch").state
	apply_rejected(c, Command.skip_step(CHILD_1, "Kind schläft"), "step_not_skippable", "vor Beginn")


func test_binding_persists_no_new_step() -> void:
	# 11
	var r := apply_ok(Fixtures.play([_k6(), Command.start_night()] as Array[Command]), Command.answer_prompt(1, [4]), "Vorbild 4")
	var b := _bond(r.state, 6)
	assert_true(int(b["model_id"]) == 4 and int(b["bound_night"]) == 1, "Bindung gespeichert")
	var bound := events_of_type(r.events, "WolfChildBound")
	assert_true(bound.size() == 1 and String(bound[0].visibility) == "gm", "GM-intern protokolliert")
	var run := _replay_ok(_concat(_bound(4), [Command.begin_step(PACK_1), Command.answer_prompt(2, []), Command.end_night(),
		Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command]), "Nacht 2")
	if run.ok:
		assert_eq(run.state.night_plan, [&"pack"] as Array[StringName], "kein erneuter Auswahl-Schritt")


# --- 12–26 Verwandlung ------------------------------------------------------------------------------

func test_pack_kill_transforms_before_provisional_win() -> void:
	# 12, 22, AS-R18
	var s := Fixtures.play(_concat(_bound(4), [Command.begin_step(PACK_1), Command.answer_prompt(2, [4])] as Array[Command]))
	var r := apply_ok(s, Command.end_night(), "Morgen")
	_expect_turned(r.state.players[6], "Rudeltod")
	assert_eq(_types(r.events, ["SeatDied", "WolfChildTransformed", "WinStatusProvisional"]), ["SeatDied", "WolfChildTransformed", "WinStatusProvisional"] as Array[String], "Verwandlung vor vorläufiger Siegprüfung")
	var prov := events_of_type(r.events, "WinStatusProvisional")
	assert_true(prov.size() == 1 and _json(prov[0].data).contains("\"wolves\":3"), "vorläufige Prüfung rechnet mit 3 Wölfen")
	var turned := events_of_type(r.events, "WolfChildTransformed")
	assert_true(turned.size() == 1 and int(turned[0].data["child_id"]) == 6 and int(turned[0].data["model_id"]) == 4 and String(turned[0].visibility) == "gm", "Ereignis")
	var b := _bond(r.state, 6)
	assert_true(bool(b["transformed"]) and int(b["transform_order"]) == int(r.state.players[4].death.order_index), "Bezug zum Todesereignis")


func test_poison_transforms() -> void:
	# 13
	var run := _replay_ok([_k8(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:schutzengel:3"),
		Command.answer_prompt(2, [7]), Command.begin_step("night:1:2:pack"), Command.answer_prompt(3, []), Command.begin_step("night:1:3:waldhexe:5"),
		Command.answer_choice(4, "poison", true), Command.answer_stage_targets(4, "poison_target", [6]), Command.answer_choice(4, "confirm", true)] as Array[Command], "Gift")
	if run.ok:
		_expect_turned(run.state.players[8], "Gifttod")


func test_execution_transforms_and_parity() -> void:
	# 14, 19 (Tag), 23
	var run := _replay_ok(_concat(_bound(4), [Command.begin_step(PACK_1), Command.answer_prompt(2, []), Command.end_night(),
		Command.nominate(3, 4), Command.decide_execution(4)] as Array[Command]), "Hinrichtung")
	if not run.ok:
		return
	_expect_turned(run.state.players[6], "Hinrichtung")
	assert_true(sole_candidate(run.state) != null and String(sole_candidate(run.state).kind) == "wolves"
		and int(sole_candidate(run.state).reason_args["wolves"]) == 3, "Parität zählt das verwandelte Wolfskind sofort")


func test_curse_transforms() -> void:
	# 15
	var run := _replay_ok([_k7r(), Command.start_night(), Command.answer_prompt(1, [5]), Command.begin_step(PACK_1), Command.answer_prompt(2, [3]),
		Command.end_night(), Command.begin_step("reaction:1"), Command.answer_prompt(3, [5])] as Array[Command], "Fluch")
	if run.ok:
		_expect_turned(run.state.players[7], "Fluch")


func test_gm_kill_with_effects_transforms() -> void:
	# 16
	var with := _replay_ok(_concat(_bound(4), [_gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command]), "mit Folgen")
	if with.ok:
		_expect_turned(with.state.players[6], "GM-Tod mit Folgen")
	var without := _replay_ok(_concat(_bound(4), [_gm("kill", {"target_id": 4, "trigger_effects": false})] as Array[Command]), "ohne Folgen")
	if without.ok:
		_expect_unturned(without.state.players[6], "GM-Tod ohne Folgen")


func test_dead_child_revive_and_second_death() -> void:
	# 17, 18, 19, AS-R19
	var commands := _concat(_bound(4, _k6one()), [_gm("kill", {"target_id": 6, "trigger_effects": false}), _gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command])
	var dead := _replay_ok(commands, "Wolfskind tot")
	if not dead.ok:
		return
	assert_eq(events_of_type(dead.events, "WolfChildTransformed").size(), 0, "17: keine Verwandlung")
	commands.append(_gm("revive", {"target_id": 6}))
	var revived := _replay_ok(commands, "Wolfskind wiederbelebt")
	if revived.ok:
		_expect_unturned(revived.state.players[6], "18: keine rückwirkende Verwandlung")
	commands.append_array([_gm("revive", {"target_id": 4}), _gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command])
	var again := _replay_ok(commands, "Vorbild stirbt erneut")
	if again.ok:
		_expect_turned(again.state.players[6], "19: neues Todesereignis")
		assert_eq(events_of_type(again.events, "WolfChildTransformed").size(), 1, "genau eine Verwandlung")


func test_multiple_children_same_model() -> void:
	# 20, 21, 45
	var start := Fixtures.start_roles(["werwolf", "werwolf", "wolfskind", "dorfbewohner", "wolfskind", "dorfbewohner"])
	var commands: Array[Command] = [start, Command.start_night(), Command.answer_prompt(1, [4]), Command.begin_step("night:1:1:wolfskind:5"),
		Command.answer_prompt(2, [4]), Command.begin_step("night:1:2:pack"), Command.answer_prompt(3, [4]), Command.end_night()]
	var run := _replay_ok(commands, "gleiches Vorbild")
	if not run.ok:
		return
	var turned := events_of_type(run.events, "WolfChildTransformed")
	assert_eq(turned.size(), 2, "beide verwandelt")
	if turned.size() == 2:
		assert_true(int(turned[0].data["child_id"]) == 3 and int(turned[1].data["child_id"]) == 5 and turned[0].index < turned[1].index, "stabile Reihenfolge nach ID")
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(run.events), "Replay bytegleich")
	var one_dead := commands.duplicate()
	one_dead.insert(5, _gm("kill", {"target_id": 3, "trigger_effects": false}))
	var partial := _replay_ok(one_dead, "ein Wolfskind tot")
	if partial.ok:
		var only := events_of_type(partial.events, "WolfChildTransformed")
		assert_true(only.size() == 1 and int(only[0].data["child_id"]) == 5, "tote Wolfskinder ausgelassen")


func test_no_extra_pack_step_and_next_night() -> void:
	# 24, 25, 26, AS-R20: Vorbild ist der einzige Werwolf; er wird am Tag hingerichtet.
	var start := Fixtures.start_roles(["werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "wolfskind"])
	var night: Array[Command] = [start, Command.start_night(), Command.answer_prompt(1, [1]), Command.begin_step(PACK_1), Command.answer_prompt(2, [])]
	var s := Fixtures.play(night)
	var r := apply_ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "anderer Tod in der Nacht")
	assert_eq(r.state.night_plan, s.night_plan, "Nachtplan unverändert")
	var day := _replay_ok(_concat(night, [Command.end_night(), Command.nominate(2, 1), Command.decide_execution(1)] as Array[Command]), "Hinrichtung des Vorbilds")
	if not day.ok:
		return
	_expect_turned(day.state.players[6], "Tag")
	assert_true(sole_candidate(day.state) == null, "1 Wolf gegen 4: kein Kandidat")
	var n2 := _replay_ok(_concat(night, [Command.end_night(), Command.nominate(2, 1), Command.decide_execution(1), Command.end_day(), Command.start_night()] as Array[Command]), "Nacht 2")
	if n2.ok:
		assert_eq(n2.state.night_plan, [&"pack"] as Array[StringName], "verwandeltes Wolfskind allein erzeugt den Rudelschritt")
	# 24: Vorbild stirbt nachts nach dem Rudelschritt → kein weiterer Rudelschritt in dieser Nacht.
	var late := _replay_ok(_concat(_bound(4), [Command.begin_step(PACK_1), Command.answer_prompt(2, []), _gm("kill", {"target_id": 4, "trigger_effects": true})] as Array[Command]), "nachts")
	if late.ok:
		_expect_turned(late.state.players[6], "nachts")
		assert_eq(RulesEngine.next_step_id(late.state), "", "kein zusätzlicher Rudelschritt")
		assert_eq(late.state.night_plan, [&"wolfskind:6", &"pack"] as Array[StringName], "Snapshot")


# --- 27–29 Information ------------------------------------------------------------------------------

## K8 Nacht 1 bis zum begonnenen Orakel (Wolfskind wählt 6, Schutz 7, kein Rudelopfer, Waldhexe verzichtet).
func _k8_to_oracle(extra_before_oracle: Array[Command] = []) -> Array[Command]:
	var out: Array[Command] = [_k8(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:schutzengel:3"),
		Command.answer_prompt(2, [7]), Command.begin_step("night:1:2:pack"), Command.answer_prompt(3, []), Command.begin_step("night:1:3:waldhexe:5"),
		Command.answer_choice(4, "poison", false), Command.answer_choice(4, "confirm", true)]
	out.append_array(extra_before_oracle)
	out.append(Command.begin_step("night:1:4:das-orakel:4"))
	return out


func test_oracle_information() -> void:
	# 27, 28
	var plain := apply_ok(Fixtures.play(_k8_to_oracle()), Command.answer_stage_targets(5, "target", [8]), "unverwandelt").state
	assert_true(str(plain.pending_prompt.partial["truth_role"]) == "wolfskind" and str(plain.pending_prompt.partial["determined_role"]) == "wolfskind", "ermittelt wolfskind")
	var turned := apply_ok(Fixtures.play(_k8_to_oracle([_gm("transform_wolf_child", {"child_id": 8})] as Array[Command])),
		Command.answer_stage_targets(5, "target", [8]), "verwandelt").state
	assert_true(str(turned.pending_prompt.partial["truth_role"]) == "wolfskind" and str(turned.pending_prompt.partial["determined_role"]) == "werwolf", "ermittelt werwolf")
	var over := apply_ok(turned, Command.override_shown_role(5, "wolfskind", "Test"), "Übersteuerung").state
	assert_true(str(over.pending_prompt.partial["truth_role"]) == "wolfskind" and str(over.pending_prompt.partial["determined_role"]) == "werwolf"
		and str(over.pending_prompt.partial["shown_role"]) == "wolfskind", "nur gezeigt geändert")


func test_witch_sees_true_role() -> void:
	# 29
	for transform: bool in [false, true]:
		var commands: Array[Command] = [_k8(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step("night:1:1:schutzengel:3"),
			Command.answer_prompt(2, [7]), Command.begin_step("night:1:2:pack"), Command.answer_prompt(3, [8])]
		if transform:
			commands.append(_gm("transform_wolf_child", {"child_id": 8}))
		commands.append_array([Command.begin_step("night:1:3:waldhexe:5"), Command.answer_choice(4, "heal", true)] as Array[Command])
		var s := Fixtures.play(commands)
		assert_true(s != null and s.pending_prompt != null and str(s.pending_prompt.partial.get("victim_role", "")) == "wolfskind",
			"Waldhexe sieht wolfskind (verwandelt: %s)" % transform)


# --- 30–32 Rollenwechsel -------------------------------------------------------------------------------

func test_role_changes() -> void:
	# 30, 31, 32
	var s := Fixtures.play(_concat(_bound(4, _k6one()), [_gm("transform_wolf_child", {"child_id": 6})] as Array[Command]))
	var away := apply_ok(s, _gm("set_role", {"target_id": 6, "role_id": "dorfbewohner"}), "weg vom Wolfskind").state
	assert_true(_bond(away, 6).is_empty(), "31: Zustand entfernt")
	assert_true(away.players[6].faction == &"village" and not away.players[6].counts_as_wolf and away.players[6].appears_as == &"dorfbewohner", "normale Felder")
	var back := apply_ok(away, _gm("set_role", {"target_id": 6, "role_id": "wolfskind"}), "wieder Wolfskind").state
	_expect_unturned(back.players[6], "32")
	var b := _bond(back, 6)
	assert_true(int(b["model_id"]) == -1 and not bool(b["transformed"]), "32: beginnt neu ohne Vorbild")
	var fresh := apply_ok(s, _gm("set_role", {"target_id": 3, "role_id": "wolfskind"}), "30: Dorfbewohner wird Wolfskind").state
	_expect_unturned(fresh.players[3], "30")
	assert_eq(fresh.night_plan, s.night_plan, "30: Nachtplan unverändert")
	apply_rejected(s, _gm("set_role", {"target_id": 3, "role_id": "wolfskind", "appears_as": "werwolf"}), "appearance_not_allowed", "keine Scheinrolle")
	var n2 := _replay_ok(_concat(_bound(4, _k6one()), [_gm("set_role", {"target_id": 3, "role_id": "wolfskind"}), Command.begin_step(PACK_1), Command.answer_prompt(2, []),
		Command.end_night(), Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command]), "Nacht 2")
	if n2.ok:
		assert_eq(n2.state.night_plan, [&"wolfskind:3", &"pack"] as Array[StringName], "30: Auswahl-Schritt erst in der nächsten Nacht")


# --- 33–38 Spielleiterkorrekturen --------------------------------------------------------------------------

func test_gm_model_corrections() -> void:
	# 33, 34, 35
	var open := Fixtures.play([_k6(), Command.start_night()] as Array[Command])
	var set := apply_ok(open, _gm("set_wolf_model", {"child_id": 6, "target_id": 3}, "Vorbild am Tisch gewählt"), "setzen")
	assert_eq(int(_bond(set.state, 6)["model_id"]), 3, "gesetzt")
	var log1 := events_of_type(set.events, "GmCorrected")
	assert_true(log1.size() == 1 and log1[0].data["old"] == {"model_id": -1} and log1[0].data["new"] == {"model_id": 3}, "alter und neuer Wert")
	assert_eq(events_of_type(set.events, "PromptCancelled").size(), 1, "offener Auswahl-Prompt abgebrochen")
	var dropped := events_of_type(set.events, "StepDropped")
	assert_true(dropped.size() == 1 and String(dropped[0].data["reason"]) == "no_decision", "Auswahl entfällt")
	var changed := apply_ok(set.state, _gm("set_wolf_model", {"child_id": 6, "target_id": 5}), "ändern")
	var log2 := events_of_type(changed.events, "GmCorrected")
	assert_true(log2.size() == 1 and log2[0].data["old"] == {"model_id": 3} and log2[0].data["new"] == {"model_id": 5}, "ändern protokolliert")
	var removed := apply_ok(changed.state, _gm("remove_wolf_model", {"child_id": 6}), "entfernen")
	assert_eq(int(_bond(removed.state, 6)["model_id"]), -1, "entfernt")
	apply_rejected(removed.state, _gm("remove_wolf_model", {"child_id": 6}), "no_change", "nichts zu entfernen")
	apply_rejected(set.state, _gm("set_wolf_model", {"child_id": 6, "target_id": 3}), "no_change", "gleiches Vorbild")
	apply_rejected(set.state, _gm("set_wolf_model", {"child_id": 6, "target_id": 6}), "invalid_target", "Selbstbindung")
	apply_rejected(set.state, _gm("set_wolf_model", {"child_id": 6, "target_id": 99}), "unknown_player", "unbekanntes Vorbild")
	apply_rejected(set.state, _gm("set_wolf_model", {"child_id": 5, "target_id": 3}), "not_a_wolf_child", "kein Wolfskind")
	apply_rejected(set.state, Command.gm_correction({"kind": "set_wolf_model", "child_id": 6, "target_id": 4, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(set.state, _gm("set_wolf_model", {"child_id": 6, "target_id": 4}, " "), "reason_required", "ohne Begründung")
	var dead := apply_ok(set.state, _gm("kill", {"target_id": 4, "trigger_effects": false}), "4 stirbt").state
	apply_rejected(dead, _gm("set_wolf_model", {"child_id": 6, "target_id": 4}), "player_dead", "totes Vorbild")


func test_gm_transform_and_revert() -> void:
	# 36, 37, 38
	var s := Fixtures.play(_bound(4, _k6one()))
	var t := apply_ok(s, _gm("transform_wolf_child", {"child_id": 6}, "Verwandlung vergessen"), "Verwandlung")
	_expect_turned(t.state.players[6], "GM-Verwandlung")
	var log1 := events_of_type(t.events, "GmCorrected")
	assert_true(log1.size() == 1 and log1[0].data["old"]["transformed"] == false and log1[0].data["new"]["transformed"] == true
		and str(log1[0].data["new"]["appears_as"]) == "werwolf", "alt und neu")
	assert_eq(events_of_type(t.events, "WinStatusFinal").size(), 1, "38: Siegprüfung angestoßen")
	apply_rejected(t.state, _gm("transform_wolf_child", {"child_id": 6}), "no_change", "schon verwandelt")
	var back := apply_ok(t.state, _gm("revert_wolf_child", {"child_id": 6}), "Rücknahme")
	_expect_unturned(back.state.players[6], "Rücknahme")
	assert_eq(int(_bond(back.state, 6)["model_id"]), 4, "Vorbild bleibt")
	assert_eq(events_of_type(back.events, "WinStatusFinal").size(), 1, "38: Siegprüfung nach Rücknahme")
	apply_rejected(back.state, _gm("revert_wolf_child", {"child_id": 6}), "no_change", "nicht verwandelt")
	apply_rejected(s, _gm("transform_wolf_child", {"child_id": 3}), "not_a_wolf_child", "kein Wolfskind")
	apply_rejected(s, _gm("set_role_field", {"target_id": 6, "field": "appears_as", "value": "dorfbewohner"}), "field_not_correctable", "Erscheinung folgt der Verwandlung")
	# Parität: 1, 2 Werwölfe, 3 Wolfskind, 4–6 Dorf → nach Verwandlung 3:3.
	var parity := Fixtures.play([Fixtures.start_roles(["werwolf", "werwolf", "wolfskind", "dorfbewohner", "dorfbewohner", "dorfbewohner"])] as Array[Command])
	var p := apply_ok(parity, _gm("transform_wolf_child", {"child_id": 3}), "Parität")
	assert_true(sole_candidate(p.state) != null and String(sole_candidate(p.state).kind) == "wolves", "38: Kandidat mit neuem Wolfsstatus")


# --- 39–45 Save/Load und Replay --------------------------------------------------------------------------

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


func _continue_both(commands: Array[Command], loaded: GameState, rest: Array[Command], label: String) -> void:
	var a := Fixtures.play(commands)
	var b := loaded
	var ea: Array[GameEvent] = []
	var eb: Array[GameEvent] = []
	for c: Command in rest:
		var ra := RulesEngine.apply(a, c)
		var rb := RulesEngine.apply(b, c)
		assert_true(ra.ok and rb.ok, "%s: %s angenommen (%s)" % [label, c.type, ra.error])
		if not (ra.ok and rb.ok):
			return
		a = ra.state
		b = rb.state
		ea.append_array(ra.events)
		eb.append_array(rb.events)
	assert_eq(events_json(eb), events_json(ea), "%s: identische Fortsetzung" % label)
	assert_eq(_json(b.to_dict()), _json(a.to_dict()), "%s: identischer Endzustand" % label)


func test_save_load_points() -> void:
	# 39, 40, 41, 43, 44
	var cases := {
		"offener Auswahl-Prompt": [[_k6(), Command.start_night()] as Array[Command], [Command.answer_prompt(1, [4]), Command.begin_step(PACK_1), Command.answer_prompt(2, [4]), Command.end_night()] as Array[Command]],
		"nach Bindung": [_bound(4), [Command.begin_step(PACK_1), Command.answer_prompt(2, [4]), Command.end_night()] as Array[Command]],
		"nach Verwandlung": [_concat(_bound(4, _k6one()), [Command.begin_step(PACK_1), Command.answer_prompt(2, [4]), Command.end_night()] as Array[Command]),
			[Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command]],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var rest: Array[Command] = []
		rest.assign(cases[label][1])
		var loaded := _roundtrip(commands, label)
		if loaded != null:
			_continue_both(commands, loaded.state, rest, label)
		var full := _concat(commands, rest)
		assert_eq(events_json(RulesEngine.replay(full).events), events_json(RulesEngine.replay(full).events), "%s: Replay bytegleich" % label)


func test_save_load_after_each_correction() -> void:
	# 42
	var cases := {
		"Vorbild setzen": _concat([_k6one(), Command.start_night()] as Array[Command], [_gm("set_wolf_model", {"child_id": 6, "target_id": 4})] as Array[Command]),
		"Vorbild ändern": _concat(_bound(3, _k6one()), [_gm("set_wolf_model", {"child_id": 6, "target_id": 4})] as Array[Command]),
		"Vorbild entfernen": _concat(_bound(4, _k6one()), [_gm("remove_wolf_model", {"child_id": 6})] as Array[Command]),
		"Verwandlung": _concat(_bound(4, _k6one()), [_gm("transform_wolf_child", {"child_id": 6})] as Array[Command]),
		"Rücknahme": _concat(_bound(4, _k6one()), [_gm("transform_wolf_child", {"child_id": 6}), _gm("revert_wolf_child", {"child_id": 6})] as Array[Command]),
	}
	for label: String in cases:
		var commands: Array[Command] = cases[label]
		var loaded := _roundtrip(commands, label)
		if loaded != null:
			_continue_both(commands, loaded.state, [Command.begin_step(PACK_1), Command.answer_prompt(2, []), Command.end_night()] as Array[Command], label)


# --- 46–50 Beschädigte Zustände ---------------------------------------------------------------------------

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


func _turn(st: Dictionary, faction: String, counts: bool, appears: String) -> void:
	st["wolf_children"][0]["transformed"] = true
	st["wolf_children"][0]["transform_command"] = 2
	st["players"][5]["faction"] = faction
	st["players"][5]["counts_as_wolf"] = counts
	st["players"][5]["appears_as"] = appears


func test_corrupt_states_rejected() -> void:
	# 46–50
	var bound := _bound(4)
	var open: Array[Command] = [_k6(), Command.start_night()]
	var control := _tampered(bound, func(st: Dictionary) -> void: st["players"][0]["name"] = "Z")
	assert_eq(String(control.error), "replay_mismatch", "Kontrolle: Hash und Integrität werden passiert")
	var cases := {
		"unbekannte Wolfskind-ID": [bound, func(st: Dictionary) -> void: st["wolf_children"][0]["child_id"] = 99],
		"nicht mehr Wolfskind": [bound, func(st: Dictionary) -> void:
			st["players"][5]["role_id"] = "dorfbewohner"
			st["players"][5]["appears_as"] = "dorfbewohner"],
		"Wolfskind ohne Zustand": [bound, func(st: Dictionary) -> void: st["wolf_children"] = []],
		"unbekanntes Vorbild": [bound, func(st: Dictionary) -> void: st["wolf_children"][0]["model_id"] = 99],
		"Selbstbindung": [bound, func(st: Dictionary) -> void: st["wolf_children"][0]["model_id"] = 6],
		"Bindung in künftiger Nacht": [bound, func(st: Dictionary) -> void: st["wolf_children"][0]["bound_night"] = 5],
		"Bindung ohne Vorbild mit Nacht": [bound, func(st: Dictionary) -> void: st["wolf_children"][0]["model_id"] = -1],
		"Bindung bei offenem Auswahl-Prompt": [open, func(st: Dictionary) -> void:
			st["wolf_children"][0]["model_id"] = 4
			st["wolf_children"][0]["bound_night"] = 1],
		"Prompt Step-ID andere Nacht": [open, func(st: Dictionary) -> void: st["pending_prompt"]["step_id"] = "night:2:0:wolfskind:6"],
		"Prompt Nacht widerspricht": [open, func(st: Dictionary) -> void: st["night_number"] = 2],
		"verwandelt mit Dorf-Fraktion": [bound, func(st: Dictionary) -> void: _turn(st, "village", true, "werwolf")],
		"verwandelt ohne Wolfszählung": [bound, func(st: Dictionary) -> void: _turn(st, "wolves", false, "werwolf")],
		"verwandelt mit falscher Erscheinung": [bound, func(st: Dictionary) -> void: _turn(st, "wolves", true, "wolfskind")],
		"unverwandelt mit Wolfsfraktion": [bound, func(st: Dictionary) -> void: st["players"][5]["faction"] = "wolves"],
		"unverwandelt zählt als Wolf": [bound, func(st: Dictionary) -> void: st["players"][5]["counts_as_wolf"] = true],
		"unverwandelt falsche Erscheinung": [bound, func(st: Dictionary) -> void: st["players"][5]["appears_as"] = "dorfbewohner"],
		"doppelter Datensatz": [bound, func(st: Dictionary) -> void: (st["wolf_children"] as Array).append((st["wolf_children"][0] as Dictionary).duplicate())],
		"Datensatz für Nicht-Wolfskind": [bound, func(st: Dictionary) -> void:
			var extra: Dictionary = (st["wolf_children"][0] as Dictionary).duplicate()
			extra["child_id"] = 3
			extra["model_id"] = 4
			(st["wolf_children"] as Array).append(extra)],
	}
	for label: String in cases:
		var commands: Array[Command] = []
		commands.assign(cases[label][0])
		var result := _tampered(commands, cases[label][1])
		assert_false(result.ok, "%s: nicht geladen" % label)
		assert_eq(String(result.error), "state_invalid", "%s: Fehlergrund" % label)
		assert_true(result.state == null, "%s: kein teilweise geladener Zustand" % label)


# --- 51–52 Sichtbarkeit -----------------------------------------------------------------------------------

func test_no_secrets_in_public_or_other_actor_events() -> void:
	# 51, 52: Vorbild 4 stirbt nachts; niemand nominiert 4 oder 6.
	var run := _replay_ok(_concat(_bound(4, _k6one()), [Command.begin_step(PACK_1), Command.answer_prompt(2, [4]), Command.end_night(),
		Command.nominate(3, 1), Command.decide_execution(1), Command.end_day()] as Array[Command]), "Partie")
	if not run.ok:
		return
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			assert_eq(_find_forbidden(e.data), "", "öffentliches %s ohne Geheimnis" % e.type)
			assert_false(_contains_int(e.data, 4) or _contains_int(e.data, 6), "öffentliches %s ohne Vorbild- oder Wolfskind-ID" % e.type)
		elif e.visibility == &"actor":
			assert_false(_json(e.data).contains("model") or _json(e.data).contains("transform"), "%s ohne Bindung" % e.type)
			if e.actor_id != 4:
				assert_false(_contains_int(e.data, 4), "%s an %d ohne Vorbild-ID" % [e.type, e.actor_id])
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")
	for type: String in ["WolfChildBound", "WolfChildTransformed", "PromptOpened", "PromptAnswered"]:
		for e: GameEvent in events_of_type(run.events, type):
			assert_eq(String(e.visibility), "gm", "%s nur für Spielleiter" % type)


func _contains_int(value: Variant, needle: int) -> bool:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			if _contains_int(value[k], needle):
				return true
	elif value is Array:
		for v: Variant in (value as Array):
			if _contains_int(v, needle):
				return true
	elif DictRead.is_int_like(value):
		return int(value) == needle
	return false


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
