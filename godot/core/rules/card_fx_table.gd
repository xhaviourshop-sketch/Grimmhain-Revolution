class_name CardFxTable
extends RefCounted
## Kartenfamilie „Tischregeln, Enthüllungen und Informationen“ (Arbeitsliste Gruppe 7). Diese Karten wirken überwiegend am
## Tisch; der Kern speichert die Regel als Effekt (Zeitraum, Anzeige) und setzt jede Folge um, die den Spielzustand ändert:
##   schicksal_01 Nebelhorn      Tagesregel am nächsten Tag; ein gemeldeter Verstoß schließt die Person aus der Diskussion aus
##   schicksal_02 Offene Bücher  Tagesregel heute (Reihum antworten), keine Folge im Zustand
##   schicksal_04 Großes Schweigen / schicksal_13 Stille Wahl  Tagesregeln (zwei Minuten bzw. keine Diskussion)
##   loki_11 Stummfilm           Tagesregel heute; ein gemeldeter Verstoß tötet die Person sofort (Ursache CARD_SILENCE)
##   loki_09 Puppenspieler       am nächsten Tag nominiert die Spielleitung fünf Personen, aus jeder Fraktion mindestens eine
##   segen_02 Flüsterwind        öffentliche Ja/Nein-Frage einer gewählten Person; die Antwort trägt die Spielleitung ein
##   fluch_06 Schwarzes Mal, fluch_11 Rabe des Unheils  Rolle einer Person der Fraktion wird öffentlich enthüllt
##   loki_04 Doppelgänger, fluch_07 (Dorf) Alptraum  eine zufällige Person trägt öffentlich einen Verdachtsmarker
## Es gibt keinen Timer in der App; Zeitangaben bleiben Anweisung an die Spielleitung.

const TASK_PUPPET := "puppet_nominate"

const RULE_KINDS: Array[String] = ["no_role_talk", "open_books", "short_day", "silent_vote", "no_speaking"]


static func playable(s: GameState, rec: Dictionary, window: StringName) -> bool:
	var card_id := StringName(rec["card"])
	match card_id:
		&"loki_09":
			return s.alive_ids().size() >= 2
		&"segen_02":
			return not _askers(s, StringName(rec["variant"])).is_empty() and _subjects(s, StringName(rec["variant"]), _askers(s, StringName(rec["variant"]))[0]).size() >= 1
		&"fluch_06", &"fluch_11":
			return not _faction_members(s, StringName(rec["variant"])).is_empty()
		&"loki_04", &"fluch_07":
			return not s.alive_ids().is_empty() if card_id == &"loki_04" else not CardEffects.living_of_variant(s, CardCatalog.DORF).is_empty()
	return true


static func next_stage(s: GameState, rec: Dictionary, _window: StringName, got: Dictionary) -> Dictionary:
	var card_id := StringName(rec["card"])
	var variant := StringName(rec["variant"])
	match card_id:
		&"segen_02":
			if not got.has("asker_id"):
				return {"stage": "pick", "key": "asker_id", "allowed": _askers(s, variant), "min": 1, "max": 1}
			if not got.has("subject_id"):
				return {"stage": "pick", "key": "subject_id", "allowed": _subjects(s, variant, int(got["asker_id"])), "min": 1, "max": 1}
			if not got.has("answer"):
				return {"stage": "ask", "key": "answer"}
		&"fluch_06", &"fluch_11":
			if not got.has("target_id"):
				return {"stage": "pick", "key": "target_id", "allowed": _faction_members(s, variant), "min": 1, "max": 1}
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	var s := ctx.state
	var card_id := StringName(rec["card"])
	var day := s.day_number
	match card_id:
		&"schicksal_01":
			CardEffects.add_effect(ctx, rec, "no_role_talk", CardEffects.day_key(day + 1), CardEffects.day_key(day + 1), {"excluded": []})
			CardEffects.announce(ctx, rec)
		&"schicksal_02":
			CardEffects.add_effect(ctx, rec, "open_books", CardEffects.day_key(day), CardEffects.day_key(day))
			CardEffects.announce(ctx, rec)
		&"schicksal_04":
			CardEffects.add_effect(ctx, rec, "short_day", CardEffects.day_key(day + 1), CardEffects.day_key(day + 1), {"minutes": 2})
			CardEffects.announce(ctx, rec)
		&"schicksal_13":
			CardEffects.add_effect(ctx, rec, "silent_vote", CardEffects.day_key(day), CardEffects.day_key(day))
			CardEffects.announce(ctx, rec)
		&"loki_11":
			CardEffects.add_effect(ctx, rec, "no_speaking", CardEffects.day_key(day), CardEffects.day_key(day))
			CardEffects.announce(ctx, rec)
		&"loki_09":
			CardEffects.add_effect(ctx, rec, "puppet_pending", CardEffects.day_key(day + 1), CardEffects.day_key(day + 1), {"day": day + 1})
			CardEffects.announce(ctx, rec, {"day": day + 1})
		&"segen_02":
			var asker := int(got["asker_id"])
			var subject := int(got["subject_id"])
			ctx.emit(GameEvent.CARD_QUESTION, Visibility.PUBLIC, {"card_id": rec["card"], "asker_id": asker, "subject_id": subject, "answer": bool(got["answer"]), "day": day})
		&"fluch_06", &"fluch_11":
			CardEffects.reveal_role(ctx, rec, int(got["target_id"]))
		&"loki_04", &"fluch_07":
			var pool: Array = s.alive_ids() if card_id == &"loki_04" else CardEffects.living_of_variant(s, CardCatalog.DORF)
			var chosen := CardEffects.random_of(s, pool)
			CardEffects.add_effect(ctx, rec, "suspect", CardEffects.now_key(s), CardEffects.day_key(day + 1), {"person_id": chosen})
			ctx.emit(GameEvent.CARD_MARKER, Visibility.PUBLIC, {"card_id": rec["card"], "person_id": chosen})


static func _askers(s: GameState, variant: StringName) -> Array[int]:
	return CardEffects.living_of_variant(s, CardCatalog.WOLF if variant == CardCatalog.WOLF else CardCatalog.DORF)


## Flüsterwind: Wolf fragt über einen Dorfbewohner, Dorf über einen Mitspieler.
static func _subjects(s: GameState, variant: StringName, asker: int) -> Array[int]:
	if variant == CardCatalog.WOLF:
		return CardEffects.living_of_variant(s, CardCatalog.DORF)
	var out := s.alive_ids()
	out.erase(asker)
	return out


static func _faction_members(s: GameState, variant: StringName) -> Array[int]:
	return CardEffects.living_of_variant(s, CardCatalog.WOLF if variant == CardCatalog.WOLF else CardCatalog.DORF)


## Puppenspieler: Die Auswahl deckt so viele verschiedene Fraktionen ab, wie bei dieser Größe möglich sind.
static func check_each_faction(s: GameState, targets: Array) -> bool:
	var living_groups := {}
	for id: int in s.alive_ids():
		living_groups[CardCatalog.owner_variant(s.players[id])] = true
	var picked_groups := {}
	for id: Variant in targets:
		picked_groups[CardCatalog.owner_variant(s.players[int(id)])] = true
	return picked_groups.size() >= mini(targets.size(), living_groups.size())


# --- Haken ------------------------------------------------------------------------------------------------

## Tagesbeginn: Puppenspieler-Auftrag fällig; abgelaufene Karteneffekte verschwinden.
static func on_day_start(ctx: RuleContext) -> void:
	var s := ctx.state
	for e: Dictionary in CardEffects.effects(s, "puppet_pending"):
		if int(e["data"]["day"]) == s.day_number:
			CardEffects.add_task(s, TASK_PUPPET, {"owner": int(e["owner"]), "card": e["card"]})
			CardEffects.remove_effect(s, int(e["id"]))
	CardEffects.prune(s)


static func task_stage(s: GameState, task: Dictionary, got: Dictionary) -> Dictionary:
	if String(task["kind"]) == TASK_PUPPET and not got.has("targets"):
		var alive := s.alive_ids()
		var n := mini(5, alive.size())
		return {"stage": "pick", "key": "targets", "allowed": alive, "min": n, "max": n, "check": "each_faction"}
	return {}


static func task_apply(ctx: RuleContext, task: Dictionary, got: Dictionary) -> void:
	var s := ctx.state
	var owner_id := int(task["owner"])
	var chosen: Array = got["targets"]
	chosen.sort()
	for id: Variant in chosen:
		if s.players[int(id)].alive:
			RulesEngine.record_card_nomination(ctx, owner_id, int(id))
	ctx.emit(GameEvent.CARD_ANNOUNCED, Visibility.PUBLIC, {"card_id": "loki_09", "variant": "neutral", "values": {"nominee_ids": chosen.duplicate(), "day": s.day_number}, "stage": "nominated"})


# --- Tischmeldungen (Befehl CardTableAction) ---------------------------------------------------------------

static func validate_action(s: GameState, p: Dictionary) -> StringName:
	if not s.death_cards:
		return &"cards_disabled"
	var e := CardEffects.effect_by_id(s, DictRead.get_int(p, "effect_id", -1))
	if e.is_empty() or not CardEffects.is_active(s, e) or not ["no_role_talk", "no_speaking"].has(String(e["kind"])):
		return &"no_table_rule"
	var person := DictRead.get_int(p, "person_id", -1)
	if not s.players.has(person) or not s.players[person].alive:
		return &"player_dead"
	if String(e["kind"]) == "no_role_talk" and (e["data"]["excluded"] as Array).has(person):
		return &"already_excluded"
	return &""


static func table_action(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var e := CardEffects.effect_by_id(s, int(p["effect_id"]))
	var person := int(p["person_id"])
	if String(e["kind"]) == "no_role_talk":
		(e["data"]["excluded"] as Array).append(person)
		(e["data"]["excluded"] as Array).sort()
		ctx.emit(GameEvent.CARD_EXCLUDED, Visibility.PUBLIC, {"person_id": person, "card_id": e["card"], "day": s.day_number})
	else:
		ctx.emit(GameEvent.CARD_TABLE_REPORT, Visibility.GM, {"person_id": person, "card_id": e["card"], "day": s.day_number})
		KillPipeline.request_kill(ctx, person, KillEvent.CAUSE_CARD_SILENCE, KillEvent.SOURCE_PLAYER, int(e["owner"]))
