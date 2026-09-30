extends UiTestCase
## Handlungszeilen (OI-18): Das Lexikonfeld „Ablauf am Tisch“ (`act`) beantwortet für jede der 71 Rollen vier Fragen: Wen ruft die
## Spielleitung auf, was wählt oder liest sie ab, was darf sie vorlesen oder zeigen, wie beendet sie den Schritt. Die Zeilen
## stützen sich auf die Texte der Karten (`ui.call.*`, `ui.prompt.*`) und dürfen ihnen nicht widersprechen; ein offener Bedienablauf
## (Rotkäppchen) ist als offen gekennzeichnet.

const LABELS := {
	"de": ["Aufruf: ", "Auswählen oder ablesen: ", "Vorlesen oder zeigen: ", "Beenden: "],
	"en": ["Call: ", "Select or read: ", "Read out or show: ", "Finish: "],
}


func _po(lang: String) -> Dictionary:
	return po_entries(PO_DE if lang == "de" else PO_EN)


func _key(role: StringName) -> String:
	return RolePresentation.lexicon_key(role, "act")


func test_every_role_has_four_labelled_lines_in_both_languages() -> void:
	assert_true(RolePresentation.LEXICON_FIELDS.has("act"), "Feld act ist Pflichtfeld des Lexikons")
	for lang: String in ["de", "en"]:
		var po := _po(lang)
		assert_eq(str(po.get("ui.lexicon.field.act", "")), "Ablauf am Tisch" if lang == "de" else "Procedure at the table", "%s: Feldüberschrift" % lang)
		for role: Variant in RoleCatalog.ROLES:
			var text := str(po.get(_key(StringName(role)), ""))
			assert_true(text != "", "%s: %s hat Handlungszeilen" % [lang, role])
			var lines := text.split("\n")
			assert_eq(lines.size(), 4, "%s: %s hat genau vier Zeilen" % [lang, role])
			for i: int in mini(lines.size(), 4):
				assert_true(lines[i].begins_with(LABELS[lang][i]), "%s: %s Zeile %d beginnt mit „%s“" % [lang, role, i + 1, LABELS[lang][i]])
				assert_true(lines[i].length() > LABELS[lang][i].length() + 8, "%s: %s Zeile %d hat Inhalt" % [lang, role, i + 1])
			assert_false(text.contains("{") or text.contains("—") or text.contains("…."), "%s: %s ohne Platzhalter und Geviertstrich" % [lang, role])
			for term: String in ["Regelkern", "GameState", "JSON", "user://", "Godot", "Schema", "Replay"]:
				assert_false(text.contains(term), "%s: %s enthält Codebegriff „%s“" % [lang, role, term])


## Jede Rolle mit eigenem Vorlesetext nennt ihn wörtlich; jede Anweisung der Karte steht in ihren Zeilen.
func test_lines_agree_with_the_card_texts() -> void:
	for lang: String in ["de", "en"]:
		var po := _po(lang)
		var with_call := 0
		var with_prompts := 0
		for role: Variant in RoleCatalog.ROLES:
			var id := StringName(role)
			var part := String(id).replace("-", "_")
			var text := str(po[_key(id)])
			var call_key := "ui.call.%s" % part
			if po.has(call_key):
				with_call += 1
				assert_true(text.contains(str(po[call_key])), "%s: %s nennt den Vorlesetext der Karte" % [lang, role])
			for key: Variant in po:
				var prefix := "ui.prompt.%s." % part
				if str(key).begins_with(prefix) and not text.contains(str(po[key])):
					# Ausnahmen: Anweisungen, die an eine andere Person als die Spielleitung gerichtet sind oder als Reaktion/Zusatz
					# formuliert werden, stehen sinngemäß in den Zeilen (Waldhexe, Lehrling, Rotkäppchen; Reaktion des Dorfschmieds).
					assert_true(["waldhexe", "lehrling", "rotkaeppchen"].has(String(id)), "%s: %s nennt die Anweisung %s" % [lang, role, key])
				elif str(key).begins_with(prefix):
					with_prompts += 1
		assert_true(with_call >= 40, "%s: Rollen mit Vorlesetext geprüft (%d)" % [lang, with_call])
		assert_true(with_prompts >= 50, "%s: Anweisungen der Karten in den Zeilen gefunden (%d)" % [lang, with_prompts])


## Nur entschiedene Abläufe: Die offene Frage zu Rotkäppchen steht ausdrücklich als offen da, statt einen Ablauf zu erfinden.
func test_undecided_flow_is_marked_open_not_invented() -> void:
	assert_true(str(_po("de")[_key(&"rotkaeppchen")]).contains("noch nicht festgelegt"), "DE: Rotkäppchen nennt den offenen Punkt")
	assert_true(str(_po("en")[_key(&"rotkaeppchen")]).contains("not settled yet"), "EN: Rotkäppchen nennt den offenen Punkt")
	for role: Variant in RoleCatalog.ROLES:
		if String(role) != "rotkaeppchen":
			assert_false(str(_po("de")[_key(StringName(role))]).contains("noch nicht festgelegt"), "%s: kein offener Punkt erfunden" % role)


func test_lexicon_entry_shows_the_field_in_both_languages() -> void:
	for lang: String in ["de", "en"]:
		var shell := await spawn_shell(SIZE_4_3, lang)
		if shell == null:
			return
		await navigate(shell, &"main_menu")
		await navigate(shell, &"lexicon")
		var lexicon := current_screen(shell).find_child("RoleLexicon", true, false) as RoleLexicon
		lexicon.open_role(&"schutzengel")
		await frames(3)
		var caption := find_node(lexicon, "LexiconCaption_act") as Label
		var body := find_node(lexicon, "LexiconField_act") as Label
		assert_true(caption != null and caption.is_visible_in_tree(), "%s: Überschrift sichtbar" % lang)
		assert_true(body != null and body.text.contains(LABELS[lang][0]) and body.text.contains(LABELS[lang][3]), "%s: Ablauf am Tisch im Eintrag" % lang)
		assert_eq(body.text, str(_po(lang)[_key(&"schutzengel")]), "%s: Text wie in der Übersetzung" % lang)
		await after_each()
