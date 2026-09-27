# Prüf-Screenshots · Rollen-Setup

Prüfartefakte, keine Produktionsassets. Erzeugt am 27.09.2026 in der Cloud-Umgebung mit Godot 4.7.2-stable unter Xvfb (Mesa llvmpipe, Compatibility-Renderer) durch `godot/tools/capture_ui_screenshots.gd`. Logische Größe = Bildgröße, reduzierte Bewegung an, fester Setup-Seed 20260926. Vorbereitet über `AppContext.setup` und echte Buttons.

| Datei | Zustand | Größe | Sprache |
|---|---|---|---|
| `01-roles-suggestion-1024x768-de.png` | Rollenwahl mit Vorschlag für 12 Personen | 1024×768 | DE |
| `02-roles-too-few-1024x768-de.png` | 8 von 12 Rollen, „Noch 4 frei“, fehlende Einzelsiegrolle, Bestätigen gesperrt | 1024×768 | DE |
| `03-roles-valid-manual-1280x800-de.png` | gültiger manuell zusammengestellter Pool, 10 Personen | 1280×800 | DE |
| `04-roles-1280x800-en.png` | Rollenwahl mit Vorschlag | 1280×800 | EN |
| `05-suggestion-overwrite-dialog-1280x800-de.png` | Rückfrage „Vorschlag übernehmen?“ über abweichender Auswahl | 1280×800 | DE |
| `06-distribution-mode-1024x768-de.png` | Verteilung vor dem Verteilen, Modus Zufällig/Manuell | 1024×768 | DE |
| `07-random-hidden-1024x768-de.png` | zufällig verteilt, Rollen verborgen („zugewiesen“), Seed sichtbar, Statusmeldung ohne Rolle | 1024×768 | DE |
| `08-secret-open-1280x800-de.png` | geöffneter Bereich „Geheim · nur für die Spielleitung“ | 1280×800 | DE |
| `09-manual-partial-1280x800-de.png` | manuell, 5 von 12 zugewiesen, Restbestand im geheimen Bereich | 1280×800 | DE |
| `10-manual-picker-1280x800-de.png` | modale Rollenauswahl mit freien Rollen, Entfernen und Tauschen | 1280×800 | DE |
| `11-manual-complete-1280x800-en.png` | vollständige manuelle Verteilung, geöffnet | 1280×800 | EN |
| `12-confirmed-ready-1280x800-de.png` | bestätigte Verteilung, Karte „Bereit für Sitzordnung“ | 1280×800 | DE |
| `13-decoy-wolf-secret-1280x800-de.png` | Trugbilderwolf mit vorläufiger Scheinrolle im geheimen Bereich | 1280×800 | DE |

Beim Ansehen der ersten Aufnahmen gefundene und behobene Mängel (Commit „fix(ui): Sichtmängel aus den Rollen-Setup-Screenshots“):
- Titel der Rollenauswahl zeigte den Platzhalter `{number}` roh → `DialogRequest.title_values`
- linke Spalte der Verteilung lief bei 1024×768 und 1280×800 über und scrollte beim Fokuswechsel aus dem Bild (Warnung angeschnitten) → Modusbuttons nebeneinander, Modus und Hinweis in einer Zeile, nur noch „Zufällig verteilen“ oder „Neu mischen“, kürzere Warnung
- Zuordnungszeilen zweizeilig, zu wenige Personen sichtbar → einzeilig mit fester Zustandsspalte
- „Verteilung bestätigen“ brach in zwei Zeilen um → ohne Umbruch
- Meldung „Spielerliste bestätigt“ bzw. „Rollen bestätigt“ aus dem vorigen Schritt verdeckte den Listenanfang in den Aufnahmen → im Werkzeug ausgeblendet; in der App verschwindet sie nach 2,5 s
- Aufnahme 13 zeigte keinen Trugbilderwolf → Liste wird zur ersten Trugbilderwolf-Zeile gescrollt

Bewusst so belassen: Die Statusmeldung einer Aktion (`07`, `12`) verdeckt 2,5 s den unteren Listenbereich. Die Fraktion steht in jeder Rollenzeile, obwohl sie auch als Gruppenüberschrift erscheint, damit sie nie nur aus der Position folgt. Die Bilder ersetzen keine Prüfung auf einem echten Tablet.

Neu erzeugen: siehe `docs/ui/role-setup.md`, Abschnitt „Tests und Screenshots“.
