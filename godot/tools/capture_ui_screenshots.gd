extends SceneTree
## Erzeugt Prüf-Screenshots der UI (keine Produktionsassets).
## Braucht einen echten Renderer; headless gibt es keine Bildausgabe. In der Cloud/CI:
##   xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- [--out=<Ordner>] [--only=<Teilstring>]
## Ohne --out landen die Bilder unter docs/evidence/<Gruppe>/ (Repo-Wurzel).
## Jede Aufnahme: logische Größe = Fenstergröße (ohne Skalierung), reduzierte Bewegung an,
## damit kein Übergang mitten im Bild steht. Tastaturfokus ist wie in der App sichtbar.
## Vorbereitung (`prepare`) nutzt nur öffentliche Wege: AppContext.setup und echte Buttons.

const MAIN_SCENE := "res://app/main.tscn"
const NAMES := ["Anna", "Ben", "Clara", "Dimitri", "Elif", "Frieda", "Gustav", "Hanna", "Ilja", "Jana", "Kemal", "Lena",
	"Mats", "Nora", "Oskar", "Paula", "Quentin", "Rosa", "Sami", "Tilda", "Umut", "Vera", "Wim", "Zoë"]
## [Gruppe, Datei, Größe, Sprache, Ansicht, Vorbereitung]
const SHOTS := [
	["ui-foundation", "01-start-1024x768-de.png", Vector2i(1024, 768), "de", &"start", ""],
	["ui-foundation", "02-main-menu-1024x768-de.png", Vector2i(1024, 768), "de", &"main_menu", ""],
	["ui-foundation", "03-cockpit-1024x768-de.png", Vector2i(1024, 768), "de", &"cockpit", ""],
	["ui-foundation", "04-main-menu-1280x800-en.png", Vector2i(1280, 800), "en", &"main_menu", ""],
	["ui-foundation", "05-settings-1280x800-de.png", Vector2i(1280, 800), "de", &"settings", ""],
	["player-setup", "01-empty-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", ""],
	["player-setup", "02-six-players-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_six"],
	["player-setup", "03-24-players-scrolled-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_full_scrolled"],
	["player-setup", "04-import-open-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_import"],
	["player-setup", "05-duplicates-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_duplicates"],
	["player-setup", "06-edit-mode-1280x800-en.png", Vector2i(1280, 800), "en", &"new_game", "_prepare_edit"],
	["player-setup", "07-remove-dialog-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_remove"],
	["player-setup", "08-confirmed-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_confirmed"],
	["role-setup", "01-roles-suggestion-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_roles_suggestion"],
	["role-setup", "02-roles-too-few-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_roles_too_few"],
	["role-setup", "03-roles-valid-manual-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_roles_valid"],
	["role-setup", "04-roles-1280x800-en.png", Vector2i(1280, 800), "en", &"new_game", "_prepare_roles_suggestion"],
	["role-setup", "05-suggestion-overwrite-dialog-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_roles_overwrite"],
	["role-setup", "06-distribution-mode-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_distribution_mode"],
	["role-setup", "07-random-hidden-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_random_hidden"],
	["role-setup", "08-secret-open-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_secret_open"],
	["role-setup", "09-manual-partial-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_manual_partial"],
	["role-setup", "10-manual-picker-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_manual_picker"],
	["role-setup", "11-manual-complete-1280x800-en.png", Vector2i(1280, 800), "en", &"new_game", "_prepare_manual_complete"],
	["role-setup", "12-confirmed-ready-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_distribution_confirmed"],
	["role-setup", "13-decoy-wolf-secret-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_decoy_secret"],
	["role-setup", "14-decoy-missing-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_decoy_missing"],
	["role-setup", "15-decoy-chosen-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_decoy_chosen"],
	["role-setup", "16-decoy-two-copies-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_decoy_two"],
	["role-setup", "17-decoy-manual-picker-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_decoy_manual_picker"],
	["role-setup", "18-decoy-random-closed-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_decoy_random_closed"],
	["role-setup", "19-decoy-random-open-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_decoy_random_open"],
	["seating-setup", "01-six-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_seating_six"],
	["seating-setup", "02-twentyfour-1024x768-de.png", Vector2i(1024, 768), "de", &"new_game", "_prepare_seating_full"],
	["seating-setup", "03-twelve-1280x800-en.png", Vector2i(1280, 800), "en", &"new_game", "_prepare_seating_twelve"],
	["seating-setup", "04-twentyfour-1920x1080-de.png", Vector2i(1920, 1080), "de", &"new_game", "_prepare_seating_full"],
	["seating-setup", "05-selected-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_seating_selected"],
	["seating-setup", "06-dragging-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_seating_dragging"],
	["seating-setup", "07-swapped-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_seating_swapped"],
	["seating-setup", "08-confirmed-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_seating_confirmed"],
	["seating-setup", "09-long-names-1024x768-en.png", Vector2i(1024, 768), "en", &"new_game", "_prepare_seating_long_names"],
	["game-start", "01-ready-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_seating_confirmed"],
	["game-start", "02-ready-twentyfour-1024x768-en.png", Vector2i(1024, 768), "en", &"new_game", "_prepare_start_ready_full"],
	["game-start", "03-cockpit-started-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_start_started"],
	["game-start", "04-cockpit-started-1024x768-en.png", Vector2i(1024, 768), "en", &"new_game", "_prepare_start_started"],
	["game-start", "05-rejected-running-1280x800-de.png", Vector2i(1280, 800), "de", &"new_game", "_prepare_start_rejected"],
]
const SCREENSHOT_SEED := 20260926  ## fester Setup-Seed, damit die Bilder reproduzierbar sind


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Screenshots brauchen einen Renderer (z. B. xvfb-run), headless ist keine Bildausgabe möglich.")
		quit(2)
		return
	var out_root := ProjectSettings.globalize_path("res://").path_join("../docs/evidence").simplify_path()
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_root = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	var failures := 0
	var count := 0
	for shot: Array in SHOTS:
		var path := out_root.path_join(shot[0]).path_join(shot[1])
		if only != "" and not path.contains(only):
			continue
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		count += 1
		var ok: bool = await _capture(path, shot[2], shot[3], shot[4], shot[5])
		if not ok:
			failures += 1
	print("%d Screenshots, %d Fehler, Ordner %s" % [count, failures, out_root])
	quit(0 if failures == 0 else 1)


func _capture(path: String, size: Vector2i, locale: String, screen: StringName, prepare: String) -> bool:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for attempt: int in 20:
		root.size = size
		await process_frame
		if root.get_visible_rect().size == Vector2(size):
			break
	var context := AppContext.new()
	context.settings.set_reduced_motion(true)
	context.settings.set_language(locale)
	var shell := (load(MAIN_SCENE) as PackedScene).instantiate() as AppShell
	shell.app_context = context
	root.add_child(shell)
	if screen != &"start" and screen != &"main_menu":
		shell.navigate(&"main_menu")
	shell.navigate(screen)
	for i: int in 4:
		await process_frame
	if prepare != "":
		await call(prepare, shell)
	for i: int in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var ok := image != null and image.get_size() == size
	if ok:
		ok = image.save_png(path) == OK
	print("%s  %s  %s %s" % ["ok  " if ok else "FAIL", path.get_file(), size, image.get_size() if image != null else "kein Bild"])
	if root.gui_is_dragging():  # Aufnahme mitten im Ziehen: Ziehen beenden, Maustaste lösen
		root.gui_cancel_drag()
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		root.push_input(up)
	root.remove_child(shell)
	shell.free()
	return ok



# --- Vorbereitungen Spieler-Setup --------------------------------------------------------------------

func _add_names(shell: AppShell, names: Array) -> void:
	for n: Variant in names:
		shell.get_app_context().setup.add_person(str(n))
	await process_frame


func _node(shell: AppShell, node_name: String) -> Node:
	return shell.current_screen().find_child(node_name, true, false)


func _rows(shell: AppShell) -> Array[PersonRow]:
	var out: Array[PersonRow] = []
	for child: Node in _node(shell, "PersonList").get_children():
		if child is PersonRow:
			out.append(child as PersonRow)
	return out


func _prepare_six(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 6))


func _prepare_full_scrolled(shell: AppShell) -> void:
	await _add_names(shell, NAMES)
	for i: int in 3:
		await process_frame
	var scroll := _node(shell, "PersonScroll") as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _prepare_import(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 4))
	(_node(shell, "ImportToggleButton") as Button).pressed.emit()
	var text := _node(shell, "ImportText") as TextEdit
	text.text = "Elif, Frieda; Gustav\nHanna\nIlja, Jana"
	text.text_changed.emit()


func _prepare_duplicates(shell: AppShell) -> void:
	await _add_names(shell, ["Anna", "Ben", "Clara", "anna", "Dimitri", "Ben ", "Elif", "Frieda"])


func _prepare_edit(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 8))
	_rows(shell)[2].edit_button().pressed.emit()
	await process_frame


func _prepare_remove(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 8))
	var remove := _rows(shell)[1].remove_button()
	remove.grab_focus()
	remove.pressed.emit()
	await process_frame


func _prepare_confirmed(shell: AppShell) -> void:
	await _add_names(shell, NAMES.slice(0, 8))
	(_node(shell, "ConfirmPlayersButton") as Button).pressed.emit()
	await process_frame


# --- Vorbereitungen Rollen-Setup ---------------------------------------------------------------------

func _press(shell: AppShell, node_name: String) -> void:
	(_node(shell, node_name) as BaseButton).pressed.emit()
	for i: int in 3:
		await process_frame


## Personen anlegen, bestätigen und per Button zum Rollenschritt.
func _to_roles(shell: AppShell, count: int) -> void:
	shell.get_app_context().setup.seed_source = func() -> int: return SCREENSHOT_SEED
	await _add_names(shell, NAMES.slice(0, count))
	await _press(shell, "ConfirmPlayersButton")
	await _press(shell, "ToRolesButton")
	shell.get_toast().hide_message()  # Meldung des vorigen Schritts nicht über den neuen legen


func _set_counts(shell: AppShell, counts: Dictionary) -> void:
	for role: Variant in counts:
		shell.get_app_context().setup.set_role_count(StringName(str(role)), int(counts[role]))
	await process_frame


## Wie `_to_roles`, dann Pool (leer = Vorschlag) bestätigen und zur Verteilung.
func _to_distribution(shell: AppShell, count: int, counts: Dictionary = {}) -> void:
	await _to_roles(shell, count)
	if counts.is_empty():
		await _press(shell, "SuggestButton")
	else:
		await _set_counts(shell, counts)
	await _choose_decoys(shell, [&"waldhexe", &"das-orakel"])
	await _press(shell, "ConfirmRolesButton")
	shell.get_toast().hide_message()


## DR-08: Scheinrollen der Trugbilderwolf-Kopien ausdrücklich wählen (der Reihe nach).
func _choose_decoys(shell: AppShell, roles: Array) -> void:
	var setup := shell.get_app_context().setup
	var decoys: Array = setup.view()["roles"]["decoys"]
	for i: int in mini(decoys.size(), roles.size()):
		setup.set_decoy_appearance(int((decoys[i] as Dictionary)["copy_id"]), roles[i])
	await process_frame


## Scheinrollen-Bereich öffnen und die Rollenliste dorthin scrollen.
func _open_decoys(shell: AppShell) -> void:
	await _press(shell, "DecoyRevealButton")
	for i: int in 3:
		await process_frame
	var scroll := _node(shell, "RoleScroll") as ScrollContainer
	var section := _node(shell, "DecoySection") as Control
	scroll.scroll_vertical = int(section.position.y + section.size.y - scroll.size.y + 16.0)


func _assignment_rows(shell: AppShell) -> Array[AssignmentRow]:
	var out: Array[AssignmentRow] = []
	for child: Node in _node(shell, "AssignmentList").get_children():
		if child is AssignmentRow:
			out.append(child as AssignmentRow)
	return out


## Manuell: die ersten `count` Personen der Reihe nach mit dem Pool belegen.
func _assign_first(shell: AppShell, count: int) -> void:
	var setup := shell.get_app_context().setup
	var view := setup.view()
	var pool: Array = view["roles"]["pool"]
	var persons: Array = view["persons"]
	var order := [9, 0, 5, 2, 7, 1, 11, 3, 10, 4, 8, 6]  # gemischte Poolpositionen, damit es nicht sortiert aussieht
	for i: int in count:
		setup.assign_role(int((persons[i] as Dictionary)["person_id"]), StringName(str(pool[order[i] % pool.size()])))
	await process_frame


func _prepare_roles_suggestion(shell: AppShell) -> void:
	await _to_roles(shell, 12)
	await _press(shell, "SuggestButton")


func _prepare_roles_too_few(shell: AppShell) -> void:
	await _to_roles(shell, 12)
	await _set_counts(shell, {"werwolf": 2, "dorfbewohner": 6})


func _prepare_roles_valid(shell: AppShell) -> void:
	await _to_roles(shell, 10)
	await _set_counts(shell, {"werwolf": 1, "trugbilderwolf": 1, "schutzengel": 1, "das-orakel": 1, "manipulator": 1, "dorfbewohner": 5})
	await _choose_decoys(shell, [&"waldhexe"])


func _prepare_roles_overwrite(shell: AppShell) -> void:
	await _to_roles(shell, 12)
	await _set_counts(shell, {"werwolf": 2, "dorfbewohner": 3})
	await _press(shell, "SuggestButton")


func _prepare_distribution_mode(shell: AppShell) -> void:
	await _to_distribution(shell, 12)


func _prepare_random_hidden(shell: AppShell) -> void:
	await _to_distribution(shell, 12)
	await _press(shell, "DistributeButton")


func _prepare_secret_open(shell: AppShell) -> void:
	await _to_distribution(shell, 12)
	await _press(shell, "DistributeButton")
	await _press(shell, "RevealButton")


func _prepare_manual_partial(shell: AppShell) -> void:
	await _to_distribution(shell, 12)
	await _press(shell, "ModeManualButton")
	await _assign_first(shell, 5)
	await _press(shell, "RevealButton")


func _prepare_manual_picker(shell: AppShell) -> void:
	await _to_distribution(shell, 12)
	await _press(shell, "ModeManualButton")
	await _assign_first(shell, 5)
	var choose := _assignment_rows(shell)[1].choose_button()
	choose.grab_focus()
	choose.pressed.emit()
	await process_frame


func _prepare_manual_complete(shell: AppShell) -> void:
	await _to_distribution(shell, 12)
	await _press(shell, "ModeManualButton")
	await _assign_first(shell, 12)
	await _press(shell, "RevealButton")


func _prepare_distribution_confirmed(shell: AppShell) -> void:
	await _to_distribution(shell, 12)
	await _press(shell, "DistributeButton")
	await _press(shell, "ConfirmDistributionButton")


func _prepare_decoy_secret(shell: AppShell) -> void:
	await _to_distribution(shell, 10, {"werwolf": 1, "trugbilderwolf": 2, "manipulator": 1, "schutzengel": 1, "dorfbewohner": 5})
	await _press(shell, "DistributeButton")
	await _press(shell, "RevealButton")
	shell.get_toast().hide_message()
	for i: int in 3:
		await process_frame
	var entries: Array = shell.get_app_context().setup.view()["distribution"]["assignment"]
	var rows := _assignment_rows(shell)
	for i: int in entries.size():
		if str((entries[i] as Dictionary)["role"]) == "trugbilderwolf":
			(_node(shell, "AssignmentScroll") as ScrollContainer).ensure_control_visible(rows[mini(i + 1, rows.size() - 1)])
			break


# --- Vorbereitungen Trugbilderwolf-Scheinrolle (DR-08) --------------------------------------------------

const DECOY_COUNTS := {"werwolf": 1, "trugbilderwolf": 2, "manipulator": 1, "schutzengel": 1, "dorfbewohner": 5}


func _prepare_decoy_missing(shell: AppShell) -> void:
	await _to_roles(shell, 10)
	await _set_counts(shell, DECOY_COUNTS)
	await _choose_decoys(shell, [&"waldhexe"])
	await _open_decoys(shell)


func _prepare_decoy_chosen(shell: AppShell) -> void:
	await _to_roles(shell, 9)
	await _set_counts(shell, {"werwolf": 1, "trugbilderwolf": 1, "manipulator": 1, "schutzengel": 1, "dorfbewohner": 5})
	await _choose_decoys(shell, [&"lehrling"])
	await _open_decoys(shell)


func _prepare_decoy_two(shell: AppShell) -> void:
	await _to_roles(shell, 10)
	await _set_counts(shell, DECOY_COUNTS)
	await _choose_decoys(shell, [&"waldhexe", &"das-orakel"])
	await _open_decoys(shell)


func _prepare_decoy_manual_picker(shell: AppShell) -> void:
	await _to_distribution(shell, 10, DECOY_COUNTS)
	await _press(shell, "ModeManualButton")
	var choose := _assignment_rows(shell)[0].choose_button()
	choose.grab_focus()
	choose.pressed.emit()
	await process_frame


func _prepare_decoy_random_closed(shell: AppShell) -> void:
	await _to_distribution(shell, 10, DECOY_COUNTS)
	await _press(shell, "DistributeButton")
	shell.get_toast().hide_message()


func _prepare_decoy_random_open(shell: AppShell) -> void:
	await _to_distribution(shell, 10, DECOY_COUNTS)
	await _press(shell, "DistributeButton")
	await _press(shell, "RevealButton")
	shell.get_toast().hide_message()


# --- Vorbereitungen Sitzordnung ----------------------------------------------------------------------

## Personen `names`, Vorschlag, Zufallsverteilung bestätigt, dann über „Weiter zur Sitzordnung“.
func _to_seating(shell: AppShell, names: Array) -> void:
	shell.get_app_context().setup.seed_source = func() -> int: return SCREENSHOT_SEED
	await _add_names(shell, names)
	await _press(shell, "ConfirmPlayersButton")
	await _press(shell, "ToRolesButton")
	await _press(shell, "SuggestButton")
	await _choose_decoys(shell, [&"waldhexe", &"das-orakel"])
	await _press(shell, "ConfirmRolesButton")
	await _press(shell, "DistributeButton")
	await _press(shell, "ConfirmDistributionButton")
	await _press(shell, "ToSeatingButton")
	shell.get_toast().hide_message()


func _seat(shell: AppShell, index: int) -> SeatToken:
	return (_node(shell, "SeatCircle") as SeatCircle).tokens()[index]


func _prepare_seating_six(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 6))


func _prepare_seating_twelve(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 12))


func _prepare_seating_full(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 24))


func _prepare_seating_selected(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 12))
	_seat(shell, 2).grab_focus()
	_seat(shell, 2).pressed.emit()


## Echtes Ziehen über den Viewport ohne Loslassen: Vorschau, abgeblendete Quelle, hervorgehobenes Ziel.
func _prepare_seating_dragging(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 12))
	var start := _seat(shell, 0).get_global_rect().get_center()
	var goal := _seat(shell, 6).get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = start
	down.global_position = start
	root.push_input(down)
	await process_frame
	var last := start
	for i: int in range(1, 11):
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		move.position = start.lerp(goal, i / 10.0)
		move.global_position = move.position
		move.relative = move.position - last
		last = move.position
		root.push_input(move)
		await process_frame


func _prepare_seating_swapped(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 12))
	_seat(shell, 1).pressed.emit()
	await process_frame
	_seat(shell, 7).pressed.emit()
	await process_frame
	shell.get_toast().hide_message()


func _prepare_seating_confirmed(shell: AppShell) -> void:
	await _prepare_seating_swapped(shell)
	await _press(shell, "ConfirmSeatingButton")
	shell.get_toast().hide_message()


func _prepare_seating_long_names(shell: AppShell) -> void:
	var names: Array = []
	for i: int in 24:
		names.append("Wolfgangamadeusmozartsalieri%04d" % i if i % 3 == 0 else "Maximiliane-Friederike von Ho%03d" % i)
	await _to_seating(shell, names)


# --- Vorbereitungen Spielstart -----------------------------------------------------------------------

func _prepare_start_ready_full(shell: AppShell) -> void:
	await _to_seating(shell, NAMES.slice(0, 24))
	await _press(shell, "ConfirmSeatingButton")
	shell.get_toast().hide_message()


## „Partie starten“ über den echten Button: Cockpit mit aktiver Partie und Statusmeldung.
func _prepare_start_started(shell: AppShell) -> void:
	await _prepare_seating_confirmed(shell)
	await _press(shell, "StartGameButton")


## Echter Ablauf: eine Partie starten, dann erneut „Neue Partie“ bis zum Start. Der Regelkern lehnt
## den zweiten Start ab; die Fußzeile meldet es, Setup und Sitzung bleiben unverändert.
func _prepare_start_rejected(shell: AppShell) -> void:
	await _prepare_start_started(shell)
	shell.navigate(&"main_menu")
	shell.navigate(&"new_game")
	for i: int in 4:
		await process_frame
	await _prepare_seating_confirmed(shell)
	await _press(shell, "StartGameButton")
