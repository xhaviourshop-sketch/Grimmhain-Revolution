extends UiTestCase
## Schichtengrenzen (Tests 16 bis 18): Core kennt keine UI, UI verändert keinen
## GameState, die Anwendungsschicht reicht Befehle unverändert an den Regelkern.

## Klassen und Pfade der UI- und Anwendungsschicht, die im Core nie vorkommen dürfen.
const UI_NAMES := "\\b(AppShell|AppContext|AppSettings|AppPlatform|GameSession|ScreenRouter|ScreenIds|BaseScreen|GrimmButton|GrimmLabel|GrimmToggle|HeaderBar|ConfirmDialog|ToastHost|ThemeTokens|ThemeFactory|TranslationServer)\\b|res://(app|content)/"
## Regelkern-Klassen, die nur die Anwendungsschicht (app/session/) verwenden darf.
const CORE_STATE_NAMES := "\\b(GameState|RulesEngine|StateCodec|KillPipeline|StepQueue|GmCorrections|WinRules|PhaseMachine|RuleContext|ExecutionRules|WitchStep|OracleStep|ApprenticeRules|WolfChildRules|RoleTransition)\\b"


func test_core_does_not_reference_ui() -> void:
	# 16
	var pattern := RegEx.create_from_string(UI_NAMES)
	var files := files_in("res://core", ".gd")
	assert_true(files.size() >= 10, "Core-Dateien gefunden")
	for path: String in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var code := lines[n].split("#")[0]
			assert_true(pattern.search(code) == null, "%s:%d referenziert UI: %s" % [path, n + 1, code.strip_edges()])


func test_ui_does_not_touch_game_state() -> void:
	# 17
	var pattern := RegEx.create_from_string(CORE_STATE_NAMES)
	var files := files_in("res://app", ".gd")
	assert_true(files.size() >= 10, "UI-Skripte gefunden (%d)" % files.size())
	var session_files: Array[String] = []
	for path: String in files:
		if path.begins_with("res://app/session/"):
			session_files.append(path.get_file())
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n: int in lines.size():
			var code := lines[n].split("#")[0]
			assert_true(pattern.search(code) == null, "%s:%d greift am Regelkern vorbei zu: %s" % [path, n + 1, code.strip_edges()])
	session_files.sort()
	assert_eq(session_files, ["card_view.gd", "cockpit_view.gd", "game_report.gd", "game_session.gd", "game_start.gd", "morning_report.gd", "night_board_view.gd", "night_warnings.gd", "presentation_cue.gd", "prompt_view.gd", "save_service.gd"] as Array[String], "nur Sitzung, Start-Builder und Sichten in der Anwendungsschicht")


func test_session_exposes_no_mutable_state() -> void:
	var script := load_script(SESSION_SCRIPT)
	if script == null:
		return
	var session: Object = script.new()
	for prop: Dictionary in session.get_property_list():
		var usage := int(prop.get("usage", 0))
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not str(prop["name"]).begins_with("_"):
			assert_true(str(prop.get("class_name", "")) != "GameState", "öffentliche Eigenschaft %s ist kein GameState" % prop["name"])
	session.call("submit", Fixtures.start_manual(6, [1]))
	var view: Dictionary = session.call("view")
	view["phase"] = "manipuliert"
	view["has_game"] = false
	var again: Dictionary = session.call("view")
	assert_eq(str(again.get("phase")), "SETUP", "Sicht ist eine Kopie")
	assert_true(bool(again.get("has_game")), "Kopie verändert die Sitzung nicht")


func test_session_forwards_commands_to_rules_engine() -> void:
	# 18
	var script := load_script(SESSION_SCRIPT)
	if script == null:
		return
	var session: Object = script.new()
	var empty: Dictionary = session.call("view")
	assert_false(bool(empty.get("has_game", true)), "ohne Partie")
	assert_eq(str(empty.get("phase")), "", "keine Phase ohne Partie")
	var events_seen: Array = []
	var rejections: Array[String] = []
	session.connect("events_applied", func(events: Array) -> void: events_seen.append(events.size()))
	session.connect("command_rejected", func(error: StringName) -> void: rejections.append(String(error)))
	var commands: Array[Command] = [Fixtures.start_manual(6, [1]), Command.start_night()]
	var first: CommandResult = session.call("submit", commands[0])
	assert_true(first.ok, "StartGame angenommen")
	var view: Dictionary = session.call("view")
	assert_true(bool(view.get("has_game")) and str(view.get("phase")) == "SETUP" and int(view.get("player_count")) == 6, "Sicht nach StartGame")
	var second: CommandResult = session.call("submit", commands[1])
	assert_true(second.ok, "StartNight angenommen")
	view = session.call("view")
	assert_eq(str(view.get("phase")), "NIGHT", "Phase aus dem Regelkern")
	assert_eq(int(view.get("night_number")), 1, "Nachtzähler aus dem Regelkern")
	assert_eq(int(view.get("command_count")), 2, "zwei Befehle")
	assert_eq(events_seen.size(), 2, "Ereignisse je angenommenem Befehl gemeldet")
	var replayed := RulesEngine.replay(commands)
	assert_eq(str(session.call("state_hash")), replayed.state.content_hash(), "gleicher Zustand wie direkter Regelkern")
	var rejected: CommandResult = session.call("submit", Command.start_night())
	assert_false(rejected.ok, "unzulässiger Befehl abgelehnt")
	assert_eq(String(rejected.error), String(RulesEngine.apply(replayed.state, Command.start_night()).error), "Fehlergrund des Regelkerns")
	assert_eq(rejections, [String(rejected.error)] as Array[String], "Ablehnung gemeldet")
	assert_eq(events_seen.size(), 2, "keine Ereignisse bei Ablehnung")
	assert_eq(str(session.call("state_hash")), replayed.state.content_hash(), "Zustand bei Ablehnung unverändert")
	var logged: Array = session.call("commands")
	assert_eq(logged.size(), 2, "nur angenommene Befehle protokolliert")
	logged.clear()
	assert_eq((session.call("commands") as Array).size(), 2, "Befehlsliste ist eine Kopie")
	session.call("reset")
	assert_false(bool((session.call("view") as Dictionary).get("has_game", true)), "Reset leert die Sitzung")
