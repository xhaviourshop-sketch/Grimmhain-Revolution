extends UiTestCase
## PE-07: Fester Rollenvorschlag für 6 bis 24 Personen (Nutzerantwort vom 30.09.2026). Erwartung unabhängig von der
## Implementierung aus dem Wortlaut der Antwort abgeleitet: Wolfsanzahl 1/2/3/4/5 ab 6/9/13/18/22 Personen, genau ein
## Manipulator, Wolfsrollen in fester Reihenfolge, Dorfrollen in fester Reihenfolge, keine Rolle doppelt.

const WOLF_ORDER: Array[String] = ["werwolf", "spiegelwolf", "trugbilderwolf", "blutwolf", "besessener-wolf"]
const VILLAGE_ORDER: Array[String] = ["schutzengel", "das-orakel", "dorfbewohner", "waldhexe", "dorfwache", "sensentraeger", "ritter",
	"lehrling", "nachtwaechter", "wolfskind", "waldlaeufer", "doktor", "detektiv", "faehrtenleser", "der-weise", "dorfchronistin",
	"wahnsinniger-kutscher", "traumdeuter"]
## Anzeigenamen aus dem Wortlaut der Antwort, in derselben Reihenfolge wie WOLF_ORDER und VILLAGE_ORDER.
const WOLF_NAMES: Array[String] = ["Werwolf", "Spiegelwolf", "Trugbilderwolf", "Blutwolf", "Besessener Wolf"]
const VILLAGE_NAMES: Array[String] = ["Schutzengel", "Orakel", "Dorfbewohner", "Waldhexe", "Dorfwache", "Sensenträger", "Ritter", "Lehrling",
	"Nachtwächter", "Wolfskind", "Waldläufer", "Doktor", "Detektiv", "Fährtenleser", "Der Weise", "Dorfchronistin", "Wahnsinniger Kutscher",
	"Traumdeuter"]


## Wolfsanzahl nach der Antwort: 1 / 2 / 3 / 4 / 5 ab 6 / 9 / 13 / 18 / 22 Personen.
func _wolves(persons: int) -> int:
	var wolves := 1
	for step: Array in [[9, 2], [13, 3], [18, 4], [22, 5]]:
		if persons >= int(step[0]):
			wolves = int(step[1])
	return wolves


func _expected_roles(persons: int) -> Array:
	var wolves := _wolves(persons)
	var out: Array = []
	out.append_array(WOLF_ORDER.slice(0, wolves))
	out.append("manipulator")
	out.append_array(VILLAGE_ORDER.slice(0, persons - wolves - 1))
	return out


func _chosen(counts: Dictionary) -> Array:
	var out: Array = []
	for id: Variant in counts:
		if int(counts[id]) > 0:
			out.append(str(id))
	out.sort()
	return out


func test_fixed_proposal_for_every_person_count() -> void:
	for persons: int in range(6, 25):
		var counts: Dictionary = RoleSuggestion.for_count(persons)
		var expected := _expected_roles(persons)
		assert_eq(expected.size(), persons, "%d: erwartete Liste hat genau eine Rolle je Person" % persons)
		var expected_sorted := expected.duplicate()
		expected_sorted.sort()
		assert_eq(_chosen(counts), expected_sorted, "%d: Rollen des Vorschlags" % persons)
		var total := 0
		var wolves := 0
		var solo := 0
		for id: Variant in counts:
			var c := int(counts[id])
			assert_true(c == 0 or c == 1, "%d: %s höchstens einmal (%d)" % [persons, id, c])
			total += c
			if c > 0 and RoleCatalog.counts_as_wolf(StringName(str(id))):
				wolves += c
			if c > 0 and RoleCatalog.faction_of(StringName(str(id))) == Faction.SOLO:
				solo += c
		assert_eq(total, persons, "%d: genau so viele Rollen wie Personen" % persons)
		assert_eq(wolves, _wolves(persons), "%d: Wolfsanzahl" % persons)
		assert_eq(solo, 1, "%d: genau ein Manipulator (die einzige Einzelsiegrolle des Vorschlags)" % persons)
		assert_eq(int(counts["manipulator"]), 1, "%d: der Manipulator" % persons)
		# Reihenfolge: die Rollen sind ein Präfix der festen Listen, Dorf und Wolf getrennt.
		for i: int in WOLF_ORDER.size():
			assert_eq(int(counts[WOLF_ORDER[i]]), 1 if i < _wolves(persons) else 0, "%d: Wolfsrolle %d (%s)" % [persons, i + 1, WOLF_ORDER[i]])
		var village := persons - _wolves(persons) - 1
		for i: int in VILLAGE_ORDER.size():
			assert_eq(int(counts[VILLAGE_ORDER[i]]), 1 if i < village else 0, "%d: Dorfrolle %d (%s)" % [persons, i + 1, VILLAGE_ORDER[i]])
		assert_eq(JSON.stringify(counts), JSON.stringify(RoleSuggestion.for_count(persons)), "%d: deterministisch" % persons)


func test_six_persons_exactly_as_confirmed() -> void:
	var counts: Dictionary = RoleSuggestion.for_count(6)
	assert_eq(_chosen(counts), ["das-orakel", "dorfbewohner", "manipulator", "schutzengel", "waldhexe", "werwolf"],
		"Werwolf, Manipulator, Schutzengel, Orakel, Dorfbewohner, Waldhexe")


func test_wolf_thresholds() -> void:
	for pair: Array in [[6, 1], [8, 1], [9, 2], [12, 2], [13, 3], [17, 3], [18, 4], [21, 4], [22, 5], [24, 5]]:
		assert_eq(RoleSuggestion.wolf_count(int(pair[0])), int(pair[1]), "%d Personen: %d Wolfsrollen" % [pair[0], pair[1]])
		assert_eq(_chosen(RoleSuggestion.for_count(int(pair[0]))).filter(func(id: String) -> bool: return RoleCatalog.counts_as_wolf(StringName(id))).size(), int(pair[1]),
			"%d Personen: Wolfsrollen im Vorschlag" % pair[0])
	# Schwellen: 8 → 9, 12 → 13, 17 → 18, 21 → 22 fügen genau eine Wolfsrolle hinzu und behalten die davor.
	for edge: Array in [[8, 9], [12, 13], [17, 18], [21, 22]]:
		var below := _chosen(RoleSuggestion.for_count(int(edge[0])))
		var above := _chosen(RoleSuggestion.for_count(int(edge[1])))
		var new_wolf: Array = above.filter(func(id: String) -> bool: return RoleCatalog.counts_as_wolf(StringName(id)) and not below.has(id))
		assert_eq(new_wolf, [WOLF_ORDER[_wolves(int(edge[1])) - 1]], "%d → %d: genau die nächste Wolfsrolle kommt dazu" % [edge[0], edge[1]])


## Namen der Antwort auf tatsächliche Rollen-IDs des Katalogs abgebildet: der deutsche Anzeigename der ID im Katalogtext
## stimmt mit dem Namen der Antwort überein (bei „Orakel“ mit dem Artikel „Das Orakel“).
func test_answer_names_match_catalog_ids() -> void:
	var de := po_entries(PO_DE)
	var pairs: Array = []
	for i: int in WOLF_ORDER.size():
		pairs.append([WOLF_NAMES[i], WOLF_ORDER[i]])
	for i: int in VILLAGE_ORDER.size():
		pairs.append([VILLAGE_NAMES[i], VILLAGE_ORDER[i]])
	pairs.append(["Manipulator", "manipulator"])
	for pair: Array in pairs:
		var id: String = pair[1]
		assert_true(RoleCatalog.has_role(StringName(id)), "%s ist eine Katalogrolle" % id)
		var shown := str(de.get("ui.role.%s.name" % id.replace("-", "_"), ""))
		assert_true(shown == pair[0] or shown == "Das " + str(pair[0]), "%s → %s (Katalogname: „%s“)" % [pair[0], id, shown])
	for i: int in WOLF_ORDER.size():
		assert_eq(String(RoleSuggestion.WOLF_ORDER[i]), WOLF_ORDER[i], "Wolfsreihenfolge %d" % (i + 1))
	for i: int in VILLAGE_ORDER.size():
		assert_eq(String(RoleSuggestion.VILLAGE_ORDER[i]), VILLAGE_ORDER[i], "Dorfreihenfolge %d" % (i + 1))


## Jeder Vorschlag ist über das Setup bis zum Start gültig: Rollen bestätigt (Scheinrolle des Trugbilderwolfs vom Setup vorbelegt), verteilt, Sitzordnung bestätigt, StartGame vom Regelkern angenommen. Keine Nachtfähigkeit wird ausgeführt.
func test_every_proposal_is_a_valid_start_for_the_core() -> void:
	for persons: int in range(6, 25):
		var setup := PlayerSetup.new()
		var draws := [0]
		setup.seed_source = func() -> int:
			draws[0] += 1
			return 20260930 + persons
		for i: int in persons:
			setup.add_person("Person %d" % (i + 1))
		assert_true(setup.confirm().ok, "%d: Spieler bestätigt" % persons)
		assert_true(setup.apply_suggestion().ok, "%d: Vorschlag übernommen" % persons)
		var decoys: Array = (setup.view() as Dictionary)["roles"].get("decoys", [])
		assert_eq(decoys.size(), 1 if persons >= 13 else 0, "%d: Trugbilderwolf nur mit mindestens drei Wolfsrollen" % persons)
		var open_issues: Array = (setup.view() as Dictionary)["roles"]["issues"]
		assert_eq(open_issues, [], "%d: nichts offen, die Scheinrolle ist vorbelegt" % persons)
		for d: Variant in decoys:
			assert_true(bool((d as Dictionary)["configured"]) and bool((d as Dictionary)["auto"]), "%d: Scheinrolle vorbelegt" % persons)
		assert_true(setup.confirm_roles().ok, "%d: Rollen bestätigt" % persons)
		assert_true(setup.distribute_randomly().ok, "%d: verteilt" % persons)
		assert_true(setup.confirm_distribution().ok, "%d: Verteilung bestätigt" % persons)
		assert_true(setup.go_to_step(&"seating").ok, "%d: Sitzordnung" % persons)
		assert_true(setup.confirm_seating().ok, "%d: Sitzordnung bestätigt" % persons)
		var data := setup.start_data()
		assert_true(data.ok, "%d: Startdaten" % persons)
		if not data.ok:
			continue
		var command := GameStart.build_command(data.details, 100 + persons)
		var result := RulesEngine.apply(GameState.new(), command)
		assert_true(result.ok, "%d: StartGame angenommen (%s)" % [persons, result.error])
		if not result.ok:
			continue
		var state: GameState = result.state
		assert_eq(state.alive_ids().size(), persons, "%d: alle Personen dabei" % persons)
		assert_eq(state.rng.draws, 0, "%d: keine zweite Rollenverteilung beim Start" % persons)
		var seen := {}
		for id: int in state.alive_ids():
			assert_false(seen.has(state.players[id].role_id), "%d: %s höchstens einmal" % [persons, state.players[id].role_id])
			seen[state.players[id].role_id] = true
		assert_eq(_chosen(_counts_of(state)), _chosen(RoleSuggestion.for_count(persons)), "%d: gestartete Rollen = Vorschlag" % persons)
		assert_eq(draws[0], 2 if persons >= 13 else 1, "%d: Seed-Quelle für die Verteilung und die Vorbelegung der Scheinrolle" % persons)


func _counts_of(state: GameState) -> Dictionary:
	var out := {}
	for id: int in state.alive_ids():
		out[str(state.players[id].role_id)] = 1
	return out
