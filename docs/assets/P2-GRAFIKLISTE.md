# P2: Grafikliste für ein spielbares Nachtbrett

**Stand:** 2026-10-01 · **Status:** nur Planung, nichts erzeugt und nichts repariert · Grundlage: Mockup V2 (`p1-mockup/`) und `ORIGIN-NOTES-NIGHT-BOARD.md`

Alle Dateien sind Entwicklungsmaterial ohne Veröffentlichungsfreigabe. „Claude Code“ heißt: aus dem Bestand ableitbar (Zuschnitt, Maske, Säuberung per Skript), kein neues Bild. „ChatGPT“: Markus erzeugt es, Briefings in `Downloads/Grimmhain-P1-Nachtentwurf/P2-BRIEFINGS-FUER-CHATGPT.md`.

| Grafik | Befund | Weg | Anmerkung |
|---|---|---|---|
| Protokoll-Lasche, textfrei | `panel-protocol-tab.png` (Buch-Symbol, kein Text) ist vorhanden | Claude Code (nur zuschneiden und prüfen) | `protocol-tab-de/en.png` tragen eingebackenen Text und entfallen |
| Optionen-Lasche, textfrei | `options-tab.png` trägt „OPTION“ im Bild, kein Zahnrad-Bild als Datei | Claude Code | Basis aus `panel-protocol-tab.png`, Buch entfernen, Zahnrad als eigenes Symbol (aus Full UI Abschnitt 10 oder gezeichnet). Fällt das Ergebnis zu grob aus: ChatGPT-Nachbestellung |
| Nachtreihenfolge-Slots (aktiv, erledigt, offen) | weiße Nummernsockel, weiße Säume, vereinzelte Pixelpunkte | Claude Code | Maske und Entsäumen, Sockel dunkel. Der rote Leuchtrand des aktiven Slots ist heikel, bei unsauberem Ergebnis ChatGPT |
| Rollenbilder ohne Karten-Eckmarken (Übergang) | `night-icon-*.webp` sind Kartenausschnitte mit Zahl, Fraktionsmarke und Zierleiste | Claude Code | mittlerer Ausschnitt mit Kreismaske für alle 72, Übergangslösung bis zum Emblemsatz |
| Rollensymbole (Emblemsatz, Stil der Full-UI-Medaillons) | als Dateien nur die fünf Beispiele in `Full UI.png` (Raster), kein Satz für 72 Rollen | ChatGPT | P2 klärt mit einem 12er-Probeblatt (P2-4) den Stil, die restlichen Rollen folgen in P5 |
| Statusabzeichen (Schutz, Gift, Markiert, Stumm, Tot, Sonder) | nur im Raster `Spielfeld.png`, keine Dateien. Unter 56 px Porträtgröße unterscheiden sich die Ringe nur noch durch Farbe | ChatGPT | Blatt P2-3 |
| Porträtblätter C und D | 10 verwendbare Gesichter (A, B), 24 nötig | ChatGPT | je 8 Gesichter (4 × 2) mit G2A als Stilvorlage, ergibt 26 |
| Rollenkartenrahmen `action-frame-night.png` | undurchsichtiger schwarzer Block im unteren Rahmenteil | Claude Code | transparent machen oder ausschneiden |
| Nachthintergrund G1 | 1536 × 1024, für ein Retina-iPad zu klein | später (P9) | Hochskalierung mit externem Werkzeug, noch nicht beauftragt, nichts bestellt |
| Rollenbild Karte A für alle 72 Rollen | `portraits-512` sind laut `PILOT-STATUS.md` vorläufig | später (P5) | für den Nachtprototyp reichen die vorhandenen |
| Panels Protokoll und Optionen (offen) | `protocol-panel.png`, `panel-options-open.png` vorhanden, textfrei | keine Aufgabe | Inhalt zeichnet Godot |
| Statusringe, Platzrahmen, Buttons, Ziel-Slot | vorhanden und im Mockup bewährt | keine Aufgabe | kleinste brauchbare Größe 56 px |
| Tagphase-Fenster (oval, „Lynchen“) | nur im Raster `Full UI.png` | später (P4) | Tag gehört nicht zu P2 |
