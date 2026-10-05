---
name: grimmhain-screens
description: Use to produce the standard Grimmhain screenshot set at 1024x768 (night cards for Loki, Spürhund, Werwolf, Lehrling, Die Gebundenen, Blutpriester, Waldhexe, Zuflucht).
---

# Standard-Screenshotsatz 1024x768
Werkzeug: `godot/tools/capture_standard_set.gd`. Headless gibt es kein Bild, ein Renderer ist nötig (Windows: opengl3).

```
"<GODOT_CONSOLE_EXE>" --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1024x768 -s res://tools/capture_standard_set.gd -- --out=C:/Users/Marku/Downloads/<Ordner>
```
- Ausgabe: `<szene>-1024x768.png` je Szene; Zeilen `bild ...` im Log, `FAIL <szene>` wenn die Karte nicht erreicht wurde.
- Neue Szene: Eintrag in `SCENES` ([Dateiname, Rolle, Stufe]).
- Vor dem Bild wartet das Werkzeug 4 s, damit die Rückgängig-Leiste des Vorschritts weg ist.
- Bilder ansehen (Read), nicht nur Existenz prüfen: Text abgeschnitten, Überdeckung, Karte lesbar. Ausgabe nach Downloads, im Bericht verlinken.
