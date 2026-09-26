# Prüf-Screenshots · UI-Grundlage

Prüfartefakte, keine Produktionsassets. Erzeugt am 26.09.2026 in der Cloud-Umgebung mit Godot 4.7.2-stable unter Xvfb (Mesa llvmpipe, OpenGL 4.5, Compatibility-Renderer) durch `godot/tools/capture_ui_screenshots.gd`.

| Datei | Ansicht | Logische Größe | Sprache |
|---|---|---|---|
| `01-start-1024x768-de.png` | Startbildschirm | 1024×768 | DE |
| `02-main-menu-1024x768-de.png` | Hauptmenü | 1024×768 | DE |
| `03-cockpit-1024x768-de.png` | Spielleiter-Cockpit (Platzhalter) | 1024×768 | DE |
| `04-main-menu-1280x800-en.png` | Hauptmenü | 1280×800 | EN |
| `05-settings-1280x800-de.png` | Einstellungen | 1280×800 | DE |

Jede Aufnahme zeigt die App ohne Skalierung (logische Größe = Bildgröße) mit reduzierter Bewegung, damit kein Übergang mitten im Bild steht. Der goldene Rahmen um den ersten Button ist der sichtbare Tastaturfokus. Auf den Einstellungen ist „Bewegung reduzieren“ deshalb eingeschaltet.

Neu erzeugen (aus der Repository-Wurzel):

```bash
xvfb-run -a -s "-screen 0 1920x1080x24" <godot-4.7.2> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd
```

Headless (`--headless`) gibt es keine Bildausgabe; das Werkzeug bricht dann mit Exit-Code 2 und Meldung ab. Die Bilder ersetzen keine Prüfung auf einem echten Tablet.
