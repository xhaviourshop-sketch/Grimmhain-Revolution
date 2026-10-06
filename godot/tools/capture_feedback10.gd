extends SceneTree
## Screenshots Feedback 10, 1024x768, Ring mit 24 Personen, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback10.gd -- --out=<Ordner> [--only=<Teil>]
## Teile: hound (Spürhund, Karte nach 1., 2., 3. Person), day (Tag ohne Tafel, Anklagen, Hinrichtung), role (Karte zeigen), piper (Rattenfänger).
var OUT := "user://shots"
var ONLY := ""
var ctx: AppContext
var shell: AppShell
const NAMES := ["Maximilian", "Friederike", "Konstantin", "Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix", "Sophie",
	"Leopold", "Annabelle", "Bartholomäus", "Katharina", "Ben", "Elif", "Sami", "Nora", "Oskar", "Johanna", "Theodor", "Zoë"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			ONLY = a.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	if ONLY in ["", "hound"]:
		await _hound()
	if ONLY in ["", "day"]:
		await _day()
	if ONLY in ["", "role"]:
		await _role()
	if ONLY in ["", "piper"]:
		await _piper()
	quit(0)


func _screen() -> Control:
	return shell.current_screen()


func _ring() -> GameSeatRing:
	return _screen().find_child("SeatRing", true, false) as GameSeatRing


func _tap(id: int) -> void:
	(_ring().token_for(id) as BaseButton).pressed.emit()
	await _fr(6)


func _press(node_name: String) -> bool:
	var b := _screen().find_child(node_name, true, false) as BaseButton
	if b == null or not b.is_visible_in_tree() or b.disabled:
		printerr("Knopf fehlt oder gesperrt: ", node_name)
		return false
	b.pressed.emit()
	await _fr(6)
	return true


func _boot(roles: Array, round_id: String) -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	var tmp := OS.get_temp_dir().path_join("grimmhain-cap10")
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
	var map := {}
	var persons: Array = []
	var order: Array[int] = []
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
		order.append(i + 1)
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": round_id, "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": order, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)
	await _fr(10)


func _roles24(replace: Dictionary = {}) -> Array:
	var roles: Array = Fixtures.unique_roles(24).duplicate()
	for i: int in roles.size():
		if replace.has(roles[i]):
			roles[i] = replace[roles[i]]
	return roles


func _next() -> Dictionary:
	return (ctx.session.cockpit_view() as Dictionary).get("next", {})


## Nachtschritte per Kernbefehl bis zur Karte `owner` (Aufgabe oder Schritt dieser Rolle); gibt false zurück, wenn sie nicht kommt.
func _to_prompt(owner: String) -> bool:
	var game: GDScript = load("res://tests/ui/ui_game.gd")
	ctx.session.start_night()
	for i: int in 120:
		var next := _next()
		var eff := next
		if str(next.get("kind")) == "begin_step" and not (next.get("preview", {}) as Dictionary).is_empty():
			eff = next.get("preview", {})
		if str(eff.get("owner", "")) == owner and (str(next.get("kind")) == "prompt" or str(next.get("kind")) == "begin_step"):
			if str(next.get("kind")) == "begin_step":
				ctx.session.begin_next_step()
			await _fr(10)
			return true
		if str(game.call("step", ctx.session)) == "":
			printerr("Weg zu %s abgebrochen bei %s" % [owner, JSON.stringify(next).left(200)])
			return false
	return false


func _hound() -> void:
	await _boot(_roles24({"doktor": "spuerhund"}), "f10-hound")
	if not await _to_prompt("spuerhund"):
		return
	shell.navigate(&"cockpit")
	await _fr(10)
	await _save("hound-0")
	for n: int in 3:
		await _tap(3 + n)
		await _save("hound-%d" % (n + 1))


func _day() -> void:
	await _boot(_roles24(), "f10-day")
	ctx.session.start_night()
	var game: GDScript = load("res://tests/ui/ui_game.gd")
	game.call("to_day", ctx.session)
	shell.navigate(&"cockpit")
	await _fr(15)
	await _press("ContinueDayButton")
	await _save("day-start")
	ctx.session.nominate(3, 1)
	ctx.session.nominate(5, 2)
	await _fr(10)
	await _save("day-nominated")
	await _press("NominateButton")
	await _save("day-nominate-from")
	await _tap(7)
	await _save("day-nominate-to-1")
	await _tap(8)
	await _save("day-nominate-to-2")
	await _press("CancelModeButton")
	await _press("ExecuteButton")
	await _save("execute-pick")
	await _tap(2)
	await _save("execute-check")


func _role() -> void:
	await _boot(_roles24(), "f10-role")
	if not await _to_prompt("das-orakel"):
		return
	shell.navigate(&"cockpit")
	await _fr(10)
	var next := _next()
	var allowed: Array = (next.get("allowed_ids", []) if str(next.get("kind")) == "prompt" else (next.get("preview", {}) as Dictionary).get("allowed_ids", []))
	await _tap(int(allowed[0]))
	await _save("role-prompt")
	if await _press("ShowCardButton"):
		await _save("karte-zeigen")


func _piper() -> void:
	await _boot(_roles24({"doktor": "rattenfaenger"}), "f10-piper")
	if not await _to_prompt("rattenfaenger"):
		return
	shell.navigate(&"cockpit")
	await _fr(10)
	var next := _next()
	var allowed: Array = next.get("allowed_ids", [])
	var count := int(((next.get("counts", [1]) as Array)[0]))
	for i: int in maxi(count, 1):
		await _tap(int(allowed[i]))
	var confirm := _screen().find_child("ConfirmTargetsButton", true, false) as BaseButton
	if confirm != null and not confirm.disabled:
		await _press("ConfirmTargetsButton")
	for i: int in 6:
		if str(_next().get("kind")) == "notice":
			break
		await _fr(5)
	if await _press("ShowNoticeButton"):
		await _save("rattenfaenger-hinweis")


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(40)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-%dx%d.png" % [label, root.size.x, root.size.y]))
	print("bild ", label)
