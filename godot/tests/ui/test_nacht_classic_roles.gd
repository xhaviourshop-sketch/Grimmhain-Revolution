extends "res://tests/ui/role_ui_case.gd"
## Nachtlauf 15.10.2026, Phase 3: Rollen-Durchlauf Classic über den Bedienweg (Karten, Knöpfe, Sitzplätze, wie die Spielleitung).
## Feste Rollenverteilung (Person i hat roles[i-1], Sitzreihenfolge = IDs, Seed 7) und feste Antworten, damit jeder Fall gezielt
## dort ankommt, wo Handbedienung selten hinkommt: Jäger-Schuss, Ritter-Fenster, Hexe, Flötenspieler, Urwolf, Weißer Wolf,
## Amor mit Liebe und Hass, Brüder/Schwestern, Seherin, Spielende, Speichern/Fortsetzen und Rückgängig.
## Jeder Fall läuft in Deutsch und Englisch. Geprüft wird: das richtige Fenster, die Knöpfe, der Regelablauf (Ereignisse und Zustand
## aus dem Regelkern, wie docs/classic/FAEHIGKEITEN.md ihn beschreibt) und dass kein Programmtext sichtbar ist.
## Vorbereitung (Start, Spielleiterkorrekturen) nutzt Kernbefehle; die geprüfte Interaktion nie.

const C := "classic-"
const D := "classic-dorfbewohner"
const W := "classic-werwolf"
const LOCALES: Array[String] = ["de", "en"]

var seen: Dictionary = {}  ## Marke -> {Sprache: Text}, für die Prüfung „Englisch ist übersetzt“
var _code_text: RegEx = RegEx.create_from_string("[a-z]+_[a-z_]+|classic-|[a-z]+\\.[a-z]+\\.[a-z_.]+|%[sdf]|\\bnull\\b|\\bSeat_")


## Wie `start`, aber mit Sprache; `direct` startet ohne Füllrollen-Kopien (Gruppenrollen brauchen die volle Besetzung beim Start).
func begin(roles: Array, locale: String, kills: Array = [], direct: bool = false) -> bool:
	shell = await spawn_shell(SIZE_16_10, locale)
	if shell == null:
		return false
	var cmds: Array[Command] = []
	if direct:
		cmds.append(Fixtures.start_roles(roles, 7))
	else:
		cmds = Fixtures.start_with_copies(Fixtures.legalize(roles), 7, {})
	for c: Command in cmds:
		var r := session().submit(c)
		if not r.ok:
			fail("Start abgelehnt: %s" % r.error)
			return false
	for id: Variant in kills:
		var r := session().submit(CorrectionFixtures.gm("kill", {"target_id": int(id), "trigger_effects": false}, "Vorbereitung"))
		if not r.ok:
			fail("Vorbereitung kill %s abgelehnt: %s" % [id, r.error])
			return false
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return true


func _locales(body: Callable) -> void:
	for loc: String in LOCALES:
		await body.call(loc)
		await after_each()


func _text() -> String:
	var out: Array[String] = []
	for c: Control in text_controls(shell):
		var t := text_of(c).strip_edges()
		if not t.is_empty():
			out.append(t)
	return "\n".join(out)


## Kein Programmtext (Schlüssel, snake_case, Platzhalter) in irgendeinem sichtbaren Text.
func _clean(context: String) -> void:
	for c: Control in text_controls(shell):
		var t := text_of(c)
		var m := _code_text.search(t)
		if m != null:
			fail("%s: Programmtext sichtbar: „%s“ (%s)" % [context, t.left(80), m.get_string()])


## Merkt den Fenstertext der Sprache unter `tag`.
func _note(tag: String, loc: String) -> void:
	_clean("%s/%s" % [tag, loc])
	if not seen.has(tag):
		seen[tag] = {}
	(seen[tag] as Dictionary)[loc] = _text()


func _assert_translated(tag: String) -> void:
	var pair: Dictionary = seen.get(tag, {})
	assert_true(pair.has("de") and pair.has("en"), "%s: beide Sprachen gesehen" % tag)
	if pair.has("de") and pair.has("en"):
		assert_true(pair["de"] != pair["en"], "%s: Englisch weicht vom Deutschen ab" % tag)


func _name(id: int) -> String:
	return state().players[id].name


func _btn_text(node_name: String) -> String:
	var b := live(node_name)
	return b.text if b != null else ""


func _over() -> bool:
	return state().phase == Phase.GAME_OVER


func _until_decided() -> Callable:
	return func(n: Dictionary) -> bool: return ["game_over", "win_decision"].has(str(n.get("kind"))) or state().phase == Phase.GAME_OVER


## Bestätigt einen offenen Siegvorschlag über die Karte (ein Tipp), falls einer ansteht.
func _confirm_win_if_open() -> void:
	var n := raw_next()
	if str(n.get("kind")) == "win_decision":
		await tap_button("ConfirmWinButton_%d" % int((n["candidates"] as Array)[0]["id"]))
		await frames(3)


## Eine ganze Nacht ab der Nachtkarte (auch ab Tageskarte davor) bis Tagesbeginn oder Spielende/Siegvorschlag.
func _night(plan: Dictionary) -> void:
	await run({}, until_kind("start_night"))
	var n0 := state().night_number
	await run(plan, func(n: Dictionary) -> bool: return (state().night_number > n0 and state().phase != Phase.NIGHT) or ["game_over", "win_decision", "end_night"].has(str(n.get("kind"))))


func _died(id: int) -> bool:
	return events("SeatDied").any(func(e: Dictionary) -> bool: return int((e["data"] as Dictionary)["target_id"]) == id)


func _died_by(id: int, cause: String) -> bool:
	return events("SeatDied").any(func(e: Dictionary) -> bool: return int((e["data"] as Dictionary)["target_id"]) == id and str((e["data"] as Dictionary)["cause"]) == cause)


func _data(type: String, index: int = 0) -> Dictionary:
	var list := events(type)
	return (list[index] as Dictionary)["data"] if list.size() > index else {}


# --- Hexe ------------------------------------------------------------------------------------------------------

func test_witch_heal_only() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "hexe", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [3], "waldhexe/heal": true, "waldhexe/poison": false}
		assert_true(await run(plan, until_prompt("waldhexe", "heal")), "bis zur Heilfrage")
		assert_true(live("YesButton") != null and live("NoButton") != null, "%s: Ja und Nein stehen auf der Karte" % loc)
		assert_true(next().get("show", []) is Array, "Karte des Opfers")
		_note("hexe-heilen", loc)
		await run(plan, until_night_end())
		var acted := _data("WitchActed")
		assert_true(bool(acted.get("heal_used")) and not bool(acted.get("poison_used")), "%s: nur geheilt" % loc)
		assert_eq(int(acted.get("saved_id", -1)), 3, "das Rudelopfer ist gerettet")
		assert_false(_died(3), "%s: Person 3 lebt" % loc)
		assert_true(has_event("KillPrevented"), "Rettung im Protokoll"))
	_assert_translated("hexe-heilen")


func test_witch_poison_only() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "hexe", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [3], "waldhexe/heal": false, "waldhexe/poison": true, "waldhexe/poison_target": [5]}
		assert_true(await run(plan, until_prompt("waldhexe", "poison_target")), "bis zur Giftwahl")
		_note("hexe-gift", loc)
		assert_false(live("ConfirmTargetsButton") != null and next().get("auto_commit", false), "Wahl über Sitzplatz")
		await run(plan, until_night_end())
		var acted := _data("WitchActed")
		assert_true(not bool(acted.get("heal_used")) and bool(acted.get("poison_used")), "%s: nur vergiftet" % loc)
		assert_true(_died_by(5, "WITCH_POISON"), "%s: Person 5 durch Gift" % loc)
		assert_true(_died_by(3, "NIGHT_KILL"), "%s: Person 3 starb ungeheilt" % loc))
	_assert_translated("hexe-gift")


func test_witch_heal_and_poison() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "hexe", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [3], "waldhexe/heal": true, "waldhexe/poison": true, "waldhexe/poison_target": [5]}
		await run(plan, until_night_end())
		var acted := _data("WitchActed")
		assert_true(bool(acted.get("heal_used")) and bool(acted.get("poison_used")), "%s: beide Tränke" % loc)
		assert_false(_died(3), "%s: Opfer gerettet" % loc)
		assert_true(_died_by(5, "WITCH_POISON"), "%s: Gift wirkt" % loc)
		# Beide Tränke sind verbraucht: in der nächsten Nacht wacht die Hexe nicht mehr auf.
		await run(plan, until_day(1, "end_day"))
		await run(plan, until_kind("start_night"))
		await tap_button("StartNightButton")
		var asked := false
		for i: int in 6:
			var n := next()
			if str(n.get("kind")) == "prompt" and str(n.get("owner")) == "waldhexe":
				asked = true
			if str(n.get("kind")) in ["day", "end_night"]:
				break
			await step({"pack/": [6]})
		assert_false(asked, "%s: keine Frage mehr an die Hexe ohne Tränke" % loc))


# --- Jäger -------------------------------------------------------------------------------------------------------

func test_hunter_shot() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "jaeger", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [2], "reaction/curse": [4]}
		assert_true(await run(plan, until_prompt("reaction")), "Jäger-Fenster nach dem Tod")
		var n := next()
		assert_eq(str(n.get("role_id")), "classic-jaeger", "Fenster gehört dem Jäger")
		assert_eq(n.get("counts"), [0, 1], "ein Schuss oder keiner")
		assert_true(live("DeclineButton") != null, "%s: „Kein Schuss“ ist wählbar" % loc)
		if loc == "de":
			assert_true(_btn_text("DeclineButton").contains("Kein Schuss"), "Knopf heißt Kein Schuss: %s" % _btn_text("DeclineButton"))
		_note("jaeger-schuss", loc)
		await run(plan, until_event("ReactionResolved"))
		assert_eq(str(_data("ReactionResolved").get("outcome")), "cursed", "%s: Schuss trifft" % loc)
		assert_true(_died(4) and _died(2), "%s: Jäger und Ziel tot" % loc))
	_assert_translated("jaeger-schuss")


func test_hunter_no_shot() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "jaeger", D, D, D, D, D, D], loc):
			return
		assert_true(await run({"pack/": [2], "reaction/curse": []}, until_event("ReactionResolved")), "Jäger verzichtet")
		assert_eq(str(_data("ReactionResolved").get("outcome")), "declined", "%s: kein Schuss" % loc)
		assert_eq(events("SeatDied").size(), 1, "%s: nur der Jäger starb" % loc))


# --- Ritter ------------------------------------------------------------------------------------------------------

func test_knight_one_wolf_dies_without_question_and_village_wins() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "ritter", D, D, D, D, D, D], loc):
			return
		await run({"pack/": [2]}, _until_decided())
		await _confirm_win_if_open()
		assert_false(has_event("ReactionQueued") and not has_event("ReactionResolved"), "keine offene Frage")
		assert_true(_died_by(1, "KNIGHT_STRIKE"), "%s: der einzige Wolf stirbt durch das Schwert" % loc)
		assert_true(_over(), "%s: Spielende" % loc)
		await frames(3)
		_note("sieg-dorf", loc)
		if loc == "de":
			assert_true(_text().contains("Das Dorf siegt"), "Siegbildschirm: %s" % _text())
		assert_eq(str(_data("WinConfirmed").get("winner", {}).get("kind")), "village", "Dorf hat gewonnen"))
	_assert_translated("sieg-dorf")


func test_knight_two_wolves_left_and_right_buttons() -> void:
	var sides := {"de": "left", "en": "right"}
	var expected := {"left": 4, "right": 1}
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "ritter", D, W, D, D, D, D], loc):
			return
		assert_true(await run({"pack/": [2]}, until_prompt("reaction")), "Ritter-Fenster")
		var n := next()
		assert_eq(str(n.get("reaction_kind")), "knight", "Ritter-Reaktion")
		assert_eq(n.get("knight_dirs"), {"left": 4, "right": 1}, "Links Person 4, Rechts Person 1")
		var side: String = sides[loc]
		assert_true(live("KnightDir_left") != null and live("KnightDir_right") != null, "Links und Rechts als Knöpfe")
		assert_true(_btn_text("KnightDir_left").contains(_name(4)), "%s: Linksknopf nennt den Wolf: %s" % [loc, _btn_text("KnightDir_left")])
		assert_true(_btn_text("KnightDir_right").contains(_name(1)), "%s: Rechtsknopf nennt den Wolf: %s" % [loc, _btn_text("KnightDir_right")])
		_note("ritter-fenster", loc)
		await tap_button("KnightDir_%s" % side)
		await frames(3)
		var target: int = expected[side]
		assert_true(_died_by(target, "KNIGHT_STRIKE"), "%s: gewählter Wolf %d stirbt" % [loc, target])
		var other: int = 1 if target == 4 else 4
		assert_false(_died(other), "%s: der andere Wolf lebt" % loc))
	_assert_translated("ritter-fenster")


func test_knight_with_many_wolves_picks_nearest_alive_wolf_each_side() -> void:
	await _locales(func(loc: String) -> void:
		# Ritter auf Platz 5; Wölfe auf 1, 6, 8. Links (Uhrzeigersinn) der nächste lebende Wolf: 6; rechts gegen den Uhrzeigersinn: 1.
		if not await begin([W, D, D, D, C + "ritter", W, D, W], loc):
			return
		assert_true(await run({"pack/": [5]}, until_prompt("reaction")), "Ritter-Fenster mit drei Wölfen")
		assert_eq(next().get("knight_dirs"), {"left": 6, "right": 1}, "%s: nächster Wolf je Richtung" % loc)
		assert_true((find_node(screen(), "SeatRing").call("token_for", 8) as BaseButton).disabled, "der dritte Wolf ist nicht wählbar")
		await tap_seat(6)
		await frames(3)
		assert_true(_died_by(6, "KNIGHT_STRIKE"), "%s: Tipp auf den linken Wolf" % loc)
		assert_false(_died(1) or _died(8), "%s: andere Wölfe leben" % loc))
	# Tote Wölfe werden übersprungen: ist 6 vorab tot, ist links der Wolf auf 8.
	await _locales(func(loc: String) -> void:
		if not await begin([W, D, D, D, C + "ritter", W, D, W], loc, [6]):
			return
		assert_true(await run({"pack/": [5]}, until_prompt("reaction")), "Ritter-Fenster, ein Wolf vorab tot")
		assert_eq(next().get("knight_dirs"), {"left": 8, "right": 1}, "%s: toter Wolf wird übersprungen" % loc))


# --- Amor ----------------------------------------------------------------------------------------------------------

func test_amor_love_kills_the_partner() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "amor", D, D, D, D, D, D], loc):
			return
		var plan := {"loki/targets": [3, 4], "loki/mode": true, "pack/": [3]}
		assert_true(await run(plan, until_prompt("loki", "targets")), "Amor-Fenster")
		assert_true(live("YesButton") != null and live("NoButton") != null, "%s: Liebe oder Hass wählbar" % loc)
		_note("amor-wahl", loc)
		await run(plan, until_night_end())
		assert_eq(str(_data("LokiBound").get("kind")), "love", "%s: Liebende" % loc)
		assert_true(_died_by(3, "NIGHT_KILL"), "Rudelopfer 3")
		assert_true(_died(4), "%s: der Partner stirbt aus Liebeskummer" % loc))
	_assert_translated("amor-wahl")


func test_amor_hate_makes_rivals() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "amor", D, D, D, D, D, D], loc):
			return
		var plan := {"loki/targets": [3, 4], "loki/mode": false, "pack/": [3]}
		await run(plan, until_night_end())
		assert_eq(str(_data("LokiBound").get("kind")), "rival", "%s: Feinde" % loc)
		assert_false(_died(4), "%s: Feindschaft löst keinen Liebeskummer aus" % loc))


# --- Flötenspieler -------------------------------------------------------------------------------------------------

func test_piper_one_and_two() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "floetenspieler", D, D, D, D, D, D], loc):
			return
		assert_true(await run({"pack/": [8], "rattenfaenger/": [3]}, until_prompt("rattenfaenger")), "Flötenspieler-Fenster")
		assert_true(live("PipeOneButton") != null and live("PipeTwoButton") != null, "%s: Eine oder zwei Personen" % loc)
		_note("floete-zahl", loc)
		await run({"pack/": [8], "rattenfaenger/": [3]}, until_event("Charmed"))
		assert_eq((_data("Charmed")["target_ids"] as Array).size(), 1, "%s: eine Person verzaubert" % loc))
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "floetenspieler", D, D, D, D, D, D], loc):
			return
		await run({"pack/": [8], "rattenfaenger/": [3, 4]}, until_event("Charmed"))
		assert_eq((_data("Charmed")["target_ids"] as Array).size(), 2, "%s: zwei Personen verzaubert" % loc))
	_assert_translated("floete-zahl")


func test_piper_wins_alone_when_everyone_is_charmed() -> void:
	await _locales(func(loc: String) -> void:
		# Lebende: Flötenspieler 1, Wolf 2, Dorf 3, 4, 5 (Person 6 vorab tot).
		if not await begin([C + "floetenspieler", W, D, D, D, D], loc, [6]):
			return
		await run({"pack/": [4], "rattenfaenger/": [2, 3]}, until_night_end())
		await run({}, until_kind("start_night"))
		await run({"pack/": [3], "rattenfaenger/": [5]}, _until_decided())
		await _confirm_win_if_open()
		assert_true(_over(), "%s: Spielende" % loc)
		var winner: Dictionary = _data("WinConfirmed").get("winner", {})
		assert_eq(str(winner.get("kind")), "solo", "%s: Einzelsieg" % loc)
		assert_eq(winner.get("beneficiary_ids"), [1], "Flötenspieler gewinnt allein"))


# --- Urwolf ------------------------------------------------------------------------------------------------------------

func test_urwolf_turns_the_victim_or_lets_it_die() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([C + "urwolf", D, D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [2], C + "urwolf/use": true}
		assert_true(await run(plan, until_prompt(C + "urwolf", "use")), "Urwolf-Frage")
		assert_true(live("YesButton") != null and live("NoButton") != null, "Ja oder Nein")
		_note("urwolf-frage", loc)
		await run(plan, until_night_end())
		assert_false(_died(2), "%s: das Opfer stirbt nicht" % loc)
		assert_true(state().players[2].counts_as_wolf, "%s: das Opfer ist jetzt ein Wolf" % loc))
	await _locales(func(loc: String) -> void:
		if not await begin([C + "urwolf", D, D, D, D, D, D, D], loc):
			return
		await run({"pack/": [2], C + "urwolf/use": false}, until_night_end())
		assert_true(_died(2), "%s: ohne Verwandlung stirbt das Opfer" % loc)
		assert_false(state().players[2].counts_as_wolf, "%s: kein neuer Wolf" % loc))
	_assert_translated("urwolf-frage")


# --- Weißer Wolf -----------------------------------------------------------------------------------------------------------

func test_white_wolf_wakes_every_second_night_and_wins_alone() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "weisser-wolf", D, D, D, D, D, D], loc):
			return
		# Nacht 1: kein Einzelschritt; Nacht 2: Frage mit Verzicht möglich; er tötet den anderen Wolf.
		await run({"pack/": [8]}, until_night_end())
		assert_false(has_event("LoneWolfStruck"), "%s: Nacht 1 ohne Einzelschritt" % loc)
		await run({}, until_kind("start_night"))
		await tap_button("StartNightButton")
		var plan := {"pack/": [7], "rachsuechtiger-wolf/": [1]}
		assert_true(await run(plan, until_prompt("rachsuechtiger-wolf")), "Nacht 2: Fenster des Weißen Wolfs")
		assert_true(live("DeclineButton") != null, "%s: Verzicht möglich" % loc)
		_note("weisser-wolf", loc)
		await run(plan, func(n: Dictionary) -> bool: return state().night_number >= 2 and state().phase != Phase.NIGHT)
		assert_eq(int(_data("LoneWolfStruck").get("target_id", -1)), 1, "%s: er tötet den Wolf auf Platz 1" % loc)
		assert_true(_died(1), "Person 1 tot")
		# Weiter bis nur noch er lebt: Rudel tötet 6 (Nacht 3), 5 (Nacht 4) und Einzelschlag 3, dann 4 (Nacht 5).
		await _night({"pack/": [6]})
		await _night({"pack/": [5], "rachsuechtiger-wolf/": [3]})
		await _night({"pack/": [4]})
		await _confirm_win_if_open()
		assert_true(_over(), "%s: Spielende" % loc)
		var winner: Dictionary = _data("WinConfirmed").get("winner", {})
		assert_eq(str(winner.get("kind")), "solo", "%s: Einzelsieg" % loc)
		assert_eq(winner.get("beneficiary_ids"), [2], "Weißer Wolf gewinnt allein")
		await frames(3)
		_note("sieg-weisser-wolf", loc))
	_assert_translated("weisser-wolf")
	_assert_translated("sieg-weisser-wolf")


# --- Seherin ----------------------------------------------------------------------------------------------------------------

func test_seer_sees_the_true_role() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([C + "urwolf", C + "seherin", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [8], C + "urwolf/use": false, "das-orakel/target": [1]}
		assert_true(await run(plan, until_prompt("das-orakel", "shown")), "Seherin: Ergebnis")
		_note("seherin-ergebnis", loc)
		await tap_button("ShowCardButton")
		await frames(2)
		var layer := find_node(shell, "ShowLayer")
		assert_true(layer != null, "Zeigekarte der Seherin")
		_clean("seherin-karte/%s" % loc)
		await tap_button("CloseLayerButton", shell)
		await run(plan, until_night_end())
		assert_eq(str(_data("InfoRevealed").get("shown_role")), "classic-urwolf", "%s: die Seherin sieht die wahre Rolle" % loc)
		assert_true(has_event("InfoRevealed"), "%s: Auskunft im Protokoll" % loc))


# --- Brüder und Schwestern --------------------------------------------------------------------------------------------------

func test_brothers_and_sisters_see_each_other_in_night_one() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "drei-brueder", C + "drei-brueder", C + "drei-brueder", C + "zwei-schwestern", C + "zwei-schwestern", D, D], loc, [], true):
			return
		await run({"pack/": [8]}, until_night_end())
		var shown := events("BoundRevealed")
		assert_eq(shown.size(), 5, "%s: fünf Gebundene erfahren es" % loc)
		for e: Dictionary in shown:
			var d: Dictionary = e["data"]
			var owner := int(d.get("seat_id", d.get("target_id", d.get("bound_id", -1))))
			var others: Array = d["other_bound_ids"]
			if [2, 3, 4].has(owner):
				assert_eq(others.size(), 2, "Bruder %d sieht zwei andere" % owner)
			elif [5, 6].has(owner):
				assert_eq(others.size(), 1, "Schwester %d sieht die andere" % owner)
		assert_true(_text().length() > 0, "Anzeige vorhanden"))


# --- Spielende ------------------------------------------------------------------------------------------------------------------

func test_village_wins_by_execution() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, D, D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [8], "day1": {"nominate": [2, 1], "execute": 1}}
		await run(plan, _until_decided())
		await _confirm_win_if_open()
		assert_true(_over(), "%s: Spielende nach der Hinrichtung" % loc)
		assert_eq(str(_data("WinConfirmed").get("winner", {}).get("kind")), "village", "Dorf")
		await frames(3)
		_note("sieg-dorf-hinrichtung", loc))
	_assert_translated("sieg-dorf-hinrichtung")


func test_wolves_win_by_parity() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, D, D, D, D, D, D, D], loc, [4, 5, 6, 7]):
			return
		await run({"pack/": [8]}, until_night_end())
		await run({}, until_kind("start_night"))
		await run({"pack/": [3]}, _until_decided())
		await _confirm_win_if_open()
		assert_true(_over(), "%s: Spielende" % loc)
		assert_eq(str(_data("WinConfirmed").get("winner", {}).get("kind")), "wolves", "Wölfe")
		await frames(3)
		_note("sieg-woelfe", loc)
		if loc == "de":
			assert_true(_text().contains("Die Werwölfe siegen"), "Siegbildschirm: %s" % _text()))
	_assert_translated("sieg-woelfe")


# --- Fehlklick, Rückgängig, Speichern und Fortsetzen -------------------------------------------------------------------------------

func test_undo_after_a_wrong_pick_reopens_the_question() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "engel", D, D, D, D, D, D], loc):
			return
		assert_true(await run({"pack/": [3]}, until_prompt("pack")), "Opferwahl")
		var count := session().commands().size()
		await tap_seat(3)  # Fehlklick: falsches Opfer
		await frames(2)
		assert_true(session().commands().size() > count, "Antwort angenommen")
		await wait_seconds(3.4)  # das Dock zeigt „Rückgängig“ erst nach der 3-Sekunden-Leiste der Karte
		await tap_button("DockUndoButton")
		await frames(2)
		assert_true(dialog().call("is_open"), "%s: Rückfrage vor dem Rückgängigmachen" % loc)
		_note("rueckgaengig", loc)
		await tap_button("ConfirmButton", dialog())
		await frames(3)
		# Nach dem letzten Nachtschritt folgt das Nachtende von selbst: das erste Rückgängig nimmt nur dieses zurück (Karte „Nacht abschließen“),
		# das zweite die Opferwahl selbst.
		var presses := 1
		while str(next().get("owner")) != "pack" and presses < 4:
			await tap_button("DockUndoButton")
			await frames(2)
			await tap_button("ConfirmButton", dialog())
			await frames(3)
			presses += 1
		assert_eq(session().commands().size(), count + 1, "%s: Wahl zurückgenommen (nur der Beginn des Schritts bleibt)" % loc)
		assert_eq(str(next().get("owner")), "pack", "%s: die Opferwahl ist wieder offen" % loc)
		await tap_seat(4)
		await frames(2)
		assert_true(session().commands().size() > count, "neue Antwort angenommen"))
	_assert_translated("rueckgaengig")


func test_save_and_resume_in_the_middle_of_a_night_stage() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "hexe", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [3], "waldhexe/heal": true, "waldhexe/poison": true, "waldhexe/poison_target": [5]}
		assert_true(await run(plan, until_prompt("waldhexe", "poison")), "mitten in der Hexen-Frage")
		var before_hash := session().state_hash()
		var before_cmds := session().commands().size()
		var round := session().round_id()
		var dir := (context_of(shell) as AppContext).saves.base_dir
		assert_true(bool((context_of(shell) as AppContext).saves.last_status.get("ok", false)), "gespeichert")
		_spawned.erase(shell)
		shell.get_parent().remove_child(shell)
		shell.free()
		await frames(2)
		shell = await spawn_shell(SIZE_16_10, loc)
		(context_of(shell) as AppContext).saves.base_dir = dir
		await navigate(shell, &"main_menu")
		await navigate(shell, &"continue")
		assert_true(find_node(screen(), "ResumeButton_%s" % round) != null, "%s: Partie steht in der Liste" % loc)
		await tap_button("ResumeButton_%s" % round)
		assert_eq(String(current_id(shell)), "cockpit", "Fortsetzen öffnet das Cockpit")
		assert_eq(session().state_hash(), before_hash, "%s: Zustand identisch" % loc)
		assert_eq(session().commands().size(), before_cmds, "keine Befehle verloren oder doppelt")
		assert_eq(str(next().get("owner")), "waldhexe", "dieselbe Frage ist wieder offen")
		assert_eq(str(next().get("stage")), "poison", "auf derselben Stufe")
		await run(plan, until_night_end())
		assert_true(_died_by(5, "WITCH_POISON"), "%s: nach dem Fortsetzen läuft die Nacht weiter" % loc)
		assert_false(_died(3), "Rettung bleibt erhalten"))


# --- Regelstellen aus docs/classic/FAEHIGKEITEN.md ---------------------------------------------------------------------------------

func test_knight_has_no_effect_when_executed_or_poisoned() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "ritter", D, W, D, D, D, D], loc):
			return
		var plan := {"pack/": [8], "day1": {"nominate": [3, 2], "execute": 2}}
		await _night(plan)
		await run(plan, until_day(1, "end_day"))
		assert_true(_died(2), "%s: Ritter hingerichtet" % loc)
		assert_false(has_event("ReactionQueued"), "%s: keine Ritter-Wirkung bei Hinrichtung" % loc)
		assert_false(_died(1) or _died(4), "kein Wolf stirbt"))


func test_hunter_shoots_after_an_execution() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "jaeger", D, D, D, D, D, D], loc):
			return
		var plan := {"pack/": [8], "day1": {"nominate": [3, 2], "execute": 2}, "reaction/curse": [1]}
		await run(plan, until_event("ReactionResolved"))
		assert_eq(str(_data("ReactionResolved").get("outcome")), "cursed", "%s: Jäger schießt nach der Hinrichtung" % loc)
		assert_true(_died(1) and _died(2), "Jäger und Ziel tot")
		await run(plan, _until_decided())
		await _confirm_win_if_open()
		assert_true(_over(), "%s: der Schuss auf den letzten Wolf beendet die Partie" % loc))


func test_amor_may_choose_himself() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "amor", D, D, D, D, D, D], loc):
			return
		assert_true(await run({"loki/targets": [2, 3], "loki/mode": true, "pack/": [8]}, until_prompt("loki", "targets")), "Amor-Fenster")
		assert_true((next().get("allowed_ids") as Array).has(2), "%s: Amor darf sich selbst wählen" % loc)
		await run({"loki/targets": [2, 3], "loki/mode": true, "pack/": [3]}, until_night_end())
		assert_true(_died(3) and _died(2), "%s: stirbt der Partner, stirbt Amor mit" % loc))


func test_elder_survives_the_first_pack_attack_only() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "alte", D, D, D, D, D, D], loc):
			return
		await _night({"pack/": [2]})
		assert_false(_died(2), "%s: erster Rudelangriff überlebt" % loc)
		await _night({"pack/": [2]})
		assert_true(_died(2), "%s: zweiter Angriff tötet" % loc))


func test_angel_protects_against_the_pack_but_not_against_poison() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "engel", C + "hexe", D, D, D, D, D], loc):
			return
		var plan := {"schutzengel/": [4], "pack/": [4], "waldhexe/heal": false, "waldhexe/poison": true, "waldhexe/poison_target": [4]}
		await run(plan, until_night_end())
		assert_true(_died_by(4, "WITCH_POISON"), "%s: Gift geht durch den Schutz" % loc)
		assert_false(_died_by(4, "NIGHT_KILL"), "Rudelangriff wurde abgewehrt"))


func test_urwolf_asks_only_once_per_game() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([C + "urwolf", D, D, D, D, D, D, D], loc):
			return
		await _night({"pack/": [2], C + "urwolf/use": false})
		await run({}, until_kind("start_night"))
		await tap_button("StartNightButton")
		var asked := false
		for i: int in 5:
			var n := next()
			if str(n.get("kind")) == "prompt" and str(n.get("owner")) == C + "urwolf":
				asked = true
			if str(n.get("kind")) in ["day", "end_night"]:
				break
			await step({"pack/": [3]})
		assert_true(asked, "%s: ein Verzicht verbraucht die Fähigkeit nicht, die Frage kommt in der nächsten Nacht wieder" % loc))


func test_two_win_candidates_ask_the_game_master() -> void:
	await _locales(func(loc: String) -> void:
		# Nur Flötenspieler 1, Wolf 2 und Dorf 3 leben: Nach der Nacht stehen Wolfsparität und Flötensieg gleichzeitig an.
		if not await begin([C + "floetenspieler", W, D, D, D, D], loc, [4, 5, 6]):
			return
		assert_true(await run({"pack/": [3], "rattenfaenger/": [2]}, until_kind("win_decision")), "%s: Siegvorschlag" % loc)
		var cands: Array = next()["candidates"]
		assert_eq(cands.size(), 2, "%s: zwei Siegkandidaten" % loc)
		assert_true(live("RejectWinButton") != null, "%s: Ablehnen ist möglich" % loc)
		for c: Dictionary in cands:
			assert_true(live("ConfirmWinButton_%d" % int(c["id"])) != null, "Bestätigen je Kandidat")
		_note("sieg-zwei-kandidaten", loc)
		var piper_id := 0
		for c: Dictionary in cands:
			if str(c["kind"]) == "solo":
				piper_id = int(c["id"])
		assert_true(piper_id != 0, "der Flötenspieler ist Kandidat")
		await tap_button("ConfirmWinButton_%d" % piper_id)
		await frames(3)
		assert_true(_over(), "%s: Spielende" % loc)
		assert_eq(str(_data("WinConfirmed").get("winner", {}).get("kind")), "solo", "Flötenspieler bestätigt"))
	_assert_translated("sieg-zwei-kandidaten")


func test_rejecting_all_win_candidates_continues_the_game() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([C + "floetenspieler", W, D, D, D, D], loc, [4, 5, 6]):
			return
		assert_true(await run({"pack/": [3], "rattenfaenger/": [2]}, until_kind("win_decision")), "%s: Siegvorschlag" % loc)
		await tap_button("RejectWinButton")
		assert_true(await confirm_dialog("Test: Tisch ist anderer Meinung"), "Begründung eingegeben und bestätigt")
		await frames(3)
		assert_false(_over(), "%s: die Partie läuft weiter" % loc)
		assert_true(has_event("WinRejected") or str(raw_next().get("kind")) != "win_decision", "Vorschlag abgelehnt"))


# --- Wechselwirkungen (Regelstellen aus FAEHIGKEITEN.md Nr. 5, 14, 19) -------------------------------------------------------------

func test_knight_swings_only_when_the_pack_really_kills_him() -> void:
	await _locales(func(loc: String) -> void:
		# Von der Hexe gerettet: er stirbt nicht, also kein Schwerthieb.
		if not await begin([W, C + "ritter", C + "hexe", D, D, D, D, D], loc):
			return
		await run({"pack/": [2], "waldhexe/heal": true, "waldhexe/poison": false}, until_night_end())
		assert_false(_died(2) or has_event("ReactionQueued"), "%s: gerettet, kein Hieb" % loc))
	await _locales(func(loc: String) -> void:
		# Vom Engel geschützt: ebenso.
		if not await begin([W, C + "ritter", C + "engel", D, D, D, D, D], loc):
			return
		await run({"pack/": [2], "schutzengel/": [2]}, until_night_end())
		assert_false(_died(2) or has_event("ReactionQueued"), "%s: geschützt, kein Hieb" % loc))
	await _locales(func(loc: String) -> void:
		# Vom Weißen Wolf getötet: unaufhaltsam und ohne Ritter-Wirkung (Nacht 2).
		if not await begin([W, C + "weisser-wolf", C + "ritter", D, D, D, D, D], loc):
			return
		await _night({"pack/": [8]})
		await _night({"pack/": [7], "rachsuechtiger-wolf/": [3]})
		assert_true(_died_by(3, "LONE_WOLF_KILL"), "%s: der Ritter stirbt durch den Weißen Wolf" % loc)
		assert_false(has_event("ReactionQueued"), "kein Hieb nach dem Einzelschlag"))


func test_hunter_shoots_when_poisoned_or_struck_by_the_white_wolf() -> void:
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "hexe", C + "jaeger", D, D, D, D, D], loc):
			return
		var plan := {"pack/": [8], "waldhexe/heal": false, "waldhexe/poison": true, "waldhexe/poison_target": [3], "reaction/curse": [4]}
		await run(plan, until_event("ReactionResolved"))
		assert_true(_died_by(3, "WITCH_POISON"), "%s: Jäger vergiftet" % loc)
		assert_eq(str(_data("ReactionResolved").get("outcome")), "cursed", "%s: er darf noch schießen" % loc)
		assert_true(_died(4), "Schuss trifft Person 4"))
	await _locales(func(loc: String) -> void:
		if not await begin([W, C + "weisser-wolf", C + "jaeger", D, D, D, D, D], loc):
			return
		await _night({"pack/": [8]})
		var plan := {"pack/": [7], "rachsuechtiger-wolf/": [3], "reaction/curse": [1]}
		await _night(plan)
		await run(plan, until_event("ReactionResolved"))
		assert_true(_died(3), "%s: Jäger vom Weißen Wolf getötet" % loc)
		assert_true(has_event("ReactionResolved") and _died(1), "%s: der Jäger nimmt den Wolf mit" % loc))
