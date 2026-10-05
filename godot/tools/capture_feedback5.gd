extends SceneTree
## Screenshots der Optik-Runde (Feedback 5), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback5.gd -- --out=<Ordner> [--only=<Teil>]
## Gruppen: start (Startbild mit Flaggen), akt (Akt 1 bis 4 und Feuer-Alternativen), cockpit (aktive Person), fenster (alle Fenster).
var OUT := "user://shots"
var ONLY := ""
const FILL := ["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor"]
const WOLF_FILL := ["siegreicher-wolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]
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
	if _want("start"):
		await _start()
	if _want("akt"):
		await _acts()
	if _want("cockpit"):
		await _active_person()
	if _want("fenster"):
		await _windows()
	quit(0)


func _want(group: String) -> bool:
	return ONLY == "" or group.contains(ONLY) or ONLY.contains(group)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await _fr(10)
	await RenderingServer.frame_post_draw
	var path := OUT.path_join("%s-1024x768.png" % label)
	root.get_texture().get_image().save_png(path)
	print("bild ", label)


func _boot(screen: StringName, reduced: bool, locale: String = "de") -> Node:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(reduced)
	ctx.settings.set_language(locale)
	ctx.setup.seed_source = func() -> int: return 20260926
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-cap5")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	if screen != &"start":
		shell.navigate(&"main_menu")
	shell.navigate(screen)
	await _fr(6)
	return shell.current_screen()


func _start() -> void:
	await _boot(&"start", false)
	await _fr(60)
	await _save("startbildschirm-flaggen-de")
	await _boot(&"start", false, "en")
	await _fr(30)
	await _save("startbildschirm-flaggen-en")


func _acts() -> void:
	for style: StringName in [&"fire", &"ghost", &"ember"]:
		FireGlow.style = style
		for level: int in [1, 2, 3, 4]:
			if style != &"fire" and level != 4 and level != 2:
				continue
			var screen := await _boot(&"new_game", false)
			var setup := ctx.setup
			while int(setup.view()["player_count"]) < 13:
				(screen.find_child("PlusButton", true, false) as BaseButton).pressed.emit()
				await _fr(2)
			(screen.find_child("ActCard_akt%d" % level, true, false) as BaseButton).pressed.emit()
			await _fr(150)
			await _save("feuer-%s-akt%d" % ["standard" if style == &"fire" else String(style), level])
	FireGlow.style = &"fire"


## Nacht-1-Karten mit handelnder Person: Einzelperson (Spürhund) und Gruppe (Rudel).
func _active_person() -> void:
	await _night("doktor", "aktive-person-einzeln", FILL)
	await _night("werwolf", "aktive-person-rudel", WOLF_FILL)


func _start_game(roles: Array) -> void:
	var fx: GDScript = load("res://tests/fixtures.gd") as GDScript
	for c: Command in fx.call("start_with_copies", fx.call("legalize", roles), 7, {}):
		var r: CommandResult = ctx.session.submit(c)
		if not r.ok:
			print("start rejected ", r.error)
	await _fr(6)


func _night(role: String, label: String, fill: Array) -> void:
	await _boot(&"cockpit", role != "werwolf")  # bei bewegter Darstellung bleibt der Vorschritt in der Rückgängig-Leiste hängen
	var roles: Array = [role]
	for f: String in fill:
		if f != role and roles.size() < 8:
			roles.append(f)
	await _start_game(roles)
	var found := await _advance_until(func(n: Dictionary) -> bool:
		var rid := str(n.get("role_id", ""))
		if rid == "" and str(n.get("kind")) == "prompt":
			rid = str(n.get("owner", ""))
		if role == "werwolf" and str(n.get("owner", "")) == "pack":
			rid = "werwolf"
		return str(n.get("kind")) in ["begin_step", "prompt"] and rid == role)
	if found:
		await _fr(40)
		await _save(label)
	else:
		print("FAIL ", label)
		await _save(label + "-fail")


## Bedient die Oberfläche (Ziele wählen, Hauptknopf), bis `cond` auf die nächste Karte zutrifft.
func _advance_until(cond: Callable) -> bool:
	var screen := shell.current_screen()
	for step: int in 80:
		var n: Dictionary = (ctx.session.cockpit_view() as Dictionary).get("next", {})
		var kind := str(n.get("kind"))
		if cond.call(n):
			return true
		if kind in ["day", "game_over", "win_decision"]:
			return false
		if kind == "begin_step" and not (n.get("preview", {}) as Dictionary).is_empty():  # Vorschau eines Schritts: die Ziele stehen schon in der Vorschau
			var pv: Dictionary = n["preview"]
			n = pv.duplicate()
			n["kind"] = "prompt"
			kind = "prompt"
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


func _press(node_name: String) -> bool:
	var b := shell.find_child(node_name, true, false) as BaseButton
	if b == null:
		print("FAIL kein Knopf ", node_name)
		return false
	if not b.is_visible_in_tree():
		var options := shell.find_child("OptionsButton", true, false) as BaseButton
		if options != null:
			options.pressed.emit()
			await _fr(4)
	b.pressed.emit()
	await _fr(8)
	return true


func _close_layer() -> void:
	var cl := shell.find_child("CloseLayerButton", true, false) as BaseButton
	if cl != null:
		cl.pressed.emit()
	await _fr(6)


func _windows() -> void:
	await _boot(&"cockpit", true)
	await _start_game(["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor", "spuerhund"])
	# Rollen zeigen: Liste, Vorderseite, Rolle
	if await _press("RolesButton"):
		await _save("fenster-rollen-zeigen-liste")
		var first := shell.find_child("RolePerson_*", true, false) as BaseButton
		if first != null:
			first.pressed.emit()
			await _fr(8)
			await _save("fenster-rollen-zeigen-vorderseite")
			if await _press("RevealRoleButton"):
				await _save("fenster-rollen-zeigen-rolle")
				var confirm := shell.find_child("ConfirmRoleButton", true, false) as BaseButton
				if confirm != null:
					confirm.pressed.emit()
					await _fr(6)
		await _close_layer()
	for pair: Array in [["PrivateButton", "fenster-privat"], ["GmButton", "fenster-spielleitung"], ["LogButton", "fenster-protokoll"],
			["LexiconButton", "fenster-lexikon"], ["RulebookButton", "fenster-regelbuch"]]:
		if await _press(pair[0]):
			await _save(pair[1])
			await _close_layer()
	if await _press("CoverButton"):
		await _save("fenster-sichtschutz")
		var resume := shell.find_child("UncoverButton", true, false) as BaseButton
		if resume != null:
			resume.pressed.emit()
			await _fr(6)
	if await _press("GmButton"):
		var undo := shell.find_child("DiscardGameButton", true, false) as BaseButton
		if undo != null:
			undo.pressed.emit()
			await _fr(10)
			await _save("fenster-rueckfrage-verwerfen")
			(shell.find_child("ConfirmDialog", true, false) as ConfirmDialog).cancel()
			await _fr(4)
		await _close_layer()
	# Karte zeigen: Spürhund beantwortet, danach die Karte mit Ergebnis
	await _boot(&"cockpit", true)
	await _start_game(["spuerhund", "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor"])
	var shown := await _advance_until(func(_n: Dictionary) -> bool:
		var sb := shell.find_child("ShowCardButton", true, false) as BaseButton
		return sb != null and sb.is_visible_in_tree() and not sb.disabled)
	if shown:
		(shell.find_child("ShowCardButton", true, false) as BaseButton).pressed.emit()
		await _fr(10)
		await _save("fenster-karte-zeigen")
		await _close_layer()
	else:
		print("FAIL Karte zeigen nicht erreicht")
	# Hinweiskarte (Loki-Bund)
	await _boot(&"cockpit", true)
	await _start_game(["loki", "werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor"])
	var got := await _advance_until(func(n: Dictionary) -> bool:
		if str(n.get("kind")) == "prompt" and str(n.get("owner")) == "loki":
			var pair: Array = (n.get("allowed_ids", []) as Array).slice(0, 2)
			ctx.session.answer_targets(pair)
			ctx.session.answer_choice(true)
		return str(n.get("kind")) == "notice")
	if got:
		(shell.find_child("ShowNoticeButton", true, false) as BaseButton).pressed.emit()
		await _fr(12)
		await _save("fenster-hinweiskarte")
	else:
		print("FAIL Hinweiskarte nicht erreicht")
