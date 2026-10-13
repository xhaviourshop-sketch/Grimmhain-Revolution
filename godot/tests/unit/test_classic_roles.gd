extends TestCase
## Akt Classic (DA-108): eigene Rollen-IDs mit Mechanik-Verweis. Besetzung C14:
## 1 Amor; 2, 3 Werwölfe; 4 Seherin; 5 Hexe; 6 Engel; 7–9 drei Brüder; 10, 11 zwei Schwestern; 12 Jäger; 13 Alte; 14 Mädchen.

const C14 := ["classic-amor", "classic-werwolf", "classic-werwolf", "classic-seherin", "classic-hexe", "classic-engel",
	"classic-drei-brueder", "classic-drei-brueder", "classic-drei-brueder", "classic-zwei-schwestern", "classic-zwei-schwestern",
	"classic-jaeger", "classic-alte", "classic-maedchen"]


func _night_one() -> GameState:
	var s := Fixtures.play([Fixtures.start_roles(C14), Command.start_night()])
	assert_true(s != null, "Classic-Besetzung startet")
	return s


## Wendet einen Befehl an und liefert den neuen Zustand (null bei Ablehnung).
func _apply(s: GameState, c: Command) -> GameState:
	var r := RulesEngine.apply(s, c)
	assert_true(r.ok, "Befehl angenommen: %s %s %s" % [c.type, c.payload, r.error])
	return r.state if r.ok else null


## Antwort mit Zielen, bei mehrstufigen Prompts für die laufende Stufe.
func _targets(p: PendingPrompt, ids: Array) -> Command:
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	return Command.answer_prompt(p.id, ids) if String(p.stage) == "" else Command.answer_stage_targets(p.id, String(p.stage), ids)


func test_night_one_order_follows_the_mechanic_numbers() -> void:
	var s := _night_one()
	var plan: Array[String] = []
	for key: StringName in s.night_plan:
		plan.append(String(key))
	assert_eq(plan, ["loki:1", "classic-drei-brueder", "classic-zwei-schwestern", "schutzengel:6", "pack", "waldhexe:5",
		"das-orakel:4"], "Amor 1, Brüder und Schwestern 5, Engel 13, Rudel 20, Hexe 34, Seherin 46")
	assert_eq(InfoSteps.living_bound(s, &"classic-drei-brueder"), [7, 8, 9], "Brüder erkennen nur sich")
	assert_eq(InfoSteps.living_bound(s, &"classic-zwei-schwestern"), [10, 11], "Schwestern erkennen nur sich")
	assert_eq(s.players[2].appears_as, &"classic-werwolf", "Seherin sieht die Classic-Rolle")
	assert_true(s.players[2].counts_as_wolf and s.players[13].faction == Faction.VILLAGE, "Fraktionen aus der Mechanik")


func test_incomplete_group_is_rejected() -> void:
	var roles := C14.duplicate()
	roles[8] = "classic-dorfbewohner"  # nur zwei Brüder
	var r := RulesEngine.apply(GameState.new(), Fixtures.start_roles(roles))
	assert_false(r.ok, "zwei Brüder abgelehnt")
	assert_eq(String(r.error), "role_group_incomplete", "Grund")


func test_amor_binds_lovers_without_asking_the_kind() -> void:
	var s := _night_one()
	assert_eq(s.pending_prompt.owner, PendingPrompt.OWNER_LOKI, "Amor ist der erste Schritt")
	s = _apply(s, _targets(s.pending_prompt, [1, 4]))
	assert_eq(s.loki_pairs.size(), 1, "ein Paar")
	assert_eq(str(s.loki_pairs[0]["kind"]), "love", "immer Liebende")
	assert_true(s.pending_prompt == null, "keine Frage nach der Bindungsart")


func test_witch_heal_reveals_no_role() -> void:
	var s := _night_one()
	var witch_index := s.night_plan.find(&"waldhexe:5")
	while s.next_night_step < witch_index or s.pending_prompt != null:
		if s.pending_prompt == null:
			s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
			continue
		var p := s.pending_prompt
		var targets := Fixtures.pass_targets(s, p)
		s = _apply(s, _targets(p, [12] if p.owner == PendingPrompt.OWNER_PACK else targets))
		if s == null:
			return
	s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
	s = _apply(s, Command.answer_choice(s.pending_prompt.id, "heal", true))
	assert_false(s.pending_prompt.partial.has("victim_role"), "keine Rolle des Opfers")
	assert_ne(String(s.pending_prompt.stage), "reveal", "keine Offenlegung")
