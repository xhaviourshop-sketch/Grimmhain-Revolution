extends UiTestCase
## Anzeige-Timer und Speichern (P3): Der Timer liegt als eigener Block `ui` in der Speicherhülle, nie im Regelkern. Restzeit und Pause
## überstehen Speichern und Fortsetzen ohne Zeitsprung; ein Ablauf oder jede Timer-Bedienung sendet keinen Befehl, ändert den Kern nicht
## und verbraucht keinen Zufall. Außerdem: der Schalter „Nacht-Timer anzeigen“ bleibt in den Einstellungen erhalten.


func _context() -> AppContext:
	var context := AppContext.new()
	context.saves = SaveService.new(make_save_dir())
	var r := context.session.submit(Fixtures.start_roles(Fixtures.unique_roles(7), 1))
	assert_true(r.ok, "Partie gestartet (%s)" % r.error)
	return context


func _core_of(context: AppContext) -> String:
	return context.session.save_text()


func test_envelope_has_no_ui_block_until_a_duration_is_set() -> void:
	var context := _context()
	context.autosave()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(context.saves.path_for(context.session.round_id())))
	assert_false(envelope.has("ui"), "ohne Timer bleibt die Hülle wie zuvor")
	context.timer.switch_group(DisplayTimer.GROUP_NIGHT)
	context.timer.set_duration(DisplayTimer.GROUP_NIGHT, 300)
	context.autosave()
	envelope = JSON.parse_string(FileAccess.get_file_as_string(context.saves.path_for(context.session.round_id())))
	assert_true(envelope.has("ui"), "mit Timer steht ein Block `ui` in der Hülle")
	assert_eq((envelope["ui"] as Dictionary).keys(), ["timer"], "nur der Timer")
	var timer: Dictionary = (envelope["ui"] as Dictionary)["timer"]
	var keys := timer.keys()
	keys.sort()
	assert_eq(keys, ["day", "group", "night", "remaining", "running"], "nur Zahlen und Wahrheitswerte")
	var core: Variant = JSON.parse_string(str(envelope["core"]))
	assert_false(JSON.stringify(core).contains("remaining"), "nichts davon im Regelkern")


func test_remaining_time_and_pause_survive_saving_and_resuming() -> void:
	var context := _context()
	context.timer.switch_group(DisplayTimer.GROUP_NIGHT)
	context.timer.set_duration(DisplayTimer.GROUP_NIGHT, 600)
	context.timer.set_duration(DisplayTimer.GROUP_DAY, 240)
	context.timer.start()
	context.timer.tick(125.0)
	context.timer.pause()
	context.autosave()
	var other := AppContext.new()
	other.saves = SaveService.new(context.saves.base_dir)
	var loaded := other.resume(context.session.round_id())
	assert_true(bool(loaded["ok"]), "Partie geladen")
	assert_eq(other.timer.remaining, 475.0, "Restzeit ohne Zeitsprung")
	assert_false(other.timer.running, "Pause bleibt")
	assert_eq(int(other.timer.durations["night"]), 600, "Dauer Nacht")
	assert_eq(int(other.timer.durations["day"]), 240, "Dauer Tag")
	assert_eq(_core_of(other), _core_of(context), "Regelstand identisch")


func test_a_running_timer_resumes_running_from_the_saved_remaining_time() -> void:
	var context := _context()
	context.timer.switch_group(DisplayTimer.GROUP_NIGHT)
	context.timer.set_duration(DisplayTimer.GROUP_NIGHT, 100)
	context.timer.start()
	context.timer.tick(30.0)
	context.autosave()
	var other := AppContext.new()
	other.saves = SaveService.new(context.saves.base_dir)
	other.resume(context.session.round_id())
	assert_eq(other.timer.remaining, 70.0, "Restzeit zum Speicherzeitpunkt")
	assert_true(other.timer.running, "läuft weiter, zählt aber ab dem Laden (keine Wanduhr)")


func test_an_old_save_without_ui_loads_with_an_empty_timer() -> void:
	var context := _context()
	context.autosave()  # ohne Timer: Hülle ohne `ui`
	var other := AppContext.new()
	other.saves = SaveService.new(context.saves.base_dir)
	other.timer.set_duration(DisplayTimer.GROUP_DAY, 99)
	var loaded := other.resume(context.session.round_id())
	assert_true(bool(loaded["ok"]), "ältere Datei lädt")
	assert_false(other.timer.is_set() or int(other.timer.durations["day"]) > 0, "Timer leer")


func test_a_corrupt_ui_block_does_not_stop_the_game_from_loading() -> void:
	var context := _context()
	context.autosave()
	var path := context.saves.path_for(context.session.round_id())
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	envelope["ui"] = {"timer": {"day": "viel", "night": 0, "group": "day", "remaining": 1, "running": false}}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()
	var other := AppContext.new()
	other.saves = SaveService.new(context.saves.base_dir)
	var loaded := other.resume(context.session.round_id())
	assert_true(bool(loaded["ok"]), "Partie lädt trotz ungültigem Block")
	assert_false(other.timer.is_set(), "Timer leer statt falsch")
	assert_eq(_core_of(other), _core_of(context), "Regelstand unberührt")


func test_a_different_game_starts_with_an_empty_timer() -> void:
	var context := _context()
	context.timer.switch_group(DisplayTimer.GROUP_DAY)
	context.timer.set_duration(DisplayTimer.GROUP_DAY, 500)
	context.session.reset()
	assert_false(context.timer.is_set(), "nach Verwerfen kein Timer")
	assert_eq(int(context.timer.durations["day"]), 0, "Dauer gelöscht")


func test_timer_use_sends_no_command_and_changes_no_rule_state() -> void:
	var context := _context()
	var commands_before := context.session.commands().size()
	var core_before := _core_of(context)
	var events := [0]
	context.session.events_applied.connect(func(_e: Array[GameEvent]) -> void: events[0] += 1)
	context.timer.switch_group(DisplayTimer.GROUP_NIGHT)
	context.timer.set_duration(DisplayTimer.GROUP_NIGHT, 5)
	context.timer.start()
	context.timer.tick(2.0)
	context.timer.pause()
	context.timer.start()
	context.timer.tick(60.0)
	assert_true(context.timer.is_expired(), "abgelaufen")
	context.timer.reset()
	context.timer.clear()
	assert_eq(context.session.commands().size(), commands_before, "kein Befehl")
	assert_eq(events[0], 0, "kein Regelereignis")
	assert_eq(_core_of(context), core_before, "Regelkern unverändert, auch Zufall und Zähler")


func test_expiry_in_the_cockpit_changes_nothing_but_the_display() -> void:
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell == null:
		return
	var s := session_of(shell)
	s.call("submit", Fixtures.start_roles(Fixtures.unique_roles(7), 1))
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var screen := current_screen(shell)
	await press(find_button(screen, "StartNightButton"))
	var core_before: String = s.call("save_text")
	var count_before := int((s.call("view") as Dictionary)["command_count"])
	await press(find_button(screen, "TimerNightPlusButton"))
	assert_eq(int(context_of(shell).get("timer").get("durations")["night"]), 60, "eine Minute eingestellt")
	await press(find_button(screen, "TimerButton"))
	assert_true(bool(context_of(shell).get("timer").get("running")), "läuft")
	context_of(shell).get("timer").call("tick", 120.0)
	await frames(3)
	var button := find_button(screen, "TimerButton")
	assert_eq(button.text, "0:00", "Anzeige steht auf 0:00")
	assert_eq(int((s.call("view") as Dictionary)["command_count"]), count_before, "kein Befehl durch Ablauf")
	assert_eq(String(s.call("save_text")), core_before, "Regelstand unverändert")
	assert_true(find_button(screen, "ConfirmTargetsButton") != null, "die Nacht ist weiter bedienbar")


func test_night_timer_can_be_hidden_in_the_options_and_the_choice_is_saved() -> void:
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell == null:
		return
	session_of(shell).call("submit", Fixtures.start_roles(Fixtures.unique_roles(7), 1))
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var screen := current_screen(shell)
	await press(find_button(screen, "StartNightButton"))
	var button := find_button(screen, "TimerButton")
	assert_true(button.is_visible_in_tree(), "Nacht-Timer standardmäßig sichtbar")
	var toggle := find_node(screen, "NightTimerToggle") as BaseButton
	assert_true(toggle.button_pressed, "Schalter an")
	await press(toggle)
	assert_false(bool(settings_of(shell).get("show_night_timer")), "Einstellung aus")
	assert_false(button.is_visible_in_tree(), "Nacht-Timer verborgen")
	# Einstellungsdatei
	var path := make_save_dir().path_join("settings.json")
	var store := SettingsStore.new(path)
	var settings := AppSettings.new()
	settings.set_show_night_timer(false)
	assert_true(bool(store.save(settings)["ok"]), "gespeichert")
	var loaded := AppSettings.new()
	store.load_into(loaded)
	assert_false(loaded.show_night_timer, "Wert bleibt erhalten")
	var fresh := AppSettings.new()
	SettingsStore.new(path.get_base_dir().path_join("none.json")).load_into(fresh)
	assert_true(fresh.show_night_timer, "ohne Datei: Standard an")
