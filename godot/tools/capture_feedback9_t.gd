extends SceneTree
## Screenshots Feedback 9, Teil T (Eingabefelder, Tooltip, Trennlinie, Würfel), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback9_t.gd -- --out=<Ordner>
var OUT := "user://shots"
var shell: AppShell
var ctx: AppContext
var step: NamesStep


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap9t")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"new_game")
	await _fr(5)
	ctx.setup.set_player_count(8)
	ctx.setup.go_to_step(&"names")
	await _fr(10)
	step = _find_step()
	var input := shell.find_child("NameInput", true, false) as LineEdit
	await _fr(5)
	await _shot("1-namen-leer")
	input.text = "Marlene"
	input.text_changed.emit("Marlene")
	input.grab_focus()
	await _shot("2-namen-text-fokus")
	step.call("_on_import_toggle")
	await _fr(5)
	(shell.find_child("ImportText", true, false) as TextEdit).text = "Anna\nTom\nLena"
	await _shot("3-namen-einfuegen")
	step.call("_on_import_confirm")
	await _fr(5)
	await _shot("4-namen-pruefkarte")
	step.call("_on_import_cancel")
	ctx.setup.replace_persons(["Anna", "Tom", "Lena", "Paul"])
	await _fr(5)
	(shell.find_child("PlateGrid", true, false).get_child(1) as NamePlate).pressed.emit()
	await _fr(3)
	step.call("_on_edit_requested")
	await _shot("5-namen-aendern")
	step.call("_set_mode", 0)
	await _fr(3)
	(step.get("_group_actions") as GroupActions).request_save()
	await _fr(10)
	await _shot("6-gruppe-speichern")
	shell.get_dialog().cancel()
	await _fr(5)
	var probe := Control.new()
	probe.theme = ThemeFactory.build()
	probe.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(probe)
	var bg := ColorRect.new()
	bg.color = ThemeTokens.NIGHT_BACKDROP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	probe.add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(80, 60)
	col.size = Vector2(860, 600)
	probe.add_child(col)
	var tip := PanelContainer.new()
	tip.theme_type_variation = &"TooltipPanel"
	var tl := Label.new()
	tl.theme_type_variation = &"TooltipLabel"
	tl.text = "Hinweis zum Würfel"
	tip.add_child(tl)
	tip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(tip)
	col.add_child(HSeparator.new())
	var dice := DiceRow.new()
	dice.show_dice([3, 5, 6])
	col.add_child(dice)
	col.add_child(HSeparator.new())
	var le := LineEdit.new()
	le.placeholder_text = "Leeres Feld"
	col.add_child(le)
	await _shot("7-tooltip-trennlinie-wuerfel")
	quit(0)


func _find_step() -> NamesStep:
	for n: Node in shell.find_children("*", "Control", true, false):
		if n is NamesStep:
			return n as NamesStep
	return null


func _shot(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
