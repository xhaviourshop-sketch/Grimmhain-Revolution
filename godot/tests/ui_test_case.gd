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
const SCREEN_IDS: Array[StringName] = [&"start", &"main_menu", &"new_game", &"continue", &"settings", &"cockpit", &"lexicon", &"rulebook", &"history", &"role_preview"]
const SUB_SCREENS: Array[StringName] = [&"new_game", &"continue", &"settings", &"cockpit", &"lexicon", &"rulebook", &"history"]

var tree: SceneTree
var quit_calls: int = 0
var _spawned: Array[Node] = []
var _save_dirs: Array[String] = []


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
	for dir: String in _save_dirs:
		_remove_dir(dir)
	_save_dirs.clear()
	await frames(1)


## Neues leeres Verzeichnis für Spielstände eines Tests (wird in after_each entfernt).
func make_save_dir() -> String:
	var dir := "user://test-saves-%d-%d" % [Time.get_ticks_usec(), _save_dirs.size()]
	_save_dirs.append(dir)
	return dir


func _remove_dir(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


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
	CockpitScreen.double_tap_msec = 0  # schnelle Testbedienung; der Doppeltipp-Test schaltet die Sperre selbst ein
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
		# Jede Test-Shell speichert in ein eigenes, danach entferntes Verzeichnis (keine echten Spielstände).
		var saves := context.get("saves") as Object
		if saves != null:
			var dir := make_save_dir()
			saves.set("base_dir", dir)
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


## Nächste Handlung wie die Karte sie zeigt: Ein noch nicht begonnener Schritt, dessen Prompt die Karte schon als Vorschau zeigt (Ansage
## und Aktion auf einem Bildschirm; `BeginStep` geht erst mit der ersten Handlung), gilt als offener Prompt.
static func effective_of(next: Dictionary) -> Dictionary:
	if str(next.get("kind")) == "begin_step" and not (next.get("preview", {}) as Dictionary).is_empty():
		var shown: Dictionary = (next["preview"] as Dictionary).duplicate()
		shown["needs_begin"] = true
		shown["decoys"] = next.get("decoys", [])
		return shown
	return next


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


## Werkzeuge im Optionenmenü des Cockpits (Privat, Rollen zeigen, Spielleitung, Lexikon, Regelbuch): Wie die Spielleitung öffnet die
## Hilfe zuerst die Lasche „Optionen“, falls der Knopf im geschlossenen Menü liegt. Ergebnis: Knopf oder null.
func tool_button(screen: Node, node_name: String) -> BaseButton:
	var b := screen.find_child(node_name, true, false) as BaseButton
	if b == null:
		return null
	var menu := screen.find_child("ToolsMenu", true, false) as Control
	if menu != null and menu.is_ancestor_of(b) and not menu.visible:
		var options := screen.find_child("OptionsButton", true, false) as BaseButton
		if options != null and not options.disabled:
			options.pressed.emit()
			await frames(2)
	return b


## Löst die Aktion eines Buttons so aus, wie Maus und Touch es tun (Signal `pressed`). Ein fehlender oder gesperrter
## Button ist ein Fehler des Tests (F-T01): echte Bedienung kann ihn nicht auslösen.
func press(button: BaseButton) -> void:
	if button == null:
		fail("press: Button fehlt")
		return
	if button.disabled:
		fail("press: Button %s ist gesperrt" % button.name)
		return
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	else:
		button.pressed.emit()
	await frames(3)


## Wie `press`, aber ohne Prüfung: für Tests, die gerade belegen, dass ein gesperrter Button nichts auslöst.
func press_blocked(button: BaseButton) -> void:
	if button == null:
		fail("press_blocked: Button fehlt")
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


## Sichtbarer Teil eines Controls: sein Rechteck, beschnitten auf alle umgebenden ScrollContainer und Controls mit `clip_contents`
## (deren Inhalt außerhalb der Fläche nicht gezeichnet wird, z. B. das überstehende Hintergrundbild). Leeres Rechteck, wenn nichts davon sichtbar ist.
func clipped_rect(c: Control) -> Rect2:
	var r := rect_of(c)
	var parent := c.get_parent()
	while parent != null:
		if parent is ScrollContainer or (parent is Control and (parent as Control).clip_contents):
			r = r.intersection(rect_of(parent as Control))
			if not r.has_area():
				return Rect2()
		parent = parent.get_parent()
	return r


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
## Sichtbare und antippbare Teile eines Porträtplatzes (Porträtkreis samt Nummer, Namensschild) in globalen Koordinaten. Die
## Steuerelemente der Plätze liegen auf einer Ellipse und überlappen diagonal, ihre Teile nicht (P3, GameSeatToken).
func seat_parts(token: Control) -> Array[Rect2]:
	var portrait: Rect2 = token.call("portrait_rect")
	var plate: Rect2 = token.call("plate_rect")
	var origin := token.get_global_position()
	return [Rect2(origin + portrait.position, portrait.size), Rect2(origin + plate.position, plate.size)]


## Berührt ein Rechteck einen Platz (rundes Porträt oder Namensschild)? Das Porträtquadrat selbst zählt nicht: Es überlappt diagonal.
func seat_hits_rect(token: Control, rect: Rect2) -> bool:
	if not rect.has_area():
		return false
	var parts := seat_parts(token)
	var portrait := parts[0]
	var center := portrait.get_center()
	var nearest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_to(nearest) < portrait.size.x * 0.5 - 0.5 or overlaps(parts[1], rect)


## Überlappen sich zwei Plätze (Porträtkreise, Namensschilder)?
func seats_overlap(a: Control, b: Control) -> bool:
	var pa := seat_parts(a)
	var pb := seat_parts(b)
	if pa[0].get_center().distance_to(pb[0].get_center()) < pa[0].size.x - 0.5:
		return true
	return seat_hits_rect(a, pb[1]) or seat_hits_rect(b, pa[1])


func rect_of(c: Control) -> Rect2:
	return c.get_global_rect()


func inside(inner: Rect2, outer: Rect2, tolerance: float = 0.5) -> bool:
	return inner.position.x >= outer.position.x - tolerance and inner.position.y >= outer.position.y - tolerance \
		and inner.end.x <= outer.end.x + tolerance and inner.end.y <= outer.end.y + tolerance


## Echte Überlappung (Berührung an Kanten zählt nicht).
func overlaps(a: Rect2, b: Rect2, tolerance: float = 0.5) -> bool:
	if not a.has_area() or not b.has_area():
		return false  # nicht sichtbarer (weggescrollter) Teil überdeckt nichts
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


# --- Spieler-Setup --------------------------------------------------------------------------------

func setup_of(shell: Control) -> Object:
	var ctx := context_of(shell)
	return ctx.get("setup") as Object if ctx != null else null


## Hauptmenü → Neue Partie (wie ein Benutzer) und liefert die Ansicht.
func open_new_game(shell: Control) -> Control:
	await navigate(shell, &"main_menu")
	await navigate(shell, &"new_game")
	return current_screen(shell)


## Vorbereitung „Neue Partie“ nur über sichtbare Buttons bis zum Rollenschritt: Spielerzahl mit Plus/Minus, Akt-Karte, Weiter, Namen per
## „Mehrere Namen einfügen“, Weiter; mit `cards` zusätzlich „Totenreichkarten verwenden“. Der Start („Spiel starten“ in der Fußzeile) bleibt
## dem Aufrufer. Nur die Seed-Quelle ist fest. Liefert die Ansicht.
func prepare_through_buttons(shell: Control, count: int, act: StringName = &"akt3", seed_value: int = 20260930, cards: bool = false) -> Control:
	var screen := await open_new_game(shell)
	var setup := setup_of(shell)
	setup.set("seed_source", func() -> int: return seed_value)
	for guard: int in 40:
		var now := int((setup.call("view") as Dictionary)["player_count"])
		if now == count:
			break
		await press(find_button(screen, "PlusButton" if now < count else "MinusButton"))
	await press(find_button(screen, "ActCard_%s" % String(act)))
	await press(find_button(screen, "NextButton"))
	await press(find_button(screen, "ImportToggleButton"))
	await type_text(find_node(screen, "ImportText") as TextEdit, ", ".join(numbered_names(count)))
	await press(find_button(screen, "ImportConfirmButton"))
	await press(find_button(screen, "NextButton"))
	await press(find_button(screen, "ProposalButton"))  # Schritt 3 startet leer (DA-91): „Empfehlung übernehmen“
	if cards:
		await press(find_button(screen, "DeathCardsToggle"))
		await frames(3)
	return screen


## Personen direkt über die Anwendungsschicht anlegen (Vorbereitung, kein UI-Pfad).
func seed_names(shell: Control, names: Array) -> void:
	var s := setup_of(shell)
	if s == null:
		fail("Setup-Anwendungsschicht fehlt im Kontext")
		return
	for n: Variant in names:
		s.call("add_person", str(n))
	await frames(2)


func numbered_names(count: int, prefix: String = "Person") -> Array[String]:
	var out: Array[String] = []
	for i: int in count:
		out.append("%s %d" % [prefix, i + 1])
	return out


## Zulässige Namen mit genau 32 Zeichen, auch einer ohne Leerzeichen.
func long_names(count: int) -> Array[String]:
	var out: Array[String] = []
	for i: int in count:
		out.append("Wolfgangamadeusmozartsalieri%04d" % i if i % 3 == 0 else "Maximiliane-Friederike von Ho%03d" % i)
	return out


## Sichtbare Personenzeilen (Knoten mit `person_id`) in Listenreihenfolge.
func person_rows(screen: Node) -> Array[Control]:
	var out: Array[Control] = []
	var list := find_node(screen, "PersonList")
	if list == null:
		return out
	for child: Node in list.get_children():
		if child is Control and child.get("person_id") != null and (child as Control).visible:
			out.append(child as Control)
	return out


func row_ids(screen: Node) -> Array[int]:
	var out: Array[int] = []
	for row: Control in person_rows(screen):
		out.append(int(row.get("person_id")))
	return out


func row_label(row: Node, label_name: String) -> String:
	var label := find_node(row, label_name) as Label
	return label.text if label != null else ""


## Tippt Text in ein Eingabefeld, wie es die Tastatur tut (Signal `text_changed`).
func type_text(field: Control, text: String) -> void:
	if field is LineEdit:
		(field as LineEdit).text = text
		(field as LineEdit).text_changed.emit(text)
	elif field is TextEdit:
		(field as TextEdit).text = text
		(field as TextEdit).text_changed.emit()
	await frames(1)


func key_mod(keycode: Key, shift: bool) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = keycode
		e.physical_keycode = keycode
		e.shift_pressed = shift
		e.pressed = pressed
		tree.root.push_input(e)
		await frames(1)
	await frames(2)


func focus_owner() -> Control:
	return tree.root.gui_get_focus_owner()
