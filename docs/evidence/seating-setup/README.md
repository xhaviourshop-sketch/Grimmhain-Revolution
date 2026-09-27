# Prüf-Screenshots · Sitzordnung

Prüfartefakte, keine Produktionsassets. Erzeugt am 27.09.2026 lokal unter Windows mit Godot 4.7.2-stable (OpenGL 3.3 Compatibility, AMD Radeon RX 6700 XT) durch `godot/tools/capture_ui_screenshots.gd -- --only=seating`. Logische Größe = Bildgröße, reduzierte Bewegung an, fester Setup-Seed 20260926. Vorbereitet über `AppContext.setup` und echte Buttons; `06` zieht mit echten Mausereignissen über den Viewport, ohne loszulassen.

| Datei | Zustand | Größe | Sprache |
|---|---|---|---|
| `01-six-1024x768-de.png` | 6 Personen: je zwei Plätze oben und unten, einer je Seite | 1024×768 | DE |
| `02-twentyfour-1024x768-de.png` | 24 Personen: je sieben Plätze oben und unten, fünf je Seite | 1024×768 | DE |
| `03-twelve-1280x800-en.png` | 12 Personen | 1280×800 | EN |
| `04-twentyfour-1920x1080-de.png` | 24 Personen: je neun Plätze oben und unten, drei je Seite | 1920×1080 | DE |
| `05-selected-1280x800-de.png` | Platz 3 zum Tauschen ausgewählt, Hinweis und „Auswahl aufheben“ in der Tischmitte | 1280×800 | DE |
| `06-dragging-1280x800-de.png` | Ziehen von Platz 1 auf Platz 7: Quelle abgeblendet, Vorschau am Zeiger, Ziel hervorgehoben | 1280×800 | DE |
| `07-swapped-1280x800-de.png` | Ben und Hanna haben die Plätze getauscht, Rückmeldung in der Fußzeile | 1280×800 | DE |
| `08-confirmed-1280x800-de.png` | Karte „Sitzordnung fertig“, in der Fußzeile „Partie starten“ statt „Sitzordnung bestätigen“ (am 27.09.2026 mit dem Spielstart neu erzeugt) | 1280×800 | DE |
| `09-long-names-1024x768-en.png` | 24 Namen mit 32 Zeichen: Namen mit Auslassungszeichen gekürzt | 1024×768 | EN |

Beim Ansehen gefunden und behoben: Bei 24 Personen und 1024×768 wurde „17 · Quentin“ gekürzt; Platzsymbole haben jetzt einen schmaleren Innenrand (`SeatButton`). Die erste Aufnahme von `06` zeigte kein Ziehen, weil dem Werkzeug `global_position` und `relative` der Mausereignisse fehlten.

Bewusst so belassen: Sehr lange Namen (32 Zeichen) werden bei vielen Plätzen gekürzt; den vollständigen Namen zeigt die Auswahl in der Tischmitte. Die Rollen erscheinen in dieser Ansicht nie. Die Bilder ersetzen keine Prüfung auf einem echten Tablet; Touchbedienung ist nicht geprüft.

Neu erzeugen: siehe `docs/ui/seating-setup.md`, Abschnitt „Tests und Screenshots“.
