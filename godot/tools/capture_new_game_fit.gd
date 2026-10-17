extends SceneTree
## Misst in „Neue Partie“, ob Akt-Schritt und Rollenschritt (Classic, 8 Personen) ohne Scrollen passen, und legt Screenshots ab.
## Braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_new_game_fit.gd -- --out=<Ordner> [--size=1180x820] [--lang=en]
## Ausgabe je Fläche: "UEBERHANG <Name> <px>" (0 = passt). Überhang = Inhaltshöhe minus sichtbare Höhe der Scrollfläche.
var OUT := "user://shots"
var SIZE := Vector2i(1024, 768)
var LANG := "de"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia"]


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
	var tmp := OS.get_temp_dir().path_join("grimmhain-capng")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"new_game")
	await _fr(8)
	ctx.setup.replace_persons(NAMES)
	ctx.setup.set_act(&"classic")
	await _fr(8)
	_overhang("RoundScroll")
	await _shot("akt")
	ctx.setup.go_to_step(&"roles")
	await _fr(10)
	_overhang("PoolScroll")
	await _shot("rollen")
	quit(0)


func _overhang(node_name: String) -> void:
	var scroll := shell.current_screen().find_child(node_name, true, false) as ScrollContainer
	if scroll == null or not scroll.is_visible_in_tree():
		print("UEBERHANG %s FEHLT" % node_name)
		return
	var content := scroll.get_child(0) as Control
	print("UEBERHANG %s %d (Inhalt %d, sichtbar %d)" % [node_name, maxi(0, int(ceil(content.size.y - scroll.size.y))), int(content.size.y), int(scroll.size.y)])


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("neue-partie-%s-%dx%d-%s.png" % [tag, SIZE.x, SIZE.y, LANG]))


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame
	await RenderingServer.frame_post_draw
