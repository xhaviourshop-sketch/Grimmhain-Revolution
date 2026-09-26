extends TestCase
## AS-C09 (Kernanteil): Zustand hängt an der stabilen Personen-ID, nicht am Sitz.
## Der Befehl ReorderSeats gehört laut implementation-boundary.md zu B-11; hier wird
## die Trennung mit einer nicht trivialen Sitzreihenfolge beim Spielstart geprüft.


func test_ids_are_independent_of_seat_order() -> void:
	var order: Array[int] = [4, 2, 6, 1, 3, 5]
	var run := RulesEngine.replay([
		Fixtures.start_manual(6, [1, 2], 1, order),
		Command.start_night(),
		Command.answer_prompt(1, [6]),
		Command.end_night(),
	] as Array[Command])
	assert_true(run.ok, "Partie angenommen")
	var state := run.state
	assert_eq(state.seat_order, order, "Sitzreihenfolge unverändert gespeichert")
	assert_false(state.players[6].alive, "Person 6 ist tot")
	assert_eq(state.players[6].name, "F", "Person 6 ist weiterhin F")
	assert_eq(state.seat_of(6), 2, "Person 6 sitzt auf Sitzindex 2")
	assert_true(state.players[4].alive, "Person auf Sitzindex 0 (ID 4) lebt")
	assert_eq(state.players[6].death.target_id, 6, "Todesdatensatz referenziert die Personen-ID")


func test_player_record_has_no_seat_field() -> void:
	var state := Fixtures.play([Fixtures.start_manual(6, [1], 1, [6, 5, 4, 3, 2, 1] as Array[int])] as Array[Command])
	var player_dict: Dictionary = (state.to_dict()["players"] as Array)[0]
	for key: String in player_dict.keys():
		assert_false(key.contains("seat"), "Personendatensatz enthält kein Sitzfeld (%s)" % key)
	assert_eq(int(player_dict["id"]), 1, "Personen im Zustand nach ID sortiert, nicht nach Sitz")


func test_seat_order_must_be_permutation_of_ids() -> void:
	var bad_orders: Array = [[1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7]]
	for order: Array in bad_orders:
		var typed: Array[int] = []
		typed.assign(order)
		var result := RulesEngine.apply(GameState.new(), Fixtures.start_manual(6, [1], 1, typed))
		assert_false(result.ok, "ungültige Sitzreihenfolge %s abgelehnt" % str(order))
		assert_eq(String(result.error), "invalid_seat_order", "Fehlergrund für %s" % str(order))


func test_role_fields_are_separate() -> void:
	var state := Fixtures.play([Fixtures.start_manual(6, [1])] as Array[Command])
	var wolf := state.players[1]
	var villager := state.players[2]
	assert_eq(String(wolf.role_id), "werwolf", "Rolle Wolf")
	assert_eq(String(wolf.faction), "wolves", "Fraktion Wolf")
	assert_true(wolf.counts_as_wolf, "Wolf zählt als Wolf")
	assert_eq(String(wolf.appears_as), "werwolf", "Erscheinung Wolf")
	assert_eq(String(villager.role_id), "dorfbewohner", "Rolle Dorf")
	assert_eq(String(villager.faction), "village", "Fraktion Dorf")
	assert_false(villager.counts_as_wolf, "Dorfbewohner zählt nicht als Wolf")
	assert_eq(String(wolf.original_role_id), "werwolf", "ursprüngliche Rolle gespeichert")
