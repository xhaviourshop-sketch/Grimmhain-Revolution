extends SceneTree
## Screenshots des Knopfs „Rollen“/„Namen“ im Cockpit: Nacht und Tag, je mit Namen und mit Rollen (eine Person tot).
## Braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_seat_labels.gd -- --out=<Ordner> [--size=1180x820] [--lang=en]
const UiGame := preload("res://tests/ui/ui_game.gd")
var OUT := "user://shots"
var SIZE := Vector2i(1024, 768)
var LANG := "de"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia"]
const ROLES := ["werwolf", "blutwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "dorfbewohner", "amalia"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
		elif a.begins_with("--size="):
			var p := a.trim_prefix("--size=").split("x")
			SIZE = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--lang="):
			LANG = a.trim_prefix("--lang=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = SIZE
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language(LANG)
	var tmp := OS.get_temp_dir().path_join("grimmhain-capseat")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": "capseat", "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	ctx.session.gm_correction({"kind": "kill", "target_id": 7, "trigger_effects": false, "reason": "Aufnahme", "confirmed": true})
	shell.navigate(&"cockpit")
	await _fr(6)
	ctx.session.start_night()
	await _fr(10)
	await _shot("nacht-namen")
	await _toggle()
	await _shot("nacht-rollen")
	if not UiGame.to_day(ctx.session):
		printerr("Tag nicht erreicht")
	await _fr(10)
	var cont := shell.current_screen().find_child("ContinueDayButton", true, false) as BaseButton
	if cont != null and cont.is_visible_in_tree():
		cont.pressed.emit()
		await _fr(10)
	await _shot("tag-rollen")
	await _toggle()
	await _shot("tag-namen")
	quit(0)


func _toggle() -> void:
	(shell.current_screen().find_child("SeatLabelButton", true, false) as BaseButton).pressed.emit()
	await _fr(8)


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := OUT.path_join("%s-%dx%d-%s.png" % [label, SIZE.x, SIZE.y, LANG])
	root.get_texture().get_image().save_png(path)
	print("BILD ", path)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
	await RenderingServer.frame_post_draw
