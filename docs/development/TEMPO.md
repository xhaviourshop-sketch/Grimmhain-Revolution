# Tempo: Messung vorher/nachher (05.10.2026)

Rechner: Windows 10, 12 logische Kerne, Godot 4.7.2 Console-Build. Stand: main `68f7abb` plus Branch `feat/team-tempo`. Je Wert ein Lauf (keine Mittelwerte), Wanduhrzeit inkl. Import und Godot-Start.

| Schritt | Vorher | Nachher | Was sich änderte |
|---|---|---|---|
| Vollsuite mit Fuzz (1423 Tests) | 558 s (`test-quiet`, 1 Prozess) | 174 s (`test-full --merge`, 6 Prozesse) | Dateien nach Dauer auf 6 Prozesse verteilt; Untergrenze ist der Fuzz-Test allein (175 s unter Last) |
| Vollsuite ohne Fuzz (1420 Tests) | nicht vorhanden (nur mit Fuzz) | 116 s (`test-full`) | Fuzz nur noch vor dem Merge |
| Gezielte Tests, 4 Filter (Cockpit-Ordner, 103 Tests) | 81 s (4 × `test-quiet`, je Import + Start) | 33 s (ein Import, 6 Prozesse) | `test-changed` nutzt `test-full` |
| Rot: nur rote Dateien wiederholen | ganze Suite erneut (558 s) | 9 s für eine Datei (`test-full --failed`) | danach einmal komplett |
| Godot-Start (headless, `--quit`) | 2,8 s | 2,8 s | unverändert |
| Import ohne Änderungen | 7,3 s je Testaufruf | 7,3 s einmal je Lauf | vorher bei jedem Filter erneut |
| Web-Export (`export-web.js`) | 6,3 s | 6,3 s | unverändert, kein Gewinn möglich (Godot packt 39 MB in 6 s) |
| Screenshots Feedback-6 + -7 (24 Bilder) | 35 s (2 Befehle) | 35 s (`capture-all`, 1 Befehl) | parallel zu Tests: Bilder 41 s, Tests 122 s statt 116 + 35 s |
| Deploy (Vercel) | nicht gemessen | nicht gemessen | kein Deploy beauftragt; Vercel-Liste nennt keine Dauer |

## Gemessene Fallen

- **Zwei Godot-Fenster gleichzeitig** bremsen sich unter Windows gegenseitig aus: zwei Screenshot-Werkzeuge parallel 290 s statt 35 s nacheinander. `capture-all` läuft deshalb nacheinander; parallel nur neben den fensterlosen Tests.
- **Mehr Prozesse ist nicht schneller:** 9 Prozesse 194 s, 6 Prozesse 174 s (Speicher und Kerne werden geteilt, der Fuzz-Test wird langsamer).
- **Erster Lauf ohne Zeitdatei** verteilt nach Schätzwert: 280 s. Die Dauer je Datei liegt danach in `%TEMP%/grimmhain-test-full/times.json`.
- **Neuer Worktree** (Agent `godot-entwickler`) hat keinen `.godot`-Cache: der erste Import dort dauert länger als 7 s.

## Was die Werkzeuge tun

- `node tools/test-full`: ein Import, dann alle Testdateien (ohne Fuzz) auf CPU-Kerne/2 Prozesse verteilt, längste Dateien zuerst nach den Zeiten des Vorlaufs. Jeder Prozess hat ein eigenes `APPDATA`, damit `user://` (Spielstände, Einstellungen, Verlauf) nicht kollidiert. `--merge` mit Fuzz, `--failed` nur die roten Dateien des Vorlaufs, `--jobs=<n>`.
- `godot/tests/run_tests.gd`: neue Option `--files=<a.gd>,<b.gd>` und eine Zeile `time <datei> <ms>` je Datei.
- `node tools/test-changed`: wie bisher die Zuordnung über `tools/test-map.json`, aber ein Lauf über `test-full` statt eines Godot-Starts je Filter.
- `node tools/capture-all <ordner> capture_a capture_b`: mehrere Screenshot-Werkzeuge mit einem Befehl, nacheinander, mit eigenem `APPDATA`.
- "Nur neu bauen, was sich änderte": der Godot-Import ist schon inkrementell (7 s ohne Änderung), der Export dauert 6 s. Ein Überspringen des Exports würde die Build-Kennung (Commit-Hash) veralten lassen und lohnt nicht.

## Schätzung für einen Auftrag wie Feedback-6/7

Reine Wartezeit auf Werkzeuge (Messwerte oben, Ablauf wie in PROGRESS.md beschrieben: gezielte Tests mehrfach, Vollsuite rot, Fix, Vollsuite erneut, Screenshots, Export):

| | Vorher | Nachher |
|---|---|---|
| gezielte Tests, ca. 5 Läufe mit je 4 bis 16 Filtern | ca. 12 min | ca. 3 min |
| Vollsuite rot, Fix, erneut | 2 × 558 s = 19 min | 174 s + 9 s + 174 s = 6 min |
| Screenshots + Export | 1 min | 1 min (Bilder neben den Tests) |
| **Summe Wartezeit** | **ca. 32 min** | **ca. 10 min** |

Dazu kommt die Umsetzung selbst. Mit zwei parallelen Entwicklern (Feedback-6 und -7 berühren verschiedene Dateien) und Prüfern, die gleichzeitig laufen (Erstlauf: 2 bis 3 min), schätze ich einen Auftrag dieser Größe auf **ca. 60 statt ca. 100 Minuten**. Die Umsetzungszeit ist geschätzt, nicht gemessen.

## Paketgröße (Feedback 9, Teil P, 06.10.2026)

Web-Export `index.pck` (nur Export in einen Temp-Ordner, kein Deploy), gleicher Stand f5588c8:

| Posten | Vorher | Nachher |
|---|---|---|
| `index.pck` gesamt | 55 807 276 Byte | 40 807 244 Byte (Ziel unter 42 MB erreicht) |
| Rollenbilder `night/role-art` (72 Bilder, 512x512) im Import | 17 642 354 Byte (verlustfrei) | 2 642 240 Byte (verlustarm, Qualität 0,8) |
| Rollenkarten `cards/de` + `cards/en` (144 Bilder) | 12 779 742 Byte | unverändert |
| Wappen `night/emblems` (72 PNG) | 4 391 596 Byte | unverändert |
| `.godot/imported` gesamt | 55 170 571 Byte | ca. 40 170 457 Byte |

Größte Einzelposten in `.godot/imported` vorher: musik-start 2,88 MB, scene-night-base 2,17 MB, village-night 2,02 MB, start-hintergrund 1,49 MB, ladebild 1,08 MB, wortmarke 0,81 MB, start-nebel 0,71 MB, start-logo 0,63 MB, epic_button_mid 0,33 MB, splash-grimmhain 0,32 MB. Die Liste bleibt nach der Änderung gleich; die 72 Rollenbilder waren einzeln nie unter den Größten, zusammen aber der größte Block.

Entscheidungen:
- **Rollenbilder:** Sie sind nicht sichtbar (`ROLE_ART_ON_CARD := false`), lagen aber verlustfrei im Paket. Nur die `.import`-Dateien wurden auf verlustarm (Modus 1, Qualität 0,8) gestellt, die Quellbilder bleiben unverändert. Das allein bringt 15,0 MB.
- **Rollenkarten bleiben bei 1024 Pixel Höhe.** Die Vollbildkarte ist in App-Einheiten rund 735 hoch (768 minus Rand). Der Stretch-Modus ist `canvas_items`, die Zeichenfläche im Web hat Gerätepixel: auf einem iPad mit 1536 Pixel Höhe sind das etwa 1470 Pixel. 1024 liegt also schon unter der Anzeige; ein Verkleinern auf 768 würde sichtbar weicher. Da das Ziel ohne die Karten erreicht ist, bleiben sie unverändert (Bilder 1024x768 in `Screenshots/Feedback-9/P`).
- **Wappen bleiben verlustfrei:** Die scharfen Silberkanten bekämen bei verlustarmer Kompression Ränder. Das Ziel ist ohne sie erreicht, der Gewinn (ca. 3 MB) rechtfertigt das Risiko nicht.
- **Karten erst laden, wenn gebraucht:** Karten werden nur per `load()` in `role_card_image.gd` geladen (beim Öffnen der Karte), nirgends per `preload` oder beim Start. Das `.pck` wird im Web aber immer ganz heruntergeladen; ein zweites Paket zum Nachladen wurde nicht gebaut und bringt erst bei deutlich mehr Inhalt etwas.
