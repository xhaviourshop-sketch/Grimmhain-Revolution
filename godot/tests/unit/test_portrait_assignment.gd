extends TestCase
## Platzporträts (P3): stabil je Personen-ID, bis 24 Personen nie dasselbe Gesicht, Nachbarn nie gleich, nur neutrale Porträtdateien.


func test_faces_are_unique_for_up_to_24_people() -> void:
	for count: int in [6, 12, 24]:
		var seen := {}
		for id: int in range(1, count + 1):
			var n := PortraitAssignment.face_number(id)
			assert_true(n >= 1 and n <= PortraitAssignment.FACE_COUNT, "Gesicht %d liegt im Bereich (Person %d)" % [n, id])
			assert_false(seen.has(n), "%d Personen: Gesicht %d doppelt vergeben (Person %d)" % [count, n, id])
			seen[n] = true


func test_assignment_is_stable_and_independent_of_the_seat() -> void:
	# F-T04: feste Erwartungswerte (Schrittweite 5 über 24 Gesichter) statt eines Vergleichs der Funktion mit sich selbst. Das Gesicht
	# hängt nur an der Personen-ID: Gespeicherte Partien behalten ihre Porträts, auch wenn eine ID im Setup fehlt.
	var expected := {1: 1, 2: 6, 3: 11, 5: 21, 6: 2, 7: 7, 24: 20}
	for id: int in expected:
		assert_eq(PortraitAssignment.face_number(id), expected[id], "Person %d bekommt Gesicht %d" % [id, expected[id]])


func test_consecutive_and_wrapping_ids_never_share_a_face() -> void:
	for id: int in range(1, 60):
		assert_ne(PortraitAssignment.face_number(id), PortraitAssignment.face_number(id + 1), "Personen %d und %d" % [id, id + 1])
		assert_ne(PortraitAssignment.face_number(id), PortraitAssignment.face_number(id + 2), "Personen %d und %d" % [id, id + 2])


func test_every_path_is_an_existing_neutral_portrait() -> void:
	for id: int in range(1, 25):
		var path := PortraitAssignment.face_path(id)
		assert_true(path.begins_with("res://assets/night/portraits/face-"), "nur der Porträtordner (%s)" % path)
		assert_false(path.to_lower().contains("solo") or path.to_lower().contains("wolf"), "kein Solo- oder Wolfsbild (%s)" % path)
		assert_true(ResourceLoader.exists(path), "Porträtdatei importiert (%s)" % path)
