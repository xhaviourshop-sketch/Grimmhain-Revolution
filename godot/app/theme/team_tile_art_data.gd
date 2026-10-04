class_name TeamTileArtData
extends RefCounted
## Gemessene Geometrie der Team-Kachelrahmen (godot/assets/ui/team_tile_*.webp). Erzeugt von tools/build_grove_ui.py, nicht von Hand ändern.
## Die Texturen werden gleichmäßig auf die Höhe der Kachel skaliert; nur die Mitte zwischen den Enden wird gedehnt.
## Je Team: Fassung (Mittelpunkt x, y und Loch-Radius als Anteil der Texturhöhe, x ab linker Kante) und Randbreiten.

const VILLAGE_SOCKET := Vector3(0.5310, 0.4729, 0.2326)  ## Mitte x, Mitte y, Lochradius
const VILLAGE_MARGINS := Vector4(126, 0, 76, 0)  ## links, oben, rechts, unten in Texturpixeln (Höhe 150); nur die Mitte wird gedehnt
const WOLVES_SOCKET := Vector3(0.5409, 0.5097, 0.2335)  ## Mitte x, Mitte y, Lochradius
const WOLVES_MARGINS := Vector4(127, 0, 76, 0)  ## links, oben, rechts, unten in Texturpixeln (Höhe 150); nur die Mitte wird gedehnt
const SOLO_SOCKET := Vector3(0.5111, 0.5481, 0.2222)  ## Mitte x, Mitte y, Lochradius
const SOLO_MARGINS := Vector4(121, 0, 72, 0)  ## links, oben, rechts, unten in Texturpixeln (Höhe 150); nur die Mitte wird gedehnt
