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
## [Gruppe, Datei, Größe, Sprache, Ansicht, Vorbereitung, skaliert]  (skaliert = Inhaltsskalierung der App wie auf dem Gerät: Basis 1024×768, Seitenverhältnis „expand“)
const SHOTS := [
	["ui-foundation", "01-start-1024x768-de.png", Vector2i(1024, 768), "de", &"start", "", false],
	["ui-foundation", "02-main-menu-1024x768-de.png", Vector2i(1024, 768), "de", &"main_menu", "", false],
	["ui-foundation", "03-cockpit-1024x768-de.png", Vector2i(1024, 768), "de", &"cockpit", "", false],
	["ui-foundation", "04-main-menu-1280x800-en.png", Vector2i(1280, 800), "en", &"main_menu", "", false],
	["ui-foundation", "05-settings-1280x800-de.png", Vector2i(1280, 800), "de", &"settings", "", false],
]
## Vorbereitung „Neue Partie“ (DA-89): jeder Schritt in beiden Modi, auf den Gerätegrößen 1024×768 und 2360×1640 (skaliert). Datei =
## <Nr>-<Schritt>-<Modus>-<Breite>x<Höhe>.png; Aufruf mit --only=prep und --out=<Ordner>.
const PREP_SIZES := [Vector2i(1024, 768), Vector2i(2360, 1640)]
const PREP_SHOTS := [
	["01-runde", "_prep_round_random", "zufaellig"], ["01-runde", "_prep_round_manual", "karten"],
	["02-namen", "_prep_names_random", "zufaellig"], ["02-namen", "_prep_names_manual", "karten"],
	["03-rollen", "_prep_roles_random", "zufaellig"], ["03-rollen", "_prep_roles_manual", "karten"],
	["03-rollen-zuordnung", "_prep_assign", "karten"], ["03-rollen-leiste", "_prep_bar", "karten"],
]
const SCREENSHOT_SEED := 20260926  ## fester Setup-Seed, damit die Bilder reproduzierbar sind


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
		var ok: bool = await _capture(path, shot[2], shot[3], shot[4], shot[5], shot[6])
		if not ok:
			failures += 1
	if only == "" or "prep".contains(only) or only.begins_with("prep"):
		for size: Vector2i in PREP_SIZES:
			for shot: Array in PREP_SHOTS:
				var path := out_root.path_join("prep").path_join("%s-%s-%dx%d.png" % [shot[0], shot[2], size.x, size.y])
				if only != "" and not path.contains(only):
					continue
				DirAccess.make_dir_recursive_absolute(path.get_base_dir())
				count += 1
				var ok: bool = await _capture(path, size, "de", &"new_game", shot[1], true)
				if not ok:
					failures += 1
	print("%d Screenshots, %d Fehler, Ordner %s" % [count, failures, out_root])
	quit(0 if failures == 0 else 1)


func _capture(path: String, size: Vector2i, locale: String, screen: StringName, prepare: String, scaled: bool = false) -> bool:
	var host: Node = root
	var view: Viewport = root
	var sub: SubViewport = null
	if scaled:
		# Wie auf dem Gerät (Basis 1024×768, Seitenverhältnis „expand“), aber in einem eigenen Bildspeicher der gewünschten Größe: so
		# hängt die Aufnahme nicht von der Größe des Fensters auf diesem Bildschirm ab.
		sub = SubViewport.new()
		sub.size = size
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var factor := minf(float(size.x) / 1024.0, float(size.y) / 768.0)
		sub.size_2d_override = Vector2i((Vector2(size) / factor).round())
		sub.size_2d_override_stretch = true
		root.add_child(sub)
		host = sub
		view = sub
	else:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		for attempt: int in 20:
			root.size = size
			await process_frame
			if root.get_visible_rect().size == Vector2(size):
				break
	var context := AppContext.new()
	context.settings.set_reduced_motion(true)
	context.settings.set_language(locale)
	context.setup.seed_source = func() -> int: return SCREENSHOT_SEED
	var shell := (load(MAIN_SCENE) as PackedScene).instantiate() as AppShell
	shell.app_context = context
	host.add_child(shell)
	if sub != null:
		await process_frame
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
	var image := view.get_texture().get_image()
	var ok := image != null and image.get_size() == size
	if ok:
		ok = image.save_png(path) == OK
	print("%s  %s  %s %s" % ["ok  " if ok else "FAIL", path.get_file(), size, image.get_size() if image != null else "kein Bild"])
	if view.gui_is_dragging():  # Aufnahme mitten im Ziehen: Ziehen beenden, Maustaste lösen
		view.gui_cancel_drag()
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		view.push_input(up)
	host.remove_child(shell)
	shell.free()
	if sub != null:
		root.remove_child(sub)
		sub.free()
	return ok


# --- Vorbereitung „Neue Partie“ (DA-89) --------------------------------------------------------------------

func _node(shell: AppShell, node_name: String) -> Node:
	return shell.current_screen().find_child(node_name, true, false)


func _press(shell: AppShell, node_name: String) -> void:
	var button := _node(shell, node_name) as BaseButton
	if button != null:
		if button.toggle_mode:
			button.button_pressed = not button.button_pressed
		else:
			button.pressed.emit()
	await process_frame
	await process_frame


## Tablet-Runde: 13 Personen, Akt III (enthält Trugbilderwolf und Totenreichkarten-Rolle), nur über echte Buttons und die Anwendungsschicht.
func _prep_names_filled(shell: AppShell, manual: bool) -> void:
	var setup := shell.get_app_context().setup
	if manual:
		await _press(shell, "ManualModeButton")
	while int(setup.view()["player_count"]) < 13:
		await _press(shell, "PlusButton")
	await _press(shell, "ActCard_akt3")


func _prep_round_random(shell: AppShell) -> void:
	await _prep_names_filled(shell, false)


func _prep_round_manual(shell: AppShell) -> void:
	await _prep_names_filled(shell, true)


const PREP_NAMES := ["Anna", "Ben", "Cara", "Dora", "Emil", "Finn", "Gerd", "Hanna", "Ida", "Jonas", "Klara", "Lukas"]


func _prep_names(shell: AppShell, manual: bool, complete: bool) -> void:
	await _prep_names_filled(shell, manual)
	await _press(shell, "NextButton")
	var setup := shell.get_app_context().setup
	for n: String in PREP_NAMES:
		setup.add_person(n)
	if complete:
		setup.add_person("Mia")
	await process_frame
	var plate := _node(shell, "NamePlate_3") as BaseButton
	if plate != null:
		plate.pressed.emit()
	await process_frame


func _prep_names_random(shell: AppShell) -> void:
	await _prep_names(shell, false, false)


func _prep_names_manual(shell: AppShell) -> void:
	await _prep_names(shell, true, false)


func _prep_roles(shell: AppShell, manual: bool) -> void:
	await _prep_names(shell, manual, true)
	await _press(shell, "NextButton")


func _prep_roles_random(shell: AppShell) -> void:
	await _prep_roles(shell, false)


func _prep_roles_manual(shell: AppShell) -> void:
	await _prep_roles(shell, true)


func _prep_assign(shell: AppShell) -> void:
	await _prep_roles(shell, true)
	await _press(shell, "NextButton")
	var setup := shell.get_app_context().setup
	var persons: Array = setup.view()["persons"]
	var units: Array[StringName] = []
	for entry: Dictionary in setup.view()["distribution"]["remaining_units"]:
		for i: int in int(entry["left"]):
			units.append(StringName(str(entry["unit"])))
	for i: int in 7:
		setup.assign_role(int(persons[i]["person_id"]), units[i])
	await process_frame


func _prep_bar(shell: AppShell) -> void:
	await _prep_assign(shell)
	var persons: Array = shell.get_app_context().setup.view()["persons"]
	var seat := _node(shell, "SeatRing").call("token_for", int(persons[9]["person_id"])) as BaseButton
	if seat != null:
		seat.pressed.emit()
	await process_frame
