extends SceneTree
## Screenshots Feedback 9, Teil X (Texte und Listen), 1024x768, braucht einen echten Renderer:
##   godot --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_feedback9_f1.gd -- --out=<Ordner>
## Bilder: Morgenbericht (Für dich), Partiebericht über den Seitenwechsel, Rollen-Vorschau (drei Reiter), Lexikon-Liste,
## Regelbuch-Kapitel Morgenbericht DE und EN, Tag mit nominierter Person.
var OUT := "user://shots"
var ctx: AppContext
var shell: AppShell
var lang := "de"
const NAMES := ["Anna", "Tom", "Lena", "Paul", "Mia", "Jonas", "Clara", "Felix"]


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			OUT = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1024, 768)
	await _morning("de")
	await _morning("en")
	await _report()
	await _rulebook("de")
	await _rulebook("en")
	quit(0)


func _boot(screen: StringName, language: String = "de") -> void:
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		await _fr(3)
	ctx = AppContext.new()
	ctx.settings.set_reduced_motion(true)
	ctx.settings.set_language(language)
	var tmp := OS.get_temp_dir().path_join("grimmhain-cap9f1")
	ctx.saves.base_dir = tmp.path_join("saves")
	ctx.history.path = tmp.path_join("history.json")
	ctx.exports_dir = tmp.path_join("exports")
	shell = (load("res://app/main.tscn") as PackedScene).instantiate() as AppShell
	shell.app_context = ctx
	root.add_child(shell)
	await _fr(3)
	shell.navigate(&"main_menu")
	if screen != &"main_menu":
		shell.navigate(screen)
	await _fr(8)


func _start(roles: Array, seats: Array, round_id: String) -> void:
	var map := {}
	var persons: Array = []
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
		persons.append({"id": i + 1, "name": NAMES[i]})
	var r: CommandResult = ctx.session.submit(Command.start_game({"round_id": round_id, "seed": 5, "assignment": "manual",
		"players": persons, "seat_order": seats, "roles": map}))
	if not r.ok:
		printerr("Start abgelehnt: ", r.error)


## Morgenbericht nach der Giftnacht (Tod, Rettung): „Für dich“ in kurzen Zeilen.
func _morning(language: String) -> void:
	await _boot(&"main_menu", language)
	_start(["werwolf", "schutzengel", "waldhexe", "nachtwaechter", "dorfbewohner", "amalia", "detektiv"], [1, 4, 2, 3, 5, 6, 7], "cap9f1-morgen")
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	ctx.session.begin_next_step()
	ctx.session.answer_targets([5])
	ctx.session.begin_next_step()
	ctx.session.answer_choice(false)
	ctx.session.answer_choice(true)
	ctx.session.answer_targets([6])
	ctx.session.answer_choice(true)
	ctx.session.end_night()
	shell.navigate(&"cockpit")
	await _fr(25)
	await _save("morgenbericht-%s" % language)


## Partiebericht (Spielleiterfassung) mit allen Seiten; druckt, womit jede Seite beginnt und endet.
func _report() -> void:
	await _boot(&"main_menu")
	_start(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"], [1, 2, 3, 4, 5, 6], "cap9f1-bericht")
	ctx.session.start_night()
	ctx.session.answer_targets([3])
	ctx.session.end_night()
	ctx.session.nominate(1, 4)
	ctx.session.decide_execution(4)
	ctx.session.confirm_win(int(ctx.session.cockpit_view()["next"]["candidates"][0]["id"]))
	shell.navigate(&"history")
	await _fr(8)
	var list := shell.find_child("HistoryList", true, false)
	(list.get_child(0) as BaseButton).pressed.emit()
	await _fr(10)
	await _save("bericht-export-knopf")
	(shell.find_child("HistoryGmButton", true, false) as BaseButton).set_pressed(true)
	await _fr(6)
	(shell.find_child("ConfirmButton", true, false) as BaseButton).pressed.emit()
	await _fr(10)
	await _save("bericht-seite1")
	var n := 2
	while true:
		var next := shell.find_child("NextPageButton", true, false) as BaseButton
		if next == null or next.disabled:
			break
		next.pressed.emit()
		await _save("bericht-seite%d" % n)
		n += 1


func _preview() -> void:
	await _boot(&"role_preview")
	for team: String in ["village", "wolves", "solo"]:
		var tab := shell.find_child("PreviewTab_%s" % team, true, false) as BaseButton
		tab.set_pressed(true)
		await _fr(10)
		await _save("rollen-vorschau-%s" % team)


func _lexicon() -> void:
	await _boot(&"lexicon")
	await _save("lexikon-liste")


func _rulebook(language: String) -> void:
	await _boot(&"rulebook", language)
	var button := shell.find_child("RulebookChapter_c06", true, false) as BaseButton
	button.pressed.emit()
	await _fr(10)
	await _save("regelbuch-morgenbericht-%s" % language)


func _nominated() -> void:
	await _boot(&"main_menu")
	var game: GDScript = load("res://tests/ui/ui_game.gd")
	_start(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"], [1, 2, 3, 4, 5, 6, 7, 8], "cap9f1-tag")
	ctx.session.start_night()
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
	await _fr(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("%s-1024x768.png" % label))
	print("bild ", label)
