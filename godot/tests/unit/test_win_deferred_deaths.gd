extends TestCase
## AUDIT-2026-10-02 B-03, B-05, CM-01: Aufgeschobene Tote (Notanker, wende_05) zählen für ALLE Siegbedingungen und
## deren Ladeprüfung als tot (`WinRules.effective_alive_ids`), nicht nur bei der Dorf- und Wolfsparität.

const Audit := preload("res://tests/audit_fixture.gd")
const SIX := ["werwolf", "doppelspion", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


## Setzt eine Notanker-Wirkung auf `person` (wie sie die Karte erzeugt); der Stand muss dabei ladbar sein.
func _defer(s: GameState, person: int, owner: int) -> GameState:
	var d := s.to_dict()
	var sys: Dictionary = d["cardsys"]
	(sys["effects"] as Array).append({"id": int(sys["next_effect"]), "card": "wende_05", "variant": "wolf", "owner": owner,
		"kind": "deferred_death", "from": 0, "to": 999999, "data": {"person_id": person, "due_day": 3, "cause": "lynch", "source_kind": "player", "source_id": -1}})
	sys["next_effect"] = int(sys["next_effect"]) + 1
	var out := GameState.from_dict(d)
	assert_true(out != null, "Stand mit Notanker ladbar")
	return out


func test_lone_wolf_candidate_stays_loadable_with_a_deferred_death() -> void:
	var s := Audit.start(self, ["rachsuechtiger-wolf", "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"], true)
	s = _defer(s, 4, 5)
	for id: int in [2, 5, 6]:
		s = Audit.ok(self, s, Audit.gm("kill", {"target_id": id, "trigger_effects": false}), "kill %d" % id)
	assert_eq(s.win_candidates.size(), 1, "ein Siegkandidat")
	assert_eq(String(s.win_candidates[0].reason_key), "lone_wolf_last_wolf", "Alleinsieg des Rachsüchtigen Wolfs")
	assert_true(Audit.reloads(s), "Stand mit Kandidat ladbar")


func test_double_agent_wins_instead_of_village_when_last_wolf_is_deferred() -> void:
	var s := Audit.start(self, SIX, true)
	s = _defer(s, 1, 3)
	s = Audit.ok(self, s, Audit.gm("kill", {"target_id": 6, "trigger_effects": false}), "kill 6")
	var kinds: Array = []
	for c: WinCandidate in s.win_candidates:
		kinds.append("%s:%s" % [c.kind, c.reason_key])
	assert_eq(kinds, ["solo:double_agent_no_wolves"], "nur der Doppelspion-Sieg, kein Dorfsieg")


func test_count_based_solo_wins_ignore_deferred_deaths() -> void:
	var s := Audit.start(self, ["werwolf", "manipulator", "parasit", "dorfbewohner", "amalia", "detektiv"], true)
	s = _defer(s, 5, 4)
	s = Audit.ok(self, s, Audit.gm("kill", {"target_id": 6, "trigger_effects": false}), "kill 6")
	# lebend: 1, 2, 3, 4, 5 (5 aufgeschoben) -> wirksam 4: noch keine Bedingung
	assert_false(WinRules.manipulator_wins(s, 2), "Manipulator: vier wirksam Lebende genügen nicht")
	s = _defer(s, 4, 3)
	assert_true(WinRules.manipulator_wins(s, 2), "Manipulator: genau drei wirksam Lebende")
	assert_true(WinRules.parasite_wins(s, 3), "Parasit: höchstens drei wirksam Lebende")
	assert_eq(WinRules.effective_alive_ids(s), [1, 2, 3] as Array[int], "wirksam Lebende")
