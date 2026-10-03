class_name PersonNameRules
extends RefCounted
## Zentrale Regeln für Personen im Setup (einzige Quelle für Grenzen und Namensregeln).
## Personenzahl 6 bis 24 wie im Regelkern (RulesEngine.MIN_PLAYERS/MAX_PLAYERS, per Test
## abgeglichen). Namen:
##   Normalisierung  führende und abschließende Leerzeichen entfernen (auch geschützte und
##                   typografische Leerzeichen); innen bleibt alles, Groß-/Kleinschreibung bleibt
##   leer            nach Normalisierung leer → `empty_name`
##   Steuerzeichen   Tabulator, Zeilenumbruch u. Ä. im Namen → `invalid_characters`
##   Länge           höchstens MAX_NAME_LENGTH Unicode-Zeichen nach Normalisierung → sonst `name_too_long`
##   Dubletten       erlaubt; Vergleich über den normalisierten Namen ohne Groß-/Kleinschreibung
## Mehrfachimport: Trennung an Zeilenumbruch, Komma und Semikolon; leere Einträge entfallen.
## Diktat (`split_spoken`): zusätzlich Trennung an den ganzen Wörtern „und“ und „and“.

const MIN_PERSONS := 6
const MAX_PERSONS := 24
const MAX_NAME_LENGTH := 32
const IMPORT_SEPARATORS: Array[String] = ["\r\n", "\n", "\r", ",", ";"]
const SPOKEN_CONJUNCTION := "(?i)\\s+(?:und|and)\\s+"   ## ganzes Wort mit Leerraum davor und danach

## Leerraum, der am Rand entfernt wird (ASCII-Leerraum, geschützte und typografische Leerzeichen).
## Andere Steuerzeichen bleiben stehen und werden als `invalid_characters` abgelehnt.
const _EDGE_SPACES: Array[int] = [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0x00A0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006,
	0x2007, 0x2008, 0x2009, 0x200A, 0x200B, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF]


static func normalize(raw: String) -> String:
	var start := 0
	var end := raw.length()
	while start < end and _EDGE_SPACES.has(raw.unicode_at(start)):
		start += 1
	while end > start and _EDGE_SPACES.has(raw.unicode_at(end - 1)):
		end -= 1
	return raw.substr(start, end - start)


## Fehlercode für einen bereits normalisierten Namen oder &"" wenn gültig.
static func error_for(name: String) -> StringName:
	if name.is_empty():
		return &"empty_name"
	for i: int in name.length():
		var c := name.unicode_at(i)
		if c < 32 or c == 127 or (c >= 0x80 and c <= 0x9F):
			return &"invalid_characters"
	if name.length() > MAX_NAME_LENGTH:
		return &"name_too_long"
	return &""


## Vergleichsschlüssel für Dubletten.
static func duplicate_key(name: String) -> String:
	return normalize(name).to_lower()


## Zerlegt einen Mehrfachimport in normalisierte, nicht leere Einträge (Reihenfolge bleibt).
static func split_import(text: String) -> Array[String]:
	var unified := text
	for separator: String in IMPORT_SEPARATORS:
		unified = unified.replace(separator, "\n")
	var out: Array[String] = []
	for part: String in unified.split("\n"):
		var name := normalize(part)
		if not name.is_empty():
			out.append(name)
	return out


## Zerlegt einen eingegebenen oder diktierten Text in Namen: wie `split_import`, zusätzlich an „und“ und „and“ als ganzen
## Wörtern („Sandra“ und „Anna Maria“ bleiben ganz). Ein Ergebnis mit mehr als einem Namen zeigt der Spieler-Schritt zur Prüfung.
static func split_spoken(text: String) -> Array[String]:
	var conjunction := RegEx.create_from_string(SPOKEN_CONJUNCTION)
	var out: Array[String] = []
	for part: String in split_import(text):
		for piece: String in conjunction.sub(part, "\n", true).split("\n"):
			var name := normalize(piece)
			if not name.is_empty():
				out.append(name)
	return out
