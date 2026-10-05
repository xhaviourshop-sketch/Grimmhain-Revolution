extends "res://tests/ui/role_ui_case.gd"
## Paket 3: Bedienarten und gemeinsame Fehlerfälle, parametrisiert statt je Rolle kopiert. Alles über echte Controls
## (Treiber `role_ui_case.gd`, der zusätzlich bei jeder Karte prüft: Überspringen nur bei überspringbaren Schritten,
## Verzicht nur bei zulässiger Anzahl 0, Abbrechen nur bei abbrechbaren Prompts).
##   - Rollenkarten haben kein Abbrechen (nur Karteneingaben); eine Einmal-Fähigkeit wird erst durch die Nutzung verbraucht.
##   - Doppeltes Tippen auf Bestätigen sendet genau einen Befehl (Ziele, Ja/Nein, Bestätigung, Option, Vorhersage).
##   - Rückgängig verwirft eine offene Auswahl auf der Karte.
##   - Zeigekarten der Informationsrollen enthalten nur die Positivliste (`show`), keine anderen Personen oder Rollen.

const W := "werwolf"
const D := "dorfbewohner"
const V5 := [D, D, D, D, D]

## Einmal-Fähigkeiten: Besitzer → [Rollen, Vorbereitungstote, Plan für die Nutzung, Nutzungsschlüssel].
const ONE_SHOT := {
	"kriegerin-des-lichts": [["kriegerin-des-lichts", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"kriegerin-des-lichts/targets": [2]}, "kriegerin-des-lichts:attack"],
	"blutpriester": [["blutpriester", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"blutpriester/targets": [3], "blutpriester/reveal": [2]}, "blutpriester:sacrifice"],
	"faehrtenleser": [["faehrtenleser", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"faehrtenleser/use": true}, "faehrtenleser:track"],
	"schattenwanderer": [[W, "schattenwanderer", D, "amalia", "detektiv", "wahnsinniger-kutscher", "der-weise"], [], {"schattenwanderer/": [3]}, "schattenwanderer:link"],
	"seelentauscher": [["seelentauscher", W, "das-orakel", D, "amalia", "detektiv", "wahnsinniger-kutscher"], [], {"seelentauscher/targets": [3, 4], "das-orakel/target": [2]}, "seelentauscher:swap"],
	"zeitwaechter": [["zeitwaechter", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"zeitwaechter/use": true}, "zeitwaechter:freeze"],
	"grabraeuber": [["grabraeuber", W, "das-orakel", D, "amalia", "detektiv", "wahnsinniger-kutscher"], [3], {"grabraeuber/targets": [3]}, "grabraeuber:steal"],
	"koenig-lykaon": [["koenig-lykaon", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "nachtwaechter", "der-weise"], [], {"koenig-lykaon/ally": [2], "koenig-lykaon/targets": [3]}, "koenig-lykaon:convert"],
}

## Informationsrollen mit Zeigekarte: Besitzer → [Rollen, Vorbereitungstote, Plan bis zur Stufe „Gezeigt“].
const SHOW := {
	"dorfchronistin": [["dorfchronistin", W, "rattenfaenger", D, "amalia", "detektiv", "wahnsinniger-kutscher"], [], {}],
	"die-gebundenen": [["die-gebundenen", W, "die-gebundenen", D, "amalia", "detektiv", "wahnsinniger-kutscher"], [], {}],
	"waldlaeufer": [["waldlaeufer", W, "blutwolf", D, "amalia", "detektiv", "wahnsinniger-kutscher"], [], {}],
	"doktor": [["doktor", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"doktor/targets": [2, 3]}],
	"faehrtenleser": [["faehrtenleser", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"faehrtenleser/use": true}],
	"traumdeuter": [["traumdeuter", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"traumdeuter/targets": [2, 3, 4]}],
	"koenig": [["koenig", W, "schutzengel", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [4, 5, 6, 7, 8], {"koenig/targets": [3], "schutzengel/": [1]}],
	"kriegerin-des-lichts": [["kriegerin-des-lichts", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"kriegerin-des-lichts/targets": [2]}],
	"blutpriester": [["blutpriester", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"blutpriester/targets": [3], "blutpriester/reveal": [2]}],
	"die-ewigen": [["die-ewigen", W, "rattenfaenger", D, "amalia", "detektiv", "wahnsinniger-kutscher"], [], {"die-ewigen/targets": [3]}],
	"spuerhund": [["spuerhund", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"spuerhund/targets": [2, 3, 4]}],
	"kopfgeldjaeger": [["kopfgeldjaeger", W, "blutwolf", D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], [], {"day1": {"nominate": [4, 2], "execute": 2}, "kopfgeldjaeger/targets": [3, 4, 5]}],
}


func _texts(root: Node) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(root):
		out.append(text_of(c))
	return "\n".join(out)


func selection() -> Array:
	return screen().get("_selection") as Array


func _uses(actor: int, key: String) -> bool:
	return state().players[actor].ability_uses.has(key)


func test_one_shot_ability_is_consumed_only_by_use() -> void:
	for owner: String in ONE_SHOT:
		var spec: Array = ONE_SHOT[owner]
		if not await start(spec[0], spec[1]):
			return
		if not await run(spec[2], until_prompt(owner)):
			continue
		var actor := int((next()["actor_ids"] as Array)[0])
		assert_true(live("CancelPromptButton") == null, "%s: Rollenkarte ohne Abbrechen" % owner)
		assert_false(_uses(actor, str(spec[3])), "%s: vor der Nutzung nichts verbraucht" % owner)
		await run(spec[2], until_night_end())
		assert_true(_uses(actor, str(spec[3])), "%s: danach genutzt und verbraucht" % owner)
		await after_each()


## Doppeltes Tippen: Beide Signale kommen an, bevor die Karte neu gebaut ist; nur ein Befehl darf entstehen.
func _double_tap(node_name: String) -> void:
	var b := live(node_name)
	if b == null:
		fail("Button %s nicht bedienbar" % node_name)
		return
	b.pressed.emit()
	b.pressed.emit()
	await frames(3)


## Doppeltes Tippen auf einen Sitzplatz, der die feste Auswahl schließt (sofort übernommen).
func _double_tap_seat(person_id: int) -> void:
	var token := find_node(screen(), "SeatRing").call("token_for", person_id) as BaseButton
	CockpitScreen.double_tap_msec = 400  # Sperre für die eben übernommene Person, sonst in Tests aus
	token.pressed.emit()
	token.pressed.emit()
	await frames(3)
	CockpitScreen.double_tap_msec = 0


func test_double_tap_sends_one_command_for_each_answer_kind() -> void:
	# [Rollen, Plan bis zum Prompt, Besitzer, Stufe, Vorbereitung auf der Karte, Button]
	var cases: Array = [
		[["doktor", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], {}, "doktor", "targets", [2], "seat:3"],
		[["faehrtenleser", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], {}, "faehrtenleser", "use", [], "YesButton"],
		[["dorfchronistin", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], {}, "dorfchronistin", "shown", [], "CloseLayerButton"],
		[["lehrling", W, "schutzengel", "das-orakel", "waldhexe", D, "amalia"], {"schutzengel/": [6], "das-orakel/target": [6]}, "lehrling", "master", [], "seat:4"],
		[["todesprediger", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], {}, "todesprediger", "prediction", [], "ConfirmPredictionButton"],
		[["schutzengel", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"], {}, "pack", "", [], "seat:3"],
	]
	for c: Array in cases:
		if not await start(c[0]):
			return
		if await run(c[1], until_prompt(str(c[2]), str(c[3]))):
			await begin_open_step()  # Vorbereitung: Der Begin-Befehl der Karte zählt hier nicht mit
			for id: Variant in c[4]:
				await tap_seat(int(id))
			if str(c[5]) == "CloseLayerButton":
				await tap_button("ShowCardButton")  # Zeigekarte öffnen; erst das Schließen bestätigt
			var before := session().commands().size()
			if str(c[5]).begins_with("seat:"):
				await _double_tap_seat(int(str(c[5]).trim_prefix("seat:")))
			else:
				await _double_tap(str(c[5]))
			# Nachtende und eindeutiger Sieg folgen von selbst (Fenster-Diät); gezählt wird nur, was das Tippen ausgelöst hat.
			var sent := session().commands().slice(before).filter(func(cmd: Command) -> bool: return cmd.type != Command.END_NIGHT and cmd.type != Command.CONFIRM_WIN)
			assert_eq(sent.size(), 1, "%s/%s: genau ein Befehl" % [c[2], c[3]])
		await after_each()


func test_undo_discards_open_selection_on_the_card() -> void:
	if not await start(["doktor", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	await run({}, until_prompt("doktor", "targets"))
	await tap_seat(2)
	assert_eq(selection(), [2], "Auswahl vorhanden (feste Anzahl 2, noch nicht übernommen)")
	var before := session().commands().size()
	await tap_button("GmButton")
	await tap_button("UndoButton")
	await confirm_dialog()
	assert_eq(session().commands().size(), before - 1, "ein Befehl zurückgenommen")
	assert_eq(str(raw_next().get("kind")), "begin_step", "Schritt wieder angekündigt")
	assert_eq(selection(), [], "alte Auswahl verworfen")
	await tap_seat(3)
	assert_eq(last_command().type, Command.BEGIN_STEP, "Person 3 allein schließt die Auswahl nicht")


func test_role_change_discards_open_prompt_card() -> void:
	if not await start(["doktor", W, D, "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	await run({}, until_prompt("doktor", "targets"))
	await tap_seat(2)
	await tap_seat(3)
	# Rollenwechsel über die Korrekturoberfläche: der offene Prompt verfällt (Kern bricht ihn ab).
	await tap_button("GmButton")
	await tap_button("GmKind_set_role")
	await tap_seat(1)
	await tap_button("GmChooseRoleButton")
	await tap_button("Role_dorfbewohner", dialog())
	await tap_button("GmConfirmButton")
	await confirm_dialog()
	assert_eq(state().players[1].role_id, &"dorfbewohner", "Rolle gewechselt")
	assert_true(state().pending_prompt == null, "offener Prompt verworfen")
	await tap_button("CloseLayerButton")
	assert_true(find_node(screen(), "ConfirmTargetsButton") == null, "keine alte Auswahlkarte")
	assert_false(has_event("DoctorRevealed"), "keine Information aus der alten Karte")


## Positivliste: Die Zeigekarte nennt nur die Personen und Rollen aus `show` (und die eigene Rolle im Titel).
func test_show_cards_contain_only_the_positive_list() -> void:
	var person_pattern := RegEx.create_from_string("\\d+ · [A-Z]")
	for owner: String in SHOW:
		var spec: Array = SHOW[owner]
		if not await start(spec[0], spec[1]):
			return
		if not await run(spec[2], until_prompt(owner, "shown")):
			await after_each()
			continue
		var lines: Array = next().get("show", [])
		assert_false(lines.is_empty(), "%s: Positivliste nicht leer" % owner)
		var allowed_people: Array[String] = []
		var allowed_roles: Array[String] = [TranslationServer.translate(CockpitText.role_name(owner))]
		for line: Dictionary in lines:
			match str(line["kind"]):
				"person":
					if line["value"] is Dictionary:
						allowed_people.append(CockpitText.person(line["value"]))
				"persons":
					for v: Dictionary in line["value"]:
						allowed_people.append(CockpitText.person(v))
				"role":
					allowed_roles.append(TranslationServer.translate(CockpitText.role_name(str(line["value"]))))
		# Die Gebundenen zeigen ihre Liste auf der Karte selbst (ohne Zeigekarte).
		var on_card := owner == "die-gebundenen"
		var layer: Node = find_node(screen(), "ActionCard") if on_card else null
		if not on_card:
			await tap_button("ShowCardButton")
			layer = find_node(screen(), "ShowLayer")
			assert_true(layer != null, "%s: Zeigekarte" % owner)
			if layer == null:
				await after_each()
				continue
			assert_false((find_node(screen(), "Layout") as Control).visible, "%s: Cockpit verdeckt" % owner)
		var text := _texts(layer)
		for m: RegExMatch in person_pattern.search_all(text):
			assert_true(allowed_people.has(m.get_string()), "%s: Karte nennt nur freigegebene Personen, nicht %s" % [owner, m.get_string()])
		for role: StringName in RolePresentation.sorted_roles():
			var name := TranslationServer.translate(RolePresentation.name_key(role))
			if text.contains(name):
				assert_true(allowed_roles.has(name), "%s: Karte nennt nicht die Rolle %s" % [owner, name])
		if not on_card:
			await tap_button("CloseLayerButton", layer)
		await after_each()
