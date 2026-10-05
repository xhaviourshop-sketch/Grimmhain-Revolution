extends SceneTree
## Screenshots der gemalten Oberfläche (Feedback 8, Teil A), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_a.gd -- --out=<Ordner>
## Bilder: Hauptmenü, Einstellungen (Schalter), Rückfrage-Fenster, neue Partie (Hauptknopf), Cockpit mit Schublade (Protokoll).
var OUT := "user://shots"
const FILL := ["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor", "werwolf"]
const NAMES := ["Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix"]
var ctx: AppContext
var shell: AppShell


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _boot(&"main_menu")
	await _save("hauptmenue")
	shell.navigate(&"settings")
	await _fr(8)
	await _save("einstellungen")
	shell.navigate(&"main_menu")
	await _fr(8)
	shell.get_dialog().open_request(DialogRequest.create("ui.dialog.quit.title", "ui.dialog.quit.message", "ui.dialog.quit.confirm", func() -> void: pass))
	await _fr(8)
	await _save("rueckfrage")
	shell.get_dialog().cancel()
	await _boot(&"new_game")
	await _save("neue-partie")
	await _boot(&"cockpit")
	await _start_game()
	await _fr(30)
	await _save("cockpit")
	(shell.find_child("LogButton", true, false) as BaseButton).pressed.emit()
	await _fr(12)
	await _save("schublade-protokoll")
	quit(0)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)


func _boot(screen: StringName) -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.setup.seed_source = func() -> int: return 20261005
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap8a")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	if screen != &"start":
		shell.navigate(&"main_menu")
	shell.navigate(screen)
	await _fr(8)


func _start_game() -> void:
	var fx: GDScript = load("res://tests/fixtures.gd") as GDScript
	var commands: Array = fx.call("start_with_copies", fx.call("legalize", FILL), 7, {})
	for c: Command in commands:
		if c.type == Command.START_GAME and c.payload.has("players"):
			var players: Array = c.payload["players"]
			for i: int in players.size():
				(players[i] as Dictionary)["name"] = NAMES[i % NAMES.size()]
		var r: CommandResult = ctx.session.submit(c)
		if not r.ok:
			print("start rejected ", r.error)
	await _fr(6)
