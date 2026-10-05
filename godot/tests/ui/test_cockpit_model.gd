extends TestCase
## Cockpit-Sicht der Anwendungsschicht (CockpitView, PromptView über GameSession): Sitzkreis aus
## der gestarteten Partie ohne Rollen, nächster Schritt aus dem Regelkern, vollständige erste Nacht
## über die Befehlsbausteine, Positivliste der gezeigten Karte.

## 1 Werwolf, 2 Trugbilderwolf (Scheinrolle Dorfbewohner), 3 Schutzengel, 4 Waldhexe, 5 Orakel,
## 6 und 7 Dorfbewohner. Sitzordnung bewusst nicht nach ID.
const ROLES := ["werwolf", "trugbilderwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "amalia"]
const SEATS: Array[int] = [3, 1, 4, 7, 2, 6, 5]


func _session() -> GameSession:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var session := GameSession.new()
	var r := session.submit(Command.start_game({
		"round_id": "test-round", "seed": 7, "assignment": "manual",
		"players": Fixtures.players(ROLES.size()), "seat_order": SEATS, "roles": map,
		"appearances": {"2": "dorfbewohner"},
	}))
	assert_true(r.ok, "StartGame angenommen (%s)" % r.error)
	return session


func _role_ids() -> Array[String]:
	var out: Array[String] = []
	for r: String in ROLES:
		out.append(r)
	return out


## Sucht rekursiv nach Rollen-IDs oder Rollenfeldern in einer Sicht.
func _contains_role(value: Variant) -> bool:
	if value is Dictionary:
		for k: Variant in value:
			if str(k).contains("role") or _contains_role(value[k]):
				return true
		return false
	if value is Array:
		for v: Variant in value:
			if _contains_role(v):
				return true
		return false
	return value is String and _role_ids().has(value)


func test_no_game_view() -> void:
	var view := GameSession.new().cockpit_view()
	assert_false(bool(view["has_game"]), "ohne Partie")
	assert_eq(view.size(), 1, "keine weiteren Daten ohne Partie")


func test_seats_follow_seat_order_without_roles() -> void:
	var view := _session().cockpit_view()
	assert_true(bool(view["has_game"]), "Partie aktiv")
	assert_eq(str(view["phase"]), "SETUP", "Phase aus dem Regelkern")
	var seats: Array = view["seats"]
	assert_eq(seats.size(), 7, "alle Personen")
	for i: int in seats.size():
		var seat: Dictionary = seats[i]
		assert_eq(int(seat["person_id"]), SEATS[i], "Sitz %d in Sitzreihenfolge" % (i + 1))
		assert_eq(int(seat["seat"]), i + 1, "Platznummer ab 1")
		assert_eq(str(seat["name"]), str(Fixtures.players(7)[SEATS[i] - 1]["name"]), "Name der Person")
		assert_true(bool(seat["alive"]), "lebt")
	assert_eq(str((view["next"] as Dictionary)["kind"]), "start_night", "nächster Schritt: Nacht beginnen")
	assert_false(_contains_role(view), "öffentliche Sicht ohne Rollen")


func test_private_seats_contain_roles_and_appearance() -> void:
	var seats := _session().private_seats()
	assert_eq(seats.size(), 7, "alle Personen")
	var by_id := {}
	for s: Dictionary in seats:
		by_id[int(s["person_id"])] = s
	assert_eq(str(by_id[3]["role_id"]), "schutzengel", "Rolle im privaten Bereich")
	var notes: Array = by_id[2]["notes"]
	assert_true(notes.any(func(n: Dictionary) -> bool: return str(n["key"]) == "ui.cockpit.private.appears_as" and str(n["role_id"]) == "dorfbewohner"), "Scheinrolle des Trugbilderwolfs")


func test_full_first_night_through_session() -> void:
	var session := _session()
	assert_true(session.start_night().ok, "StartNight")
	var next: Dictionary = session.cockpit_view()["next"]
	# Der erste Schritt beginnt mit StartNight selbst: Schutzengel.
	assert_eq(str(next["kind"]), "prompt", "offener Prompt")
	assert_true(bool(next["secret"]), "Prompt ist geheim")
	assert_eq(str(next["owner"]), "schutzengel", "Schutzengel zuerst")
	assert_eq(str(next["answer"]), "targets", "Personenauswahl")
	assert_eq([int(next["min"]), int(next["max"])], [1, 1], "genau eine Person")
	assert_false((next["allowed_ids"] as Array).has(3), "nicht sich selbst")
	assert_true(session.answer_targets([6]).ok, "Schutz für 6")

	next = session.cockpit_view()["next"]
	assert_eq(str(next["kind"]), "begin_step", "nächster Schritt angekündigt")
	assert_eq(str(next["role_id"]), "pack", "Rudel")
	assert_eq(next["actor_ids"], [1, 2], "Rudel aus beiden Wölfen")
	assert_true(bool(next["skippable"]), "Rudel überspringbar")
	assert_eq([int(next["index"]), int(next["total"])], [2, 4], "Schritt 2 von 4")
	assert_true(session.begin_next_step().ok, "BeginStep Rudel")
	next = session.cockpit_view()["next"]
	assert_eq([int(next["min"]), int(next["max"])], [1, 1], "genau ein Opfer (kein Verzicht laut Kartentext)")
	assert_true(session.answer_targets([7]).ok, "Rudel wählt 7")

	assert_true(session.begin_next_step().ok, "BeginStep Waldhexe")
	next = session.cockpit_view()["next"]
	assert_eq(str(next["owner"]), "waldhexe", "Waldhexe")
	assert_eq(str(next["stage"]), "heal", "zuerst Heiltrank")
	assert_eq(str(next["answer"]), "choice", "Ja/Nein")
	assert_true(session.answer_choice(true).ok, "rettet")
	next = session.cockpit_view()["next"]
	assert_eq(str(next["stage"]), "reveal", "Rolle des Opfers")
	assert_eq(str(next["answer"]), "ack", "zur Kenntnis nehmen")
	var shown: Array = next["show"]
	assert_eq(shown.size(), 2, "Opfer und Rolle zeigbar")
	assert_true(session.answer_choice(true).ok, "gesehen")
	assert_eq(str(session.cockpit_view()["next"]["stage"]), "poison", "Gifttrank")
	assert_true(session.answer_choice(false).ok, "kein Gift")
	next = session.cockpit_view()["next"]
	assert_eq(str(next["stage"]), "confirm", "Zusammenfassung")
	assert_true(session.answer_choice(true).ok, "bestätigt")

	assert_true(session.begin_next_step().ok, "BeginStep Orakel")
	assert_true(session.answer_targets([2]).ok, "Orakel prüft den Trugbilderwolf")
	next = session.cockpit_view()["next"]
	assert_eq(str(next["stage"]), "shown", "Ergebnis zeigen")
	var show_keys: Array = []
	for line: Dictionary in next["show"]:
		show_keys.append(str(line["key"]))
		if str(line["key"]) == "shown_role":
			assert_eq(str(line["value"]), "dorfbewohner", "gezeigt wird die Scheinrolle")
	assert_eq(show_keys, ["target_id", "shown_role"], "Positivliste ohne Wahrheit")
	var info_keys: Array = (next["info"] as Array).map(func(l: Dictionary) -> String: return str(l["key"]))
	assert_true(info_keys.has("truth_role"), "Spielleiter sieht die Wahrheit im Prompt")
	assert_true(session.answer_choice(true).ok, "Gezeigt")

	next = session.cockpit_view()["next"]
	assert_eq(str(next["kind"]), "end_night", "alle Schritte erledigt")
	assert_true(session.end_night().ok, "EndNight")
	var view := session.cockpit_view()
	assert_eq(str(view["phase"]), "DAY", "Tag nach der Morgenauflösung")
	assert_eq(str((view["next"] as Dictionary)["kind"]), "day", "Tagesaktionen")
	var seven: Dictionary = (view["seats"] as Array).filter(func(s: Dictionary) -> bool: return int(s["person_id"]) == 7)[0]
	assert_true(bool(seven["alive"]), "Opfer von der Waldhexe gerettet")


func test_rejected_answer_keeps_state() -> void:
	var session := _session()
	session.start_night()
	var hash_before := session.state_hash()
	var rejected: Array = []
	session.command_rejected.connect(func(e: StringName) -> void: rejected.append(e))
	assert_false(session.answer_targets([3]).ok, "Schutzengel darf sich nicht selbst wählen")
	assert_eq(session.state_hash(), hash_before, "Zustand unverändert")
	assert_eq(rejected.size(), 1, "Ablehnung gemeldet")
	# Doppeltes Bestätigen: zweiter Befehl trifft keinen offenen Prompt mehr.
	assert_true(session.answer_targets([6]).ok, "erste Antwort")
	assert_false(session.answer_targets([6]).ok, "zweite Antwort abgelehnt")


func test_cancel_restores_hash() -> void:
	var session := _session()
	session.start_night()
	session.answer_targets([6])
	var before := session.state_hash()
	session.begin_next_step()
	assert_true(session.cancel_prompt("versehentlich").ok, "Rudel-Prompt abgebrochen")
	assert_eq(session.state_hash(), before, "Hash wie vor dem Beginn")
	assert_eq(str(session.cockpit_view()["next"]["kind"]), "begin_step", "Schritt erneut anzubieten")


func test_skip_requires_reason() -> void:
	var session := _session()
	session.start_night()
	session.answer_targets([6])
	assert_false(session.skip_next_step("  ").ok, "ohne Grund abgelehnt")
	assert_true(session.skip_next_step("Rudel schläft").ok, "mit Grund")
	assert_eq(str(session.cockpit_view()["next"]["role_id"]), "waldhexe", "weiter mit der Waldhexe")


## Gestohlene Fähigkeit (Grabräuber): Die Ankündigung nennt die übernommene Rolle und die eigene.
func test_stolen_ability_is_announced_with_own_role() -> void:
	var session := GameSession.new()
	session.submit(Fixtures.start_roles(["grabraeuber", "waldhexe", "werwolf", "dorfbewohner", "amalia", "detektiv"]))
	assert_true(session.gm_correction({"kind": "kill", "target_id": 2, "trigger_effects": false, "reason": "Test"}).ok, "Waldhexe tot")
	session.start_night()
	assert_true(session.skip_next_step("kein Opfer").ok, "Rudel übersprungen")
	assert_true(session.begin_next_step().ok, "Grabräuber-Schritt")
	var next: Dictionary = session.cockpit_view()["next"]
	assert_eq([str(next["owner"]), str(next["stage"])], ["grabraeuber", "targets"], "Grabräuber wählt einen Toten")
	assert_eq(next["allowed_ids"], [2], "nur die tote Waldhexe")
	var steal := session.answer_targets([2])
	assert_true(steal.ok, "stiehlt die Fähigkeit (%s)" % steal.error)
	for guard: int in 10:
		var n: Dictionary = session.cockpit_view()["next"]
		if str(n["kind"]) == "day":
			break
		var ok := false
		match str(n["kind"]):
			"begin_step", "prompt":
				ok = session.skip_next_step("kein Opfer").ok
			"end_night":
				ok = session.end_night().ok
		assert_true(ok, "Nacht 1 weiter (%s)" % n["kind"])
		if not ok:
			return
	session.decide_execution(-1)
	session.end_day()
	session.start_night()
	var found := false
	for i: int in 6:
		next = session.cockpit_view()["next"]
		if str(next["kind"]) == "begin_step" and str(next["role_id"]) == "waldhexe":
			found = true
			assert_eq(str(next["own_role_id"]), "grabraeuber", "eigene Rolle für den Hinweis")
			assert_eq(next["actor_ids"], [1], "handelnd: der Grabräuber")
			break
		if str(next["kind"]) == "prompt" and str(next["owner"]) == "pack":
			session.skip_next_step("kein Opfer")
		elif str(next["kind"]) == "begin_step":
			session.begin_next_step()
	assert_true(found, "gestohlener Waldhexenschritt angekündigt")


## Nominierungsband (Feedback 8): normale Nominierung trägt die nominierende Person, die verdeckte Richter-Nominierung keine.
func test_nomination_band_pairs_never_name_the_judge() -> void:
	var session := _session()
	var state: GameState = session.get("_state")
	state.phase = Phase.DAY
	state.day_number = 1
	var normal := Nomination.new()
	normal.nominator_id = 3
	normal.nominee_id = 1
	normal.day = 1
	var judge := Nomination.new()
	judge.nominator_id = 4
	judge.nominee_id = 2
	judge.day = 1
	judge.by_judge = true
	state.nominations.append(normal)
	state.nominations.append(judge)
	var seats: Array = session.cockpit_view()["seats"]
	var by := {}
	for seat: Dictionary in seats:
		by[int(seat["person_id"])] = int(seat["nominated_by"])
	assert_eq(by[1], 3, "normale Nominierung nennt die nominierende Person")
	assert_eq(by[2], 0, "Richter-Nominierung nennt niemanden")
	assert_true(bool((seats.filter(func(s: Dictionary) -> bool: return int(s["person_id"]) == 2)[0] as Dictionary)["nominated_today"]), "die nominierte Person bleibt öffentlich sichtbar")
	assert_eq(GameSeatRing.bands_of(seats), [Vector2i(3, 1)] as Array[Vector2i], "genau ein Band, nur für die normale Nominierung")
