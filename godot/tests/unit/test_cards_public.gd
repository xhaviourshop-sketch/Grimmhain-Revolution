extends TestCase
## Öffentliche Kartenangaben: Nach dem Spielen jeder Karte (jede Variante) tragen alle öffentlichen Kartenereignisse und
## Anzeigezeilen nur die Positivliste (Karte, Personen, Zahlen), nie Schutzwirkungen, Stapel, Eingaben der Spielleitung oder
## geheime Teilantworten. Für Spielende und Zuschauer nicht sichtbare Ereignisse bleiben GM oder ACTOR.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3, 4]
const OWNERS := {"wolf": 4, "dorf": 13, "solo": 14}
const EXTRA_DEAD := {"wolf": [3], "dorf": [11, 12], "solo": [11, 12]}
const CAST := {"wolf": {"2": "albtraumwolf", "4": "giftwolf", "5": "schutzengel", "6": "das-orakel"}, "dorf": {"2": "albtraumwolf", "5": "schutzengel", "6": "das-orakel", "13": "doktor"},
	"solo": {"2": "albtraumwolf", "5": "schutzengel", "6": "das-orakel", "14": "rattenfaenger"}}
const SKIPPED: Array[StringName] = [&"schicksal_10"]

## Schlüssel in öffentlichen Kartenansagen (`values`) und Anzeigezeilen.
const ALLOWED_VALUE_KEYS: Array[String] = ["day", "person_id", "person_ids", "victim_id", "victim_ids", "extra_ids", "extra_votes", "wolf_ids", "nominee_ids", "to_day", "from_day",
	"until_night", "side", "night", "leader", "judge_id", "count", "agreed", "accused_id", "rejected_id"]
const FORBIDDEN_KEYS: Array[String] = ["protection", "sources", "shield", "shields", "stacks", "balance", "total_stacks", "secret", "answer_raw", "inputs", "spec", "pre", "rng", "seed",
	"source_id", "cause", "target_role", "hand", "option"]
const PUBLIC_CARD_EVENTS: Array[String] = ["CardAnnounced", "CardRoleRevealed", "CardRevived", "CardQuestion", "CardMarker", "CardExcluded", "CardDiceRolled", "SwallowerAnnounced",
	"NightSkippedByCard", "CardWindowOpened", "CardWindowClosed", "CardDrawn"]


func _played(card_id: StringName, variant: StringName, kind: String) -> CardGame:
	var g := CardGame.started(self, COUNT, WOLVES, 3, CAST[kind])
	var owner_id: int = OWNERS[kind]
	for id: int in EXTRA_DEAD[kind]:
		g.gm_kill(id, false)
	g.gm_kill(owner_id, false)
	g.give(owner_id, card_id)
	g.night(10)
	if CardCatalog.windows(card_id, variant)[0] == CardCatalog.WIN_END:
		if CardRules.window_open(g.state):
			g.close_window()
		g.end_day()
	if g.window_for(owner_id):
		g.play_min()
		g.settle()
	return g


func _check(g: CardGame, label: String) -> void:
	for e: GameEvent in g.events:
		var is_card := String(e.type).begins_with("Card") or String(e.type).begins_with("Swallower") or e.type == GameEvent.NIGHT_SKIPPED_BY_CARD
		if not is_card or e.visibility != Visibility.PUBLIC:
			continue
		assert_true(PUBLIC_CARD_EVENTS.has(String(e.type)), "%s: öffentliches Ereignis %s steht auf der Positivliste" % [label, e.type])
		if e.type == GameEvent.CARD_DRAWN:
			assert_true(false, "%s: das Ziehen einer Karte ist nie öffentlich" % label)
		for key: Variant in e.data:
			assert_false(FORBIDDEN_KEYS.has(String(key)), "%s: %s enthält verbotenes Feld %s" % [label, e.type, key])
		if e.type == GameEvent.CARD_ANNOUNCED:
			for key: Variant in DictRead.get_dict(e.data, "values"):
				assert_true(ALLOWED_VALUE_KEYS.has(String(key)), "%s: Ansagewert %s ist freigegeben" % [label, key])
	for line: Dictionary in CardView.public_lines(g.state, g.events):
		for key: Variant in line:
			assert_false(FORBIDDEN_KEYS.has(String(key)), "%s: Anzeigezeile enthält verbotenes Feld %s" % [label, key])
		if line["kind"] == "announced":
			for key: Variant in line["values"]:
				assert_true(ALLOWED_VALUE_KEYS.has(String(key)), "%s: Anzeigewert %s ist freigegeben" % [label, key])


func _category(prefix: String) -> void:
	for pair: Array in CardCatalog.pairs():
		if not String(pair[0]).begins_with(prefix) or SKIPPED.has(pair[0]):
			continue
		var kinds: Array = [String(pair[1])] if OWNERS.has(String(pair[1])) else OWNERS.keys()
		for kind: String in kinds:
			_check(_played(pair[0], pair[1], kind), "%s/%s/%s" % [pair[0], pair[1], kind])


func test_blessings_public_data() -> void:
	_category("segen_")


func test_curses_public_data() -> void:
	_category("fluch_")


func test_turns_public_data() -> void:
	_category("wende_")


func test_fates_public_data() -> void:
	_category("schicksal_")


func test_loki_public_data() -> void:
	_category("loki_")


func test_solo_public_data() -> void:
	_category("solo_")
