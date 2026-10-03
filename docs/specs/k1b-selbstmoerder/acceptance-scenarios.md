# K1b · Akzeptanzszenarien · Selbstmörder

**Stand:** 2026-10-03 · **Status:** Spezifikation, nicht umgesetzt; AS-K1B-30 und AS-K1B-31 offen
**Regeln:** `rules-register.md` · **Umfang:** `implementation-boundary.md` · **Abhängigkeiten:** `../../role-migration/06-implementation-batches.md` §3.3

Pfade relativ zu `docs/specs/k1b-selbstmoerder/`.

## Konventionen

- Konventionen wie `../vertical-slice/acceptance-scenarios.md` und `../k1a-siegreicher-wolf-doppelspion/acceptance-scenarios.md`.
- **Stufe K1b**: muss grün sein, bevor K1b als umgesetzt gilt. Szenarien mit **offen** werden erst nach der Antwort auf die genannte Frage festgeschrieben.
- Die Spalte **§3.3** im Titel verweist auf die Zeile der Abhängigkeitstabelle in `06`.

### Standardbesetzung B10S

Personen Anna, Ben, Clara, David, Emil, Frieda, Gustav, Hanna, Ida, Jonas mit IDs 1–10. Anna `werwolf`, Ben `selbstmoerder`, alle anderen `dorfbewohner`, sofern ein Szenario nichts anderes sagt. `reveal_role_on_death` = Nein. **Ausgangslage T5:** Clara, David, Frieda, Gustav und Hanna sind tot; Anna, Ben, Emil, Ida und Jonas leben; es ist Tag und Ben ist nominiert.

---

## 1. Grundregel und Zählung

**AS-K1B-01 · Hinrichtung nach fünf anderen Toten** (§3.3 Grundregel, Bedingung; RM-DR-138.1)
- Given: B10S, Ausgangslage T5.
- When: Hinrichtung von Ben wird bestätigt.
- Then: genau ein Kandidat: Einzelsieg Ben. Kein Paritätskandidat (Anna gegen Emil, Ida, Jonas). Nach `ConfirmWin` ist nur Ben Sieger.

**AS-K1B-02 · Er selbst zählt nicht** (RM-DR-138.1)
- Given: B10S wie T5, aber Hanna lebt (vier andere Tote).
- When: Hinrichtung von Ben.
- Then: Mit Ben sind fünf Personen tot, aber nur vier andere: kein Kandidat.

**AS-K1B-03 · Tod durch Reaktion vor der Prüfung zählt** (§3.3 Bedingung; RM-DR-138.3)
- Given: B10S, aber Hanna `sensentraeger`; Clara, David, Frieda sind tot; Anna, Ben, Emil, Gustav, Hanna, Ida, Jonas leben; Tag.
- When: Hinrichtung von Hanna; ihre Reaktion ist offen. `GmCorrection execute` Ben (mit Warnung und Grund). Danach trifft Hannas Reaktion Emil.
- Then: Während die Reaktion offen ist, entsteht kein Kandidat (G-GM-3). Bei der verbindlichen Prüfung sind außer Ben fünf Personen tot (Clara, David, Frieda, Hanna, Emil): Kandidat Einzelsieg Ben.

**AS-K1B-04 · Wiederbelebte zählen nicht** (§3.3 Wiederbelebung; RM-DR-138.3)
- Given: B10S, T5; vor der Hinrichtung `GmCorrection revive` Clara.
- When: Hinrichtung von Ben.
- Then: vier andere Tote: kein Kandidat.

## 2. Ablehnung

**AS-K1B-10 · Abgelehnter Sieg verfällt nicht** (§3.3 Ablehnung; RM-DR-138.4)
- Given: Kandidat aus AS-K1B-01, `RejectWin(reason="weiterspielen")`.
- When: `EndDay`, `StartNight`; das Rudel wählt Emil; Morgenauflösung.
- Then: Nach Emils Tod läuft die verbindliche Prüfung: Kandidat Einzelsieg Ben entsteht erneut (sechs andere Tote).

**AS-K1B-11 · Ohne relevante Änderung kein neues Angebot** (AS-C04)
- Given: wie AS-K1B-10 nach `RejectWin`.
- When: `EndDay`, `StartNight`, Rudelschritt übersprungen, Morgenauflösung ohne Tod.
- Then: kein neuer Kandidat.

**AS-K1B-12 · Nach Ablehnung fällt die Bedingung weg** (RM-DR-138.3, RM-DR-138.4)
- Given: wie AS-K1B-10 nach `RejectWin`.
- When: `GmCorrection revive` Clara.
- Then: verbindliche Prüfung mit vier anderen Toten: kein Kandidat.

## 3. Welche Hinrichtung zählt

**AS-K1B-20 · Spielleiter-Hinrichtung zählt** (§3.3 Hinrichtungsart, Spielleiterkorrekturen)
- Given: B10S, T5, aber Ben ist nicht nominiert.
- When: `GmCorrection execute` Ben.
- Then: Ursache `LYNCH`; Kandidat Einzelsieg Ben.

**AS-K1B-21 · Spielleiter-Tötung zählt nicht** (§3.3 Spielleiterkorrekturen)
- Given: B10S, T5.
- When: `GmCorrection kill` Ben.
- Then: Ursache `GM_CORRECTION`; kein Selbstmörder-Kandidat.

**AS-K1B-22 · Tod in der Nacht zählt nicht**
- Given: B10S mit den Toten aus T5; es ist Nacht.
- When: Das Rudel wählt Ben; Morgenauflösung.
- Then: Ursache `NIGHT_KILL`; kein Selbstmörder-Kandidat.

**AS-K1B-23 · Tod durch Spiegelung zählt nicht** (§3.3 Hinrichtungsart; RM-DR-138.5)
- Given: B10S, T5, aber Emil `spiegelwolf` (Spiegelung unverbraucht); Ben hat heute Emil nominiert.
- When: Hinrichtung von Emil wird bestätigt.
- Then: Ben stirbt mit `SPIEGELWOLF_RETALIATE`, Emil lebt; kein Selbstmörder-Kandidat. Unabhängig davon entsteht der Kandidat „Werwölfe“ (Anna und Emil gegen Ida und Jonas, 2 gegen 2).

## 4. Wechselwirkungen

**AS-K1B-30 · offen RM-DR-138.6: früh hingerichtet, später genug Tote**
- Given: B10S wie T5, aber Hanna lebt; Ben wird hingerichtet (vier andere Tote, kein Kandidat).
- When: In der folgenden Nacht stirbt Hanna durch das Rudel; Morgenauflösung.
- Then: **offen.** Bei A: Kandidat Einzelsieg Ben. Bei B: kein Kandidat.

**AS-K1B-31 · offen RM-DR-138.7: wiederbelebt, dann anders gestorben**
- Given: Kandidat aus AS-K1B-01 wurde abgelehnt; `GmCorrection revive` Ben.
- When: In der folgenden Nacht stirbt Ben durch das Rudel; Morgenauflösung.
- Then: **offen.** Bei A: kein Selbstmörder-Kandidat. Bei B: Kandidat Einzelsieg Ben.

**AS-K1B-32 · Gleichzeitig mit der Wolfsparität** (§3.3 Gleichzeitige Kandidaten)
- Given: B10S, T5, aber Ida und Jonas sind ebenfalls tot (Anna, Ben, Emil leben).
- When: Hinrichtung von Ben.
- Then: zwei Kandidaten ohne Rangfolge: Einzelsieg Ben und „Werwölfe“ (1 gegen 1).

**AS-K1B-33 · Lehrling erbt den Selbstmörder** (§3.3 Lehrling)
- Given: B10S mit den Toten aus T5, aber Emil `lehrling`, gebunden an Ben; es ist Nacht.
- When: Nacht: Das Rudel wählt Ben; Morgenauflösung. Tag: Hinrichtung von Emil.
- Then: In der Morgenauflösung erbt Emil `selbstmoerder`; Ben (Ursache `NIGHT_KILL`) ist kein Kandidat. Nach Emils Hinrichtung sind außer ihm sechs Personen tot: Kandidat Einzelsieg Emil.

**AS-K1B-34 · Zwei Selbstmörder** (§3.3 Mehrere Personen)
- Given: B10S, aber Ida ebenfalls `selbstmoerder`. Clara, David, Frieda und Gustav sind tot; Ben ist in der letzten Nacht durch das Rudel gestorben; Anna, Emil, Hanna, Ida, Jonas leben; Tag, Ida ist nominiert (andere Tote aus Idas Sicht: Clara, David, Frieda, Gustav, Ben).
- When: Hinrichtung von Ida.
- Then: genau ein Kandidat: Einzelsieg Ida. Ben zählt als andere tote Person, ist aber selbst kein Kandidat.

**AS-K1B-35 · Niemand lebt** (DR-02)
- Given: B10S; außer Anna und Ben sind alle tot; Ben ist nominiert.
- When: Hinrichtung von Ben; beide entstehenden Kandidaten (Einzelsieg Ben, „Werwölfe“ 1 gegen 0) werden abgelehnt; `GmCorrection kill` Anna.
- Then: nach dem letzten Tod kein Kandidat, obwohl Bens Bedingung erfüllt ist; `requires_gm_decision` = ja.

**AS-K1B-36 · Orakel** (§3.3 Orakel und Waldhexe)
- Given: Clara `das-orakel` lebt, Ben `selbstmoerder`.
- When: Clara prüft Ben.
- Then: ermitteltes Ergebnis `selbstmoerder`.

## 5. Speichern, Laden, Sichtbarkeit

**AS-K1B-40 · Speichern, Laden, Replay** (§3.3 Speichern und Laden)
- Given: offener Kandidat aus AS-K1B-01.
- When: Speichern und Laden; Replay derselben Befehlsliste mit demselben Seed.
- Then: gleicher fachlicher Hash, gleicher Kandidat, bytegleiche Eventliste.

**AS-K1B-41 · Beschädigte Spielstände**
- Given: Stand aus AS-K1B-01, getrennt manipuliert: (a) offener Selbstmörder-Kandidat, dessen Person lebt; (b) Todesursache der Person ist nicht `LYNCH` (bei RM-DR-138.7 = A); (c) nur vier andere Tote; (d) Person hat eine andere Rolle.
- When: Laden.
- Then: (a) bis (d) werden abgelehnt.

**AS-K1B-42 · Kein Leck vor der Bestätigung**
- Given: offener Kandidat aus AS-K1B-01.
- When: Projektionen für alle Spieler und öffentliche Ereignisse werden erzeugt.
- Then: kein Hinweis auf den Kandidaten vor `ConfirmWin`; die öffentliche Todesmeldung folgt DR-04.
