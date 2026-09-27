# Prüf-Screenshots · Spielstart

Prüfartefakte, keine Produktionsassets. Erzeugt am 27.09.2026 lokal unter Windows mit Godot 4.7.2-stable (OpenGL 3.3 Compatibility, AMD Radeon RX 6700 XT) durch `godot/tools/capture_ui_screenshots.gd -- --only=game-start/`. Logische Größe = Bildgröße, reduzierte Bewegung an, fester Setup-Seed 20260926. Vorbereitet über `AppContext.setup` und echte Buttons (Signal `pressed`); „Partie starten“ läuft über `GameStart` und `GameSession` bis in den Regelkern.

| Datei | Zustand | Größe | Sprache |
|---|---|---|---|
| `01-ready-1280x800-de.png` | 12 Personen, Sitzordnung bestätigt: „Partie starten“ in der Fußzeile statt „Sitzordnung bestätigen“ | 1280×800 | DE |
| `02-ready-twentyfour-1024x768-en.png` | 24 Personen, bestätigt: Tischmitte passt zwischen die Platzreihen | 1024×768 | EN |
| `03-cockpit-started-1280x800-de.png` | nach „Partie starten“: Cockpit mit Phase „Vorbereitung“, Statusmeldung „Partie gestartet“, Hinweise auf spätere Arbeitspakete | 1280×800 | DE |
| `04-cockpit-started-1024x768-en.png` | wie 03 | 1024×768 | EN |
| `05-rejected-running-1280x800-de.png` | echter zweiter Durchlauf, während eine Partie läuft: Fußzeile „Start abgelehnt: Es läuft bereits eine Partie. Nichts wurde geändert.“ | 1280×800 | DE |

Beim Ansehen gefunden und behoben: Zuerst stand „Partie starten“ in der Karte „Sitzordnung fertig“. Bei 24 Personen und 1024×768 wurde die Tischmitte dadurch höher als ihre Fläche und lag unter der unteren Platzreihe. Der Button steht jetzt in der Fußzeile, und ein Layouttest prüft das. Außerdem zeigte das Cockpit bei aktiver Partie noch „Aktionen erscheinen, sobald eine Partie läuft“. Es gibt jetzt eigene Texte für die aktive Partie.

Bewusst so belassen: Die kurze Statusmeldung liegt als Einblendung über dem Cockpit (in 04 über der Überschrift „Actions“) und verschwindet nach kurzer Zeit. So verhält sich die bestehende Einblendung auch überall sonst.

Die Bilder ersetzen keine Prüfung auf einem echten Tablet. Touchbedienung ist nicht geprüft.
