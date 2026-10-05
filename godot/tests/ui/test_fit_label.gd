extends UiTestCase
## FitLabel (Feedback 8): Die Schrift schrumpft bei wenig Platz und wächst bei mehr Platz wieder, nie über `max_font_size`.


func test_font_grows_back_when_there_is_more_room() -> void:
	var host := Control.new()
	tree.root.add_child(host)
	var label := FitLabel.new()
	label.max_font_size = 48
	label.text_key = "ui.cockpit.roles.heading"  # „Rollen zeigen“
	host.add_child(label)
	label.size = Vector2(60, 60)
	await frames(2)
	var small := label.get_theme_font_size(&"font_size")
	assert_true(small < 48, "schmal: Schrift verkleinert (%d)" % small)
	label.size = Vector2(900, 60)
	await frames(2)
	assert_eq(label.get_theme_font_size(&"font_size"), 48, "breit: Schrift wieder auf die größte Größe")
	label.size = Vector2(60, 60)
	await frames(2)
	assert_eq(label.get_theme_font_size(&"font_size"), small, "wieder schmal: wieder klein")
	host.queue_free()
