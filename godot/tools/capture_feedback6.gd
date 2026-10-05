extends SceneTree
## Screenshots der Mini-Nachtkarte (Feedback 6, DA-101), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback6.gd -- --out=<Ordner> [--only=<Teil>]
## Teile: feuer (Akt IV Geisterfeuer), werwolf, kriegerin (ohne und mit Warnung), waldlaeufer (Karte und Ergebnis), loki, ansagen.
## Die Warnung der Kriegerin entsteht aus einem echten Kernzustand: zwei wählbare Personen werden als Liebende eingetragen (nur in dieser
## Wegwerf-Partie, nichts wird gespeichert).
var OUT := "user://shots"
var ONLY := ""
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
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _fr(2)
	if _want("feuer"):
		await _fire()
	if _want("werwolf"):
		await _night("werwolf", "werwoelfe", ["werwolf", "dorfbewohner", "amalia", "detektiv", "doktor", "waechter-am-tor", "werwolf", "dorfbewohner"])
	if _want("kriegerin"):
		await _night("kriegerin-des-lichts", "kriegerin-ohne-warnung", ["kriegerin-des-lichts"] + FILL)
		await _night("kriegerin-des-lichts", "kriegerin-mit-warnung", ["kriegerin-des-lichts"] + FILL, false, true)
	if _want("waldlaeufer"):
		await _ranger()
	if _want("loki"):
		await _night("loki", "loki", ["loki"] + FILL)
	if _want("ansagen"):
		await _night("kriegerin-des-lichts", "ansagen-anzeigen-an", ["kriegerin-des-lichts"] + FILL, true)
	quit(0)


func _want(group: String) -> bool:
	return ONLY == "" or group.contains(ONLY) or ONLY.contains(group)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
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


func _fire() -> void:
	var screen := await _boot(&"new_game", false)
	while int(ctx.setup.view()["player_count"]) < 13:
		(screen.find_child("PlusButton", true, false) as BaseButton).pressed.emit()
		await _fr(2)
	(screen.find_child("ActCard_akt4", true, false) as BaseButton).pressed.emit()
	await _fr(150)
	await _save("feuer-akt4-geisterfeuer")


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


func _night(role: String, label: String, roles: Array, calls: bool = false, lovers: bool = false) -> void:
	await _boot(&"cockpit", true, calls)
	await _start_game(roles.slice(0, 8))
	var owner := "pack" if role == "werwolf" else role
	var found := await _advance_until(func(n: Dictionary) -> bool:
		return str(n.get("kind")) == "prompt" and str(n.get("owner", "")) == owner)
	if not found:
		print("FAIL ", label)
		await _save(label + "-fail")
		return
	if lovers:
		var n: Dictionary = _effective()
		var ids: Array = n.get("allowed_ids", [])
		ctx.session.preview_apply(func(s: GameState) -> void:
			s.loki_pairs.append({"loki_id": int(ids[0]), "a": int(ids[0]), "b": int(ids[1]), "kind": "love", "ended": false}))
	await _fr(30)
	await _save(label)


## Waldläufer: Karte mit „Karte zeigen“, danach das gezeigte Ergebnis.
func _ranger() -> void:
	await _boot(&"cockpit", true)
	await _start_game(["waldlaeufer"] + FILL)
	var shown := await _advance_until(func(n: Dictionary) -> bool:
		return str(n.get("kind")) == "prompt" and str(n.get("owner", "")) == "waldlaeufer")
	if not shown:
		print("FAIL waldlaeufer")
		return
	await _fr(20)
	await _save("waldlaeufer-karte")
	(shell.find_child("ShowCardButton", true, false) as BaseButton).pressed.emit()
	await _fr(12)
	await _save("waldlaeufer-ergebnis")


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
			var picks: Array = [ids.back()] if str(n.get("owner")) in ["pack", "pack2"] else ids.slice(0, want)
			for id: Variant in picks:
				ring.token_for(int(id)).pressed.emit()
				await _fr(2)
			if CockpitText.auto_commit(n):
				await _fr(4)
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
