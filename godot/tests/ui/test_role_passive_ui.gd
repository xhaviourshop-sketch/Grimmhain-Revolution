extends "res://tests/ui/role_ui_case.gd"
## R-02 (Paket 3): Rollen ohne eigenen Fähigkeitsbutton. Ihre Wirkung wird über den Ablauf geprüft, der sie auslöst
## (Nominierung, Hinrichtung, Rudelangriff, Morgenbericht, Siegentscheidung), und zwar über die echten Controls
## (Treiber `role_ui_case.gd`). Es gibt keinen erfundenen Fähigkeitsbutton. Vorbereitung wie in `test_role_buttons`.

const W := "werwolf"
const D := "dorfbewohner"


func _villagers(n: int) -> Array:
	var out: Array = []
	for i: int in n:
		out.append(D)
	return out


func _texts(root: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		out.append(text_of(c))
	return "\n".join(out)


## Ganzes Wort (Namen sind hier ein einzelner Buchstabe; „contains“ träfe jeden Text).
func _has_word(text: String, word: String) -> bool:
	return RegEx.create_from_string("(^|[^\\p{L}])%s($|[^\\p{L}])" % word).search(text) != null


## Gewinner-Team auf dem Siegbildschirm (ein eindeutiger Sieg gilt nach der Kartenhandlung sofort, Fenster-Diät 05.10.2026).
func _winner_kind(n: Dictionary) -> String:
	return str((n.get("winner", {}) as Dictionary).get("kind", ""))


## Vorlesezeilen „Fürs Dorf“ der Morgenkarte (bis zur Überschrift „Für dich“).
func _village_text() -> String:
	var card := find_node(screen(), "ActionCard")
	var labels := card.find_children("*", "Label", true, false)
	var start := labels.find(find_node(card, "MorningVillage"))
	var stop := labels.find(find_node(card, "MorningPrivate"))
	if start == -1 or stop == -1:
		return ""
	return "\n".join(labels.slice(start, stop).map(func(l: Label) -> String: return l.text))


func test_siegreicher_wolf_counts_double_for_parity() -> void:
	if not await start(["siegreicher-wolf"] + _villagers(5), [4, 5]):
		return
	await run({"day1": {"nominate": [2, 3], "execute": 3}}, until_kind("game_over"))
	assert_eq(_winner_kind(next()), "wolves", "ein Siegreicher Wolf gegen zwei Dorfpersonen: Wolfssieg ohne Rückfrage")
	assert_true(find_node(screen(), "VictoryTitle") != null, "Siegbildschirm")


func test_doppelspion_wins_alone_when_no_wolf_lives() -> void:
	if not await start(["doppelspion", W] + _villagers(4)):
		return
	await run({"day1": {"nominate": [3, 2], "execute": 2}}, until_kind("game_over"))
	assert_eq(_winner_kind(next()), "solo", "nur der Doppelspion, kein Dorfsieg")


func test_selbstmoerder_fulfilled_by_execution_with_five_dead() -> void:
	if not await start(["selbstmoerder", W] + _villagers(8), [3, 4, 5, 6, 7]):
		return
	await run({"day1": {"nominate": [8, 1], "execute": 1}}, until_event("DeathSeekerFulfilled"))
	assert_true(has_event("DeathSeekerFulfilled"), "Sieg des Selbstmörders erfüllt")


func test_wahnsinniger_kutscher_takes_neighbours_on_lynch() -> void:
	if not await start([D, W, "wahnsinniger-kutscher", "amalia", "detektiv", "blutwolf", "waechter-am-tor"]):
		return
	await run({"day1": {"nominate": [5, 3], "execute": 3}}, until_kind("end_day"))
	assert_false(alive(2) or alive(4), "beide Nachbarn sterben mit")
	var effects: Array = session().day_effects()
	assert_true(effects.any(func(e: Dictionary) -> bool: return str(e["effect"]) == "coachman_crash"), "öffentlich angesagter Todeseffekt")
	assert_true(_has_word(_texts(screen()), "B"), "Tageskarte nennt die Mitgerissenen")


func test_dorfwache_survives_pack_attack() -> void:
	if not await start(["dorfwache", W] + _villagers(5)):
		return
	await run({"pack/": [1]}, until_kind("day"))
	assert_true(alive(1), "Rudelangriff tötet die Dorfwache nicht")


func test_waechter_am_tor_blocks_new_wolf() -> void:
	if not await start(["koenig-lykaon", W, "waechter-am-tor"] + _villagers(5)):
		return
	await run({"koenig-lykaon/ally": [2], "koenig-lykaon/targets": [4]}, until_kind("day"))
	assert_eq(state().players[4].role_id, &"dorfbewohner", "Ziel bleibt Dorfbewohner")
	assert_false(state().players[4].counts_as_wolf, "kein neuer Wolf")
	assert_true(has_event("NewWolfBlocked"), "Blockade protokolliert")


func test_rudelvater_lynch_gives_second_pack_step() -> void:
	if not await start([W, "rudelvater"] + _villagers(6)):
		return
	await run({"day1": {"nominate": [3, 2], "execute": 2}, "pack/": null, "pack2/": [4]}, until_day(2))
	assert_true(session().event_log().any(func(e: Dictionary) -> bool: return str(e["type"]) == "PromptOpened" and str(((e["data"] as Dictionary)["prompt"] as Dictionary).get("owner")) == "pack2"),
		"zweiter Rudelschritt als Karte")
	assert_false(alive(4), "Opfer des zweiten Rudelschritts")


func test_seuchenwolf_death_lets_next_attack_pierce_protection() -> void:
	if not await start([W, "seuchenwolf", "schutzengel"] + _villagers(5)):
		return
	await run({"day1": {"nominate": [4, 2], "execute": 2}, "schutzengel/": [5], "pack/": [5]},
		until_day(2))
	assert_false(alive(5), "Schutz durchdrungen")


func test_fenrir_survives_death_from_stage_three() -> void:
	if not await start([W, "fenrir"] + _villagers(6)):
		return
	await run({"day3": {"nominate": [3, 2], "execute": 2}},
		until_day(3, "end_day"))
	assert_true(alive(2), "Fenrir überlebt die Hinrichtung an Tag 3")


func test_nachtwaechter_bells_in_village_part() -> void:
	if not await start([D, W, "nachtwaechter"] + _villagers(4)):
		return
	await run({"pack/": [4]}, until_kind("day"))
	if has_event("AlarmBells"):
		assert_true(_village_text().contains(TranslationServer.translate("ui.morning.notice.bells")), "Glocken im Teil „Fürs Dorf“")
	else:
		fail("keine Glocken ausgelöst")


func test_detektiv_hint_in_public_morning_card() -> void:
	if not await start(["detektiv", W, W, "waldhexe"] + _villagers(4)):
		return
	await run({"waldhexe/heal": false, "waldhexe/poison": true, "waldhexe/poison_target": [2]}, until_kind("day"))
	assert_true(has_event("DetectiveHint"), "Richtungshinweis nach Wolfstod")
	var village := _village_text()
	assert_true(village.contains(TranslationServer.translate("ui.prompt.direction.%s" % str((events("DetectiveHint")[0]["data"] as Dictionary)["direction"]))),
		"Teil „Fürs Dorf“ nennt die Richtung")
	# Die Rolle des Toten wird in Runden ohne Wiederbelebung angesagt (Entscheidung 29.09.2026); andere Rollen nie.
	for role: String in ["detektiv", "waldhexe"]:
		assert_false(village.contains(TranslationServer.translate("ui.role.%s.name" % role)), "Teil „Fürs Dorf“ ohne Rolle %s" % role)


## RM-DR-008: Stimmen werden physisch gezählt; die Spielleitung sieht Boni als Hinweis (Blutwolf, Korrupter Richter),
## nur im privaten Bereich, nie auf der öffentlichen Tageskarte.
func test_blutwolf_vote_bonus_visible_only_in_private_area() -> void:
	if not await start([D, "blutwolf", D] + _villagers(4), [1, 3]):
		return
	await run({}, until_kind("day"))
	await tap_button("ContinueDayButton")
	var day_text := _texts(screen())
	await tap_button("PrivateButton")
	var drawer := find_node(screen(), "PrivateLayer")
	assert_true(drawer != null and drawer.find_child("VoteHint_2", true, false) != null, "Stimmhinweis für Person 2 im privaten Bereich")
	if drawer != null and drawer.find_child("VoteHint_2", true, false) != null:
		assert_true(text_of(drawer.find_child("VoteHint_2", true, false) as Control).contains("+2"), "zwei tote Nachbarn: +2")
	assert_false(day_text.contains("+2"), "öffentliche Tageskarte ohne Bonus")


func test_korrupter_richter_vote_bonus_in_private_area() -> void:
	if not await start(["korrupter-richter", W] + _villagers(5)):
		return
	await run({"korrupter-richter/": [3]}, until_kind("day"))
	if live("ContinueDayButton") != null:
		await tap_button("ContinueDayButton")
	await tap_button("PrivateButton")
	var drawer := find_node(screen(), "PrivateLayer")
	assert_true(drawer != null and drawer.find_child("VoteHint_3", true, false) != null, "Richterbonus für Person 3 im privaten Bereich")
