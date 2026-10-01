class_name CardRules
extends RefCounted
## Totenreichkarten, gemeinsame Mechanik (Umsetzungsauftrag vom 01.10.2026; Decision Log 1A, 2C, 3A, Kartenfenster).
## Alles gehört zum Spielstand (`GameState.cardsys`) und ist nur vorhanden, wenn die Partie mit Totenreichkarten
## eingerichtet wurde (`GameState.death_cards`). Ohne diese Option verhält sich der Kern wie zuvor.
##
## Ablauf:
##   Tod → Karte ziehen (gespeicherter Generator, nach Fraktionsvariante, Wiederbelebungsmodus und Kartenbedingung)
##   Tagesbeginn und Tagesende → Kartenfenster: jede tote Person mit spielbarer oder tauschbarer Originalkarte wird
##     nacheinander gefragt: Karte spielen, aufbewahren (vorerst nichts tun) oder tauschen (nur bei lebendem
##     Kartenschlucker; die Ersatzkarte wird sofort gespielt)
##   Eingaben einer Karte (Personen, Optionen, Würfel) laufen als Prompt des Besitzers `card` mit gespeicherten
##     Teilantworten; die Wirkung wird erst nach der letzten Eingabe vollständig angewandt (Abbruch ändert nichts).
##   Entscheidungen der Spielleitung, die erst später anfallen (Zusatzopfer, Auswahl nach Rollenstärke), liegen als
##     Aufgaben in `tasks` und öffnen als Prompt, sobald kein anderer Prompt offen ist.
##   Die Siegprüfung wartet, bis das Kartenfenster und alle Aufgaben abgeschlossen sind (und am Tag, bis das Tagesende
##     samt zweitem Fenster verarbeitet ist).
##
## Zustand `cardsys`:
##   records   Karten der Partie [{id, owner, card, variant, status, origin, exchanged, must_play, order, pre}]
##   window    {} oder {kind: start|end, queue: [Personen-IDs], done: [Personen-IDs]}
##   tasks     offene Entscheidungen der Spielleitung [{kind, owner, card, data}]
##   effects   wirksame Karteneffekte [{id, card, variant, owner, kind, from, to, data}] (Zeitschlüssel, siehe CardTime)
##   abilities zusätzliche Nachtfähigkeiten dieser Nacht [{player_id, role_id, night}]
##   stacks    Kartenschlucker: Person-ID (Text) → {total, balance}
##   shields   Personen mit unverbrauchtem Kartenschlucker-Schild, aufsteigend
##   swallower_wins  Kartenschlucker mit ausgelöster Zehn-Finger-Aktion, aufsteigend
##   next_record, next_effect  Zähler (gehören zum fachlichen Zustand, weil Karten-IDs im Verlauf erscheinen)

const STATUS_HELD := "held"        ## Originalkarte liegt noch bei der toten Person
const STATUS_PLAYED := "played"
const STATUS_SWAPPED := "swapped"  ## gegen eine Ersatzkarte getauscht (zurück im Vorrat)
const STATUS_LAPSED := "lapsed"    ## verfallen: Person lebt wieder, die Karte war nicht gespielt
const STATUSES: Array[String] = [STATUS_HELD, STATUS_PLAYED, STATUS_SWAPPED, STATUS_LAPSED]
const ORIGIN_DRAW := "draw"
const ORIGIN_EXCHANGE := "exchange"

const ACT_PLAY := "play"
const ACT_KEEP := "keep"
const ACT_EXCHANGE := "exchange"
const ACTIONS: Array[String] = [ACT_PLAY, ACT_KEEP, ACT_EXCHANGE]

const MAX_PRESELECT := 3  ## Segen „Zweites Leben“: höchstens drei angebotene Namen


static func empty_system() -> Dictionary:
	return {"records": [], "window": {}, "tasks": [], "effects": [], "abilities": [], "stacks": {}, "shields": [], "swallower_wins": [],
		"pack_extra": [], "next_record": 1, "next_effect": 1}


static func enabled(s: GameState) -> bool:
	return s.death_cards


static func window_open(s: GameState) -> bool:
	return s.death_cards and not (s.cardsys["window"] as Dictionary).is_empty()


static func tasks_open(s: GameState) -> bool:
	return s.death_cards and not (s.cardsys["tasks"] as Array).is_empty()


## Die Siegprüfung wartet auf Kartenfenster, Aufgaben und am Tag auf das verarbeitete Tagesende.
static func defers_win_check(s: GameState) -> bool:
	if not s.death_cards:
		return false
	return window_open(s) or tasks_open(s) or (s.phase == Phase.DAY and (s.day_step == Phase.DAY_EXECUTION_DECIDED or s.day_step == Phase.DAY_CARDS_END))


# --- Karten und Ziehung ---------------------------------------------------------------------------------

static func records(s: GameState) -> Array:
	return s.cardsys["records"]


static func record_by_id(s: GameState, record_id: int) -> Dictionary:
	for r: Dictionary in records(s):
		if int(r["id"]) == record_id:
			return r
	return {}


## Originalkarte (oder zu spielende Ersatzkarte) einer Person, die noch bei ihr liegt; leer ohne Karte.
static func held_of(s: GameState, owner_id: int) -> Dictionary:
	for r: Dictionary in records(s):
		if int(r["owner"]) == owner_id and r["status"] == STATUS_HELD:
			return r
	return {}


static func owner_variant(s: GameState, owner_id: int) -> StringName:
	return CardCatalog.owner_variant(s.players[owner_id])


## Kartenvorrat für die Ziehung: Karten, die zur Fraktionsvariante und zum Wiederbelebungsmodus passen, nicht gerade im
## Besitz oder gespielt sind und deren Vergabebedingung erfüllt ist. `reuse` nimmt gespielte Karten wieder auf.
static func eligible_cards(s: GameState, owner_id: int, reuse: bool = false) -> Array[StringName]:
	var variant := owner_variant(s, owner_id)
	var taken := {}
	for r: Dictionary in records(s):
		if r["status"] == STATUS_HELD or (not reuse and r["status"] == STATUS_PLAYED):
			taken[StringName(r["card"])] = true
	var cats := CardCatalog.draw_categories(variant)
	var out: Array[StringName] = []
	for card_id: StringName in CardCatalog.ids():
		if not cats.has(CardCatalog.category(card_id)) or taken.has(card_id):
			continue
		var tv := CardCatalog.text_variant(card_id, variant)
		if not CardCatalog.has_variant(card_id, tv):
			continue
		if CardCatalog.is_revival(card_id, tv) and not s.revival_round:
			continue
		if not CardEffects.grantable(s, owner_id, card_id, tv):
			continue
		out.append(card_id)
	return out


## Zieht beim Tod eine Karte (Decision Log 1A). Leerer Vorrat: gespielte Karten kehren zurück; ist auch das leer, entsteht keine Karte.
static func draw_for(ctx: RuleContext, owner_id: int) -> void:
	var s := ctx.state
	var pool := eligible_cards(s, owner_id)
	if pool.is_empty():
		pool = eligible_cards(s, owner_id, true)
	if pool.is_empty():
		ctx.emit(GameEvent.CARD_POOL_EMPTY, Visibility.GM, {"owner_id": owner_id})
		return
	var card_id := pool[s.rng.next_int(0, pool.size() - 1)]
	var rec := new_record(s, owner_id, card_id, ORIGIN_DRAW)
	ctx.emit(GameEvent.CARD_DRAWN, Visibility.GM, {"owner_id": owner_id, "card_id": String(card_id), "variant": rec["variant"], "record_id": rec["id"], "origin": ORIGIN_DRAW})


static func new_record(s: GameState, owner_id: int, card_id: StringName, origin: String) -> Dictionary:
	var sys := s.cardsys
	var rec := {"id": int(sys["next_record"]), "owner": owner_id, "card": String(card_id),
		"variant": String(CardCatalog.text_variant(card_id, owner_variant(s, owner_id))), "status": STATUS_HELD, "origin": origin,
		"exchanged": false, "must_play": false, "order": int(sys["next_record"]), "pre": []}
	sys["next_record"] = int(sys["next_record"]) + 1
	(sys["records"] as Array).append(rec)
	return rec


## Tod (nach dem Todesdatensatz): Karte ziehen. Aufgerufen aus KillPipeline.
static func on_death(ctx: RuleContext, target: Player) -> void:
	if not ctx.state.death_cards:
		return
	draw_for(ctx, target.id)


## Wiederbelebung: eine nicht gespielte Karte aus dem früheren Leben verfällt (Wiederbelebte starten frisch).
static func on_revive(s: GameState, player_id: int) -> void:
	if not s.death_cards:
		return
	for r: Dictionary in records(s):
		if int(r["owner"]) == player_id and r["status"] == STATUS_HELD:
			r["status"] = STATUS_LAPSED
			r["must_play"] = false


# --- Spielbarkeit ----------------------------------------------------------------------------------------

static func playable(s: GameState, rec: Dictionary, window: StringName) -> bool:
	var card_id := StringName(rec["card"])
	var variant := StringName(rec["variant"])
	if not CardCatalog.windows(card_id, variant).has(window):
		return false
	return CardEffects.playable(s, rec, window)


static func swallower_alive(s: GameState) -> bool:
	return not SwallowerRules.living_bearers(s).is_empty()


## Tausch erlaubt (Decision Log 3A, KS-01): lebender Kartenschlucker, Originalkarte, noch nicht getauscht, und es gibt eine
## Ersatzkarte, die jetzt gespielt werden kann.
static func can_exchange(s: GameState, rec: Dictionary, window: StringName) -> bool:
	if not swallower_alive(s) or rec["origin"] != ORIGIN_DRAW or bool(rec["exchanged"]) or bool(rec["must_play"]):
		return false
	return not replacement_pool(s, rec, window).is_empty()


## Ersatzkarten: wie der Vorrat, ohne die Originalkarte, nur jetzt spielbare.
static func replacement_pool(s: GameState, rec: Dictionary, window: StringName) -> Array[StringName]:
	var owner_id := int(rec["owner"])
	var out: Array[StringName] = []
	for card_id: StringName in eligible_cards(s, owner_id):
		if StringName(rec["card"]) == card_id:
			continue
		var trial := {"id": -1, "owner": owner_id, "card": String(card_id),
			"variant": String(CardCatalog.text_variant(card_id, owner_variant(s, owner_id))), "status": STATUS_HELD, "origin": ORIGIN_EXCHANGE,
			"exchanged": true, "must_play": true, "order": -1, "pre": []}
		if playable(s, trial, window):
			out.append(card_id)
	return out


## Tote Personen, die im Fenster gefragt werden: Originalkarte spielbar oder tauschbar (Reihenfolge: Ziehreihenfolge der Karten).
static func candidates(s: GameState, window: StringName) -> Array[int]:
	var out: Array[int] = []
	for r: Dictionary in records(s):
		var owner_id := int(r["owner"])
		if r["status"] != STATUS_HELD or s.players[owner_id].alive or out.has(owner_id):
			continue
		if bool(r["must_play"]) or playable(s, r, window) or can_exchange(s, r, window):
			out.append(owner_id)
	return out


# --- Fenster ------------------------------------------------------------------------------------------------

static func window_kind(s: GameState) -> StringName:
	return StringName((s.cardsys["window"] as Dictionary).get("kind", ""))


static func current_owner(s: GameState) -> int:
	var w: Dictionary = s.cardsys["window"]
	return int((w["queue"] as Array)[0]) if not w.is_empty() and not (w["queue"] as Array).is_empty() else -1


## Öffnet das Fenster, wenn mindestens eine tote Person etwas tun kann. Gibt zurück, ob es geöffnet wurde.
static func open_window(ctx: RuleContext, kind: StringName) -> bool:
	var s := ctx.state
	var list := candidates(s, kind)
	if list.is_empty():
		return false
	s.cardsys["window"] = {"kind": String(kind), "queue": list, "done": []}
	CardEffects.prepare_window(ctx, kind)
	ctx.emit(GameEvent.CARD_WINDOW_OPENED, Visibility.PUBLIC, {"kind": String(kind), "day": s.day_number})
	return true


## Tagesbeginn (nach der Morgenauflösung): fällige verschobene Tode, auslaufende Karteneffekte, dann das erste Kartenfenster.
static func begin_day(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.death_cards:
		return
	CardEffects.on_day_start(ctx)
	open_window(ctx, CardCatalog.WIN_START)


## Tagesende (Befehl EndDay): Fristen, dann das zweite Fenster; ohne Fenster endet der Tag sofort.
static func begin_day_end(ctx: RuleContext) -> void:
	var s := ctx.state
	s.day_step = Phase.DAY_CARDS_END
	CardEffects.on_day_end(ctx)
	if not open_window(ctx, CardCatalog.WIN_END):
		finish_day_end(ctx)


static func finish_day_end(ctx: RuleContext) -> void:
	var s := ctx.state
	s.day_step = Phase.DAY_ENDED
	ctx.emit(GameEvent.DAY_ENDED, Visibility.PUBLIC, {"day": s.day_number})


## Nach jeder Karte: die gefragte Person ist erledigt; dann neu hinzugekommene Tote aufnehmen, die nächste Person fragen oder schließen.
static func advance(ctx: RuleContext) -> void:
	var w: Dictionary = ctx.state.cardsys["window"]
	if w.is_empty():
		return
	var queue: Array = w["queue"]
	if not queue.is_empty():
		(w["done"] as Array).append(queue.pop_front())
	refresh_window(ctx)


## Gleicht die Warteschlange mit dem Zustand ab: neu hinzugekommene Tote (Fenster 2 nimmt auch gerade Verstorbene auf) werden
## angehängt, Personen, die nichts mehr tun können (z. B. wieder am Leben), entfallen; ohne Rest schließt das Fenster.
static func refresh_window(ctx: RuleContext) -> void:
	var s := ctx.state
	var w: Dictionary = s.cardsys["window"]
	if w.is_empty():
		return
	var queue: Array = w["queue"]
	var done: Array = w["done"]
	var valid := candidates(s, StringName(w["kind"]))
	var kept: Array = []
	for owner_id: Variant in queue:
		if valid.has(int(owner_id)):
			kept.append(owner_id)
	for owner_id: int in valid:
		if not kept.has(owner_id) and not done.has(owner_id):
			kept.append(owner_id)
	w["queue"] = kept
	if kept.is_empty():
		close_window(ctx)


static func close_window(ctx: RuleContext) -> void:
	var s := ctx.state
	var w: Dictionary = s.cardsys["window"]
	if w.is_empty():
		return
	var kind := StringName(w["kind"])
	s.cardsys["window"] = {}
	ctx.emit(GameEvent.CARD_WINDOW_CLOSED, Visibility.PUBLIC, {"kind": String(kind), "day": s.day_number})
	CardEffects.on_window_closed(ctx, kind)
	if kind == CardCatalog.WIN_END and s.day_step == Phase.DAY_CARDS_END:
		finish_day_end(ctx)


# --- Befehle ------------------------------------------------------------------------------------------------

static func validate_act(s: GameState, p: Dictionary) -> StringName:
	if not window_open(s):
		return &"no_card_window"
	if s.pending_prompt != null:
		return &"prompt_open"
	var owner_id := DictRead.get_int(p, "owner_id", -1)
	if owner_id != current_owner(s):
		return &"not_current_card_owner"
	var action := DictRead.get_string(p, "action")
	if not ACTIONS.has(action):
		return &"invalid_card_action"
	var rec := held_of(s, owner_id)
	if rec.is_empty():
		return &"no_card"
	var kind := window_kind(s)
	match action:
		ACT_PLAY:
			if not playable(s, rec, kind):
				return &"card_not_playable"
		ACT_KEEP:
			if bool(rec["must_play"]):
				return &"card_must_be_played"
		ACT_EXCHANGE:
			if not can_exchange(s, rec, kind):
				return &"card_not_exchangeable"
	return &""


static func validate_close(s: GameState) -> StringName:
	if not window_open(s):
		return &"no_card_window"
	if s.pending_prompt != null:
		return &"prompt_open"
	for r: Dictionary in records(s):
		if bool(r["must_play"]) and r["status"] == STATUS_HELD:
			return &"card_must_be_played"
	return &""


static func act(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var owner_id := int(p["owner_id"])
	var rec := held_of(s, owner_id)
	match String(p["action"]):
		ACT_KEEP:
			ctx.emit(GameEvent.CARD_KEPT, Visibility.GM, {"owner_id": owner_id, "card_id": rec["card"], "record_id": rec["id"]})
			advance(ctx)
		ACT_PLAY:
			CardSteps.start_play(ctx, rec)
		ACT_EXCHANGE:
			_exchange(ctx, rec)


static func close(ctx: RuleContext) -> void:
	var s := ctx.state
	for owner_id: Variant in (s.cardsys["window"]["queue"] as Array).duplicate():
		var rec := held_of(s, int(owner_id))
		if not rec.is_empty():
			ctx.emit(GameEvent.CARD_KEPT, Visibility.GM, {"owner_id": int(owner_id), "card_id": rec["card"], "record_id": rec["id"]})
	close_window(ctx)


## Tausch (3A): Der Kartenschlucker erhält einen Stapel, die Originalkarte kehrt in den Vorrat zurück und die Ersatzkarte
## muss sofort gespielt werden (nicht erneut tauschbar). Die Ersatzkarte wird aus den jetzt spielbaren Karten gezogen.
static func _exchange(ctx: RuleContext, rec: Dictionary) -> void:
	var s := ctx.state
	var window := window_kind(s)
	var pool := replacement_pool(s, rec, window)
	var card_id := pool[s.rng.next_int(0, pool.size() - 1)]
	var owner_id := int(rec["owner"])
	rec["status"] = STATUS_SWAPPED
	rec["exchanged"] = true
	var replacement := new_record(s, owner_id, card_id, ORIGIN_EXCHANGE)
	replacement["must_play"] = true
	replacement["exchanged"] = true
	CardEffects.prepare_record(ctx, replacement)
	var bearer := SwallowerRules.gain_stack(ctx, 1)
	ctx.emit(GameEvent.CARD_EXCHANGED, Visibility.GM, {"owner_id": owner_id, "from_card": rec["card"], "card_id": String(card_id), "record_id": replacement["id"], "bearer_id": bearer})
	CardSteps.start_play(ctx, replacement)


# --- Laden und Prüfen -------------------------------------------------------------------------------------------

## Liest `cardsys` aus dem gespeicherten Zustand und prüft jeden Eintrag gegen die bekannten Personen. false bei Widerspruch.
static func load_system(s: GameState, d: Dictionary) -> bool:
	if not s.death_cards:
		s.cardsys = {}
		return not d.has("cardsys")
	var raw := DictRead.get_dict(d, "cardsys")
	if raw.is_empty():
		return false
	var sys := empty_system()
	var seen_records := {}
	var held_owners := {}
	var last_id := 0
	if not raw.get("records") is Array or not raw.get("tasks") is Array or not raw.get("effects") is Array or not raw.get("abilities") is Array:
		return false
	for item: Variant in raw["records"]:
		if not item is Dictionary:
			return false
		var r: Dictionary = item
		var id := DictRead.get_int(r, "id", -1)
		var owner_id := DictRead.get_int(r, "owner", -1)
		var card_id := StringName(DictRead.get_string(r, "card"))
		var variant := StringName(DictRead.get_string(r, "variant"))
		var status := DictRead.get_string(r, "status")
		var origin := DictRead.get_string(r, "origin")
		if id <= last_id or seen_records.has(id) or not s.players.has(owner_id) or not CardCatalog.has_card(card_id) or not CardCatalog.has_variant(card_id, variant):
			return false
		if not STATUSES.has(status) or not [ORIGIN_DRAW, ORIGIN_EXCHANGE].has(origin) or not r.get("exchanged") is bool or not r.get("must_play") is bool:
			return false
		var pre: Variant = DictRead.to_int_array(DictRead.get_array(r, "pre"))
		if pre == null or not r.get("pre") is Array or (pre as Array).size() > MAX_PRESELECT or (pre as Array).any(func(p: int) -> bool: return not s.players.has(p)):
			return false
		if status == STATUS_HELD:
			if held_owners.has(owner_id):
				return false
			held_owners[owner_id] = true
		elif bool(r["must_play"]):
			return false
		last_id = id
		seen_records[id] = true
		(sys["records"] as Array).append({"id": id, "owner": owner_id, "card": String(card_id), "variant": String(variant), "status": status, "origin": origin,
			"exchanged": bool(r["exchanged"]), "must_play": bool(r["must_play"]), "order": DictRead.get_int(r, "order"), "pre": pre})
	sys["next_record"] = DictRead.get_int(raw, "next_record", -1)
	if int(sys["next_record"]) <= last_id:
		return false
	var window := DictRead.get_dict(raw, "window")
	if not window.is_empty():
		var kind := DictRead.get_string(window, "kind")
		var queue: Variant = DictRead.to_int_array(DictRead.get_array(window, "queue"))
		var done: Variant = DictRead.to_int_array(DictRead.get_array(window, "done"))
		if not [String(CardCatalog.WIN_START), String(CardCatalog.WIN_END)].has(kind) or queue == null or done == null or (queue as Array).is_empty():
			return false
		for id: int in (queue as Array) + (done as Array):
			if not s.players.has(id):
				return false
		for id: int in queue:
			if (queue as Array).count(id) > 1 or (done as Array).has(id):
				return false
		sys["window"] = {"kind": kind, "queue": queue, "done": done}
	for item: Variant in raw["tasks"]:
		if not item is Dictionary:
			return false
		var t: Dictionary = item
		if not CardEffects.is_task_kind(DictRead.get_string(t, "kind")) or not s.players.has(DictRead.get_int(t, "owner", -1)):
			return false
		(sys["tasks"] as Array).append({"kind": DictRead.get_string(t, "kind"), "owner": DictRead.get_int(t, "owner"), "card": DictRead.get_string(t, "card"), "data": DictRead.get_dict(t, "data").duplicate(true)})
	var last_effect := 0
	for item: Variant in raw["effects"]:
		if not item is Dictionary:
			return false
		var e: Dictionary = item
		var eid := DictRead.get_int(e, "id", -1)
		var from_key := DictRead.get_int(e, "from", -1)
		var to_key := DictRead.get_int(e, "to", -1)
		if eid <= last_effect or from_key < 0 or to_key < from_key or DictRead.get_string(e, "kind") == "" or not s.players.has(DictRead.get_int(e, "owner", -1)):
			return false
		var data := DictRead.get_dict(e, "data")
		if not _data_is_valid(s, data) or not e.get("data") is Dictionary:
			return false
		last_effect = eid
		(sys["effects"] as Array).append({"id": eid, "card": DictRead.get_string(e, "card"), "variant": DictRead.get_string(e, "variant"), "owner": DictRead.get_int(e, "owner"),
			"kind": DictRead.get_string(e, "kind"), "from": from_key, "to": to_key, "data": data.duplicate(true)})
	sys["next_effect"] = DictRead.get_int(raw, "next_effect", -1)
	if int(sys["next_effect"]) <= last_effect:
		return false
	for item: Variant in raw["abilities"]:
		if not item is Dictionary:
			return false
		var a: Dictionary = item
		var role := StringName(DictRead.get_string(a, "role_id"))
		if not s.players.has(DictRead.get_int(a, "player_id", -1)) or not RoleCatalog.has_role(role) or not RoleCatalog.stealable(role) or (DictRead.get_int(a, "night", 0) < 1 and DictRead.get_int(a, "night", 0) != CardFxSolo.PERM):
			return false
		(sys["abilities"] as Array).append({"player_id": DictRead.get_int(a, "player_id"), "role_id": String(role), "night": DictRead.get_int(a, "night")})
	var stacks := DictRead.get_dict(raw, "stacks")
	for key: Variant in stacks:
		var entry: Variant = stacks[key]
		if not String(key).is_valid_int() or not s.players.has(String(key).to_int()) or not entry is Dictionary:
			return false
		var total := DictRead.get_int(entry, "total", -1)
		var balance := DictRead.get_int(entry, "balance", -1)
		if balance < 0 or total < balance:
			return false
		(sys["stacks"] as Dictionary)[String(key)] = {"total": total, "balance": balance}
	for key: String in ["shields", "swallower_wins"]:
		var ids: Variant = DictRead.to_int_array(DictRead.get_array(raw, key))
		if ids == null or not raw.get(key) is Array:
			return false
		var sorted_ids: Array = (ids as Array).duplicate()
		sorted_ids.sort()
		if sorted_ids != ids:
			return false
		for i: int in sorted_ids.size():
			if not s.players.has(sorted_ids[i]) or (i > 0 and sorted_ids[i] == sorted_ids[i - 1]):
				return false
		sys[key] = ids
	var extra: Variant = DictRead.to_int_array(DictRead.get_array(raw, "pack_extra"))
	if extra == null or not raw.get("pack_extra") is Array or (extra as Array).any(func(id: int) -> bool: return not s.players.has(id)):
		return false
	sys["pack_extra"] = extra
	s.cardsys = sys
	return true


## Personenverweise in Effektdaten (`*_id`, `*_ids`) müssen bekannte Personen oder −1 nennen.
static func _data_is_valid(s: GameState, data: Dictionary) -> bool:
	for key: Variant in data:
		var k := String(key)
		var v: Variant = data[key]
		if k.ends_with("_id") and DictRead.is_int_like(v):
			if int(v) != -1 and not s.players.has(int(v)):
				return false
		elif k.ends_with("_ids") or k == "excluded" or k == "ids":
			if not v is Array:
				return false
			for item: Variant in v:
				if not DictRead.is_int_like(item) or not s.players.has(int(item)):
					return false
	return true


## Zusammenhang mit dem übrigen Zustand: Option und Tagesschritt, Fensterzustand, Kartenschlucker nur mit Karten.
static func state_is_consistent(s: GameState) -> bool:
	if not s.death_cards:
		if s.day_step == Phase.DAY_CARDS_END:
			return false
		for id: int in s.players:
			if RoleCatalog.requires_cards(s.players[id].role_id) or RoleCatalog.requires_cards(s.players[id].original_role_id):
				return false
		return true
	var w: Dictionary = s.cardsys["window"]
	if w.is_empty():
		return s.day_step != Phase.DAY_CARDS_END
	if s.phase != Phase.DAY:
		return false
	var kind := StringName(w["kind"])
	if kind == CardCatalog.WIN_END:
		return s.day_step == Phase.DAY_CARDS_END
	return s.day_step == Phase.DAY_DISCUSSION or s.day_step == Phase.DAY_NOMINATION


# --- Aufgaben der Spielleitung ---------------------------------------------------------------------------------

## Öffnet die nächste ausstehende Aufgabe als Prompt (oder wendet sie ohne nötige Eingabe an), sobald kein Prompt offen ist.
static func pump(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.death_cards:
		return
	var tasks: Array = s.cardsys["tasks"]
	var guard := 0
	while s.pending_prompt == null and not tasks.is_empty() and guard < 64:
		guard += 1
		CardSteps.open_task(ctx, tasks.pop_front())


# --- Spielleiterkorrekturen ------------------------------------------------------------------------------------

static func gm_validate(s: GameState, p: Dictionary, kind: String) -> StringName:
	if not s.death_cards:
		return &"cards_disabled"
	if kind == GmCorrections.END_CARD_EFFECT:
		return &"" if not CardEffects.effect_by_id(s, DictRead.get_int(p, "effect_id", -1)).is_empty() else &"unknown_effect"
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	if not s.players.has(target):
		return &"unknown_player"
	match kind:
		GmCorrections.SET_CARD:
			var card_id := StringName(DictRead.get_string(p, "card_id"))
			if s.players[target].alive:
				return &"player_alive"
			if not CardCatalog.has_card(card_id) or not CardCatalog.has_variant(card_id, CardCatalog.text_variant(card_id, owner_variant(s, target))):
				return &"unknown_card"
			var held := held_of(s, target)
			if not held.is_empty() and StringName(held["card"]) == card_id:
				return &"no_change"
		GmCorrections.REMOVE_CARD:
			if held_of(s, target).is_empty():
				return &"no_card"
		GmCorrections.SET_STACKS:
			var total := DictRead.get_int(p, "total", -1)
			var balance := DictRead.get_int(p, "balance", -1)
			if balance < 0 or total < balance:
				return &"invalid_correction"
		GmCorrections.SET_CARD_SHIELD:
			if not p.get("value") is bool:
				return &"invalid_correction"
			if (s.cardsys["shields"] as Array).has(target) == bool(p["value"]):
				return &"no_change"
	return &""


## Führt eine Kartenkorrektur aus; liefert alten und neuen Wert für das Protokoll.
static func gm_execute(ctx: RuleContext, p: Dictionary, kind: String) -> Dictionary:
	var s := ctx.state
	var target := DictRead.get_int(p, "target_id", GameState.NO_TARGET)
	match kind:
		GmCorrections.SET_CARD:
			var held := held_of(s, target)
			var old := {"card_id": held.get("card", "")}
			if not held.is_empty():
				held["status"] = STATUS_LAPSED
				held["must_play"] = false
			var rec := new_record(s, target, StringName(DictRead.get_string(p, "card_id")), ORIGIN_DRAW)
			ctx.emit(GameEvent.CARD_DRAWN, Visibility.GM, {"owner_id": target, "card_id": rec["card"], "variant": rec["variant"], "record_id": rec["id"], "origin": "gm_correction"})
			refresh_window(ctx)
			return {"old": old, "new": {"card_id": rec["card"]}}
		GmCorrections.REMOVE_CARD:
			var held := held_of(s, target)
			held["status"] = STATUS_LAPSED
			held["must_play"] = false
			refresh_window(ctx)
			return {"old": {"card_id": held["card"]}, "new": {"card_id": ""}}
		GmCorrections.SET_STACKS:
			var e: Dictionary = (s.cardsys["stacks"] as Dictionary).get(str(target), {"total": 0, "balance": 0})
			var old := e.duplicate()
			(s.cardsys["stacks"] as Dictionary)[str(target)] = {"total": DictRead.get_int(p, "total"), "balance": DictRead.get_int(p, "balance")}
			return {"old": old, "new": {"total": DictRead.get_int(p, "total"), "balance": DictRead.get_int(p, "balance")}}
		GmCorrections.SET_CARD_SHIELD:
			var list: Array = s.cardsys["shields"]
			var had := list.has(target)
			if bool(p["value"]):
				list.append(target)
				list.sort()
			else:
				list.erase(target)
			return {"old": {"shield": had}, "new": {"shield": bool(p["value"])}}
	var effect := CardEffects.effect_by_id(s, DictRead.get_int(p, "effect_id", -1))
	CardEffects.remove_effect(s, int(effect["id"]))
	return {"old": {"effect": effect["kind"]}, "new": {"effect": ""}}


# --- Nach jedem Befehl -------------------------------------------------------------------------------------------

## Folgen eines angenommenen Befehls für laufende Karteneffekte: Fähigkeitseinsatz einer Person mit halber Fähigkeit (Befreiung).
static func after_command(ctx: RuleContext, c: Command, prompt_actor: int, prompt_id: int, prompt_owner: StringName) -> void:
	var s := ctx.state
	if not s.death_cards:
		return
	var p := c.payload
	if c.type == Command.ANSWER_PROMPT and prompt_actor != -1 and (s.pending_prompt == null or s.pending_prompt.id != prompt_id):
		var substantive: bool = not DictRead.get_array(p, "targets").is_empty() or p.get("choice") == true or p.has("option") or p.has("prediction")
		if substantive and prompt_owner != PendingPrompt.OWNER_CARD and prompt_owner != PendingPrompt.OWNER_SWALLOWER:
			CardFxReturn.half_used(ctx, prompt_actor)
	elif c.type == Command.NAME_WOLF or c.type == Command.AMALIA_SACRIFICE:
		CardFxReturn.half_used(ctx, DictRead.get_int(p, "player_id", -1))


# --- Haken für Nacht und Morgen --------------------------------------------------------------------------------

static func begin_night(ctx: RuleContext) -> void:
	var s := ctx.state
	if not s.death_cards:
		return
	s.cardsys["abilities"] = (s.cardsys["abilities"] as Array).filter(func(a: Dictionary) -> bool: return int(a["night"]) >= s.night_number or int(a["night"]) == CardFxSolo.PERM)
	s.cardsys["pack_extra"] = []
	CardEffects.on_night_start(ctx)
	# Geblendetes Rudel (Schattenmantel, Dorf): ein zufälliges Opfer, auch ein Wolf, ersetzt die Zielwahl des Rudels (KS-107).
	if not CardEffects.active(s, "pack_blind").is_empty() and not s.alive_ids().is_empty():
		s.pack_target_id = CardEffects.random_of(s, s.alive_ids())
		ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": "segen_06", "blind_victim_id": s.pack_target_id})


static func end_dawn(ctx: RuleContext, had_victim: bool) -> void:
	if ctx.state.death_cards:
		CardEffects.on_dawn_end(ctx, had_victim)
