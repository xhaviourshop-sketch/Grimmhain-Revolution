# Prüf-Screenshots · Spieler-Setup

Prüfartefakte, keine Produktionsassets. Erzeugt am 26.09.2026 in der Cloud-Umgebung mit Godot 4.7.2-stable unter Xvfb (Mesa llvmpipe, Compatibility-Renderer) durch `godot/tools/capture_ui_screenshots.gd`. Logische Größe = Bildgröße, reduzierte Bewegung an. Vorbereitet über `AppContext.setup` und echte Buttons.

| Datei | Zustand | Größe | Sprache |
|---|---|---|---|
| `01-empty-1024x768-de.png` | Neue Partie, leer | 1024×768 | DE |
| `02-six-players-1024x768-de.png` | 6 Personen, Bestätigen frei | 1024×768 | DE |
| `03-24-players-scrolled-1024x768-de.png` | 24 Personen, ans Listenende gescrollt, Eingabe gesperrt | 1024×768 | DE |
| `04-import-open-1280x800-de.png` | Mehrfachimport geöffnet, Text eingefügt | 1280×800 | DE |
| `05-duplicates-1280x800-de.png` | Liste mit Dublettenhinweisen | 1280×800 | DE |
| `06-edit-mode-1280x800-en.png` | Bearbeitungsmodus | 1280×800 | EN |
| `07-remove-dialog-1280x800-de.png` | Entfernen-Dialog, Hintergrund abgedunkelt | 1280×800 | DE |
| `08-confirmed-1280x800-de.png` | bestätigter Namensschritt mit Statusmeldung | 1280×800 | DE |

Beim Ansehen der ersten Aufnahmen gefundene und behobene Mängel (Commit „fix(ui): Sichtmängel aus den Setup-Prüf-Screenshots“):
- Eingabefeld bei 1024×768 zu schmal, Platzhalter „Name e…“ abgeschnitten → Feld jetzt in voller Spaltenbreite über „Hinzufügen“
- Import-Aktionen brachen mitten im Wort um („Abbrech-en“) → untereinander angeordnet
- Statusmeldung lag über Statustext und Primäraktion der Fußzeile → schwebt jetzt darüber
- bei voller Liste blieb der Fokus im gesperrten Eingabefeld → Fokus auf „Spieler bestätigen“

Bewusst so belassen: Die Statusmeldung verdeckt 2,5 s lang den unteren Listenbereich (`08`); am oberen Listenrand werden Zeilen beim Scrollen angeschnitten (`03`). Die Bilder ersetzen keine Prüfung auf einem echten Tablet.

Am 27.09.2026 mit dem Setup-Wizard neu erzeugt: Die Aufnahmen zeigen jetzt zusätzlich die Schrittanzeige „Schritt 1 von 3“, `08` die Schaltfläche „Weiter zu den Rollen“ mit Fokus.

Neu erzeugen: siehe `docs/ui/player-setup.md`, Abschnitt „Tests und Screenshots“.
