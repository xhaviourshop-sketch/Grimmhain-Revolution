extends TestCase
## Geheime Brettdaten (P3): Zustandsabzeichen und Nachtreihenfolge der Spielleitung. Reines Lesen des Kernzustands; die
## öffentliche Cockpit-Sicht bleibt ohne beides (Positivliste), die Anzeige blendet es bei „Verbergen“ aus.


func _state(count: int = 8) -> GameState:
	var commands: Array[Command] = [Fixtures.start_roles(Fixtures.unique_roles(count), 1)]
	var r := RulesEngine.replay(commands)
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state


func test_fresh_game_has_no_marks() -> void:
	assert_eq(NightBoardView.marks(_state()), {}, "ohne Wirkung keine Abzeichen")
	assert_eq(NightBoardView.marks(GameState.new()), {}, "ohne Partie leer")


func test_marks_map_core_state_to_the_five_kinds() -> void:
	var s := _state()
	var protection := Protection.new()
	protection.guardian_id = 5
	protection.target_id = 2
	protection.night = 1
	s.protections.append(protection)
	s.wolf_poisons.append({"target_id": 3, "source_id": 1, "due_night": 2})
	s.pack_target_id = 4
	s.judge_marks.append({"judge_id": 6, "target_id": 4})
	s.blocked_ids.append(7)
	s.infected.append(8)
	var marks := NightBoardView.marks(s)
	assert_eq(marks.get(2), ["protected"], "Schutz")
	assert_eq(marks.get(3), ["poisoned"], "Gift")
	assert_eq(marks.get(4), ["marked"], "Opfer und Markierung ergeben eine Art, nicht zwei")
	assert_eq(marks.get(7), ["silenced"], "blockiert")
	assert_eq(marks.get(8), ["special"], "infiziert")
	assert_false(marks.has(1), "Person ohne Wirkung ohne Abzeichen")


func test_one_person_can_carry_several_kinds_in_a_fixed_order() -> void:
	var s := _state()
	s.infected.append(2)
	s.blocked_ids.append(2)
	s.wolf_poisons.append({"target_id": 2, "source_id": 1, "due_night": 2})
	var protection := Protection.new()
	protection.guardian_id = 5
	protection.target_id = 2
	protection.night = 1
	s.protections.append(protection)
	assert_eq(NightBoardView.marks(s).get(2), ["protected", "poisoned", "silenced", "special"], "feste Reihenfolge, unabhängig vom Eintragen")


func test_dead_people_carry_no_marks() -> void:
	var s := _state()
	s.infected.append(3)
	s.players[3].alive = false
	assert_false(NightBoardView.marks(s).has(3), "Tote zeigen nur den Tod, nie Zustände")


func test_public_cockpit_view_never_contains_marks_or_order() -> void:
	var s := _state()
	s.infected.append(3)
	var view := CockpitView.build(s)
	var text := JSON.stringify(view)
	assert_false(view.has("marks") or view.has("night_order"), "kein Schlüssel für Brettdaten in der öffentlichen Sicht")
	for seat: Dictionary in view["seats"]:
		for key: String in ["marks", "badges", "role_id", "status"]:
			assert_false(seat.has(key), "Sitz ohne %s" % key)
	assert_false(text.contains("special"), "kein Zustand in der öffentlichen Sicht")


func test_night_order_outside_the_night_is_empty() -> void:
	assert_eq(NightBoardView.night_order(_state()), [], "vor der ersten Nacht keine Reihenfolge")


func test_night_order_follows_progress() -> void:
	var s := _state(12)
	var r := apply_ok(s, Command.start_night(), "Nacht")
	s = r.state
	var order := NightBoardView.night_order(s)
	assert_false(order.is_empty(), "Reihenfolge der Nacht")
	var active := 0
	var last_slot := -1
	for entry: Dictionary in order:
		assert_true(["done", "active", "upcoming"].has(str(entry["state"])), "bekannter Zustand")
		assert_true(int(entry["slot"]) >= last_slot, "nach Nachtposition sortiert")
		last_slot = int(entry["slot"])
		if str(entry["state"]) == "active":
			active += 1
	assert_eq(active, 1, "genau ein aktiver Eintrag")
	var roles: Array = order.map(func(e: Dictionary) -> String: return str(e["role_id"]))
	assert_eq(roles.size(), (roles.duplicate() as Array).filter(func(x: String) -> bool: return roles.count(x) == 1).size(), "jede Rolle nur einmal")
	assert_true(roles.has("werwolf"), "das Rudel erscheint als Werwolf")


func test_night_order_has_no_effect_on_the_state() -> void:
	var s := _state(12)
	s = apply_ok(s, Command.start_night(), "Nacht").state
	var before := CanonicalJson.stringify(s.to_dict())
	NightBoardView.night_order(s)
	NightBoardView.marks(s)
	assert_eq(CanonicalJson.stringify(s.to_dict()), before, "Lesen verändert nichts")
