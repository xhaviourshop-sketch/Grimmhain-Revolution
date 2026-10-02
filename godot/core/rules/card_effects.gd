class_name CardEffects
extends RefCounted
## Wirkungen der Totenreichkarten: Verteiler auf die Kartenfamilien und gemeinsame Bausteine. Jede Familie (CardFx*)
## liefert für ihre Karten drei reine Funktionen und eine Wirkung:
##   playable(s, rec, window)           kann die Karte jetzt gespielt werden (Ziele vorhanden, Zeitpunkt passend)?
##   next_stage(s, rec, window, got)    nächste Eingabestufe oder {} (komplett); `got` sind die bisherigen Eingaben
##   apply(ctx, rec, window, got)       Wirkung, vollständig oder gar nicht
## Aufgaben der Spielleitung (später anfallende Entscheidungen) laufen über task_stage/task_apply je Art.
## Zeitschlüssel (CardTime): Tag d = 2·d, Nacht n = 2·n − 1; so liegt eine Nacht vor ihrem Tag und Fristen lassen sich als
## Bereiche [von, bis] ausdrücken. Karteneffekte sind Daten ({id, card, variant, owner, kind, from, to, data}); die
## Wirkung steckt in den Haken, die Kern und Familien an den passenden Stellen aufrufen.

const FOREVER := 1 << 40

## Karte → Familie (für den Verteiler).
const FAMILY_OF := {
	&"loki_08": &"ability",
	&"solo_01": &"solo", &"solo_02": &"solo", &"solo_03": &"solo", &"solo_04": &"solo", &"solo_05": &"solo", &"solo_06": &"solo", &"solo_07": &"solo", &"solo_08": &"solo", &"solo_09": &"solo", &"solo_10": &"solo", &"solo_11": &"solo", &"solo_12": &"solo", &"solo_14": &"solo",
	&"segen_10": &"dead", &"schicksal_12": &"dead", &"loki_05": &"dead", &"solo_13": &"dead",
	&"segen_06": &"ability", &"segen_12": &"ability", &"segen_14": &"ability", &"fluch_01": &"ability", &"wende_01": &"ability", &"wende_08": &"ability",
	&"wende_10": &"ability", &"schicksal_07": &"ability", &"schicksal_10": &"ability", &"loki_07": &"ability", &"wende_11": &"ability",
	&"segen_05": &"vote", &"segen_09": &"vote", &"fluch_03": &"vote", &"fluch_09": &"vote", &"fluch_13": &"vote",
	&"wende_09": &"vote", &"schicksal_03": &"vote", &"schicksal_05": &"vote", &"schicksal_09": &"vote", &"schicksal_11": &"vote", &"schicksal_14": &"vote",
	&"loki_01": &"vote", &"loki_02": &"vote", &"loki_13": &"vote",
	&"segen_03": &"night", &"segen_04": &"night", &"segen_13": &"night", &"fluch_02": &"night", &"fluch_04": &"night", &"fluch_07": &"night",
	&"fluch_10": &"night", &"wende_03": &"night", &"wende_06": &"night", &"wende_12": &"night", &"schicksal_06": &"night", &"loki_03": &"night",
	&"segen_01": &"guard", &"segen_07": &"guard", &"segen_11": &"guard", &"wende_02": &"guard", &"wende_05": &"guard", &"fluch_05": &"guard",
	&"fluch_08": &"guard", &"fluch_12": &"guard", &"loki_12": &"guard",
	&"segen_08": &"return", &"wende_04": &"return", &"wende_07": &"return", &"loki_10": &"return", &"schicksal_08": &"return", &"loki_06": &"return",
	&"schicksal_01": &"table", &"schicksal_02": &"table", &"schicksal_04": &"table", &"schicksal_13": &"table",
	&"loki_11": &"table", &"loki_09": &"table", &"loki_04": &"table", &"segen_02": &"table", &"fluch_06": &"table",
	&"fluch_11": &"table",
}


## Ausnahmen je Variante (fluch_07: Wolf = Nachtfamilie, Dorf = öffentliche Verdächtigung).
const VARIANT_FAMILY := {"fluch_07/dorf": &"table", "fluch_04/dorf": &"vote", "fluch_10/dorf": &"vote", "wende_03/dorf": &"vote", "segen_03/dorf": &"vote", "wende_11/dorf": &"vote"}

## Aufgabenart → Familie.
const TASK_FAMILY := {"puppet_nominate": &"table", "protect_pick": &"guard", "blood_pact_reveal": &"guard", "cosmic_victim": &"guard", "pack_review": &"night", "pack_redirect": &"night", "bad_omen_pick": &"night", "short_vote_check": &"vote", "solo_rebirth": &"solo", "solo_judge": &"solo"}


## Familie einer Karte in einer Variante (für den Verteiler).
static func family_of(rec_card: StringName, variant: StringName) -> StringName:
	var key := "%s/%s" % [rec_card, variant]
	if VARIANT_FAMILY.has(key):
		return VARIANT_FAMILY[key]
	return FAMILY_OF.get(rec_card, &"")


# --- Zeit -----------------------------------------------------------------------------------------------

static func day_key(day: int) -> int:
	return 2 * day


static func night_key(night: int) -> int:
	return 2 * night - 1


## Zeitschlüssel des jetzigen Moments: Tag d (Phase DAY) = 2d, Nacht n (NIGHT, Morgenauflösung) = 2n − 1.
static func now_key(s: GameState) -> int:
	if s.phase == Phase.DAY:
		return day_key(s.day_number)
	if s.phase == Phase.NIGHT or s.phase == Phase.DAWN_RESOLUTION:
		return night_key(s.night_number)
	return 0


## Tag der nächsten Hinrichtung, wenn jetzt in `window` gespielt wird (siebte Antwortrunde, KS-56): im ersten Fenster die
## Hinrichtung desselben Tages, im zweiten die des Folgetages.
static func lynch_day(s: GameState, window: StringName) -> int:
	return s.day_number if window == CardCatalog.WIN_START else s.day_number + 1


## Nächste Nacht nach dem Spielen (Fenster liegen immer am Tag): „heute Nacht“ und „Folgenacht“.
static func next_night(s: GameState) -> int:
	return s.night_number + 1


static func next_day(s: GameState) -> int:
	return s.day_number + 1


# --- Effekte ----------------------------------------------------------------------------------------------

## Neuer Karteneffekt für den Zeitraum [from, to] (Zeitschlüssel).
static func add_effect(ctx: RuleContext, rec: Dictionary, kind: String, from_key: int, to_key: int, data: Dictionary = {}) -> Dictionary:
	var sys := ctx.state.cardsys
	var e := {"id": int(sys["next_effect"]), "card": String(rec["card"]), "variant": String(rec["variant"]), "owner": int(rec["owner"]),
		"kind": kind, "from": from_key, "to": to_key, "data": data.duplicate(true)}
	sys["next_effect"] = int(sys["next_effect"]) + 1
	(sys["effects"] as Array).append(e)
	return e


static func effects(s: GameState, kind: String) -> Array:
	var out: Array = []
	if not s.death_cards:
		return out
	for e: Dictionary in s.cardsys["effects"]:
		if e["kind"] == kind:
			out.append(e)
	return out


static func is_active(s: GameState, e: Dictionary) -> bool:
	var now := now_key(s)
	return int(e["from"]) <= now and now <= int(e["to"])


## Wirksame Effekte einer Art zum jetzigen Zeitpunkt.
static func active(s: GameState, kind: String) -> Array:
	return effects(s, kind).filter(func(e: Dictionary) -> bool: return is_active(s, e))


static func effect_by_id(s: GameState, effect_id: int) -> Dictionary:
	for e: Dictionary in s.cardsys["effects"]:
		if int(e["id"]) == effect_id:
			return e
	return {}


## Entfernt abgelaufene Effekte (Ende vor dem jetzigen Zeitpunkt).
static func prune(s: GameState) -> void:
	var now := now_key(s)
	s.cardsys["effects"] = (s.cardsys["effects"] as Array).filter(func(e: Dictionary) -> bool: return int(e["to"]) >= now)


static func remove_effect(s: GameState, effect_id: int) -> void:
	var list: Array = s.cardsys["effects"]
	for i: int in list.size():
		if int(list[i]["id"]) == effect_id:
			list.remove_at(i)
			return


static func add_task(s: GameState, kind: String, rec_or_owner: Dictionary, data: Dictionary = {}) -> void:
	(s.cardsys["tasks"] as Array).append({"kind": kind, "owner": int(rec_or_owner["owner"]), "card": String(rec_or_owner.get("card", "")), "data": data.duplicate(true)})


## Öffentliche Ansage einer Kartenwirkung: Text und Werte bildet die Oberfläche (`ui.card.<id>.<variante>.public`).
static func announce(ctx: RuleContext, rec: Dictionary, values: Dictionary = {}) -> void:
	ctx.emit(GameEvent.CARD_ANNOUNCED, Visibility.PUBLIC, {"card_id": rec["card"], "variant": rec["variant"], "values": values.duplicate(true)})


static func living_of_variant(s: GameState, variant: StringName) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.alive_ids():
		if CardCatalog.owner_variant(s.players[id]) == variant:
			out.append(id)
	return out


## Zufällige Person aus `ids` über den gespeicherten Generator; -1 bei leerer Liste.
static func random_of(s: GameState, ids: Array) -> int:
	if ids.is_empty():
		return -1
	return int(ids[s.rng.next_int(0, ids.size() - 1)])


## Rolle öffentlich enthüllen (Schwarzes Mal, Rabe des Unheils): dauerhaft bekannt, solange die Person ihre jetzige Rolle hat.
static func reveal_role(ctx: RuleContext, rec: Dictionary, person_id: int) -> void:
	var p := ctx.state.players[person_id]
	add_effect(ctx, rec, "role_revealed", FOREVER, FOREVER, {"person_id": person_id, "role_id": String(p.role_id)})
	ctx.emit(GameEvent.CARD_ROLE_REVEALED, Visibility.PUBLIC, {"person_id": person_id, "role_id": String(p.role_id), "card_id": rec["card"]})


# --- Verteiler ---------------------------------------------------------------------------------------------

## Vergabebedingung beim Ziehen (nur die Karten mit Bedingung, sonst immer erfüllt).
static func grantable(s: GameState, owner_id: int, card_id: StringName, _variant: StringName) -> bool:
	if card_id == &"segen_08":
		return CardFxReturn.segen08_grantable(s, owner_id)
	return true


static func playable(s: GameState, rec: Dictionary, window: StringName) -> bool:
	match family_of(StringName(rec["card"]), StringName(rec["variant"])):
		&"table":
			return CardFxTable.playable(s, rec, window)
		&"return":
			return CardFxReturn.playable(s, rec, window)
		&"guard":
			return CardFxGuard.playable(s, rec, window)
		&"night":
			return CardFxNight.playable(s, rec, window)
		&"dead":
			return CardFxDead.playable(s, rec, window)
		&"solo":
			return CardFxSolo.playable(s, rec, window)
		&"vote":
			return CardFxVote.playable(s, rec, window)
		&"ability":
			return CardFxAbility.playable(s, rec, window)
	return false


static func next_stage(s: GameState, rec: Dictionary, window: StringName, got: Dictionary) -> Dictionary:
	match family_of(StringName(rec["card"]), StringName(rec["variant"])):
		&"table":
			return CardFxTable.next_stage(s, rec, window, got)
		&"return":
			return CardFxReturn.next_stage(s, rec, window, got)
		&"guard":
			return CardFxGuard.next_stage(s, rec, window, got)
		&"night":
			return CardFxNight.next_stage(s, rec, window, got)
		&"dead":
			return CardFxDead.next_stage(s, rec, window, got)
		&"solo":
			return CardFxSolo.next_stage(s, rec, window, got)
		&"vote":
			return CardFxVote.next_stage(s, rec, window, got)
		&"ability":
			return CardFxAbility.next_stage(s, rec, window, got)
	return {}


static func apply(ctx: RuleContext, rec: Dictionary, window: StringName, got: Dictionary) -> void:
	match family_of(StringName(rec["card"]), StringName(rec["variant"])):
		&"table":
			CardFxTable.apply(ctx, rec, window, got)
		&"return":
			CardFxReturn.apply(ctx, rec, window, got)
		&"guard":
			CardFxGuard.apply(ctx, rec, window, got)
		&"night":
			CardFxNight.apply(ctx, rec, window, got)
		&"dead":
			CardFxDead.apply(ctx, rec, window, got)
		&"solo":
			CardFxSolo.apply(ctx, rec, window, got)
		&"vote":
			CardFxVote.apply(ctx, rec, window, got)
		&"ability":
			CardFxAbility.apply(ctx, rec, window, got)


## Prüfung einer Personenauswahl über die Stufenbeschreibung hinaus (spec.check).
static func check_pick(s: GameState, spec: Dictionary, targets: Array) -> bool:
	match String(spec.get("check", "")):
		"each_faction":
			return CardFxTable.check_each_faction(s, targets)
	return true


static func is_task_kind(kind: String) -> bool:
	return TASK_FAMILY.has(kind)


static func task_stage(s: GameState, task: Dictionary, got: Dictionary) -> Dictionary:
	match TASK_FAMILY.get(String(task["kind"]), &""):
		&"table":
			return CardFxTable.task_stage(s, task, got)
		&"guard":
			return CardFxGuard.task_stage(s, task, got)
		&"night":
			return CardFxNight.task_stage(s, task, got)
		&"vote":
			return CardFxVote.task_stage(s, task, got)
		&"solo":
			return CardFxSolo.task_stage(s, task, got)
	return {}


static func task_apply(ctx: RuleContext, task: Dictionary, got: Dictionary) -> void:
	match TASK_FAMILY.get(String(task["kind"]), &""):
		&"table":
			CardFxTable.task_apply(ctx, task, got)
		&"guard":
			CardFxGuard.task_apply(ctx, task, got)
		&"night":
			CardFxNight.task_apply(ctx, task, got)
		&"vote":
			CardFxVote.task_apply(ctx, task, got)
		&"solo":
			CardFxSolo.task_apply(ctx, task, got)


## Gebrochener Schild (fluch_05): Schutzwirkungen auf der Person ruhen derzeit.
static func protections_paused(s: GameState, person_id: int) -> bool:
	return CardHooks.protections_paused(s, person_id)


# --- Haken im Tagesablauf -----------------------------------------------------------------------------------

## Vor dem Öffnen eines Fensters (z. B. gespeicherte Vorauswahl).
static func prepare_window(ctx: RuleContext, kind: StringName) -> void:
	for owner_id: Variant in (ctx.state.cardsys["window"]["queue"] as Array):
		var rec := CardRules.held_of(ctx.state, int(owner_id))
		if not rec.is_empty():
			prepare_record(ctx, rec)


## Zufallsabhängige Vorbereitung einer Karte, die vor dem Spielen feststehen muss (gespeichert, nie neu gezogen).
static func prepare_record(ctx: RuleContext, rec: Dictionary) -> void:
	CardFxReturn.prepare(ctx, rec)


## Beginn des Tages (nach der Morgenauflösung, vor dem ersten Fenster).
static func on_day_start(ctx: RuleContext) -> void:
	CardHooks.execute_due_deferrals(ctx)
	CardFxTable.on_day_start(ctx)


## Tagesende (EndDay): Fristen, bevor das zweite Fenster öffnet.
static func on_day_end(ctx: RuleContext) -> void:
	CardFxReturn.on_day_end(ctx)
	CardLynch.on_day_end(ctx)


static func on_window_closed(_ctx: RuleContext, _kind: StringName) -> void:
	pass


## Beginn der Nacht (nach dem Nachtplan): Aufgaben, die in der Nacht anfallen (Verzweiflungsschrei).
static func on_night_start(ctx: RuleContext) -> void:
	CardFxGuard.on_night_start(ctx)


## Ende der Morgenauflösung: Blutpakt (Dorf) und weitere Wirkungen nach dem nächtlichen Opfer.
static func on_dawn_end(ctx: RuleContext, had_victim: bool) -> void:
	CardFxGuard.on_dawn_end(ctx, had_victim)
	CardFxNight.on_dawn_end(ctx)
