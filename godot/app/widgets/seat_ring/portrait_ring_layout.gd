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
const OBSTACLE_RADIUS := 0.44  ## Anteil der Rahmenbreite für die Tischmitte: Ring samt Wurzeln (das Bildrechteck ist größer als das Sichtbare)
const PLATE_BIAS := 11.0  ## so viel (je Seite, also 2x insgesamt) darf ein Schild zur freieren Seite über die symmetrische Breite hinaus wachsen
const PLATE_HEIGHT := 20.0
const PLATE_DROP := 12.0 * 2.0   ## das Namensschild ragt so weit in den unteren Rahmenrand
const SIDE_MARGIN := 6.0
const CENTER_MAX := Vector2(640.0, 400.0)  ## größte Tischmitte (bei wenigen Personen)
const CENTER_PREFERRED := Vector2(560.0, 340.0)  ## Größe, bis zu der eine größere Tischmitte nichts mehr bringt
const CENTER_MIN_WIDTH := 200.0
const CENTER_WIDTH_STEP := 8.0
const PLATE_OVERHANG := 20.0  ## so weit ragt das Namensschild höchstens über den Rahmenrand
const PLATE_GAP := 2.0       ## Mindestabstand des Schilds zu Nachbarn
const PLATE_MIN_WIDTH := 36.0
const CENTER_GAP := 8.0     ## Abstand der Tischmitte zu Porträts und Schildern
const RING_SHAPE := 2.15 ## Exponent der Ringform: 2 = Ellipse, größer = kantiger. Rückt die Plätze in den Ecken nach außen (oben und unten mehr Abstand)
const COMPACT_MIN_DIAMETER := 44.0  ## kompakter Ring (flache Fläche über der Rollenleiste): kleinster Rahmen
const COMPACT_SPACING := 0.94       ## kompakter Ring: Mindestabstand benachbarter Porträtmitten in Rahmenbreiten (der sichtbare Ring misst 0,8)


## Breite des Platzrahmens nach Personenzahl (Silberring samt Wurzeln, P5). Das Porträtfenster im Ring ist 0,656 davon: ab 13 Personen
## 86 (Porträt 56,4, Mindestmaß 56), mit weniger Personen größer.
static func diameter_for(count: int) -> float:
	if count >= 13:
		return 86.0
	if count >= 8:
		return 96.0
	return 104.0


## Nummern-Abzeichen: Mitte relativ zur Porträtmitte und Radius (Sockel des Rahmens, siehe GroveArtData.SEAT_SOCKET_*). Es ragt oben links über den Ring hinaus.
static func badge_offset(d: float) -> Vector2:
	return Vector2((GroveArtData.SEAT_SOCKET_CENTER.x - GroveArtData.SEAT_HOLE_CENTER.x) * d, (GroveArtData.SEAT_SOCKET_CENTER.y - GroveArtData.SEAT_HOLE_CENTER.y) * d * GroveArtData.SEAT_ASPECT)


static func badge_radius(d: float) -> float:
	return GroveArtData.SEAT_SOCKET_RADIUS * d * 1.05


static func token_size_for(diameter: float) -> Vector2:
	return Vector2(maxf(diameter + 40.0, 90.0), NUMBER_BAND + diameter + PLATE_HEIGHT - PLATE_DROP)


## Breiteste Namensschild-Breite: schmaler als der Abstand benachbarter Plätze, auch bei langen Namen (der Text wird gekürzt).
static func plate_max_width(diameter: float) -> float:
	return diameter + PLATE_OVERHANG * 2.0


## Mitte des Porträtkreises im Steuerelement.
static func portrait_center(diameter: float) -> Vector2:
	return Vector2(token_size_for(diameter).x * 0.5, NUMBER_BAND + diameter * 0.5)


## Ergebnis: {"seats": Array[Rect2], "diameter": float, "token_size": Vector2, "center": Rect2}. `area` ist die Fläche des Rings.
## `compact`: flache Fläche (Rollenleiste offen): die Rahmen werden gleichmäßig so weit verkleinert, dass sich keine zwei Porträts berühren.
static func layout(count: int, area: Vector2, compact: bool = false) -> Dictionary:
	var d := diameter_for(count)
	if compact:
		d = _compact_diameter(count, area, d)
	var size := token_size_for(d)
	var seats: Array[Rect2] = []
	var anchor := portrait_center(d)
	# Ellipse der Porträtmitten: seitlich so weit, dass Porträt und Schild im Feld bleiben, oben und unten mit Rand für Nummer und Schild.
	var top := NUMBER_BAND + d * 0.5
	var bottom := d * 0.5 + PLATE_HEIGHT - PLATE_DROP + 2.0
	var a := maxf(1.0, area.x * 0.5 - size.x * 0.5 - SIDE_MARGIN)
	var b := maxf(1.0, (area.y - top - bottom) * 0.5)
	var centre := Vector2(area.x * 0.5, top + b)
	var points: Array[Vector2] = _row_points(count, area, size, top, bottom) if compact else _ring_points(count, centre, a, b)
	for p: Vector2 in points:
		seats.append(Rect2(p - anchor, size))
	var spans := _plate_spans(seats, d, size)
	var widths: Array[float] = []
	for span: Vector2 in spans:
		widths.append(span.x + span.y)
	return {"seats": seats, "diameter": d, "token_size": size, "center": _free_center(seats, d, size, centre, a, b, spans), "plate_widths": widths, "plate_spans": spans}


## Größter Rahmen bis `start`, bei dem benachbarte Porträtmitten auf der flachen Ellipse mindestens COMPACT_SPACING Rahmenbreiten auseinanderliegen.
static func _compact_diameter(count: int, area: Vector2, start: float) -> float:
	var d := start
	while d > COMPACT_MIN_DIAMETER:
		var size := token_size_for(d)
		var top := NUMBER_BAND + d * 0.5
		var bottom := d * 0.5 + PLATE_HEIGHT - PLATE_DROP + 2.0
		if _compact_fits(_row_points(count, area, size, top, bottom), d):
			return d
		d -= 2.0
	return COMPACT_MIN_DIAMETER


## Flache Ellipse als zwei gleichmäßige Reihen (oben von links nach rechts, unten von rechts nach links, im Uhrzeigersinn): Enden und
## Mitte haben denselben Abstand, nichts steht auf der steilen Seite einer schmalen Ellipse übereinander gedrängt.
static func _row_points(count: int, area: Vector2, size: Vector2, top: float, bottom: float) -> Array[Vector2]:
	var upper := (count + 1) / 2
	var lower := count - upper
	var left := size.x * 0.5 + SIDE_MARGIN
	var width := maxf(1.0, area.x - size.x - SIDE_MARGIN * 2.0)
	var out: Array[Vector2] = []
	for k: int in upper:
		out.append(Vector2(left + width * (float(k) + 0.5) / float(upper), top))
	for k: int in lower:
		out.append(Vector2(left + width * (1.0 - (float(k) + 0.5) / float(lower)), area.y - bottom))
	return out


## Kein Paar von Plätzen berührt sich: nebeneinander mindestens COMPACT_SPACING Rahmenbreiten Abstand, übereinander Platz für Porträt und Schild.
static func _compact_fits(points: Array[Vector2], d: float) -> bool:
	var stacked := d * RING_RADIUS * 2.0 + PLATE_HEIGHT - PLATE_DROP + 6.0
	for i: int in points.size():
		for j: int in range(i + 1, points.size()):
			if absf(points[i].x - points[j].x) < d * COMPACT_SPACING and absf(points[i].y - points[j].y) < stacked:
				return false
	return true


## Breite des Namensschilds je Platz: so breit wie möglich bis `plate_max_width`, aber so schmal, dass es weder den Porträtkreis eines
## Nachbarn noch dessen Schild berührt (am steilen Rand der Ellipse liegen Nachbarn dicht über- und nebeneinander). Lange Namen werden im
## Schild gekürzt, der volle Name steht auf der Karte.
static func _plate_spans(seats: Array[Rect2], d: float, size: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var radius := d * RING_RADIUS
	var badge_r := badge_radius(d)
	for i: int in seats.size():
		var band_top := seats[i].position.y + NUMBER_BAND + d - PLATE_DROP
		var cap := plate_max_width(d) * 0.5
		var span := Vector2(cap, cap)  # (nach links, nach rechts) von der Mitte des Platzes; ein Nachbar beschränkt nur seine Seite
		var x := seats[i].position.x + size.x * 0.5
		for j: int in seats.size():
			if j == i:
				continue
			var other := seats[j]
			var signed_dx := other.position.x + size.x * 0.5 - x
			var dx := absf(signed_dx)
			var side := 1 if signed_dx > 0.0 else 0
			var centre_y := other.position.y + NUMBER_BAND + d * 0.5
			var dy := maxf(maxf(band_top - centre_y, centre_y - (band_top + PLATE_HEIGHT)), 0.0)
			if dy < radius:
				span[side] = minf(span[side], dx - sqrt(radius * radius - dy * dy) - PLATE_GAP)
			# Das Nummern-Abzeichen des Nachbarn (oben links an seinem Rahmen) bleibt ebenfalls frei.
			var badge_x := signed_dx + badge_offset(d).x
			var badge_dy := maxf(maxf(band_top - (centre_y + badge_offset(d).y), (centre_y + badge_offset(d).y) - (band_top + PLATE_HEIGHT)), 0.0)
			if badge_dy < badge_r:
				var badge_side := 1 if badge_x > 0.0 else 0
				span[badge_side] = minf(span[badge_side], absf(badge_x) - sqrt(badge_r * badge_r - badge_dy * badge_dy) - PLATE_GAP)
			var other_top := other.position.y + NUMBER_BAND + d - PLATE_DROP
			if absf(other_top - band_top) < PLATE_HEIGHT:
				span[side] = minf(span[side], (dx - PLATE_GAP) * 0.5)
		span.x = maxf(span.x, 0.0)
		span.y = maxf(span.y, 0.0)
		var narrow := minf(span.x, span.y)
		span = Vector2(minf(span.x, narrow + PLATE_BIAS), minf(span.y, narrow + PLATE_BIAS))  # zur freien Seite nur begrenzt wachsen (die Tischmitte braucht Platz)
		if span.x + span.y < PLATE_MIN_WIDTH:
			span = Vector2(PLATE_MIN_WIDTH * 0.5, PLATE_MIN_WIDTH * 0.5)
		out.append(span)
	return out


## Schildrechteck im Steuerelement eines Platzes: Breite `width`, möglichst mittig unter dem Rahmen, aber innerhalb der Spanne
## (nach links, nach rechts), die die Nachbarn lassen. So darf ein Schild an dichten Stellen zur freien Seite wachsen.
static func plate_rect_local(d: float, size: Vector2, width: float, span: Vector2) -> Rect2:
	var half := width * 0.5
	var shift := clampf(0.0, -span.x + half, span.y - half)
	return Rect2(size.x * 0.5 + shift - half, NUMBER_BAND + d - PLATE_DROP, width, PLATE_HEIGHT)


## Freies Rechteck um die Mitte, das kein Porträt (samt Nummer) und kein Namensschild berührt und im Bogen der Ellipse bleibt. Für jede
## Breite (von der größten abwärts) ergibt sich die höchste freie Höhe aus den Hindernissen in dieser Spalte; gewählt wird die Breite mit
## der besten Fläche bis zur bevorzugten Kartengröße (CENTER_PREFERRED), damit die Karte nicht schmal und flach wird.
static func _free_center(seats: Array[Rect2], d: float, size: Vector2, centre: Vector2, a: float, b: float, spans: Array[Vector2]) -> Rect2:
	var obstacles: Array[Rect2] = []
	var reach := d * OBSTACLE_RADIUS
	for i: int in seats.size():
		var r: Rect2 = seats[i]
		var middle := r.position + Vector2(size.x * 0.5, NUMBER_BAND + d * 0.5)
		obstacles.append(Rect2(middle - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))
		obstacles.append(Rect2(r.position + Vector2(size.x * 0.5 - spans[i].x, NUMBER_BAND + d - PLATE_DROP), Vector2(spans[i].x + spans[i].y, PLATE_HEIGHT)))
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
		var pt := _shape_point(-PI * 0.5 + TAU * float(i) / float(samples), a, b)
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
		out.append(centre + _shape_point(-PI * 0.5 + TAU * float(idx) / float(samples), a, b))
	return out


static func _shape_point(t: float, a: float, b: float) -> Vector2:
	var power := 2.0 / RING_SHAPE
	return Vector2(signf(cos(t)) * pow(absf(cos(t)), power) * a, signf(sin(t)) * pow(absf(sin(t)), power) * b)
