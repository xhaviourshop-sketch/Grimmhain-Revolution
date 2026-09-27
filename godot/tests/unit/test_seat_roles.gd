extends TestCase
## Rollen mit Sitznachbarn und passive Rolle aus dem Rollenaudit (DECISION-LOG „Rollenaudit ·
## Waldläufer, Doktor, Sitznachbarn …“, 27.09.2026). Nachbarn = nächste lebende Personen links
## und rechts im Sitzkreis (RM-DR-003).
##   Wahnsinniger Kutscher: „Wird er gelyncht, sterben beide direkten Nachbarn mit ihm.“ Nur Lynch
##     (auch Spielleiter-Hinrichtung), nicht Spiegelung; Nachbarn sterben mit `COACHMAN_CRASH`.
##   Nachtwächter: „… spürt, wenn ein Nachbar nicht ins Dorf gehört. Es ertönen öffentlich die
##     Alarmglocken.“ Jeden Morgen nach der Morgenauflösung, Wolf oder Einzelsieg, ohne Seite/Namen.
##   Dorfwache: „Stirbt nicht, wenn er nachts Ziel der Werwölfe wird.“ Nur der Rudelangriff.

const KU := "wahnsinniger-kutscher"
const NW := "nachtwaechter"
const DW := "dorfwache"


func _start(roles: Array, seat_order: Array = []) -> Command:
	var payload := Fixtures.start_roles(roles, 1).payload.duplicate(true)
	if not seat_order.is_empty():
		payload["seat_order"] = seat_order
	return Command.start_game(payload)


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _run(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _to_day(start: Command) -> Array[Command]:
	return [start, Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]


## Ereignisse nur des letzten Befehls.
func _last(cmds: Array[Command]) -> CommandResult:
	var before := RulesEngine.replay(cmds.slice(0, cmds.size() - 1))
	assert_true(before.ok, "Vorlauf angenommen (%s @ %d)" % [before.error, before.failed_index])
	return apply_ok(before.state, cmds[cmds.size() - 1], "letzter Befehl") if before.ok else null


func _deaths(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events_of_type(events, "SeatDied"):
		out.append([int(e.data["target_id"]), String(e.data["cause"])])
	return out


func _roundtrip(run: ReplayResult, commands: Array[Command], label: String) -> void:
	var loaded := StateCodec.decode(StateCodec.encode(run.state, commands))
	assert_true(loaded.ok, "%s: Spielstand lädt (%s)" % [label, loaded.error])
	if loaded.ok:
		assert_eq(events_json(loaded.events), events_json(run.events), "%s: Replay-Ereignisse identisch" % label)


func test_production_roles() -> void:
	for role: String in [KU, NW, DW]:
		assert_true(RoleCatalog.has_role(StringName(role)), "%s im Katalog" % role)
		assert_eq(RoleCatalog.faction_of(StringName(role)), Faction.VILLAGE, "%s Dorf" % role)
		assert_false(RoleCatalog.counts_as_wolf(StringName(role)), "%s kein Wolf" % role)
		assert_eq(RoleCatalog.night_priority(StringName(role)), 0, "%s ohne Nachtschritt" % role)


# --- Wahnsinniger Kutscher ------------------------------------------------------------------------

func test_coachman_lynch_kills_nearest_living_neighbours() -> void:
	# Sitzkreis 1..8 (ID = Sitz). 4 Kutscher; 3 ist tot → links stirbt 2, rechts 5.
	var cmds := _to_day(_start(["werwolf", "dorfbewohner", "dorfbewohner", KU, "dorfbewohner", "dorfbewohner", "werwolf", "dorfbewohner"]))
	cmds.append_array([_gm("kill", {"target_id": 3, "trigger_effects": false}), Command.nominate(6, 4), Command.decide_execution(4)])
	var run := _run(cmds, "Lynch")
	var last := _last(cmds)
	if not run.ok or last == null:
		return
	assert_eq(_deaths(last.events), [[4, "LYNCH"], [5, "COACHMAN_CRASH"], [2, "COACHMAN_CRASH"]], "Kutscher, dann rechter und linker nächster Lebender")
	assert_eq(run.state.players[5].death.source_id, 4, "Quelle Kutscher")
	_roundtrip(run, cmds, "Kutscher")


func test_coachman_neighbours_follow_seat_order_not_ids() -> void:
	# Sitzreihenfolge 1, 5, 3, 7, 2, 6, 4, 8 → Nachbarn von 3 sind 5 und 7.
	var cmds := _to_day(_start(["werwolf", "dorfbewohner", KU, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner", "werwolf"], [1, 5, 3, 7, 2, 6, 4, 8]))
	cmds.append_array([Command.nominate(2, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Sitzfolge")
	if run.ok:
		assert_false(run.state.players[5].alive or run.state.players[7].alive, "5 und 7 sterben")
		assert_true(run.state.players[2].alive and run.state.players[4].alive, "2 und 4 leben (ID-Nachbarn, nicht Sitznachbarn)")


func test_coachman_gm_execute_and_not_other_deaths() -> void:
	var roles := ["werwolf", "dorfbewohner", KU, "dorfbewohner", "dorfbewohner", "dorfbewohner", "werwolf"]
	var gm_exec := _to_day(_start(roles))
	gm_exec.append(_gm("execute", {"target_id": 3}))
	var run := _run(gm_exec, "Spielleiter-Hinrichtung")
	if run.ok:
		assert_false(run.state.players[2].alive or run.state.players[4].alive, "Nachbarn sterben auch bei Hinrichtung per Korrektur")
	var gm_kill := _to_day(_start(roles))
	gm_kill.append(_gm("kill", {"target_id": 3, "trigger_effects": true}))
	run = _run(gm_kill, "Korrektur-Tötung")
	if run.ok:
		assert_true(run.state.players[2].alive and run.state.players[4].alive, "keine Wirkung ohne Lynch")
	var pack: Array[Command] = [_start(roles), Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night()]
	run = _run(pack, "Rudel")
	if run.ok:
		assert_true(run.state.players[2].alive and run.state.players[4].alive, "keine Wirkung bei Rudeltod")


func test_coachman_mirrored_is_not_lynched() -> void:
	var cmds := _to_day(_start(["spiegelwolf", "dorfbewohner", KU, "dorfbewohner", "dorfbewohner", "dorfbewohner", "werwolf"]))
	cmds.append_array([Command.nominate(3, 1), Command.decide_execution(1)])
	var run := _run(cmds, "Spiegelung")
	if run.ok:
		assert_eq(String(run.state.players[3].death.cause), "SPIEGELWOLF_RETALIATE", "Kutscher stirbt durch Spiegelung")
		assert_true(run.state.players[2].alive and run.state.players[4].alive, "Nachbarn leben")


func test_coachman_neighbour_reacts_and_single_other() -> void:
	# Nachbar 2 ist Sensenträger: Reaktion sofort am Tag. Siegkandidat erst nach der Reaktion.
	var cmds := _to_day(_start(["werwolf", "sensentraeger", KU, "dorfbewohner", "dorfbewohner", "dorfbewohner", "werwolf"]))
	cmds.append_array([Command.nominate(4, 3), Command.decide_execution(3)])
	var run := _run(cmds, "Reaktion")
	if not run.ok:
		return
	assert_eq(run.state.reactions.size(), 1, "Sensenträger-Reaktion eingereiht")
	assert_eq(run.state.open_candidates().size(), 0, "kein Kandidat bei offener Reaktion")
	# Nur zwei Lebende: Kutscher und eine andere Person → genau ein Mittod.
	var few := _to_day(_start([KU, "werwolf", "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]))
	var s := _run(few, "wenige").state
	if s == null:
		return
	for id: int in [3, 4, 5, 6]:
		s = apply_ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Tod %d" % id).state
		if not s.open_candidates().is_empty():
			s = apply_ok(s, Command.create(Command.REJECT_WIN, {"reason": "weiter"}), "Ablehnung").state
	s = apply_ok(s, Command.nominate(2, 1), "Nominierung").state
	var r := apply_ok(s, Command.decide_execution(1), "Hinrichtung")
	assert_eq(_deaths(r.events), [[1, "LYNCH"], [2, "COACHMAN_CRASH"]], "derselbe Nachbar auf beiden Seiten stirbt einmal")


# --- Nachtwächter -------------------------------------------------------------------------------------

func _alarm(events: Array[GameEvent]) -> Array[GameEvent]:
	return events_of_type(events, "AlarmBells")


func test_watchman_rings_for_wolf_or_solo_neighbour() -> void:
	# 2 Nachtwächter zwischen 1 (Werwolf) und 3 (Dorf).
	var run := _run(_to_day(_start(["werwolf", NW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"])), "Wolf")
	if run.ok:
		var alarm := _alarm(run.events)
		assert_eq(alarm.size(), 1, "Glocken am Morgen")
		if alarm.size() == 1:
			assert_eq(alarm[0].visibility, Visibility.PUBLIC, "öffentlich")
			assert_false(alarm[0].data.has("watchman_ids") or alarm[0].data.has("neighbour_ids"), "ohne Namen und Seite")
		var gm := events_of_type(run.events, "AlarmBellsDetail")
		assert_true(gm.size() == 1 and gm[0].visibility == Visibility.GM, "Details nur für den Spielleiter")
	var solo := _run(_to_day(_start(["dorfbewohner", NW, "manipulator", "werwolf", "dorfbewohner", "dorfbewohner"])), "Solo")
	if solo.ok:
		assert_eq(_alarm(solo.events).size(), 1, "Einzelsieg-Nachbar löst aus")
	var quiet := _run(_to_day(_start(["dorfbewohner", NW, "dorfbewohner", "werwolf", "dorfbewohner", "dorfbewohner"])), "ruhig")
	if quiet.ok:
		assert_eq(_alarm(quiet.events).size(), 0, "nur Dorf-Nachbarn: keine Glocken")


func test_watchman_skips_dead_seats_and_needs_to_live() -> void:
	# 3 ist tot → nächster rechter Lebender 4 ist Wolf.
	var cmds: Array[Command] = [_start(["dorfbewohner", NW, "dorfbewohner", "werwolf", "dorfbewohner", "dorfbewohner"]),
		_gm("kill", {"target_id": 3, "trigger_effects": false}), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]
	var run := _run(cmds, "tote Plätze")
	if run.ok:
		assert_eq(_alarm(run.events).size(), 1, "nächster Lebender zählt")
	var dead: Array[Command] = [_start(["werwolf", NW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, [2]), Command.end_night()]
	run = _run(dead, "toter Nachtwächter")
	if run.ok:
		assert_eq(_alarm(run.events).size(), 0, "stirbt der Nachtwächter in der Nacht, läutet nichts")


func test_watchman_every_morning_and_two_watchmen_one_bell() -> void:
	var cmds := _to_day(_start([NW, "werwolf", NW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]))
	cmds.append_array([Command.decide_execution(-1), Command.end_day(), Command.start_night(), Command.skip_step("night:2:0:pack", "kein Opfer"), Command.end_night()])
	var run := _run(cmds, "zwei Morgen")
	if run.ok:
		assert_eq(_alarm(run.events).size(), 2, "je Morgen genau eine öffentliche Glocke, auch bei zwei Nachtwächtern")
		_roundtrip(run, cmds, "Nachtwächter")


# --- Dorfwache ---------------------------------------------------------------------------------------

func test_guard_survives_pack_attack_only() -> void:
	var cmds: Array[Command] = [_start(["werwolf", "werwolf", DW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, [3]), Command.end_night()]
	var run := _run(cmds, "Rudel")
	if not run.ok:
		return
	assert_true(run.state.players[3].alive, "überlebt den Rudelangriff")
	var prevented := events_of_type(run.events, "KillPrevented")
	assert_true(prevented.size() == 1 and (prevented[0].data["sources"] as Array).has("dorfwache") and prevented[0].visibility == Visibility.GM, "abgewehrt, nur Spielleiter")
	var lynch := cmds.duplicate()
	lynch.append_array([Command.nominate(4, 3), Command.decide_execution(3)])
	run = _run(lynch, "Lynch")
	if run.ok:
		assert_false(run.state.players[3].alive, "Hinrichtung tötet")


func test_guard_dies_by_poison_and_witch_can_heal() -> void:
	# 3 Dorfwache, 4 Waldhexe. Rudel greift 3 an; Waldhexe heilt (verbraucht) → zwei Quellen, ein Abfangen.
	var cmds: Array[Command] = [_start(["werwolf", "werwolf", DW, "waldhexe", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_prompt(1, [3]), Command.begin_step("night:1:1:waldhexe:4"),
		Command.answer_choice(2, "heal", true), Command.answer_choice(2, "reveal", true), Command.answer_choice(2, "poison", false),
		Command.answer_choice(2, "confirm", true), Command.end_night()]
	var run := _run(cmds, "Heilung")
	if run.ok:
		var prevented := events_of_type(run.events, "KillPrevented")
		assert_true(prevented.size() == 1 and (prevented[0].data["sources"] as Array).size() == 2, "Waldhexe und Dorfwache, genau ein Abfangen")
		assert_eq(int(run.state.players[4].ability_uses.get("waldhexe:heal", 0)), 1, "Heiltrank verbraucht")
	var poison: Array[Command] = [_start(["werwolf", "werwolf", DW, "waldhexe", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.begin_step("night:1:1:waldhexe:4"),
		Command.answer_choice(2, "poison", true), Command.answer_stage_targets(2, "poison_target", [3]), Command.answer_choice(2, "confirm", true), Command.end_night()]
	run = _run(poison, "Gift")
	if run.ok:
		assert_false(run.state.players[3].alive, "Gift tötet die Dorfwache")


func test_apprentice_inherits_guard_immunity_immediately() -> void:
	# Lehrling 3 bindet an Dorfwache 4; 4 stirbt am Tag; in der nächsten Nacht greift das Rudel 3 an.
	var cmds: Array[Command] = [_start(["werwolf", "werwolf", "lehrling", DW, "dorfbewohner", "dorfbewohner", "dorfbewohner", "dorfbewohner"]),
		Command.start_night(), Command.answer_stage_targets(1, "candidates", [1, 4, 5])]
	var run := _run(cmds, "Kandidaten")
	if not run.ok:
		return
	var options: Array = run.state.pending_prompt.partial["options"]
	cmds.append_array([Command.create(Command.ANSWER_PROMPT, {"prompt_id": 1, "stage": "option", "option": options.find(DW)}),
		Command.answer_choice(1, "confirm", true), Command.skip_step("night:1:1:pack", "kein Opfer"), Command.end_night(),
		Command.nominate(5, 4), Command.decide_execution(4), Command.end_day(), Command.start_night(), Command.answer_prompt(2, [3]), Command.end_night()])
	run = _run(cmds, "Erbe")
	if run.ok:
		assert_eq(String(run.state.players[3].role_id), DW, "Lehrling ist Dorfwache")
		assert_true(run.state.players[3].alive, "geerbte Immunität wirkt")
