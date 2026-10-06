extends "res://tests/ui/role_ui_case.gd"
## Allgemeines Regelbuch (Paket C): dreizehn Kapitel in DE und EN, erreichbar aus Hauptmenü und Cockpit, Navigation, lange
## Kapitel, Sprachwechsel, keine Befehle, kein Zufall, keine Ressourcen, keine Partiedaten. Headless-Geometrie belegt nur
## Überlauf und Erreichbarkeit, keine visuelle oder Touch-Abnahme.

const W := "werwolf"
const D := "dorfbewohner"
const CHAPTER_TITLES_DE: Array[String] = ["Vorbereitung", "Personen, Rollenwahl, Verteilung und Sitzordnung", "Rollen sicher zeigen",
		"Nacht führen und Tarnaufrufe", "Private Informationen zeigen", "Morgen und Wiederbelebungsrunde",
		"Tag, Nominierung und physische Abstimmung", "Hinrichtung und Todesreaktionen", "Sieg bestätigen",
		"Spielleiterkorrekturen und Undo", "Speichern, Fortsetzen und Fehlerbehandlung", "Rollenlexikon und Hilfe nutzen",
		"Totenreichkarten und Kartenschlucker"]
## Begriffe aus Code und Planungsdokumenten haben im Regelbuch nichts zu suchen (verständliche Sprache).
const BANNED_TERMS: Array[String] = ["Regelkern", "GameState", "JSON", "user://", "Godot", ".gd", "Schema", "Autoload", "Node", "Befehlsfolge", "Replay", "Seed"]


func _book(root: Node) -> RuleBook:
	return root.find_child("RuleBook", true, false) as RuleBook


func _fingerprint() -> String:
	return JSON.stringify([session().commands().size(), session().event_log().size(), state().to_dict()])


func _texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		if c.is_visible_in_tree():
			out.append(text_of(c))
	return out


func _block_texts(index: int, lang: String) -> Array[String]:
	var po := po_entries(PO_DE if lang == "de" else PO_EN)
	var out: Array[String] = []
	for b: int in RulebookCatalog.kinds(index).length():
		out.append(str(po[RulebookCatalog.block_key(index, b)]))
	return out


# --- Inhalt --------------------------------------------------------------------------------------------------

func test_catalog_matches_translations_in_both_languages() -> void:
	assert_eq(RulebookCatalog.count(), 13, "dreizehn Kapitel")
	var chapter_key := RegEx.create_from_string("^ui\\.rulebook\\.c\\d\\d\\.")
	for lang: String in ["de", "en"]:
		var po := po_entries(PO_DE if lang == "de" else PO_EN)
		var used := {}
		for i: int in RulebookCatalog.count():
			var title := str(po.get(RulebookCatalog.title_key(i), ""))
			assert_true(title != "", "%s: Kapitel %d hat einen Titel" % [lang, i + 1])
			used[RulebookCatalog.title_key(i)] = true
			if lang == "de":
				assert_eq(title, CHAPTER_TITLES_DE[i], "Kapitel %d: vereinbarter Titel" % (i + 1))
			var kinds := RulebookCatalog.kinds(i)
			assert_true(kinds.length() >= 4, "%s: Kapitel %d hat Inhalt (%d Blöcke)" % [lang, i + 1, kinds.length()])
			for b: int in kinds.length():
				assert_true("hpl".contains(kinds[b]), "Kapitel %d Block %d: bekannte Art" % [i + 1, b + 1])
				var key := RulebookCatalog.block_key(i, b)
				used[key] = true
				var text := str(po.get(key, ""))
				assert_true(text.strip_edges() != "", "%s: %s vorhanden" % [lang, key])
				assert_false(text.contains("—"), "%s: kein Geviertstrich in %s" % [lang, key])
				assert_false(text.contains("{"), "%s: kein Platzhalter in %s" % [lang, key])
				for term: String in BANNED_TERMS:
					assert_false(text.contains(term), "%s: %s enthält Codebegriff „%s“" % [lang, key, term])
			assert_eq(str(po.get(RulebookCatalog.block_key(i, kinds.length()), "")), "", "%s: Kapitel %d hat keinen Text über den Katalog hinaus" % [lang, i + 1])
		for key: Variant in po:
			if chapter_key.search(str(key)) != null:
				assert_true(used.has(key), "%s: %s gehört zum Katalog" % [lang, key])
	# Kein Kapitel ist in beiden Sprachen wortgleich (kein vergessener Text).
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	for i: int in RulebookCatalog.count():
		for b: int in RulebookCatalog.kinds(i).length():
			var key := RulebookCatalog.block_key(i, b)
			assert_ne(de[key], en[key], "%s: DE und EN unterscheiden sich" % key)


## Jede in Anführungszeichen genannte Beschriftung, Meldung oder Vorlesezeile des Regelbuchs kommt im Programm tatsächlich
## vor: als Text irgendwo außerhalb des Regelbuchs. Das belegt, dass Knopfnamen und Meldungen echt sind.
func test_quoted_labels_exist_in_the_app() -> void:
	# Bewusst frei formulierte Ausdrücke: Beispiele und Spielbegriffe, keine Beschriftungen des Programms.
	var allowed: Dictionary = {
		"de": ["Nur für die Spielleitung", "Zuerst aufrufen", "Karte für Sitz · Name", "Sieg bestätigen: …", "Neue Partie", "Regelbuch", "Nächster Schritt · 3 von 7"],
		"en": ["Game master only", "Call first", "Card for seat · name", "Confirm win: …", "New game", "Rulebook", "Next step · 3 of 7"],
	}
	for lang: String in ["de", "en"]:
		var po := po_entries(PO_DE if lang == "de" else PO_EN)
		var pool: Array[String] = []
		for key: Variant in po:
			if not str(key).begins_with("ui.rulebook."):
				pool.append(str(po[key]))
		var opening := "„" if lang == "de" else "“"
		var closing := "“" if lang == "de" else "”"
		var checked := 0
		for i: int in RulebookCatalog.count():
			for b: int in RulebookCatalog.kinds(i).length():
				var text := str(po[RulebookCatalog.block_key(i, b)])
				var from := 0
				while true:
					var start := text.find(opening, from)
					if start == -1:
						break
					var end := text.find(closing, start + 1)
					assert_true(end != -1, "%s: Anführungszeichen geschlossen in %s" % [lang, RulebookCatalog.block_key(i, b)])
					if end == -1:
						break
					var quoted := text.substr(start + 1, end - start - 1).strip_edges()
					from = end + 1
					var probe := quoted.trim_suffix(" …").trim_suffix("…").trim_suffix(".").trim_suffix(" ").strip_edges()
					var found: bool = allowed[lang].has(quoted) or allowed[lang].has(probe)
					for entry: String in pool:
						if found:
							break
						found = entry.contains(probe)
					assert_true(found, "%s: „%s“ (%s) kommt im Programm vor" % [lang, quoted, RulebookCatalog.block_key(i, b)])
					checked += 1
		assert_true(checked >= 100, "%s: viele genannte Beschriftungen geprüft (%d)" % [lang, checked])


# --- Hauptmenü, Navigation, Sprache ----------------------------------------------------------------------------

func test_main_menu_opens_toc_and_every_chapter_in_both_languages() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await press(find_button(current_screen(shell), "RulebookButton"))
	assert_eq(current_id(shell), &"rulebook", "Hauptmenü öffnet das Regelbuch")
	var book := _book(current_screen(shell))
	assert_false(book.is_chapter_open(), "zuerst das Inhaltsverzeichnis")
	for i: int in RulebookCatalog.count():
		assert_true(find_node(book, "RulebookChapter_%s" % RulebookCatalog.chapter_id(i)) != null, "Verzeichniseintrag %d" % (i + 1))
	for lang: String in ["de", "en"]:
		settings_of(shell).call("set_language", lang)
		await frames(2)
		for i: int in RulebookCatalog.count():
			await press(find_button(book, "RulebookChapter_%s" % RulebookCatalog.chapter_id(i)))
			assert_eq(book.current_chapter(), i, "%s: Kapitel %d geöffnet" % [lang, i + 1])
			assert_eq(book.chapter_texts(), _block_texts(i, lang), "%s: Kapitel %d zeigt genau seine Texte" % [lang, i + 1])
			var title := find_node(book, "RulebookTitleLabel") as Label
			assert_eq(title.text, str(po_entries(PO_DE if lang == "de" else PO_EN)[RulebookCatalog.title_key(i)]), "%s: Kapiteltitel %d" % [lang, i + 1])
			await press(find_button(book, "RulebookBackToTocButton"))
			assert_false(book.is_chapter_open(), "%s: zurück zum Verzeichnis" % lang)


func test_previous_next_and_back_navigation() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"rulebook")
	var book := _book(current_screen(shell))
	await press(find_button(book, "RulebookChapter_c01"))
	assert_true(find_button(book, "RulebookPrevButton").disabled, "erstes Kapitel: kein Vorheriges")
	assert_false(find_button(book, "RulebookNextButton").disabled, "erstes Kapitel: Nächstes frei")
	await press(find_button(book, "RulebookNextButton"))
	assert_eq(book.current_chapter(), 1, "Nächstes Kapitel")
	assert_true(str((find_node(book, "RulebookPositionLabel") as Label).text).contains("2") and str((find_node(book, "RulebookPositionLabel") as Label).text).contains("13"), "Position „Kapitel 2 von 13“")
	await press(find_button(book, "RulebookPrevButton"))
	assert_eq(book.current_chapter(), 0, "Vorheriges Kapitel")
	for i: int in 12:
		await press(find_button(book, "RulebookNextButton"))
	assert_eq(book.current_chapter(), 12, "letztes Kapitel erreicht")
	assert_true(find_button(book, "RulebookNextButton").disabled, "letztes Kapitel: kein Nächstes")
	await go_back(shell)
	assert_eq(current_id(shell), &"rulebook", "Zurück schließt zuerst das Kapitel")
	assert_false(book.is_chapter_open(), "wieder im Verzeichnis")
	await go_back(shell)
	assert_eq(current_id(shell), &"main_menu", "dann zum Hauptmenü")


func test_language_switch_keeps_the_open_chapter() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"rulebook")
	var book := _book(current_screen(shell))
	book.open_chapter(5)
	await frames(2)
	assert_eq(book.chapter_texts(), _block_texts(5, "de"), "deutscher Text")
	await press(find_button(book, "RulebookLanguageButton"))
	assert_eq(str(settings_of(shell).get("language")), "en", "Sprache gewechselt")
	assert_eq(book.current_chapter(), 5, "Kapitel bleibt")
	assert_eq(book.chapter_texts(), _block_texts(5, "en"), "englischer Text")
	await press(find_button(book, "RulebookLanguageButton"))
	assert_eq(book.chapter_texts(), _block_texts(5, "de"), "wieder Deutsch")


# --- Layout --------------------------------------------------------------------------------------------------------

## Kopf und Fuß bleiben im Fenster, der Text blättert (keine Scrollfläche), jede Seite liegt ganz in der Textfläche.
func _check_chapter_layout(book: RuleBook, label: String) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var host := find_node(book, "RulebookChapterHost") as Control
	assert_true(inside(rect_of(book), viewport), "%s: Regelbuch im Fenster (%s)" % [label, rect_of(book)])
	assert_true(host.find_children("*", "ScrollContainer", true, false).is_empty(), "%s: nichts scrollt" % label)
	for name: String in ["RulebookBackToTocButton", "RulebookLanguageButton", "RulebookPrevButton", "RulebookNextButton", "RulebookPositionLabel"]:
		var c := find_node(book, name) as Control
		assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s sichtbar im Fenster" % [label, name])
		if c is BaseButton:
			assert_true(c.size.x >= 47.5 and c.size.y >= 47.5, "%s: %s mindestens 48×48" % [label, name])
	assert_true(host.size.y >= 150.0, "%s: Text behält Platz (%.0f)" % [label, host.size.y])
	for page: int in book.page_count():
		var body := find_node(book, "PageBody") as Control
		for block: Node in body.get_children():
			assert_true(inside(rect_of(block as Control), rect_of(host), 1.0), "%s Seite %d: %s liegt in der Fläche" % [label, page + 1, block.name])
		var next := find_node(book, "NextPageButton") as BaseButton
		if next != null and not next.disabled:
			await press(next)


func test_every_chapter_fits_and_scrolls_at_1024x768() -> void:
	for lang: String in ["de", "en"]:
		shell = await spawn_shell(SIZE_4_3, lang)
		if shell == null:
			return
		await navigate(shell, &"main_menu")
		await navigate(shell, &"rulebook")
		var book := _book(current_screen(shell))
		var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
		# Inhaltsverzeichnis: alle dreizehn Einträge erreichbar (zur Not durch Scrollen), Einträge mindestens 48 hoch.
		var toc_scroll := find_node(book, "RulebookTocScroll") as ScrollContainer
		assert_true(inside(rect_of(toc_scroll), viewport), "%s: Verzeichnis im Fenster" % lang)
		var last_toc := find_button(book, "RulebookChapter_c13")
		toc_scroll.ensure_control_visible(last_toc)
		await frames(2)
		assert_true(inside(rect_of(last_toc), rect_of(toc_scroll), 1.0), "%s: letzter Verzeichniseintrag erreichbar" % lang)
		for i: int in RulebookCatalog.count():
			var b := find_button(book, "RulebookChapter_%s" % RulebookCatalog.chapter_id(i))
			assert_true(b.size.y >= 47.5, "%s: Eintrag %d mindestens 48 hoch" % [lang, i + 1])
			assert_true(b.size.x <= toc_scroll.size.x + 0.5, "%s: Eintrag %d nicht breiter als die Fläche" % [lang, i + 1])
			book.open_chapter(i)
			await frames(3)
			await _check_chapter_layout(book, "%s Kapitel %d" % [lang, i + 1])
		await after_each()


func test_longest_chapter_is_longer_than_the_area() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"main_menu")
	await navigate(shell, &"rulebook")
	var book := _book(current_screen(shell))
	var longest := 0
	var best := 0
	for i: int in RulebookCatalog.count():
		var total := 0
		for t: String in _block_texts(i, "de"):
			total += t.length()
		if total > best:
			best = total
			longest = i
	book.open_chapter(longest)
	await frames(3)
	assert_true(book.page_count() > 1, "langes Kapitel %d braucht mehrere Seiten (%d)" % [longest + 1, book.page_count()])
	assert_true(find_node(book, "RulebookChapterHost").find_children("*", "ScrollContainer", true, false).is_empty(), "keine Scrollfläche")


# --- Cockpit -------------------------------------------------------------------------------------------------------

func test_cockpit_tool_keeps_the_open_selection_and_sends_nothing() -> void:
	if not await start([W, "spuerhund", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({}, until_prompt("spuerhund")), "Spürhund-Auswahl offen")
	await tap_seat(3)  # drei Personen nötig: die Auswahl bleibt offen
	assert_eq(selection(), [3], "Person 3 ausgewählt")
	var before := _fingerprint()
	assert_true(await tap_button("RulebookButton"), "Werkzeug „Regelbuch“")
	assert_eq(screen().call("layer_kind"), &"rulebook", "Regelbuch als Ebene")
	var book := _book(screen())
	assert_false(book.is_chapter_open(), "Ebene öffnet mit dem Verzeichnis")
	await press(find_button(book, "RulebookChapter_c04"))
	await press(find_button(book, "RulebookNextButton"))
	await press(find_button(book, "RulebookLanguageButton"))
	await press(find_button(book, "RulebookLanguageButton"))
	await press(find_button(book, "RulebookBackToTocButton"))
	assert_eq(_fingerprint(), before, "Öffnen, Blättern, Sprache: kein Befehl, kein Zufall, keine Ressource")
	await tap_button("CloseLayerButton")
	assert_eq(screen().call("layer_kind"), &"", "Ebene geschlossen")
	assert_eq(selection(), [3], "Auswahl nach dem Schließen erhalten")
	assert_eq(_fingerprint(), before, "Schließen sendet nichts")
	assert_eq(selection(), [3], "Auswahl weiter offen")
	# Echte Zustandsänderung bei offenem Regelbuch: die bestehenden Regeln verwerfen die Auswahl.
	assert_true(await tap_button("RulebookButton"), "Regelbuch erneut geöffnet")
	var r := session().answer_targets([4, 5, 6])
	assert_true(r.ok, "Zustand ändert sich (Vorbereitung über die Anwendungsschicht)")
	await frames(2)
	assert_true(selection().is_empty(), "veraltete Auswahl verworfen")


func test_cockpit_rulebook_shows_no_game_data_and_cover_and_back_close_it() -> void:
	if not await start([W, "rattenfaenger", "schutzengel", D, "amalia", "detektiv"]):
		return
	assert_true(await tap_button("RulebookButton"), "Regelbuch im Cockpit")
	var book := _book(screen())
	var reference := RuleBook.new(context_of(shell).get("settings") as AppSettings)
	tree.root.add_child(reference)
	# Verzeichnis und alle Kapitel sind wortgleich mit einem Regelbuch ohne jede Partie.
	assert_eq(_texts(book), _texts(reference), "Verzeichnis wie ohne Partie")
	for i: int in RulebookCatalog.count():
		book.open_chapter(i)
		reference.open_chapter(i)
		await frames(1)
		assert_eq(book.chapter_texts(), reference.chapter_texts(), "Kapitel %d wie ohne Partie" % (i + 1))
	var names := (session().summary()["names"] as Array)
	for text: String in book.chapter_texts():
		for person: Variant in names:
			assert_false(text.contains(str(person) + ":"), "keine Personendaten im Regelbuch")
	reference.queue_free()
	await go_back(shell)
	assert_eq(screen().call("layer_kind"), &"", "Zurück schließt die Ebene, kein Verlassen-Dialog")
	assert_false(dialog().call("is_open"), "keine Rückfrage")
	assert_true(await tap_button("RulebookButton"), "erneut geöffnet")
	assert_true(await tap_button("CoverButton"), "Sichtschutz über dem Regelbuch")
	assert_true(screen().call("is_covered"), "Sichtschutz aktiv")
	assert_true(screen().find_child("RulebookLayer", true, false) == null, "Sichtschutz entfernt das Regelbuch")
	screen().call("uncover")


func test_no_rulebook_tool_on_a_shown_card() -> void:
	if not await start([W, "das-orakel", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({}, until_prompt("das-orakel", "shown")), "Orakel: Ergebnis zum Zeigen")
	assert_true(await tap_button("ShowCardButton"), "Karte zeigen")
	assert_eq(screen().call("layer_kind"), &"show", "gezeigte Karte")
	var tool := find_node(screen(), "RulebookButton") as Control
	assert_true(tool != null and not tool.is_visible_in_tree(), "das Cockpit-Werkzeug ist auf der gezeigten Karte nicht erreichbar")
	assert_true(screen().find_child("RulebookLayer", true, false) == null, "kein Regelbuch über der gezeigten Karte")


func test_rulebook_without_a_game_from_the_cockpit() -> void:
	shell = await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	await navigate(shell, &"cockpit")
	assert_true(await tap_button("RulebookButton"), "Regelbuch auch ohne Partie")
	assert_eq(screen().call("layer_kind"), &"rulebook", "Ebene offen")
	assert_true(_book(screen()) != null, "Regelbuch vorhanden")


func selection() -> Array:
	return screen().get("_selection") as Array
