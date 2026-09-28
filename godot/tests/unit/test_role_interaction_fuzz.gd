extends TestCase
## Kombinationsprüfung aller Rollen des Regelkerns (Rollenaudit, docs/role-migration/11-role-audit-status.md).
## Deterministisch erzeugte Partien mit 6 bis 24 Personen, gemischten Rollen inklusive
## Mehrfachkopien, zufälligen gültigen Antworten, Abbrüchen, Überspringen, Nominierungen,
## Hinrichtungen, Spielleitertötungen und Wiederbelebungen. Nach jedem angenommenen Befehl
## gelten Invarianten, die unabhängig von der einzelnen Rolle beobachtbar sind:
##   - Zustand übersteht to_dict/from_dict unverändert (inkl. Ladeprüfungen aller Rollen)
##   - öffentliche Ereignisse enthalten keine Rollen-, Ursachen- oder Informationsdaten
##   - persönliche Nachtschritte öffnen nur für lebende Personen mit der geplanten Rolle
##   - niemand stirbt zweimal; Tote tragen einen Todesdatensatz, Lebende keinen
##   - Rollenfelder passen zur Rolle (Wolfskind: zum Verwandlungszustand)
##   - Save/Load (StateCodec) und Replay liefern denselben Zustand und dieselben Ereignisse
## Der Test-Zufall ist lokal und festgelegt; der Regelkern nutzt ausschließlich seinen Seed.

const ROLES: Array[String] = ["dorfbewohner", "werwolf", "schutzengel", "waldhexe", "das-orakel", "trugbilderwolf",
	"wolfskind", "spiegelwolf", "manipulator", "lehrling", "sensentraeger", "siegreicher-wolf", "doppelspion", "selbstmoerder", "dorfchronistin", "die-gebundenen", "waldlaeufer", "doktor", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "ritter", "faehrtenleser", "besessener-wolf", "korrupter-richter", "waechter-am-tor", "blutwolf", "spuerhund", "parasit", "schattenhund", "albtraumwolf", "giftwolf", "rudelvater", "seuchenwolf", "fenrir", "cerberus", "henker",
	"traumdeuter", "kopfgeldjaeger", "koenig", "kriegerin-des-lichts", "blutpriester", "amalia", "detektiv", "die-ewigen",
	"der-weise", "maertyrerin", "schutzgeist", "dorfschmied", "verdammniswaechter", "loki", "rotkaeppchen", "schwarze-witwe", "schattenwanderer"]
const WOLF_ROLES: Array[String] = ["werwolf", "trugbilderwolf", "spiegelwolf", "siegreicher-wolf", "besessener-wolf", "blutwolf", "schattenhund", "albtraumwolf", "giftwolf", "rudelvater", "seuchenwolf", "fenrir", "cerberus", "schwarze-witwe", "schattenwanderer"]
const COUNTS: Array[int] = [6, 7, 8, 10, 12, 16, 24]
const GAMES := 160
const MAX_COMMANDS := 160
const CODEC_EVERY := 20
const FORBIDDEN_PUBLIC_KEYS: Array[String] = ["role_id", "appears_as", "cause", "faction", "shown_role", "truth_role",
	"determined_role", "victim_id", "model_id", "master_id", "options", "protection", "saved_id", "poison_target_id"]

## Ereignisse, die in der Gesamtheit der Partien mindestens einmal vorkommen müssen, damit
## die Wechselwirkungen tatsächlich durchlaufen wurden (Abdeckungsnachweis des Generators).
const REQUIRED_EVENTS: Array[String] = ["KillPrevented", "WitchActed", "InfoRecorded", "InfoOverridden", "WolfChildBound",
	"WolfChildTransformed", "ApprenticeBound", "RoleChanged", "ExecutionRedirected", "MirrorNotTriggered", "ReactionResolved",
	"StepDropped", "PromptCancelled", "KillIgnored", "WinConfirmed", "WinRejected", "GmCorrected", "StepSkipped",
	"DreamRevealed", "BountyRevealed", "KingRevealed", "WarriorRevealed", "BloodRevealed", "EternalRevealed", "DetectiveHint", "AmaliaAnswered",
	"SageCursed", "WeaponGiven", "ShieldGiven", "DoomJudged", "MartyrChosen", "LokiBound", "RedRefuge", "WidowStruck", "ShadowLinked", "AppleUsed"]
const REQUIRED_CAUSES: Array[String] = ["NIGHT_KILL", "WITCH_POISON", "HUNTER_SHOT", "LYNCH", "SPIEGELWOLF_RETALIATE",
	"MANIPULATOR_NOMINATED", "GM_CORRECTION", "WARRIOR_WRONG", "BLOOD_SACRIFICE", "AMALIA_SACRIFICE", "MARTYR_SACRIFICE", "LOVER_HEARTBREAK", "RED_CHAIN"]

var _rng := RandomNumberGenerator.new()
var _game_label := ""
var _seen := {}
var _probe := false  ## letzter Befehl ist eine zufällige Korrektur, Ablehnung erlaubt
var _probe_rejected := 0
var _probe_accepted := 0


func test_random_games_keep_invariants() -> void:
	var games_over := 0
	var total_commands := 0
	var deaths := 0
	for g: int in GAMES:
		_rng.seed = 7919 * (g + 1)
		var count := COUNTS[g % COUNTS.size()]
		var result := _play_game(g, count)
		total_commands += int(result["commands"])
		deaths += int(result["deaths"])
		if bool(result["game_over"]):
			games_over += 1
		if not failures.is_empty():
			return
	# Der Generator muss tatsächlich tief spielen, sonst belegt der Test nichts.
	assert_true(total_commands > GAMES * 30, "genügend Befehle gespielt (%d)" % total_commands)
	assert_true(deaths > GAMES * 2, "genügend Tode erzeugt (%d)" % deaths)
	assert_true(games_over > GAMES / 4, "genügend Partien bis zum bestätigten Sieg (%d)" % games_over)
	for type: String in REQUIRED_EVENTS:
		assert_true(int(_seen.get(type, 0)) > 0, "Ereignis %s kam vor" % type)
	for cause: String in REQUIRED_CAUSES:
		assert_true(int(_seen.get("cause:" + cause, 0)) > 0, "Todesursache %s kam vor" % cause)
	assert_true(_probe_accepted > GAMES, "genügend angenommene Zufallskorrekturen (%d)" % _probe_accepted)
	assert_true(_probe_rejected > 0, "abgelehnte Zufallskorrekturen geprüft (%d)" % _probe_rejected)
	print("      Abdeckung: %s" % CanonicalJson.stringify(_seen))
	print("      Zufallskorrekturen: %d angenommen, %d abgelehnt" % [_probe_accepted, _probe_rejected])


func _play_game(g: int, count: int) -> Dictionary:
	var start := _start_command(g, count)
	var log: Array[Command] = []
	var events: Array[GameEvent] = []
	var state := GameState.new()
	var deaths := 0
	var r := RulesEngine.apply(state, start)
	if not r.ok:
		fail("%s: Start abgelehnt (%s) %s" % [_game_label, r.error, CanonicalJson.stringify(start.to_dict())])
		return {"commands": 0, "deaths": 0, "game_over": false}
	log.append(start)
	events.append_array(r.events)
	state = r.state
	for i: int in MAX_COMMANDS:
		if state.phase == Phase.GAME_OVER:
			break
		var c := _next_command(state)
		if c == null:
			fail("%s @%d: kein Befehl erzeugbar (Phase %s, Schritt %s)" % [_game_label, i, state.phase, RulesEngine.next_step_id(state)])
			break
		var before := state
		var before_json := CanonicalJson.stringify(state.to_dict())
		var res := RulesEngine.apply(state, c)
		if not res.ok and _probe:
			# A-13: abgelehnte Befehle ändern nichts und erzeugen keine Ereignisse.
			_probe_rejected += 1
			assert_eq(CanonicalJson.stringify(state.to_dict()), before_json, "%s @%d: Ablehnung %s lässt Zustand unverändert" % [_game_label, i, res.error])
			assert_true(res.events.is_empty() and String(res.error) != "", "%s @%d: Ablehnung ohne Ereignisse, mit Grund" % [_game_label, i])
			continue
		if _probe:
			_probe_accepted += 1
		if not res.ok:
			fail("%s @%d: gültig erzeugter Befehl abgelehnt: %s → %s (Phase %s, Schritt %s)" % [_game_label, i,
				CanonicalJson.stringify(c.to_dict()), res.error, state.phase, RulesEngine.next_step_id(state)])
			break
		state = res.state
		log.append(c)
		events.append_array(res.events)
		deaths += _check_after(before, state, res.events, "%s @%d %s" % [_game_label, i, c.type])
		if log.size() % CODEC_EVERY == 0:
			_check_codec(state, log, "%s @%d" % [_game_label, i])
		if not failures.is_empty():
			break
	if failures.is_empty():
		_check_codec(state, log, "%s Ende" % _game_label)
		var replay := RulesEngine.replay(log)
		assert_true(replay.ok, "%s: Replay angenommen (%s @ %d)" % [_game_label, replay.error, replay.failed_index])
		if replay.ok:
			assert_eq(CanonicalJson.stringify(replay.state.to_dict()), CanonicalJson.stringify(state.to_dict()), "%s: Replay-Zustand identisch" % _game_label)
			assert_eq(events_json(replay.events), events_json(events), "%s: Replay-Ereignisse identisch" % _game_label)
	return {"commands": log.size(), "deaths": deaths, "game_over": state.phase == Phase.GAME_OVER}


func _start_command(g: int, count: int) -> Command:
	var roles: Array[String] = []
	var wolves := 1 + _rng.randi_range(0, maxi(0, count / 5))
	for i: int in wolves:
		roles.append(WOLF_ROLES[_rng.randi_range(0, WOLF_ROLES.size() - 1)])
	roles.append("dorfbewohner" if _rng.randf() < 0.3 else ["schutzengel", "waldhexe", "das-orakel", "wolfskind", "lehrling", "sensentraeger"][_rng.randi_range(0, 5)])
	while roles.size() < count:
		roles.append(ROLES[_rng.randi_range(0, ROLES.size() - 1)])
	# Mischen im Test (nicht im Kern): Sitz- und ID-Verteilung variieren.
	for i: int in range(roles.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := roles[i]
		roles[i] = roles[j]
		roles[j] = tmp
	var map := {}
	var appearances := {}
	var non_wolf: Array[String] = ["dorfbewohner", "schutzengel", "waldhexe", "das-orakel", "wolfskind", "manipulator", "lehrling", "sensentraeger", "doppelspion", "selbstmoerder", "dorfchronistin", "die-gebundenen", "waldlaeufer", "doktor", "wahnsinniger-kutscher", "nachtwaechter", "dorfwache", "ritter", "faehrtenleser", "korrupter-richter", "waechter-am-tor", "spuerhund", "parasit", "henker"]
	for i: int in count:
		map[str(i + 1)] = roles[i]
		if roles[i] == "trugbilderwolf":
			appearances[str(i + 1)] = non_wolf[_rng.randi_range(0, non_wolf.size() - 1)]
	var order := Fixtures.identity_order(count)
	for i: int in range(order.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	_game_label = "Partie %d (%d Personen: %s)" % [g, count, ",".join(roles)]
	var payload := {
		"round_id": "fuzz-%d" % g, "seed": 1000 + g, "assignment": "manual",
		"players": Fixtures.players(count), "seat_order": order, "roles": map,
	}
	if not appearances.is_empty():
		payload["appearances"] = appearances
	return Command.start_game(payload)


# --- Befehlserzeugung (nur gültige Befehle) ------------------------------------------------------

func _pick(list: Array) -> Variant:
	return list[_rng.randi_range(0, list.size() - 1)]


func _alive_in(s: GameState, ids: Array[int], exclude: int = -1) -> Array[int]:
	var out: Array[int] = []
	for id: int in ids:
		if id != exclude and s.players.has(id) and s.players[id].alive:
			out.append(id)
	return out


func _gm_kill(s: GameState) -> Command:
	var alive := s.alive_ids()
	if alive.is_empty():
		return null
	return CorrectionFixtures.gm("kill", {"target_id": _pick(alive), "trigger_effects": _rng.randf() < 0.7}, "Fuzz")


func _gm_revive(s: GameState) -> Command:
	var dead: Array[int] = []
	for id: int in s.players:
		if not s.players[id].alive:
			dead.append(id)
	if dead.is_empty():
		return null
	dead.sort()
	return CorrectionFixtures.gm("revive", {"target_id": _pick(dead)}, "Fuzz")


func _next_command(s: GameState) -> Command:
	_probe = false
	var open := s.open_candidates()
	if not open.is_empty():
		if _rng.randf() < 0.6:
			return Command.confirm_win((_pick(open) as WinCandidate).id)
		return Command.create(Command.REJECT_WIN, {"reason": "Fuzz: weiterspielen"})
	var roll := _rng.randf()
	# Spielleitereingriffe jederzeit (auch mit offenem Prompt oder offener Reaktion).
	if roll < 0.06:
		_probe = true
		return _random_correction(s)
	roll = _rng.randf()
	if roll < 0.03:
		var kill := _gm_kill(s)
		if kill != null:
			return kill
	elif roll < 0.05:
		var revive := _gm_revive(s)
		if revive != null:
			return revive
	if s.pending_prompt != null:
		return _answer(s, s.pending_prompt)
	match s.phase:
		Phase.SETUP:
			return Command.start_night()
		Phase.NIGHT:
			var step := RulesEngine.next_step_id(s)
			if step == "":
				return Command.end_night()
			if StepQueue.is_skippable(step) and _rng.randf() < 0.15:
				return Command.skip_step(step, "Fuzz: kein Opfer")
			return Command.begin_step(step)
		Phase.DAWN_RESOLUTION, Phase.DAY:
			if StepQueue.reactions_due(s):
				return Command.begin_step(RulesEngine.next_step_id(s))
			return _day_command(s)
	return null


## Beliebige Spielleiterkorrektur mit plausiblen, aber nicht garantiert gültigen Feldern.
func _random_correction(s: GameState) -> Command:
	var ids: Array[int] = []
	for id: int in s.players:
		ids.append(id)
	ids.sort()
	var any: int = _pick(ids)
	var other: int = _pick(ids)
	var holders := func(role: StringName) -> Array[int]:
		var out: Array[int] = []
		for id: int in ids:
			if s.players[id].role_id == role:
				out.append(id)
		return out if not out.is_empty() else ids
	var non_wolf: Array[String] = ["dorfbewohner", "schutzengel", "waldhexe", "das-orakel", "wolfskind", "manipulator", "lehrling", "sensentraeger"]
	match _rng.randi_range(0, 15):
		0:
			var role: String = _pick(ROLES)
			var fields := {"target_id": any, "role_id": role}
			if role == "trugbilderwolf":
				fields["appears_as"] = _pick(non_wolf)
			return CorrectionFixtures.gm("set_role", fields, "Fuzz")
		1:
			return CorrectionFixtures.gm("set_role_field", {"target_id": any, "field": "appears_as", "value": _pick(non_wolf)}, "Fuzz")
		2:
			return CorrectionFixtures.gm("set_protection", {"guardian_id": _pick(holders.call(RoleCatalog.SCHUTZENGEL)), "target_id": other}, "Fuzz")
		3:
			return CorrectionFixtures.gm("remove_protection", {"guardian_id": _pick(holders.call(RoleCatalog.SCHUTZENGEL))}, "Fuzz")
		4:
			return CorrectionFixtures.gm("set_witch_potion", {"witch_id": _pick(holders.call(RoleCatalog.WALDHEXE)), "potion": _pick(["heal", "poison"]), "available": _rng.randf() < 0.5}, "Fuzz")
		5:
			return CorrectionFixtures.gm("set_rescue", {"witch_id": _pick(holders.call(RoleCatalog.WALDHEXE)), "target_id": s.pack_target_id if s.pack_target_id != -1 else other}, "Fuzz")
		6:
			return CorrectionFixtures.gm("remove_rescue", {"witch_id": _pick(holders.call(RoleCatalog.WALDHEXE))}, "Fuzz")
		7:
			return CorrectionFixtures.gm("set_wolf_model", {"child_id": _pick(holders.call(RoleCatalog.WOLFSKIND)), "target_id": other}, "Fuzz")
		8:
			return CorrectionFixtures.gm(_pick(["remove_wolf_model", "transform_wolf_child", "revert_wolf_child"]), {"child_id": _pick(holders.call(RoleCatalog.WOLFSKIND))}, "Fuzz")
		9:
			return CorrectionFixtures.gm("set_apprentice_master", {"apprentice_id": _pick(holders.call(RoleCatalog.LEHRLING)), "target_id": other}, "Fuzz")
		10:
			return CorrectionFixtures.gm(_pick(["remove_apprentice_master", "trigger_apprentice_inheritance", "revert_apprentice_inheritance"]), {"apprentice_id": any if _rng.randf() < 0.3 else _pick(holders.call(RoleCatalog.LEHRLING))}, "Fuzz")
		11:
			return CorrectionFixtures.gm("set_mirror", {"target_id": _pick(holders.call(RoleCatalog.SPIEGELWOLF)), "available": _rng.randf() < 0.5}, "Fuzz")
		12:
			return CorrectionFixtures.gm("set_ever_nominated", {"target_id": any, "value": _rng.randf() < 0.5}, "Fuzz")
		13:
			return CorrectionFixtures.gm("kill", {"target_id": any, "trigger_effects": _rng.randf() < 0.5}, "Fuzz")
		14:
			return CorrectionFixtures.gm("revive", {"target_id": any}, "Fuzz")
	return CorrectionFixtures.gm("execute", {"target_id": any}, "Fuzz")


func _day_command(s: GameState) -> Command:
	if s.day_step == Phase.DAY_ENDED:
		return Command.start_night()
	if s.day_step == Phase.DAY_EXECUTION_DECIDED:
		return Command.end_day()
	var roll := _rng.randf()
	if roll < 0.05:
		for id: int in s.alive_ids():
			if s.players[id].role_id == RoleCatalog.AMALIA:
				_probe = true  # bei zu wenigen Wölfen abgelehnt
				return Command.amalia_sacrifice(id, _rng.randf() < 0.5)
	if roll < 0.45:
		var nomination := _random_nomination(s)
		if nomination != null:
			return nomination
	if roll < 0.5:
		var alive := s.alive_ids()
		if not alive.is_empty():
			var exec_target: int = _pick(alive)
			return CorrectionFixtures.gm("execute", _execution_fields(s, exec_target), "Fuzz: Hinrichtung ohne Nominierung")
	var nominees: Array[int] = []
	for n: Nomination in s.nominations_on_day(s.day_number):
		if s.players[n.nominee_id].alive:
			nominees.append(n.nominee_id)
	if nominees.is_empty() or _rng.randf() < 0.2:
		return Command.decide_execution(-1)
	var chosen: int = _pick(nominees)
	return Command.create(Command.DECIDE_EXECUTION, _execution_fields(s, chosen))


## Pflichtfelder einer Hinrichtung: Cerberus-Abwehr und Fluchdauer des Weisen (0–3).
func _execution_fields(s: GameState, target: int) -> Dictionary:
	var fields := {"target_id": target}
	if ExecutionRules.needs_cerberus_decision(s, target):
		fields["cerberus_defend"] = _rng.randf() < 0.5
	if GuardRoles.needs_sage_decision(s, target):
		fields["sage_curse"] = _rng.randi_range(0, RoleCatalog.SAGE_MAX_CURSE)
	return fields


func _random_nomination(s: GameState) -> Command:
	var nominators: Array[int] = []
	var nominees: Array[int] = []
	var used_nominators := {}
	var used_nominees := {}
	for n: Nomination in s.nominations_on_day(s.day_number):
		used_nominators[n.nominator_id] = true
		used_nominees[n.nominee_id] = true
	for id: int in s.alive_ids():
		if not used_nominators.has(id):
			nominators.append(id)
		if not used_nominees.has(id):
			nominees.append(id)
	if nominators.is_empty() or nominees.is_empty():
		return null
	return Command.nominate(_pick(nominators), _pick(nominees))


func _answer(s: GameState, p: PendingPrompt) -> Command:
	if p.cancellable and _rng.randf() < 0.08:
		return Command.cancel_prompt(p.id, "Fuzz: Abbruch")
	match p.owner:
		PendingPrompt.OWNER_WITCH:
			match p.stage:
				WitchStep.STAGE_HEAL, WitchStep.STAGE_POISON:
					return Command.answer_choice(p.id, String(p.stage), _rng.randf() < 0.5)
				WitchStep.STAGE_POISON_TARGET:
					# Öfter das Rudelopfer: erzeugt „Gift vor Rudel, Angriff auf Tote“ (KillIgnored).
					if s.pack_target_id != -1 and s.players[s.pack_target_id].alive and _rng.randf() < 0.4:
						return Command.answer_stage_targets(p.id, String(p.stage), [s.pack_target_id])
					return Command.answer_stage_targets(p.id, String(p.stage), [_pick(_alive_in(s, p.allowed_ids))])
				_:
					return Command.answer_choice(p.id, String(p.stage), true)
		PendingPrompt.OWNER_ORACLE:
			if p.stage == OracleStep.STAGE_TARGET:
				return Command.answer_stage_targets(p.id, String(p.stage), [_pick(_alive_in(s, p.allowed_ids, p.actor_id))])
			if _rng.randf() < 0.1 and _override_allowed(p):
				return Command.override_shown_role(p.id, "dorfbewohner", "Fuzz: Übersteuerung")
			return Command.answer_choice(p.id, String(p.stage), true)
		PendingPrompt.OWNER_CHRONICLER, PendingPrompt.OWNER_BOUND, PendingPrompt.OWNER_RANGER, PendingPrompt.OWNER_DOCTOR, PendingPrompt.OWNER_TRACKER, PendingPrompt.OWNER_HOUND:
			if p.stage == InfoSteps.STAGE_USE:
				return Command.answer_choice(p.id, String(p.stage), _rng.randf() < 0.5)
			if p.stage == InfoSteps.STAGE_TARGETS and p.owner == PendingPrompt.OWNER_HOUND:
				var pool3 := _alive_in(s, p.allowed_ids, p.actor_id)
				if pool3.size() < 3 or _rng.randf() < 0.2:
					return Command.answer_stage_targets(p.id, String(p.stage), [])
				var picks: Array = []
				while picks.size() < 3:
					var t: int = _pick(pool3)
					if not picks.has(t):
						picks.append(t)
				return Command.answer_stage_targets(p.id, String(p.stage), picks)
			if p.stage == InfoSteps.STAGE_TARGETS:
				var pool2 := _alive_in(s, p.allowed_ids, p.actor_id)
				var a: int = _pick(pool2)
				pool2.erase(a)
				return Command.answer_stage_targets(p.id, String(p.stage), [a, _pick(pool2)])
			return Command.answer_choice(p.id, String(p.stage), true)
		PendingPrompt.OWNER_DREAMER, PendingPrompt.OWNER_BOUNTY, PendingPrompt.OWNER_KING, PendingPrompt.OWNER_WARRIOR, PendingPrompt.OWNER_BLOOD, PendingPrompt.OWNER_ETERNAL:
			if p.stage == InfoSteps.STAGE_SHOWN:
				return Command.answer_choice(p.id, String(p.stage), true)
			var pool := _alive_in(s, p.allowed_ids, p.actor_id)
			if p.stage == InfoSteps.STAGE_REVEAL or (p.min_count == 0 and _rng.randf() < 0.3):
				var k := 0 if p.stage == InfoSteps.STAGE_TARGETS else _rng.randi_range(0, mini(p.max_count, pool.size()))
				return Command.answer_stage_targets(p.id, String(p.stage), pool.slice(0, k))
			var chosen: Array = []
			if InfoSteps.TRIPLE_OWNERS.has(p.owner):
				# Meist gültig (ein Wolf dabei), manchmal ohne Wolf: Ablehnung muss folgenlos bleiben.
				var wolves := pool.filter(func(id: int) -> bool: return s.players[id].counts_as_wolf)
				if not wolves.is_empty() and _rng.randf() < 0.9:
					chosen.append(_pick(wolves))
				else:
					_probe = true  # ohne gezielten Wolf darf die Auswahl abgelehnt werden
			while chosen.size() < p.max_count and chosen.size() < pool.size():
				var t: int = _pick(pool)
				if not chosen.has(t):
					chosen.append(t)
			return Command.answer_stage_targets(p.id, String(p.stage), chosen)
		PendingPrompt.OWNER_LOKI, PendingPrompt.OWNER_RED:
			if p.stage != BondSteps.STAGE_TARGETS:
				return Command.answer_choice(p.id, String(p.stage), _rng.randf() < 0.6)
			var bond_pool := _alive_in(s, p.allowed_ids)
			var bond_picks: Array = []
			var wanted := p.max_count if (p.min_count > 0 or _rng.randf() < 0.8) else 0
			while bond_picks.size() < wanted and bond_picks.size() < bond_pool.size():
				var b: int = _pick(bond_pool)
				if not bond_picks.has(b):
					bond_picks.append(b)
			return Command.answer_stage_targets(p.id, String(p.stage), bond_picks)
		PendingPrompt.OWNER_SHADOW:
			return Command.answer_choice(p.id, "use", _rng.randf() < 0.3)
		PendingPrompt.OWNER_APPRENTICE:
			match p.stage:
				ApprenticeRules.STAGE_CANDIDATES:
					var pool := _alive_in(s, p.allowed_ids, p.actor_id)
					var chosen: Array = []
					while chosen.size() < ApprenticeRules.OPTION_COUNT:
						var candidate: int = _pick(pool)
						if not chosen.has(candidate):
							chosen.append(candidate)
					return Command.answer_stage_targets(p.id, String(p.stage), chosen)
				ApprenticeRules.STAGE_OPTION:
					var options: Array = p.partial.get("options", [])
					return Command.create(Command.ANSWER_PROMPT, {"prompt_id": p.id, "stage": String(p.stage), "option": _rng.randi_range(0, options.size() - 1)})
				_:
					return Command.answer_choice(p.id, String(p.stage), true)
	var pool := _alive_in(s, p.allowed_ids)
	var n := _rng.randi_range(p.min_count, mini(p.max_count, pool.size()))
	var targets: Array = []
	while targets.size() < n:
		var t: int = _pick(pool)
		if not targets.has(t):
			targets.append(t)
	return Command.answer_prompt(p.id, targets)


## Übersteuerung nur, wenn das gezeigte Ergebnis sich dadurch ändert (sonst `no_change`).
func _override_allowed(p: PendingPrompt) -> bool:
	return String(p.partial.get("shown_role", "")) != "dorfbewohner"


# --- Invarianten ----------------------------------------------------------------------------------

func _check_after(before: GameState, s: GameState, events: Array[GameEvent], label: String) -> int:
	var deaths := 0
	var restored := GameState.from_dict(s.to_dict())
	assert_true(restored != null, "%s: Zustand ladbar" % label)
	if restored != null:
		assert_eq(CanonicalJson.stringify(restored.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: Zustand verlustfrei" % label)
	for e: GameEvent in events:
		_seen[String(e.type)] = int(_seen.get(String(e.type), 0)) + 1
		if e.type == GameEvent.SEAT_DIED:
			var key := "cause:" + String(e.data["cause"])
			_seen[key] = int(_seen.get(key, 0)) + 1
		if e.visibility == Visibility.PUBLIC:
			var leak := _find_forbidden(e.data)
			assert_eq(leak, "", "%s: öffentliches %s ohne Geheimnis" % [label, e.type])
		elif e.visibility == Visibility.ACTOR:
			assert_true(s.players.has(e.actor_id), "%s: %s an eine bekannte Person" % [label, e.type])
		if e.type == GameEvent.SEAT_DIED:
			deaths += 1
			var target := int(e.data["target_id"])
			assert_true(before.players[target].alive and not _died_earlier_in(events, e, target), "%s: nur Lebende sterben, höchstens einmal (%d)" % [label, target])
		if e.type == GameEvent.PROMPT_OPENED:
			_check_prompt_actor(s, e.data["prompt"], label)
	for id: int in s.players:
		var p: Player = s.players[id]
		assert_eq(p.death == null, p.alive, "%s: Todesdatensatz passt zu lebend/tot (%d)" % [label, id])
		if p.role_id == RoleCatalog.WOLFSKIND:
			var bond := WolfChildRules.bond_of(s, id)
			assert_true(bond != null and WolfChildRules.fields_match(p, bond.transformed), "%s: Wolfskind-Felder (%d)" % [label, id])
		else:
			assert_eq(p.faction, RoleCatalog.faction_of(p.role_id), "%s: Fraktion passt zur Rolle (%d)" % [label, id])
			assert_eq(p.counts_as_wolf, RoleCatalog.counts_as_wolf(p.role_id), "%s: Wolfszählung passt zur Rolle (%d)" % [label, id])
			# Die Erscheinung ist per `set_role_field` korrigierbar; sie bleibt eine bekannte Rolle,
			# beim Trugbilderwolf nie eine Wolfsrolle (DR-08).
			assert_true(RoleCatalog.has_role(p.appears_as), "%s: Erscheinung ist eine bekannte Rolle (%d)" % [label, id])
			if RoleCatalog.requires_appearance(p.role_id):
				assert_true(RoleCatalog.is_valid_appearance(p.appears_as), "%s: Scheinrolle gültig (%d)" % [label, id])
	return deaths


## Zweiter Tod derselben Person innerhalb eines Befehls wäre ebenso ein Fehler.
func _died_earlier_in(events: Array[GameEvent], current: GameEvent, target: int) -> bool:
	for e: GameEvent in events:
		if e == current:
			return false
		if e.type == GameEvent.SEAT_DIED and int(e.data["target_id"]) == target:
			return true
	return false


func _check_prompt_actor(s: GameState, prompt: Dictionary, label: String) -> void:
	var step := String(prompt["step_id"])
	var actor := int(prompt["actor_id"])
	if not step.begins_with("night:") or actor == -1:
		return
	var role := StepQueue.step_kind(step)
	# Ausnahme zu G-PH-2: der Schutzgeist handelt in der ersten Nacht nach seinem Tod (S-04).
	assert_true(s.players[actor].alive != (role == RoleCatalog.SCHUTZGEIST), "%s: %s nur für Lebende (Schutzgeist: nur tot)" % [label, step])
	assert_eq(s.players[actor].role_id, role, "%s: %s nur mit geplanter Rolle" % [label, step])
	assert_false((prompt["allowed_ids"] as Array).has(actor) and not [RoleCatalog.WALDHEXE, RoleCatalog.KORRUPTER_RICHTER, RoleCatalog.LOKI].has(role), "%s: %s ohne Selbstwahl" % [label, step])


func _check_codec(s: GameState, log: Array[Command], label: String) -> void:
	var loaded := StateCodec.decode(StateCodec.encode(s, log))
	assert_true(loaded.ok, "%s: Spielstand lädt (%s)" % [label, loaded.error])
	if loaded.ok:
		assert_eq(CanonicalJson.stringify(loaded.state.to_dict()), CanonicalJson.stringify(s.to_dict()), "%s: geladener Zustand identisch" % label)


func _find_forbidden(value: Variant) -> String:
	if value is Dictionary:
		for k: Variant in (value as Dictionary):
			if FORBIDDEN_PUBLIC_KEYS.has(String(k)):
				return String(k)
			var hit := _find_forbidden(value[k])
			if hit != "":
				return hit
	elif value is Array:
		for v: Variant in (value as Array):
			var hit := _find_forbidden(v)
			if hit != "":
				return hit
	return ""
