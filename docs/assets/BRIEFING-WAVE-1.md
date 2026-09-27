# Produktionsbriefing · Erste hochwertige Assetwelle

**Stand:** 2026-09-27 · **Status:** Briefing zur Product-Owner-Freigabe. Nichts ist beauftragt, gekauft oder erzeugt.
**Welle:** W2 „Stiltest" aus [`PRODUCTION-PLAN.md`](PRODUCTION-PLAN.md) §3. Sie legt Stil, Werkzeuge und Nachweisablage fest, bevor die Masse (W3) produziert wird.
**Grundlagen:** Decision Log (bestätigter Planungsrahmen bis 500 €; Q8 Option B ist **Empfehlung**, nicht entschieden; siehe „Korrektur …“ vom 2026-09-27), [`../godot-migration/05-visual-audio-direction.md`](../godot-migration/05-visual-audio-direction.md), [`../architecture/tablet-asset-spec.md`](../architecture/tablet-asset-spec.md), [`../masterplan/ASSET-REGISTER.md`](../masterplan/ASSET-REGISTER.md).

**Kennzeichnung:** Vorgaben mit Quelle sind belegt. **[Vorschlag]** markiert gestalterische Festlegungen dieses Briefings, die der Product Owner noch bestätigen oder ändern muss.

Dieses Dokument ist so geschrieben, dass es als Ganzes oder je Abschnitt an eine Illustratorin, einen Sounddesigner, eine Sprecherin oder ein KI-Werkzeug weitergegeben werden kann.

---

## 1. Umfang

| # | Asset-ID | Art | Menge | Zweck in der Welle |
|---|---|---|---:|---|
| B1 | `bg-village-night` | Hintergrund | 1 | Grundstimmung der Nacht, Lesbarkeit des Sitzkreises |
| B2 | `portrait-werwolf` | Rollenporträt | 1 | Wolfsseite, Bedrohung ohne Gewalt |
| B3 | `portrait-waldhexe` | Rollenporträt | 1 | Dorfseite mit Magie, warmes Licht |
| B4 | `portrait-das-orakel` | Rollenporträt | 1 | Informationsrolle, kühles Licht |
| A1–A5 | `cue-night-begin`, `cue-dawn`, `cue-death`, `ui-confirm`, `ui-error` | Cue | 5 | Kern-Rückmeldungen |
| M1 | `music-night` (Probe) | Musik | 1 | 60–90 s schleifenfähige Probe |
| V1 | 6 Erzählerzeilen DE und EN | Stimme | 12 | Ton und Tempo der Stimme |

**Nicht in dieser Welle:** weitere Porträts, Tag- und Dämmerungshintergrund, Nebel-Ebenen, Siegel, Symbole, Rahmen, Karten, Tableaus, Ambiente, Fanfaren, App-Icon. Sie folgen in W3 im hier festgelegten Stil.

**Auswahl der drei Porträts.** Werwolf, Waldhexe und Orakel decken beide Hauptfraktionen, zwei Lichtstimmungen (warm, kühl) und die schwierigste Lesbarkeitsaufgabe ab (Tiergesicht gegen Menschengesicht bei ⌀ 56 px). Alle drei sind im Regelkern umgesetzt (`godot/README.md`, Rollen).

## 2. Kontext für alle Beteiligten

- **Produkt:** Grimmhain ist ein digitaler Spielleiter-Assistent für Werwolf-Runden am Tisch. Das Tablet liegt vor der Spielleitung, oft sichtbar für die Runde, in gedimmtem Licht, im Querformat. Referenzbildschirme: 1024×768 (4:3, iPad) und 1280×800 (16:10), siehe Abschnitt 4 B1 „Formate“.
- **Leitbild:** „Dunkles Märchen, helle Bedienung." Die Welt ist ein verfluchtes Walddorf zwischen Kerzenlicht und Mondnebel; die Bedienoberfläche liegt klar und ruhig davor (`05` §1).
- **Publikum:** Zielrichtung ab 12, keine drastische Gewaltdarstellung (Decision Log „Gestaltung, Audio und Assets“). [Vorschlag] Darüber hinaus kein Blut, keine Verletzungen, keine Leichen (in Anlehnung an `05` §2.2 „kein Blut auf dem Brett“).
- **Geheimhaltung:** Nichts darf ein geheimes Ereignis verraten, weder wen es betrifft noch dass es stattfand, bevor die Spielleitung es verkündet (`05` §1). Für Klänge gelten die Schnittstellenanforderungen in `PRODUCTION-PLAN.md` §6.4 und Abschnitt 5 unten.
- **Eigenständigkeit:** Keine Elemente, Formen oder Begriffe aus Blood on the Clocktower (Empfehlung `05` §2.4, `01` §6.2). Keine erkennbaren fremden Marken (Assetregister, Pflichtregeln). [Vorschlag] Auch keine Anlehnung an andere bekannte Social-Deduction-Spiele, keine lebenden Künstlerstile als Vorlage, keine Namen realer Künstlerinnen oder Künstler in Prompts.
- **Kein Text im Bild.** Beschriftungen setzt die App (`tablet-asset-spec.md` Grundregeln, `05` §7).

## 3. Art Direction für diese Welle

Die ausführliche Art Bible (W0-3) steht noch aus. Die Farben stammen aus dem umgesetzten Theme und `05`; Licht, Material und Legacy-Bewertung sind [Vorschlag]. Das Ergebnis der Welle wird Grundlage der Art Bible.

### 3.1 Farben (aus dem umgesetzten Godot-Theme und `05` §2.1)

| Rolle | Wert | Verwendung im Bild |
|---|---|---|
| Grundfläche App | `#0B0D14` | Bildränder und Vignette laufen auf diesen Ton zu, damit Bild und UI verschmelzen |
| Fläche | `#151924` | mittlere Schatten |
| Gold (Hausfarbe) | `#C9A84C` | Kerzen, Fensterlicht, Akzente; sparsam |
| Warmes Weiß | `#ECE7DC` | höchste Lichter; nie reines Weiß |
| Mondlicht | `#9DB4FF` | kaltes Oberlicht, Nachtnebel |
| Glut | `#FF8A3D` | Feuer, Kessel, Morgengrauen |
| Wolf | `#C1121F` | nur als kleiner Akzent (Augenreflex), nie als Blut |
| Dorf | `#2A9D8F` | Kleidungsdetails der Dorfrollen, gedämpft |

### 3.2 Licht und Material

- **Ein Hauptlicht je Bild**, klar erkennbar: Mond von oben links (Nacht), Kerze oder Kessel von unten (Waldhexe), kaltes Eigenleuchten (Orakel).
- Materialien: nasses Kopfsteinpflaster, dunkles Fachwerk, Wolle, Leder, Holz, angelaufenes Messing. Kein Hochglanz, keine Neonfarben.
- Detail nimmt zur Bildmitte ab (Hintergrund) beziehungsweise zum Rand ab (Porträt).

### 3.3 Was die Legacy-Bilder lehren (Referenz, nicht Vorlage)

| Legacy-Datei | Übernehmen | Vermeiden |
|---|---|---|
| `app/public/assets/bg/bg-village-night.webp` | Draufsicht auf einen ovalen Platz, Häuserring, Mond, Kirchturm als Orientierung | fast schwarze Mitte ohne Tiefenstaffelung; Häuserring zu gleichförmig; Turmuhr wirkt als Bildfokus neben dem Sitzkreis |
| `app/public/assets/portraits/Wolf_Male.png` | Frontalansicht, Augen als Blickfang, Stadtkulisse | Motiv füllt das Bild bis zum Rand, bei ⌀ 56 px nur dunkler Fleck; zu viel Fell-Rauschen |
| `assets/cards/de/Waldhexe.webp` | Kessel mit warmem Licht als Rollenmerkmal | Horrorgesicht im Rauch, Überfülle, eingebackener Text |
| `app/public/assets/markers/marker-protected.webp` | klare Silhouette, symmetrischer Rahmen | Blau-Violett-Glanz passt nicht zur Goldpalette |

Für diese Legacy-Dateien fehlt ein Herkunftsnachweis; ihre Nutzung ist nicht freigegeben (Register). Das ist keine Aussage über rechtliche Unzulässigkeit. [Vorschlag] Solange die Nutzung nicht geklärt ist, dienen sie nur als Gesprächsreferenz und werden nicht als Bildvorlage in ein KI-Werkzeug hochgeladen, abgepaust oder übermalt.

## 4. Grafik-Briefings

### B1 · `bg-village-night`

| | |
|---|---|
| Verwendung | Hintergrund des Spielleiter-Cockpits in der Nacht; Sitzkreis-Token und Ansagekarte liegen darüber. Die endgültige Cockpit-Aufteilung in Godot steht noch nicht fest (`godot/app/screens/cockpit/` ist ein Platzhalter) |
| Liefer-Spezifikation | 2560×1600 px, WebP q85 (Laufzeit) plus verlustfreier Master (PNG oder PSD), sRGB, ohne Alpha, ohne eingebettetes ICC-Profil |
| Formate | Bildschirme 1024×768 (4:3 = 1,33:1, iPad) und 1280×800 (16:10 = 1,6:1). Das Godot-Projekt skaliert von 1280×800 aus (`project.godot`: `canvas_items`, `expand`); auf 4:3 wächst die logische Fläche in der Höhe. Die früher genannten 1,71:1 und 2,03:1 (`tablet-asset-spec.md` §1) sind **nicht** der Bildschirm, sondern die gemessene Bühne der Legacy-React-App (Bildschirm minus Nachtleiste 76 px und Phasenleiste 56 px); für Godot gelten sie nicht |
| Beschnitt | Füllt das 16:10-Bild (2560×1600) den ganzen Bildschirm im `cover`-Modus: bei 16:10 bleibt alles sichtbar, bei 4:3 bleiben nur die mittleren **83 % der Breite** sichtbar (je 8,3 % links und rechts fallen weg). Bei einem späteren 16:9-Gerät blieben die mittleren 90 % der Höhe sichtbar |
| Sicherer Bereich (**vorläufig**) | Wichtige Motive innerhalb der mittleren 80 % Breite × 85 % Höhe (liegt in beiden Beschnittfällen sichtbar). Darin eine ruhige zentrale Ellipse von ca. 70 % × 80 % des sichtbaren Bereichs für den Sitzkreis: geringer Kontrast, keine Einzelobjekte. Vorläufig, weil Lage und Größe der Spielfeldfläche im Godot-Cockpit noch nicht feststehen; keine Zuschnittgarantie. Nach Festlegung des Cockpit-Layouts neu prüfen |
| Motiv | Dorfplatz eines Walddorfs aus erhöhter Perspektive (ca. 45°), Kopfsteinpflaster, am Rand ein unregelmäßiger Ring aus Fachwerkhäusern mit wenigen erleuchteten Fenstern, dahinter dunkler Nadelwald, Mond oben links, Nebel am unteren Rand |
| Stimmung | still, wachsam, nicht bedrohlich; die Gefahr liegt im Wald, nicht auf dem Platz |
| Helligkeit | Mitte bei ca. 10–15 % Luminanz (heller als die App-Grundfläche, damit Token-Schatten sichtbar bleiben); keine Fläche heller als 70 % außer Mond und Kerzenpunkte |
| Vorgaben | keine Schrift (`tablet-asset-spec.md`). [Vorschlag] keine Figuren, keine Tiere, kein Galgen, kein Blut, kein Uhrenziffernblatt als Blickfang |
| Abnahme | Vollbild-Testansicht bei 1024×768 und 1280×800 mit einer Platzhalter-Überlagerung von 12, 18 und 24 Token (in Anlehnung an `tablet-asset-spec.md` §8): Token-Ränder und Namen lesbar; der 4:3-Beschnitt schneidet kein wichtiges Motiv |

### B2–B4 · Rollenporträts (gemeinsame Vorgaben)

| | |
|---|---|
| Verwendung | Token im Sitzkreis (⌀ 56–110 px), Ansagekarte (ca. 160–240 px), später Rollenkarte |
| Liefer-Spezifikation | 512×512 px WebP q85 (Laufzeit) plus Master mindestens 2048×2048 px, sRGB, ohne Alpha |
| Komposition | Kopf und Schulterpartie, frontal bis Dreiviertel; Motiv innerhalb des Kreises ⌀ 460 px; Augenlinie bei 40 % der Höhe; Hintergrund schlicht und dunkel, ohne Ring oder Rahmen (kommt aus dem Code) |
| Lesbarkeit | Silhouette und Gesicht müssen bei ⌀ 56 px (24 Spieler auf 1024×768) als dieses Porträt erkennbar sein. Ein Hauptlicht, klarer Hell-Dunkel-Kontrast im Gesicht, keine feinen Muster |
| Serie | gleicher Bildausschnitt, gleiche Kamerahöhe, gleiche Pinsel- oder Renderanmutung in allen drei Bildern |
| Vorgaben | keine Schrift, kein Ring oder Rahmen im Bild (`tablet-asset-spec.md` §2). [Vorschlag] kein Blut, keine Wunden, keine Waffen im Anschlag, keine Symbole anderer Spiele, keine erkennbaren realen Personen |

Die Figurenspalte ist aus `rules-register.md` abgeleitet. Bildidee, Geschlecht, Alter, Darstellungsstil und Licht sind **[Vorschlag]**; der Product Owner entscheidet sie (Abschnitt 11).

| Porträt | Figur (aus den Regeln abgeleitet, `rules-register.md`) | Bildidee [Vorschlag] | Licht [Vorschlag] |
|---|---|---|---|
| **B2 · Werwolf** | Teil des Rudels; jede Nacht wählt das Rudel gemeinsam ein Opfer | Wolfskopf mit menschlicher Haltung, dunkles Fell, halb aus dem Schatten tretend; bernsteinfarbene Augen mit kleinem rotem Reflex; Kapuze oder Mantelkragen deutet an, dass er tagsüber im Dorf lebt | Mondlicht von oben links, Gesicht zur Hälfte im Schatten |
| **B3 · Waldhexe** | Kräuterkundige des Dorfs; erfährt das Wolfsopfer, hat einen Heil- und einen Gifttrank | Frau mittleren Alters, wettergegerbt, wach und entschlossen statt unheimlich; zwei kleine Fläschchen gut sichtbar (eines warm leuchtend, eines dunkelgrün), Kräuterbündel | warmes Kessel- oder Kerzenlicht von unten |
| **B4 · Das Orakel** | Seherin oder Seher; erfährt jede Nacht die Rolle einer Person | alterslose Figur mit verhüllten oder geschlossenen Augen, Hände um eine matte Glaskugel oder Wasserschale, ruhiger Ausdruck | kaltes Eigenlicht aus der Kugel, Mondton `#9DB4FF` |

**Konzeptphase mit KI.** Die grundsätzliche Nutzung kostenpflichtiger KI-Werkzeuge ist vom Nutzer genannt; für finale KI-Assets gilt der Decision-Log-Eintrag „Gestaltung, Audio und Assets“ (Herkunft, Lizenzprüfung, Qualitätsprüfung, PO-Freigabe). Q8 ist offen. Für Moodboards und Varianten dürfen KI-Bildwerkzeuge genutzt werden. Vorlage für einen Prompt, anzupassen je Motiv:

```text
Painted dark-fairytale character portrait, head and shoulders, centered, eye line at 40 % height,
[FIGUR UND BILDIDEE], single key light from [LICHT], muted palette of deep charcoal blue,
warm candle gold and cold moonlight, soft painterly texture, simple dark background,
strong silhouette readable at thumbnail size, no text, no frame, no border, no blood,
no gore, no weapons, not in the style of any named artist or existing game
```

Jeder KI-Durchlauf wird protokolliert (Abschnitt 7). Ein KI-Ergebnis wird nur final, wenn der Tarif kommerzielle Nutzung eindeutig erlaubt, die Bedingungen zum Datum archiviert sind und die Nachbearbeitung dokumentiert ist. Sonst dient es als Konzept für eine eigene oder beauftragte Ausführung.

## 5. Audio-Briefings

Technische Norm für alle Dateien: 48 kHz; Cues und UI als WAV 16 bit, −18 LUFS, Spitze ≤ −1 dBTP, Stille am Anfang ≤ 10 ms; Musik als WAV-Master plus OGG Vorbis q5, −16 LUFS (`PRODUCTION-PLAN.md` §6.1). Messung und Normalisierung sind mit dem kostenlosen `ffmpeg` (Filter `ebur128`, `loudnorm`) und Audacity möglich.

**Wann ein Klang hörbar wird** (Schnittstellenanforderung für das spätere Audio-System, `PRODUCTION-PLAN.md` §6.4; noch nicht umgesetzt). Das Tablet steht offen auf dem Tisch; auch ein Klang ohne Personenbezug kann verraten, dass ein geheimes Ereignis stattfand. Deshalb:

- A1 und A2 folgen nur freigegebenen öffentlichen Phasenübergängen.
- A3 gehört zur ausdrücklichen öffentlichen Verkündung eines Todes durch die Spielleitung, nie zum internen Tod in der Nacht.
- A4 und A5 sind in geheimen Schritten (Nachtschritte, private Anzeigen) stumm; dort gibt es nur visuelle Rückmeldung.
- Geheime Ereignisse wie Schutz, Angriff oder Rollenwechsel lösen keinen öffentlichen Klang aus.
- Fehlt eine Datei, läuft die Bedienung ohne Klang weiter.

Die Klänge dieser Welle werden trotzdem so gestaltet, dass sie auch bei versehentlicher Wiedergabe möglichst wenig verraten: kurz, ohne Stimme, ohne erzählende Wirkung.

| ID | Ereignis | Klangbeschreibung | Länge | Muss / darf nicht |
|---|---|---|---|---|
| A1 `cue-night-begin` | Nacht beginnt (öffentlich) | ein tiefer, weicher Glockenschlag, langer natürlicher Ausklang, leichter Wind im Nachhall | 2,0 s | muss auf Tablet-Lautsprechern bei 50 % hörbar sein; darf nicht dröhnen |
| A2 `cue-dawn` | Morgengrauen (öffentlich) | ferner Hahn, zwei, drei Vogelstimmen, aufhellend | 2,5 s | darf nicht comichaft wirken |
| A3 `cue-death` | Tod beim Verkünden | tiefer gedämpfter Gong, danach ein Ausatmen des Windes | 1,5 s | ernst, nicht schockierend; kein Schrei, keine Stimme |
| A4 `ui-confirm` | Bestätigen | kurzer trockener Holzton | ≤ 0,15 s | angenehm bei 50 Wiederholungen je Partie |
| A5 `ui-error` | abgelehnte Eingabe | tiefer, dumpfer Holzklopfer | ≤ 0,2 s | klar anders als A4, nicht strafend |

**M1 · `music-night` (Probe).** Empfohlener Ersatz für die gesperrte, nicht freigegebene `Nachtmusik.mp3`. Ruhige, schwebende Nachtmusik mit wenigen Instrumenten (z. B. tiefe Streicher oder Drone, einzelne Harfen- oder Celesta-Töne, gedämpfte Trommel sehr fern), Moll, 60–75 BPM gefühlt, keine Melodie, die sich aufdrängt, keine Stimmen. Muss unter der Erzählerstimme bei −6 dB Ducking tragen. Probe 60–90 s, nahtlos schleifenfähig; Endfassung später 3–5 min.

**Quellen, in dieser Reihenfolge:**
1. eigene Aufnahme oder Synthese (0 €), z. B. Holzklopfer, Wind;
2. Bibliotheken mit eindeutiger kommerzieller Lizenz ohne Einzelabrechnung, Lizenztext beim Download als PDF archivieren (z. B. Freesound nur mit Filter „Creative Commons 0"; die jährlichen GDC-Audio-Bundles von Sonniss);
3. KI-Musik- oder Klangdienst nur mit Tarif, der kommerzielle Nutzung ausdrücklich einschließt, für die Laufzeit des Abos; Bedingungen zum Erstellungsdatum archivieren;
4. Auftrag an eine Person mit schriftlicher Rechteübertragung (Buy-out).

Keine Samples aus bekannten Filmen, Serien oder Spielen, keine „Soundalikes".

## 6. Erzähler-Briefing (V1)

| | |
|---|---|
| Zeilen | `narration.night.begin`, `narration.dawn.begin`, `role.werwolf.call`, `role.werwolf.sleep`, `narration.morning.no_death`, `narration.win.village` aus [`NARRATOR-SCRIPT.md`](NARRATOR-SCRIPT.md), jeweils DE und EN |
| Stimme | ruhige Erzählstimme, warm, mittlere Tonlage, klar artikuliert; keine Horror-Verstellung, kein Flüstern |
| Tempo | ca. 130 Wörter/min (DE), deutliche Pause nach dem ersten Satz |
| Technik | WAV 24 bit 48 kHz Mono, trocken, 0,3 s Stille vorn und hinten, Rauschen ≤ −60 dBFS, −18 LUFS; Dateiname `vo-<de|en>-<schlüssel mit Bindestrichen>.wav` |
| Rechte | eigene Aufnahme: schriftliche Einwilligung der sprechenden Person zur Nutzung in App, Stores und Werbung; KI-Stimme: nur Stimmen des Anbieters mit geklärten Stimmrechten, keine geklonte fremde Stimme |
| Vorher | Die Texte in `NARRATOR-SCRIPT.md` sind Entwurf; für V1 genügt die PO-Freigabe dieser sechs Zeilen |

## 7. Nachweis-Paket je Asset

Vor der Übergabe ins Repository liegt im Archiv (Struktur `PRODUCTION-PLAN.md` §2) für jedes Asset:

- [ ] `brief.md`: Auszug aus diesem Dokument, Datum, beteiligte Personen
- [ ] Rohdateien und Master (verlustfrei)
- [ ] Werkzeug und Version, Tarif, Rechnung oder Kontoauszug-Zeile
- [ ] Nutzungsbedingungen des Tarifs zum Erstellungsdatum als PDF
- [ ] bei KI: alle Prompts, Seeds oder Verlaufs-Export, ausgewählte Variante, C2PA-Manifest unverändert im Master
- [ ] bei Bibliotheken: Lizenztext, Quell-URL, Datei-ID, Urheberangabe
- [ ] bei Auftrag: Vertrag oder schriftliche Rechteübertragung
- [ ] Nachbearbeitung: was, womit, von wem
- [ ] technische Abnahme (Maße, Lautheit, Schleife, 56-px-Test)
- [ ] Registerzeile vorbereitet (Status `ki-nachgewiesen` oder `ungeklärt` bis zur Freigabe)

## 8. Abnahme und Entscheidung nach der Welle

**Technik (bestanden / nicht bestanden):** Spezifikation aus Abschnitt 4–6 eingehalten; `node tools/check-asset-register.js` grün; Nachweis-Paket vollständig.

**Wirkung (Product Owner, Skala 1–5, am Tablet im gedimmten Raum):**

| Kriterium | B1 | B2 | B3 | B4 | Audio | Stimme |
|---|---|---|---|---|---|---|
| passt zu „dunkles Märchen, helle Bedienung" | | | | | | |
| lesbar bzw. hörbar unter Spielbedingungen | | | | | | |
| eigenständig, nicht verwechselbar | | | | | | |
| wirkt als Serie (Porträts, Audio) | | | | | | |
| stört nie die Bedienung | | | | | | |

**Entscheidung:** Durchschnitt ≥ 4 und kein Wert < 3 → Werkzeug und Stil für W3 festlegen. Sonst: Ursache benennen (Werkzeug, Brief, Ausführung), Brief anpassen, höchstens eine Wiederholung innerhalb des Budgets.

## 9. Werkzeuge und Kostenrahmen

Richtwerte zur Planung, keine Angebote. Preise und Bedingungen vor jeder Buchung aktuell prüfen und archivieren (Kaufcheckliste `BUDGET.md`). Claude kauft nichts.

| Bereich | Kostenloser Weg | Kostenpflichtiger Weg (falls Qualität nicht reicht) | Vorschlag W2 |
|---|---|---|---:|
| Porträts, Hintergrund | eigene Ausführung auf Basis von KI-Konzepten; Krita, GIMP | ein Monat eines KI-Bilddienstes mit kommerzieller Lizenz im Tarif | 30 € |
| Cues | eigene Aufnahme, CC0-Bibliothek, Audacity, ffmpeg | Einzelkauf aus einer Bibliothek mit Lizenzurkunde | 10 € |
| Musikprobe | eigene Produktion | ein Monat eines Musikdienstes mit kommerziellem Tarif | 20 € |
| Stimme | eigene Aufnahme mit Smartphone oder USB-Mikrofon im gedämpften Raum | – (erst W3) | 0 € |
| **Summe W2 (vorgeschlagenes Teilbudget)** | | | **≤ 60 €** |

Bestätigt ist nur der Planungsrahmen bis 500 €. Die 60 € für W2 und die 300 € Gesamtplanung (`PRODUCTION-PLAN.md` §8) sind Vorschläge; kein Kauf ist genehmigt.

## 10. Ablauf

1. Product Owner gibt dieses Briefing und die sechs Erzählerzeilen frei.
2. Archivordner nach `PRODUCTION-PLAN.md` §2 anlegen.
3. Audio A1–A5 zuerst (günstig, schnell, prüft den Nachweisablauf).
4. Konzeptrunde Porträts: je Figur 6–10 Varianten, Auswahl durch Product Owner, dann Ausführung.
5. B1 Hintergrund, Test mit Token-Überlagerung.
6. M1 und V1.
7. Abnahme nach Abschnitt 8, Registerzeilen anlegen.
8. Übernahme nach Godot erst in einem eigenen Arbeitspaket, nach Freigabe.

## 11. Offene Entscheidungen für den Product Owner

1. Freigabe dieses Briefings und der Porträtauswahl (Werwolf, Waldhexe, Orakel).
2. Darstellung der Porträts: gemalte Illustration (Empfehlung, trägt die Märchenanmutung) oder fotorealistischer Render?
3. Geschlecht und Alter der Figuren: wie in Abschnitt 4 vorgeschlagen oder bewusst gemischt über die späteren 20–30 Rollen planen?
4. Wer spricht die Probe V1?
5. Q8: Option B verbindlich machen oder anders entscheiden (bisher nur Empfehlung).
6. Teilbudget der ersten Welle: vorgeschlagene 60 € bestätigen, ändern oder auf 0 € (nur kostenlose Wege) setzen.
7. Gestalterische Vorgaben, die hier als [Vorschlag] markiert sind: Figurenbeschreibungen, Motivverbote, Helligkeitswerte, Lichtführung.
8. Sicherer Bildbereich des Hintergrunds endgültig festlegen, sobald das Godot-Cockpit-Layout steht.
