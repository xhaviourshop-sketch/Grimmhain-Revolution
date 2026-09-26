# 06 · Umsetzungs-Roadmap

**Stand:** 2026-09-26 · Kennzeichnung: **[B]** Beobachtung, **[S]** Schlussfolgerung, **[E]** Empfehlung.
Aufwände sind **grobe Schätzungen in konzentrierten Entwicklungstagen** (≈ 6 h), keine Zusagen.

---

## 1. Grundsatz

- **Vertikale Slices:** Jeder Slice endet mit etwas Spielbarem auf einem echten Tablet. Kein monatelanger Kernbau ohne Oberfläche.
- **Erst Regeln + Platzhalter, dann Präsentation.** Grafik und Effekte ab Slice 5, wenn Kern und Bedienung stehen.
- **Legacy bleibt spielbar** bis Godot die Kernstrecke nachweislich besser kann. Legacy erhält in dieser Zeit nur kritische Fehlerbehebungen (Frage Q9).
- **Jede Rolle hat einen Automatisierungsstatus** (`verified` / `partial` / `manual`). Nicht abgenommene Rollen laufen als „manuell geführt": Die App zeigt Ansage und Erinnerung, der SL setzt Folgen per Korrektur.

---

## 2. Stufen des Produkts

| Stufe | Definition |
|---|---|
| **Tablet-MVP** | Android-Tablet, offline. Setup mit Gruppe/Akt I, Rollen zeigen, geführte Nacht, Morgen mit Reaktionen, Tag mit Direkt-Hinrichtung, Sieg. **Alle 17 Rollen aus Akt I automatisiert und getestet**, übrige Rollen „manuell geführt". Speichern jeder Aktion, Undo/Redo, Crash-Recovery. Platzhaltergrafik + 5 Kern-Cues. DE (EN je nach Q6). |
| **Version 1.0** | Alle 72 Rollen verifiziert oder bewusst als manuell markiert, alle Akte, Totenkarten-Assistent, Stimmfunktion nach Q2, finale Art-Direction mit Cues, Ambiente, DE+EN vollständig, iPad (nach Q7), Pilot mit ≥ 5 externen SL bestanden. |
| **Steam-/Online-Stufe** | Desktop-Build, Steam (Achievements, Cloud-Saves), öffentliche Zweitanzeige, danach LAN-Spielerclients, dann Online-Relay. Jeweils eigene Go-Entscheidung. |

---

## 3. Slices

### Slice 0 · Grundlagen festzurren (2–4 Tage)

| | |
|---|---|
| Abhängigkeiten | keine |
| Deliverables | Antworten auf Q1–Q4 und Q6–Q9 (`07`); eingefrorene Regelliste Akt I; Godot-Version gepinnt; Referenz-Tablet beschafft; `assets/PROVENANCE.md` angelegt |
| Akzeptanz | Jede „widersprüchlich"-Zeile aus `04` für Akt I hat eine Entscheidung |
| Tests | – |

### Slice 1 · Headless-Kern-Skelett (6–9 Tage)

| | |
|---|---|
| Abhängigkeiten | Slice 0 (nur Godot-Version zwingend) |
| Deliverables | Godot-Projekt nach `03` §2; `GameState`, `Seat`, `Effect`, `SeededRng`, `PhaseMachine` (Setup → Nacht → Morgen → Tag); Befehle `StartGame`, `StartNight`, `AnswerPrompt`, `EndNight`, `DecideExecution`, `EndDay`; `KillPipeline` ohne Rollen-Abfangregeln; `WinRules` Dorf/Wolf; JSON-Codec mit `schema_version`; Test-Runner headless; CI |
| Rollen | Werwolf, Dorfbewohner |
| Akzeptanz | Ein Spiel Werwolf gegen Dorf läuft headless per Szenario-JSON bis zum Sieg; Save → Load → identischer Hash; gleiche Befehle + Seed → identische Ereignisse |
| Tests | S-WIN-01/02, S-SAVE-01, Property-Test Replay |

### Slice 2 · Walking Skeleton auf dem Tablet (6–10 Tage)

| | |
|---|---|
| Abhängigkeiten | Slice 1 |
| Deliverables | Screens Start, Setup (Namen als Liste, Rollenchips, zufällige Verteilung), Cockpit mit Sitzkreis (Kreise + Namen + Nummern), Nachtleiste, Ansagekarte (3 Zonen), Kopfzeile mit Speicherstatus; Android-Export; Rollen Schutzengel, Das Orakel, Waldhexe |
| Akzeptanz | Auf dem Referenz-Tablet: Setup → Nacht → Morgen → Tag → Sieg mit 8 Spielern ohne Absturz; alle Touch-Ziele ≥ 48 dp; App-Kill und Neustart setzt am selben Schritt fort |
| Tests | S-ROLE-04/08/11, Layout 12 Spieler, manueller Gerätetest |

**Stop/Go 1:** Läuft die Kernstrecke flüssig auf dem schwächsten Referenz-Tablet (< 100 ms Rückmeldung, 60 fps)? Wirkt die Ansagekarte im Test mit 1–2 Personen verständlicher als die Legacy-App? *No-Go* → Architektur oder UI-Ansatz korrigieren, bevor Rollen skaliert werden.

### Slice 3 · Korrektheit und Sicherheit (8–12 Tage)

| | |
|---|---|
| Abhängigkeiten | Slice 2 |
| Deliverables | Vollständige Abfangreihenfolge (`04` §C.1) als Rahmen; Reaktions-Warteschlange; mehrstufige Prompts mit Abbruch; Undo/Redo 20 Schritte mit Klartext; Checkpoints; Rotation + Korrupt-Erkennung; Unterbrechungszettel; SL-Korrektur über Pipeline; Ereignisprotokoll persistent; Golden-Harness gegen Legacy (Puppeteer) |
| Rollen | Sensenträger, Loki, Der Weise, Ritter |
| Akzeptanz | Abbruch jeder mehrstufigen Aktion lässt Zustands-Hash unverändert; Undo aller Befehle ergibt Ausgangszustand; beschädigte Datei wird erkannt und die Vorversion geladen |
| Tests | S-UNDO-*, S-SAVE-*, S-KILL-01..05, S-ROLE-01/06/22/47 (Golden) |

### Slice 4 · Akt I komplett = Tablet-MVP (8–12 Tage)

| | |
|---|---|
| Abhängigkeiten | Slice 3 |
| Deliverables | Übrige Akt-I-Rollen: Spürhund, Wolfskind, Nachtwächter, König Lykaon, Rachsüchtiger Wolf, Selbstmörder, Rattenfänger, Die Gebundenen; Übergabe-Modus Rollen zeigen; Morgenbericht öffentlich/privat; Diskussionstimer; Nominierung; „keine Hinrichtung"; Spielende mit Auslöser; gespeicherte Gruppen; 5 Kern-Cues; Nachtmusik (Q8); Übrige 55 Rollen als „manuell geführt" mit Ansagetext |
| Akzeptanz | Tablet-MVP-Definition (Abschnitt 2) erfüllt; 3 vollständige Testrunden mit echter Gruppe ohne Entwicklerhilfe; keine Namensüberlappung bei 12/18/24 Spielern auf 1024×768 und 1280×800 |
| Tests | alle Akt-I-Szenarien Golden, Layout-Tests, Gerätetest offline (Flugmodus) |

**Stop/Go 2 (MVP-Abnahme):** Würden die Testleiter die Godot-App statt der Web-App nutzen? Gibt es Fehler mit Spielstandsverlust oder falscher Auflösung? *Go* → Legacy einfrieren; *No-Go* → Slice 3/4 nacharbeiten.

### Slice 5 · Präsentationsqualität (10–15 Tage, parallel Asset-Produktion)

| | |
|---|---|
| Abhängigkeiten | Slice 4; Assets P1 aus `05` |
| Deliverables | Theme mit NinePatch-Rahmen; Hintergründe mit Himmel/Nebel-Ebenen; Porträts (mindestens Akt I final); Cue-System nach `05` §4; Ambiente-Schleifen; Fallback-Stufen; Dunkelraum-Modus; Linkshänder-Spiegelung; „Bewegung reduzieren" |
| Akzeptanz | Performance-Budgets `05` §6 auf Referenzgerät; kein Effekt verzögert Eingaben (Messung); Geheimhaltungsregel: Test mit Zuschauern erkennt aus Effekten keine Betroffenen |
| Tests | Performance-Log, A/B-Probe mit 2 Gruppen (Effekte an/aus) |

### Slice 6 · Akte II–IV in Chargen (20–35 Tage)

| | |
|---|---|
| Abhängigkeiten | Slice 3 (Kern), Q1-Entscheidungen je Rolle |
| Deliverables | Rollen in 4 Chargen nach Mechanik-Familie: (a) Info-Rollen, (b) Schutz/Schilde/Umlenkung, (c) Rollenwechsel/Wiederbelebung, (d) Solos mit Siegen. Je Charge: Behavior, Texte DE/EN, Szenarien, Golden wo verifiziert |
| Akzeptanz | Jede Rolle: Normalfall, Randfall, Reload, Undo getestet; Status in `RoleDef.automation_status` gepflegt; Kombinationen aus `04` §C (konkurrierende Abfangregeln) grün |
| Tests | S-ROLE-* aller Akte, S-KILL-06..16, S-WIN-* |

### Slice 7 · Tag, Totenkarten, Sprache (10–16 Tage)

| | |
|---|---|
| Abhängigkeiten | Q2, Q3, Q6 |
| Deliverables | Stimmfunktion (falls Q2), Totenkarten-Assistent (Anzeige, Checkliste, Ausspielen, Kartenschlucker), 80 Karten EN, Chronik und Export, Aufmerksamkeitsliste, Nacht-Probe |
| Akzeptanz | 80/80 Karten DE/EN ohne Mischtext; Kartenzuweisung reproduzierbar per Seed |
| Tests | S-CARD-*, S-DAY-*, Content-Lint |

### Slice 8 · Release 1.0 (8–15 Tage + 3–4 Wochen Pilot)

| | |
|---|---|
| Deliverables | iPad-Build (Q7), Store-Einträge, Hilfe, bekannte Grenzen, Versionshinweise, Lizenzen (OFL, Audio, KI-Offenlegung), Pilot mit ≥ 5 SL und ≥ 10 Runden |
| Akzeptanz | Keine offenen Fehler mit Spielstandsverlust, Geheimnisoffenlegung oder falscher spielentscheidender Auflösung; ≥ 4 von 5 SL wollen erneut nutzen |

**Stop/Go 3 (Release):** Pilotkriterien erfüllt? Sonst Umfang (Rollen als „manuell") reduzieren statt verschieben.

### Slice 9+ · Desktop, Steam, Online (nach eigener Entscheidung)

1. Desktop-Build mit Tastatur/Maus und öffentlicher Zweitanzeige (5–8 Tage).
2. Steam-Integration über `Platform`-Autoload (5–10 Tage + Store-Prozess).
3. LAN-Spielerclients mit Projektionen (15–25 Tage).
4. Online-Relay, Accounts nur bei belegtem Bedarf.

---

## 4. Abhängigkeitsübersicht

```
S0 ─► S1 ─► S2 ─(Stop/Go 1)─► S3 ─► S4 ─(Stop/Go 2 = MVP)─► S5 ─┐
                                 └──────────► S6 (Chargen) ─────┼─► S8 ─(Stop/Go 3)─► S9+
                                               S7 (nach Q2/Q3) ─┘
Asset-Produktion (05 §7) läuft ab S2 parallel; P1-Assets müssen zu S5 vorliegen.
```

**Summe bis 1.0:** ca. 78–128 Entwicklungstage plus Pilot. [S] Bei Teilzeitkapazität ist 1.0 bis März 2027 (Deadline aus `ROADMAP.md`) nur mit reduziertem Rollenumfang realistisch; der Tablet-MVP (S0–S4, ca. 30–47 Tage) ist das belastbarere Zwischenziel.

---

## 5. Risiken und Gegenmaßnahmen

| Risiko | Wahrscheinlichkeit / Wirkung | Gegenmaßnahme |
|---|---|---|
| Regelwidersprüche verzögern jede Rolle | hoch / hoch | Q1 vorab als Tabelle entscheiden; Default „Legacy-Verhalten, dokumentiert" |
| Godot-Neuling-Kurve beim PO | mittel / mittel | Kern bewusst einfach (Hooks, JSON); Szenario-Tests lesbar ohne Programmierkenntnis |
| Legacy-Bugs werden als Golden-Referenz übernommen | mittel / hoch | Golden nur für *verifiziert*; Bugs aus `04` explizit als Abweichung markieren |
| Performance auf alten Tablets | mittel / mittel | Compatibility-Renderer, Fallback-Stufen, Stop/Go 1 |
| Parallelentwicklung Legacy + Godot | mittel / hoch | Legacy nur kritische Fixes (Q9) |
| Asset-Lizenzen (Nachtmusik, KI-Bilder) blockieren Release | mittel / hoch | Provenance-Log ab S0; Ersatz-Musik rechtzeitig beauftragen |
| Scope-Druck durch 72 Rollen + 80 Karten | hoch / hoch | „Manuell geführt" als offizieller Status; MVP = Akt I |
| iOS-Export erfordert macOS/Apple-Konto | sicher / mittel | Android zuerst; iPad in S8 |
| Determinismus bricht durch unsortierte Iteration | niedrig / hoch | Property-Test Replay in CI ab S1 |

---

## 6. Der nächste einzelne Arbeitsschritt

**Slice 1, erster Teil: Godot-Projekt `godot/` im Repository anlegen und den headless Regelkern für „Werwolf gegen Dorfbewohner" bauen.**

Konkret:
1. Godot-Version pinnen (in `godot/README.md`), Projektstruktur nach `03` §2 anlegen, statische Typisierung erzwingen.
2. `GameState`, `Seat`, `SeededRng`, `PhaseMachine`, `KillPipeline` (nur Grundschritt), `WinRules` (Dorf/Wolf) implementieren.
3. Befehle `StartGame`, `StartNight`, `AnswerPrompt`, `EndNight`, `DecideExecution`, `EndDay`.
4. JSON-Codec mit `schema_version: 1`.
5. Headless-Test-Runner und drei Szenario-JSONs: *Wölfe gewinnen durch Parität*, *Dorf gewinnt durch Hinrichtung des letzten Wolfs*, *Save/Load-Hash identisch*.

**Fertig, wenn** `godot --headless` die drei Szenarien grün ausführt und dieselbe Befehlsfolge mit demselben Seed zweimal identische Ereignislisten liefert.

Dieser Schritt hängt nur an der Godot-Versionswahl, nicht an offenen Regelentscheidungen, weil Werwolf und Dorfbewohner in `04` *verifiziert* sind. Parallel beantwortet der PO die Fragen aus `07`.
