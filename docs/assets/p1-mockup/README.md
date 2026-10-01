# P1-Mockup (Wiederverwendung für P3)

**Keine Laufzeitassets, nicht in `godot/`.** Wegwerf-Skripte und zugeschnittene Bilder aus Auftrag 1 (P0 + P1), damit P3 nicht von vorn beginnt. Alle Bilder sind Entwicklungsmaterial ohne Veröffentlichungsfreigabe (Herkunft: `../ORIGIN-NOTES-NIGHT-BOARD.md`).

| Datei | Zweck |
|---|---|
| `mockup2.gd` | Mockup V2 nach `Spielfeld.png`: Leiste, Platzrahmen, Laschen, Uhr, Buttons, Karte A und B, Größentest. Maße und Positionen sind die Grundlage für das Layout in P3. |
| `mockup.gd` | frühere Platzvarianten V1 bis V1c (Einring, versetzter Ring, zwei Ringe) |
| `p0_capture.gd`, `p0_roles.gd` | Ist-Aufnahmen (24er-Cockpit, Zielwahl, Rollenschritt) mit der Capture-Technik aus `godot/tools/capture_ui_screenshots.gd` |
| `echt/face00..09.png` | 10 zugeschnittene Gesichter aus G2A (6) und G2B (4), 256 px |
| `echt/frame.png` | G3-Kartenrahmen, Magenta freigestellt, 25 % verkleinert (9-Slice, 46 px Ecken) |
| `echt2/slot-*.png` | Nachtreihenfolge-Slots mit dunkel ersetzten Nummernsockeln (weiße Säume bleiben, siehe P2-Liste) |
| `echt2/crop-*.png` | auf den sichtbaren Inhalt zugeschnittene Laschen, Buttons und Rollenkartenrahmen |

## Ausführen

Aus dem Worktree (Windows, sichtbares Fenster nötig):

```text
godot --path godot --rendering-driver opengl3 --audio-driver Dummy -s ../docs/assets/p1-mockup/mockup2.gd -- [--only=V2-A] [--sizes=1024x768]
```

Ausgabe nach `OUT` (Konstante im Skript). **Maschinenabhängig:** `WK` (Ordner „Grimmhain Assets“), `BG_G1` und `OUT` zeigen auf Pfade dieses Rechners (`C:/Users/Marku/...`) und müssen angepasst werden. `SP` zeigt auf diesen Ordner. Das Skript nutzt `ThemeFactory` und läuft nur im Projekt `godot/`.
