# P2: Grafikliste für ein spielbares Nachtbrett

**Stand:** 2026-10-01 · **Status:** P2 ausgeführt (Ergebnis in `p2-mockup/`, Mockup V3), offen siehe Abschnitt „Für P3 noch offen“ · Grundlage: Mockup V2 (`p1-mockup/`) und `ORIGIN-NOTES-NIGHT-BOARD.md`

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

## Ausführung P2 (2026-10-01)

| Grafik | Ergebnis |
|---|---|
| Protokoll-Lasche, Optionen-Lasche | erledigt: `parts/tab-protocol.png`, `parts/tab-options.png`, beide textfrei (Zahnrad selbst gezeichnet) |
| Nachtreihenfolge-Slots | erledigt: Speckles, weißer Saum und Nummernsockel bereinigt. Der rote Rand des aktiven Slots hat noch einen leichten rosa Hauch |
| Rollenbilder per Kreismaske | erledigt für alle 72: `night-icons-circle/` |
| Rollenkartenrahmen | erledigt: Platte transparent, Rand bleibt |
| Porträts | 24 eindeutige Gesichter (26 Kandidaten, 2 aussortiert: D6 gegen A5, D5 gegen C7 und A4) |
| Statusabzeichen | freigestellt, 6 Stück |
| Rollensymbole | 11 von 12 freigestellt, Wolfskind-Symbol verworfen |

Grenzwertig ähnliche Gesichter, die bleiben: B2 und C6 (lockiges Haar mit Stirnband), C4 und D4 (Schnurrbart), D3 und D8 (graues Haar, Knoten), A2 und D2 (Mütze, Männer), A6 und D7 (alter Mann, weißes Haar). Wer sie im Test nicht mehr unterscheidet, tauscht jeweils eines gegen ein neues Blatt-E-Gesicht.

## Für P3 noch offen

| Punkt | Was fehlt | Anmerkung |
|---|---|---|
| Rollensymbole | 61 weitere Symbole (72 minus 11 verwendbare) einschließlich Wolfskind neu | Stil entschieden. Schätzung unten |
| Statusabzeichen | Zuordnung weiterer Zustände (Verliebt, Verhext, Nominiert usw.) zu Abzeichen oder `marker-*.webp` | Sechs Abzeichen decken nur die Kernzustände. Lesbarkeit bei 24 px, vor allem Stumm, auf dem Tablet prüfen |
| Porträts | ein Reservesatz nur, falls ähnliche Paare im Test stören | 24 reichen für den 24er-Ring genau, ohne Reserve |
| Tablet-Prüfung | echte Größe, Kontrast und Touch auf dem Gerät | Screenshots am Fenster ersetzen das nicht |
| Nachthintergrund | 1536 × 1024 zu klein für ein Retina-iPad | später (P9), nichts beauftragt |
| Rollenbild Karte A, Tagphase-Fenster | unverändert | P5 bzw. P4 |
| Freigabe und Herkunft | Status aller Bilder bleibt `ungeklärt` | Product Owner |
| Layout | „Rückgängig“ überlappt bei 1024 × 768 knapp den Platz 11 | Aufgabe in P3 |

### Schätzung Rollensymbol-Blätter (je 12)

72 Rollen minus 11 vorhandene Symbole = 61 Symbole, also mindestens **6 Blätter** (72 Plätze, 11 Reserve). Bei angenommenem Ausschuss von etwa jedem sechsten Symbol (im Probeblatt war es 1 von 12) sind **7 bis 8 Blätter** realistisch, dazu Folgeprompts je Blatt. Voraussetzung: Die elf verwendbaren Motive sind den richtigen Rollen zugeordnet. Sieben sind es durch die Namen der Nachtreihenfolge (Gebundene, Schutzengel, Werwolf, Rachsüchtiger Wolf, König Lykaon, Waldhexe, Rattenfänger). Die Motive 9 bis 12 (Kristallauge, Kreuz mit Fläschchen, Schild mit Speer, Totenkopf mit Stab) sind Vorschläge und noch keiner Rolle zugeordnet.
