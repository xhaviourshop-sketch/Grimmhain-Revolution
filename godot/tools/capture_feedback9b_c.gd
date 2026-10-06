extends SceneTree
## Screenshots Feedback 9b, Teil C (Schutz in Mondblau), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback9b_c.gd -- --out=<Ordner>
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix", "Sophie",
	"Leopold", "Annabelle", "Bartholomäus", "Katharina", "Ben", "Elif", "Sami", "Nora", "Oskar", "Johanna", "Theodor", "Zoë"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _boot(8, "c9b-8")
	_ring().set_marks({3: ["protected"], 6: ["poisoned"], 2: ["marked"], 4: ["silenced"], 7: ["protected"]})
	await _save("schutz-ring")
	_ring().set_marks({3: ["protected"], 6: ["poisoned"], 2: ["lovers", "marked"], 1: ["lovers"], 4: ["silenced"], 5: ["protected", "poisoned"]})
	await _save("schutz-neben-anderen")
	quit(0)


func _ring() -> GameSeatRing:
	return shell.current_screen().find_child("SeatRing", true, false) as GameSeatRing


func _boot(n: int, round_id: String) -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	var tmp := OS.get_temp_dir().path_join("grimmhain-cap9bc")
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
	root.get_texture().get_image().save_png(OUT.path_join("%s-%dx%d.png" % [label, root.size.x, root.size.y]))
	print("bild ", label)
