extends SceneTree
## Screenshots Feedback 8, Teil F (Cockpit-Karten), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_f.gd -- --out=<Ordner>
## Bilder: Werwölfe (Nachtkarte mittig), Kriegerin (alle Stufen, Sonderfall mit Warnung), Loki Schritte 1 bis 5, Tag mit Nominierungsbändern
## (24 Personen), Hinrichtung, Timer. Der Zustand wird nur für die Anzeige vorbereitet; die Ansicht liest ihn wie im Spiel.
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgang", "Zoë"]
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _boot()
	shell.navigate(&"main_menu")
	shell.navigate(&"settings")
	await _fr(6)
	(shell.find_child("RolePreviewButton", true, false) as BaseButton).pressed.emit()
	await _fr(10)
	var screen := shell.current_screen() as RolePreviewScreen
	await _role(screen, "werwolf", "werwoelfe", false)
	await _role(screen, "kriegerin-des-lichts", "kriegerin", true)
	await _role(screen, "loki", "loki", false)
	shell.queue_free()
	await _fr(3)
	await _day("tag-baender-24", 24, false, false)
	await _day("hinrichtung", 24, true, false)
	await _day("timer", 6, false, true)
	quit(0)


func _boot() -> void:
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap8f")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)


func _role(screen: RolePreviewScreen, role: String, label: String, special: bool) -> void:
	(screen.find_child("PreviewRole_%s" % role, true, false) as BaseButton).pressed.emit()
	await _fr(10)
	for i: int in screen.stop_count():
		await _fr(20)
		await _save("%s-%d" % [label, i + 1])
		(screen.find_child("PreviewNext", true, false) as BaseButton).pressed.emit()
	if special:
		(screen.find_child("PreviewSpecial", true, false) as BaseButton).pressed.emit()
		await _fr(25)
		await _save("%s-sonderfall" % label)
	(screen.find_child("PreviewList", true, false) as BaseButton).pressed.emit()
	await _fr(6)


func _day(label: String, count: int, execute: bool, timer: bool) -> void:
	await _boot()
	var roles: Array = (load("res://tests/fixtures.gd") as GDScript).call("unique_roles", count)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in count:
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var started: CommandResult = ctx.session.submit(Command.start_game({"round_id": "cap8f", "seed": 1, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not started.ok:
		printerr("Start abgelehnt: ", started.error)
		return
	var state: GameState = ctx.session.get("_state")
	state.phase = Phase.DAY
	state.night_number = 1
	state.day_number = 1
	state.day_step = Phase.DAY_NOMINATION
	for pair: Array in ([[1, 13], [7, 20], [18, 4]] if count >= 20 else [[1, 3]]):
		var n := Nomination.new()
		n.nominator_id = pair[0]
		n.nominee_id = pair[1]
		n.day = 1
		state.nominations.append(n)
	if timer:
		ctx.timer.adjust_duration(&"day", 300)
		ctx.timer.toggle()
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(20)
	if execute:
		var cockpit := shell.current_screen()
		cockpit.call("_select_execution_target", 13)
		await _fr(20)
	await _save(label)
	shell.queue_free()
	await _fr(3)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)
