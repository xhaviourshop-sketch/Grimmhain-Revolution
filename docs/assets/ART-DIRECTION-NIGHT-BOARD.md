# Art Direction: Nachtbrett (Ergänzung zu BRIEFING-WAVE-1)

**Stand:** 2026-10-01 · **Status:** Entwurf zur Abnahme 1 (Roadmap P1), keine Freigabe von Medien · **Ergänzt:** [`BRIEFING-WAVE-1.md`](BRIEFING-WAVE-1.md) (Palette §3.1, Licht §3.2 gelten weiter) · **Roadmap:** `docs/masterplan/entwurf-visuell/GRIMMHAIN-VISUELLE-ROADMAP.md`

Die vier Zielbilder in `docs/masterplan/entwurf-visuell/referenzen/` geben nur die Richtung vor. Maßgeblich ist Bild 3 (Nacht), mit deutlich weniger Detail.

## 1. Komposition

- **Kamera:** feste Aufsicht, etwa 45 Grad, symmetrisch. Tag und Nacht später aus derselben Kamera (Gebäude dürfen beim Überblenden nicht springen).
- **Zonen (Anteil an der Bildfläche):**
  - Mitte, etwa 55 %: ruhiges, dunkles, nasses Kopfsteinpflaster. Keine Statue, kein Brunnen, keine Figuren, kaum Kontrast. Hier liegt die Aktionskarte.
  - Sitzband (Ellipse, in der die 24 Porträts liegen): ebenfalls ruhig. Kein Detail, das mit Namensschildern konkurriert.
  - Außenrand, etwa 15 %: Häuser, Kirchturm, Mond, wenige warme Fenster und sechs bis acht Laternen. Hier darf das Detail sein.
  - Oberer Streifen: dunkel und ruhig für die Statusleiste.
- **Formate:** Master 16:10. Wichtiges bleibt im mittleren 4:3-Ausschnitt, die äußeren 12 % links und rechts sind beschneidbar.
- **Ebenen:** Hintergrund, optional Vordergrund und Nebel als eigene Dateien (P2/P6). Keine Beschriftung im Bild.

## 2. Brett und Bedienelemente

| Element | Festlegung |
|---|---|
| Aktionskarte | kompakt: Titel, eine Anweisungszeile, Hauptbutton und „Mehr“ für die Detailansicht. Etwa 300 × 150 logische Pixel im Mockup (rund 6 % der Brettfläche bei 1024 × 768), halbtransparent mit Goldrand. Ausführlicher Text und Vorlesetext öffnen als bewusste Detailansicht. |
| Statusleiste | oben, eine Zeile (Phase, Schritt, Lebende). |
| Seitenleisten (Mockup V1c) | Links Protokoll, Rollen, Spielleitung, Verbergen; rechts Optionen, Ton, Hilfe (Lexikon, Regelbuch). 52 px breit (48 px Bedienfläche), nicht vollhoch, enden über den äußersten Plätzen, damit der 24er-Ring bei 1024 × 768 unverändert bleibt. Unten links Phasenanzeige mit Timer-Platz (Entscheidung in `DECISIONS.md`) und „Legende“. Icons sind Platzhalter. |
| Porträtplatz | Kreis, 60 px, Goldring. Nummer als kleines Badge oben links am Porträt, Name auf einem Schild darunter. |
| Zustände | normal: dunkler Goldring. Wählbar: heller Goldring. Gewählt: heller Ring mit Leuchten. Handelnd: Mondblau mit Leuchten. Tot: entsättigtes Porträt, grauer Ring, durchgestrichen. Information hängt zusätzlich an Form oder Text, nie nur an der Farbe. |
| Touch | Porträt 60 px plus Schild bilden eine Fläche, Mindestkante 48 px (`ThemeTokens.TOUCH_MIN`). Auf dem Gerät zu prüfen, nicht aus dem Fenster abzuleiten. |

## 3. Schrift

Dekorative Schrift (Cinzel, OFL belegt, Lizenzdatei fehlt) nur für kurze Überschriften wie den Rollennamen auf der Karte. Namen, Regeln und Anweisungen in der klaren Leseschrift (Engine-Standard, bis die Schriftentscheidung fällt). Vor Übernahme prüfen, dass ä, ö, ü, ß und „…“ sauber dargestellt werden.

## 4. Porträts

- Neutrale öffentliche Porträts, **keine** Rollenhinweise (keine Waffen, Reißzähne, Leuchtaugen, Felle, Kronen, Kreuze, Tränke, verdeckte Gesichter).
- Ein Licht in allen Bildern: warmes Hauptlicht von vorn links, kühles Randlicht von rechts, Hintergrund einfarbig `#14161d`.
- Jede Figur hat eine eigene Silhouette (Haar, Hut, Tuch) und eine eigene gedämpfte Kleidungsfarbe, damit 24 Plätze bei 60 px unterscheidbar bleiben.
- Erzeugung als Blatt mit sechs Köpfen je Lauf, danach Zuschnitt. Einzelgenerierungen driften im Stil. Der Kreisausschnitt liegt im mittleren 70 % der Zelle.
- Neutrales Porträt, privates Rollenbild und erlaubte öffentliche Aufdeckung bleiben getrennte Dateien.

## 4a. Rahmen und Effekte

- Porträtring in Godot gezeichnet (keine Bilddatei in P1).
- Aktionskartenrahmen als 9-Slice: Zierde nur in den Ecken, gerade Kanten schlicht und dünn, Innenfläche einfarbig.
- Nebel, Feuerflackern, Funken erst in P6. Wolfsangriff: einfache Variante zuerst (Aufleuchten, Porträtriss, Krallenspuren nur bei öffentlich erlaubter Ursache), aufwendige Wölfe später.

## 5. Platzvariante für 24 Personen (Entscheidung nach Mockup)

Auf 4:3 (1024 × 768) wurden drei Anordnungen mit Platzhalterbildern verglichen (Screenshots im Übergabeordner `mockup-platzhalter/`):

| Variante | Befund |
|---|---|
| V1 Einring, Schild 84 px, „Nr Name“ im Schild | lesbar, ruhige Mitte, Namen aber ab etwa acht Zeichen gekürzt; im ersten Lauf überlappte die untere Reihe die Werkzeugleiste (Mockup-Fehler, in V1b behoben) |
| **V1b Einring, Nummer als Badge, Schild 84 px nur Name** | **empfohlen**: lesbar, Mitte frei, etwa zehn Zeichen Name, Sitzreihenfolge im Uhrzeigersinn klar erkennbar, nichts überlappt bei 1024 × 768 und 1280 × 800 |
| V2 versetzter Ring (Zickzack), Name 100 px | Schilder überlappen Porträts der Nachbarn, unruhig |
| V3 zwei Ringe (abwechselnd außen/innen) | Lesereihenfolge geht verloren, Schilder reichen an die Aktionskarte, wirkt zerstreut |

Rechenbasis: 24 Plätze auf einer Ellipse mit etwa 2270 px Umfang bei 1024 × 768 ergeben etwa 95 px Abstand. Ein Schild darf daher höchstens etwa 88 px breit sein. Zwei Ringe sind nur der Rückfall, falls Namen in der Praxis länger lesbar sein müssen.

**Einschränkung:** Das Mockup zeigt statische Platzhalter (alte, nicht freigegebene Bilder, nur 8 Gesichter wiederholt). Die Aussage gilt für die Platzaufteilung, nicht für das Aussehen der Endbilder.

## 6. Quellen und Status

Alle Bilder aus dem ChatGPT-Lauf sind Kandidaten. Pro Bild festhalten: Werkzeug und Modell, Datum, Prompt, Nachbearbeitung. Kandidaten liegen außerhalb von `godot/` (Übergabeordner), freigegebene Exporte kommen später in das Register (`docs/masterplan/ASSET-REGISTER.md`). Eine Aufnahme in das Register oder in `godot/` bedeutet noch keine Release-Freigabe.

## 7. Statusabzeichen und Rollensymbole (P2)

**Statusabzeichen am Platz:** Die sechs freigestellten Medaillons aus `p2-mockup/badges/` (Schutz, Gift, Markiert, Stumm, Tot, Sonder) sind die Abzeichen am Porträtplatz. Größe ab 24 px (rund 37 % des Porträtdurchmessers), unten rechts am Porträt, mehrere Abzeichen reihen sich nach links. Form und Farbe tragen die Information gemeinsam. Bei 24 px sind Schutz, Gift, Markiert und Tot sicher erkennbar, das Stumm-Symbol (Mund mit Schrägstrich) ist grenzwertig und auf dem Gerät zu prüfen.

**Größere Ansichten (Protokoll, Legende, Detailpanels):** nicht die Abzeichen skalieren, sondern die vorhandenen `marker-*.webp` verwenden.

**Rollensymbole (Nachtreihenfolge-Leiste):** Der Stil des Probeblatts P2-4 gilt für alle 72 Rollen (Entscheidung in `DECISIONS.md`): rundes Medaillon mit dunklem Metallrand, vier Rautenzier an den Kompasspunkten, monochromes Silber auf dunklem Grund, ein Emblem statt einer Szene, kein Text, keine Kartenecken. Lesbar ab etwa 40 px. Bis ein Symbol existiert, zeigt die Leiste das Kreisbild aus `night-icons-circle/`. Das Wolfskind-Symbol (Wolf mit Zipfelmütze) ist verworfen und wird neu erzeugt.

**Reparierte Teile:** Laschen ohne Text (Beschriftung über Lokalisierung), Nachtreihenfolge-Slots ohne Säume, Rollenkartenrahmen mit transparenter Platte. Siehe `p2-mockup/README.md`.
