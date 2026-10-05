extends "res://tools/capture_ui_screenshots.gd"
## P0 scratch: real cockpit with 24 persons, start of night and a target selection.

func _initialize() -> void:
	var out := "C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/p0-istzustand"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	await _capture(out + "/P0-24-start-1024x768.png", Vector2i(1024, 768), "de", &"new_game", "_p0_started")
	await _capture(out + "/P0-24-zielwahl-1024x768.png", Vector2i(1024, 768), "de", &"new_game", "_p0_target")
	await _capture(out + "/P0-24-zielwahl-1280x800.png", Vector2i(1280, 800), "de", &"new_game", "_p0_target")
	quit(0)


func _p0_started(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 24))
	await _press(shell, "ConfirmSeatingButton")
	await _press(shell, "StartGameButton")
	shell.get_toast().hide_message()


func _p0_target(shell: AppShell) -> void:
	await _p0_started(shell)
	await _press(shell, "StartNightButton")
	for i: int in 16:
		if _node(shell, "ConfirmTargetsButton") != null:
			break
		var b: Node = null
		for n: String in ["BeginStepButton", "AckButton", "YesButton", "SkipStepButton", "ShowCardButton"]:
			b = _node(shell, n)
			if b != null:
				break
		if b == null:
			print("P0: keine Schrittaktion in Schritt %d" % i)
			break
		print("P0: Schritt %d drückt %s" % [i, b.name])
		await _press(shell, b.name)
	print("P0: ConfirmTargets vorhanden: ", _node(shell, "ConfirmTargetsButton") != null)
	shell.get_toast().hide_message()
