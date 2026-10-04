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
