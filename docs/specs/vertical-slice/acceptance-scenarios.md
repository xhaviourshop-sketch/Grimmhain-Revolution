# Vertical Slice · Akzeptanzszenarien

**Stand:** 2026-09-26 · **Status:** abgeglichen mit DR-01 bis DR-14 (`../../masterplan/DECISION-LOG.md`)
**Regeln:** `rules-register.md` · **Ablauf:** `vertical-slice-flow.md` · **Umfang:** `implementation-boundary.md`

Pfade relativ zu `docs/specs/vertical-slice/`.

## Konventionen

- Jedes Szenario wird als headless Szenariotest umgesetzt (`../../godot-migration/03-godot-architecture.md` §7; Format in `../../../godot/README.md`, Abschnitt „Szenarioformat“).
- **Stufe** gibt an, wann das Szenario grün sein muss: **C** = Core-Slice (Masterplan Phase 1, umgesetzt), **V** = Vertical Slice (Phase 2/3).
- Alle erwarteten Ergebnisse folgen den endgültigen Entscheidungen DR-01 bis DR-14. Es gibt keine Varianten je Option.
- „Fachlicher Hash" = Hash über den Spielzustand ohne Anzeige- und Zeitwerte (`03` §6.3).
- „Projektion für X" = alle Daten, die die App der Person X zeigt oder an ihr Gerät sendet (gesicherte Tablet-Karte, später Smartphone).
- Personen werden über Buchstaben benannt; die Sitzposition ist nur relevant, wo ausdrücklich genannt.

### Standardbesetzungen

- **B6**: Personen A–F, IDs 1–6, Sitzreihenfolge 1–6. A `werwolf`, B `trugbilderwolf`, C `schutzengel`, D `das-orakel`, E `waldhexe`, F `dorfbewohner`. `reveal_role_on_death` = Nein.
- **B9L**: Personen A–G, L, W, IDs 1–9, Sitzreihenfolge 1–9. A `werwolf`, B `werwolf`, C `schutzengel`, D `das-orakel`, E `waldhexe`, F `dorfbewohner`, G `dorfbewohner`, L `lehrling` (ID 8), W `wolfskind` (ID 9). `reveal_role_on_death` = Nein. Nachtreihenfolge Nacht 1: W (0.9) → L (1.1) → C (1.3) → Rudel (2.0) → E (3.4) → D (4.6).

---

## 1. Kern (Stufe C)

**AS-C01 · Wolfsparität**
- Given: 6 Personen, A und B `werwolf`, C–F `dorfbewohner`; F ist in Nacht 1 durch das Rudel gestorben; A–E leben (2 Wölfe, 3 Nicht-Wölfe).
- When: Hinrichtung von C wird bestätigt (`LYNCH`).
- Then: Es leben 2 Wölfe und 2 Nicht-Wölfe; genau ein Siegkandidat „Werwölfe" mit Grund „Parität 2:2" entsteht; Phase bleibt bis zur Bestätigung unverändert.

**AS-C02 · Keine vorzeitige Parität**
- Given: 2 Wölfe, 3 Dorfbewohner lebend.
- When: beliebiger Befehl ohne Tod.
- Then: kein Siegkandidat.

**AS-C03 · Tod des letzten Wolfs**
- Given: A `werwolf` ist der einzige lebende Wolf; 3 Dorfbewohner leben.
- When: Hinrichtung von A wird bestätigt.
- Then: Siegkandidat „Dorf"; nach `ConfirmWin` ist die Phase GAME_OVER und weitere Spielbefehle werden abgelehnt.

**AS-C04 · Siegbestätigung und Ablehnung**
- Given: Siegkandidat „Werwölfe" liegt vor.
- When: `RejectWin(reason="Zählfehler")`.
- Then: Ereignis mit Grund im Protokoll; Phase unverändert; ein Kandidat wird erst nach einem weiteren Tod erneut angeboten.

**AS-C05 · Gleicher Seed, gleiche Partie**
- Given: identische Personenliste, identischer Rollenpool, Seed 4711, zufällige Verteilung.
- When: dieselbe Befehlsliste wird zweimal auf frischem Zustand ausgeführt.
- Then: Rollenzuordnung, Eventliste und Endzustand sind bytegleich (Masterplan Phase 1 Gate).

**AS-C06 · Anderer Seed**
- Given: wie AS-C05, aber Seed 4712.
- When: Verteilung.
- Then: Die Zuordnung darf abweichen; der gespeicherte Seed im Spielstand ist 4712.

**AS-C07 · Save/Load ohne Hashänderung**
- Given: Partie mitten in Nacht 2.
- When: speichern, App-Zustand verwerfen, laden.
- Then: fachlicher Hash vor und nach dem Laden identisch; `schema_version` und `rules_version` vorhanden.

**AS-C08 · Beschädigter Spielstand**
- Given: gültiger Spielstand.
- When: der Spielstand wird manipuliert (Byte geändert, JSON abgeschnitten).
- Then (C): Laden erkennt den Fehler über Integritätsprüfsumme, fachlichen Hash oder Replay und liefert keinen Zustand; ein älterer gültiger Spielstand bleibt ladbar.
- Then (V, B-13): Die beschädigte Datei wird nicht überschrieben, gemeldet und der vorherige gültige Checkpoint wird angeboten.

**AS-C09 · Personen-ID getrennt vom Sitz** (Kernanteil)
- Given: Sitzreihenfolge 4, 2, 6, 1, 3, 5 (nicht identisch mit der ID-Reihenfolge).
- When: Das Rudel tötet ID 6.
- Then: ID 6 ist tot, die Sitzreihenfolge ist unverändert; der Todesdatensatz und alle Ereignisse referenzieren ID 6; der Personendatensatz enthält kein Sitzfeld. Sitztausch per `ReorderSeats`: AS-S03.

**AS-C10 · Todesereignis vollständig**
- Given: 6 Personen, Nacht 1.
- When: Rudel wählt F, Nacht endet.
- Then: `SeatDied` für ID 6 enthält Ursache `NIGHT_KILL`, Quelle Rudel, Nacht 1, Reihenfolgeindex.

**AS-C11 · Keine digitale Stimme**
- Given: Tag 1.
- When: A nominiert F, Hinrichtung von F wird bestätigt.
- Then: Der Spielstand enthält `Nomination{A→F, Tag 1}` und die bestätigte Hinrichtung; er enthält **kein** Feld für Stimmen, Stimmanzahl oder Mehrheit (Negativtest auf Schema und Ereignisse).

**AS-C12 · Keine Hinrichtung**
- Given: Tag 1.
- When: `DecideExecution(none)`.
- Then: Ereignis „keine Hinrichtung" im Protokoll; niemand stirbt; `EndDay` ist möglich.

**AS-C13 · Technische Rollen-IDs**
- Given: Partie mit `werwolf` und `dorfbewohner`.
- When: Spielstand wird serialisiert.
- Then: Rollen stehen ausschließlich als deutsche ASCII-kebab-case-IDs im Zustand (`werwolf`, `dorfbewohner`); kein Anzeigename und kein englischer Bezeichner dient als ID (DR-01).

## 2. Undo, Redo, Abbruch (Stufe V)

Undo/Redo gehört laut Masterplan in Phase 3. Die Szenarien sind mit dem Befehls-/Ereignismodell des Core-Slice umsetzbar.

**AS-U01 · Undo eines Befehls**
- Given: Tag 1, Hinrichtung von F bestätigt.
- When: Undo.
- Then: F lebt; fachlicher Hash entspricht dem Zustand vor `DecideExecution`; Redo stellt den Tod mit identischem Ereignis wieder her.

**AS-U02 · Undo über Neustart**
- Given: drei bestätigte Befehle, App wird beendet und neu gestartet.
- When: Undo.
- Then: Zustand entspricht dem nach Befehl 2.

**AS-U03 · Undo aller Befehle**
- Given: vollständige Beispielpartie bis Spielende.
- When: Undo bis zum Anfang, dann Redo bis zum Ende.
- Then: Anfangszustand exakt erreicht; Endzustand nach Redo hat denselben Hash wie vorher (Masterplan Phase 3 Gate).

**AS-U04 · Neuer Befehl leert Redo**
- Given: Undo wurde ausgeführt.
- When: anderer Befehl wird bestätigt.
- Then: Redo ist nicht mehr möglich.

**AS-A01 · App-Abbruch mitten in der Hexenkette**
- Given: B6, Nacht 1, Rudel hat F gewählt; Waldhexe-Prompt: „retten = ja" beantwortet, Gift noch offen.
- When: Prozess wird hart beendet und neu gestartet.
- Then: Phase NIGHT, Schritt Waldhexe, offener Prompt mit gespeicherter Teilantwort „retten = ja"; die Rettung ist **noch nicht** angewandt und als unverbraucht gespeichert.

**AS-A02 · Abbruch des Prompts**
- Given: wie AS-A01, Teilantwort vorhanden.
- When: `CancelPrompt`.
- Then: fachlicher Hash entspricht dem Zustand vor Beginn des Hexenschritts.

**AS-A03 · Abbruch während einer Reaktion**
- Given: Sensenträger ist gestorben, Reaktion offen.
- When: Neustart.
- Then: Reaktion ist weiterhin offen, Phasenwechsel und verbindliche Siegprüfung sind blockiert.

**AS-A04 · Abbruch während der Rollenanzeige**
- Given: 3 von 6 Personen haben `ConfirmRoleShown`.
- When: Neustart.
- Then: Rollenanzeige setzt bei der vierten Person fort; keine Rolle ist im Cockpit sichtbar, bis der Spielleiter die Anzeige verlässt.

## 3. Rollen (Stufe V)

### Schutzengel (DR-05)

Im Regelkern umgesetzt und getestet (`../../../godot/tests/unit/test_schutzengel.gd`): AS-R01 bis AS-R04, AS-R32, AS-R42, AS-R43. AS-R32 prüft Fluch, Hinrichtung und Spielleitertod; Gift prüft `../../../godot/tests/unit/test_waldhexe.gd`.

**AS-R01 · Schutz hält**
- Given: B6, Nacht 1: C schützt F.
- When: Rudel wählt F, Nacht endet.
- Then: F lebt; `KillPrevented{by: schutzengel}` nur für den Spielleiter; Morgenbericht öffentlich „Niemand ist gestorben".

**AS-R02 · Schutz wird erst in der Morgenauflösung angewandt**
- Given: B6, Nacht 1: C schützt F.
- When: Rudel wählt F; der Spielleiter korrigiert die Wolfswahl vor Bestätigung auf D und bestätigt; E sieht im Hexenschritt „D".
- Then: Die erste Zielwahl verbraucht nichts; D stirbt am Morgen; die Hexe hat das Opfer unabhängig von einem Schutz gesehen.

**AS-R03 · Schutz endet bei Tagesbeginn**
- Given: C schützt F in Nacht 1; kein Angriff auf F.
- When: Nacht 2, C schützt D, Rudel wählt F.
- Then: F stirbt am Morgen; ein Schutz aus Nacht 1 existiert nach Beginn von Tag 1 nicht mehr.

**AS-R04 · Kein Selbstschutz**
- Given: Schutzengel-Prompt.
- Then: C ist nicht in `allowed_seats`.

**AS-R42 · Schutzengel stirbt nach bestätigter Wahl**
- Given: B6, Nacht 1: C schützt F und bestätigt; danach stirbt C durch eine Spielleiterkorrektur.
- When: Rudel wählt F, Nacht endet.
- Then: F lebt; `KillPrevented` mit Schutzengel C (DECISION-LOG, Schutzengel 26.09.2026).

**AS-R43 · Zwei Schutzengel, dieselbe Person**
- Given: zwei Schutzengel (niedrigere ID zuerst) schützen beide F.
- When: Rudel wählt F.
- Then: F lebt; genau ein `KillPrevented` mit beiden Schutzengel-IDs.

**AS-R32 · Schutz wirkt nur gegen Wolfsangriff**
- Given: B6, Nacht 1: C schützt F.
- When: E vergiftet F.
- Then: F stirbt sofort mit `WITCH_POISON`; der Schutz verhindert das nicht.

### Waldhexe (DR-06)

Im Regelkern umgesetzt und getestet (`../../../godot/tests/unit/test_waldhexe.gd`): AS-R05 bis AS-R08, AS-R39, AS-R32 mit Gift, AS-R37 mit echtem Gifttod, AS-A01, AS-A02. Die Testbesetzung entspricht B6 mit `dorfbewohner` statt `trugbilderwolf` (als zweiter `werwolf`) und `das-orakel`, bis diese Rollen umgesetzt sind; AS-R08 prüft die Rollenoffenlegung am Opfer C (`schutzengel`). „Projektion für E“ ist im Kern der offene Prompt und das Ereignis `WitchActed` (nur Spielleiter).

**AS-R05 · Rettung**
- Given: B6, Rudel wählt F.
- When: E rettet F und verzichtet auf Gift.
- Then: F lebt; Heiltrank von E verbraucht; Gifttrank unverbraucht; nach der Rettung zeigt die Projektion für E zusätzlich die Rolle `dorfbewohner` von F.

**AS-R06 · Gift tötet sofort**
- Given: B6, Rudel wählt F.
- When: E rettet nicht und vergiftet A.
- Then: A stirbt sofort im Hexenschritt mit `WITCH_POISON`, Quelle E; F stirbt in der Morgenauflösung mit `NIGHT_KILL`; kein Siegkandidat (B lebt als Wolf, 1 Wolf gegen 3 Nicht-Wölfe).

**AS-R07 · Einmal-Nutzung pro Person**
- Given: E hat in Nacht 1 gerettet.
- When: Nacht 2, Rudel wählt F.
- Then: Option „retten" ist nicht verfügbar; Option „vergiften" ist verfügbar.

**AS-R08 · Hexe sieht vor der Entscheidung nur den Namen**
- Given: Rudel wählt D (`das-orakel`).
- When: Hexenschritt beginnt; E entscheidet „retten = nein".
- Then: Die Projektion für E zeigt nur den Namen „D", keine Rolle. Variante „retten = ja": erst danach zeigt die Projektion zusätzlich `das-orakel`.

**AS-R39 · Beide Tränke in derselben Nacht**
- Given: B6, Rudel wählt F.
- When: E rettet F und vergiftet A in derselben Nacht.
- Then: beide Wirkungen treten ein; beide Tränke sind verbraucht.

### Orakel und Trugbilderwolf (DR-07, DR-08)

**AS-R09 · Wahre Information**
- Given: B6, Nacht 1, D wählt F.
- Then: Wahrheit `dorfbewohner`, ermittelt `dorfbewohner`, nach „Gezeigt" gezeigt `dorfbewohner`; alle drei im Ereignis gespeichert, Sichtbarkeit „nur D".

**AS-R10 · Sonderwolf erscheint als Werwolf**
- Given: A `spiegelwolf` statt `werwolf`; D wählt A.
- Then: ermittelt `werwolf`; Wahrheit `spiegelwolf`.

**AS-R33 · Keine Selbstprüfung**
- Given: Orakel-Prompt für D.
- Then: D ist nicht in `allowed_seats`.

**AS-R11 · Scheinrolle aus dem Spielaufbau**
- Given: B6; beim Spielaufbau hat der Spielleiter aus den angebotenen Nicht-Wolf-Rollen die Scheinrolle `waldhexe` festgelegt.
- When: D wählt B.
- Then: Wahrheit `trugbilderwolf`, ermittelt `waldhexe`; keine Rückfrage an den Spielleiter; keine Zufallsziehung, Seed-Ziehposition unverändert. Ohne festgelegte Scheinrolle lehnt `StartGame` einen Pool mit `trugbilderwolf` ab.

**AS-R12 · Wiederholte Prüfung**
- Given: wie AS-R11; Nacht 2 prüft D erneut B.
- Then: ermittelt erneut `waldhexe`; ohne Spielleiterkorrektur bleibt die Scheinrolle während der ganzen Partie unverändert (Korrektur: AS-G05).

**AS-R13 · Übersteuerte Anzeige**
- Given: ermittelt ist `waldhexe`.
- When: Spielleiter setzt gezeigt auf `dorfbewohner` und bestätigt die Warnung.
- Then: Ereignis enthält ermittelt `waldhexe`, gezeigt `dorfbewohner`, Übersteuerungsgrund.

**AS-R14 · Replay und Undo ohne Zufall**
- Given: AS-R11 abgeschlossen.
- When: Undo des Orakel-Schritts, danach dieselbe Prüfung; zusätzlich Replay der gesamten Befehlsliste.
- Then: identisches Ergebnis; die Scheinrolle stammt aus dem gespeicherten `StartGame`-Befehl, nicht aus dem Seed.

### Sensenträger (DR-09)

Im Regelkern umgesetzt und getestet (`../../../godot/tests/unit/test_sensentraeger.gd`): AS-R15, AS-R16, AS-R17, AS-R37, AS-R40, AS-R41, AS-G01, AS-G02. AS-R37 nutzt dort einen Nachttod per Spielleiterkorrektur; den echten Gifttod prüft `../../../godot/tests/unit/test_waldhexe.gd`.

**AS-R15 · Reaktion nach Nachttod**
- Given: Sensenträger G wird nachts vom Rudel getötet.
- When: Morgenauflösung.
- Then: Reaktion „Sensenträger" erscheint vor dem Morgenbericht; G wählt A; A stirbt mit `HUNTER_SHOT`, Quelle G.

**AS-R16 · Reaktion nach Hinrichtung sofort**
- Given: Sensenträger G wird an Tag 1 hingerichtet.
- Then: Die Reaktion wird unmittelbar nach der Hinrichtung abgefragt, vor `EndDay`.

**AS-R17 · Verzicht**
- When: G wählt „Überspringen".
- Then: keine Tötung, Reaktion erledigt, protokolliert.

**AS-R40 · Wiederbelebung entfernt keine eingereihte Reaktion**
- Given: G `sensentraeger` ist gestorben, seine Reaktion ist eingereiht.
- When: `GmCorrection(revive G)`.
- Then: G lebt; die Reaktion bleibt offen und wird normal abgearbeitet; das frühere `SeatDied` bleibt unverändert im Protokoll. Beim Beginn der Reaktion ist G nicht wählbar; eine Antwort mit G als Ziel wird mit `invalid_target` abgelehnt, jede andere lebende Person ist zulässig. Stirbt G später erneut, entsteht keine zweite Reaktion (einmal pro Person).

**AS-R41 · Bereits totes Rudelopfer**
- Given: Nacht 1, das Rudel hat F bestätigt; danach stirbt F durch eine Spielleiterkorrektur.
- When: Nacht endet.
- Then: kein weiterer Rudelangriff (`KillIgnored`, nur Spielleiter), die Rudelwahl wird nicht erneut geöffnet, der Tag beginnt.

**AS-R37 · Reaktion nach Gifttod**
- Given: E vergiftet G in Nacht 1.
- Then: G stirbt sofort; seine Reaktion wird in der Morgenauflösung abgefragt, nicht während der Nacht.

### Wolfskind (DR-10)

**AS-R18 · Verwandlung**
- Given: Wolfskind W wählt F als Vorbild; ein Wolf A lebt; 4 Nicht-Wölfe inklusive W leben.
- When: F stirbt.
- Then: W zählt sofort als Wolf (`counts_as_wolf` = ja), Rolle bleibt `wolfskind`; die Siegprüfung rechnet mit 2 Wölfen; eine Orakel-Prüfung auf W ergibt `werwolf`.

**AS-R19 · Totes Wolfskind verwandelt sich nicht**
- Given: W ist tot, Vorbild F lebt.
- When: F stirbt.
- Then: keine Verwandlung.

**AS-R20 · Rudelteilnahme ab der folgenden Nacht**
- Given: F stirbt in Nacht 1 durch Gift; W ist dadurch verwandelt.
- Then: Der Rudelschritt von Nacht 1 ist bereits vorbei; ab Nacht 2 wacht W mit dem Rudel. Stirbt A als einziger anderer Wolf, existiert der Rudelschritt weiter (G-PH-6) und W wählt das Opfer.

**AS-R38 · Keine Selbstwahl**
- Given: Wolfskind-Prompt für W.
- Then: W ist nicht in `allowed_seats`.

### Lehrling (DR-11)

Die früheren Szenarien AS-R21 bis AS-R23 sind durch AS-L01 bis AS-L16 ersetzt. Grundlage: `rules-register.md` §9, Besetzung B9L.

**AS-L01 · Verdeckte Auswahl der drei Personen**
- Given: B9L, Nacht 1, Schritt Lehrling aktiv.
- When: Der Spielleiter wählt im Cockpit C, E und F.
- Then: Der offene Prompt speichert die Teilantwort `candidates = [3, 5, 6]` mit Sichtbarkeit nur Spielleiter. Abgelehnt werden: L selbst, eine tote Person, weniger oder mehr als drei Personen, eine Person doppelt.

**AS-L02 · Anzeige ausschließlich der Rollen**
- Given: AS-L01.
- When: Die gesicherte Karte für L wird geöffnet.
- Then: Sie zeigt genau drei Optionen: `dorfbewohner`, `schutzengel`, `waldhexe` (nach Rollen-ID sortiert). Negativtest über Projektion für L und alle Ereignisse mit Sichtbarkeit „handelnde Person": keine Personen-IDs 3, 5, 6, keine Namen C, E, F, keine Sitzpositionen, keine Porträts. Wäre eine gewählte Person ein verwandeltes Wolfskind, zeigte die Option nur `wolfskind`.

**AS-L03 · Gleiche Rollen ohne Identitätshinweis**
- Given: B9L, Nacht 1; der Spielleiter wählt C, F und G (F und G sind `dorfbewohner`).
- Then: Die Karte zeigt `dorfbewohner`, `dorfbewohner`, `schutzengel`. Die Reihenfolge der beiden Dorfbewohner-Optionen stammt aus einer `SeededRng`-Ziehung, nicht aus Sitz- oder ID-Reihenfolge; bei gleichem Seed und gleichen Befehlen ist sie identisch.

**AS-L04 · Geheime Bindung zwischen Rollenoption und Person**
- Given: AS-L02.
- When: L wählt `waldhexe`, Bestätigung.
- Then: Intern gilt `apprentice_master_id = 5` (E); Ereignis `ApprenticeBound` nur für den Spielleiter. Die Projektion für L enthält nur „gewählt: `waldhexe`"; die öffentliche Projektion enthält nichts über den Lehrling. `role_id` von L bleibt `lehrling`.

**AS-L05 · Tod der ausgewählten Person**
- Given: AS-L04; Rudel wählt E in Nacht 1; niemand rettet.
- When: Morgenauflösung.
- Then: E stirbt (`NIGHT_KILL`); in derselben Pipeline-Ausführung `RoleChanged{from: lehrling, to: waldhexe, by: master_death}` nur für den Spielleiter. L hat `role_id` `waldhexe`, `original_role_id` `lehrling`. Der öffentliche Morgenbericht nennt nur „E" (DR-04), nichts über L.

**AS-L06 · Tod des Lehrlings vor der Vererbung**
- Given: AS-L04; L stirbt in Nacht 1 durch das Rudel.
- When: E stirbt an Tag 1 durch Hinrichtung.
- Then: kein Rollenwechsel; L bleibt tot mit `role_id` `lehrling`; die Bindung ist erloschen (Bugfix F5).

**AS-L07 · Zurücksetzen verbrauchter Fähigkeiten**
- Given: AS-L04; E hat in Nacht 1 F gerettet (Heiltrank verbraucht).
- When: E wird an Tag 1 hingerichtet.
- Then: L erbt `waldhexe`; für L sind Heil- und Gifttrank unverbraucht. Die Verbrauchsdaten von E bleiben unverändert bei E gespeichert (G-ID-3).

**AS-L08 · Aktivierung erst in der folgenden Nacht**
- Given: B9L; L hat in Nacht 1 `das-orakel` gewählt (Bindung an D).
- When: Nacht 2: E vergiftet D im Hexenschritt (3.4).
- Then: L erbt `das-orakel` sofort, erhält in Nacht 2 aber keinen Orakel-Schritt; der Orakel-Schritt von D wird mit Grund „tot" angezeigt. In Nacht 3 erhält L den Orakel-Schritt mit voller Nutzung.

**AS-L09 · Fraktion sofort, aktive Nachtfähigkeit ab der folgenden Nacht**
- Given: B9L; L hat in Nacht 1 `werwolf` gewählt (Bindung an A).
- When: A wird an Tag 1 hingerichtet.
- Then: L hat `role_id` `werwolf`, Fraktion Werwölfe und zählt sofort als Wolf; die Siegprüfung nach der Hinrichtung rechnet L als Wolf. Die Nachtfähigkeit (Rudel) ist erstmals in Nacht 2 verfügbar.

**AS-L10 · Vererbung des Wolfskinds**
- Given: B9L; W hat in Nacht 1 F als Vorbild gewählt; L hat `wolfskind` gewählt (Bindung an W); F stirbt, W ist dadurch verwandelt.
- When: W stirbt an Tag 2.
- Then: L erbt `wolfskind` und zählt **nicht** als Wolf, obwohl W verwandelt war. L übernimmt kein Vorbild von W.

**AS-L11 · Neues Wolfskind-Vorbild**
- Given: AS-L10.
- When: Nacht 3 beginnt.
- Then: L erhält den Wolfskind-Schritt (0.9); L ist nicht in `allowed_seats`; L wählt G als neues Vorbild. Weitere Tode anderer Personen verwandeln L nicht. Stirbt G, während L lebt, zählt L ab sofort als Wolf und wacht ab der folgenden Nacht mit dem Rudel.

**AS-L12 · Speichern und Laden während der offenen Lehrlingswahl**
- Given: AS-L01 (drei Personen gewählt, L hat noch nicht gewählt).
- When: speichern, Prozess hart beenden, neu starten, laden.
- Then: fachlicher Hash identisch; Phase NIGHT, Schritt Lehrling, offener Prompt mit `candidates = [3, 5, 6]` und identischer Optionsreihenfolge; keine Bindung existiert; `EndNight` bleibt blockiert.

**AS-L13 · Speichern und Laden bei gebundener, noch nicht vollzogener Vererbung**
- Given: AS-L04 (L an E gebunden, E lebt).
- When: speichern, laden; danach stirbt E.
- Then: fachlicher Hash nach dem Laden identisch; die Bindung ist vorhanden und nur im Spielleiterteil sichtbar; nach dem Tod von E erbt L genau wie ohne Speichern (identische Ereignisse).

**AS-L14 · Speichern und Laden zwischen Erbe und Aktivierung**
- Given: AS-L07 (L hat an Tag 1 `waldhexe` geerbt, Nacht 2 noch nicht begonnen).
- When: speichern, laden, `StartNight`.
- Then: fachlicher Hash nach dem Laden identisch; in Nacht 2 erhält L den Waldhexe-Schritt mit beiden Tränken, genau wie ohne Speichern.

**AS-L16 · Todesreaktion der geerbten Rolle gilt sofort**
- Given: B9L mit G als `sensentraeger` statt `dorfbewohner`; L hat in Nacht 1 `sensentraeger` gewählt (Bindung an G).
- When: G wird an Tag 1 hingerichtet (L erbt `sensentraeger`); G reagiert und verflucht L; L stirbt noch an Tag 1, vor Nacht 2.
- Then: Der Tod von L reiht sofort eine eigene Sensenträger-Reaktion für L ein; sie wird noch an Tag 1 abgefragt (DR-09). Die geerbte Todesreaktion gilt ab dem Erbe, nicht erst ab der folgenden Nacht.

**AS-L15 · Deterministisches Replay und Undo des Lehrling-Ablaufs**
- Given: B9L, Seed 4711; Befehlsliste mit Spielleiterauswahl (C, F, G), Lehrlingswahl, Tod der gebundenen Person, Erbe, Aktivierung in der folgenden Nacht.
- When: Die Befehlsliste wird zweimal auf frischem Zustand ausgeführt; zusätzlich Undo der Lehrlingswahl und erneute gleiche Wahl.
- Then: Eventlisten und Endzustände bytegleich, einschließlich Optionsreihenfolge, `ApprenticeBound` und `RoleChanged`. Nach Undo ist die Seed-Ziehposition zurückgesetzt; die erneute Wahl ergibt dieselbe Reihenfolge und dieselbe Bindung.

### Manipulator und Siegprüfung (DR-02, DR-12, DR-14)

**AS-R24 · Tod durch Nominierung**
- Given: Tag 1, M `manipulator` lebt.
- When: F nominiert M.
- Then: `Nomination{F→M}` gespeichert; M stirbt sofort mit `MANIPULATOR_NOMINATED`, Quelle F; Tagesphase bleibt aktiv, weitere Nominierungen sind möglich.

**AS-R25 · Solo-Sieg bei genau drei Lebenden**
- Given: Es leben M (nie nominiert), A `werwolf`, F `dorfbewohner`, C `schutzengel`.
- When: C stirbt.
- Then: Es leben genau 3 (M, A, F); Siegkandidat „Manipulator"; keine Wolfsparität (1 Wolf gegen 2 Nicht-Wölfe).

**AS-R26 · Sprung von vier auf zwei, vorläufig und verbindlich**
- Given: Es leben M (nie nominiert), A `werwolf`, G `sensentraeger`, F `dorfbewohner`.
- When: Hinrichtung von G wird bestätigt; G verflucht in seiner sofortigen Reaktion F.
- Then: Nach dem Tod von G leben genau drei: vorläufiger Siegstatus „Manipulator", nicht bestätigbar, weil die Reaktion offen ist (DR-14). Nach der Reaktion leben M und A: verbindliche Prüfung ergibt nur „Werwölfe" (Parität 1:1); kein Manipulator-Kandidat, weil nicht genau drei leben (DR-12).

**AS-R34 · Gleichzeitige Siege**
- Given: Es leben M (nie nominiert), A `werwolf`, B `werwolf`, C `schutzengel`.
- When: C stirbt.
- Then: Kandidaten „Manipulator" (genau drei) und „Werwölfe" (Parität 2:1) liegen gleichzeitig vor; keine automatische Priorität. Der Spielleiter bestätigt genau einen (`ConfirmWin`) oder lehnt beide mit Grund ab (DR-02).

**AS-R35 · Niemand lebt**
- Given: Nach abgelehnten Kandidaten lebt nur noch A `werwolf`.
- When: A stirbt.
- Then: kein automatischer Siegkandidat; der Spielleiter erklärt das Ergebnis per Übersteuerung mit Warnung und Protokoll (DR-02, G-GM-1).

**AS-R36 · Reaktion hebt vorläufigen Sieg auf**
- Given: Es leben A, B `werwolf`, G `sensentraeger`, F, H `dorfbewohner`.
- When: Rudel tötet G in Nacht 2; in der Morgenauflösung verflucht G A.
- Then: Nach dem Tod von G vorläufig „Werwölfe" (2:2), nicht bestätigbar. Nach der Reaktion leben B, F, H (1:2): die verbindliche Prüfung ergibt keinen Kandidaten; der Spielleiter wird nicht zur Bestätigung aufgefordert.

**AS-R27 · Nominierung durch Undo zurückgenommen**
- Given: AS-R24.
- When: Undo.
- Then: M lebt, Nominierung entfernt, Status „nie nominiert" wiederhergestellt.

### Spiegelwolf (DR-13)

**AS-R28 · Spiegelung**
- Given: S `spiegelwolf`; Tag 1: F nominiert S.
- When: Hinrichtung von S wird bestätigt.
- Then: S lebt; F stirbt mit `SPIEGELWOLF_RETALIATE`, Quelle S; Spiegelung für S verbraucht; die Hinrichtung des Tages gilt als erfolgt.

**AS-R29 · Zweite Hinrichtung**
- Given: Spiegelung verbraucht; Tag 2: D nominiert S.
- When: Hinrichtung von S.
- Then: S stirbt mit `LYNCH`.

**AS-R30 · Nominierende Person bereits tot**
- Given: F nominiert S, F stirbt danach durch eine andere Ursache am selben Tag.
- When: Hinrichtung von S.
- Then: niemand stirbt; Spiegelung verbraucht.

**AS-R31 · Hinrichtung ohne Nominierung**
- Given: S wurde an diesem Tag nicht nominiert.
- When: Der Spielleiter richtet S per `GmCorrection execute` mit Bestätigung und Begründung hin (DR-03).
- Then: keine Spiegelung; S stirbt mit `LYNCH`; die App fragt keine nominierende Person nachträglich ab (DR-13); die Übersteuerung ist mit Grund protokolliert.

## 4. Nominierung (Stufe V, Validierung bereits in C)

**AS-N01 · Einmal nominieren**
- Given: Tag 1, A hat bereits nominiert.
- When: A nominiert erneut.
- Then: abgelehnt mit Grund; nur per Übersteuerung mit Warnung, Begründung und Protokoll möglich.

**AS-N02 · Einmal nominiert werden**
- Given: F ist an Tag 1 nominiert.
- When: B nominiert F.
- Then: abgelehnt mit Grund.

**AS-N03 · Neuer Tag**
- Given: A hat an Tag 1 nominiert.
- When: Tag 2, A nominiert.
- Then: erlaubt.

**AS-N04 · Nur Lebende**
- When: Eine tote Person nominiert oder wird nominiert.
- Then: abgelehnt mit Grund.

**AS-N05 · Hinrichtung nur nach Nominierung**
- Given: F wurde an diesem Tag nicht nominiert.
- When: `DecideExecution(F)`.
- Then: abgelehnt mit Grund; per `GmCorrection execute` mit Bestätigung, Begründung und Protokoll möglich (AS-G03).

## 5. Sitztausch (Stufe V)

**AS-S01 · Schutz folgt der Person**
- Given: C schützt F (ID 6, Sitz 6) in Nacht 1.
- When: Spielleiter tauscht vor dem Rudelschritt die Sitze von F und E; Rudel wählt die Person auf Sitz 6 (jetzt E).
- Then: E stirbt am Morgen; F bleibt geschützt; alle Ereignisse referenzieren Personen-IDs.

**AS-S02 · Tausch während offenem Prompt**
- Given: Waldhexe- oder Lehrling-Prompt offen.
- When: `ReorderSeats`.
- Then: Prompt bleibt offen; `allowed_seats`, `candidates` und Bindungen referenzieren weiterhin dieselben Personen-IDs; die Optionsreihenfolge des Lehrlings ändert sich nicht.

**AS-S03 · Sitztausch mit Toten**
- Given: A (ID 1) auf Sitz 1, B (ID 2) auf Sitz 2; A ist tot.
- When: `ReorderSeats` tauscht die Sitzplätze.
- Then: ID 1 ist weiterhin tot und auf Sitz 2; ID 2 lebt und sitzt auf Sitz 1; kein anderes Feld ändert sich.

## 6. Morgenbericht und Geheimhaltung (Stufe V, DR-04)

**AS-M01 · Öffentlich nur der Name**
- Given: `reveal_role_on_death` = Nein; Nacht mit Schutz auf F, Angriff auf F, Gift auf A.
- Then: Der öffentliche Teil nennt nur „A"; keine Rolle, keine Ursache. Der private Teil nennt Schutz, Angriff, Gift und Ursachen.

**AS-M03 · Rolle bei Tod aufdecken**
- Given: `reveal_role_on_death` = Ja; wie AS-M01.
- Then: Der öffentliche Teil nennt „A" und `werwolf`; weiterhin keine Ursache.

**AS-M02 · Keine Geheimnisse in öffentlicher Projektion**
- Given: beliebiger Zustand.
- When: öffentliche Projektion wird erzeugt.
- Then: keine Rollen lebender Personen, keine Rollen Toter bei `reveal_role_on_death` = Nein, keine Todesursachen, keine Effekte, keine Nachtziele, keine Lehrling-Bindungen, keine Informationsergebnisse (Negativtest über alle Felder).

## 7. Übersteuerung (Stufe V)

**AS-G01 · Spielleiter-Tod mit Folgen**
- Given: G `sensentraeger` lebt.
- When: `GmCorrection(kill G, cause=GM_CORRECTION, trigger_effects=true)` nach Warnung.
- Then: G stirbt mit `GM_CORRECTION`; Sensenträger-Reaktion wird eingereiht; Protokolleintrag mit Grund.

**AS-G02 · Spielleiter-Tod ohne Folgen**
- When: wie AS-G01 mit `trigger_effects=false`.
- Then: G stirbt; keine Reaktion; Protokoll vermerkt „ohne Folgen".

**AS-G03 · Hinrichtung ohne Nominierung per Übersteuerung** (Kern umgesetzt)
- Given: Tag 1, G `sensentraeger` lebt und wurde nicht nominiert; 2 Wölfe, 3 Nicht-Wölfe inklusive G.
- When: `GmCorrection(execute G)` mit Bestätigung und Begründung.
- Then: G stirbt mit `LYNCH`, Quelle Spielleiter; `GmCorrected{kind: execute}` und `ExecutionConfirmed{gm_override: true}` protokolliert; die Hinrichtung des Tages gilt als erfolgt. Die Reaktion von G wird eingereiht, vorläufiger Siegstatus „Werwölfe“ (2:2), verbindliche Prüfung erst nach der Reaktion (DR-14).

**AS-G04 · Korrektur bei offenem Prompt** (Kern umgesetzt)
- Given: Nacht 1, Rudel-Prompt offen, F ist wählbar.
- When: `GmCorrection(kill F)` (ebenso `revive`, `set_role`, `set_role_field`, am Tag `execute` bei offenem Reaktions-Prompt).
- Then: Der offene Prompt wird mit Grund `state_changed_by_gm_correction` abgebrochen; der Rudelschritt ist erneut der erwartete Schritt; der neu begonnene Prompt enthält F nicht mehr. Ein durch die Korrektur ausgelöster Siegkandidat existiert nie neben einem offenen Prompt.

**AS-G05 · Scheinrolle korrigieren** (Kern: Mechanik am Feld `appears_as`)
- Given: B6, Scheinrolle von B ist `waldhexe`.
- When: `GmCorrection(set_role_field B, field=appears_as, value=schutzengel)` mit Bestätigung und Begründung.
- Then: Scheinrolle ist `schutzengel`; Protokoll mit altem und neuem Wert. Andere Felder (`role_id`, `faction`, `counts_as_wolf`, …) und ungültige Werte werden abgelehnt.

## 8. Vollständige Beispielrunde (Stufe V)

**AS-E01 · Setup bis Sieg**
- Given: 7 Personen: A `werwolf`, B `trugbilderwolf` (Scheinrolle beim Spielaufbau: `schutzengel`), C `schutzengel`, D `das-orakel`, E `waldhexe`, G `sensentraeger`, M `manipulator`; Seed 4711; `reveal_role_on_death` = Nein.
- When: Setup → Rollenanzeige → Nacht 1 (C schützt D, Rudel wählt G, E sieht „G" und verzichtet, D prüft B und erhält `schutzengel`) → Morgen (G stirbt, Reaktion: G verflucht A) → Tag 1 (D nominiert B, Hinrichtung B).
- Then: Nach Tag 1 leben C, D, E, M; kein Wolf lebt → verbindlicher Siegkandidat „Dorf"; kein Manipulator-Kandidat, weil vier Personen leben (DR-12); nach `ConfirmWin` GAME_OVER. Wiederholung mit gleichem Seed und gleichen Befehlen erzeugt dieselbe Eventliste.

---

## 9. Rückverfolgbarkeit der Entscheidungen

| Entscheidung | Regelabschnitt (`rules-register.md`, `vertical-slice-flow.md`) | Akzeptanzszenario |
|---|---|---|
| DR-01 Rollen-IDs | Register §1–§11 (IDs in Überschriften), §12 | AS-C13 |
| DR-02 gleichzeitige Siege, niemand lebt | Register G-SIEG-5; Ablauf §9.1, §9.6 | AS-R34, AS-R35 |
| DR-03 Nominierung | Register G-TAG-2, G-TAG-4; Ablauf §6.1, §7.6 | AS-C11, AS-N01–AS-N05, AS-G03 |
| DR-04 öffentliche Todesinformation | Register G-TOD-5; Ablauf §0.2, §1.5, §4 | AS-M01, AS-M02, AS-M03, AS-L05 |
| Randfall bereits totes Rudelopfer (DL 26.09.2026) | Register §2; Ablauf §4 Schritt 2 | AS-R41 |
| DR-05 Schutzengel | Register §3; Ablauf §3, §4, §8 | AS-R01–AS-R04, AS-R32, AS-R42, AS-R43 |
| DR-06 Waldhexe | Register §6; Ablauf §3 | AS-R05–AS-R08, AS-R39 |
| DR-07 Orakel | Register §4 | AS-R09, AS-R10, AS-R33 |
| DR-08 Trugbilderwolf | Register §5, G-RNG-1, G-GM-3; Ablauf §1.5a, §3 | AS-R11–AS-R14, AS-G05 |
| DR-09 Sensenträger | Register §7, G-TOD-4; Ablauf §4, §7.4 | AS-R15–AS-R17, AS-R37, AS-R40 |
| DR-10 Wolfskind | Register §8, §2 (Rudel); Ablauf §8 | AS-R18–AS-R20, AS-R38 |
| DR-11 Lehrling | Register §9, G-RNG-1; Ablauf §3, §8 | AS-L01–AS-L16 |
| DR-12 Manipulator | Register §10; Ablauf §9.2 | AS-R25, AS-R26, AS-E01 |
| DR-13 Spiegelwolf ohne Nominierung | Register §11; Ablauf §7.6 | AS-R31 |
| DR-14 Siegprüfung und Reaktionen | Register G-SIEG-6; Ablauf §4 Schritt 5, §7.5, §9.1 | AS-R26, AS-R36, AS-A03 |
