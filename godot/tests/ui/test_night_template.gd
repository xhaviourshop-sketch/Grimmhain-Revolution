extends "res://tests/ui/role_ui_case.gd"
## Nacht-Schablone: automatische Übernahme bei fester Anzahl, Rückgängig-Leiste (3 s), Loki fragt zuerst die Art der
## Bindung, das Rudel hat kein „Kein Opfer“.

const W := "werwolf"
const D := "dorfbewohner"
const PACK_ROLES := [W, "schutzengel", "waldhexe", "das-orakel", D, "amalia", "detektiv"]


func _auto(counts: Array, high: int, extra: Dictionary = {}) -> bool:
	var next := {"answer": "targets", "owner": "doktor", "max": high, "counts": counts}
	next.merge(extra, true)
	return CockpitText.auto_commit(next)


## Feste Anzahl (genau n, 0 oder n) gilt sofort; Bereiche, Zufallsvorschläge, Karteneingaben und Nicht-Zielfragen nicht.
func test_auto_commit_applies_only_to_fixed_counts() -> void:
	assert_true(_auto([1], 1), "genau eine Person")
	assert_true(_auto([2], 2), "genau zwei Personen")
	assert_true(_auto([0, 3], 3), "keine oder drei Personen")
	assert_false(_auto([1, 2], 2), "Bereich 1 bis 2 bestätigt die Spielleitung")
	assert_false(_auto([2], 2, {"random": true}), "Zufallsvorschlag wird bestätigt")
	assert_false(_auto([2], 2, {"owner": "card"}), "Karteneingabe wird bestätigt")
	assert_false(_auto([], 0), "keine Auswahl möglich")
	assert_false(_auto([1], 1, {"answer": "choice"}), "keine Zielfrage")


## Rudel: genau eine Person, sofort übernommen, kein Verzicht („Kein Opfer“); die Rückgängig-Leiste nimmt die Wahl zurück.
func test_pack_has_no_decline_and_undo_bar_takes_the_choice_back() -> void:
	if not await start(PACK_ROLES):
		return
	assert_true(await run({}, until_prompt("pack")), "bis zum Rudel")
	await begin_open_step()
	assert_true(live("DeclineButton") == null, "kein Verzicht beim Rudel")
	assert_false(_texts_of_card().contains("Kein Opfer"), "kein „Kein Opfer“ auf der Karte")
	var card := find_node(screen(), "ActionCard")
	card.call("hide_undo")  # die Leiste vom vorigen Schritt stört nicht
	var before := session().commands().size()
	await tap_seat(5)
	assert_eq(session().commands().size(), before + 1, "feste Anzahl sofort übernommen, ohne Bestätigen")
	assert_true(bool(card.call("undo_visible")), "Rückgängig-Leiste nach der Übernahme")
	await tap_button("UndoBarButton")
	assert_eq(session().commands().size(), before, "Rückgängig nimmt die Wahl zurück")
	assert_eq(str(next().get("owner")), "pack", "Rudel wieder offen")


## „Rückgängig“ gibt es nur einmal sichtbar und erst nach einer Auswahl: vorher nicht, danach erst in der Karte, dann im Dock.
func test_dock_undo_shows_once_and_only_after_a_choice() -> void:
	if not await start(PACK_ROLES):
		return
	assert_true(await run({}, until_prompt("pack")), "bis zum Rudel")
	await begin_open_step()
	var dock := find_node(screen(), "DockUndoButton") as Control
	var card := find_node(screen(), "ActionCard")
	card.call("hide_undo")
	await frames(2)
	assert_false(dock.visible, "vor einer Auswahl kein Rückgängig im Dock")
	await tap_seat(5)
	assert_true(bool(card.call("undo_visible")) and not dock.visible, "gleich nach der Wahl zeigt nur die Karte Rückgängig")
	card.call("hide_undo")
	await frames(2)
	assert_true(dock.visible, "danach steht es im Dock")


## Warnungen der Mini-Nachtkarte (DA-101) kommen aus dem Kernzustand: vor der Wahl nennt die Karte das geschützte mögliche Rudelopfer
## (die Wahl gilt beim Antippen sofort), nach einer Wahl zählt nur die gewählte Person.
func test_night_warnings_follow_core_state() -> void:
	if not await start(PACK_ROLES):
		return
	assert_true(await run({"schutzengel/": [4]}, until_prompt("pack")), "bis zum Rudel, Person 4 geschützt")
	var keys := func(sel: Array) -> Array: return session().night_warnings(next(), sel).map(func(w: Dictionary) -> String: return str(w["key"]))
	assert_true((keys.call([]) as Array).has("ui.warn.protected"), "vor der Wahl: geschütztes mögliches Opfer")
	assert_true((keys.call([4]) as Array).has("ui.warn.protected"), "gewähltes geschütztes Ziel")
	assert_false((keys.call([5]) as Array).has("ui.warn.protected"), "ungeschütztes Ziel nicht")
	assert_false(shell.get_tree().get_nodes_in_group(&"night_warning").is_empty(), "rote Zeile auf der Karte")
	assert_true(_texts_of_card().contains("ist geschützt"), "Text der Warnung: %s" % _texts_of_card())


## Die Leiste verschwindet nach der eingestellten Zeit von selbst (Standard 3 s, hier verkürzt).
func test_undo_bar_disappears_after_its_time() -> void:
	if not await start(PACK_ROLES):
		return
	assert_eq(ActionCard.UNDO_SECONDS, 3.0, "Standardzeit 3 Sekunden")
	var card := find_node(screen(), "ActionCard")
	card.call("show_undo", 0.1)
	assert_true(bool(card.call("undo_visible")), "Leiste sichtbar")
	await shell.get_tree().create_timer(0.4).timeout
	assert_false(bool(card.call("undo_visible")), "Leiste nach Ablauf weg")


## Loki: erst Liebende oder Rivalen (Ja/Nein), dann die zwei Personen. Vorher zählt kein Sitzplatz.
func test_loki_asks_the_kind_before_the_two_people() -> void:
	if not await start([W, "loki", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	assert_true(await run({}, until_prompt("loki", "targets")), "bis Loki")
	await begin_open_step()
	assert_true(live("YesButton") != null and live("NoButton") != null, "erst die Art: Liebende oder Rivalen")
	var before := session().commands().size()
	await tap_seat(3)
	assert_eq([session().commands().size(), selection()], [before, []], "vor der Art zählt kein Sitzplatz")
	await tap_button("YesButton")
	await tap_seat(3)
	assert_eq(session().commands().size(), before, "eine Person allein sendet nichts")
	await tap_seat(4)
	var sent := session().commands().slice(before).filter(func(c: Command) -> bool: return c.payload.has("targets"))
	assert_eq(sent.size(), 1, "mit der zweiten Person sofort ein Befehl")
	if not sent.is_empty():
		assert_eq(sent[0].payload["targets"], [3, 4], "die gewählten zwei Personen")


func selection() -> Array:
	return screen().get("_selection") as Array


func _texts_of_card() -> String:
	var out: Array[String] = []
	for c: Control in text_controls(find_node(screen(), "ActionCard")):
		out.append(text_of(c))
	return "\n".join(out)


## S-05 (DA-93): Tagsüber sind die Abzeichen am Sitzkreis verborgen; ein Tipp auf die Person blendet ihre Abzeichen ein.
func test_day_hides_marks_until_a_seat_is_tapped() -> void:
	if not await start([W, "parasit", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	for c: Command in [Command.start_night(), Command.skip_step("night:1:0:pack", "kein Opfer"), Command.begin_step("night:1:1:parasit:2")]:
		assert_true(session().submit(c).ok, "Vorbereitung")
	assert_true(session().submit(Command.answer_prompt(2, [3])).ok and session().submit(Command.end_night()).ok, "Wirt gewählt, Nacht beendet")
	await frames(4)
	var ring: Node = find_node(screen(), "SeatRing")
	assert_eq(str(session().cockpit_view().get("phase")), "DAY", "Tag")
	assert_true((ring.get("_marks") as Dictionary).is_empty(), "Tag: keine Abzeichen")
	await tap_seat(3)
	assert_true((ring.get("_marks") as Dictionary).has(3), "Tipp zeigt das Abzeichen des Wirts")
