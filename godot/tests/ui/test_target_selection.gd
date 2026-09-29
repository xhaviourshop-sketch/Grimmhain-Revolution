extends UiTestCase
## Personenauswahl der Aktionskarte bei Regeln, die min/max allein nicht ausdrücken (Loki,
## Seelentauscher, Kutscher: keiner oder alle; Spürhund: keiner oder genau drei). Nur über Sitzplätze
## und Buttons der Karte: Die Karte nennt die zulässige Anzahl aus dem Regelkern, lässt eine
## Teilauswahl nicht bestätigen und erklärt warum, bestätigt die vollständige Auswahl mit dem
## erwarteten Ergebnis und verwirft eine Auswahl, wenn sich der Zustand ändert.

const D := "dorfbewohner"
const W := "werwolf"


func _cockpit(roles: Array, kills: Array = []) -> Control:
	var shell := await spawn_shell()
	if shell == null:
		return null
	var session := session_of(shell)
	var r: CommandResult = session.call("submit", Fixtures.start_roles(roles, 1))
	assert_true(r.ok, "Partie gestartet (%s)" % r.error)
	for id: int in kills:
		r = session.call("submit", CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false}, "Vorbereitung"))
		assert_true(r.ok, "%d tot (%s)" % [id, r.error])
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _screen(shell: Control) -> Control:
	return current_screen(shell)


func _next(shell: Control) -> Dictionary:
	return (session_of(shell).call("cockpit_view") as Dictionary).get("next", {})


func _command_count(shell: Control) -> int:
	return (session_of(shell).call("commands") as Array).size()


func _tap_seat(shell: Control, person_id: int) -> void:
	await press(find_node(_screen(shell), "SeatRing").call("token_for", person_id) as BaseButton)


func _confirm(shell: Control) -> BaseButton:
	return find_button(_screen(shell), "ConfirmTargetsButton")


func _label_key(shell: Control, node_name: String) -> String:
	var label := find_node(_screen(shell), node_name) as Control
	return key_of(label) if label != null and label.is_visible_in_tree() else ""


func _label_text(shell: Control, node_name: String) -> String:
	var label := find_node(_screen(shell), node_name) as Control
	return text_of(label) if label != null and label.is_visible_in_tree() else ""


## Über Buttons bis zum Prompt von `owner`: Schritte beginnen, andere Prompts ohne Wirkung beenden.
func _advance_to(shell: Control, owner: String) -> bool:
	await press(find_button(_screen(shell), "StartNightButton"))
	for guard: int in 30:
		var next := _next(shell)
		if str(next.get("kind")) == "prompt" and str(next.get("owner")) == owner:
			return true
		var pressed := false
		for name: String in ["BeginStepButton", "DeclineButton", "AckButton", "NoButton"]:
			var b := find_node(_screen(shell), name) as BaseButton
			if b != null and b.is_visible_in_tree() and not b.disabled:
				await press(b)
				pressed = true
				break
		if not pressed:
			fail("kein Weg zu %s: %s" % [owner, JSON.stringify(next)])
			return false
	fail("%s nicht erreicht" % owner)
	return false


## Gemeinsamer Ablauf: Regelzeile, Teilauswahl gesperrt und erklärt, Tippen auf die gesperrte
## Bestätigung sendet nichts, vollständige Auswahl freigegeben. Liefert false bei Abbruch.
func _partial_then_full(shell: Control, owner: String, counts_text: Array[String], partial: Array, rest: Array) -> bool:
	if not await _advance_to(shell, owner):
		return false
	assert_eq(_next(shell)["counts"], [0, partial.size() + rest.size()], "%s: zulässige Anzahlen aus dem Regelkern" % owner)
	var rule := _label_text(shell, "SelectionRuleLabel")
	for part: String in counts_text:
		assert_true(rule.contains(part), "%s: Regelzeile nennt %s („%s“)" % [owner, part, rule])
	assert_true(find_node(_screen(shell), "DeclineButton") != null, "%s: Verzicht angeboten" % owner)
	assert_true(_confirm(shell).disabled, "%s: ohne Auswahl gesperrt" % owner)
	for id: int in partial:
		await _tap_seat(shell, id)
	assert_true(_confirm(shell).disabled, "%s: Teilauswahl gesperrt" % owner)
	assert_eq(_label_key(shell, "SelectionBlockedLabel"), "ui.cockpit.card.selection.blocked.invalid_target_count", "%s: Erklärung der Sperre" % owner)
	var before := _command_count(shell)
	await press(_confirm(shell))
	assert_eq(_command_count(shell), before, "%s: gesperrte Bestätigung sendet nichts" % owner)
	assert_eq(_label_key(shell, "ErrorLabel"), "", "%s: kein Ablehnungsfehler" % owner)
	for id: int in rest:
		await _tap_seat(shell, id)
	assert_false(_confirm(shell).disabled, "%s: vollständige Auswahl freigegeben" % owner)
	assert_eq(_label_key(shell, "SelectionBlockedLabel"), "", "%s: keine Sperrerklärung mehr" % owner)
	await press(_confirm(shell))
	assert_eq(_command_count(shell), before + 1, "%s: genau ein Befehl angenommen" % owner)
	var last: Command = (session_of(shell).call("commands") as Array).back()
	var sent: Array = last.payload["targets"]
	sent.sort()
	var expected := partial + rest
	expected.sort()
	assert_eq(sent, expected, "%s: gesendete Auswahl" % owner)
	return true


func _role_of(shell: Control, person_id: int) -> String:
	for seat: Dictionary in session_of(shell).call("private_seats"):
		if int(seat["person_id"]) == person_id:
			return str(seat["role_id"])
	return ""


func test_loki_needs_none_or_two() -> void:
	var shell := await _cockpit([W, "loki", D, D, D, D, D])
	if shell == null or not await _partial_then_full(shell, "loki", ["0", "2"], [3], [4]):
		return
	var next := _next(shell)
	assert_eq([str(next["owner"]), str(next["stage"])], ["loki", "mode"], "Loki: weiter zur Art der Bindung")


func test_soul_swapper_needs_none_or_two() -> void:
	var shell := await _cockpit([W, "seelentauscher", "ritter", D, D, D, D])
	if shell == null or not await _partial_then_full(shell, "seelentauscher", ["0", "2"], [3], [4]):
		return
	assert_eq([_role_of(shell, 3), _role_of(shell, 4)], [D, "ritter"], "Seelentauscher: Rollen von 3 und 4 getauscht")


func test_coachman_needs_none_or_three() -> void:
	var shell := await _cockpit([W, "kutscher", D, D, D, D, D, D, D, D, D, D, D, D, D, D], [5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
	if shell == null or not await _partial_then_full(shell, "kutscher", ["0", "3"], [5, 6], [7]):
		return
	var next := _next(shell)
	assert_eq([str(next["owner"]), str(next["stage"]), next["allowed_ids"]], ["kutscher", "wolf", [5, 6, 7]], "Kutscher: Wolfswahl unter den dreien")


func test_hound_needs_none_or_three() -> void:
	var shell := await _cockpit([W, "spuerhund", D, D, D, D, D])
	if shell == null or not await _partial_then_full(shell, "spuerhund", ["0", "3"], [1, 3], [4]):
		return
	var next := _next(shell)
	assert_eq([str(next["owner"]), str(next["stage"])], ["spuerhund", "shown"], "Spürhund: Ergebnis zeigen")
	var hit := (next["show"] as Array).filter(func(l: Dictionary) -> bool: return str(l["key"]) == "hit")
	assert_eq(hit.map(func(l: Dictionary) -> bool: return bool(l["value"])), [true], "Spürhund: Wolf 1 unter den dreien")


## Mehr als die Höchstzahl lässt der Sitzkreis nicht zu.
func test_selection_beyond_maximum_is_refused() -> void:
	var shell := await _cockpit([W, "loki", D, D, D, D, D])
	if shell == null or not await _advance_to(shell, "loki"):
		return
	for id: int in [3, 4, 5]:
		await _tap_seat(shell, id)
	assert_true(_label_text(shell, "SelectionLabel").contains("C") and _label_text(shell, "SelectionLabel").contains("D"), "3 und 4 gewählt")
	assert_false(_label_text(shell, "SelectionLabel").contains("E"), "5 nicht gewählt")
	assert_false(_confirm(shell).disabled, "zwei bleiben bestätigbar")


## Ändert sich der Zustand (Laden, Spielleiterkorrektur, Rückgängig/Wiederholen), verfällt die Auswahl,
## auch wenn danach derselbe Prompt offen ist.
func test_state_change_discards_selection() -> void:
	var shell := await _cockpit([W, "loki", D, D, D, D, D])
	if shell == null or not await _advance_to(shell, "loki"):
		return
	var session := session_of(shell)
	var prompt_id := int(_next(shell)["prompt_id"])
	# Laden desselben Stands: gleicher Prompt, Auswahl trotzdem verworfen.
	await _tap_seat(shell, 3)
	assert_eq(_label_key(shell, "SelectionLabel"), "ui.cockpit.card.selection.some", "Auswahl vorhanden")
	assert_eq(String(session.call("load_text", session.call("save_text"))), "", "Stand geladen")
	await frames(3)
	assert_eq([str(_next(shell)["owner"]), int(_next(shell)["prompt_id"])], ["loki", prompt_id], "derselbe Prompt offen")
	assert_eq(_label_key(shell, "SelectionLabel"), "ui.cockpit.card.selection.none", "Auswahl nach Laden verworfen")
	# Korrektur während des Prompts: Der Regelkern kündigt den Schritt neu an; die Auswahl gilt nicht weiter.
	await _tap_seat(shell, 3)
	var r: CommandResult = session.call("submit", CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}, "Tisch"))
	assert_true(r.ok, "Korrektur angenommen (%s)" % r.error)
	await frames(3)
	assert_eq(str(_next(shell)["kind"]), "begin_step", "Schritt neu angekündigt")
	await press(find_button(_screen(shell), "BeginStepButton"))
	assert_eq(str(_next(shell)["owner"]), "loki", "Loki erneut offen")
	assert_eq(_label_key(shell, "SelectionLabel"), "ui.cockpit.card.selection.none", "Auswahl nach Korrektur verworfen")
	assert_false(_next(shell)["allowed_ids"].has(6), "Getötete Person nicht mehr wählbar")
	# Rückgängig und Wiederholen stellen den Prompt wieder her, nicht die alte Auswahl.
	await _tap_seat(shell, 4)
	assert_true(session.call("undo"), "Rückgängig")
	await frames(3)
	assert_true(session.call("redo"), "Wiederholen")
	await frames(3)
	assert_eq(str(_next(shell)["owner"]), "loki", "Loki nach Wiederholen offen")
	assert_eq(_label_key(shell, "SelectionLabel"), "ui.cockpit.card.selection.none", "Auswahl nach Rückgängig/Wiederholen verworfen")
