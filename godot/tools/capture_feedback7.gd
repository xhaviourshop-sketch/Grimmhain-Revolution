extends SceneTree
## Screenshots der Rollen-Vorschau (Feedback 7), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback7.gd -- --out=<Ordner>
## Bilder: Rollenliste, Vorschau Loki (alle Bildschirme), Vorschau Kriegerin mit Sonderfall.
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap7")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"settings")
	await _fr(6)
	await _save("einstellungen-rollen-vorschau")
	(shell.find_child("RolePreviewButton", true, false) as BaseButton).pressed.emit()
	await _fr(10)
	var screen := shell.current_screen() as RolePreviewScreen
	await _save("rollenliste")
	var scroll := screen.find_child("ListScroll", true, false) as ScrollContainer
	scroll.scroll_vertical = 100000
	await _fr(6)
	await _save("rollenliste-ende")
	await _role(screen, "loki", "vorschau-loki", false)
	await _role(screen, "kriegerin-des-lichts", "vorschau-kriegerin", true)
	quit(0)


func _role(screen: RolePreviewScreen, role: String, label: String, special: bool) -> void:
	(screen.find_child("PreviewRole_%s" % role, true, false) as BaseButton).pressed.emit()
	await _fr(10)
	for i: int in screen.stop_count():
		await _fr(20)
		await _save("%s-%d" % [label, i + 1])
		(screen.find_child("PreviewNext", true, false) as BaseButton).pressed.emit()
	if special:
		(screen.find_child("PreviewSpecial", true, false) as BaseButton).pressed.emit()
		await _fr(25)
		await _save("%s-sonderfall" % label)
	(screen.find_child("PreviewList", true, false) as BaseButton).pressed.emit()
	await _fr(6)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)
