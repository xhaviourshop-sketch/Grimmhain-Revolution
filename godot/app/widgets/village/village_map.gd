class_name VillageMap
extends RefCounted
## Bildkoordinaten des Dorfbilds (1672 x 941, `assets/village/village-night.webp`) auf die Hintergrundebene abbilden. Das Bild füllt die Fläche
## wie der TextureRect mit „Seitenverhältnis halten, abdecken“ (zentriert, Überstand abgeschnitten). Alle Positionen der Dorf-Ebenen sind in
## Bildpixeln angegeben und werden hier umgerechnet, damit sie bei jeder Bildschirmgröße auf denselben Häusern liegen.

const IMAGE_SIZE := Vector2(1672.0, 941.0)

var area := Vector2(1024.0, 768.0)  ## Größe der Dorf-Ebene (lokal)
var _blocked: Array[Rect2] = []     ## Sitzplätze (Porträt und Name) in lokalen Koordinaten, dazu ein Rand


## Bildmaßstab: lokale Einheiten je Bildpixel.
func scale() -> float:
	return maxf(area.x / IMAGE_SIZE.x, area.y / IMAGE_SIZE.y)


## Bildpixel nach lokal.
func to_local(image_px: Vector2) -> Vector2:
	var s := scale()
	return (area - IMAGE_SIZE * s) * 0.5 + image_px * s


## Ist der Bildpunkt auf der Fläche sichtbar (nicht im abgeschnittenen Überstand)?
func visible_px(image_px: Vector2, margin: float = 0.0) -> bool:
	var p := to_local(image_px)
	return p.x >= -margin and p.y >= -margin and p.x <= area.x + margin and p.y <= area.y + margin


## Sitzplätze, die nichts überdecken darf (lokal). Das Cockpit meldet sie nach jedem Layout.
func set_blocked(rects: Array[Rect2]) -> void:
	_blocked = rects


## Ragt das Rechteck (lokal) in einen Sitzplatz?
func hits_seat(rect: Rect2) -> bool:
	for r: Rect2 in _blocked:
		if r.intersects(rect):
			return true
	return false
