extends "res://tests/ui/role_ui_case.gd"
## Rollenlexikon und Kontexthilfe (Paket 5b), Bedienung über echte Controls:
##   Hauptmenü → Lexikon (Suche, Fraktionsfilter, leerer Zustand, langer Eintrag, Sprachwechsel, Zurück),
##   Setup → Eintrag aus der Rollenwahl ohne Änderung der Besetzung,
##   Cockpit → Kontexthilfe bei offener Zielauswahl: kein Befehl, kein Zufall, keine Ressource; die Auswahl bleibt,
##   bis sich der Zustand ändert; allgemeines Lexikon ohne Partiedaten; Sichtschutz, gezeigte Karte und Zurück.
## Headless-Geometrie belegt nur Überlauf und Erreichbarkeit, keine visuelle oder Touch-Abnahme.

const W := "werwolf"
const D := "dorfbewohner"


func _lexicon(root: Node) -> RoleLexicon:
	return root.find_child("RoleLexicon", true, false) as RoleLexicon


func _texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		out.append(text_of(c))
	return out


func _visible_text(root: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		if c.is_visible_in_tree():
			out.append(text_of(c))
	return "\n".join(out)


## Vollständiger Spielstand und Protokoll: bleibt bei reiner Lexikonbedienung unverändert (Befehle, Generator, Ressourcen).
func _fingerprint() -> String:
	return JSON.stringify([session().commands().size(), session().event_log().size(), state().to_dict()])


func test_main_menu_opens_lexicon_with_search_filter_and_empty_state() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await press(find_button(current_screen(shell), "LexiconButton"))
	await frames(2)
	assert_eq(current_id(shell), &"lexicon", "Hauptmenü öffnet das Rollenlexikon")
	var lexicon := _lexicon(current_screen(shell))
	assert_eq(lexicon.visible_roles().size(), 71, "alle 71 Rollen gelistet")
	await type_text(find_node(lexicon, "LexiconSearchField") as Control, "ORAK")
	assert_eq(lexicon.visible_roles(), [&"das-orakel"] as Array[StringName], "Suche nach Rollenname ohne Groß-/Kleinschreibung")
	await press(find_button(lexicon, "LexiconFilter_wolves"))
	assert_true(lexicon.visible_roles().is_empty(), "Filter Werwölfe: kein Treffer")
	var empty := find_node(lexicon, "LexiconEmptyLabel") as Control
	assert_true(empty.is_visible_in_tree(), "leerer Zustand sichtbar")
	assert_eq(key_of(empty), "ui.lexicon.empty", "verständlicher Hinweis")
	lexicon.set_search("")
	var wolves := lexicon.visible_roles()
	assert_true(not wolves.is_empty() and wolves.all(func(r: StringName) -> bool: return RoleCatalog.faction_of(r) == Faction.WOLVES), "nur Werwölfe")
	await press(find_button(lexicon, "LexiconFilter_all"))
	assert_eq(lexicon.visible_roles().size(), 71, "Filter Alle")
	await press(find_button(lexicon, "LexiconRole_das-orakel"))
	assert_eq(lexicon.current_role(), &"das-orakel", "Eintrag geöffnet")
	await go_back(shell)
	assert_eq(current_id(shell), &"lexicon", "Zurück schließt zuerst den Eintrag")
	assert_false(lexicon.is_entry_open(), "wieder in der Liste")
	await go_back(shell)
	assert_eq(current_id(shell), &"main_menu", "dann zum Hauptmenü")


func test_search_uses_the_selected_language() -> void:
	shell = await spawn_shell(SIZE_16_10, "en")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"lexicon")
	var lexicon := _lexicon(current_screen(shell))
	lexicon.set_search("oracle")
	assert_eq(lexicon.visible_roles(), [&"das-orakel"] as Array[StringName], "englischer Name gefunden")
	lexicon.set_search("orakel")
	assert_true(lexicon.visible_roles().is_empty(), "deutscher Name nicht im englischen Lexikon")


func test_long_entry_is_fully_reachable_at_4_3() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"lexicon")
	var lexicon := _lexicon(current_screen(shell))
	# Längster Eintrag nach Zeichen (beide Sprachen).
	var longest := &""
	var best := 0
	var de := po_entries(PO_DE)
	for id: Variant in RoleCatalog.ROLES:
		var total := 0
		for field: String in RolePresentation.LEXICON_FIELDS:
			total += str(de.get(RolePresentation.lexicon_key(StringName(id), field), "")).length()
		if total > best:
			best = total
			longest = StringName(id)
	lexicon.open_role(longest)
	await frames(3)
	var scroll := find_node(lexicon, "LexiconEntryScroll") as ScrollContainer
	var entry := find_node(lexicon, "LexiconEntry") as Control
	assert_true(entry.size.y > scroll.size.y, "langer Eintrag %s ist länger als die Fläche (%d > %d)" % [longest, entry.size.y, scroll.size.y])
	assert_true(entry.size.x <= scroll.size.x + 0.5, "kein horizontaler Überlauf")
	assert_true(inside(rect_of(lexicon), Rect2(Vector2.ZERO, Vector2(SIZE_4_3))), "Lexikon innerhalb des Fensters")
	scroll.scroll_vertical = int(entry.size.y)
	await frames(2)
	var last := find_node(entry, "LexiconField_gm") as Control
	if find_node(entry, "LexiconField_open") != null:
		last = find_node(entry, "LexiconField_open") as Control
	assert_true(inside(rect_of(last), rect_of(scroll), 1.0), "letzter Abschnitt erreichbar")


func test_language_switch_keeps_the_open_entry() -> void:
	shell = await spawn_shell(SIZE_16_10, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"lexicon")
	var lexicon := _lexicon(current_screen(shell))
	await press(find_button(lexicon, "LexiconRole_rattenfaenger"))
	var ability := find_node(lexicon, "LexiconField_ability") as Label
	var german := ability.text
	await press(find_button(lexicon, "LexiconLanguageButton"))
	await frames(2)
	assert_eq(str(settings_of(shell).get("language")), "en", "Sprache gewechselt")
	assert_eq(lexicon.current_role(), &"rattenfaenger", "Rollenbezug bleibt")
	assert_true(ability.text != german and ability.text == TranslationServer.translate("ui.role.rattenfaenger.lex.ability"), "Text in Englisch")
	assert_eq((find_node(lexicon, "LexiconTitleLabel") as Label).text, "Pied Piper", "Titel in Englisch")
	await press(find_button(lexicon, "LexiconLanguageButton"))
	assert_eq(str(settings_of(shell).get("language")), "de", "zurück auf Deutsch")


func test_setup_opens_an_entry_without_changing_the_selection() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, numbered_names(6))
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	var setup := setup_of(shell)
	assert_eq(str((setup.call("view") as Dictionary)["step"]), "roles", "Rollenwahl erreicht")
	await press(find_button(screen, "PlusButton"))
	var before := JSON.stringify(setup.call("view"))
	await press(find_button(screen, "RoleInfoButton_das-orakel"))
	var layer := screen.call("lexicon_layer") as Control
	assert_true(layer != null, "Ebene geöffnet")
	assert_eq(_lexicon(layer).current_role(), &"das-orakel", "Eintrag der gewählten Zeile")
	assert_eq(JSON.stringify(setup.call("view")), before, "Rollenwahl und Verteilung unverändert")
	await press(find_button(layer, "CloseLayerButton"))
	assert_true(screen.call("lexicon_layer") == null, "Schließen entfernt die Ebene")
	assert_eq(current_id(shell), &"new_game", "zurück im Setup")
	await press(find_button(screen, "RoleInfoButton_werwolf"))
	await go_back(shell)
	assert_true(screen.call("lexicon_layer") == null, "Zurück schließt die Ebene")
	assert_eq(str((setup.call("view") as Dictionary)["step"]), "roles", "gleicher Setup-Schritt")
	assert_eq(JSON.stringify(setup.call("view")), before, "Besetzung weiter unverändert")


## Schutzengel-Auswahl offen, eine Person angetippt: Kontexthilfe öffnet den passenden Eintrag, Lexikonbedienung ändert
## nichts, Schließen führt zur selben Auswahl zurück. Eine echte Zustandsänderung verwirft die Auswahl.
func test_context_help_keeps_the_open_selection_and_sends_nothing() -> void:
	if not await start([W, "schutzengel", D, D, D, D]):
		return
	assert_true(await run({}, until_prompt("schutzengel")), "Schutzengel-Auswahl offen")
	await tap_seat(3)
	assert_eq(selection(), [3], "Person 3 ausgewählt")
	var before := _fingerprint()
	assert_true(await tap_button("ContextHelpButton"), "Kontexthilfe auf der privaten Karte")
	assert_eq(screen().call("layer_kind"), &"lexicon", "Lexikon als Ebene")
	var lexicon := _lexicon(screen())
	assert_eq(lexicon.current_role(), &"schutzengel", "Eintrag der handelnden Rolle")
	await press(find_button(lexicon, "LexiconBackToListButton"))
	lexicon.set_search("wolf")
	await press(find_button(lexicon, "LexiconFilter_solo"))
	await press(find_button(lexicon, "LexiconRole_rattenfaenger"))
	assert_eq(_fingerprint(), before, "Öffnen, Suchen, Filtern: kein Befehl, kein Zufall, keine Ressource")
	await tap_button("CloseLayerButton")
	assert_eq(screen().call("layer_kind"), &"", "Ebene geschlossen")
	assert_eq(selection(), [3], "Auswahl nach dem Schließen erhalten")
	assert_eq(_fingerprint(), before, "Schließen sendet nichts")
	assert_true(live("ConfirmTargetsButton") != null, "Auswahl weiter bestätigbar")
	# Echte Zustandsänderung bei offener Hilfe: die bestehenden Regeln verwerfen die Auswahl.
	assert_true(await tap_button("ContextHelpButton"), "Hilfe erneut geöffnet")
	var r := session().answer_targets([4])
	assert_true(r.ok, "Zustand ändert sich (Vorbereitung über die Anwendungsschicht)")
	await frames(2)
	assert_true(selection().is_empty(), "veraltete Auswahl verworfen")


func test_general_lexicon_in_a_game_shows_no_game_data() -> void:
	if not await start([W, "rattenfaenger", "schutzengel", D, D, D]):
		return
	await tap_button("LexiconButton")
	var lexicon := _lexicon(screen())
	assert_true(lexicon != null and not lexicon.is_entry_open(), "allgemeines Lexikon als Liste")
	assert_eq(lexicon.visible_roles().size(), 71, "alle Rollen, nicht nur die verteilten")
	# Derselbe Eintrag ohne jede Partie ist der Maßstab: jede Abweichung wäre Partiewissen im allgemeinen Lexikon.
	var reference := RoleLexicon.new(null)
	tree.root.add_child(reference)
	for role: StringName in [&"rattenfaenger", &"werwolf", &"hades"]:
		lexicon.open_role(role)
		reference.open_role(role)
		await frames(1)
		assert_eq(_texts(lexicon.find_child("LexiconEntry", true, false)), _texts(reference.find_child("LexiconEntry", true, false)), "%s: Eintrag wie ohne Partie" % role)
	reference.queue_free()
	await go_back(shell)
	assert_eq(screen().call("layer_kind"), &"", "Zurück schließt die Ebene, kein Verlassen-Dialog")
	assert_false(dialog().call("is_open"), "keine Rückfrage")


func test_context_help_stays_private_and_cover_closes_it() -> void:
	if not await start([W, "das-orakel", D, D, D, D]):
		return
	assert_true(await run({}, until_prompt("das-orakel", "shown")), "Orakel: Ergebnis zum Zeigen")
	# Die gezeigte Karte ersetzt das Cockpit; auf ihr gibt es keine Hilfe.
	assert_true(await tap_button("ShowCardButton"), "Karte zeigen")
	assert_eq(screen().call("layer_kind"), &"show", "gezeigte Karte")
	assert_true(live("ContextHelpButton") == null, "keine Hilfe über der gezeigten Karte")
	assert_true(screen().find_child("LexiconLayer", true, false) == null, "kein Lexikon auf der gezeigten Karte")
	await tap_button("CloseLayerButton")
	assert_true(await tap_button("ContextHelpButton"), "Hilfe auf der privaten Karte")
	var public_before := JSON.stringify(session().cockpit_view().get("warnings", []))
	assert_true(await tap_button("CoverButton"), "Sichtschutz über dem offenen Lexikon")
	assert_true(screen().call("is_covered"), "Sichtschutz aktiv")
	assert_true(screen().find_child("LexiconLayer", true, false) == null, "Sichtschutz entfernt das Lexikon")
	var cover_text := _visible_text(screen())
	assert_false(cover_text.contains(tr("ui.role.das_orakel.name")), "verdecktes Cockpit nennt die Rolle nicht")
	screen().call("uncover")
	assert_eq(JSON.stringify(session().cockpit_view().get("warnings", [])), public_before, "öffentliche Hinweise unverändert")
	assert_true(live("ContextHelpButton") != null, "nach dem Aufheben wieder auf der privaten Karte")


## Außerhalb der Nacht ist eine geheime Karte verdeckt: dann gibt es keine Hilfe, erst nach dem Aufdecken.
func test_covered_secret_card_has_no_context_help() -> void:
	var card := ActionCard.new()
	tree.root.add_child(card)
	var next := {"kind": "prompt", "secret": true, "role_id": "das-orakel", "owner": "das-orakel", "stage": "", "answer": "ack"}
	card.render(next, {"phase": "DAY", "revealed": false})
	assert_true(card.find_child("ContextHelpButton", true, false) == null, "verdeckt: keine Hilfe, keine Rolle")
	card.render(next, {"phase": "DAY", "revealed": true})
	assert_true(card.find_child("ContextHelpButton", true, false) != null, "aufgedeckt: Hilfe vorhanden")
	card.queue_free()


func selection() -> Array:
	return screen().get("_selection") as Array


func test_help_role_mapping() -> void:
	assert_eq(CockpitText.help_role({"kind": "begin_step", "role_id": "pack"}), "werwolf", "Rudel → Werwolf")
	assert_eq(CockpitText.help_role({"kind": "prompt", "role_id": "", "owner": "rotkaeppchen"}), "rotkaeppchen", "anonyme Frage → Rotkäppchen")
	assert_eq(CockpitText.help_role({"kind": "prompt", "role_id": "die-gebundenen"}), "die-gebundenen", "Gruppe mit eigenem Eintrag")
	assert_eq(CockpitText.help_role({"kind": "notice", "notice_kind": "piper_all"}), "rattenfaenger", "Hinweis der Verzauberten")
	assert_eq(CockpitText.help_role({"kind": "day"}), "", "Tageskarte: keine Kontexthilfe")
	assert_eq(CockpitText.help_role({"kind": "prompt", "role_id": "reaction"}), "", "unbekannt: keine Hilfe")
