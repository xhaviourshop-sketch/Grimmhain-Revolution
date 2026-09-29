class_name NoticeRules
extends RefCounted
## Private Hinweise an Betroffene (DI-04, DI-06, DI-07; Antworten des Product Owners vom 29.09.2026).
## Ein Hinweis gehört zum Spielstand (`GameState.notices`), damit Neustart, Rückgängig und Replay ihn
## gleich behandeln. Er enthält nur Personen-IDs und Werte; Namen und Texte bildet die Anwendungsschicht.
## `AckNotice` schließt einen Hinweis als gezeigt ab. Er blockiert den Ablauf im Regelkern nicht, die
## Oberfläche zeigt offene Hinweise zuerst. Stirbt eine Person, verlässt sie die Betrachterliste, ein leerer
## Hinweis entfällt (protokolliert).
##   loki_bond      Betrachter: eine Person des Paares; data {partner_id, bond: love|rival}
##   piper_new      Betrachter: die in dieser Nacht neu Verzauberten
##   piper_all      Betrachter: alle lebenden Verzauberten (sie erkennen einander)
##   pest_infected  Betrachter: eine neu infizierte Person

const LOKI_BOND := "loki_bond"
const PIPER_NEW := "piper_new"
const PIPER_ALL := "piper_all"
const PEST_INFECTED := "pest_infected"
const KINDS: Array[String] = [LOKI_BOND, PIPER_NEW, PIPER_ALL, PEST_INFECTED]


static func queue(ctx: RuleContext, kind: String, viewer_ids: Array[int], data: Dictionary = {}) -> void:
	var s := ctx.state
	var viewers: Array[int] = viewer_ids.filter(func(id: int) -> bool: return s.players.has(id) and s.players[id].alive)
	if viewers.is_empty():
		return
	var notice := {"id": s.next_notice_id, "kind": kind, "viewer_ids": viewers.duplicate(), "data": data.duplicate(true)}
	s.next_notice_id += 1
	s.notices.append(notice)
	ctx.emit(GameEvent.NOTICE_QUEUED, Visibility.GM, {"notice_id": notice["id"], "kind": kind, "viewer_ids": viewers.duplicate(), "data": data.duplicate(true)})


static func find(s: GameState, notice_id: int) -> int:
	for i: int in s.notices.size():
		if int(s.notices[i]["id"]) == notice_id:
			return i
	return -1


static func validate_ack(s: GameState, p: Dictionary) -> StringName:
	if not DictRead.is_int_like(p.get("notice_id")) or find(s, int(p["notice_id"])) == -1:
		return &"unknown_notice"
	return &""


static func ack(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var id := int(p["notice_id"])
	s.notices.remove_at(find(s, id))
	ctx.emit(GameEvent.NOTICE_ACKED, Visibility.GM, {"notice_id": id})


## Tod von `person_id`: aus allen Betrachterlisten entfernen, leere Hinweise verwerfen.
static func on_death(ctx: RuleContext, person_id: int) -> void:
	var s := ctx.state
	var kept: Array = []
	for n: Dictionary in s.notices:
		var viewers: Array = (n["viewer_ids"] as Array).filter(func(id: Variant) -> bool: return int(id) != person_id)
		if viewers.size() == (n["viewer_ids"] as Array).size():
			kept.append(n)
		elif viewers.is_empty():
			ctx.emit(GameEvent.NOTICE_DROPPED, Visibility.GM, {"notice_id": int(n["id"]), "reason": "viewer_dead"})
		else:
			n["viewer_ids"] = viewers
			kept.append(n)
	s.notices = kept


## Laden: Aufbau, Personen und Eindeutigkeit der IDs prüfen. Null bei Widerspruch.
static func from_list(s: GameState, list: Array) -> Variant:
	var out: Array = []
	var seen := {}
	for item: Variant in list:
		if not item is Dictionary:
			return null
		var n: Dictionary = item
		var id := DictRead.get_int(n, "id", -1)
		var kind := DictRead.get_string(n, "kind")
		if id < 1 or seen.has(id) or not KINDS.has(kind):
			return null
		var viewers: Variant = DictRead.to_int_array(DictRead.get_array(n, "viewer_ids"))
		if viewers == null or (viewers as Array).is_empty():
			return null
		for v: int in viewers:
			if not s.players.has(v):
				return null
		var data := DictRead.get_dict(n, "data")
		if kind == LOKI_BOND:
			if not s.players.has(DictRead.get_int(data, "partner_id", -1)) or not ["love", "rival"].has(DictRead.get_string(data, "bond")):
				return null
		seen[id] = true
		out.append({"id": id, "kind": kind, "viewer_ids": viewers, "data": data.duplicate(true)})
	return out
