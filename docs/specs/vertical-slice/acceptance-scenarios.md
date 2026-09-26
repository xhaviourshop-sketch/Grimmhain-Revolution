# Vertical Slice · Akzeptanzszenarien

**Stand:** 2026-09-26 · **Status:** Entwurf
**Regeln:** `rules-register.md` · **Ablauf:** `vertical-slice-flow.md` · **Umfang:** `implementation-boundary.md`

Pfade relativ zu `docs/specs/vertical-slice/`.

## Konventionen

- Jedes Szenario wird später als headless Szenariotest umgesetzt (`03` §7: `tests/scenarios/*.json` mit Setup, Seed, Befehlen, erwarteten Ereignissen und Endzustand).
- **Stufe** gibt an, wann das Szenario grün sein muss: **C** = Core-Slice (Prompt 2, Masterplan Phase 1), **V** = Vertical Slice (Phase 2/3).
- **Hängt an** nennt offene Entscheidungen. Solange sie offen sind, ist das erwartete Ergebnis für jede Option angegeben oder das Szenario ist gesperrt.
- „Fachlicher Hash" = Hash über den Spielzustand ohne Anzeige- und Zeitwerte (`03` §6.3).
- Standardbesetzung **B6**, sofern nicht anders angegeben: Personen A–F mit stabilen IDs 1–6, Sitzreihenfolge 1–6.
  - A `werwolf`, B `trugbilderwolf`, C `schutzengel`, D `das-orakel`, E `waldhexe`, F `dorfbewohner`.
- Personen werden über Buchstaben benannt; die Sitzposition ist nur relevant, wo ausdrücklich genannt.

---

## 1. Kern (Stufe C)

**AS-C01 · Wolfsparität**
- Given: A `werwolf`, B `werwolf`, C, D, E `dorfbewohner`, alle lebend.
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
- Then: Ereignis mit Grund im Protokoll; Phase unverändert; derselbe Kandidat wird ohne weitere Zustandsänderung nicht erneut angeboten.

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
- Given: gültiger Spielstand mit mindestens zwei Checkpoints.
- When: die jüngste Datei wird manipuliert (Byte geändert, JSON abgeschnitten).
- Then: Laden erkennt den Fehler über den Hash, überschreibt die Datei nicht, meldet ihn und bietet den vorherigen gültigen Checkpoint an.

**AS-C09 · Personen-ID getrennt vom Sitz**
- Given: A (ID 1) auf Sitz 1, B (ID 2) auf Sitz 2; A ist tot.
- When: `ReorderSeats` tauscht die Sitzplätze.
- Then: ID 1 ist weiterhin tot und auf Sitz 2; ID 2 lebt und sitzt auf Sitz 1; kein anderes Feld ändert sich.

**AS-C10 · Todesereignis vollständig**
- Given: B6, Nacht 1.
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

## 2. Undo, Redo, Abbruch (Stufe V)

Undo/Redo gehört laut Masterplan in Phase 3 und ist nicht Teil der Pflichtliste von Prompt 2. Die Szenarien sind deshalb Stufe V, müssen aber schon mit dem Befehls-/Ereignismodell des Core-Slice umsetzbar sein.

**AS-U01 · Undo eines Befehls** (V)
- Given: Tag 1, Hinrichtung von F bestätigt.
- When: Undo.
- Then: F lebt; fachlicher Hash entspricht dem Zustand vor `DecideExecution`; Redo stellt den Tod mit identischem Ereignis wieder her.

**AS-U02 · Undo über Neustart** (V)
- Given: drei bestätigte Befehle, App wird beendet und neu gestartet.
- When: Undo.
- Then: Zustand entspricht dem nach Befehl 2.

**AS-U03 · Undo aller Befehle** (V)
- Given: vollständige Beispielpartie bis Spielende.
- When: Undo bis zum Anfang, dann Redo bis zum Ende.
- Then: Anfangszustand exakt erreicht; Endzustand nach Redo hat denselben Hash wie vorher (Masterplan Phase 3 Gate).

**AS-U04 · Neuer Befehl leert Redo** (V)
- Given: Undo wurde ausgeführt.
- When: anderer Befehl wird bestätigt.
- Then: Redo ist nicht mehr möglich.

**AS-A01 · App-Abbruch mitten in der Hexenkette** (V)
- Given: B6, Nacht 1, Rudel hat F gewählt; Waldhexe-Prompt: „retten = ja" beantwortet, Gift noch offen.
- When: Prozess wird hart beendet und neu gestartet.
- Then: Phase NIGHT, Schritt Waldhexe, offener Prompt mit gespeicherter Teilantwort „retten = ja"; die Rettung ist **noch nicht** angewandt; Rettung ist noch als unverbraucht gespeichert.

**AS-A02 · Abbruch des Prompts** (V)
- Given: wie AS-A01, Teilantwort vorhanden.
- When: `CancelPrompt`.
- Then: fachlicher Hash entspricht dem Zustand vor Beginn des Hexenschritts.

**AS-A03 · Abbruch während einer Reaktion** (V)
- Given: Sensenträger ist gestorben, Reaktion offen.
- When: Neustart.
- Then: Reaktion ist weiterhin offen, Phasenwechsel ist blockiert.

**AS-A04 · Abbruch während der Rollenanzeige** (V)
- Given: 3 von 6 Personen haben `ConfirmRoleShown`.
- When: Neustart.
- Then: Rollenanzeige setzt bei der vierten Person fort; keine Rolle ist im Cockpit sichtbar, bis der Spielleiter die Anzeige verlässt.

## 3. Rollen (Stufe V)

### Schutzengel

**AS-R01 · Schutz hält**
- Given: B6, Nacht 1: C schützt F.
- When: Rudel wählt F, Nacht endet.
- Then: F lebt; `KillPrevented{by: schutzengel}` nur für den Spielleiter; Morgenbericht öffentlich „Niemand ist gestorben".

**AS-R02 · Zielwahl verbraucht keinen Schutz** — hängt an DR-05b
- Given: C schützt F; Rudel wählt zuerst F.
- When: Spielleiter korrigiert die Wolfswahl vor Bestätigung auf D und bestätigt.
- Then (Empfehlung DR-05b): F bleibt geschützt; D stirbt am Morgen. Then (Legacy-Option): F wird ab Wolfswahl als ungeschützt geführt.

**AS-R03 · Schutz läuft ab** — hängt an DR-05a
- Given: C schützt F in Nacht 1; kein Angriff auf F.
- When: Nacht 2, Rudel wählt F; C schützt D.
- Then (Option „diese Nacht"): F stirbt. Then (Option „bis nächster Angriff"): F lebt.

**AS-R04 · Kein Selbstschutz**
- Given: Schutzengel-Prompt.
- Then: C ist nicht in `allowed_seats`.

### Waldhexe

**AS-R05 · Rettung**
- Given: B6, Rudel wählt F.
- When: E rettet F und verzichtet auf Gift.
- Then: F lebt; Rettung für E verbraucht; Gift unverbraucht.

**AS-R06 · Gift** — hängt an DR-06c
- Given: B6, Rudel wählt F.
- When: E rettet nicht und vergiftet A.
- Then: A stirbt mit `WITCH_POISON`, Quelle E (sofort oder am Morgen nach DR-06c); F stirbt am Morgen mit `NIGHT_KILL`; Siegkandidat nur nach G-SIEG-2 (hier: B ist noch Wolf, kein Kandidat).

**AS-R07 · Einmal-Nutzung pro Person** — hängt an DR-06a
- Given: E hat in Nacht 1 gerettet.
- When: Nacht 2, Rudel wählt F.
- Then: Option „rettet" ist nicht verfügbar.

**AS-R08 · Hexe sieht nicht die Rolle** — hängt an DR-06d
- Given: Rudel wählt D (`das-orakel`).
- Then: Die gesicherte Karte für E zeigt nur „D"; die Rolle von D erscheint nur im Spielleiterbereich.

### Orakel und Trugbilderwolf

**AS-R09 · Wahre Information**
- Given: B6, Nacht 1, D wählt F.
- Then: Wahrheit `dorfbewohner`, ermittelt `dorfbewohner`, nach „Gezeigt" gezeigt `dorfbewohner`; alle drei im Ereignis gespeichert, Sichtbarkeit „nur D".

**AS-R10 · Wolf erscheint als Werwolf** — hängt an DR-07a
- Given: A `spiegelwolf` statt `werwolf`; D wählt A.
- Then (Empfehlung): ermittelt „Werwolf"; Wahrheit `spiegelwolf`.

**AS-R11 · Falsche Information durch Trugbilderwolf**
- Given: B6, Seed 4711, D wählt B.
- Then: Wahrheit `trugbilderwolf`; ermittelt ist eine Rolle aus {`schutzengel`, `waldhexe`, `dorfbewohner`} (lebende Nicht-Wölfe ohne Orakel und Trugbilderwolf); die Auswahl ist bei gleichem Seed immer dieselbe.

**AS-R12 · Wiederholte Prüfung** — hängt an DR-08
- Given: wie AS-R11, Nacht 2 prüft D erneut B, alle Personen leben noch.
- Then (Empfehlung): gleiche Scheinrolle wie in Nacht 1. Then (Legacy): neue Ziehung aus dem Seed.

**AS-R13 · Übersteuerte Anzeige**
- Given: ermittelt ist `waldhexe`.
- When: Spielleiter setzt gezeigt auf `dorfbewohner` und bestätigt die Warnung.
- Then: Ereignis enthält ermittelt `waldhexe`, gezeigt `dorfbewohner`, Übersteuerungsgrund.

**AS-R14 · Undo erzeugt keinen neuen Zufall**
- Given: AS-R11 abgeschlossen.
- When: Undo des Orakel-Schritts, gleiche Auswahl erneut bestätigt.
- Then: dieselbe Scheinrolle (Seedposition wird mit dem Undo zurückgesetzt).

### Sensenträger

**AS-R15 · Reaktion nach Nachttod**
- Given: Sensenträger G wird nachts vom Rudel getötet.
- When: Morgenauflösung.
- Then: Reaktion „Sensenträger" erscheint vor dem Morgenbericht; G wählt A; A stirbt mit `HUNTER_SHOT`, Quelle G.

**AS-R16 · Reaktion nach Hinrichtung** — hängt an DR-09b
- Given: Sensenträger G wird hingerichtet.
- Then (Empfehlung): Reaktion unmittelbar nach der Hinrichtung, vor `EndDay`. Then (Legacy): Reaktion erst am nächsten Morgen.

**AS-R17 · Verzicht** — hängt an DR-09a
- When: G wählt „Überspringen".
- Then (Option freiwillig): keine Tötung, Reaktion erledigt, protokolliert.

### Wolfskind

**AS-R18 · Verwandlung**
- Given: Wolfskind W wählt F als Vorbild; ein Wolf A lebt; 4 Nicht-Wölfe inklusive W leben.
- When: F stirbt.
- Then: W zählt als Wolf (`counts_as_wolf` = ja), Rolle bleibt `wolfskind`; Siegprüfung rechnet mit 2 Wölfen; Orakel-Prüfung auf W ergibt „Werwolf".

**AS-R19 · Totes Wolfskind verwandelt sich nicht**
- Given: W ist tot, Vorbild F lebt.
- When: F stirbt.
- Then: keine Verwandlung.

**AS-R20 · Rudelteilnahme** — hängt an DR-10b
- Given: W verwandelt, A ist der einzige andere Wolf und stirbt.
- Then (Empfehlung): Der Rudelschritt existiert weiter (G-PH-6), W wählt das Opfer.

### Lehrling

**AS-R21 · Rollenwechsel**
- Given: Lehrling L wählt E (`waldhexe`) als Mentor; E hat bereits gerettet.
- When: E stirbt.
- Then: L hat `role_id` `waldhexe`, `original_role_id` `lehrling`; `RoleChanged` nur für den Spielleiter; Nutzungen von L nach DR-11b (Empfehlung: Rettung und Gift unverbraucht).

**AS-R22 · Toter Lehrling erbt nicht**
- Given: L ist tot, Mentor E lebt.
- When: E stirbt.
- Then: kein Rollenwechsel (Behebung Bug F5).

**AS-R23 · Wirkungsbeginn** — hängt an DR-11c, DR-06c
- Given: L hat D (`das-orakel`) als Mentor.
- When: Nacht 2, E vergiftet D im Hexenschritt (3.4, vor Orakel 4.6), Gift wirkt nach DR-06c sofort.
- Then (Empfehlung DR-11c): L erhält den Orakel-Schritt erst ab Nacht 3. Then (Legacy): L erhält den Orakel-Schritt noch in Nacht 2.

### Manipulator

**AS-R24 · Tod durch Nominierung**
- Given: Tag 1, M `manipulator` lebt.
- When: F nominiert M.
- Then: `Nomination{F→M}` gespeichert; M stirbt sofort mit `MANIPULATOR_NOMINATED`, Quelle F; Tagesphase bleibt aktiv, weitere Nominierungen sind möglich.

**AS-R25 · Solo-Sieg** — hängt an DR-12a, DR-02
- Given: Es leben M (nie nominiert), A `werwolf`, F `dorfbewohner`, C `schutzengel`.
- When: C stirbt.
- Then: Es leben 3; Siegkandidat „Manipulator".

**AS-R26 · Sprung von 4 auf 2** — hängt an DR-12a, DR-14, DR-02
- Given: Es leben M (nie nominiert), A `werwolf`, G `sensentraeger`, F `dorfbewohner`.
- When: Hinrichtung von G wird bestätigt; G verflucht in seiner Reaktion (sofort nach DR-09b-Empfehlung) F.
- Then: Es leben M und A. Option „höchstens drei": Kandidaten Manipulator und Werwölfe (Parität 1:1) konkurrieren, Auflösung nach DR-02. Option „genau drei" mit DR-14 „erst nach Reaktionen": nur Kandidat Werwölfe. Option „genau drei" mit Legacy-Zeitpunkt (sofort nach jedem Tod): nach dem Tod von G leben genau drei, Kandidat Manipulator entsteht vor der Reaktion.

**AS-R27 · Nominierung durch Undo zurückgenommen**
- Given: AS-R24.
- When: Undo.
- Then: M lebt, Nominierung entfernt, Status „nie nominiert" wiederhergestellt.

### Spiegelwolf

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

**AS-R31 · Hinrichtung ohne Nominierung** — hängt an DR-03, DR-13
- Given: S wurde an diesem Tag nicht nominiert.
- Then (Empfehlung DR-03): Hinrichtung nur per Übersteuerung; dabei fragt die App die nominierende Person ab (DR-13).

## 4. Nominierung (Stufe V)

**AS-N01 · Einmal nominieren** — hängt an DR-03
- Given: Tag 1, A hat bereits nominiert.
- When: A nominiert erneut.
- Then: abgelehnt mit Grund; per Übersteuerung mit Warnung möglich.

**AS-N02 · Einmal nominiert werden** — hängt an DR-03
- Given: F ist an Tag 1 nominiert.
- When: B nominiert F.
- Then: abgelehnt mit Grund.

**AS-N03 · Neuer Tag** — hängt an DR-03
- Given: A hat an Tag 1 nominiert.
- When: Tag 2, A nominiert.
- Then (Empfehlung „pro Tag"): erlaubt.

## 5. Sitztausch (Stufe V)

**AS-S01 · Schutz folgt der Person**
- Given: C schützt F (ID 6, Sitz 6) in Nacht 1.
- When: Spielleiter tauscht vor dem Rudelschritt die Sitze von F und E; Rudel wählt die Person auf Sitz 6 (jetzt E).
- Then: E stirbt am Morgen; F bleibt geschützt; alle Ereignisse referenzieren Personen-IDs.

**AS-S02 · Tausch während offenem Prompt**
- Given: Waldhexe-Prompt offen.
- When: `ReorderSeats`.
- Then: Prompt bleibt offen; `allowed_seats` referenzieren weiterhin dieselben Personen-IDs.

## 6. Morgenbericht und Geheimhaltung (Stufe V)

**AS-M01 · Trennung öffentlich/privat** — hängt an DR-04
- Given: Nacht mit Schutz auf F, Angriff auf F, Gift auf A.
- Then: Öffentlicher Teil nennt nur A (und nach DR-04 ggf. Ursache/Rolle); privater Teil nennt Schutz, Angriff, Gift und Ursachen.

**AS-M02 · Keine Geheimnisse in öffentlicher Projektion**
- Given: beliebiger Zustand.
- When: öffentliche Projektion wird erzeugt.
- Then: keine Rollen lebender Personen, keine Effekte, keine Nachtziele, keine Informationsergebnisse enthalten (Negativtest über alle Felder).

## 7. Übersteuerung (Stufe V)

**AS-G01 · Spielleiter-Tod mit Folgen**
- Given: G `sensentraeger` lebt.
- When: `GmCorrection(kill G, cause=GM_CORRECTION, trigger_effects=true)` nach Warnung.
- Then: G stirbt mit `GM_CORRECTION`; Sensenträger-Reaktion wird eingereiht; Protokolleintrag mit Grund.

**AS-G02 · Spielleiter-Tod ohne Folgen**
- When: wie AS-G01 mit `trigger_effects=false`.
- Then: G stirbt; keine Reaktion; Protokoll vermerkt „ohne Folgen".

## 8. Vollständige Beispielrunde (Stufe V)

**AS-E01 · Setup bis Sieg**
- Given: 7 Personen: A `werwolf`, B `trugbilderwolf`, C `schutzengel`, D `das-orakel`, E `waldhexe`, G `sensentraeger`, M `manipulator`; Seed 4711.
- When: Setup → Rollenanzeige → Nacht 1 (C schützt D, Rudel wählt G, E verzichtet, D prüft B) → Morgen (G stirbt, Reaktion: G verflucht A) → Tag 1 (D nominiert B, Hinrichtung B) → Siegprüfung.
- Then: Nach Tag 1 leben C, D, E, M; kein Wolf lebt → Siegkandidat „Dorf" (unter DR-02 Empfehlung und DR-12 „höchstens drei" kein Manipulator-Kandidat, da 4 Lebende); nach `ConfirmWin` GAME_OVER. Wiederholung mit gleichem Seed und gleichen Befehlen erzeugt dieselbe Eventliste.
