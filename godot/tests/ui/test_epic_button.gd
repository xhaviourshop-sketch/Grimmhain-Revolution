extends UiTestCase
## Knopf-Typ „epic“ (nur „Eintreten“ und „Spiel beginnen“): Mindesthöhe 72, eigene Fläche statt Rahmen, kein rotes Rechteck-Glühen.

const UiGame := preload("res://tests/ui/ui_game.gd")


func _check(button: GrimmButton, what: String) -> void:
	assert_true(button != null, "%s: Knopf vorhanden" % what)
	if button == null:
		return
	assert_true(button.get_node_or_null("EpicFace") != null, "%s: epische Fläche" % what)
	assert_true(button.get_node_or_null("SelectionGlow") == null, "%s: kein Rechteck-Glühen" % what)
	assert_true(button.custom_minimum_size.y >= EpicButton.MIN_HEIGHT, "%s: Mindesthöhe %d" % [what, int(EpicButton.MIN_HEIGHT)])


func test_begin_game_and_enter_buttons_are_epic() -> void:
	var s := UiGame.session(["werwolf", "werwolf", "schutzengel", "das-orakel", "dorfbewohner", "dorfbewohner"])
	var card := ActionCard.new()
	tree.root.add_child(card)
	_spawned.append(card)
	card.render(UiGame.next_of(s), {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	_check(card.find_child("StartNightButton", true, false) as GrimmButton, "Spiel beginnen")
	var shell := await spawn_shell()
	if shell == null:
		return
	_check(find_button(current_screen(shell), "EnterButton"), "Eintreten")
