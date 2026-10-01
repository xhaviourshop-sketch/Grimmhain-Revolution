extends TestCase
## Jede Karte in jeder Variante wird über echte Befehle gespielt: Vergabe, Fenster, Spielen mit kleinster gültiger Wahl,
## danach Nacht und Tag weiterführen, Replay und Laden müssen denselben Zustand ergeben. Das beweist Spielbarkeit und
## Konsistenz; die eigentliche Wirkung prüfen die Tests je Mechanikfamilie (test_cards_*).

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3, 4]
const OWNERS := {"wolf": 4, "dorf": 13, "solo": 14}
## Zusätzliche Tote, damit Karten mit Bedarf an Toten spielbar sind (Zweites Leben, Wiedergeburt, Phoenix, ...).
const EXTRA_DEAD := {"wolf": [3], "dorf": [11, 12], "solo": [11, 12]}
## Rollen mit Nachtschritt, damit Karten, die Fähigkeiten verleihen oder sperren, ein Ziel finden.
const CAST := {"wolf": {"2": "albtraumwolf", "4": "giftwolf", "5": "schutzengel", "6": "das-orakel"}, "dorf": {"2": "albtraumwolf", "5": "schutzengel", "6": "das-orakel", "13": "doktor"},
	"solo": {"2": "albtraumwolf", "5": "schutzengel", "6": "das-orakel", "14": "rattenfaenger"}}
## Karten, die erst mit einem bereits verbrauchten Einsatz spielbar sind; sie erhalten eigene Tests.
const NEEDS_SPENT_USE: Array[StringName] = [&"schicksal_10"]
const VICTIMS: Array[int] = [10, 9, 8, 7]


func _game(card_id: StringName, kind: String, seed_value: int) -> CardGame:
	var g := CardGame.started(self, COUNT, WOLVES, seed_value, CAST[kind])
	var owner_id: int = OWNERS[kind]
	for id: int in EXTRA_DEAD[kind]:
		g.gm_kill(id, false)
	g.gm_kill(owner_id, false)
	g.give(owner_id, card_id)
	return g


func _victim(g: CardGame) -> int:
	for id: int in VICTIMS:
		if g.state.players[id].alive:
			return id
	return -1


func _close(g: CardGame) -> void:
	g.settle()
	if CardRules.window_open(g.state):
		g.close_window()


## `kind`: Fraktion der Besitzerin (wolf, dorf, solo); neutrale Karten laufen mit allen dreien.
func _play_pair(card_id: StringName, variant: StringName, kind: String, seed_value: int) -> void:
	var label := "%s/%s/%s/%d" % [card_id, variant, kind, seed_value]
	var g := _game(card_id, kind, seed_value)
	var owner_id: int = OWNERS[kind]
	var first: StringName = CardCatalog.windows(card_id, variant)[0]
	if first == CardCatalog.WIN_START:
		g.night(_victim(g))
	else:
		g.night(_victim(g))
		if CardRules.window_open(g.state):
			g.close_window()
		g.end_day()
	if NEEDS_SPENT_USE.has(card_id):
		assert_false(g.window_for(owner_id), "%s: ohne verbrauchten Einsatz nicht spielbar" % label)
		return
	assert_true(g.window_for(owner_id), "%s: Fenster offen für die Besitzerin" % label)
	if not g.window_for(owner_id):
		return
	var rec := CardRules.held_of(g.state, owner_id)
	assert_true(CardRules.playable(g.state, rec, CardRules.window_kind(g.state)), "%s: spielbar" % label)
	g.play_min()
	g.settle()
	assert_true(g.state.pending_prompt == null, "%s: keine offene Eingabe" % label)
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden gleich" % label)
	# Weiterspielen: der nächste Zyklus darf nichts zerbrechen (außer die Karte hat einen Siegkandidaten ergeben).
	if not g.state.open_candidates().is_empty():
		print("INFO %s: Siegkandidat nach der Karte, Zyklus entfällt" % label)
		return
	_close(g)
	if g.state.phase == Phase.DAY:
		if g.state.day_step != Phase.DAY_ENDED:
			g.end_day()
		_close(g)
	if not g.state.open_candidates().is_empty():
		print("INFO %s: Siegkandidat im Zyklus, Nacht entfällt" % label)
		return
	if g.state.phase == Phase.DAY and g.state.day_step == Phase.DAY_ENDED:
		g.night(_victim(g))
		g.settle()
	assert_true(g.replay_equals(), "%s: Replay nach dem Zyklus gleich" % label)
	assert_true(g.reload_equals(), "%s: Laden nach dem Zyklus gleich" % label)


func _category(prefix: String) -> void:
	for pair: Array in CardCatalog.pairs():
		if not String(pair[0]).begins_with(prefix):
			continue
		var kinds: Array = [String(pair[1])] if OWNERS.has(String(pair[1])) else OWNERS.keys()
		for kind: String in kinds:
			_play_pair(pair[0], pair[1], kind, 3)


func test_every_catalog_pair_has_a_family() -> void:
	for pair: Array in CardCatalog.pairs():
		assert_true(CardEffects.family_of(pair[0], pair[1]) != &"", "%s/%s hat eine Mechanikfamilie" % [pair[0], pair[1]])
	assert_eq(CardCatalog.pairs().size(), 119, "119 Karten-Varianten-Paare")


func test_blessings_play() -> void:
	_category("segen_")


func test_curses_play() -> void:
	_category("fluch_")


func test_turns_play() -> void:
	_category("wende_")


func test_fates_play() -> void:
	_category("schicksal_")


func test_loki_play() -> void:
	_category("loki_")


func test_solo_play() -> void:
	_category("solo_")
