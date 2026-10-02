extends SceneTree
## Spielt eine Nacht auf dem Nachtbrett (P3) mit den echten Bedienelementen durch und speichert Screenshots (Entwicklungswerkzeug,
## keine Produktionsassets). Braucht einen echten Renderer, headless gibt es keine Bildausgabe:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy -s res://tools/capture_p3_night.gd -- \
##     --out=<Ordner> [--players=24] [--size=1024x768] [--locale=de] [--prefix=n24] [--shots=all|start] [--motion] [--hold=<Frames>]
## Die Partie startet über die Testfixtures (feste Rollen, fester Seed); jede Handlung läuft danach über die Knöpfe der Karte und
## das Antippen der Porträtplätze, nie über Befehle der Anwendungsschicht. Für die Prüfung der Sichtbarkeit zusätzlich ein Bild mit
## „Verbergen“ und eines mit gestartetem Timer.

const MAIN_SCENE := "res://app/main.tscn"
const FIXTURES := "res://tests/fixtures.gd"
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin-Maximilian", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wolfgangamadeus", "Zoë"]

var _out: String = ""
var _prefix: String = "n"
var _hold: int = 0  ## --hold=N: nach dem ersten Bild N Frames ruhig weiterlaufen und beenden (für Movie Maker)
var _motion: bool = false  ## --motion: Fensterschein und Nebel laufen (sonst stehen sie wie bei reduzierter Bewegung)
var _size := Vector2i(1024, 768)
var _shell: AppShell = null
var _context: AppContext = null
var _log: Array[String] = []


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Screenshots brauchen einen Renderer, headless ist keine Bildausgabe möglich.")
		quit(2)
		return
	var players := 24
	var locale := "de"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--players="):
			players = int(arg.trim_prefix("--players="))
		elif arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			_size = Vector2i(int(parts[0]), int(parts[1]))
		elif arg.begins_with("--locale="):
			locale = arg.trim_prefix("--locale=")
		elif arg.begins_with("--prefix="):
			_prefix = arg.trim_prefix("--prefix=")
		elif arg.begins_with("--hold="):
			_hold = int(arg.trim_prefix("--hold="))
		elif arg == "--motion":
			_motion = true
	if _out == "":
		printerr("--out=<Ordner> fehlt")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	var ok: bool = await _run(players, locale)
	for line: String in _log:
		print(line)
	quit(0 if ok else 1)


func _run(players: int, locale: String) -> bool:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for attempt: int in 20:
		root.size = _size
		await process_frame
		if root.get_visible_rect().size == Vector2(_size):
			break
	_context = AppContext.new()
	_context.settings.set_reduced_motion(not _motion)
	_context.settings.set_language(locale)
	_context.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-p3-capture")
	_shell = (load(MAIN_SCENE) as PackedScene).instantiate() as AppShell
	_shell.app_context = _context
	root.add_child(_shell)
	_shell.navigate(&"main_menu")
	_shell.navigate(&"cockpit")
	await _frames(4)
	var fixtures: GDScript = load(FIXTURES) as GDScript
	var roles: Array = fixtures.call("unique_roles", players)
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in players:
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var started: CommandResult = _context.session.submit(Command.start_game({"round_id": "p3-capture", "seed": 1, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not started.ok:
		_log.append("FAIL Start: %s" % started.error)
		return false
	await _frames(6)
	await _shot("01-vor-der-nacht")
	if _hold > 0:
		await _frames(_hold)
		return true
	var screen := _shell.current_screen()
	var steps := 0
	var shots := {"begin": false, "target": false, "chosen": false, "hidden": false, "timer": false}
	while steps < 250:
		steps += 1
		var next: Dictionary = (_context.session.cockpit_view() as Dictionary).get("next", {})
		var kind := str(next.get("kind", ""))
		if kind == "day" or kind == "card_window" or kind == "game_over" or kind == "win_decision":
			break
		if kind == "begin_step" and not shots["begin"]:
			shots["begin"] = true
			await _shot("02-rollenschritt")
		if kind == "prompt" and str(next.get("answer")) == "targets" and not shots["target"]:
			shots["target"] = true
			await _shot("03-zielwahl")
			await _select_targets(screen, next)
			await _shot("04-ziel-gewaehlt")
			shots["chosen"] = true
			var hide := screen.find_child("HideButton", true, false) as BaseButton
			hide.button_pressed = true
			await _frames(4)
			await _shot("05-verbergen")
			hide.button_pressed = false
			await _frames(4)
			await _set_timer(screen)
			await _shot("06-timer-laeuft")
		elif kind == "prompt" and str(next.get("answer")) == "targets":
			await _select_targets(screen, next)
		if not await _advance(screen):
			_log.append("FAIL: keine Aktion für %s" % kind)
			await _shot("fehler-%s" % kind)
			return false
	await _shot("07-nacht-ende")
	_log.append("ok: %d Schritte, Phase %s" % [steps, str((_context.session.cockpit_view() as Dictionary).get("phase"))])
	return true


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(label: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := _out.path_join("%s-%s-%dx%d.png" % [_prefix, label, _size.x, _size.y])
	image.save_png(path)
	_log.append("bild  %s" % path.get_file())


func _select_targets(screen: Node, next: Dictionary) -> void:
	var ring := screen.find_child("SeatRing", true, false) as GameSeatRing
	var allowed: Array = next.get("allowed_ids", [])
	var counts: Array = next.get("counts", [])
	var want := 1
	for c: Variant in counts:
		if int(c) > 0:
			want = int(c)
			break
	for id: Variant in allowed.slice(0, want):
		var token := ring.token_for(int(id))
		if token != null and not token.disabled:
			token.pressed.emit()
			await _frames(2)


## Drückt die Hauptaktion der Karte (Dock), sonst die erste freie Aktion.
func _advance(screen: Node) -> bool:
	var card := screen.find_child("ActionCard", true, false) as ActionCard
	var button := card.primary_button() as BaseButton
	if button == null or button.disabled:
		button = null
		for b: BaseButton in card.action_buttons():
			if not b.disabled and b.name != &"CancelPromptButton" and b.name != &"SkipStepButton":
				button = b
				break
	if button == null:
		return false
	button.pressed.emit()
	await _frames(4)
	return true


func _set_timer(screen: Node) -> void:
	var plus := screen.find_child("TimerNightPlusFiveButton", true, false) as BaseButton
	if plus != null:
		plus.pressed.emit()
		await _frames(2)
	var timer_button := screen.find_child("TimerButton", true, false) as BaseButton
	timer_button.pressed.emit()
	await _frames(30)
