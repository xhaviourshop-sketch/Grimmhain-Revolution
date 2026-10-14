extends TestCase
## Morgenmeldung und Spielleiter-Hinweise: gleiche Wirkungen auf mehrere Personen stehen in einer Zeile (Nachtauftrag 14.10.2026).


func test_same_effect_is_one_line_with_all_names() -> void:
	var lines := [
		{"key": "ui.morning.private.charmed", "values": {"name": "Anna"}},
		{"key": "ui.morning.private.lovers", "values": {"name": "Cora", "target": "Dirk"}},
		{"key": "ui.morning.private.charmed", "values": {"name": "Ben"}},
		{"key": "ui.morning.private.protected", "values": {"name": "Eva"}},
	]
	var merged := LineGroups.merge(lines)
	assert_eq(merged.size(), 3, "zwei Verzauberte werden eine Zeile")
	assert_eq(str(merged[0]["key"]), "ui.morning.private.charmed.many", "Mehrzahl an der Stelle des ersten Treffers")
	assert_eq(str(merged[0]["values"]["names"]), "Anna, Ben", "alle Namen")
	assert_eq(str(merged[1]["key"]), "ui.morning.private.lovers", "Zeilen mit mehreren Werten bleiben")
	assert_eq(str(merged[2]["key"]), "ui.morning.private.protected", "eine Person bleibt in der Einzahl")
	assert_eq(str(merged[2]["values"]["name"]), "Eva", "Einzahl mit Namen")


func test_plural_texts_exist_in_both_languages() -> void:
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in ["ui.morning.private.charmed.many", "ui.morning.private.protected.many", "ui.warn.protected.many", "ui.warn.cursed.many"]:
			var text := String(TranslationServer.translate(key)).format({"names": "Anna, Ben"})
			assert_ne(text, key, "%s (%s) übersetzt" % [key, locale])
			assert_true(text.contains("Anna, Ben"), "%s nennt die Namen" % key)
	TranslationServer.set_locale("de")


func test_private_lines_group_through_the_morning_text_path() -> void:
	var raw := [
		{"key": "ui.morning.private.charmed", "person": {"name": "Anna", "person_id": 1, "seat": 1}},
		{"key": "ui.morning.private.charmed", "person": {"name": "Ben", "person_id": 2, "seat": 2}},
	]
	var out := CockpitText.private_lines(raw)
	assert_eq(out.size(), 1, "eine Zeile")
	assert_eq(str(out[0]["key"]), "ui.morning.private.charmed.many", "Mehrzahl")
