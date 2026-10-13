extends TestCase
## Classic nach Wortlaut des Bogens: Alte (Fluch dauerhaft), Weißer Wolf (nur Alleinsieg), Seherin (tatsächliche Rolle), Jäger (Schuss freiwillig).

const C14 := ["classic-amor", "classic-werwolf", "classic-werwolf", "classic-seherin", "classic-hexe", "classic-engel",
	"classic-drei-brueder", "classic-drei-brueder", "classic-drei-brueder", "classic-zwei-schwestern", "classic-zwei-schwestern",
	"classic-jaeger", "classic-alte", "classic-maedchen"]


func _apply(s: GameState, c: Command) -> GameState:
	var r := RulesEngine.apply(s, c)
	assert_true(r.ok, "Befehl angenommen: %s %s %s" % [c.type, c.payload, r.error])
	return r.state if r.ok else null


func _targets(p: PendingPrompt, ids: Array) -> Command:
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	return Command.answer_prompt(p.id, ids) if String(p.stage) == "" else Command.answer_stage_targets(p.id, String(p.stage), ids)


func _id_of(s: GameState, role: String) -> int:
	for id: int in s.players:
		if String(s.players[id].role_id) == role:
			return id
	return -1


## Spielt Nacht 1 durch; `stop_at` darf einen Prompt anhalten (liefert true), `victim` ist das Rudelopfer.
func _night(s: GameState, victim: int, stop_at: Callable = Callable()) -> GameState:
	s = _apply(s, Command.start_night())
	for guard: int in 60:
		if s == null or (s.pending_prompt == null and StepQueue.next_step_id(s) == ""):
			break
		if s.pending_prompt == null:
			s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
			continue
		var p := s.pending_prompt
		if stop_at.is_valid() and bool(stop_at.call(s, p)):
			return s
		if p.stage != &"" and p.stage != &"shown" and (p.max_count == 0 or p.stage == &"use"):
			s = _apply(s, Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm"))
			continue
		s = _apply(s, _targets(p, [victim] if p.owner == PendingPrompt.OWNER_PACK else Fixtures.pass_targets(s, p)))
	return s


## Seherin: erfährt die tatsächliche Rolle, auch bei Urwolf und Weißem Wolf.
func test_seherin_sees_the_true_role_of_special_wolves() -> void:
	var roles := ["classic-seherin", "classic-urwolf", "classic-weisser-wolf", "classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner"]
	var s := Fixtures.play([Fixtures.start_roles(roles)])
	var seher := s.players[_id_of(s, "classic-seherin")]
	for role: String in ["classic-urwolf", "classic-weisser-wolf"]:
		var target := s.players[_id_of(s, role)]
		assert_eq(InformationRules.determine_role(target, seher), StringName(role), "Seherin sieht %s" % role)
		assert_eq(InformationRules.determine_role(target), RoleCatalog.WERWOLF, "ohne Seherin bleibt es „Werwolf“ (Grundspiel)")
	var urwolf := _id_of(s, "classic-urwolf")
	s = _night(s, _id_of(s, "classic-dorfbewohner"), func(st: GameState, p: PendingPrompt) -> bool:
		if p.owner == PendingPrompt.OWNER_ORACLE and String(p.stage) != "shown":
			return true
		return false)
	assert_true(s.pending_prompt != null and s.pending_prompt.owner == PendingPrompt.OWNER_ORACLE, "Seherin-Schritt offen")
	s = _apply(s, _targets(s.pending_prompt, [urwolf]))
	assert_eq(String(s.pending_prompt.partial["determined_role"]), "classic-urwolf", "gezeigt wird der Urwolf")


## Jäger: Der Schuss bei seinem Tod ist freiwillig, Verzicht ist möglich.
func test_hunter_shot_is_optional() -> void:
	var s := Fixtures.play([Fixtures.start_roles(C14)])
	var hunter := _id_of(s, "classic-jaeger")
	s = _night(s, hunter)
	s = _apply(s, Command.end_night())
	assert_false(s.players[hunter].alive, "Jäger gestorben")
	assert_true(StepQueue.reactions_due(s), "Reaktion offen")
	s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
	var prompt := s.pending_prompt
	assert_eq(prompt.owner, PendingPrompt.OWNER_REACTION, "Schuss-Karte")
	assert_eq(prompt.min_count, 0, "Verzicht erlaubt")
	assert_eq(CockpitText.action_key("decline", "reaction", ""), "ui.cockpit.action.decline.reaction.pick", "Knopf „Kein Schuss“")
	s = _apply(s, Command.answer_prompt(prompt.id, []))
	assert_false(StepQueue.reactions_due(s), "Reaktion erledigt ohne Schuss")
	assert_false(RoleCatalog.param(RoleCatalog.SENSENTRAEGER, "optional_shot", false), "Grundspiel: Schuss bleibt Pflicht")
