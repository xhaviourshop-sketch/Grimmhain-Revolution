class_name Protection
extends RefCounted
## Bestätigter Schutz eines Schutzengels (rules-register.md §3, DR-05). Gilt nur für
## den Wolfsangriff der Nacht `night` und wird beim Tagesbeginn verworfen.

var guardian_id: int = -1  ## Schutzengel
var target_id: int = -1    ## geschützte Person
var night: int = 0         ## Nacht, für die der Schutz gilt


func to_dict() -> Dictionary:
	return {"guardian_id": guardian_id, "target_id": target_id, "night": night}


static func from_dict(d: Dictionary) -> Protection:
	var p := Protection.new()
	p.guardian_id = DictRead.get_int(d, "guardian_id", -1)
	p.target_id = DictRead.get_int(d, "target_id", -1)
	p.night = DictRead.get_int(d, "night")
	if p.guardian_id < 1 or p.target_id < 1 or p.night < 1:
		return null
	return p
