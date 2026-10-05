extends UiTestCase
## Spezialkorrekturen über „Spielleitung → Status ändern“: Schutz, Rettung, Trankstatus, Wolfskind und Lehrling. Die Oberfläche
## bietet nur an, was der Regelkern für die gewählte Person im aktuellen Zustand annimmt (Vorprüfung mit `RulesEngine.check`),
## zeigt Person und bisherigen Wert, verlangt Warnung und Begründung und sendet ausschließlich den vorhandenen Befehl
## `GmCorrection`. Abbrechen ändert nichts; eine veraltete Auswahl wird verworfen.

const UiGame := preload("res://tests/ui/ui_game.gd")
## 1, 2 Werwölfe; 3 Schutzengel; 4 Waldhexe; 5 Wolfskind; 6 Lehrling; 7 bis 9 Dorfbewohner.
const ROLES: Array = ["werwolf", "blutwolf", "schutzengel", "waldhexe", "wolfskind", "lehrling", "dorfbewohner", "amalia", "detektiv"]


## Cockpit mit Partie am Ende von Nacht 1 (alle Nachtschritte erledigt, EndNight noch offen).
func _night_shell() -> Control:
	var shell := await spawn_shell()
	if shell == null:
		return null
	var s := session_of(shell) as GameSession
	assert_true(s.submit(UiGame.start(ROLES, 7)).ok, "Start")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night", {"pack/": [7]}), "Nacht 1 bis zum Ende gespielt")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _state(shell: Control) -> GameState:
	return RulesEngine.replay((session_of(shell) as GameSession).commands()).state


func _dialog(shell: Control) -> Control:
	return shell.call("get_dialog") as Control


func _open_status(shell: Control, seat_id: int) -> void:
	var screen := current_screen(shell)
	if find_node(screen, "GmLayer") == null:
		await press(find_button(screen, "GmButton"))
	await press(find_button(screen, "GmKind_status"))
	await press(find_node(screen, "SeatRing").call("token_for", seat_id) as BaseButton)


func _confirm_with_reason(shell: Control, reason: String) -> void:
	var dialog := _dialog(shell)
	assert_true(dialog.call("is_open"), "Rückfrage mit Begründung")
	var confirm := find_node(dialog, "ConfirmButton") as BaseButton
	assert_true(confirm.disabled, "ohne Begründung gesperrt")
	await type_text(find_node(dialog, "InputField") as LineEdit, reason)
	await press(confirm)
	await frames(2)


## Korrektur über die Buttons: Person antippen, Feld wählen, bei Bedarf Ziel wählen, Begründung eingeben.
func _apply(shell: Control, seat_id: int, field: String, pick: int = -1, reason: String = "Korrektur am Tisch") -> void:
	await _open_status(shell, seat_id)
	await press(find_button(current_screen(shell), "GmField_%s" % field))
	if pick != -1:
		await press(find_button(_dialog(shell), "Pick_%d" % pick))
		await frames(2)
	await _confirm_with_reason(shell, reason)


func _fields(shell: Control, id: int) -> Array[String]:
	var out: Array[String] = []
	for f: Dictionary in (session_of(shell) as GameSession).status_fields(id):
		out.append(str(f["field"]))
	return out


func _texts(node: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(node):
		out.append(text_of(c))
	return "\n".join(out)


## Ganzes Wort (Namen sind hier ein einzelner Buchstabe; „contains“ träfe jeden Text).
func _has_word(text: String, word: String) -> bool:
	return RegEx.create_from_string("(^|[^\\p{L}])%s($|[^\\p{L}])" % word).search(text) != null


func _corrections(shell: Control) -> Array:
	return (session_of(shell) as GameSession).commands().filter(func(c: Command) -> bool: return c.type == Command.GM_CORRECTION)


# --- Erfolgsfälle pro Korrekturart -------------------------------------------------------------------------

func test_protection_set_and_remove() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(_fields(shell, 3).has("set_protection") and _fields(shell, 3).has("remove_protection"), "Schutzengel nach seinem Schritt: setzen und entfernen")
	await _apply(shell, 3, "set_protection", 8)
	assert_eq(Protections.of_guardian(_state(shell), 3).target_id, 8, "Person 8 ist geschützt")
	assert_eq(_corrections(shell).size(), 1, "genau eine Korrektur im Verlauf")
	var last: Dictionary = (s.event_log().filter(func(e: Dictionary) -> bool: return str(e["type"]) == "GmCorrected").back() as Dictionary)
	assert_eq(str((last["data"] as Dictionary)["reason"]), "Korrektur am Tisch", "Begründung protokolliert")
	assert_eq(int(((last["data"] as Dictionary)["new"] as Dictionary)["protected_id"]), 8, "neuer Wert protokolliert")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 3, "remove_protection")
	assert_true(Protections.of_guardian(_state(shell), 3) == null, "Schutz entfernt")
	assert_false(_fields(shell, 3).has("remove_protection"), "danach nicht mehr angeboten")


func test_rescue_set_and_remove() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	assert_true(_fields(shell, 4).has("set_rescue"), "Rettung setzbar (Rudelopfer lebt, Waldhexenschritt erledigt)")
	assert_false(_fields(shell, 4).has("remove_rescue"), "noch keine Rettung zu entfernen")
	await _apply(shell, 4, "set_rescue")
	assert_eq(WitchStep.action_of(_state(shell), 4).saved_id, 7, "Rudelopfer 7 gerettet")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 4, "remove_rescue")
	assert_eq(WitchStep.action_of(_state(shell), 4).saved_id, GameState.NO_TARGET, "Rettung entfernt")


func test_witch_potion_is_operable_in_both_directions() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	assert_true(_fields(shell, 4).has("potion_heal") and _fields(shell, 4).has("potion_poison"), "beide Tränke bedienbar")
	await _apply(shell, 4, "potion_poison")
	assert_false(WitchStep.potion_available(_state(shell).players[4], "poison"), "Gifttrank verbraucht")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 4, "potion_poison")
	assert_true(WitchStep.potion_available(_state(shell).players[4], "poison"), "Gifttrank wieder verfügbar")


func test_wolf_child_model_and_transformation_cycle() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var model_before := WolfChildRules.bond_of(_state(shell), 5).model_id
	assert_ne(model_before, GameState.NO_TARGET, "Vorbild aus Nacht 1")
	var offered := _fields(shell, 5)
	for kind: String in ["set_wolf_model", "remove_wolf_model", "transform_wolf_child"]:
		assert_true(offered.has(kind), "%s angeboten" % kind)
	assert_false(offered.has("revert_wolf_child"), "Rücknahme nur nach Verwandlung")
	await _apply(shell, 5, "set_wolf_model", 8)
	assert_eq(WolfChildRules.bond_of(_state(shell), 5).model_id, 8, "neues Vorbild")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 5, "transform_wolf_child")
	assert_true(WolfChildRules.bond_of(_state(shell), 5).transformed, "verwandelt")
	assert_true(_state(shell).players[5].counts_as_wolf, "zählt als Wolf")
	assert_false(_fields(shell, 5).has("transform_wolf_child"), "Verwandlung nicht doppelt angeboten")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 5, "revert_wolf_child")
	assert_false(WolfChildRules.bond_of(_state(shell), 5).transformed, "Verwandlung zurückgenommen")
	assert_eq(WolfChildRules.bond_of(_state(shell), 5).model_id, 8, "Vorbild bleibt")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 5, "remove_wolf_model")
	assert_eq(WolfChildRules.bond_of(_state(shell), 5).model_id, GameState.NO_TARGET, "Vorbild entfernt")


func test_apprentice_binding_and_inheritance_cycle() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var offered := _fields(shell, 6)
	assert_true(offered.has("set_apprentice_master") and offered.has("remove_apprentice_master") and offered.has("trigger_apprentice_inheritance"), "Lehrling mit Bindung: setzen, entfernen, Erbe auslösen")
	assert_false(offered.has("revert_apprentice_inheritance"), "noch kein Erbe zurückzunehmen")
	var old_master := ApprenticeRules.active_of(_state(shell), 6).master_id
	var master := 4 if old_master != 4 else 3
	var inherited := _state(shell).players[master].role_id
	assert_ne(old_master, master, "anderer Meister als bisher")
	await _apply(shell, 6, "set_apprentice_master", master)
	assert_eq(ApprenticeRules.active_of(_state(shell), 6).master_id, master, "neuer Meister")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 6, "trigger_apprentice_inheritance")
	assert_eq(_state(shell).players[6].role_id, inherited, "Erbe der Meisterrolle")
	assert_true(_fields(shell, 6).has("revert_apprentice_inheritance"), "geerbte Person bietet die Rücknahme an (nicht mehr Lehrling)")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 6, "revert_apprentice_inheritance")
	assert_eq(_state(shell).players[6].role_id, &"lehrling", "Erbe zurückgenommen")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 6, "remove_apprentice_master")
	assert_true(ApprenticeRules.active_of(_state(shell), 6) == null, "Bindung entfernt")


# --- Nur passende Korrekturen -------------------------------------------------------------------------------

func test_only_matching_corrections_are_offered() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var special := ["set_protection", "remove_protection", "set_rescue", "remove_rescue", "set_wolf_model", "remove_wolf_model", "transform_wolf_child", "revert_wolf_child",
		"set_apprentice_master", "remove_apprentice_master", "trigger_apprentice_inheritance", "revert_apprentice_inheritance"]
	for id: int in [1, 7, 9]:
		for kind: String in special:
			assert_false(_fields(shell, id).has(kind), "Person %d (ohne passende Rolle): %s nicht angeboten" % [id, kind])
	assert_false(_fields(shell, 4).has("set_protection"), "Waldhexe bietet keinen Schutz an")
	# Ziele: nie die Person selbst, nie Tote.
	for f: Dictionary in (session_of(shell) as GameSession).status_fields(3):
		if str(f["field"]) == "set_protection":
			assert_false((f["pick_ids"] as Array).has(3), "kein Selbstschutz")
			assert_true((f["pick_ids"] as Array).has(8), "lebende andere Person wählbar")
	# Frühe Nacht: Schutzengelschritt noch nicht erledigt → keine Schutzkorrektur.
	var early := UiGame.session(ROLES, 7)
	assert_true(early.start_night().ok, "Nacht 1")
	for kind: String in ["set_protection", "remove_protection", "set_rescue", "remove_rescue"]:
		assert_false(early.status_fields(3).any(func(f: Dictionary) -> bool: return str(f["field"]) == kind), "%s vor dem Schritt nicht angeboten" % kind)
		assert_false(early.status_fields(4).any(func(f: Dictionary) -> bool: return str(f["field"]) == kind), "%s (Waldhexe) vor dem Schritt nicht angeboten" % kind)
	# Tag: Schutz und Rettung gehören zur Nacht.
	var day := UiGame.session(ROLES, 7)
	assert_true(UiGame.run_until(day, func(n: Dictionary) -> bool: return str(n.get("kind")) == "day", {"pack/": [7]}), "Tag erreicht")
	for kind: String in ["set_protection", "remove_protection", "set_rescue", "remove_rescue"]:
		assert_false(day.status_fields(3).any(func(f: Dictionary) -> bool: return str(f["field"]) == kind), "%s am Tag nicht angeboten" % kind)


# --- Abbruch, Grund, ungültige Eingabe ---------------------------------------------------------------------

func test_cancel_at_every_stage_changes_nothing() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	var hash_before := s.state_hash()
	var commands_before := s.commands().size()
	var events_before := s.event_log().size()
	await _open_status(shell, 3)
	await press(find_button(current_screen(shell), "GmField_set_protection"))
	await press(find_button(_dialog(shell), "CancelButton"))
	assert_false(_dialog(shell).call("is_open"), "Zielwahl abgebrochen")
	await press(find_button(current_screen(shell), "GmField_set_protection"))
	await press(find_button(_dialog(shell), "Pick_8"))
	await frames(2)
	await press(find_button(_dialog(shell), "CancelButton"))
	assert_false(_dialog(shell).call("is_open"), "Begründungsdialog abgebrochen")
	await press(find_button(current_screen(shell), "GmField_remove_protection"))
	await press(find_button(_dialog(shell), "CancelButton"))
	await press(find_button(current_screen(shell), "CancelModeButton"))
	assert_eq(s.state_hash(), hash_before, "Zustand unverändert")
	assert_eq(s.commands().size(), commands_before, "kein Befehl")
	assert_eq(s.event_log().size(), events_before, "keine Ereignisse")


func test_confirmation_shows_person_change_and_requires_reason() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	await _open_status(shell, 3)
	await press(find_button(current_screen(shell), "GmField_set_protection"))
	var pick_dialog := _texts(_dialog(shell))
	assert_true(_has_word(pick_dialog, "C"), "Zielwahl nennt die betroffene Person: %s" % pick_dialog)
	await press(find_button(_dialog(shell), "Pick_8"))
	await frames(2)
	var reason_dialog := _texts(_dialog(shell))
	assert_true(_has_word(reason_dialog, "C") and _has_word(reason_dialog, "H"), "Rückfrage nennt Person und Ziel: %s" % reason_dialog)
	assert_true(find_button(_dialog(shell), "ConfirmButton").disabled, "ohne Begründung gesperrt")
	await press(find_button(_dialog(shell), "CancelButton"))


func test_invalid_input_changes_neither_state_nor_events() -> void:
	var s := UiGame.session(ROLES, 7)
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night", {"pack/": [7]}), "Nacht 1")
	var hash_before := s.state_hash()
	var commands_before := s.commands().size()
	var events_before := s.event_log().size()
	var invalid: Array = [
		{"kind": "set_protection", "guardian_id": 7, "target_id": 8, "reason": "x"},          # kein Schutzengel
		{"kind": "set_protection", "guardian_id": 3, "target_id": 3, "reason": "x"},          # Selbstschutz
		{"kind": "set_protection", "guardian_id": 3, "target_id": 99, "reason": "x"},         # unbekannte Person
		{"kind": "remove_rescue", "witch_id": 4, "reason": "x"},                              # keine Rettung vorhanden
		{"kind": "set_rescue", "witch_id": 4, "target_id": 8, "reason": "x"},                 # nicht das Rudelopfer
		{"kind": "set_wolf_model", "child_id": 5, "target_id": 5, "reason": "x"},             # sich selbst
		{"kind": "transform_wolf_child", "child_id": 7, "reason": "x"},                       # kein Wolfskind
		{"kind": "set_apprentice_master", "apprentice_id": 6, "target_id": 6, "reason": "x"}, # sich selbst
		{"kind": "revert_apprentice_inheritance", "apprentice_id": 6, "reason": "x"},         # kein Erbe
		{"kind": "remove_protection", "guardian_id": 3, "reason": ""},                        # ohne Grund (unten)
	]
	for payload: Dictionary in invalid:
		var r := s.gm_correction(payload)
		assert_false(r.ok, "%s abgelehnt" % str(payload))
		assert_eq(r.events.size(), 0, "keine Ereignisse")
	assert_eq(s.gm_correction({"kind": "set_protection", "guardian_id": 3, "target_id": 8, "reason": "  "}).error, &"reason_required", "fehlender Grund")
	assert_eq(s.state_hash(), hash_before, "Zustand unverändert")
	assert_eq(s.commands().size(), commands_before, "kein Befehl aufgenommen")
	assert_eq(s.event_log().size(), events_before, "Ereignisverlauf unverändert")


func test_core_rejections_have_readable_messages_in_both_languages() -> void:
	var codes := ["not_a_guardian", "no_guard_step", "step_not_completed", "not_a_witch", "no_witch_step", "no_pack_target", "not_current_pack_target",
		"not_a_wolf_child", "not_an_apprentice", "no_binding", "no_inheritance", "stale_inheritance", "not_a_mirror_wolf", "invalid_correction", "invalid_value",
		"unknown_role", "field_not_correctable", "confirmation_required", "player_alive", "no_change", "invalid_target", "player_dead", "wrong_phase", "reason_required"]
	for path: String in [PO_DE, PO_EN]:
		var po := po_entries(path)
		for code: String in codes:
			var key := "ui.cockpit.error.%s" % code
			assert_true(po.has(key) and str(po[key]) != "", "%s: %s" % [path.get_file(), key])
		for key: String in ["ui.cockpit.card.gm.action", "ui.cockpit.card.gm.action_pick", "ui.cockpit.dialog.pick.title", "ui.cockpit.dialog.pick.message",
				"ui.cockpit.dialog.gm.message_detail", "ui.cockpit.status.stale_selection", "ui.gm.state.protection_set", "ui.gm.state.protection_none", "ui.gm.state.rescue_set",
				"ui.gm.state.rescue_none", "ui.gm.state.wolf_child", "ui.gm.state.apprentice", "ui.gm.state.nobody"]:
			assert_true(po.has(key) and str(po[key]) != "", "%s: %s" % [path.get_file(), key])


# --- Undo, Redo, Speichern -------------------------------------------------------------------------------

func test_undo_redo_and_save_load_after_corrections() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	var protected_before := Protections.of_guardian(_state(shell), 3).target_id
	assert_ne(protected_before, 8, "Ausgangsschutz ist ein anderer")
	await _apply(shell, 3, "set_protection", 8)
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 5, "transform_wolf_child")
	var after := s.state_hash()
	var saved := s.save_text()
	var reloaded := GameSession.new()
	assert_eq(reloaded.load_text(saved), &"", "Speichern und Laden")
	assert_eq(reloaded.state_hash(), after, "geladener Stand entspricht")
	assert_true(reloaded.status_fields(5).any(func(f: Dictionary) -> bool: return str(f["field"]) == "revert_wolf_child"), "nach dem Laden bietet das Wolfskind die Rücknahme an")
	assert_true(s.undo(), "Rückgängig (Verwandlung)")
	assert_false(WolfChildRules.bond_of(_state(shell), 5).transformed, "Verwandlung zurückgenommen")
	assert_true(s.undo(), "Rückgängig (Schutz)")
	assert_eq(Protections.of_guardian(_state(shell), 3).target_id, protected_before, "Schutz wieder wie vor der Korrektur")
	assert_true(s.redo() and s.redo(), "Wiederholen zweimal")
	assert_eq(s.state_hash(), after, "Wiederholen stellt denselben Zustand her")


# --- Veraltete Auswahl ------------------------------------------------------------------------------------

func test_state_change_discards_status_selection_and_stale_dialog() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	await _open_status(shell, 3)
	var screen := current_screen(shell)
	assert_true(find_node(screen, "GmField_set_protection") != null, "Felder der gewählten Person")
	# Zustandswechsel im Hintergrund: die Personenauswahl der Status-Ansicht verfällt.
	assert_true(s.gm_correction({"kind": "set_ever_nominated", "target_id": 9, "value": true, "reason": "Test"}).ok, "Zustandswechsel")
	await frames(2)
	assert_true(find_node(screen, "GmField_set_protection") == null, "keine Felder einer veralteten Auswahl")
	# Offene Zielwahl, dann Zustandswechsel: die spätere Wahl ändert nichts.
	await press(find_node(screen, "SeatRing").call("token_for", 3) as BaseButton)
	await press(find_button(screen, "GmField_set_protection"))
	assert_true(_dialog(shell).call("is_open"), "Zielwahl offen")
	assert_true(s.gm_correction({"kind": "set_ever_nominated", "target_id": 9, "value": false, "reason": "Test"}).ok, "Zustandswechsel bei offener Zielwahl")
	var before := s.state_hash()
	var count := s.commands().size()
	await press(find_button(_dialog(shell), "Pick_8"))
	await frames(3)
	assert_false(_dialog(shell).call("is_open"), "kein Begründungsdialog zu veralteter Auswahl")
	assert_eq(s.state_hash(), before, "Zustand unverändert")
	assert_eq(s.commands().size(), count, "kein Befehl")


# --- Geheimhaltung ----------------------------------------------------------------------------------------

func test_public_morning_card_never_reveals_protection_or_rescue_corrections() -> void:
	var shell := await _night_shell()
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	await _apply(shell, 3, "set_protection", 7)
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	await _apply(shell, 4, "set_rescue")
	await press(find_button(current_screen(shell), "CloseLayerButton"))
	assert_true(s.end_night().ok, "Morgen")
	var public: String = JSON.stringify((s.morning_report() as Dictionary).get("public", {}))
	for forbidden: String in ["protect", "rescue", "guardian", "schutz", "GmCorrected", "witch"]:
		assert_false(public.to_lower().contains(forbidden.to_lower()), "öffentlicher Bericht nennt „%s“ nicht" % forbidden)
	for e: Dictionary in s.event_log():
		if str(e["type"]) == "GmCorrected":
			assert_eq(str(e["visibility"]), "gm", "Korrekturereignis nur für die Spielleitung")
