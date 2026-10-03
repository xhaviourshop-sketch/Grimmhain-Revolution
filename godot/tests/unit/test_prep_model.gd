extends TestCase
## Vorbereitung „Neue Partie“ in drei Schritten (DA-89), ohne Oberfläche: Akt-Sätze gegen den Rollenkatalog, Vorschlag je Akt und
## Spielerzahl als gültiger Start für den Regelkern, Blocker und Warnungen, Namensreihenfolge = Sitzordnung, Zuordnung im Modus
## „Echte Karten“, zufällige Verteilung mit gespeichertem Seed und dieselbe StartGame-Struktur wie zuvor. Keine festen Rollenzahlen:
## Erwartungen kommen aus Katalog und Akt-Karten.

const SEED := 20261003


func _setup_with(count: int, act: StringName = &"akt2", seed_value: int = SEED) -> PlayerSetup:
	var setup := PlayerSetup.new()
	setup.seed_source = func() -> int: return seed_value
	setup.set_act(act)
	setup.set_player_count(count)
	for i: int in count:
		setup.add_person("Person %d" % (i + 1))
	return setup


func _ready_to_start(count: int, act: StringName = &"akt2") -> PlayerSetup:
	var setup := _setup_with(count, act)
	var result := setup.go_to_step(SetupDraft.STEP_ROLES)
	assert_true(result.ok, "%d Personen, %s: Rollenschritt erreichbar (%s)" % [count, act, result.error])
	return setup


func _start_command(setup: PlayerSetup) -> Command:
	var data := setup.prepare_start()
	assert_true(data.ok, "Startdaten (%s)" % data.error)
	return GameStart.build_command(data.details, SEED)


func test_acts_match_the_role_catalog() -> void:
	var union := {}
	for act: StringName in ActCatalog.ACT_IDS:
		var seen := {}
		var teams := {Faction.VILLAGE: ActCatalog.village(act), Faction.WOLVES: ActCatalog.wolves(act), Faction.SOLO: ActCatalog.solo(act)}
		for team: StringName in teams:
			for role: StringName in teams[team]:
				assert_true(SetupRoleCatalog.has_role(role), "%s: %s steht im Katalog" % [act, role])
				assert_false(seen.has(role), "%s: %s nur einmal" % [act, role])
				seen[role] = true
				union[role] = true
				assert_eq(SetupRoleCatalog.faction_of(role), team, "%s: %s liegt im Team %s" % [act, role, team])
		assert_eq(ActCatalog.roles(act).size(), seen.size(), "%s: Rollenliste ohne Dopplung" % act)
		assert_true(ActCatalog.capacity(act, true) >= ActCatalog.capacity(act, false), "%s: Totenreichkarten verkleinern nie die Tragkraft" % act)
	assert_eq(union.size(), SetupRoleCatalog.role_ids().size(), "die vier Akte decken alle Katalogrollen ab")


func test_every_act_proposal_is_a_valid_start_for_the_core() -> void:
	for act: StringName in ActCatalog.ACT_IDS:
		for count: int in range(PersonNameRules.MIN_PERSONS, PersonNameRules.MAX_PERSONS + 1):
			var counts := RoleSuggestion.for_act(act, count)
			if count > ActCatalog.capacity(act, false):
				assert_true(counts.is_empty(), "%s, %d: Akt zu klein, kein Vorschlag" % [act, count])
				continue
			var chosen: Array[StringName] = []
			for key: String in counts:
				if int(counts[key]) > 0:
					chosen.append(StringName(key))
					assert_true(ActCatalog.contains(act, StringName(key)), "%s, %d: %s gehört zum Akt" % [act, count, key])
					assert_false(RoleCatalog.requires_cards(StringName(key)), "%s, %d: keine Kartenrolle ohne Totenreichkarten" % [act, count])
			assert_eq(chosen.size(), count, "%s, %d: eine Rolle je Person" % [act, count])
			var wolves := chosen.filter(func(r: StringName) -> bool: return RoleCatalog.counts_as_wolf(r)).size()
			assert_true(wolves >= 1, "%s, %d: mindestens eine Wolfsrolle" % [act, count])
			assert_true(chosen.any(func(r: StringName) -> bool: return SetupRoleCatalog.is_village(r)), "%s, %d: mindestens eine Dorfrolle" % [act, count])
			assert_eq(JSON.stringify(counts), JSON.stringify(RoleSuggestion.for_act(act, count)), "%s, %d: deterministisch" % [act, count])
			var setup := _ready_to_start(count, act)
			assert_true((setup.blockers() as Array).is_empty(), "%s, %d: keine Blocker (%s)" % [act, count, setup.blockers()])
			var result := RulesEngine.apply(GameState.new(), _start_command(setup))
			assert_true(result.ok, "%s, %d: Regelkern nimmt den Start an (%s)" % [act, count, result.error])


func test_act_that_is_too_small_blocks_instead_of_borrowing_roles() -> void:
	var small := ActCatalog.ACT_IDS.filter(func(a: StringName) -> bool: return ActCatalog.capacity(a, false) < PersonNameRules.MAX_PERSONS)
	assert_false(small.is_empty(), "mindestens ein Akt trägt nicht 24 Personen")
	var act: StringName = small[0]
	var count := ActCatalog.capacity(act, false) + 1
	var setup := _setup_with(count, act)
	assert_true((setup.blockers() as Array[StringName]).has(&"act_too_small"), "Blocker act_too_small")
	assert_false(setup.go_to_step(SetupDraft.STEP_ROLES).ok, "Rollenschritt gesperrt")
	assert_false(bool(setup.view()["act_fits"]), "Sicht meldet: passt nicht")


func test_names_order_is_the_seating() -> void:
	var setup := _setup_with(8)
	var ids: Array = setup.view()["persons"].map(func(p: Dictionary) -> int: return int(p["person_id"]))
	assert_true(setup.move_person(ids[3], -2).ok, "Person 4 zwei Plätze früher")
	assert_true(setup.move_person(ids[0], 99).ok, "Person 1 ans Ende (Rand begrenzt)")
	var moved: Array = setup.view()["persons"].map(func(p: Dictionary) -> int: return int(p["person_id"]))
	assert_eq(moved, [ids[3], ids[1], ids[2], ids[4], ids[5], ids[6], ids[7], ids[0]], "neue Reihenfolge")
	assert_eq(setup.view()["persons"].map(func(p: Dictionary) -> int: return int(p["number"])), [1, 2, 3, 4, 5, 6, 7, 8], "Nummern folgen dem Platz")
	var twin := _setup_with(8)
	assert_true(setup.shuffle_persons().ok and twin.shuffle_persons().ok, "mischen")
	assert_eq(setup.view()["persons"].map(func(p: Dictionary) -> String: return str(p["name"])).size(), 8, "nichts geht verloren")
	var again := _setup_with(8)
	again.shuffle_persons()
	assert_eq(JSON.stringify(twin.view()["persons"]), JSON.stringify(again.view()["persons"]), "gleicher Seed, gleiche Reihenfolge")
	var by_id := {}
	for p: Dictionary in setup.view()["persons"]:
		by_id[int(p["person_id"])] = str(p["name"])
	for id: int in ids:
		assert_true(by_id.has(id), "Personen-ID %d bleibt" % id)
	setup.go_to_step(SetupDraft.STEP_ROLES)
	var data := setup.prepare_start()
	assert_true(data.ok, "Start (%s)" % data.error)
	assert_eq(data.details["seat_order"], setup.view()["persons"].map(func(p: Dictionary) -> int: return int(p["person_id"])), "Sitzordnung = Namensreihenfolge")
	assert_eq(data.details["players"].map(func(p: Dictionary) -> int: return int(p["id"])), data.details["seat_order"], "players in Sitzreihenfolge")


func test_blockers_and_warnings() -> void:
	var setup := _ready_to_start(10, &"akt3")
	var roles: Dictionary = setup.view()["roles"]
	var solo := ""
	for key: String in roles["counts"]:
		if int(roles["counts"][key]) > 0 and SetupRoleCatalog.is_solo(StringName(key)):
			solo = key
	assert_ne(solo, "", "der Vorschlag enthält eine Einzelgängerrolle")
	assert_true(setup.remove_role(StringName(solo)).ok, "Einzelgängerrolle entfernen")
	assert_true((setup.blockers() as Array[StringName]).has(&"too_few_roles"), "Rolle fehlt: Blocker (Summe)")
	var filler := ""
	for role: StringName in RolePresentation.sorted_roles():
		if SetupRoleCatalog.is_village(role) and int(setup.view()["roles"]["counts"][String(role)]) == 0 and RoleCatalog.max_copies(role) == 1:
			filler = String(role)
			break
	assert_true(setup.add_role(StringName(filler)).ok, "Dorfrolle ergänzen")
	assert_true((setup.blockers() as Array).is_empty(), "ohne Einzelgänger startbar: %s" % [setup.blockers()])
	assert_true((setup.view()["warnings"] as Array).has("missing_solo"), "fehlende Einzelgängerrolle ist eine Warnung")
	assert_true(bool(setup.view()["can_start"]), "Start möglich")
	for key: String in setup.view()["roles"]["counts"]:
		if int(setup.view()["roles"]["counts"][key]) > 0 and RoleCatalog.counts_as_wolf(StringName(key)):
			setup.remove_role(StringName(key))
	assert_true((setup.blockers() as Array[StringName]).has(&"missing_wolf"), "kein Wolf bleibt Blocker")
	assert_false(bool(setup.view()["can_start"]), "kein Start ohne Wolf")
	var names_missing := _setup_with(8)
	names_missing.remove_person(int(names_missing.view()["persons"][0]["person_id"]))
	names_missing.set_player_count(8)
	assert_true((names_missing.blockers() as Array[StringName]).has(&"names_incomplete"), "Namen fehlen: Blocker")
	assert_eq(int(names_missing.view()["fit_count"]), 7, "Knopf: Spielerzahl auf die Namen anpassen")
	assert_true(names_missing.fit_player_count_to_names().ok, "Spielerzahl angepasst")
	assert_eq(int(names_missing.view()["player_count"]), 7, "neue Spielerzahl")
	assert_false(setup.set_player_count(PersonNameRules.MAX_PERSONS + 1).ok, "mehr als 24 abgelehnt")
	assert_false(setup.set_player_count(PersonNameRules.MIN_PERSONS - 1).ok, "weniger als 6 abgelehnt")


func test_real_cards_mode_needs_every_assignment() -> void:
	var setup := _ready_to_start(9, &"akt1")
	assert_true(setup.set_distribution_mode(DistributionDraft.MANUAL).ok, "Modus Echte Karten")
	assert_false(bool(setup.view()["can_start"]), "ohne Zuordnung kein Start")
	var early := setup.prepare_start()
	assert_false(early.ok, "prepare_start verteilt im Kartenmodus nichts")
	assert_eq(early.error, &"distribution_incomplete", "Fehlercode")
	var units: Array[StringName] = []
	for entry: Dictionary in setup.view()["distribution"]["remaining_units"]:
		for i: int in int(entry["left"]):
			units.append(StringName(str(entry["unit"])))
	var persons: Array = setup.view()["persons"]
	for i: int in persons.size() - 1:
		assert_true(setup.assign_role(int(persons[i]["person_id"]), units[i]).ok, "Platz %d zugeordnet" % (i + 1))
	assert_eq(int(setup.view()["distribution"]["assigned_count"]), persons.size() - 1, "Fortschritt zählt mit")
	assert_false(bool(setup.view()["can_start"]), "eine Person fehlt noch")
	assert_true(setup.assign_role(int(persons[-1]["person_id"]), units[-1]).ok, "letzte Zuordnung")
	assert_true(bool(setup.view()["can_start"]), "alle zugeordnet: Start möglich")
	var data := setup.prepare_start()
	assert_true(data.ok, "Start (%s)" % data.error)
	for i: int in persons.size():
		assert_eq(str(data.details["roles"][str(int(persons[i]["person_id"]))]), String(RoleCopy.role_of(units[i])), "Rolle von Platz %d wie zugeordnet" % (i + 1))
	assert_true(setup.unassign_role(int(persons[0]["person_id"])).ok, "Zuordnung löschen")
	assert_false(bool(setup.view()["can_start"]), "wieder unvollständig")
	assert_true(setup.set_distribution_mode(DistributionDraft.RANDOM).ok, "zurück zu zufällig")
	assert_eq(int(setup.view()["distribution"]["assigned_count"]), 0, "Modus-Wechsel verwirft die Zuordnung")


func test_random_mode_distributes_once_with_a_stored_seed() -> void:
	var calls := [0]
	var setup := PlayerSetup.new()
	setup.seed_source = func() -> int:
		calls[0] += 1
		return SEED
	setup.set_player_count(8)
	for i: int in 8:
		setup.add_person("Person %d" % (i + 1))
	setup.go_to_step(SetupDraft.STEP_ROLES)
	assert_eq(int(setup.view()["distribution"]["assigned_count"]), 0, "vor dem Start wird nichts verteilt")
	var first := setup.prepare_start()
	assert_true(first.ok, "Start (%s)" % first.error)
	var again := setup.prepare_start()
	assert_eq(JSON.stringify(first.details["roles"]), JSON.stringify(again.details["roles"]), "erneutes Verteilen mit gespeichertem Seed: gleich")
	var twin := _setup_with(8, &"akt1")
	twin.go_to_step(SetupDraft.STEP_ROLES)
	var other := PlayerSetup.new()
	other.seed_source = func() -> int: return SEED
	other.set_player_count(8)
	for i: int in 8:
		other.add_person("Person %d" % (i + 1))
	other.go_to_step(SetupDraft.STEP_ROLES)
	assert_eq(JSON.stringify(other.prepare_start().details["roles"]), JSON.stringify(first.details["roles"]), "gleiche Eingabe, gleicher Seed: gleiche Zuordnung")


func test_start_command_has_the_same_structure_as_before() -> void:
	var setup := _ready_to_start(12, &"akt3")
	var command := _start_command(setup)
	var payload := command.payload
	var expected: Array[String] = ["assignment", "players", "roles", "round_id", "seat_order", "seed"]
	if payload.has("appearances"):
		expected.append("appearances")
	if payload.has("death_cards"):
		expected.append("death_cards")
	var keys: Array = payload.keys()
	keys.sort()
	expected.sort()
	assert_eq(keys, expected, "Felder des StartGame-Befehls")
	assert_eq(payload["assignment"], "manual", "feste Zuordnung")
	assert_eq(payload["players"].size(), 12, "players")
	assert_true(RulesEngine.apply(GameState.new(), command).ok, "Regelkern nimmt an")


func test_role_actions_swap_remove_add_and_decoy() -> void:
	var setup := _ready_to_start(10, &"akt3")
	var roles: Dictionary = setup.view()["roles"]
	assert_true(int(roles["counts"]["trugbilderwolf"]) + int(roles["counts"]["spiegelwolf"]) + int(roles["counts"]["werwolf"]) >= 1, "Wolfsrollen vorhanden")
	if int(roles["counts"]["trugbilderwolf"]) == 0:
		assert_true(setup.replace_role(&"werwolf", &"trugbilderwolf").ok, "Werwolf gegen Trugbilderwolf tauschen")
	var decoys: Array = setup.view()["roles"]["decoys"]
	assert_eq(decoys.size(), 1, "eine Kopie des Trugbilderwolfs")
	assert_true(bool(decoys[0]["configured"]), "Scheinrolle vorbelegt (DA-88)")
	assert_true(setup.set_decoy_appearance(int(decoys[0]["copy_id"]), &"dorfbewohner").ok or setup.set_decoy_appearance(int(decoys[0]["copy_id"]), &"schutzengel").ok, "Scheinrolle ändern")
	assert_true(setup.remove_role(&"trugbilderwolf").ok, "Trugbilderwolf entfernen (samt Kopie)")
	assert_eq((setup.view()["roles"]["decoys"] as Array).size(), 0, "Kopie ist weg")
	assert_false(setup.replace_role(&"trugbilderwolf", &"werwolf").ok, "nicht vorhandene Rolle tauschen: abgelehnt")
	var cards := setup.add_role(&"kartenschlucker")
	assert_false(cards.ok, "Kartenschlucker ohne Totenreichkarten: abgelehnt")
	assert_true(setup.apply_suggestion().ok, "Neuer Vorschlag")
	assert_true(bool(setup.view()["roles"]["is_suggestion"]), "Auswahl = Vorschlag")


func test_going_back_keeps_names_and_roles() -> void:
	var setup := _ready_to_start(9, &"akt2")
	setup.replace_role(&"werwolf", &"blutwolf") if int(setup.view()["roles"]["counts"]["blutwolf"]) == 0 else null
	var before := JSON.stringify(setup.view()["roles"]["counts"])
	assert_true(setup.go_to_step(SetupDraft.STEP_NAMES).ok and setup.go_to_step(SetupDraft.STEP_ROUND).ok, "zwei Schritte zurück")
	assert_eq(setup.view()["count"], 9, "Namen bleiben")
	assert_true(setup.go_to_step(SetupDraft.STEP_NAMES).ok and setup.go_to_step(SetupDraft.STEP_ROLES).ok, "wieder vor")
	assert_eq(JSON.stringify(setup.view()["roles"]["counts"]), before, "Rollenauswahl bleibt unverändert")
	assert_true(setup.go_to_step(SetupDraft.STEP_ROUND).ok, "zur Runde")
	setup.set_act(&"akt4")
	assert_eq(int(setup.view()["roles"]["total"]), 0, "anderer Akt verwirft die Auswahl")
	assert_true(setup.go_to_step(SetupDraft.STEP_NAMES).ok, "Namen")
	assert_true(setup.go_to_step(SetupDraft.STEP_ROLES).ok, "neuer Vorschlag beim Öffnen")
	assert_eq(int(setup.view()["roles"]["total"]), 9, "Vorschlag passt zur Personenzahl")
