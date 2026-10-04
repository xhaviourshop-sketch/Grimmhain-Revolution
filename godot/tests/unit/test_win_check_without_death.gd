extends TestCase
## AUDIT-2026-10-02 B-04: Verzaubern, Infizieren und die Pest-Ausbreitung können einen Einzelsieg erfüllen, ohne dass
## jemand stirbt. Der Sieg muss dann trotzdem als Kandidat erkannt werden (win_check_pending), sonst geht er verloren,
## sobald die Person später stirbt.

const Audit := preload("res://tests/audit_fixture.gd")
const SIX := ["werwolf", "rattenfaenger", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


func _reasons(s: GameState) -> Array:
	var out: Array = []
	for c: WinCandidate in s.win_candidates:
		out.append(String(c.reason_key))
	return out


func test_piper_win_is_detected_when_the_last_person_is_charmed() -> void:
	var s := Audit.start(self, SIX)
	s = Audit.dawn(self, s, {"rattenfaenger:2@": [3, 4]})
	s = Audit.dawn(self, s, {"rattenfaenger:2@": [1, 5]})
	if s == null:
		return
	# Dritte Nacht von Hand: sobald die letzte Person verzaubert ist, steht der Kandidat da und sperrt die weitere Nacht.
	s = Audit.ok(self, s, Command.decide_execution(-1), "keine Hinrichtung")
	s = Audit.ok(self, s, Command.end_day(), "end day")
	s = Audit.ok(self, s, Command.start_night(), "start night")
	for guard: int in 40:
		if s == null or not s.win_candidates.is_empty():
			break
		var cmd: Command
		if s.pending_prompt == null:
			cmd = Command.begin_step(RulesEngine.next_step_id(s))
		elif s.pending_prompt.owner == PendingPrompt.OWNER_PIPER:
			cmd = Command.answer_prompt(s.pending_prompt.id, [6])
		elif s.pending_prompt.owner == PendingPrompt.OWNER_PACK:
			cmd = Command.skip_step(s.pending_prompt.step_id, "Test: ruhige Nacht")
		else:
			cmd = Audit.auto(s)
		s = Audit.ok(self, s, cmd, "night command")
	if s == null:
		return
	assert_true(SoloRules.piper_wins(s, 2), "alle verzaubert")
	assert_true(_reasons(s).has("pied_piper_all_charmed"), "Siegkandidat Rattenfänger ohne Tod (%s)" % [_reasons(s)])


func test_plague_win_is_detected_without_any_death() -> void:
	var s := Audit.start(self, ["werwolf", "pestbringerin", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"])
	for night: int in 6:
		s = Audit.dawn(self, s)
		if s == null:
			return
		if SoloRules.pest_wins(s, 2):
			break
	assert_true(SoloRules.pest_wins(s, 2), "alle anderen infiziert")
	assert_eq(s.alive_ids().size(), 6, "niemand ist gestorben")
	assert_true(_reasons(s).has("plague_all_infected"), "Siegkandidat Pestbringerin ohne Tod (%s)" % [_reasons(s)])
