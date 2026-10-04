extends TestCase
## DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 2 (Feuerteufel)“ (28.09.2026, E-05 bis E-11):
##   RM-DR-131.1 jeder tatsächliche Tod des markierten Ziels verbrennt dessen nächste lebende Nachbarn
##     (nicht bei Korrektur ohne Todesfolgen; überlebt das Ziel, brennt nichts)
##   RM-DR-131.2 höchstens eine aktive Markierung je Feuerteufel, bis Neuwahl oder Tod des Ziels
##   RM-DR-131.3 Nachbarn = nächste lebende links und rechts (RM-DR-003)
##   RM-DR-131.4 jeder Feuerteufel wird als Nachbar verschont, kein Ersatz auf dieser Seite
##   RM-DR-131.5 Mitsieg lebend, kein Alleinsieg
##   RM-DR-131.6 jede Nacht genau eine andere lebende Person markieren (Karte nennt keinen Verzicht; dieselbe Person erneut = behalten)
##   RM-DR-131.7 Markierung erlischt bei Tod oder Rollenverlust des Feuerteufels
##   RM-DR-131.8 mehrfach markiertes Ziel: genau ein Brand, alle Markierungen verbraucht

const FT := "feuerteufel"
const D := "dorfbewohner"
const W := "werwolf"
const SE := "schutzengel"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay(Fixtures.start_with_copies(roles, 1))  # Kopien gleicher Rollen entstehen nach dem Start (PE-07)
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.owner == PendingPrompt.OWNER_WITCH:
		return Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm")
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	if p.stage != &"":
		return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))
	if p.owner == PendingPrompt.OWNER_PACK or p.owner == PendingPrompt.OWNER_PACK2:
		return Command.skip_step(p.step_id, "Test: ruhige Nacht")  # Wölfe ohne vorgesehenes Opfer
	if p.owner == &"feuerteufel":
		return Command.answer_prompt(p.id, Fixtures.pass_targets(s, p))
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Antworten {"<rolle>:<id>" oder "pack": Ziele}; alle anderen Schritte ohne Wirkung. Endet vor EndNight.
func _night(s: GameState, answers: Dictionary = {}) -> GameState:
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
			if key == "pack" and (not answers.has("pack") or (answers["pack"] as Array).is_empty()):
				s = _ok(s, Command.skip_step(p.step_id, "Test: ruhige Nacht"), "Rudel")  # Wölfe ohne vorgesehenes Opfer
			elif answers.has(key) and p.stage == &"":
				s = _ok(s, Command.answer_prompt(p.id, answers[key]), "Antwort %s" % key)
			elif p.owner == &"feuerteufel" and SoloRules.fire_mark_of(s, p.actor_id) != GameState.NO_TARGET and p.allowed_ids.has(SoloRules.fire_mark_of(s, p.actor_id)):
				s = _ok(s, Command.answer_prompt(p.id, [SoloRules.fire_mark_of(s, p.actor_id)]), "Markierung behalten %s" % key)  # dieselbe Person erneut
			else:
				s = _ok(s, _auto(s), "ohne Wirkung %s" % key)
			continue
		var step := RulesEngine.next_step_id(s)
		if step == "":
			return s
		s = _ok(s, Command.begin_step(step), "Schritt %s" % step)
	fail("Nacht endet nicht")
	return null


func _dawn(s: GameState, answers: Dictionary = {}) -> CommandResult:
	s = _night(s, answers)
	return apply_ok(s, Command.end_night(), "Morgen") if s != null else null


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _marks(s: GameState) -> Array:
	return s.fire_marks if s != null else []


## Tote mit Ursache BURN aus Ereignissen, in Reihenfolge.
func _burned(events: Array[GameEvent]) -> Array[int]:
	var out: Array[int] = []
	for e: GameEvent in events_of_type(events, "SeatDied"):
		if String(e.data["cause"]) == "BURN":
			out.append(int(e.data["target_id"]))
	return out


func _dead(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.players:
		if not s.players[id].alive:
			out.append(id)
	out.sort()
	return out


## Feuerteufel `devil` markiert in der ersten Nacht `target`; der Rudelschritt wird mit Grund übersprungen.
func _marked(roles: Array, devil: int, target: int) -> GameState:
	var r := _dawn(_state(roles), {"feuerteufel:%d" % devil: [target], "pack": []})
	return r.state if r != null else null


# --- Katalog und Nachtschritt --------------------------------------------------------------------

func test_catalog_entry() -> void:
	assert_true(RoleCatalog.has_role(&"feuerteufel"), "im Katalog")
	if not RoleCatalog.has_role(&"feuerteufel"):
		return
	assert_eq(RoleCatalog.faction_of(&"feuerteufel"), Faction.SOLO, "Einzelsieg")
	assert_false(RoleCatalog.counts_as_wolf(&"feuerteufel"), "zählt nicht als Wolf")
	assert_eq(RoleCatalog.night_priority(&"feuerteufel"), 76, "Legacy-Stufe 7.6")
	assert_false(RoleCatalog.first_night_only(&"feuerteufel"), "jede Nacht")
	assert_true(RoleCatalog.APPLE_ROLES.has(&"feuerteufel"), "Jede-Nacht-Schritt, Apfel verdoppelt (R-02)")
	assert_true(KillEvent.CAUSES.has(&"BURN"), "eigene Ursache")


func test_step_targets_keep_and_replace() -> void:
	var s := _state([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _ok(s, Command.start_night(), "Nacht")
	s = _ok(s, Command.skip_step(s.pending_prompt.step_id, "Test: ruhige Nacht"), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Feuerteufel") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(String(p.owner), FT, "eigener Prompt")
	assert_eq(p.allowed_ids, [1, 3, 4, 5, 6] as Array[int], "andere Lebende")
	assert_eq([p.min_count, p.max_count], [1, 1], "jede Nacht genau eine Person")
	apply_rejected(s, Command.answer_prompt(p.id, [2]), "invalid_target", "nie er selbst (E-09)")
	apply_rejected(s, Command.answer_prompt(p.id, [3, 4]), "invalid_target_count", "genau ein Ziel")
	apply_rejected(s, Command.answer_prompt(p.id, []), "invalid_target_count", "kein Verzicht: die Karte nennt keinen")
	var r := apply_ok(s, Command.answer_prompt(p.id, [4]), "markiert 4")
	for e: GameEvent in r.events:
		assert_true(e.visibility != Visibility.PUBLIC, "Markierung geheim: %s" % e.type)
	s = _ok(r.state, Command.end_night(), "Morgen")
	assert_eq(_marks(s), [{"devil_id": 2, "target_id": 4}], "eine Markierung")
	_codec_same(s, "Markierung")
	# Nacht 2: dieselbe Person erneut markieren (behalten).
	var r2 := _dawn(s, {"feuerteufel:2": [4], "pack": []})
	s = r2.state if r2 != null else null
	assert_eq(_marks(s), [{"devil_id": 2, "target_id": 4}], "behalten")
	# Nacht 3: neues Ziel ersetzt die alte Markierung.
	var r3 := _dawn(s, {"feuerteufel:2": [5], "pack": []})
	s = r3.state if r3 != null else null
	assert_eq(_marks(s), [{"devil_id": 2, "target_id": 5}], "höchstens eine aktive Markierung")
	# Die alte Zielperson stirbt jetzt: kein Brand.
	var dead := apply_ok(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), "alte Zielperson stirbt")
	assert_eq(_burned(dead.events), [] as Array[int], "alte Markierung wirkt nicht mehr")


# --- Brand ----------------------------------------------------------------------------------------

func test_pack_death_of_target_burns_nearest_living_neighbours() -> void:
	var s := _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"], 2, 5)
	if s == null:
		return
	s = _ok(s, _gm("kill", {"target_id": 6, "trigger_effects": false}), "Platz 6 bereits tot")
	# Nacht 2: Rudel frisst 5 → brennen 7 (nächster Lebender im Uhrzeigersinn, 6 ist tot) und 4.
	var r := _dawn(s, {"pack": [5]})
	if r == null:
		return
	assert_eq(_burned(r.events), [7, 4] as Array[int], "nächste lebende Nachbarn, Uhrzeigersinn zuerst")
	assert_eq(_dead(r.state), [4, 5, 6, 7] as Array[int], "Ziel und zwei Nachbarn tot")
	assert_eq(_marks(r.state), [], "Markierung verbraucht")
	for e: GameEvent in events_of_type(r.events, "SeatDied"):
		assert_true(e.visibility != Visibility.PUBLIC, "Ursache nicht öffentlich")
	_codec_same(r.state, "nach Brand")


func test_every_real_death_triggers_but_not_correction_without_effects() -> void:
	# Hinrichtung.
	var s := _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2, 5)
	s = _ok(s, Command.nominate(3, 5), "Nominierung")
	var r := apply_ok(s, Command.decide_execution(5), "Hinrichtung des Ziels") if s != null else null
	assert_eq(_burned(r.events) if r != null else [], [6, 4] as Array[int], "Brand bei Hinrichtung")
	# Korrektur mit Todesfolgen.
	s = _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2, 5)
	r = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Korrektur mit Folgen") if s != null else null
	assert_eq(_burned(r.events) if r != null else [], [6, 4] as Array[int], "Brand bei Korrektur mit Folgen")
	# Korrektur ohne Todesfolgen: kein Brand, Markierung trotzdem beendet (Ziel tot).
	s = _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2, 5)
	r = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": false}), "Korrektur ohne Folgen") if s != null else null
	if r == null:
		return
	assert_eq(_burned(r.events), [] as Array[int], "kein Brand ohne Todesfolgen")
	assert_eq(_marks(r.state), [], "Markierung endet mit dem Tod des Ziels")
	s = _ok(r.state, _gm("revive", {"target_id": 5}), "Ziel wiederbelebt")
	r = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "erneuter Tod") if s != null else null
	assert_eq(_burned(r.events) if r != null else [0], [] as Array[int], "verbrauchte Markierung wirkt nicht erneut")


func test_surviving_target_does_not_burn() -> void:
	# Schutzengel schützt das Ziel vor dem Rudel: kein Tod, kein Brand, Markierung bleibt (Legacy-Fehler entfällt).
	var s := _marked([W, FT, D, "amalia", SE, "detektiv", "wahnsinniger-kutscher"], 2, 4)
	var r := _dawn(s, {"pack": [4], "schutzengel:5": [4]})
	if r == null:
		return
	assert_eq(_burned(r.events), [] as Array[int], "Ziel überlebt, nichts brennt")
	assert_eq(_marks(r.state), [{"devil_id": 2, "target_id": 4}], "Markierung bleibt")


func test_fire_devils_are_spared_without_replacement() -> void:
	# 3 und 5 sind Feuerteufel; 5 markiert 4, 4 stirbt → beide Nachbarn sind Feuerteufel, niemand brennt.
	var s := _marked([W, D, FT, "amalia", FT, "detektiv", "wahnsinniger-kutscher"], 5, 4)
	var r := apply_ok(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), "Ziel stirbt") if s != null else null
	if r == null:
		return
	assert_eq(_burned(r.events), [] as Array[int], "kein Ersatz hinter den Feuerteufeln")
	assert_eq(_dead(r.state), [4] as Array[int], "nur das Ziel")
	# Einseitig: Feuerteufel 3 markiert 2; Nachbarn 3 (verschont) und 1 (brennt).
	s = _marked([W, D, FT, "amalia", "detektiv", "wahnsinniger-kutscher"], 3, 2)
	r = apply_ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Ziel neben dem Feuerteufel") if s != null else null
	assert_eq(_burned(r.events) if r != null else [], [1] as Array[int], "nur die andere Seite brennt")


func test_two_devils_same_target_burn_once() -> void:
	var r := _dawn(_state([W, FT, D, "amalia", "detektiv", FT, "wahnsinniger-kutscher", "waechter-am-tor"]), {"feuerteufel:2": [4], "feuerteufel:6": [4], "pack": []})
	if r == null:
		return
	var s := r.state
	assert_eq(_marks(s).size(), 2, "zwei Markierungen auf 4")
	r = apply_ok(s, _gm("kill", {"target_id": 4, "trigger_effects": true}), "4 stirbt")
	if r == null:
		return
	assert_eq(_burned(r.events), [5, 3] as Array[int], "genau ein Brand (E-11)")
	assert_eq(_marks(r.state), [], "beide Markierungen verbraucht")


func test_burn_chain_through_marked_neighbour() -> void:
	# 2 markiert 5, 7 markiert 6; 5 stirbt → 6 brennt → 6 war markiert → 8 (und 5 ist tot, also 4) brennen.
	var r := _dawn(_state([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", FT, "waechter-am-tor", "der-weise", "nachtwaechter"]), {"feuerteufel:2": [5], "feuerteufel:7": [6], "pack": []})
	if r == null:
		return
	r = apply_ok(r.state, _gm("kill", {"target_id": 5, "trigger_effects": true}), "5 stirbt")
	if r == null:
		return
	# Brand von 5: Nachbarn 6 und 4. 6 stirbt zuerst und löst sofort den zweiten Brand aus:
	# Nachbarn von 6 sind jetzt 7 (Feuerteufel, verschont) und 4 → 4 stirbt im zweiten Brand;
	# der erste Brand findet 4 danach tot vor.
	assert_eq(_burned(r.events), [6, 4] as Array[int], "Kettenbrand, jede Person stirbt einmal")
	assert_eq(_dead(r.state), [4, 5, 6] as Array[int], "Feuerteufel 7 verschont")
	assert_eq(_marks(r.state), [], "beide Markierungen verbraucht")
	_codec_same(r.state, "Kette")


func test_protection_and_personal_shields_against_burn() -> void:
	# Schutzengel schützt nur vor dem Rudel (RM-DR-004/005): der geschützte Nachbar verbrennt trotzdem.
	var s := _marked([W, FT, D, "amalia", SE, "detektiv", "wahnsinniger-kutscher"], 2, 3)
	var r := _dawn(s, {"pack": [3], "schutzengel:5": [4]})
	assert_eq(_burned(r.events) if r != null else [], [4] as Array[int], "geschützter Nachbar 4 brennt; 2 ist Feuerteufel")
	# Rudelvater überlebt einmal je Leben einen Tod, der weder Rudel noch Lynch noch Korrektur ist.
	s = _marked([W, FT, D, "rudelvater", "amalia", "detektiv", "wahnsinniger-kutscher"], 2, 5)
	r = apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Ziel stirbt") if s != null else null
	if r == null:
		return
	assert_eq(_burned(r.events), [6] as Array[int], "Rudelvater 4 überlebt den Brand")
	assert_true(r.state.players[4].alive, "Rudelvater lebt")


func test_devil_death_or_role_loss_ends_mark() -> void:
	# Tod des Feuerteufels (auch ohne Todesfolgen).
	var s := _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2, 5)
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": false}), "Feuerteufel tot")
	assert_eq(_marks(s), [], "Markierung erlischt")
	var r := apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Ziel stirbt danach") if s != null else null
	assert_eq(_burned(r.events) if r != null else [0], [] as Array[int], "kein Brand nach dem Tod des Feuerteufels")
	# Rollenverlust per Korrektur.
	s = _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2, 5)
	s = _ok(s, _gm("set_role", {"target_id": 2, "role_id": D}), "Rolle weg")
	assert_eq(_marks(s), [], "Markierung erlischt bei Rollenverlust")
	# Wiederbelebter Feuerteufel startet ohne Markierung.
	s = _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2, 5)
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Feuerteufel tot")
	s = _ok(s, _gm("revive", {"target_id": 2}), "wiederbelebt")
	assert_eq(_marks(s), [], "keine alte Markierung")


# --- Mitsieg --------------------------------------------------------------------------------------

func test_living_devil_co_wins_with_every_detected_win() -> void:
	# Dorfsieg: letzter Wolf stirbt, Feuerteufel 2 lebt → Mitsieger.
	var s := _state([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "letzter Wolf tot")
	if s == null:
		return
	var open := s.open_candidates()
	assert_eq(open.size(), 1, "ein Kandidat")
	if open.size() == 1:
		assert_eq(open[0].reason_key, WinCandidate.REASON_NO_WOLVES_ALIVE, "Dorfsieg")
		assert_eq(open[0].co_winner_ids, [2] as Array[int], "Feuerteufel gewinnt mit")
	_codec_same(s, "Kandidat mit Mitsieger")
	# Wolfssieg durch Parität: Feuerteufel zählt als Nicht-Wolf und gewinnt lebend mit.
	s = _state([W, "blutwolf", FT, D, "amalia", "detektiv"])
	for id: int in [4, 5]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Tod %d" % id)
	if s == null:
		return
	var wolves := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_WOLF_PARITY)
	assert_true(wolves.size() == 1 and (wolves[0] as WinCandidate).co_winner_ids == ([3] as Array[int]), "Mitsieg beim Wolfssieg")
	# Toter Feuerteufel gewinnt nicht mit.
	s = _state([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Feuerteufel tot")
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "letzter Wolf tot")
	if s == null:
		return
	assert_true(s.open_candidates().all(func(c: WinCandidate) -> bool: return c.co_winner_ids.is_empty()), "nur lebend")


func test_co_win_with_solo_win_and_two_devils() -> void:
	# Einzelsieg des Manipulators bei genau drei Lebenden: beide lebenden Feuerteufel gewinnen mit.
	var s := _state([W, "manipulator", FT, FT, D, "amalia"])
	for id: int in [5, 6, 1]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Tod %d" % id)
	if s == null:
		return
	var solo := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_MANIPULATOR)
	assert_eq(solo.size(), 1, "Manipulator-Sieg")
	if solo.size() == 1:
		assert_eq((solo[0] as WinCandidate).beneficiary_ids, [2] as Array[int], "Begünstigter bleibt allein der Manipulator")
		assert_eq((solo[0] as WinCandidate).co_winner_ids, [3, 4] as Array[int], "beide Feuerteufel als Mitsieger")
	_codec_same(s, "zwei Mitsieger")


func test_no_solo_win_of_his_own() -> void:
	# Feuerteufel allein mit einer Dorfperson und ohne Wolf: nur der Dorfsieg (mit ihm), kein eigener Sieg.
	var s := _state([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	for id: int in [4, 5, 6, 1]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Tod %d" % id)
	if s == null:
		return
	assert_true(s.open_candidates().all(func(c: WinCandidate) -> bool: return c.kind != Faction.SOLO), "kein Einzelsieg")


# --- Laden und Replay -----------------------------------------------------------------------------

func test_load_rejects_inconsistent_marks() -> void:
	var s := _marked([W, FT, D, "amalia", "detektiv", "wahnsinniger-kutscher"], 2, 4)
	if s == null:
		return
	for bad: Array in [[{"devil_id": 2, "target_id": 2}], [{"devil_id": 2, "target_id": 4}, {"devil_id": 2, "target_id": 5}], [{"devil_id": 9, "target_id": 4}]]:
		var d := s.to_dict()
		d["fire_marks"] = bad
		assert_true(GameState.from_dict(d) == null, "abgelehnt: %s" % str(bad))
