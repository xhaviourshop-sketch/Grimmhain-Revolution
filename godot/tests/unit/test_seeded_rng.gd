extends TestCase
## SeededRng: Seed und Ziehposition sind serialisierbar und reproduzierbar.


func test_same_seed_same_sequence() -> void:
	var a := SeededRng.new(4711)
	var b := SeededRng.new(4711)
	for i: int in 50:
		assert_eq(a.next_int(0, 99), b.next_int(0, 99), "Ziehung %d" % i)
	assert_eq(a.draws, 50, "Ziehposition gezählt")


func test_restore_mid_sequence() -> void:
	var a := SeededRng.new(123456789)
	for i: int in 17:
		a.next_int(0, 1000)
	var b := SeededRng.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_true(b != null, "aus JSON wiederhergestellt")
	assert_eq(b.seed_value, 123456789, "Seed")
	assert_eq(b.draws, 17, "Ziehposition")
	for i: int in 20:
		assert_eq(b.next_int(0, 1000), a.next_int(0, 1000), "Folgeziehung %d" % i)


func test_shuffle_is_deterministic_and_complete() -> void:
	var items: Array = ["a", "b", "c", "d", "e", "f", "g"]
	var x := SeededRng.new(42).shuffled(items)
	var y := SeededRng.new(42).shuffled(items)
	assert_eq(x, y, "gleiche Mischung")
	var sorted_x := x.duplicate()
	sorted_x.sort()
	assert_eq(sorted_x, items, "keine Elemente verloren")
	assert_eq(items, ["a", "b", "c", "d", "e", "f", "g"], "Eingabe unverändert")
