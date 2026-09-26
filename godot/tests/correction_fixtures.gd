class_name CorrectionFixtures
extends RefCounted
## Hilfen für Tests der Spielleiterkorrektur (eigene Datei, damit die älteren
## Fixtures unabhängig von neuen Befehlen bleiben).


## Spielleiterkorrektur mit Bestätigung und Begründung.
static func gm(kind: String, fields: Dictionary, reason: String = "Korrektur am Tisch") -> Command:
	var payload := fields.duplicate(true)
	payload["kind"] = kind
	payload["reason"] = reason
	payload["confirmed"] = true
	return Command.gm_correction(payload)
