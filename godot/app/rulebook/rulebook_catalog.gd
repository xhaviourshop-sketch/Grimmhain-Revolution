class_name RulebookCatalog
extends RefCounted
## Aufbau des allgemeinen Regelbuchs: zwölf Kapitel mit je einer Folge von Blöcken. Die Texte stehen nur in den
## Übersetzungen (`ui.rulebook.<kapitel>.title` und `ui.rulebook.<kapitel>.b<NN>`); dieser Katalog kennt nur die Reihenfolge und die
## Art jedes Blocks: `h` Zwischenüberschrift, `p` Absatz, `l` Listenzeile (der Text trägt Aufzählungszeichen oder Nummer selbst).
## Kein Bezug zu einer Partie, einem Spielstand oder dem Regelkern: Das Regelbuch erklärt nur bestätigte Regeln und tatsächlich
## umgesetzte Abläufe und kann deshalb keine geheimen Angaben enthalten.

const CHAPTERS: Array[Dictionary] = [
	{"id": "c01", "kinds": "pphphphlllll"},
	{"id": "c02", "kinds": "phpphpppphphpp"},
	{"id": "c03", "kinds": "pllllppp"},
	{"id": "c04", "kinds": "phpllllhpphphppp"},
	{"id": "c05", "kinds": "phphphphp"},
	{"id": "c06", "kinds": "pphplllphpp"},
	{"id": "c07", "kinds": "pphlllphpp"},
	{"id": "c08", "kinds": "ppphppp"},
	{"id": "c09", "kinds": "ppllppp"},
	{"id": "c10", "kinds": "phpphppphp"},
	{"id": "c11", "kinds": "phphpphppp"},
	{"id": "c12", "kinds": "ppphppp"},
]


static func count() -> int:
	return CHAPTERS.size()


static func chapter_id(index: int) -> String:
	return str(CHAPTERS[index]["id"])


static func title_key(index: int) -> String:
	return "ui.rulebook.%s.title" % chapter_id(index)


## Arten der Blöcke eines Kapitels in Reihenfolge, zum Beispiel "hppl".
static func kinds(index: int) -> String:
	return str(CHAPTERS[index]["kinds"])


static func block_key(index: int, block: int) -> String:
	return "ui.rulebook.%s.b%02d" % [chapter_id(index), block + 1]
