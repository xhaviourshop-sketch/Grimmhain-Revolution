class_name PortraitRingLayout
extends RefCounted
## Anordnung der Porträtplätze auf einer Ellipse (Mockup V3, Abnahme 1): gleichmäßiger Bogenabstand, Platz 1 knapp links von
## der Mitte oben, im Uhrzeigersinn. Reine Rechnung ohne Szene. Liefert je Platz das Rechteck des Steuerelements und die freie
## Tischmitte für die Aktionskarte.
##
## Ein Platz ist ein Steuerelement der Größe `token_size`: oben ein schmaler Rand für das Nummern-Abzeichen, darunter das
## Porträt (Durchmesser `diameter`), darunter das Namensschild. Die Steuerelemente überlappen diagonal, die Tippfläche
## (Porträtkreis und Namensschild) nicht (siehe GameSeatToken._has_point).

const NUMBER_BAND := 2.0   ## schmaler Rand oberhalb des Rahmens (Rahmen ohne Nummernsockel)
const RING_RADIUS := 0.40  ## Anteil der Rahmenbreite bis zum äußeren Rand des Silberrings: gemeint ist der sichtbare Kreis, nicht das Bildrechteck
const OBSTACLE_RADIUS := 0.44  ## Anteil der Rahmenbreite für die Tischmitte: Ring samt Wurzeln (das Bildrechteck ist größer als das Sichtbare)
const PLATE_BIAS := 40.0  ## so viel (je Seite, also 2x insgesamt) darf ein Schild zur freieren Seite über die symmetrische Breite hinaus wachsen
const PLATE_BIAS_TWO := 80.0  ## wie PLATE_BIAS, aber für Plätze mit zweizeiligem Schild
const PLATE_BIAS_THREE := 120.0  ## wie PLATE_BIAS, aber für Plätze mit dreizeiligem Schild
const PLATE_HEIGHT := 22.0  ## Schild mit einer Zeile
const PLATE_HEIGHT_TWO := 36.0  ## Schild mit zwei Zeilen; so hoch rechnet das Layout jeden Platz (Platz für lange Namen, DA-104)
const PLATE_HEIGHT_THREE := 51.0  ## Schild mit drei Zeilen (lange Namen bei 24 Personen, DA-104)
const RING_X_WEIGHT_DENSE := 0.72  ## ab 20 Personen zählt der Weg in x nur so viel für den Bogenabstand: oben und unten stehen die Plätze weiter auseinander (breitere Schilder), an den Seiten enger
const PLATE_DROP := 12.0 * 2.0   ## das Namensschild ragt so weit in den unteren Rahmenrand
const SIDE_MARGIN := 6.0
const CENTER_MAX := Vector2(640.0, 400.0)  ## größte Tischmitte (bei wenigen Personen)
const CENTER_PREFERRED := Vector2(560.0, 340.0)  ## Größe, bis zu der eine größere Tischmitte nichts mehr bringt
const CENTER_MIN_WIDTH := 200.0
const CENTER_WIDTH_STEP := 8.0
const PLATE_OVERHANG := 36.0  ## so weit ragt das Namensschild höchstens über den Rahmenrand
const PLATE_SIDE_MAX := 70.0  ## ab 20 Personen: so viel Platz (Mitte des Seitenplatzes bis Rand) für ein dreizeiliges Schild nach außen
const PLATE_PREFERRED_ONE := 80.0  ## ein Schild bis zu dieser Breite steht einzeilig (für die Verteilung der Plätze, ab 20 Personen)
const PLATE_PREFERRED_TWO := 100.0  ## bis zu dieser Breite zweizeilig, sonst dreizeilig
const DENSE_TOP_INSET := 12.0  ## ab 20 Personen: die obere Reihe steht so weit tiefer (die Statuschips der Nachtansicht ragen links oben in den Ring)
const PAIR_GAP_VERTICAL := 4.0  ## Abstand zweier übereinander laufender Porträtringe
const CARD_MIN := Vector2(460.0, 280.0)  ## kleinste Fläche der Aktionskarte (Mindestbreite der Karte 460); die Schilder bleiben ab 20 Personen daraus heraus
const PLATE_GAP := 8.0       ## Mindestabstand des Schilds zu Nachbarn
const PLATE_MIN_WIDTH := 36.0
const CENTER_GAP := 8.0     ## Abstand der Tischmitte zu Porträts und Schildern
const RING_SHAPE_DENSE := 3.4  ## ab 20 Personen eckiger: mehr Bogenlänge, die Schilder oben und unten stehen weiter auseinander
const RING_SHAPE := 2.15 ## Exponent der Ringform: 2 = Ellipse, größer = kantiger. Rückt die Plätze in den Ecken nach außen (oben und unten mehr Abstand)
const COMPACT_MIN_DIAMETER := 44.0  ## kompakter Ring (flache Fläche über der Rollenleiste): kleinster Rahmen
const COMPACT_SPACING := 0.94       ## kompakter Ring: Mindestabstand benachbarter Porträtmitten in Rahmenbreiten (der sichtbare Ring misst 0,8)


## Breite des Platzrahmens nach Personenzahl (Silberring samt Wurzeln, P5). Das Porträtfenster im Ring ist 0,656 davon: ab 13 Personen
## 86 (Porträt 56,4, Mindestmaß 56), mit weniger Personen größer.
static func diameter_for(count: int) -> float:
	if count >= 20:
		return 72.0
	if count >= 13:
		return 86.0
	if count >= 8:
		return 96.0
	return 104.0


static func token_size_for(diameter: float) -> Vector2:
	return Vector2(maxf(diameter + 40.0, 90.0), NUMBER_BAND + diameter + PLATE_HEIGHT_THREE - PLATE_DROP)


## Höhe des Schilds mit `lines` Zeilen (1 bis 3).
static func plate_height(lines: int) -> float:
	if lines >= 3:
		return PLATE_HEIGHT_THREE
	return PLATE_HEIGHT_TWO if lines == 2 else PLATE_HEIGHT


## Breiteste Namensschild-Breite: schmaler als der Abstand benachbarter Plätze, auch bei langen Namen (der Text wird gekürzt).
static func plate_max_width(diameter: float) -> float:
	return diameter + PLATE_OVERHANG * 2.0


## Mitte des Porträtkreises im Steuerelement.
static func portrait_center(diameter: float) -> Vector2:
	return Vector2(token_size_for(diameter).x * 0.5, NUMBER_BAND + diameter * 0.5)


## Ergebnis: {"seats": Array[Rect2], "diameter": float, "token_size": Vector2, "center": Rect2, "plate_widths", "plate_spans", "plate_heights", "plate_lines"}.
## `area` ist die Fläche des Rings. `plate_needs`: je Platz die Schildbreiten [eine, zwei, drei Zeilen], die der Name braucht (leer = jeder Platz rechnet
## mit zwei Zeilen). Passt der Name in die Spanne, behält das Schild eine Zeile, sonst zwei, sonst drei; höhere Schilder lassen den Nachbarn weniger
## Breite, darum bekommen nur die Plätze mehr Zeilen, die sie brauchen. Passt auch drei Zeilen nicht, kürzt der Platz die letzte Zeile (Namen über 32 Zeichen).
## `compact`: flache Fläche (Rollenleiste offen): die Rahmen werden gleichmäßig so weit verkleinert, dass sich keine zwei Porträts berühren; höchstens zwei Zeilen.
static func layout(count: int, area: Vector2, compact: bool = false, plate_needs: Array = []) -> Dictionary:
	var extra: Array[float] = []
	extra.resize(count)
	extra.fill(0.0)
	var result := _layout_core(count, area, compact, plate_needs, extra)
	# Viele Personen: reicht bei einem Namen die Breite nicht, bekommt sein Platz beim nächsten Durchgang mehr Bogenlänge (auf Kosten freierer Nachbarn).
	for _pass: int in 5:
		var short := false
		for i: int in count:
			var deficit := float((result["deficits"] as Array)[i])
			if deficit > 0.0:
				extra[i] += deficit + 2.0
				short = true
		if not short or not (count >= 20 and not compact and plate_needs.size() == count):
			break
		result = _layout_core(count, area, compact, plate_needs, extra)
	result.erase("deficits")
	return result


static func _layout_core(count: int, area: Vector2, compact: bool, plate_needs: Array, extra: Array[float]) -> Dictionary:
	var d := diameter_for(count)
	if compact:
		d = _compact_diameter(count, area, d)
	var size := token_size_for(d)
	var seats: Array[Rect2] = []
	var anchor := portrait_center(d)
	# Ellipse der Porträtmitten: seitlich so weit, dass Porträt und Schild im Feld bleiben, oben und unten mit Rand für Nummer und Schild.
	var dense := count >= 20 and not compact and plate_needs.size() == count  # viele Personen mit bekannten Namen: Plätze nach Bedarf der Namen verteilen
	var top := NUMBER_BAND + d * 0.5 + (DENSE_TOP_INSET if dense else 0.0)
	var bottom := d * 0.5 + (PLATE_HEIGHT_THREE if plate_needs.size() == count and not compact else PLATE_HEIGHT_TWO) - PLATE_DROP + 2.0
	var side := size.x * 0.5
	if dense:
		# Viele Personen: die Seitenplätze brauchen nach außen Platz für das breiteste Schild (drei Zeilen), sonst bleibt nur ein schmaler Streifen.
		var widest := 0.0
		for need: Variant in plate_needs:
			widest = maxf(widest, float((need as Array)[2]))
		side = maxf(side, minf(widest, PLATE_SIDE_MAX))
	var a := maxf(1.0, area.x * 0.5 - side - SIDE_MARGIN)
	var b := maxf(1.0, (area.y - top - bottom) * 0.5)
	var centre := Vector2(area.x * 0.5, top + b)
	var points: Array[Vector2] = _row_points(count, area, size, top, bottom) if compact else _ring_points(count, centre, a, b, RING_X_WEIGHT_DENSE if dense else 1.0, [], RING_SHAPE_DENSE if dense else RING_SHAPE)
	if dense:
		points = _fit_to_names(points, plate_needs, d, centre, a, b, extra)
	for p: Vector2 in points:
		seats.append(Rect2(p - anchor, size))
	var most := 2 if compact else 3
	var lines: Array[int] = []
	for i: int in count:
		lines.append(2 if plate_needs.size() != count else 1)
	var reserved := Rect2(centre - CARD_MIN * 0.5, CARD_MIN).grow(CENTER_GAP) if plate_needs.size() == count and not compact else Rect2()  # die Aktionskarte bleibt frei
	var cap_total := plate_max_width(d) if plate_needs.size() == count else d + 40.0  # ohne Namen wie bisher: höchstens so breit wie der Platz
	var targets := _plate_targets(lines, plate_needs, count, cap_total)
	var spans := _plate_spans(seats, d, size, lines, targets, area.x, cap_total, plate_needs.size() != count, reserved)
	for _round: int in 8:
		var changed := false
		for i: int in count:
			if plate_needs.size() == count and lines[i] < most and _promote(plate_needs[i] as Array, lines[i], minf(spans[i].x + spans[i].y, cap_total)):
				lines[i] += 1
				changed = true
		if not changed:
			break
		targets = _plate_targets(lines, plate_needs, count, cap_total)
		spans = _plate_spans(seats, d, size, lines, targets, area.x, cap_total, plate_needs.size() != count, reserved)
	var widths: Array[float] = []
	var heights: Array[float] = []
	for i: int in count:
		widths.append(minf(spans[i].x + spans[i].y, _plate_goal(plate_needs, i, lines[i], targets[i]) if plate_needs.size() == count else cap_total))
		heights.append(plate_height(lines[i]))
	var deficits: Array[float] = []
	for i: int in count:
		var short := 0.0
		if plate_needs.size() == count:
			short = maxf(0.0, float((plate_needs[i] as Array)[lines[i] - 1]) - minf(spans[i].x + spans[i].y, cap_total))
		deficits.append(short)
	return {"deficits": deficits, "seats": seats, "diameter": d, "token_size": size, "center": _free_center(seats, d, size, centre, a, b, spans, heights, CARD_MIN if reserved.size.x > 0.0 else Vector2.ZERO), "plate_widths": widths, "plate_spans": spans, "plate_heights": heights, "plate_lines": lines}


## Preisgabe der Gleichverteilung bei vielen Personen: jedes Paar benachbarter Plätze bekommt so viel Bogenlänge, wie die beiden Namensschilder (nebeneinander,
## wo der Ring waagerecht läuft) oder die beiden Porträts (übereinander, wo er senkrecht läuft) brauchen; lange Namen stehen so nicht Schild an Schild.
static func _fit_to_names(start: Array[Vector2], plate_needs: Array, d: float, centre: Vector2, a: float, b: float, extra: Array[float]) -> Array[Vector2]:
	var count := start.size()
	var widths: Array[float] = []
	var heights: Array[float] = []
	for need: Variant in plate_needs:
		var n := need as Array
		var w := float(n[0])
		var rows := 1
		if w > PLATE_PREFERRED_ONE:
			w = float(n[1])
			rows = 2
			if w > PLATE_PREFERRED_TWO:
				w = float(n[2])
				rows = 3
		widths.append(minf(w, plate_max_width(d)) + extra[widths.size()])
		heights.append(plate_height(rows))
	var points := start
	for _pass: int in 3:
		var weights: Array[float] = []
		for k: int in count:
			var delta := points[(k + 1) % count] - points[k]
			var length := maxf(delta.length(), 0.001)
			var horizontal := (widths[k] + widths[(k + 1) % count]) * 0.5 + PLATE_GAP
			# übereinander: die Porträtringe berühren sich nicht, und das Schild des oberen Platzes hängt nicht in den Ring des unteren
			var upper := k if delta.y > 0.0 else (k + 1) % count
			var vertical := maxf(d * RING_RADIUS * 2.0, NUMBER_BAND + d * 0.5 - PLATE_DROP + heights[upper] + d * RING_RADIUS) + PAIR_GAP_VERTICAL
			# Nebeneinander (waagerecht genug Abstand für beide Schilder) oder übereinander (senkrecht genug für beide Porträtringe): was zuerst reicht.
			var along := minf(horizontal / maxf(absf(delta.x) / length, 0.001), vertical / maxf(absf(delta.y) / length, 0.001))
			weights.append(maxf(along, vertical))
		points = _ring_points(count, centre, a, b, 1.0, weights, RING_SHAPE_DENSE, d * RING_RADIUS * 2.0 + 1.0)
	return points


## Größter Rahmen bis `start`, bei dem benachbarte Porträtmitten auf der flachen Ellipse mindestens COMPACT_SPACING Rahmenbreiten auseinanderliegen.
static func _compact_diameter(count: int, area: Vector2, start: float) -> float:
	var d := start
	while d > COMPACT_MIN_DIAMETER:
		var size := token_size_for(d)
		var top := NUMBER_BAND + d * 0.5
		var bottom := d * 0.5 + PLATE_HEIGHT_TWO - PLATE_DROP + 2.0
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
	var stacked := d * RING_RADIUS * 2.0 + PLATE_HEIGHT_TWO - PLATE_DROP + 6.0
	for i: int in points.size():
		for j: int in range(i + 1, points.size()):
			if absf(points[i].x - points[j].x) < d * COMPACT_SPACING and absf(points[i].y - points[j].y) < stacked:
				return false
	return true


## Ein Schild bekommt eine Zeile mehr, wenn der Name die jetzige Breite nicht hat und eine Zeile mehr ihm wirklich Breite spart.
static func _promote(need: Array, lines: int, room: float) -> bool:
	return float(need[lines - 1]) > room + 0.01 and float(need[lines]) < float(need[lines - 1]) - 0.5


## Breite, bis zu der ein Schild wachsen darf: das Mindestmaß seines Namens, bei freier Spanne die Breite der schöneren Aufteilung (nur an Leerzeichen und Bindestrich).
static func _plate_goal(plate_needs: Array, i: int, lines: int, target: float) -> float:
	var need := plate_needs[i] as Array
	if lines >= 2 and need.size() > 3:
		var nice := float(need[lines + 1])
		if nice < INF:
			return maxf(target, nice) + 0.5
	return target + 0.5


## Breite, die ein Schild voraussichtlich belegt: die Breite, die sein Name bei der jetzigen Zeilenzahl braucht (ohne Angaben: die Obergrenze).
static func _plate_targets(lines: Array[int], plate_needs: Array, count: int, cap_total: float) -> Array[float]:
	var out: Array[float] = []
	for i: int in count:
		out.append(minf(float((plate_needs[i] as Array)[lines[i] - 1]), cap_total) if plate_needs.size() == count else cap_total)
	return out


## Breite des Namensschilds je Platz: so breit wie möglich bis `plate_max_width`, aber so schmal, dass es weder den Porträtkreis eines
## Nachbarn noch dessen Schild berührt (am steilen Rand der Ellipse liegen Nachbarn dicht über- und nebeneinander). Lange Namen werden im
## Schild gekürzt, der volle Name steht auf der Karte.
## Anteil der Lücke `gap` zwischen zwei Schildern in einer Höhe, der dem ersten gehört: seine halbe Breite plus die Hälfte des Rests (beide Anteile ergeben
## genau `gap`); reicht die Lücke nicht für beide, teilen sie sich nach Breite.
static func _gap_share(gap: float, own: float, other: float) -> float:
	var spare := gap - (own + other) * 0.5
	if spare >= 0.0:
		return own * 0.5 + spare * 0.5
	return gap * own / maxf(own + other, 1.0)


static func _plate_spans(seats: Array[Rect2], d: float, size: Vector2, lines: Array[int], targets: Array[float], area_width: float, cap_total: float, default_mode: bool, reserved: Rect2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var radius := d * RING_RADIUS
	var mid_x := 0.0
	for seat: Rect2 in seats:
		mid_x += seat.position.x + size.x * 0.5
	mid_x /= float(maxi(seats.size(), 1))
	for i: int in seats.size():
		var band_top := seats[i].position.y + NUMBER_BAND + d - PLATE_DROP
		var band_height := plate_height(lines[i])
		var cap := cap_total * 0.5 if default_mode else cap_total  # mit bekannten Namen darf ein Schild auch ganz auf eine Seite wachsen (neben einen Nachbarring)
		var span := Vector2(cap_total, cap_total)  # (nach links, nach rechts) von der Mitte des Platzes; ein Nachbar beschränkt nur seine Seite
		var x := seats[i].position.x + size.x * 0.5
		for j: int in seats.size():
			if j == i:
				continue
			var other := seats[j]
			var signed_dx := other.position.x + size.x * 0.5 - x
			var dx := absf(signed_dx)
			var side := 1 if signed_dx > 0.0 else 0
			var centre_y := other.position.y + NUMBER_BAND + d * 0.5
			var dy := maxf(maxf(band_top - centre_y, centre_y - (band_top + band_height)), 0.0)
			if dy < radius:
				span[side] = minf(span[side], dx - sqrt(radius * radius - dy * dy) - PLATE_GAP)
			var other_top := other.position.y + NUMBER_BAND + d - PLATE_DROP
			var other_height := plate_height(lines[j])
			if other_top < band_top + band_height and band_top < other_top + other_height:
				span[side] = minf(span[side], _gap_share(dx - PLATE_GAP, targets[i], targets[j]))
		# Eine Spanne darf negativ sein: liegt der Nachbarkreis genau unter oder über dem Platz, steht das Schild ganz auf der freien Seite neben ihm.
		var raw := span
		span = Vector2(minf(span.x, cap), minf(span.y, cap))  # ohne die freie Seite (siehe unten) wächst das Schild nur bis zur halben Obergrenze je Seite
		var narrow := minf(span.x, span.y)
		# Zur Tischmitte hin nur begrenzt wachsen (die Mitte braucht Platz); nach außen am Rand des Rings darf das Schild bis zur Obergrenze
		# wachsen, damit auch dicht gedrängte Namen vollständig stehen (nie gekürzt).
		var outward := signf(x - mid_x) if absf(x - mid_x) > d else 0.0
		var bias: float = [PLATE_BIAS, PLATE_BIAS_TWO, PLATE_BIAS_THREE][lines[i] - 1]  # ein mehrzeiliges Schild braucht die Breite für den Namen, die Mitte verliert dafür wenig
		span = Vector2(minf(span.x, narrow + bias), minf(span.y, narrow + bias))
		if outward < 0.0:
			span.x = minf(raw.x, cap_total)
		elif outward > 0.0:
			span.y = minf(raw.y, cap_total)
		if reserved.size.x > 0.0 and band_top < reserved.end.y and band_top + band_height > reserved.position.y:
			if x < reserved.get_center().x:
				span.y = minf(span.y, reserved.position.x - x)
			else:
				span.x = minf(span.x, x - reserved.end.x)
		var at_left_edge := span.x > x - SIDE_MARGIN
		var at_right_edge := span.y > area_width - x - SIDE_MARGIN
		span = Vector2(minf(span.x, x - SIDE_MARGIN), minf(span.y, area_width - x - SIDE_MARGIN))  # das Schild bleibt im Feld
		if span.x + span.y < PLATE_MIN_WIDTH:
			var missing := PLATE_MIN_WIDTH - span.x - span.y
			if at_right_edge and missing <= SIDE_MARGIN:
				span.y += missing  # lieber ein paar Pixel in den Rand als ein Schild über dem Nachbarn
			elif at_left_edge and missing <= SIDE_MARGIN:
				span.x += missing
			else:
				span = Vector2(PLATE_MIN_WIDTH * 0.5, PLATE_MIN_WIDTH * 0.5)
		out.append(span)
	return out


## Schildrechteck im Steuerelement eines Platzes: Breite `width`, möglichst mittig unter dem Rahmen, aber innerhalb der Spanne
## (nach links, nach rechts), die die Nachbarn lassen. So darf ein Schild an dichten Stellen zur freien Seite wachsen.
static func plate_rect_local(d: float, size: Vector2, width: float, span: Vector2, height: float = PLATE_HEIGHT) -> Rect2:
	var half := width * 0.5
	var shift := clampf(0.0, -span.x + half, span.y - half)
	return Rect2(size.x * 0.5 + shift - half, NUMBER_BAND + d - PLATE_DROP, width, height)


## Freies Rechteck um die Mitte, das kein Porträt (samt Nummer) und kein Namensschild berührt und im Bogen der Ellipse bleibt. Für jede
## Breite (von der größten abwärts) ergibt sich die höchste freie Höhe aus den Hindernissen in dieser Spalte; gewählt wird die Breite mit
## der besten Fläche bis zur bevorzugten Kartengröße (CENTER_PREFERRED), damit die Karte nicht schmal und flach wird.
static func _free_center(seats: Array[Rect2], d: float, size: Vector2, centre: Vector2, a: float, b: float, spans: Array[Vector2], heights: Array[float], min_card: Vector2 = Vector2.ZERO) -> Rect2:
	var obstacles: Array[Rect2] = []
	var reach := d * OBSTACLE_RADIUS
	for i: int in seats.size():
		var r: Rect2 = seats[i]
		var middle := r.position + Vector2(size.x * 0.5, NUMBER_BAND + d * 0.5)
		obstacles.append(Rect2(middle - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))
		obstacles.append(Rect2(r.position + Vector2(size.x * 0.5 - spans[i].x, NUMBER_BAND + d - PLATE_DROP), Vector2(spans[i].x + spans[i].y, heights[i])))
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
		if width >= min_card.x and half * 2.0 >= min_card.y:
			score += 1000000.0  # die Karte passt: das geht jeder größeren, aber schmaleren Fläche vor
		if score > best_score:
			best_score = score
			best = Rect2(centre - Vector2(width * 0.5, half), Vector2(width, half * 2.0))
		var next := width - CENTER_WIDTH_STEP
		if width > min_card.x and next < min_card.x:
			next = min_card.x  # die Kartenbreite selbst ist immer ein Kandidat
		width = next
	return best


## Punkte in gleichem Bogenabstand (in x mit `x_weight` gewichtet) auf der Ellipse, im Uhrzeigersinn; der erste liegt eine halbe Teilung links von oben.
static func _ring_points(count: int, centre: Vector2, a: float, b: float, x_weight: float = 1.0, pair_weights_in: Array[float] = [], shape: float = RING_SHAPE, pair_min: float = 0.0) -> Array[Vector2]:
	var samples := 2000
	var cum: Array[float] = [0.0]
	var prev := Vector2(0.0, -b)
	for i: int in range(1, samples + 1):
		var pt := _shape_point(-PI * 0.5 + TAU * float(i) / float(samples), a, b, shape)
		cum.append(cum[i - 1] + Vector2((pt.x - prev.x) * x_weight, pt.y - prev.y).length())
		prev = pt
	var total: float = cum[samples]
	var out: Array[Vector2] = []
	var pair_weights: Array[float] = pair_weights_in.duplicate()
	var sum_w := 0.0
	for w: float in pair_weights:
		sum_w += w
	if sum_w > total and sum_w > pair_min * float(count):
		# Der Bedarf übersteigt den Ring: der Überschuss über das Mindestmaß (Porträtringe, die sich nie berühren) schrumpft gleichmäßig.
		var keep := clampf((total - pair_min * float(count)) / (sum_w - pair_min * float(count)), 0.0, 1.0)
		sum_w = 0.0
		for k: int in count:
			pair_weights[k] = pair_min + (pair_weights[k] - pair_min) * keep
			sum_w += pair_weights[k]
	var offset: float = 0.0 if pair_weights.is_empty() else -pair_weights[count - 1] * 0.5
	for k: int in count:
		var target := total * float(k) / float(count) - total / float(count) * 0.5
		if not pair_weights.is_empty():
			target = total * offset / sum_w
			offset += pair_weights[k]
		if target < 0.0:
			target += total
		var idx := 0
		while idx < samples and cum[idx] < target:
			idx += 1
		out.append(centre + _shape_point(-PI * 0.5 + TAU * float(idx) / float(samples), a, b, shape))
	return out


static func _shape_point(t: float, a: float, b: float, shape: float) -> Vector2:
	var power := 2.0 / shape
	return Vector2(signf(cos(t)) * pow(absf(cos(t)), power) * a, signf(sin(t)) * pow(absf(sin(t)), power) * b)
