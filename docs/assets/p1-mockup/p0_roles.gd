extends "res://tools/capture_ui_screenshots.gd"

func _initialize() -> void:
	var out := "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/p0-istzustand"
	await _capture(out + "/P0-setup-totenreichkarten-1280x800.png", Vector2i(1280, 800), "de", &"new_game", "_p0_roles")
	quit(0)

func _p0_roles(shell: AppShell) -> void:
	await _to_roles(shell, 12)
