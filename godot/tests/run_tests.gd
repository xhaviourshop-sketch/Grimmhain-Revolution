extends SceneTree
## Headless-Testrunner. Lädt alle Skripte tests/unit/test_*.gd, ruft deren
## `test_*`-Methoden auf und beendet Godot mit Exit-Code 0 (grün) oder 1 (rot).
##
## Aufruf:  godot --headless --path godot -s res://tests/run_tests.gd
## Optional: -- --filter=<teilstring>   (nur passende Testdateien)

const UNIT_DIR := "res://tests/unit"


func _init() -> void:
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
			instance.call(method)
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
	var dir := DirAccess.open(UNIT_DIR)
	if dir == null:
		return result
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd") and (filter == "" or file.contains(filter)):
			result.append(UNIT_DIR.path_join(file))
	result.sort()
	return result
