extends UiTestCase
## Tablet-Layout (Tests 11 bis 14): Rechteckprüfungen über Control-Geometrien, keine
## Pixelprüfung. Geprüft wird ohne Herunterskalieren, also in genau 1024×768 bzw.
## 1280×800 logischen Pixeln, jeweils für alle sechs Ansichten und den offenen Dialog.

const PSEUDO_LOCALE := "de_XA"


func test_layout_1024x768() -> void:
	# 12
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell != null:
		await _check_all_screens(shell, "1024×768 DE")


func test_layout_1280x800() -> void:
	# 13
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell != null:
		await _check_all_screens(shell, "1280×800 DE")
		settings_of(shell).call("set_language", "en")
		await frames(2)
		await _check_all_screens(shell, "1280×800 EN")


func test_layout_wide_desktop_does_not_fall_apart() -> void:
	var tokens := load_script(THEME_TOKENS_SCRIPT)
	var shell := await spawn_shell(SIZE_WIDE, "de")
	if shell == null or tokens == null:
		return
	await _check_all_screens(shell, "1920×1080 DE")
	await navigate(shell, &"main_menu")
	var max_width := float(tokens.get("MENU_COLUMN_WIDTH"))
	for b: BaseButton in visible_buttons(current_screen(shell)):
		assert_true(b.size.x <= max_width + 0.5, "Menübutton %s wächst nicht über die Spaltenbreite (%.0f)" % [b.name, b.size.x])
	var column := rect_of(find_node(current_screen(shell), "NewGameButton") as Control)
	assert_true(absf(column.get_center().x - SIZE_WIDE.x / 2.0) < 2.0, "Menüspalte zentriert")


func test_long_german_texts_do_not_overlap() -> void:
	# 14: Pseudo-Lokalisierung = deutsche Texte um etwa 50 % verlängert.
	var de := po_entries(PO_DE)
	var pseudo := Translation.new()
	pseudo.locale = PSEUDO_LOCALE
	for k: Variant in de:
		var text := str(de[k])
		pseudo.add_message(StringName(str(k)), text + " " + text.left(ceili(text.length() * 0.5)))
	TranslationServer.add_translation(pseudo)
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		TranslationServer.remove_translation(pseudo)
		return
	TranslationServer.set_locale(PSEUDO_LOCALE)
	shell.propagate_notification(Node.NOTIFICATION_TRANSLATION_CHANGED)
	await frames(3)
	await navigate(shell, &"main_menu")
	var b := find_node(current_screen(shell), "NewGameButton") as Button
	assert_true(b != null and b.text.length() > "Neue Partie".length(), "verlängerte Texte aktiv")
	await _check_all_screens(shell, "1024×768 lange DE-Texte")
	TranslationServer.remove_translation(pseudo)


func test_touch_targets() -> void:
	# 11
	var tokens := load_script(THEME_TOKENS_SCRIPT)
	if tokens == null:
		return
	var min_size := float(tokens.get("TOUCH_MIN"))
	var primary_height := float(tokens.get("BUTTON_PRIMARY_HEIGHT"))
	assert_true(min_size >= 48.0, "Mindestgröße ≥ 48 (%s)" % min_size)
	assert_true(primary_height >= 64.0, "Primärhöhe ≥ 64 (%s)" % primary_height)
	for size: Vector2i in [SIZE_4_3, SIZE_16_10]:
		var shell := await spawn_shell(size, "de")
		if shell == null:
			return
		for id: StringName in SCREEN_IDS:
			await navigate(shell, id)
			for button: BaseButton in visible_buttons(current_screen(shell)):
				assert_true(button.size.x >= min_size - 0.5 and button.size.y >= min_size - 0.5,
					"%s %s: %s mindestens 48×48 (%s)" % [size, id, button.name, button.size])
				if str(button.get("kind")) == "0" or button.theme_type_variation == &"PrimaryButton":
					assert_true(button.size.y >= primary_height - 0.5, "%s %s: Primäraktion %s mindestens 64 hoch" % [size, id, button.name])
		# Gegensätzliche Aktionen im Dialog mit ausreichendem Abstand.
		shell.call("request_quit")
		await frames(3)
		var dialog := shell.call("get_dialog") as Control
		var confirm := find_node(dialog, "ConfirmButton") as Control
		var cancel := find_node(dialog, "CancelButton") as Control
		assert_true(confirm != null and cancel != null, "Dialogbuttons vorhanden")
		if confirm != null and cancel != null:
			var gap := maxf(rect_of(confirm).position.x - rect_of(cancel).end.x, rect_of(cancel).position.x - rect_of(confirm).end.x)
			assert_true(gap >= float(tokens.get("SPACE_XL")) - 0.5, "%s: Abstand Bestätigen/Abbrechen %.0f" % [size, gap])
			assert_true(confirm.size.y >= min_size and cancel.size.y >= min_size, "Dialogbuttons ≥ 48")
		await _check_controls(dialog, "%s Dialog" % size)
		await after_each()


func test_safe_area_insets_respected() -> void:
	var tokens := load_script(THEME_TOKENS_SCRIPT)
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell == null or tokens == null:
		return
	var inset := Rect2(Vector2(40, 24), Vector2(SIZE_16_10) - Vector2(40 + 32, 24 + 20))
	shell.call("apply_safe_area", inset)
	await frames(3)
	for id: StringName in SCREEN_IDS:
		await navigate(shell, id)
		for c: Control in visible_controls(current_screen(shell)):
			assert_true(inside(rect_of(c), inset), "%s: %s innerhalb der sicheren Fläche" % [id, c.name])
	shell.call("apply_safe_area", Rect2())
	await frames(3)
	var margin := float(tokens.get("SAFE_MARGIN"))
	var screen_rect := rect_of(current_screen(shell))
	assert_true(screen_rect.position.x >= margin - 0.5 and screen_rect.position.y >= margin - 0.5, "Mindestrand ohne Geräteangabe")


# --- Prüfkern ---------------------------------------------------------------------------------

func _check_all_screens(shell: Control, label: String) -> void:
	for id: StringName in SCREEN_IDS:
		await navigate(shell, id)
		await _check_controls(current_screen(shell), "%s %s" % [label, id])


## Innerhalb des Viewports, keine überlappenden Bedienelemente, kein abgeschnittener Text,
## Beschriftungen überdecken keine fremden Bedienelemente.
func _check_controls(root: Control, label: String) -> void:
	if root == null:
		fail("%s: keine Ansicht" % label)
		return
	var viewport := Rect2(Vector2.ZERO, Vector2(tree.root.size))
	var controls := visible_controls(root)
	var buttons := visible_buttons(root)
	for c: Control in controls:
		if c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		assert_true(inside(rect_of(c), viewport), "%s: %s liegt im Viewport (%s)" % [label, c.name, rect_of(c)])
		var min_size := c.get_combined_minimum_size()
		assert_true(min_size.x <= c.size.x + 0.5 and min_size.y <= c.size.y + 0.5,
			"%s: %s nicht abgeschnitten (min %s, ist %s)" % [label, c.name, min_size, c.size])
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			assert_false(overlaps(rect_of(buttons[i]), rect_of(buttons[j])),
				"%s: %s und %s überlappen" % [label, buttons[i].name, buttons[j].name])
	for c: Control in text_controls(root):
		if c is BaseButton:
			continue
		for b: BaseButton in buttons:
			if b.is_ancestor_of(c):
				continue
			assert_false(overlaps(rect_of(c), rect_of(b)), "%s: Text %s überdeckt %s" % [label, c.name, b.name])
