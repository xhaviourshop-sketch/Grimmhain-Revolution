extends UiTestCase
## Rückgängig und Wiederholen über die Befehlsfolge (GameSession.undo/redo): genau ein Befehl je
## Schritt, Zustand und Ereignisse identisch mit dem Replay der verkürzten Folge, Wiederholen stellt
## denselben Hash her, ein neuer Befehl verwirft Wiederholbares, StartGame bleibt, mehrstufige
## Prompts und bestätigte Siege lassen sich zurücknehmen, gespeichert wird nach jeder Änderung.

const ROLES := ["werwolf", "schutzengel", "waldhexe", "das-orakel", "dorfbewohner", "amalia", "detektiv"]


func _session() -> GameSession:
	var s := GameSession.new()
	assert_true(s.submit(Fixtures.start_roles(ROLES, 4)).ok, "Start")
	return s


func _replay_hash(commands: Array[Command]) -> String:
	return RulesEngine.replay(commands).state.content_hash()


func test_undo_equals_replay_of_prefix_and_redo_restores() -> void:
	var s := _session()
	s.start_night()
	s.answer_targets([5])
	s.begin_next_step()
	s.answer_targets([6])
	var full_hash := s.state_hash()
	var full_events := s.event_log()
	var commands := s.commands()
	assert_true(s.undo(), "Rückgängig")
	assert_eq(s.state_hash(), _replay_hash(commands.slice(0, commands.size() - 1)), "Zustand = Replay ohne letzten Befehl")
	assert_eq(str(s.cockpit_view()["next"]["owner"]), "pack", "Rudel-Prompt wieder offen")
	assert_true(s.can_redo(), "Wiederholen möglich")
	assert_true(s.redo(), "Wiederholen")
	assert_eq(s.state_hash(), full_hash, "gleicher Hash nach Wiederholen")
	assert_eq(s.event_log(), full_events, "gleiche Ereignisse nach Wiederholen")


func test_many_undos_down_to_start_only() -> void:
	var s := _session()
	s.start_night()
	s.answer_targets([5])
	var count := 0
	while s.undo():
		count += 1
	assert_eq(count, 2, "zwei Befehle rücknehmbar, StartGame nicht")
	assert_eq(int(s.view()["command_count"]), 1, "nur StartGame übrig")
	assert_true(bool(s.view()["has_game"]), "Partie besteht weiter")
	assert_false(s.undo(), "StartGame ist nicht rücknehmbar")


func test_new_command_discards_redo() -> void:
	var s := _session()
	s.start_night()
	s.answer_targets([5])
	s.undo()
	assert_true(s.can_redo(), "Wiederholbar")
	assert_true(s.answer_targets([6]).ok, "andere Antwort")
	assert_false(s.can_redo(), "Wiederholen verworfen")


func test_undo_inside_multistage_prompt_steps_back_one_stage() -> void:
	var s := _session()
	s.start_night()
	s.answer_targets([5])
	s.begin_next_step()
	s.answer_targets([6])
	s.begin_next_step()
	s.answer_choice(true)  # Waldhexe rettet → Stufe „reveal“
	assert_eq(str(s.cockpit_view()["next"]["stage"]), "reveal", "Stufe reveal")
	var info := s.undo_info()
	assert_eq([str(info["type"]), str(info["role_id"]), str(info["stage"])], ["AnswerPrompt", "waldhexe", "heal"], "Beschreibung des Rücknehmbaren")
	s.undo()
	assert_eq(str(s.cockpit_view()["next"]["stage"]), "heal", "zurück zur Heiltrank-Frage")


func test_undo_confirmed_win() -> void:
	var s := GameSession.new()
	s.submit(Fixtures.start_roles(["werwolf", "blutwolf", "dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher"]))
	s.start_night()
	s.answer_targets([3])
	s.end_night()
	s.nominate(1, 4)
	s.decide_execution(4)
	var next: Dictionary = s.cockpit_view()["next"]
	assert_eq(str(next["kind"]), "win_decision", "Wolfsparität")
	assert_true(s.confirm_win(int(next["candidates"][0]["id"])).ok, "Sieg bestätigt")
	assert_eq(str(s.cockpit_view()["phase"]), "GAME_OVER", "Spielende")
	assert_eq(str(s.undo_info()["type"]), "ConfirmWin", "letzter Befehl: Siegbestätigung")
	assert_true(s.undo(), "Rückgängig hinter ConfirmWin (Vertical Slice §9.5)")
	assert_eq(str(s.cockpit_view()["next"]["kind"]), "win_decision", "Entscheidung wieder offen")


func test_undo_and_redo_are_saved() -> void:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	ctx.session.submit(Fixtures.start_roles(ROLES, 4))
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	ctx.session.undo()
	var loaded := ctx.saves.load_game(ctx.session.round_id())
	var other := GameSession.new()
	other.load_text(str(loaded["core"]))
	assert_eq(other.state_hash(), ctx.session.state_hash(), "Stand nach Rückgängig gespeichert")
	ctx.session.redo()
	loaded = ctx.saves.load_game(ctx.session.round_id())
	other.load_text(str(loaded["core"]))
	assert_eq(other.state_hash(), ctx.session.state_hash(), "Stand nach Wiederholen gespeichert")
	# Rückgängig ist auch nach einem Neustart möglich (Befehlsfolge im Spielstand).
	assert_true(other.undo(), "Rückgängig nach dem Laden")


## Rückgängig und Neustart: Ereignisse = Anfang des ursprünglichen Verlaufs, Wiederholen überlebt
## den Neustart nicht (nicht gespeichert), eine neue Handlung ist danach möglich.
func test_undo_then_restart_keeps_events_and_drops_redo() -> void:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	ctx.session.submit(Fixtures.start_roles(ROLES, 4))
	ctx.session.start_night()
	ctx.session.answer_targets([5])
	var full_events := ctx.session.event_log()
	ctx.session.undo()
	var n := ctx.session.commands().size()
	assert_eq(ctx.session.event_log(), full_events.filter(func(e: Dictionary) -> bool: return int(e["command_index"]) < n), "Ereignisse = Anfang des Verlaufs")
	var fresh := AppContext.new()
	fresh.saves.base_dir = ctx.saves.base_dir
	assert_true(bool(fresh.resume(ctx.session.round_id())["ok"]), "Wiederaufnahme")
	assert_eq(fresh.session.state_hash(), ctx.session.state_hash(), "Zustand nach Rückgängig und Neustart")
	assert_eq(fresh.session.event_log(), ctx.session.event_log(), "Ereignisse nach Neustart")
	assert_false(fresh.session.can_redo(), "Wiederholen nach Neustart nicht verfügbar")
	assert_true(fresh.session.answer_targets([6]).ok, "neue Handlung nach Neustart")
