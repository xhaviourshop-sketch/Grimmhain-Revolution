extends TestCase
## Produktionsrolle `waldhexe` (Forest Witch), rules-register.md §6, DR-06.
## W6:  1, 2 Werwölfe; 3 Schutzengel; 4 Dorfbewohner; 5 Waldhexe; 6 Dorfbewohner
##      (entspricht B6 aus acceptance-scenarios.md ohne noch nicht umgesetzte Rollen).
## W7R: wie W6, zusätzlich 7 Sensenträger.
## W2H: 1, 2 Werwölfe; 3 Waldhexe; 4 Dorfbewohner; 5 Waldhexe; 6 Dorfbewohner.
## Nacht 1 in W6: Prompt 1 Schutzengel, Prompt 2 Rudel, Prompt 3 Waldhexe.
## Die Tests greifen über Befehlsnutzdaten und die Serialisierung auf neue Felder zu.

const GUARD_1 := "night:1:0:schutzengel:3"
const PACK_1 := "night:1:1:pack"
const WITCH_1 := "night:1:2:waldhexe:5"
const WITCH_PROMPT := 3
const FORBIDDEN_PUBLIC := ["waldhexe", "witch", "heal", "poison", "rescue", "potion", "saved", "victim", "schutzengel",
	"guardian", "protect", "prevent", "werwolf", "dorfbewohner", "sensentraeger", "role", "cause", "targets", "stage", "allowed"]


func _w6(seed_value: int = 1) -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "dorfbewohner", "waldhexe", "dorfbewohner"], seed_value)


func _w7r() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "schutzengel", "dorfbewohner", "waldhexe", "dorfbewohner", "sensentraeger"])


func _w2h() -> Command:
	return Fixtures.start_roles(["werwolf", "werwolf", "waldhexe", "dorfbewohner", "waldhexe", "dorfbewohner"])


func _concat(a: Array[Command], b: Array[Command]) -> Array[Command]:
	var out: Array[Command] = a.duplicate()
	out.append_array(b)
	return out


## Antwort auf eine Ja/Nein- oder Bestätigungsstufe des mehrstufigen Prompts.
func _choice(stage: String, choice: bool, prompt_id: int = WITCH_PROMPT) -> Command:
	return Command.create(Command.ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": stage, "choice": choice})


## Antwort auf eine Auswahlstufe des mehrstufigen Prompts.
func _pick(stage: String, targets: Array, prompt_id: int = WITCH_PROMPT) -> Command:
	return Command.create(Command.ANSWER_PROMPT, {"prompt_id": prompt_id, "stage": stage, "targets": targets})


## Nacht 1 bis zum begonnenen Waldhexenschritt: Schutz auf `protect`, Rudel wählt `victim` (-1 = kein Opfer).
func _to_witch(start: Command, protect: int, victim: int) -> Array[Command]:
	return [start, Command.start_night(), Command.answer_prompt(1, [protect]), Command.begin_step(PACK_1),
		Command.answer_prompt(2, [] if victim < 0 else [victim]), Command.begin_step(WITCH_1)]


## Vollständige Waldhexenantwort: Rettung ja/nein, Giftziel (-1 = kein Gift), Bestätigung.
func _decide(heal: bool, poison_target: int, heal_offered: bool = true, poison_offered: bool = true, prompt_id: int = WITCH_PROMPT) -> Array[Command]:
	var out: Array[Command] = []
	if heal_offered:
		out.append(_choice("heal", heal, prompt_id))
		if heal:
			out.append(_choice("reveal", true, prompt_id))
	if poison_offered:
		out.append(_choice("poison", poison_target >= 0, prompt_id))
		if poison_target >= 0:
			out.append(_pick("poison_target", [poison_target], prompt_id))
	out.append(_choice("confirm", true, prompt_id))
	return out


## Nacht 1 in W6 vollständig bis nach der Waldhexe (Schutz auf `protect`, Rudel `victim`).
func _night(protect: int, victim: int, heal: bool, poison_target: int, start: Command = null) -> Array[Command]:
	return _concat(_to_witch(start if start != null else _w6(), protect, victim), _decide(heal, poison_target, victim >= 0))


func _replay_ok(commands: Array[Command], label: String) -> ReplayResult:
	var run := RulesEngine.replay(commands)
	assert_true(run.ok, "%s: Befehle angenommen (%s @ %d)" % [label, run.error, run.failed_index])
	return run


func _stage(s: GameState) -> String:
	return str(s.pending_prompt.to_dict().get("stage", "")) if s.pending_prompt != null else ""


func _uses(s: GameState, witch: int, potion: String) -> int:
	return int(s.players[witch].ability_uses.get("waldhexe:%s" % potion, 0))


func _actions(s: GameState) -> Array:
	return s.to_dict().get("witch_actions", [])


func _json(value: Variant) -> String:
	return CanonicalJson.stringify(value)


# --- 1–8 Rolle, Nachtplan, entfallende Schritte -------------------------------------

func test_production_role() -> void:
	# 1
	var r := apply_ok(GameState.new(), _w6(), "Spielaufbau ohne Testmodus")
	if not r.ok:
		return
	var p := r.state.players[5]
	assert_eq(String(p.role_id), "waldhexe", "Rolle")
	assert_eq(String(p.faction), "village", "Dorf")
	assert_false(p.counts_as_wolf, "kein Wolf")
	assert_eq(String(p.appears_as), "waldhexe", "Erscheinung für Informationsrollen")
	assert_eq(_uses(r.state, 5, "heal") + _uses(r.state, 5, "poison"), 0, "beide Tränke unverbraucht")


func test_night_order_guard_pack_witch() -> void:
	# 2
	var run := _replay_ok(_to_witch(_w6(), 6, 4), "bis zur Waldhexe")
	if not run.ok:
		return
	var s := run.state
	assert_eq(s.night_plan, [&"schutzengel:3", &"pack", &"waldhexe:5"] as Array[StringName], "Schutzengel, Rudel, Waldhexe")
	assert_eq(s.pending_prompt.step_id, WITCH_1, "Waldhexenschritt nach dem Rudel")
	assert_eq(int(s.pending_prompt.actor_id), 5, "handelnde Person")
	assert_eq(String(s.pending_prompt.owner), "waldhexe", "Besitzer")
	assert_true(s.pending_prompt.cancellable, "vor der Bestätigung abbrechbar")


func test_multiple_witches_by_id() -> void:
	# 3: stabile Reihenfolge; Gift der ersten Hexe auf die zweite lässt deren Schritt entfallen.
	var run := _replay_ok([_w2h(), Command.start_night()] as Array[Command], "zwei Waldhexen")
	if not run.ok:
		return
	assert_eq(run.state.night_plan, [&"pack", &"waldhexe:3", &"waldhexe:5"] as Array[StringName], "nach Personen-ID")
	var s := apply_ok(run.state, Command.answer_prompt(1, [6]), "Rudel wählt 6").state
	assert_eq(RulesEngine.next_step_id(s), "night:1:1:waldhexe:3", "erste Waldhexe")
	s = apply_ok(s, Command.begin_step("night:1:1:waldhexe:3"), "erste Waldhexe beginnt").state
	assert_eq(int(s.pending_prompt.actor_id), 3, "erste handelt")
	var r: CommandResult = null
	for c: Command in _decide(false, 5, true, true, 2):
		r = apply_ok(s, c, "erste Waldhexe vergiftet 5")
		if not r.ok:
			return
		s = r.state
	assert_false(s.players[5].alive, "zweite Waldhexe tot")
	var dropped := events_of_type(r.events, "StepDropped")
	assert_true(dropped.size() == 1 and String(dropped[0].data["step_id"]) == "night:1:2:waldhexe:5"
		and String(dropped[0].data["reason"]) == "actor_dead", "Schritt der toten Waldhexe entfällt protokolliert")
	assert_eq(String(s.night_step_status[2]), "skipped", "Status")
	assert_eq(RulesEngine.next_step_id(s), "", "kein weiterer Schritt")
	apply_ok(s, Command.end_night(), "Nacht endet")


func test_no_step_without_living_witch() -> void:
	# 4: Waldhexe stirbt in Nacht 1 durch das Rudel; Nacht 2 ohne Waldhexenschritt.
	var run := _replay_ok(_concat(_night(6, 5, false, -1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night()] as Array[Command]), "Nacht 2")
	if run.ok:
		assert_false(run.state.players[5].alive, "Waldhexe tot")
		assert_eq(run.state.night_plan, [&"schutzengel:3", &"pack"] as Array[StringName], "kein Waldhexenschritt")


func test_dead_witch_before_step_does_not_act() -> void:
	# 5: Tod nach der Rudelwahl, vor dem eigenen Schritt.
	var s := Fixtures.play([_w6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1), Command.answer_prompt(2, [4])] as Array[Command])
	assert_eq(RulesEngine.next_step_id(s), WITCH_1, "Waldhexe wäre dran")
	var r := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false}), "Waldhexe stirbt")
	var dropped := events_of_type(r.events, "StepDropped")
	assert_true(dropped.size() == 1 and String(dropped[0].data["step_id"]) == WITCH_1 and String(dropped[0].data["reason"]) == "actor_dead", "Schritt entfällt protokolliert")
	assert_eq(String(dropped[0].visibility) if dropped.size() == 1 else "", "gm", "nur Spielleiter")
	assert_eq(String(r.state.night_step_status[2]), "skipped", "Status übersprungen")
	assert_eq(RulesEngine.next_step_id(r.state), "", "kein Schritt mehr")
	apply_rejected(r.state, Command.begin_step(WITCH_1), "no_pending_step", "nicht mehr beginnbar")
	var dawn := apply_ok(r.state, Command.end_night(), "Nacht endet")
	assert_false(dawn.state.players[4].alive, "keine Rettung")
	# Variante: Tod bei offenem Prompt bricht ihn ab, der Schritt entfällt ebenfalls.
	var open := Fixtures.play(_to_witch(_w6(), 6, 4))
	var r2 := apply_ok(open, CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false}), "Tod bei offenem Prompt")
	assert_eq(events_of_type(r2.events, "PromptCancelled").size(), 1, "Prompt abgebrochen")
	assert_eq(events_of_type(r2.events, "StepDropped").size(), 1, "Schritt entfällt")
	assert_true(r2.state.pending_prompt == null and RulesEngine.next_step_id(r2.state) == "", "kein veralteter Prompt")


func test_both_potions_used_no_later_step() -> void:
	# 6
	var run := _replay_ok(_concat(_night(6, 4, true, 1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night()] as Array[Command]), "Nacht 2")
	if not run.ok:
		return
	assert_eq(_uses(run.state, 5, "heal"), 1, "Heiltrank verbraucht")
	assert_eq(_uses(run.state, 5, "poison"), 1, "Gifttrank verbraucht")
	assert_eq(run.state.night_plan, [&"schutzengel:3", &"pack"] as Array[StringName], "kein sinnloser Schritt")


func test_no_victim_and_poison_used_no_step() -> void:
	# 7: Nacht 1 Gift auf 1; Nacht 2 Rudel ohne Opfer.
	var commands := _concat(_night(6, 4, false, 1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night(), Command.answer_prompt(4, [6]), Command.begin_step("night:2:1:pack")] as Array[Command])
	var s := Fixtures.play(commands)
	assert_eq(s.night_plan, [&"schutzengel:3", &"pack", &"waldhexe:5"] as Array[StringName], "Heiltrank noch da")
	var r := apply_ok(s, Command.answer_prompt(5, []), "Rudel ohne Opfer")
	var dropped := events_of_type(r.events, "StepDropped")
	assert_true(dropped.size() == 1 and String(dropped[0].data["step_id"]) == "night:2:2:waldhexe:5"
		and String(dropped[0].data["reason"]) == "no_decision", "Schritt entfällt ohne mögliche Entscheidung")
	assert_eq(RulesEngine.next_step_id(r.state), "", "kein Waldhexenschritt angeboten")
	apply_ok(r.state, Command.end_night(), "Nacht endet")


func test_no_victim_poison_available() -> void:
	# 8
	var s := Fixtures.play(_to_witch(_w6(), 6, -1))
	assert_true(s != null and s.pending_prompt != null, "Waldhexe dran")
	if s == null or s.pending_prompt == null:
		return
	assert_eq(int(s.pending_prompt.partial.get("victim_id", 0)), -1, "kein Opfer")
	assert_eq(_stage(s), "poison", "direkt Giftentscheidung")
	apply_rejected(s, _choice("heal", true), "stage_mismatch", "Rettung ohne Opfer")
	var run := _replay_ok(_concat(_to_witch(_w6(), 6, -1), _decide(false, 1, false)), "Gift ohne Rudelopfer")
	if run.ok:
		assert_false(run.state.players[1].alive, "Gift wirkt")
		assert_eq(_uses(run.state, 5, "heal"), 0, "Heiltrank nicht verbraucht")


# --- 9–16 Rettung, Gift, Offenlegung -------------------------------------------------

func test_sees_only_victim_id_before_decision() -> void:
	# 9, AS-R08: Opfer 3 (Schutzengel) hat eine unterscheidbare Rolle.
	var s := Fixtures.play(_to_witch(_w6(), 6, 3))
	assert_eq(_stage(s), "heal", "Rettungsentscheidung")
	assert_eq(int(s.pending_prompt.partial.get("victim_id", 0)), 3, "Opfer-ID sichtbar")
	assert_false(_json(s.pending_prompt.to_dict()).contains("schutzengel"), "keine Rolle vor der Entscheidung")
	assert_false(s.pending_prompt.partial.has("victim_role"), "kein Rollenfeld")
	var no := apply_ok(s, _choice("heal", false), "retten = nein").state
	assert_eq(_stage(no), "poison", "weiter zum Gift")
	assert_false(_json(no.pending_prompt.to_dict()).contains("schutzengel"), "auch nach Nein keine Rolle")


func test_role_revealed_after_rescue() -> void:
	# 10, AS-R08 Variante, AS-R05
	var s := Fixtures.play(_to_witch(_w6(), 6, 3))
	var yes := apply_ok(s, _choice("heal", true), "retten = ja").state
	assert_eq(_stage(yes), "reveal", "Rolle offenlegen")
	assert_eq(str(yes.pending_prompt.partial.get("victim_role", "")), "schutzengel", "Rolle des Opfers")
	var run := _replay_ok(_concat(_to_witch(_w6(), 6, 3), _decide(true, -1)), "Rettung bestätigt")
	if not run.ok:
		return
	var acted := events_of_type(run.events, "WitchActed")
	assert_true(acted.size() == 1 and str(acted[0].data.get("saved_role", "")) == "schutzengel", "Rolle GM-intern protokolliert")
	assert_true(acted.size() == 1 and String(acted[0].visibility) == "gm", "nur Spielleiter")


func test_heal_alone_prevents_pack_attack() -> void:
	# 11, AS-R05
	var run := _replay_ok(_night(2, 6, true, -1), "Rettung ohne Gift")
	if not run.ok:
		return
	assert_eq(_uses(run.state, 5, "heal"), 1, "Heiltrank verbraucht")
	assert_eq(_uses(run.state, 5, "poison"), 0, "Gifttrank unverbraucht")
	var actions := _actions(run.state)
	assert_eq(actions.size(), 1, "Entscheidung gespeichert")
	if actions.size() == 1:
		var a: Dictionary = actions[0]
		assert_true(int(a["witch_id"]) == 5 and int(a["saved_id"]) == 6 and int(a["night"]) == 1 and bool(a["heal_used"])
			and not bool(a["poison_used"]) and int(a["poison_target_id"]) == -1, "Rettungsdatensatz")
	assert_true(run.state.players[6].alive, "noch lebt 6")
	var dawn := apply_ok(run.state, Command.end_night(), "Morgen")
	assert_true(dawn.state.players[6].alive, "6 überlebt")
	var prevented := events_of_type(dawn.events, "KillPrevented")
	assert_eq(prevented.size(), 1, "ein verhinderter Angriff")
	if prevented.size() == 1:
		var d: Dictionary = prevented[0].data
		assert_eq(d.get("sources"), ["waldhexe"], "Quelle Rettung, kein Schutzengel")
		assert_eq(d.get("rescuer_ids"), [5], "rettende Waldhexe")
		assert_eq(d.get("guardian_ids"), [], "kein Schutzengel")
	assert_eq(events_of_type(dawn.events, "SeatDied").size(), 0, "kein Tod")
	assert_true(_actions(dawn.state).is_empty(), "Rettung endet mit Tagesbeginn")


func test_poison_alone_kills_immediately() -> void:
	# 12, AS-R06
	var commands := _concat(_to_witch(_w6(), 2, 6), _decide(false, 1))
	var before := Fixtures.play(commands.slice(0, commands.size() - 1))
	var r := apply_ok(before, commands[commands.size() - 1], "Bestätigung")
	assert_false(r.state.players[1].alive, "1 stirbt sofort")
	var died := events_of_type(r.events, "SeatDied")
	assert_true(died.size() == 1 and String(died[0].data["cause"]) == "WITCH_POISON" and String(died[0].data["source_kind"]) == "player"
		and int(died[0].data["source_id"]) == 5 and String(died[0].data["phase"]) == "NIGHT", "Gifttod mit Quelle Waldhexe")
	assert_eq(String(r.state.phase), "NIGHT", "noch Nacht")
	assert_eq(_uses(r.state, 5, "poison"), 1, "Gifttrank verbraucht")
	assert_eq(_uses(r.state, 5, "heal"), 0, "Heiltrank unverbraucht")
	var dawn := apply_ok(r.state, Command.end_night(), "Morgen")
	assert_false(dawn.state.players[6].alive, "6 stirbt am Morgen")
	assert_eq(String(dawn.state.players[6].death.cause), "NIGHT_KILL", "Rudelangriff")
	assert_true(dawn.state.win_candidate == null, "kein Siegkandidat (1 Wolf gegen 3)")


func test_heal_and_poison_same_night() -> void:
	# 13, AS-R39
	var run := _replay_ok(_concat(_night(2, 6, true, 1), [Command.end_night()] as Array[Command]), "beide Tränke")
	if not run.ok:
		return
	assert_false(run.state.players[1].alive, "Gift wirkt")
	assert_true(run.state.players[6].alive, "Rettung wirkt")
	assert_eq(_uses(run.state, 5, "heal") + _uses(run.state, 5, "poison"), 2, "beide verbraucht")


func test_heal_and_poison_same_person() -> void:
	# 14: Gift tötet sofort, die Rettung läuft am Morgen ins Leere.
	var run := _replay_ok(_concat(_night(2, 6, true, 6), [Command.end_night()] as Array[Command]), "gleiche Person")
	if not run.ok:
		return
	assert_false(run.state.players[6].alive, "Gift tötet")
	assert_eq(String(run.state.players[6].death.cause), "WITCH_POISON", "erste Ursache gilt")
	assert_eq(events_of_type(run.events, "KillIgnored").size(), 1, "Rudelangriff ins Leere")
	assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "nichts verhindert")
	assert_eq(_uses(run.state, 5, "heal") + _uses(run.state, 5, "poison"), 2, "beide verbraucht")


func test_poison_self() -> void:
	# 15
	var run := _replay_ok(_concat(_to_witch(_w6(), 6, -1), _decide(false, 5, false)), "Gift auf sich selbst")
	if not run.ok:
		return
	assert_false(run.state.players[5].alive, "Waldhexe tot")
	assert_eq(int(run.state.players[5].death.source_id), 5, "Quelle sie selbst")
	assert_eq(String(run.state.night_step_status[2]), "done", "Schritt erledigt")
	apply_ok(run.state, Command.end_night(), "Nacht endet")


func test_poison_reaper_reacts_at_dawn() -> void:
	# 16, 34, AS-R37 mit echtem Gifttod
	var commands := _concat(_to_witch(_w7r(), 6, 4), _decide(false, 7))
	var before := Fixtures.play(commands.slice(0, commands.size() - 1))
	var r := apply_ok(before, commands[commands.size() - 1], "Gift auf Sensenträger")
	var types: Array[String] = []
	for e: GameEvent in r.events:
		types.append(String(e.type))
	assert_eq(types, ["PromptAnswered", "WitchActed", "SeatDied", "ReactionQueued", "WinStatusProvisional"] as Array[String], "Ereignisreihenfolge")
	assert_eq(r.state.reactions.size(), 1, "Reaktion eingereiht")
	assert_eq(String(r.state.phase), "NIGHT", "noch Nacht")
	assert_eq(RulesEngine.next_step_id(r.state), "", "keine Reaktion in der Nacht")
	apply_rejected(r.state, Command.begin_step("reaction:1"), "no_pending_step", "nicht mitten in der Nacht")
	var dawn := apply_ok(r.state, Command.end_night(), "Morgen")
	assert_eq(String(dawn.state.phase), "DAWN_RESOLUTION", "Morgenauflösung wartet")
	assert_eq(RulesEngine.next_step_id(dawn.state), "reaction:1", "Reaktion jetzt fällig")
	var again := RulesEngine.apply(before, commands[commands.size() - 1])
	assert_eq(events_json(again.events), events_json(r.events), "deterministisch")


# --- 17–21 Schutzengel ---------------------------------------------------------------

func test_guard_does_not_prevent_poison() -> void:
	# 17, AS-R32
	var run := _replay_ok(_concat(_to_witch(_w6(), 6, -1), _decide(false, 6, false)), "Gift auf Geschützten")
	if not run.ok:
		return
	assert_false(run.state.players[6].alive, "Schutz verhindert Gift nicht")
	assert_eq(String(run.state.players[6].death.cause), "WITCH_POISON", "Ursache Gift")
	assert_eq(events_of_type(run.events, "KillPrevented").size(), 0, "nichts verhindert")


func test_guard_and_heal_same_victim() -> void:
	# 18–21
	var run := _replay_ok(_concat(_night(6, 6, true, -1), [Command.end_night()] as Array[Command]), "Schutz und Rettung")
	if not run.ok:
		return
	assert_true(run.state.players[6].alive, "Opfer überlebt")
	assert_eq(_uses(run.state, 5, "heal"), 1, "Heiltrank trotzdem verbraucht")
	var prevented := events_of_type(run.events, "KillPrevented")
	assert_eq(prevented.size(), 1, "genau ein verhindertes Ergebnis")
	if prevented.size() == 1:
		var d: Dictionary = prevented[0].data
		assert_eq(d.get("sources"), ["schutzengel", "waldhexe"], "beide Quellen protokolliert")
		assert_eq(d.get("guardian_ids"), [3], "Schutzengel")
		assert_eq(d.get("rescuer_ids"), [5], "Waldhexe")
		assert_eq(String(prevented[0].visibility), "gm", "nur Spielleiter")
	assert_eq(events_of_type(run.events, "ProtectionSet").size(), 1, "Schutz protokolliert")
	assert_eq(events_of_type(run.events, "WitchActed").size(), 1, "Rettung protokolliert")
	assert_eq(events_of_type(run.events, "SeatDied").size(), 0, "kein Tod")
	assert_eq(events_of_type(run.events, "ReactionQueued").size(), 0, "keine Todesreaktion")
	assert_eq(events_of_type(run.events, "WinStatusProvisional").size(), 0, "keine vorläufige Siegprüfung")
	var s := Fixtures.play(_to_witch(_w6(), 6, 6))
	assert_false(_json(s.pending_prompt.to_dict()).contains("protect") or _json(s.pending_prompt.to_dict()).contains("guard"), "Hexe erfährt keinen Schutz")


# --- 22–26 Einmal-Nutzung, Wiederbelebung, Abbruch -----------------------------------

func test_used_heal_not_offered_again() -> void:
	# 22, AS-R07
	var commands := _concat(_night(2, 4, true, -1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night(), Command.answer_prompt(4, [4]), Command.begin_step("night:2:1:pack"), Command.answer_prompt(5, [6]),
		Command.begin_step("night:2:2:waldhexe:5")] as Array[Command])
	var s := Fixtures.play(commands)
	assert_true(s != null and s.pending_prompt != null, "Nacht 2 Waldhexe")
	if s == null or s.pending_prompt == null:
		return
	assert_eq(int(s.pending_prompt.partial.get("victim_id", 0)), 6, "Opfer sichtbar")
	assert_false(bool(s.pending_prompt.partial.get("heal_offered", true)), "retten nicht verfügbar")
	assert_true(bool(s.pending_prompt.partial.get("poison_offered", false)), "vergiften verfügbar")
	assert_eq(_stage(s), "poison", "Rettung wird übersprungen")
	apply_rejected(s, _choice("heal", true, 6), "stage_mismatch", "manipulierte Rettung")


func test_used_poison_not_offered_again() -> void:
	# 23
	var commands := _concat(_night(2, 4, false, 1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night(), Command.answer_prompt(4, [2]), Command.begin_step("night:2:1:pack"), Command.answer_prompt(5, [6]),
		Command.begin_step("night:2:2:waldhexe:5")] as Array[Command])
	var s := Fixtures.play(commands)
	assert_true(s != null and s.pending_prompt != null, "Nacht 2 Waldhexe")
	if s == null or s.pending_prompt == null:
		return
	assert_false(bool(s.pending_prompt.partial.get("poison_offered", true)), "Gift nicht verfügbar")
	var no := apply_ok(s, _choice("heal", false, 6), "retten = nein").state
	assert_eq(_stage(no), "confirm", "direkt zur Bestätigung")
	apply_rejected(no, _choice("poison", true, 6), "stage_mismatch", "manipuliertes Gift")


func test_revive_does_not_reset_potions() -> void:
	# 24: Rettung von 4 und Gift auf sich selbst, danach Wiederbelebung.
	var commands := _concat(_night(2, 4, true, 5), [Command.end_night(),
		CorrectionFixtures.gm("revive", {"target_id": 5}), Command.decide_execution(-1), Command.end_day(), Command.start_night()] as Array[Command])
	var run := _replay_ok(commands, "Wiederbelebung")
	if not run.ok:
		return
	assert_true(run.state.players[5].alive, "Waldhexe lebt")
	assert_eq(_uses(run.state, 5, "heal") + _uses(run.state, 5, "poison"), 2, "Tränke bleiben verbraucht")
	assert_false(run.state.night_plan.has(&"waldhexe:5"), "kein Schritt")


## Befehle innerhalb des Waldhexen-Prompts bis zur jeweiligen Stufe (W6, Rudel wählt 6).
func _stage_paths() -> Dictionary:
	return {
		"heal": [] as Array[Command],
		"reveal": [_choice("heal", true)] as Array[Command],
		"poison": [_choice("heal", true), _choice("reveal", true)] as Array[Command],
		"poison_target": [_choice("heal", false), _choice("poison", true)] as Array[Command],
		"confirm": [_choice("heal", true), _choice("reveal", true), _choice("poison", true), _pick("poison_target", [1])] as Array[Command],
	}


func test_cancel_at_every_stage_discards_partial() -> void:
	# 25, 26, AS-A02
	var before_begin := Fixtures.play(_to_witch(_w6(), 2, 6).slice(0, 5))
	assert_eq(RulesEngine.next_step_id(before_begin), WITCH_1, "vor Beginn")
	var paths := _stage_paths()
	for stage: String in paths:
		var s := Fixtures.play(_concat(_to_witch(_w6(), 2, 6), paths[stage]))
		assert_true(s != null and _stage(s) == stage, "%s: Stufe erreicht" % stage)
		if s == null:
			continue
		var r := apply_ok(s, Command.cancel_prompt(WITCH_PROMPT, "falsch aufgerufen"), "%s: Abbruch" % stage)
		var c := r.state
		assert_eq(c.content_hash(), before_begin.content_hash(), "%s: fachlicher Hash wie vor BeginStep" % stage)
		assert_eq(_uses(c, 5, "heal") + _uses(c, 5, "poison"), 0, "%s: kein Trank verbraucht" % stage)
		assert_true(_actions(c).is_empty(), "%s: keine Rettung gespeichert" % stage)
		assert_true(c.players[1].alive and c.players[6].alive, "%s: niemand stirbt" % stage)
		assert_eq(RulesEngine.next_step_id(c), WITCH_1, "%s: derselbe Schritt erneut" % stage)
		var again := apply_ok(c, Command.begin_step(WITCH_1), "%s: neu begonnen" % stage).state
		assert_eq(_stage(again), "heal", "%s: beginnt von vorn" % stage)
		assert_false(again.pending_prompt.partial.has("heal"), "%s: keine alte Teilantwort" % stage)


# --- 27–34 Save/Load und Replay --------------------------------------------------------

func _load_roundtrip(commands: Array[Command], label: String) -> LoadResult:
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


## Wendet `rest` auf Original und geladenen Zustand an und vergleicht Ereignisse und Endzustand.
func _continue_both(original: GameState, loaded: GameState, rest: Array[Command], label: String) -> GameState:
	var a := original
	var b := loaded
	var ea: Array[GameEvent] = []
	var eb: Array[GameEvent] = []
	for c: Command in rest:
		var ra := RulesEngine.apply(a, c)
		var rb := RulesEngine.apply(b, c)
		assert_true(ra.ok and rb.ok, "%s: %s angenommen (%s)" % [label, c.type, ra.error])
		if not (ra.ok and rb.ok):
			return null
		a = ra.state
		b = rb.state
		ea.append_array(ra.events)
		eb.append_array(rb.events)
	assert_eq(events_json(eb), events_json(ea), "%s: identische Fortsetzung" % label)
	assert_eq(_json(b.to_dict()), _json(a.to_dict()), "%s: identischer Endzustand" % label)
	return b


func test_save_load_at_every_stage() -> void:
	# 27, AS-A01
	var paths := _stage_paths()
	var full: Array[Command] = _stage_paths()["confirm"]
	full.append(_choice("confirm", true))
	for stage: String in paths:
		var prefix: Array[Command] = paths[stage]
		var commands := _concat(_to_witch(_w6(), 2, 6), prefix)
		var loaded := _load_roundtrip(commands, stage)
		if loaded == null:
			continue
		assert_eq(_stage(loaded.state), stage, "%s: dieselbe Stufe" % stage)
		assert_eq(_uses(loaded.state, 5, "heal"), 0, "%s: Heiltrank noch unverbraucht" % stage)
		assert_true(_actions(loaded.state).is_empty(), "%s: Rettung noch nicht angewandt" % stage)
		var rest: Array[Command] = []
		if stage == "poison_target":
			rest = [_pick("poison_target", [1]), _choice("confirm", true)]
		else:
			rest = full.slice(prefix.size())
		rest.append(Command.end_night())
		var original := Fixtures.play(commands)
		_continue_both(original, loaded.state, rest, stage)
	var a01 := _load_roundtrip(_concat(_to_witch(_w6(), 2, 6), _stage_paths()["poison"]), "AS-A01")
	if a01 != null:
		assert_true(bool(a01.state.pending_prompt.partial.get("heal", false)), "Teilantwort retten = ja gespeichert")
		assert_eq(String(a01.state.phase), "NIGHT", "Phase")
		assert_eq(RulesEngine.next_step_id(a01.state), WITCH_1, "Schritt Waldhexe")


func test_save_load_after_confirmed_rescue() -> void:
	# 28
	var commands := _night(2, 6, true, -1)
	var loaded := _load_roundtrip(commands, "Rettung bestätigt")
	if loaded == null:
		return
	assert_eq(_json(_actions(loaded.state)), _json(_actions(Fixtures.play(commands))), "Rettung nach Laden")
	var end := _continue_both(Fixtures.play(commands), loaded.state, [Command.end_night()] as Array[Command], "Morgen")
	assert_true(end != null and end.players[6].alive, "Rettung wirkt nach Laden")


func test_save_load_after_poison_with_open_reaction() -> void:
	# 29
	var commands := _concat(_to_witch(_w7r(), 6, 4), _decide(false, 7))
	var loaded := _load_roundtrip(commands, "Gifttod Sensenträger")
	if loaded == null:
		return
	assert_eq(loaded.state.reactions.size(), 1, "Reaktion offen")
	_continue_both(Fixtures.play(commands), loaded.state, [Command.end_night(), Command.begin_step("reaction:1"),
		Command.answer_prompt(4, [2])] as Array[Command], "Reaktion am Morgen")


func test_replay_variants() -> void:
	# 30–33
	var variants := {
		"nur Rettung": _night(2, 6, true, -1),
		"nur Gift": _night(2, 6, false, 1),
		"Rettung und Gift": _night(2, 6, true, 1),
		"Verzicht auf beide": _night(2, 6, false, -1),
	}
	for label: String in variants:
		var commands: Array[Command] = _concat(variants[label], [Command.end_night()] as Array[Command])
		var a := RulesEngine.replay(commands)
		var b := RulesEngine.replay(commands)
		assert_true(a.ok and b.ok, "%s: Replay angenommen (%s @ %d)" % [label, a.error, a.failed_index])
		assert_eq(events_json(a.events), events_json(b.events), "%s: Ereignisse bytegleich" % label)
		assert_eq(_json(a.state.to_dict()), _json(b.state.to_dict()), "%s: Endzustand bytegleich" % label)
	var waived := RulesEngine.replay(variants["Verzicht auf beide"])
	if waived.ok:
		assert_eq(String(waived.state.night_step_status[2]), "done", "Verzicht schließt den Schritt ab")
		assert_eq(_uses(waived.state, 5, "heal") + _uses(waived.state, 5, "poison"), 0, "nichts verbraucht")


# --- 35–37 Manipulation und Überspringen -----------------------------------------------

func test_dead_poison_target_rejected() -> void:
	# 35: 4 stirbt in Nacht 1; Nacht 2 Giftziel 4.
	var commands := _concat(_night(2, 4, false, -1), [Command.end_night(), Command.decide_execution(-1), Command.end_day(),
		Command.start_night(), Command.answer_prompt(4, [6]), Command.begin_step("night:2:1:pack"), Command.answer_prompt(5, [2]),
		Command.begin_step("night:2:2:waldhexe:5"), _choice("heal", false, 6), _choice("poison", true, 6)] as Array[Command])
	var s := Fixtures.play(commands)
	assert_true(s != null and _stage(s) == "poison_target", "Giftziel wählen")
	if s == null:
		return
	assert_false(s.pending_prompt.allowed_ids.has(4), "Tote nicht angeboten")
	apply_rejected(s, _pick("poison_target", [4], 6), "invalid_target", "totes Giftziel")
	apply_rejected(s, _pick("poison_target", [99], 6), "invalid_target", "unbekanntes Giftziel")
	apply_rejected(s, _pick("poison_target", [1, 2], 6), "invalid_target_count", "zwei Ziele")
	apply_rejected(s, _pick("poison_target", [], 6), "invalid_target_count", "kein Ziel")


func test_invalid_rescue_rejected() -> void:
	# 36
	var s := Fixtures.play(_to_witch(_w6(), 2, 6))
	apply_rejected(s, _pick("heal", [4]), "invalid_answer", "fremdes Rettungsziel")
	apply_rejected(s, Command.answer_prompt(WITCH_PROMPT, [6]), "stage_mismatch", "Antwort ohne Stufe")
	apply_rejected(s, _choice("poison", true), "stage_mismatch", "falsche Stufe")
	apply_rejected(s, Command.create(Command.ANSWER_PROMPT, {"prompt_id": WITCH_PROMPT, "stage": "heal", "choice": "ja"}), "invalid_answer", "kein Wahrheitswert")
	apply_rejected(s, _choice("heal", true, 9), "prompt_mismatch", "falscher Prompt")
	var revealed := apply_ok(s, _choice("heal", true), "retten").state
	apply_rejected(revealed, _choice("reveal", false), "invalid_answer", "Offenlegung nur bestätigen")
	var at_confirm := Fixtures.play(_concat(_to_witch(_w6(), 2, 6), _stage_paths()["confirm"]))
	apply_rejected(at_confirm, _choice("confirm", false), "invalid_answer", "Bestätigung nur mit Ja")
	var no_victim := Fixtures.play(_to_witch(_w6(), 2, -1))
	apply_rejected(no_victim, _choice("heal", true), "stage_mismatch", "Rettung ohne Opfer")


func test_witch_step_not_skippable() -> void:
	# 37
	var open := Fixtures.play(_to_witch(_w6(), 2, 6))
	apply_rejected(open, Command.skip_step(WITCH_1, "Hexe schläft"), "step_not_skippable", "bei offenem Prompt")
	var cancelled := apply_ok(open, Command.cancel_prompt(WITCH_PROMPT, "später"), "Abbruch").state
	apply_rejected(cancelled, Command.skip_step(WITCH_1, "Hexe schläft"), "step_not_skippable", "vor Beginn")
	apply_rejected(cancelled, Command.end_night(), "night_steps_open", "nicht still übergangen")


# --- Randfälle Ablauf ---------------------------------------------------------------------

func test_sees_final_pack_choice() -> void:
	# Rudelwahl vor Bestätigung per Abbruch geändert: Hexe sieht nur das endgültige Opfer.
	var s := Fixtures.play([_w6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1),
		Command.cancel_prompt(2, "Rudel umentschieden"), Command.begin_step(PACK_1), Command.answer_prompt(3, [4]), Command.begin_step(WITCH_1)] as Array[Command])
	assert_true(s != null and s.pending_prompt != null, "Waldhexe dran")
	if s != null and s.pending_prompt != null:
		assert_eq(int(s.pending_prompt.partial.get("victim_id", 0)), 4, "endgültiges Opfer")


func test_correction_during_prompt_leaves_no_stale_prompt() -> void:
	var s := Fixtures.play(_concat(_to_witch(_w6(), 2, 6), [_choice("heal", true)] as Array[Command]))
	var r := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}), "Opfer stirbt per Korrektur")
	assert_eq(events_of_type(r.events, "PromptCancelled").size(), 1, "Prompt abgebrochen")
	assert_eq(_uses(r.state, 5, "heal"), 0, "Teilantwort verworfen")
	var again := apply_ok(r.state, Command.begin_step(WITCH_1), "neu begonnen").state
	assert_eq(int(again.pending_prompt.partial.get("victim_id", 0)), -1, "kein lebendes Opfer mehr")
	assert_eq(_stage(again), "poison", "nur noch Gift")


func test_witch_dies_after_confirmation_effects_remain() -> void:
	var run := _replay_ok(_concat(_night(2, 6, true, -1), [CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false}),
		Command.end_night()] as Array[Command]), "Hexe stirbt nach Bestätigung")
	if run.ok:
		assert_true(run.state.players[6].alive, "Rettung bleibt bestehen")
		assert_eq(events_of_type(run.events, "KillPrevented").size(), 1, "verhindert")


# --- 38–40 Spielleiterkorrektur ------------------------------------------------------------

func test_gm_potion_corrections() -> void:
	# 38
	var s := Fixtures.play([_w6(), Command.start_night()] as Array[Command])
	var r := apply_ok(s, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": false}, "Trank am Tisch verbraucht"), "Heiltrank verbraucht")
	assert_eq(_uses(r.state, 5, "heal"), 1, "verbraucht")
	var corrected := events_of_type(r.events, "GmCorrected")
	assert_true(corrected.size() == 1 and int(corrected[0].data["target_id"]) == 5
		and corrected[0].data["old"] == {"potion": "heal", "available": true} and corrected[0].data["new"] == {"potion": "heal", "available": false}, "alter und neuer Wert")
	assert_eq(events_of_type(r.events, "PromptCancelled").size(), 1, "offener Prompt abgebrochen")
	var back := apply_ok(r.state, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": true}), "wieder verfügbar").state
	assert_eq(_uses(back, 5, "heal"), 0, "verfügbar")
	var poison := apply_ok(back, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "poison", "available": false}), "Gift verbraucht").state
	assert_eq(_uses(poison, 5, "poison"), 1, "Gift verbraucht")
	apply_rejected(back, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": true}), "no_change", "unverändert")
	apply_rejected(s, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "liebe", "available": false}), "invalid_correction", "unbekannter Trank")
	apply_rejected(s, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": "nein"}), "invalid_correction", "kein Wahrheitswert")
	apply_rejected(s, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 4, "potion": "heal", "available": false}), "not_a_witch", "keine Waldhexe")
	apply_rejected(s, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 99, "potion": "heal", "available": false}), "unknown_player", "unbekannt")
	apply_rejected(s, Command.gm_correction({"kind": "set_witch_potion", "witch_id": 5, "potion": "heal", "available": false, "reason": "x"}), "confirmation_required", "ohne Bestätigung")
	apply_rejected(s, CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": false}, " "), "reason_required", "ohne Begründung")
	# Beide Tränke vor der Nacht als verbraucht markiert: kein Waldhexenschritt.
	var run := _replay_ok([_w6(), CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "heal", "available": false}),
		CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "poison", "available": false}), Command.start_night()] as Array[Command], "beide verbraucht")
	if run.ok:
		assert_eq(run.state.night_plan, [&"schutzengel:3", &"pack"] as Array[StringName], "kein Schritt")


func test_gm_rescue_corrections() -> void:
	# 39
	var waived := Fixtures.play(_night(2, 4, false, -1))
	var set := apply_ok(waived, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 4}, "Rettung übersehen"), "Rettung setzen")
	var c1 := events_of_type(set.events, "GmCorrected")
	assert_true(c1.size() == 1 and c1[0].data["old"] == {"saved_id": -1} and c1[0].data["new"] == {"saved_id": 4}, "setzen: alter und neuer Wert")
	assert_eq(_uses(set.state, 5, "heal"), 0, "Trankstatus bleibt eigene Korrektur")
	assert_true(apply_ok(set.state, Command.end_night(), "Morgen").state.players[4].alive, "gesetzte Rettung wirkt")
	var saved := Fixtures.play(_night(2, 4, true, -1))
	var changed := apply_ok(saved, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 6}, "falsches Opfer eingetragen"), "Rettung ändern")
	var c2 := events_of_type(changed.events, "GmCorrected")
	assert_true(c2.size() == 1 and c2[0].data["old"] == {"saved_id": 4} and c2[0].data["new"] == {"saved_id": 6}, "ändern: alter und neuer Wert")
	assert_false(apply_ok(changed.state, Command.end_night(), "Morgen").state.players[4].alive, "4 nicht mehr gerettet")
	var removed := apply_ok(saved, CorrectionFixtures.gm("remove_rescue", {"witch_id": 5}, "Rettung irrtümlich"), "Rettung entfernen")
	var c3 := events_of_type(removed.events, "GmCorrected")
	assert_true(c3.size() == 1 and c3[0].data["old"] == {"saved_id": 4} and c3[0].data["new"] == {"saved_id": -1}, "entfernen: alter und neuer Wert")
	assert_false(apply_ok(removed.state, Command.end_night(), "Morgen").state.players[4].alive, "ohne Rettung stirbt 4")
	# Ungültige Korrekturen
	var open := Fixtures.play(_to_witch(_w6(), 2, 4))
	apply_rejected(open, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 4}), "step_not_completed", "Schritt noch offen")
	apply_rejected(saved, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 4}), "no_change", "gleiches Ziel")
	apply_rejected(waived, CorrectionFixtures.gm("remove_rescue", {"witch_id": 5}), "no_change", "keine Rettung")
	apply_rejected(saved, CorrectionFixtures.gm("set_rescue", {"witch_id": 3, "target_id": 6}), "not_a_witch", "keine Waldhexe")
	apply_rejected(saved, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 99}), "unknown_player", "unbekanntes Ziel")
	var dead := apply_ok(saved, CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}), "Vorbereitung").state
	apply_rejected(dead, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 6}), "player_dead", "totes Ziel")
	# Keine rückwirkende Wiederbelebung: nach der Morgenauflösung keine Rettungskorrektur.
	var day := apply_ok(waived, Command.end_night(), "Morgen").state
	assert_false(day.players[4].alive, "4 gestorben")
	apply_rejected(day, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 4}), "wrong_phase", "nicht rückwirkend")
	var no_step := Fixtures.play([_w6(), Command.start_night(), Command.answer_prompt(1, [6]), Command.begin_step(PACK_1), Command.answer_prompt(2, [4]),
		CorrectionFixtures.gm("kill", {"target_id": 5, "trigger_effects": false}), CorrectionFixtures.gm("revive", {"target_id": 5})] as Array[Command])
	apply_rejected(no_step, CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 4}), "no_witch_step", "Schritt entfallen")


func test_save_load_after_each_correction_kind() -> void:
	# 40
	var cases := {
		"Trankstatus": _concat(_night(2, 4, false, -1), [CorrectionFixtures.gm("set_witch_potion", {"witch_id": 5, "potion": "poison", "available": false})] as Array[Command]),
		"Rettung setzen": _concat(_night(2, 4, false, -1), [CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 4})] as Array[Command]),
		"Rettung ändern": _concat(_night(2, 4, true, -1), [CorrectionFixtures.gm("set_rescue", {"witch_id": 5, "target_id": 6})] as Array[Command]),
		"Rettung entfernen": _concat(_night(2, 4, true, -1), [CorrectionFixtures.gm("remove_rescue", {"witch_id": 5})] as Array[Command]),
	}
	for label: String in cases:
		var commands: Array[Command] = cases[label]
		var loaded := _load_roundtrip(commands, label)
		if loaded == null:
			continue
		_continue_both(Fixtures.play(commands), loaded.state, [Command.end_night()] as Array[Command], label)
		var a := RulesEngine.replay(commands)
		var b := RulesEngine.replay(commands)
		assert_eq(events_json(a.events), events_json(b.events), "%s: Replay bytegleich" % label)


# --- 41 Sichtbarkeit -----------------------------------------------------------------------

func test_no_secrets_in_public_events() -> void:
	# 41: Schutz und Rettung auf 6, Gift auf 1, Hinrichtung von 2 am Tag.
	var run := _replay_ok(_concat(_night(6, 6, true, 1), [Command.end_night(), Command.nominate(4, 2), Command.decide_execution(2)] as Array[Command]), "Partie")
	if not run.ok:
		return
	for type: String in ["WitchActed", "PromptStageAnswered", "KillPrevented", "SeatDied", "PromptOpened", "PromptAnswered", "GmCorrected"]:
		for e: GameEvent in events_of_type(run.events, type):
			assert_eq(String(e.visibility), "gm", "%s nur für Spielleiter" % type)
	assert_true(events_of_type(run.events, "PromptStageAnswered").size() > 0, "Stufenantworten protokolliert")
	var public_count := 0
	for e: GameEvent in run.events:
		if e.visibility == &"public":
			public_count += 1
			assert_eq(_find_forbidden(e.data), "", "öffentliches %s ohne Geheimnis" % e.type)
			assert_false(_contains_int(e.data, 5), "öffentliches %s ohne Waldhexen-ID" % e.type)
		elif e.visibility == &"actor":
			assert_eq(int(e.data.get("player_id", e.actor_id)), e.actor_id, "%s nur über die eigene Person" % e.type)
	assert_true(public_count > 0, "öffentliche Ereignisse geprüft")


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
