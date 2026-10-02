extends TestCase
## Ungültige Eingaben zu jeder Karte und Variante: Sobald eine Karteneingabe offen ist, müssen falsche Antworten, fremde Prompts, falsche
## Stufen und unpassende Befehle abgelehnt werden, ohne den Zustand auch nur teilweise zu verändern. Danach lässt sich die Karte
## mit einer gültigen Eingabe regulär zu Ende spielen.

const COUNT := 14
const WOLVES: Array[int] = [1, 2, 3, 4]
const OWNERS := {"wolf": 4, "dorf": 13, "solo": 14}
const EXTRA_DEAD := {"wolf": [3], "dorf": [11, 12], "solo": [11, 12]}
const CAST := {"wolf": {"2": "albtraumwolf", "4": "giftwolf", "5": "schutzengel", "6": "das-orakel"}, "dorf": {"2": "albtraumwolf", "5": "schutzengel", "6": "das-orakel", "13": "doktor"},
	"solo": {"2": "albtraumwolf", "5": "schutzengel", "6": "das-orakel", "14": "rattenfaenger"}}
const SKIPPED: Array[StringName] = [&"schicksal_10"]  ## braucht einen verbrauchten Einsatz; eigener Test in test_cards_ability


func _armed(card_id: StringName, variant: StringName, kind: String) -> CardGame:
	var g := CardGame.started(self, COUNT, WOLVES, 3, CAST[kind])
	var owner_id: int = OWNERS[kind]
	for id: int in EXTRA_DEAD[kind]:
		g.gm_kill(id, false)
	g.gm_kill(owner_id, false)
	g.give(owner_id, card_id)
	var first: StringName = CardCatalog.windows(card_id, variant)[0]
	g.night(10)
	if first == CardCatalog.WIN_END:
		if CardRules.window_open(g.state):
			g.close_window()
		g.end_day()
	return g


## Falsche Antworten passend zur Stufe der offenen Eingabe.
func _bad_answers(g: CardGame, p: PendingPrompt) -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{},
		{"prompt_id": p.id + 1000, "stage": String(p.stage)},
		{"prompt_id": p.id, "stage": "bogus"},
		{"prompt_id": p.id},
		{"prompt_id": p.id, "stage": String(p.stage), "targets": "x", "choice": "yes", "option": "0", "roll": "true"},
	]
	var base := {"prompt_id": p.id, "stage": String(p.stage)}
	match p.stage:
		&"pick":
			var outside := -1
			for id: int in g.state.players:
				if not p.allowed_ids.has(id):
					outside = id
					break
			out.append(base.merged({"targets": [999]}))
			out.append(base.merged({"targets": ["a"]}))
			if outside != -1:
				out.append(base.merged({"targets": [outside]}))
			if p.allowed_ids.size() > 0:
				out.append(base.merged({"targets": [p.allowed_ids[0], p.allowed_ids[0]]}))
			if p.max_count < p.allowed_ids.size():
				out.append(base.merged({"targets": p.allowed_ids.slice(0, p.max_count + 1)}))
			if p.min_count > 0:
				out.append(base.merged({"targets": []}))
		&"option":
			for o: Variant in [-1, 99, "0", 1.5]:
				out.append(base.merged({"option": o}))
		&"ask":
			for c: Variant in ["yes", 1, null]:
				out.append(base.merged({"choice": c}))
		&"roll":
			for r: Variant in [false, "true", 1]:
				out.append(base.merged({"roll": r}))
		&"confirm":
			for c: Variant in [false, "true", 0]:
				out.append(base.merged({"choice": c}))
	return out


func _bad_foreign_commands(owner_id: int) -> Array[Command]:
	var other := 5 if owner_id != 5 else 6
	return [Command.start_night(), Command.end_day(), Command.end_night(), Command.nominate(other, 7), Command.create(Command.DECIDE_EXECUTION, {"target_id": 7}),
		Command.card_close_window(), Command.card_act(owner_id, "play"), Command.card_act(owner_id, "keep"), Command.card_act(other, "play"), Command.begin_step("night:1:1:x:1")]


func _check_pair(card_id: StringName, variant: StringName, kind: String) -> void:
	var label := "%s/%s/%s" % [card_id, variant, kind]
	var g := _armed(card_id, variant, kind)
	var owner_id: int = OWNERS[kind]
	if not g.window_for(owner_id):
		return  # nicht spielbar in dieser Lage: bereits von test_cards_play_all abgedeckt
	# Fenster: fremde Personen, falsche Aktionen, unbekannte Aktionen
	var before_window := CanonicalJson.stringify(g.state.to_dict())
	for bad: Command in [Command.card_act(5, "play"), Command.card_act(owner_id, "bogus"), Command.card_act(owner_id, ""), Command.card_act(999, "play"), Command.create(Command.CARD_ACT, {"owner_id": owner_id}),
		Command.create(Command.CARD_ACT, {"owner_id": "x", "action": "play"}), Command.start_night(), Command.end_day(), Command.nominate(5, 6)]:
		assert_false(g.attempt(bad).ok, "%s: Fensterbefehl abgelehnt: %s" % [label, CanonicalJson.stringify(bad.to_dict())])
	assert_eq(CanonicalJson.stringify(g.state.to_dict()), before_window, "%s: Fenster unverändert nach falschen Befehlen" % label)
	g.do(Command.card_act(owner_id, "play"), "play")
	var guard := 0
	while g.state.pending_prompt != null and g.state.pending_prompt.owner == PendingPrompt.OWNER_CARD and guard < 12:
		guard += 1
		var p := g.state.pending_prompt
		var snapshot := CanonicalJson.stringify(g.state.to_dict())
		for payload: Dictionary in _bad_answers(g, p):
			var res := g.attempt(Command.create(Command.ANSWER_PROMPT, payload))
			assert_false(res.ok, "%s/%s: falsche Antwort abgelehnt: %s" % [label, p.stage, CanonicalJson.stringify(payload)])
			if res.ok:
				return
		for bad: Command in _bad_foreign_commands(owner_id):
			assert_false(g.attempt(bad).ok, "%s/%s: Befehl während der Eingabe abgelehnt: %s" % [label, p.stage, bad.type])
		assert_eq(CanonicalJson.stringify(g.state.to_dict()), snapshot, "%s/%s: Zustand unverändert nach allen falschen Antworten" % [label, p.stage])
		g.answer_card_min(p)
	g.settle()
	assert_true(CardRules.state_is_consistent(g.state), "%s: Kartenzustand konsistent" % label)
	assert_true(g.replay_equals(), "%s: Replay gleich" % label)


func _category(prefix: String) -> void:
	for pair: Array in CardCatalog.pairs():
		if not String(pair[0]).begins_with(prefix) or SKIPPED.has(pair[0]):
			continue
		var kinds: Array = [String(pair[1])] if OWNERS.has(String(pair[1])) else OWNERS.keys()
		for kind: String in kinds:
			_check_pair(pair[0], pair[1], kind)


func test_blessings_reject_invalid_input() -> void:
	_category("segen_")


func test_curses_reject_invalid_input() -> void:
	_category("fluch_")


func test_turns_reject_invalid_input() -> void:
	_category("wende_")


func test_fates_reject_invalid_input() -> void:
	_category("schicksal_")


func test_loki_reject_invalid_input() -> void:
	_category("loki_")


func test_solo_reject_invalid_input() -> void:
	_category("solo_")
