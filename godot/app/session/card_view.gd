class_name CardView
extends RefCounted
## Sicht der Totenreichkarten für die Oberfläche (nur einfache Werte, keine Regel). Alles stammt unverändert aus
## `GameState.cardsys` und den Regeln des Kerns (`CardRules`); ob eine Aktion gilt, entscheidet allein der Regelkern.
##   window()    das offene Kartenfenster: wer ist an der Reihe, welche Karte, was ist erlaubt
##   overview()  alle Karten der Partie für den privaten Spielleiterbereich (Besitzer, Karte, Status)
##   rules()     öffentlich geltende Tagesregeln (Nebelhorn, Offene Bücher, ...) und Tischregeln mit meldbaren Verstößen
##   swallower() Stapel, Schild und Zahlen der lebenden Kartenschlucker (nur Spielleiter)

const STATUS_KEYS := {"held": "ui.cards.status.held", "played": "ui.cards.status.played", "swapped": "ui.cards.status.swapped", "lapsed": "ui.cards.status.lapsed"}


static func enabled(s: GameState) -> bool:
	return s.is_started() and s.death_cards


## Karte als Anzeigewerte: Schlüssel für Name, Text und Spielleiter-Anleitung.
static func card_info(rec: Dictionary) -> Dictionary:
	if rec.is_empty():
		return {}
	var card_id := StringName(rec["card"])
	var variant := StringName(rec["variant"])
	return {
		"record_id": int(rec["id"]), "card_id": String(card_id), "variant": String(variant),
		"name_key": CardCatalog.name_key(card_id), "text_key": CardCatalog.text_key(card_id, variant), "guide_key": CardCatalog.guide_key(card_id, variant),
		"status": String(rec["status"]), "origin": String(rec["origin"]), "exchanged": bool(rec["exchanged"]), "must_play": bool(rec["must_play"]),
	}


## Das offene Kartenfenster ({} ohne Fenster): die gefragte Person mit Originalkarte und den erlaubten Aktionen.
static func window(s: GameState) -> Dictionary:
	if not enabled(s) or not CardRules.window_open(s):
		return {}
	var owner_id := CardRules.current_owner(s)
	var rec := CardRules.held_of(s, owner_id)
	if rec.is_empty():
		return {}
	var kind := CardRules.window_kind(s)
	var queue: Array = (s.cardsys["window"]["queue"] as Array).duplicate()
	var waiting: Array = []
	for id: Variant in queue.slice(1):
		waiting.append(PromptView.person_label(s, int(id)))
	return {
		"owner_id": owner_id, "owner": PromptView.person_label(s, owner_id), "window": String(kind), "card": card_info(rec),
		"can_play": CardRules.playable(s, rec, kind), "can_keep": not bool(rec["must_play"]), "can_exchange": CardRules.can_exchange(s, rec, kind),
		"must_play": bool(rec["must_play"]), "swallower_alive": CardRules.swallower_alive(s), "waiting": waiting,
		"preselected": _names(s, rec.get("pre", [])),
		"can_close": CardRules.validate_close(s) == &"",
	}


static func _names(s: GameState, ids: Variant) -> Array:
	var out: Array = []
	for id: Variant in (ids as Array if ids is Array else []):
		out.append(PromptView.person_label(s, int(id)))
	return out


## Alle Karten der Partie, nach Vergabereihenfolge: Besitzer (lebt oder tot), Karte, Status, Herkunft.
static func overview(s: GameState) -> Array:
	var out: Array = []
	if not enabled(s):
		return out
	for rec: Dictionary in CardRules.records(s):
		var info := card_info(rec)
		info["owner"] = PromptView.person_label(s, int(rec["owner"]))
		info["owner_alive"] = s.players[int(rec["owner"])].alive
		info["status_key"] = STATUS_KEYS.get(String(rec["status"]), "ui.cards.status.held")
		out.append(info)
	return out


## Wirksame Karteneffekte, die der Tisch kennen muss: Tagesregeln und meldbare Verstöße.
## Nur Werte aus den Effekten selbst; keine versteckten Wirkungen (Schilde, geheime Schutzwirkungen) erscheinen hier.
static func rules(s: GameState) -> Array:
	var out: Array = []
	if not enabled(s) or s.phase != Phase.DAY:
		return out
	for kind: String in CardFxTable.RULE_KINDS:
		for e: Dictionary in CardEffects.active(s, kind):
			var reportable := ["no_role_talk", "no_speaking"].has(kind)
			out.append({"effect_id": int(e["id"]), "kind": kind, "card_id": String(e["card"]), "variant": String(e["variant"]),
				"name_key": CardCatalog.name_key(StringName(e["card"])), "text_key": CardCatalog.text_key(StringName(e["card"]), StringName(e["variant"])),
				"reportable": reportable, "excluded": _names(s, (e["data"] as Dictionary).get("excluded", []))})
	for e: Dictionary in CardEffects.effects(s, "dead_rule"):
		if CardFxDead.dead_rule_active(s):
			out.append({"effect_id": int(e["id"]), "kind": "dead_rule", "card_id": String(e["card"]), "variant": String(e["variant"]),
				"name_key": CardCatalog.name_key(StringName(e["card"])), "text_key": CardCatalog.text_key(StringName(e["card"]), StringName(e["variant"])),
				"reportable": false, "excluded": []})
			break
	return out


## Kartenschlucker (nur Spielleiter): Guthaben, gesammelte Stapel, Schild.
static func swallower(s: GameState) -> Array:
	var out: Array = []
	if not enabled(s):
		return out
	for id: int in SwallowerRules.living_bearers(s):
		out.append({"person": PromptView.person_label(s, id), "total": SwallowerRules.total_of(s, id), "balance": SwallowerRules.balance_of(s, id), "shield": SwallowerRules.has_shield(s, id)})
	return out


## Aufgaben der Spielleitung, die zu einer Karte noch ausstehen (Anzeige im Kartenüberblick).
static func open_tasks(s: GameState) -> int:
	return (s.cardsys["tasks"] as Array).size() if enabled(s) else 0


## Öffentliche Kartenereignisse eines Abschnitts als Anzeigedaten (nur Positivliste: Karte, Personen, Zahlen; nie Eingaben der
## Spielleitung, Schutzwirkungen oder geheime Teilantworten). Die Oberfläche setzt daraus die Vorlesezeilen zusammen.
static func public_lines(s: GameState, span: Array[GameEvent]) -> Array:
	var out: Array = []
	if not enabled(s):
		return out
	for e: GameEvent in span:
		var d := e.data
		match e.type:
			GameEvent.CARD_ANNOUNCED:
				out.append({"kind": "announced", "card_id": str(d["card_id"]), "variant": str(d["variant"]), "stage": str(d.get("stage", "")),
					"values": _public_values(s, DictRead.get_dict(d, "values"))})
			GameEvent.CARD_ROLE_REVEALED:
				out.append({"kind": "role_revealed", "card_id": str(d.get("card_id", "")), "person": PromptView.person_label(s, int(d["person_id"])), "role_id": str(d["role_id"])})
			GameEvent.CARD_REVIVED:
				out.append({"kind": "revived", "card_id": str(d.get("card_id", "")), "person": PromptView.person_label(s, int(d["person_id"]))})
			GameEvent.CARD_QUESTION:
				out.append({"kind": "question", "card_id": str(d["card_id"]), "asker": PromptView.person_label(s, int(d["asker_id"])),
					"subject": PromptView.person_label(s, int(d["subject_id"])), "answer": bool(d["answer"])})
			GameEvent.CARD_MARKER:
				out.append({"kind": "marker", "card_id": str(d["card_id"]), "person": PromptView.person_label(s, int(d["person_id"]))})
			GameEvent.CARD_EXCLUDED:
				out.append({"kind": "excluded", "card_id": str(d["card_id"]), "person": PromptView.person_label(s, int(d["person_id"]))})
			GameEvent.CARD_DICE_ROLLED:
				out.append({"kind": "dice", "dice": (d["dice"] as Array).duplicate(), "person": PromptView.person_label(s, int(d["owner_id"]))})
			GameEvent.SWALLOWER_ANNOUNCED:
				out.append({"kind": "swallower", "total": int(d["total"])})
			GameEvent.NIGHT_SKIPPED_BY_CARD:
				out.append({"kind": "night_skipped", "night": int(d["night"])})
	return out


## Werte einer Ansage: Personenverweise (`*_id`, `*_ids`) als Anzeigename, sonst Zahl, Text oder Wahrheitswert.
static func _public_values(s: GameState, values: Dictionary) -> Dictionary:
	var out := {}
	var keys := values.keys()
	keys.sort()
	for k: Variant in keys:
		var key := str(k)
		var v: Variant = values[k]
		if key.ends_with("_ids") and v is Array:
			out[key] = (v as Array).map(func(id: Variant) -> Dictionary: return PromptView.person_label(s, int(id)))
		elif key.ends_with("_id") and DictRead.is_int_like(v):
			out[key] = PromptView.person_label(s, int(v)) if int(v) != GameState.NO_TARGET else {}
		elif v is bool or v is String or v is int or v is float:
			out[key] = v
	return out
