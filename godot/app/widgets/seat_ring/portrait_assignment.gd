class_name PortraitAssignment
extends RefCounted
## Öffentliches Platzporträt je Personen-ID (nie Sitzplatz, nie Rolle). Vorläufig automatisch und stabil: Die 24 neutralen
## Gesichter in `res://assets/night/portraits/` werden mit einer zu 24 teilerfremden Schrittweite durchlaufen, damit
## aufeinanderfolgende Personen weit auseinanderliegende Gesichter bekommen und bis zu 24 Personen nie ein Gesicht teilen.
## Die Auswahl durch die Spielleitung folgt in P4 (DECISIONS.md, „Platzporträt wählt die Spielleitung“). Solo-, Wolfs- und
## Rollenbilder sind nie Platzporträts: Es gibt nur diesen einen Ordner.

const FACE_COUNT := PersonNameRules.MAX_PERSONS  ## genau so viele Gesichter wie Personen höchstens teilnehmen
const STEP := 5  ## teilerfremd zu FACE_COUNT
const DIR := "res://assets/night/portraits/"


## Gesichtsnummer 1 bis FACE_COUNT.
static func face_number(person_id: int) -> int:
	return posmod((person_id - 1) * STEP, FACE_COUNT) + 1


static func face_path(person_id: int) -> String:
	return DIR + "face-%02d.webp" % face_number(person_id)
