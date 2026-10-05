extends TestCase
## LogText (Feedback 8): Ein Ereignis wird zu genau einem Alltagssatz mit Namen, nie mit Typname, Schlüssel, Feldname oder Nummer.

const NAMES: Array = ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"]
const ROLES: Array = ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


func _played() -> Dictionary:
	TranslationServer.set_locale("de")
	var players: Array = []
	var map := {}
	for i: int in ROLES.size():
		players.append({"id": i + 1, "name": NAMES[i]})
		map[str(i + 1)] = ROLES[i]
	var session := GameSession.new()
	assert_true(session.submit(Command.start_game({"round_id": "log-1", "seed": 1, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(ROLES.size()), "roles": map})).ok, "Start angenommen")
	session.start_night()
	session.answer_targets([3])
	session.end_night()
	session.nominate(1, 4)
	session.decide_execution(4)
	return {"events": session.event_log(), "state": StateCodec.decode(session.save_text()).state}


func test_typical_events_become_plain_sentences_with_names() -> void:
	var played := _played()
	var lines := LogText.lines(played["events"], played["state"])
	var text := "\n".join(lines)
	for expected: String in ["Partie gestartet mit 6 Personen.", "Anna hat die Rolle Werwolf.", "Nacht 1: Çelik ist gestorben", "Tag 1: Anna nominiert Dörte.", "Tag 1: Dörte wurde hingerichtet."]:
		assert_true(text.contains(expected), "Satz vorhanden: %s" % expected)
	for line: String in lines:
		assert_false(_technical(line), "kein Programmiertext: %s" % line)
	TranslationServer.set_locale("en")
	assert_true("\n".join(LogText.lines(played["events"], played["state"])).contains("Day 1: Dörte was executed."), "EN übersetzt")
	TranslationServer.set_locale("de")


func test_unknown_and_secret_events_give_a_neutral_sentence() -> void:
	var played := _played()
	var state: GameState = played["state"]
	for type: String in ["GibtEsNicht", "HoundRecorded", "WolfChildBound", "StepBegun"]:
		var line := LogText.line({"index": 7, "type": type, "visibility": "gm", "data": {"target_id": 3, "seed": 99}}, state)
		assert_eq(line, "Etwas ist geschehen.", "neutraler Satz für %s" % type)
		assert_false(_technical(line), "kein Typname, keine Nummer: %s" % line)
	var dead := LogText.line({"type": "SeatDied", "data": {"target_id": 999, "cause": "ZauberFehler"}}, state)
	assert_eq(dead, "jemand ist gestorben.", "unbekannte Person und Ursache zeigen weder Nummer noch Namen der Ursache")


func _technical(text: String) -> bool:
	var regex := RegEx.create_from_string("_|ui\\.|[A-Z][a-z]+[A-Z]")  # snake_case, Schlüssel, CamelCase-Typname
	return regex.search(text) != null
