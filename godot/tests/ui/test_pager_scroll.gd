extends UiTestCase
## Block F: Listen, deren Seite höher wird als der Platz, scrollen; die letzte Zeile ist erreichbar und ganz sichtbar.
## Prüft die Rollenübersicht der Spielleitung mit 9 und 20 Personen in Handy- und Tablet-Größen (Seitenhöhe zu knapp geschätzt).

const SIZES: Array[Vector2i] = [Vector2i(412, 915), Vector2i(768, 1024), Vector2i(1180, 820)]


func _seats(count: int) -> Array:
	var out: Array = []
	for i: int in count:
		out.append({"person_id": i + 1, "seat": i + 1, "name": "Spieler %d mit langem Namen" % (i + 1), "alive": true, "role_id": "werwolf",
			"faction": "wolves", "notes": [{"key": "ui.cockpit.private.warning", "role_id": ""}]})
	return out


func _check(count: int, size: Vector2i) -> void:
	await resize(size)
	var drawer := CockpitLayers.private_drawer(_seats(count))
	tree.root.add_child(drawer)
	_spawned.append(drawer)
	await frames(4)
	var scroll := find_node(drawer, "PageScroll") as ScrollContainer
	assert_true(scroll != null, "Scrollbereich vorhanden (%d Personen, %s)" % [count, size])
	if scroll == null:
		return
	var panel := find_node(drawer, "Drawer")
	assert_true(panel.get_global_rect().end.y <= float(size.y) + 1.0, "Fenster höher als der Bildschirm (%d, %s)" % [count, size])
	var body := find_node(drawer, "PageBody") as Control
	var overflow: bool = body.get_combined_minimum_size().y > scroll.size.y + 1.0
	if overflow:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await frames(2)
	var last: Control = body.get_child(body.get_child_count() - 1)
	var window: Rect2 = scroll.get_global_rect()
	assert_true(last.get_global_rect().end.y <= window.end.y + 1.0 and last.get_global_rect().position.y >= window.position.y - 1.0,
		"letzte Zeile ganz sichtbar (%d Personen, %s, scrollt: %s)" % [count, size, overflow])


func test_private_list_last_row_reachable() -> void:
	for size: Vector2i in SIZES:
		for count: int in [9, 20]:
			await _check(count, size)
