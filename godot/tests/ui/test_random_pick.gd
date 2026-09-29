extends "res://tests/ui/role_ui_case.gd"
## Zufallsknopf (RM-DR-015.2, Matrix R-06) über echte Controls: „Zufällig auswählen“ erzeugt einen Vorschlag aus einer
## Kopie des gespeicherten Generators, erst „Auswahl bestätigen“ wendet die Fähigkeit an. Je Rolle geprüft:
##   Vorschlag im zulässigen Raum (aus den Rollenregeln, nicht aus der Produktionsfunktion), Vorschau ändert nichts,
##   wiederholter Vorschlag identisch (auch nach Laden), manuelles Antippen macht daraus eine eigene Wahl ohne Ziehung,
##   veraltete oder veränderte Bestätigung wird ohne Änderung abgelehnt, Doppeltippen bestätigt einmal mit genau einer
##   Ziehung, Speichern/Laden und Replay gleich, Rückgängig und erneute Bestätigung ergeben dasselbe Ergebnis, Abbrechen
##   erhält Generator und Fähigkeit, keine zusätzlichen öffentlichen oder Generatordaten in Ereignissen.
## Die manuelle Wahl ohne Zufall prüfen weiterhin test_role_buttons (traumdeuter, kopfgeldjaeger, koenig, blutpriester).

const W := "werwolf"
const D := "dorfbewohner"


## Rolle → [Rollen, Vorbereitungstote, Plan bis zur Auswahl, Stufe, Nutzungsschlüssel oder ""].
func _cases() -> Dictionary:
	return {
		"traumdeuter": [["traumdeuter", W, W, D, D, D, D], [], {}, "targets", ""],
		"kopfgeldjaeger": [["kopfgeldjaeger", W, W, D, D, D, D, D], [], {"day1": {"nominate": [4, 2], "execute": 2}}, "targets", ""],
		"koenig": [["koenig", W, "schutzengel", "dorfwache", D, D, D, D, D, D], [5, 6, 7, 8, 9, 10], {"schutzengel/": [1]}, "targets", "koenig:learn"],
		"blutpriester": [["blutpriester", W, W, D, D, D, D], [], {"blutpriester/targets": [4]}, "reveal", "blutpriester:sacrifice"],
	}


## Zulässiger Ergebnisraum laut Decision Log (I-01, I-03, I-06, I-08, I-13).
func _admissible(role: String, s: GameState, targets: Array) -> bool:
	var actor := s.pending_prompt.actor_id
	var distinct := targets.all(func(t: Variant) -> bool: return targets.count(t) == 1)
	var others := targets.all(func(t: Variant) -> bool: return int(t) != actor and s.players[int(t)].alive)
	match role:
		"traumdeuter", "kopfgeldjaeger":
			return targets.size() == 3 and distinct and others and targets.any(func(t: Variant) -> bool: return s.players[int(t)].counts_as_wolf)
		"koenig":
			return targets.size() == 1 and others and s.players[int(targets[0])].faction == Faction.VILLAGE
		"blutpriester":
			return targets.size() <= 3 and distinct and others and targets.all(func(t: Variant) -> bool: return s.players[int(t)].counts_as_wolf)
	return false


## Ein anderes zulässiges Ergebnis als `p` (für die manipulierte Bestätigung), sonst [].
func _other_admissible(role: String, s: GameState, p: Array) -> Array:
	var ids: Array = s.pending_prompt.allowed_ids.duplicate()
	var candidates: Array = []
	for a: int in ids.size():
		candidates.append([ids[a]])
		for b: int in range(a + 1, ids.size()):
			candidates.append([ids[a], ids[b]])
			for c: int in range(b + 1, ids.size()):
				candidates.append([ids[a], ids[b], ids[c]])
	candidates.append([])
	for q: Array in candidates:
		if _admissible(role, s, q) and not _same(q, p):
			return q
	return []


func selection() -> Array:
	return screen().get("_selection") as Array


func _same(a: Array, b: Array) -> bool:
	var x := a.duplicate()
	var y := b.duplicate()
	x.sort()
	y.sort()
	return x == y


func _check_role(role: String) -> void:
	var c: Array = _cases()[role]
	if not await start(c[0], c[1]):
		return
	assert_true(await run(c[2], until_prompt(role, c[3])), "%s: bis zur Auswahl" % role)
	var hash0 := session().state_hash()
	var draws0 := state().rng.draws
	var count0 := session().commands().size()
	# Vorschau: ändert nichts, identisch bei erneutem Drücken und nach Laden.
	await tap_button("RandomTargetsButton")
	var proposal: Array = selection().duplicate()
	assert_true(_admissible(role, state(), proposal), "%s: Vorschlag %s zulässig" % [role, proposal])
	assert_true(find_node(screen(), "RandomProposalLabel") != null, "%s: als Vorschlag gekennzeichnet" % role)
	assert_eq([session().state_hash(), session().commands().size()], [hash0, count0], "%s: Vorschau ändert keinen Zustand" % role)
	await tap_button("RandomTargetsButton")
	assert_true(_same(selection(), proposal), "%s: gleicher Vorschlag beim erneuten Drücken" % role)
	var loaded := GameSession.new()
	assert_eq(loaded.load_text(session().save_text()), &"", "%s: Laden" % role)
	assert_true(_same(loaded.random_proposal(), proposal), "%s: gleicher Vorschlag nach dem Laden" % role)
	# Veränderte Bestätigung: anderes zulässiges Ergebnis mit Zufallskennzeichen wird abgelehnt.
	var other := _other_admissible(role, state(), proposal)
	if not other.is_empty() or not proposal.is_empty():
		var r := session().answer_random(other)
		assert_eq(String(r.error), "random_mismatch", "%s: veränderte Bestätigung abgelehnt" % role)
		assert_eq(session().state_hash(), hash0, "%s: Ablehnung ohne Änderung" % role)
	# Manuelles Antippen nach dem Vorschlag: eigene Wahl, keine Ziehung.
	await tap_button("RandomTargetsButton")
	var allowed: Array = next()["allowed_ids"]
	await tap_seat(int(proposal[0]) if not proposal.is_empty() else int(allowed[0]))
	assert_true(find_node(screen(), "RandomProposalLabel") == null, "%s: nach Antippen kein Vorschlag mehr" % role)
	if live("ConfirmTargetsButton") != null and not selection().is_empty():
		var manual := session().check_targets(selection())
		if manual == &"":
			await tap_button("ConfirmTargetsButton")
			assert_false(bool(last_command().payload.get("random", false)), "%s: geänderte Auswahl wird als eigene Wahl gesendet" % role)
			assert_eq(state().rng.draws, draws0, "%s: eigene Wahl ohne Ziehung" % role)
			assert_true(session().undo(), "%s: eigene Wahl zurücknehmen" % role)
			await frames(2)
	# Bestätigung des Vorschlags über den Button, doppelt getippt.
	await tap_button("RandomTargetsButton")
	var b := live("ConfirmTargetsButton")
	assert_true(b != null, "%s: Bestätigen möglich" % role)
	if b == null:
		return
	b.pressed.emit()
	b.pressed.emit()
	await frames(3)
	assert_eq(session().commands().size(), count0 + 1, "%s: genau ein Befehl trotz Doppeltippen" % role)
	var cmd := last_command()
	assert_true(bool(cmd.payload.get("random", false)) and _same(cmd.payload["targets"], proposal), "%s: bestätigt wird der Vorschlag" % role)
	assert_eq(state().rng.draws, draws0 + 1, "%s: genau eine Ziehung übernommen" % role)
	var hash1 := session().state_hash()
	# Keine zusätzlichen öffentlichen oder Generatordaten in den Ereignissen des Befehls.
	for e: Dictionary in session().last_command_events():
		assert_ne(str(e["visibility"]), "public", "%s: %s nicht öffentlich" % [role, e["type"]])
		var text := JSON.stringify(e["data"])
		assert_false(text.contains("rng") or text.contains("random"), "%s: %s ohne Generatordaten" % [role, e["type"]])
	# Speichern/Laden und Replay.
	var reloaded := GameSession.new()
	assert_eq(reloaded.load_text(session().save_text()), &"", "%s: Laden nach Bestätigung" % role)
	assert_eq(reloaded.state_hash(), hash1, "%s: gleicher Stand nach Laden" % role)
	assert_eq(RulesEngine.replay(session().commands()).state.content_hash(), hash1, "%s: Replay gleich" % role)
	# Rückgängig und erneute Bestätigung über die Buttons ergeben dasselbe Ergebnis.
	assert_true(session().undo(), "%s: Rückgängig" % role)
	await frames(2)
	assert_eq(session().state_hash(), hash0, "%s: Stand vor der Bestätigung" % role)
	assert_true(selection().is_empty() and find_node(screen(), "RandomProposalLabel") == null, "%s: alter Vorschlag verworfen" % role)
	await tap_button("RandomTargetsButton")
	assert_true(_same(selection(), proposal), "%s: nach Rückgängig derselbe Vorschlag" % role)
	await tap_button("ConfirmTargetsButton")
	assert_eq(session().state_hash(), hash1, "%s: erneute Bestätigung reproduziert das Ergebnis" % role)
	# Abbrechen nach einem Vorschlag erhält Generator und Fähigkeit.
	assert_true(session().undo(), "%s: Rückgängig vor dem Abbrechen" % role)
	await frames(2)
	await tap_button("RandomTargetsButton")
	await tap_button("CancelPromptButton")
	await confirm_dialog()
	assert_eq(state().rng.draws, draws0, "%s: Abbrechen verbraucht keine Ziehung" % role)
	if str(c[4]) != "":
		assert_false(state().players[1].ability_uses.has(str(c[4])), "%s: Fähigkeit nicht verbraucht" % role)


func test_traumdeuter_random_pick() -> void:
	await _check_role("traumdeuter")


func test_kopfgeldjaeger_random_pick() -> void:
	await _check_role("kopfgeldjaeger")


func test_koenig_random_pick() -> void:
	await _check_role("koenig")


func test_blutpriester_random_pick() -> void:
	await _check_role("blutpriester")


## Unterstützte Rolle ohne zulässiges Zufallsergebnis: Knopf gesperrt mit Erklärung, Auslösen sendet nichts und zieht nicht,
## „Schritt abbrechen …“ bleibt bedienbar. Grenze: Im regulären Ablauf ist der Zustand nicht erreichbar (Traumdeuter und
## Kopfgeldjäger entfallen ohne mögliche Dreiergruppe mit Wolf, der König ohne Kandidaten, die Aufdeckung des Blutpriesters
## erlaubt immer „keiner“, eine Spielleiterkorrektur bricht den offenen Prompt ab). Deshalb setzt die Testvorbereitung bei
## offenem Traumdeuter-Prompt beide Wölfe im Sitzungszustand auf tot und die Auswahl auf die übrigen Lebenden. Der Zustand
## bleibt für den Regelkern gültig (InfoSteps.matches_state); die Regeln bleiben unverändert.
func test_disabled_random_button_without_admissible_result() -> void:
	if not await start(["traumdeuter", W, W, D, D, D, D]):
		return
	assert_true(await run({}, until_prompt("traumdeuter", "targets")), "Traumdeuter: Auswahl offen")
	var st := session()._state
	for wolf: int in [2, 3]:
		st.players[wolf].alive = false  # Testvorbereitung: keine Dreiergruppe mit Wolf mehr möglich
	st.pending_prompt.allowed_ids = [4, 5, 6, 7] as Array[int]  # wie InfoSteps: alle anderen Lebenden
	assert_true(GameState.from_dict(st.to_dict()) != null, "vorbereiteter Zustand ist für den Regelkern gültig")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	assert_true(bool(next()["random"]), "Rolle und Stufe unterstützen Zufall")
	assert_eq(session().random_proposal(), null, "kein zulässiges Zufallsergebnis")
	var random := find_button(screen(), "RandomTargetsButton")
	assert_true(random != null and random.is_visible_in_tree() and random.disabled, "Zufallsknopf sichtbar und gesperrt")
	var reason := find_node(screen(), "RandomUnavailableLabel") as Label
	assert_true(reason != null and reason.is_visible_in_tree(), "Erklärung sichtbar")
	assert_eq(reason.text if reason != null else "", "Zufällig auswählen ist hier nicht möglich: Es gibt keine zulässige Auswahl.", "verständliche Erklärung")
	var hash0 := session().state_hash()
	var count0 := session().commands().size()
	var draws0 := st.rng.draws
	await press(random)   # Signal wie Touch
	await click(random)   # Klick über den Viewport
	assert_eq([session().state_hash(), session().commands().size(), st.rng.draws], [hash0, count0, draws0], "kein Befehl, keine Ziehung")
	assert_true(selection().is_empty() and find_node(screen(), "RandomProposalLabel") == null, "kein Vorschlag übernommen")
	# Manuelle Bedienung bleibt erreichbar: Auswahl ohne Wolf wird mit Begründung gesperrt, Abbrechen ist möglich.
	for id: int in [4, 5, 6]:
		await tap_seat(id)
	assert_eq(selection().size(), 3, "Personen weiter antippbar")
	assert_true(find_button(screen(), "ConfirmTargetsButton").disabled, "Auswahl ohne Wolf nicht bestätigbar (I-01)")
	assert_true(find_node(screen(), "SelectionBlockedLabel") != null, "Sperrgrund der manuellen Auswahl sichtbar")
	assert_true(await tap_button("CancelPromptButton"), "Schritt abbrechen bedienbar")
	assert_true(await confirm_dialog(), "Abbruch mit Begründung")
	assert_eq(session().commands().size(), count0 + 1, "genau ein Befehl")
	assert_eq(String(last_command().type), String(Command.CANCEL_PROMPT), "Abbruch gesendet")
	assert_eq(session()._state.rng.draws, draws0, "Abbrechen ohne Ziehung")
	assert_eq(session()._state.pending_prompt, null, "Prompt geschlossen")


## Andere Rollen und die Opferwahl des Blutpriesters haben keinen Zufallsknopf.
func test_no_random_button_for_other_selections() -> void:
	if not await start(["blutpriester", "schutzengel", W, D, D, D, D]):
		return
	assert_true(await run({}, until_prompt("schutzengel")), "Schutzengel")
	assert_true(live("RandomTargetsButton") == null and find_node(screen(), "RandomTargetsButton") == null, "Schutzengel ohne Zufallsknopf")
	assert_true(await run({"schutzengel/": [4]}, until_prompt("blutpriester", "targets")), "Opferwahl")
	assert_true(find_node(screen(), "RandomTargetsButton") == null, "Opferwahl des Blutpriesters ohne Zufallsknopf")
