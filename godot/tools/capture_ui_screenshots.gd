extends SceneTree
## Erzeugt Prüf-Screenshots der UI-Grundlage (keine Produktionsassets).
## Braucht einen echten Renderer; headless gibt es keine Bildausgabe. In der Cloud/CI:
##   xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- --out=<Ordner>
## Ohne --out landen die Bilder in docs/evidence/ui-foundation/ (Repo-Wurzel).
## Jede Aufnahme: logische Größe = Fenstergröße (ohne Skalierung), reduzierte Bewegung an,
## damit kein Übergang mitten im Bild steht. Tastaturfokus ist wie in der App sichtbar.

const MAIN_SCENE := "res://app/main.tscn"
const SHOTS := [
	["01-start-1024x768-de.png", Vector2i(1024, 768), "de", &"start"],
	["02-main-menu-1024x768-de.png", Vector2i(1024, 768), "de", &"main_menu"],
	["03-cockpit-1024x768-de.png", Vector2i(1024, 768), "de", &"cockpit"],
	["04-main-menu-1280x800-en.png", Vector2i(1280, 800), "en", &"main_menu"],
	["05-settings-1280x800-de.png", Vector2i(1280, 800), "de", &"settings"],
]


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Screenshots brauchen einen Renderer (z. B. xvfb-run), headless ist keine Bildausgabe möglich.")
		quit(2)
		return
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../docs/evidence/ui-foundation").simplify_path()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var failures := 0
	for shot: Array in SHOTS:
		var ok: bool = await _capture(out_dir.path_join(shot[0]), shot[1], shot[2], shot[3])
		if not ok:
			failures += 1
	print("%d Screenshots, %d Fehler, Ordner %s" % [SHOTS.size(), failures, out_dir])
	quit(0 if failures == 0 else 1)


func _capture(path: String, size: Vector2i, locale: String, screen: StringName) -> bool:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for attempt: int in 20:
		root.size = size
		await process_frame
		if root.get_visible_rect().size == Vector2(size):
			break
	var context := AppContext.new()
	context.settings.set_reduced_motion(true)
	context.settings.set_language(locale)
	var shell := (load(MAIN_SCENE) as PackedScene).instantiate() as AppShell
	shell.app_context = context
	root.add_child(shell)
	shell.navigate(screen)
	for i: int in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var ok := image != null and image.get_size() == size
	if ok:
		ok = image.save_png(path) == OK
	print("%s  %s  %s %s" % ["ok  " if ok else "FAIL", path.get_file(), size, image.get_size() if image != null else "kein Bild"])
	root.remove_child(shell)
	shell.free()
	return ok
