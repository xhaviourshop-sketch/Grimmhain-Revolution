extends SceneTree
## Screenshots Feedback 8, Teil G (Vorbereitung), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_g.gd -- --out=<Ordner>
## Bilder: Schritt 1 mit Akt IV, Schritt 2 mit Namen, Schritt 3 Zuordnung mit 24 und mit 9 Personen (Echte Karten).
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgang", "Zoë"]
var OUT := "user://shots"


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _scene(24)
	await _scene(9)
	quit(0)


func _scene(count: int) -> void:
	var ctx := AppContext.new()
	ctx.settings.set_reduced_motion(false)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap8g")
	var shell := (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"new_game")
	await _fr(5)
	var setup := ctx.setup
	setup.set_player_count(count)
	setup.set_act(&"akt4" if count > 12 else &"akt2")
	setup.set_distribution_mode(&"manual")
	await _fr(30)
	if count > 12:
		await _shot("1-schritt1-akt4")
	var names: Array = NAMES.slice(0, count)
	setup.replace_persons(names)
	setup.go_to_step(&"names")
	await _fr(10)
	if count > 12:
		await _shot("2-schritt2-namen")
		(shell.find_child("PlateGrid", true, false).get_child(2) as NamePlate).pressed.emit()
		await _fr(5)
		await _shot("2b-schritt2-gewaehlt")
	setup.go_to_step(&"roles")
	await _fr(5)
	setup.apply_suggestion()
	await _fr(5)
	var tab := shell.find_child("AssignTab", true, false) as BaseButton
	tab.button_pressed = true
	await _fr(10)
	var view: Dictionary = setup.view()
	var ids: Array = (view["distribution"]["assignment"] as Array).map(func(p: Dictionary) -> int: return int(p["person_id"]))
	for i: int in mini(4, ids.size()):
		var units: Array = setup.view()["distribution"]["remaining_units"]
		if units.is_empty():
			break
		setup.assign_role(ids[i], StringName(str(units[0]["unit"])))
	await _shot("3-schritt3-%d" % count)
	shell.queue_free()
	await _fr(3)


func _shot(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
