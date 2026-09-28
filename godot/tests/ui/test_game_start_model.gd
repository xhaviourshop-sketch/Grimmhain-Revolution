extends UiTestCase
## Spielstart aus dem bestätigten Setup (Anwendungsschicht ohne Szenen): PlayerSetup liefert reine
## Startdaten, GameStart baut daraus genau einen manuellen StartGame-Befehl und sendet ihn über
## GameSession an den Regelkern. Geprüft wird der entstandene GameState über ein Replay der
## angenommenen Befehle.

const SETUP_SCRIPT := "res://app/setup/player_setup.gd"
const START_SCRIPT := "res://app/session/game_start.gd"
const FIXED_SEED := 727272
const UUID_PATTERN := "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"


## Setup mit `count` Personen, mindestens einem Trugbilderwolf mit ausdrücklicher Scheinrolle,
## Zufallsverteilung mit `distribution_seed` und bestätigter Sitzordnung nach mehreren Tauschen.
func _ready_setup(count: int, distribution_seed: int = FIXED_SEED) -> Object:
	var script := load_script(SETUP_SCRIPT)
	if script == null:
		return null
	var s: Object = script.new()
	s.set("seed_source", func() -> int: return distribution_seed)
	for i: int in count:
		s.call("add_person", "Person %d" % (i + 1))
	_ok(s.call("confirm"), "Spieler bestätigt")
	s.call("apply_suggestion")
	if ((s.call("view") as Dictionary)["roles"].get("decoys", []) as Array).is_empty():
		s.call("change_role_count", &"dorfbewohner", -1)
		s.call("change_role_count", &"trugbilderwolf", 1)
	var decoys: Array = (s.call("view") as Dictionary)["roles"].get("decoys", [])
	assert_false(decoys.is_empty(), "Vorbereitung: Trugbilderwolf im Pool")
	for d: Variant in decoys:
		s.call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"schutzengel")
	_ok(s.call("confirm_roles"), "Rollen bestätigt")
	_ok(s.call("distribute_randomly"), "zufällig verteilt")
	_ok(s.call("confirm_distribution"), "Verteilung bestätigt")
	_ok(s.call("go_to_step", &"seating"), "zur Sitzordnung")
	var ids := _ids(s)
	s.call("swap_seats", ids[0], ids[count - 1])
	s.call("swap_seats", ids[1], ids[3])
	s.call("swap_seats", ids[0], ids[2])
	_ok(s.call("confirm_seating"), "Sitzordnung bestätigt")
	return s


func _new_session() -> Object:
	var script := load_script(SESSION_SCRIPT)
	return script.new() if script != null else null


func _start(session: Object, s: Object) -> Dictionary:
	var script := load_script(START_SCRIPT)
	if script == null:
		return {}
	return script.call("start", session, s) as Dictionary


func _ids(s: Object) -> Array[int]:
	var out: Array[int] = []
	for p: Variant in (s.call("view") as Dictionary)["persons"]:
		out.append(int((p as Dictionary)["person_id"]))
	return out


func _order(s: Object) -> Array[int]:
	var out: Array[int] = []
	for seat: Variant in ((s.call("view") as Dictionary)["seating"] as Dictionary)["seats"]:
		out.append(int((seat as Dictionary)["person_id"]))
	return out


## Erwartung je Personen-ID aus der geheimen Verteilungssicht: [Name, Rolle, Scheinrolle oder ""].
func _expected(s: Object) -> Dictionary:
	var names := {}
	for p: Variant in (s.call("view") as Dictionary)["persons"]:
		names[int((p as Dictionary)["person_id"])] = str((p as Dictionary)["name"])
	var out := {}
	for e: Variant in ((s.call("view") as Dictionary)["distribution"] as Dictionary)["assignment"]:
		var entry: Dictionary = e
		var id := int(entry["person_id"])
		out[id] = [names[id], str(entry["role"]), str(entry["appearance"])]
	return out


func _state_of(session: Object) -> GameState:
	var commands: Array[Command] = []
	for c: Variant in session.call("commands"):
		commands.append(c as Command)
	var replayed := RulesEngine.replay(commands)
	assert_true(replayed.ok, "Replay der angenommenen Befehle (%s)" % replayed.error)
	return replayed.state


## Tatsächlicher Zustand je Personen-ID: [Name, Rolle, Scheinrolle bei Pflicht-Scheinrolle oder ""].
func _actual(state: GameState) -> Dictionary:
	var out := {}
	for id: int in state.players:
		var p: Player = state.players[id]
		var appearance := String(p.appears_as) if RoleCatalog.requires_appearance(p.role_id) else ""
		out[id] = [p.name, String(p.role_id), appearance]
	return out


func _ok(result: Object, label: String) -> bool:
	var ok := result != null and bool(result.get("ok"))
	assert_true(ok, "%s angenommen (%s)" % [label, result.get("error") if result != null else "kein Ergebnis"])
	return ok


# --- Gültiger Start --------------------------------------------------------------------------------------

func test_valid_start_with_six_and_twentyfour_persons() -> void:
	for count: int in [6, 24]:
		var s := _ready_setup(count)
		var session := _new_session()
		if s == null or session == null:
			return
		var expected := _expected(s)
		var order := _order(s)
		assert_ne(order, _ids(s), "%d: Sitzordnung weicht nach Tauschen von der Listenreihenfolge ab" % count)
		var result := _start(session, s)
		assert_true(bool(result.get("ok", false)), "%d: Start angenommen (%s)" % [count, result.get("error", "")])
		var view: Dictionary = session.call("view")
		assert_true(bool(view["has_game"]), "%d: aktive Partie" % count)
		assert_eq(int(view["player_count"]), count, "%d: alle Personen in der Partie" % count)
		assert_eq(int(view["command_count"]), 1, "%d: genau ein Befehl" % count)
		var state := _state_of(session)
		assert_eq(_actual(state), expected, "%d: Name, Rolle und Scheinrolle je Personen-ID unverändert" % count)
		assert_eq(state.seat_order, order, "%d: Sitzreihenfolge unverändert (Platz 1 = Index 0)" % count)
		var decoys := 0
		for id: int in expected:
			if str((expected[id] as Array)[2]) != "":
				decoys += 1
				assert_eq(String(state.players[id].appears_as), "schutzengel", "%d: ausdrücklich gewählte Scheinrolle übernommen" % count)
		assert_true(decoys >= 1, "%d: mindestens eine Scheinrolle geprüft" % count)


func test_command_uses_fixed_assignment_without_reshuffle() -> void:
	var s := _ready_setup(10)
	var session := _new_session()
	if s == null or session == null:
		return
	var expected := _expected(s)
	_start(session, s)
	var commands: Array = session.call("commands")
	assert_eq(commands.size(), 1, "ein Befehl")
	if commands.is_empty():
		return
	var c: Command = commands[0]
	assert_eq(String(c.type), String(Command.START_GAME), "StartGame")
	assert_eq(str(c.payload.get("assignment")), "manual", "feste Zuordnung als manuelle Zuordnung")
	assert_false(c.payload.has("role_pool") or c.payload.has("role_entries"), "kein Pool zum erneuten Mischen")
	# Ein anderer Spielseed ändert die Zuordnung nicht: Replay mit anderem Seed ergibt dieselben Rollen.
	var payload: Dictionary = c.payload.duplicate(true)
	payload["seed"] = int(payload["seed"]) + 1
	var other := RulesEngine.apply(GameState.new(), Command.start_game(payload))
	assert_true(other.ok, "gleicher Befehl mit anderem Seed angenommen")
	if other.ok:
		assert_eq(_actual(other.state), expected, "Rollen hängen nicht vom Spielseed ab (kein erneutes Mischen)")


func test_seed_and_round_id_are_reproducible() -> void:
	var script := load_script(START_SCRIPT)
	var first := _ready_setup(8)
	var second := _ready_setup(8)
	if script == null or first == null or second == null:
		return
	var a: Command = script.call("build_command", first.call("start_data").get("details"), 4242)
	var b: Command = script.call("build_command", second.call("start_data").get("details"), 4242)
	assert_eq(JSON.stringify(a.payload), JSON.stringify(b.payload), "gleiches Setup und gleicher Seed ergeben denselben Befehl")
	assert_eq(int(a.payload["seed"]), 4242, "Seed unverändert übernommen")
	var round_id := str(a.payload["round_id"])
	assert_true(RegEx.create_from_string(UUID_PATTERN).search(round_id) != null, "round_id im UUID-Format: %s" % round_id)
	assert_eq(round_id, str(script.call("round_id_for", 4242)), "round_id nur aus dem Seed abgeleitet")
	assert_ne(str(script.call("round_id_for", 4243)), round_id, "anderer Seed, andere round_id")
	# Der Seed der Partie kommt aus der Seed-Quelle des Setups.
	var session := _new_session()
	first.set("seed_source", func() -> int: return 13579)
	_start(session, first)
	var c: Command = (session.call("commands") as Array)[0]
	assert_eq(int(c.payload["seed"]), 13579, "Seed aus PlayerSetup.seed_source")
	assert_eq(str(c.payload["round_id"]), str(script.call("round_id_for", 13579)), "round_id passend zum Seed")


func test_replay_of_same_command_yields_identical_state() -> void:
	var s := _ready_setup(12)
	var session := _new_session()
	if s == null or session == null:
		return
	_start(session, s)
	var commands: Array[Command] = []
	for c: Variant in session.call("commands"):
		commands.append(c as Command)
	var first := RulesEngine.replay(commands)
	var second := RulesEngine.replay(commands)
	assert_true(first.ok and second.ok, "Replay angenommen")
	assert_eq(first.state.content_hash(), str(session.call("state_hash")), "Replay entspricht der Sitzung")
	assert_eq(second.state.content_hash(), first.state.content_hash(), "zweites Replay identisch")


# --- Unvollständiger oder veränderter Entwurf ------------------------------------------------------------

func test_incomplete_or_changed_draft_starts_no_game() -> void:
	var script := load_script(SETUP_SCRIPT)
	var session := _new_session()
	if script == null or session == null:
		return
	# Nur Spieler bestätigt.
	var partial: Object = script.new()
	for i: int in 6:
		partial.call("add_person", "P%d" % i)
	partial.call("confirm")
	_expect_rejected(session, partial, "roles_not_confirmed", "nur Spieler bestätigt")
	# Sitzordnung nach Bestätigung erneut getauscht.
	var s := _ready_setup(8)
	var ids := _ids(s)
	s.call("swap_seats", ids[2], ids[5])
	_expect_rejected(session, s, "seating_not_confirmed", "Tausch nach Bestätigung")
	# Verteilung nachträglich neu gemischt.
	s.call("confirm_seating")
	s.call("reshuffle")
	_expect_rejected(session, s, "distribution_not_confirmed", "neu gemischt")
	# Name nachträglich geändert.
	var t := _ready_setup(7)
	t.call("rename_person", _ids(t)[0], "Neu")
	_expect_rejected(session, t, "players_not_confirmed", "Name geändert")
	# Person hinzugefügt.
	var u := _ready_setup(7)
	u.call("add_person", "Nachzügler")
	_expect_rejected(session, u, "players_not_confirmed", "Person hinzugefügt")


func _expect_rejected(session: Object, s: Object, error: String, label: String) -> void:
	var setup_before := JSON.stringify(s.call("view"))
	var session_before := JSON.stringify(session.call("view"))
	var hash_before := str(session.call("state_hash"))
	var result := _start(session, s)
	assert_false(bool(result.get("ok", true)), "%s: kein Start" % label)
	assert_eq(str(result.get("error", "")), error, "%s: Fehlercode" % label)
	assert_eq(JSON.stringify(s.call("view")), setup_before, "%s: Setup unverändert" % label)
	assert_eq(JSON.stringify(session.call("view")), session_before, "%s: Sitzung unverändert" % label)
	assert_eq(str(session.call("state_hash")), hash_before, "%s: Zustand unverändert" % label)


# --- Wiederholter Start und Ablehnung durch den Regelkern ------------------------------------------------

func test_repeated_start_creates_exactly_one_game() -> void:
	var s := _ready_setup(9)
	var session := _new_session()
	if s == null or session == null:
		return
	assert_true(bool(_start(session, s).get("ok", false)), "erster Start")
	var hash_after := str(session.call("state_hash"))
	assert_false(bool((s.call("view") as Dictionary)["seating"]["ready"]), "Entwurf nach dem Start verbraucht")
	var again := _start(session, s)
	assert_false(bool(again.get("ok", true)), "zweiter Start mit demselben Entwurf abgelehnt")
	assert_eq(int((session.call("view") as Dictionary)["command_count"]), 1, "weiterhin genau ein Befehl")
	assert_eq(str(session.call("state_hash")), hash_after, "Partie unverändert")


func test_rules_core_rejection_changes_nothing() -> void:
	var session := _new_session()
	var s := _ready_setup(6)
	if s == null or session == null:
		return
	session.call("submit", Fixtures.start_manual(6, [1]))
	var rejections: Array[String] = []
	session.connect("command_rejected", func(e: StringName) -> void: rejections.append(String(e)))
	_expect_rejected(session, s, "game_already_started", "Partie läuft bereits")
	assert_eq(rejections, ["game_already_started"] as Array[String], "Ablehnung kommt aus dem Regelkern")
	assert_true(bool((s.call("view") as Dictionary)["seating"]["ready"]), "Entwurf bleibt startbereit")


# --- Startdaten ohne Regelkern ---------------------------------------------------------------------------

func test_start_data_is_plain_and_only_when_ready() -> void:
	var s := _ready_setup(6)
	if s == null:
		return
	var result: Object = s.call("start_data")
	_ok(result, "Startdaten")
	var data: Dictionary = result.get("details")
	assert_eq(data.keys().size(), 4, "nur players, seat_order, roles, appearances")
	for key: String in ["players", "seat_order", "roles", "appearances"]:
		assert_true(data.has(key), "Startdaten enthalten %s" % key)
	assert_eq(data["seat_order"], _order(s), "Sitzreihenfolge")
	var ids := _ids(s)
	s.call("swap_seats", ids[0], ids[1])
	var blocked: Object = s.call("start_data")
	assert_false(bool(blocked.get("ok")), "nach Tausch keine Startdaten")
	assert_eq(String(blocked.get("error")), "seating_not_confirmed", "Fehlercode")
