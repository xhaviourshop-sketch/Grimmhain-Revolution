# Vertical Slice · Umsetzungsgrenze

**Stand:** 2026-09-26 · **Status:** A ist umgesetzt (`../../../godot/README.md`); B ist mit DR-01 bis DR-14 vollständig spezifiziert
**Bezug:** Prompt 2 in `../../masterplan/CLAUDE-PROMPTS.md`, Masterplan Phasen 1–3 in `../../../GRIMMHAIN-REVOLUTION-MASTERPLAN.md`, `../../godot-migration/03-godot-architecture.md`

Pfade relativ zu `docs/specs/vertical-slice/`. Diese Datei legt fest, **was der nächste Auftrag baut und was nicht**. Alles, was hier nicht unter A steht, ist für den Core-Slice verboten.

---

## A · Core-Slice (Prompt 2, Masterplan Phase 1)

Voraussetzung: DR-01 und DR-03 sind entschieden (`decision-request.md`). Der Core-Slice unterstützt 6 bis 24 Personen allein mit `dorfbewohner` und `werwolf`, ohne Obergrenze je Rolle (`../../masterplan/DECISION-LOG.md`, „Rollenanzahl der Grundrollen“).

### A.1 Projekt und Werkzeuge

| Nr. | Umfang |
|---|---|
| A-01 | Godot-4.x-Projekt unter `godot/`, statisch typisiertes GDScript, exakte Version in `godot/README.md` gepinnt |
| A-02 | Headless-Test-Runner und Szenarioformat (`03` §7); ein Befehl startet alle Tests ohne Fenster |
| A-03 | Domain-Core ohne Szenen, Nodes, UI, Audio, Netzwerk und Dateisystem (`03` §1, Masterplan §4 Regel 1) |

### A.2 Datenmodell

| Nr. | Umfang |
|---|---|
| A-04 | `Player`/`Seat` mit stabiler Personen-ID, getrennt von `seat_order` |
| A-05 | `GameState` mit `schema_version`, `rules_version`, Seed-Zustand, Phase, Nacht- und Tageszähler (getrennt) |
| A-06 | Rollen **nur** `dorfbewohner` und `werwolf`; Fraktions-Enum mit Dorf, Werwölfe, Einzelsieg (Einzelsieg ohne Rolle und ohne Siegregel) |
| A-07 | Getrennte Felder `role_id`, Fraktion, `counts_as_wolf`; `appears_as` als Feld vorhanden, ohne Nutzer |
| A-08 | `Nomination{nominator_id, nominee_id, day}` nach DR-03; **kein** Feld für Stimmen |
| A-09 | `KillEvent`/`DeathRecord` mit Ursache, Quelle, Ziel, Phase, Nummer, Reihenfolgeindex; Ursachen `NIGHT_KILL`, `LYNCH` |
| A-10 | Prompt-Grundmodell (`PendingPrompt` nach `03` §5.5) mit ID, Art, handelnder Seite, erlaubten Personen-IDs, Teilantworten, Abbrechbarkeit; im Core-Slice nur für die Wolfswahl genutzt |
| A-11 | `WinCandidate` mit Art, Grund und Status offen/bestätigt/abgelehnt |

### A.3 Befehle, Ereignisse, Phasen

| Nr. | Umfang |
|---|---|
| A-12 | Befehle: `StartGame`, `StartNight`, `AnswerPrompt` (Wolfswahl), `EndNight` (inkl. Morgenauflösung), `Nominate`, `DecideExecution(person|none)`, `EndDay`, `ConfirmWin`, `RejectWin`. Namen nach `03` §5.6; die abweichenden Masterplan-Namen (`SubmitAction`, `ResolveMorning`, `ExecutePlayer`, `DeclareWinner`) werden in `godot/README.md` als Entsprechung dokumentiert |
| A-13 | Validierung vor Anwendung; abgelehnte Befehle verändern nichts und liefern einen Fehlergrund |
| A-14 | Unveränderliche Ereignisse mit Sichtbarkeit (Spielleiter, öffentlich, handelnde Person) |
| A-15 | Phasenmaschine: SETUP → NIGHT → DAWN_RESOLUTION → DAY → NIGHT …, GAME_OVER; Übergänge nur per Befehl; offener Prompt blockiert Übergang |
| A-16 | Grundlegende Tötungs-Pipeline ohne Abfangregeln: Ziel tot? → Tod anwenden → Ereignis → Siegprüfung |
| A-17 | Eine Siegprüfung für Dorf (G-SIEG-1) und Werwölfe (G-SIEG-2); Ergebnis nur als Kandidat. Solange jemand lebt, schließen sich beide Bedingungen aus. Lebt niemand mehr (nach abgelehnten Kandidaten erreichbar), entsteht kein Kandidat (DR-02); die Siegerklärung durch den Spielleiter folgt mit `GmCorrection` (B-11). Ohne Reaktionen fallen vorläufige und verbindliche Prüfung (DR-14) am Ende des Befehls zusammen |

### A.4 Determinismus und Speicherung

| Nr. | Umfang |
|---|---|
| A-18 | `SeededRng` im Zustand (Seed und Ziehposition serialisiert); einzige Zufallsquelle; im Core-Slice genutzt für die Rollenverteilung |
| A-19 | Versionierter JSON-Codec mit fachlichem Hash; Erkennung beschädigter Dateien |
| A-20 | Replay: identische Befehlsliste mit gleichem Seed → bytegleiche Eventliste |

### A.5 Pflichttests (zuerst fehlschlagend, dann grün)

| Test | Szenario in `acceptance-scenarios.md` |
|---|---|
| Wolfsparität | AS-C01, AS-C02 |
| Tod des letzten Wolfs | AS-C03 |
| Siegbestätigung/Ablehnung | AS-C04 |
| identischer Replay mit gleichem Seed | AS-C05, AS-C06 |
| Save/Load mit identischem fachlichem Hash | AS-C07 |
| beschädigte Save-Datei | AS-C08 (Erkennung; Rückfall auf älteren Checkpoint: B-13) |
| Personen-ID getrennt vom Sitz | AS-C09 (Sitztausch per `ReorderSeats`: AS-S03, Stufe V) |
| vollständiges Todesereignis | AS-C10 |
| keine digitale Stimme | AS-C11 |
| keine Hinrichtung | AS-C12 |
| technische Rollen-IDs (DR-01) | AS-C13 |

### A.6 Im Core-Slice ausdrücklich nicht enthalten

Alle Punkte unter B, C und D; insbesondere keine UI, keine Assets, keine weiteren Rollen, kein Undo/Redo, keine Effekte, keine Reaktionswarteschlange, kein atomisches Schreiben mit Rotation auf echtem Dateisystem (der Codec arbeitet auf Strings/Bytes; Dateizugriff liegt außerhalb des Domain-Core).

---

## B · Vertical Slice, Rest (Masterplan Phasen 2 und 3)

Erst nach Abnahme von A. Alle DR-Punkte sind entschieden (`decision-request.md`, Spalte „Entscheidung“).

| Nr. | Umfang | Bezug |
|---|---|---|
| B-01 | Rollen `schutzengel` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_schutzengel.gd`), `das-orakel` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_orakel.gd`), `trugbilderwolf` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_trugbilderwolf.gd`), `waldhexe` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_waldhexe.gd`), `sensentraeger` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_sensentraeger.gd`), `wolfskind` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_wolfskind.gd`), `lehrling` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_lehrling.gd`), `manipulator` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_manipulator.gd`), `spiegelwolf` (im Regelkern umgesetzt, `../../../godot/tests/unit/test_spiegelwolf.gd`) nach `rules-register.md` | DR-05 bis DR-13 (entschieden) |
| B-02 | Nachtplan mit Prioritäten, Einmalschritten, Rudelschritt nach G-PH-6, Überspringen mit Grund | `vertical-slice-flow.md` §3 |
| B-03 | Effekt-Modell mit Quelle und Dauer (Schutz bis Tagesbeginn, Vorbildbindung, verdeckte Lehrling-Bindung, gespeicherte Scheinrolle) und `expire_effects` | `03` §5.2, DR-05, DR-08, DR-11 |
| B-04 | Abfangregeln der Tötungs-Pipeline: Schutzengel, Hexenrettung, Spiegelung (alle im Regelkern umgesetzt; Spiegelung als zentrale Hinrichtungsauflösung `ExecutionRules`) | `03` §5.4 |
| B-05 | Mehrstufige Prompt-Kette mit persistenten Teilantworten und `CancelPrompt`: Waldhexe (im Regelkern umgesetzt); Lehrling mit Spielleiterteil (drei Personen) und Lehrlingsteil (nur Rollen) (im Regelkern umgesetzt); Setup mit Pflichtangabe der Scheinrolle bei `trugbilderwolf` (im Regelkern umgesetzt) | `03` §5.5, DR-06, DR-08, DR-11 |
| B-06 | Persistente Reaktionswarteschlange (Sensenträger) | `03` §5.2 |
| B-07 | Informationsmodell Wahrheit/ermittelt/gezeigt (für das Orakel im Regelkern umgesetzt: `InformationRules`, `InfoRecord`, Übersteuerung, getrennte Audit- und Actor-Ereignisse); Projektion für die handelnde Person ohne fremde Identitäten (Lehrling sieht nur Rollen) | G-INF-1, DR-07, DR-08, DR-11 |
| B-08 | Rollen- und Fraktionswechsel mit `original_role_id`; Lehrling-Erbe nur bei lebendem Lehrling, Reset aller begrenzten Einsätze, Aktivierung aktiver Nachtfähigkeiten ab folgender Nacht; geerbtes Wolfskind unverwandelt mit neuem Vorbild (im Regelkern umgesetzt: `RoleTransition`, `ApprenticeBond`, `ApprenticeRules`) | DR-10, DR-11; AS-L01–AS-L15 |
| B-09 | Einzelsiegregel Manipulator (genau drei Lebende); mehrere gleichzeitige Kandidaten ohne Priorität, Spielleiter bestätigt einen; vorläufiger Siegstatus nach jedem Tod und verbindliche Prüfung nach allen Reaktionen (im Regelkern umgesetzt: persistente Kandidatenmenge `win_candidates`, `ever_nominated`) | DR-02, DR-12, DR-14 |
| B-10 | Zusätzliche Todesursachen `WITCH_POISON` (umgesetzt), `HUNTER_SHOT` (umgesetzt), `SPIEGELWOLF_RETALIATE` (umgesetzt), `MANIPULATOR_NOMINATED` (umgesetzt), `GM_CORRECTION` | G-TOD-3 |
| B-11 | Befehle `BeginStep`, `SkipStep`, `CancelPrompt`, `ReorderSeats`, `ConfirmRoleShown`, `BeginDay`, `GmCorrection` | `vertical-slice-flow.md` §0.1 |
| B-12 | Undo/Redo als Befehlsstapel, über Neustart | AS-U01–U04 |
| B-13 | Checkpoint nach jeder bestätigten Aktion, atomisches Schreiben, Backup, Wiederaufnahme nach Prozessabbruch | Masterplan Phase 1 und 2 |
| B-14 | Tablet-UI: Start, Setup, Wiederaufnahme, Sitzkreis mit Drag-and-drop, Cockpit, gesicherte Ansagekarte, Morgenbericht öffentlich/privat, Nominierung Quelle → Ziel, getrennte Buttons für Todesaktionen | Masterplan Phase 2 |
| B-15 | Vorläufige, lizenzklare Tag-/Nacht-Gestaltung; Reduced-Motion-, Untertitel- und Lautstärkeregelung verdrahtet | Masterplan Phase 2 |
| B-16 | DE- und EN-Texte aller Slice-Rollen aus `rules-register.md` als Übersetzungsschlüssel | DL |
| B-17 | Nachweis auf echtem iPad | Masterplan Phase 2 Gate |
| B-18 | Setup-Option `reveal_role_on_death`; öffentliche Todesmeldung mit Name, Rolle nur bei Ja, nie Ursache | DR-04 |

---

## C · Bewusst später (nach dem Vertical Slice)

| Thema | Frühester Zeitpunkt | Grund |
|---|---|---|
| weitere Rollen bis 20–30 für 1.0 | Phase 4 (17–20 Rollen), Phase 7 (1.0-Umfang) | Masterplan |
| `waechter-am-tor`, Kettentode (`loki`), Wiederbelebung (`dr-victor-frankenstein`), Umlenkung, verzögerter Tod | Phase 3 (Zentralisierung), Rollen danach | Masterplan Phase 3 |
| Täuschungsschritte für tote Rollen („Tote Rollen weiter aufrufen") | Phase 4 | `../../godot-migration/02-product-and-ux-spec.md` §3.2, nicht entschieden |
| Totenkarten-Assistent | Phase 4 | `07` Q3 |
| geführter Modus / Expertenmodus vollständig, Regelbuch, Übungsmodus | Phase 4 | Masterplan |
| Smartphoneclients, öffentliche Anzeige, lokales Netzwerk | Phase 5 | Masterplan |
| 2.5D-Dorf, Cue-System, adaptive Musik, Erzählerstimmen | Phase 6 | Masterplan |
| Szenarien mit eigener Rollenliste und Kulisse | Phase 7 | Masterplan |
| Nachspielbericht, Chronik-Export | Phase 7 | Masterplan |
| Android-/Windows-Builds, Pilot | Phase 8 | Masterplan |
| Online-Remote-Spiel | nach 1.0, eigener Stop/Go | DL |

## D · Ausgeschlossen (nicht nur verschoben)

| Thema | Quelle |
|---|---|
| digitale Stimmabgabe, Stimmzählung, Stimmgewichte, Mehrheitsberechnung | DL; Masterplan §2 „Version 1.0 enthält nicht" |
| Weiterentwicklung der Legacy-Web-App über kritische Fehler hinaus | DL |
| Einbettung von Legacy-Code in den neuen Kern | Masterplan §4 Regel 10 |
| Übernahme bekannter Legacy-Bugs als Referenzverhalten | DL |
