extends UiTestCase
## Paket 4: echter Prozessneustart. Dieser Prozess spielt bis in die offene Waldhexen-Giftstufe (automatisch gespeichert)
## und beendet seine Sitzung; ein zweiter Godot-Prozess (process_resume_child.gd) setzt über AppContext.resume aus der
## Datei fort und beantwortet die Stufe. Danach lädt dieser Prozess den vom Kindprozess gespeicherten Stand.
## Beide Prozesse nutzen dasselbe isolierte Verzeichnis `user://test-saves-*`.

const ROLES := ["werwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "amalia", "detektiv"]
const CHILD := "res://tests/ui/process_resume_child.gd"


func test_resume_in_a_separate_process() -> void:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	assert_true(ctx.session.submit(Fixtures.start_roles(ROLES, 4)).ok, "Start")
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	ctx.session.begin_next_step()
	ctx.session.answer_targets([6])
	ctx.session.begin_next_step()
	ctx.session.answer_choice(false)  # Waldhexe: kein Heiltrank → Stufe Gift offen
	assert_eq(str(ctx.session.cockpit_view()["next"]["stage"]), "poison", "Giftstufe offen")
	assert_true(bool(ctx.saves.last_status["ok"]), "automatisch gespeichert")
	var round := ctx.session.round_id()
	var commands := ctx.session.commands()
	var hash_before := ctx.session.state_hash()
	var dir := ctx.saves.base_dir
	ctx = null  # Sitzung dieses Prozesses beendet; nur die Datei bleibt
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", CHILD,
		"--", "--dir=" + dir, "--round=" + round], output, true)
	var result := {}
	for chunk: Variant in output:
		for line: String in str(chunk).split("\n"):
			if line.begins_with("RESULT "):
				result = JSON.parse_string(line.trim_prefix("RESULT "))
	assert_eq(code, 0, "Kindprozess beendet ohne Fehler")
	assert_false(result.is_empty(), "Kindprozess meldet Ergebnis")
	if result.is_empty():
		return
	assert_true(bool(result["ok"]) and str(result["recovered"]) == "", "Kindprozess lädt die Datei")
	assert_eq(str(result["hash_loaded"]), hash_before, "gleicher Stand im neuen Prozess")
	assert_eq(str((result["next"] as Dictionary)["stage"]), "poison", "offene Stufe im neuen Prozess")
	assert_eq(int(result["commands"]), commands.size(), "keine doppelten oder verlorenen Befehle")
	assert_true(bool(result["answered"]) and bool(result["saved"]), "Fortsetzung angenommen und gespeichert")
	var expected: Array[Command] = commands.duplicate()
	expected.append(Command.answer_choice(RulesEngine.replay(commands).state.pending_prompt.id, "poison", true))
	var reference := RulesEngine.replay(expected)
	assert_eq(str(result["hash_after"]), reference.state.content_hash(), "Ergebnis wie ohne Prozessneustart")
	var back := AppContext.new()
	back.saves.base_dir = dir
	assert_true(bool(back.resume(round)["ok"]), "Stand des Kindprozesses hier ladbar")
	assert_eq(back.session.state_hash(), str(result["hash_after"]), "Stand des Kindprozesses erhalten")
