extends UiTestCase
## PE-04 (Decision Log „Produktentscheidungen nach Paket 4“, Matrix R-07, Analyse C-1 und C-3): nicht blockierende
## Besetzungshinweise im privaten Rollenschritt. Genau zwei Hinweise:
##   coach_small_round        Kutscher (direkte Wiederbelebungsrolle) bei weniger als 13 Personen.
##   simultaneous_solo_wins   mindestens zwei Kopien aus Parasit, Voodoo-Priester, Grabräuber, Manipulator
##                            (Einzelsieg bei höchstens drei Lebenden, Manipulator bei genau drei).
## Kein Dialog, keine Sperre, keine automatische Änderung, kein Feld im StartGame-Befehl.

const FIXED_SEED := 424242
const COACH := "coach_small_round"
const SOLO := "simultaneous_solo_wins"
const COACH_DE := "Hinweis: Der Kutscher kann erst wiederbeleben, wenn mindestens zehn Personen tot sind. Mit weniger als 13 Personen endet die Partie meist vorher. Die Runde wird trotzdem eine Wiederbelebungsrunde (Rollen bleiben beim Tod verdeckt). Starten bleibt möglich."
const COACH_EN := "Note: The Coachman can only revive once at least ten people are dead. With fewer than 13 people, the game usually ends before that. It still becomes a revival round (roles stay hidden on death). You can still start."
const SOLO_DE := "Hinweis: Mehrere Rollen dieser Besetzung gewinnen allein, wenn höchstens drei Personen leben (Parasit, Voodoo-Priester, Grabräuber; Manipulator bei genau drei). Dann können mehrere Siege zugleich erfüllt sein, die Spielleitung bestätigt genau einen. Starten bleibt möglich."
const SOLO_EN := "Note: Several roles in this setup win alone when at most three people are alive (Parasite, Voodoo Priest, Grave Robber; Manipulator at exactly three). Several wins can then be met at once, and the game master confirms exactly one. You can still start."


func _draft(counts: Dictionary) -> RolePoolDraft:
	var d := RolePoolDraft.new()
	for role: Variant in counts:
		d.counts[StringName(str(role))] = int(counts[role])
	return d


## Die Hinweisfunktion liest nur die Anzahlen; die Fälle unten mit mehr als einer Kopie (z. B. zwei Parasiten) sind bewusst
## isolierte Funktionsprüfungen ohne Gültigkeitsanspruch (beim Start ist jede Rolle höchstens einmal möglich, PE-07).
func _hints(counts: Dictionary, persons: int) -> Array:
	return _draft(counts).view(persons)["hints"]


# --- Auslösebedingungen ---------------------------------------------------------------------------------

func test_coach_hint_threshold_is_thirteen_persons() -> void:
	var pool := {"werwolf": 2, "manipulator": 1, "kutscher": 1}
	assert_eq(_hints(pool, 12), [COACH], "Kutscher bei 12 Personen: Hinweis")
	assert_eq(_hints(pool, 6), [COACH], "Kutscher bei 6 Personen: Hinweis")
	assert_eq(_hints(pool, 13), [], "Kutscher bei 13 Personen: kein Hinweis")
	assert_eq(_hints(pool, 24), [], "Kutscher bei 24 Personen: kein Hinweis")
	assert_eq(_hints({"werwolf": 2, "manipulator": 1, "wahnsinniger-kutscher": 1, "dr-victor-frankenstein": 1}, 8), [],
		"ohne Kutscher kein Kutscher-Hinweis (auch nicht für Wahnsinnigen Kutscher oder Frankenstein)")


func test_solo_hint_only_for_the_documented_overlap() -> void:
	assert_eq(_hints({"werwolf": 2, "parasit": 1, "voodoo-priester": 1}, 8), [SOLO], "Parasit und Voodoo-Priester")
	assert_eq(_hints({"werwolf": 2, "grabraeuber": 1, "manipulator": 1}, 8), [SOLO], "Grabräuber und Manipulator")
	assert_eq(_hints({"werwolf": 2, "parasit": 2}, 8), [SOLO], "zwei Parasiten")
	# Kontrollbesetzungen: mehrere Einzelsiegrollen ohne gemeinsame Drei-Lebende-Schwelle lösen nichts aus.
	assert_eq(_hints({"werwolf": 2, "parasit": 1}, 8), [], "eine Rolle der Gruppe")
	assert_eq(_hints({"werwolf": 2, "manipulator": 1, "feuerteufel": 1, "rattenfaenger": 1, "pestbringerin": 1}, 8), [],
		"mehrere andere Einzelsiege: kein pauschaler Fehlalarm")
	assert_eq(_hints({"werwolf": 2, "dorfbewohner": 5, "manipulator": 1}, 8), [], "Standardbesetzung")


func test_both_hints_together_and_validity_unchanged() -> void:
	# Gültige Besetzung für 9 Personen mit verschiedenen Rollen (PE-07): zwei Wolfsrollen, Kutscher, Parasit und Voodoo-Priester.
	var pool := {"werwolf": 1, "blutwolf": 1, "dorfbewohner": 1, "amalia": 1, "detektiv": 1, "wahnsinniger-kutscher": 1, "kutscher": 1, "parasit": 1, "voodoo-priester": 1}
	var view := _draft(pool).view(9)
	assert_eq(view["hints"], [COACH, SOLO], "beide Hinweise nebeneinander")
	assert_true(bool(view["valid"]), "Hinweise machen die Besetzung nicht ungültig")
	assert_eq(view["issues"], [], "keine zusätzlichen Fehler")


# --- Bedienweg --------------------------------------------------------------------------------------------

func _to_roles(shell: Control, count: int) -> Control:
	var screen := await open_new_game(shell)
	setup_of(shell).set("seed_source", func() -> int: return FIXED_SEED)
	await seed_names(shell, numbered_names(count))
	await press(find_button(screen, "ConfirmPlayersButton"))
	await press(find_button(screen, "ToRolesButton"))
	return screen


func _set_counts(shell: Control, counts: Dictionary) -> void:
	for role: Variant in counts:
		setup_of(shell).call("set_role_count", StringName(str(role)), int(counts[role]))
	await frames(2)


## 12 Personen mit Kutscher (PE-07: jede Rolle einmal): Werwolf, Blutwolf, Manipulator, Kutscher und acht wirkungsarme Dorfrollen.
func _cast12() -> Dictionary:
	var out := {"werwolf": 1, "blutwolf": 1, "manipulator": 1, "kutscher": 1}
	for role: String in Fixtures.village_fillers(8):
		out[role] = 1
	return out


func _label(screen: Node, node_name: String) -> Label:
	return find_node(screen, node_name) as Label


func _shown(screen: Node, node_name: String) -> bool:
	var label := _label(screen, node_name)
	return label != null and label.is_visible_in_tree() and label.text != ""


func test_role_step_updates_hints_immediately() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 12)
	assert_false(_shown(screen, "CoachHintLabel") or _shown(screen, "SoloWinsHintLabel"), "leere Besetzung: kein Hinweis")
	await _set_counts(shell, _cast12())
	assert_true(_shown(screen, "CoachHintLabel"), "Kutscher bei 12 Personen")
	assert_eq(_label(screen, "CoachHintLabel").text, COACH_DE, "Text DE")
	assert_false(_shown(screen, "SoloWinsHintLabel"), "ein Einzelsieg: kein Sieg-Hinweis")
	assert_false(find_button(screen, "ConfirmRolesButton").disabled, "Bestätigen bleibt möglich")
	await _set_counts(shell, {Fixtures.village_fillers(8)[7]: 0, "parasit": 1})  # eine Dorfrolle weniger, dafür der zweite Einzelsieg
	assert_true(_shown(screen, "CoachHintLabel") and _shown(screen, "SoloWinsHintLabel"), "beide Hinweise gleichzeitig")
	assert_eq(_label(screen, "SoloWinsHintLabel").text, SOLO_DE, "Text DE")
	assert_false(find_button(screen, "ConfirmRolesButton").disabled, "Bestätigen bleibt möglich")
	settings_of(shell).call("set_language", "en")
	await frames(2)
	assert_eq(_label(screen, "CoachHintLabel").text, COACH_EN, "Text EN")
	assert_eq(_label(screen, "SoloWinsHintLabel").text, SOLO_EN, "Text EN")
	settings_of(shell).call("set_language", "de")
	await frames(2)
	# Voraussetzungen entfernen: Hinweise verschwinden; die Besetzung wird nie automatisch geändert.
	await press(find_button(find_node(screen, "RoleRow_parasit"), "MinusButton"))
	assert_false(_shown(screen, "SoloWinsHintLabel"), "Parasit entfernt: Sieg-Hinweis weg")
	assert_true(_shown(screen, "CoachHintLabel"), "Kutscher-Hinweis bleibt")
	var nine := Fixtures.village_fillers(9)
	await _set_counts(shell, {"kutscher": 0, nine[7]: 1, nine[8]: 1})
	assert_false(_shown(screen, "CoachHintLabel"), "Kutscher entfernt: Hinweis weg")
	var counts: Dictionary = (setup_of(shell).call("view") as Dictionary)["roles"]["counts"]
	assert_eq([int(counts["werwolf"]), int(counts["blutwolf"]), int(counts["manipulator"]), int(counts[nine[8]])], [1, 1, 1, 1], "Besetzung nur wie ausdrücklich geändert")


func test_person_count_change_updates_coach_hint() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 12)
	await _set_counts(shell, _cast12())
	assert_true(_shown(screen, "CoachHintLabel"), "12 Personen: Hinweis")
	var s := setup_of(shell)
	s.call("go_to_step", &"players")
	s.call("add_person", "Person 13")
	s.call("confirm")
	s.call("go_to_step", &"roles")
	await frames(2)
	assert_eq(int((s.call("view") as Dictionary)["roles"]["persons"]), 13, "13 Personen")
	assert_false(_shown(screen, "CoachHintLabel"), "13 Personen: kein Kutscher-Hinweis")
	s.call("go_to_step", &"players")
	s.call("remove_person", int(((s.call("view") as Dictionary)["persons"] as Array)[12]["person_id"]))
	s.call("confirm")
	s.call("go_to_step", &"roles")
	await frames(2)
	assert_true(_shown(screen, "CoachHintLabel"), "wieder 12 Personen: Hinweis")


func test_start_game_with_hinted_setup_keeps_roles_and_assignments() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var screen := await _to_roles(shell, 8)
	await _set_counts(shell, {"werwolf": 1, "blutwolf": 1, "dorfbewohner": 1, "amalia": 1, "detektiv": 1, "kutscher": 1, "parasit": 1, "voodoo-priester": 1})
	assert_true(_shown(screen, "CoachHintLabel") and _shown(screen, "SoloWinsHintLabel"), "beide Hinweise vor dem Start")
	await press(find_button(screen, "ConfirmRolesButton"))
	await press(find_button(screen, "DistributeButton"))
	await press(find_button(screen, "ConfirmDistributionButton"))
	await press(find_button(screen, "ToSeatingButton"))
	await press(find_button(screen, "ConfirmSeatingButton"))
	await frames(2)
	var data: SetupResult = setup_of(shell).call("start_data")
	assert_true(data.ok, "Startdaten ohne Sperre")
	var start := find_button(screen, "StartGameButton")
	assert_true(start != null and start.is_visible_in_tree() and not start.disabled, "„Partie starten“ nicht gesperrt")
	await press(start)
	await frames(3)
	var session := session_of(shell) as GameSession
	assert_eq(String(current_id(shell)), "cockpit", "Cockpit geöffnet")
	var commands := session.commands()
	assert_eq(commands.size(), 1, "genau ein StartGame")
	var payload := commands[0].payload
	assert_eq(payload["roles"], data.details["roles"], "dieselben Rollen und Zuordnungen")
	assert_eq(payload["seat_order"], data.details["seat_order"], "dieselbe Sitzordnung")
	for key: Variant in payload:
		assert_false(str(key).contains("hint"), "kein Hinweisfeld im Befehl")
	for seat: Dictionary in session.private_seats():
		assert_eq(str(seat["role_id"]), str((data.details["roles"] as Dictionary)[str(seat["person_id"])]), "Rolle von %s" % seat["name"])
	assert_true(bool((session.cockpit_view() as Dictionary)["revival_round"]), "Wiederbelebungsrunde wie gewählt")
	# Private Hinweise erreichen keine Spieleransicht.
	var cockpit_text := ""
	for c: Control in text_controls(current_screen(shell)):
		cockpit_text += text_of(c) + "\n"
	assert_false(cockpit_text.contains("Hinweis: Der Kutscher") or cockpit_text.contains("Hinweis: Mehrere Rollen"), "Cockpit ohne Setup-Hinweise")
	assert_false(JSON.stringify(session.cockpit_view()).contains(COACH) or JSON.stringify(session.cockpit_view()).contains(SOLO), "öffentliche Sicht ohne Hinweise")
