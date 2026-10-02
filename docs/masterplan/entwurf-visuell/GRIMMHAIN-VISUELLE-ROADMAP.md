# Grimmhain: vollständige Roadmap für Spielbrett, Atmosphäre und Bedienung

Stand: 01.10.2026. **Entwurf zur Bestätigung durch Claude und Markus, noch kein Umsetzungsauftrag.**

**Ziel:** Aus dem funktionierenden Godot-Prototyp ein hochwertiges, atmosphärisches und auf Tablets zuverlässig bedienbares Werwolf-Spiel machen. Das laufende Spielbrett soll sich an den beigefügten Tag-, Nacht- und Angriffsreferenzen orientieren und den bestehenden Spielablauf tatsächlich bedienen.

**Architektur:** Bestehender Godot-Regelkern und Anwendungsschicht bleiben Grundlage. Die Darstellung wird als 2D-Szene aus mehreren Bildebenen mit räumlicher Wirkung, nativen Godot-Bedienelementen und gezielten Effekten umgesetzt. Kein kompletter 3D-Neubau und keine neue Web-Oberfläche.

**Technik:** Vorhandenes Godot/GDScript-Projekt, Controls und Theme, Texturen, AnimationPlayer/Tweens, geeignete Partikel und sparsame Shader. Keine neue Engine und kein Versionswechsel allein für die Gestaltung.

**Ausführung nach Bestätigung:** Ein Claude-Code-Agent arbeitet paketweise mit `executing-plans` oder dem bestehenden Projektworkflow. Keine automatische Delegation. Die Arbeitspakete sind bewusst größer als einzelne Mini-Fixes; die Nutzervorgabe zur begrenzten Prüfung geht generischen Testabläufen vor.

## 1. Ausgangspunkt und Verbindlichkeit

- Lokal geprüfter Branch: `feature/night-ui-expansion`, Commit `9ca16c2`, Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui`.
- PR #3 bleibt offen. Diese Roadmap autorisiert keinen Merge.
- Der letzte Bericht nennt 1.457 grüne Tests und grüne CI. Diese Roadmap hat diese Tests nicht erneut ausgeführt.
- Rollen, Karten, Phasen, Speichern und ein funktionales Cockpit sind vorhanden. Eine neue Illustration ersetzt keine fehlende Funktion; andererseits ist ein grüner Geometrietest kein Beleg für gutes Aussehen.
- Das aktuelle Bild zeigt eine zu dominante Textkarte, rechteckige Personenbuttons und kaum Atmosphäre. Die Angabe „85–92 % Brettfläche“ beschreibt den Container, nicht den tatsächlich sichtbaren Dorfplatz.
- Die zuletzt ergänzte Testvorgabe in `CLAUDE.md` ist eine vorhandene, uncommittete Nutzeränderung. Erhalten und nicht versehentlich verwerfen.
- Sichtbare Godot-Fenster und visuelle Prüfungen sind inzwischen erlaubt. Die frühere Einschränkung wegen des Urban-Rivals-Bots ist aufgehoben.
- Autoritative Spielregeln bleiben im Decision Log. Diese Roadmap entscheidet Darstellung und Arbeitsreihenfolge, keine neuen Rollenfähigkeiten.

### Referenzen, zusammen mit dieser Datei weitergeben

Die vier Bilder sind im Unterordner `referenzen/` dauerhaft kopiert:

| Datei | Bedeutung |
|---|---|
| [01-istzustand.png](referenzen/01-istzustand.png) | Funktionierender Prototyp, dessen visuelle Schwächen behoben werden sollen |
| [02-ziel-tag.png](referenzen/02-ziel-tag.png) | Dorfplatz, warme Beleuchtung, Porträtringe, kompakte Spielinformation |
| [03-ziel-nacht.png](referenzen/03-ziel-nacht.png) | Hauptreferenz für den ersten hochwertigen, spielbaren Stand |
| [04-ziel-angriff.png](referenzen/04-ziel-angriff.png) | Richtung für spätere dramatische, kurze Ereignisanimationen |

Die Bilder sind Gestaltungsreferenzen, keine freigegebenen Laufzeitassets. Nicht als kompletten Screenshot hinter unsichtbare Buttons legen. Abgebildete Zähler, Texte und Rollenmarker sind keine neuen Produktanforderungen. Doppelte Platznummern oder unmögliche Details der Referenzen nicht übernehmen.

## 2. Fertig bedeutet am Ende dieser Roadmap

- [ ] Eine echte Partie mit 6–24 Personen lässt sich auf dem gestalteten Brett durchführen.
- [ ] Dorfplatz, Porträts, Rahmen, Typografie, Karten und Effekte bilden einen erkennbar einheitlichen Stil.
- [ ] Tag, Nacht, Morgen, Zielwahl, Schutz, öffentlicher Tod, Wiederbelebung und Spielende sind verständlich inszeniert.
- [ ] Alle 72 Rollen und 80 Totenreichkarten bleiben bedienbar, auch wenn viele davon gemeinsame Darstellungsbausteine nutzen.
- [ ] Namen und relevante Statusinformationen sind ohne Zoom lesbar; Ziele lassen sich mit dem Finger sicher auswählen.
- [ ] Geheimnisse werden nicht durch Porträt, Bewegung, Audio, Highlight oder versteckte Oberfläche verraten.
- [ ] Animationen sind überspringbar und verändern weder Regeln noch gespeicherte Entscheidungen.
- [ ] Die App funktioniert offline, mit reduzierter Bewegung und stummgeschaltetem Audio.
- [ ] Ein realer iPad-Test und später Android-Tests auf einer ausdrücklich benannten Gerätegruppe sind erfolgt.
- [ ] Windows erhält dieselbe funktionale Gestaltung mit passender Maus-/Tastaturbedienung.
- [ ] Assetherkunft, Produktionsdateien, Import und Budget sind nachvollziehbar.

Nicht enthalten als angeblich fertige Funktion: Smartphone-QR-Verbindung, tatsächliche externe Projektion, Online-Multiplayer, Shop, Steam-Veröffentlichung und neue Spielinhalte. Abschnitt 12 benennt die Anschlüsse dafür. Diese Roadmap ist vollständig für den visuellen Offline-Spielumfang, nicht gleichbedeutend mit Abschluss des gesamten kommerziellen Produkts.

## 3. Feste Leitplanken

### Spielbrett und Information

1. In der normalen Brettansicht stehen ungefähr 85–90 % der nutzbaren Fläche dem Brett zur Verfügung. Zusätzlich zählt der visuelle Eindruck: kein großer undurchsichtiger Dialog über dem gesamten Dorf.
2. Die normale Aktionskarte enthält Titel, eine kurze Anweisung und die nächste Handlung. Langer Vorlesetext, Erklärung und Details öffnen bei Bedarf. Wichtige Regeltexte dürfen dadurch nicht verloren gehen.
3. Ausgangswert für den Entwurf: kompakte Aktionskarte bis ungefähr 25 % der Brettfläche; bei 24 Personen gegebenenfalls kleiner oder anders platziert. Das ist ein Designziel, kein starres Hindernis für notwendige Auswahldialoge.
4. Kein Spielerplatz darf durch die normale Aktionskarte verdeckt sein. Bei Zielwahl müssen alle zulässigen Ziele erreichbar bleiben.
5. Kreisförmige beziehungsweise leicht elliptische Anordnung; dieselbe Sitzreihenfolge und Personen-ID wie bisher. Kein Spiegeln für Linkshänder und kein automatisches Umordnen im laufenden Spiel.
6. Neutrale Personenporträts sind von geheimen Rollenillustrationen getrennt. Rollenwechsel dürfen nicht unbemerkt das öffentliche Porträt in einen Wolf verwandeln.
7. Große Texte und Auswahlkarten dürfen als bewusst geöffnete Detailansicht das Brett zeitweise ersetzen. Text scrollt, notwendige Aktionen bleiben fest sichtbar.

### Stil

- Düsterer, eigenständiger mittelalterlicher Dorfplatz, gotische Architektur, nasses Pflaster, Mondlicht, warmes Feuer und zurückhaltende rote Stoffe.
- Gealtertes Gold und dunkles Metall für Rahmen. Ornament vor allem an Schwerpunkten, nicht an jedem Text und jedem Abstand.
- Dekorative Schrift nur für kurze Überschriften; klare Leseschrift für Namen, Regeln und Anweisungen.
- Ruhige Zonen hinter Namen und Text. Nicht jedes detailreiche Referenzmotiv eignet sich unverändert als interaktiver Hintergrund.
- Keine Texte in generierten Bildern. Keine erfundenen Anzeigen, die keinen Wert aus dem Spielmodell besitzen.

### Arbeit, Entscheidungen und Tests

- Normale technische und gestalterische Details entscheidet Claude selbst. Keine neue kleinteilige Fragenserie.
- Drei gebündelte Produktabnahmen: erster Stilentwurf, spielbares Nachtbrett, finaler Gerätecheck. Keine Bestätigung für jedes Icon.
- Große Richtungsänderungen und kostenpflichtige Bestellungen bleiben Entscheidungen von Markus. Ein Budget ist keine Kaufvollmacht.
- Pro Paket normalerweise 1–2 lokale Prüfrunden: gezielt und gegebenenfalls Abschluss. Zusätzliche Läufe nur nach Fehler oder relevanter Änderung, mit kurzem Grund.
- Keine vollständige Rollen-/Kartensuite bei reinen Textur- oder Layoutänderungen. Sichtprüfung statt automatischer Tests, die lediglich Pixelwerte nacherzählen.
- Bestehende CI nicht deaktivieren. Automatische CI ist kein Anlass, unveränderte lokale Prüfungen nochmals zu starten.
- Ein screenshotbasierter Sichtcheck gehört in einen gebündelten Prüfdurchgang. Nicht nach jeder Farbänderung die komplette Ansichtenmatrix erzeugen.

## 4. Bestand wiederverwenden, veraltete Quellen eingrenzen

Die folgenden Pfade sind relativ zum aktiven Worktree. Sie sind vorhandene Ansatzpunkte, keine Forderung, jede Datei anzufassen.

| Bereich | Vorhandene Dateien/Ordner | Aufgabe |
|---|---|---|
| Brett und Karte | `godot/app/screens/cockpit/cockpit_screen.gd`, `.tscn`, `action_card.gd`, `detail_panel.gd`, `cockpit_layers.gd` | Aufbau, zentrale Handlung, Detailansichten |
| Spielerplätze | `godot/app/widgets/seat_ring/game_seat_ring.gd`, `game_seat_token.gd` | Sitzanordnung, Porträts, Auswahl, Zustände |
| Stil | `godot/app/theme/theme_tokens.gd`, `theme_factory.gd` | Schriften, Größen, Farben, Abstände, Controls |
| Sichere Daten | `godot/app/session/cockpit_view.gd`, `prompt_view.gd`, `card_view.gd`, `morning_report.gd` | Nur passende öffentliche/private Daten an Ansichten geben |
| Darstellung und Ton | `godot/app/session/presentation_cue.gd`, `godot/app/audio/audio_cue_player.gd` | Gezielt erweitern, nicht durch zweiten Regelkern ersetzen |
| Optionen | `godot/app/settings/`, `godot/app/screens/settings/` | Handmodus, Bewegung, Ton, Leistungsprofil |
| Bestandstests | `godot/tests/ui/test_board_layout.gd`, `test_handedness.gd`, `test_cards_ui_closing.gd`, `test_full_round_ui.gd` | Relevante Tests anpassen statt parallele Prüfsysteme bauen |
| Medien | `docs/assets/PRODUCTION-PLAN.md`, `BRIEFING-WAVE-1.md`, `NARRATOR-SCRIPT.md`, `FONTS.md` und vorhandenes Assetregister | Bestehende Briefings und Nachweise fortführen |

**Konkrete Quellenprobleme:**
- `docs/architecture/tablet-asset-spec.md` stammt aus React/Pixi. Bildideen können nützlich sein, UI-Technik, Maße und Aussagen über CSS nicht als Godot-Vertrag übernehmen.
- `docs/ui/cockpit.md` enthält neben neuem Layout noch historische Aussagen zur freien Rollenaufdeckungsoption und älteren Schemas. Für Geheimhaltung aktuelle Entscheidungen und Code verwenden.
- `presentation_cue.gd` beschreibt am geprüften Stand den Fünf-Tote-Hinweis. Eine allgemeine sichere Ereignispräsentation für Angriffe ist nicht bereits allein dadurch vorhanden.
- Bericht widersprüchlich: Totenreichkarten sollen im Setup aktivierbar sein, zugleich wird dort ein fehlender Schalter genannt. In P0 gezielt am tatsächlichen Bildschirm prüfen, keine erneute Gesamtanalyse.

## 5. Produktionsablauf und Zuständigkeit

| Beteiligter | Liefert |
|---|---|
| Markus | Bestätigt Stil und tatsächliche Bedienbarkeit in drei gebündelten Abnahmen; führt reale Tabletprobe durch, wenn kein Gerätezugriff verfügbar ist |
| Claude Code | Godot-Szenen, Anbindung, Theme, Importe, Animation, Audiosteuerung, gezielte Fehlerbehebung und technische Übergabe |
| Bildproduktion über verfügbares Bildwerkzeug oder Designer | Hintergründe, Porträts, Rahmen und einzelne Effektbestandteile nach konkretem Briefing |
| Audioproduktion über geeignetes Werkzeug oder Bibliothek | Musik, Atmosphären, Effekte und optionale Sprecherdateien mit dokumentierter Herkunft |

Claude darf nicht behaupten, ein Bild oder Audio produziert zu haben, wenn das benötigte Werkzeug nicht verfügbar ist. Dann liefert er das konkrete Briefing und arbeitet an unabhängigen Aufgaben weiter. Ein einfacher Platzhalter hält die Entwicklung lauffähig, erfüllt aber keine finale Grafikabnahme.

### Assetvertrag für die neue Godot-Produktion

- Jeder Auftrag enthält Asset-ID, Verwendung, Blickwinkel, Licht, Bildausschnitt, Transparenz, Varianten und untersagte eingebrannte Texte.
- Tag und Nacht zeigen denselben Dorfplatz aus derselben Kamera. Gebäude und Perspektive dürfen beim Überblenden nicht springen.
- Erste Hintergründe als detailreiche Masterdateien ungefähr 2560×1600 oder größer, sofern das Werkzeug sinnvoll liefert. Laufzeitauflösung erst nach tatsächlichem Gerätebedarf und Speicherprüfung wählen.
- Transparente Porträtrahmen und FX als getrennte Dateien; keine großflächigen Atlanten voller ungenutzter Leerfläche.
- Bedienrahmen skalierbar, etwa mit getrennten Ecken/Rändern; Ornamente dürfen lange deutsche Texte nicht zusammendrücken.
- Laufzeitformate und Godot-Importe auf dem gewählten Renderer prüfen. Keine alten WebP-/Pixi-Empfehlungen ungeprüft übernehmen.
- Quelldatei, Generator/Modell, Erstelldatum, relevante Nutzungsbedingungen, Prompt und Bearbeitungen soweit verfügbar dokumentieren. KI-Metadaten allein sind keine Lizenzfreigabe.
- Referenzbilder nicht automatisch als freigegebene Assets einstufen. Ungeklärte alte Nachtmusik bleibt gesperrt.
- Kandidaten zunächst außerhalb der Laufzeitassets sammeln; freigegebene Exporte in das bestehende Register übernehmen.

## 6. Arbeitspakete und Abnahmen

Reihenfolge: P0 → P1 → P2 → P3. Danach P4/P5/P6 auf derselben gestalterischen Grundlage. P7/P8 liefern Ereignisse und Audio. P9/P10 machen den Stand auf Geräten belastbar. P11 schließt ab.

### P0: Ausgangsstand und zielgerichtete Vorbereitung

**Ergebnis:** Eine laufende Referenzpartie und klare technische Ansatzpunkte, keine neue Grundlagenanalyse.

- [x] Branch, HEAD, Arbeitsverzeichnis und vorhandene Änderungen feststellen.
- [x] Aktuelles Brett einmal sichtbar starten; 24-Personen-Ansicht und eine Zielwahl ansehen.
- [x] Totenreichkarten-Schalter im Setup gezielt prüfen; bei realem Fehlen kleinsten Funktionsfix separat behandeln.
- [x] Referenzen lesen, vorhandene freigegebene Grafiken/Schriften sichten, unnötige Neuproduktion vermeiden.
- [x] (Standard-iPad, genaues Modell folgt) Vorhandenes Gerät für den ersten iPad-Test benennen lassen, wenn Modell unbekannt ist; Designarbeit läuft unabhängig weiter.
- [ ] Diese Roadmap nach Bestätigung unter `docs/masterplan/VISUAL-EXPERIENCE-ROADMAP.md` übernehmen und im Masterplan verlinken. (Offen: bisher nur unter `docs/masterplan/entwurf-visuell/`, nicht verlinkt.)

**Abnahme:** Tatsächlicher Startweg, Zielszene, verfügbare Assets und ein konkreter Setup-Befund. Keine vollständige Testsuite allein für diese Vorbereitung.

### P1: Ein verbindlicher Stilentwurf

**Ergebnis:** Ein hochwertiger Nachtentwurf mit 24 Plätzen, nicht nur eine Farbpalette.

- [x] Bestehendes Grafikbriefing um eine kompakte Art Direction ergänzen: Komposition, Schriften, Palette, Rahmenstil, Personen-/Rollenporträts, Bewegungscharakter.
- [x] Nachtentwurf für 4:3 und Übertragung auf 16:10 erstellen. Ein gemeinsames Design, keine breite Variantenlotterie.
- [x] 24 gut lesbare Namensschilder, ruhiger Dorfplatz und eine kleine Aktionskarte zeigen.
- [x] Kurze Anweisung und ausführliche Detailansicht separat darstellen.
- [x] Sichtbare Touch-Flächen neben der bloßen Bildgröße festlegen; Vorschlag 48–56 logische Einheiten, auf dem Gerät prüfen statt als universelle Pixelvorgabe behandeln.
- [x] Falls keine Bildproduktion verfügbar ist, konkretes Briefing für einen Bildgenerierungsauftrag liefern, nicht wieder nur graue Kästen als Endergebnis vorlegen.

**Abnahme 1 durch Markus:** „Diese Richtung ist das gewünschte Spiel.“ Eine gebündelte Korrekturrunde. Erst danach große Serienproduktion.

**Erledigt am 01.10.2026 (Abnahme 1 erteilt).** Nachweis: Mockup V2 (`docs/assets/p1-mockup/`, Screenshots `Downloads/Grimmhain-P1-Nachtentwurf/mockup-v2/`), Entscheidungen in `DECISIONS.md`. Verbindliche Layoutvorlage ist `Spielfeld.png` und `Full UI.png` aus „Grimmhain Assets“, nicht die ursprünglichen Zielbilder. Hinweis: Die Porträts waren Mockup-Material, 24 eindeutige Gesichter fehlen noch (P2).

### P2: Minimales zusammenhängendes Grafikpaket

**Ergebnis:** Genug echte Grafiken für ein überzeugendes Nachtbrett.

- [ ] Nacht-Dorfplatz ohne UI, Namen, Spieler und Texte produzieren.
- [ ] Vordergrund als eigene optionale Ebene; freie Sicht auf Spielerplätze und Zielauswahl erhalten.
- [ ] Ein einheitlicher Spielerrahmen mit normaler, ausgewählter und toter Variante.
- [ ] Kleine neutrale Porträtserie für sechs Personen; zusätzliche Plätze zunächst mit wiederverwendbaren neutralen Motiven und eindeutigen Namen belegen.
- [ ] Aktionskartenrahmen, Hauptbutton, dezente Statussymbole und Phasenemblem produzieren.
- [ ] Bilder in echter Anzeigegröße prüfen: Transparenzränder, Kontrast, Zuschnitt und gleiche Lichtstimmung.
- [ ] Assetregister, Export und Quellablage führen. Keine 72 Rollenbilder vor dem bestätigten Stil produzieren.

**Abnahme:** Grafiken ergeben zusammen ein System; keine eingebrannten Beschriftungen und keine uneinheitlichen Rahmen.

### P3: Erstes hochwertiges und wirklich spielbares Nachtbrett

**Ergebnis:** Die Referenzrichtung läuft in Godot und bedient eine echte Nacht.

- [ ] Hintergrund und Ebenen in die vorhandene Cockpit-Szene einbauen.
- [ ] Rechteckige Personenbuttons zu Porträtplätzen mit Namensschild umgestalten; Identität, Reihenfolge und bestehende Signale erhalten.
- [ ] Brettlayout zuerst für 24 Personen auf 4:3 lösen, dann auf 6/12 Personen und breites Format anpassen.
- [ ] Große Textfläche durch kompakte Handlung ersetzen; ausführliche Erklärung über Details, ohne Pflichtaktionen zu verstecken.
- [ ] Werkzeuge am Rand oder in kompakter Leiste, keine neue feste breite Seitenspalte.
- [ ] Phasenanzeige, Zielmarkierung, tote Personen und gespeicherter Zustand verständlich darstellen.
- [ ] Anzeige-Timer für Tagphase und Diskussion (Entscheidung 01.10.2026, `DECISIONS.md`): von der Spielleitung einstellbar, pausierbar, rein anzeigend ohne Regelwirkung, Restzeit speicherstandtauglich. Platz im Brett: unten links unter der Phasenanzeige.
- [ ] Bedienung mit Totenreichkarten, Sitzkreiszielen und Linkshändermodus erhalten.
- [ ] Zwei repräsentative Größen sichtbar ansehen; einen Nachtablauf mit tatsächlichen Controls ausführen.

**Abnahme 2 durch Markus:** Ein Screenshot zeigt deutlich den gewünschten Stil, und eine Nacht lässt sich wirklich spielen. Bei 24 Personen sind Namen und Ziele brauchbar. Kein „fertig“ allein aufgrund des Flächenverhältnisses.

### P4: Tag, Morgen und vollständiger sichtbarer Spielablauf

**Ergebnis:** Die Partie bleibt auch außerhalb der Nacht im selben hochwertigen Stil.

- [ ] Deckungsgleiche Tagesversion des Dorfplatzes produzieren, daraus einen sparsamen Morgenübergang gestalten.
- [ ] Setup, Rollenverteilung und Sitzordnung stilistisch angleichen, ohne einen neuen Setup-Ablauf zu erfinden.
- [ ] Morgenbericht, Diskussion, Nominierung, Hinrichtung und Tagesend-Kartenfenster gestalten.
- [ ] Tod und Wiederbelebung klar kennzeichnen, ohne private Ursachen öffentlich zu machen.
- [ ] Siegansicht und Abschlussbericht im selben Design; erlaubte Rollenoffenlegung erst nach bestätigtem Spielende.
- [ ] Menü, Optionen, Lexikon, Regelbuch, Gruppen und Historie mit gemeinsamen Schriften/Rahmen nachziehen.

**Abnahme:** Eine gesamte Partie benutzt ein konsistentes System. Keine übrig gebliebenen riesigen Prototypdialoge im normalen Ablauf.

### P5: Personenporträts, Rollenbilder und Kartengestaltung vervollständigen

**Ergebnis:** Inhalt ist hochwertig dargestellt, ohne 152 individuelle Illustrationstypen erzwingen zu müssen.

- [ ] Neutrale Personenporträts auf eine für 24 Plätze brauchbare Auswahl erweitern. Namen bleiben primäre Identifikation.
- [ ] Alle 72 Rollen in der Rollenansicht mit passender Illustration oder bewusst konsistentem Symbolsystem versehen.
- [ ] Rollenfamilien in kontrollierten Chargen produzieren; Stil nach erster Charge abgleichen, nicht jedes Bild einzeln genehmigen lassen.
- [ ] Für 80 Totenreichkarten sechs Familienrahmen und eine gemeinsame Typografie entwickeln; Wirkungsicons helfen der Erkennbarkeit.
- [ ] Kartenvarianten beziehen Texte aus DE/EN, nicht aus Bildern. Individuelle Bilder nur dort, wo sie tatsächlich Verständlichkeit oder Charakter verbessern.
- [ ] Alle Rollen/Karten erhalten einen bewussten visuellen Zustand; verbleibende Platzhalter als solche offen auflisten.
- [ ] Privates Rollenbild, neutrales Personenporträt und erlaubte öffentliche Aufdeckung getrennt halten.

**Abnahme:** Keine unbeabsichtigt leeren Bilder, abgeschnittenen Texte oder Geheimnisse in öffentlichen Spielerplätzen. Keine Pflicht zu 80 teuren Einzelgemälden.

### P6: Lebendiger Dorfplatz und angenehme Bedienbewegungen

**Ergebnis:** Das Brett wirkt lebendig, auch wenn gerade niemand handelt.

- [ ] Sparsame Nebelschleier, Feuerflackern, einzelne Funken und Lichtbewegungen als getrennte Ebenen.
- [ ] Dezente Reaktion beim Antippen, Auswählen, Öffnen und Schließen von Karten.
- [ ] Tag-/Nachtübergang und Fokuswechsel ohne störenden Kameraschwenk.
- [ ] Keine Bewegung direkt hinter längeren Lesetexten; Effekte dürfen keine Touch-Eingaben abfangen.
- [ ] Kosmetischen Zufall getrennt vom gespeicherten Regelzufall behandeln.
- [ ] Reduzierte Bewegung: klare statische Zustände statt Dauernebel, Zoom oder Schütteln.
- [ ] Beim Wechsel in den Hintergrund aufwendige Effekte pausieren; bei Rückkehr nicht doppelt starten.

**Abnahme:** Sichtbar lebendig, gleichzeitig ruhig lesbar. Keine neue Spielregel und keine blockierte Aktion durch Animation.

### P7: Angriffe, Schutz, Todesmeldungen und Ereignisinszenierung

**Ergebnis:** Kurze, zielbezogene Ereignisse in der Richtung von Referenz 4.

- [ ] Vorhandene Ereignisse und öffentliche/private Sichten gezielt einer Darstellungswarteschlange zuordnen. Keine Effekte durch beliebige Beobachtung geheimer Zustandsfelder starten.
- [ ] Pro Hinweis festlegen: erlaubtes Publikum, Zeitpunkt, Zielperson, Typ, Unterbrechbarkeit und Verhalten beim Laden/Undo.
- [ ] Erst drei Sequenzen fertigstellen: bestätigter öffentlicher Tod, ausdrücklich erlaubter Schutzeffekt, Wiederbelebung.
- [ ] Danach Wolfsangriff: getrennte Wolfselemente, Bewegungsbahn, Partikel und Zielreaktion. Kein komplettes Referenzbild als starres Video über das Brett legen.
- [ ] Angriffsziel und tatsächliches Todesopfer unterscheiden. Ein geschützter Angriff darf nicht voreilig als Tod inszeniert werden.
- [ ] Morgendliche öffentliche Meldung verrät nicht automatisch „durch Wölfe“, wenn die Todesursache geheim bleiben muss. In diesem Fall neutrale Todessequenz.
- [ ] Restliche Rollen/Karten auf gemeinsame Effekttypen abbilden: Information, Bindung, Sperre, Verwandlung, Ziehung, Würfel, Sieg. Nur echte visuelle Sonderfälle eigens bauen.
- [ ] Mehrere Todesfälle geordnet zeigen; überspringen führt sofort zum aktuellen korrekten Zustand, ohne Befehle erneut auszuführen.
- [ ] Laden und normales Neuzeichnen spielen keine bereits bestätigte dramatische Sequenz ungewollt erneut ab.

**Abnahme:** Eine kontrollierte Kombination aus Angriff, Schutz und Folgetod zeigt die richtigen Personen und nur zulässige Informationen. Überspringen und reduzierte Bewegung funktionieren.

### P8: Musik, Atmosphäre, Signale und optionale Erzählerstimme

**Ergebnis:** Audio unterstützt die Spielleitung und bleibt separat steuerbar.

- [ ] Vorhandenen Audioplayer und Optionen erweitern statt konkurrierenden Audiomanager aufbauen.
- [ ] Kategorien: Musik, Dorfatmosphäre, Ereignisse, Bedienung, optionale Sprache; gemeinsame Lautstärke und stumm.
- [ ] Zunächst eine Nachtatmosphäre, eine Tagesatmosphäre und wenige wichtige Ereignissignale produzieren.
- [ ] Schleifen ohne hörbare Schnittkante; weich zwischen Phasen wechseln. Sprache senkt bei Bedarf Musik ab.
- [ ] Erzählertexte aus aktuellem Guide ableiten, nicht aus alten ungeprüften Vorlesetexten. DE/EN sauber zuordnen.
- [ ] Freie Spielernamen zunächst als Text für die Spielleitung behandeln. Keine zwingende Online-Spracherzeugung und keine Cloudabhängigkeit für Offline-Partien.
- [ ] Keine Rollen verratenden Klänge während verdeckter Zustände. Bereits bestätigte ausdrückliche öffentliche Ausnahmen wie den Fünf-Tote-Hinweis beachten.
- [ ] Unklare Altdateien nicht wiederverwenden. Produktion und kommerzielle Nutzungsrechte dokumentieren.

**Abnahme:** Eine echte Hörprobe bei normaler Lautstärke; alles bleibt ohne Ton vollständig bedienbar. Keine störend lauten Spitzen, keine mehrfach ausgelösten Signale.

### P9: Tablet-Performance, Touch und Unterbrechungen

**Ergebnis:** Ein auf realer Hardware brauchbarer Stand, kein reiner Desktop-Screenshot.

- [ ] Primärgerät: vorhandenes iPad. Modell und Betriebssystem vor Export konkret erfassen; keine Behauptung „alle Tablets“ aus zwei Fenstergrößen ableiten.
- [ ] Exportweg mit vorhandenem MacBook und aktueller Godot-/Apple-Werkzeugkette klären; Signierung und notwendige Konten prüfen. Keine kostenpflichtige Registrierung ohne Auftrag.
- [ ] Frühen Gerätebuild nach P3 versuchen, nicht bis zur gesamten Medienproduktion warten. P9 führt die endgültige Geräteprüfung zusammen.
- [ ] Touch-Ziele, langes Drücken nur falls bereits benötigt, sichere Abstände, Safe Area, Textskalierung und 24 Personen real prüfen.
- [ ] Hintergrund/Foreground, Gerätesperre, Audio-Unterbrechung und Fortsetzen einer offenen Auswahl prüfen.
- [ ] Leistung einmal an einer repräsentativen Szene messen. Entwurfsziel: flüssige 60 FPS, bei älteren unterstützten Geräten stabiles reduziertes Profil mit 30 FPS; keine Werte als gemessen ausgeben, bevor sie gemessen sind.
- [ ] Texturspeicher, Überblendungen, Partikel und Ladezeiten anhand realer Engpässe reduzieren. Keine pauschale Performance-Refaktorierung.
- [ ] Qualitätsstufen für Effekte und Texturen; Regeln und Informationsgehalt bleiben identisch.
- [ ] Android danach über ein benanntes Gerät oder einen verfügbaren Tester abdecken. Nicht vorhandene Hardware ehrlich als Lücke nennen.

**Abnahme:** Eingetragene Gerätedaten und konkrete Beobachtungen. Eine längere Partie beziehungsweise repräsentative Sitzung auf dem Zielgerät ohne unbedienbare Szene oder verlorenen Zustand.

### P10: Windows-Auslieferung und PC-Bedienung

**Ergebnis:** Ein startbarer Windows-Testbuild ohne Godot-Editor.

- [ ] Exportpreset im vorhandenen Projekt ergänzen oder nutzen; Laufzeitassets vollständig einbeziehen.
- [ ] Maus, Tastaturfokus, Escape/Zurück, Fenstergröße und Vollbild passend umsetzen, ohne Touchbedienung vorauszusetzen.
- [ ] Auf breiten Bildschirmen nicht sämtliche Texte und Porträts grenzenlos vergrößern.
- [ ] Spielstände in einem beschreibbaren Nutzerdatenverzeichnis, nicht neben einer eventuell schreibgeschützten EXE.
- [ ] Sauberer Start aus dem exportierten Paket und ein Fortsetzen-Test. Projektordner darf dafür nicht nötig sein.
- [ ] Versionskennung und kurze Startanleitung mitliefern. Keine Steam-Verfügbarkeit behaupten.

**Abnahme:** Export startet eigenständig, eine Partie lässt sich bedienen und fortsetzen. Steam-SDK, Store und Veröffentlichung sind ein späterer Auftrag.

### P11: Gebündelte Schlussabnahme und Übergabe

**Ergebnis:** Visuell zusammenhängender, spielbarer Offline-Stand mit ehrlichen Restpunkten.

- [ ] Eine reale Testpartie mit Gestaltung und Ton, einschließlich Karten, geheimer Information und öffentlicher Todesmeldung.
- [ ] Einen dichten 24-Personen-Zustand zusätzlich ansehen. Nicht sämtliche Rollen erneut spielen.
- [ ] Deutsch mit langem Namen/Text und einen englischen Ablauf prüfen.
- [ ] Markus bewertet Lesbarkeit, Orientierung, Atmosphäre und Tempo gesammelt.
- [ ] Konkrete Mängel nach schwerwiegend/funktional/kosmetisch priorisieren und eine begrenzte Korrekturrunde durchführen.
- [ ] Relevante Abschlussprüfungen gemäß Änderungsumfang, keine neue universelle Testkampagne.
- [ ] Roadmap, Assetregister, Startanleitung und offene Gerätelücken nachziehen.
- [ ] Ergebnis mit tatsächlichen Screenshots und kurzen Clips übergeben. Keine Aufnahme mit privaten Nutzerdaten veröffentlichen.

**Abnahme 3:** Markus kann eine Partie führen und erkennt die gewünschte visuelle Richtung im laufenden Spiel. Offene kosmetische Wünsche verhindern keine ehrliche Übergabe, Funktionsfehler schon.

## 7. Erste Produktionsliste

Die IDs sind vorgeschlagene Produktionsnamen, keine neuen Rollen-IDs. Bestehende passende IDs wiederverwenden.

| Gruppe | Erste Lieferung | Spätere Vervollständigung |
|---|---|---|
| Dorf | `village-night`, optionale Vordergrundebene | Deckungsgleiches `village-day`, Morgenübergang |
| Personen | 6 neutrale Porträts und ein lesbarer Token | Auswahl für 24 Plätze, bewusste Zuordnung unabhängig von Geheimrolle |
| Rahmen | Spielerrahmen, Namensschild, kompakte Aktionskarte | Detailkarte, Rollen- und Totenreichkartenfamilien |
| Symbole | Tag/Nacht, tot, Auswahl, Details, Werkzeuge | Konsistenter Satz für vorhandene Statusarten |
| Atmosphäre | Nebelebene, Feuer-/Lichtbaustein | Funken, dezente Vordergrundbewegung |
| Ereignisse | Tod, Schutz, Wiederbelebung | Wölfe links/rechts, Treffer, Verwandlung, Sieg, Karten/Würfel |
| Audio | Nacht/Tag-Ambiente und wenige Cues | Musik und freigegebene Erzählertexte |

Bildgenerierung kann Hintergründe und einzelne transparente Bestandteile liefern. Für glaubhafte laufende Wölfe braucht es zusätzlich eine konsistente Bewegungssequenz, ein animierbares 2D-Modell oder anderes geeignetes Animationsmaterial. Ein statisches Bild allein verspricht diese Qualität nicht. Die Wahl fällt nach dem ersten kurzen Effektprototyp, nicht durch vorzeitigen Kauf einer großen Bibliothek.

## 8. Test- und Sichtprüfplan ohne Übermaß

| Änderung | Notwendiger Nachweis |
|---|---|
| Hintergrund, Rahmen, Schrift | Import/Assetprüfung und eine gebündelte Sichtprüfung |
| Sitzlayout und Auswahl | Bestehende gezielte Layout-/Signaltests und Sichtprüfung bei 24 Personen |
| Private/öffentliche Darstellung | Gezielt erlaubte Daten und neutralen Rückweg prüfen |
| Ereigniswarteschlange | Einmal-Auslösung, richtige Zielperson, Abbruch/Laden ohne Doppelwirkung |
| Audio | Cue-Zuordnung und tatsächliche Hörprobe |
| Plattformexport | Reales Starten, kurze Bedienung und Fortsetzen auf dem Zielgerät |

- Ein bis zwei lokale Prüfrunden pro Paket sind der Normalfall. Keine getrennte Vollsuite für jede Auflösung, Sprache oder Textur.
- Vollsuite nur bei relevanter Integration, geändertem Kernverhalten oder am passenden Gesamtabschluss. Bereits grüne unveränderte Belege verwenden.
- Keine Tests schwächen, um eine kaputte Darstellung grün zu bekommen. Ein Test zur sichtbaren Pflichtaktion bleibt eine sichtbare Pflichtaktion.
- Screenshots müssen tatsächlich angesehen werden. „Screenshot gespeichert“ ist noch keine Sichtprüfung.
- Leistung und Touch nur auf tatsächlich geprüfter Hardware als bestätigt markieren.

## 9. Budget und Aufwand

Bestätigter bisheriger Planungsrahmen: bis 500 Euro. Bereits erfolgte Ausgaben sind unbekannt; vor jeder neuen Ausgabe verbleibenden Betrag prüfen. Bestehende Abos und kostenlose Werkzeuge zuerst nutzen. Keine Preise oder Tarifrechte aus veraltetem Wissen übernehmen, vor einer konkreten Buchung aktuell prüfen.

Vorgeschlagene Priorität innerhalb des RESTBUDGETS:
1. Zusammenhängendes Hintergrund-/UI-/Porträtpaket.
2. Ein überzeugender Angriffseffekt statt vieler halbfertiger Effekte.
3. Atmosphäre und wenige gute Sounds.
4. Sprecher und zusätzliche individuelle Kartenbilder erst danach.

Keine feste Tagesplanung. Aufwand hängt wesentlich von Qualität und Verfügbarkeit der Grafiken, Iterationen am Gerät und gewünschter Animationsqualität ab. Eine hohe Bildqualität ist kein automatisches Ergebnis einer bestimmten Zahl Claude-Stunden. P1–P3 müssen zuerst sichtbaren Nutzen liefern, bevor die gesamte Produktionsbreite gestartet wird.

## 10. Zustandsliste für die visuelle Umsetzung

Diese Liste ist eine Abdeckungsübersicht, keine Aufforderung zu einem separaten Testlauf pro Zeile.

- [ ] Startmenü, neue Partie, Gruppen und Fortsetzen.
- [ ] Spieler, Rollen, Verteilung, Sitzordnung, geheime Rollenkarten.
- [ ] Nachtbeginn, Rollenaufruf, Tarnaufruf und Zielauswahl.
- [ ] Keine zulässigen Ziele, freiwilliges Verzichten, mehrstufige Auswahl.
- [ ] Private Information, Sichtschutz und neutraler Rückweg.
- [ ] Morgenbericht mit erlaubten Namen und Rolleninformationen.
- [ ] Tagesdiskussion, Nominierung, Hinrichtung und verhinderte Hinrichtung.
- [ ] Kartenfenster morgens/abends, Auswahl, Tausch, Würfel und Anleitung für reale Handlung.
- [ ] Tote, Wiederbelebte, Schutz- und Bindungsinformationen jeweils nur im erlaubten Kontext.
- [ ] Spielleiterkorrektur, Protokoll, Undo/Redo, Speicherfehler und Wiederaufnahme.
- [ ] Siegkandidat, bestätigter Abschluss, Mitsiege, Historie und Export.
- [ ] Einstellungen, Bewegung reduziert, Audio stumm, Rechts-/Linkshand, DE/EN.

## 11. Aufgabenpakete für die Übergabe an Claude

Nach Planbestätigung in dieser Reihenfolge beauftragen, ohne jedes Detail erneut zu planen:

| Auftrag | Pakete | Sichtbares Ergebnis |
|---|---|---|
| 1 | P0 + P1 | Geprüfter Startpunkt und erster konkreter Nachtentwurf |
| 2 | P2 + P3 | Hochwertiges, tatsächlich spielbares Nachtbrett |
| 3 | P4 + Beginn P5 | Tag/Morgen, vollständiger Spielablauf und einheitliche Inhaltselemente |
| 4 | Rest P5 + P6 | Vollständige visuelle Inhaltsabdeckung und lebendiges Dorf |
| 5 | P7 + P8 | Gezielte Ereignisinszenierung und Audio |
| 6 | P9 + P10 + P11 | Geräteabnahme, Windows-Testbuild und fertige Offline-Übergabe |

Früher iPad-Exportversuch bereits nach Auftrag 2; nicht erst nach Auftrag 5. Unabhängige Assetproduktion kann parallel zur Programmierung erfolgen, aber kein zweiter Agent im gleichen Worktree ohne ausdrückliche Organisation.

Für jeden Abschlussbericht: Commit/Status, konkreter Startweg, sichtbare Änderung, Screenshots oder Clip, tatsächlich ausgeführte Prüfungen, Grenzen und nächster sinnvoller Schritt. Keine seitenlangen Wiederholungen aller Regeln.

## 12. Anschluss an Smartphone, externe Anzeige und Steam

Die visuelle Arbeit soll diese späteren Projekte nicht verbauen, implementiert sie aber nicht nebenbei:

- Externe Dorfansicht: öffentlicher Datenvertrag und neutrale Porträts wiederverwendbar halten. Eine lokale öffentliche Karte ist noch keine Netzwerkprojektion auf einen Fernseher.
- Smartphone/QR: sichere Empfängerzuordnung, geheime Inhalte, Verbindung, Wiederverbindung und Hosting beziehungsweise LAN-Konzept separat planen. Keine Geheimdaten im QR selbst voraussetzen.
- Online-Version: autoritativer Spielzustand, Sitzungen und Rechte erfordern einen eigenen Netzwerkauftrag. Der Offline-Regelkern allein ist noch kein Multiplayer-Server.
- Steam: Windows-Testbuild ist Vorstufe. Storematerial, aktuelle Vertriebsbedingungen, Signierung/Installer und gewünschte Steam-Funktionen separat prüfen und beauftragen.
- Weitere Tablets: Android-Export, reale Geräteabdeckung und unterstützte Mindestgeräte festlegen. „Alle Tablets“ bleibt eine Zielrichtung, kein unbegrenztes Kompatibilitätsversprechen.

## 13. Bestätigungsauftrag an Claude

Der folgende Text kann zusammen mit dieser Datei und dem Referenzordner übergeben werden:

```text
Prüfe diese visuelle Roadmap gegen den tatsächlichen Grimmhain-Projektstand und bestätige ihre Umsetzbarkeit. Jetzt noch nicht implementieren und nichts kaufen.

Lies nur die relevanten Projektanweisungen, Szenen, Assetunterlagen und Schnittstellen. Keine Testsuite und keine erneute Analyse aller Rollen/Karten.

Berücksichtige:
- Die riesige Textfläche des Istzustands muss einem tatsächlich sichtbaren Dorfplatz weichen.
- Die Zielbilder sind Gestaltungsreferenzen, keine vollständigen Laufzeitassets.
- Vorhandenen Regelkern und Godot-Stack erhalten.
- Sichtbare Tests sind jetzt erlaubt.
- Normalerweise maximal 1–2 notwendige lokale Prüfrunden pro Umsetzungspaket.
- Keine kleinteilige neue Fragenserie und keine automatische Parallelisierung.

Liefere höchstens:
1. Bestätigt / mit konkreten Änderungen machbar.
2. Tatsächliche technische Widersprüche, fehlende Bild-/Audiowerkzeuge und fehlende Gerätezugänge.
3. Welche vorhandenen Assets und Komponenten wiederverwendbar sind, ohne ungeklärte Freigaben zu behaupten.
4. Ob P0–P3 als erster sichtbarer Meilenstein sinnvoll abgegrenzt sind.
5. Den konkreten ersten Umsetzungsauftrag für P0/P1 samt Liefergegenstand und benötigten externen Grafiken.

Normale technische Detailentscheidungen selbst treffen. Änderungen an der Roadmap nur als konkrete Vorschläge nennen. Bestehende Dateien nicht ungefragt überschreiben, keine Umsetzung und kein Merge starten.
```

## 14. Fortschritt

| Paket | Status bei Erstellung | Ergebnis/Nachweis |
|---|---|---|
| P0 | erledigt 01.10.2026 | Startweg, 24er-Brett und Zielwahl gesehen, Totenreichkarten-Schalter vorhanden (Screenshots `p0-istzustand/`) |
| P1 | erledigt 01.10.2026 | Abnahme 1 erteilt; Mockup V2 nach Spielfeld.png, `mockup-v2/`, Art Direction `docs/assets/ART-DIRECTION-NIGHT-BOARD.md` |
| P2 | geplant | Grafikpaket fehlt |
| P3 | geplant | Hochwertiges Nachtbrett und Abnahme 2 fehlen |
| P4 | geplant | Tag/Morgen und restliche Ansichten gestalten |
| P5 | geplant | Bestehende Medien erst sichten, nicht pauschal als freigegeben zählen |
| P6 | geplant | Atmosphäre und Bewegungsführung |
| P7 | geplant | Sichere Ereignisinszenierung |
| P8 | geplant | Audio und Hörprobe |
| P9 | geplant | Reale Tablet-Abnahme |
| P10 | geplant | Eigenständiger Windows-Testbuild |
| P11 | geplant | Gemeinsame Schlussabnahme |

Diese Datei ist eine umsetzbare Produktionsroadmap. Exakte neue Methodensignaturen, Bilddateinamen im Katalog und Exportparameter werden pro Paket anhand des dann aktuellen Stands festgelegt, nicht ohne Codeprüfung vorab erfunden.
