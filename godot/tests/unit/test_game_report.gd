extends TestCase
## Abschlussbericht (Paket D): GameReport (Auswertung der Ereignisse einer beendeten Partie) und ReportText (öffentliche Fassung
## und Spielleiterfassung in DE/EN). Der Bericht entsteht erst nach bestätigtem Sieg, ordnet die Ereignisse zeitlich, die
## öffentliche Fassung enthält nur bereits öffentliche Angaben, und kein rohes Wörterbuch gelangt in den Text.

const NAMES: Array = ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"]
const ROLES: Array = ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]
const REVIVAL_ROLES: Array = ["werwolf", "blutwolf", "kutscher", "amalia", "detektiv", "dorfbewohner"]


func _start(roles: Array, round_id: String = "bericht-1") -> GameSession:
	TranslationServer.set_locale("de")  # die Texte prüfen deutsche Wörter; die Systemsprache des Rechners darf nichts ändern
	var players: Array = []
	var map := {}
	for i: int in roles.size():
		players.append({"id": i + 1, "name": NAMES[i]})
		map[str(i + 1)] = roles[i]
	var session := GameSession.new()
	var result := session.submit(Command.start_game({"round_id": round_id, "seed": 1, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(roles.size()), "roles": map}))
	assert_true(result.ok, "Start angenommen")
	return session


## Eine Nacht mit Rudelopfer (Person 3), Nominierung 1 → 4, Hinrichtung von 4: Wolfsparität, noch nicht bestätigt.
func _to_win_decision(session: GameSession) -> Dictionary:
	session.start_night()
	session.answer_targets([3])
	session.end_night()
	session.nominate(1, 4)
	session.decide_execution(4)
	return session.cockpit_view()["next"]


func _finished(roles: Array = ROLES) -> GameSession:
	var session := _start(roles)
	var next := _to_win_decision(session)
	assert_true(session.confirm_win(int(next["candidates"][0]["id"])).ok, "Sieg bestätigt")
	return session


func _all_text(report: Dictionary, version: String) -> String:
	var parts: Array[String] = []
	for line: Dictionary in ReportText.lines(report, version):
		parts.append(str(line["text"]))
	return "\n".join(parts)


func _all_text_locked(report: Dictionary) -> String:
	var parts: Array[String] = []
	for line: Dictionary in ReportText.lines(report, ReportText.PUBLIC, false):
		parts.append(str(line["text"]))
	return "\n".join(parts)


func _entry(report: Dictionary, kind: String) -> Dictionary:
	for entry: Dictionary in report["entries"]:
		if str(entry["kind"]) == kind:
			return entry
	fail("Eintrag %s fehlt" % kind)
	return {}


func _kinds(report: Dictionary, vis: String) -> Array:
	var out: Array = []
	for entry: Dictionary in report["entries"]:
		if str(entry["vis"]) == vis:
			out.append(str(entry["kind"]))
	return out


func test_no_report_before_a_confirmed_win() -> void:
	var session := _start(ROLES)
	assert_eq(session.game_report(), {}, "laufende Partie: kein Bericht")
	var next := _to_win_decision(session)
	assert_eq(str(next["kind"]), "win_decision", "Sieg erkannt, noch nicht bestätigt")
	assert_eq(session.game_report(), {}, "erkannter, unbestätigter Sieg: kein Bericht")
	assert_false(session.is_over(), "Partie nicht beendet")
	assert_true(session.reject_win("Test").ok, "Sieg abgelehnt")
	assert_eq(session.game_report(), {}, "abgelehnter Sieg: kein Bericht")


func test_report_has_winner_counts_and_chronological_public_entries() -> void:
	var session := _finished()
	var report := session.game_report()
	assert_eq(str(report["game_id"]), "bericht-1", "Partie-ID")
	assert_eq(int(report["players"]), 6, "Teilnehmerzahl")
	assert_eq(report["names"], NAMES, "Namen in Sitzreihenfolge")
	assert_eq(int(report["nights"]), 1, "gespielte Nächte")
	assert_eq(int(report["days"]), 1, "gespielte Tage")
	assert_eq(str(report["winner"]["side"]), "wolves", "bestätigte Siegseite")
	assert_eq(_kinds(report, "public"), ["night", "morning", "day", "nomination", "execution", "death", "win"], "öffentliche Ereignisse in zeitlicher Reihenfolge")
	var morning := _entry(report, "morning")
	var deaths: Array = morning["report"]["deaths"]
	assert_eq(deaths.size(), 1, "ein Toter in der Nacht")
	assert_eq(str(deaths[0]["name"]), "Çelik", "Rudelopfer Person 3")
	var nomination := _entry(report, "nomination")
	assert_eq([str(nomination["nominator"]), str(nomination["nominee"])], ["Anna", "Dörte"], "Nominierung 1 → 4")
	assert_eq(str(_entry(report, "execution")["name"]), "Dörte", "Hinrichtung von 4")
	assert_eq(str(report["roles"][2]["role_id"]), "dorfbewohner", "Rolle je Person für die Spielleitung")
	assert_true(bool(report["roles"][2]["alive"]) == false, "Toter als tot markiert")


## NQ-07: Nach bestätigtem Spielende nennt die öffentliche Fassung alle Rollen zum Spielende, die Sieger und die Siegbedingung;
## geheime Ursachen, Korrekturen und Rollenwechselverläufe bleiben in der Spielleiterfassung.
func test_public_version_shows_end_roles_winner_and_condition_but_no_other_secret() -> void:
	var report := _finished().game_report()
	var text := _all_text(report, ReportText.PUBLIC)
	for expected: String in ["Abschlussbericht (öffentliche Fassung)", "bericht-1", "6", "Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd", "Nacht 1", "Tag 1",
			"In dieser Nacht ist gestorben", "Çelik", "Anna nominiert Dörte", "Hinrichtung: Dörte", "Werwölfe"]:
		assert_true(text.contains(expected), "öffentlich vorhanden: %s" % expected)
	assert_true(text.contains("Dörte (Amalia)"), "Rolle beim Tod in einer Runde ohne Wiederbelebung (wie am Tisch angesagt)")
	for expected: String in ["Rollen zum Spielende", "1 · Anna: Werwolf", "2 · Bärbel: Blutwolf", "3 · Çelik: Dorfbewohner †", "4 · Dörte: Amalia †", "5 · Émile: Detektiv",
			"6 · Fjörd: Wahnsinniger Kutscher", "Sieger: Werwölfe", "Siegbedingung: Die Wölfe sind mindestens so viele wie alle anderen Lebenden."]:
		assert_true(text.contains(expected), "nach bestätigtem Spielende öffentlich: %s" % expected)
	for secret: String in ["Rudelangriff", "Spielleiterkorrektur", "ursprünglich", "Nur für die Spielleitung", "Verdeckte Nominierung", "Begünstigte", "technische Einzelereignisse"]:
		assert_false(text.contains(secret), "weiterhin nicht öffentlich: %s" % secret)
	assert_eq(text.count("Amalia"), 2, "Rolle des Hingerichteten in der Chronik und in der Rollenliste")
	var lines := ReportText.lines(report, ReportText.PUBLIC)
	assert_true(str(lines[1]["text"]).contains("alle Rollen zum Spielende"), "Hinweis nennt die Freigabe nach dem Spielende")


## Ohne Freigabe (Siegbestätigung zurückgenommen) fehlen Rollen, Sieger und Siegbedingung in der öffentlichen Fassung wieder.
func test_public_version_without_release_has_no_roles_winner_or_condition() -> void:
	var report := _finished().game_report()
	var text := _all_text_locked(report)
	for hidden: String in ["Rollen zum Spielende", "Wahnsinniger Kutscher", "Blutwolf", "Detektiv", "Siegbedingung:", "Gewinnende", "1 · Anna"]:
		assert_false(text.contains(hidden), "ohne Freigabe nicht öffentlich: %s" % hidden)
	assert_true(text.contains("Anna nominiert Dörte") and text.contains("Hinrichtung: Dörte"), "öffentliche Chronik bleibt")
	assert_true(text.contains("Die Siegbestätigung wurde zurückgenommen"), "Hinweis auf die fehlende Freigabe")
	assert_true(_all_text(report, ReportText.PUBLIC).length() > text.length(), "Freigabe erweitert die Fassung")


## In einer Wiederbelebungsrunde bleiben die Rollen der Toten in der Chronik verdeckt; erst die Rollenliste nach dem bestätigten
## Spielende nennt alle Rollen (NQ-07).
func test_revival_round_keeps_death_roles_out_of_the_chronicle_but_lists_end_roles() -> void:
	var report := _finished(REVIVAL_ROLES).game_report()
	assert_true(bool(report["revival_round"]), "Wiederbelebungsrunde")
	var text := _all_text(report, ReportText.PUBLIC)
	assert_true(text.contains("Gestorben: Dörte.") and text.contains("Çelik"), "Tote ohne Rolle genannt")
	assert_false(text.contains("Dörte (") or text.contains("Çelik ("), "Chronik nennt keine Rolle der Toten")
	assert_true(text.contains("4 · Dörte: Amalia †") and text.contains("3 · Çelik: Kutscher †"), "Rollenliste nach dem Spielende nennt alle Rollen")
	assert_false(_all_text_locked(report).contains("Amalia"), "ohne Freigabe bleibt die Rolle verdeckt")
	var gm := _all_text(report, ReportText.GM)
	assert_true(gm.contains("Kutscher") and gm.contains("Amalia"), "Spielleiterfassung nennt die Rollen")


func test_game_master_version_adds_roles_causes_and_reason() -> void:
	var report := _finished().game_report()
	var text := _all_text(report, ReportText.GM)
	for expected: String in ["Abschlussbericht (Spielleiterfassung)", "Nur für die Spielleitung", "Rollen", "3 · Çelik: Dorfbewohner", "4 · Dörte: Amalia", "Rudelangriff",
			"Hinrichtung", "Siegbedingung: Die Wölfe sind mindestens so viele wie alle anderen Lebenden.", "Sieger: Werwölfe", "Wahnsinniger Kutscher", "Blutwolf"]:
		assert_true(text.contains(expected), "Spielleiterfassung enthält: %s" % expected)
	# Die Spielleiterfassung enthält alles Öffentliche (außer dem Hinweis der Fassung) und zusätzlich Ursachen, Ursprungsrollen und Korrekturen.
	for line: Dictionary in ReportText.lines(report, ReportText.PUBLIC):
		if str(line["style"]) != "note" and str(line["style"]) != "title" and not str(line["text"]).begins_with("Gestorben: Dörte ("):
			assert_true(text.contains(str(line["text"])), "Spielleiterfassung enthält die öffentliche Zeile: %s" % line["text"])
	assert_true(ReportText.lines(report, ReportText.GM).size() > ReportText.lines(report, ReportText.PUBLIC).size(), "Spielleiterfassung ist umfangreicher")


func test_texts_contain_no_raw_data_and_no_keys() -> void:
	var report := _finished().game_report()
	for lang: String in ["de", "en"]:
		TranslationServer.set_locale(lang)
		for version: String in [ReportText.PUBLIC, ReportText.GM]:
			var lines := ReportText.lines(report, version)
			assert_true(lines.size() >= 8, "%s %s: Zeilen vorhanden" % [lang, version])
			for line: Dictionary in lines:
				var text := str(line["text"])
				assert_true(text.strip_edges() != "", "%s %s: keine leere Zeile" % [lang, version])
				for bad: String in ["{", "}", "[", "]", "Dictionary", "ui.", "&\"", "null"]:
					assert_false(text.contains(bad), "%s %s: „%s“ in „%s“" % [lang, version, bad, text])
	TranslationServer.set_locale("en")
	var en_text := _all_text(report, ReportText.GM)
	assert_true(en_text.contains("Final report (game master version)") and en_text.contains("Winner: Werewolves") and en_text.contains("Night 1"), "EN: übersetzt")
	TranslationServer.set_locale("de")


func test_stored_report_renders_the_same_after_json_round_trip() -> void:
	var report := _finished().game_report()
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(report))
	for version: String in [ReportText.PUBLIC, ReportText.GM]:
		assert_eq(ReportText.plain_text(reloaded, version), ReportText.plain_text(report, version), "%s: nach Speichern und Laden gleich" % version)
	assert_true(ReportText.plain_text(report, ReportText.PUBLIC).ends_with("\n"), "Text endet mit Zeilenumbruch")


func test_undone_confirmation_removes_the_report_and_a_second_completion_matches() -> void:
	var session := _start(ROLES)
	var next := _to_win_decision(session)
	session.confirm_win(int(next["candidates"][0]["id"]))
	var first := session.game_report()
	assert_true(session.undo(), "Siegbestätigung zurückgenommen")
	assert_eq(session.game_report(), {}, "nach Rückgängig kein Bericht: keine Behauptung „abgeschlossen“")
	assert_true(session.redo(), "Wiederholen")
	assert_eq(JSON.stringify(session.game_report()), JSON.stringify(first), "gleicher Bericht nach Wiederholen (deterministisch)")


## Rollenwechsel vor dem Spielende: Die öffentliche Liste nennt die Rolle zum Spielende; die ursprüngliche Rolle und ein Wechselverlauf
## stehen nur in der Spielleiterfassung.
func test_role_change_before_the_end_shows_the_end_role_publicly() -> void:
	var session := _start(ROLES)
	session.start_night()
	session.answer_targets([3])
	session.end_night()
	assert_true(session.submit(CorrectionFixtures.gm("set_role", {"target_id": 6, "role_id": "dorfbewohner"}, "Karte vertauscht")).ok, "Rolle von Person 6 gesetzt")
	session.nominate(1, 4)
	session.decide_execution(4)
	var next: Dictionary = session.cockpit_view()["next"]
	assert_true(session.confirm_win(int(next["candidates"][0]["id"])).ok, "Sieg bestätigt")
	var report := session.game_report()
	assert_eq(str(report["roles"][5]["role_id"]), "dorfbewohner", "Rolle zum Spielende")
	assert_eq(str(report["roles"][5]["original_role_id"]), "wahnsinniger-kutscher", "ursprüngliche Rolle nur im Bericht der Spielleitung")
	var text := _all_text(report, ReportText.PUBLIC)
	assert_true(text.contains("6 · Fjörd: Dorfbewohner"), "öffentlich: Rolle zum Spielende")
	for secret: String in ["Wahnsinniger Kutscher", "ursprünglich", "Karte vertauscht", "Spielleiterkorrektur"]:
		assert_false(text.contains(secret), "öffentlich ohne %s" % secret)
	var gm := _all_text(report, ReportText.GM)
	assert_true(gm.contains("6 · Fjörd: Dorfbewohner (ursprünglich Wahnsinniger Kutscher)") and gm.contains("Karte vertauscht"), "Spielleiterfassung mit ursprünglicher Rolle und Korrektur")


func _kill(id: int) -> Command:
	return CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": true})


## Zwei offene Siegkandidaten (Wolfsparität und Manipulator): Die bestätigte Siegbedingung und die Gewinner stammen aus dem
## gewählten Kandidaten, nicht aus dem anderen.
func test_chosen_candidate_decides_condition_and_winners() -> void:
	var roles: Array = ["werwolf", "blutwolf", "manipulator", "sensentraeger", "dorfbewohner", "amalia"]
	var texts := {}
	for pick: int in [0, 1]:
		var session := _start(roles, "wahl-%d" % pick)
		for c: Command in [Command.start_night(), Command.answer_prompt(1, []), Command.end_night(), _kill(6), _kill(4), Command.begin_step("reaction:1"), Command.answer_prompt(2, [5])]:
			assert_true(session.submit(c).ok, "Vorbereitung angenommen")
		var candidates: Array = session.cockpit_view()["next"]["candidates"]
		assert_eq(candidates.size(), 2, "zwei offene Kandidaten")
		assert_true(session.confirm_win(int(candidates[pick]["id"])).ok, "Kandidat %d bestätigt" % pick)
		var report := session.game_report()
		texts[pick] = _all_text(report, ReportText.PUBLIC)
		assert_eq(report["winner"]["reason_key"], "wolf_parity" if pick == 0 else "manipulator_three_alive", "bestätigte Siegbedingung %d" % pick)
	assert_true(texts[0].contains("Sieger: Werwölfe") and texts[0].contains("Die Wölfe sind mindestens so viele"), "Wolfsparität gewählt")
	assert_false(texts[0].contains("Gewinnende Personen"), "keine Einzelperson bei der Wolfsparität")
	assert_true(texts[1].contains("Gewinnende Personen: Çelik"), "Manipulator gewählt: die begünstigte Person")
	assert_false(texts[1].contains("Die Wölfe sind mindestens so viele"), "die nicht gewählte Bedingung steht nicht im Bericht")


## Speichern und Laden ändern die öffentliche Fassung nicht; Rückgängig sperrt die Freigabe, die erneute Bestätigung gibt denselben
## Umfang wieder frei.
func test_release_survives_save_load_and_follows_undo_and_reconfirmation() -> void:
	var session := _finished()
	var released := _all_text(session.game_report(), ReportText.PUBLIC)
	var loaded := GameSession.new()
	assert_eq(loaded.load_text(session.save_text()), &"", "Spielstand geladen")
	assert_eq(_all_text(loaded.game_report(), ReportText.PUBLIC), released, "nach Speichern und Laden gleicher öffentlicher Umfang")
	assert_true(loaded.undo(), "Siegbestätigung zurückgenommen")
	assert_eq(loaded.game_report(), {}, "ohne bestätigtes Spielende kein Bericht und damit keine Rollenliste")
	var next: Dictionary = loaded.cockpit_view()["next"]
	assert_eq(str(next["kind"]), "win_decision", "Siegkandidat wieder offen, noch nicht bestätigt")
	assert_true(loaded.confirm_win(int(next["candidates"][0]["id"])).ok, "erneut bestätigt")
	assert_eq(_all_text(loaded.game_report(), ReportText.PUBLIC), released, "gleicher Umfang nach erneuter Bestätigung")
