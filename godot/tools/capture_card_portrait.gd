extends SceneTree
## Screenshots der Karten hochkant (Karte links, Text und Knöpfe rechts), braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1180x820 -s res://tools/capture_card_portrait.gd -- --out=<Ordner> [--only=<Teil>] [--size=1180x820]
## Teile: zeigen (Waldläufer, Karte zeigen), hexe (Waldhexe, Opfer), seherin, rolle (Rollenanzeige einer Person).
var OUT := "user://shots"
var ONLY := ""
var SIZE := Vector2i(1180, 820)
const FILL := ["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor"]
const NAMES := ["Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix", "Emma", "Lukas"]
var ctx: AppContext
var shell: AppShell


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			ONLY = a.trim_prefix("--only=")
		elif a.begins_with("--size="):
			var p := a.trim_prefix("--size=").split("x")
			SIZE = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = SIZE
	await _fr(2)
	if _want("zeigen"):
		await _shown("waldlaeufer", "zeigen")
	if _want("hexe"):
		await _witch()
	if _want("das-orakel"):
		await _shown("das-orakel", "das-orakel")
	if _want("rolle"):
		await _role_card()
	quit(0)


func _want(group: String) -> bool:
	return ONLY == "" or group.contains(ONLY) or ONLY.contains(group)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-%dx%d.png" % [label, SIZE.x, SIZE.y]))
	print("bild ", label)


func _boot(screen: StringName, reduced: bool, calls: bool = false) -> Node:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(reduced)
	ctx.settings.set_language("de")
	ctx.settings.set_show_calls(calls)
	ctx.setup.seed_source = func() -> int: return 20260926
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap6")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	if screen != &"start":
		shell.navigate(&"main_menu")
	shell.navigate(screen)
	await _fr(6)
	return shell.current_screen()


func _start_game(roles: Array) -> void:
	var fx: GDScript = load("res://tests/fixtures.gd") as GDScript
	var commands: Array = fx.call("start_with_copies", fx.call("legalize", roles), 7, {})
	for c: Command in commands:
		if c.type == Command.START_GAME and c.payload.has("players"):
			var players: Array = c.payload["players"]
			for i: int in players.size():
				(players[i] as Dictionary)["name"] = NAMES[i % NAMES.size()]
		var r: CommandResult = ctx.session.submit(c)
		if not r.ok:
			print("start rejected ", r.error)
	await _fr(6)


## Spielt bis zur Karte der Rolle und drückt „Karte zeigen“.
func _shown(role: String, label: String, fill: Array = FILL) -> void:
	await _boot(&"cockpit", true)
	await _start_game(([role] + fill).slice(0, 8))
	var found := await _advance_until(func(n: Dictionary) -> bool:
		return str(n.get("kind")) == "prompt" and str(n.get("owner", "")) == role)
	if not found:
		print("FAIL ", label)
		return
	await _fr(20)
	(shell.find_child("ShowCardButton", true, false) as BaseButton).pressed.emit()
	await _fr(14)
	await _save("karte-hochkant-" + label)


## Waldhexe: wie `test_witch_card.gd`, die Wölfe wählen ein Opfer, dann „Karte zeigen“.
func _witch() -> void:
	var roles := ["werwolf", "trugbilderwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "kutscher"]
	var seats: Array[int] = [3, 1, 4, 7, 2, 6, 5]
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	var fx: GDScript = load("res://tests/fixtures.gd") as GDScript
	var players: Array = fx.call("players", roles.size())
	await _boot(&"cockpit", true)
	var start := Command.start_game({"round_id": "t", "seed": 11, "assignment": "manual", "players": players, "seat_order": seats, "roles": map,
		"appearances": {"2": "dorfbewohner"}})
	ctx.session.submit(start)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(8)
	var screen := shell.current_screen()
	(screen.find_child("StartNightButton", true, false) as BaseButton).pressed.emit()
	await _fr(8)
	var ring := screen.find_child("SeatRing", true, false) as GameSeatRing
	for seat: int in [7, 6]:
		ring.token_for(seat).pressed.emit()
		await _fr(3)
	await _fr(10)
	(screen.find_child("ShowCardButton", true, false) as BaseButton).pressed.emit()
	await _fr(14)
	await _save("karte-hochkant-hexe")


## Rollenanzeige: erste Person antippen.
func _role_card() -> void:
	var screen := await _boot(&"cockpit", true)
	await _start_game(["werwolf"] + FILL)
	(shell.find_child("RolesButton", true, false) as BaseButton).pressed.emit()
	await _fr(10)
	(shell.find_child("RolePerson_1", true, false) as BaseButton).pressed.emit()
	await _fr(14)
	await _save("karte-hochkant-rolle")


func _effective() -> Dictionary:
	var n: Dictionary = (ctx.session.cockpit_view() as Dictionary).get("next", {})
	if str(n.get("kind")) == "begin_step" and not (n.get("preview", {}) as Dictionary).is_empty():
		var pv: Dictionary = (n["preview"] as Dictionary).duplicate()
		pv["kind"] = "prompt"
		return pv
	return n


## Bedient die Oberfläche (Ziele wählen, Hauptknopf), bis `cond` auf die nächste Karte zutrifft.
func _advance_until(cond: Callable) -> bool:
	var screen := shell.current_screen()
	for step: int in 80:
		var n := _effective()
		var kind := str(n.get("kind"))
		if cond.call(n):
			return true
		if kind in ["day", "game_over", "win_decision"]:
			return false
		if kind == "prompt" and str(n.get("answer")) == "targets":
			var ring := screen.find_child("SeatRing", true, false) as GameSeatRing
			var ids: Array = n.get("allowed_ids", [])
			var want := 1
			for c: Variant in n.get("counts", []):
				if int(c) > 0:
					want = int(c)
					break
			var picks: Array = ids.slice(maxi(0, ids.size() - 2)) if str(n.get("owner")) in ["pack", "pack2"] else ids.slice(0, want)
			for id: Variant in picks:
				ring.token_for(int(id)).pressed.emit()
				await _fr(2)
			if CockpitText.auto_commit(n):
				await _fr(4)
				continue
			var confirm := screen.find_child("ConfirmTargetsButton", true, false) as BaseButton
			if confirm != null and not confirm.disabled:
				confirm.pressed.emit()
				await _fr(6)
				continue
		var showb := screen.find_child("ShowCardButton", true, false) as BaseButton
		if showb == null or not showb.is_visible_in_tree():
			showb = screen.find_child("ShowNoticeButton", true, false) as BaseButton
		if showb != null and showb.is_visible_in_tree() and not showb.disabled and (kind == "notice" or str(n.get("answer")) == "ack"):
			showb.pressed.emit()
			await _fr(8)
			var close_shown := shell.find_child("CloseLayerButton", true, false) as BaseButton
			if close_shown != null:
				close_shown.pressed.emit()
			await _fr(6)
			continue
		var card := screen.find_child("ActionCard", true, false) as ActionCard
		var b := card.primary_button() as BaseButton
		if kind == "begin_step":
			b = screen.find_child("BeginStepButton", true, false) as BaseButton
		if b == null or b.disabled:
			b = null
			for x: BaseButton in card.action_buttons():
				if not x.disabled and x.name != &"CancelPromptButton" and x.name != &"SkipStepButton":
					b = x
					break
		if b == null:
			for nm: String in ["BeginStepButton", "EndNightButton", "StartNightButton", "ShowNoticeButton"]:
				b = screen.find_child(nm, true, false) as BaseButton
				if b != null:
					break
		if b == null or b.disabled:
			await _fr(10)
			continue
		b.pressed.emit()
		await _fr(8)
	return false
