extends TestCase
## Bestätigte Entscheidungen KS-106 bis KS-110 des Umsetzungsauftrags (Zeitsprung und Zeitwarp, Schattenmantel, Geisterhand, fälliges
## Gift und Todesprediger bei übersprungener Nacht). Zustände, die sonst nur durch langes Rollenspiel entstehen (fälliges Gift,
## Vorhersage), werden direkt gesetzt; daher gilt hier Speichern und Laden statt Replay.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3]
const OWNER := 14


func _codec_equal(g: CardGame) -> bool:
	return CanonicalJson.stringify(GameState.from_dict(g.state.to_dict()).to_dict()) == CanonicalJson.stringify(g.state.to_dict())


func test_ks106_time_skip_and_time_warp_count_the_night_and_cancel_actions_and_announcements() -> void:
	for card: StringName in [&"schicksal_06", &"loki_03"]:
		var g := CardGame.started(self, COUNT, WOLVES, 3, {"5": "schutzengel", "6": "das-orakel"})
		g.arm(OWNER, card)
		g.play_with()
		var night_before := g.state.night_number
		var events_before := g.events.size()
		g.next_night(8)
		assert_eq(g.state.night_number, night_before + 1, "%s: die übersprungene Nacht zählt" % card)
		var span := g.events.slice(events_before)
		assert_false(span.any(func(e: GameEvent) -> bool: return e.type == GameEvent.STEP_BEGUN or e.type == GameEvent.PROMPT_OPENED), "%s: keine Aktion und keine Eingabe in der Nacht" % card)
		assert_true(g.state.players[8].alive, "%s: das Rudel greift nicht an" % card)
		var morning := span.filter(func(e: GameEvent) -> bool: return e.visibility == Visibility.PUBLIC and e.type != GameEvent.PHASE_CHANGED and e.type != GameEvent.CARD_WINDOW_OPENED \
			and e.type != GameEvent.CARD_WINDOW_CLOSED and e.type != GameEvent.NIGHT_SKIPPED_BY_CARD and e.type != GameEvent.DAY_ENDED and e.type != GameEvent.NO_EXECUTION)
		assert_true(morning.is_empty(), "%s: keine öffentlichen Ansagen der übersprungenen Nacht (%s)" % [card, morning.map(func(e: GameEvent) -> String: return String(e.type))])
		assert_true(g.replay_equals() and g.reload_equals(), "%s: Replay und Laden gleich" % card)


func test_ks107_shadow_cloak_village_uses_a_random_target_instead_of_the_pack_choice() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3)
	g.arm(OWNER, &"segen_06")
	g.play_with()
	g.skip_cards()
	g.end_day()
	g.skip_cards()
	g.do(Command.start_night(), "StartNight")
	var note := g.events_of(GameEvent.CARD_EFFECT_NOTE).filter(func(e: GameEvent) -> bool: return e.data.has("blind_victim_id"))
	assert_eq(note.size(), 1, "Zufallsziel gesetzt")
	var p := g.state.pending_prompt
	assert_true(p == null or p.owner != PendingPrompt.OWNER_PACK, "keine normale Zielwahl des Rudels")
	assert_eq(g.state.pack_target_id, int(note[0].data["blind_victim_id"]), "das Zufallsziel ist das Rudelziel")
	assert_true(g.state.players[g.state.pack_target_id].alive, "ein lebendes Ziel, auch ein Wolf ist möglich")


func test_ks108_ghost_hand_grants_the_extra_ability_fresh_with_available_uses() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"6": "waldhexe", "7": "doktor"})
	g.state.players[7].ability_uses["waldhexe:heal"] = 1  # Einsatzmarke der Fähigkeit, die verliehen wird (z. B. aus einer früheren Verleihung)
	g.gm_kill(6, false)
	g.arm(OWNER, &"segen_12")
	g.play_with([[7]])
	var granted := (g.state.cardsys["abilities"] as Array).filter(func(a: Dictionary) -> bool: return int(a["player_id"]) == 7 and String(a["role_id"]) == "waldhexe")
	assert_eq(granted.size(), 1, "die Fähigkeit der zuletzt Verstorbenen ist verliehen")
	assert_false(g.state.players[7].ability_uses.has("waldhexe:heal"), "frisch: verbrauchte Einsätze dieser Fähigkeit sind zurückgesetzt")
	assert_true(_codec_equal(g), "Speichern und Laden gleich")


func test_ks109_due_poison_acts_at_the_end_of_the_skipped_night() -> void:
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"2": "giftwolf"})
	g.arm(OWNER, &"schicksal_06")
	g.state.wolf_poisons.append({"target_id": 5, "source_id": 2, "due_night": g.state.night_number + 1})
	g.play_with()
	g.next_night(8)
	assert_false(g.state.players[5].alive, "das fällige Gift wirkt trotz übersprungener Nacht")
	assert_eq(String(g.state.players[5].death.cause), String(KillEvent.CAUSE_WOLF_POISON), "Ursache: Gift")
	assert_true(g.state.players[8].alive, "das Rudelopfer lebt (kein Rudelangriff)")
	assert_true(g.state.wolf_poisons.is_empty(), "das Gift ist verbraucht")
	assert_true(_codec_equal(g), "Speichern und Laden gleich")


func test_ks110_the_preachers_chosen_night_counts_when_skipped_without_shift_or_replacement() -> void:
	# Kontrolle: ohne Zeitsprung erfüllt der Tod in der gewählten Nacht die Vorhersage.
	var control := CardGame.started(self, COUNT, WOLVES, 3, {"6": "todesprediger"})
	control.state.prophecies.append({"preacher_id": 6, "kind": "night", "number": 2})
	control.night(-1)
	control.skip_cards()
	control.next_night(6)
	assert_false(control.state.players[6].alive, "Kontrolle: der Prediger stirbt in Nacht 2")
	assert_true(control.state.preacher_wins.has(6), "Kontrolle: Vorhersage erfüllt")
	# Mit Zeitsprung: Nacht 2 zählt, es gibt keinen Tod in ihr, die Vorhersage verschiebt sich nicht und verlangt keine neue Wahl.
	var g := CardGame.started(self, COUNT, WOLVES, 3, {"6": "todesprediger"})
	g.state.prophecies.append({"preacher_id": 6, "kind": "night", "number": 2})
	g.arm(OWNER, &"schicksal_06")
	g.play_with()
	g.next_night(6)
	assert_eq(g.state.night_number, 2, "Nacht 2 ist vorbei")
	assert_true(g.state.players[6].alive, "niemand starb in der übersprungenen Nacht")
	assert_eq(SoloRules.prophecy_of(g.state, 6), {"preacher_id": 6, "kind": "night", "number": 2}, "die Vorhersage bleibt unverändert (keine Verschiebung, keine Ersatzwahl)")
	assert_true(g.state.pending_prompt == null, "keine neue Eingabe")
	g.skip_cards()
	g.next_night(6)
	assert_false(g.state.players[6].alive, "der Prediger stirbt in Nacht 3")
	assert_false(g.state.preacher_wins.has(6), "Tod in Nacht 3 erfüllt die für Nacht 2 gewählte Vorhersage nicht")
