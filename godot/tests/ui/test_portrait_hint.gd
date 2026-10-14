extends UiTestCase
## Block H: Im Hochformat deckt der Hinweis „Bitte das Gerät drehen“ die Oberfläche; quer ist er weg, „Trotzdem weiter“ blendet ihn für die
## Sitzung aus und er blockiert danach keine Eingabe mehr.


func _hint(shell: Control) -> Control:
	return find_node(shell, "PortraitHint") as Control


func test_hint_follows_orientation_and_can_be_dismissed() -> void:
	var shell := await spawn_shell(Vector2i(412, 915))
	if shell == null:
		return
	var hint := _hint(shell)
	assert_true(hint != null and hint.visible, "Hochformat 412x915: Hinweis sichtbar")
	assert_eq(hint.mouse_filter, Control.MOUSE_FILTER_STOP, "Hinweis fängt Eingaben ab")
	await resize(Vector2i(1180, 820))
	await frames(2)
	assert_false(hint.visible, "Querformat 1180x820: kein Hinweis")
	await resize(Vector2i(412, 915))
	await frames(2)
	assert_true(hint.visible, "Zurück ins Hochformat: Hinweis wieder da")
	await press(find_button(hint, "PortraitContinueButton"))
	assert_false(hint.visible, "Trotzdem weiter blendet aus")
	await resize(Vector2i(1180, 820))
	await resize(Vector2i(412, 915))
	await frames(2)
	assert_false(hint.visible, "bleibt für die Sitzung ausgeblendet")


func test_hint_has_both_languages_and_never_shows_in_landscape() -> void:
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for key: String in ["ui.portrait.title", "ui.portrait.text", "ui.portrait.continue"]:
			assert_true(po.has(key) and str(po[key]) != "", "%s: %s" % [path.get_file(), key])
	var shell := await spawn_shell(Vector2i(1024, 768))
	if shell != null:
		assert_false(_hint(shell).visible, "Querformat: kein Hinweis")
