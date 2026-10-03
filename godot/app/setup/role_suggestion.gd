class_name RoleSuggestion
extends RefCounted
## Fester Rollenvorschlag je Akt und Personenzahl 6 bis 24 (Setup-Hilfe, keine Spielregel; DA-89, löst den Vorschlag aus PE-07 ab).
## Jede Rolle kommt höchstens einmal vor (Startbesetzung, PE-07), der Vorschlag nimmt nur Rollen des gewählten Aktes (`ActCatalog`):
##   1. Wolfsrollen: 1 / 2 / 3 / 4 / 5 ab 6 / 9 / 13 / 18 / 22 Personen, in der Reihenfolge der Akt-Karte (der Werwolf steht überall vorn)
##   2. genau eine Einzelgängerrolle, die erste der Akt-Karte ohne Totenreichkarten-Pflicht
##   3. Dorfrollen: zuerst die Reihenfolge VILLAGE_ORDER (bewährte Starthilfe aus PE-07), soweit der Akt sie hat, dann der Rest der Karte
## Reicht ein Akt dafür nicht, kommen weitere Einzelgänger- und dann Wolfsrollen des Aktes dazu. Trägt er die Personenzahl auch dann
## nicht, gibt es keinen Vorschlag (leeres Ergebnis, `ActCatalog.capacity`); die Rollen anderer Akte werden nie still beigemischt.
## Kein Zufall, keine Uhr: gleiche Eingabe ergibt immer denselben Vorschlag. Der Trugbilderwolf braucht weiter eine Scheinrolle; das
## Setup belegt sie nach der Übernahme zufällig mit einer Dorfrolle des Pools vor (DA-88), änderbar.

## [ab Personenzahl, Wolfsrollen]; darunter gilt 1 Wolfsrolle.
const WOLF_STEPS: Array[Vector2i] = [Vector2i(9, 2), Vector2i(13, 3), Vector2i(18, 4), Vector2i(22, 5)]
## Bewährte Reihenfolge der Dorfrollen (PE-07, Nutzerantwort vom 30.09.2026), wird auf den Akt eingeschränkt.
const VILLAGE_ORDER: Array[StringName] = [&"schutzengel", &"das-orakel", &"dorfbewohner", &"waldhexe", &"dorfwache", &"sensentraeger",
	&"ritter", &"lehrling", &"nachtwaechter", &"wolfskind", &"waldlaeufer", &"doktor", &"detektiv", &"faehrtenleser", &"der-weise",
	&"dorfchronistin", &"wahnsinniger-kutscher", &"traumdeuter"]


static func wolf_count(persons: int) -> int:
	var wolves := 1
	for step: Vector2i in WOLF_STEPS:
		if persons >= step.x:
			wolves = step.y
	return wolves


## Anzahl je Rollen-ID (String-Schlüssel, alle Katalogrollen, kanonisch sortiert; jeder Wert 0 oder 1) oder `{}`, wenn der Akt
## die Personenzahl nicht tragen kann.
static func for_act(act: StringName, persons: int, death_cards: bool = false) -> Dictionary:
	if not ActCatalog.has_act(act) or persons > ActCatalog.capacity(act, death_cards):
		return {}
	var wolves := _usable(ActCatalog.wolves(act), death_cards)
	var solo := _usable(ActCatalog.solo(act), death_cards)
	var village := _village_priority(_usable(ActCatalog.village(act), death_cards))
	var take_wolves := mini(wolf_count(persons), wolves.size())
	var take_solo := mini(1, solo.size())
	var take_village := mini(persons - take_wolves - take_solo, village.size())
	var missing := persons - take_wolves - take_solo - take_village
	var more_solo := mini(missing, solo.size() - take_solo)
	take_solo += more_solo
	missing -= more_solo
	take_wolves += missing  # reicht wegen der Kapazitätsprüfung oben genau aus
	var chosen: Array[StringName] = []
	chosen.append_array(wolves.slice(0, take_wolves))
	chosen.append_array(solo.slice(0, take_solo))
	chosen.append_array(village.slice(0, take_village))
	var counts := {}
	for id: StringName in SetupRoleCatalog.role_ids():
		counts[String(id)] = 1 if chosen.has(id) else 0
	return counts


static func _usable(list: Array[StringName], death_cards: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	for role: StringName in list:
		if death_cards or not RoleCatalog.requires_cards(role):
			out.append(role)
	return out


static func _village_priority(village: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for role: StringName in VILLAGE_ORDER:
		if village.has(role):
			out.append(role)
	for role: StringName in village:
		if not out.has(role):
			out.append(role)
	return out
