extends "res://tests/ui/role_ui_case.gd"
## Paket 4: Unterbrechung und Fortsetzen über den tatsächlichen Bedienweg. Jede Szene wird über die Karten und Sitzplätze
## des Cockpits bis zur Unterbrechungsstelle bedient; gespeichert wird nur über den automatischen Speicherweg
## (AppContext.autosave nach jedem Befehl). Der Neustart entfernt die Shell samt Sitzung und Diensten, startet eine neue
## Shell mit demselben Speicherort und setzt über Hauptmenü → „Fortsetzen“ → „Fortsetzen“ fort.
##
## Geprüft wird je Szene:
##   A. persistenter Regelzustand: fachlicher Hash, Ereignisverlauf, Cockpit-Sicht (nächste Handlung, Hinweise),
##      Morgenbericht und Rollenanzeige sind nach dem Neustart identisch
##   B. flüchtige Bedienauswahl (angetippte Sitzplätze, aufgedeckte Prüfkarte, offene Ebene) ist bewusst verworfen
##   C. nach dem Fortsetzen erzeugt genau eine Bedienung genau einen Befehl, und das Ergebnis gleicht dem
##      ununterbrochenen Ablauf (Replay der Befehle vor dem Neustart plus dieser Befehl)
## Vorbereitung ohne Karten (Start, Spielleiterkorrekturen) ist wie in role_ui_case.gd gekennzeichnet.

const W := "werwolf"
const D := "dorfbewohner"


## Neustart der App mit demselben Speicherort, Fortsetzen über den Fortsetzen-Bildschirm. Liefert den Zustand vor dem
## Neustart {snapshot, commands}.
func restart() -> Dictionary:
	var before := {"snapshot": snapshot(), "commands": session().commands()}
	var dir := (context_of(shell) as AppContext).saves.base_dir
	var round := session().round_id()
	assert_true(bool((context_of(shell) as AppContext).saves.last_status.get("ok", false)), "vor dem Neustart gespeichert")
	_spawned.erase(shell)
	shell.get_parent().remove_child(shell)
	shell.free()
	await frames(2)
	shell = await spawn_shell()
	(context_of(shell) as AppContext).saves.base_dir = dir
	await navigate(shell, &"main_menu")
	await navigate(shell, &"continue")
	await tap_button("ResumeButton_%s" % round)
	assert_eq(String(current_id(shell)), "cockpit", "Fortsetzen öffnet das Cockpit")
	assert_eq(snapshot(), before["snapshot"], "persistenter Zustand nach dem Neustart identisch")
	assert_true(screen().get("_layer") == null, "keine private Ebene nach dem Fortsetzen geöffnet")
	return before


func snapshot() -> Dictionary:
	return {"hash": session().state_hash(), "events": session().event_log(), "cockpit": session().cockpit_view(),
		"morning": session().morning_report(), "roles": session().role_show_list(), "day_effects": session().day_effects()}


## Genau eine Bedienung nach dem Fortsetzen (ein Befehl; `commands` mehr, wenn die Karte eine Folgestufe selbst übernimmt),
## Ergebnis wie ohne Unterbrechung, und er wurde gespeichert.
func assert_one_effect(before: Dictionary, label: String, commands: int = 1) -> void:
	var old: Array[Command] = before["commands"]
	var now := session().commands()
	# Nachtende und eindeutiger Sieg folgen einer Kartenhandlung von selbst (Fenster-Diät) und zählen nicht als eigene Handlung.
	var added := now.slice(old.size())
	var own := added.filter(func(c: Command) -> bool: return c == added[0] or (c.type != Command.END_NIGHT and c.type != Command.CONFIRM_WIN))
	assert_eq(own.size(), commands, "%s: genau %d Befehl(e) nach dem Fortsetzen" % [label, commands])
	var expected: Array[Command] = old.duplicate()
	expected.append_array(now.slice(old.size()))
	var reference := RulesEngine.replay(expected)
	assert_true(reference.ok, "%s: ununterbrochener Ablauf angenommen" % label)
	assert_eq(session().state_hash(), reference.state.content_hash(), "%s: Zustand wie ohne Unterbrechung" % label)
	assert_eq(session().event_log(), reference.events.map(func(e: GameEvent) -> Dictionary: return e.to_dict()), "%s: Ereignisse wie ohne Unterbrechung" % label)
	assert_true(bool((context_of(shell) as AppContext).saves.last_status.get("ok", false)), "%s: nach dem Fortsetzen gespeichert" % label)


func selection() -> Array:
	return screen().get("_selection") as Array


# --- offene Auswahl -------------------------------------------------------------------------------------

## Zufallsvorschlag des Traumdeuters (muss bestätigt werden, RM-DR-015.2): Der Vorschlag ist flüchtig und nach dem Neustart
## verworfen; ein neuer Vorschlag wird bestätigt und erzeugt genau einen Befehl. Feste Anzahlen ohne Vorschlag werden sofort
## übernommen und haben keine offene Auswahl, die ein Neustart verwerfen müsste.
func test_open_single_selection_is_discarded_and_prompt_stays_open() -> void:
	if not await start(["traumdeuter", W, "blutwolf", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({}, until_prompt("traumdeuter", "targets")), "bis zur Auswahl")
	await begin_open_step()
	await tap_button("RandomTargetsButton")
	assert_eq(selection().size(), 3, "Vorschlag angezeigt, nicht bestätigt")
	var before := await restart()
	assert_eq(selection(), [], "flüchtiger Vorschlag verworfen")
	assert_eq(str(next()["owner"]), "traumdeuter", "Prompt weiter offen")
	await tap_button("RandomTargetsButton")
	await tap_button("ConfirmTargetsButton")
	assert_one_effect(before, "Zufallsvorschlag")
	assert_true(bool(last_command().payload.get("random", false)), "Befehl mit dem neuen Vorschlag")


## Halbe Mehrfachauswahl (zwei von drei Personen): flüchtig und nach dem Neustart verworfen; erst die dritte Person
## schließt die feste Anzahl, und sie wird sofort übernommen, ohne dass die zwei alten Personen noch zählen.
func test_open_multi_selection_is_discarded() -> void:
	if not await start(["traumdeuter", W, "blutwolf", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({}, until_prompt("traumdeuter", "targets")), "bis zur Auswahl")
	await begin_open_step()
	await tap_seat(2)
	await tap_seat(4)
	assert_eq(selection(), [2, 4], "halbe Auswahl vorhanden")
	var before := await restart()
	assert_eq(selection(), [], "halbe Mehrfachauswahl verworfen")
	assert_eq(str(next()["owner"]), "traumdeuter", "Prompt weiter offen")
	await tap_seat(5)
	assert_eq(session().commands().size(), before["commands"].size(), "eine Person allein sendet nichts")
	await tap_seat(2)
	await tap_seat(4)
	if live("ConfirmTargetsButton") != null:
		await tap_button("ConfirmTargetsButton")
	assert_one_effect(before, "Mehrfachauswahl")


# --- mehrstufige Rollenaktion, Todesreaktion ------------------------------------------------------------

## Waldhexe: Stufe „Heiltrank“ ist beantwortet (bestätigter Schritt), Stufe „Gift“ offen.
func test_multistage_role_action_keeps_the_answered_stage() -> void:
	if not await start([W, "schutzengel", "waldhexe", "das-orakel", D, "amalia", "detektiv"]):
		return
	assert_true(await run({"waldhexe/heal": false}, until_prompt("waldhexe", "poison")), "bis zur Giftstufe")
	var before := await restart()
	assert_eq(str(next()["stage"]), "poison", "Giftstufe weiter offen, Heiltrankantwort erhalten")
	assert_true(await answer(false), "Gift verworfen")
	assert_one_effect(before, "Waldhexe", 2)  # Giftverzicht, danach übernimmt die Karte die Bestätigungsstufe selbst


## Offene Todesreaktion (Sensenträger), einmal eingereiht und einmal mit offenem Prompt: nach dem Neustart genau
## eine Reaktion, keine doppelte Auslösung.
func test_open_death_reaction_survives_restart_once() -> void:
	if not await start([W, "blutwolf", "sensentraeger", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({}, until_day(1)), "bis Tag 1")
	# Vorbereitung ohne Karte: Tod des Sensenträgers mit Folgen.
	assert_true(session().submit(CorrectionFixtures.gm("kill", {"target_id": 3, "trigger_effects": true}, "Vorbereitung")).ok, "Tod mit Folgen")
	assert_eq(state().reactions.size(), 1, "Reaktion eingereiht")
	var before := await restart()
	assert_eq(state().reactions.size(), 1, "nach dem Neustart genau eine Reaktion")
	assert_eq(str(next()["owner"]), "reaction", "Reaktion steht als Karte an (Vorschau)")
	await begin_open_step()  # Vorbereitung ohne Karte: Die Karte beginnt den Schritt erst mit der ersten Bedienung
	assert_eq(state().reactions.size(), 1, "Reaktion mit offenem Prompt noch eingereiht")
	before = await restart()
	assert_true(await step({"reaction/%s" % str(next()["reaction_kind"]): [4]}), "Ziel der Reaktion über die aufgedeckte Karte")
	assert_one_effect(before, "Reaktionsprompt")
	assert_eq(state().reactions.size(), 0, "Reaktion erledigt")
	assert_eq(events("ReactionQueued").size(), 1, "nur einmal eingereiht")
	assert_false(alive(4), "Wirkung genau einmal")


# --- private Hinweise und Rollenanzeige ------------------------------------------------------------------

## Unbestätigter privater Hinweis bleibt erreichbar; eine vor dem Neustart geöffnete Karte ist geschlossen.
## Ein bestätigter Hinweis wird nach dem nächsten Neustart nicht erneut verlangt.
func test_unconfirmed_notice_stays_reachable_and_confirmed_one_is_not_asked_again() -> void:
	if not await start([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	assert_true(await run({"loki/targets": [3, 5], "loki/mode": true}, until_kind("notice")), "bis zum ersten Hinweis")
	var first := int(next()["notice_id"])
	await tap_button("ShowNoticeButton")
	assert_true(find_node(screen(), "NoticeLayer") != null or screen().get("_layer") != null, "Hinweiskarte offen")
	var before := await restart()
	assert_true(find_node(screen(), "NoticeLayer") == null, "private Karte nach dem Neustart nicht offen")
	assert_eq(int(next()["notice_id"]), first, "derselbe unbestätigte Hinweis erreichbar")
	await tap_button("ShowNoticeButton")
	await tap_button("CloseLayerButton", find_node(screen(), "NoticeLayer"))  # Schließen der gezeigten Karte bestätigt den Hinweis
	assert_one_effect(before, "Hinweis bestätigt")
	assert_ne(int(next().get("notice_id", -1)), first, "erledigter Hinweis steht nicht mehr an")
	assert_true(session().undo(), "Rückgängig nach dem Fortsetzen")
	assert_eq(int(next()["notice_id"]), first, "Hinweis steht wieder an")
	assert_true(session().redo(), "Wiederholen")
	assert_ne(int(next().get("notice_id", -1)), first, "wieder erledigt")
	await restart()
	assert_ne(int(next().get("notice_id", -1)), first, "nach erneutem Neustart nicht erneut verlangt")
	assert_eq(session().commands().filter(func(c: Command) -> bool: return c.type == Command.ACK_NOTICE).size(), 1, "genau eine Bestätigung")


## Teilweise abgeschlossene Rollenanzeige: bestätigte Personen bleiben bestätigt, die offene Karte ist verworfen.
func test_partial_role_show_continues_with_the_first_unconfirmed_person() -> void:
	if not await start([D, W, "waldhexe", "amalia", "schutzengel", "detektiv"]):
		return
	for id: int in [1, 2]:
		await tap_button("RolesButton")
		await tap_button("RolePerson_%d" % id, find_node(screen(), "RoleListLayer"))
		await tap_button("ConfirmRoleButton", find_node(screen(), "RoleCardLayer"))
		await tap_button("CloseLayerButton", find_node(screen(), "RoleListLayer"))
	await tap_button("RolesButton")
	await tap_button("RolePerson_3", find_node(screen(), "RoleListLayer"))
	# Karte offen, nicht bestätigt
	var before := await restart()
	assert_true(find_node(screen(), "RoleCardLayer") == null, "offene Rollenkarte nach dem Neustart verworfen")
	assert_eq(int(session().role_show_list()["next_id"]), 3, "Fortsetzung bei Person 3")
	await tap_button("RolesButton")
	await tap_button("RolePerson_3", find_node(screen(), "RoleListLayer"))
	await tap_button("ConfirmRoleButton", find_node(screen(), "RoleCardLayer"))
	assert_one_effect(before, "Rollenanzeige")
	assert_eq(int(session().role_show_list()["next_id"]), 4, "danach Person 4")


# --- Morgen, Tag, Sieg --------------------------------------------------------------------------------------

## Morgenbericht: öffentlicher und privater Teil nach dem Neustart gleich (Vergleich in `restart`); das Weiterschalten
## des Berichts ist Bedienzustand und darf erneut angeboten werden.
func test_morning_report_is_identical_after_restart() -> void:
	if not await start([W, "schutzengel", "waldhexe", "das-orakel", D, "amalia", "detektiv"]):
		return
	assert_true(await run({"pack/": [5]}, until_day(1)), "bis zum Morgen")
	assert_false((session().morning_report()["public"]["deaths"] as Array).is_empty(), "Bericht mit Todesfall")
	var before := await restart()
	if live("ContinueDayButton") != null:
		await tap_button("ContinueDayButton")
	assert_true(await day({}), "Tag ohne Hinrichtung")
	assert_one_effect(before, "Tag nach dem Morgenbericht")


## Offene Nominierung bleibt (bestätigter Befehl); eine offene, nicht bestätigte Hinrichtungsprüfung ist flüchtig.
func test_open_nomination_survives_and_execution_check_is_discarded() -> void:
	if not await start([W, "schutzengel", "waldhexe", "das-orakel", D, "amalia", "detektiv"]):
		return
	assert_true(await run({}, until_day(1)), "bis Tag 1")
	if live("ContinueDayButton") != null:
		await tap_button("ContinueDayButton")
	assert_true(await day({"nominate": [2, 1]}), "Nominierung über Sitzplätze")
	await tap_button("ExecuteButton")
	await tap_seat(1)
	assert_true(live("ConfirmExecutionButton") != null, "Karte der Hinrichtung offen")
	var before := await restart()
	assert_eq((next()["nominations"] as Array).size(), 1, "Nominierung erhalten")
	assert_true(live("ConfirmExecutionButton") == null, "Prüfkarte verworfen")
	assert_true(await day({"execute": 1}), "Hinrichtung nach dem Fortsetzen")
	assert_one_effect(before, "Hinrichtung")
	assert_eq(events("Executed").size() + events("SeatDied").filter(func(e: Dictionary) -> bool: return str(e["data"].get("cause", "")) == "LYNCH").size() > 0, true, "Hinrichtung genau jetzt wirksam")


## Offener Siegkandidat: Entscheidung bleibt offen und wird genau einmal bestätigt.
func test_open_win_candidate_is_decided_once_after_restart() -> void:
	if not await start([W, "blutwolf", "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher"]):
		return
	assert_true(await run({}, until_prompt("pack")), "bis zum Rudel")
	# Vorbereitung ohne Karte: drei Tote per Korrektur führen zur Siegentscheidung.
	for id: int in [4, 5, 6]:
		assert_true(session().submit(CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false}, "Vorbereitung")).ok, "Korrektur %d" % id)
	await frames(2)
	assert_eq(str(next()["kind"]), "win_decision", "Siegentscheidung offen")
	var before := await restart()
	var candidate := int((next()["candidates"] as Array)[0]["id"])
	await tap_button("ConfirmWinButton_%d" % candidate)  # ein Tipp, keine Rückfrage
	assert_one_effect(before, "Sieg")
	assert_eq(str(next()["kind"]), "game_over", "Spielende")
	assert_true(session().undo(), "Rückgängig nach dem Fortsetzen")
	assert_eq(str(next()["kind"]), "win_decision", "Entscheidung wieder offen")
	assert_true(session().redo(), "Wiederholen")
	await restart()
	assert_eq(str(next()["kind"]), "game_over", "bestätigtes Spielende nach erneutem Neustart")
	assert_eq(session().commands().filter(func(c: Command) -> bool: return c.type == Command.CONFIRM_WIN).size(), 1, "genau eine Bestätigung")


## PE-06: Neustart an jeder Unterbrechungsstelle des Rattenfänger-Ablaufs. Danach steht dieselbe Karte mit denselben
## berechtigten Personen an, keine Ebene ist offen, eine Bedienung erzeugt genau einen Befehl; keine Ansage fehlt oder
## doppelt sich. Rückgängig und Wiederholen der Bestätigung stellen den Schritt wieder her bzw. erledigen ihn wieder.
func test_piper_flow_resumes_at_every_interruption_point() -> void:
	if not await start([W, "rattenfaenger", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "das-orakel"]):
		return
	assert_true(await run({}, until_prompt("rattenfaenger")), "vor dem Rattenfänger")
	var before := await restart()
	assert_eq(str(next()["role_id"]), "rattenfaenger", "Rattenfänger steht weiter an")
	await tap_seat(4)
	await tap_seat(5)
	await tap_button("ConfirmTargetsButton")  # Anzahl 1 bis 2: bestätigt die Spielleitung
	assert_one_effect(before, "Rattenfänger", 2)  # Schritt beginnen und Auswahl übernehmen
	assert_eq(str(next().get("notice_kind")), "piper_new", "nach der Aktion: Hinweis offen")
	await tap_button("ShowNoticeButton")
	before = await restart()
	assert_true(find_node(screen(), "NoticeLayer") == null, "Hinweiskarte nach dem Neustart nicht wieder geöffnet")
	assert_eq(str(next().get("notice_kind")), "piper_new", "derselbe Hinweis")
	await tap_button("ShowNoticeButton")
	await tap_button("CloseLayerButton", find_node(screen(), "NoticeLayer"))  # Schließen der gezeigten Karte bestätigt den Hinweis
	assert_one_effect(before, "Hinweis bestätigt")
	before = await restart()
	assert_eq(str(next()["role_id"]), "piper-all", "zwischen den Phasen: „Alle Verzauberten“ steht an")
	assert_eq(next()["actor_ids"], [4, 5], "dieselben Personen")
	await begin_open_step()  # Vorbereitung ohne Karte: Die Karte beginnt den Schritt erst mit der ersten Bedienung
	before = await restart()
	assert_eq(str(next().get("owner")), "piper-all", "offene Karte bleibt offen")
	assert_eq(next()["actor_ids"], [4, 5], "dieselben Personen nach dem Neustart")
	await tap_button("AckButton")
	assert_one_effect(before, "„Alle Verzauberten“ bestätigt")
	var after_ack := next()
	assert_eq(str(after_ack["role_id"]), "das-orakel", "weiter mit dem nächsten Nachtschritt")
	await restart()
	assert_eq(next(), after_ack, "nach dem Neustart kein erneutes „Alle Verzauberten“")
	assert_true(session().undo(), "Rückgängig der Bestätigung")
	assert_eq(str(next().get("owner")), "piper-all", "Karte wieder offen")
	assert_eq(next()["actor_ids"], [4, 5], "dieselben Personen nach Rückgängig")
	assert_true(session().redo(), "Wiederholen")
	assert_eq(next(), after_ack, "wieder erledigt")
	var shown := session().commands().filter(func(c: Command) -> bool: return c.type == Command.BEGIN_STEP and str(c.payload["step_id"]).ends_with(":piper-all"))
	assert_eq(shown.size(), 1, "„Alle Verzauberten“ genau einmal begonnen")
