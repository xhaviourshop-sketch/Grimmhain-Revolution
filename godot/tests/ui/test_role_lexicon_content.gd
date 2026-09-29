extends UiTestCase
## Rollenlexikon (Paket 5b), Inhalt: Genau die Katalogrollen haben vollständige allgemeine Einträge in DE und EN
## (ui.role.<rolle>.lex.<feld>), es gibt keine Einträge für unbekannte Rollen oder Felder, und das gerenderte Lexikon
## zeigt für jede Rolle in beiden Sprachen echte Texte statt Schlüsseln. Geprüft wird parametrisiert über den
## Rollenkatalog, nicht durch einen Bedientest je Rolle.

const LEX_KEY := "^ui\\.role\\.([a-z_]+)\\.lex\\.([a-z]+)$"
## Verweise auf Planungsdokumente gehören nicht in Texte für die Spielleitung.
const INTERNAL_REFS := "Decision Log|decision log|\\b(DI|DA|OI|PE)-\\d|RM-DR|Regelkern|rules core|`"


func _role_parts() -> Dictionary:
	var out := {}
	for id: Variant in RoleCatalog.ROLES:
		out[String(id).replace("-", "_")] = StringName(id)
	return out


func test_every_catalog_role_has_all_fields_in_both_languages() -> void:
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	assert_eq(RoleCatalog.ROLES.size(), 71, "71 implementierte Rollen im Katalog")
	for id: Variant in RoleCatalog.ROLES:
		for field: String in RolePresentation.LEXICON_FIELDS:
			var key := RolePresentation.lexicon_key(StringName(id), field)
			for pair: Array in [["de", de], ["en", en]]:
				var text := str((pair[1] as Dictionary).get(key, ""))
				assert_true(text.strip_edges() != "", "%s fehlt oder ist leer (%s)" % [key, pair[0]])
		var open := RolePresentation.lexicon_key(StringName(id), RolePresentation.LEXICON_OPEN)
		assert_eq(de.has(open), en.has(open), "%s in beiden Sprachen gleich vorhanden" % open)


func test_no_entries_for_unknown_roles_fields_or_the_card_eater() -> void:
	var parts := _role_parts()
	var allowed: Array[String] = RolePresentation.LEXICON_FIELDS.duplicate()
	allowed.append(RolePresentation.LEXICON_OPEN)
	var re := RegEx.create_from_string(LEX_KEY)
	for path: String in [PO_DE, PO_EN]:
		var roles := {}
		var count := 0
		for key: String in po_entries(path):
			var m := re.search(key)
			if m == null:
				continue
			count += 1
			assert_true(parts.has(m.get_string(1)), "%s: unbekannte Rolle in %s" % [path, key])
			assert_true(allowed.has(m.get_string(2)), "%s: unbekanntes Feld in %s" % [path, key])
			roles[m.get_string(1)] = true
		assert_eq(roles.size(), parts.size(), "%s: Einträge für genau alle Katalogrollen" % path)
		assert_false(roles.has("kartenschlucker"), "%s: Kartenschlucker ohne Eintrag" % path)
		assert_true(count >= parts.size() * RolePresentation.LEXICON_FIELDS.size(), "%s: alle Pflichtfelder" % path)
	assert_false(RoleCatalog.has_role(&"kartenschlucker"), "Kartenschlucker ist keine spielbare Rolle")


func test_texts_have_no_placeholders_or_document_references() -> void:
	var re := RegEx.create_from_string(LEX_KEY)
	var refs := RegEx.create_from_string(INTERNAL_REFS)
	for path: String in [PO_DE, PO_EN]:
		var entries := po_entries(path)
		for key: String in entries:
			if re.search(key) == null:
				continue
			var text := str(entries[key])
			assert_false(text.contains("{") or text.contains("}"), "%s: %s ohne Platzhalter (wird ohne Werte angezeigt)" % [path, key])
			var m := refs.search(text)
			assert_true(m == null, "%s: %s verweist auf Dokumente (%s)" % [path, key, m.get_string() if m != null else ""])
			assert_false(text.contains("\""), "%s: %s mit geraden Anführungszeichen" % [path, key])


func test_decided_rule_answers_are_reflected() -> void:
	# PE-05: Quellrolle in den Ansagen; PE-06: Phase „Alle Verzauberten“, noch nicht umgesetzt und deshalb offen markiert.
	var de := po_entries(PO_DE)
	assert_true(str(de["ui.role.loki.lex.gm"]).contains("nie die Rolle der sterbenden Person"), "Loki: Quellrolle")
	assert_true(str(de["ui.role.rotkaeppchen.lex.gm"]).contains("nie die Rolle der sterbenden Person"), "Rotkäppchen: Quellrolle")
	assert_true(str(de["ui.role.schattenwanderer.lex.gm"]).contains("nie die Rolle der sterbenden Person"), "Schattenwanderer: Quellrolle")
	assert_true(str(de["ui.role.rattenfaenger.lex.gm"]).contains("auch auf einen reinen Tarnaufruf"), "Rattenfänger: Regel PE-06")
	assert_true(de.has("ui.role.rattenfaenger.lex.open"), "Rattenfänger: Umsetzung offen gekennzeichnet")
	assert_false(str(de["ui.role.loki.lex.gm"]).contains("nur in Nacht 1 auf"), "Loki: kein Widerspruch zur Aufrufpolitik")


## Laufzeit: das gerenderte Lexikon zeigt für jede Rolle in beiden Sprachen übersetzte Texte, keine Schlüssel und keinen
## generischen Ersatz; die offene Zeile erscheint genau bei Rollen mit Eintrag.
func test_rendered_entries_show_real_texts_in_both_languages() -> void:
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell == null:
		return
	var settings := settings_of(shell) as AppSettings
	var de := po_entries(PO_DE)
	for locale: String in ["de", "en"]:
		settings.set_language(locale)
		var lexicon := RoleLexicon.new(settings)
		tree.root.add_child(lexicon)
		for id: Variant in RoleCatalog.ROLES:
			var role := StringName(id)
			lexicon.open_role(role)
			assert_eq(lexicon.current_role(), role, "Eintrag %s geöffnet" % role)
			var fields: Array[String] = RolePresentation.LEXICON_FIELDS.duplicate()
			var has_open := de.has(RolePresentation.lexicon_key(role, RolePresentation.LEXICON_OPEN))
			if has_open:
				fields.append(RolePresentation.LEXICON_OPEN)
			for field: String in fields:
				var label := lexicon.find_child("LexiconField_%s" % field, true, false) as Label
				assert_true(label != null, "%s/%s: Feld %s vorhanden" % [locale, role, field])
				if label != null:
					assert_true(label.text != "" and label.text != RolePresentation.lexicon_key(role, field), "%s/%s: %s übersetzt" % [locale, role, field])
			assert_eq(lexicon.find_child("LexiconField_open", true, false) != null, has_open, "%s/%s: offene Punkte nur bei Eintrag" % [locale, role])
			var title := lexicon.find_child("LexiconTitleLabel", true, false) as Label
			assert_eq(title.text, tr(RolePresentation.name_key(role)), "%s/%s: Titel ist der Rollenname" % [locale, role])
		lexicon.queue_free()
	settings.set_language("de")
