extends TestCase
## DECISION-LOG „Rollenaudit · Schutzrollen“ (28.09.2026, Fragen S-01 bis S-14).
##   Der Weise: überlebt einmal je Leben einen Rudelangriff, der ihn sonst töten würde (S-02); Durchdringung
##     tötet ihn. Sein Lynch verlangt die Spielleiterwahl 0–3 (`sage_curse`); so viele folgende Nächte und
##     Tage ruhen alle Fähigkeiten aller Dorfpersonen, ausgelöste Wirkungen entfallen endgültig (S-01, S-05, S-09).
##   Schutzreihenfolge: wiederholbare Wirkungen zuerst, sonst genau eine einmalige: Waffe, Schild, Weiser (S-10, S-11).
##   Märtyrerin (9.0): am Ende der Nacht, nur wenn das erste Rudelopfer wirklich stürbe; Ersatzopfer, nicht
##     blockierbar (S-03, S-14).
##   Schutzgeist (5.6): in der ersten Nacht nach ihrem Tod ein Schild für eine lebende Person, wirksam ab der
##     Folgenacht bis zum nächsten Rudelangriff; Wolf gewählt → öffentliche Meldung ohne Namen (S-04).
##   Dorfschmied (1.7): ab Nacht 6 der Partie Waffe an eine andere Person; wehrt den nächsten Rudelangriff ab
##     (auch durchdringend), der Spielleiter wählt den sterbenden Wolf (S-06). Gaben bleiben (S-12).
##   Verdammniswächter (2.3): lenkt den Angriff auf das erste Rudelopfer wahlweise auf eine per Seed gezogene
##     lebende Nicht-Wolf-Person; es bleibt ein Rudelangriff (S-07, S-08, S-13).

const WE := "der-weise"
const MA := "maertyrerin"
const SG := "schutzgeist"
const SM := "dorfschmied"
const VW := "verdammniswaechter"
const D := "dorfbewohner"
const W := "werwolf"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay(Fixtures.start_with_copies(roles, 1))  # Kopien gleicher Rollen entstehen nach dem Start (PE-07)
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


## Antwort ohne Wirkung: Verzicht bzw. erste zulässige Ziele, dann „Gezeigt“.
func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Rudelopfer `victim` (−1: keines); `answers` legt Antworten für Schritte fest
## ({"<rolle>:<id>" oder "pack": Zielliste}); alle anderen Schritte ohne Wirkung. Endet vor EndNight.
func _night(s: GameState, victim: int, answers: Dictionary = {}) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Tagesende")
	if s != null and s.phase != Phase.NIGHT:
		s = _ok(s, Command.start_night(), "Nachtbeginn")
	for guard: int in 60:
		if s == null:
			return null
		if s.pending_prompt != null:
			var p := s.pending_prompt
			var key := p.step_id.get_slice(":", 3) + (":" + p.step_id.get_slice(":", 4) if p.step_id.get_slice_count(":") > 4 else "")
			if p.owner == PendingPrompt.OWNER_PACK:
				s = _ok(s, Command.answer_prompt(p.id, [victim] if victim != -1 else []), "Rudel")
			elif answers.has(key) and p.stage == &"":
				s = _ok(s, Command.answer_prompt(p.id, answers[key]), "Antwort %s" % key)
			else:
				s = _ok(s, _auto(s), "ohne Wirkung %s" % key)
			continue
		var step := RulesEngine.next_step_id(s)
		if step == "":
			return s
		s = _ok(s, Command.begin_step(step), "Schritt %s" % step)
	fail("Nacht endet nicht")
	return null


## Nacht und Morgen; liefert das Ergebnis des EndNight-Befehls (Ereignisse des Morgens).
func _dawn(s: GameState, victim: int, answers: Dictionary = {}) -> CommandResult:
	s = _night(s, victim, answers)
	return apply_ok(s, Command.end_night(), "Morgen") if s != null else null


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _prevented_by(events: Array[GameEvent], target: int) -> String:
	for e: GameEvent in events_of_type(events, "KillPrevented"):
		if int(e.data["target_id"]) == target:
			return String(e.data["protection"])
	return ""


func _died(events: Array[GameEvent], target: int) -> String:
	for e: GameEvent in events_of_type(events, "SeatDied"):
		if int(e.data["target_id"]) == target:
			return String(e.data["cause"])
	return ""


func _dropped_reason(events: Array[GameEvent], key: String) -> String:
	for e: GameEvent in events_of_type(events, "StepDropped"):
		if String(e.data["step_id"]).ends_with(":" + key):
			return String(e.data["reason"])
	return ""


## Lynch des Weisen `sage` durch `nominator` mit Fluchdauer `curse`.
func _lynch_sage(s: GameState, nominator: int, sage: int, curse: int) -> CommandResult:
	s = _ok(s, Command.nominate(nominator, sage), "Nominierung")
	if s == null:
		return null
	apply_rejected(s, Command.decide_execution(sage), "sage_curse_required", "Fluchdauer Pflicht")
	apply_rejected(s, Command.create(Command.DECIDE_EXECUTION, {"target_id": sage, "sage_curse": 4}), "invalid_sage_curse", "höchstens 3")
	return apply_ok(s, Command.create(Command.DECIDE_EXECUTION, {"target_id": sage, "sage_curse": curse}), "Lynch des Weisen")


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entries() -> void:
	var prio := {WE: 0, MA: 90, SG: 56, SM: 17, VW: 23}
	for role: String in prio:
		assert_true(RoleCatalog.has_role(StringName(role)), "%s im Katalog" % role)
		if RoleCatalog.has_role(StringName(role)):
			assert_eq(RoleCatalog.faction_of(StringName(role)), Faction.VILLAGE, "%s Dorf" % role)
			assert_eq(RoleCatalog.night_priority(StringName(role)), int(prio[role]), "%s Priorität" % role)
	for kind: String in [MA, SG, SM, VW]:
		assert_false(StepQueue.is_skippable("night:1:0:%s:1" % kind), "%s nicht überspringbar" % kind)


# --- Der Weise ------------------------------------------------------------------------------------

func test_sage_survives_first_attack_only_when_needed() -> void:
	var s := _state([W, WE, "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	var r := _dawn(s, 2, {"schutzengel:3": [2]})
	if r == null:
		return
	assert_eq(_prevented_by(r.events, 2), "schutzengel", "Schutzengel rettet zuerst")
	assert_false(r.state.players[2].ability_uses.has("der-weise:survive"), "Rettung des Weisen nicht verbraucht")
	r = _dawn(r.state, 2, {"schutzengel:3": [4]})
	if r == null:
		return
	assert_eq(_prevented_by(r.events, 2), "der-weise", "eigene Rettung")
	assert_true(r.state.players[2].alive and r.state.players[2].ability_uses.has("der-weise:survive"), "verbraucht")
	var pub := events_of_type(r.events, "KillPrevented")
	assert_true(pub.size() == 1 and pub[0].visibility == Visibility.GM, "still, nur Spielleiter")
	r = _dawn(r.state, 2, {"schutzengel:3": [4]})
	assert_eq(_died(r.events, 2) if r != null else "", "NIGHT_KILL", "zweiter Angriff tötet")


func test_sage_is_pierced() -> void:
	var s := _state(["seuchenwolf", W, WE, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "Seuchenwolf tot")
	var r := _dawn(s, 3)
	assert_eq(_died(r.events, 3) if r != null else "", "NIGHT_KILL", "Durchdringung tötet den Weisen")


func test_sage_lynch_curse_silences_village_abilities() -> void:
	# 1 W, 2 Weiser, 3 Orakel, 4 Dorfwache, 5 Nachtwächter (neben 6 = Wolf), 6 W, 7 Sensenträger, 8 Amalia, 9 W, 10–12 D
	var s := _state([W, WE, "das-orakel", "dorfwache", "nachtwaechter", "blutwolf", "sensentraeger", "amalia", "rudelvater", D, "detektiv", "wahnsinniger-kutscher"])
	var r := _dawn(s, -1)
	if r == null:
		return
	r = _lynch_sage(r.state, 10, 2, 1)
	if r == null:
		return
	assert_eq([r.state.sage_curse_from, r.state.sage_curse_to], [2, 2], "Nacht 2 und Tag 2")
	var cursed := r.state
	s = _ok(cursed, Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 2")
	var all: Array[GameEvent] = []
	if s == null:
		return
	# Orakel entfällt (verflucht); Rudel greift die Dorfwache an; der Sensenträger stirbt per Korrektur.
	var packed := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Rudel auf Dorfwache")
	all.append_array(packed.events)
	r = apply_ok(packed.state, _gm("kill", {"target_id": 7, "trigger_effects": true}), "Sensenträger stirbt")
	assert_true(r.state.reactions.is_empty(), "keine Todesreaktion im Fluch")
	s = r.state
	for guard: int in 10:
		if s.pending_prompt == null and RulesEngine.next_step_id(s) == "":
			break
		var cr := apply_ok(s, _auto(s) if s.pending_prompt != null else Command.begin_step(RulesEngine.next_step_id(s)), "weiter")
		all.append_array(cr.events)
		s = cr.state
	var dawn := apply_ok(s, Command.end_night(), "Morgen")
	all.append_array(dawn.events)
	assert_eq(_dropped_reason(all, "das-orakel:3"), "cursed", "Orakel ruht")
	assert_eq(_died(dawn.events, 4), "NIGHT_KILL", "Dorfwache ohne Immunität")
	assert_eq(events_of_type(dawn.events, "AlarmBells").size(), 0, "keine Glocken")
	apply_rejected(dawn.state, Command.amalia_sacrifice(8, true), "cursed", "Amalia ruht am Tag")
	# Nach dem Fluch wirkt alles wieder.
	s = _ok(_ok(dawn.state, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 3")
	assert_true(s != null and s.night_plan.has(&"das-orakel:3"), "Orakel wieder geplant")


func test_sage_curse_drops_triggered_effects_for_good() -> void:
	# Wolfskind 3 mit Vorbild 4, Lehrling 5 mit Meister 6 (per Korrektur gebunden).
	var s := _state([W, WE, "wolfskind", D, "lehrling", "das-orakel", "amalia", "detektiv", "blutwolf"])
	s = _ok(s, _gm("set_wolf_model", {"child_id": 3, "target_id": 4}), "Vorbild")
	s = _ok(s, _gm("set_apprentice_master", {"apprentice_id": 5, "target_id": 6}), "Meister")
	var r := _dawn(s, -1)
	r = _lynch_sage(r.state, 7, 2, 2) if r != null else null
	if r == null:
		return
	s = _ok(r.state, Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 2 (Fluch)")
	s = _ok(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), "Vorbild stirbt")
	s = _ok(s, _gm("kill", {"target_id": 6, "trigger_effects": true}), "Meister stirbt")
	if s == null:
		return
	assert_false(s.players[3].counts_as_wolf, "keine Verwandlung im Fluch")
	assert_eq(s.players[5].role_id, &"lehrling", "kein Erbe im Fluch")
	_codec_same(s, "Fluch")
	# Nach dem Fluch wird nichts nachgeholt.
	var after := _dawn(s, -1)
	for i: int in 2:
		after = _dawn(_ok(_ok(after.state, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende"), -1) if after != null else null
	if after != null:
		assert_false(after.state.players[3].counts_as_wolf, "nicht nachgeholt (Verwandlung)")
		assert_eq(after.state.players[5].role_id, &"lehrling", "nicht nachgeholt (Erbe)")


func test_sage_curse_zero_and_silenced_sage() -> void:
	var s := _state([W, WE, WE, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "blutwolf"])
	var r := _dawn(s, -1)
	r = _lynch_sage(r.state, 4, 2, 0) if r != null else null
	if r == null:
		return
	assert_eq(r.state.sage_curse_to, 0, "0 = kein Fluch")
	s = _ok(_ok(r.state, Command.end_day(), "Ende"), Command.start_night(), "Nacht 2")
	r = _dawn(s, -1)
	r = _lynch_sage(r.state, 4, 3, 1) if r != null else null
	if r == null:
		return
	s = _ok(r.state, Command.end_day(), "Ende")
	var n := _night(s, -1)
	s = _ok(n, Command.end_night(), "Morgen")
	# Tag 3 ist verflucht: ein weiterer Weiser würde keinen Fluch auslösen (seine Fähigkeit ruht).
	s = _ok(s, _gm("set_role", {"target_id": 5, "role_id": WE}), "zweiter Weiser")
	s = _ok(s, Command.nominate(6, 5), "Nominierung")
	var direct := apply_ok(s, Command.decide_execution(5), "Lynch ohne Fluchwahl")
	assert_eq(direct.state.sage_curse_to, 3, "Fluch nicht verlängert")


# --- Mehrere Schutzwirkungen ---------------------------------------------------------------------

func test_one_time_protection_order_weapon_shield_sage() -> void:
	# Weiser 2 trägt Waffe (Schmied 3) und Schild (Schutzgeist 4) per Spielablauf; hier per Zustand vorbereitet.
	var s := _state([W, WE, SM, SG, D, "amalia", "detektiv", "blutwolf"])
	if s == null:
		return
	s.weapons.append({"holder_id": 2, "smith_id": 3})
	s.shields.append({"holder_id": 2, "source_id": 4, "night": 0})
	var r := _dawn(s, 2)
	if r == null:
		return
	assert_eq(_prevented_by(r.events, 2), "dorfschmied", "Waffe zuerst")
	assert_eq(r.state.shields.size(), 1, "Schild bleibt")
	assert_false(r.state.players[2].ability_uses.has("der-weise:survive"), "Weiser bleibt")
	assert_eq(r.state.reactions.size(), 1, "Spielleiter wählt den Wolf")
	var p := RulesEngine.next_step_id(r.state)
	s = _ok(r.state, Command.begin_step(p), "Waffe")
	if s == null:
		return
	assert_eq(s.pending_prompt.allowed_ids, [1, 8] as Array[int], "nur lebende Wölfe")
	var k := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [8]), "Wolf 8")
	assert_eq(_died(k.events, 8), "SMITH_WEAPON", "Wolf stirbt durch die Waffe")
	r = _dawn(k.state, 2)
	assert_eq(_prevented_by(r.events, 2) if r != null else "", "schutzgeist", "dann das Schild")
	r = _dawn(r.state, 2) if r != null else null
	assert_eq(_prevented_by(r.events, 2) if r != null else "", "der-weise", "zuletzt der Weise")


# --- Märtyrerin -----------------------------------------------------------------------------------

func test_martyr_replaces_victim_who_would_die() -> void:
	var s := _state([W, MA, D, "amalia", "detektiv", "wahnsinniger-kutscher", "albtraumwolf"])
	# Albtraumwolf blockiert die Märtyrerin: ihre Entscheidung ist trotzdem möglich (S-03).
	s = _night(s, 3, {"albtraumwolf:7": [2]})
	if s == null:
		return
	var r := apply_ok(s, Command.end_night(), "Morgen ohne Opfer der Märtyrerin")
	assert_eq(_died(r.events, 3), "NIGHT_KILL", "Verzicht: Opfer stirbt")
	# Nacht 2: sie opfert sich.
	s = _ok(_ok(r.state, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _night(s, 4, {"%s:2" % MA: [4]})
	_codec_same(s, "Opfer gewählt")
	r = apply_ok(s, Command.end_night(), "Morgen")
	assert_eq(_died(r.events, 2), "MARTYR_SACRIFICE", "Märtyrerin stirbt")
	assert_true(r.state.players[4].alive, "Opfer überlebt")
	assert_eq(_prevented_by(r.events, 4), "maertyrerin", "protokolliert")


func test_martyr_not_asked_when_victim_survives_anyway() -> void:
	var s := _state([W, MA, "schutzengel", D, "amalia", "detektiv"])
	s = _ok(s, Command.start_night(), "Nacht")
	if s == null:
		return
	var all: Array[GameEvent] = []
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Schutz 4")
	for guard: int in 10:
		if s.pending_prompt == null and RulesEngine.next_step_id(s) == "":
			break
		var cmd := Command.begin_step(RulesEngine.next_step_id(s))
		if s.pending_prompt != null:
			cmd = Command.answer_prompt(s.pending_prompt.id, [4]) if s.pending_prompt.owner == PendingPrompt.OWNER_PACK else _auto(s)
		var cr := apply_ok(s, cmd, "weiter")
		all.append_array(cr.events)
		s = cr.state
	assert_eq(_dropped_reason(all, "%s:2" % MA), "no_decision", "geschütztes Opfer: keine Frage")


# --- Schutzgeist ----------------------------------------------------------------------------------

func test_guardian_spirit_shield_from_next_night() -> void:
	var s := _state([W, SG, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	var r := _dawn(s, -1)
	if r == null:
		return
	s = _ok(r.state, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Schutzgeist stirbt am Tag 1")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 2")
	assert_true(s != null and s.night_plan.has(&"schutzgeist:2"), "Schritt für die Tote")
	s = _night(s, 4, {"schutzgeist:2": [3]})
	if s == null:
		return
	assert_eq(s.shields, [{"holder_id": 3, "source_id": 2, "night": 2}], "Schild vergeben")
	r = apply_ok(s, Command.end_night(), "Morgen 2")
	assert_eq(_died(r.events, 4), "NIGHT_KILL", "anderes Opfer stirbt")
	s = _ok(_ok(r.state, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 3")
	assert_false(s != null and s.night_plan.has(&"schutzgeist:2"), "nur die erste Nacht nach dem Tod")
	r = _dawn(s, 3)
	assert_eq(_prevented_by(r.events, 3) if r != null else "", "schutzgeist", "Schild rettet ab der Folgenacht")
	r = _dawn(_ok(_ok(r.state, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende"), 3) if r != null else null
	assert_eq(_died(r.events, 3) if r != null else "", "NIGHT_KILL", "Schild verbraucht")


func test_guardian_spirit_step_dropped_without_living_person() -> void:
	# Regressionstest (Fuzz, 28.09.2026): Leben keine Personen mehr, öffnete der Schritt der toten Schutzgeist eine
	# Pflichtwahl ohne mögliches Ziel. Wie jede Pflichtwahl ohne Ziel entfällt er mit „no_decision“.
	var r := _dawn(_state([W, SG, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]), -1)
	if r == null:
		return
	var s := _ok(r.state, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Schutzgeist stirbt am Tag 1")
	for id: int in [3, 4, 5, 6, 7, 8, 1]:
		if s != null and not s.open_candidates().is_empty():
			s = _ok(s, Command.create(Command.REJECT_WIN, {"reason": "Test"}), "weiter")
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "Toter %d" % id)
	if s == null:
		return
	assert_eq(s.alive_ids(), [] as Array[int], "niemand lebt")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	var started := apply_ok(s, Command.start_night(), "Nacht 2") if s != null else null
	if started == null:
		return
	assert_eq(_dropped_reason(started.events, "schutzgeist:2"), "no_decision", "Schritt entfällt")
	assert_true(started.state.pending_prompt == null, "keine unbeantwortbare Pflichtwahl")


func test_guardian_spirit_announces_wolf_without_name() -> void:
	var s := _state([W, SG, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Schutzgeist tot vor Nacht 1")
	var r := _dawn(s, -1, {"schutzgeist:2": [1]})
	if r == null:
		return
	var pub := events_of_type(r.events, "GhostWolfAlert")
	assert_true(pub.size() == 1 and pub[0].visibility == Visibility.PUBLIC, "öffentlich am Morgen")
	if pub.size() == 1:
		assert_false(pub[0].data.has("target_id") or pub[0].data.has("holder_id"), "ohne Namen")


# --- Dorfschmied ----------------------------------------------------------------------------------

func test_smith_gives_weapon_from_night_six_and_it_beats_piercing() -> void:
	var s := _state(["seuchenwolf", W, SM, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"])
	var r: CommandResult = null
	for night: int in 5:
		if s != null and s.phase != Phase.SETUP:
			s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
		if s != null:
			s = _ok(s, Command.start_night(), "Nacht")
			assert_false(s != null and s.night_plan.has(&"dorfschmied:3"), "vor Nacht 6 kein Schritt (%d)" % (night + 1))
			r = apply_ok(_night(s, -1), Command.end_night(), "Morgen")
			s = r.state
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 6")
	assert_true(s != null and s.night_plan.has(&"dorfschmied:3"), "ab Nacht 6")
	s = _night(s, -1, {"dorfschmied:3": [4]})
	if s == null:
		return
	assert_eq(s.weapons, [{"holder_id": 4, "smith_id": 3}], "Waffe bei 4")
	s = _ok(s, Command.end_night(), "Morgen 6")
	s = _ok(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), "Schmied stirbt (Gabe bleibt)")
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "Seuchenwolf stirbt: Durchdringung")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	r = _dawn(s, 4)
	if r == null:
		return
	assert_eq(_prevented_by(r.events, 4), "dorfschmied", "Waffe hält auch gegen Durchdringung")
	assert_true(r.state.weapons.is_empty(), "verbraucht")


# --- Verdammniswächter ----------------------------------------------------------------------------

func test_doom_warden_redirects_pack_attack_to_offered_non_wolf() -> void:
	var s := _state([W, VW, "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher", "blutwolf"])
	s = _ok(s, Command.start_night(), "Nacht")
	if s == null:
		return
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Schutz 4")
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Rudel")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Rudel auf 4")
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Verdammniswächter")
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.owner, &"verdammniswaechter", "Schritt nach dem Rudel")
	assert_eq(p.allowed_ids.size(), 2, "zwei Möglichkeiten")
	var offer := p.allowed_ids[0] if p.allowed_ids[0] != 4 else p.allowed_ids[1]
	assert_true(p.allowed_ids.has(4), "das Rudelopfer")
	assert_false([1, 2, 4, 8].has(offer), "Angebot: lebende Nicht-Wolf-Person außer Opfer und Wächter")
	# Abbruch und erneuter Beginn behalten das Angebot (keine neue Ziehung).
	var draws := s.rng.draws
	var again := _ok(_ok(s, Command.cancel_prompt(p.id, "zurück"), "Abbruch"), Command.begin_step(RulesEngine.next_step_id(s)), "erneut")
	if again != null:
		assert_eq(again.pending_prompt.allowed_ids, p.allowed_ids, "gleiches Angebot")
		assert_eq(again.rng.draws, draws, "keine neue Ziehung")
	_codec_same(s, "Angebot offen")
	s = _ok(s, Command.answer_prompt(p.id, [offer]), "Angebot gewählt")
	var r := apply_ok(_night(s, -1), Command.end_night(), "Morgen")
	assert_eq(_died(r.events, offer), "NIGHT_KILL", "Angebot stirbt als Rudelopfer")
	assert_true(r.state.players[4].alive, "ursprüngliches Opfer lebt")


func test_doom_warden_choice_of_protected_victim_keeps_protection() -> void:
	var s := _state([W, VW, "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher", "blutwolf"])
	s = _ok(s, Command.start_night(), "Nacht")
	if s == null:
		return
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [4]), "Schutz 4")
	var r := _dawn(s, 4, {"verdammniswaechter:2": [4]})
	assert_eq(_prevented_by(r.events, 4) if r != null else "", "schutzengel", "Schutz wirkt (S-07)")


func test_doom_warden_as_pack_victim_has_no_judgment() -> void:
	# Regression aus dem Fuzztest (S-15 = B): ist er selbst das Rudelopfer, entfällt sein Schritt.
	var s := _state([W, VW, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	s = _ok(s, Command.start_night(), "Nacht")
	if s == null:
		return
	var r := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, [2]), "Rudel auf den Wächter")
	assert_eq(_dropped_reason(r.events, "%s:2" % VW), "no_decision", "kein Urteil über sich selbst")
	r = apply_ok(r.state, Command.end_night(), "Morgen")
	assert_eq(_died(r.events, 2), "NIGHT_KILL", "der Angriff trifft ihn")
