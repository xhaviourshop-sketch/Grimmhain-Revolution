extends SceneTree
## Screenshots Feedback 11 (Kette K1): Spielstände-Liste mit einer laufenden und einer beendeten Partie, 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_k1.gd -- --out=<Ordner>
var OUT := "user://shots"
var many := 0  ## --many=N: N weitere laufende Partien (Platzprobe der Liste)
const NAMES := ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"]
const ROLES := ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
		elif a.begins_with("--many="):
			many = int(a.trim_prefix("--many="))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	var tmp := OS.get_temp_dir().path_join("grimmhain-capk1")
	var ctx := AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	_start(ctx, "k1-beendet")
	ctx.session.start_night()
	ctx.session.answer_targets([3])
	ctx.session.end_night()
	ctx.session.nominate(1, 4)
	ctx.session.decide_execution(4)
	var candidates: Array = ctx.session.cockpit_view()["next"]["candidates"]
	ctx.session.confirm_win(int(candidates[0]["id"]))
	await process_frame
	ctx.session.reset()
	for extra: int in many:
		ctx.session.reset()
		_start(ctx, "k1-weitere-%d" % extra)
		await process_frame
	ctx.session.reset()
	_start(ctx, "k1-laufend")
	ctx.session.start_night()
	var shell := (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	for i: int in 3:
		await process_frame
	shell.navigate(&"main_menu")
	shell.navigate(&"continue")
	for i: int in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("k1-liste-de-1024x768.png"))
	quit(0)


func _start(ctx: AppContext, round_id: String) -> void:
	var players: Array = []
	var map := {}
	for i: int in ROLES.size():
		players.append({"id": i + 1, "name": NAMES[i]})
		map[str(i + 1)] = ROLES[i]
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": round_id, "seed": 1, "assignment": "manual", "players": players,
		"seat_order": Fixtures.identity_order(ROLES.size()), "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
