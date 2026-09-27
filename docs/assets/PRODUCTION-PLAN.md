# Assets und Audio · Produktionsplan

**Stand:** 2026-09-26 · **Status:** Entwurf zur Product-Owner-Freigabe. Nichts davon ist beauftragt, gekauft oder in Godot eingebaut.
**Grundlagen:** [`INVENTORY.md`](INVENTORY.md), [`../godot-migration/05-visual-audio-direction.md`](../godot-migration/05-visual-audio-direction.md) (Leitbild, Cue-Tabelle, Budgets), [`../architecture/tablet-asset-spec.md`](../architecture/tablet-asset-spec.md), [`../masterplan/ASSET-REGISTER.md`](../masterplan/ASSET-REGISTER.md), [`../masterplan/BUDGET.md`](../masterplan/BUDGET.md), [`../../GRIMMHAIN-REVOLUTION-MASTERPLAN.md`](../../GRIMMHAIN-REVOLUTION-MASTERPLAN.md) Phasen 2, 6, 7, 9.
**Sprechertexte:** [`NARRATOR-SCRIPT.md`](NARRATOR-SCRIPT.md) · **Briefing erste Welle:** [`BRIEFING-WAVE-1.md`](BRIEFING-WAVE-1.md)

---

## 1. Leitplanken

1. **Nur registrierte Assets.** Jede Datei bekommt ihre Registerzeile, bevor sie ins Repository kommt. In `godot/` liegt nur, was `freigegeben` ist (`node tools/check-asset-register.js`).
2. **Herkunft bei der Erstellung sichern, nicht nachträglich.** Prompt, Werkzeug, Tarif, Datum, Rechnung und die zum Datum geltenden Nutzungsbedingungen werden sofort archiviert. Der Bestand zeigt, dass Nachträge kaum gelingen (208 Dateien ohne Nachweis).
3. **Strategie Q8 Option B (Empfehlung; Entscheidung offen, siehe Decision Log „Korrektur …“ vom 2026-09-27):** KI oder freie Bibliotheken für Platzhalter und Nebenelemente; Schlüsselassets (Porträts der 1.0-Rollen, Nachtmusik, Kern-Cues, Erzählerstimme) beauftragt, selbst erstellt oder mit belegtem kommerziellem Tarif erzeugt und nachbearbeitet.
4. **Kein Text im Bild.** Beschriftungen rendert Godot aus Übersetzungsschlüsseln. Das betrifft auch Karten und Tableaus.
5. **Geheimhaltung vor Wirkung.** Kein Asset und kein Cue darf ein geheimes Ereignis verraten, weder wen es betrifft noch dass es stattfand, bevor der Spielleiter es verkündet (`05` §1 Regel 3, Schnittstellenanforderungen in Abschnitt 6.4).
6. **Eigenständige Gestaltung.** Keine Elemente, Begriffe oder Formen aus Blood on the Clocktower (Empfehlung aus `05` §2.4 und `01` §6.2). Vorschlag: jeder Auftrag enthält diesen Satz.
7. **Budget.** Bestätigt ist ein Planungsrahmen bis 500 € (Decision Log „Gestaltung, Audio und Assets“). Kein Einzelkauf und kein Abonnement ist genehmigt. Die Aufteilung in Abschnitt 8 (zusammen 300 €) ist ein Vorschlag; kostenlose Werkzeuge haben Vorrang. Claude kauft nichts und schließt keine Abonnements ab.

## 2. Ablauf je Asset

```
Brief (ID, Zweck, Spezifikation, Referenz, Verbote)
  → Erstellung (Dienst/Person, Tarif belegt)
  → Nachweis archivieren (Prompt, Rechnung, Bedingungen als PDF, Rohdatei)
  → Technische Abnahme (Maße, Format, Lautheit, Schleife, 56-px-Test)
  → Registerzeile anlegen (Status: ki-nachgewiesen / ungeklärt)
  → Sicht- oder Hörprüfung durch Product Owner → po_freigabe eintragen → Status freigegeben
  → Übernahme ins Godot-Projekt in einem eigenen Arbeitspaket mit Tests
```

**Archiv außerhalb von Git** (z. B. `Grimmhain Assets/production/` lokal plus Cloud-Backup):

```
<asset-id>/
  brief.md          Auftrag, Referenzen, Verbote
  source/           Rohdateien, PSD/Projektdatei, Stems, unkomprimiertes Audio
  export/           Laufzeitdatei(en), identisch zur Repository-Datei
  provenance/       Prompt(s), Werkzeug + Version, Tarif, Rechnung, Bedingungen (PDF, Datum), C2PA-Manifest
  review.md         technische Abnahme, PO-Freigabe mit Datum
```

**Dateinamen:** ASCII-kebab-case, Asset-ID = Dateiname ohne Endung. Rollen über die technische ID aus DR-01 (`waldhexe`, `das-orakel`).

## 3. Produktionswellen

| Welle | Zeitpunkt (Masterplan) | Ziel | Kosten |
|---|---|---|---|
| **W0 · Vorbereitung** | jetzt, parallel zu Phase 2 | Formalien und Grundlagen, ohne die keine Produktion sinnvoll startet | 0 € |
| **W1 · Vertical Slice** | Phase 2 („Tag- und Nacht-Theme mit vorläufigen, lizenzklaren Assets") | Slice auf dem iPad mit minimalen, freigegebenen Assets; Audio stumm oder mit freien Cues | 0 € |
| **W2 · Stiltest** | nach bestandenem Phase-2-Gate | ein kleiner Satz echter Schlüsselassets als Stil- und Pipeline-Probe | Vorschlag ≤ 60 € |
| **W3 · Präsentationsqualität** | Phase 6 | P1-Assets aus `05` §7 für die Slice-Rollen, alle Kern-Cues, Musik, Erzähler | Rest des Rahmens |
| **W4 · 1.0-Inhalt** | Phase 7 | übrige 1.0-Rollen (20–30), Szenarien, Totenkarten-Motive | neue Budgetfreigabe |
| **W5 · Nachweisabschluss** | Phase 9 | jede ausgelieferte Datei `freigegeben`, Lizenzseite in der App, KI-Offenlegung für Stores | 0 € |

### W0 · Vorbereitung (ohne Kosten)

| # | Aufgabe | Ergebnis | Abnahme |
|---|---|---|---|
| W0-1 | OFL-Lizenztexte für Cinzel und IM Fell English aus der Originalquelle beschaffen, Bezugsquelle eintragen | **erledigt 2026-09-27:** `assets/fonts/OFL-*.txt`, `FONTS.md`, Status `lizenz-belegt` | PO-Freigabe → Status `freigegeben` |
| W0-2 | Lesetextschrift wählen (Vorschlag `05` §2.3: Source Sans 3 oder Alegreya Sans, beide OFL) | Entscheidung + Lizenzdatei | Lesbarkeit 14–20 sp auf 1024×768 |
| W0-3 | Art Bible, 2–3 Seiten: Farbpalette (`05` §2.1), Licht, Formensprache, Motivregeln, Verbote, 6–8 freigegebene Stilreferenzen aus dem Bestand | `docs/assets/ART-BIBLE.md` | PO-Freigabe |
| W0-4 | Cue-Liste aus `05` §4 finalisieren: IDs, Länge, Bus, Priorität, stumme Alternative (Abschnitt 6.3) | Tabelle in diesem Dokument freigegeben | PO-Freigabe |
| W0-5 | Sprechertexte DE/EN finalisieren und die offenen Fragen in `NARRATOR-SCRIPT.md` §6 entscheiden | freigegebene Texttabelle | PO-Freigabe, Probelesung am Tisch |
| W0-6 | PO beantwortet die Herkunftsfragen aus `INVENTORY.md` §6 | Stand laut Arbeitsauftrag 2026-09-27: kein zusätzlicher Nachweis bekannt; Nutzung der Legacy-Medien nicht freigegeben | `node tools/check-asset-register.js` grün |
| W0-7 | Q8 entscheiden | **offen** (Empfehlung B; ein Vermerk „entschieden“ wurde am 2026-09-27 korrigiert) | Eintrag des Nutzers im Decision Log |

### W1 · Vertical Slice (lizenzklar, ohne Kosten)

Ziel ist ein vollständig spielbarer Slice ohne ein einziges ungeklärtes Asset. Wo nichts Freigegebenes vorliegt, zeichnet Godot selbst.

| Bereich | Lösung für W1 |
|---|---|
| Hintergrund Tag/Nacht | Farbverlauf + Vignette als Shader aus den Farb-Tokens (`05` §2.1). Die vorhandenen `bg-village-*.webp` dienen als Referenz: Herkunftsnachweis fehlt, Nutzung nicht freigegeben. |
| Token, Ringe, Sitznummer | im Code gezeichnet (heute schon Spezifikation, `tablet-asset-spec.md` §3–4) |
| Fraktions- und Phasensymbole | einfache eigene Vektorsymbole (Wolfskopf, Haus, Stern, Mond, Sonne, Schild, Sanduhr, Siegel) als SVG, selbst gezeichnet; alternativ freie Sammlung mit geprüfter Lizenz (z. B. CC0; bei CC BY Namensnennung in der Lizenzseite) |
| Porträts | keine; Token zeigen Initialen und Fraktionssymbol |
| Schriften | Cinzel + Lesetextschrift nach W0-1/W0-2 |
| Audio | alle Busse und Regler verdrahtet (Masterplan Phase 2), Standard stumm; optional 5 Kern-Cues aus freier Bibliothek mit archivierter Lizenz |
| Erzähler | keiner; Vorlesetext steht auf der Ansagekarte |

### W2 · Stiltest (vorgeschlagenes Teilbudget ≤ 60 €)

Ein kleiner, vollständiger Durchstich, der Stil, Werkzeuge, Nachweisablage und Godot-Import gemeinsam prüft, bevor Geld in Masse fließt:

- 3 Rollenporträts (`werwolf`, `waldhexe`, `das-orakel`) nach Spezifikation, getestet bei ⌀ 56 px.
- 1 Hintergrund Nacht 2560×1600 mit Nebel-Ebene.
- 5 Kern-Cues (`cue-night-begin`, `cue-dawn`, `cue-death`, `ui-confirm`, `ui-error`).
- 1 Musik-Probe Nacht (60–90 s, schleifenfähig).
- 6 Erzählerzeilen DE und EN (Nachtbeginn, Morgen, Werwölfe erwachen/schlafen, Niemand ist gestorben, Spielende Dorf).

Entscheidungspunkt danach: Werkzeug und Anbieter für W3 festlegen oder wechseln.

## 4. Grafik

Spezifikationen aus `05` §7 und `tablet-asset-spec.md`, hier auf Wellen und Slice-Umfang heruntergebrochen. Menge für den Slice: 11 Rollen (`role-selection.md`).

| ID-Muster | Asset | Menge Slice / 1.0 | Spezifikation | Welle | Quelle (Empfehlung) |
|---|---|---:|---|---|---|
| `bg-village-{night,day,dawn}` | Dorfplatz | 3 / 3 | 2560×1600 WebP q85, ohne Alpha, sichere Ellipse 70×80 %, ohne Text | W2 (Nacht), W3 | KI mit belegtem Tarif + Nachbearbeitung, oder beauftragt |
| `layer-sky`, `layer-fog-{1,2,3}` | Himmel, Nebel | 4 / 4 | 2560×800 bzw. 2048×512 PNG-32, horizontal kachelbar | W3 | selbst (Noise-Textur, prozedural) |
| `portrait-<rollen-id>` | Rollenporträt | 11 / 20–30 | 512×512 WebP q85, Motiv im Kreis ⌀ 460, Augenlinie 40 %, kontrastreich bei ⌀ 56 px | W2 (3), W3 (8), W4 | Schlüsselasset: beauftragt oder KI + dokumentierte Nachbearbeitung |
| `night-icon-<rollen-id>` | Nachtleisten-Medaillon | 6 / ~20 | 256×256, duoton, kreissicher ⌀ 230 | W3 | selbst (Vektor) |
| `symbol-<name>` | Fraktions-/Phasen-/Statussymbole | ~16 / ~24 | SVG-Master, Import 128² | W1 (einfach), W3 (final) | selbst (Vektor) |
| `seal-<status>` | Statussiegel | 8 / ~20 | 256×256 PNG-32, einheitliche Leinwand | W3 | Neuaufbau im Stil der vorhandenen Siegel, falls deren Herkunft offen bleibt |
| `frame-<name>` | NinePatch-Rahmen | ~8 / ~8 | Ecke 64×64, Kante kachelbar, PNG-32 | W3 | selbst |
| `card-<rollen-id>` | Rollenkarte textfrei | 11 / 20–30 + Rückseite | 839×1400 WebP, Text im Code | W4 | aus Porträt-Master abgeleitet |
| `endgame-{wolves,village,solo,draw}` | Spielende-Tableau | 3 / 4 | 2560×1600 WebP | W3 | wie Hintergrund |
| `app-icon` | App-Icon, Splash | 1 / 1 | 1024² Master, Android-Adaptive 432² Vorder-/Hintergrund | W3 | selbst aus Logo-Neuzeichnung |
| `deathcard-category-<n>` | Totenkarten-Motive | – / 6 | 839×1400 ohne Text | W4 | offen |

**Abnahme Grafik:** Maße und Format exakt; Porträt-Testansicht bei 12/18/24 Spielern auf 1024×768 und 1280×800 (`tablet-asset-spec.md` §8); Kontrast von Symbolen ≥ 3:1 zum Untergrund; kein Text im Bild; Registerzeile vollständig.

## 5. Animation

Alle Effekte hängen an Kern-Ereignissen über `FxDirector` (`05` §3, `03` §3). Die meisten brauchen keine Bilddatei, sondern Tweens und Shader. Jede Zeile braucht eine Reduced-Motion-Fassung: 150-ms-Überblendung ohne Bewegung (`05` §5).

| ID | Ereignis | Technik | Benötigte Assets | Welle |
|---|---|---|---|---|
| `fx-night-begin` | `PhaseChanged → NIGHT` | Tween auf Himmelsgradient-Shader, Nebel-Einblendung | `layer-sky`, `layer-fog-*` | W1 (nur Farbe), W3 |
| `fx-dawn` | `PhaseChanged → DAWN` | Gradient-Shader Blau → Bernstein 2,5 s | `layer-sky` | W1 (nur Farbe), W3 |
| `fx-step-start` | `StepBegun` | Ansagekarte blättert (250 ms), Nachtleiste gleitet | keine | W1 |
| `fx-target-select` | Ziel gewählt | pulsierender Goldring, diskret | keine | W1 |
| `fx-protect` | `ProtectionSet` | Siegel prägt sich in den Token-Rand, Schimmer auf der Karte | `seal-protected` | W3 |
| `fx-attack` | Wolfswahl bestätigt | Kratzspuren auf der Ansagekarte, nie am Token | `fx-claw` (PNG-32) | W3 |
| `fx-kill-prevented` | `KillPrevented` | Siegel zerspringt, nur private Spalte | Partikel-Sprite | W3 |
| `fx-death` | Tod beim Verkünden | Kerze erlischt, Rauchfaden, Porträt entsättigt | `fx-smoke` | W3 |
| `fx-chain-death` | Folgetod, Reaktion | `Line2D`-Faden reißt | keine | W3 |
| `fx-nomination` | `NominationRecorded` | Siegel fällt auf Token | `seal-nominated` | W3 |
| `fx-execution` | `ExecutionConfirmed` | wie Tod + Silhouette im Hintergrund | Silhouette | W3 |
| `fx-special-rescue` | Spiegelwolf-Umleitung beim Verkünden | Kette zerspringt im Zentrum | Kettensprite | W3 |
| `fx-role-change` | `RoleChanged` | Münzdrehung des Porträts, privat | keine | W3 |
| `fx-endgame` | `WinConfirmed` | Tableau + Asche-/Blattpartikel, überspringbar | `endgame-*` | W3 |
| `fx-undo`, `fx-error` | Undo, abgelehnter Befehl | Flirren bzw. 3-px-Schütteln | keine | W1 |

**Regeln:** Eingaben bleiben während jeder Animation möglich; neue Eingabe beendet laufende Übergänge. Bei Undo und Replay werden Ereigniseffekte nicht erneut abgespielt. Budgets aus `05` §6 (≤ 300 Partikel, 60 fps, Low-Processor-Mode im Leerlauf).
**Abnahme Animation:** Messlauf 10 Minuten Nacht auf dem Referenzgerät; Reduced-Motion-Durchlauf; Geheimhaltungsprüfung aus 2 m Abstand (erkennt ein Zuschauer, welcher Token betroffen ist?).

## 6. Audio

### 6.1 Technische Norm

| Klasse | Format im Projekt | Lautheit | Sonstiges |
|---|---|---|---|
| Musik | OGG Vorbis q5, 48 kHz Stereo | −16 LUFS integriert, Spitze −1 dBTP | nahtlose Schleife, Schleifenpunkte dokumentiert |
| Ambiente | OGG Vorbis q4, 48 kHz Stereo | −24 LUFS | Schleife 60–90 s, keine auffälligen Einzelereignisse |
| Cues, UI | WAV 16 bit oder OGG, 48 kHz | −18 LUFS, Spitze −1 dBTP | ≤ 2,5 s, Stille am Anfang ≤ 10 ms |
| Erzähler | WAV 24 bit 48 kHz Master, OGG im Projekt | −18 LUFS | Mono, trocken, Rauschen ≤ −60 dBFS |

Busse: `Master` → `Music`, `Ambience`, `Cues`, `UI`, zusätzlich `Voice` für den Erzähler [E, Ergänzung zu `05` §4]. Ducking: `Cues` und `Voice` senken `Music` um 6 dB.

### 6.2 Musik und Ambiente

| ID | Inhalt | Länge | Welle | Quelle |
|---|---|---|---|---|
| `music-night` | Nachtmusik, empfohlener Ersatz für `legacy-night-music` | Schleife 3–5 min | W2 (Probe), W3 | beauftragt, eigene Produktion oder KI-Musikdienst mit kommerziellem Tarif; Bedingungen zum Kaufdatum archivieren |
| `ambience-night` | Wind, entfernte Eule, Grillen | 60–90 s | W3 | freie Bibliothek mit archivierter Lizenz oder Feldaufnahme |
| `ambience-day` | Dorfgemurmel leise, Vögel | 60–90 s | W3 | wie oben |
| `fanfare-{wolves,village,solo,draw}` | Spielende | 4–6 s | W3 | mit `music-night` aus einer Hand |

Die 60-Minuten-Datei `Nachtmusik.mp3` wird nicht ersetzt, sondern abgelöst: Eine gute 3–5-Minuten-Schleife genügt und spart rund 55 MB.

### 6.3 Cues

Aus `05` §4 abgeleitet. Priorität: höhere Zahl unterbricht niedrigere. Jeder Cue hat eine stumme Alternative, weil „Stumm im Spiel" jederzeit möglich ist. Spalte „Auslöser“ nach den Schnittstellenanforderungen in 6.4: Nur öffentliche Phasenübergänge und ausdrückliche öffentliche Verkündungen erzeugen automatisch hörbaren Klang.

| ID | Ereignis | Klang | Bus | Prio | Welle | Stumme Alternative | Auslöser |
|---|---|---|---|---:|---|---|---|
| `cue-night-begin` | Nachtbeginn | tiefer Glockenschlag | Cues | 3 | W2 | Animation `fx-night-begin` | freigegebener Phasenübergang |
| `cue-dawn` | Morgengrauen | Hahn fern, Vogelchor | Cues | 3 | W2 | `fx-dawn` | freigegebener Phasenübergang |
| `cue-step-start` | Rollenzug beginnt | Seitenrascheln | UI | 1 | W3 | Karte blättert | keiner automatisch; nur wenn auch Tarnaufrufe identisch klingen |
| `cue-target-select` | Ziel gewählt | Holzklick | UI | 1 | W3 | Goldring | keiner (geheime Eingabe) |
| `cue-protect` | Schutz gesetzt | gläserner Ton, sehr leise | Cues | 2 | W3 | Siegel | keiner (geheimes Ereignis) |
| `cue-attack` | Wolfswahl | gedämpftes Knurren | Cues | 2 | W3 | Kratzspuren | keiner (geheimes Ereignis) |
| `cue-kill-prevented` | Schutz greift | weiches Glasklirren | Cues | 2 | W3 | Siegel zerspringt | keiner (geheimes Ereignis) |
| `cue-death` | Tod beim Verkünden | tiefer Gong, Windhauch | Cues | 4 | W2 | Kerze erlischt | öffentliche Verkündung des Todes, nie der interne Tod |
| `cue-chain-death` | Folgetod | reißende Saite | Cues | 4 | W3 | Faden reißt | öffentliche Verkündung |
| `cue-timer-tick` | letzte 10 s Diskussion | Uhrticken | UI | 1 | W3 | pulsierender Ring | öffentlicher Tagestimer |
| `cue-timer-end` | Timer abgelaufen | Glocke (ersetzt `Ruhe.mp3`) | Cues | 3 | W3 | Ring + Hinweiszeile | öffentlicher Tagestimer |
| `cue-nomination` | Nominierung | Holzhammer dumpf | Cues | 2 | W3 | Siegel fällt | öffentlich erfasste Nominierung |
| `cue-execution` | Hinrichtung bestätigt | Trommelschlag, Menge verstummt | Cues | 4 | W3 | `fx-execution` | öffentliche Verkündung |
| `cue-special-rescue` | Sonderrettung | metallisches Reißen | Cues | 4 | W3 | Kette zerspringt | öffentliche Verkündung |
| `cue-role-change` | Rollenwechsel (privat) | Chorhauch | Cues | 2 | W3 | Münzdrehung | keiner (geheimes Ereignis) |
| `cue-undo` | Undo | Rückspul-Wisch leise | UI | 1 | W3 | Flirren | Eingabe; in geheimen Schritten stumm |
| `ui-confirm` | Bestätigen | kurzer Holzton | UI | 1 | W2 | Button-Rückmeldung | Eingabe; in geheimen Schritten stumm |
| `ui-error` | Befehl abgelehnt | tiefer Holzklopfer | UI | 1 | W2 | Schütteln + Grundzeile | Eingabe; in geheimen Schritten stumm |
| `ui-tap` | allgemeiner Tap | sehr leiser Klick | UI | 0 | W3 | – | Eingabe; in geheimen Schritten stumm |

19 Cues für den Slice. Totenkarten-Cues (6) folgen in W4 mit dem Totenkarten-System. Rollen-Leittöne (`05` §4, „optional") sind nicht eingeplant.

**Abnahme Audio:** Lautheitsmessung je Datei (Protokoll im Archiv); Schleifen ohne hörbaren Sprung bei 10 Durchläufen; Hörtest am Tisch mit Tablet-Lautsprecher bei 50 % Lautstärke; kein Cue verrät ein privates Ereignis vor der Verkündung.

### 6.4 Schnittstellenanforderungen an das spätere Audio-System

Nur Anforderungen; es gibt noch keinen `AudioDirector` und keine Anbindung an den Regelkern. Hintergrund: Das Tablet steht offen auf dem Tisch. Auch ein Todes-, Schutz- oder Fehlerklang ohne Personenbezug kann verraten, dass ein geheimes Ereignis stattfand.

1. **Geheime Kernereignisse lösen keinen öffentlichen Klang aus.** Ereignisse mit Sichtbarkeit Spielleiter oder handelnde Person (`rules-register.md` G-INF-3), etwa `ProtectionSet`, `KillPrevented`, `WitchActed`, `RoleChanged`, `SeatDied` während der Nacht, sind für das Audio-System keine Auslöser.
2. **Ein Todesklang gehört zur ausdrücklichen öffentlichen Verkündung,** also zu der Spielleiter-Aktion, mit der ein Tod öffentlich gemacht wird (Morgenbericht, bestätigte Hinrichtung), nicht zum internen Ereignis `SeatDied`.
3. **Öffentliche Phasenklänge folgen freigegebenen Phasenübergängen,** also nur öffentlichen `PhaseChanged`-Ereignissen, nicht internen Zwischenständen.
4. **Öffentliche Erzählertexte enthalten keine geheimen Namen, Rollen oder Ergebnisse** (Regeln in `NARRATOR-SCRIPT.md` §1).
5. **Bedienklänge (Bestätigen, Fehler, Tap, Undo) sind in geheimen Schritten stumm;** die Rückmeldung ist dort rein visuell.
6. **Fehlende oder nicht ladbare Audiodateien blockieren die Bedienung nie.** Ein fehlender Cue wird still übersprungen und höchstens im Entwicklerprotokoll vermerkt; kein Dialog, keine Wartezeit.
7. Undo und Replay spielen keine Ereignisklänge erneut ab (`05` §3).

## 7. Sprechertexte und Erzählerstimme

**Umfang:** 1 Erzählerstimme DE, 1 Erzählerstimme EN (Decision Log „Gestaltung, Audio und Assets"). Texte, IDs, Regeln und offene Fragen: [`NARRATOR-SCRIPT.md`](NARRATOR-SCRIPT.md). Der Slice-Katalog umfasst 36 Zeilen je Sprache; mit einer Zweitvariante für die sechs häufigsten Zeilen 42.

**Grundsatz:** Der Erzähler ist optional. Die App bleibt ohne Stimme voll bedienbar, weil derselbe Text als Vorlesetext auf der Ansagekarte steht (Untertitel = Vorlesetext = Aufnahme). Nie Text-to-Speech als Pflicht (`05` §4).

| Option | Kosten | Rechte | Aufwand | Einschätzung |
|---|---|---|---|---|
| A · Product Owner oder Bekannte sprechen selbst | 0 € (+ Mikrofon, falls nötig) | eigenes Werk, schriftliche Einwilligung der sprechenden Person archivieren | hoch: Raum, Schnitt, Konsistenz | gut für W2-Probe |
| B · Beauftragte Sprecherin oder Sprecher | nach Angebot; liegt voraussichtlich über dem Rahmen aus `BUDGET.md` | Buy-out-Vertrag für Spiel, Stores, Werbung | mittel | beste Qualität, sprengt ohne neue Freigabe den Rahmen |
| C · KI-Stimme mit kommerziellem Tarif (z. B. ElevenLabs, `BUDGET.md`) | 50–100 € (`BUDGET.md`) | Tarifbedingungen zum Datum archivieren; nur Stimmen mit geklärten Stimmrechten | niedrig | im Budget; Store-Offenlegung nötig |

**Empfehlung:** W2 mit Option A als Probe (0 €); W3 mit Option C, falls die Probe zeigt, dass eine Stimme das Spiel verbessert; Option B erst mit neuer Budgetfreigabe.

**Aufnahmespezifikation:** je Zeile eine Datei `vo-<sprache>-<schlüssel>.wav` (z. B. `vo-de-role-waldhexe-call.wav`), 0,3 s Stille vorn und hinten, ruhiges Erzähltempo (ca. 130 Wörter/min DE), keine Musik unterlegt; Varianten mit Suffix `-v2`.

## 8. Budget

Bestätigter Planungsrahmen: bis 500 €. Die Beträge unten sind **vorgeschlagene Teilbudgets**, keine Zusagen und keine genehmigten Käufe. Jede Ausgabe durchläuft die dortige Kaufcheckliste und wird in der Registerzeile verknüpft.

| Posten | Welle | Vorschlag |
|---|---|---:|
| W0, W1 | – | 0 € |
| W2 Stiltest (Bild- oder Musikdienst für einen Monat) | W2 | 60 € |
| Grafik-/KI-Dienste und Nachbearbeitung | W3 | 60 € |
| Musik und Cues (Dienst oder Bibliothek) | W3 | 80 € |
| Erzähler DE/EN (Option C) | W3 | 100 € |
| **Summe Assets und Audio** | | **300 €** |
| Reserve Plattform- und Signaturkosten, Testgerät (`BUDGET.md`) | Phase 8–9 | 200 € |

Nicht enthalten: Option B für den Erzähler, beauftragte Illustration der 20–30 Porträts für 1.0. Beides braucht eine neue Budgetentscheidung nach dem Stiltest.

## 9. Risiken

| Risiko | Wirkung | Gegenmaßnahme |
|---|---|---|
| Herkunft auch neuer Assets geht verloren | kein Release | Archivstruktur aus Abschnitt 2 vor dem ersten Auftrag anlegen; Register-Prüfung im Commit-Ablauf |
| Tarifbedingungen ändern sich | Rechte unklar | Bedingungen zum Erstellungsdatum als PDF archivieren |
| Uneinheitlicher Stil über mehrere KI-Sitzungen | Qualitätseindruck | Art Bible (W0-3), feste Referenzbilder, ein Werkzeug je Asset-Klasse |
| Porträts bei ⌀ 56 px unlesbar | Bedienbarkeit | Pflichttest in der Abnahme, Stiltest W2 vorher |
| Audio verrät geheime Ereignisse | Spielbruch | Geheimhaltungsspalte der Cue-Tabelle, Test am Tisch |
| Budget reicht nicht für 20–30 Porträts | Verzögerung 1.0 | Stiltest W2 liefert Stückkosten; Entscheidung danach |
| Repository wächst mit Rohdateien | langsame Klone | nur Exporte versionieren; Musik als 3–5-min-Schleife |

## 10. Nächste einzelne Arbeitspakete

1. **W0-1 Schriftlizenzen:** Lizenztexte liegen bei; offen ist nur die PO-Freigabe der vier Registerzeilen (`FONTS.md` §5).
2. **W0-5 Sprechertexte:** offene Fragen in `NARRATOR-SCRIPT.md` §6 entscheiden, Texte freigeben.
3. **W0-3 Art Bible** schreiben.
4. **W1 Audio-Technik in Godot:** `AudioDirector`, Busse, Regler, stummer Standard, Cue-Katalog als Daten, Tests zuerst. Keine Mediendateien nötig.
