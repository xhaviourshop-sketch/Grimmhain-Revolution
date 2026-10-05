# Marke Grimmhain (Kurzfassung)

Verbindlich ist das Marken-Blatt (Stand 04.10.2026, Markus): `C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/marke/marken-blatt.md`. Diese Datei ist die Kurzfassung im Repo; bei Abweichung gilt das Blatt. Bildvorlage: `marke/design-tafel.png` (bei jedem neuen Asset anhängen). Alle Texte und Assets folgen dieser Datei.

## Produkt und Gefühl
Eigenes gedrucktes Kartenspiel plus Spielleiter-App; die Marke muss auf iPad, App-Symbol, Kartenrückseite und Verpackung funktionieren. Gefühl: unheimlich und edel, wie ein altes, verfluchtes Buch. Dunkel, hochwertig, ruhig bedrohlich. Nicht laut, nicht comichaft, kein Action-Kitsch.

## Zeichen
- **Bildzeichen (Siegel):** Wolfskopf in rundem Kranz aus Wurzeln und Dornen, Mondsilber auf Nachtschwarz. `godot/assets/brand/siegel.webp`. Unter 144 px gilt die vereinfachte Klein-Fassung (`godot/assets/app/app-symbol-*.png`).
- **Wortmarke:** Fassung der Design-Tafel. `godot/assets/brand/wortmarke.webp`.
- **Kombination:** Siegel über Wortmarke (Ladebild, Kartenrückseite); Siegel allein (App-Symbol, kleine Stellen).
- **Kein Slogan festgelegt.** "The Night Begins" auf der Tafel ist nur Platzhalter und steht nirgends in der App.

## Farben (verbindliche Werte: ThemeTokens, `godot/app/theme/theme_tokens.gd`)
- Grund: Nachtblau bis Schwarz (`BG_APP`, `NIGHT_BACKDROP`, `BOARD_NIGHT`).
- Hauptakzent: Mondsilber (`MOON_SILVER`).
- Blutrot (`BLOOD_RED`): nur für Aktives (gewählt, Start, Gefahr), nie als Flächenfarbe.
- Teams: Dorf Mondblau, Wölfe Blutrot, Einzelgänger Violett (`TEAM_PLATE_*`, `GLOW_*`).
- Einziger warmer Ton: Fenster- und Laternenlicht in Bildern.
- **Kein Gold. Nirgends.** Ausnahme (DA-101): Flaggen dürfen ihre echten Farben haben; das Gelb der deutschen Sprachflagge bleibt.

## Material
Geschmiedetes schwarzes Eisen, Wurzeln, Dornen, Mondsilber. Lava und Glut nur bei Start- und Feuer-Momenten. Ornamente nur an Ecken und Enden, damit Rahmen dehnbar bleiben.

## Schrift
- Logo und große Titel: gotisch-geschmiedet, hohe spitze Buchstaben (wie die Wortmarke). Titelschrift in der App: Grenze Gotisch (SIL OFL 1.1, intern freigegeben), nur für `GothicTitleLabel`.
- Alles andere: schlichte, gut lesbare Schrift. Nie gotisch in Fließtext oder Knöpfen.

## Bildstil
Wie der Startbildschirm: detailreich gemalt, nachtblau, Mondlicht, warme Fensterlichter als einziger warmer Ton. Gilt für Szenen, Porträts und gemalte Rollenbilder. Kleine Symbole bleiben Silber-Prägung.

## Sprache (Spielleiter-App): kurz und klar
Einfache Worte, keine Floskeln, kein Amtsdeutsch. Atmosphäre nur in Überschriften und Ansagen, nie in Bedientexten.
- Nachtkarte (DA-101): Mini-Karte mit Rollensymbol, Name, 1 bis 3 Wörtern Aktion; Warnungen höchstens 6 Wörter, ohne Kommas und Fachwörter, immer mit Namen. Kein Vorlesesatz (zuschaltbar), keine Regelzeilen, siehe `docs/audit/NACHTSCHRITTE-PRINZIPIEN.md`.
- Keine Statuswörter für Programmierer ("Tu jetzt", "Handelnd 15").
- Schlecht: "Wähle 0 bis 2 Personen. Auswahl leeren. Niemand/Verzichten."
- Gut: "Loki bindet 2 Spieler. Erst Liebende oder Rivalen wählen, dann 2 Spieler antippen."

## Regeln für jedes neue Asset
ChatGPT-Projekt "Grimmhain Assets", Design-Tafel als Vorlage anhängen, echte Transparenz, kein Text im Bild, kein Gold, Ornamente nur an den Enden.
