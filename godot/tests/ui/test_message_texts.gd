extends UiTestCase
## Meldungstexte zeigen nie einen Code: in allen Texten (DE und EN) kein Wort „Code“, keine snake_case-Zeichenfolge und keine
## Klammer mit einem technischen Namen. Platzhalter in {} sind ausgenommen (sie werden vor der Prüfung entfernt); die Werte, die
## sie in zusammengesetzten Meldungen erhalten, werden unten einzeln geprüft. Keine Whitelist nötig: kein legitimes Wort passt.

const DROP_REASONS: Array = ["frozen", "no_decision", "blocked", "cursed", "actor_dead", "marked_for_death", "actor_role_changed",
	"no_living_wolf", "not_called", "card_blocked", "card_sleep", "etwas_unbekanntes"]


func _problems(text: String) -> Array:
	var plain := RegEx.create_from_string("\\{[^}]*\\}").sub(text, "", true)
	var found: Array = []
	if RegEx.create_from_string("\\b[Cc]odes?\\b").search(plain) != null:
		found.append("Wort Code")
	if RegEx.create_from_string("\\b[a-z0-9]+(?:_[a-z0-9]+)+\\b").search(plain) != null:
		found.append("snake_case")
	if RegEx.create_from_string("\\([a-z0-9]*[_.][a-z0-9_.]*\\)").search(plain) != null:
		found.append("Klammercode")
	return found


func test_no_message_shows_a_code() -> void:
	for path: String in [PO_DE, PO_EN]:
		var entries := po_entries(path)
		assert_true(entries.size() > 100, "%s geladen" % path)
		for key: Variant in entries:
			var problems := _problems(str(entries[key]))
			assert_true(problems.is_empty(), "%s: %s zeigt einen Code (%s)" % [path.get_file(), key, ", ".join(problems)])


## Zusammengesetzte Meldungen: jeder Grund, der in {drop} oder {reason} landen kann, ergibt einen klaren Satzteil.
func test_composed_reasons_are_plain_words() -> void:
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for reason: String in DROP_REASONS:
			var text := str(TranslationServer.translate(CockpitText.drop_key(reason)))
			assert_true(_problems(text).is_empty() and not text.begins_with("ui."), "%s: Grund %s lesbar (%s)" % [locale, reason, text])
		for reason: String in ["game_already_started", "game_over", "setup_incomplete", "other"]:
			var key := "ui.setup.seating.status.start_failed.%s" % reason
			var text := str(TranslationServer.translate(key))
			assert_ne(text, key, "%s: %s übersetzt" % [locale, key])
			assert_false(text.contains("{"), "%s: %s ohne Platzhalter" % [locale, key])
	TranslationServer.set_locale("de")
