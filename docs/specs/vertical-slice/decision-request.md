# Vertical Slice · Entscheidungsanfrage an den Product Owner

**Stand:** 2026-09-26 · **Status:** offen
**Bezug:** `rules-register.md` (Abschnitte „DECISION REQUIRED"), `acceptance-scenarios.md`, `implementation-boundary.md`

Pfade relativ zu `docs/specs/vertical-slice/`.

Diese Datei enthält **nur** Entscheidungen, ohne die der Core-Slice oder der Vertical Slice nicht regelkonform gebaut werden kann. Jede Empfehlung ist ein Vorschlag, keine Entscheidung. Nach der Entscheidung werden die Ergebnisse in `../../masterplan/DECISION-LOG.md` eingetragen und die `⟨DR-xx⟩`-Stellen in `rules-register.md` ersetzt.

**Nicht gefragt**, weil bereits entschieden: Legacy-Bugs aus `../../godot-migration/07-open-questions.md` Q1 Teil 2 werden behoben (u. a. fehlende Wolfszeile F2, toter Lehrling erbt F5, zwei Siegprüfer F7, manueller Tod ohne Folgen F6). Grundlage: `DECISION-LOG.md` „Offensichtliche Bugs werden nicht als Referenzverhalten portiert."

## Übersicht

| ID | Frage | Blockiert ab | Empfehlung |
|---|---|---|---|
| DR-01 | Schema der technischen Rollen-IDs | **Core-Slice** | A · deutsches kebab-case |
| DR-03 | Nominierungsregeln | **Core-Slice** | A · pro Tag, nur Lebende, Hinrichtung nur nach Nominierung |
| DR-02 | Siegpriorität, „niemand lebt" | Vertical Slice | A · Einzelsieg vor Werwölfen vor Dorf |
| DR-14 | Siegprüfung bei offenen Reaktionen | Vertical Slice | A · erst nach allen Reaktionen |
| DR-04 | Öffentliche Information bei Tod | Vertical Slice | A · nur Name |
| DR-05 | Schutzengel: Dauer und Verbrauch | Vertical Slice | a A, b A |
| DR-06 | Waldhexe: Tränke, Zeitpunkt, Anzeige | Vertical Slice | a A, b A, c A, d A |
| DR-07 | Orakel: Ergebnis bei Wölfen, Selbstwahl | Vertical Slice | a A, c A |
| DR-08 | Trugbilderwolf: Ziehungszeitpunkt | Vertical Slice | B |
| DR-09 | Sensenträger: Pflicht und Zeitpunkt | Vertical Slice | a A, b A |
| DR-10 | Wolfskind: Selbstwahl, Rudelteilnahme | Vertical Slice | a A, b A |
| DR-11 | Lehrling: Mentoren, Nutzungen, Wirkungsbeginn | Vertical Slice | a A, b A, c B, d A |
| DR-12 | Manipulator: „Final 3" | Vertical Slice | B |
| DR-13 | Spiegelwolf ohne gespeicherte Nominierung | Vertical Slice, entfällt bei DR-03 A ohne Übersteuerung | A |

---

## DR-01 · Schema der technischen Rollen-IDs

**Kontext.** `../../masterplan/RULE-MIGRATION-MATRIX.md` nutzt `villager`, `werewolf`. `../../godot-migration/03-godot-architecture.md` §5.1 und `04` nutzen `dorfbewohner`, `werwolf`, `das-orakel`. Legacy verwendet deutsche Anzeigenamen als ID (`ALL_ROLES` in `../../../js/core/roles.js`). IDs werden ab dem ersten Godot-Commit in Spielständen gespeichert.

| Option | Auswirkung |
|---|---|
| **A · deutsches ASCII-kebab-case** (`werwolf`, `das-orakel`) | passt zu `03`, `04`, Asset-Dateinamen (`../../architecture/tablet-asset-spec.md`) und der Legacy-Zuordnung; `RULE-MIGRATION-MATRIX.md` muss angepasst werden |
| B · englisches kebab-case (`werewolf`, `the-oracle`) | international lesbarer Code; alle Verweise in `03`/`04` und Assetnamen müssen umbenannt werden |

**Empfehlung: A.** Anzeigenamen sind ohnehin lokalisiert; eine Umbenennung nach dem ersten Spielstand erfordert Migrationen.

## DR-03 · Nominierungsregeln

**Kontext.** `DECISION-LOG.md`: Jede Person nominiert standardmäßig einmal und wird einmal nominiert. Offen sind Bezugszeitraum, Berechtigung und ob eine Hinrichtung eine Nominierung voraussetzt. Legacy speichert nur ein Flag `nominated` und setzt es bei Nachtbeginn zurück (`onNightStart` in `../../../js/core/night.js`); Nominierende werden nicht gespeichert.

| Option | Auswirkung |
|---|---|
| **A · pro Tag; nur lebende Personen nominieren und werden nominiert; Hinrichtung nur für an diesem Tag Nominierte, sonst Übersteuerung mit Warnung** | klare Validierung im Core; Spiegelwolf hat immer eine nominierende Person; Manipulator-Tod ist eindeutig |
| B · wie A, aber Hinrichtung auch ohne Nominierung ohne Warnung erlaubt | flexibler für Hausregeln; DR-13 wird nötig |
| C · einmal pro Partie statt pro Tag | sehr restriktiv; in größeren Runden gehen Nominierende früh aus |

**Empfehlung: A.** Blockiert den Core-Slice, weil `Nominate` und `DecideExecution` dort validiert werden (AS-C11, AS-N01–N03).

## DR-02 · Siegpriorität und „niemand lebt"

**Kontext.** `07` Q4 schlägt „Solo vor Wölfen vor Dorf" vor, entschieden ist das nicht. Legacy: `checkWinConditions` (`../../../js/ui/core.js`) prüft Dorf vor Werwölfen vor Manipulator und ruft bei null Lebenden den Dorfsieg aus; `checkTeamWin` ruft bei null Lebenden keinen Sieg aus. Im Slice relevant: Manipulator gegen Wolfsparität (AS-R26).

| Option | Auswirkung |
|---|---|
| **A · Einzelsieg vor Werwölfen vor Dorf; niemand lebt → kein automatischer Kandidat, Spielleiter erklärt das Ergebnis** | Einzelsiegrollen bleiben attraktiv; keine erfundene Siegerregel für den Totalausfall |
| B · Legacy-Reihenfolge Dorf vor Werwölfen vor Einzelsieg; niemand lebt → Dorf | Manipulator gewinnt bei Gleichzeitigkeit nie |
| C · gleichzeitige Kandidaten → Spielleiter wählt immer selbst | keine feste Regel; langsamer, aber nie falsch automatisch |

**Empfehlung: A.**

## DR-14 · Siegprüfung bei offenen Reaktionen

**Kontext.** Legacy löst den Sieg nach jedem Tod sofort aus (`checkWinConditions` am Ende von `applyKill`), auch wenn z. B. ein Sensenträger noch reagieren darf. Die Reaktion kann das Ergebnis ändern.

| Option | Auswirkung |
|---|---|
| **A · Siegkandidat erst, wenn kein Prompt und keine Reaktion offen ist** | Ergebnis berücksichtigt alle Folgen; ein Sieg „zwischendurch" (z. B. Manipulator bei genau drei) kann verloren gehen |
| B · nach jedem Tod sofort (Legacy) | Reaktionen nach einem erkannten Sieg entfallen oder werden trotzdem abgefragt; Reihenfolge schwer erklärbar |

**Empfehlung: A.**

## DR-04 · Öffentliche Information bei Tod

**Kontext.** `DECISION-LOG.md`: „Tagsüber werden nur öffentliche Informationen gezeigt." Nicht festgelegt ist, was bei einem Tod öffentlich ist. Legacy zeigt im Todes-Overlay Name und Ursache (`_renderDeathGroups`, `_deathLabel` in `../../../js/ui/ui.js`); die Ursache verrät z. B. eine Waldhexe.

| Option | Auswirkung |
|---|---|
| **A · nur Name** | maximale Geheimhaltung; Spielleiter kann Rollen bei Bedarf mündlich nennen |
| B · Name und Ursachenkategorie (Nacht / Hinrichtung / Sonstiges) | mehr Orientierung, verrät Nachtfähigkeiten nur grob |
| C · Name und Rolle | klassische Variante mit Rollenaufdeckung; stärkerer Informationsfluss |

**Empfehlung: A**, später optional als Rundeneinstellung.

## DR-05 · Schutzengel

| Punkt | Option A | Option B | Empfehlung |
|---|---|---|---|
| a · Dauer | gilt nur in der Nacht der Wahl (Code, `onNightStart`) | gilt bis zum nächsten Wolfsangriff (Wortlaut „nächsten") | **A** |
| b · Verbrauch | erst in der Morgenauflösung | bei der Wolfszielwahl (Code) | **A**; verhindert Verlust durch Fehlklick und verhindert, dass die Waldhexe den Schutz erkennt |

**Auswirkung:** Bei a B entsteht ein mehrnächtiger Effekt; die Nachtdarstellung muss ihn anzeigen. Bei b B bleibt ein bekannter Fehlerpfad erhalten. Szenarien: AS-R01–R03.

## DR-06 · Waldhexe

| Punkt | Option A | Option B | Empfehlung |
|---|---|---|---|
| a · Tränke | je einmal retten **und** einmal vergiften (Code) | insgesamt nur eine der beiden Fähigkeiten (möglicher Wortlaut „oder") | **A**, Text anpassen |
| b · beides in einer Nacht | erlaubt (Code) | nicht erlaubt | **A** |
| c · Zeitpunkt Gifttod | sofort in der Nacht (Code); spätere Nachtschritte der Person entfallen | in der Morgenauflösung | **A** |
| d · was der Hexe gezeigt wird | nur die Person des Wolfsopfers | Person und Rolle (Legacy-Dialog zeigt die Rolle dem Spielleiter) | **A** |

**Auswirkung:** a B halbiert die Stärke der Rolle. c B macht Gift und Wolfsangriff gleichzeitig und vereinfacht die Nacht, ändert aber das Legacy-Verhalten. Szenarien: AS-R05–R08, AS-R23.

## DR-07 · Orakel

| Punkt | Option A | Option B | Empfehlung |
|---|---|---|---|
| a · Ergebnis bei Wölfen | jeder Wolf außer Trugbilderwolf erscheint als „Werwolf" (Code) | tatsächliche Rolle (Wortlaut „die Rolle") | **A** |
| c · sich selbst wählen | ausgeschlossen | erlaubt (Code) | **A** |

**Auswirkung:** a B verrät Sonderwölfe (Spiegelwolf) samt Fähigkeit. Szenarien: AS-R09, AS-R10.

## DR-08 · Trugbilderwolf: Ziehungszeitpunkt

| Option | Auswirkung |
|---|---|
| A · bei jeder Prüfung neu ziehen (Code) | zweite Prüfung kann ein anderes Ergebnis liefern und die Täuschung verraten |
| **B · einmal pro Partie ziehen und beibehalten; neu ziehen nur, wenn die Scheinrolle nicht mehr gültig ist** | konsistente Täuschung; Scheinrolle muss gespeichert werden |
| C · Spielleiter wählt die Scheinrolle selbst | kein Zufall nötig; Mehrarbeit und Fehlerquelle am Tisch |

**Empfehlung: B.** Szenarien: AS-R11, AS-R12.

## DR-09 · Sensenträger

| Punkt | Option A | Option B | Empfehlung |
|---|---|---|---|
| a · Pflicht | freiwillig, Verzicht möglich (Code) | Pflicht (Wortlaut „erntet") | **A** |
| b · Zeitpunkt nach Tod am Tag | sofort nach der Hinrichtung | am folgenden Morgen (Legacy-Folge von `processQueue`) | **A** |

Nach einem Tod in der Nacht erfolgt die Reaktion in der Morgenauflösung (`07` Q1: „alle Reaktionen am Morgen"); hier ist keine Alternative vorgeschlagen. Szenarien: AS-R15–R17.

## DR-10 · Wolfskind

| Punkt | Option A | Option B | Empfehlung |
|---|---|---|---|
| a · sich selbst als Vorbild | ausgeschlossen | erlaubt (Code) | **A** |
| b · Rudelteilnahme nach Verwandlung | wacht ab der folgenden Nacht mit dem Rudel und wählt mit | zählt nur für Parität und Information, wacht nicht | **A** |

**Auswirkung:** b B erzeugt einen Wolf, der nie tötet; lebt nur noch das Wolfskind, gäbe es keinen Angriff mehr. Szenarien: AS-R18–R20.

## DR-11 · Lehrling

| Punkt | Option A | Option B | Empfehlung |
|---|---|---|---|
| a · erlaubte Mentoren | eine andere lebende Person, die kein Wolf ist (Einzelsiegrollen erlaubt) | nur Rollen der Fraktion Dorf (Prompt-Text „Dorfbewohner") | **A** |
| b · Nutzungen | unverbraucht (Code) | Restnutzungen des Mentors übernehmen | **A** |
| c · Wirkungsbeginn | sofort, auch in derselben Nacht (Code) | ab der nächsten Nacht | **B** |
| d · Mentor ist verwandeltes Wolfskind | Lehrling wird `wolfskind` und Wolf (Code) | Lehrling wird `wolfskind` ohne Wolfsstatus | **A** |

**Auswirkung:** c A kann dieselbe Nachtfähigkeit zweimal in einer Nacht auslösen (Mentor und Lehrling). a A kann einen Lehrling zum Manipulator machen. Szenarien: AS-R21–R23.

## DR-12 · Manipulator: „Final 3"

| Option | Auswirkung |
|---|---|
| A · genau drei Lebende (Code) | springt die Zahl über drei hinweg (z. B. 4 → 2), gewinnt er nie |
| **B · höchstens drei Lebende** | entspricht dem Wortlaut „bis in die Final 3 schafft"; Gleichzeitigkeit mit Wolfsparität wird nach DR-02 aufgelöst |

**Empfehlung: B.** Szenarien: AS-R25, AS-R26.

## DR-13 · Spiegelwolf ohne gespeicherte Nominierung

Nur nötig, wenn DR-03 eine Hinrichtung ohne Nominierung zulässt (Option B oder Übersteuerung in A).

| Option | Auswirkung |
|---|---|
| **A · App fragt die nominierende Person als Pflichtschritt ab und speichert sie nachträglich** | Spiegelung bleibt immer möglich; entspricht Legacy-Abfrage `mirrorWolfWhoNominated` in `doLynchFlow` |
| B · ohne gespeicherte Nominierung keine Spiegelung; Spiegelwolf stirbt normal | einfach, aber die Fähigkeit geht durch eine Formalität verloren |

**Empfehlung: A.** Szenario: AS-R31.

---

## Antwortbogen

| ID | Entscheidung (A/B/C bzw. je Punkt) | Datum | Notiz |
|---|---|---|---|
| DR-01 | | | |
| DR-02 | | | |
| DR-03 | | | |
| DR-04 | | | |
| DR-05 | a: · b: | | |
| DR-06 | a: · b: · c: · d: | | |
| DR-07 | a: · c: | | |
| DR-08 | | | |
| DR-09 | a: · b: | | |
| DR-10 | a: · b: | | |
| DR-11 | a: · b: · c: · d: | | |
| DR-12 | | | |
| DR-13 | | | |
| DR-14 | | | |
