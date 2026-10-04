extends TestCase
## Gemeinsame Auswahlprüfung für die Aktionskarte: `RulesEngine.target_counts` nennt die zulässigen
## Anzahlen des offenen Personen-Prompts, `RulesEngine.check` prüft einen Befehl ohne ihn anzuwenden.
## Beide stammen aus derselben Validierung wie `apply`; die Oberfläche implementiert keine Rollenregel.
##   Seelentauscher, Kutscher: keiner oder alle (0 oder Höchstzahl). Loki: genau zwei. Spürhund: genau drei. Doktor: genau zwei.
##   Rudel: genau ein Opfer.

const D := "dorfbewohner"
const W := "werwolf"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.owner == PendingPrompt.OWNER_WITCH:
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm")
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	if p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
		return Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
	if p.owner == &"feuerteufel":
		return Command.answer_prompt(p.id, Fixtures.pass_targets(s, p))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Bis zum offenen Prompt von `owner` in der ersten Nacht; andere Schritte ohne Wirkung.
func _to_owner(s: GameState, owner: StringName) -> GameState:
	s = _ok(s, Command.start_night(), "Nacht")
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			if s.pending_prompt.owner == owner:
				return s
			s = _ok(s, _auto(s), "ohne Wirkung")
		elif RulesEngine.next_step_id(s) == "":
			return null
		else:
			s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
	return null


## Prüft Anzahlen und dass `check` für jede Auswahlgröße dasselbe sagt wie `apply`, ohne Änderung.
func _assert_counts(s: GameState, expected: Array[int], label: String) -> void:
	if s == null:
		fail("%s: Prompt nicht erreicht" % label)
		return
	var p := s.pending_prompt
	assert_eq(RulesEngine.target_counts(s), expected, "%s: zulässige Anzahlen" % label)
	var pool: Array[int] = p.allowed_ids.duplicate()
	for n: int in range(0, p.max_count + 1):
		if n > pool.size():
			break
		var c := Command.answer_stage_targets(p.id, String(p.stage), pool.slice(0, n))
		var before := CanonicalJson.stringify(s.to_dict())
		var checked := RulesEngine.check(s, c)
		assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: check ändert nichts (%d)" % [label, n])
		assert_eq(checked, RulesEngine.apply(s, c).error, "%s: check entspricht apply (%d)" % [label, n])
		assert_eq(checked == &"", expected.has(n), "%s: %d Personen %s" % [label, n, "zulässig" if expected.has(n) else "abgelehnt"])


func test_loki_exactly_two() -> void:
	_assert_counts(_to_owner(_state([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), &"loki"), [2] as Array[int], "Loki")


func test_soul_swapper_none_or_two() -> void:
	_assert_counts(_to_owner(_state([W, "seelentauscher", D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise"]), &"seelentauscher"), [0, 2] as Array[int], "Seelentauscher")


func test_coachman_none_or_three() -> void:
	var s := _state([W, "kutscher", D, "amalia"] + Fixtures.extra_village(10) + ["detektiv", "wahnsinniger-kutscher"])
	for id: int in [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]:
		s = _ok(s, CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false}, "Test"), "%d tot" % id)
	_assert_counts(_to_owner(s, &"kutscher"), [0, 3] as Array[int], "Kutscher")


func test_hound_exactly_three() -> void:
	_assert_counts(_to_owner(_state([W, "spuerhund", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), &"spuerhund"), [3] as Array[int], "Spürhund")


func test_doctor_exactly_two() -> void:
	_assert_counts(_to_owner(_state([W, "doktor", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), &"doktor"), [2] as Array[int], "Doktor")


func test_plain_prompt_uses_min_and_max() -> void:
	var s := _ok(_state([W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), Command.start_night(), "Nacht")
	assert_eq(s.pending_prompt.owner, &"pack", "Rudel offen")
	assert_eq([s.pending_prompt.min_count, s.pending_prompt.max_count], [1, 1], "Rudel: genau ein Opfer (DA Nachtschritte neu)")
	assert_eq(RulesEngine.target_counts(s), [1] as Array[int], "Rudel: genau ein Opfer")


func test_no_prompt_has_no_counts() -> void:
	assert_eq(RulesEngine.target_counts(_state([W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])), [] as Array[int], "ohne Prompt keine Anzahl")


## Manipulierte und veraltete Befehle bleiben abgelehnt, auch wenn die Oberfläche sie nie bildet.
func test_manipulated_and_stale_commands_are_still_rejected() -> void:
	var s := _to_owner(_state([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), &"loki")
	if s == null:
		fail("Loki nicht erreicht")
		return
	var p := s.pending_prompt
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [3]), "invalid_target_count", "Teilauswahl")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [3, 3]), "invalid_target", "doppelt")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [3, 99]), "invalid_target", "unbekannte Person")
	apply_rejected(s, Command.answer_stage_targets(p.id + 1, "targets", [3, 4]), "prompt_mismatch", "falscher Prompt")
	apply_rejected(s, Command.answer_stage_targets(p.id, "mode", [3, 4]), "stage_mismatch", "falsche Stufe")
	assert_eq(RulesEngine.check(s, Command.answer_stage_targets(p.id, "targets", [3])), &"invalid_target_count", "check meldet dasselbe")
	# Veraltet: nach der Antwort gilt der alte Befehl nicht mehr.
	var answered := _ok(s, Command.answer_stage_targets(p.id, "targets", [3, 4]), "Paar")
	apply_rejected(answered, Command.answer_stage_targets(p.id, "targets", [3, 4]), "stage_mismatch", "veraltete Antwort")
	assert_eq(RulesEngine.check(answered, Command.answer_stage_targets(p.id, "targets", [3, 4])), &"stage_mismatch", "check: veraltet")
	# Phase: außerhalb der Nacht lehnt schon die Phasenprüfung ab.
	assert_eq(RulesEngine.check(_state([W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), Command.answer_prompt(1, [2])), RulesEngine.apply(_state([W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), Command.answer_prompt(1, [2])).error, "check mit Phasenprüfung")
