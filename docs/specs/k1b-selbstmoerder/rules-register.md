# K1b · Regelregister · Selbstmörder

**Stand:** 2026-10-03 · **Status:** Spezifikation, nicht umgesetzt; zwei Punkte offen (RM-DR-138.6, RM-DR-138.7); Freigabe durch den Product Owner ausstehend
**Entscheidungen:** `../../masterplan/DECISION-LOG.md`, Eintrag „Rollenmigration K1 · Siegreicher Wolf, Doppelspion, Selbstmörder · 3. Oktober 2026“ · **Szenarien:** `acceptance-scenarios.md` · **Umfang:** `implementation-boundary.md`

Pfade relativ zu `docs/specs/k1b-selbstmoerder/`. Alle Regeln aus `../vertical-slice/rules-register.md` gelten unverändert. Die Ergänzungen für den Siegreichen Wolf und den Doppelspion stehen in `../k1a-siegreicher-wolf-doppelspion/rules-register.md`; K1b hängt nicht von K1a ab.

## Lesehilfe

- **Regeltext DE** ist verbindlich. **Regeltext EN** beschreibt dasselbe Verhalten.
- **Quelle**: `Text` (Rollentext in `../../../js/core/roles.js`), `Code` (Legacy-Verhalten, belegt im Dossier), `DL` (Decision Log), `RM-DR-###` (Entscheidungsanfrage `../../role-migration/08-decision-request.md`).
- **offen** markiert eine noch nicht beantwortete Frage. Für offene Punkte gibt es keine Standardannahme; die betroffenen Szenarien sind als offen gekennzeichnet.

---

## 1. Siegregel

| ID | Regel | Quelle |
|---|---|---|
| K1B-SIEG-1 | **Bedingung.** Bei einer verbindlichen Prüfung (G-SIEG-6) ist der Einzelsieg einer Person ein Kandidat, wenn (a) ihre aktuelle Rolle `selbstmoerder` ist, (b) sie tot ist und ihr Tod die Ursache `LYNCH` hat und (c) außer ihr mindestens fünf Personen tot sind. | Text; RM-DR-138.1 |
| K1B-SIEG-2 | **Wer zählt als tot.** Gezählt wird, wer im Moment der Prüfung tot ist. Wer wiederbelebt wurde und lebt, zählt nicht. Personen, die nach seiner Hinrichtung, aber vor der verbindlichen Prüfung sterben (z. B. durch eine Todesreaktion), zählen mit. | RM-DR-138.3 |
| K1B-SIEG-3 | **Ablehnung.** Ein abgelehnter Kandidat verfällt nicht. Ist die Bedingung bei einer späteren verbindlichen Prüfung erfüllt, entsteht er erneut. Geprüft wird wie immer erst nach einer weiteren relevanten Zustandsänderung (AS-C04). | RM-DR-138.4 |
| K1B-SIEG-4 | **Welche Hinrichtung zählt.** Ursache `LYNCH`, auch per `GmCorrection execute` (Korrekturrunde Regelkern 4). Nicht: Tod durch Spiegelung (`SPIEGELWOLF_RETALIATE`, RM-DR-138.5), `GmCorrection kill` (`GM_CORRECTION`), Tod in der Nacht, Tod durch Nominierung. Der Henker folgt später (RM-DR-138.2). | DL; G-TOD-3 |
| K1B-SIEG-5 | **offen RM-DR-138.6.** Ob eine Hinrichtung, bei der die Bedingung (c) noch nicht erfüllt war, bei einer späteren Prüfung noch zum Sieg führt. A: ja, K1B-SIEG-1 gilt bei jeder Prüfung. B: nein, die Bedingung muss bei der ersten verbindlichen Prüfung nach seiner Hinrichtung erfüllt sein; danach gilt K1B-SIEG-3. | RM-DR-138.6 |
| K1B-SIEG-6 | **offen RM-DR-138.7.** Ob nach seiner eigenen Wiederbelebung nur ein erneuter Tod durch Hinrichtung zählt (A) oder eine frühere Hinrichtung gültig bleibt, egal wie er später stirbt (B). | RM-DR-138.7 |
| K1B-SIEG-7 | **Unverändert:** alle gleichzeitig erfüllten Bedingungen bilden eine Kandidatenmenge (G-SIEG-3); je Selbstmörder ein personenbezogener Kandidat; keine Kandidaten bei offenem Prompt oder offener Reaktion (G-GM-3); lebt niemand, entsteht kein Kandidat (DR-02); bestätigt der Spielleiter den Kandidaten, gewinnt nur diese Person. | G-SIEG-3 bis G-SIEG-6, DR-02 |

---

## 2. `selbstmoerder` · Selbstmörder / Death Seeker

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Selbstmörder gehört zu keiner Seite und zählt nie als Werwolf. Wird er hingerichtet und sind außer ihm mindestens fünf Personen tot, gewinnt er allein. Wer wiederbelebt wurde, zählt nicht als tot. *(Wortlaut unter Vorbehalt von RM-DR-138.6 und .7.)* |
| Regeltext EN | The Death Seeker belongs to no side and never counts as a werewolf. If they are executed and at least five other people are dead, they win alone. Anyone who has been revived does not count as dead. *(Wording subject to RM-DR-138.6 and .7.)* |
| Fraktion | Einzelsieg. `counts_as_wolf` = nein; zählt in G-SIEG-2 als Nicht-Wolf |
| Nachtpriorität | keine |
| Gültige Ziele | keine |
| Dauer | passiv |
| Auflösung | Siegprüfung nach §1. Seine Hinrichtung läuft normal über `ExecutionRules` (Nominierung, Spiegelung, Todesfolgen) |
| Konflikte | Ein anderer toter Selbstmörder zählt als „andere tote Person“. Macht seine Hinrichtung die Wölfe zum Paritätssieger, entstehen beide Kandidaten (G-SIEG-3). Hat er einen Spiegelwolf nominiert und stirbt durch dessen Spiegelung, gibt es keinen Selbstmörder-Sieg (RM-DR-138.5) |
| Siegbezug | eigener personenbezogener Kandidat; Nicht-Wolf in G-SIEG-2 |
| Information | Orakel: `selbstmoerder` (DR-07). Waldhexe nach einer Rettung: tatsächliche Rolle. Als Scheinrolle eines Trugbilderwolfs zulässig (Nicht-Wolf-Rolle, DR-08) |
| Lehrling | erbt der Lehrling die Rolle, gilt die Siegbedingung sofort; das Erbe läuft vor der Siegprüfung (DL Lehrling). Ein Meister, der mit Ursache `LYNCH` stirbt und dabei die Rolle `selbstmoerder` hat, kann selbst Kandidat sein |
| Manuelle Übersteuerung | `execute` zählt als Hinrichtung; `kill` nicht; `revive` und `set_role` stoßen die verbindliche Prüfung an |
| Nicht enthalten | Henker-Hinrichtung (RM-DR-138.2, Charge K4), Brand des Feuerteufels, Voodoo-Puppe, Liebespaar (spätere Chargen) |
| Legacy-Beleg | `doLynchFlow` in `js/core/night.js` (`:421-423`, `:474-482`); Dossier `../../role-migration/dossiers/solos-a.md` Abschnitt `selbstmoerder`. Abweichung zur Legacy-App: dort zählt die Totenzahl vor der Hinrichtung und der Sieg wird ohne Guard gesetzt (Bug 1 im Dossier) |

---

## 3. Entscheidungsgrundlage

| Frage | Antwort | Quelle |
|---|---|---|
| Zählt er selbst mit? | nein, mindestens 5 andere | RM-DR-138.1 |
| Welche Hinrichtung? | `LYNCH`, auch per Spielleiterkorrektur; Henker später | DL Korrekturrunde 4; RM-DR-138.2 |
| Wer zählt als tot? | wer im Moment der Prüfung tot ist | RM-DR-138.3 |
| Abgelehnter Sieg | verfällt nicht | RM-DR-138.4 |
| Tod durch Spiegelung | keine Hinrichtung des Selbstmörders | RM-DR-138.5 |
| Späterer Sieg nach früher Hinrichtung | **offen** | RM-DR-138.6 |
| Anspruch nach eigener Wiederbelebung | **offen** | RM-DR-138.7 |
