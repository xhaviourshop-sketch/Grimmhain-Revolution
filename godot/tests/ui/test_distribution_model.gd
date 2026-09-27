extends UiTestCase
## Rollen-Setup: Verteilungsmodell (Auftrag Rollen, Tests 37 bis 71). Ohne Szenen. Seeds sind
## fest; kein Test setzt voraus, dass ein anderer Seed eine andere Permutation liefert.

const SETUP_SCRIPT := "res://app/setup/player_setup.gd"
const DISTRIBUTION_SCRIPT := "res://app/setup/role_distribution.gd"
const CATALOG_SCRIPT := "res://app/setup/setup_role_catalog.gd"
const FIXED_SEED := 424242


## Setup mit `count` bestätigten Personen, bestätigtem Pool `counts` (sonst Vorschlag) und
## fester Seed-Quelle; `calls[0]` zählt die Aufrufe der Seed-Quelle.
## `appearances`: ausdrücklich gewählte Scheinrollen der Trugbilderwolf-Kopien (DR-08), der Reihe nach.
func _ready_setup(count: int = 8, counts: Dictionary = {}, seed_value: int = FIXED_SEED, calls: Array = [0], appearances: Array = []) -> Object:
	var script := load_script(SETUP_SCRIPT)
	if script == null:
		return null
	var s: Object = script.new()
	s.set("seed_source", func() -> int:
		calls[0] += 1
		return seed_value)
	for i: int in count:
		s.call("add_person", "Person %d" % (i + 1))
	s.call("confirm")
	if counts.is_empty():
		s.call("apply_suggestion")
	else:
		for role: Variant in counts:
			s.call("set_role_count", StringName(str(role)), int(counts[role]))
	var decoys: Array = (s.call("view") as Dictionary)["roles"].get("decoys", [])
	for i: int in mini(decoys.size(), appearances.size()):
		s.call("set_decoy_appearance", int((decoys[i] as Dictionary)["copy_id"]), StringName(str(appearances[i])))
	var r: Object = s.call("confirm_roles")
	assert_true(r != null and bool(r.get("ok")), "Vorbereitung: Rollen bestätigt")
	return s


func _dist(s: Object) -> Dictionary:
	return (s.call("view") as Dictionary).get("distribution", {}) as Dictionary


## Zuordnung als {person_id: role} aus der Sicht.
func _assignment(s: Object) -> Dictionary:
	var out := {}
	for entry: Variant in _dist(s).get("assignment", []):
		var e: Dictionary = entry
		if str(e["role"]) != "":
			out[int(e["person_id"])] = str(e["role"])
	return out


func _appearances(s: Object) -> Dictionary:
	var out := {}
	for entry: Variant in _dist(s).get("assignment", []):
		var e: Dictionary = entry
		if str(e["appearance"]) != "":
			out[int(e["person_id"])] = str(e["appearance"])
	return out


func _ids(s: Object) -> Array[int]:
	var out: Array[int] = []
	for p: Variant in (s.call("view") as Dictionary)["persons"]:
		out.append(int((p as Dictionary)["person_id"]))
	return out


func _ok(result: Object, label: String) -> bool:
	var ok := result != null and bool(result.get("ok"))
	assert_true(ok, "%s angenommen (%s)" % [label, result.get("error") if result != null else "kein Ergebnis"])
	return ok


func _rejected(s: Object, result: Object, error: String, label: String, before: String) -> void:
	assert_true(result != null and not bool(result.get("ok")), "%s abgelehnt" % label)
	if result != null:
		assert_eq(String(result.get("error")), error, "%s: Fehlercode" % label)
	assert_eq(JSON.stringify(s.call("view")), before, "%s: Zustand unverändert" % label)


func _sorted_values(d: Dictionary) -> Array:
	var values := d.values()
	values.sort()
	return values


# --- Zufällige Verteilung (41 bis 52) --------------------------------------------------------------------

func test_random_distribution_is_complete_and_reproducible() -> void:
	var calls := [0]
	var s := _ready_setup(12, {}, FIXED_SEED, calls)
	if s == null:
		return
	assert_false(bool(_dist(s)["has_seed"]), "vor dem ersten Verteilen kein Seed")
	assert_eq(calls[0], 0, "Seed-Quelle erst beim bewussten Verteilen")
	if not _ok(s.call("distribute_randomly"), "zufällig verteilen"):
		return
	assert_eq(calls[0], 1, "Seed genau einmal erzeugt")
	var d := _dist(s)
	assert_eq(str(d["seed"]), str(FIXED_SEED), "Seed gespeichert und sichtbar")
	var a := _assignment(s)
	assert_eq(a.size(), 12, "jede Person genau eine Rolle")
	assert_eq(a.keys().map(func(k: Variant) -> int: return int(k)), _ids(s) as Array, "Zuordnung genau zu den Personen-IDs")
	var pool: Array = (s.call("view") as Dictionary)["roles"]["pool"]
	assert_eq(_sorted_values(a), pool, "jede Rollenkopie genau einmal")
	assert_true(bool(d["complete"]) and int(d["remaining_total"]) == 0, "vollständig")
	var twin := _ready_setup(12, {}, FIXED_SEED)
	twin.call("distribute_randomly")
	assert_eq(_assignment(twin), a, "gleiche IDs, gleicher Pool, gleicher Seed: gleiche Zuordnung")
	s.call("distribute_randomly")
	assert_eq(_assignment(s), a, "erneutes Verteilen mit gespeichertem Seed: unverändert")
	assert_eq(calls[0], 1, "kein zweiter Seed")


func test_assignment_depends_on_person_id_not_order() -> void:
	var dist := load_script(DISTRIBUTION_SCRIPT)
	if dist == null:
		return
	var pool: Array[StringName] = [&"dorfbewohner", &"dorfbewohner", &"dorfbewohner", &"manipulator", &"schutzengel", &"werwolf"]
	var ids: Array[int] = [3, 7, 9, 12, 15, 20]
	var reversed: Array[int] = [20, 15, 12, 9, 7, 3]
	var first: Dictionary = dist.call("random_assignment", ids, pool, FIXED_SEED)
	var second: Dictionary = dist.call("random_assignment", reversed, pool, FIXED_SEED)
	assert_eq(first, second, "Listenreihenfolge ändert nichts, nur die Personen-ID zählt")
	assert_eq(first.size(), 6, "sechs Zuordnungen")


func test_rerender_language_and_rename_keep_assignment() -> void:
	var s := _ready_setup(10, {"trugbilderwolf": 1, "werwolf": 1, "manipulator": 1, "dorfbewohner": 7}, FIXED_SEED, [0], ["waldhexe"])
	if s == null:
		return
	s.call("distribute_randomly")
	var a := _assignment(s)
	var app := _appearances(s)
	assert_eq(JSON.stringify(s.call("view")), JSON.stringify(s.call("view")), "wiederholte Sicht identisch")
	TranslationServer.set_locale("en")
	assert_eq(_assignment(s), a, "Sprachwechsel ändert nichts")
	TranslationServer.set_locale("de")
	var ids := _ids(s)
	_ok(s.call("rename_person", ids[2], "Ganz neuer Name"), "umbenennen")
	assert_eq(_assignment(s), a, "Namensänderung ändert die Zuordnung nicht")
	assert_eq(_appearances(s), app, "Namensänderung ändert die Scheinrolle nicht")
	var entry: Dictionary = (_dist(s)["assignment"] as Array)[2]
	assert_eq(str(entry["name"]), "Ganz neuer Name", "angezeigter Name aktualisiert")


func test_reshuffle_is_deliberate_and_changes_only_distribution() -> void:
	var s := _ready_setup(9)
	if s == null:
		return
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("reshuffle"), "nothing_to_reshuffle", "Neu mischen ohne Verteilung", before)
	s.call("distribute_randomly")
	var view_before: Dictionary = s.call("view")
	var d_before := _dist(s)
	assert_eq(int(d_before["shuffle_count"]), 0, "Mischzähler 0")
	assert_eq(JSON.stringify(s.call("view")), JSON.stringify(view_before), "keine Änderung ohne bewusste Aktion")
	if not _ok(s.call("reshuffle"), "neu mischen"):
		return
	var view_after: Dictionary = s.call("view")
	var d_after := _dist(s)
	assert_eq(int(d_after["shuffle_count"]), 1, "Mischzähler erhöht und gespeichert")
	assert_eq(str(d_after["seed"]), str(d_before["seed"]), "Basis-Seed bleibt")
	assert_true(str(d_after["effective_seed"]) != "", "verwendeter Seed protokolliert")
	assert_eq(view_after["persons"], view_before["persons"], "Personen unverändert")
	assert_eq(view_after["roles"], view_before["roles"], "Rollenpool unverändert")
	assert_true(bool(d_after["complete"]) and _assignment(s).size() == 9, "wieder vollständig")
	var twin := _ready_setup(9)
	twin.call("distribute_randomly")
	twin.call("reshuffle")
	assert_eq(_assignment(twin), _assignment(s), "Neu mischen ist reproduzierbar")


func test_confirm_random_distribution() -> void:
	var s := _ready_setup(8)
	if s == null:
		return
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("confirm_distribution"), "distribution_incomplete", "leere Verteilung bestätigen", before)
	s.call("distribute_randomly")
	if not _ok(s.call("confirm_distribution"), "Verteilung bestätigen"):
		return
	var d := _dist(s)
	assert_true(bool(d["confirmed"]) and bool(d["ready_for_seating"]), "bestätigt, bereit für Sitzordnung")
	var steps: Array = (s.call("view") as Dictionary)["steps"]
	assert_eq(str(steps[2]["state"]), "done", "Verteilungsschritt erledigt")
	s.call("reshuffle")
	assert_false(bool(_dist(s)["confirmed"]), "Neu mischen hebt die Bestätigung auf")


# --- Abhängigkeiten (37 bis 40) ---------------------------------------------------------------------------

func test_person_changes_discard_distribution() -> void:
	var s := _ready_setup(8)
	if s == null:
		return
	s.call("distribute_randomly")
	s.call("add_person", "Neu")
	var d := _dist(s)
	assert_true(not bool(d["has_assignment"]) and str(d["invalidated"]) == "person_count_changed", "hinzufügen verwirft die Verteilung")
	assert_eq(str((s.call("view") as Dictionary)["step"]), "players", "Schritt fällt auf Spieler zurück")
	s.call("set_role_count", &"dorfbewohner", int((s.call("view") as Dictionary)["roles"]["counts"]["dorfbewohner"]) + 1)
	s.call("confirm")
	_ok(s.call("confirm_roles"), "neu bestätigt")
	s.call("distribute_randomly")
	var ids := _ids(s)
	s.call("remove_person", ids[4])
	d = _dist(s)
	assert_true(not bool(d["has_assignment"]) and _assignment(s).is_empty(), "entfernen verwirft die Verteilung")
	for entry: Variant in d["assignment"]:
		assert_true(ids.has(int((entry as Dictionary)["person_id"])) and int((entry as Dictionary)["person_id"]) != ids[4], "keine unbekannte Personen-ID")


func test_role_changes_discard_distribution_unless_pool_identical() -> void:
	var s := _ready_setup(8)
	if s == null:
		return
	s.call("distribute_randomly")
	var a := _assignment(s)
	_ok(s.call("go_to_step", &"roles"), "zurück zu den Rollen")
	_ok(s.call("confirm_roles"), "identischen Pool erneut bestätigen")
	assert_eq(_assignment(s), a, "semantisch identischer Pool erhält die Verteilung")
	s.call("change_role_count", &"dorfbewohner", -1)
	var d := _dist(s)
	assert_true(not bool(d["has_assignment"]) and str(d["invalidated"]) == "roles_changed", "Rollenänderung verwirft die Verteilung")
	s.call("change_role_count", &"dorfbewohner", 1)
	s.call("confirm_roles")
	assert_true(_assignment(s).is_empty(), "Rückänderung bringt keine alte Verteilung zurück")
	assert_eq(_ids(s), [1, 2, 3, 4, 5, 6, 7, 8] as Array[int], "Personen-IDs unverändert")


# --- Manuelle Verteilung (53 bis 64) ----------------------------------------------------------------------

func test_manual_assignment_flow() -> void:
	var s := _ready_setup(6, {"werwolf": 2, "manipulator": 1, "dorfbewohner": 3})
	if s == null:
		return
	_ok(s.call("set_distribution_mode", &"manual"), "Modus manuell")
	var d := _dist(s)
	assert_eq(str(d["mode"]), "manual", "Modus gespeichert")
	assert_eq(_assignment(s).size(), 0, "zunächst alle nicht zugewiesen")
	assert_eq(d["remaining"], {"dorfbewohner": 3, "manipulator": 1, "werwolf": 2}, "verfügbare Kopien")
	var ids := _ids(s)
	_ok(s.call("assign_role", ids[0], &"werwolf"), "zuweisen")
	_ok(s.call("assign_role", ids[1], &"werwolf"), "zweite Kopie")
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("assign_role", ids[2], &"werwolf"), "no_copy_available", "Überbelegung", before)
	_rejected(s, s.call("assign_role", ids[2], &"nicht-im-katalog"), "unknown_role", "unbekannte Rolle", before)
	_rejected(s, s.call("assign_role", ids[2], &"schutzengel"), "role_not_in_pool", "Rolle nicht im Pool", before)
	_rejected(s, s.call("assign_role", 999, &"dorfbewohner"), "unknown_person", "unbekannte Person", before)
	_ok(s.call("assign_role", ids[1], &"manipulator"), "Rolle ändern")
	assert_eq(_assignment(s)[ids[1]], "manipulator", "geändert")
	assert_eq(int(_dist(s)["remaining"]["werwolf"]), 1, "alte Kopie wieder frei")
	_ok(s.call("unassign_role", ids[1]), "Zuweisung entfernen")
	assert_false(_assignment(s).has(ids[1]), "entfernt")
	_ok(s.call("swap_roles", ids[0], ids[1]), "tauschen mit nicht zugewiesener Person")
	assert_true(_assignment(s).get(ids[1], "") == "werwolf" and not _assignment(s).has(ids[0]), "getauscht")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("confirm_distribution"), "distribution_incomplete", "unvollständige Zuordnung", before)
	var rest: Array[String] = ["werwolf", "manipulator", "dorfbewohner", "dorfbewohner", "dorfbewohner"]
	var free_ids: Array[int] = [ids[0], ids[2], ids[3], ids[4], ids[5]]
	for i: int in free_ids.size():
		_ok(s.call("assign_role", free_ids[i], StringName(rest[i])), "zuweisen %d" % i)
	assert_true(bool(_dist(s)["complete"]) and int(_dist(s)["remaining_total"]) == 0, "vollständig, kein Rest")
	_ok(s.call("confirm_distribution"), "vollständige Zuordnung bestätigen")
	assert_eq(_ids(s), [1, 2, 3, 4, 5, 6] as Array[int], "Personen-IDs stabil")


func test_mode_switch_requires_confirmation() -> void:
	var s := _ready_setup(6, {"werwolf": 1, "manipulator": 1, "dorfbewohner": 4})
	if s == null:
		return
	s.call("set_distribution_mode", &"manual")
	s.call("assign_role", _ids(s)[0], &"werwolf")
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("set_distribution_mode", &"random"), "confirmation_required", "Moduswechsel mit Zuordnung", before)
	assert_eq(_assignment(s), {1: "werwolf"}, "Abbruch erhält die Zuordnung")
	_ok(s.call("set_distribution_mode", &"random", true), "bestätigter Moduswechsel")
	assert_true(str(_dist(s)["mode"]) == "random" and _assignment(s).is_empty(), "Zuordnung kontrolliert verworfen")
	s.call("distribute_randomly")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("assign_role", 1, &"werwolf"), "wrong_mode", "manuell zuweisen im Zufallsmodus", before)
	_rejected(s, s.call("set_distribution_mode", &"manual"), "confirmation_required", "zufällige Zuordnung nicht unbemerkt überschreiben", before)


# --- Trugbilderwolf (65 bis 71) ---------------------------------------------------------------------------

## DR-08: Jede Trugbilderwolf-Person trägt genau die ausdrücklich gewählte Scheinrolle ihrer Kopie.
func _check_appearances(s: Object, chosen: Array, label: String) -> void:
	var a := _assignment(s)
	var app := _appearances(s)
	var shown: Array = []
	for person: Variant in a:
		if str(a[person]) == "trugbilderwolf":
			shown.append(str(app.get(person, "")))
		else:
			assert_false(app.has(person), "%s: andere Rollen ohne Scheinrolle" % label)
	shown.sort()
	var expected := chosen.duplicate()
	expected.sort()
	assert_eq(shown, expected, "%s: genau die gewählten Scheinrollen" % label)


func test_decoy_wolf_appearances() -> void:
	# Angepasst an DR-08: früher zufällig aus dem Seed abgeleitet, jetzt ausdrücklich gewählt.
	var counts := {"trugbilderwolf": 3, "manipulator": 1, "dorfbewohner": 6}
	var chosen := ["lehrling", "waldhexe", "waldhexe"]
	var s := _ready_setup(10, counts, FIXED_SEED, [0], chosen)
	if s == null:
		return
	s.call("distribute_randomly")
	_check_appearances(s, chosen, "zufällig")
	var app := _appearances(s)
	var twin := _ready_setup(10, counts, FIXED_SEED, [0], chosen)
	twin.call("distribute_randomly")
	assert_eq(_appearances(twin), app, "gleicher Seed, gleiche Einträge: gleiche Scheinrollen je Person")
	s.call("rename_person", _ids(s)[0], "Umbenannt")
	assert_eq(_appearances(s), app, "Namensänderung erhält die Scheinrolle")
	s.call("reshuffle")
	_check_appearances(s, chosen, "neu gemischt")
	var manual := _ready_setup(10, counts, FIXED_SEED, [0], chosen)
	manual.call("set_distribution_mode", &"manual")
	var entries: Array = (manual.call("view") as Dictionary)["roles"]["entries"]
	var ids := _ids(manual)
	for i: int in ids.size():
		manual.call("assign_role", ids[i], StringName(str((entries[i] as Dictionary)["key"])))
	_check_appearances(manual, chosen, "manuell")
