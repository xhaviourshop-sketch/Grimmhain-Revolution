extends SceneTree
## Headless-Testrunner. Lädt alle Skripte tests/unit/test_*.gd (Regelkern) und
## tests/ui/test_*.gd (UI), ruft deren `test_*`-Methoden auf und beendet Godot mit
## Exit-Code 0 (grün) oder 1 (rot).
## Läuft in `_initialize`, also mit fertigem Szenenbaum: UI-Tests dürfen Frames abwarten
## (`await`); synchrone Regelkern-Tests laufen unverändert. UI-Tests erhalten den Baum
## über `attach_tree` und räumen nach jedem Test über `after_each` auf.
##
## Aufruf:  godot --headless --path godot -s res://tests/run_tests.gd
## Optional: -- --filter=<teilstring>   (nur passende Testdateien)

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/ui"]


func _initialize() -> void:
	var filter := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")

	var files := _collect_test_files(filter)
	var total := 0
	var failed := 0
	var broken_files := 0

	for path: String in files:
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			print("FAIL  %s  (Skript nicht ladbar)" % path)
			broken_files += 1
			continue
		var methods: Array[String] = []
		for m: Dictionary in script.get_script_method_list():
			var name: String = m["name"]
			if name.begins_with("test_") and not methods.has(name):
				methods.append(name)
		methods.sort()
		for method: String in methods:
			var instance: TestCase = script.new()
			if instance.has_method("attach_tree"):
				instance.call("attach_tree", self)
			await instance.call(method)
			if instance.has_method("after_each"):
				await instance.call("after_each")
			total += 1
			var label := "%s::%s" % [path.get_file().get_basename(), method]
			if instance.assertions == 0:
				failed += 1
				print("FAIL  %s  (keine Prüfung ausgeführt, möglicher Laufzeitfehler)" % label)
			elif instance.failures.is_empty():
				print("ok    %s  (%d Prüfungen)" % [label, instance.assertions])
			else:
				failed += 1
				print("FAIL  %s" % label)
				for f: String in instance.failures:
					print("      - %s" % f)

	print("")
	print("%d Tests, %d fehlgeschlagen, %d Testdateien nicht ladbar" % [total, failed, broken_files])
	quit(0 if failed == 0 and broken_files == 0 and total > 0 else 1)


func _collect_test_files(filter: String) -> Array[String]:
	var result: Array[String] = []
	for test_dir: String in TEST_DIRS:
		var dir := DirAccess.open(test_dir)
		if dir == null:
			continue
		var files: Array[String] = []
		for file: String in dir.get_files():
			if file.begins_with("test_") and file.ends_with(".gd") and (filter == "" or file.contains(filter)):
				files.append(test_dir.path_join(file))
		files.sort()
		result.append_array(files)
	return result
