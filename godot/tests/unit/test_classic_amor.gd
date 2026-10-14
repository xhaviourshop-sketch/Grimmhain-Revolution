extends TestCase
## Classic-Amor: bestimmt zwei Personen und fragt nach der Art, Liebe oder Hass (Nachtauftrag 14.10.2026, Schalter `amor_hate_option`, Standard an). Keine Loki-Texte.

const C14 := ["classic-amor", "classic-werwolf", "classic-werwolf", "classic-seherin", "classic-hexe", "classic-engel",
	"classic-drei-brueder", "classic-drei-brueder", "classic-drei-brueder", "classic-zwei-schwestern", "classic-zwei-schwestern",
	"classic-jaeger", "classic-alte", "classic-maedchen"]
const BANNED := ["Loki", "Rival", "rival"]


func _night_one() -> GameState:
	var s := Fixtures.play([Fixtures.start_roles(C14), Command.start_night()])
	assert_true(s != null, "Classic-Besetzung startet")
	return s


func _apply(s: GameState, c: Command) -> CommandResult:
	return RulesEngine.apply(s, c)


func _bind(kind_is_love: bool) -> GameState:
	var s := _night_one()
	var prompt := s.pending_prompt
	assert_eq(prompt.owner, PendingPrompt.OWNER_LOKI, "Amor ist der erste Schritt")
	var r := _apply(s, Command.answer_stage_targets(prompt.id, String(prompt.stage), [1, 4]) if String(prompt.stage) != "" else Command.answer_prompt(prompt.id, [1, 4]))
	assert_true(r.ok, "Ziele angenommen")
	s = r.state
	assert_true(s.pending_prompt != null and String(s.pending_prompt.stage) == "mode", "Frage nach der Art: Liebe oder Hass")
	assert_true(RoleCatalog.param(RoleCatalog.CLASSIC_AMOR, "amor_hate_option", false), "Schalter in den Classic-Daten, Standard an")
	r = _apply(s, Command.answer_choice(s.pending_prompt.id, "mode", kind_is_love))
	assert_true(r.ok, "Art angenommen")
	return r.state


func test_classic_amor_asks_love_or_hate_and_binds_both_ways() -> void:
	var love := _bind(true)
	assert_eq(love.loki_pairs.size(), 1, "ein Paar")
	assert_eq(str(love.loki_pairs[0]["kind"]), "love", "Liebe")
	assert_eq(str(CockpitView.notice_card(love)["text_key"]), "ui.notice.loki_bond.classic.love", "Hinweiskarte der Verliebten")
	var hate := _bind(false)
	assert_eq(str(hate.loki_pairs[0]["kind"]), "rival", "Hass bindet Feinde (Mechanik der Rivalen)")
	var notice := CockpitView.notice_card(hate)
	assert_eq(str(notice["text_key"]), "ui.notice.loki_bond.classic.rival", "Hinweiskarte der Feinde")
	assert_eq(CockpitText.help_role(notice), "classic-amor", "Hilfe von Amor statt Loki")


func test_classic_amor_texts_have_no_loki_wording_and_name_the_choice() -> void:
	var keys: Array[String] = ["ui.call.classic_amor", "ui.notice.loki_bond.classic.love", "ui.notice.loki_bond.classic.rival", "ui.night.classic_amor.targets.title",
		"ui.night.classic_amor.targets.help", "ui.night.classic_amor.targets.short", "ui.night.classic_amor.mode.title", "ui.night.classic_amor.mode.help",
		"ui.night.classic_amor.mode.short", "ui.cockpit.action.yes.classic_amor.mode", "ui.cockpit.action.no.classic_amor.mode", "ui.rulebook.classic.c05.b07", "ui.cause.lover_heartbreak"]
	for field: String in ["name", "short", "lex.night", "lex.wolf", "lex.ability", "lex.timing", "lex.targets", "lex.exceptions", "lex.win", "lex.example", "lex.act", "lex.gm"]:
		keys.append("ui.role.classic_amor.%s" % field)
	var step := {"owner": "loki", "stage": "targets", "answer": "targets", "role_id": "classic-amor"}
	assert_eq(CockpitText.night_short_key({"owner": "loki", "stage": "mode", "answer": "choice", "role_id": "classic-amor"}), "ui.night.classic_amor.mode.short", "Kurzaktion der Frage")
	assert_eq(CockpitText.night_short_key(step), "ui.night.classic_amor.targets.short", "Kurzaktion von Amor")
	assert_true(CockpitText.asks_bond_mode(step), "die Karte fragt zuerst nach der Art")
	assert_eq(CockpitText.action_key("yes", "loki", "mode", "classic-amor"), "ui.cockpit.action.yes.classic_amor.mode", "Knopf „Liebe“")
	assert_eq(CockpitText.action_key("yes", "loki", "mode", "loki"), "ui.cockpit.action.yes.loki.mode", "Loki behält „Liebende“")
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in keys:
			var text := String(TranslationServer.translate(key))
			assert_ne(text, key, "%s (%s) übersetzt" % [key, locale])
			for word: String in BANNED:
				assert_false(text.contains(word), "%s (%s) nennt %s" % [key, locale, word])
		var mentions := String(TranslationServer.translate("ui.role.classic_amor.lex.gm")) + String(TranslationServer.translate("ui.night.classic_amor.mode.short"))
		assert_true(mentions.contains("Hass") or mentions.contains("hate") or mentions.contains("Hate"), "die Texte nennen die Wahl (%s)" % locale)
	TranslationServer.set_locale("de")


func _bond_report(kind_is_love: bool) -> Array:
	var s := _night_one()
	var r := _apply(s, Command.answer_stage_targets(s.pending_prompt.id, String(s.pending_prompt.stage), [1, 4]))
	r = _apply(r.state, Command.answer_choice(r.state.pending_prompt.id, "mode", kind_is_love))
	return MorningReport.private_of(r.state, r.events)


func test_classic_amor_texts_follow_the_choice() -> void:
	var step := {"owner": "loki", "stage": "targets", "answer": "targets", "role_id": "classic-amor"}
	var hate_step := step.duplicate()
	hate_step["bond_hate"] = true
	assert_eq(CockpitText.night_short_key(step), "ui.night.classic_amor.targets.short", "Liebe: verliebt zwei")
	assert_eq(CockpitText.night_short_key(hate_step), "ui.night.classic_amor.targets_hate.short", "Hass: verfeindet zwei")
	var loki_step := {"owner": "loki", "stage": "targets", "answer": "targets", "role_id": "loki", "bond_hate": true}
	assert_eq(CockpitText.night_short_key(loki_step), "ui.night.loki.targets.short", "Loki bleibt bei seinem Text")
	assert_eq(_bond_report(true)[0]["key"], "ui.morning.private.classic_lovers", "Morgenmeldung Liebe")
	assert_eq(_bond_report(false)[0]["key"], "ui.morning.private.classic_rivals", "Morgenmeldung Hass")
	var expected := {"de": ["verfeindet zwei", "sind Feinde"], "en": ["makes two enemies", "are enemies"]}
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		var hate_texts := String(TranslationServer.translate("ui.night.classic_amor.targets_hate.short")) + "|" + String(TranslationServer.translate("ui.morning.private.classic_rivals")) \
			+ "|" + String(TranslationServer.translate("ui.night.classic_amor.targets_hate.title")) + "|" + String(TranslationServer.translate("ui.night.classic_amor.targets_hate.help"))
		for word: String in expected[locale]:
			assert_true(hate_texts.contains(word), "%s nennt %s" % [locale, word])
		for banned: String in ["verlieb", "Verlieb", "Liebe", "Liebende", "in love", "lover", "enamor", "Loki", "Rival", "rival"]:
			assert_false(hate_texts.contains(banned), "Hass-Text (%s) nennt nicht %s" % [locale, banned])
	TranslationServer.set_locale("de")
