class_name RoleSuggestion
extends RefCounted
## Fester Rollenvorschlag je Personenzahl 6 bis 24 (Setup-Hilfe, keine Spielregel; PE-07 mit Nutzerantwort vom 30.09.2026).
## Jede Rolle kommt höchstens einmal vor (Startbesetzung), daher gibt es keine Füllung mit gleichen Rollen:
##   1. Wolfsrollen: 1 / 2 / 3 / 4 / 5 ab 6 / 9 / 13 / 18 / 22 Personen, in der Reihenfolge WOLF_ORDER
##      (Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf)
##   2. genau ein Manipulator im Vorschlag (keine Pflicht für manuell zusammengestellte Partien)
##   3. Dorfrollen in der Reihenfolge VILLAGE_ORDER, so viele wie Personen übrig sind (Personen − Wolfsrollen − 1)
## Beispiel 6 Personen: Werwolf, Manipulator, Schutzengel, Orakel, Dorfbewohner, Waldhexe.
## Kein Zufall, keine Uhr: gleiche Personenzahl ergibt immer denselben Vorschlag. Der Trugbilderwolf braucht weiter eine
## Scheinrolle; der Vorschlag wählt keine (offene Angabe im Rollenschritt, keine geheime Standardwahl).

## [ab Personenzahl, Wolfsrollen]; darunter gilt 1 Wolfsrolle.
const WOLF_STEPS: Array[Vector2i] = [Vector2i(9, 2), Vector2i(13, 3), Vector2i(18, 4), Vector2i(22, 5)]
const WOLF_ORDER: Array[StringName] = [&"werwolf", &"spiegelwolf", &"trugbilderwolf", &"blutwolf", &"besessener-wolf"]
const SOLO_ROLE: StringName = &"manipulator"
## Schutzengel, Orakel, Dorfbewohner, Waldhexe, Dorfwache, Sensenträger, Ritter, Lehrling, Nachtwächter, Wolfskind, Waldläufer,
## Doktor, Detektiv, Fährtenleser, Der Weise, Dorfchronistin, Wahnsinniger Kutscher, Traumdeuter (Rollen-IDs nach dem Katalog).
const VILLAGE_ORDER: Array[StringName] = [&"schutzengel", &"das-orakel", &"dorfbewohner", &"waldhexe", &"dorfwache", &"sensentraeger",
	&"ritter", &"lehrling", &"nachtwaechter", &"wolfskind", &"waldlaeufer", &"doktor", &"detektiv", &"faehrtenleser", &"der-weise",
	&"dorfchronistin", &"wahnsinniger-kutscher", &"traumdeuter"]


static func wolf_count(persons: int) -> int:
	var wolves := 1
	for step: Vector2i in WOLF_STEPS:
		if persons >= step.x:
			wolves = step.y
	return wolves


## Anzahl je Rollen-ID (String-Schlüssel, alle Katalogrollen, kanonisch sortiert; jeder Wert 0 oder 1).
static func for_count(persons: int) -> Dictionary:
	var counts := {}
	for id: StringName in SetupRoleCatalog.role_ids():
		counts[String(id)] = 0
	var wolves := wolf_count(persons)
	for i: int in mini(wolves, WOLF_ORDER.size()):
		counts[String(WOLF_ORDER[i])] = 1
	counts[String(SOLO_ROLE)] = 1
	for i: int in mini(maxi(0, persons - wolves - 1), VILLAGE_ORDER.size()):
		counts[String(VILLAGE_ORDER[i])] = 1
	return counts
