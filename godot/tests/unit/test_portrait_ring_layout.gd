extends TestCase
## Geometrie des Porträtkreises (P3): reine Rechnung ohne Szene. Porträtfenster mindestens 56 px (Rahmenbreite 86 ab 13 Personen, P5), runde Porträts und
## Namensschilder überlappen sich nicht, die Tischmitte bleibt frei von Plätzen und im Feld.

## Felder des Sitzkreises: 1024x768 (Chip, 908 x 638), 1280x800 (volle Leiste, 1164 x 592) und größere Fenster.
const AREAS: Array[Vector2] = [Vector2(908.0, 638.0), Vector2(1164.0, 592.0), Vector2(1164.0, 560.0), Vector2(1700.0, 900.0)]


func _circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var nearest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_to(nearest) < radius - 0.5


func _portrait_center(seat: Rect2, d: float, size: Vector2) -> Vector2:
	return seat.position + Vector2(size.x * 0.5, PortraitRingLayout.NUMBER_BAND + d * 0.5)


func _plate(seat: Rect2, d: float, width: float, size: Vector2, span: Vector2) -> Rect2:
	var local := PortraitRingLayout.plate_rect_local(d, size, width, span)
	return Rect2(seat.position + local.position, local.size)


func test_diameter_by_group_size() -> void:
	assert_eq(PortraitRingLayout.diameter_for(6), 104.0, "kleine Runde groß")
	assert_eq(PortraitRingLayout.diameter_for(8), 96.0, "mittel ab 8")
	assert_eq(PortraitRingLayout.diameter_for(13), 86.0, "Ziel 86 ab 13")
	assert_eq(PortraitRingLayout.diameter_for(24), 86.0, "24 Personen")
	for count: int in range(1, 25):
		var face := PortraitRingLayout.diameter_for(count) * GroveArtData.SEAT_HOLE_RADIUS * 2.0
		assert_true(face >= 56.0, "Porträtfenster mindestens 56 px bei %d (%.1f)" % [count, face])


func test_seats_do_not_overlap_and_stay_in_the_area() -> void:
	for area: Vector2 in AREAS:
		for count: int in range(2, 25):
			var result := PortraitRingLayout.layout(count, area)
			var seats: Array = result["seats"]
			var d := float(result["diameter"])
			var size: Vector2 = result["token_size"]
			var widths: Array = result["plate_widths"]
			var spans: Array = result["plate_spans"]
			assert_eq(seats.size(), count, "%d Plätze" % count)
			assert_eq(widths.size(), count, "%d Schildbreiten" % count)
			for i: int in count:
				var seat: Rect2 = seats[i]
				var plate := _plate(seat, d, float(widths[i]), size, spans[i])
				var label := "%dx%d, %d Personen, Platz %d" % [int(area.x), int(area.y), count, i + 1]
				assert_true(Rect2(Vector2.ZERO, area).encloses(Rect2(_portrait_center(seat, d, size) - Vector2.ONE * d * PortraitRingLayout.RING_RADIUS, Vector2.ONE * d * PortraitRingLayout.RING_RADIUS * 2.0)), "%s: Porträt im Feld" % label)
				assert_true(Rect2(Vector2.ZERO, area).encloses(plate), "%s: Schild im Feld" % label)
				assert_true(float(widths[i]) >= PortraitRingLayout.PLATE_MIN_WIDTH, "%s: Schild nicht schmaler als das Minimum" % label)
				for j: int in range(i + 1, count):
					var other: Rect2 = seats[j]
					var other_plate := _plate(other, d, float(widths[j]), size, spans[j])
					assert_true(_portrait_center(seat, d, size).distance_to(_portrait_center(other, d, size)) >= d * PortraitRingLayout.RING_RADIUS * 2.0 - 0.5, "%s/%d: Porträts überlappen" % [label, j + 1])
					assert_false(_circle_hits_rect(_portrait_center(seat, d, size), d * PortraitRingLayout.RING_RADIUS, other_plate), "%s/%d: Porträt berührt Schild" % [label, j + 1])
					assert_false(_circle_hits_rect(_portrait_center(other, d, size), d * PortraitRingLayout.RING_RADIUS, plate), "%s/%d: Schild berührt Porträt" % [label, j + 1])
					assert_false(plate.grow(-0.5).intersects(other_plate.grow(-0.5)), "%s/%d: Schilder überlappen" % [label, j + 1])


func test_center_is_free_of_every_seat_and_inside_the_area() -> void:
	for area: Vector2 in AREAS:
		for count: int in range(2, 25):
			var result := PortraitRingLayout.layout(count, area)
			var center: Rect2 = result["center"]
			var d := float(result["diameter"])
			var size: Vector2 = result["token_size"]
			var widths: Array = result["plate_widths"]
			var spans: Array = result["plate_spans"]
			var label := "%dx%d, %d Personen" % [int(area.x), int(area.y), count]
			assert_true(Rect2(Vector2.ZERO, area).encloses(center), "%s: Mitte im Feld" % label)
			assert_true(center.size.x > 0.0 and center.size.y > 0.0, "%s: Mitte hat eine Fläche" % label)
			for i: int in count:
				var seat: Rect2 = (result["seats"] as Array)[i]
				assert_false(_circle_hits_rect(_portrait_center(seat, d, size), d * PortraitRingLayout.OBSTACLE_RADIUS, center), "%s: Mitte berührt Porträt %d" % [label, i + 1])
				assert_false(_plate(seat, d, float(widths[i]), size, spans[i]).grow(-0.5).intersects(center), "%s: Mitte berührt Schild %d" % [label, i + 1])


func test_center_is_large_enough_for_the_card_in_both_target_sizes() -> void:
	# Die Aktionskarte braucht mindestens rund 480 x 280 (siehe ActionCard); das Feld ist die Fläche des Sitzkreises.
	for cfg: Array in [[24, Vector2(908.0, 638.0)], [6, Vector2(908.0, 638.0)], [24, Vector2(1164.0, 592.0)], [6, Vector2(1164.0, 592.0)]]:
		var center: Rect2 = PortraitRingLayout.layout(int(cfg[0]), cfg[1])["center"]
		assert_true(center.size.x >= 440.0 and center.size.y >= 280.0, "%d Personen, Feld %s: Mitte %s" % [int(cfg[0]), str(cfg[1]), str(center.size)])
