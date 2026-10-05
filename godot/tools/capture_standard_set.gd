extends SceneTree
## Standard-Screenshotsatz 1024x768 (Entwicklungswerkzeug, braucht einen echten Renderer):
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_standard_set.gd -- --out=<Ordner>
## Je Szene wird die Karte der Rolle (Rolle plus Füller, Nacht 1) mit der Oberfläche bedient, bis sie erscheint; die Rückgängig-Leiste
## vom Schritt davor läuft vor dem Bild ab. Szene: [Dateiname, Rolle, Stufe]. Neue Szenen in SCENES ergänzen.
var OUT := "user://shots"
const FILL := ["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor"]
const SCENES := [["loki", "loki", ""], ["spuerhund", "spuerhund", ""], ["werwolf", "werwolf", ""], ["lehrling", "lehrling", ""],
	["die-gebundenen", "die-gebundenen", ""], ["blutpriester", "blutpriester", ""], ["waldhexe", "waldhexe", ""], ["zuflucht", "rotkaeppchen", "grant"]]
var ctx: AppContext
var shell: AppShell


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	var ok := await _all()
	quit(0 if ok else 1)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _all() -> bool:
	for sc: Array in SCENES:
		if not await _scene(str(sc[0]), str(sc[1]), str(sc[2])):
			print("FAIL ", sc[0])
	return true


func _scene(label: String, role: String, stage: String) -> bool:
	root.size = Vector2i(1024, 768)
	await _fr(2)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap-" + label)
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(4)
	var roles: Array = [role]
	for f: String in FILL:
		if f != role and roles.size() < 8:
			roles.append(f)
	var fx: GDScript = load("res://tests/fixtures.gd") as GDScript
	for c: Command in fx.call("start_with_copies", fx.call("legalize", roles), 7, {}):
		var r: CommandResult = ctx.session.submit(c)
		if not r.ok:
			print("start rejected ", r.error)
			return false
	await _fr(6)
	var screen := shell.current_screen()
	for step: int in 80:
		var n: Dictionary = (ctx.session.cockpit_view() as Dictionary).get("next", {})
		var kind := str(n.get("kind"))
		var rid := str(n.get("role_id", ""))
		if rid == "" and kind == "prompt":
			rid = str(n.get("owner", ""))
		if role == "werwolf" and str(n.get("owner", "")) == "pack":
			rid = "werwolf"
		if kind in ["begin_step", "prompt"] and rid == role and (stage == "" or str(n.get("stage")) == stage):
			await _fr(20)
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 4000:
				await process_frame
			await _fr(10)
			await RenderingServer.frame_post_draw
			var path := OUT.path_join("%s-1024x768.png" % label)
			root.get_texture().get_image().save_png(path)
			print("bild ", label, " ", kind, " ", n.get("stage"))
			shell.queue_free()
			await _fr(3)
			return true
		if kind in ["day", "game_over", "win_decision"]:
			break
		if kind == "prompt" and str(n.get("answer")) == "targets":
			var ring := screen.find_child("SeatRing", true, false) as GameSeatRing
			var ids: Array = n.get("allowed_ids", [])
			var want := 1
			for c: Variant in n.get("counts", []):
				if int(c) > 0:
					want = int(c)
					break
			var picks: Array = [ids.back()] if str(n.get("owner")) in ["pack", "pack2"] else ids.slice(0, want)
			if role == "rotkaeppchen" and str(n.get("owner")) == "rotkaeppchen":
				picks = [ids.back()]
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
			var cl := shell.find_child("CloseLayerButton", true, false) as BaseButton
			if cl != null:
				cl.pressed.emit()
			await _fr(6)
			continue
		var card := screen.find_child("ActionCard", true, false) as ActionCard
		var b := card.primary_button() as BaseButton
		if b == null or b.disabled:
			b = null
			for x: BaseButton in card.action_buttons():
				if not x.disabled and x.name != &"CancelPromptButton" and x.name != &"SkipStepButton":
					b = x
					break
		if b == null:
			b = screen.find_child("BeginStepButton", true, false) as BaseButton
		if b == null:
			b = screen.find_child("EndNightButton", true, false) as BaseButton
		if b == null:
			b = screen.find_child("StartNightButton", true, false) as BaseButton
		if b == null:
			b = screen.find_child("ShowNoticeButton", true, false) as BaseButton
		if b == null and kind == "begin_step":
			ctx.session.begin_next_step()
			await _fr(8)
			continue
		if b == null:
			print("kein Button bei ", kind)
			break
		b.pressed.emit()
		await _fr(4)
	shell.queue_free()
	await _fr(3)
	return false
