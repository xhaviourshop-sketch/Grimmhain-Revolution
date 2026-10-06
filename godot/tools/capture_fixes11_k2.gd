extends SceneTree
## Screenshots der Vollbildkarten mit unscharfem Dorfgrund (Fixes 11, Teil C), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_fixes11_k2.gd -- --out=<Ordner>
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language("de")
	ctx.setup.seed_source = func() -> int: return 20260926
	ctx.saves.base_dir = OS.get_temp_dir().path_join("grimmhain-capk2")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	shell.navigate(&"cockpit")
	await _fr(6)
	var fx: GDScript = load("res://tests/fixtures.gd") as GDScript
	var roles: Array = ["werwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "doktor", "spuerhund"]
	for c: Command in fx.call("start_with_copies", fx.call("legalize", roles), 7, {}):
		ctx.session.submit(c)
	await _fr(10)
	var screen := shell.current_screen()
	await _save("basis-ohne-karte")  # Vergleich: Cockpit ohne Kartenebene (kein BlurBackdrop)
	# 1) Rollenkarte aus der Rollenanzeige
	var roles_button := shell.find_child("RolesButton", true, false) as BaseButton
	if roles_button == null or not roles_button.is_visible_in_tree():
		(shell.find_child("OptionsButton", true, false) as BaseButton).pressed.emit()
		await _fr(4)
		roles_button = shell.find_child("RolesButton", true, false) as BaseButton
	roles_button.pressed.emit()
	await _fr(8)
	(screen.find_child("RolePerson_*", true, false) as BaseButton).pressed.emit()
	await _fr(8)
	await _fr(20)
	await _save("rollenkarte-rollenanzeige")
	# 2) Karte zeigen mit Rollenkarte (Nachtkarte), direkt auf das Cockpit gelegt
	for n: String in ["RoleCardLayer", "RolesLayer"]:
		var l := shell.find_child(n, true, false)
		if l != null:
			l.queue_free()
	await _fr(4)
	var layer := CockpitLayers.show_card("werwolf", [{"kind": "role", "key": "role", "value": "doktor"}])
	screen.add_child(layer)
	await _fr(20)
	await _save("karte-zeigen-rollenkarte")
	quit(0)


func _fr(n: int) -> void:
	for i: int in n:
		await process_frame


func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)
