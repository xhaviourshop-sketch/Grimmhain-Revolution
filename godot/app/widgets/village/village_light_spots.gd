class_name VillageLightSpots
extends RefCounted
## Laternen und helle Fenster im Nachtbild (`assets/village/village-night.webp`, 1672 x 941), in Bildpixeln.
## Gefunden mit `tools/find_village_lights.py` (helle orange Flecken), von Hand in Laternen und Fenster sortiert und gegen ein Overlay geprüft.

## Laternen: [x, y] der Flamme. Der Schein liegt flach auf dem Pflaster darunter.
const LANTERNS: Array[Vector2] = [
	Vector2(534, 70), Vector2(996, 32), Vector2(1137, 68), Vector2(1286, 152), Vector2(1434, 262),
	Vector2(1606, 495), Vector2(248, 712), Vector2(329, 196), Vector2(92, 390),
]

## Fenster: Mitte (x, y) und Größe (Breite, Höhe) des gemalten hellen Fensters.
const WINDOWS: Array[Rect2] = [
	Rect2(218, 25, 12, 16), Rect2(512, 9, 10, 12), Rect2(420, 50, 14, 16), Rect2(447, 39, 12, 14), Rect2(315, 114, 16, 18),
	Rect2(226, 136, 12, 14), Rect2(181, 95, 12, 14), Rect2(52, 212, 14, 16), Rect2(654, 34, 12, 14), Rect2(685, 26, 10, 12),
	Rect2(197, 240, 16, 20), Rect2(116, 368, 14, 18), Rect2(10, 380, 14, 16), Rect2(936, 10, 10, 12), Rect2(1312, 16, 10, 12),
	Rect2(1191, 55, 12, 14), Rect2(1328, 125, 12, 14), Rect2(1379, 170, 8, 10), Rect2(1524, 172, 14, 30), Rect2(1557, 175, 14, 30),
	Rect2(1543, 295, 8, 12), Rect2(1542, 375, 8, 12), Rect2(1633, 432, 14, 16), Rect2(44, 823, 14, 16), Rect2(277, 917, 14, 18),
	Rect2(40, 920, 10, 12), Rect2(1627, 666, 14, 16), Rect2(1536, 901, 14, 18), Rect2(1371, 911, 12, 16), Rect2(1417, 804, 10, 12),
]
