extends TestCase
## Morgenbericht (MorningReport über GameSession): öffentlicher Teil nur aus der Positivliste, Rolle
## der Gestorbenen nur mit der Setup-Option, privater Teil mit Ursachen und Rettungen.

## 1 Werwolf, 2 Schutzengel, 3 Waldhexe, 4 Nachtwächter (sitzt neben dem Wolf), 5 bis 7 Dorfbewohner.
const ROLES := ["werwolf", "schutzengel", "waldhexe", "nachtwaechter", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
const SEATS := [1, 4, 2, 3, 5, 6, 7]


func _session(reveal: bool) -> GameSession:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var session := GameSession.new()
	var r := session.submit(Command.start_game({"round_id": "r", "seed": 5, "assignment": "manual", "players": Fixtures.players(7),
		"seat_order": SEATS, "roles": map, "reveal_role_on_death": reveal}))
	assert_true(r.ok, "Start (%s)" % r.error)
	return session


## Nacht: Schutz auf 5, Rudel auf 5 (gerettet), Waldhexe vergiftet 6.
func _night(session: GameSession) -> void:
	session.start_night()
	assert_true(session.answer_targets([5]).ok, "Schutz 5")
	session.begin_next_step()
	assert_true(session.answer_targets([5]).ok, "Rudel 5")
	session.begin_next_step()
	assert_true(session.answer_choice(false).ok, "kein Heiltrank")
	assert_true(session.answer_choice(true).ok, "Gift")
	assert_true(session.answer_targets([6]).ok, "Giftziel 6")
	assert_true(session.answer_choice(true).ok, "bestätigt")
	assert_true(session.end_night().ok, "Morgen")


func _all_strings(value: Variant, out: Array) -> void:
	if value is Dictionary:
		for k: Variant in value:
			out.append(str(k))
			_all_strings(value[k], out)
	elif value is Array:
		for v: Variant in value:
			_all_strings(v, out)
	else:
		out.append(str(value))


func test_public_part_without_roles_by_default() -> void:
	var session := _session(false)
	assert_true(session.morning_report().is_empty(), "vor der ersten Nacht kein Bericht")
	_night(session)
	var report := session.morning_report()
	assert_eq(int(report["night_number"]), 1, "Bericht der Nacht 1")
	assert_true(bool(report["complete"]), "Tag hat begonnen")
	var pub: Dictionary = report["public"]
	assert_eq((pub["deaths"] as Array).size(), 1, "nur die Vergiftete ist tot")
	assert_eq(int(pub["deaths"][0]["person_id"]), 6, "Person 6")
	assert_eq(str(pub["deaths"][0]["role_id"]), "", "keine Rolle ohne Setup-Option")
	var strings: Array = []
	_all_strings(pub, strings)
	for forbidden: String in ["cause", "WITCH_POISON", "protection", "schutzengel", "waldhexe", "werwolf", "dorfbewohner", "nachtwaechter", "source"]:
		assert_false(strings.has(forbidden), "öffentlicher Teil ohne %s" % forbidden)
	var notices: Array = (pub["notices"] as Array).map(func(n: Dictionary) -> String: return str(n["key"]))
	assert_eq(notices, ["ui.morning.notice.bells"], "Glocken des Nachtwächters (Wolf sitzt neben ihm)")


func test_private_part_names_causes_and_rescues() -> void:
	var session := _session(false)
	_night(session)
	var lines: Array = session.morning_report()["private"]
	var death: Array = lines.filter(func(l: Dictionary) -> bool: return str(l["key"]) == "ui.morning.private.death")
	assert_true(death.size() == 1 and str(death[0]["cause"]) == "WITCH_POISON" and str(death[0]["role_id"]) == "dorfbewohner", "Tod mit Ursache und Rolle")
	var saved: Array = lines.filter(func(l: Dictionary) -> bool: return str(l["key"]) == "ui.morning.private.saved")
	assert_true(saved.size() == 1 and int(saved[0]["person"]["person_id"]) == 5 and str(saved[0]["role_id"]) == "schutzengel", "Rettung durch den Schutzengel")


func test_reveal_option_adds_role_of_the_dead() -> void:
	var session := _session(true)
	_night(session)
	var pub: Dictionary = session.morning_report()["public"]
	assert_true(bool(pub["reveal_roles"]), "Option aktiv")
	assert_eq(str(pub["deaths"][0]["role_id"]), "dorfbewohner", "Rolle der Gestorbenen öffentlich")


func test_nobody_died() -> void:
	var session := _session(false)
	session.start_night()
	session.answer_targets([5])
	session.skip_next_step("kein Opfer")
	session.begin_next_step()
	session.answer_choice(false)
	session.answer_choice(true)
	session.end_night()
	var pub: Dictionary = session.morning_report()["public"]
	assert_eq((pub["deaths"] as Array).size(), 0, "niemand gestorben")
	var revived: Array = pub["revived"]
	assert_eq(revived.size(), 0, "niemand wiederbelebt")
