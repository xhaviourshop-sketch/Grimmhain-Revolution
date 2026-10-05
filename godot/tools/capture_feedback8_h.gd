extends SceneTree
## Screenshots Feedback 8 Teil H (Rollen-Vorschau), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_h.gd -- --out=<Ordner>
## Bilder: Startbildschirm mit Sprachflaggen, Rollenliste (ganz), Vorschau Kriegerin Bildschirm 3, Loki Bildschirm 4.
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
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap8h")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(10)
	await _save("startbildschirm-flaggen")
	shell.navigate(&"settings")
	await _fr(6)
	(shell.find_child("RolePreviewButton", true, false) as BaseButton).pressed.emit()
	await _fr(10)
	var screen := shell.current_screen() as RolePreviewScreen
	await _save("rollenliste")
	var missing: Array[String] = []
	for r: StringName in SetupRoleCatalog.role_ids():
		if NightArt.texture("emblems/%s.png" % NightArt.image_key(String(r))) == null:
			missing.append(String(r))
	print("EMBLEM FEHLT: ", missing)
	await _role(screen, "kriegerin-des-lichts", "vorschau-kriegerin", 3)
	await _role(screen, "loki", "vorschau-loki", 4)
	quit(0)


func _role(screen: RolePreviewScreen, role: String, label: String, shot: int) -> void:
	(screen.find_child("PreviewRole_%s" % role, true, false) as BaseButton).pressed.emit()
	await _fr(10)
	for i: int in screen.stop_count():
		await _fr(20)
		if i + 1 == shot:
			await _save("%s-%d" % [label, shot])
			break
		(screen.find_child("PreviewNext", true, false) as BaseButton).pressed.emit()
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
