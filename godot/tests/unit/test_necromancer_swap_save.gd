extends TestCase
## AUDIT-2026-10-02 B-02: Lenkt der Nekromant den Rudelangriff um und tauscht der Seelentauscher später in derselben
## Nacht seine Rolle weg, bleibt der Spielstand ladbar (die Umlenkung verlangt nur noch eine vorhandene Person).

const Audit := preload("res://tests/audit_fixture.gd")


func test_state_stays_loadable_after_necromancer_loses_his_role_in_the_night() -> void:
	var s := Audit.start(self, ["werwolf", "nekromant", "seelentauscher", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	for id: int in [7, 8, 9]:
		s = Audit.ok(self, s, Audit.gm("kill", {"target_id": id, "trigger_effects": false}), "kill %d" % id)
	s = Audit.night(self, s, {"pack@": [2], "nekromant:2@targets": [7, 8, 9], "nekromant:2@redirect": [5], "seelentauscher:3@targets": [2, 4]})
	if s == null:
		return
	assert_eq(s.pack_redirect_from, 2, "Umlenkung ist gemerkt")
	assert_ne(s.players[2].role_id, &"nekromant", "Nekromant hat die Rolle getauscht")
	assert_true(Audit.reloads(s), "Zustand mitten in der Nacht ladbar")
	var end := Audit.ok(self, s, Command.end_night(), "Nachtende")
	if end != null:
		assert_true(Audit.reloads(end), "Zustand nach der Morgenauflösung ladbar")
