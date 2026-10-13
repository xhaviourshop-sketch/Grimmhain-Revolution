extends TestCase
## Classic-Amor (Bogen): bestimmt nur zwei Liebende. Kein Loki-Verhalten (Rivalen, Wahl der Bindungsart, Loki-Texte).

const C14 := ["classic-amor", "classic-werwolf", "classic-werwolf", "classic-seherin", "classic-hexe", "classic-engel",
	"classic-drei-brueder", "classic-drei-brueder", "classic-drei-brueder", "classic-zwei-schwestern", "classic-zwei-schwestern",
	"classic-jaeger", "classic-alte", "classic-maedchen"]
const BANNED := ["Loki", "Rival", "rival", "Hass", "hate", "Hate", "Feind", "enemies"]


func _night_one() -> GameState:
	var s := Fixtures.play([Fixtures.start_roles(C14), Command.start_night()])
	assert_true(s != null, "Classic-Besetzung startet")
	return s


func _apply(s: GameState, c: Command) -> CommandResult:
	return RulesEngine.apply(s, c)


func test_classic_amor_creates_only_lovers_and_no_hate_path() -> void:
	var s := _night_one()
	var prompt := s.pending_prompt
	assert_eq(prompt.owner, PendingPrompt.OWNER_LOKI, "Amor ist der erste Schritt")
	var r := _apply(s, Command.answer_stage_targets(prompt.id, String(prompt.stage), [1, 4]) if String(prompt.stage) != "" else Command.answer_prompt(prompt.id, [1, 4]))
	assert_true(r.ok, "Ziele angenommen")
	s = r.state
	assert_eq(s.loki_pairs.size(), 1, "ein Paar")
	assert_eq(str(s.loki_pairs[0]["kind"]), "love", "Liebende")
	assert_true(s.pending_prompt == null, "keine Frage nach der Bindungsart")
	# Kein Weg zu Rivalen: Die Antwort „Rivalen“ auf eine Bindungsfrage wird abgelehnt, weil es keine offene Frage gibt.
	var late := _apply(s, Command.answer_choice(prompt.id, "mode", false))
	assert_false(late.ok, "Rivalen-Antwort nicht möglich")
	for pair: Dictionary in s.loki_pairs:
		assert_eq(str(pair["kind"]), "love", "nur Liebende im Zustand")
	var notice := CockpitView.notice_card(s)
	assert_eq(str(notice["text_key"]), "ui.notice.loki_bond.classic.love", "Hinweiskarte ohne Loki")
	assert_eq(CockpitText.help_role(notice), "classic-amor", "Hilfe von Amor statt Loki")


func test_classic_amor_texts_have_no_loki_or_hate_wording() -> void:
	var keys: Array[String] = ["ui.call.classic_amor", "ui.notice.loki_bond.classic.love", "ui.night.classic_amor.targets.title",
		"ui.night.classic_amor.targets.help", "ui.night.classic_amor.targets.short", "ui.rulebook.classic.c05.b07", "ui.cause.lover_heartbreak"]
	for field: String in ["name", "short", "lex.night", "lex.wolf", "lex.ability", "lex.timing", "lex.targets", "lex.exceptions", "lex.win", "lex.example", "lex.act", "lex.gm"]:
		keys.append("ui.role.classic_amor.%s" % field)
	var step := {"owner": "loki", "stage": "targets", "answer": "targets", "role_id": "classic-amor"}
	assert_eq(CockpitText.night_short_key(step), "ui.night.classic_amor.targets.short", "Kurzaktion von Amor")
	assert_false(CockpitText.asks_bond_mode(step), "keine Frage nach der Art")
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in keys:
			var text := String(TranslationServer.translate(key))
			assert_ne(text, key, "%s (%s) übersetzt" % [key, locale])
			for word: String in BANNED:
				assert_false(text.contains(word), "%s (%s) nennt %s" % [key, locale, word])
	TranslationServer.set_locale("de")
