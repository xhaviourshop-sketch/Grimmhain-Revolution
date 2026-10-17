extends SceneTree
## Misst, ob das Optionenmenü des Cockpits (Lasche rechts) ganz im Bild liegt, und legt einen Screenshot ab.
## Braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_options_fit.gd -- --out=<Ordner> [--size=1180x820] [--lang=en]
## Ausgabe: "FENSTER ToolsMenu oben <y> unten <y> Bildhoehe <h> Ueberhang <px>" (0 = passt).
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
	var tmp := OS.get_temp_dir().path_join("grimmhain-capopt")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"cockpit")
	await _fr(4)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": "capopt", "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	await _fr(10)
	var tab := shell.current_screen().find_child("OptionsButton", true, false) as BaseButton
	tab.pressed.emit()
	await _fr(10)
	var menu := shell.current_screen().find_child("ToolsMenu", true, false) as Control
	var last := shell.current_screen().find_child("SettingsButton", true, false) as Control  # unterster Eintrag des Menüs
	var top := menu.get_global_rect().position.y
	var bottom := last.get_global_rect().end.y
	var h := float(menu.get_viewport_rect().size.y)
	print("FENSTER ToolsMenu oben %d letzter Knopf unten %d Bildhoehe %d Ueberhang %d" % [int(top), int(bottom), int(h), maxi(0, int(ceil(bottom - h)))])
	for c: Node in shell.current_screen().find_child("MenuColumn", true, false).get_children():
		var ctl := c as Control
		if ctl != null and ctl.visible:
			print("FENSTER   %s Mindesthoehe %d" % [ctl.name, int(ctl.get_combined_minimum_size().y)])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("optionen-%dx%d-%s.png" % [SIZE.x, SIZE.y, LANG]))
	quit(0)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
	await RenderingServer.frame_post_draw
