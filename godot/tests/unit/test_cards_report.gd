extends TestCase
## Abschlussbericht mit Totenreichkarten: öffentliche Kartenansagen stehen im Verlauf des Tages, stille Mitsieger (Schwarze
## Prophezeiung) erscheinen als Gewinnende, geheime Kartenangaben nie in der öffentlichen Fassung; DE und EN.

const COUNT := 12
const WOLVES: Array[int] = [1, 2, 3]


func _finished() -> CardGame:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"12": "rattenfaenger"})
	g.gm_kill(11, false)
	g.give(11, &"schicksal_02")  # Offene Bücher: öffentliche Ansage
	g.arm(12, &"solo_02", -1, false)
	g.play_with()  # die zuerst gefragte Person: ohne Eingabe
	g.play_with([1])  # Schwarze Prophezeiung: Option 1 = Wölfe
	g.skip_cards()
	for id: int in [4, 5, 6, 7, 8, 9, 10]:
		if g.state.open_candidates().is_empty():
			g.gm_kill(id, false)
	assert_false(g.state.open_candidates().is_empty(), "Siegkandidat (Wölfe)")
	g.do(Command.confirm_win(g.state.open_candidates()[0].id), "Sieg bestätigen")
	return g


func test_the_silent_cowinner_appears_among_the_winners_and_public_card_lines_in_the_history() -> void:
	for lang: String in ["de", "en"]:
		TranslationServer.set_locale(lang)
		var g := _finished()
		var report := GameReport.build(g.state, g.events)
		assert_false(report.is_empty(), "%s: Bericht vorhanden" % lang)
		var owner_name := g.state.players[12].name
		assert_eq((report["winner"] as Dictionary)["card_co_names"], [owner_name], "%s: stille Mitsiegerin im Bericht" % lang)
		var public_text := ReportText.plain_text(report, ReportText.PUBLIC, true)
		assert_true(public_text.contains(owner_name), "%s: öffentliche Fassung nennt die Mitsiegerin nach bestätigtem Sieg" % lang)
		var card_name := str(TranslationServer.translate(CardCatalog.name_key(&"schicksal_02")))
		assert_true(public_text.contains(card_name), "%s: öffentliche Kartenansage im Verlauf (%s)" % [lang, card_name])
		var locked := ReportText.plain_text(report, ReportText.PUBLIC, false)
		assert_false(locked.contains(str(TranslationServer.translate(CardCatalog.name_key(&"solo_02")))), "%s: gesperrte Fassung nennt die geheime Karte nicht" % lang)
		assert_false(public_text.contains("solo_02") or public_text.contains("card_cowinners"), "%s: keine Rohdaten" % lang)
	TranslationServer.set_locale("de")


func test_the_report_survives_a_json_round_trip_with_card_data() -> void:
	TranslationServer.set_locale("de")
	var g := _finished()
	var report := GameReport.build(g.state, g.events)
	var parsed: Variant = JSON.parse_string(JSON.stringify(report))
	assert_true(parsed is Dictionary, "JSON lesbar")
	assert_eq(ReportText.plain_text(parsed as Dictionary, ReportText.GM, true), ReportText.plain_text(report, ReportText.GM, true), "gleicher Text nach dem Speichern")
