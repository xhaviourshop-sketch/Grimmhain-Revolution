extends UiTestCase
## DI-03 in der Oberfläche: Angesagte Todeseffekte stehen im öffentlichen Teil des Morgenberichts und bei den
## Tagestoden, mit Effekt und Rolle zum Ereigniszeitpunkt (auch in Wiederbelebungsrunden, wo die Karten der Toten
## sonst verdeckt bleiben). Der öffentliche Teil enthält nur die Positivliste; Ursachen, Schutz und Markierungen
## erscheinen nie. Save/Load und Replay erzeugen dieselben Ansagen.

const UiGame := preload("res://tests/ui/ui_game.gd")
const W := "werwolf"
const D := "dorfbewohner"
const EFFECT_ENTRY_KEYS := ["effect", "replaced", "role_id", "source", "source_id", "targets"]
const PUBLIC_KEYS := ["deaths", "effects", "notices", "reveal_roles", "revived"]
const EFFECTS := ["reaper_curse", "knight_strike", "possessed_drag", "coachman_crash", "sage_curse", "heartbreak", "red_chain", "shadow_link"]


func _cockpit(roles: Array, locale: String = "de") -> Control:
	var shell := await spawn_shell(SIZE_16_10, locale)
	if shell == null:
		return null
	var r: CommandResult = session_of(shell).call("submit", UiGame.start(roles))
	assert_true(r.ok, "Start (%s)" % r.error)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	return shell


func _card_text(shell: Control) -> String:
	var out: Array[String] = []
	for c: Control in text_controls(find_node(current_screen(shell), "ActionCard")):
		out.append(text_of(c))
	return "\n".join(out)


## Ritter B (Platz 2) stirbt durch das Rudel, der nächste Wolf A (Platz 1) stirbt mit.
func _knight_roles(revival: bool) -> Array:
	return [W, "ritter", D, D, "kutscher" if revival else D, W]


func _knight_morning(s: GameSession) -> void:
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night", {"pack/": [2]}), "Rudel wählt den Ritter")
	assert_true(s.end_night().ok, "Morgen")


func test_morning_card_announces_the_knight_effect_with_role_in_german() -> void:
	var shell := await _cockpit(_knight_roles(false))
	if shell == null:
		return
	var s := session_of(shell) as GameSession
	_knight_morning(s)
	await frames(3)
	var text := _card_text(shell)
	assert_true(text.contains("„B war Ritter und reißt A mit in den Tod.“"), "Ansage mit Effekt und Rolle: %s" % text)
	assert_true(text.contains("A (Werwolf)") and text.contains("B (Ritter)"), "Runde ohne Wiederbelebung: Tote mit Rolle")


func test_morning_card_announces_the_knight_effect_in_english() -> void:
	var shell := await _cockpit(_knight_roles(false), "en")
	if shell == null:
		return
	_knight_morning(session_of(shell) as GameSession)
	await frames(3)
	assert_true(_card_text(shell).contains("“B was Knight and takes A down too.”"), "englische Ansage: %s" % _card_text(shell))


func test_revival_round_hides_death_roles_but_the_effect_names_the_role() -> void:
	var shell := await _cockpit(_knight_roles(true))
	if shell == null:
		return
	_knight_morning(session_of(shell) as GameSession)
	await frames(3)
	var text := _card_text(shell)
	assert_true(text.contains("„B war Ritter und reißt A mit in den Tod.“"), "Effekt nennt die Rolle bewusst: %s" % text)
	assert_false(text.contains("A (Werwolf)") or text.contains("B (Ritter)"), "gewöhnliche Todesansage ohne Rollen (DI-01)")
	assert_true(text.contains("A, B") or text.contains("B, A"), "Namen der Toten ohne Rolle: %s" % text)


func test_public_part_contains_only_the_positive_list() -> void:
	var s := UiGame.session(_knight_roles(false))
	_knight_morning(s)
	var report := s.morning_report()
	var public: Dictionary = report["public"]
	var keys: Array = public.keys()
	keys.sort()
	assert_eq(keys, PUBLIC_KEYS, "nur Positivliste im öffentlichen Teil")
	var effects: Array = public["effects"]
	assert_eq(effects.size(), 1, "eine Ansage")
	var entry_keys: Array = (effects[0] as Dictionary).keys()
	entry_keys.sort()
	assert_eq(entry_keys, EFFECT_ENTRY_KEYS, "nur Effekt, Rolle, Quelle, Ziele, ersetzte Person")
	var json := JSON.stringify(public)
	for secret: String in ["KNIGHT_STRIKE", "NIGHT_KILL", "cause", "protection", "Schutz"]:
		assert_false(json.contains(secret), "öffentlicher Teil nennt keine Ursache: %s" % secret)
	var layer := CockpitLayers.announcement(1, public)
	assert_true(layer != null, "zeigbare Ansagekarte")
	var shown: Array[String] = []
	for c: Control in text_controls(layer):
		shown.append(text_of(c))
	layer.free()
	assert_false("\n".join(shown).contains("NIGHT_KILL"), "Ansagekarte ohne Ursache")


func test_coachman_crash_is_one_announcement_with_all_neighbours() -> void:
	var s := UiGame.session([W, D, "wahnsinniger-kutscher", D, D, D])
	assert_true(s.start_night().ok and UiGame.to_day(s), "Tag 1")
	assert_true(s.nominate(5, 3).ok and s.decide_execution(3).ok, "Kutscher wird hingerichtet")
	var effects := s.day_effects()
	assert_eq(effects.size(), 1, "eine Ansage für den Unfall")
	assert_eq(str(effects[0]["effect"]), "coachman_crash", "Effekt")
	assert_eq(str(effects[0]["role_id"]), "wahnsinniger-kutscher", "Rolle zum Zeitpunkt")
	assert_eq((effects[0]["targets"] as Array).size(), 2, "beide Nachbarn in einer Ansage")


func test_day_card_lists_day_effects_and_sage_curse_names_the_role() -> void:
	var s := UiGame.session([W, D, "der-weise", D, D, "kutscher"])
	assert_true(s.start_night().ok and UiGame.to_day(s), "Tag 1")
	assert_true(s.nominate(4, 3).ok and s.decide_execution(3, {"sage_curse": 2}).ok, "Weiser wird hingerichtet")
	var effects := s.day_effects()
	assert_true(effects.size() == 1 and str(effects[0]["effect"]) == "sage_curse" and str(effects[0]["role_id"]) == "der-weise", "Fluch mit Rolle")
	var deaths := s.day_deaths()
	assert_true(deaths.size() == 1 and str(deaths[0]["role_id"]) == "", "gewöhnliche Todesansage ohne Rolle in der Wiederbelebungsrunde")
	var card := ActionCard.new()
	tree.root.add_child(card)
	_spawned.append(card)
	card.render(UiGame.next_of(s), {"phase": "DAY", "seats": (s.cockpit_view()["seats"] as Array), "day_deaths": deaths, "day_effects": effects,
		"day_number": 1, "day_mode": "", "selection": [], "revealed": true})
	var labels: Array = card.find_children("*", "GrimmLabel", true, false)
	var keys: Array[String] = []
	for l: Node in labels:
		keys.append(String((l as GrimmLabel).text_key))
	assert_true(keys.has("ui.effect.sage_curse"), "Tageskarte zeigt die Ansage des Fluchs: %s" % str(keys))


func test_heartbreak_names_the_source_role_and_survives_load() -> void:
	var s := UiGame.session([W, "loki", D, D, D, D, D])
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(s.answer_targets([3, 5]).ok and s.answer_choice(true).ok, "Liebende 3 und 5")
	assert_true(UiGame.to_day(s), "Tag 1")
	assert_true(s.nominate(4, 3).ok and s.decide_execution(3).ok, "Person 3 wird hingerichtet")
	var effects := s.day_effects()
	assert_eq(effects.size(), 1, "Liebeskummer angesagt")
	assert_eq(str(effects[0]["effect"]), "heartbreak", "Effekt")
	assert_eq(str(effects[0]["role_id"]), "loki", "Quellrolle Loki (PE-05)")
	assert_eq(str((CockpitText.effect_line(effects[0])["values"] as Dictionary)["role"]), "ui.role.loki.name", "Ansagezeile nennt Loki")
	var other := GameSession.new()
	assert_eq(other.load_text(s.save_text()), &"", "Laden")
	assert_eq(JSON.stringify(other.day_effects()), JSON.stringify(effects), "nach dem Laden dieselbe Ansage")
	var replayed := RulesEngine.replay(s.commands())
	assert_true(replayed.ok, "Replay")
	assert_eq(MorningReport.day_effects(replayed.state, replayed.events).size(), 1, "Replay erzeugt dieselbe Ansage")


func test_every_effect_has_a_line_in_both_languages() -> void:
	for effect: String in EFFECTS:
		var key := "ui.effect.%s" % effect
		for path: String in ["res://content/i18n/ui.de.po", "res://content/i18n/ui.en.po"]:
			assert_true(po_entries(path).has(key), "%s in %s" % [key, path])
	var line := CockpitText.effect_line({"effect": "shadow_link", "role_id": "", "source": {}, "targets": [{"name": "E"}], "replaced": {"name": "D"}})
	assert_eq(str(line["key"]), "ui.effect.shadow_link", "Schlüssel")
	assert_eq(str((line["values"] as Dictionary)["replaced"]), "D", "ersetzte Person")
	assert_eq(str((line["values"] as Dictionary)["role"]), "", "keine Rolle")
