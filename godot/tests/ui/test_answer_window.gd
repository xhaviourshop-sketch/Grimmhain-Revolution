extends UiTestCase
## Antwortschritte: alle Antworten stehen als zentrierte Reihe gleich hoher Knöpfe im Fenster; im Dock bleibt nur „Rückgängig“ (genau einmal).

const ROLES := ["werwolf", "trugbilderwolf", "schutzengel", "waldhexe", "das-orakel", "sensentraeger", "kutscher"]
const SEATS: Array[int] = [3, 1, 4, 7, 2, 6, 5]


func _witch_step(size: Vector2i) -> Control:
	var map := {}
	for i: int in ROLES.size():
		map[str(i + 1)] = ROLES[i]
	var shell := await spawn_shell(size)
	var start := Command.start_game({"round_id": "t", "seed": 11, "assignment": "manual", "players": Fixtures.players(ROLES.size()), "seat_order": SEATS, "roles": map,
		"appearances": {"2": "dorfbewohner"}})
	assert_true((session_of(shell).call("submit", start) as CommandResult).ok, "Partie gestartet")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	var screen := current_screen(shell)
	await press(find_button(screen, "StartNightButton"))
	var ring := find_node(screen, "SeatRing")
	for seat: int in [7, 6]:
		await press(ring.call("token_for", seat) as BaseButton)
	return shell


func _check_window(shell: Control, label: String) -> void:
	var screen := current_screen(shell)
	var box := find_node(screen, "Actions") as Control
	var yes := find_button(screen, "YesButton")
	var no := find_button(screen, "NoButton")
	assert_true(yes != null and no != null, "%s: beide Antworten da" % label)
	if yes == null or no == null:
		return
	assert_true(box.is_ancestor_of(yes) and box.is_ancestor_of(no), "%s: beide Antworten im Fenster" % label)
	assert_eq(yes.size.y, no.size.y, "%s: gleich hoch" % label)
	assert_true(yes.size.y >= 44.0, "%s: mindestens 44 hoch" % label)
	var inner := box.get_global_rect()
	for b: BaseButton in [yes, no]:
		var r := b.get_global_rect()
		assert_true(r.position.x >= inner.position.x - 1.0 and r.end.x <= inner.end.x + 1.0, "%s: Knopf %s liegt im Fenster" % [label, b.name])
	var left := minf(yes.get_global_rect().position.x, no.get_global_rect().position.x) - inner.position.x
	var right := inner.end.x - maxf(yes.get_global_rect().end.x, no.get_global_rect().end.x)
	assert_true(absf(left - right) <= 40.0, "%s: Reihe ist mittig (%.0f / %.0f)" % [label, left, right])
	var dock := find_node(screen, "NextHost") as Control
	assert_eq(dock.find_children("*", "BaseButton", true, false).size(), 0, "%s: im Dock keine Hauptaktion" % label)
	var undo_visible := 0
	for name: String in ["DockUndoButton", "UndoBarButton"]:
		var u := find_node(screen, name) as Control
		if u != null and u.is_visible_in_tree():
			undo_visible += 1
	assert_true(undo_visible <= 1, "%s: Rückgängig höchstens einmal" % label)


func test_witch_answers_sit_in_the_window() -> void:
	var shell := await _witch_step(SIZE_16_10)
	if shell != null:
		_check_window(shell, "Tablet")


func test_witch_answers_fit_a_phone_width() -> void:
	var shell := await _witch_step(Vector2i(412, 915))
	if shell != null:
		_check_window(shell, "412")
