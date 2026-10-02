class_name ReportExport
extends RefCounted
## Textexport eines Abschlussberichts als UTF-8-Datei (kein PDF, kein Teilen, kein Upload). Die Fassung (öffentlich oder
## Spielleitung) steht im Dateinamen und im Text. Eine vorhandene Datei wird nur mit ausdrücklichem `overwrite` ersetzt; das
## Ersetzen schreibt zuerst eine geprüfte `.tmp` und tauscht dann, bei Fehler bleibt die vorhandene Datei erhalten.

const DEFAULT_DIR := "user://exports"


static func file_name(report: Dictionary, version: String) -> String:
	var id := RegEx.create_from_string("[^A-Za-z0-9_-]").sub(str(report.get("game_id", "partie")), "_", true)
	return "grimmhain-bericht-%s-%s.txt" % [id, "spielleitung" if version == ReportText.GM else "oeffentlich"]


static func path_for(dir: String, report: Dictionary, version: String) -> String:
	return dir.path_join(file_name(report, version))


## Ergebnis {ok, error, path}. Fehler: `exists` (Datei da, `overwrite` fehlt), `no_directory`, `write_failed`, `verify_failed`, `swap_failed`.
## `simulate_failure` (nur Tests): "write", "verify", "swap".
static func export(dir: String, report: Dictionary, version: String, overwrite: bool = false, simulate_failure: StringName = &"", reveal: bool = true) -> Dictionary:
	var path := path_for(dir, report, version)
	if FileAccess.file_exists(path) and not overwrite:
		return {"ok": false, "error": "exists", "path": path}
	if not SafeJsonFile.ensure_dir(dir):
		return {"ok": false, "error": "no_directory", "path": path}
	var text := ReportText.plain_text(report, version, reveal)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE) if simulate_failure != &"write" else null
	if file == null:
		return {"ok": false, "error": "write_failed", "path": path}
	file.store_string(text)
	file.close()
	if simulate_failure == &"verify" or FileAccess.get_file_as_string(tmp) != text:
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error": "verify_failed", "path": path}
	var old := path + ".old"
	var had_old := FileAccess.file_exists(path)
	if had_old:
		if FileAccess.file_exists(old):
			DirAccess.remove_absolute(old)
		if DirAccess.rename_absolute(path, old) != OK:
			DirAccess.remove_absolute(tmp)
			return {"ok": false, "error": "swap_failed", "path": path}
	if simulate_failure == &"swap" or DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
		if had_old:
			DirAccess.rename_absolute(old, path)  # vorhandene Datei zurück
		return {"ok": false, "error": "swap_failed", "path": path}
	if had_old:
		DirAccess.remove_absolute(old)
	return {"ok": true, "error": "", "path": path}
