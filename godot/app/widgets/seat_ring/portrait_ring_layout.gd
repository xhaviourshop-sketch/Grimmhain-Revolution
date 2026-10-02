class_name PortraitRingLayout
extends RefCounted
## Anordnung der Porträtplätze auf einer Ellipse (Mockup V3, Abnahme 1): gleichmäßiger Bogenabstand, Platz 1 knapp links von
## der Mitte oben, im Uhrzeigersinn. Reine Rechnung ohne Szene. Liefert je Platz das Rechteck des Steuerelements und die freie
## Tischmitte für die Aktionskarte.
##
## Ein Platz ist ein Steuerelement der Größe `token_size`: oben ein schmaler Rand für das Nummern-Abzeichen, darunter das
## Porträt (Durchmesser `diameter`), darunter das Namensschild. Die Steuerelemente überlappen diagonal, die Tippfläche
## (Porträtkreis und Namensschild) nicht (siehe GameSeatToken._has_point).

const NUMBER_BAND := 2.0   ## Rand oberhalb des Rahmens (die Nummer sitzt im Sockel des Rahmens, P5)
const RING_RADIUS := 0.40  ## Anteil der Rahmenbreite bis zum äußeren Rand des Silberrings: gemeint ist der sichtbare Kreis, nicht das Bildrechteck
const PLATE_HEIGHT := 20.0
const PLATE_DROP := 24.0   ## das Namensschild ragt so weit in den unteren Rahmenrand
const SIDE_MARGIN := 6.0
const CENTER_MAX := Vector2(640.0, 400.0)  ## größte Tischmitte (bei wenigen Personen)
const CENTER_PREFERRED := Vector2(560.0, 340.0)  ## Größe, bis zu der eine größere Tischmitte nichts mehr bringt
const CENTER_MIN_WIDTH := 200.0
const CENTER_WIDTH_STEP := 8.0
const PLATE_OVERHANG := 10.0  ## so weit ragt das Namensschild höchstens über den Rahmenrand
const PLATE_GAP := 2.0       ## Mindestabstand des Schilds zu Nachbarn
const PLATE_MIN_WIDTH := 36.0
const CENTER_GAP := 8.0     ## Abstand der Tischmitte zu Porträts und Schildern


## Breite des Platzrahmens nach Personenzahl (Silberring samt Wurzeln, P5). Das Porträtfenster im Ring ist 0,656 davon: ab 13 Personen
## 86 (Porträt 56,4, Mindestmaß 56), mit weniger Personen größer.
static func diameter_for(count: int) -> float:
	if count >= 13:
		return 86.0
	if count >= 8:
		return 96.0
	return 104.0


static func token_size_for(diameter: float) -> Vector2:
	return Vector2(maxf(diameter + 26.0, 90.0), NUMBER_BAND + diameter + PLATE_HEIGHT - PLATE_DROP)


## Breiteste Namensschild-Breite: schmaler als der Abstand benachbarter Plätze, auch bei langen Namen (der Text wird gekürzt).
static func plate_max_width(diameter: float) -> float:
	return diameter + PLATE_OVERHANG * 2.0


## Mitte des Porträtkreises im Steuerelement.
static func portrait_center(diameter: float) -> Vector2:
	return Vector2(token_size_for(diameter).x * 0.5, NUMBER_BAND + diameter * 0.5)


## Ergebnis: {"seats": Array[Rect2], "diameter": float, "token_size": Vector2, "center": Rect2}. `area` ist die Fläche des Rings.
static func layout(count: int, area: Vector2) -> Dictionary:
	var d := diameter_for(count)
	var size := token_size_for(d)
	var seats: Array[Rect2] = []
	var anchor := portrait_center(d)
	# Ellipse der Porträtmitten: seitlich so weit, dass Porträt und Schild im Feld bleiben, oben und unten mit Rand für Nummer und Schild.
	var top := NUMBER_BAND + d * 0.5
	var bottom := d * 0.5 + PLATE_HEIGHT - PLATE_DROP + 2.0
	var a := maxf(1.0, area.x * 0.5 - size.x * 0.5 - SIDE_MARGIN)
	var b := maxf(1.0, (area.y - top - bottom) * 0.5)
	var centre := Vector2(area.x * 0.5, top + b)
	for p: Vector2 in _ring_points(count, centre, a, b):
		seats.append(Rect2(p - anchor, size))
	return {"seats": seats, "diameter": d, "token_size": size, "center": _free_center(seats, d, size, centre, a, b), "plate_widths": _plate_widths(seats, d, size)}


## Breite des Namensschilds je Platz: so breit wie möglich bis `plate_max_width`, aber so schmal, dass es weder den Porträtkreis eines
## Nachbarn noch dessen Schild berührt (am steilen Rand der Ellipse liegen Nachbarn dicht über- und nebeneinander). Lange Namen werden im
## Schild gekürzt, der volle Name steht auf der Karte.
static func _plate_widths(seats: Array[Rect2], d: float, size: Vector2) -> Array[float]:
	var out: Array[float] = []
	var radius := d * RING_RADIUS
	for i: int in seats.size():
		var band_top := seats[i].position.y + NUMBER_BAND + d - PLATE_DROP
		var half := plate_max_width(d) * 0.5
		var x := seats[i].position.x + size.x * 0.5
		for j: int in seats.size():
			if j == i:
				continue
			var other := seats[j]
			var dx := absf(other.position.x + size.x * 0.5 - x)
			var centre_y := other.position.y + NUMBER_BAND + d * 0.5
			var dy := maxf(maxf(band_top - centre_y, centre_y - (band_top + PLATE_HEIGHT)), 0.0)
			if dy < radius:
				half = minf(half, dx - sqrt(radius * radius - dy * dy) - PLATE_GAP)
			var other_top := other.position.y + NUMBER_BAND + d - PLATE_DROP
			if absf(other_top - band_top) < PLATE_HEIGHT:
				half = minf(half, (dx - PLATE_GAP) * 0.5)
		out.append(maxf(half * 2.0, PLATE_MIN_WIDTH))
	return out


## Freies Rechteck um die Mitte, das kein Porträt (samt Nummer) und kein Namensschild berührt und im Bogen der Ellipse bleibt. Für jede
## Breite (von der größten abwärts) ergibt sich die höchste freie Höhe aus den Hindernissen in dieser Spalte; gewählt wird die Breite mit
## der besten Fläche bis zur bevorzugten Kartengröße (CENTER_PREFERRED), damit die Karte nicht schmal und flach wird.
static func _free_center(seats: Array[Rect2], d: float, size: Vector2, centre: Vector2, a: float, b: float) -> Rect2:
	var obstacles: Array[Rect2] = []
	for r: Rect2 in seats:
		obstacles.append(Rect2(r.position + Vector2((size.x - d) * 0.5, 0.0), Vector2(d, NUMBER_BAND + d)))
		obstacles.append(Rect2(r.position + Vector2(0.0, NUMBER_BAND + d - PLATE_DROP), Vector2(size.x, PLATE_HEIGHT)))
	var best := Rect2(centre, Vector2.ZERO)
	var best_score := -1.0
	var width := minf(a * 2.0, CENTER_MAX.x)
	while width >= CENTER_MIN_WIDTH:
		var column := Rect2(centre.x - width * 0.5 - CENTER_GAP, -INF, width + CENTER_GAP * 2.0, INF)
		var up := minf(b, CENTER_MAX.y * 0.5)
		var down := up
		for o: Rect2 in obstacles:
			if o.position.x >= column.end.x or o.end.x <= column.position.x:
				continue
			if o.get_center().y < centre.y:
				up = minf(up, centre.y - o.end.y - CENTER_GAP)
			else:
				down = minf(down, o.position.y - centre.y - CENTER_GAP)
		var half := maxf(0.0, minf(up, down))
		var score := minf(width, CENTER_PREFERRED.x) * minf(half * 2.0, CENTER_PREFERRED.y) + width * half * 0.001
		if score > best_score:
			best_score = score
			best = Rect2(centre - Vector2(width * 0.5, half), Vector2(width, half * 2.0))
		width -= CENTER_WIDTH_STEP
	return best


## Punkte in gleichem Bogenabstand auf der Ellipse, im Uhrzeigersinn; der erste liegt eine halbe Teilung links von oben.
static func _ring_points(count: int, centre: Vector2, a: float, b: float) -> Array[Vector2]:
	var samples := 2000
	var cum: Array[float] = [0.0]
	var prev := Vector2(0.0, -b)
	for i: int in range(1, samples + 1):
		var t := -PI * 0.5 + TAU * float(i) / float(samples)
		var pt := Vector2(cos(t) * a, sin(t) * b)
		cum.append(cum[i - 1] + prev.distance_to(pt))
		prev = pt
	var total: float = cum[samples]
	var out: Array[Vector2] = []
	for k: int in count:
		var target := total * float(k) / float(count) - total / float(count) * 0.5
		if target < 0.0:
			target += total
		var idx := 0
		while idx < samples and cum[idx] < target:
			idx += 1
		var t := -PI * 0.5 + TAU * float(idx) / float(samples)
		out.append(centre + Vector2(cos(t) * a, sin(t) * b))
	return out
