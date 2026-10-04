extends UiTestCase
## DI-02 (Aufrufpolitik) in der Oberfläche: Tarnaufrufe erscheinen als Ansage auf der Karte des nächsten echten
## Schritts bzw. vor dem Ende der Nacht. Sie ergeben sich allein aus dem Kernzustand (`CallPolicy`), lösen keinen
## Befehl aus und bleiben nach Rückgängig und Laden gleich. Die Wiederbelebungsrunde sagt die Nacht für Tote an.

const UiGame := preload("res://tests/ui/ui_game.gd")
const W := "werwolf"
const D := "dorfbewohner"


func _render(next: Dictionary) -> ActionCard:
	var card := ActionCard.new()
	tree.root.add_child(card)
	_spawned.append(card)
	card.render(next, {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	return card


func _decoy_nodes(card: ActionCard) -> Array[String]:
	var out: Array[String] = []
	for n: Node in card.find_children("DecoyCall_*", "", true, false):
		out.append(String(n.name))
	return out


func _has_key(root: Node, key: String) -> bool:
	for n: Node in root.find_children("*", "GrimmLabel", true, false):
		if String((n as GrimmLabel).text_key) == key:
			return true
	return false


## Nacht 1 ist gespielt; die Karte der ersten Handlung von Nacht 2 steht an.
func _night_two(roles: Array) -> GameSession:
	var s := UiGame.session(roles)
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.to_day(s), "Tag 1 erreicht")
	assert_true(UiGame.to_next_night_first_card(s), "Nacht 2 beginnt")
	return s


func test_first_night_only_role_is_announced_on_the_first_card_of_later_nights() -> void:
	var s := _night_two([W, "blutwolf", "loki", "schutzengel", "das-orakel", D])
	var next := UiGame.next_of(s)
	assert_eq(str(next["kind"]), "prompt", "erster Schritt der Nacht läuft schon")
	assert_eq(str(next["owner"]), "schutzengel", "Schutzengel handelt zuerst")
	assert_eq(next["decoys"], ["loki"], "Loki hat keinen Schritt mehr und wird nur angesagt")
	var card := _render(next)
	assert_eq(_decoy_nodes(card), ["DecoyCall_loki"], "Tarnaufruf steht auf der Karte")
	assert_true(_has_key(card, "ui.cockpit.card.decoys.caption"), "als Ansage gekennzeichnet")
	# Nach dem Schritt des Schutzengels steht der Tarnaufruf nicht mehr an.
	assert_true(UiGame.step(s) == "prompt", "Schutzengel antwortet")
	var after := UiGame.next_of(s)
	assert_eq(after["decoys"] if after.has("decoys") else [], [], "nicht doppelt angesagt")


func test_trailing_call_stands_on_the_end_of_night_card() -> void:
	var s := UiGame.session([W, "blutwolf", "schutzengel", "henker", "das-orakel", D])
	assert_true(s.start_night().ok, "Nacht 1")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night"), "Ende der Nacht erreicht")
	var next := UiGame.next_of(s)
	assert_eq(next["decoys"], ["henker"], "Henker ohne Schritt wird vor dem Ende angesagt")
	var card := _render(next)
	assert_eq(_decoy_nodes(card), ["DecoyCall_henker"], "auf der Karte")
	assert_true(card.find_child("EndNightButton", true, false) != null, "Nacht beenden bleibt bedienbar")


func test_dead_role_is_called_only_in_revival_rounds() -> void:
	for revival: bool in [false, true]:
		var roles := [W, W, "schutzengel", "das-orakel", D, "kutscher" if revival else D]
		var s := UiGame.session(roles)
		assert_true(s.start_night().ok and UiGame.to_day(s), "Tag 1 (%s)" % revival)
		assert_true(s.gm_correction({"kind": "kill", "target_id": 3, "trigger_effects": true, "reason": "Test"}).ok, "Schutzengel stirbt")
		assert_true(UiGame.to_next_night_first_card(s), "Nacht 2 (%s)" % revival)
		var decoys: Array = UiGame.next_of(s).get("decoys", [])
		assert_eq(decoys.has("schutzengel"), revival, "tote Rolle aufgerufen nur mit Wiederbelebung (%s)" % revival)


func test_dead_eyes_line_only_in_revival_rounds() -> void:
	for revival: bool in [false, true]:
		var s := UiGame.session([W, W, "schutzengel", "das-orakel", D, "kutscher" if revival else D])
		var next := UiGame.next_of(s)
		assert_eq(str(next["kind"]), "start_night", "Nachtbeginn")
		assert_eq(bool(next["revival_round"]), revival, "Modus auf der Karte (%s)" % revival)
		if not revival:
			# Spielbeginn ohne Wiederbelebung: kein Textkasten, nur der große Knopf (Testrunde 1); die Ansage steht ab Nacht 2 wieder auf der Karte.
			var bare := _render(next)
			assert_true(bare.is_bare(), "Spielbeginn: Karte ohne Text")
			assert_false(_has_key(bare, "ui.call.night_falls"), "Spielbeginn: keine Ansage auf der Karte")
			assert_true(bare.find_child("StartNightButton", true, false) != null, "Spielbeginn: großer Knopf")
			assert_true(s.start_night().ok and UiGame.to_day(s) and s.decide_execution(-1).ok and s.end_day().ok, "Tag 1 beendet")
			next = UiGame.next_of(s)
			assert_eq(str(next["kind"]), "start_night", "Nachtbeginn von Nacht 2")
		var card := _render(next)
		assert_eq(_has_key(card, "ui.call.night_falls_revival"), revival, "Ansage „auch die Toten“ nur in Wiederbelebungsrunden (%s)" % revival)
		assert_eq(_has_key(card, "ui.call.night_falls"), not revival and str(next["kind"]) == "start_night", "sonst die gewöhnliche Ansage (%s)" % revival)


func test_announcing_changes_nothing_in_state_or_randomness() -> void:
	var s := UiGame.session([W, "blutwolf", "schutzengel", "henker", "das-orakel", "kutscher"])
	assert_true(s.start_night().ok, "Nacht 1")
	var hash_before := s.state_hash()
	var commands_before := s.commands().size()
	for i: int in 3:
		_render(UiGame.next_of(s))
	assert_eq(s.state_hash(), hash_before, "Rendern und Ansagen ändern den Zustand nicht")
	assert_eq(s.commands().size(), commands_before, "kein Befehl durch Tarnaufrufe")
	assert_true(UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("kind")) == "end_night"), "Nacht gespielt")
	var replayed := RulesEngine.replay(s.commands())
	assert_true(replayed.ok, "Replay")
	assert_eq(replayed.state.content_hash(), s.state_hash(), "gleicher Zustand ohne die Anzeige")
	assert_eq(CanonicalJson.stringify(replayed.state.rng.to_dict()), CanonicalJson.stringify(RulesEngine.replay(s.commands()).state.rng.to_dict()), "Zufallsposition unverändert")


func test_same_calls_after_undo_redo_and_load() -> void:
	var s := _night_two([W, "blutwolf", "loki", "schutzengel", "das-orakel", D])
	var decoys: Array = UiGame.next_of(s).get("decoys", [])
	assert_eq(decoys, ["loki"], "Ausgangslage")
	assert_true(s.can_undo() and s.undo(), "Rückgängig")
	assert_ne(str(UiGame.next_of(s).get("kind")), "prompt", "Nacht 2 noch nicht begonnen")
	assert_true(s.redo(), "Wiederholen")
	assert_eq(UiGame.next_of(s).get("decoys", []), decoys, "nach Wiederholen gleiche Ansage")
	var other := GameSession.new()
	assert_eq(other.load_text(s.save_text()), &"", "Laden")
	assert_eq(UiGame.next_of(other).get("decoys", []), decoys, "nach dem Laden gleiche Ansage")
