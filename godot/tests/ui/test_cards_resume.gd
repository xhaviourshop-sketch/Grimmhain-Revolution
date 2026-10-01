extends UiTestCase
## Neustart über den echten Speicherweg (AppContext.autosave → Datei → neuer AppContext → resume) bei zwei kritischen Kartenabläufen:
## mitten in einer mehrstufigen Kartenaktion (Schicksal-08: zwei Personen, zwei Rollen) und nach dem festgelegten Phoenix-Wurf bis
## zum späteren Fristablauf. Die Befehlsfolge entsteht mit `CardGame` über reguläre Befehle; sie wird hier nach jedem einzelnen Befehl
## mit Neustart in die Anwendungsschicht gespielt. Nach jedem Neustart müssen Zustand, Ereignisse und Cockpit gleich sein, und der
## nächste Befehl wird vom fortgesetzten Stand genau einmal angenommen.

const COUNT := 16
const WOLVES: Array[int] = [1, 2, 3]
const OWNER := 12


func _views(s: GameSession) -> Dictionary:
	return {"hash": s.state_hash(), "events": s.event_log(), "cockpit": s.cockpit_view(), "morning": s.morning_report(),
		"private": s.private_seats(), "day_effects": s.day_effects(), "day_cards": s.day_cards()}


## Spielt `log` Befehl für Befehl in eine Sitzung; nach jedem Befehl startet eine zweite Sitzung aus der Datei neu und setzt fort.
## `on_step(session, index)` wird nach jedem Neustart auf der fortgesetzten Sitzung aufgerufen. Liefert die zuletzt fortgesetzte Sitzung.
func _play_with_restarts(log: Array[Command], on_step: Callable) -> GameSession:
	var ctx := AppContext.new()
	ctx.saves.base_dir = make_save_dir()
	var expected_next := {}
	var last: GameSession = ctx.session
	for i: int in log.size():
		var r := ctx.session.submit(log[i])
		assert_true(r.ok, "@%d: %s angenommen (%s)" % [i, log[i].type, r.error])
		if not r.ok:
			return last
		var original := _views(ctx.session)
		if not expected_next.is_empty():
			assert_eq(original, expected_next, "@%d: fortgesetzter Stand plus Befehl gleich ununterbrochen" % i)
		var fresh := AppContext.new()
		fresh.saves.base_dir = ctx.saves.base_dir
		var resumed := fresh.resume(ctx.session.round_id())
		assert_true(bool(resumed["ok"]) and str(resumed["recovered"]) == "", "@%d: Neustart lädt die Datei" % i)
		assert_eq(_views(fresh.session), original, "@%d nach %s: Neustart identisch" % [i, log[i].type])
		on_step.call(fresh.session, i)
		expected_next = {}
		if i + 1 < log.size():
			var count := fresh.session.commands().size()
			var cont := fresh.session.submit(log[i + 1])
			assert_true(cont.ok and fresh.session.commands().size() == count + 1, "@%d: nächster Befehl genau einmal angenommen" % i)
			expected_next = _views(fresh.session)
		last = fresh.session
		if not failures.is_empty():
			return last
	return last


func test_restart_in_the_middle_of_an_open_multistage_card_action() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3)
	g.arm(OWNER, &"schicksal_08")
	g.do(Command.card_act(OWNER, "play"), "play")
	var p := g.state.pending_prompt
	assert_eq(p.stage, &"pick", "Stufe 1: zwei Personen")
	g.do(Command.answer_stage_targets(p.id, "pick", [4, 5]), "Personen")
	assert_eq(g.state.pending_prompt.stage, &"option", "Stufe 2: Rolle der ersten Person")
	g.do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": g.state.pending_prompt.id, "stage": "option", "option": 0}), "Rolle 1")
	assert_eq(g.state.pending_prompt.stage, &"option", "Stufe 3: Rolle der zweiten Person")
	g.do(Command.create(Command.ANSWER_PROMPT, {"prompt_id": g.state.pending_prompt.id, "stage": "option", "option": 0}), "Rolle 2")
	g.settle()
	var mid := {"stages": []}
	var check := func(session: GameSession, _i: int) -> void:
		var next: Dictionary = session.cockpit_view().get("next", {})
		if str(next.get("kind")) == "prompt":
			mid["stages"].append(str(next.get("stage")))
	var final := _play_with_restarts(g.commands, check)
	assert_true((mid["stages"] as Array).has("option"), "ein Neustart fiel mitten in die mehrstufige Aktion (%s)" % str(mid["stages"]))
	var changed := final.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "CardEffectNote" and (e["data"] as Dictionary).has("roles"))
	assert_eq(changed.size(), 1, "die Rollenvergabe wirkte genau einmal")
	assert_true(CardRules.state_is_consistent(g.state), "Kartenzustand der Quelle konsistent")


func test_restart_after_the_phoenix_roll_and_before_the_deadline() -> void:
	var g: CardGame = null
	var note: Dictionary = {}
	for seed_value: int in range(1, 40):
		var c := CardGame.started(self, COUNT, WOLVES, seed_value)
		for id: int in [5, 6, 7, 8]:
			c.gm_kill(id, false)
		c.arm(OWNER, &"loki_10")
		c.play_with()
		var notes := c.events_of(GameEvent.CARD_EFFECT_NOTE).filter(func(e: GameEvent) -> bool: return e.data.has("revived_ids"))
		if notes.size() == 1 and int(notes[0].data["days"]) == 3:
			g = c
			note = notes[0].data
			break
	assert_true(g != null, "ein Phoenix-Wurf mit drei Tagen gefunden")
	if g == null:
		return
	var die_day := int(note["die_day"])
	var guard := 0
	while g.state.day_number < die_day and guard < 6:
		guard += 1
		g.next_night()
	g.skip_cards()
	g.end_day()
	var revived: Array = note["revived_ids"]
	for id: Variant in revived:
		assert_false(g.state.players[int(id)].alive, "Quelle: %d starb nach Fristablauf" % int(id))
	var seen := {"alive_between": 0}
	var check := func(session: GameSession, _i: int) -> void:
		var notes_now := session.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "CardEffectNote" and (e["data"] as Dictionary).has("revived_ids"))
		if notes_now.size() == 1:
			assert_eq((notes_now[0]["data"] as Dictionary)["dice"], note["dice"], "gespeicherte Würfel bleiben nach dem Neustart gleich")
			assert_eq((notes_now[0]["data"] as Dictionary)["revived_ids"], note["revived_ids"], "gleiche Rückkehrende")
			seen["alive_between"] = int(seen["alive_between"]) + 1
	var final := _play_with_restarts(g.commands, check)
	assert_true(int(seen["alive_between"]) > 5, "mehrere Neustarts zwischen Wurf und Fristablauf (%d)" % int(seen["alive_between"]))
	var notes_final := final.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "CardEffectNote" and (e["data"] as Dictionary).has("revived_ids"))
	assert_eq(notes_final.size(), 1, "nach allen Neustarts wurde nur einmal gewürfelt")
	var expiry := final.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "SeatDied" and str((e["data"] as Dictionary).get("cause")) == "CARD_EXPIRY")
	assert_eq(expiry.size(), revived.size(), "jeder Rückkehrende starb genau einmal durch den Fristablauf")


## Rückgängig und Wiederholen über die Befehlsfolge: der gespeicherte Phoenix-Wurf ändert sich dabei nicht (kein erneutes Würfeln).
func test_undo_and_redo_of_the_phoenix_roll_keep_the_stored_dice() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 5)
	for id: int in [5, 6, 7, 8]:
		g.gm_kill(id, false)
	g.arm(OWNER, &"loki_10")
	g.play_with()
	var session := GameSession.new()
	for c: Command in g.commands:
		assert_true(session.submit(c).ok, "%s angenommen" % c.type)
	var after_roll := _views(session)
	assert_true(session.undo(), "Rückgängig")
	assert_true(session.event_log().filter(func(e: Dictionary) -> bool: return (e["data"] as Dictionary).has("revived_ids")).is_empty(), "nach Rückgängig keine Rückkehr")
	assert_true(session.redo(), "Wiederholen")
	assert_eq(_views(session), after_roll, "Wiederholen ergibt denselben Wurf und dieselben Rückkehrenden")
	assert_true(session.undo() and session.undo() and session.redo() and session.redo(), "zweimal zurück und vor")
	assert_eq(_views(session), after_roll, "weiterhin derselbe Stand")
