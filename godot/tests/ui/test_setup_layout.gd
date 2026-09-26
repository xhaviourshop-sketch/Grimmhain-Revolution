extends UiTestCase
## Spieler-Setup: Layout, Scrollen, Touchziele und Lokalisierung (Tests 52 bis 61).
## Rechteckprüfungen über Control-Geometrien, keine Pixelprüfung. Controls in der
## scrollbaren Liste werden nur geprüft, soweit sie im sichtbaren Listenbereich liegen.


func _scroll(screen: Control) -> ScrollContainer:
	return find_node(screen, "PersonScroll") as ScrollContainer


func _inside_scroll(c: Control, scroll: ScrollContainer) -> bool:
	return scroll != null and scroll.is_ancestor_of(c)


## Prüft Ansicht plus offenen Dialog: Viewport, Überlappungen, nichts abgeschnitten,
## Touchziele. Listeneinträge nur im sichtbaren Bereich der Liste.
func _check(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var scroll := _scroll(screen)
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var roots: Array[Control] = [screen]
	var dialog := shell.call("get_dialog") as Control
	if dialog != null and dialog.visible:
		roots = [dialog]
	for root: Control in roots:
		var buttons: Array[BaseButton] = []
		for c: Control in visible_controls(root):
			if c.size.x <= 0.0 or c.size.y <= 0.0:
				continue
			var r := rect_of(c)
			if _inside_scroll(c, scroll):
				var visible_area := rect_of(scroll)
				if not r.intersects(visible_area):
					continue
				if c is BaseButton and not inside(r, visible_area):
					continue  # am Listenrand angeschnittene Zeile: erreichbar per Scrollen
			else:
				assert_true(inside(r, viewport), "%s: %s im Viewport (%s)" % [label, c.name, r])
			var min_size := c.get_combined_minimum_size()
			assert_true(min_size.x <= c.size.x + 0.5 and min_size.y <= c.size.y + 0.5, "%s: %s nicht abgeschnitten (min %s, ist %s)" % [label, c.name, min_size, c.size])
			if c is BaseButton:
				buttons.append(c as BaseButton)
				assert_true(c.size.x >= 47.5 and c.size.y >= 47.5, "%s: %s mindestens 48×48 (%s)" % [label, c.name, c.size])
			if c is LineEdit or c is TextEdit:
				assert_true(c.size.y >= 47.5, "%s: Eingabefeld %s mindestens 48 hoch" % [label, c.name])
		for i: int in buttons.size():
			for j: int in range(i + 1, buttons.size()):
				assert_false(overlaps(rect_of(buttons[i]), rect_of(buttons[j])), "%s: %s und %s überlappen" % [label, buttons[i].name, buttons[j].name])
		for c: Control in text_controls(root):
			var text_rect := rect_of(c)
			if _inside_scroll(c, scroll):
				# Die Liste schneidet ihren Inhalt ab: nur der sichtbare Ausschnitt zählt.
				if not text_rect.intersects(rect_of(scroll)):
					continue
				text_rect = text_rect.intersection(rect_of(scroll))
			if c is BaseButton:
				continue
			for b: BaseButton in buttons:
				if not b.is_ancestor_of(c):
					assert_false(overlaps(text_rect, rect_of(b)), "%s: Text %s überdeckt %s" % [label, c.name, b.name])
	# Kopfzeile und Bestätigungsbereich bleiben immer vollständig sichtbar.
	for name: String in ["BackButton", "ConfirmPlayersButton", "RestartButton", "CountLabel"]:
		var c := find_node(screen, name) as Control
		assert_true(c != null and c.is_visible_in_tree() and inside(rect_of(c), viewport), "%s: %s erreichbar" % [label, name])


func _case(size: Vector2i, locale: String, names: Array, label: String, prepare: Callable = Callable()) -> void:
	var shell := await spawn_shell(size, locale)
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, names)
	if prepare.is_valid():
		await prepare.call(shell, screen)
		await frames(3)
	await _check(shell, label)
	await after_each()


func test_layout_person_counts() -> void:
	# 54, 55: 0, 6, 12, 18, 24 Personen bei 1024×768 und 1280×800
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		for count: int in [0, 6, 12, 18, 24]:
			await _case(size, "de", numbered_names(count, "Spieler"), "%s DE %d Personen" % [size, count])
	await _case(SIZE_4_3, "en", numbered_names(24), "1024×768 EN 24 Personen")
	await _case(SIZE_WIDE, "de", numbered_names(24), "1920×1080 DE 24 Personen")


func test_layout_long_names_and_duplicates() -> void:
	# 56, 57
	await _case(SIZE_16_10, "de", long_names(24), "1280×800 DE 24 lange Namen")
	await _case(SIZE_4_3, "de", long_names(24), "1024×768 DE 24 lange Namen")
	await _case(SIZE_4_3, "en", long_names(12), "1024×768 EN 12 lange Namen")
	var dups: Array[String] = ["Anna", "anna", " ANNA ", "Max", "max", "Wolfgangamadeusmozartsalieri0000", "wolfgangamadeusmozartsalieri0000", "Ben"]
	await _case(SIZE_16_10, "de", dups, "1280×800 DE Dubletten")
	await _case(SIZE_4_3, "de", dups, "1024×768 DE Dubletten")


func test_layout_open_modes() -> void:
	# 58, 59 und offener Entfernen-Dialog
	var open_import := func(_shell: Control, screen: Control) -> void:
		await press(find_button(screen, "ImportToggleButton"))
		await type_text(find_node(screen, "ImportText") as TextEdit, "Anna, Ben;\nClara\n" + "Dora\n".repeat(10))
		await press(find_button(screen, "ImportConfirmButton"))  # Ablehnung, Meldung sichtbar
		await type_text(find_node(screen, "ImportText") as TextEdit, "X".repeat(40) + "\nAnna")
		await press(find_button(screen, "ImportConfirmButton"))
	var open_edit := func(_shell: Control, screen: Control) -> void:
		await press(find_button(person_rows(screen)[3], "EditButton"))
		await type_text(find_node(screen, "EditInput") as LineEdit, "Y".repeat(40))
		await press(find_button(screen, "EditSaveButton"))  # Fehlermeldung sichtbar
	var open_remove := func(_shell: Control, screen: Control) -> void:
		await press(find_button(person_rows(screen)[5], "RemoveButton"))
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		await _case(size, "de", numbered_names(14), "%s Import offen" % size, open_import)
		await _case(size, "de", long_names(18), "%s Bearbeiten offen" % size, open_edit)
		await _case(size, "en", long_names(18), "%s EN Bearbeiten offen" % size, open_edit)
		await _case(size, "de", long_names(24), "%s Entfernen-Dialog" % size, open_remove)


func test_scroll_reaches_first_and_last() -> void:
	# 60
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, numbered_names(24))
	var scroll := _scroll(screen)
	var rows := person_rows(screen)
	if scroll == null or rows.size() != 24:
		fail("Liste oder Zeilen fehlen")
		return
	scroll.scroll_vertical = 0
	await frames(2)
	assert_true(inside(rect_of(rows[0]), rect_of(scroll)), "erste Person sichtbar")
	assert_false(inside(rect_of(rows[23]), rect_of(scroll)), "24 Personen brauchen Scrollen")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await frames(2)
	assert_true(inside(rect_of(rows[23]), rect_of(scroll)), "letzte Person nach Scrollen sichtbar")
	scroll.scroll_vertical = 0
	await frames(2)
	find_button(rows[23], "EditButton").grab_focus()
	await frames(3)
	assert_true(inside(rect_of(find_button(rows[23], "EditButton")), rect_of(scroll)), "Tastaturfokus scrollt die Liste mit")


func test_setup_keys_complete_in_both_languages() -> void:
	# 52
	var de := po_entries(PO_DE)
	var en := po_entries(PO_EN)
	var setup_keys: Array = []
	for k: Variant in de:
		if str(k).begins_with("ui.setup."):
			setup_keys.append(k)
			assert_true(en.has(k), "EN hat %s" % k)
	for k: Variant in en:
		if str(k).begins_with("ui.setup."):
			assert_true(de.has(k), "DE hat %s" % k)
	assert_true(setup_keys.size() >= 40, "Setup-Schlüssel vorhanden (%d)" % setup_keys.size())
	for required: String in ["ui.setup.error.empty_name", "ui.setup.error.name_too_long", "ui.setup.error.too_many_persons",
			"ui.setup.error.invalid_entries", "ui.setup.error.too_few_persons", "ui.setup.person.duplicate",
			"ui.setup.status.confirmed", "ui.setup.dialog.leave.title", "ui.setup.dialog.remove.title", "ui.setup.dialog.restart.title"]:
		assert_true(de.has(required), "Schlüssel %s" % required)


func test_no_hardcoded_texts_in_setup_screen() -> void:
	# 53
	var de := po_entries(PO_DE)
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await open_new_game(shell)
	await seed_names(shell, ["Anna", "anna", "Ben", "Clara", "Dora", "Emil"])
	for state: String in ["Liste", "Import", "Bearbeiten"]:
		await _enter_state(screen, state)
		await frames(2)
		for c: Control in text_controls(screen):
			var k := key_of(c)
			var shown := text_of(c)
			if c.is_in_group(&"user_content") or (shown == "" and k == ""):
				continue
			assert_true(k != "" and de.has(k), "%s: %s nutzt einen Übersetzungsschlüssel (%s)" % [state, c.name, k])
			assert_true(shown != k, "%s: %s zeigt Text statt Schlüssel" % [state, c.name])
		for c: Control in visible_controls(screen):
			if c is LineEdit or c is TextEdit:
				var placeholder := str(c.get("placeholder_text"))
				assert_true(placeholder != "" and not placeholder.begins_with("ui."), "%s: Platzhalter von %s übersetzt (%s)" % [state, c.name, placeholder])
	var name_label := find_node(person_rows(screen)[0], "NameLabel") as Label
	assert_true(name_label.is_in_group(&"user_content") and name_label.tooltip_text == "Anna", "Name als Nutzerdaten mit vollem Namen im Tooltip")


func _enter_state(screen: Control, state: String) -> void:
	if state == "Import":
		await press(find_button(screen, "ImportToggleButton"))
	elif state == "Bearbeiten":
		await press(find_button(screen, "ImportCancelButton"))
		await press(find_button(person_rows(screen)[0], "EditButton"))
