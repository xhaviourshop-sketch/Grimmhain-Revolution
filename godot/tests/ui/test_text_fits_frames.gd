extends UiTestCase
## Prüfskript Knöpfe und Rahmen (Markus 15.10.2026): Jeder sichtbare Knopf und jedes Textfeld passt mit seinem Text in den Rahmen-Innenraum
## (Breite und Höhe, nichts abgeschnitten), in Deutsch und Englisch bei 1024x768 und 1180x820. Der Rahmen wächst mit dem Text; die Schrift
## schrumpft nicht unter ihre Mindestgröße. Meldet jede Fundstelle mit Bildschirm, Größe, Sprache, Name, Text und Maß.

const SIZES: Array[Vector2i] = [Vector2i(1024, 768), Vector2i(1180, 820)]
const SCREENS: Array[StringName] = [&"main_menu", &"settings", &"new_game", &"continue", &"lexicon", &"rulebook", &"history"]
const ROLES := ["werwolf", "blutwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner", "amalia"]


## Fundstellen eines Bildschirms: Textbreite des längsten unteilbaren Worts (bzw. der ganzen Zeile ohne Umbruch) gegen den Innenraum, Zeilenzahl gegen Höhe.
func _misfits(root: Node, label: String) -> Array[String]:
	var out: Array[String] = []
	for c: Control in visible_controls(root):
		if c.size.x <= 1.0 or c.size.y <= 1.0:
			continue
		var text := text_of(c)
		if text == "" or not (c is Label or c is Button):
			continue
		var type := c.theme_type_variation if c.theme_type_variation != &"" else (&"Button" if c is Button else &"Label")
		if c.get_theme_color(&"font_color", type).a < 0.05:
			continue  # Text nur als Tooltip und Bedienungshilfe, gezeichnet wird ein Zeichen oder Bild (Randknöpfe, Schrittmedaillons)
		var font := c.get_theme_font(&"font", type)
		var font_size := c.get_theme_font_size(&"font_size", type)
		var wraps := (c is Label and (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF) or (c is Button and (c as Button).autowrap_mode != TextServer.AUTOWRAP_OFF)
		var inner_w := c.size.x
		var inner_h := c.size.y
		if c is Button:
			var box := c.get_theme_stylebox(&"normal")
			inner_w -= box.get_minimum_size().x
			inner_h -= box.get_minimum_size().y
		var need_w := 0.0
		if wraps:
			for word: String in text.replace("\n", " ").split(" "):
				need_w = maxf(need_w, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		else:
			need_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var path := "%s/%s" % [label, c.name]
		if need_w > inner_w + 0.5 and not (c is Label and (c as Label).text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING and false):
			out.append("%s \"%s\": Text %.0f breit, Innenraum %.0f" % [path, text.left(40), need_w, inner_w])
		var lines := (c as Label).get_line_count() if c is Label else 1
		if c is Label and (c as Label).get_visible_line_count() < lines:
			out.append("%s \"%s\": %d Zeilen, nur %d sichtbar" % [path, text.left(40), lines, (c as Label).get_visible_line_count()])
		elif c is Button and not wraps and font.get_height(font_size) > inner_h + 0.5:
			out.append("%s \"%s\": Schrift %.0f hoch, Innenraum %.0f" % [path, text.left(40), font.get_height(font_size), inner_h])
	return out


func _start_game(shell: Control) -> void:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var r: CommandResult = session_of(shell).call("submit", Command.start_game({"round_id": "r", "seed": 9, "assignment": "manual",
		"players": Fixtures.players(ROLES.size()), "seat_order": [2, 5, 1, 7, 3, 8, 4, 6], "roles": map}))
	assert_true(r.ok, "Start")


func test_all_buttons_and_labels_fit_their_frames() -> void:
	var findings: Array[String] = []
	for size: Vector2i in SIZES:
		for locale: String in ["de", "en"]:
			var shell := await spawn_shell(size, locale)
			if shell == null:
				return
			for id: StringName in SCREENS:
				await navigate(shell, id)
				findings.append_array(_misfits(current_screen(shell), "%s %dx%d %s" % [id, size.x, size.y, locale]))
			_start_game(shell)
			await navigate(shell, &"main_menu")
			await navigate(shell, &"cockpit")
			var screen := current_screen(shell)
			findings.append_array(_misfits(screen, "cockpit-start %dx%d %s" % [size.x, size.y, locale]))
			session_of(shell).call("start_night")
			await frames(10)
			findings.append_array(_misfits(screen, "cockpit-nacht %dx%d %s" % [size.x, size.y, locale]))
			for tool: String in ["LogButton", "OptionsButton"]:
				var b := find_node(screen, tool) as BaseButton
				if b != null and b.is_visible_in_tree() and not b.disabled:
					await press(b)
					await frames(8)
					findings.append_array(_misfits(screen, "cockpit-%s %dx%d %s" % [tool, size.x, size.y, locale]))
					var close := find_node(screen, "CloseLayerButton") as BaseButton
					if close != null and close.is_visible_in_tree():
						await press(close)
						await frames(4)
	var unique: Array[String] = []
	for f: String in findings:
		if not unique.has(f):
			unique.append(f)
	var report := OS.get_environment("FIT_REPORT")
	if report != "":
		var file := FileAccess.open(report, FileAccess.WRITE)
		file.store_string("
".join(unique))
	assert_true(unique.is_empty(), "%d Fundstellen, erste: %s" % [unique.size(), unique.slice(0, 5)])
