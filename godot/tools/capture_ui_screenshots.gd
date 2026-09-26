extends SceneTree
## Erzeugt Prüf-Screenshots der UI (keine Produktionsassets).
## Braucht einen echten Renderer; headless gibt es keine Bildausgabe. In der Cloud/CI:
##   xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- [--out=<Ordner>] [--only=<Teilstring>]
## Ohne --out landen die Bilder unter docs/evidence/<Gruppe>/ (Repo-Wurzel).
## Jede Aufnahme: logische Größe = Fenstergröße (ohne Skalierung), reduzierte Bewegung an,
## damit kein Übergang mitten im Bild steht. Tastaturfokus ist wie in der App sichtbar.
## Vorbereitung (`prepare`) nutzt nur öffentliche Wege: AppContext.setup und echte Buttons.

const MAIN_SCENE := "res://app/main.tscn"
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wim", "Zoë"]
## [Gruppe, Datei, Größe, Sprache, Ansicht, Vorbereitung]
const SHOTS := [
	["ui-foundation", "01-start-1024x768-de.png", Vector2i(1024, 768), "de", &"start", ""],
	["ui-foundation", "02-main-menu-1024x768-de.png", Vector2i(1024, 768), "de", &"main_menu", ""],
	["ui-foundation", "03-cockpit-1024x768-de.png", Vector2i(1024, 768), "de", &"cockpit", ""],
	["ui-foundation", "04-main-menu-1280x800-en.png", Vector2i(1280, 800), "en", &"main_menu", ""],
	["ui-foundation", "05-settings-1280x800-de.png", Vector2i(1280, 800), "de", &"settings", ""],
	["player-setup", "01-empty-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", ""],
	["player-setup", "02-six-players-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_six"],
	["player-setup", "03-24-players-scrolled-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_full_scrolled"],
	["player-setup", "04-import-open-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_import"],
	["player-setup", "05-duplicates-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_duplicates"],
	["player-setup", "06-edit-mode-1280x800-en.png", Vector2i(1280, 800), "en", &"new_game", "_prepare_edit"],
	["player-setup", "07-remove-dialog-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_remove"],
	["player-setup", "08-confirmed-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_confirmed"],
]


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Screenshots brauchen einen Renderer (z. B. xvfb-run), headless ist keine Bildausgabe möglich.")
		quit(2)
		return
	var out_root := ProjectSettings.globalize_path("res://").path_join("../docs/evidence").simplify_path()
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_root = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	var failures := 0
	var count := 0
	for shot: Array in SHOTS:
		var path := out_root.path_join(shot[0]).path_join(shot[1])
		if only != "" and not path.contains(only):
			continue
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		count += 1
		var ok: bool = await _capture(path, shot[2], shot[3], shot[4], shot[5])
		if not ok:
			failures += 1
	print("%d Screenshots, %d Fehler, Ordner %s" % [count, failures, out_root])
	quit(0 if failures == 0 else 1)


func _capture(path: String, size: Vector2i, locale: String, screen: StringName, prepare: String) -> bool:
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
	if screen != &"start" and screen != &"main_menu":
		shell.navigate(&"main_menu")
	shell.navigate(screen)
	for i: int in 4:
		await process_frame
	if prepare != "":
		await call(prepare, shell)
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



# --- Vorbereitungen Spieler-Setup --------------------------------------------------------------------

func _add_names(shell: AppShell, names: Array) -> void:
	for n: Variant in names:
		shell.get_app_context().setup.add_person(str(n))
	await process_frame


func _node(shell: AppShell, node_name: String) -> Node:
	return shell.current_screen().find_child(node_name, true, false)


func _rows(shell: AppShell) -> Array[PersonRow]:
	var out: Array[PersonRow] = []
	for child: Node in _node(shell, "PersonList").get_children():
		if child is PersonRow:
			out.append(child as PersonRow)
	return out


func _prepare_six(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 6))


func _prepare_full_scrolled(shell: AppShell) -> void:
	await _add_names(shell, NAMES)
	for i: int in 3:
		await process_frame
	var scroll := _node(shell, "PersonScroll") as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _prepare_import(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 4))
	(_node(shell, "ImportToggleButton") as Button).pressed.emit()
	var text := _node(shell, "ImportText") as TextEdit
	text.text = "Elif, Frieda; Gustav\nHanna\nIlja, Jana"
	text.text_changed.emit()


func _prepare_duplicates(shell: AppShell) -> void:
	await _add_names(shell, ["Anna", "Ben", "Clara", "anna", "Dimitri", "Ben ", "Elif", "Frieda"])


func _prepare_edit(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 8))
	_rows(shell)[2].edit_button().pressed.emit()
	await process_frame


func _prepare_remove(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 8))
	var remove := _rows(shell)[1].remove_button()
	remove.grab_focus()
	remove.pressed.emit()
	await process_frame


func _prepare_confirmed(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 8))
	(_node(shell, "ConfirmPlayersButton") as Button).pressed.emit()
	await process_frame
