class_name SetupPerson
extends RefCounted
## Eine Person im Setup-Entwurf. `person_id` wird beim Anlegen genau einmal vergeben und nie
## geändert oder wiederverwendet; sie hängt nicht vom Listenplatz ab und wird später die
## Personen-ID im StartGame. `created_order` hält die Erstellungsreihenfolge (derzeit gleich
## der Vergabereihenfolge der IDs), damit spätere Sortierungen sie nicht überschreiben.

var person_id: int = 0
var name: String = ""
var created_order: int = 0


func _init(p_id: int = 0, p_name: String = "", p_order: int = 0) -> void:
	person_id = p_id
	name = p_name
	created_order = p_order


func to_dict() -> Dictionary:
	return {"person_id": person_id, "name": name, "created_order": created_order}
