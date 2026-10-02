extends SceneTree
## Kindprozess für test_process_restart: setzt eine gespeicherte Partie in einem neuen Godot-Prozess über
## AppContext.resume fort, meldet den geladenen Stand, beantwortet die offene Waldhexen-Giftstufe (automatisch
## gespeichert) und meldet den neuen Stand. Kein eigener Test (Name ohne `test_`), kein Zugriff auf `user://saves`.
##
## Aufruf: godot --headless --path godot -s res://tests/ui/process_resume_child.gd -- --dir=<user://test-saves-…> --round=<id>


func _initialize() -> void:
	var args := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			args[arg.substr(2, arg.find("=") - 2)] = arg.substr(arg.find("=") + 1)
	var dir := str(args.get("dir", ""))
	if not dir.begins_with("user://test-saves-"):
		print("RESULT " + JSON.stringify({"ok": false, "error": "kein Testverzeichnis"}))
		quit(2)
		return
	var ctx := AppContext.new()
	ctx.saves.base_dir = dir
	var resumed := ctx.resume(str(args.get("round", "")))
	var out := {"ok": bool(resumed["ok"]), "recovered": str(resumed.get("recovered", "")), "hash_loaded": ctx.session.state_hash(),
		"next": ctx.session.cockpit_view().get("next", {}), "commands": ctx.session.commands().size()}
	if bool(resumed["ok"]):
		out["answered"] = ctx.session.answer_choice(true).ok
		out["hash_after"] = ctx.session.state_hash()
		out["saved"] = bool(ctx.saves.last_status.get("ok", false))
	print("RESULT " + JSON.stringify(out))
	quit(0 if bool(resumed["ok"]) else 1)
