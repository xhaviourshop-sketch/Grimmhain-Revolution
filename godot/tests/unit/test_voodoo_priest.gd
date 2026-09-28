extends TestCase
## DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 3“ (28.09.2026), Voodoo-Priester:
##   RM-DR-132.1 (E-12) jeder tatsächliche Tod außer Spielleiterkorrektur trifft nach allen Schutzwirkungen die lebende Puppe
##   RM-DR-132.2 (E-13) keine Abklingzeit; höchstens eine lebende Puppe je Priester, Neuvergabe in der nächsten Nacht
##   RM-DR-132.4 (E-15) Sieg allein, wenn er lebt und höchstens drei Personen leben
##   RM-DR-132.5 (E-14) Puppe ist eine andere lebende Person, geheim
##   RM-DR-132.6 (E-20) Umlenkungsketten: jede Person höchstens einmal, jede Umlenkung verbraucht ihre Verknüpfung
##   RM-DR-132.7 (E-21) Vergabe freiwillig
##   RM-DR-132.8 (E-22) Rollenverlust beendet die Puppe
##   RM-DR-132.9 (E-23) eigene Puppe vor fremder Verknüpfung (Schattenwanderer)

const VP := "voodoo-priester"
const D := "dorfbewohner"
const W := "werwolf"
const SE := "schutzengel"
const SW := "schattenwanderer"
const FT := "feuerteufel"


func _state(roles: Array) -> GameState:
	var r := RulesEngine.replay([Fixtures.start_roles(roles, 1)] as Array[Command])
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
	return Command.answer_prompt(p.id, p.allowed_ids.slice(0, p.min_count))


## Nacht mit Antworten {"<rolle>:<id>@<stufe>" bzw. "pack@": Ziele}; Rudel ohne Antwort ohne Opfer. Endet vor EndNight.
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
			if answers.has(staged):
				cmd = Command.answer_prompt(p.id, answers[staged]) if p.stage == &"" else Command.answer_stage_targets(p.id, String(p.stage), answers[staged])
			elif p.owner == PendingPrompt.OWNER_PACK:
				cmd = Command.answer_prompt(p.id, [])
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


func _dawn(s: GameState, answers: Dictionary = {}, log: Array[GameEvent] = []) -> GameState:
	s = _night(s, answers, log)
	if s == null:
		return null
	var r := apply_ok(s, Command.end_night(), "Morgen")
	log.append_array(r.events)
	return r.state


func _codec_same(s: GameState, label: String) -> void:
	if s == null:
		return
	var loaded := GameState.from_dict(s.to_dict())
	assert_true(loaded != null, "%s: lädt" % label)
	if loaded != null:
		assert_eq(CanonicalJson.stringify(loaded.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: identisch nach Laden" % label)


## [Ziel, Ursache] aller Tode in Reihenfolge.
func _deaths(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events_of_type(events, "SeatDied"):
		out.append([int(e.data["target_id"]), String(e.data["cause"])])
	return out


func _voodoo_redirects(events: Array[GameEvent]) -> Array:
	var out: Array = []
	for e: GameEvent in events_of_type(events, "KillPrevented"):
		if String(e.data.get("protection", "")) == VP:
			out.append([int(e.data["target_id"]), int(e.data["redirected_to"])])
	return out


func _dolls(s: GameState) -> Array:
	return s.voodoo_dolls if s != null else []


## Priester `priest` gibt in Nacht 1 `doll` die Puppe; kein Rudelopfer.
func _with_doll(roles: Array, priest: int, doll: int) -> GameState:
	return _dawn(_state(roles), {"%s:%d@" % [VP, priest]: [doll]})


# --- Katalog, Vergabe ---------------------------------------------------------------------------

func test_catalog_entry() -> void:
	assert_true(RoleCatalog.has_role(&"voodoo-priester"), "im Katalog")
	if not RoleCatalog.has_role(&"voodoo-priester"):
		return
	assert_eq(RoleCatalog.faction_of(&"voodoo-priester"), Faction.SOLO, "Einzelsieg")
	assert_false(RoleCatalog.counts_as_wolf(&"voodoo-priester"), "kein Wolf")
	assert_eq(RoleCatalog.night_priority(&"voodoo-priester"), 84, "Legacy-Stufe 8.4")
	assert_false(RoleCatalog.APPLE_ROLES.has(&"voodoo-priester"), "nur ein Ergebnis, kein Apfel (R-04)")


func test_giving_is_voluntary_secret_and_only_without_living_doll() -> void:
	var s := _state([W, VP, D, D, D, D, D])
	s = _ok(s, Command.start_night(), "Nacht")
	s = _ok(s, Command.answer_prompt(s.pending_prompt.id, []), "Rudel") if s != null else null
	s = _ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Priester") if s != null else null
	if s == null:
		return
	var p := s.pending_prompt
	assert_eq(String(p.owner), VP, "eigener Prompt")
	assert_eq(p.allowed_ids, [1, 3, 4, 5, 6, 7] as Array[int], "andere Lebende")
	assert_eq([p.min_count, p.max_count], [0, 1], "freiwillig, eine Puppe (E-21)")
	var rejected := RulesEngine.apply(s, Command.answer_prompt(p.id, [2]))
	assert_false(rejected.ok, "nie er selbst (E-14)")
	assert_true(rejected.events.is_empty(), "Ablehnung ohne Ereignisse")
	apply_rejected(s, Command.answer_prompt(p.id, [2]), "invalid_target", "Selbstwahl")
	_codec_same(s, "offener Prompt")
	var r := apply_ok(s, Command.answer_prompt(p.id, [5]), "Puppe 5")
	for e: GameEvent in r.events:
		assert_true(e.visibility == Visibility.GM, "geheim, auch nicht für die Puppe: %s" % e.type)
	s = _ok(r.state, Command.end_night(), "Morgen")
	assert_eq(_dolls(s), [{"priest_id": 2, "doll_id": 5}], "eine Puppe")
	s = _night(s)
	assert_false(s != null and s.night_plan.has(&"voodoo-priester:2"), "kein Schritt mit lebender Puppe")
	# Verzicht: in der nächsten Nacht wieder gefragt.
	var t := _dawn(_state([W, VP, D, D, D, D, D]), {"voodoo-priester:2@": []})
	assert_eq(_dolls(t), [], "Verzicht")
	t = _night(t)
	assert_true(t != null and t.night_plan.has(&"voodoo-priester:2"), "erneut gefragt")


# --- Umlenkung ----------------------------------------------------------------------------------

func test_pack_attack_goes_to_doll_with_original_cause_and_source() -> void:
	var s := _with_doll([W, VP, D, D, D, D, D], 2, 5)
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"]], "Puppe stirbt statt des Priesters")
	assert_eq(_voodoo_redirects(log), [[2, 5]], "Umlenkung protokolliert")
	var prevented := log.find(events_of_type(log, "KillPrevented")[0]) if not events_of_type(log, "KillPrevented").is_empty() else -1
	var died := log.find(events_of_type(log, "SeatDied")[0]) if not events_of_type(log, "SeatDied").is_empty() else -1
	assert_true(prevented != -1 and prevented < died, "Umlenkung vor dem Tod der Puppe")
	assert_eq(String(s.players[5].death.source_kind), "pack", "Quelle bleibt das Rudel")
	assert_true(s.players[2].alive, "Priester lebt")
	assert_eq(_dolls(s), [], "Puppe verbraucht")
	for e: GameEvent in log:
		if e.visibility == Visibility.PUBLIC:
			assert_false(e.data.has("cause") or e.data.has("protection"), "öffentlich ohne Ursache: %s" % e.type)
	# Keine Abklingzeit: in der nächsten Nacht wieder Vergabe.
	s = _night(s)
	assert_true(s != null and s.night_plan.has(&"voodoo-priester:2"), "Neuvergabe in der nächsten Nacht (E-13)")


func test_lynch_and_burn_redirect_but_gm_correction_does_not() -> void:
	# Hinrichtung.
	var s := _with_doll([W, VP, D, D, D, D, D], 2, 5)
	s = _ok(s, Command.nominate(3, 2), "Nominierung")
	var r := apply_ok(s, Command.decide_execution(2), "Hinrichtung des Priesters") if s != null else null
	assert_eq(_deaths(r.events) if r != null else [], [[5, "LYNCH"]], "Puppe stirbt durch die Hinrichtung")
	# Spielleiterkorrektur mit Folgen: keine Umlenkung.
	s = _with_doll([W, VP, D, D, D, D, D], 2, 5)
	r = apply_ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Korrektur") if s != null else null
	if r != null:
		assert_eq(_deaths(r.events), [[2, "GM_CORRECTION"]], "Priester stirbt selbst")
		assert_true(r.state.players[5].alive, "Puppe lebt")
		assert_eq(_dolls(r.state), [], "Puppe endet mit dem Priester")
	# Brand (Voodoo × Feuerteufel): Feuerteufel 4 markiert 3; 3 stirbt; Nachbar 2 (Priester) verbrennt → Puppe 6.
	s = _dawn(_state([W, VP, D, FT, D, D, D]), {"voodoo-priester:2@": [6], "feuerteufel:4@": [3]})
	r = apply_ok(s, _gm("kill", {"target_id": 3, "trigger_effects": true}), "Ziel des Feuerteufels stirbt") if s != null else null
	if r == null:
		return
	assert_eq(_deaths(r.events), [[3, "GM_CORRECTION"], [6, "BURN"]], "Brand am Priester trifft die Puppe")
	assert_eq(r.state.players[6].death.source_id, 4, "Quelle bleibt der Feuerteufel")


func test_protection_acts_before_redirect_and_doll_keeps_own_protection() -> void:
	# Schutzengel 3 schützt den Priester: keine Umlenkung, Puppe bleibt.
	var s := _with_doll([W, VP, SE, D, D, D, D], 2, 5)
	var log: Array[GameEvent] = []
	s = _dawn(s, {"schutzengel:3@": [2], "pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [], "niemand stirbt")
	assert_eq(_voodoo_redirects(log), [], "keine Umlenkung bei Schutz")
	assert_eq(_dolls(s), [{"priest_id": 2, "doll_id": 5}], "Puppe bleibt")
	# Schutzengel 3 schützt die Puppe: umgelenkter Rudelangriff wird abgewehrt, Verknüpfung verbraucht (E-20).
	s = _with_doll([W, VP, SE, D, D, D, D], 2, 5)
	log = []
	s = _dawn(s, {"schutzengel:3@": [5], "pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [], "Puppe durch eigenen Schutz gerettet")
	assert_eq(_voodoo_redirects(log), [[2, 5]], "Umlenkung ausgeführt")
	assert_eq(_dolls(s), [], "Verknüpfung verbraucht")


func test_dead_doll_and_new_doll_without_cooldown() -> void:
	var s := _with_doll([W, VP, D, D, D, D, D], 2, 5)
	s = _ok(s, _gm("kill", {"target_id": 5, "trigger_effects": true}), "Puppe stirbt")
	assert_eq(_dolls(s), [], "tote Puppe schützt nicht")
	s = _dawn(s, {"voodoo-priester:2@": [6]})
	assert_eq(_dolls(s), [{"priest_id": 2, "doll_id": 6}], "neue Puppe in der nächsten Nacht")
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2]}, log)
	assert_eq(_deaths(log), [[6, "NIGHT_KILL"]], "neue Puppe wirkt")


# --- Ketten und Schleifen (E-20, E-23) -------------------------------------------------------------

func test_mutual_dolls_and_chains_each_person_at_most_once() -> void:
	# Gegenseitig: 2 hat 3, 3 hat 2 als Puppe; 2 wird angegriffen → 3 stirbt.
	var s := _dawn(_state([W, VP, VP, D, D, D, D]), {"voodoo-priester:2@": [3], "voodoo-priester:3@": [2]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[3, "NIGHT_KILL"]], "Ben stirbt, nicht zurück zu Anna")
	assert_eq(_voodoo_redirects(log), [[2, 3]], "genau eine Umlenkung")
	assert_eq(_dolls(s), [], "beide Verknüpfungen beendet")
	# Kette: 2 hat 3, 3 hat 4 → 2 angegriffen → 4 stirbt.
	s = _dawn(_state([W, VP, VP, D, D, D, D]), {"voodoo-priester:2@": [3], "voodoo-priester:3@": [4]})
	log = []
	s = _dawn(s, {"pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[4, "NIGHT_KILL"]], "Kette endet bei Clara")
	assert_eq(_voodoo_redirects(log), [[2, 3], [3, 4]], "zwei Umlenkungen in Reihenfolge")
	assert_true(s.players[2].alive and s.players[3].alive, "beide Priester leben")
	# Zwei Priester, dieselbe Puppe: 2 angegriffen → 5 stirbt; 3 verliert seine Puppe.
	s = _dawn(_state([W, VP, VP, D, D, D, D]), {"voodoo-priester:2@": [5], "voodoo-priester:3@": [5]})
	log = []
	s = _dawn(s, {"pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"]], "gemeinsame Puppe stirbt einmal")
	assert_eq(_dolls(s), [], "auch die Puppe des zweiten Priesters endet")
	_codec_same(s, "nach Kette")


func test_own_doll_before_shadow_link_and_no_way_back() -> void:
	# E-23: Schattenwanderer 3 verknüpft sich mit Priester 2; Priester 2 hat 5 als Puppe; 2 angegriffen → 5 stirbt.
	var s := _dawn(_state([W, VP, SW, D, D, D, D]), {"schattenwanderer:3@": [2], "voodoo-priester:2@": [5]})
	var log: Array[GameEvent] = []
	s = _dawn(s, {"pack@": [2]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[5, "NIGHT_KILL"]], "eigene Puppe zuerst")
	assert_eq(s.shadow_links.size(), 1, "Verknüpfung des Schattenwanderers bleibt")
	# E-20: Priester 2 hat den Schattenwanderer 3 als Puppe, 3 ist mit 2 verknüpft; das Rudel greift 3 an:
	# Verknüpfung → 2; 2s Puppe ist 3 (schon betroffen) → keine Umlenkung zurück → 2 stirbt.
	s = _dawn(_state([W, VP, SW, D, D, D, D]), {"schattenwanderer:3@": [2], "voodoo-priester:2@": [3]})
	log = []
	s = _dawn(s, {"pack@": [3]}, log)
	if s == null:
		return
	assert_eq(_deaths(log), [[2, "NIGHT_KILL"]], "Priester stirbt, nicht zurück zum Schattenwanderer")
	assert_true(s.players[3].alive, "Schattenwanderer lebt")
	assert_eq(s.shadow_links.size(), 0, "Verknüpfung verbraucht")
	assert_eq(_dolls(s), [], "Puppe endet mit dem Priester")


# --- Rollenverlust, Sieg, Laden ---------------------------------------------------------------------

func test_role_loss_ends_doll() -> void:
	var s := _with_doll([W, VP, D, D, D, D, D], 2, 5)
	s = _ok(s, _gm("set_role", {"target_id": 2, "role_id": D}), "Rolle weg")
	assert_eq(_dolls(s), [], "Puppe endet (E-22)")
	# Seelentausch in Nacht 2: Priester 2 tauscht mit 4; 4 wird Priester ohne Puppe.
	s = _with_doll([W, VP, "seelentauscher", D, D, D, D], 2, 5)
	s = _dawn(s, {"seelentauscher:3@targets": [2, 4]})
	if s == null:
		return
	assert_eq(String(s.players[4].role_id), VP, "4 ist Priester")
	assert_eq(_dolls(s), [], "alte Puppe endet, neuer Priester ohne Puppe")
	s = _night(s)
	assert_true(s != null and s.night_plan.has(&"voodoo-priester:4"), "neuer Priester vergibt")


func test_wins_alone_with_at_most_three_living() -> void:
	var s := _state([W, VP, D, D, D, D])
	for id: int in [4, 5, 6]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Tod %d" % id)
	if s == null:
		return
	var solo := s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_VOODOO)
	assert_eq(solo.size(), 1, "Voodoo-Sieg bei drei Lebenden")
	if solo.size() == 1:
		assert_eq((solo[0] as WinCandidate).beneficiary_ids, [2] as Array[int], "Priester allein")
	_codec_same(s, "Kandidat")
	# Toter Priester gewinnt nicht; lebender Feuerteufel gewinnt mit.
	s = _state([W, VP, FT, D, D, D])
	for id: int in [4, 5, 6]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Tod %d" % id)
	if s == null:
		return
	solo = s.open_candidates().filter(func(c: WinCandidate) -> bool: return c.reason_key == WinCandidate.REASON_VOODOO)
	assert_true(solo.size() == 1 and (solo[0] as WinCandidate).co_winner_ids == ([3] as Array[int]), "Feuerteufel als Mitsieger")
	s = _state([W, VP, D, D, D, D])
	s = _ok(s, _gm("kill", {"target_id": 2, "trigger_effects": true}), "Priester tot")
	for id: int in [5, 6]:
		s = _ok(s, _gm("kill", {"target_id": id, "trigger_effects": true}), "Tod %d" % id)
	if s == null:
		return
	assert_true(s.open_candidates().all(func(c: WinCandidate) -> bool: return c.reason_key != WinCandidate.REASON_VOODOO), "nur lebend")


func test_load_rejects_inconsistent_dolls() -> void:
	var s := _with_doll([W, VP, VP, D, D, D, D], 2, 5)
	if s == null:
		return
	s = _ok(s, _gm("kill", {"target_id": 6, "trigger_effects": true}), "6 tot")
	if s == null:
		return
	for bad: Array in [[{"priest_id": 2, "doll_id": 2}], [{"priest_id": 2, "doll_id": 4}, {"priest_id": 2, "doll_id": 5}],
			[{"priest_id": 4, "doll_id": 5}], [{"priest_id": 2, "doll_id": 6}], [{"priest_id": 3, "doll_id": 4}, {"priest_id": 2, "doll_id": 5}]]:
		var d := s.to_dict()
		d["voodoo_dolls"] = bad
		assert_true(GameState.from_dict(d) == null, "abgelehnt: %s" % str(bad))
