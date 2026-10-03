# K1a · Akzeptanzszenarien · Siegreicher Wolf und Doppelspion

**Stand:** 2026-10-03 · **Status:** Spezifikation, nicht umgesetzt
**Regeln:** `rules-register.md` · **Umfang:** `implementation-boundary.md` · **Abhängigkeiten:** `../../role-migration/06-implementation-batches.md` §3.3

Pfade relativ zu `docs/specs/k1a-siegreicher-wolf-doppelspion/`.

## Konventionen

- Konventionen wie `../vertical-slice/acceptance-scenarios.md` (headless Szenariotest, fachlicher Hash, Projektion).
- **Stufe K1a**: muss grün sein, bevor K1a als umgesetzt gilt. Alle bestehenden Szenarien (AS-C, AS-V) bleiben unverändert grün.
- „Kandidaten“ meint die offenen Siegkandidaten nach der verbindlichen Prüfung (G-SIEG-6). „Kein Kandidat“ heißt: die verbindliche Prüfung lief, es entstand keiner.
- Jede Zeile der Abhängigkeitstabelle in `06` §3.3 ist mindestens einem Szenario zugeordnet (Spalte **§3.3** im Titel). Szenarien zu den Antworten vom 3. Oktober 2026 nennen die Entscheidung.

### Personen

Anna, Ben, Clara, David, Emil, Frieda, Gustav, Hanna mit IDs 1–8 in dieser Reihenfolge, sofern ein Szenario nichts anderes sagt. `reveal_role_on_death` = Nein.

---

## 1. Siegreicher Wolf

**AS-K1A-01 · Doppeltes Gewicht in der Parität** (§3.3 Grundregel, Zählung; Bestätigung 3. Oktober 2026)
- Given: Emil `siegreicher-wolf`, Clara, David und Frieda `dorfbewohner` leben; alle anderen sind tot.
- When: Hinrichtung von Frieda wird bestätigt.
- Then: Es leben Emil, Clara, David; genau ein Kandidat „Werwölfe“, Grund Parität mit `wolves` = 2, `non_wolves` = 2.

**AS-K1A-02 · Keine vorzeitige Parität**
- Given: Emil `siegreicher-wolf`, Clara, David, Frieda `dorfbewohner` leben.
- When: verbindliche Prüfung.
- Then: kein Kandidat (2 gegen 3).

**AS-K1A-03 · Gewicht nur, solange er lebt** (§3.3 Muss die Person leben?)
- Given: Anna `werwolf`, Clara, David `dorfbewohner` leben; Emil `siegreicher-wolf` ist tot.
- When: verbindliche Prüfung.
- Then: kein Kandidat (1 gegen 2). Emil trägt nichts bei.

**AS-K1A-04 · Kein Gewicht bei „kein Wolf lebt“** (§3.3 Bedingung)
- Given: Emil `siegreicher-wolf` ist der einzige lebende Wolf; Clara, David, Frieda leben.
- When: Hinrichtung von Emil wird bestätigt.
- Then: genau ein Kandidat „Dorf“. Vor der Hinrichtung (Emil lebt, alle anderen Wölfe tot) entsteht kein Dorfkandidat.

**AS-K1A-05 · Kein Gewicht bei Personenzählungen, gleichzeitige Kandidaten** (§3.3 Gleichzeitige Kandidaten; Bestätigung 3. Oktober 2026)
- Given: Es leben genau Emil `siegreicher-wolf`, Gustav `manipulator` (nie nominiert), Clara und David `dorfbewohner`.
- When: Hinrichtung von David wird bestätigt.
- Then: Es leben drei Personen; zwei Kandidaten ohne Rangfolge: „Werwölfe“ (Parität 2 gegen 2) und „Manipulator Gustav“ (genau drei lebende Personen; Emil zählt als eine Person).

**AS-K1A-06 · Wiederbelebung** (§3.3 Wiederbelebung)
- Given: wie AS-K1A-03, Emil tot.
- When: `GmCorrection revive` Emil.
- Then: verbindliche Prüfung läuft; Kandidat „Werwölfe“ mit `wolves` = 3 (Anna 1, Emil 2), `non_wolves` = 2.

**AS-K1A-07 · Lehrling erbt den Siegreichen Wolf** (§3.3 Lehrling)
- Given: Hanna `lehrling` ist an Emil `siegreicher-wolf` gebunden. Es leben Anna `werwolf`, Emil, Hanna, Clara, David, Frieda.
- When: Emil wird hingerichtet.
- Then: Hanna hat sofort die Rolle `siegreicher-wolf` und zählt als Wolf; verbindliche Prüfung: Anna 1 + Hanna 2 = 3 gegen 3 (Clara, David, Frieda) → Kandidat „Werwölfe“.

**AS-K1A-08 · Zwei Siegreiche Wölfe** (§3.3 Mehrere Personen)
- Given: Anna und Emil `siegreicher-wolf`, Clara, David, Frieda, Gustav `dorfbewohner` leben.
- When: verbindliche Prüfung.
- Then: Kandidat „Werwölfe“ mit `wolves` = 4, `non_wolves` = 4.

**AS-K1A-09 · Ablehnung** (§3.3 Ablehnung)
- Given: Kandidat aus AS-K1A-01 liegt vor.
- When: `RejectWin(reason="Tischregel")`, danach `EndDay` und `StartNight` ohne Tod.
- Then: kein neuer Kandidat. Erst nach dem nächsten Tod oder einer Korrektur wird erneut geprüft (AS-C04).

**AS-K1A-10 · Rollenkorrektur** (§3.3 Spielleiterkorrekturen)
- Given: Anna `werwolf`, Clara, David, Frieda leben (1 gegen 3).
- When: `GmCorrection set_role` Anna → `siegreicher-wolf`, danach `GmCorrection kill` Frieda.
- Then: Nach `set_role` läuft die verbindliche Prüfung: kein Kandidat (2 gegen 3). Nach dem Tod von Frieda: Kandidat „Werwölfe“ (2 gegen 2).

**AS-K1A-11 · Orakel** (§3.3 Orakel und Waldhexe)
- Given: Clara `das-orakel` lebt, Emil `siegreicher-wolf`.
- When: Clara prüft Emil.
- Then: ermitteltes Ergebnis `werwolf`.

**AS-K1A-12 · Rudelschritt mit nur einem Siegreichen Wolf** (Tischablauf, Legacy-Bug F2)
- Given: Emil `siegreicher-wolf` ist der einzige lebende Wolf; vier Nicht-Wölfe leben.
- When: `StartNight`.
- Then: Der Nachtplan enthält den Rudelschritt mit Emil als handelnder Person.

**AS-K1A-13 · Speichern, Laden, Replay** (§3.3 Speichern und Laden)
- Given: Zustand von AS-K1A-01 mit offenem Kandidaten.
- When: Speichern und Laden; Replay derselben Befehlsliste mit demselben Seed.
- Then: Kandidat und Ereigniswerte identisch, fachlicher Hash gleich, Eventliste bytegleich. Für das Gewicht wird kein Feld gespeichert.

**AS-K1A-14 · Bestehende Ereigniswerte unverändert** (K1-SIEG-6)
- Given: Besetzungen von AS-C01, AS-C03, AS-C04.
- When: dieselben Befehle wie dort.
- Then: dieselben Werte `wolves` und `non_wolves` wie heute.

## 2. Doppelspion

**AS-K1A-20 · Nur der Doppelspion statt des Dorfs** (§3.3 Grundregel; RM-DR-155.3 = A)
- Given: Anna `werwolf` ist die letzte lebende Wölfin; Ben `doppelspion`, Clara, David `dorfbewohner` leben.
- When: Hinrichtung von Anna wird bestätigt.
- Then: genau ein Kandidat: Einzelsieg Ben. Kein Kandidat „Dorf“. Nach `ConfirmWin` ist nur Ben Sieger.

**AS-K1A-21 · Toter Doppelspion gewinnt nicht** (§3.3 Muss die Person leben?; RM-DR-155.1 = A)
- Given: Ben `doppelspion` ist in Nacht 2 durch das Rudel gestorben. Anna `werwolf` ist die letzte Wölfin; Clara, David leben.
- When: Hinrichtung von Anna an Tag 3.
- Then: genau ein Kandidat „Dorf“; kein Kandidat für Ben.

**AS-K1A-22 · Ablehnen und selbst erklären** (§3.3 Ablehnung; RM-DR-155.3 = A)
- Given: Kandidat Ben aus AS-K1A-20 ist offen.
- When: `RejectWin(reason="Dorf soll gewinnen")`, danach `GmCorrection declare_winner` Dorf mit Grund.
- Then: Die Partie endet mit Sieger Dorf (Grund `gm_declared`), mit Warnung und Protokolleintrag (G-GM-1).

**AS-K1A-23 · Manipulator weiter gleichzeitig** (§3.3 Gleichzeitige Kandidaten; RM-DR-155.3 = A)
- Given: Es leben Anna `werwolf`, Ben `doppelspion`, Gustav `manipulator` (nie nominiert) und Clara.
- When: Hinrichtung von Anna.
- Then: zwei Kandidaten ohne Rangfolge: Einzelsieg Ben und Manipulator Gustav (genau drei Lebende). Kein Kandidat „Dorf“.

**AS-K1A-24 · Parität mit Doppelspion als Nicht-Wolf** (§3.3 Zählung)
- Given: Anna `werwolf`, Ben `doppelspion`, Clara leben.
- When: verbindliche Prüfung; danach stirbt Clara.
- Then: zuerst kein Kandidat (1 gegen 2); nach Claras Tod Kandidat „Werwölfe“ (1 gegen 1).

**AS-K1A-25 · Abgelehnt, später wieder** (§3.3 Ablehnung)
- Given: Kandidat Ben aus AS-K1A-20 wurde abgelehnt; kein Wolf lebt.
- When: `GmCorrection kill` David.
- Then: Kandidat Einzelsieg Ben entsteht erneut; „Dorf“ weiterhin nicht.

**AS-K1A-26 · Wiederbelebung des Doppelspions** (§3.3 Wiederbelebung)
- Given: Zustand von AS-K1A-21 nach `RejectWin` des Dorfkandidaten.
- When: `GmCorrection revive` Ben.
- Then: verbindliche Prüfung: genau ein Kandidat, Einzelsieg Ben; kein Kandidat „Dorf“.

**AS-K1A-27 · Wolfskind verhindert den Sieg**
- Given: Ben `doppelspion`, Clara `wolfskind` mit Vorbild Anna `werwolf` (letzte Wölfin), David leben.
- When: Hinrichtung von Anna.
- Then: Clara verwandelt sich (zählt als Wolf); kein Doppelspion-Kandidat, kein Dorfkandidat; die Parität ist 1 gegen 2, also kein Kandidat.

**AS-K1A-28 · Lehrling erbt den Doppelspion** (§3.3 Lehrling)
- Given: Hanna `lehrling` ist an Ben `doppelspion` gebunden; Ben stirbt in Nacht 2 durch das Rudel. Anna `werwolf` ist die letzte Wölfin; Hanna, Clara leben.
- When: Morgenauflösung Nacht 2 (Erbe), an Tag 2 Hinrichtung von Anna.
- Then: Hanna ist ab dem Erbe `doppelspion` (Fraktion Einzelsieg, zählt nicht als Wolf). Nach Annas Hinrichtung genau ein Kandidat: Einzelsieg Hanna. Ben erzeugt keinen Kandidaten.

**AS-K1A-29 · Zwei Doppelspione** (§3.3 Mehrere Personen)
- Given: Ben und Frieda `doppelspion`, Clara leben; Anna `werwolf` ist die letzte Wölfin.
- When: Hinrichtung von Anna; dann `ConfirmWin` für den Kandidaten von Frieda.
- Then: zwei Kandidaten (Ben, Frieda), kein Dorf. Nach der Bestätigung ist nur Frieda Siegerin; Bens Kandidat gilt als nicht gewählt.

**AS-K1A-30 · Aufwachen mit dem Rudel** (§3.3 Tischablauf; RM-DR-155.4 = A, RM-DR-155.5)
- Given: Nacht 1, Anna und Emil `werwolf`, Ben `doppelspion` leben.
- When: Rudelschritt beginnt, Antwort mit Opfer Clara.
- Then: Der Prompt nennt Ben dem Spielleiter als mitaufwachende Person (Sichtbarkeit nur Spielleiter). Handelnde Personen des Prompts sind nur Anna und Emil. Gespeichert wird Clara als Rudelopfer. Keine Projektion für Spieler und kein öffentliches Ereignis enthält „doppelspion“. Der Ansagetext nennt keine Rolle. Ob Ben mitzeigen darf, ist offen (RM-DR-155.6); das Szenario prüft nur den gespeicherten Zustand.

**AS-K1A-31 · Toter Doppelspion wacht nicht auf**
- Given: Ben `doppelspion` ist tot, Anna `werwolf` lebt.
- When: Rudelschritt beginnt.
- Then: Ben wird nicht als mitaufwachende Person genannt.

**AS-K1A-32 · Orakel** (§3.3 Orakel und Waldhexe)
- Given: Clara `das-orakel`, Ben `doppelspion`.
- When: Clara prüft Ben.
- Then: ermitteltes Ergebnis `doppelspion`.

**AS-K1A-33 · Reaktion vor der Prüfung**
- Given: Tag. Anna `werwolf` ist die letzte Wölfin; Ben `doppelspion`, Clara `sensentraeger`, David leben.
- When: Hinrichtung von Clara; die Reaktion des Sensenträgers trifft Anna.
- Then: Solange die Reaktion offen ist, entsteht kein Kandidat (G-GM-3). Danach genau ein Kandidat: Einzelsieg Ben.

**AS-K1A-34 · Kein Leck vor der Bestätigung**
- Given: Kandidat Ben aus AS-K1A-20 offen.
- When: Projektionen für alle Spieler und öffentliche Ereignisse werden erzeugt.
- Then: kein Hinweis auf den Kandidaten oder auf Bens Rolle vor `ConfirmWin`.

**AS-K1A-35 · Speichern, Laden, beschädigte Stände** (§3.3 Speichern und Laden)
- Given: offener Kandidat Ben aus AS-K1A-20.
- When: Speichern und Laden; danach getrennte Ladeversuche mit manipulierten Ständen: (a) offener Doppelspion-Kandidat, dessen Person tot ist; (b) offener Doppelspion-Kandidat, obwohl ein Wolf lebt; (c) offener Doppelspion-Kandidat für eine Person mit anderer Rolle; (d) Person `doppelspion` mit `counts_as_wolf` = ja; (e) offener Dorfkandidat, obwohl ein Doppelspion lebt.
- Then: Der unveränderte Stand lädt mit gleichem fachlichen Hash; (a) bis (e) werden abgelehnt. Replay ergibt eine bytegleiche Eventliste.

**AS-K1A-36 · Rollenkorrektur zum Doppelspion** (§3.3 Spielleiterkorrekturen)
- Given: kein Wolf lebt mehr; ein Kandidat „Dorf“ wurde abgelehnt; Clara und David leben.
- When: `GmCorrection set_role` Clara → `doppelspion`.
- Then: verbindliche Prüfung: genau ein Kandidat, Einzelsieg Clara.

**AS-K1A-37 · Niemand lebt**
- Given: Ben `doppelspion` und Anna `werwolf` sind die letzten Lebenden.
- When: `GmCorrection kill` Ben; der entstehende Kandidat „Werwölfe“ (1 gegen 0) wird abgelehnt; `GmCorrection kill` Anna.
- Then: nach dem zweiten Tod kein Kandidat; `requires_gm_decision` = ja (DR-02).
