extends TestCase
## DECISION-LOG „Rollenaudit · Informationsrollen“ (28.09.2026, Fragen I-01 bis I-15).
##   Traumdeuter (7.0): jede Nacht wählt der Spielleiter drei andere Lebende, mindestens einer zählt als
##     Wolf; der Traumdeuter erfährt nur „mindestens ein Wolf“ (I-01, I-05, I-02).
##   Kopfgeldjäger (3.2): je Lynch-Tod einer Wolfsperson, den er lebend mit der Rolle erlebt, eine Liste
##     wie beim Traumdeuter in einer folgenden Nacht; ohne genug Ziele verfällt sie mit Hinweis (I-04, I-06).
##   König (4.4): einmal je Leben, sobald strikt mehr Tote als Lebende; eine andere lebende Person der
##     aktuellen Fraktion Dorf mit wahrer Rolle (I-03).
##   Kriegerin des Lichts (6.0): einmal je Leben; Wolf? nur an sie; kein Wolf: sie stirbt am Morgen (I-07).
##   Blutpriester (8.2): einmal je Leben; Opfer eine andere Lebende (stirbt am Morgen, kein Wolfsangriff),
##     der Spielleiter nennt ihm 0 bis 3 lebende Wölfe (I-08, I-13).
##   Amalia: Tagesaktion bei mindestens drei lebenden Wölfen; öffentliche Antwort, sie stirbt sofort (I-09).
##   Detektiv: Wolfstod bei lebendem Detektiv und mindestens einem anderen Wolf: öffentliche Richtung vom
##     Platz des Toten zum nächsten Wolf; nachts erst am Morgen; verwandelte Wolfskinder zählen (I-10, I-14).
##   Die Ewigen (4.8): gemeinsamer Schritt, eine andere Person prüfen, nur Ja/Nein (Einzelsieg); Mitsieg
##     aller Ewigen mit einer mit Ja geprüften Person (I-11, I-12, I-15).

const TD := "traumdeuter"
const KG := "kopfgeldjaeger"
const KO := "koenig"
const KR := "kriegerin-des-lichts"
const BP := "blutpriester"
const AM := "amalia"
const DE := "detektiv"
const EW := "die-ewigen"
const D := "dorfbewohner"
const W := "werwolf"


func _state(roles: Array, appearances: Dictionary = {}) -> GameState:
	var commands := Fixtures.start_with_copies(roles, 1)  # Kopien gleicher Rollen entstehen nach dem Start (PE-07)
	if not appearances.is_empty():
		var payload := commands[0].payload.duplicate(true)
		payload["appearances"] = appearances
		commands[0] = Command.start_game(payload)
	var r := RulesEngine.replay(commands)
	assert_true(r.ok, "Start (%s)" % r.error)
	return r.state if r.ok else null


func _gm(kind: String, fields: Dictionary) -> Command:
	return CorrectionFixtures.gm(kind, fields, "Test")


func _ok(s: GameState, c: Command, label: String) -> GameState:
	return apply_ok(s, c, label).state if s != null else null


## Nacht beginnen (falls nötig) und bis zum Schritt `key` laufen; andere Prompts mit „kein Ziel“.
func _to_step(s: GameState, key: String) -> GameState:
	if s == null:
		return null
	if s.phase != Phase.NIGHT:
		s = _ok(s, Command.start_night(), "Nachtbeginn")
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			if s.pending_prompt.step_id.ends_with(":" + key):
				return s
			s = _ok(s, _auto(s), "fremder Schritt")
			continue
		var step := RulesEngine.next_step_id(s)
		if step == "":
			fail("Schritt %s nicht erreicht" % key)
			return null
		s = _ok(s, Command.begin_step(step), "Schritt %s" % step)
	fail("Schritt %s: Schleife" % key)
	return null


## Antwort ohne Wirkung: Verzicht, sonst die ersten zulässigen Ziele, dann „Gezeigt“.
func _auto(s: GameState) -> Command:
	var p := s.pending_prompt
	if p.stage == &"":
		return Command.answer_prompt(p.id, Fixtures.pass_targets(s, p))
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	return Command.answer_stage_targets(p.id, String(p.stage), p.allowed_ids.slice(0, p.min_count))


## Rest der Nacht ohne Aktionen, dann Morgen. Das Rudel muss töten: Sein Opfer wird am Morgen sofort wiederbelebt, damit der Tag mit allen
## Lebenden beginnt wie in den Vorgaben der Tests.
func _finish_night(s: GameState) -> GameState:
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			s = _ok(s, _auto(s), "kein Ziel")
			continue
		if RulesEngine.next_step_id(s) == "":
			var victim := s.pack_target_id
			s = _ok(s, Command.end_night(), "Morgen")
			if s != null and victim != GameState.NO_TARGET and not s.players[victim].alive:
				s = _ok(s, _gm("revive", {"target_id": victim}), "Rudelopfer wiederbelebt")
			return s
		s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
	fail("Nacht endet nicht")
	return null


func _next_day(s: GameState) -> GameState:
	if s == null:
		return null
	if s.phase == Phase.DAY:
		if s.day_step != Phase.DAY_EXECUTION_DECIDED and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.decide_execution(-1), "keine Hinrichtung")
		if s != null and s.day_step != Phase.DAY_ENDED:
			s = _ok(s, Command.end_day(), "Tagesende")
	if s != null and s.phase != Phase.NIGHT:
		s = _ok(s, Command.start_night(), "Nachtbeginn")
	return _finish_night(s)


func _lynch(s: GameState, nominator: int, target: int) -> CommandResult:
	s = _ok(s, Command.nominate(nominator, target), "Nominierung")
	return apply_ok(s, Command.decide_execution(target), "Hinrichtung") if s != null else null


## Ladeprüfungen (GameState.from_dict inklusive Prompt-Abgleich) und verlustfreie Rundreise.
func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


func _plan_has(s: GameState, key: String) -> bool:
	return s != null and s.night_plan.has(StringName(key))


func _dropped_reason(events: Array[GameEvent], key: String) -> String:
	for e: GameEvent in events_of_type(events, "StepDropped"):
		if String(e.data["step_id"]).ends_with(":" + key):
			return String(e.data["reason"])
	return ""


func _only_actor(events: Array[GameEvent], type: String, actor: int, label: String) -> GameEvent:
	var list := events_of_type(events, type)
	assert_eq(list.size(), 1, "%s: genau ein %s" % [label, type])
	if list.size() != 1:
		return null
	assert_eq(list[0].visibility, Visibility.ACTOR, "%s: nur actor" % label)
	assert_eq(list[0].actor_id, actor, "%s: an Person %d" % [label, actor])
	return list[0]


# --- Katalog --------------------------------------------------------------------------------------

func test_catalog_entries() -> void:
	var prio := {TD: 70, KG: 32, KO: 44, KR: 60, BP: 82}
	for role: String in [TD, KG, KO, KR, BP, AM, DE, EW]:
		assert_true(RoleCatalog.has_role(StringName(role)), "%s im Katalog" % role)
		if RoleCatalog.has_role(StringName(role)):
			assert_eq(RoleCatalog.faction_of(StringName(role)), Faction.VILLAGE, "%s Dorf" % role)
			assert_false(RoleCatalog.counts_as_wolf(StringName(role)), "%s kein Wolf" % role)
			assert_eq(RoleCatalog.night_priority(StringName(role)), int(prio.get(role, 0)), "%s Priorität" % role)
	assert_eq(RoleCatalog.ETERNAL_PRIORITY, 48, "gemeinsamer Schritt der Ewigen 4.8")
	for kind: String in [TD, KG, KO, KR, BP, EW]:
		assert_false(StepQueue.is_skippable("night:1:0:%s:1" % kind), "%s nicht überspringbar" % kind)


# --- Traumdeuter ----------------------------------------------------------------------------------

func test_dreamer_needs_three_others_with_a_wolf_and_learns_only_that() -> void:
	var s := _to_step(_state([W, "blutwolf", TD, D, "amalia", "detektiv"]), "%s:3" % TD)
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.stage, &"targets", "Stufe Auswahl")
	assert_eq(p.allowed_ids, [1, 2, 4, 5, 6] as Array[int], "nur andere Lebende")
	assert_eq([p.min_count, p.max_count], [3, 3], "genau drei")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [4, 5, 6]), "no_wolf_selected", "ohne Wolf gesperrt")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [3, 1, 4]), "invalid_target", "nicht sich selbst")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [1, 4]), "invalid_target_count", "nur zwei")
	_codec_same(s, "Auswahl offen")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [1, 2, 4]), "zwei Wölfe erlaubt")
	if s == null:
		return
	assert_eq(s.pending_prompt.stage, &"shown", "Stufe Gezeigt")
	_codec_same(s, "Gezeigt offen")
	var r := apply_ok(s, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	var shown := _only_actor(r.events, "DreamRevealed", 3, "Traumdeuter")
	if shown != null:
		assert_eq(shown.data["target_ids"], [1, 2, 4], "die drei Namen")
		assert_false(shown.data.has("wolf_count") or shown.data.has("wolf_ids"), "keine Anzahl, keine Wölfe")
	var gm := events_of_type(r.events, "DreamRecorded")
	assert_true(gm.size() == 1 and gm[0].visibility == Visibility.GM and gm[0].data["wolf_ids"] == [1, 2], "Spielleiter-Datensatz mit Wölfen")
	s = _finish_night(r.state)
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 2")
	assert_true(_plan_has(s, "%s:3" % TD), "jede Nacht")


func test_dreamer_true_wolf_count_and_drop_without_enough_targets() -> void:
	# Trugbilderwolf mit Scheinrolle Dorfbewohner zählt als Wolf (I-02).
	var s := _to_step(_state(["trugbilderwolf", TD, D, "amalia", "detektiv", "wahnsinniger-kutscher"], {"1": "dorfbewohner"}), "%s:2" % TD)
	if s == null:
		return
	_ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [1, 3, 4]), "Trugbild ist der Wolf")
	# Weniger als drei andere Lebende: Schritt entfällt ohne Entscheidung (nach der Rudelantwort).
	var t := _state([W, TD, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	for id: int in [4, 5, 6]:
		t = _ok(t, _gm("kill", {"target_id": id, "trigger_effects": false}), "tot %d" % id)
	t = _ok(t, Command.start_night(), "Nacht")
	if t == null:
		return
	assert_true(_plan_has(t, "%s:2" % TD), "geplant")
	var r := apply_ok(t, Command.answer_prompt(t.pending_prompt.id, Fixtures.pass_targets(t, t.pending_prompt)), "Rudel")
	assert_eq(_dropped_reason(r.events, "%s:2" % TD), "no_decision", "entfällt protokolliert")
	assert_eq(RulesEngine.next_step_id(r.state), "", "kein weiterer Schritt")


# --- Kopfgeldjäger --------------------------------------------------------------------------------

func test_bounty_hunter_gets_one_list_per_wolf_lynch() -> void:
	# Neun Personen: Ein Rudelopfer (jede Nacht) soll keine Wolfsparität erzeugen.
	var s := _state([W, "blutwolf", "rudelvater", KG, D, "amalia", "detektiv", "wahnsinniger-kutscher", "nachtwaechter"])
	s = _ok(s, Command.start_night(), "Nacht 1")
	assert_false(_plan_has(s, "%s:4" % KG), "ohne Lynch kein Schritt")
	s = _finish_night(s)
	var r := _lynch(s, 5, 6)  # Dorfbewohner: keine Liste
	s = _ok(_ok(r.state, Command.end_day(), "Ende"), Command.start_night(), "Nacht 2") if r != null else null
	assert_false(_plan_has(s, "%s:4" % KG), "Lynch eines Nicht-Wolfs zählt nicht")
	s = _finish_night(s)
	r = _lynch(s, 5, 1)
	if r == null:
		return
	assert_eq(int(r.state.bounty_credits.get(4, 0)), 1, "ein Guthaben je Wolfs-Lynch")
	s = _ok(r.state, Command.end_day(), "Ende")
	s = _to_step(s, "%s:4" % KG)
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [2, 3, 5, 7, 8, 9] as Array[int], "andere Lebende")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [5, 7, 8]), "no_wolf_selected", "Freigabe erst mit Wolf")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [2, 3, 5]), "zwei Wölfe erlaubt (I-06)")
	r = apply_ok(s, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	_only_actor(r.events, "BountyRevealed", 4, "Kopfgeldjäger")
	assert_eq(int(r.state.bounty_credits.get(4, 0)), 0, "Guthaben verbraucht")
	s = _next_day(_finish_night(r.state))
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 4")
	assert_false(_plan_has(s, "%s:4" % KG), "ohne neuen Lynch keine Liste")


func test_bounty_hunter_only_counts_real_wolf_lynch_while_holding_role() -> void:
	# Spielleitertötung eines Wolfs ist kein Lynch; ein toter Kopfgeldjäger sammelt nichts.
	var s := _next_day(_state([W, "blutwolf", KG, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]))
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "Korrektur-Tod eines Wolfs")
	assert_eq(int(s.bounty_credits.get(3, 0)) if s != null else -1, 0, "kein Lynch")
	s = _ok(s, _gm("kill", {"target_id": 3, "trigger_effects": false}), "Kopfgeldjäger tot")
	s = _ok(s, _gm("execute", {"target_id": 2}), "Wolf hingerichtet")
	assert_eq(int(s.bounty_credits.get(3, 0)) if s != null else -1, 0, "toter Kopfgeldjäger sammelt nichts")


func test_bounty_list_expires_with_notice_and_survives_block() -> void:
	# Acht Personen: Ein Rudelopfer (jede Nacht) soll keine Wolfsparität erzeugen.
	var s := _state([W, "blutwolf", KG, D, "amalia", "detektiv", "albtraumwolf", "nachtwaechter"])
	s = _next_day(s)
	var r := _lynch(s, 4, 1)
	if r == null:
		return
	s = _ok(r.state, Command.end_day(), "Ende")
	# Nacht 2: Albtraumwolf blockiert den Kopfgeldjäger → Guthaben bleibt.
	s = _ok(s, Command.start_night(), "Nacht 2")
	if s == null:
		return
	assert_eq(s.pending_prompt.owner, PendingPrompt.OWNER_PACK, "Rudel zuerst (2,0)")
	s = _ok(s, Command.skip_step(s.pending_prompt.step_id, "Test: ruhige Nacht"), "kein Opfer")
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Albtraumwolf")
	assert_eq(s.pending_prompt.owner if s != null else &"", &"albtraumwolf", "Albtraumwolf nach dem Rudel (2,1), vor dem Kopfgeldjäger (3,2)")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [3]), "blockiert 3")
	s = _finish_night_before_end(s)
	assert_eq(int(s.bounty_credits.get(3, 0)) if s != null else -1, 1, "blockiert: Guthaben bleibt")
	s = _end_night_revived(s)
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	# Nur noch Wolf 2, Kopfgeldjäger 3 und Dorfbewohner 4 leben → Liste verfällt mit Hinweis.
	for id: int in [7, 5, 6, 8]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "tot %d" % id)
	r = apply_ok(s, Command.start_night(), "Nacht 3")
	var all: Array[GameEvent] = r.events.duplicate()
	s = r.state
	for guard: int in 10:
		if s == null or s.phase != Phase.NIGHT or (s.pending_prompt == null and RulesEngine.next_step_id(s) == ""):
			break
		var cr := apply_ok(s, Command.answer_prompt(s.pending_prompt.id, Fixtures.pass_targets(s, s.pending_prompt)) if s.pending_prompt != null else Command.begin_step(RulesEngine.next_step_id(s)), "weiter")
		all.append_array(cr.events)
		s = cr.state
	assert_eq(_dropped_reason(all, "%s:3" % KG), "no_decision", "ohne genug Ziele entfallen")
	_only_actor(all, "BountyExpired", 3, "Hinweis an den Kopfgeldjäger")
	assert_eq(int(s.bounty_credits.get(3, 0)) if s != null else -1, 0, "Liste verfallen")


# --- König ----------------------------------------------------------------------------------------

func test_king_learns_one_village_person_once_per_life() -> void:
	var s := _state([W, KO, "dorfwache", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"])
	for id: int in [4, 5, 6, 7, 8]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "tot %d" % id)
	s = _ok(s, Command.start_night(), "5 tot, 5 leben")
	assert_false(_plan_has(s, "%s:2" % KO), "Gleichstand zählt nicht")
	s = _finish_night(s)
	s = _ok(s, _gm("kill", {"target_id": 9, "trigger_effects": false}), "6 tot, 4 leben")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _to_step(s, "%s:2" % KO)
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [3, 10] as Array[int], "nur andere lebende Dorfpersonen")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [1]), "invalid_target", "kein Wolf")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [3]), "Dorfwache")
	_codec_same(s, "Ergebnis offen")
	var r := apply_ok(s, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	var e := _only_actor(r.events, "KingRevealed", 2, "König")
	if e != null:
		assert_true(int(e.data["target_id"]) == 3 and String(e.data["role_id"]) == "dorfwache", "wahre Rolle")
	s = _finish_night(r.state)
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 3")
	assert_false(_plan_has(s, "%s:2" % KO), "nur einmal je Leben")
	s = _finish_night(s)
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": false}), "König tot")
	s = _ok(s, _gm("revive", {"target_id": 2}), "wiederbelebt")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 4")
	assert_true(_plan_has(s, "%s:2" % KO), "Wiederbelebung setzt zurück")


# --- Kriegerin des Lichts -------------------------------------------------------------------------

func test_warrior_hits_wolf_privately_and_wolf_survives() -> void:
	var s := _to_step(_state([W, KR, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:2" % KR)
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [1, 3, 4, 5, 6] as Array[int], "andere Lebende")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [1]), "Angriff auf den Wolf")
	_codec_same(s, "Ergebnis offen")
	var r := apply_ok(s, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	var e := _only_actor(r.events, "WarriorRevealed", 2, "Kriegerin")
	if e != null:
		assert_true(bool(e.data["is_wolf"]), "Wolf erkannt")
	s = _finish_night(r.state)
	assert_true(s != null and s.players[1].alive and s.players[2].alive, "beide leben")
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _ok(s, Command.start_night(), "Nacht 2")
	assert_false(_plan_has(s, "%s:2" % KR), "einmal je Leben")


func test_warrior_wrong_dies_at_dawn() -> void:
	# Kriegerin 3 irrt: Tod erst am Morgen, Ursache WARRIOR_WRONG; ein Verzicht verbraucht nichts.
	var s := _to_step(_state([W, D, KR, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:3" % KR)
	if s == null:
		return
	var declined := _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", []), "Verzicht")
	if declined != null:
		assert_false(declined.players[3].ability_uses.has("kriegerin-des-lichts:attack"), "Verzicht verbraucht nichts")
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [2]), "kein Wolf")
	s = _ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Gezeigt")
	assert_true(s != null and s.players[3].alive, "nachts noch am Leben")
	var r := apply_ok(_finish_night_before_end(s), Command.end_night(), "Morgen")
	# Das Rudel tötet jede Nacht zusätzlich (NIGHT_KILL); gezählt wird nur der Tod durch den Irrtum der Kriegerin.
	var died := events_of_type(r.events, "SeatDied").filter(func(e: GameEvent) -> bool: return String(e.data["cause"]) != "NIGHT_KILL")
	assert_true(died.size() == 1 and int(died[0].data["target_id"]) == 3 and String(died[0].data["cause"]) == "WARRIOR_WRONG", "stirbt am Morgen")


## Nacht beenden; das Rudelopfer wird am Morgen sofort wiederbelebt (siehe `_finish_night`).
func _end_night_revived(s: GameState) -> GameState:
	var victim := s.pack_target_id
	s = _ok(s, Command.end_night(), "Morgen")
	if s != null and victim != GameState.NO_TARGET and not s.players[victim].alive:
		s = _ok(s, _gm("revive", {"target_id": victim}), "Rudelopfer wiederbelebt")
	return s


func _finish_night_before_end(s: GameState) -> GameState:
	for guard: int in 40:
		if s == null:
			return null
		if s.pending_prompt != null:
			s = _ok(s, _auto(s), "kein Ziel")
			continue
		if RulesEngine.next_step_id(s) == "":
			return s
		s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schritt")
	return null


func test_sacrificed_person_sleeps_rest_of_night() -> void:
	# Todesmarkierung (Decision Log „Nachttode“): Blutpriester 2 opfert Blutpriester 3 (gleiche Priorität,
	# später nach Personen-ID); dessen Schritt entfällt, er stirbt am Morgen.
	var s := _to_step(_state([W, BP, BP, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:2" % BP)
	if s == null:
		return
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [3]), "Opfer 3")
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "reveal", []), "keine Aufdeckung")
	var r := apply_ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Gezeigt")
	assert_eq(_dropped_reason(r.events, "%s:3" % BP), "marked_for_death", "Opfer wacht nicht mehr auf")
	assert_true(r.state.players[3].alive, "Opfer lebt bis zum Morgen")
	_codec_same(r.state, "Markierung")
	r = apply_ok(r.state, Command.end_night(), "Morgen")
	# Das Rudel tötet jede Nacht zusätzlich (NIGHT_KILL); gezählt wird nur der Tod durch die Markierung.
	var died := events_of_type(r.events, "SeatDied").filter(func(e: GameEvent) -> bool: return String(e.data["cause"]) != "NIGHT_KILL")
	assert_true(died.size() == 1 and String(died[0].data["cause"]) == "BLOOD_SACRIFICE" and int(died[0].data["source_id"]) == 2, "Blutopfer am Morgen")


# --- Blutpriester ---------------------------------------------------------------------------------

func test_blood_priest_sacrifice_and_private_reveal() -> void:
	var s := _state([W, "blutwolf", BP, "schutzengel", D, "amalia", "detektiv"])
	s = _ok(s, Command.start_night(), "Nacht")
	if s == null:
		return
	assert_eq(s.pending_prompt.owner, &"schutzengel", "Schutzengel zuerst")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, [5]), "schützt 5")
	s = _to_step(s, "%s:3" % BP)
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.allowed_ids, [1, 2, 4, 5, 6, 7] as Array[int], "andere Lebende (I-13)")
	apply_rejected(s, Command.answer_stage_targets(p.id, "targets", [3]), "invalid_target", "nicht sich selbst")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [5]), "opfert 5")
	if s == null:
		return
	assert_eq(s.pending_prompt.stage, &"reveal", "Aufdeckung")
	assert_eq(s.pending_prompt.allowed_ids, [1, 2] as Array[int], "nur lebende Wölfe")
	assert_eq([s.pending_prompt.min_count, s.pending_prompt.max_count], [0, 3], "0 bis 3")
	apply_rejected(s, Command.answer_stage_targets(p.id, "reveal", [4]), "invalid_target", "kein Wolf")
	_codec_same(s, "Aufdeckung offen")
	s = _ok(s, Command.answer_stage_targets(p.id, "reveal", [2, 1]), "zwei Wölfe")
	var r := apply_ok(s, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	var e := _only_actor(r.events, "BloodRevealed", 3, "Blutpriester")
	if e != null:
		assert_eq(e.data["revealed_ids"], [1, 2], "Namen der Wölfe")
		assert_false(e.data.has("victim_id"), "kein Opferfeld")
	r = apply_ok(r.state, Command.end_night(), "Morgen")
	assert_false(r.state.players[5].alive, "Schutzengel wirkt nicht")
	assert_true(r.state.players[3].ability_uses.has("blutpriester:sacrifice"), "verbraucht")


func test_blood_priest_victim_packfather_survives_once() -> void:
	var s := _to_step(_state(["rudelvater", W, BP, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:3" % BP)
	if s == null:
		return
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [1]), "Rudelvater als Opfer")
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "reveal", [1]), "zeigt ihn")
	s = _ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Gezeigt")
	var r := apply_ok(s, Command.end_night(), "Morgen")
	assert_true(r.state.players[1].alive, "Rudelvater überlebt den ersten Nicht-Rudel-Tod")
	assert_eq(events_of_type(r.events, "KillPrevented").size(), 1, "protokolliert verhindert")


# --- Amalia ---------------------------------------------------------------------------------------

func test_amalia_day_sacrifice_with_public_answer() -> void:
	var s := _next_day(_state([W, "blutwolf", "rudelvater", AM, D, "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"]))
	if s == null:
		return
	apply_rejected(s, Command.amalia_sacrifice(5, true), "not_amalia", "nur Amalia")
	apply_rejected(s, Command.create(Command.AMALIA_SACRIFICE, {"player_id": 4}), "invalid_answer", "Antwort Pflicht")
	var r := apply_ok(s, Command.amalia_sacrifice(4, false), "Opfer")
	var pub := events_of_type(r.events, "AmaliaAnswered")
	assert_true(pub.size() == 1 and pub[0].visibility == Visibility.PUBLIC and int(pub[0].data["player_id"]) == 4 and pub[0].data["answer"] == false, "öffentliche Antwort")
	var died := events_of_type(r.events, "SeatDied")
	assert_true(died.size() == 1 and int(died[0].data["target_id"]) == 4 and String(died[0].data["cause"]) == "AMALIA_SACRIFICE", "stirbt sofort")
	apply_rejected(r.state, Command.amalia_sacrifice(4, true), "player_dead", "nur lebend")
	var night := _ok(_ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende"), Command.start_night(), "Nacht")
	apply_rejected(night, Command.amalia_sacrifice(4, true), "wrong_phase", "nur am Tag")


func test_amalia_needs_three_living_wolves() -> void:
	var s := _next_day(_state([W, "blutwolf", "rudelvater", AM, D, "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"]))
	s = _ok(s, _gm("kill", {"target_id": 1, "trigger_effects": false}), "Wolf tot")
	apply_rejected(s, Command.amalia_sacrifice(4, true), "too_few_wolves", "zwei Wölfe reichen nicht")


# --- Detektiv -------------------------------------------------------------------------------------

func test_detective_hint_points_from_dead_wolf_seat() -> void:
	# Sitze = IDs 1..8 im Uhrzeigersinn. Wolf 1 stirbt; Wölfe 5 (Abstand 4 links) und 8 (Abstand 1 rechts).
	var s := _next_day(_state([W, D, DE, "amalia", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor", "rudelvater"]))
	var r := _lynch(s, 2, 1)
	if r == null:
		return
	var hint := events_of_type(r.events, "DetectiveHint")
	assert_true(hint.size() == 1 and hint[0].visibility == Visibility.PUBLIC, "ein öffentlicher Hinweis")
	if hint.size() == 1:
		assert_eq(int(hint[0].data["anchor_id"]), 1, "Anker: Platz des Toten")
		assert_eq(String(hint[0].data["direction"]), "right", "nächster Wolf rechts")
	# Tie: gleich weit.
	var t := _next_day(_state([D, W, DE, "amalia", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "blutwolf", "nachtwaechter", "rudelvater"]))
	# Wolf 10 stirbt: Wolf 2 (cw Abstand 2), Wolf 8 (ccw Abstand 2) → gleich weit.
	r = _lynch(t, 1, 10)
	hint = events_of_type(r.events, "DetectiveHint") if r != null else []
	assert_true(hint.size() == 1 and String(hint[0].data["direction"]) == "equal", "beide Seiten gleich weit")


func test_detective_conditions() -> void:
	# Ohne lebenden Detektiv kein Hinweis.
	var s := _next_day(_state([W, D, DE, "amalia", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"]))
	s = _ok(s, _gm("kill", {"target_id": 3, "trigger_effects": false}), "Detektiv tot")
	var r := _lynch(s, 2, 1)
	assert_eq(events_of_type(r.events, "DetectiveHint").size() if r != null else -1, 0, "Detektiv muss leben")
	# Letzter Wolf: kein anderer Wolf, kein Hinweis.
	s = _next_day(_state([W, D, DE, "amalia", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"]))
	r = _lynch(s, 2, 1)
	assert_eq(events_of_type(r.events, "DetectiveHint").size() if r != null else -1, 0, "ohne anderen Wolf kein Hinweis")
	# Zwei Detektive: ein Hinweis; Korrektur-Tod ohne Folgen: kein Hinweis.
	s = _next_day(_state([W, DE, DE, D, "blutwolf", "amalia", "wahnsinniger-kutscher", "waechter-am-tor"]))
	var quiet := apply_ok(s, _gm("kill", {"target_id": 5, "trigger_effects": false}), "ohne Folgen")
	assert_eq(events_of_type(quiet.events, "DetectiveHint").size(), 0, "ohne Todesfolgen kein Hinweis")
	r = _lynch(s, 4, 1)
	assert_eq(events_of_type(r.events, "DetectiveHint").size() if r != null else -1, 1, "ein Hinweis trotz zwei Detektiven")


func test_detective_night_death_is_announced_at_dawn() -> void:
	var s := _state([W, D, DE, "amalia", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"])
	s = _ok(s, Command.start_night(), "Nacht")
	var r := apply_ok(s, _gm("kill", {"target_id": 1, "trigger_effects": true}), "Wolf stirbt nachts")
	assert_eq(events_of_type(r.events, "DetectiveHint").size(), 0, "nachts noch nicht öffentlich")
	assert_eq(r.state.detective_hints.size(), 1, "vorgemerkt")
	_codec_same(r.state, "vorgemerkter Hinweis")
	s = _finish_night_before_end(r.state)
	r = apply_ok(s, Command.end_night(), "Morgen")
	var hint := events_of_type(r.events, "DetectiveHint")
	assert_true(hint.size() == 1 and int(hint[0].data["anchor_id"]) == 1, "am Morgen verkündet")
	assert_true(r.state.detective_hints.is_empty(), "Vormerkung geleert")


func test_detective_counts_wolf_child_transformed_by_same_death() -> void:
	# Wolf 1 ist Vorbild von Wolfskind 2 (rechts daneben, Abstand 1); der andere Wolf 5 sitzt links weiter weg.
	var s := _state([W, "wolfskind", DE, D, "amalia", "blutwolf", "wahnsinniger-kutscher", "der-weise"])
	s = _ok(s, _gm("set_wolf_model", {"child_id": 2, "target_id": 1}), "Vorbild")
	s = _next_day(s)
	var r := _lynch(s, 4, 1)
	if r == null:
		return
	assert_true(r.state.players[2].counts_as_wolf, "Wolfskind verwandelt")
	var hint := events_of_type(r.events, "DetectiveHint")
	assert_true(hint.size() == 1 and String(hint[0].data["direction"]) == "left", "zeigt auf das verwandelte Wolfskind (I-14)")


# --- Die Ewigen -----------------------------------------------------------------------------------

func test_eternal_shared_check_yes_no() -> void:
	var s := _to_step(_state([W, EW, EW, "manipulator", D, "amalia"]), EW)
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(p.actor_id, -1, "gemeinsamer Schritt")
	assert_eq(p.allowed_ids, [1, 4, 5, 6] as Array[int], "andere Lebende ohne Ewige")
	s = _ok(s, Command.answer_stage_targets(p.id, "targets", [4]), "prüft 4")
	_codec_same(s, "Ergebnis offen")
	var r := apply_ok(s, Command.answer_choice(p.id, "shown", true), "Gezeigt")
	var shown := events_of_type(r.events, "EternalRevealed")
	assert_eq(shown.size(), 2, "jede lebende Ewige")
	for e: GameEvent in shown:
		assert_true(e.visibility == Visibility.ACTOR and bool(e.data["solo"]) and int(e.data["target_id"]) == 4, "Ja an %d" % e.actor_id)
		assert_false(e.data.has("role_id"), "kein Rollenname")
	assert_eq(r.state.eternal_finds, [4] as Array[int], "gefundene Person")
	s = _next_day(_finish_night(r.state))
	s = _ok(_ok(s, Command.decide_execution(-1), "keine"), Command.end_day(), "Ende")
	s = _to_step(s, EW)
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [5]), "prüft 5")
	r = apply_ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Gezeigt")
	assert_false(bool(events_of_type(r.events, "EternalRevealed")[0].data["solo"]), "Nein")
	assert_eq(r.state.eternal_finds, [4] as Array[int], "Nein wird nicht gespeichert")


func test_eternal_co_win_with_found_person_only() -> void:
	var s := _to_step(_state([W, EW, EW, "manipulator", D, "amalia", "detektiv"]), EW)
	s = _ok(s, Command.answer_stage_targets(s.pending_prompt.id, "targets", [4]), "prüft Manipulator")
	s = _finish_night(_ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Ja"))
	# Drei Lebende (1, 2, 4): Manipulator gewinnt; Ewige 2 (lebend) und 3 (tot) gewinnen mit.
	for id: int in [3, 5, 6, 7]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": false}), "tot %d" % id)
	if s == null:
		return
	var manip: WinCandidate = null
	for c: WinCandidate in s.open_candidates():
		if c.reason_key == WinCandidate.REASON_MANIPULATOR:
			manip = c
	assert_true(manip != null, "Manipulatorsieg erkannt")
	if manip != null:
		assert_eq(manip.beneficiary_ids, [4, 2, 3] as Array[int], "Mitsieg aller Ewigen, lebend oder tot")
	_codec_same(s, "Kandidat mit Mitsiegern")
	# I-15: ein anderer Manipulator (nicht geprüft) gewinnt ohne Ewige.
	var t := _state([W, EW, EW, "manipulator", "manipulator", D, "amalia"])
	for id: int in [4, 6, 7, 3]:
		t = _ok(t, _gm("kill", {"target_id": id, "trigger_effects": false}), "tot %d" % id)
	if t == null:
		return
	for c: WinCandidate in t.open_candidates():
		if c.reason_key == WinCandidate.REASON_MANIPULATOR:
			assert_eq(c.beneficiary_ids, [5] as Array[int], "ohne Ja kein Mitsieg")


func test_shadow_hound_blocks_shared_village_steps() -> void:
	# Regression (RM-DR-010, DA-106): der Schattenhund (0,7) blockiert auch gemeinsame Dorfschritte nach ihm (Ewige 4,8),
	# nicht aber die Gebundenen (0,5), die vor ihm dran sind.
	var s := _state(["schattenhund", "die-gebundenen", "die-gebundenen", EW, EW, D, "amalia"])
	s = _ok(s, Command.start_night(), "Nacht 1")
	if s == null:
		return
	var events: Array[GameEvent] = []
	for guard: int in 12:
		if s == null or (s.pending_prompt == null and RulesEngine.next_step_id(s) == ""):
			break
		var c: Command
		if s.pending_prompt == null:
			c = Command.begin_step(RulesEngine.next_step_id(s))
		elif s.pending_prompt.owner == &"schattenhund":
			c = Command.answer_choice(s.pending_prompt.id, "use", true)
		elif s.pending_prompt.stage != &"":
			c = Command.answer_choice(s.pending_prompt.id, String(s.pending_prompt.stage), true)
		else:
			c = Command.answer_prompt(s.pending_prompt.id, Fixtures.pass_targets(s, s.pending_prompt))
		var cr := apply_ok(s, c, "weiter")
		events.append_array(cr.events)
		s = cr.state
	assert_eq(_dropped_reason(events, "die-gebundenen"), "", "Gebundene vor der Blockade nicht betroffen")
	assert_eq(_dropped_reason(events, EW), "blocked", "Ewige blockiert")
	assert_eq(events_of_type(events, "NightBlocked").size(), 1, "Schattenhund hat blockiert")


# --- Zufallsknopf (RM-DR-015.2, Matrix R-06) --------------------------------------------------------
# Die Spielleitung kann wählen oder ziehen lassen. Der Vorschlag entsteht aus einer Kopie des gespeicherten
# Generators; erst die Bestätigung (Antwort mit `random: true`) übernimmt Ergebnis und Generatorfortschritt.
# Erwartungen aus den Regeln: Ergebnis im zulässigen Raum, genau eine Ziehung, gleiche Eingabe gleicher Vorschlag.

## Offene Auswahl je Rolle: {owner: [Zustand, Stufe]}.
func _random_prompts() -> Dictionary:
	var out := {}
	out[TD] = [_to_step(_state([W, "blutwolf", TD, D, "amalia", "detektiv"]), "%s:3" % TD), "targets"]
	var k := _state([W, "blutwolf", "rudelvater", KG, D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	k = _ok(k, Command.start_night(), "Nacht 1")
	k = _finish_night(k)
	var lynch := _lynch(k, 5, 1)
	out[KG] = [_to_step(_ok(lynch.state, Command.end_day(), "Ende"), "%s:4" % KG) if lynch != null else null, "targets"]
	var ko := _state([W, KO, "dorfwache", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise", "nachtwaechter"])
	for id: int in [4, 5, 6, 7, 8, 9]:
		ko = _ok(ko, _gm("kill", {"target_id": id, "trigger_effects": false}), "tot %d" % id)
	out[KO] = [_to_step(ko, "%s:2" % KO), "targets"]
	var bp := _ok(_state([W, "blutwolf", BP, "schutzengel", D, "amalia", "detektiv"]), Command.start_night(), "Nacht")
	bp = _ok(bp, Command.answer_prompt(bp.pending_prompt.id, [5]), "Schutzengel") if bp != null else null
	bp = _to_step(bp, "%s:3" % BP)
	bp = _ok(bp, Command.answer_stage_targets(bp.pending_prompt.id, "targets", [5]), "Opfer 5") if bp != null else null
	out[BP] = [bp, "reveal"]
	return out


## Zulässiger Ergebnisraum nach den Regeln, unabhängig von der Produktionsfunktion.
func _admissible(role: String, s: GameState, targets: Array) -> bool:
	var actor := s.pending_prompt.actor_id
	var distinct := targets.all(func(t: Variant) -> bool: return targets.count(t) == 1)
	var others_alive := targets.all(func(t: Variant) -> bool: return int(t) != actor and s.players.has(int(t)) and s.players[int(t)].alive)
	match role:
		TD, KG:
			return targets.size() == 3 and distinct and others_alive and targets.any(func(t: Variant) -> bool: return s.players[int(t)].counts_as_wolf)
		KO:
			return targets.size() == 1 and others_alive and s.players[int(targets[0])].faction == Faction.VILLAGE
		BP:
			return targets.size() <= 3 and distinct and others_alive and targets.all(func(t: Variant) -> bool: return s.players[int(t)].counts_as_wolf)
	return false


func test_random_choice_proposes_an_admissible_result_and_confirms_with_one_draw() -> void:
	var prompts := _random_prompts()
	for role: String in prompts:
		var s: GameState = prompts[role][0]
		var stage: String = prompts[role][1]
		if s == null:
			fail("%s: Auswahl nicht erreicht" % role)
			continue
		var before := CanonicalJson.stringify(s.to_dict())
		var proposal := InfoSteps.random_choice(s)
		assert_false(proposal.is_empty(), "%s: Vorschlag vorhanden" % role)
		if proposal.is_empty():
			continue
		var targets: Array = proposal["targets"]
		assert_true(_admissible(role, s, targets), "%s: Vorschlag %s im zulässigen Raum" % [role, targets])
		assert_eq(InfoSteps.random_choice(s)["targets"], targets, "%s: gleicher Zustand, gleicher Vorschlag" % role)
		assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: Vorschlag ändert den Zustand nicht" % role)
		var p := s.pending_prompt
		var manual_targets: Array = [p.allowed_ids[0]] if role == KO else ([p.allowed_ids[0]] if role == BP else [])
		if role in [TD, KG]:
			for id: int in p.allowed_ids:
				if s.players[id].counts_as_wolf:
					manual_targets = [id]
					break
			for id: int in p.allowed_ids:
				if manual_targets.size() < 3 and not manual_targets.has(id):
					manual_targets.append(id)
		var manual := apply_ok(s, Command.answer_stage_targets(p.id, stage, manual_targets), "%s: manuelle Wahl" % role)
		assert_eq(manual.state.rng.draws, s.rng.draws, "%s: manuelle Wahl verbraucht keine Ziehung" % role)
		var random := apply_ok(s, Command.answer_random(p.id, stage, targets), "%s: Zufall bestätigt" % role)
		assert_eq(random.state.rng.draws, s.rng.draws + 1, "%s: genau eine Ziehung übernommen" % role)
		assert_eq(random.state.rng.to_dict(), proposal["rng_after"], "%s: Generatorfortschritt wie im Vorschlag" % role)
		assert_eq(random.state.pending_prompt.stage, &"shown", "%s: weiter zur Anzeige" % role)
		assert_eq(CanonicalJson.stringify(s.to_dict()), before, "%s: Ausgangszustand unverändert (Kopie)" % role)
		# Manipuliert: anderes, sonst zulässiges Ergebnis mit Zufallskennzeichen.
		if manual_targets != targets:
			apply_rejected(s, Command.answer_random(p.id, stage, manual_targets), "random_mismatch", "%s: manipulierte Bestätigung" % role)
		# Veraltet: Generator inzwischen fortgeschritten (anderer gespeicherter Stand).
		var stale := GameState.from_dict(s.to_dict())
		stale.rng.next_int(0, 1000)
		var fresh := InfoSteps.random_choice(stale)
		if fresh["targets"] != targets:
			apply_rejected(stale, Command.answer_random(p.id, stage, targets), "random_mismatch", "%s: veraltete Bestätigung" % role)
		# Replay und Laden nach der Bestätigung.
		var loaded := GameState.from_dict(random.state.to_dict())
		assert_true(loaded != null and CanonicalJson.stringify(loaded.to_dict()) == CanonicalJson.stringify(random.state.to_dict()), "%s: Laden identisch" % role)


func test_random_choice_is_uniform_over_the_admissible_results() -> void:
	# Traumdeuter mit fünf anderen Lebenden, davon ein Wolf: genau sechs zulässige Dreiergruppen (Wolf plus zwei von vier).
	var s := _to_step(_state([W, TD, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:2" % TD)
	# Blutpriester mit zwei lebenden Wölfen: vier zulässige Ergebnisse (keiner, einer von zwei, beide).
	var b := _to_step(_state([W, "blutwolf", BP, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:3" % BP)
	b = _ok(b, Command.answer_stage_targets(b.pending_prompt.id, "targets", [5]), "Opfer") if b != null else null
	for entry: Array in [[s, 6, "Traumdeuter"], [b, 4, "Blutpriester"]]:
		var base: GameState = entry[0]
		if base == null:
			fail("%s: Auswahl nicht erreicht" % entry[2])
			continue
		var counts := {}
		for seed_value: int in 600:
			var probe := GameState.from_dict(base.to_dict())
			probe.rng = SeededRng.new(seed_value + 1)
			var t: Array = InfoSteps.random_choice(probe)["targets"]
			counts[str(t)] = int(counts.get(str(t), 0)) + 1
		assert_eq(counts.size(), int(entry[1]), "%s: jedes zulässige Ergebnis kommt vor %s" % [entry[2], counts])
		var expected := 600.0 / float(entry[1])
		for k: String in counts:
			assert_true(absf(float(counts[k]) - expected) < expected * 0.35, "%s: %s etwa gleich häufig (%d)" % [entry[2], k, counts[k]])


func test_random_choice_is_unavailable_without_admissible_result_and_for_other_roles() -> void:
	# Das Opfer wählt der Blutpriester selbst (I-13): kein Zufallsknopf in dieser Stufe.
	var b := _to_step(_state([W, BP, D, "amalia", "detektiv", "wahnsinniger-kutscher"]), "%s:2" % BP)
	if b != null:
		assert_true(InfoSteps.random_choice(b).is_empty(), "Opferwahl des Blutpriesters: kein Zufall")
		apply_rejected(b, Command.answer_random(b.pending_prompt.id, "targets", [3]), "random_not_supported", "Opferwahl nicht per Zufall")
		# Aufdeckung mit einem lebenden Wolf: zulässig sind „keiner“ oder dieser Wolf.
		b = _ok(b, Command.answer_stage_targets(b.pending_prompt.id, "targets", [3]), "Opfer 3")
		assert_true(InfoSteps.random_choice(b)["targets"] in [[], [1]], "nur „keiner“ oder Wolf 1")
	# Ohne zulässiges Ergebnis (keine Dreiergruppe mit Wolf in der Auswahl) kein Vorschlag, keine ungültige Wahl.
	var t := _to_step(_state([W, "blutwolf", TD, D, "amalia", "detektiv"]), "%s:3" % TD)
	if t != null:
		var probe := GameState.from_dict(t.to_dict())
		probe.pending_prompt.allowed_ids = [4, 5, 6] as Array[int]
		assert_true(InfoSteps.random_choice(probe).is_empty(), "keine Dreiergruppe mit Wolf: kein Vorschlag")
	var s := _state([W, "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	s = _ok(s, Command.start_night(), "Nacht")
	assert_true(InfoSteps.random_choice(s).is_empty(), "Schutzengel: kein Zufallsknopf")
	apply_rejected(s, Command.answer_random(s.pending_prompt.id, "", [3]), "random_not_supported", "Zufall bei anderer Rolle abgelehnt")
