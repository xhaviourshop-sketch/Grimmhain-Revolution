extends UiTestCase
## Handlungszeilen (OI-18): Das Lexikonfeld „Ablauf am Tisch“ (`act`) beantwortet für jede der 71 Rollen vier Fragen: Wen ruft die
## Spielleitung auf, was wählt oder liest sie ab, was darf sie vorlesen oder zeigen, wie beendet sie den Schritt. Die Zeilen
## stützen sich auf die Texte der Karten (`ui.call.*`, `ui.prompt.*`) und dürfen ihnen nicht widersprechen; alle Abläufe sind
## entschieden (Rotkäppchen: NQ-06).

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


## Jede Rolle mit eigenem Vorlesetext nennt ihn wörtlich. (Die Prompt-Anweisungen `ui.prompt.*` sind mit der Schablone entfallen: Die Karte hat nur noch Satz und Hilfe `ui.night.*`.)
func test_lines_agree_with_the_card_texts() -> void:
	for lang: String in ["de", "en"]:
		var po := _po(lang)
		var with_call := 0
		for role: Variant in RoleCatalog.ROLES:
			var id := StringName(role)
			var part := String(id).replace("-", "_")
			var text := str(po[_key(id)])
			var call_key := "ui.call.%s" % part
			if po.has(call_key):
				with_call += 1
				assert_true(text.contains(str(po[call_key])), "%s: %s nennt den Vorlesetext der Karte" % [lang, role])
		assert_true(with_call >= 40, "%s: Rollen mit Vorlesetext geprüft (%d)" % [lang, with_call])


## NQ-06: Rotkäppchens Ablauf am Tisch ist entschieden und vollständig. Reihenfolge der Handlungen, keine hörbare Namensansage,
## Erklärung zu Apfel, Kette und Ablehnung bleibt; kein offener Hinweis mehr, weder bei ihr noch bei einer anderen Rolle.
func test_red_riding_hood_flow_is_complete_in_order() -> void:
	for lang: String in ["de", "en"]:
		var po := _po(lang)
		var text := str(po[_key(&"rotkaeppchen")])
		var steps: Array = [
			["Zeige auf die Person", "Point to the person"],  # Rotkäppchen wählt
			["Augen wieder schließen", "close their eyes again"],  # Spielleitung lässt Rotkäppchen die Augen schließen
			["unauffällig an", "quietly tap"],  # gewählte Person unauffällig antippen
			["auf dem Tablet", "on the tablet"],  # anonyme Frage zeigen
			["Zuflucht gewährt", "Refuge granted"],  # Antwort über den bestehenden Bedienweg
			["schließt danach wieder die Augen", "then closes their eyes again"],  # Person schließt die Augen
		]
		var at := -1
		for step: Array in steps:
			var found := text.find(str(step[0] if lang == "de" else step[1]))
			assert_true(found > at, "%s: Schritt „%s“ vorhanden und nach dem vorigen" % [lang, step[0 if lang == "de" else 1]])
			at = found
		assert_true(text.contains("Apfel und Kette" if lang == "de" else "apple and chain"), "%s: Erklärung zu Apfel und Kette bleibt" % lang)
		assert_true(text.contains("ablehnen" if lang == "de" else "decline"), "%s: Ablehnung bleibt erklärt" % lang)
		assert_true(text.contains("nicht laut" if lang == "de" else "not read it aloud"), "%s: keine hörbare Ansage der Frage" % lang)
		assert_true(text.contains("ohne ihren Namen" if lang == "de" else "without saying a name"), "%s: keine Namensnennung" % lang)
		assert_false(po.has("ui.role.rotkaeppchen.lex.open"), "%s: kein offener Hinweis zu Rotkäppchen" % lang)
		# Vertrauliche Anleitung bleibt von der Karte der gefragten Person und von öffentlichen Texten getrennt.
		for key: String in ["ui.night.rotkaeppchen.grant.title", "ui.night.rotkaeppchen.grant.help", "ui.cockpit.card.red_grant.heading", "ui.cockpit.action.yes.rotkaeppchen.grant",
				"ui.cockpit.action.no.rotkaeppchen.grant"]:
			var card := str(po[key])
			for secret: String in ["Augen", "eyes", "antippen", "tap the chosen", "Rotkäppchen", "Little Red"]:
				assert_false(card.contains(secret), "%s: %s enthält keine Anleitung oder Rolle (%s)" % [lang, key, secret])
	for role: Variant in RoleCatalog.ROLES:
		for lang: String in ["de", "en"]:
			var open_key := RolePresentation.lexicon_key(StringName(role), RolePresentation.LEXICON_OPEN)
			if String(role) == "rotkaeppchen":
				assert_false(_po(lang).has(open_key), "%s: Rotkäppchen ohne Offen-Feld" % lang)
			assert_false(str(_po(lang)[_key(StringName(role))]).contains("noch nicht festgelegt" if lang == "de" else "not settled yet"), "%s/%s: kein offener Punkt in den Zeilen" % [lang, role])


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
