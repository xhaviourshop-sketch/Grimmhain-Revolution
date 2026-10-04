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


## Bis zum Prompt von `owner`: Pflichtwahlen mit fester Anzahl werden angetippt (sofort übernommen), Ja/Nein und Hinweise per Knopf.
## Ein Schritt mit Vorschau gilt als offener Prompt (`effective_of`).
func _advance_to(shell: Control, owner: String) -> bool:
	await press(find_button(_screen(shell), "StartNightButton"))
	for guard: int in 30:
		var next := effective_of(_next(shell))
		if str(next.get("kind")) == "prompt" and str(next.get("owner")) == owner:
			return true
		if str(next.get("kind")) == "prompt" and str(next.get("answer")) == "targets" and CockpitText.auto_commit(next):
			for id: Variant in (next["allowed_ids"] as Array).slice(0, int(next["max"])):
				await _tap_seat(shell, int(id))
			continue
		var pressed := false
		for name: String in ["DeclineButton", "AckButton", "NoButton", "ShowCardButton"]:
			var b := find_node(_screen(shell), name) as BaseButton
			if b != null and b.is_visible_in_tree() and not b.disabled:
				await press(b)
				if name == "ShowCardButton":
					await press(find_button(find_node(_screen(shell), "NoticeLayer"), "CloseLayerButton"))
				pressed = true
				break
		if not pressed:
			fail("kein Weg zu %s: %s" % [owner, JSON.stringify(next).left(300)])
			return false
	fail("%s nicht erreicht" % owner)
	return false


## Gemeinsamer Ablauf bei fester Anzahl: Regelkern nennt die Anzahlen, Verzicht nur wo erlaubt, eine Teilauswahl
## sendet nichts und es gibt kein Bestätigen; mit der letzten Person wird sofort genau eine Auswahl gesendet.
## `art_button`: Loki wählt zuerst die Art der Bindung (Ja/Nein), dann die zwei Personen.
func _partial_then_full(shell: Control, owner: String, counts: Array, decline: bool, partial: Array, rest: Array, art_button: String = "") -> bool:
	if not await _advance_to(shell, owner):
		return false
	await _begin_open_step(shell)
	if art_button != "":
		await press(find_button(_screen(shell), art_button))
	assert_eq(_next(shell)["counts"], counts, "%s: zulässige Anzahlen aus dem Regelkern" % owner)
	assert_eq(find_node(_screen(shell), "DeclineButton") != null, decline, "%s: Verzicht nur wo erlaubt" % owner)
	assert_true(find_node(_screen(shell), "ConfirmTargetsButton") == null, "%s: feste Anzahl ohne Bestätigen" % owner)
	var before := _command_count(shell)
	for id: int in partial:
		await _tap_seat(shell, id)
	assert_eq(_command_count(shell), before, "%s: Teilauswahl sendet nichts" % owner)
	for id: int in rest:
		await _tap_seat(shell, id)
	var sent: Array = []
	for c: Command in (session_of(shell).call("commands") as Array).slice(before):
		if c.payload.has("targets"):
			sent = c.payload["targets"]
	sent.sort()
	var expected := partial + rest
	expected.sort()
	assert_eq(sent, expected, "%s: Auswahl sofort gesendet" % owner)
	return true


## Beginnt einen angekündigten Schritt per Kernbefehl, damit die Befehlszahl vor dem Antippen feststeht.
func _begin_open_step(shell: Control) -> void:
	if str(_next(shell).get("kind")) == "begin_step":
		assert_true(session_of(shell).call("begin_next_step").ok, "Schritt begonnen")
		await frames(2)


func _role_of(shell: Control, person_id: int) -> String:
	for seat: Dictionary in session_of(shell).call("private_seats"):
		if int(seat["person_id"]) == person_id:
			return str(seat["role_id"])
	return ""


func test_loki_needs_none_or_two() -> void:
	var shell := await _cockpit([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null or not await _partial_then_full(shell, "loki", [2], false, [3], [4], "YesButton"):
		return
	var bound := (session_of(shell).call("event_log") as Array).filter(func(e: Dictionary) -> bool: return str(e["type"]) == "LokiBound")
	assert_eq(bound.size(), 1, "Loki: Bindung geschlossen")


func test_soul_swapper_needs_none_or_two() -> void:
	var shell := await _cockpit([W, "seelentauscher", "ritter", D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	if shell == null or not await _partial_then_full(shell, "seelentauscher", [0, 2], true, [3], [4]):
		return
	assert_eq([_role_of(shell, 3), _role_of(shell, 4)], [D, "ritter"], "Seelentauscher: Rollen von 3 und 4 getauscht")


func test_coachman_needs_none_or_three() -> void:
	var shell := await _cockpit([W, "kutscher", D, "amalia"] + Fixtures.extra_village(10) + ["detektiv", "wahnsinniger-kutscher"], [5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
	if shell == null or not await _partial_then_full(shell, "kutscher", [0, 3], true, [5, 6], [7]):
		return
	var next := _next(shell)
	assert_eq([str(next["owner"]), str(next["stage"]), next["allowed_ids"]], ["kutscher", "wolf", [5, 6, 7]], "Kutscher: Wolfswahl unter den dreien")


func test_hound_needs_none_or_three() -> void:
	var shell := await _cockpit([W, "spuerhund", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null or not await _partial_then_full(shell, "spuerhund", [3], false, [1, 3], [4]):
		return
	var next := _next(shell)
	assert_eq([str(next["owner"]), str(next["stage"])], ["spuerhund", "shown"], "Spürhund: Ergebnis zeigen")
	var hit := (next["show"] as Array).filter(func(l: Dictionary) -> bool: return str(l["key"]) == "hit")
	assert_eq(hit.map(func(l: Dictionary) -> bool: return bool(l["value"])), [true], "Spürhund: Wolf 1 unter den dreien")


## Mehr als die Höchstzahl lässt der Sitzkreis nicht zu.
func test_selection_beyond_maximum_is_refused() -> void:
	var shell := await _cockpit([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null or not await _advance_to(shell, "loki"):
		return
	await press(find_button(_screen(shell), "YesButton"))
	var before := _command_count(shell)
	for id: int in [3, 4, 5]:
		await _tap_seat(shell, id)
	var sent: Array = []
	for c: Command in (session_of(shell).call("commands") as Array).slice(before):
		if c.payload.has("targets"):
			sent.append(c.payload["targets"])
	assert_eq(sent, [[3, 4]], "genau zwei übernommen, die dritte Person nicht")


## Loki fragt zuerst nach der Art; die Taste fehlt, wenn die Art schon gewählt ist.
func _choose_art(shell: Control) -> void:
	var yes := find_node(_screen(shell), "YesButton") as BaseButton
	if yes != null and yes.is_visible_in_tree():
		await press(yes)


## Ein Antippen allein darf nichts senden, wenn keine alte Auswahl mehr besteht (sonst wären es schon zwei).
func _assert_selection_empty(shell: Control, id: int, msg: String) -> void:
	var before := _command_count(shell)
	await _tap_seat(shell, id)
	assert_eq(_command_count(shell), before, msg)
	await _tap_seat(shell, id)


## Ändert sich der Zustand (Laden, Spielleiterkorrektur, Rückgängig/Wiederholen), verfällt die Auswahl,
## auch wenn danach derselbe Prompt offen ist.
func test_state_change_discards_selection() -> void:
	var shell := await _cockpit([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	if shell == null or not await _advance_to(shell, "loki"):
		return
	var session := session_of(shell)
	await _choose_art(shell)  # Loki: erst die Art, dann die Personen
	var prompt_id := int(_next(shell)["prompt_id"])
	# Laden desselben Stands: gleicher Prompt, Auswahl trotzdem verworfen.
	await _tap_seat(shell, 3)
	assert_eq(String(session.call("load_text", session.call("save_text"))), "", "Stand geladen")
	await frames(3)
	assert_eq([str(_next(shell)["owner"]), int(_next(shell)["prompt_id"])], ["loki", prompt_id], "derselbe Prompt offen")
	await _choose_art(shell)
	await _assert_selection_empty(shell, 4, "Auswahl nach Laden verworfen")
	# Korrektur während des Prompts: Der Regelkern kündigt den Schritt neu an; die Auswahl gilt nicht weiter.
	await _tap_seat(shell, 3)
	var r: CommandResult = session.call("submit", CorrectionFixtures.gm("kill", {"target_id": 6, "trigger_effects": false}, "Tisch"))
	assert_true(r.ok, "Korrektur angenommen (%s)" % r.error)
	await frames(3)
	assert_eq(str(_next(shell)["kind"]), "begin_step", "Schritt neu angekündigt")
	await _begin_open_step(shell)
	await _choose_art(shell)
	assert_eq(str(_next(shell)["owner"]), "loki", "Loki erneut offen")
	await _assert_selection_empty(shell, 4, "Auswahl nach Korrektur verworfen")
	assert_false(_next(shell)["allowed_ids"].has(6), "Getötete Person nicht mehr wählbar")
	# Rückgängig und Wiederholen stellen den Prompt wieder her, nicht die alte Auswahl.
	await _tap_seat(shell, 4)
	assert_true(session.call("undo"), "Rückgängig")
	await frames(3)
	assert_true(session.call("redo"), "Wiederholen")
	await frames(3)
	assert_eq(str(_next(shell)["owner"]), "loki", "Loki nach Wiederholen offen")
	await _choose_art(shell)
	await _assert_selection_empty(shell, 3, "Auswahl nach Rückgängig/Wiederholen verworfen")
