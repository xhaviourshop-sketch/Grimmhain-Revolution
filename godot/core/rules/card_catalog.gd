class_name CardCatalog
extends RefCounted
## Katalog der 80 Totenreichkarten (Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`, Umsetzungsauftrag
## vom 01.10.2026). Reine Stammdaten ohne Zustand: stabile IDs, Kategorie, Varianten und Spielfenster. Die Regeln jeder
## Karte stehen in `CardEffects`, Texte in den Übersetzungsdateien (`ui.card.<id>.name`, `ui.card.<id>.<variante>.text`
## und `.guide`).
##
## Varianten: SEGEN, FLUCH und WENDE haben einen Text für Wölfe und für das Dorf, SCHICKSAL und LOKI einen neutralen,
## SOLO einen Solo-Text. Die Variante richtet sich nach der Fraktion der Person zum Zeitpunkt des Todes und bleibt fest
## (technische Entscheidung dieses Auftrags, ÜB-1).
## Fenster: `start` (Tagesbeginn, vor der Diskussion) und `end` (Tagesende, nach Hinrichtung und Fristablauf). Karten, die
## sich auf „heute“ beziehen, sind nur im ersten Fenster spielbar.

const WOLF := &"wolf"
const DORF := &"dorf"
const NEUTRAL := &"neutral"
const SOLO := &"solo"
const VARIANTS: Array[StringName] = [WOLF, DORF, NEUTRAL, SOLO]

const WIN_START := &"start"
const WIN_END := &"end"
const BOTH: Array = [WIN_START, WIN_END]
const START: Array = [WIN_START]

const CAT_SEGEN := &"segen"
const CAT_FLUCH := &"fluch"
const CAT_WENDE := &"wende"
const CAT_SCHICKSAL := &"schicksal"
const CAT_LOKI := &"loki"
const CAT_SOLO := &"solo"

## Karte → {cat, v: {Variante: Fenster}, revival: Variante → true (nur in Wiederbelebungsrunden)}.
const CARDS := {
	&"segen_01": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_02": {"cat": CAT_SEGEN, "v": {WOLF: START, DORF: START}},
	&"segen_03": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_04": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_05": {"cat": CAT_SEGEN, "v": {WOLF: START, DORF: START}},
	&"segen_06": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_07": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_08": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}, "revival": [WOLF, DORF]},
	&"segen_09": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_10": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_11": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_12": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_13": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"segen_14": {"cat": CAT_SEGEN, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_01": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_02": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_03": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_04": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: START}},
	&"fluch_05": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_06": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_07": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_08": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_09": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_10": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: START}},
	&"fluch_11": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_12": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"fluch_13": {"cat": CAT_FLUCH, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_01": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_02": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_03": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: START}},
	&"wende_04": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}, "revival": [WOLF, DORF]},
	&"wende_05": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_06": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_07": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}, "revival": [WOLF, DORF]},
	&"wende_08": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_09": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_10": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_11": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}},
	&"wende_12": {"cat": CAT_WENDE, "v": {WOLF: BOTH, DORF: BOTH}, "revival": [DORF]},
	&"schicksal_01": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_02": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: START}},
	&"schicksal_03": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: START}},
	&"schicksal_04": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_05": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: START}},
	&"schicksal_06": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_07": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_08": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_09": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_10": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_11": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_12": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: BOTH}},
	&"schicksal_13": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: START}},
	&"schicksal_14": {"cat": CAT_SCHICKSAL, "v": {NEUTRAL: START}},
	&"loki_01": {"cat": CAT_LOKI, "v": {NEUTRAL: START}},
	&"loki_02": {"cat": CAT_LOKI, "v": {NEUTRAL: START}},
	&"loki_03": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_04": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_05": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_06": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_07": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_08": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_09": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_10": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}, "revival": [NEUTRAL]},
	&"loki_11": {"cat": CAT_LOKI, "v": {NEUTRAL: START}},
	&"loki_12": {"cat": CAT_LOKI, "v": {NEUTRAL: BOTH}},
	&"loki_13": {"cat": CAT_LOKI, "v": {NEUTRAL: START}},
	&"solo_01": {"cat": CAT_SOLO, "v": {SOLO: BOTH}, "revival": [SOLO]},
	&"solo_02": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_03": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_04": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_05": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_06": {"cat": CAT_SOLO, "v": {SOLO: BOTH}, "revival": [SOLO]},
	&"solo_07": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_08": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_09": {"cat": CAT_SOLO, "v": {SOLO: START}},
	&"solo_10": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_11": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_12": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_13": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
	&"solo_14": {"cat": CAT_SOLO, "v": {SOLO: BOTH}},
}

const EXPECTED_COUNT := 80


static func has_card(card_id: StringName) -> bool:
	return CARDS.has(card_id)


## Alle Karten-IDs in fester Reihenfolge (Reihenfolge der Konstanten oben).
static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: Variant in CARDS:
		out.append(StringName(id))
	return out


static func category(card_id: StringName) -> StringName:
	return (CARDS[card_id] as Dictionary)["cat"]


static func has_variant(card_id: StringName, variant: StringName) -> bool:
	return CARDS.has(card_id) and ((CARDS[card_id] as Dictionary)["v"] as Dictionary).has(variant)


static func variants_of(card_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for v: Variant in (CARDS[card_id] as Dictionary)["v"]:
		out.append(StringName(v))
	return out


## Spielfenster der Variante (`start`, `end`).
static func windows(card_id: StringName, variant: StringName) -> Array:
	return ((CARDS[card_id] as Dictionary)["v"] as Dictionary)[variant]


## true, wenn die Variante nur in Wiederbelebungsrunden vergeben wird (Decision Log, dritte Antwortrunde, KS-10).
static func is_revival(card_id: StringName, variant: StringName) -> bool:
	return ((CARDS[card_id] as Dictionary).get("revival", []) as Array).has(variant)


## Kartenvariante einer Person: Wolf, Dorf oder Solo (Einzelsieg). Maßgeblich ist die Fraktion beim Tod.
static func owner_variant(p: Player) -> StringName:
	if p.counts_as_wolf:
		return WOLF
	if p.faction == Faction.VILLAGE:
		return DORF
	return SOLO


## Kategorien, aus denen eine Variante gezogen wird: Wolf und Dorf aus SEGEN, FLUCH, WENDE (mit ihrem Text) sowie aus den
## neutralen Karten, Einzelsiegpersonen aus den neutralen Karten und den SOLO-Karten.
static func draw_categories(variant: StringName) -> Array[StringName]:
	if variant == SOLO:
		return [CAT_SCHICKSAL, CAT_LOKI, CAT_SOLO]
	return [CAT_SEGEN, CAT_FLUCH, CAT_WENDE, CAT_SCHICKSAL, CAT_LOKI]


## Textvariante einer Karte für eine Fraktionsvariante: SCHICKSAL und LOKI sind neutral, SOLO nur solo.
static func text_variant(card_id: StringName, owner_variant_id: StringName) -> StringName:
	var cat := category(card_id)
	if cat == CAT_SCHICKSAL or cat == CAT_LOKI:
		return NEUTRAL
	if cat == CAT_SOLO:
		return SOLO
	return owner_variant_id


static func name_key(card_id: StringName) -> String:
	return "ui.card.%s.name" % card_id


static func text_key(card_id: StringName, variant: StringName) -> String:
	return "ui.card.%s.%s.text" % [card_id, variant]


static func guide_key(card_id: StringName, variant: StringName) -> String:
	return "ui.card.%s.%s.guide" % [card_id, variant]


## Alle (Karte, Variante)-Paare, für Vollständigkeitsprüfungen.
static func pairs() -> Array:
	var out: Array = []
	for card_id: StringName in ids():
		for v: StringName in variants_of(card_id):
			out.append([card_id, v])
	return out
