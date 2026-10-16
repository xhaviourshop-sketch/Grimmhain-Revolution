extends TestCase
## Nachtlauf Regeln: Die Korrekturfelder der Hexe (Tränke) gelten auch für die Classic-Hexe; der Regelkern nimmt sie über die Mechanik an.

const CLASSIC_WITCH := "classic-hexe"


func test_classic_witch_offers_the_potion_corrections() -> void:
	var r := RulesEngine.apply(GameState.new(), Fixtures.start_roles(["classic-werwolf", CLASSIC_WITCH, "classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner", "classic-dorfbewohner"]))
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return
	var fields: Array = CockpitView.status_fields(r.state, 2).map(func(f: Dictionary) -> String: return str(f["field"]))
	assert_true(fields.has("potion_heal") and fields.has("potion_poison"), "beide Tränke der Classic-Hexe sind korrigierbar: %s" % [fields])
	var base := RulesEngine.apply(GameState.new(), Fixtures.start_roles(["werwolf", "waldhexe", "dorfbewohner", "amalia", "detektiv", "nachtwaechter"]))
	var base_fields: Array = CockpitView.status_fields(base.state, 2).map(func(f: Dictionary) -> String: return str(f["field"]))
	assert_true(base_fields.has("potion_heal"), "Waldhexe des Grundspiels wie bisher")
