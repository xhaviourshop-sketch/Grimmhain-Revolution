extends SceneTree
## Screenshots Feedback 8, Teil D (Ring), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_d.gd -- --out=<Ordner>
## Bilder: Tag mit drei Nominierungsbändern (24 Personen), Nacht mit Liebenden und Rivalen, Tag mit verborgenen Abzeichen (6).
## Der Zustand wird nur für die Anzeige vorbereitet (Nominierungen, Bündnisse); die Ansicht liest ihn wie im Spiel.
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgang", "Zoë"]
var OUT := "user://shots"


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _scene(24, "tag-baender-24", true, false, true)
	await _scene(24, "nacht-bund-24", false, true, false)
	await _scene(6, "nacht-bund-6", false, true, false)
	await _scene(6, "tag-abzeichen-verborgen-6", true, true, false)
	quit(0)


func _scene(count: int, label: String, day: bool, bonds: bool, bands: bool) -> void:
	var ctx := AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap8d")
	var shell := (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	var fixtures: GDScript = load("res://tests/fixtures.gd") as GDScript
	var roles: Array = fixtures.call("unique_roles", count)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in count:
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var started: CommandResult = ctx.session.submit(Command.start_game({"round_id": "cap8d", "seed": 1, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not started.ok:
		printerr("Start abgelehnt: ", started.error)
		return
	if not day:
		ctx.session.start_night()
	var state: GameState = ctx.session.get("_state")
	if bonds:
		state.loki_pairs.append({"kind": "love", "a": 1, "b": 3, "ended": false})
		state.loki_pairs.append({"kind": "rival", "a": 2, "b": 4, "ended": false})
		state.pack_target_id = 5
	if day:
		state.phase = Phase.DAY
		state.night_number = 1
		state.day_number = 1
		state.day_step = Phase.DAY_NOMINATION
	if bands:
		for pair: Array in [[1, 13], [7, 20], [18, 4]]:
			var n := Nomination.new()
			n.nominator_id = pair[0]
			n.nominee_id = pair[1]
			n.day = 1
			state.nominations.append(n)
		var judge := Nomination.new()
		judge.nominator_id = 9
		judge.nominee_id = 23
		judge.day = 1
		judge.by_judge = true
		state.nominations.append(judge)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)
	shell.queue_free()
	await _fr(3)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
