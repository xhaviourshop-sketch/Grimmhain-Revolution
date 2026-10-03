class_name ActCatalog
extends RefCounted
## Die vier Akte als fertige Rollen-Sets der Vorbereitung (DA-89). Inhalt 1:1 aus `js/core/akte.js` (Quelle der Nutzerentscheidung),
## nach Team getrennt und in der Reihenfolge der Akt-Karte. Setup-Hilfe, keine Spielregel: Der Regelkern kennt keine Akte, er prüft nur
## die gestartete Besetzung. Alle Rollen-IDs stehen im Katalog (Test `test_act_catalog`); Teamzuordnung und Katalog-Fraktion stimmen überein.

const ACT_IDS: Array[StringName] = [&"akt1", &"akt2", &"akt3", &"akt4"]

const ACTS := {
	&"akt1": {
		"level": 1,
		"village": [&"dorfbewohner", &"die-gebundenen", &"der-weise", &"sensentraeger", &"loki", &"ritter", &"schutzengel", &"spuerhund",
			&"waldhexe", &"wolfskind", &"das-orakel", &"nachtwaechter"],
		"wolves": [&"werwolf", &"koenig-lykaon", &"rachsuechtiger-wolf"],
		"solo": [&"selbstmoerder", &"rattenfaenger"],
	},
	&"akt2": {
		"level": 2,
		"village": [&"dorfbewohner", &"blutpriester", &"waldhexe", &"seelentauscher", &"verdammniswaechter", &"korrupter-richter", &"kutscher",
			&"dr-victor-frankenstein", &"die-ewigen", &"schutzgeist", &"maertyrerin", &"lehrling", &"loki", &"sensentraeger", &"der-weise"],
		"wolves": [&"werwolf", &"rachsuechtiger-wolf", &"blutwolf", &"daemonischer-wolf", &"giftwolf", &"rudelvater", &"schattenwanderer"],
		"solo": [&"pestbringerin", &"voodoo-priester", &"todesprediger", &"nekromant", &"grabraeuber"],
	},
	&"akt3": {
		"level": 3,
		"village": [&"dorfbewohner", &"detektiv", &"traumdeuter", &"dorfchronistin", &"faehrtenleser", &"zeitwaechter", &"wahnsinniger-kutscher",
			&"rotkaeppchen", &"henker", &"koenig", &"lehrling", &"loki", &"sensentraeger", &"der-weise"],
		"wolves": [&"werwolf", &"rachsuechtiger-wolf", &"trugbilderwolf", &"spiegelwolf", &"albtraumwolf", &"besessener-wolf", &"schattenhund"],
		"solo": [&"manipulator", &"parasit", &"doppelspion", &"prophet-des-untergangs", &"kartenschlucker"],
	},
	&"akt4": {
		"level": 4,
		"village": [&"dorfbewohner", &"amalia", &"doktor", &"dorfschmied", &"dorfwache", &"kopfgeldjaeger", &"kriegerin-des-lichts", &"waldlaeufer",
			&"waechter-am-tor", &"koenig", &"verdammniswaechter", &"loki", &"sensentraeger", &"der-weise"],
		"wolves": [&"werwolf", &"rachsuechtiger-wolf", &"fenrir", &"cerberus", &"schwarze-witwe", &"schicksalswolf", &"seuchenwolf",
			&"siegreicher-wolf", &"albtraumwolf"],
		"solo": [&"hades", &"feuerteufel", &"kartenschlucker", &"prophet-des-untergangs"],
	},
}


static func has_act(act: StringName) -> bool:
	return ACTS.has(act)


static func level(act: StringName) -> int:
	return int((ACTS[act] as Dictionary)["level"])


static func village(act: StringName) -> Array[StringName]:
	return _list(act, "village")


static func wolves(act: StringName) -> Array[StringName]:
	return _list(act, "wolves")


static func solo(act: StringName) -> Array[StringName]:
	return _list(act, "solo")


## Alle Rollen des Aktes: Dorf, dann Wölfe, dann Einzelgänger, jeweils in Kartenreihenfolge.
static func roles(act: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	out.append_array(village(act))
	out.append_array(wolves(act))
	out.append_array(solo(act))
	return out


static func contains(act: StringName, role: StringName) -> bool:
	return has_act(act) and roles(act).has(role)


## Rollen des Aktes, die in der Partie gewählt werden können (Kartenschlucker nur mit Totenreichkarten).
static func usable(act: StringName, death_cards: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	for role: StringName in roles(act):
		if death_cards or not RoleCatalog.requires_cards(role):
			out.append(role)
	return out


## Größte Personenzahl, die der Akt allein tragen kann (jede Rolle höchstens einmal, PE-07).
static func capacity(act: StringName, death_cards: bool) -> int:
	return usable(act, death_cards).size()


static func name_key(act: StringName) -> String:
	return "ui.act.%s.name" % String(act)


static func title_key(act: StringName) -> String:
	return "ui.act.%s.title" % String(act)


static func subtitle_key(act: StringName) -> String:
	return "ui.act.%s.subtitle" % String(act)


static func _list(act: StringName, team: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for role: Variant in (ACTS[act] as Dictionary)[team]:
		out.append(role as StringName)
	return out
