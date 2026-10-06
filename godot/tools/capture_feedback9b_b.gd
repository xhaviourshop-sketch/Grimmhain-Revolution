extends SceneTree
## Screenshots Feedback 9b, Teil B (Anklagen), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback9b_b.gd -- --out=<Ordner>
## Bilder: Tageskarte DE und EN im Startzustand, Anklage erfassen (von, an), Liste der Anklagen mit Verteidigungssatz, Protokoll.
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix"]
const ROLES := ["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _day("en")
	await _save("tageskarte-en")
	await _day("de")
	await _save("tageskarte-de")
	await _press("NominateButton")
	await _save("anklage-von-de")
	await _tap_seat(3)
	await _save("anklage-an-de")
	await _tap_seat(1)
	(shell.find_child("ConfirmNominationButton", true, false) as BaseButton).pressed.emit()
	await _fr(6)
	await _save("anklagen-liste-de")
	await _press("LogButton")
	await _save("protokoll-de")
	quit(0)


func _day(language: String) -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language(language)
	var tmp := OS.get_temp_dir().path_join("grimmhain-cap9bb")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	var map := {}
	var persons: Array = []
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": "cap9bb", "seed": 3, "assignment": "manual",
		"players": persons, "seat_order": [1, 2, 3, 4, 5, 6, 7, 8], "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	ctx.session.start_night()
	for i: int in 30:
		var next: Dictionary = ctx.session.cockpit_view()["next"]
		var kind := str(next["kind"])
		if kind == "day":
			break
		match kind:
			"begin_step":
				if bool(next.get("skippable", false)):
					ctx.session.skip_next_step("Aufnahme")
				else:
					ctx.session.begin_next_step()
			"prompt":
				ctx.session.skip_next_step("Aufnahme")
			"end_night":
				ctx.session.end_night()
			_:
				ctx.session.end_night()
	shell.navigate(&"cockpit")
	await _fr(10)
	var cont := shell.find_child("ContinueDayButton", true, false) as BaseButton
	if cont != null:
		cont.pressed.emit()
		await _fr(6)


func _press(node_name: String) -> void:
	var b := shell.find_child(node_name, true, false) as BaseButton
	if b == null:
		printerr("Knopf fehlt: ", node_name)
		return
	b.pressed.emit()
	await _fr(6)


func _tap_seat(id: int) -> void:
	var ring := shell.find_child("SeatRing", true, false)
	(ring.call("token_for", id) as BaseButton).pressed.emit()
	await _fr(6)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)
