extends UiTestCase
## Paket 4: Neustart nach jedem einzelnen Befehl über den echten Speicherweg (AppContext.autosave → Datei → neuer
## AppContext → resume). Grundlage sind Mischpartien des Fuzz-Generators (test_role_interaction_fuzz) mit Rollenwechsel,
## Wiederbelebung, Kettentod, Ressourcenverbrauch, Spielleiterkorrekturen, privaten Hinweisen und Rollenbestätigungen.
## Nach jedem Befehl gilt: Zustand, Ereignisverlauf, Cockpit-Sicht (nächste Handlung, Hinweise), Morgenbericht,
## Rollenanzeige und Spielleiterbereich sind nach dem Neustart identisch; der nächste Befehl wird vom fortgesetzten Stand
## genau einmal angenommen und ergibt denselben Stand wie ohne Unterbrechung.

const Fuzz := preload("res://tests/unit/test_role_interaction_fuzz.gd")
## Fokusrollen der gewählten Mischpartien (je Fokus die erste Fuzz-Partie): Hinweise, Wiederbelebung, Rollenwechsel, Tränke.
const FOCUS := ["loki", "rattenfaenger", "dr-victor-frankenstein", "wolfskind", "seelentauscher", "waldhexe"]
## Übergänge, die mindestens einmal vorkommen müssen, sonst belegt der Test nichts.
const REQUIRED := ["role_change", "revival", "WitchActed", "GmCorrected", "RoleShownConfirmed", "NoticeAcked",
	"ReactionQueued", "chain_death"]


func _views(s: GameSession) -> Dictionary:
	return {"hash": s.state_hash(), "events": s.event_log(), "cockpit": s.cockpit_view(), "morning": s.morning_report(),
		"roles": s.role_show_list(), "private": s.private_seats(), "day_effects": s.day_effects()}


func test_restart_after_every_command_equals_uninterrupted_play() -> void:
	var fuzz := Fuzz.new()
	var seen := {}
	var restarts := 0
	for focus: String in FOCUS:
		var g: int = Fuzz.ROLES.find(focus)
		fuzz._rng.seed = 7919 * (g + 1)
		fuzz._play_game(g, Fuzz.COUNTS[g % Fuzz.COUNTS.size()])
		assert_true(fuzz.failures.is_empty(), "Partie %d erzeugt: %s" % [g, fuzz.failures])
		var log: Array[Command] = fuzz.last_log.duplicate()
		# Rollenanzeige gleich nach dem Start bestätigen (bestätigte Schritte, die ein Rollenwechsel später aufhebt).
		var players: int = (log[0].payload["players"] as Array).size()
		for id: int in range(1, players + 1):
			log.insert(id, Command.confirm_role_shown(id))
		log = _with_notice_acks(log)
		var ctx := AppContext.new()
		ctx.saves.base_dir = make_save_dir()
		var expected_next := {}
		for i: int in log.size():
			var r := ctx.session.submit(log[i])
			assert_true(r.ok, "Partie %d @%d: %s angenommen (%s)" % [g, i, log[i].type, r.error])
			if not r.ok:
				return
			for e: GameEvent in r.events:
				seen[String(e.type)] = true
				if e.type == GameEvent.PLAYER_REVIVED or e.type == GameEvent.REVIVED_BY_ROLE or (e.type == GameEvent.GM_CORRECTED and str(e.data.get("kind")) == "revive"):
					seen["revival"] = true
				if e.type in [GameEvent.ROLE_CHANGED, GameEvent.WOLF_CHILD_TRANSFORMED, GameEvent.SOULS_SWAPPED] or (e.type == GameEvent.GM_CORRECTED and str(e.data.get("kind")) == "set_role"):
					seen["role_change"] = true
			if r.events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.SEAT_DIED).size() >= 2:
				seen["chain_death"] = true
			var original := _views(ctx.session)
			if not expected_next.is_empty():
				assert_eq(original, expected_next, "Partie %d @%d: fortgesetzter Stand plus Befehl gleich ununterbrochen" % [g, i])
			var fresh := AppContext.new()
			fresh.saves.base_dir = ctx.saves.base_dir
			var resumed := fresh.resume(ctx.session.round_id())
			restarts += 1
			assert_true(bool(resumed["ok"]) and str(resumed["recovered"]) == "", "Partie %d @%d: Neustart lädt die Datei" % [g, i])
			assert_eq(_views(fresh.session), original, "Partie %d @%d nach %s: Neustart identisch" % [g, i, log[i].type])
			expected_next = {}
			if i + 1 < log.size():
				var count := fresh.session.commands().size()
				var cont := fresh.session.submit(log[i + 1])
				assert_true(cont.ok and fresh.session.commands().size() == count + 1, "Partie %d @%d: nächster Befehl genau einmal angenommen" % [g, i])
				expected_next = _views(fresh.session)
			if not failures.is_empty():
				return
	assert_true(restarts > 300, "genügend Neustarts (%d)" % restarts)
	for key: String in REQUIRED:
		assert_true(seen.has(key), "Übergang %s kam vor" % key)


## Bestätigt jeden neu anstehenden privaten Hinweis gleich nach seinem Auslöser (der Fuzz lässt Hinweise offen).
func _with_notice_acks(log: Array[Command]) -> Array[Command]:
	var out: Array[Command] = []
	var state := GameState.new()
	for c: Command in log:
		state = RulesEngine.apply(state, c).state
		out.append(c)
		var next: Dictionary = CockpitView.build(state).get("next", {})
		if str(next.get("kind")) == "notice":
			var ack := RulesEngine.apply(state, Command.ack_notice(int(next["notice_id"])))
			if ack.ok:
				state = ack.state
				out.append(Command.ack_notice(int(next["notice_id"])))
	return out
