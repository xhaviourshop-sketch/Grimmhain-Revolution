extends TestCase
## Akt Classic (DA-108): eigene Rollen-IDs mit Mechanik-Verweis. Besetzung C14:
## 1 Amor; 2, 3 Werwölfe; 4 Seherin; 5 Hexe; 6 Engel; 7–9 drei Brüder; 10, 11 zwei Schwestern; 12 Jäger; 13 Alte; 14 Mädchen.

const C14 := ["classic-amor", "classic-werwolf", "classic-werwolf", "classic-seherin", "classic-hexe", "classic-engel",
	"classic-drei-brueder", "classic-drei-brueder", "classic-drei-brueder", "classic-zwei-schwestern", "classic-zwei-schwestern",
	"classic-jaeger", "classic-alte", "classic-maedchen"]


func _night_one() -> GameState:
	var s := Fixtures.play([Fixtures.start_roles(C14), Command.start_night()])
	assert_true(s != null, "Classic-Besetzung startet")
	return s


## Wendet einen Befehl an und liefert den neuen Zustand (null bei Ablehnung).
func _apply(s: GameState, c: Command) -> GameState:
	var r := RulesEngine.apply(s, c)
	assert_true(r.ok, "Befehl angenommen: %s %s %s" % [c.type, c.payload, r.error])
	return r.state if r.ok else null


## Antwort mit Zielen, bei mehrstufigen Prompts für die laufende Stufe.
func _targets(p: PendingPrompt, ids: Array) -> Command:
	if p.stage == &"shown":
		return Command.answer_choice(p.id, "shown", true)
	return Command.answer_prompt(p.id, ids) if String(p.stage) == "" else Command.answer_stage_targets(p.id, String(p.stage), ids)


func test_night_one_order_follows_the_mechanic_numbers() -> void:
	var s := _night_one()
	var plan: Array[String] = []
	for key: StringName in s.night_plan:
		plan.append(String(key))
	assert_eq(plan, ["loki:1", "classic-drei-brueder", "classic-zwei-schwestern", "schutzengel:6", "pack", "waldhexe:5",
		"das-orakel:4"], "Amor 1, Brüder und Schwestern 5, Engel 13, Rudel 20, Hexe 34, Seherin 46")
	assert_eq(InfoSteps.living_bound(s, &"classic-drei-brueder"), [7, 8, 9], "Brüder erkennen nur sich")
	assert_eq(InfoSteps.living_bound(s, &"classic-zwei-schwestern"), [10, 11], "Schwestern erkennen nur sich")
	assert_eq(s.players[2].appears_as, &"classic-werwolf", "Seherin sieht die Classic-Rolle")
	assert_true(s.players[2].counts_as_wolf and s.players[13].faction == Faction.VILLAGE, "Fraktionen aus der Mechanik")


func test_incomplete_group_is_rejected() -> void:
	var roles := C14.duplicate()
	roles[8] = "classic-dorfbewohner"  # nur zwei Brüder
	var r := RulesEngine.apply(GameState.new(), Fixtures.start_roles(roles))
	assert_false(r.ok, "zwei Brüder abgelehnt")
	assert_eq(String(r.error), "role_group_incomplete", "Grund")


func test_amor_binds_lovers_without_asking_the_kind() -> void:
	var s := _night_one()
	assert_eq(s.pending_prompt.owner, PendingPrompt.OWNER_LOKI, "Amor ist der erste Schritt")
	s = _apply(s, _targets(s.pending_prompt, [1, 4]))
	assert_eq(s.loki_pairs.size(), 1, "ein Paar")
	assert_eq(str(s.loki_pairs[0]["kind"]), "love", "immer Liebende")
	assert_true(s.pending_prompt == null, "keine Frage nach der Bindungsart")


func test_witch_heal_reveals_no_role() -> void:
	var s := _night_one()
	var witch_index := s.night_plan.find(&"waldhexe:5")
	while s.next_night_step < witch_index or s.pending_prompt != null:
		if s.pending_prompt == null:
			s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
			continue
		var p := s.pending_prompt
		var targets := Fixtures.pass_targets(s, p)
		s = _apply(s, _targets(p, [12] if p.owner == PendingPrompt.OWNER_PACK else targets))
		if s == null:
			return
	s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
	s = _apply(s, Command.answer_choice(s.pending_prompt.id, "heal", true))
	assert_false(s.pending_prompt.partial.has("victim_role"), "keine Rolle des Opfers")
	assert_ne(String(s.pending_prompt.stage), "reveal", "keine Offenlegung")


## Kurzer Durchlauf (Phase 1): Vorbereitung mit Akt Classic und Empfehlung, Start über die Anwendungsschicht, Nacht 1 bis zur ersten
## Hinrichtung. Die Gruppen kommen nur ganz und nur mit genug freien Plätzen.
func test_classic_setup_plays_to_first_execution() -> void:
	var setup := PlayerSetup.new()
	setup.seed_source = func() -> int: return 7
	setup.set_act(ActCatalog.CLASSIC)
	setup.set_player_count(14)
	for i: int in 14:
		setup.add_person("Person %d" % (i + 1))
	assert_true(setup.go_to_step(SetupDraft.STEP_ROLES).ok, "Rollenschritt")
	assert_true(setup.apply_suggestion().ok, "Empfehlung")
	var counts: Dictionary = setup.view()["roles"]["counts"]
	assert_eq(int(counts["classic-werwolf"]), 3, "drei Werwölfe bei 14")
	assert_eq(int(counts["classic-drei-brueder"]), 3, "Brüder ganz")
	assert_eq(int(counts["classic-zwei-schwestern"]), 0, "für die Schwestern ist kein Platz")
	assert_false(bool(setup.view()["roles"]["can_increase"]["classic-zwei-schwestern"]), "Schwestern nicht angeboten")
	setup.remove_role(&"classic-drei-brueder")
	assert_eq(int(setup.view()["roles"]["counts"]["classic-drei-brueder"]), 0, "Brüder gehen nur ganz")
	assert_true(bool(setup.view()["roles"]["can_increase"]["classic-zwei-schwestern"]), "jetzt ist Platz für die Schwestern")
	setup.add_role(&"classic-drei-brueder")
	var session := GameSession.new()
	var started := GameStart.start(session, setup)
	assert_true(bool(started["ok"]), "Classic-Partie startet (%s)" % started.get("error"))
	var s: GameState = session._state
	s = _apply(s, Command.start_night())
	for guard: int in 40:
		if s == null or (s.pending_prompt == null and StepQueue.next_step_id(s) == ""):
			break
		if s.pending_prompt == null:
			s = _apply(s, Command.begin_step(StepQueue.next_step_id(s)))
			continue
		var p := s.pending_prompt
		if p.stage != &"" and p.stage != &"shown" and p.max_count == 0:
			s = _apply(s, Command.answer_choice(p.id, String(p.stage), p.stage == &"confirm"))  # Ja/Nein-Stufe (Hexe: kein Trank, Abschluss mit Ja)
			continue
		# Opfer: ein Dorfbewohner außerhalb der Amor-Paare, damit weder Jägerschuss noch Liebestod dazwischenkommt.
		var paired: Array = []
		for pair: Dictionary in s.loki_pairs:
			paired.append_array([int(pair["a"]), int(pair["b"])])
		var wolf_victim := s.players.keys().filter(func(id: int) -> bool:
			return s.players[id].role_id == &"classic-dorfbewohner" and not paired.has(id))
		s = _apply(s, _targets(p, [wolf_victim[0]] if p.owner == PendingPrompt.OWNER_PACK else Fixtures.pass_targets(s, p)))
	s = _apply(s, Command.end_night())
	assert_eq(s.phase, Phase.DAY, "Morgen erreicht")
	var wolf := -1
	var nominator := -1
	for id: int in s.players:
		if s.players[id].alive and s.players[id].counts_as_wolf and wolf == -1:
			wolf = id
		elif s.players[id].alive and not s.players[id].counts_as_wolf and nominator == -1:
			nominator = id
	s = _apply(s, Command.nominate(nominator, wolf))
	s = _apply(s, Command.decide_execution(wolf))
	assert_false(s.players[wolf].alive, "erste Hinrichtung: ein Werwolf stirbt")


## Block 1: Jede Classic-Rolle steht in Nachtleiste und Tarnaufrufen genau einmal, mit ihrer Classic-ID (nie mit der Mechanik-ID).
func test_night_bar_and_decoys_use_classic_ids() -> void:
	var s := _night_one()
	var ids: Array = NightBoardView.night_order(s).map(func(e: Dictionary) -> String: return str(e["role_id"]))
	for want: String in ["classic-amor", "classic-engel", "classic-hexe", "classic-seherin", "classic-drei-brueder", "classic-zwei-schwestern"]:
		assert_eq(ids.count(want), 1, "%s genau einmal in der Leiste" % want)
	for mech: String in ["loki", "schutzengel", "waldhexe", "das-orakel", "die-gebundenen"]:
		assert_false(ids.has(mech), "Mechanik-ID %s nicht in der Leiste" % mech)
	for role: StringName in CallPolicy.decoy_calls(s):
		assert_false(["loki", "schutzengel", "waldhexe", "das-orakel"].has(String(role)), "Tarnaufruf nennt die Mechanik: %s" % role)


## Block 1: Schrittkarte und Vorschau tragen die Classic-ID; Amor fragt nie nach Liebenden oder Rivalen.
func test_step_card_names_the_classic_role() -> void:
	var s := _night_one()
	var first := PromptView.build(s, s.pending_prompt)  # Nacht 1 öffnet den Amor-Schritt gleich
	assert_eq(str(first["role_id"]), "classic-amor", "Amor-Karte")
	assert_false(CockpitText.asks_bond_mode(first), "keine Frage nach der Bindungsart")
	s = _apply(s, _targets(s.pending_prompt, [1, 4]))
	var group := CockpitView.step_announcement(s, StepQueue.next_step_id(s))
	assert_eq(str(group["preview"]["role_id"]), "classic-drei-brueder", "Brüder-Karte nennt die Gruppe, nicht die Gebundenen")


## Block 1: Texte der Classic-Rollen und die gemeinsamen Meldungen nennen in Deutsch und Englisch keinen Grundspiel-Namen.
func test_classic_texts_have_no_base_game_names() -> void:
	var banned := ["Loki", "Schutzengel", "Orakel", "Waldhexe", "Gebundenen", "Weise", "Sensenträger", "Guardian Angel", "Oracle", "Forest Witch", "Sage", "Scythe", "Bound"]
	var keys: Array[String] = ["ui.cause.hunter_shot", "ui.cause.lover_heartbreak", "ui.cause.witch_poison", "ui.morning.drop.cursed",
		"ui.cockpit.card.day.check.sage", "ui.cockpit.error.cursed", "ui.cockpit.error.sage_curse_required", "ui.prompt.info.bound_ids"]
	for role: StringName in RoleCatalog.CLASSIC_ROLES:
		var part := CockpitText.key_part(String(role))
		keys.append_array(["ui.role.%s.name" % part, "ui.role.%s.short" % part, "ui.call.%s" % part])
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in keys:
			if key.begins_with("ui.call.") and not CockpitText.has_key(key):
				continue  # Dorfbewohner, Werwolf, Jäger, Alte, Mädchen haben keine eigene Ansage
			var text := TranslationServer.translate(key)
			assert_ne(String(text), key, "%s (%s) übersetzt" % [key, locale])
			for word: String in banned:
				assert_false(String(text).contains(word), "%s (%s) nennt %s" % [key, locale, word])
	TranslationServer.set_locale("de")
