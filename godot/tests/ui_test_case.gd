class_name UiTestCase
extends TestCase
## Basis für UI-Tests (tests/ui/). Der Runner übergibt den Szenenbaum (`attach_tree`) und
## räumt nach jedem Test auf (`after_each`). Die App-Shell wird in einer festen logischen
## Größe ohne Skalierung gestartet (`spawn_shell`), damit Geometrieprüfungen den
## ungünstigsten Fall prüfen: 1024×768 logische Pixel ohne Herunterskalieren.
## UI-Klassen werden bewusst über Pfade und `call`/`get` angesprochen: So bleiben die
## Tests unabhängig von der internen Typisierung der UI und waren vor der Implementierung
## ladbar (roter Commit).

const MAIN_SCENE := "res://app/main.tscn"
const SCREEN_IDS_SCRIPT := "res://app/navigation/screen_ids.gd"
const THEME_TOKENS_SCRIPT := "res://app/theme/theme_tokens.gd"
const PLATFORM_SCRIPT := "res://app/platform/app_platform.gd"
const SESSION_SCRIPT := "res://app/session/game_session.gd"
const CONTEXT_SCRIPT := "res://app/app_context.gd"
const PO_DE := "res://content/i18n/ui.de.po"
const PO_EN := "res://content/i18n/ui.en.po"

const SIZE_4_3 := Vector2i(1024, 768)
const SIZE_16_10 := Vector2i(1280, 800)
const SIZE_WIDE := Vector2i(1920, 1080)

## Alle sechs Ansichten mit ihren erwarteten stabilen IDs.
const SCREEN_IDS: Array[StringName] = [&"start", &"main_menu", &"new_game", &"continue", &"settings", &"cockpit"]
const SUB_SCREENS: Array[StringName] = [&"new_game", &"continue", &"settings", &"cockpit"]

var tree: SceneTree
var quit_calls: int = 0
var _spawned: Array[Node] = []


func attach_tree(t: SceneTree) -> void:
	tree = t


func after_each() -> void:
	for node: Node in _spawned:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned.clear()
	var platform := load_script(PLATFORM_SCRIPT, false)
	if platform != null:
		platform.call("clear_override")
	TranslationServer.set_locale("de")
	await frames(1)


func frames(count: int = 2) -> void:
	for i: int in count:
		await tree.process_frame


func wait_seconds(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


## Lädt ein Skript; mit `required` gilt ein fehlendes Skript als Fehlschlag.
func load_script(path: String, required: bool = true) -> Script:
	if not ResourceLoader.exists(path):
		if required:
			fail("%s fehlt" % path)
		return null
	return load(path) as Script


## Startet die App-Shell in logischer Größe `size` (ohne Skalierung), Sprache `locale`.
## Übergänge sind standardmäßig aus (reduzierte Bewegung), damit Geometrie sofort stimmt.
func spawn_shell(size: Vector2i = SIZE_16_10, locale: String = "de", reduced_motion: bool = true) -> Control:
	if not ResourceLoader.exists(MAIN_SCENE):
		fail("Hauptszene %s fehlt" % MAIN_SCENE)
		return null
	var scene := load(MAIN_SCENE) as PackedScene
	if scene == null:
		fail("Hauptszene %s nicht ladbar" % MAIN_SCENE)
		return null
	await resize(size)
	var shell := scene.instantiate() as Control
	if shell == null:
		fail("Hauptszene ist kein Control")
		return null
	shell.set("quit_handler", func() -> void: quit_calls += 1)
	# Einstellungen vor dem Start übergeben, damit schon die erste Ansicht sie beachtet.
	var context_script := load_script(CONTEXT_SCRIPT)
	if context_script != null:
		var context: Object = context_script.new()
		var s := context.get("settings") as Object
		s.call("set_reduced_motion", reduced_motion)
		s.call("set_language", locale)
		shell.set("app_context", context)
	tree.root.add_child(shell)
	_spawned.append(shell)
	if settings_of(shell) == null:
		fail("App-Shell liefert keine Einstellungen")
	await frames(3)
	return shell


## Setzt die logische Größe des Root-Viewports ohne Skalierung. Headless setzt Godot die
## Fenstergröße in den ersten Frames nach dem Start zurück; deshalb bis zur Übernahme wiederholen.
func resize(size: Vector2i) -> void:
	var root := tree.root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for attempt: int in 10:
		root.size = size
		await frames(1)
		if root.size == size and root.get_visible_rect().size == Vector2(size):
			break
	if root.get_visible_rect().size != Vector2(size):
		fail("Viewportgröße %s nicht übernommen (%s)" % [size, root.get_visible_rect().size])
	await frames(2)


func context_of(shell: Control) -> Object:
	return shell.call("get_app_context") as Object if shell != null and shell.has_method("get_app_context") else null


func settings_of(shell: Control) -> Object:
	var ctx := context_of(shell)
	return ctx.get("settings") as Object if ctx != null else null


func session_of(shell: Control) -> Object:
	var ctx := context_of(shell)
	return ctx.get("session") as Object if ctx != null else null


func router_of(shell: Control) -> Control:
	return shell.call("get_router") as Control if shell != null and shell.has_method("get_router") else null


func current_id(shell: Control) -> StringName:
	return StringName(shell.call("current_screen_id")) if shell != null and shell.has_method("current_screen_id") else &""


func current_screen(shell: Control) -> Control:
	return shell.call("current_screen") as Control if shell != null and shell.has_method("current_screen") else null


## Navigiert über die Shell und wartet, bis das Layout steht.
func navigate(shell: Control, id: StringName) -> void:
	if shell != null and shell.has_method("navigate"):
		shell.call("navigate", id)
	await frames(3)


func go_back(shell: Control) -> void:
	if shell != null and shell.has_method("go_back"):
		shell.call("go_back")
	await frames(3)


## Sucht einen benannten Knoten unterhalb von `root` (auch in instanzierten Unterszenen).
func find_node(root: Node, node_name: String) -> Node:
	return root.find_child(node_name, true, false) if root != null else null


func find_button(root: Node, node_name: String) -> BaseButton:
	var node := find_node(root, node_name)
	if node == null:
		fail("Button %s fehlt" % node_name)
	return node as BaseButton


## Löst die Aktion eines Buttons so aus, wie Maus und Touch es tun (Signal `pressed`).
func press(button: BaseButton) -> void:
	if button == null:
		return
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	else:
		button.pressed.emit()
	await frames(3)


## Echter Mausklick in der Mitte eines Controls über den Viewport.
func click(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = center
		e.global_position = center
		tree.root.push_input(e)
		await frames(1)
	await frames(2)


func key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = keycode
		e.physical_keycode = keycode
		e.pressed = pressed
		tree.root.push_input(e)
		await frames(1)
	await frames(2)


## Alle sichtbaren Controls unterhalb von `root` (inklusive `root`).
func visible_controls(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	_collect_visible(root, out)
	return out


func _collect_visible(node: Node, out: Array[Control]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Control:
		out.append(node as Control)
	for child: Node in node.get_children():
		_collect_visible(child, out)


func visible_buttons(root: Node) -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	for c: Control in visible_controls(root):
		if c is BaseButton:
			out.append(c as BaseButton)
	return out


## Sichtbare Controls mit Text (Label, Button und Unterklassen).
func text_controls(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for c: Control in visible_controls(root):
		if c is Label or c is Button:
			out.append(c)
	return out


func text_of(c: Control) -> String:
	if c is Label:
		return (c as Label).text
	if c is Button:
		return (c as Button).text
	return ""


func key_of(c: Control) -> String:
	var value: Variant = c.get("text_key")
	return str(value) if value != null else ""


## Einfache PO-Auswertung: msgid → msgstr (ohne Kopfzeile).
func po_entries(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		fail("%s fehlt" % path)
		return out
	var msg_id := ""
	var reading := ""
	for raw: String in FileAccess.get_file_as_string(path).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("msgid "):
			msg_id = _po_string(line.trim_prefix("msgid "))
			reading = "id"
		elif line.begins_with("msgstr "):
			if msg_id != "":
				out[msg_id] = _po_string(line.trim_prefix("msgstr "))
			reading = "str"
		elif line.begins_with("\"") and reading == "str" and msg_id != "":
			out[msg_id] = str(out[msg_id]) + _po_string(line)
	return out


func _po_string(quoted: String) -> String:
	var s := quoted.strip_edges()
	if s.begins_with("\"") and s.ends_with("\"") and s.length() >= 2:
		s = s.substr(1, s.length() - 2)
	return s.c_unescape()


## Rechteck eines Controls in Viewport-Koordinaten.
func rect_of(c: Control) -> Rect2:
	return c.get_global_rect()


func inside(inner: Rect2, outer: Rect2, tolerance: float = 0.5) -> bool:
	return inner.position.x >= outer.position.x - tolerance and inner.position.y >= outer.position.y - tolerance \
		and inner.end.x <= outer.end.x + tolerance and inner.end.y <= outer.end.y + tolerance


## Echte Überlappung (Berührung an Kanten zählt nicht).
func overlaps(a: Rect2, b: Rect2, tolerance: float = 0.5) -> bool:
	return a.grow(-tolerance).intersects(b.grow(-tolerance))


## Dateien mit Endung `ext` rekursiv unterhalb von `dir_path`.
func files_in(dir_path: String, ext: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for f: String in dir.get_files():
		if f.ends_with(ext):
			result.append(dir_path.path_join(f))
	for d: String in dir.get_directories():
		result.append_array(files_in(dir_path.path_join(d), ext))
	result.sort()
	return result
