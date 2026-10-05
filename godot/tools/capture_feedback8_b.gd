extends SceneTree
## Screenshots Partiebericht (Feedback 8 Teil B), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_b.gd -- --out=<Ordner>
## Bilder: Liste, öffentlicher Bericht, Spielleiterbericht nach einer kurzen Partie. Druckt zusätzlich die Protokollsätze.
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
	var tmp := OS.get_temp_dir().path_join("grimmhain-cap8b")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	var players: Array = []
	var map := {}
	var names := ["Anna", "Bärbel", "Çelik", "Dörte", "Émile", "Fjörd"]
	var roles := ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]
	for i: int in roles.size():
		players.append({"id": i + 1, "name": names[i]})
		map[str(i + 1)] = roles[i]
	ctx.session.submit(Command.start_game({"round_id": "kurze-partie", "seed": 1, "assignment": "manual", "players": players,
		"seat_order": [1, 2, 3, 4, 5, 6], "roles": map}))
	ctx.session.start_night()
	ctx.session.answer_targets([3])
	ctx.session.end_night()
	ctx.session.nominate(1, 4)
	ctx.session.decide_execution(4)
	ctx.session.confirm_win(int(ctx.session.cockpit_view()["next"]["candidates"][0]["id"]))
	var state: GameState = StateCodec.decode(ctx.session.save_text()).state
	for l: String in LogText.lines(ctx.session.event_log(), state):
		print("protokoll: ", l)
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"history")
	await _fr(8)
	await _save("verlauf-liste")
	await _page("verlauf-liste-seite2")
	var list := shell.find_child("HistoryList", true, false)
	(list.get_child(0) as BaseButton).pressed.emit()
	await _fr(10)
	await _save("bericht-oeffentlich")
	await _page("bericht-oeffentlich-seite2")
	(shell.find_child("HistoryGmButton", true, false) as BaseButton).set_pressed(true)
	await _fr(6)
	(shell.find_child("ConfirmButton", true, false) as BaseButton).pressed.emit()
	await _fr(10)
	await _save("bericht-spielleitung")
	await _page("bericht-spielleitung-seite2")
	quit(0)


func _page(label: String) -> void:
	var next := shell.find_child("NextPageButton", true, false) as BaseButton
	if next == null or next.disabled:
		print("keine zweite Seite: ", label)
		return
	next.pressed.emit()
	await _save(label)


func _save(label: String) -> void:
	await _fr(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
