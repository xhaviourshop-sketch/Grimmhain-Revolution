extends TestCase
## Morgenbericht (MorningReport über GameSession): öffentlicher Teil nur aus der Positivliste, Rolle
## der Gestorbenen nur in Runden ohne Wiederbelebung (DI-01), privater Teil mit Ursachen und Rettungen.

## 1 Werwolf, 2 Schutzengel, 3 Waldhexe, 4 Nachtwächter (sitzt neben dem Wolf), 5 bis 7 Dorfbewohner.
const ROLES := ["werwolf", "schutzengel", "waldhexe", "nachtwaechter", "dorfbewohner", "amalia", "detektiv"]
const SEATS := [1, 4, 2, 3, 5, 6, 7]


## `reveal` = Runde ohne Wiederbelebung (Rolle beim Tod öffentlich); sonst Wiederbelebungsrunde (Kutscher auf Platz 7).
func _session(reveal: bool) -> GameSession:
	var roles := ROLES.duplicate()
	if not reveal:
		roles[6] = "kutscher"
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	var session := GameSession.new()
	var r := session.submit(Command.start_game({"round_id": "r", "seed": 5, "assignment": "manual", "players": Fixtures.players(7),
		"seat_order": SEATS, "roles": map}))
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
	for forbidden: String in ["cause", "WITCH_POISON", "protection", "schutzengel", "waldhexe", "werwolf", "dorfbewohner", "amalia", "nachtwaechter", "source"]:
		assert_false(strings.has(forbidden), "öffentlicher Teil ohne %s" % forbidden)
	var notices: Array = (pub["notices"] as Array).map(func(n: Dictionary) -> String: return str(n["key"]))
	assert_eq(notices, ["ui.morning.notice.bells"], "Glocken des Nachtwächters (Wolf sitzt neben ihm)")


## AUDIT-2026-10-02 S-01: Die Reihenfolge der Ansage folgt dem Sitzplatz, nie der Auflösungsreihenfolge (Gift vor Rudel).
## Das Rudel tötet Person 5 (Platz 5), die Hexe vergiftet Person 6 (Platz 6); aufgelöst wird zuerst das Gift.
func test_deaths_are_announced_by_seat_not_by_resolution_order() -> void:
	var session := _session(false)
	session.start_night()
	assert_true(session.answer_targets([7]).ok, "Schutz 7")
	session.begin_next_step()
	assert_true(session.answer_targets([5]).ok, "Rudel 5")
	session.begin_next_step()
	assert_true(session.answer_choice(false).ok, "kein Heiltrank")
	assert_true(session.answer_choice(true).ok, "Gift")
	assert_true(session.answer_targets([6]).ok, "Giftziel 6")
	assert_true(session.answer_choice(true).ok, "bestätigt")
	assert_true(session.end_night().ok, "Morgen")
	var ids := (session.morning_report()["public"]["deaths"] as Array).map(func(d: Dictionary) -> int: return int(d["person_id"]))
	assert_eq(ids, [5, 6], "Morgenansage nach Sitzplatz")


func test_private_part_names_causes_and_rescues() -> void:
	var session := _session(false)
	_night(session)
	var lines: Array = session.morning_report()["private"]
	var death: Array = lines.filter(func(l: Dictionary) -> bool: return str(l["key"]) == "ui.morning.private.death")
	assert_true(death.size() == 1 and str(death[0]["cause"]) == "WITCH_POISON" and str(death[0]["role_id"]) == "amalia", "Tod mit Ursache und Rolle")
	var saved: Array = lines.filter(func(l: Dictionary) -> bool: return str(l["key"]) == "ui.morning.private.saved")
	assert_true(saved.size() == 1 and int(saved[0]["person"]["person_id"]) == 5 and str(saved[0]["role_id"]) == "schutzengel", "Rettung durch den Schutzengel")


func test_reveal_option_adds_role_of_the_dead() -> void:
	var session := _session(true)
	_night(session)
	var pub: Dictionary = session.morning_report()["public"]
	assert_true(bool(pub["reveal_roles"]), "Option aktiv")
	assert_eq(str(pub["deaths"][0]["role_id"]), "amalia", "Rolle der Gestorbenen öffentlich")


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


# --- Historische Rolle: Die Ansage zeigt die Rolle zum Zeitpunkt des Todes ------------------------------

func _gm(session: GameSession, kind: String, fields: Dictionary) -> void:
	var r := session.submit(CorrectionFixtures.gm(kind, fields, "Test"))
	assert_true(r.ok, "%s %s (%s)" % [kind, fields, r.error])


func _death_roles(report: Dictionary) -> Array:
	return (report["public"]["deaths"] as Array).map(func(d: Dictionary) -> String: return str(d["role_id"]))


## Tod als Amalia (Dorfrolle ohne Nachtschritt), danach Rollenänderung: Bericht, privater Teil, Laden und Replay bleiben historisch.
func test_role_change_after_death_keeps_reported_role() -> void:
	var session := _session(true)
	_night(session)
	_gm(session, "set_role", {"target_id": 6, "role_id": "doktor"})
	var report := session.morning_report()
	assert_eq(_death_roles(report), ["amalia"], "öffentlich: Rolle beim Tod, nicht die spätere")
	var death: Array = (report["private"] as Array).filter(func(l: Dictionary) -> bool: return str(l["key"]) == "ui.morning.private.death")
	assert_eq(death.map(func(l: Dictionary) -> String: return str(l["role_id"])), ["amalia"], "privat: Rolle beim Tod")
	var loaded := GameSession.new()
	assert_eq(String(loaded.load_text(session.save_text())), "", "Stand geladen")
	assert_eq(loaded.morning_report(), report, "nach Laden derselbe Bericht")
	var replayed := RulesEngine.replay(session.commands())
	assert_true(replayed.ok, "Replay")
	assert_eq(MorningReport.build(replayed.state, replayed.events), report, "Replay ergibt denselben Bericht")


## Tod, Wiederbelebung, andere Rolle, erneuter Tod am selben Tag: jede Ansage mit ihrer eigenen Rolle.
func test_revive_and_second_death_each_keep_their_role() -> void:
	var session := _session(true)
	_night(session)
	_gm(session, "kill", {"target_id": 5, "trigger_effects": false})
	_gm(session, "revive", {"target_id": 5})
	_gm(session, "set_role", {"target_id": 5, "role_id": "doktor"})
	_gm(session, "kill", {"target_id": 5, "trigger_effects": false})
	_gm(session, "revive", {"target_id": 5})
	_gm(session, "set_role", {"target_id": 5, "role_id": "koenig"})
	var deaths := session.day_deaths()
	assert_eq(deaths.map(func(d: Dictionary) -> Array: return [int(d["person_id"]), str(d["role_id"])]), [[5, "dorfbewohner"], [5, "doktor"]], "zwei Tode, zwei Rollen")
	var loaded := GameSession.new()
	assert_eq(String(loaded.load_text(session.save_text())), "", "Stand geladen")
	assert_eq(loaded.day_deaths(), deaths, "nach Laden dieselben Ansagen")
	var replayed := RulesEngine.replay(session.commands())
	assert_eq(MorningReport.day_deaths(replayed.state, replayed.events), deaths, "Replay ergibt dieselben Ansagen")


## Ohne Setup-Option: keine Rolle in den zeigbaren Daten, auch nicht nach Rollenänderung oder zweitem Tod.
func test_without_reveal_no_role_in_public_data() -> void:
	var session := _session(false)
	_night(session)
	_gm(session, "set_role", {"target_id": 6, "role_id": "doktor"})
	_gm(session, "kill", {"target_id": 5, "trigger_effects": false})
	_gm(session, "revive", {"target_id": 5})
	_gm(session, "set_role", {"target_id": 5, "role_id": "koenig"})
	_gm(session, "kill", {"target_id": 5, "trigger_effects": false})
	var strings: Array = []
	_all_strings(session.morning_report()["public"], strings)
	_all_strings(session.day_deaths(), strings)
	for role: String in ["dorfbewohner", "doktor", "koenig", "werwolf", "schutzengel", "waldhexe", "nachtwaechter"]:
		assert_false(strings.has(role), "zeigbare Daten ohne %s" % role)
	assert_eq(session.day_deaths().map(func(d: Dictionary) -> String: return str(d["role_id"])), ["", ""], "Tagesansagen ohne Rolle")
