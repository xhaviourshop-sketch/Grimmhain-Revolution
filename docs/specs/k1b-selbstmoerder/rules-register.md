# K1b · Regelregister · Selbstmörder

**Stand:** 2026-10-03 · **Status:** bereit zur Umsetzung, wartet auf Grimmhain-1; keine offene Produktfrage
**Entscheidungen:** `../../masterplan/DECISION-LOG.md`, Eintrag „Rollenmigration K1 · Siegreicher Wolf, Doppelspion, Selbstmörder · 3. Oktober 2026“ · **Szenarien:** `acceptance-scenarios.md` · **Umfang:** `implementation-boundary.md`

Pfade relativ zu `docs/specs/k1b-selbstmoerder/`. Alle Regeln aus `../vertical-slice/rules-register.md` gelten unverändert. Die Ergänzungen für den Siegreichen Wolf und den Doppelspion stehen in `../k1a-siegreicher-wolf-doppelspion/rules-register.md`; K1b hängt nicht von K1a ab.

## Lesehilfe

- **Regeltext DE** ist verbindlich. **Regeltext EN** beschreibt dasselbe Verhalten.
- **Quelle**: `Text` (Rollentext in `../../../js/core/roles.js`), `Code` (Legacy-Verhalten, belegt im Dossier), `DL` (Decision Log), `RM-DR-###` (Entscheidungsanfrage `../../role-migration/08-decision-request.md`).

---

## 1. Siegregel

| ID | Regel | Quelle |
|---|---|---|
| K1B-SIEG-1 | **Anspruch im Moment der Hinrichtung.** Stirbt eine Person mit aktueller Rolle `selbstmoerder` mit Ursache `LYNCH`, wird in genau diesem Moment gezählt, bevor Folgen dieses Todes (Todesreaktionen, Erbe, Verwandlung) abgearbeitet werden. Sind außer ihr mindestens fünf Personen tot, erhält sie einen Hinrichtungsanspruch, sonst nicht. | Text; RM-DR-138.1; RM-DR-138.6 |
| K1B-SIEG-2 | **Wer zählt als tot.** Gezählt wird, wer in diesem Moment tot ist; wer wiederbelebt wurde und lebt, zählt nicht. Wer danach stirbt, auch durch eine Reaktion vor der verbindlichen Prüfung, macht keinen nachträglichen Sieg. | RM-DR-138.3, RM-DR-138.6; Lesart im DL-Eintrag vom 3. Oktober 2026 |
| K1B-SIEG-3 | **Kandidat.** Bei jeder verbindlichen Prüfung (G-SIEG-6) ist der Einzelsieg einer Person ein Kandidat, wenn sie einen Hinrichtungsanspruch hat, tot ist und ihre aktuelle Rolle `selbstmoerder` ist. | RM-DR-138.1 |
| K1B-SIEG-4 | **Ablehnung.** Ein abgelehnter Kandidat verfällt nicht. Bei jeder späteren verbindlichen Prüfung entsteht er erneut, solange der Anspruch besteht; geprüft wird wie immer erst nach einer weiteren relevanten Zustandsänderung (AS-C04). Die Wiederbelebung einer anderen Person ändert den Anspruch nicht. | RM-DR-138.4 |
| K1B-SIEG-5 | **Wiederbelebung.** Wird die Person wiederbelebt, verfällt ihr Hinrichtungsanspruch. Stirbt sie später auf anderem Weg, gewinnt sie nicht. Eine erneute Hinrichtung ist ein neuer Moment nach K1B-SIEG-1. | RM-DR-138.7 |
| K1B-SIEG-6 | **Welche Hinrichtung zählt.** Ursache `LYNCH`, auch per `GmCorrection execute` (Korrekturrunde Regelkern 4). Nicht: Tod durch Spiegelung (`SPIEGELWOLF_RETALIATE`, RM-DR-138.5), `GmCorrection kill` (`GM_CORRECTION`), Tod in der Nacht, Tod durch Nominierung. Der Henker folgt später (RM-DR-138.2). | DL; G-TOD-3 |
| K1B-SIEG-7 | **Unverändert:** alle gleichzeitig erfüllten Bedingungen bilden eine Kandidatenmenge (G-SIEG-3); je Selbstmörder ein personenbezogener Kandidat; keine Kandidaten bei offenem Prompt oder offener Reaktion (G-GM-3); lebt niemand, entsteht kein Kandidat (DR-02); bestätigt der Spielleiter den Kandidaten, gewinnt nur diese Person. | G-SIEG-3 bis G-SIEG-6, DR-02 |

---

## 2. `selbstmoerder` · Selbstmörder / Death Seeker

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Selbstmörder gehört zu keiner Seite und zählt nie als Werwolf. Wird er hingerichtet, während außer ihm schon mindestens fünf Personen tot sind, gewinnt er allein. Wer danach stirbt, zählt nicht; wer wiederbelebt wurde, zählt nicht als tot. Wird er selbst wiederbelebt, verfällt seine Hinrichtung. |
| Regeltext EN | The Death Seeker belongs to no side and never counts as a werewolf. If they are executed while at least five other people are already dead, they win alone. Deaths after the execution do not count, and anyone who has been revived does not count as dead. If the Death Seeker is revived, their execution no longer counts. |
| Fraktion | Einzelsieg. `counts_as_wolf` = nein; zählt in G-SIEG-2 als Nicht-Wolf |
| Nachtpriorität | keine |
| Gültige Ziele | keine |
| Dauer | passiv; der Hinrichtungsanspruch gilt bis zur eigenen Wiederbelebung |
| Auflösung | Siegprüfung nach §1. Seine Hinrichtung läuft normal über `ExecutionRules` (Nominierung, Spiegelung, Todesfolgen) |
| Konflikte | Ein anderer toter Selbstmörder zählt als „andere tote Person“. Macht seine Hinrichtung die Wölfe zum Paritätssieger, entstehen beide Kandidaten (G-SIEG-3). Hat er einen Spiegelwolf nominiert und stirbt durch dessen Spiegelung, gibt es keinen Selbstmörder-Sieg (RM-DR-138.5) |
| Siegbezug | eigener personenbezogener Kandidat; Nicht-Wolf in G-SIEG-2 |
| Information | Orakel: `selbstmoerder` (DR-07). Waldhexe nach einer Rettung: tatsächliche Rolle. Als Scheinrolle eines Trugbilderwolfs zulässig (Nicht-Wolf-Rolle, DR-08) |
| Lehrling | erbt der Lehrling die Rolle, gilt die Siegbedingung sofort; das Erbe läuft vor der Siegprüfung (DL Lehrling). Ein Meister, der mit Ursache `LYNCH` stirbt und dabei die Rolle `selbstmoerder` hat, kann selbst Kandidat sein |
| Manuelle Übersteuerung | `execute` zählt als Hinrichtung; `kill` nicht; `revive` lässt den Anspruch verfallen; `revive` und `set_role` stoßen die verbindliche Prüfung an |
| Nicht enthalten | Henker-Hinrichtung (RM-DR-138.2, Charge K4), Brand des Feuerteufels, Voodoo-Puppe, Liebespaar (spätere Chargen) |
| Legacy-Beleg | `doLynchFlow` in `js/core/night.js` (`:421-423`, `:474-482`); Dossier `../../role-migration/dossiers/solos-a.md` Abschnitt `selbstmoerder`. Abweichung zur Legacy-App: dort zählt die Totenzahl vor der Hinrichtung und der Sieg wird ohne Guard gesetzt (Bug 1 im Dossier) |

---

## 3. Entscheidungsgrundlage

| Frage | Antwort | Quelle |
|---|---|---|
| Zählt er selbst mit? | nein, mindestens 5 andere | RM-DR-138.1 |
| Welche Hinrichtung? | `LYNCH`, auch per Spielleiterkorrektur; Henker später | DL Korrekturrunde 4; RM-DR-138.2 |
| Wer zählt als tot? | wer im Moment der Hinrichtung tot ist; Wiederbelebte nicht | RM-DR-138.3 mit RM-DR-138.6 |
| Abgelehnter Sieg | verfällt nicht | RM-DR-138.4 |
| Tod durch Spiegelung | keine Hinrichtung des Selbstmörders | RM-DR-138.5 |
| Späterer Sieg nach früher Hinrichtung | nein | RM-DR-138.6 |
| Anspruch nach eigener Wiederbelebung | verfällt | RM-DR-138.7 |
