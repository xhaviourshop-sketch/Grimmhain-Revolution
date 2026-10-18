extends UiTestCase
## Knopf „Rollen“/„Namen“ im Cockpit: in Nacht und Tag sichtbar, schaltet alle Schilder im Sitzkreis zwischen Spielername und wahrer
## Rolle um, „Verbergen“ zeigt nur Namen, die Wahl gilt je Partie (im Spielstand gespeichert, eine neue Partie startet mit Namen).

const UiGame := preload("res://tests/ui/ui_game.gd")
const COUNT := 8


func _start(s: Object, round_id: String) -> void:
	var roles := {}
	var list := Fixtures.unique_roles(COUNT)
	for i: int in list.size():
		roles[str(i + 1)] = list[i]
	var r: CommandResult = s.call("submit", Command.start_game({"round_id": round_id, "seed": 1, "assignment": "manual",
		"players": Fixtures.players(COUNT), "seat_order": Fixtures.identity_order(COUNT), "roles": roles}))
	assert_true(r.ok, "Partie %s gestartet (%s)" % [round_id, r.error])


## Schildtexte je Person.
func _plates(screen: Control) -> Dictionary:
	var out := {}
	for t: Variant in (find_node(screen, "SeatRing") as Object).call("tokens"):
		out[int((t as Control).get("person_id"))] = (t as Control).tooltip_text
	return out


func _role_names(s: Object) -> Dictionary:
	var out := {}
	for p: Dictionary in s.call("private_seats"):
		out[int(p["person_id"])] = tr(CockpitText.role_name(str(p["role_id"])))
	return out


func _name_of(s: Object) -> Dictionary:
	var out := {}
	for p: Dictionary in s.call("private_seats"):
		out[int(p["person_id"])] = str(p["name"])
	return out


func test_button_in_night_and_day_switches_every_plate() -> void:
	var shell := await spawn_shell(SIZE_4_3, "de")
	if shell == null:
		return
	var s := session_of(shell)
	_start(s, "labels-1")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	s.call("start_night")
	await frames(3)
	var screen := current_screen(shell)
	var button := find_button(screen, "SeatLabelButton")
	assert_true(button.is_visible_in_tree() and not button.disabled, "Knopf in der Nacht sichtbar")
	assert_eq(button.text, tr("ui.cockpit.seat_labels.roles"), "Standard: Namen, der Knopf bietet Rollen an")
	assert_eq(_plates(screen), _name_of(s), "Schilder zeigen Namen")
	await press(button)
	assert_eq(_plates(screen), _role_names(s), "Schilder zeigen die wahren Rollen")
	assert_eq(button.text, tr("ui.cockpit.seat_labels.names"), "Knopf bietet Namen an")
	var ctx := context_of(shell)
	ctx.set("role_labels", false)
	assert_true(bool((ctx.call("resume", "labels-1") as Dictionary)["ok"]), "Partie fortgesetzt")
	assert_true(bool(ctx.get("role_labels")), "Wahl im Spielstand gemerkt")
	assert_true(UiGame.to_day(s as GameSession), "Nacht bis zum Tag gespielt")
	await frames(3)
	assert_eq(str((s.call("view") as Dictionary)["phase"]), "DAY", "Tag erreicht")
	assert_true(button.is_visible_in_tree() and not button.disabled, "Knopf am Tag sichtbar")
	assert_eq(_plates(screen), _role_names(s), "Rollen bleiben am Tag")
	var hide := find_button(screen, "HideButton")
	await press(hide)
	assert_eq(_plates(screen), _name_of(s), "Verbergen zeigt nur Namen")
	assert_true(button.disabled, "Knopf ruht beim Verbergen")
	await press(hide)
	assert_eq(_plates(screen), _role_names(s), "nach dem Verbergen wieder Rollen")
	await press(button)
	assert_eq(_plates(screen), _name_of(s), "zurück auf Namen")
	await press(button)
	s.call("reset")
	_start(s, "labels-2")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	await frames(2)
	screen = current_screen(shell)
	assert_eq(_plates(screen), _name_of(s), "neue Partie startet mit Namen")
	assert_eq(find_button(screen, "SeatLabelButton").text, tr("ui.cockpit.seat_labels.roles"), "Knopf bietet wieder Rollen an")
