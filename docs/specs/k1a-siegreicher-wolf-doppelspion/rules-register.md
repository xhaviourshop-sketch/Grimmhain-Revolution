# K1a · Regelregister · Siegreicher Wolf und Doppelspion

**Stand:** 2026-10-03 · **Status:** Spezifikation, nicht umgesetzt; Freigabe durch den Product Owner ausstehend
**Entscheidungen:** `../../masterplan/DECISION-LOG.md`, Eintrag „Rollenmigration K1 · Siegreicher Wolf, Doppelspion, Selbstmörder · 3. Oktober 2026“ · **Szenarien:** `acceptance-scenarios.md` · **Umfang:** `implementation-boundary.md`

Pfade relativ zu `docs/specs/k1a-siegreicher-wolf-doppelspion/`. Alle Regeln aus `../vertical-slice/rules-register.md` (G-ID, G-INF, G-PH, G-TOD, G-TAG, G-SIEG, G-GM) gelten unverändert, soweit dieses Register nichts anderes sagt. Abweichungen stehen ausdrücklich in §1 und nennen ihre Entscheidung.

## Lesehilfe

- **Regeltext DE** ist verbindlich. **Regeltext EN** beschreibt dasselbe Verhalten.
- **Quelle**: `Text` (Rollentext in `../../../js/core/roles.js`), `Code` (Legacy-Verhalten, belegt im Dossier), `DL` (Decision Log), `RM-DR-###` (Entscheidungsanfrage `../../role-migration/08-decision-request.md`).
- **offen** markiert eine Frage, die der Product Owner noch nicht beantwortet hat. Für offene Punkte gibt es keine Standardannahme.

---

## 1. Ergänzungen der Siegregeln

| ID | Regel | Quelle |
|---|---|---|
| K1-SIEG-1 | **Gewicht in der Wolfsparität.** In G-SIEG-2 zählt jede lebende Person mit aktueller Rolle `siegreicher-wolf` als zwei Wölfe, jede andere lebende Person, die als Wolf zählt, als ein Wolf. Nicht-Wölfe zählen je Person einfach. Tote zählen nicht. | DL 3. Oktober 2026 (Bestätigung); Text; Code `countLivingWolfPower` |
| K1-SIEG-2 | **Gewicht nur dort.** G-SIEG-1 („kein lebender Mensch zählt als Wolf“), die Manipulator-Bedingung („genau drei Personen leben“) und jede andere Zählung von Personen zählen den Siegreichen Wolf als eine Person. | DL 3. Oktober 2026 |
| K1-SIEG-3 | **Doppelspion-Kandidat.** Lebt keine Person, die als Wolf zählt, entsteht für jede lebende Person mit aktueller Rolle `doppelspion` ein eigener personenbezogener Einzelsiegkandidat. Ein toter Doppelspion erzeugt keinen Kandidaten. | Text; RM-DR-155.1 = A |
| K1-SIEG-4 | **Ausnahme zum Dorfkandidaten.** Entsteht nach K1-SIEG-3 mindestens ein Doppelspion-Kandidat, entsteht kein Dorfkandidat (G-SIEG-1). Alle übrigen gleichzeitig erfüllten Bedingungen (z. B. Manipulator) bleiben Kandidaten (G-SIEG-3). Der Spielleiter kann alle Kandidaten ablehnen und das Ergebnis selbst erklären (`GmCorrection declare_winner`, G-GM-1). | RM-DR-155.3 = A; bewusste Ausnahme zu G-SIEG-1 und G-SIEG-3 |
| K1-SIEG-5 | **Unverändert:** Kandidaten entstehen erst aus dem endgültigen Zustand nach allen Reaktionen (G-SIEG-6, DR-14); bei offenem Prompt oder offener Reaktion entsteht keiner (G-GM-3); lebt niemand, entsteht keiner (DR-02); nach `RejectWin` wird erst nach einer weiteren relevanten Zustandsänderung erneut geprüft (AS-C04). Bestätigt der Spielleiter einen Doppelspion-Kandidaten, gewinnt nur die begünstigte Person. | G-SIEG-3 bis G-SIEG-6, DR-02, DR-14 |
| K1-SIEG-6 | **Ereigniswerte (technisch).** Die Werte `wolves` und `non_wolves` in den Siegereignissen sind die Seiten des Vergleichs aus K1-SIEG-1: `wolves` ist das Gewicht, `non_wolves` die Anzahl der Nicht-Wölfe. Ohne Siegreichen Wolf sind beide Zahlen identisch mit heute; AS-C01, AS-C03 und AS-C04 bleiben unverändert. | technisch, `../../role-migration/06-implementation-batches.md` §3.5 |

---

## 2. `siegreicher-wolf` · Siegreicher Wolf / Victorious Wolf

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Siegreiche Wolf ist ein Werwolf und wacht mit dem Rudel auf. Solange er lebt, zählt er beim Vergleich der Werwölfe mit allen anderen wie zwei Werwölfe. Bei allen anderen Zählungen ist er eine Person. |
| Regeltext EN | The Victorious Wolf is a werewolf and wakes up with the pack. As long as they are alive, they count as two werewolves when the werewolves are compared with everyone else. In every other count they are one person. |
| Fraktion | Werwölfe. `counts_as_wolf` = ja |
| Nachtpriorität | kein eigener Schritt; nimmt am Rudelschritt (2.0) teil wie jeder lebende Wolf (G-PH-2). Der Rudelschritt entsteht auch, wenn er der einzige lebende Wolf ist (behebt Legacy-Bug F2) |
| Gültige Ziele | wie im Rudelschritt (Regelregister §2) |
| Dauer | passiv, solange er lebt und die Rolle hat |
| Auflösung | wirkt nur in der Siegprüfung (K1-SIEG-1, K1-SIEG-2) |
| Konflikte | Mehrere Siegreiche Wölfe zählen je zwei. Wiederbelebt zählt er wieder zwei. Ändert eine Korrektur seine Rolle, zählt er nach der neuen Rolle |
| Siegbezug | G-SIEG-2 mit Gewicht 2 (K1-SIEG-1); G-SIEG-1 ohne Gewicht |
| Information | Orakel: `werwolf` (DR-07, wie jeder Sonderwolf). Waldhexe nach einer Rettung: tatsächliche Rolle. Als Scheinrolle eines Trugbilderwolfs nicht zulässig (Wolfsrolle, DR-08) |
| Lehrling | erbt der Lehrling die Rolle, zählt er sofort zwei (Korrekturrunde Regelkern 2) |
| Manuelle Übersteuerung | nur allgemeine Korrekturen (`set_role`, `kill`, `revive`, `declare_winner`); jede stößt die verbindliche Siegprüfung an |
| Legacy-Beleg | `countLivingWolfPower` und `checkTeamWin` in `js/ui/core.js` (`:21-29`, `:311-312`); Dossier `../../role-migration/dossiers/wolves-a.md` Abschnitt `siegreicher-wolf` |

---

## 3. `doppelspion` · Doppelspion / Double Agent

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Doppelspion gehört zu keiner Seite und zählt nie als Werwolf. In der Nacht wacht er gemeinsam mit den Werwölfen auf; der Spielleiter nennt dabei keine Rolle. Lebt kein Werwolf mehr, während der Doppelspion lebt, gewinnt er allein statt des Dorfs. |
| Regeltext EN | The Double Agent belongs to no side and never counts as a werewolf. At night they wake up together with the werewolves; the game master does not name their role. If no werewolf is alive while the Double Agent is alive, they win alone instead of the village. |
| Fraktion | Einzelsieg. `counts_as_wolf` = nein; zählt in G-SIEG-2 als Nicht-Wolf (RM-DR-155.2) |
| Nachtpriorität | kein eigener Schritt. Lebt er, nennt der Rudelschritt ihn dem Spielleiter als mitaufwachende Person (nur Spielleiter-Sichtbarkeit). Ein toter Doppelspion wacht nicht auf (G-PH-2) |
| Gültige Ziele | keine. Gespeichert wird nur das Opfer der Werwölfe (Regelregister §2, RM-DR-155.5). **offen RM-DR-155.6:** ob er am Tisch mitzeigen darf; betrifft nur den Ansagetext |
| Dauer | passiv, solange er lebt und die Rolle hat |
| Auflösung | Siegprüfung nach K1-SIEG-3 und K1-SIEG-4 |
| Konflikte | Mehrere Doppelspione: je Person ein Kandidat, kein Dorfkandidat. Manipulator gleichzeitig erfüllt: beide Kandidaten. Verwandelt sich ein Wolfskind im selben Tod, lebt wieder ein Wolf und es entsteht kein Doppelspion-Kandidat. Das Rudel darf ihn als Opfer wählen |
| Siegbezug | eigener personenbezogener Kandidat; unterdrückt den Dorfkandidaten (K1-SIEG-4); Nicht-Wolf in G-SIEG-2 |
| Information | Orakel: `doppelspion` (keine besondere Erscheinung, DR-07). Waldhexe nach einer Rettung: tatsächliche Rolle. Als Scheinrolle eines Trugbilderwolfs zulässig (Nicht-Wolf-Rolle, DR-08) |
| Tischablauf | Die Werwölfe sehen ihn als Mitaufwachenden und erfahren nicht, dass er der Spion ist (RM-DR-155.4 = A). Kein öffentlicher Text und keine Projektion für Spieler nennt ihn im Zusammenhang mit dem Rudel |
| Lehrling | erbt der Lehrling die Rolle, gelten Fraktion und Siegbedingung sofort (Korrekturrunde Regelkern 2) |
| Manuelle Übersteuerung | allgemeine Korrekturen; `declare_winner` ist immer möglich, auch für das Dorf |
| Nicht enthalten | „Der Angriff des Rachsüchtigen Wolfs verpufft an ihm“: wird mit `rachsuechtiger-wolf` (Charge K11) umgesetzt, bis dahin ohne Wirkung |
| Legacy-Beleg | `isWolf` (`js/ui/core.js:13`), `checkWinConditions` (`:227-230`), `checkTeamWin` (`:314-320`); Dossier `../../role-migration/dossiers/solos-a.md` Abschnitt `doppelspion` |

---

## 4. Entscheidungsgrundlage

| Frage | Antwort | Quelle |
|---|---|---|
| Gewicht des Siegreichen Wolfs | nur Wolfsparität, nur lebend | DL 3. Oktober 2026 |
| Muss der Doppelspion leben? | ja | RM-DR-155.1 = A |
| Zählt er in der Parität? | als Nicht-Wolf | RM-DR-155.2, G-SIEG-2 |
| Dorf zusätzlich vorgeschlagen? | nein; andere Siege weiter gleichzeitig | RM-DR-155.3 = A |
| Was erfahren die Wölfe? | keine Rolle | RM-DR-155.4 = A |
| Teilnahme an der gespeicherten Rudelwahl | nein | RM-DR-155.5 (technisch) |
| Mitzeigen am Tisch | **offen** | RM-DR-155.6 |
