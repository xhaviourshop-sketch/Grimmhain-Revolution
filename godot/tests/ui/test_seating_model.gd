extends UiTestCase
## Setup-Sitzordnung: Modell und Anwendungsschicht ohne Szenen. Personen-ID ist Identität,
## der Sitzplatz nur Anordnung; Rolle, Name und Verteilung bleiben immer an der Person.

const SETUP_SCRIPT := "res://app/setup/player_setup.gd"
const FIXED_SEED := 515151


## Setup mit `count` Personen bis einschließlich bestätigter Zufallsverteilung.
func _to_seating(count: int = 8) -> Object:
	var script := load_script(SETUP_SCRIPT)
	if script == null:
		return null
	var s: Object = script.new()
	s.set("seed_source", func() -> int: return FIXED_SEED)
	for i: int in count:
		s.call("add_person", "Person %d" % (i + 1))
	s.call("confirm")
	s.call("apply_suggestion")
	for d: Variant in (s.call("view") as Dictionary)["roles"].get("decoys", []):
		s.call("set_decoy_appearance", int((d as Dictionary)["copy_id"]), &"waldhexe")
	s.call("confirm_roles")
	s.call("distribute_randomly")
	_ok(s.call("confirm_distribution"), "Vorbereitung: Verteilung bestätigt")
	return s


func _seating(s: Object) -> Dictionary:
	return (s.call("view") as Dictionary).get("seating", {}) as Dictionary


## Personen-IDs in Sitzreihenfolge (Platz 1 zuerst).
func _order(s: Object) -> Array[int]:
	var out: Array[int] = []
	for seat: Variant in _seating(s).get("seats", []):
		out.append(int((seat as Dictionary)["person_id"]))
	return out


## Rolle je Personen-ID aus der geheimen Verteilungssicht.
func _roles_by_person(s: Object) -> Dictionary:
	var out := {}
	for e: Variant in ((s.call("view") as Dictionary)["distribution"] as Dictionary)["assignment"]:
		out[int((e as Dictionary)["person_id"])] = [str((e as Dictionary)["role"]), str((e as Dictionary)["appearance"])]
	return out


func _names_by_person(s: Object) -> Dictionary:
	var out := {}
	for seat: Variant in _seating(s).get("seats", []):
		out[int((seat as Dictionary)["person_id"])] = str((seat as Dictionary)["name"])
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


# --- Identität beim Umordnen ----------------------------------------------------------------------------

func test_initial_order_follows_person_list() -> void:
	var s := _to_seating(8)
	if s == null:
		return
	var seating := _seating(s)
	assert_eq(_order(s), _ids(s), "Startreihenfolge = Reihenfolge der Spielerliste")
	var seats: Array = seating.get("seats", [])
	assert_eq(seats.size(), 8, "acht Plätze")
	for i: int in seats.size():
		assert_eq(int((seats[i] as Dictionary)["seat"]), i + 1, "Platznummer %d fortlaufend" % (i + 1))
	assert_eq(int(seating.get("person_count", 0)), 8, "Personenzahl in der Sicht")
	assert_false(bool(seating.get("confirmed", true)), "noch nicht bestätigt")


func test_swap_keeps_identity_role_and_name() -> void:
	var s := _to_seating(10)
	if s == null:
		return
	_ok(s.call("go_to_step", &"seating"), "zur Sitzordnung")
	var ids := _ids(s)
	var roles_before := _roles_by_person(s)
	var names_before := _names_by_person(s)
	var persons_before := JSON.stringify((s.call("view") as Dictionary)["persons"])
	var a := ids[1]
	var b := ids[7]
	_ok(s.call("swap_seats", a, b), "Plätze 2 und 8 tauschen")
	var order := _order(s)
	assert_eq(order[1], b, "Person von Platz 8 sitzt jetzt auf Platz 2")
	assert_eq(order[7], a, "Person von Platz 2 sitzt jetzt auf Platz 8")
	var sorted_order := order.duplicate()
	sorted_order.sort()
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()
	assert_eq(sorted_order, sorted_ids, "jede Personen-ID genau einmal, keine neue, keine verloren")
	assert_eq(_roles_by_person(s), roles_before, "Rolle und Scheinrolle bleiben an der Personen-ID")
	assert_eq(_names_by_person(s), names_before, "Name bleibt an der Personen-ID")
	assert_eq(JSON.stringify((s.call("view") as Dictionary)["persons"]), persons_before, "Spielerliste unverändert")
	assert_true(bool(((s.call("view") as Dictionary)["distribution"] as Dictionary)["confirmed"]), "Verteilung bleibt bestätigt")
	# Zurücktauschen stellt den Ausgangszustand exakt wieder her.
	_ok(s.call("swap_seats", b, a), "zurücktauschen")
	assert_eq(_order(s), ids, "Ausgangsreihenfolge wiederhergestellt")


func test_many_swaps_are_a_permutation() -> void:
	var s := _to_seating(24)
	if s == null:
		return
	var ids := _ids(s)
	var roles_before := _roles_by_person(s)
	for i: int in 23:
		_ok(s.call("swap_seats", _order(s)[i], _order(s)[i + 1]), "Nachbartausch %d" % (i + 1))
	var order := _order(s)
	assert_eq(order[23], ids[0], "Person 1 ist einmal im Kreis nach hinten gewandert")
	assert_eq(order.slice(0, 23), ids.slice(1, 24), "übrige Personen rücken nach")
	assert_eq(_roles_by_person(s), roles_before, "alle Rollen bleiben an ihren Personen")


func test_invalid_swaps_are_rejected_atomically() -> void:
	var s := _to_seating(8)
	if s == null:
		return
	var ids := _ids(s)
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("swap_seats", ids[0], 999), "unknown_person", "unbekannte Person", before)
	_rejected(s, s.call("swap_seats", -1, ids[0]), "unknown_person", "negative ID", before)
	_rejected(s, s.call("swap_seats", ids[2], ids[2]), "same_person", "Tausch mit sich selbst", before)
	s.call("remove_person", ids[3])
	var removed := ids[3]
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("swap_seats", removed, ids[0]), "players_not_confirmed", "vor erneuter Bestätigung", before)
	s.call("confirm")
	before = JSON.stringify(s.call("view"))
	# Sieben Personen, Pool für acht: der früheste offene Schritt sperrt (Rollen).
	_rejected(s, s.call("swap_seats", ids[0], ids[1]), "roles_not_confirmed", "vor erneut bestätigten Rollen", before)
	s.call("reshuffle")
	s.call("change_role_count", &"dorfbewohner", -1)
	s.call("confirm_roles")
	s.call("distribute_randomly")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("swap_seats", ids[0], ids[1]), "distribution_not_confirmed", "vor bestätigter Verteilung", before)


func test_seating_unreachable_before_distribution_confirmed() -> void:
	var script := load_script(SETUP_SCRIPT)
	if script == null:
		return
	var s: Object = script.new()
	s.set("seed_source", func() -> int: return FIXED_SEED)
	for i: int in 6:
		s.call("add_person", "P%d" % i)
	var before := JSON.stringify(s.call("view"))
	_rejected(s, s.call("go_to_step", &"seating"), "players_not_confirmed", "Sitzordnung ohne bestätigte Spieler", before)
	_rejected(s, s.call("confirm_seating"), "players_not_confirmed", "Bestätigen ohne bestätigte Spieler", before)
	s.call("confirm")
	s.call("apply_suggestion")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("go_to_step", &"seating"), "roles_not_confirmed", "Sitzordnung ohne bestätigte Rollen", before)
	s.call("confirm_roles")
	s.call("distribute_randomly")
	before = JSON.stringify(s.call("view"))
	_rejected(s, s.call("go_to_step", &"seating"), "distribution_not_confirmed", "Sitzordnung ohne bestätigte Verteilung", before)
	_ok(s.call("confirm_distribution"), "Verteilung bestätigen")
	_ok(s.call("go_to_step", &"seating"), "jetzt erreichbar")
	assert_eq(str((s.call("view") as Dictionary)["step"]), "seating", "Schritt Sitzordnung aktiv")
	var steps: Array = (s.call("view") as Dictionary)["steps"]
	assert_eq(steps.size(), 4, "vier Schritte")
	assert_eq(str((steps[3] as Dictionary)["id"]), "seating", "vierter Schritt ist die Sitzordnung")


# --- Bestätigen -----------------------------------------------------------------------------------------

func test_confirm_seating_keeps_complete_draft() -> void:
	var s := _to_seating(12)
	if s == null:
		return
	_ok(s.call("go_to_step", &"seating"), "zur Sitzordnung")
	var ids := _ids(s)
	s.call("swap_seats", ids[0], ids[5])
	var order := _order(s)
	var roles_before := _roles_by_person(s)
	assert_false(bool(_seating(s)["ready"]), "vor der Bestätigung nicht fertig")
	assert_true(bool(_seating(s)["can_confirm"]), "bestätigbar")
	_ok(s.call("confirm_seating"), "Sitzordnung bestätigen")
	var seating := _seating(s)
	assert_true(bool(seating["confirmed"]) and bool(seating["ready"]), "Sitzordnung fertig")
	assert_false(bool(seating["can_confirm"]), "nicht doppelt bestätigbar")
	assert_eq(_order(s), order, "Reihenfolge unverändert")
	assert_eq(_roles_by_person(s), roles_before, "Verteilung unverändert")
	var v := s.call("view") as Dictionary
	assert_true(bool(v["confirmed"]) and bool(v["roles"]["confirmed"]) and bool(v["distribution"]["confirmed"]), "alle Schritte bestätigt")
	assert_eq(str((v["steps"] as Array)[3]["state"]), "done", "Schritt Sitzordnung erledigt")
	var before := JSON.stringify(v)
	_ok(s.call("confirm_seating"), "erneut bestätigen ändert nichts")
	assert_eq(JSON.stringify(s.call("view")), before, "idempotent")
	_ok(s.call("swap_seats", ids[1], ids[2]), "Tausch nach Bestätigung")
	assert_false(bool(_seating(s)["confirmed"]), "Tausch hebt die Bestätigung auf")


# --- Änderungen an Personen und früheren Schritten -----------------------------------------------------

func test_person_changes_adjust_order() -> void:
	var s := _to_seating(8)
	if s == null:
		return
	var ids := _ids(s)
	s.call("go_to_step", &"seating")
	s.call("swap_seats", ids[0], ids[7])
	s.call("confirm_seating")
	var expected := _order(s)
	# Umbenennen: Reihenfolge bleibt, neuer Name erscheint am selben Platz.
	s.call("rename_person", ids[2], "Neuer Name")
	assert_eq(_order(s), expected, "Umbenennen ändert die Reihenfolge nicht")
	assert_eq(str(_names_by_person(s)[ids[2]]), "Neuer Name", "Name folgt der Personen-ID")
	assert_false(bool(_seating(s)["confirmed"]), "Umbenennen hebt Spielerbestätigung und damit Sitzbestätigung auf")
	assert_eq(str(_seating(s)["invalidated"]), "setup_changed", "Grund: früherer Schritt geändert")
	assert_eq(str((s.call("view") as Dictionary)["step"]), "players", "Wizard fällt auf erreichbaren Schritt zurück")
	# Entfernen: Person verschwindet aus der Reihenfolge, übrige behalten ihre relative Folge.
	s.call("remove_person", ids[4])
	expected.erase(ids[4])
	assert_eq(_order(s), expected, "entfernte Person fehlt, Rest unverändert geordnet")
	assert_eq(str(_seating(s)["invalidated"]), "person_count_changed", "Grund: Personenzahl geändert")
	# Hinzufügen: neue Person sitzt zunächst am Ende.
	var r: Object = s.call("add_person", "Nachzüglerin")
	var new_id := int((r.get("person_ids") as Array)[0]) if r != null and r.get("person_ids") != null else _ids(s)[-1]
	expected.append(new_id)
	assert_eq(_order(s), expected, "neue Person auf dem letzten Platz")
	assert_eq(_order(s).size(), 8, "wieder acht Plätze")


func test_earlier_step_changes_lift_confirmation_keep_order() -> void:
	var s := _to_seating(9)
	if s == null:
		return
	var ids := _ids(s)
	s.call("go_to_step", &"seating")
	s.call("swap_seats", ids[0], ids[3])
	s.call("confirm_seating")
	var order := _order(s)
	s.call("reshuffle")
	assert_false(bool(_seating(s)["confirmed"]), "Neu mischen hebt die Sitzbestätigung auf")
	assert_eq(str(_seating(s)["invalidated"]), "setup_changed", "Grund: früherer Schritt geändert")
	assert_eq(_order(s), order, "Reihenfolge bleibt beim Neu mischen")
	assert_eq(str((s.call("view") as Dictionary)["step"]), "distribution", "zurück in der Verteilung")
	s.call("confirm_distribution")
	_ok(s.call("go_to_step", &"seating"), "wieder erreichbar")
	assert_eq(_order(s), order, "Reihenfolge nach erneutem Öffnen erhalten")
	s.call("change_role_count", &"dorfbewohner", 1)
	assert_eq(_order(s), order, "Rollenänderung lässt die Reihenfolge stehen")


func test_navigation_back_and_reopen_keeps_order() -> void:
	var s := _to_seating(7)
	if s == null:
		return
	var ids := _ids(s)
	s.call("go_to_step", &"seating")
	s.call("swap_seats", ids[0], ids[6])
	s.call("confirm_seating")
	var before := JSON.stringify(_seating(s))
	_ok(s.call("go_to_step", &"distribution"), "zurück zur Verteilung")
	_ok(s.call("go_to_step", &"players"), "zurück zu Spielern")
	_ok(s.call("go_to_step", &"seating"), "wieder zur Sitzordnung")
	assert_eq(JSON.stringify(_seating(s)), before, "Navigation ändert weder Reihenfolge noch Bestätigung")


# --- Geheimhaltung ---------------------------------------------------------------------------------------

func test_seating_view_contains_no_roles() -> void:
	var s := _to_seating(18)
	if s == null:
		return
	var seating := _seating(s)
	for seat: Variant in seating.get("seats", []):
		var keys: Array = (seat as Dictionary).keys()
		keys.sort()
		assert_eq(keys, ["name", "person_id", "seat"], "Platz enthält nur Nummer, Personen-ID und Name")
	var text := JSON.stringify(seating)
	for role: Variant in ((s.call("view") as Dictionary)["roles"] as Dictionary)["counts"]:
		assert_false(text.contains("\"%s\"" % str(role)), "Sitzsicht nennt keine Rolle %s" % role)
	assert_false(text.contains("trugbilderwolf#"), "keine Kopien-Schlüssel")
