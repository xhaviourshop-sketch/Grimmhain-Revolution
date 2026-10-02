extends TestCase
## DI-04, DI-06, DI-07 (Antworten des Product Owners vom 29.09.2026): Private Hinweise an Betroffene.
##   Loki: beide Personen des Paares erfahren Partner und Bindungsart.
##   Rattenfänger: die neu Verzauberten; „Alle Verzauberten“ ist seit PE-06 ein Nachtschritt (test_piper_all).
##   Pestbringerin: jede neu infizierte Person, auch durch die Ausbreitung am Morgen.
## Ein Hinweis ist Teil des Spielstands (`notices`), wird mit `AckNotice` als gezeigt abgeschlossen und ist
## nie öffentlich. Er blockiert den Ablauf im Regelkern nicht; die Oberfläche zeigt ihn zuerst.

const W := "werwolf"
const D := "dorfbewohner"
const LO := "loki"
const RF := "rattenfaenger"
const PB := "pestbringerin"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage == &"grant" or p.stage == &"mode":
		return Command.answer_choice(p.id, String(p.stage), false)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht; `answers`: {"<rolle>:<id>" | "<rolle>:<id>@<stufe>": Antwort}. Rudel wählt niemanden. Endet vor EndNight.
func _night(s: GameState, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Tagesende")
	if s != null and s.phase != Phase.NIGHT:
		var started := apply_ok(s, Command.start_night(), "Nachtbeginn")
		log.append_array(started.events)
		s = started.state
	for guard: int in 60:
		if s == null:
			return null
		var cmd: Command = null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
			var staged := "%s@%s" % [key, p.stage]
			if p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.answer_prompt(p.id, [])
			elif answers.has(staged):
				var a: Variant = answers[staged]
				cmd = Command.answer_choice(p.id, String(p.stage), a) if a is bool else Command.answer_stage_targets(p.id, String(p.stage), a)
			elif answers.has(key) and p.stage == &"":
				cmd = Command.answer_prompt(p.id, answers[key])
			else:
				cmd = _auto(s)
		else:
			var step := RulesEngine.next_step_id(s)
			if step == "":
				return s
			cmd = Command.begin_step(step)
		var r := apply_ok(s, cmd, "Nachtbefehl")
		log.append_array(r.events)
		s = r.state
	fail("Nacht endet nicht")
	return null


func _notices_of(s: GameState, kind: String) -> Array:
	return s.notices.filter(func(n: Dictionary) -> bool: return String(n["kind"]) == kind)


# --- Loki ------------------------------------------------------------------------------------------

func test_loki_love_notifies_both_persons_with_partner_and_kind() -> void:
	var s := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [3, 5], "loki:2@mode": true})
	assert_true(s != null, "Nacht 1")
	if s == null:
		return
	var bonds := _notices_of(s, "loki_bond")
	assert_eq(bonds.size(), 2, "ein Hinweis je Person")
	if bonds.size() == 2:
		assert_eq(bonds[0]["viewer_ids"], [3], "erster Hinweis nur für Person 3")
		assert_eq(bonds[0]["data"], {"partner_id": 5, "bond": "love"}, "Partner und Art für 3")
		assert_eq(bonds[1]["viewer_ids"], [5], "zweiter Hinweis nur für Person 5")
		assert_eq(bonds[1]["data"], {"partner_id": 3, "bond": "love"}, "Partner und Art für 5")
		assert_true(int(bonds[0]["id"]) < int(bonds[1]["id"]), "feste Reihenfolge")


func test_loki_rivals_and_decline() -> void:
	var rivals := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [4, 6], "loki:2@mode": false})
	var bonds := _notices_of(rivals, "loki_bond") if rivals != null else []
	assert_true(bonds.size() == 2 and bonds[0]["data"]["bond"] == "rival" and bonds[1]["data"]["bond"] == "rival", "Rivalen erfahren die Art")
	var declined := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": []})
	assert_true(declined != null and declined.notices.is_empty(), "Verzicht: keine Hinweise")


func test_loki_himself_in_the_pair_is_a_viewer_too() -> void:
	var s := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [2, 3], "loki:2@mode": true})
	var bonds := _notices_of(s, "loki_bond") if s != null else []
	assert_eq(bonds.size(), 2, "beide Personen des Paares, auch Loki selbst")


# --- Rattenfänger -----------------------------------------------------------------------------------

func test_piper_notifies_only_the_new_enchanted() -> void:
	var s := _night(_state([W, RF, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), {"rattenfaenger:2": [3, 4]})
	assert_true(s != null, "Nacht 1")
	if s == null:
		return
	var new_notices := _notices_of(s, "piper_new")
	assert_true(new_notices.size() == 1 and s.notices.size() == 1, "ein Hinweis, kein zweiter für alle Verzauberten (PE-06)")
	if new_notices.size() == 1:
		assert_eq(new_notices[0]["viewer_ids"], [3, 4], "neu Verzauberte")
	# Zweite Nacht: nur die weitere Person erhält den Hinweis.
	for n: Dictionary in s.notices.duplicate():
		s = _ok(s, Command.ack_notice(int(n["id"])), "Hinweis gezeigt")
	s = _ok(_ok(s, Command.end_night(), "Morgen"), Command.decide_execution(-1), "keine Hinrichtung")
	var s2 := _night(s, {"rattenfaenger:2": [5]})
	if s2 == null:
		return
	assert_eq(_notices_of(s2, "piper_new")[0]["viewer_ids"], [5], "nur die neu Verzauberte")
	assert_eq(s2.notices.size(), 1, "kein Hinweis für alle Verzauberten")


# --- Pestbringerin ---------------------------------------------------------------------------------

func test_plague_notifies_each_newly_infected_including_spread() -> void:
	var log: Array[GameEvent] = []
	var s := _night(_state([W, PB, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), {"pestbringerin:2": [5]}, log)
	assert_true(s != null, "Nacht 1")
	if s == null:
		return
	var first := _notices_of(s, "pest_infected")
	assert_true(first.size() == 1 and first[0]["viewer_ids"] == [5] and first[0]["data"].is_empty(), "Hinweis an die in der Nacht Infizierte")
	var morning := apply_ok(s, Command.end_night(), "Morgen")
	if not morning.ok:
		return
	var spread_new: Array[int] = []
	for e: GameEvent in events_of_type(morning.events, "PlagueSpread"):
		if bool(e.data["new"]):
			spread_new.append(int(e.data["target_id"]))
	var after := _notices_of(morning.state, "pest_infected")
	assert_eq(after.size(), 1 + spread_new.size(), "ein Hinweis je neu Angesteckter")
	var viewers: Array[int] = []
	for n: Dictionary in after:
		viewers.append(int((n["viewer_ids"] as Array)[0]))
	for id: int in spread_new:
		assert_true(viewers.has(id), "Person %d hat einen Hinweis" % id)
	assert_eq(events_of_type(morning.events, "NoticeQueued").size(), spread_new.size(), "Ereignisse je neue Ansteckung")


# --- Bestätigen, Sichtbarkeit, Aufräumen -----------------------------------------------------------

func test_ack_removes_notice_and_rejects_unknown_ids() -> void:
	var s := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [3, 5], "loki:2@mode": true})
	if s == null or s.notices.size() != 2:
		fail("Vorbereitung")
		return
	var first := int(s.notices[0]["id"])
	var before := s.content_hash()
	var r := apply_ok(s, Command.ack_notice(first), "Hinweis gezeigt")
	assert_eq(r.state.notices.size(), 1, "einer bleibt")
	assert_ne(r.state.content_hash(), before, "Bestätigung gehört zum fachlichen Zustand")
	var acked := events_of_type(r.events, "NoticeAcked")
	assert_true(acked.size() == 1 and String(acked[0].visibility) == "gm" and int(acked[0].data["notice_id"]) == first, "Ereignis nur für die Spielleitung")
	apply_rejected(r.state, Command.ack_notice(first), "unknown_notice", "zweimal bestätigt")
	apply_rejected(s, Command.ack_notice(999), "unknown_notice", "unbekannte ID")
	apply_rejected(s, Command.create(Command.ACK_NOTICE, {"notice_id": "1"}), "unknown_notice", "kein Zahlenwert")


func test_notices_never_appear_in_public_events() -> void:
	var log: Array[GameEvent] = []
	var s := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [3, 5], "loki:2@mode": true}, log)
	assert_true(s != null, "Nacht")
	var queued := 0
	for e: GameEvent in log:
		if String(e.type) == "NoticeQueued":
			queued += 1
			assert_eq(String(e.visibility), "gm", "Hinweisereignis nur für die Spielleitung")
		elif e.visibility == Visibility.PUBLIC:
			assert_false(String(e.type).begins_with("Notice"), "kein öffentliches Hinweisereignis")
	assert_eq(queued, 2, "zwei Hinweise eingereiht")


func test_ack_is_allowed_while_a_reaction_or_win_candidate_is_open() -> void:
	var s := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [3, 5], "loki:2@mode": true})
	if s == null:
		return
	s = _ok(s, Command.end_night(), "Morgen")
	assert_true(s != null and s.phase == Phase.DAY, "Tag")
	var with_reaction := s.duplicate_state()
	var reaction := Reaction.new()
	reaction.id = 1
	reaction.owner_id = 3
	reaction.kind = Reaction.KIND_CURSE
	with_reaction.reactions.append(reaction)
	with_reaction.next_reaction_id = 2
	assert_eq(RulesEngine.check(with_reaction, Command.ack_notice(int(with_reaction.notices[0]["id"]))), &"", "Bestätigen trotz offener Reaktion")


func test_death_removes_the_viewer_and_drops_empty_notices() -> void:
	var s := _night(_state([W, PB, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), {"pestbringerin:2": [5]})
	if s == null or s.notices.size() != 1:
		fail("Vorbereitung")
		return
	s = _ok(s, Command.end_night(), "Morgen")
	if s == null:
		return
	var target := int((s.notices[0]["viewer_ids"] as Array)[0])
	var r := apply_ok(s, CorrectionFixtures.gm("kill", {"target_id": target, "trigger_effects": false}), "Person stirbt")
	assert_true(_notices_of(r.state, "pest_infected").filter(func(n: Dictionary) -> bool: return (n["viewer_ids"] as Array).has(target)).is_empty(), "Hinweis einer Toten entfällt")
	assert_eq(events_of_type(r.events, "NoticeDropped").size(), 1, "Verwerfen protokolliert")
	var piper := _night(_state([W, RF, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), {"rattenfaenger:2": [3, 4]})
	if piper == null:
		return
	piper = _ok(piper, Command.end_night(), "Morgen")
	var shrunk := apply_ok(piper, CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": false}), "Verzauberte stirbt")
	var charmed := _notices_of(shrunk.state, "piper_new")
	assert_true(charmed.size() == 1 and charmed[0]["viewer_ids"] == [4], "Tote steht nicht mehr in der Liste der neu Verzauberten")


func test_notices_survive_save_load_and_replay() -> void:
	var commands: Array[Command] = [Fixtures.start_roles([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 1), Command.start_night()]
	var s := RulesEngine.replay(commands).state
	var p := s.pending_prompt
	commands.append(Command.answer_stage_targets(p.id, "targets", [3, 5]))
	commands.append(Command.answer_choice(p.id, "mode", true))
	var first := RulesEngine.replay(commands)
	assert_true(first.ok and first.state.notices.size() == 2, "zwei Hinweise")
	if not first.ok:
		return
	commands.append(Command.ack_notice(int(first.state.notices[0]["id"])))
	var replayed := RulesEngine.replay(commands)
	assert_true(replayed.ok and replayed.state.notices.size() == 1, "Bestätigung im Befehlsverlauf")
	assert_eq(events_json(RulesEngine.replay(commands).events), events_json(replayed.events), "bytegleiches Replay")
	var loaded := StateCodec.decode(StateCodec.encode(replayed.state, commands))
	assert_true(loaded.ok, "Laden (%s)" % loaded.error)
	if loaded.ok:
		assert_eq(loaded.state.content_hash(), replayed.state.content_hash(), "gleicher Hash")
		assert_eq(loaded.state.notices, replayed.state.notices, "offene Hinweise erhalten")
	# Rücknahme des letzten Befehls stellt den vorherigen Stand wieder her (Undo per Replay).
	var undone := RulesEngine.replay(commands.slice(0, commands.size() - 1))
	assert_eq(undone.state.notices.size(), 2, "nach Rücknahme wieder zwei Hinweise")


func test_load_rejects_inconsistent_notices() -> void:
	var s := _night(_state([W, LO, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]), {"loki:2@targets": [3, 5], "loki:2@mode": true})
	if s == null:
		return
	var d := s.to_dict()
	var bad_kind := d.duplicate(true)
	(bad_kind["notices"] as Array)[0]["kind"] = "unknown"
	assert_true(GameState.from_dict(bad_kind) == null, "unbekannte Art")
	var bad_viewer := d.duplicate(true)
	(bad_viewer["notices"] as Array)[0]["viewer_ids"] = [99]
	assert_true(GameState.from_dict(bad_viewer) == null, "unbekannte Person")
	var dup_id := d.duplicate(true)
	(dup_id["notices"] as Array)[1]["id"] = (dup_id["notices"] as Array)[0]["id"]
	assert_true(GameState.from_dict(dup_id) == null, "doppelte ID")
	var low_next := d.duplicate(true)
	(low_next["next_ids"] as Dictionary)["notice"] = 1
	assert_true(GameState.from_dict(low_next) == null, "Zähler kleiner als vergebene IDs")
