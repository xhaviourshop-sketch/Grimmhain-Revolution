extends UiTestCase
## PE-01 (Decision Log „Produktentscheidungen nach Paket 4“, Matrix I-03): Die öffentliche Hinweiszeile nennt offene
## Reaktionen weder mit Anzahl noch Art oder Besitzer. Sie zeigt außerhalb der Nacht bei jedem verdeckten Schritt
## (Reaktion, Prompt, Siegentscheidung, Hinweiskarte) denselben neutralen, zur Phase passenden Text; die Ansagekarte der
## Spielleitung behält alle Einzelheiten. Grenze: Rückschlüsse aus Handlungen am Tisch oder Bedienzeit verhindert das nicht.

const UiGame := preload("res://tests/ui/ui_game.gd")
const W := "werwolf"
const D := "dorfbewohner"
const DAWN_HINT := {"key": "ui.cockpit.warning.gm_preparing.dawn", "values": {}}
const DAY_HINT := {"key": "ui.cockpit.warning.gm_preparing.day", "values": {}}
## 2 Sensenträger, 3 Waldhexe, 4 Besessener Wolf; acht Personen, damit der Besessene Wolf reagieren darf.
const ROLES := [W, "sensentraeger", "waldhexe", "besessener-wolf", D, "amalia", "detektiv", "wahnsinniger-kutscher"]


## Erste Nacht mit Rudelziel und optionalem Gift der Waldhexe, danach Morgenauflösung.
func _dawn(pack: int, poison: int = -1) -> GameSession:
	var s := UiGame.session(ROLES)
	assert_true(s.start_night().ok, "Nacht 1")
	var answers := {"pack/": [pack]}
	if poison > 0:
		answers["waldhexe/poison"] = true
		answers["waldhexe/poison_target"] = [poison]
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night", answers), "bis Nachtende")
	assert_true(s.end_night().ok, "Morgen")
	return s


## Tag 1 ohne Nachtfolgen für `executed`, dann Hinrichtung von `executed`.
func _day_execution(roles: Array, executed: int) -> GameSession:
	var s := UiGame.session(roles)
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.to_day(s, {"pack/": [roles.size()]}), "bis zum Tag")
	assert_true(s.nominate(1, executed).ok, "Nominierung")
	assert_true(s.decide_execution(executed).ok, "Hinrichtung")
	return s


func _warnings(s: GameSession) -> Array:
	return s.cockpit_view()["warnings"]


func _assert_neutral(s: GameSession, expected: Dictionary, label: String) -> void:
	assert_eq(_warnings(s), [expected], "%s: nur der neutrale Hinweis" % label)
	var text := JSON.stringify(_warnings(s))
	for word: String in ["reaction", "count", "owner", "role", "curse", "possessed", "sensentraeger", "besessener"]:
		assert_false(text.contains(word), "%s: Hinweiszeile ohne „%s“" % [label, word])
	for digit: int in 10:
		assert_false(text.contains(str(digit)), "%s: Hinweiszeile ohne Zahl" % label)


func test_different_dawn_reactions_give_the_same_public_hint() -> void:
	var curse := _dawn(2)           # Sensenträger: eine Reaktion
	var possessed := _dawn(5, 4)    # Besessener Wolf (Wolf als Besitzer): eine Reaktion anderer Art
	var both := _dawn(2, 4)         # zwei Reaktionen
	assert_eq((curse.view() as Dictionary)["phase"], "DAWN_RESOLUTION", "Morgen mit Reaktion")
	assert_eq(UiGame.next_of(curse)["reaction_kind"], "curse", "Fluch offen")
	assert_eq(UiGame.next_of(possessed)["reaction_kind"], "possessed", "Besessener Wolf offen")
	assert_eq(int(UiGame.next_of(both)["reactions_open"]), 2, "zwei Reaktionen offen")
	for entry: Array in [["Sensenträger", curse], ["Besessener Wolf", possessed], ["zwei Reaktionen", both]]:
		_assert_neutral(entry[1], DAWN_HINT, entry[0])


func test_day_reaction_uses_the_day_text() -> void:
	var curse := _day_execution([W, "sensentraeger", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], 2)
	var possessed := _day_execution([W, "besessener-wolf", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise"], 2)
	for entry: Array in [["Sensenträger am Tag", curse], ["Besessener Wolf am Tag", possessed]]:
		var s: GameSession = entry[1]
		assert_eq(str(UiGame.next_of(s)["step_kind"]), "reaction", "%s: Reaktion offen" % entry[0])
		_assert_neutral(s, DAY_HINT, entry[0])


## Kein exklusiver Marker: dieselbe Zeile erscheint bei einer verdeckten Siegentscheidung ohne jede Reaktion.
func test_same_hint_for_other_secret_steps_and_none_on_open_cards() -> void:
	var s := UiGame.session([W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"])
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.to_day(s, {"pack/": [2]}), "bis zum Tag")
	assert_eq(_warnings(s), [], "offener Tag ohne verdeckten Schritt: keine Zeile")
	assert_true(s.nominate(3, 1).ok, "Nominierung")
	assert_true(s.decide_execution(1).ok, "letzter Wolf hingerichtet")
	assert_eq(str(UiGame.next_of(s)["kind"]), "win_decision", "verdeckte Siegentscheidung")
	assert_false(JSON.stringify(s.event_log()).contains("ReactionQueued"), "keine Reaktion (Werwolf hat keine Todesfolge)")
	_assert_neutral(s, DAY_HINT, "Siegentscheidung")
	var night := UiGame.session([W, "sensentraeger", D, "amalia", "detektiv", "wahnsinniger-kutscher"])
	assert_true(night.start_night().ok, "Nacht 1")
	assert_eq(_warnings(night), [], "Nacht: keine Zeile (jeder Nachtschritt ist verdeckt)")


func test_private_card_keeps_details_and_reactions_stay_operable() -> void:
	var s := _dawn(2, 4)
	var next := UiGame.next_of(s)
	assert_true(bool(next["secret"]), "Karte nur für die Spielleitung")
	# Reihenfolge der Tode: Gift (Besessener Wolf) vor dem Rudelopfer (Sensenträger).
	assert_eq(str(next["role_id"]), "besessener-wolf", "Rolle der ersten Reaktion auf der Karte")
	assert_eq(next["actor_ids"], [4], "Besitzer auf der Karte")
	assert_eq(int(next["reactions_open"]), 2, "Anzahl auf der Karte")
	assert_true(s.begin_next_step().ok, "Reaktion beginnen")
	assert_true(s.answer_targets([]).ok, "Besessener Wolf verzichtet")
	_assert_neutral(s, DAWN_HINT, "zweite Reaktion")
	assert_eq(str(UiGame.next_of(s)["reaction_kind"]), "curse", "zweite Reaktion auf der Karte")
	assert_true(s.begin_next_step().ok, "zweite Reaktion beginnen")
	assert_true(s.answer_targets([5]).ok, "Sensenträger verflucht 5")
	assert_eq(str((s.view() as Dictionary)["phase"]), "DAY", "Tag nach den Reaktionen")
	# DI-03: Der Todeseffekt wird öffentlich angesagt, sobald er eintritt.
	var effects: Array = (s.morning_report()["public"] as Dictionary)["effects"]
	assert_eq(effects.map(func(e: Dictionary) -> String: return str(e["effect"])), ["reaper_curse"], "Fluch öffentlich angesagt")
	assert_eq(str(effects[0]["role_id"]), "sensentraeger", "mit Rolle (DI-03)")


func test_hint_stays_neutral_after_load_and_undo() -> void:
	var s := _dawn(2, 4)
	var loaded := GameSession.new()
	assert_eq(loaded.load_text(s.save_text()), &"", "Laden")
	_assert_neutral(loaded, DAWN_HINT, "nach Laden")
	assert_eq(int(UiGame.next_of(loaded)["reactions_open"]), 2, "Karte nach Laden vollständig")
	assert_true(loaded.begin_next_step().ok, "Reaktion beginnen")
	_assert_neutral(loaded, DAWN_HINT, "offener Reaktions-Prompt")
	assert_true(loaded.undo(), "Rückgängig")
	_assert_neutral(loaded, DAWN_HINT, "nach Rückgängig")
	assert_eq(str(UiGame.next_of(loaded)["step_kind"]), "reaction", "Reaktion wieder angekündigt")


func test_warning_label_shows_the_neutral_text_in_both_languages() -> void:
	var shell := await spawn_shell(SIZE_16_10, "de")
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	assert_true(s.submit(UiGame.start(ROLES)).ok, "Start")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night", {"pack/": [2]}), "bis Nachtende")
	await press(find_button(current_screen(shell), "EndNightButton"))
	var label := find_node(current_screen(shell), "WarningsLabel") as Label
	assert_true(label.is_visible_in_tree(), "Hinweiszeile sichtbar")
	assert_eq(label.text, "Die Spielleitung bereitet den Morgen vor.", "neutraler Text DE")
	assert_true(find_button(current_screen(shell), "RevealButton").is_visible_in_tree(), "Karte verdeckt")
	settings_of(shell).call("set_language", "en")
	await frames(2)
	assert_eq(label.text, "The game master is preparing the morning.", "neutraler Text EN")
	await press(find_button(current_screen(shell), "RevealButton"))
	assert_true(find_button(current_screen(shell), "BeginStepButton").is_visible_in_tree(), "Reaktion nach „Show“ bedienbar")
	settings_of(shell).call("set_language", "de")
	await frames(2)
