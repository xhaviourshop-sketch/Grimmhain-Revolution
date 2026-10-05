extends TestCase
## Architekturregel (Masterplan §4 Regel 1, 03 §2): Der Domain-Core unter core/ lädt
## keine Szenen, nutzt keine Nodes, UI, Audio, Netzwerk, Zeit oder Dateisystem und
## keinen globalen Zufall.

const CORE_DIR := "res://core"
const FORBIDDEN := [
	["\\bextends\\s+(Node|Node2D|Node3D|Control|CanvasItem|Resource)\\b", "Node/Resource-Basisklasse"],
	["\\b(get_tree|get_node|add_child|queue_free)\\s*\\(", "Szenenbaum"],
	["\\b(PackedScene|SceneTree|Viewport|Window)\\b", "Szenen"],
	["\\b(FileAccess|DirAccess|ResourceLoader|ResourceSaver|ConfigFile|ProjectSettings)\\b", "Dateisystem"],
	["\\b(load|preload)\\s*\\(", "Laden von Ressourcen"],
	["\\b(OS|Time|Engine|Input|DisplayServer|Performance)\\s*\\.", "Plattform/Zeit"],
	["\\b(AudioStream\\w*|AudioServer)\\b", "Audio"],
	["\\b(HTTPRequest|HTTPClient|StreamPeer\\w*|PacketPeer\\w*|WebSocket\\w*|ENet\\w*|MultiplayerAPI|TCPServer|UDPServer)\\b", "Netzwerk"],
	["(?<![\\w.])(randi|randf|randi_range|randf_range|randomize|randfn|seed)\\s*\\(", "globaler Zufall"],
	["\\bprint(_rich|err|raw)?\\s*\\(|\\bpush_(error|warning)\\s*\\(", "Konsolenausgabe"],
	["\\b(await|signal)\\b", "Signale/Nebenläufigkeit"],
	["\\.(shuffle|pick_random)\\s*\\(", "globaler Zufall (shuffle, pick_random; RandomNumberGenerator nur in seeded_rng.gd)"],  # F-T03
]


func test_core_has_no_forbidden_dependencies() -> void:
	var files := _collect(CORE_DIR)
	assert_true(files.size() >= 10, "Core-Dateien gefunden (%d)" % files.size())
	var patterns: Array[RegEx] = []
	for entry: Array in FORBIDDEN:
		patterns.append(RegEx.create_from_string(entry[0]))
	for path: String in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var line := lines[n]
			var code := line.split("#")[0]
			for i: int in patterns.size():
				if patterns[i].search(code) != null:
					fail("%s:%d verletzt Kernregel (%s): %s" % [path, n + 1, FORBIDDEN[i][1], line.strip_edges()])
	assert_true(true, "Prüfung abgeschlossen")


func test_core_scripts_are_refcounted() -> void:
	for path: String in _collect(CORE_DIR):
		var text := FileAccess.get_file_as_string(path)
		assert_true(text.contains("\nextends RefCounted") or text.begins_with("extends RefCounted"), "%s erbt von RefCounted" % path)


func _collect(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for f: String in dir.get_files():
		if f.ends_with(".gd"):
			result.append(dir_path.path_join(f))
	for d: String in dir.get_directories():
		result.append_array(_collect(dir_path.path_join(d)))
	result.sort()
	return result
