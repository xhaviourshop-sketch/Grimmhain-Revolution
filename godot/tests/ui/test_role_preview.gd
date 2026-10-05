extends UiTestCase
## Rollen-Vorschau (Feedback 7): echte Bildschirme aus einer Wegwerf-Partie, nichts wird gespeichert, die echte Sitzung bleibt unberührt.


func test_preview_shows_real_screens_and_saves_nothing() -> void:
	var shell := await spawn_shell(SIZE_4_3)
	if shell == null:
		return
	await navigate(shell, &"settings")
	await press(find_button(current_screen(shell), "RolePreviewButton"))
	await frames(3)
	assert_eq(current_id(shell), &"role_preview", "Einstellungen > Rollen-Vorschau")
	var screen := current_screen(shell)
	await press(find_button(screen, "PreviewRole_doktor"))
	await frames(3)
	assert_true(int(screen.call("stop_count")) >= 4, "Doktor: Nacht, Karte zeigen, Morgen, Tag, Tod")
	var cockpit := screen.call("cockpit") as Node
	assert_true(cockpit != null and find_node(cockpit, "ActionCard") != null, "das echte Cockpit")
	for i: int in int(screen.call("stop_count")):
		await press(find_button(screen, "PreviewNext"))
	await frames(4)
	var saves_dir := str((context_of(shell).get("saves") as Object).get("base_dir"))
	assert_false(DirAccess.dir_exists_absolute(saves_dir) and DirAccess.get_files_at(saves_dir).size() > 0, "kein Spielstand im Speicherordner")
	assert_false(DirAccess.dir_exists_absolute("user://preview-scratch") and DirAccess.get_files_at("user://preview-scratch").size() > 0, "auch kein Vorschau-Spielstand")
	assert_eq(str((session_of(shell) as Object).call("round_id")), "", "die echte Sitzung bleibt leer")
	await press(find_button(screen, "PreviewList"))
	assert_true(screen.call("cockpit") == null, "zurück zur Liste")
