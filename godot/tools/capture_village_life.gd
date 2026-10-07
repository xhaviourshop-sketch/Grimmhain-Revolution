extends SceneTree
## Screenshots lebendiges Dorf (1024x768, echter Renderer):
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_village_life.gd -- --out=<Ordner>
## Bilder: 1-nacht-ruhig, 2-nacht-wolf, 3-nacht-akt4, 4-tag. Wolfsschritt und Akt werden direkt an `NightAmbience` geschaltet.
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia", "Ida", "Jonas", "Klara", "Ben", "Eva", "Karl", "Nora", "Otto"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _boot(8, "amb-n")
	ctx.session.start_night()
	await _fr(10)
	await create_timer(3.0).timeout
	var amb: NightAmbience = shell.current_screen().get("_ambience")
	var life: VillageLife = amb._parts[2]
	life.spawn_flock_now()
	await create_timer(1.5).timeout
	await _save("5-nacht-schwarm")
	var game: GDScript = load("res://tests/ui/ui_game.gd")
	game.call("to_day", ctx.session)
	shell.navigate(&"cockpit")
	await create_timer(3.0).timeout
	await _save("6-tag-8")
	amb = shell.current_screen().get("_ambience")
	life = amb._parts[2]
	life.spawn_flock_now()
	await create_timer(1.4).timeout
	await _save("7-tag-kraehen")
	var shown := 0
	for f: VillageLife.Folk in life._folk:
		if f.fits:
			shown += 1
	print("gruppen 8: ", shown, " galgen: ", life._gallows.visible, " pos ", life._gallows.position, " scale ", life._gallows.scale)
	shell.queue_free()
	await _fr(3)
	await _boot(16, "amb-16")
	game.call("to_day", ctx.session)
	shell.navigate(&"cockpit")
	await create_timer(3.0).timeout
	await _save("8-tag-16")
	amb = shell.current_screen().get("_ambience")
	life = amb._parts[2]
	shown = 0
	for f: VillageLife.Folk in life._folk:
		if f.fits:
			shown += 1
	print("gruppen 16: ", shown, " galgen: ", life._gallows.visible)
	quit(0)


func _boot(n: int, round_id: String) -> void:
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(false)
	ctx.settings.set_language("de")
	var tmp := OS.get_temp_dir().path_join("grimmhain-capamb")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(4)
	var fixtures: GDScript = load("res://tests/fixtures.gd") as GDScript
	var roles: Array = fixtures.call("unique_roles", n)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in n:
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": round_id, "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	await _fr(10)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s.png" % label))
	print("bild ", label)
