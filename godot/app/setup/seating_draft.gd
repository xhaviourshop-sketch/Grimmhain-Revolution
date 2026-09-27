class_name SeatingDraft
extends RefCounted
## Sitzordnung im Setup-Entwurf: Personen-IDs im Uhrzeigersinn ab Platz 1 (`order`), Bestätigung
## und Invalidierungsgrund. Der Sitzplatz ist nur Anordnung; Name, Rolle und alle anderen Daten
## hängen an der Personen-ID. Entspricht später `seat_order` im StartGame.
## Nur PlayerSetup verändert den Entwurf; alle Werte sind reine, speicherbare Daten.

const INVALIDATED_PERSONS := &"person_count_changed"  ## Personen hinzugefügt oder entfernt
const INVALIDATED_SETUP := &"setup_changed"           ## früherer Schritt nicht mehr bestätigt

var order: Array[int] = []
var confirmed: bool = false
var invalidated: StringName = &""


## Gleicht die Reihenfolge an die Personen an: entfernte IDs fallen weg, übrige behalten ihre
## relative Folge, neue IDs kommen in Listenreihenfolge ans Ende. true, wenn sich etwas änderte.
func sync(person_ids: Array[int]) -> bool:
	var kept: Array[int] = []
	for id: int in order:
		if person_ids.has(id):
			kept.append(id)
	for id: int in person_ids:
		if not kept.has(id):
			kept.append(id)
	if kept == order:
		return false
	order = kept
	return true


## Hebt die Bestätigung auf und merkt den Grund (nur wenn bestätigt war).
func lift(reason: StringName) -> void:
	if confirmed:
		confirmed = false
		invalidated = reason


func swap(first_id: int, second_id: int) -> void:
	var a := order.find(first_id)
	var b := order.find(second_id)
	order[a] = second_id
	order[b] = first_id
