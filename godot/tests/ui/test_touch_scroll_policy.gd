extends UiTestCase
## Touch-Scrollen global: Knöpfe und Karten in einem ScrollContainer geben das Ziehen an den Container weiter
## (mouse_filter PASS) und der Container hat eine Totzone; Eingabefelder und Flächen außerhalb bleiben unverändert.


func _host() -> Control:
	var host := Control.new()
	tree.root.add_child(host)
	_spawned.append(host)
	var policy := TouchScrollPolicy.new()
	host.add_child(policy)
	await frames(2)
	return host


func test_controls_added_inside_a_scroll_container_pass_touch_drags_on() -> void:
	var host: Control = await _host()
	var scroll := ScrollContainer.new()
	host.add_child(scroll)
	var box := VBoxContainer.new()
	scroll.add_child(box)
	var button := Button.new()
	var card := PanelContainer.new()
	var field := LineEdit.new()
	box.add_child(button)
	box.add_child(card)
	box.add_child(field)
	var outside := Button.new()
	host.add_child(outside)
	assert_eq(scroll.scroll_deadzone, ThemeTokens.TOUCH_DRAG_DEADZONE, "Totzone gesetzt")
	assert_eq(button.mouse_filter, Control.MOUSE_FILTER_PASS, "Knopf reicht das Ziehen weiter")
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_PASS, "Karte reicht das Ziehen weiter")
	assert_eq(field.mouse_filter, Control.MOUSE_FILTER_STOP, "Eingabefeld behält seine Geste")
	assert_eq(outside.mouse_filter, Control.MOUSE_FILTER_STOP, "Knopf außerhalb bleibt unverändert")
