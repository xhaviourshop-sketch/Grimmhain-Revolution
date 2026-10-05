extends SceneTree
## Screenshots Feedback 8, Teil E (Cockpit-Fenster), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback8_e.gd -- --out=<Ordner>
## Bilder: Rollen zeigen (Liste mit 24 Personen, große Karte), Karte zeigen (Orakel, Spürhund Treffer und kein Treffer, Waldläufer,
## Kriegerin), Hinweiskarten Liebende und Rivalen, Protokoll, Schublade privat (6 und 24 Personen). Der Zustand entsteht über die
## Sitzung (Befehle wie im Spiel); die Ansicht liest ihn wie sonst.
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgang", "Zoë"]
const W := "werwolf"
const D := "dorfbewohner"
const FILL: Array = ["amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "schutzengel", "waldhexe"]
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell
var _ui_game: GDScript


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	_ui_game = load("res://tests/ui/ui_game.gd") as GDScript
	var unique: Array = (load("res://tests/fixtures.gd") as GDScript).call("unique_roles", 24)
	# Rollen zeigen
	await _scene("rollen-liste-24", unique, {}, Callable(), &"roles", 24)
	await _scene("rollen-karte", unique, {}, Callable(), &"roles", 24, "RolePerson_2")
	await _scene("rollen-liste-6", [D, W, "waldhexe"] + FILL.slice(0, 3), {}, Callable(), &"roles", 6)
	# Karte zeigen
	await _show("karte-orakel", ["das-orakel", W, D] + FILL, {"das-orakel/targets": [2]}, "das-orakel")
	await _show("karte-spuerhund-treffer", ["spuerhund", W, D] + FILL, {"spuerhund/targets": [2, 3, 4]}, "spuerhund")
	await _show("karte-spuerhund-kein-treffer", ["spuerhund", W, D] + FILL, {"spuerhund/targets": [3, 4, 5]}, "spuerhund")
	await _show("karte-waldlaeufer", ["waldlaeufer", W, W] + FILL, {}, "waldlaeufer")
	await _show("karte-kriegerin-treffer", ["kriegerin-des-lichts", W, D] + FILL, {"kriegerin-des-lichts/targets": [2]}, "kriegerin-des-lichts")
	await _show("karte-kriegerin-kein-wolf", ["kriegerin-des-lichts", W, D] + FILL, {"kriegerin-des-lichts/targets": [3]}, "kriegerin-des-lichts")
	# Hinweiskarten
	await _notice("hinweis-liebende", true)
	await _notice("hinweis-rivalen", false)
	# Protokoll und private Schublade
	var night: Callable = func(n: Dictionary) -> bool: return str(n.get("kind")) == "day"
	await _scene("protokoll", [W, "loki", D] + FILL, {}, night, &"log", 9)
	await _scene("protokoll-24", unique, {}, night, &"log", 24)
	await _scene("privat-6", [W, "loki", D] + FILL.slice(0, 3), {}, Callable(), &"private", 6)
	await _scene("privat-24", unique, {}, Callable(), &"private", 24)
	quit(0)


func _boot() -> void:
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap8e")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)


func _start(roles: Array, count: int) -> bool:
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in count:
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var started: CommandResult = ctx.session.submit(Command.start_game({"round_id": "cap8e", "seed": 3, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not started.ok:
		printerr("Start abgelehnt: ", started.error)
	return started.ok


func _scene(label: String, roles: Array, answers: Dictionary, stop: Callable, layer: StringName, count: int, tap: String = "") -> void:
	await _boot()
	if not _start(roles, count):
		return
	if ctx.session.start_night().ok and stop.is_valid():
		_ui_game.call("run_until", ctx.session, stop, answers)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(15)
	shell.current_screen().call("open_layer", layer)
	await _fr(10)
	if tap != "":
		(shell.find_child(tap, true, false) as BaseButton).pressed.emit()
		await _fr(10)
	await _save(label)
	shell.queue_free()
	await _fr(3)


## Karte zeigen: bis zur gezeigten Auskunft der Rolle spielen, dann die Karte öffnen.
func _show(label: String, roles: Array, answers: Dictionary, owner: String) -> void:
	await _boot()
	if not _start(roles, roles.size()):
		return
	ctx.session.start_night()
	var stop: Callable = func(n: Dictionary) -> bool: return str(n.get("kind")) == "prompt" and str(n.get("owner")) == owner and str(n.get("stage")) == "shown"
	if not _ui_game.call("run_until", ctx.session, stop, answers):
		printerr("Keine gezeigte Auskunft: ", label)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(15)
	shell.current_screen().call("open_layer", &"show")
	await _fr(10)
	await _save(label)
	shell.queue_free()
	await _fr(3)


func _notice(label: String, love: bool) -> void:
	await _boot()
	if not _start([W, "loki", D] + FILL, 9):
		return
	ctx.session.start_night()
	var stop: Callable = func(n: Dictionary) -> bool: return str(n.get("kind")) == "prompt" and str(n.get("owner")) == "loki"
	_ui_game.call("run_until", ctx.session, stop, {})
	ctx.session.answer_targets([3, 5])
	ctx.session.answer_choice(love)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(15)
	shell.current_screen().call("open_layer", &"notice")
	await _fr(10)
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
