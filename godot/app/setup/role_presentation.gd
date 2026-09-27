class_name RolePresentation
extends RefCounted
## Darstellungsdaten der Rollen (App-Inhaltsschicht): Übersetzungsschlüssel für Name,
## Kurzbeschreibung und Fraktion sowie die Reihenfolge in der Oberfläche. Keine Regelwirkung:
## Fraktion und Wolfszählung liest die Oberfläche über SetupRoleCatalog aus dem Regelkern.

## Reihenfolge der Fraktionsgruppen in der Oberfläche.
const FACTION_ORDER: Array[StringName] = [Faction.VILLAGE, Faction.WOLVES, Faction.SOLO]

## Reihenfolge innerhalb einer Gruppe (Grundrolle zuerst, dann Nachtschritte, dann übrige).
const ROLE_ORDER: Array[StringName] = [
	&"dorfbewohner", &"schutzengel", &"das-orakel", &"waldhexe", &"sensentraeger", &"wolfskind", &"lehrling", &"dorfchronistin", &"die-gebundenen", &"waldlaeufer", &"doktor", &"nachtwaechter", &"dorfwache", &"wahnsinniger-kutscher",
	&"werwolf", &"spiegelwolf", &"trugbilderwolf", &"siegreicher-wolf",
	&"manipulator", &"doppelspion", &"selbstmoerder",
]


## Alle Katalogrollen in Oberflächenreihenfolge: nach Fraktion gruppiert, darin nach ROLE_ORDER.
## Eine Katalogrolle ohne Eintrag in ROLE_ORDER steht am Ende ihrer Gruppe (nach ID).
static func sorted_roles() -> Array[StringName]:
	var roles := SetupRoleCatalog.role_ids()
	roles.sort_custom(func(a: StringName, b: StringName) -> bool:
		var fa := FACTION_ORDER.find(SetupRoleCatalog.faction_of(a))
		var fb := FACTION_ORDER.find(SetupRoleCatalog.faction_of(b))
		if fa != fb:
			return fa < fb
		var ia := ROLE_ORDER.find(a)
		var ib := ROLE_ORDER.find(b)
		ia = ROLE_ORDER.size() if ia == -1 else ia
		ib = ROLE_ORDER.size() if ib == -1 else ib
		return ia < ib if ia != ib else String(a) < String(b))
	return roles


static func _key_part(role: StringName) -> String:
	return String(role).replace("-", "_")


static func name_key(role: StringName) -> String:
	return "ui.role.%s.name" % _key_part(role)


static func short_key(role: StringName) -> String:
	return "ui.role.%s.short" % _key_part(role)


static func faction_key(faction: StringName) -> String:
	return "ui.faction.%s" % String(faction)
