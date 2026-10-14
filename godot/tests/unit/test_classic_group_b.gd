extends TestCase
## Akt Classic, Gruppe B: Fuchs, Flötenspieler, Bärenführer. Sitzreihenfolge = Personen-ID 1 bis n.

const D := "classic-dorfbewohner"
const W := "classic-werwolf"


func _apply(s: GameState, c: Command) -> GameState:
	var r := RulesEngine.apply(s, c)
	assert_true(r.ok, "Befehl angenommen: %s %s %s" % [c.type, c.payload, r.error])
	return r.state if r.ok else null


## Beginnt Schritte und beantwortet fremde Prompts, bis der Prompt von `owner` offen ist.
func _to_prompt(s: GameState, owner: StringName) -> GameState:
	for guard: int in 30:
		if s == null:
			return null
		if s.pending_prompt == null:
			if StepQueue.next_step_id(s) == "":
				return s
			s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
			continue
		var p := s.pending_prompt
		if p.owner == owner:
			return s
		var ids: Array = [s.alive_ids().filter(func(id: int) -> bool: return not s.players[id].counts_as_wolf)[-1]] if p.owner == PendingPrompt.OWNER_PACK else Fixtures.pass_targets(s, p)
		if p.stage == &"shown":
			s = _apply(s, Command.answer_choice(p.id, "shown", true))
		elif String(p.stage) == "":
			s = _apply(s, Command.answer_prompt(p.id, ids))
		else:
			s = _apply(s, Command.answer_stage_targets(p.id, String(p.stage), ids))
	return s


func _night(roles: Array) -> GameState:
	var s := Fixtures.play([Fixtures.start_roles(roles), Command.start_night()])
	assert_true(s != null, "Partie startet")
	return s


func _fox_result(roles: Array, pick: int) -> Dictionary:
	var s := _to_prompt(_night(roles), PendingPrompt.OWNER_HOUND)
	s = _apply(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [pick]))
	return {"state": s, "partial": s.pending_prompt.partial}


func test_fox_asks_about_the_trio_and_loses_the_gift_without_a_wolf() -> void:
	var roles := ["classic-fuchs", D, D, D, W, D, D, D]  # Wolf auf Platz 5
	var hit := _fox_result(roles, 6)  # Trio 5, 6, 7
	assert_eq(hit["partial"]["target_ids"], [5, 6, 7], "Trio: Gewählter und beide Nachbarn")
	assert_true(bool(hit["partial"]["hit"]), "Werwolf im Trio")
	var s: GameState = _apply(hit["state"], Command.answer_choice(hit["state"].pending_prompt.id, "shown", true))
	assert_false(InfoSteps.hound_lost(s.players[1]), "Treffer: Fähigkeit bleibt")
	var miss := _fox_result(roles, 3)  # Trio 2, 3, 4
	assert_false(bool(miss["partial"]["hit"]), "kein Werwolf im Trio")
	s = _apply(miss["state"], Command.answer_choice(miss["state"].pending_prompt.id, "shown", true))
	assert_true(InfoSteps.hound_lost(s.players[1]), "Kein Werwolf im Trio: Fuchs verliert die Fähigkeit")
	var wrap := _fox_result(roles, 1)  # Trio über die Tischkante: 8, 1, 2
	assert_eq(wrap["partial"]["target_ids"], [1, 2, 8], "Nachbarn über die Tischkante")


func test_flute_enchants_one_or_two_and_wins_without_all_enchanted_step() -> void:
	var s := _night(["classic-floetenspieler", W, D, D, D, D])
	assert_false(s.night_plan.has(StepQueue.PIPER_ALL), "kein Schritt „Alle Verzauberten“")
	s = _to_prompt(s, PendingPrompt.OWNER_PIPER)
	var p := s.pending_prompt
	assert_eq([p.min_count, p.max_count], [1, 2], "eine oder zwei pro Nacht (die Spielleitung fragt zuerst die Zahl, Nachtauftrag 14.10.2026)")
	assert_false(RulesEngine.apply(s, Command.answer_prompt(p.id, [3, 4, 5])).ok, "drei sind zu viel")
	s = _apply(s, Command.answer_prompt(p.id, [3, 4]))
	assert_eq(SoloRules.charmed_living(s), [3, 4], "zwei verzaubert")
	assert_false(SoloRules.piper_wins(s, 1), "noch nicht alle")
	# Grenzfall: Bleibt nur eine unverzauberte Person, wählt er diese und gewinnt.
	var t := _night(["classic-floetenspieler", W, D, D, D, D])
	for id: int in [2, 3, 4, 5]:
		t.charms.append({"piper_id": 1, "target_id": id})
	t = _to_prompt(t, PendingPrompt.OWNER_PIPER)
	assert_eq([t.pending_prompt.min_count, t.pending_prompt.max_count], [1, 1], "eine übrig")
	t = _apply(t, Command.answer_prompt(t.pending_prompt.id, [6]))
	assert_true(SoloRules.piper_wins(t, 1), "alle Lebenden verzaubert: Flötenspieler gewinnt")


func _growls(roles: Array) -> Array:
	var cmds: Array[Command] = [Fixtures.start_roles(roles), Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.end_night()]
	var run := RulesEngine.replay(cmds)
	assert_true(run.ok, "Nacht läuft (%s)" % run.error)
	return [events_of_type(cmd_events(cmds), "BearGrowl"), run]


func cmd_events(cmds: Array[Command]) -> Array[GameEvent]:
	return RulesEngine.replay(cmds).events


func test_bear_trainer_growls_only_next_to_a_wolf_without_naming_it() -> void:
	var near := _growls([D, "classic-baerenfuehrer", W, D, D, D])  # Wolf rechts neben dem Bärenführer
	assert_eq(near[0].size(), 1, "Knurren am Morgen")
	assert_eq(near[0][0].visibility, Visibility.PUBLIC, "öffentlich")
	assert_eq(near[0][0].data.keys(), ["day"], "öffentlich nur das Knurren, kein Name")
	var far := _growls([D, "classic-baerenfuehrer", D, W, D, D])
	assert_eq(far[0].size(), 0, "kein Wolf unmittelbar daneben: kein Knurren")
