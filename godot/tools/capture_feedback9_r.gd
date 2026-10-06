extends SceneTree
## Screenshots Feedback 9, Teil R (Sitzring), 1024x768 (24 Personen auch 1280x800), braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback9_r.gd -- --out=<Ordner>
## Bilder: Ring mit 8, 16 und 24 Personen (Nacht, lange Namen), Liebende und Rivalen am Ring, voller Name bei aufliegendem Finger,
## Tag mit Nominierung. Druckt je Ring die kleinste Schriftgröße und die Zahl gekürzter Namen.
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix", "Sophie",
	"Leopold", "Annabelle", "Bartholomäus", "Katharina", "Ben", "Elif", "Sami", "Nora", "Oskar", "Johanna", "Theodor", "Zoë"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	for n: int in [8, 16, 24]:
		await _boot(n, "r9-%d" % n)
		_report(n)
		await _save("ring-%d" % n)
		if n == 8:
			_ring().set_marks({1: ["lovers"], 4: ["lovers"], 2: ["rivals"], 6: ["rivals"]})
			await _save("bund-liebende-rivalen")
			_ring().set_marks({6: ["poisoned"], 3: ["marked"], 2: ["lovers", "poisoned"]})
			await _save("weitere-markierungen")
		if n == 24:
			var token := _ring().token_for(1)
			token.set_full_name_shown(true)
			await _save("voller-name-gedrueckt")
			token.set_full_name_shown(false)
			_ring().set_marks({1: ["lovers"], 14: ["lovers"], 2: ["rivals"], 3: ["rivals"], 12: ["rivals"]})
			await _save("bund-24")
	root.size = Vector2i(1280, 800)
	await _boot(24, "r9-24w")
	_report(24)
	await _save("ring-24")
	root.size = Vector2i(1024, 768)
	await _nominated()
	quit(0)


func _ring() -> GameSeatRing:
	return shell.current_screen().find_child("SeatRing", true, false) as GameSeatRing


func _report(n: int) -> void:
	var cut := 0
	for t: GameSeatToken in _ring().tokens():
		if t.is_name_truncated():
			cut += 1
	print("ring %d: Schrift %d px, gekuerzt %d von %d" % [n, GameSeatToken.PLATE_FONT_SIZE, cut, n])


func _boot(n: int, round_id: String) -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	var tmp := OS.get_temp_dir().path_join("grimmhain-cap9r")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(4)
	var fixtures: GDScript = load("res://tests/fixtures.gd") as GDScript
	var roles: Array = fixtures.call("unique_roles", n)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in n:
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": round_id, "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	await _fr(10)


func _nominated() -> void:
	await _boot(8, "r9-tag")
	ctx.session.start_night()
	var game: GDScript = load("res://tests/ui/ui_game.gd")
	game.call("to_day", ctx.session)
	shell.navigate(&"cockpit")
	await _fr(15)
	var cont := shell.find_child("ContinueDayButton", true, false) as BaseButton
	if cont != null:
		cont.pressed.emit()
		await _fr(10)
	var nominated: CommandResult = ctx.session.nominate(3, 1)
	if not nominated.ok:
		printerr("Nominierung abgelehnt: ", nominated.error)
	await create_timer(3.5).timeout
	await _fr(10)
	await _save("tag-nominiert")


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-%dx%d.png" % [label, root.size.x, root.size.y]))
	print("bild ", label)
