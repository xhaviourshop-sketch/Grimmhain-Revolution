extends TestCase
## Rückanklage: A klagt B an, danach darf B auch A anklagen (Markus, 14.10.2026). Je Person bleibt es bei
## einer Anklage und einmal angeklagt werden pro Tag (DR-03).

var _cmds: Array[Command] = []


func _day() -> GameState:
	_cmds = [Fixtures.start_roles(["werwolf", "blutwolf", "dorfbewohner", "amalia", "waechter-am-tor", "detektiv"], 1),
		Command.start_night(), Command.skip_step("night:1:0:pack", "ruhige Nacht"), Command.end_night()]
	var r := RulesEngine.replay(_cmds)
	assert_true(r.ok and r.state.phase == Phase.DAY, "Tag erreicht (%s)" % r.error)
	return r.state if r.ok else null


func test_accused_may_accuse_back() -> void:
	var s := _day()
	if s == null:
		return
	s = apply_ok(s, Command.nominate(1, 2), "A klagt B an").state
	s = apply_ok(s, Command.nominate(2, 1), "B klagt A an").state
	var all := _cmds.duplicate()
	all.append(Command.nominate(1, 2))
	all.append(Command.nominate(2, 1))
	assert_eq(s.nominations_on_day(1).size(), 2, "beide Anklagen stehen")
	apply_rejected(s, Command.nominate(2, 3), "already_nominated_today", "B klagt nur einmal an")
	apply_rejected(s, Command.nominate(3, 1), "already_nominee_today", "A wird nur einmal angeklagt")
	var loaded := StateCodec.decode(StateCodec.encode(s, all))
	assert_true(loaded.ok and loaded.state.nominations_on_day(1).size() == 2, "Speichern und Laden")
	var done := apply_ok(s, Command.decide_execution(1), "A steht zur Entscheidung").state
	assert_true(not done.players[1].alive, "A hingerichtet")


func test_without_counter_accusation_unchanged() -> void:
	var s := _day()
	if s == null:
		return
	s = apply_ok(s, Command.nominate(1, 2), "A klagt B an").state
	assert_eq(s.nominations_on_day(1).size(), 1, "nur eine Anklage")
	apply_rejected(s, Command.decide_execution(1), "not_nominated_today", "A wurde nicht angeklagt")
