extends TestCase
## AUDIT-2026-10-02 B-01: Rollen, die Totenreichkarten brauchen (Kartenschlucker), werden ohne Karten weder von
## Frankenstein angeboten noch von der Spielleiterkorrektur gesetzt. Sonst ist der Spielstand nicht mehr ladbar.

const Audit := preload("res://tests/audit_fixture.gd")
const ROLES := ["werwolf", "dr-victor-frankenstein", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


func test_frankenstein_does_not_offer_card_roles_without_death_cards() -> void:
	var s := Audit.start(self, ROLES)
	s = Audit.ok(self, s, Audit.gm("kill", {"target_id": 3, "trigger_effects": false}), "kill")
	assert_false(BondSteps.frankenstein_options(s).has("kartenschlucker"), "ohne Karten kein Kartenschlucker")
	var with_cards := Audit.start(self, ROLES, true)
	with_cards = Audit.ok(self, with_cards, Audit.gm("kill", {"target_id": 3, "trigger_effects": false}), "kill (Karten)")
	assert_true(BondSteps.frankenstein_options(with_cards).has("kartenschlucker"), "mit Karten bleibt Kartenschlucker wählbar")


func test_gm_set_role_rejects_card_role_without_death_cards() -> void:
	var s := Audit.start(self, ROLES)
	var r := RulesEngine.apply(s, Audit.gm("set_role", {"target_id": 3, "role_id": "kartenschlucker"}))
	assert_false(r.ok, "set_role Kartenschlucker ohne Karten abgelehnt")
	assert_true(Audit.reloads(s), "Zustand bleibt ladbar")
