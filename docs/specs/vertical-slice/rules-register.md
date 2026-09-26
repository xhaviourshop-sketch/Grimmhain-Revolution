# Vertical Slice · Regelregister

**Stand:** 2026-09-26 · **Status:** Produktentscheidungen DR-01 bis DR-14 sind verbindlich eingetragen.
**Rollenauswahl:** `role-selection.md` · **Entscheidungsvorlage:** `decision-request.md`

Pfade relativ zu `docs/specs/vertical-slice/`. Zeilennummern (Commit `c5a9e98`) nur als Suchhilfe, maßgeblich ist der Symbolname.

## Lesehilfe

- **Regeltext DE** ist der verbindliche Text. **Regeltext EN** beschreibt dasselbe Verhalten und wird bei jeder Änderung mitgeführt.
- Die Tabellen „Entscheidungsgrundlage“ dokumentieren, welcher Konflikt zwischen Text und Legacy-Code bestand und wie DR-01 bis DR-14 ihn entschieden haben. Verbindlich sind der aktuelle Regeltext und `../../masterplan/DECISION-LOG.md`. Offene Alternativen gibt es nicht mehr.
- **Quelle** nennt, woher eine entschiedene Aussage stammt: `Text` (Rollenbeschreibung in `../../../js/core/roles.js`, Objekt der DE-Beschreibungen und EN-Pendant), `Code` (Legacy-Verhalten), `DL` (`../../masterplan/DECISION-LOG.md`), `07-T2` (Bugliste „ohne Rückfrage behoben" in `../../godot-migration/07-open-questions.md`, Q1 Teil 2), `03` (`../../godot-migration/03-godot-architecture.md`).
- Legacy-Bugs sind keine Referenz (DL, Abschnitt Regeln).
- **Nachtpriorität** = `tier` aus `ORDER_BASE` in `../../../js/core/roles.js`. Kleinere Zahl zuerst.

---

## 0. Grundregeln aller Slice-Rollen

### 0.1 Identität und Zustand

| Regel | Inhalt | Quelle |
|---|---|---|
| G-ID-1 | Jeder Zustand (lebend/tot, Effekte, Nutzungen, Nominierungen, Rolle) hängt an der stabilen **Personen-ID**, nie an der Sitzposition. Sitzreihenfolge ist ein getrennter Wert. | DL „Personen, Sitze und Darstellung"; 03 §5.1 |
| G-ID-2 | Rolle (`role_id`), Siegfraktion, Wolfszählung (`counts_as_wolf`) und Erscheinung für Informationsrollen (`appears_as`) sind getrennte Werte. | Masterplan §4 Regel 5; 03 §5.3 |
| G-ID-3 | Einmal-Fähigkeiten werden **pro Person und Rolle** gezählt, nicht global pro Rolle. | 03 §5.2 `Seat.ability_uses`; Legacy-Schwäche `resetOnceForInheritedRole` in `../../../js/ui/core.js` |

### 0.2 Information

| Regel | Inhalt | Quelle |
|---|---|---|
| G-INF-1 | Jede Informationsfähigkeit erzeugt drei getrennte Werte: **Wahrheit** (tatsächlicher Zustand), **ermitteltes Ergebnis** (nach Regeln wie Täuschung) und **gezeigte Information** (was der Spielleiter bestätigt gezeigt hat). | DL „Falsche Information ist ein modellierter Spieleffekt" |
| G-INF-2 | Ermitteltes und gezeigtes Ergebnis werden im Ereignisprotokoll gespeichert. Weicht die gezeigte Information vom ermittelten Ergebnis ab, ist das eine Spielleiterübersteuerung mit Warnung. | DL „Spielleiter darf jeden Zustand überschreiben" |
| G-INF-3 | Jedes Ereignis trägt eine Sichtbarkeit: nur Spielleiter, öffentlich oder nur handelnde Person. | 03 §5.6 |

### 0.3 Zufall

| Regel | Inhalt | Quelle |
|---|---|---|
| G-RNG-1 | Jede Zufallsentscheidung läuft über den gespeicherten Seed. Seed und Ziehposition sind Teil des Spielstands. Im Slice sind das die zufällige Rollenverteilung und die Anzeigereihenfolge gleicher Rollen im Lehrling-Schritt (§9). Die Scheinrolle des Trugbilderwolfs ist **keine** Zufallsentscheidung, sondern wird vom Spielleiter gewählt (DR-08). | Masterplan §4 Regel 4; DR-08; DR-11 |

### 0.4 Phasen und Nacht

| Regel | Inhalt | Quelle |
|---|---|---|
| G-PH-1 | Phasenfolge: Setup → Nacht → Morgenauflösung → Tag → Nacht … → Spielende. Wechsel nur durch bestätigte Befehle. | 03 §4.3 |
| G-PH-2 | Eine Nacht besteht aus Schritten in aufsteigender Nachtpriorität. Nur lebende Rolleninhaber erhalten einen wirksamen Schritt. | `rebuildOrder` in `../../../js/core/night.js` |
| G-PH-3 | Ein offener mehrstufiger Prompt blockiert jeden Phasenwechsel und ist Teil des Spielstands. | 03 §5.5; Masterplan §4 Regel 3 |
| G-PH-4 | Bestätigen wendet an. Vorher ändert sich kein fachlicher Zustand. | `../../godot-migration/02-product-and-ux-spec.md` §3.2 |
| G-PH-5 | Der Wolfsangriff wird erst in der Morgenauflösung angewandt. | `resolveDayKills` in `night.js` |
| G-PH-6 | Der Rudelschritt existiert, solange mindestens eine lebende Person als Wolf zählt, unabhängig davon, ob ein `werwolf` lebt. | 07-T2 „fehlende Wolfszeile" (Bug F2, `WOLF_KILL_ROLES` in `rebuildOrder`) |
| G-PH-7 | Nachtzähler und Tageszähler sind getrennte Werte. | 03 §5.2 |

### 0.5 Tod

| Regel | Inhalt | Quelle |
|---|---|---|
| G-TOD-1 | Jeder Tod speichert Ursache, Quelle (Person oder System), Ziel und Zeitpunkt (Phase, Nummer, Reihenfolge). | DL „Todesursache, Quelle, Ziel und Zeitpunkt bleiben getrennt" |
| G-TOD-2 | Jeder Tod, auch ein vom Spielleiter gesetzter, läuft durch dieselbe Tötungs-Pipeline. Der Spielleiter wählt bei einer Korrektur ausdrücklich, ob Folgen ausgelöst werden. | 07-T2 „manueller Tod umgeht Folgen"; `04` C-4 |
| G-TOD-3 | Todesursachen im Slice: `NIGHT_KILL` (Wolfsangriff), `WITCH_POISON` (Hexengift), `HUNTER_SHOT` (Fluch des Sensenträgers), `LYNCH` (Hinrichtung nach physischer Abstimmung), `SPIEGELWOLF_RETALIATE` (Spiegelung auf Nominierende), `MANIPULATOR_NOMINATED` (Tod durch Nominierung), `GM_CORRECTION` (Spielleiterkorrektur). | `../../godot-migration/04-rules-migration-matrix.md` C.2; `GM_CORRECTION` aus `04` C-4 |
| G-TOD-4 | Todesfolgen mit Spielerentscheidung werden als persistente Reaktion eingereiht. Nach einem Tod am Tag werden sie sofort, nach einem Tod in der Nacht während der Morgenauflösung abgearbeitet. | DR-09; 03 §5.2 `reaction_queue` |
| G-TOD-5 | Öffentlich ist immer der Name. Die Setup-Option `reveal_role_on_death` bestimmt, ob zusätzlich die Rolle veröffentlicht wird. Ursache und interne Effekte bleiben privat, sofern eine Regel sie nicht ausdrücklich veröffentlicht. | DR-04 |

### 0.6 Tag, Nominierung, Hinrichtung

| Regel | Inhalt | Quelle |
|---|---|---|
| G-TAG-1 | Diskussion und Abstimmung finden physisch statt. Stimmen werden **nicht** digital erfasst, gespeichert oder gezählt. | DL Abschnitt Regeln |
| G-TAG-2 | Gespeichert werden je Nominierung: nominierende Person, nominierte Person und Tag. Pro Tag darf jede lebende Person einmal nominieren und einmal nominiert werden. Die Rechte werden beim nächsten Tag zurückgesetzt. | DL, DR-03 |
| G-TAG-3 | Der Spielleiter bestätigt nach der physischen Abstimmung genau eine Todesaktion auf einer Person oder ausdrücklich „keine Hinrichtung". | DL; `04` E-6; 03 §5.6 `DecideExecution(seat|none)` |
| G-TAG-4 | Eine normale Hinrichtung ist nur für eine an diesem Tag nominierte Person zulässig. Eine andere Person kann ausschließlich über eine Spielleiter-Übersteuerung mit Warnung, Begründung und Protokolleintrag hingerichtet werden (`GmCorrection execute`); Ursache bleibt `LYNCH`, Todesreaktionen und Siegprüfung laufen normal. | DR-03, G-GM-1 |

### 0.7 Sieg

| Regel | Inhalt | Quelle |
|---|---|---|
| G-SIEG-1 | **Dorf**: Kein lebender Mensch zählt als Wolf. | `checkWinConditions` in `../../../js/ui/core.js`; `04` D-1 |
| G-SIEG-2 | **Werwölfe**: Anzahl lebender Wölfe ≥ Anzahl lebender Nicht-Wölfe. Einzelsiegrollen zählen als Nicht-Wölfe. Im Slice zählt jeder Wolf einfach (Siegreicher Wolf ist nicht enthalten). | `countLivingWolfPower`, `checkWinConditions`; `04` D-2 |
| G-SIEG-3 | Ein erkannter Sieg ist ein **Siegkandidat**. Er wird erst durch den Spielleiter bestätigt. Ablehnung wird mit Grund protokolliert; die Partie läuft weiter. | DL „Mögliche Siege werden erkannt, aber erst durch den Spielleiter bestätigt" |
| G-SIEG-4 | Es gibt genau eine Siegprüfung. Ein bestätigter Sieg wird nicht überschrieben. | 07-T2 „zwei Siegprüfer" (Bug F7) |
| G-SIEG-5 | Bei gleichzeitig erfüllten Siegbedingungen entscheidet der Spielleiter. Leben keine Personen mehr, entsteht kein automatischer Gewinner. | DR-02 |
| G-SIEG-6 | Nach jedem Tod wird vorläufig geprüft. Offene Todesreaktionen und Fähigkeiten werden vollständig abgearbeitet; danach erfolgt die erneute verbindliche Prüfung vor der Spielleiterbestätigung. | DR-14 |

### 0.8 Übersteuerung

| Regel | Inhalt | Quelle |
|---|---|---|
| G-GM-1 | Der Spielleiter darf jeden Zustand überschreiben. Jede Übersteuerung zeigt vorher eine Warnung und erzeugt einen Protokolleintrag mit Grund. | DL |
| G-GM-2 | Übersteuerungen laufen als Befehl durch dieselbe Pipeline wie normale Aktionen und sind rückgängig machbar. | Masterplan Phase 3; 03 §5.6 `GmCorrection` |
| G-GM-3 | Eine Übersteuerung hinterlässt keinen widersprüchlichen Zustand: Ändert sie den Zustand einer Person, wird ein offener Prompt mit Grund `state_changed_by_gm_correction` abgebrochen; sein Schritt kann erneut begonnen werden. Kein Siegkandidat entsteht bei offenem Prompt oder offener Reaktion. Ein Sieger wird nur ohne offenen Prompt und ohne offene Reaktion erklärt. | DL, Korrekturrunde 26.09.2026 |

---

## 1. `dorfbewohner` · Dorfbewohner / Villager

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Dorfbewohner hat keine Fähigkeit. Er gewinnt mit dem Dorf. |
| Regeltext EN | The Villager has no ability. They win with the village. |
| Fraktion | Dorf. `counts_as_wolf` = nein. `appears_as` = `dorfbewohner`. |
| Nachtpriorität | keine |
| Gültige Ziele | keine |
| Dauer | – |
| Auflösung | – |
| Konflikte | keine |
| Siegbezug | G-SIEG-1; zählt als Nicht-Wolf für G-SIEG-2 |
| Manuelle Übersteuerung | nur allgemeine Korrekturen (Rolle ändern, töten, wiederbeleben) nach G-GM-1 |
| Legacy-Beleg | `"Dorfbewohner"` in den Beschreibungen, `../../../js/core/roles.js` |

## 2. `werwolf` · Werwolf / Werewolf

| Feld | Inhalt |
|---|---|
| Regeltext DE | Jede Nacht wählen alle lebenden Wölfe gemeinsam genau eine lebende Person als Opfer oder verzichten ausdrücklich. Das Opfer stirbt in der Morgenauflösung durch Wolfsangriff, sofern kein Schutz greift. |
| Regeltext EN | Each night all living wolves jointly choose exactly one living person as their victim or explicitly choose no one. The victim dies during the dawn resolution from a wolf attack unless a protection applies. |
| Fraktion | Werwölfe. `counts_as_wolf` = ja. `appears_as` = Wolf. |
| Nachtpriorität | 2.0 (Rudelschritt). Der Schritt existiert nach G-PH-6, solange irgendein Wolf lebt. Es wachen alle lebenden Personen, die zu Beginn dieser Nacht (`StartNight`) als Wolf zählen, im Slice: `werwolf`, `trugbilderwolf`, `spiegelwolf`, ein verwandeltes `wolfskind` (DR-10) und ein Lehrling mit geerbter Wolfsrolle (DR-11). Wer erst während der Nacht oder später als Wolf zu zählen beginnt, wacht ab der folgenden Nacht. |
| Gültige Ziele | jede lebende Person, auch ein Wolf (Code: Filter `!x.flags.dead`) |
| Dauer | Zielwahl gilt bis zur Morgenauflösung dieser Nacht |
| Auflösung | Morgenauflösung: Schutz prüfen (siehe `schutzengel`, `waldhexe`), sonst Tod mit Ursache `NIGHT_KILL`, Quelle = Rudel. Ist das bestätigte Opfer bis zur Morgenauflösung bereits tot, findet kein Angriff statt; die Rudelwahl wird nicht erneut geöffnet (Ereignis `KillIgnored`, nur Spielleiter; DECISION-LOG, Randfälle 26.09.2026) |
| Konflikte | Wolfsziel und Hexenrettung, Wolfsziel und Schutzengel: siehe dort |
| Siegbezug | G-SIEG-2 |
| Manuelle Übersteuerung | Ziel ändern oder entfernen, bevor die Nacht endet; Schritt überspringen = kein Angriff (protokolliert) |
| Legacy-Beleg | `Werwolf`-Handler in `../../../js/core/abilities-roles-chunk.js`; `resolveDayKills` und `processOne` in `../../../js/core/night.js` |

## 3. `schutzengel` · Schutzengel / Guardian Angel

| Feld | Inhalt |
|---|---|
| Regeltext DE | Jede Nacht wählt der Schutzengel eine andere lebende Person. Diese Person ist in dieser Nacht vor Wolfsangriffen geschützt. Der Schutz wird erst in der Morgenauflösung berücksichtigt und endet bei Tagesbeginn. Er wirkt nicht gegen andere Todesursachen. |
| Regeltext EN | Each night the Guardian Angel chooses another living person. That person is protected from wolf attacks during this night. Protection is evaluated during dawn resolution and ends when day begins. It does not protect against other causes of death. |
| Fraktion | Dorf. `counts_as_wolf` = nein. |
| Nachtpriorität | 1.3 (vor dem Rudel) |
| Gültige Ziele | jede lebende Person außer sich selbst („andere“ in DR-05 = nicht der Schutzengel selbst). Dieselbe Person in aufeinanderfolgenden Nächten ist erlaubt (Code: keine Sperre; DR-05 regelt keine Sperre). |
| Dauer | Wahl bis zum Beginn des folgenden Tages. Gespeichert wird beim Bestätigen: Schutzengel, geschützte Person, Nacht. Ein Schutz früherer Nächte wirkt nie erneut. Stirbt der Schutzengel nach bestätigter Wahl in derselben Nacht, bleibt der Schutz bestehen (DECISION-LOG, Schutzengel 26.09.2026) |
| Auflösung | Pflichtauswahl je lebendem Schutzengel, nie per `SkipStep` überspringbar (vor der Bestätigung per `CancelPrompt` abbrechbar und erneut angeboten), Schritte vor dem Rudel, bei mehreren Schutzengeln nach Personen-ID. Morgenauflösung: Ist das Wolfsopfer (`NIGHT_KILL` durch das Rudel) in dieser Nacht geschützt, stirbt es nicht; genau ein Ereignis `KillPrevented` (Ziel, Ursache, Schutzquelle, Schutzengel-ID, Nacht) nur für den Spielleiter, kein Todesereignis, keine Todesreaktion, kein vorläufiger Siegstatus. Andere Todesursachen (`HUNTER_SHOT`, `WITCH_POISON`, `LYNCH`, `GM_CORRECTION`) verhindert der Schutz nicht. Stirbt die geschützte Person vorher aus anderem Grund, wird sie nicht wiederbelebt und das Rudel erhält kein neues Ziel |
| Konflikte | Hexenrettung und Schutz auf demselben Opfer: das Opfer überlebt einmal; beide Wirkungen werden protokolliert. Entscheidung DR-05 (unten) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | nur in der laufenden Nacht und nach erledigtem Schritt des Schutzengels: Schutz setzen, ändern oder entfernen (`GmCorrection set_protection` / `remove_protection`, Bestätigung, Begründung, alter und neuer Wert); Selbstschutz bleibt verboten |
| Legacy-Beleg | `Schutzengel`-Handler (`protectedCount`, Filter `role!=="Schutzengel"`) und `Werwolf`-Handler in `abilities-roles-chunk.js`; Rücksetzen `flags.protected` in `onNightStart`, `night.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-05 Schutzengel**

| Punkt | Text sagt | Code tut | Entscheidung (DR-05) |
|---|---|---|---|
| a · Dauer | „schütze diesen vor dem **nächsten** Werwolfangriff" (`roles.js`) | Schutz wird zu Beginn jeder Nacht zurückgesetzt (`onNightStart`) | gilt nur in dieser Nacht und endet bei Tagesbeginn |
| b · Verbrauch | schweigt | Wolfs-Zielwahl auf geschützte Person verbraucht den Schutz sofort (`Werwolf`-Handler) | wird erst in der Morgenauflösung angewandt |
| c · Sicht der Waldhexe | schweigt | Folge von b: Die Hexe sieht bei geschütztem Ziel „Kein Opfer gesetzt" | folgt aus b: Die Hexe sieht das gewählte Opfer, unabhängig vom Schutz |

## 4. `das-orakel` · Das Orakel / The Oracle

| Feld | Inhalt |
|---|---|
| Regeltext DE | Jede Nacht wählt das Orakel eine andere lebende Person und erfährt deren Rolle. Zählt die Person als Wolf, lautet das Ergebnis „Werwolf“. Beim Trugbilderwolf gilt stattdessen dessen vom Spielleiter festgelegte Täuschung. |
| Regeltext EN | Each night the Oracle chooses another living person and learns their role. If that person counts as a wolf, the result is "Werewolf". For the Decoy Wolf, the game master's chosen deception applies instead. |
| Fraktion | Dorf |
| Nachtpriorität | 4.6 |
| Gültige Ziele | jede andere lebende Person; Selbstwahl ist verboten |
| Dauer | sofort, keine Zustandsänderung |
| Auflösung | Pflichtschritt je lebendem Orakel nach allen Waldhexenschritten (mehrere nach Personen-ID), nie per `SkipStep` überspringbar, vor „Gezeigt“ per `CancelPrompt` vollständig verwerfbar. Stufe 1: genau eine andere lebende Person wählen; dabei werden Wahrheit (aktuelle `role_id`) und ermitteltes Ergebnis (`InformationRules.determine_role`: gespeicherte besondere Erscheinung `appears_as` ≠ `role_id`, sonst `werwolf` bei `counts_as_wolf`, sonst `role_id`) berechnet und als gezeigtes Ergebnis vorbelegt. Stufe 2: „Gezeigt“ bestätigen. Erst dann entstehen der Datensatz `InfoRecord`, das Audit `InfoRecorded` (nur Spielleiter, alle drei Werte) und `InfoRevealed` (nur das Orakel, nur das gezeigte Ergebnis) (G-INF-1). Keine Zufallsziehung |
| Konflikte | Verwandeltes `wolfskind` und `lehrling` mit geerbter Rolle werden nach aktuellem Zustand ermittelt (Code: `isWolf`, `seat.role`) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | gezeigte Information vor „Gezeigt“ abweichend setzen (`OverrideShownRole`: bekannte Rolle, Warnung, Begründung, Protokoll mit altem und neuem gezeigtem Wert); Wahrheit und ermitteltes Ergebnis bleiben unverändert, der Prompt bleibt offen |
| Legacy-Beleg | `"Das Orakel"`-Handler in `abilities-roles-chunk.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-07 Orakel**

| Punkt | Text sagt | Code tut | Entscheidung (DR-07) |
|---|---|---|---|
| a · Ergebnis bei Wölfen | „erfahre die Rolle eines Spielers" | Jeder Wolf außer Trugbilderwolf erscheint als „Werwolf" | jede Person, die als Wolf zählt, erscheint als `werwolf`; Ausnahme Trugbilderwolf (DR-08) |
| b · Ergebnis bei Nicht-Wölfen | tatsächliche Rolle | tatsächliche Rolle | tatsächliche aktuelle Rolle |
| c · sich selbst wählen | schweigt | erlaubt (Filter nur `!dead` über `startPick`) | verboten |

## 5. `trugbilderwolf` · Trugbilderwolf / Decoy Wolf

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Trugbilderwolf gehört zu den Wölfen und wacht mit dem Rudel. Der Spielleiter legt seine Scheinrolle beim Spielaufbau fest; nur eine bestätigte Spielleiterkorrektur kann sie danach ändern. Prüft ihn das Orakel, erhält es diese Scheinrolle statt „Werwolf“. |
| Regeltext EN | The Decoy Wolf belongs to the wolves and wakes with the pack. The game master defines their decoy role during game setup; only a confirmed game master correction can change it afterwards. When the Oracle checks them, it receives that decoy role instead of "Werewolf". |
| Fraktion | Werwölfe. `counts_as_wolf` = ja. `appears_as` = Scheinrolle (nur gegenüber Informationsrollen) |
| Nachtpriorität | keine eigene; Teil des Rudelschritts 2.0 |
| Gültige Ziele | wie `werwolf` im Rudelschritt |
| Dauer | Die beim Spielaufbau gewählte Scheinrolle wird gespeichert und bei jeder Orakel-Prüfung verwendet. Änderung nur per bestätigter Spielleiterkorrektur (`GmCorrection set_role_field`, Feld `appears_as`) mit Begründung und Protokoll von altem und neuem Wert. |
| Auflösung | Setup: Ist ein `trugbilderwolf` im Rollenpool, verlangt der Spielaufbau die Scheinrolle (Auswahl: jede Rolle des Slice-Katalogs, die nicht als Wolf zählt). Orakel-Schritt ohne Zufallsziehung und ohne Rückfrage: ermitteltes Ergebnis = gespeicherte Scheinrolle; Wahrheit = `trugbilderwolf` |
| Konflikte | Scheinrolle kann eine Rolle sein, die im Spiel lebend existiert (beabsichtigt, Code) |
| Siegbezug | G-SIEG-2 |
| Manuelle Übersteuerung | gespeicherte Scheinrolle korrigieren (`set_role_field appears_as`, G-GM-1); gezeigte Information abweichend setzen (G-INF-2) |
| Legacy-Beleg | Beschreibung `"Trugbilderwolf"` in `roles.js`; Zufallsziehung `pool[Math.floor(Math.random()*pool.length)]` im `"Das Orakel"`-Handler, `abilities-roles-chunk.js`; `WOLF_ROLES_SET` und `WOLF_KILL_ROLES` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-08 Trugbilderwolf**

| Punkt | Text sagt | Code tut | Entscheidung (DR-08) |
|---|---|---|---|
| Herkunft der Scheinrolle | „zufällige Nicht-Wolf-Rolle" | bei jeder Prüfung neu zufällig (`Math.random`) | Der Spielleiter wählt die Scheinrolle beim Spielaufbau; kein Zufall. Sie bleibt gespeichert, damit jede Prüfung dasselbe Ergebnis liefert; ändern kann sie nur eine bestätigte Spielleiterkorrektur (DECISION-LOG, Korrekturrunde 26.09.2026) |

## 6. `waldhexe` · Waldhexe / Witch of the Woods

| Feld | Inhalt |
|---|---|
| Regeltext DE | Jede Nacht erfährt die Waldhexe den Namen des Wolfsopfers. Einmal pro Partie darf sie dieses Opfer retten und einmal pro Partie eine lebende Person vergiften; beides ist in derselben Nacht erlaubt. Rettet sie das Opfer, erfährt sie zusätzlich dessen Rolle. Das gerettete Opfer stirbt in dieser Nacht nicht durch den Wolfsangriff. Das Giftziel stirbt sofort. |
| Regeltext EN | Each night the Witch of the Woods learns the wolf victim's name. Once per game she may save that victim and once per game poison a living person; both may be used in the same night. If she saves the victim, she additionally learns their role. The saved victim does not die from the wolf attack that night. The poisoned target dies immediately. |
| Fraktion | Dorf |
| Nachtpriorität | 3.4 (nach dem Rudel, vor dem Orakel) |
| Gültige Ziele | Rettung: nur das aktuelle Wolfsopfer dieser Nacht, auch sie selbst (Code). Gift: jede lebende Person, auch sie selbst und das Wolfsopfer (Code: Filter `!x.flags.dead`) |
| Dauer | Rettung gilt für den Wolfsangriff dieser Nacht. Einmal-Nutzungen gelten pro Person und Fähigkeit für die ganze Partie (G-ID-3) |
| Auflösung | Mehrstufiger Prompt, **eine** atomare Prompt-Kette (03 §5.5), Schritt nach dem Rudel je lebender Waldhexe mit mindestens einem unverbrauchten Trank (mehrere nach Personen-ID): Opfer anzeigen (nur Personen-ID, auch wenn geschützt) → retten ja/nein (nur mit lebendem Rudelopfer und Heiltrank) → bei Ja tatsächliche Rolle des Opfers offenlegen (`role_id`, nicht `appears_as`) → vergiften ja/nein (nur mit Gifttrank) → Giftziel → Zusammenfassung und finale Bestätigung. Bis zur Bestätigung wird nichts verbraucht, gespeichert oder getötet; `CancelPrompt` verwirft alle Teilantworten und bietet den Schritt erneut an. Bestätigung: Trankverbrauch und Rettung speichern → Giftziel stirbt sofort (`WITCH_POISON`, Quelle Waldhexe, über die normale Pipeline) → Schritt erledigt. Die Rettung wird in der Morgenauflösung angewandt. Nie per `SkipStep` überspringbar; Verzicht auf beide Tränke ist eine Antwort. Ist die Waldhexe vor ihrem Schritt tot oder ist keine Entscheidung möglich (kein lebendes Rudelopfer bzw. Heiltrank verbraucht und Gifttrank verbraucht), entfällt der Schritt protokolliert |
| Konflikte | Rettung eines geschützten Opfers: Die Hexe sieht das Opfer unabhängig vom Schutz (DR-05, Punkt c) und darf es retten; ihr Heiltrank ist damit verbraucht. Gift und Wolfsopfer auf derselben Person: eine Person stirbt nur einmal; die erste angewandte Ursache gilt (G-TOD-1). Gift auf Sensenträger: löst dessen Reaktion aus (G-TOD-4) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | Heil- und Gifttrank einzeln als verfügbar oder verbraucht markieren (ein wieder verfügbarer Trank gilt erst ab der nächsten Nacht, wenn der Nachtplan bereits steht); bestätigte Rettung der laufenden Nacht setzen (nur auf das aktuelle lebende Rudelopfer) oder entfernen, nicht nach der Morgenauflösung; Giftopfer per Korrektur wiederbeleben (Warnung, Protokoll). Gift selbst wird über den allgemeinen Spielleitertod korrigiert |
| Legacy-Beleg | `Waldhexe`-Handler (`WaldhexeL`, `WaldhexeD`, Anzeige `v.role`) in `abilities-roles-chunk.js`; `hexeAskDeath` und `witchDeadlyFatePick` (`applyKill(s,"WITCH_POISON")` sofort) in `../../../js/core/abilities-helpers.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-06 Waldhexe**

| Punkt | Text sagt | Code tut | Entscheidung (DR-06) |
|---|---|---|---|
| a · Anzahl Tränke | DE: „Einmalig kannst du diesen … bewahren **oder** einen anderen Spieler in eine tödliche Zukunft weisen." EN: „once per game you can spare them **or** doom another player" | zwei getrennte Einmal-Fähigkeiten (`WaldhexeL`, `WaldhexeD`) | je ein Heil- und ein Gifttrank pro Partie; Text ist angepasst |
| b · beides in einer Nacht | schweigt | erlaubt (nach Rettung folgt `hexeAskDeath`) | erlaubt |
| c · Todeszeitpunkt Gift | schweigt | sofort in der Nacht; spätere Nachtschritte der vergifteten Person entfallen | sofort; Folgereaktionen nach DR-09 in der Morgenauflösung |
| d · Was die Hexe sieht | „Sieht jede Nacht die Zukunft des Opfers" | Spielleiterdialog zeigt die **Rolle** des Opfers | Vor ihrer Entscheidung sieht die Hexe nur den Namen des Wolfsopfers. Rettet sie es, erfährt sie zusätzlich dessen Rolle |

## 7. `sensentraeger` · Sensenträger / Reaper

| Feld | Inhalt |
|---|---|
| Regeltext DE | Stirbt der Sensenträger, darf er einmal pro Partie eine lebende Person wählen oder verzichten. Die gewählte Person stirbt durch seinen Fluch. Nach einem Tod in der Nacht (auch durch Gift) erfolgt die Reaktion in der Morgenauflösung, nach einem Tod am Tag sofort. |
| Regeltext EN | When the Reaper dies, they may, once per game, choose one living person or decline. The chosen person dies from their curse. After a death at night (including poison) the reaction happens during dawn resolution; after a death during the day it happens immediately. |
| Fraktion | Dorf |
| Nachtpriorität | keine; Reaktion (`reaction_queue`) |
| Gültige Ziele | jede Person, die zum Zeitpunkt der Antwort lebt, außer dem Sensenträger selbst, auch wenn er inzwischen wiederbelebt wurde (Code: `!x.flags.dead && x!==h`; DECISION-LOG, Randfälle 26.09.2026) |
| Dauer | Reaktion bleibt offen und persistent, bis sie beantwortet ist (Ziel oder ausdrücklicher Verzicht). Sie ist weder überspringbar (`SkipStep`) noch abbrechbar (`CancelPrompt`). Eine spätere Wiederbelebung entfernt eine bereits eingereihte Reaktion nicht (DECISION-LOG, Randfälle 26.09.2026) |
| Auflösung | Tod des Sensenträgers → Reaktion einreihen → Prompt „verfluchen? → Ziel → bestätigen" → Tod mit Ursache `HUNTER_SHOT`, Quelle = Sensenträger; Verzicht erledigt die Reaktion ohne Tod (`ReactionResolved{outcome: declined}`). Genau eine Reaktion pro Tod und höchstens eine pro Person und Partie (Code: `meta.hunterShot`); ein erneuter Tod nach Wiederbelebung löst keine zweite aus |
| Konflikte | Schutzengel schützt nicht (nur Wolfsangriff). Wird ein weiterer Sensenträger getroffen, entsteht eine weitere Reaktion. Siegprüfung: vorläufig nach jedem Tod, verbindlich erst nach Abarbeitung aller Reaktionen (G-SIEG-6, DR-14) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | Tod ohne Folgen per `GmCorrection kill` mit `trigger_effects = false` (keine Reaktion); die Reaktion selbst wird nicht übersprungen (Warnung, Protokoll) |
| Legacy-Beleg | `window.__queueHunterOnDeath`, `processQueue` (`if(state.dark) return;`), Schlüssel `hunterCurseQueuedAsk` in `../../../game.html`; Einreihung in `postDeathHooks`, `js/ui/core.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-09 Sensenträger**

| Punkt | Text sagt | Code tut | Entscheidung (DR-09) |
|---|---|---|---|
| a · Pflicht oder freiwillig | „erntet eine letzte Seele seiner Wahl" | freiwillig (Knopf „Überspringen") | freiwillig, Verzicht möglich |
| b · Zeitpunkt nach Tod am Tag | „Beim Tod" | nach Tageslynch in der Praxis erst nach der nächsten Nacht (`04` A-6) | sofort |
| c · Zeitpunkt nach Tod in der Nacht | „Beim Tod" | am folgenden Morgen | während der Morgenauflösung |

## 8. `wolfskind` · Wolfskind / Wolf Child

| Feld | Inhalt |
|---|---|
| Regeltext DE | In seiner ersten Nacht wählt das Wolfskind eine andere lebende Person als Vorbild. Stirbt das Vorbild, während das Wolfskind lebt, zählt das Wolfskind ab sofort als Wolf und gewinnt mit den Werwölfen. Seine Rolle bleibt Wolfskind. Ab der folgenden Nacht wacht es mit dem Rudel. Für einen Lehrling, der `wolfskind` geerbt hat, gilt als erste Nacht seine nächste Nacht mit aktiver geerbter Rolle (§9). |
| Regeltext EN | In their first night the Wolf Child chooses another living person as their role model. If that role model dies while the Wolf Child lives, the Wolf Child counts as a wolf and wins with the werewolves. Their role remains Wolf Child. From the following night onward they wake with the pack. For an Apprentice who inherited Wolf Child, their first night is their next night with the inherited role active (§9). |
| Fraktion | Dorf; nach Verwandlung Werwölfe. `counts_as_wolf` = nein, danach ja. `appears_as` folgt `counts_as_wolf` (Orakel: „Werwolf" nach Verwandlung, Code `isWolf`) |
| Nachtpriorität | 0.9, einmalig: in Nacht 1, bei geerbtem `wolfskind` in der ersten Nacht nach dem Erbe |
| Gültige Ziele | jede andere lebende Person; Selbstwahl ist verboten |
| Dauer | Vorbildbindung für die ganze Partie; Verwandlung dauerhaft |
| Auflösung | Tod des Vorbilds (jede Ursache) → in derselben Pipeline-Ausführung `RoleChanged`/Fraktionswechsel-Ereignis, nur für den Spielleiter sichtbar; danach Siegprüfung |
| Konflikte | Stirbt das Vorbild, während das Wolfskind tot ist: keine Verwandlung (Code: `mogli` nur lebend). Wächter am Tor nicht im Slice |
| Siegbezug | vor Verwandlung Dorf, danach G-SIEG-2 |
| Manuelle Übersteuerung | Vorbild nachträglich setzen, Verwandlung auslösen oder rückgängig machen (Warnung, Protokoll) |
| Legacy-Beleg | `Wolfskind`-Handler (`MogliVorbildId`, Filter `!x.flags.dead`) in `abilities-roles-chunk.js`; Verwandlung `mogli.flags.werewolf=true` in `postDeathHooks`, `js/ui/core.js`; Beschreibung `"Wolfskind"` in `roles.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-10 Wolfskind**

| Punkt | Text sagt | Code tut | Entscheidung (DR-10) |
|---|---|---|---|
| a · sich selbst wählen | DE „einen Feind", EN „an enemy" | erlaubt (Filter nur `!dead`); Prompt nennt es „Vorbild" | verboten; Begriff „Vorbild" in beiden Sprachen |
| b · Rudelteilnahme | „zählst fortan als Wolf" | nur `flags.werewolf`; `wolfskind` fehlt in `WOLF_KILL_ROLES` | wacht nach der Verwandlung ab der folgenden Nacht mit dem Rudel und wählt mit |

## 9. `lehrling` · Lehrling / Apprentice

| Feld | Inhalt |
|---|---|
| Regeltext DE | Ist der Lehrling in der ersten Nacht an der Reihe, bestimmt der Spielleiter verdeckt drei geeignete lebende Personen. Der Lehrling sieht ausschließlich die drei Rollen dieser Personen, niemals ihre Namen oder Identitäten. Jede angezeigte Rolle bleibt intern und geheim mit ihrer Person verknüpft. Der Lehrling wählt eine der drei Rollen. Stirbt die damit verknüpfte Person, während der Lehrling lebt, erbt der Lehrling deren Rolle. Alle begrenzten Fähigkeitseinsätze der geerbten Rolle beginnen für ihn neu. Fraktion, passive Eigenschaften, Siegbedingungen und Todesreaktionen der geerbten Rolle gelten sofort; ihre aktiv auszuführenden Nachtfähigkeiten sind erstmals in der folgenden Nacht verfügbar. Erbt der Lehrling `wolfskind`, bleibt er zunächst unverwandelt, wählt bei seinem nächsten Nachtschritt ein neues Vorbild und verwandelt sich erst, wenn dieses neue Vorbild stirbt. |
| Regeltext EN | When the Apprentice's turn comes in the first night, the game master secretly selects three eligible living people. The Apprentice sees only the three roles of these people, never their names or identities. Each displayed role stays internally and secretly linked to its person. The Apprentice chooses one of the three roles. If the linked person dies while the Apprentice is alive, the Apprentice inherits that role. All limited ability uses of the inherited role start fresh for them. Faction, passive properties, victory conditions and death reactions of the inherited role apply immediately; its actively performed night abilities are first available in the following night. If the Apprentice inherits Wolf Child, they initially remain untransformed, choose a new role model on their next night step and transform only when that new role model dies. |
| Fraktion | Dorf; nach dem Erbe Fraktion und Wolfszählung der geerbten Rolle (siehe Auflösung, Schritt 6) |
| Nachtpriorität | 1.1, nur Nacht 1, einmalig |
| Gültige Ziele | Geeignet ist jede lebende Person außer dem Lehrling selbst (DECISION-LOG, Präzisierung 26.09.2026). Der Spielleiter wählt genau drei verschiedene Personen; die App prüft nur Lebendigkeit, Verschiedenheit und Anzahl. Der Lehrling wählt anschließend genau eine der drei angezeigten Rollen. |
| Dauer | Bindung an die gewählte Person bis zu deren Tod oder bis zum Tod des Lehrlings; Rollenwechsel dauerhaft |
| Auflösung | Mehrstufige, persistente Prompt-Kette (03 §5.5):<br>1. **Spielleiterteil (nur Cockpit):** Der Spielleiter wählt drei geeignete Personen. Teilantwort `candidates = [Person-IDs]` wird im offenen Prompt gespeichert.<br>2. **Lehrlingsteil (gesicherte Karte):** Angezeigt werden nur drei Optionen mit Rollennamen (aktuelle `role_id` der Person). Keine Namen, Sitzplätze, Porträts, IDs oder Reihenfolgen, aus denen die Person erkennbar wäre. Reihenfolge: nach Rollen-ID sortiert; gleiche Rollen werden über eine `SeededRng`-Ziehung geordnet, die mit dem Prompt gespeichert wird (G-RNG-1).<br>3. **Bestätigen:** Die gewählte Option wird intern an ihre Person gebunden (`apprentice_master_id`). Ereignis `ApprenticeBound` nur für den Spielleiter; die Projektion für den Lehrling enthält nur die gewählte Rolle.<br>4. **Tod der gebundenen Person** (jede Ursache) bei lebendem Lehrling: in derselben Pipeline-Ausführung `RoleChanged{from: lehrling, to: <Rolle der Person im Todeszeitpunkt>, by: master_death}`, nur für den Spielleiter. `original_role_id` bleibt `lehrling`. Alle `ability_uses` der geerbten Rolle stehen für den Lehrling auf null (G-ID-3).<br>5. **Tod des Lehrlings vor dem Erbe:** Die Bindung erlischt; es findet nie ein Erbe statt (Bugfix F5).<br>6. **Wirksamkeit** (DECISION-LOG, Korrekturrunde 26.09.2026): Rolle, Fraktion, passive Eigenschaften, Siegbedingungen und Todesreaktionen der geerbten Rolle gelten sofort beim Erbe; die Siegprüfung rechnet sofort damit. Stirbt der Lehrling nach dem Erbe und vor der folgenden Nacht, wird die Todesreaktion der geerbten Rolle eingereiht. Nur aktiv auszuführende Nachtfähigkeiten sind erstmals in der folgenden Nacht verfügbar (`StartNight`).<br>7. **Geerbtes `wolfskind`:** Der Lehrling zählt nicht als Wolf, auch wenn die verstorbene Person ein verwandeltes Wolfskind war. In seiner nächsten Nacht erhält er den Wolfskind-Schritt (0.9) und wählt ein neues Vorbild (nicht sich selbst). Erst der Tod dieses neuen Vorbilds verwandelt ihn nach §8. |
| Konflikte | Erbt der Lehrling `manipulator`, gilt dessen Status „nie nominiert“ für die Person des Lehrlings. Doppelte Rollen unter den drei Optionen erscheinen als getrennte Optionen mit gleichem Rollennamen; jede ist an eine andere Person gebunden. Stirbt die gebundene Person und der Lehrling in derselben Befehlsausführung, entscheidet die Reihenfolge der Tode (`order_index`): Nur wenn der Lehrling zum Todeszeitpunkt der Person noch lebt, erbt er. |
| Siegbezug | Fraktion der aktuellen Rolle |
| Manuelle Übersteuerung | Bindung setzen oder ändern, Erbe auslösen oder rückgängig machen (Warnung, Protokoll) |
| Legacy-Beleg | `Lehrling`-Handler (Filter `!x.flags.dead&&!isWolf(x)`, Prompt „wähle Mentor (Dorfbewohner)“) in `abilities-roles-chunk.js`; Erbe und `resetOnceForInheritedRole` in `postDeathHooks`, `js/ui/core.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-11 Lehrling**

| Punkt | Text sagt | Code tut | Entscheidung (DR-11) |
|---|---|---|---|
| Auswahl | „Wählt einen Mentor“ | Lehrling wählt offen eine Person (lebend, kein Wolf) | Spielleiter wählt drei Personen; der Lehrling sieht nur deren Rollen und wählt eine Rolle |
| Identität | schweigt | Lehrling kennt seinen Mentor | Der Lehrling erfährt nie, welche Person an seine Rolle gebunden ist |
| Nutzungen der geerbten Rolle | schweigt | Einmal-Flags werden zurückgesetzt | alle begrenzten Einsätze zurückgesetzt |
| Wirkungsbeginn | schweigt | sofort; `rebuildOrder` nimmt die Rolle in die laufende Nacht auf | ab der folgenden Nacht |
| Erbe von `wolfskind` | schweigt | Lehrling wird `wolfskind` und übernimmt den Wolfsstatus | unverwandelt; neues Vorbild im nächsten Nachtschritt; Verwandlung erst nach dessen Tod |
| toter Lehrling erbt | „übernimmt die Rolle“ | erbt auch tot (Bug F5) | kein Erbe (07-T2) |

## 10. `manipulator` · Manipulator / Manipulator

| Feld | Inhalt |
|---|---|
| Regeltext DE | Wird der Manipulator nominiert, stirbt er sofort. Leben genau drei Personen, er lebt und wurde in dieser Partie nie nominiert, ist sein Einzelsieg ein Siegkandidat. |
| Regeltext EN | If the Manipulator is nominated, they die immediately. If exactly three people are alive, the Manipulator is alive and has never been nominated in this game, their solo victory becomes a victory candidate. |
| Fraktion | Einzelsieg. `counts_as_wolf` = nein (Code: fest in `isWolf` ausgeschlossen) |
| Nachtpriorität | keine |
| Gültige Ziele | keine |
| Dauer | Status „nie nominiert" gilt für die ganze Partie und haftet an der Person |
| Auflösung | Befehl `Nominate(nominierende, Manipulator)` wird gespeichert und löst in derselben Befehlsausführung den Tod mit Ursache `MANIPULATOR_NOMINATED`, Quelle = nominierende Person, aus. Die Tagesphase läuft danach weiter |
| Konflikte | Gleichzeitig mit Wolfsparität oder Dorfsieg: Der Spielleiter entscheidet (G-SIEG-5, DR-02). Eine Hinrichtung ohne Nominierung (nur per Übersteuerung, DR-03) löst keinen Manipulator-Tod aus, weil keine Nominierung vorliegt |
| Siegbezug | eigener Siegkandidat; zählt als Nicht-Wolf in G-SIEG-2 |
| Manuelle Übersteuerung | Nominierung zurücknehmen = Undo des Befehls; Status „nie nominiert" korrigieren (Warnung, Protokoll) |
| Legacy-Beleg | `openPop` in `../../../game.html` (Chip `nominated`, `ManipulatorWasNominated`, `applyKill(currentSeat,"MANIPULATOR_NOMINATED")`); `checkWinConditions` (`alive.length===3`) in `js/ui/core.js`; `isWolf` Ausschlussliste |

**ENTSCHEIDUNGSGRUNDLAGE · DR-12 Manipulator**

| Punkt | Text sagt | Code tut | Entscheidung |
|---|---|---|---|
| a · „Final 3" | „bis in die Final 3 schafft" | genau 3 Lebende | genau drei Lebende (DR-12); springt die Zahl über drei hinweg, entsteht kein Manipulator-Kandidat |
| b · Vorrang vor Werwölfen | schweigt | Wolfsparität wird vor dem Manipulator geprüft; Dorfsieg ebenfalls | keine feste Priorität; bei Gleichzeitigkeit entscheidet der Spielleiter (DR-02) |

## 11. `spiegelwolf` · Spiegelwolf / Mirror Wolf

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Spiegelwolf gehört zu den Wölfen und wacht mit dem Rudel. Bestätigt der Spielleiter zum ersten Mal in dieser Partie seine Hinrichtung und liegt eine gespeicherte Nominierung vor, überlebt er; stattdessen stirbt die nominierende Person. Lebt sie nicht mehr, stirbt niemand. Fehlt die Nominierung, findet keine Spiegelung statt und der Spiegelwolf stirbt normal. Ab der zweiten Hinrichtung stirbt er ebenfalls normal. |
| Regeltext EN | The Mirror Wolf belongs to the wolves and wakes with the pack. The first time the game master confirms their execution, and a nomination is recorded, the Mirror Wolf survives and the nominating person dies instead. If that person is no longer alive, nobody dies. Without a recorded nomination, no reflection occurs and the Mirror Wolf dies normally. From the second execution onward, they also die normally. |
| Fraktion | Werwölfe. `counts_as_wolf` = ja |
| Nachtpriorität | keine eigene; Teil des Rudelschritts 2.0 |
| Gültige Ziele | keine eigenen |
| Dauer | Spiegelung einmal pro Person |
| Auflösung | `DecideExecution(Spiegelwolf)` → Abfangregel „Spiegelung" → Tod der nominierenden Person mit Ursache `SPIEGELWOLF_RETALIATE`, Quelle = Spiegelwolf. Die Hinrichtung des Tages gilt als erfolgt (Code: `finalizeLynch` läuft) |
| Konflikte | Nominierende Person ist Sensenträger → Reaktion. Nominierende Person ist Manipulator → er stirbt durch die Spiegelung; sein Tod durch Nominierung betrifft nur den Fall, dass er selbst nominiert wird |
| Siegbezug | G-SIEG-2 |
| Manuelle Übersteuerung | Spiegelung als verbraucht/unverbraucht setzen; Spiegelziel abweichend wählen (Warnung, Protokoll) |
| Legacy-Beleg | Zweig `target.role==="Spiegelwolf"` in `doLynchFlow` (`meta.spMirrorUsed`, Abfrage `mirrorWolfWhoNominated`, Filter `!x.flags.dead && x!==target`) in `../../../js/core/night.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-13 Spiegelwolf**

| Punkt | Text sagt | Code tut | Entscheidung (DR-13) |
|---|---|---|---|
| fehlende Nominierung | „auf den Spieler, der ihn nominiert hat" | Nominierende werden nicht gespeichert; der Spielleiter wählt bei der Hinrichtung frei eine lebende Person | Tritt nur bei einer Hinrichtung per Übersteuerung auf (DR-03). Dann keine Spiegelung, der Spiegelwolf stirbt normal; die App fragt keine nominierende Person nachträglich ab |

---

## 12. Zusammenfassung der Entscheidungen

| ID | Thema | Entscheidung | Regelabschnitt |
|---|---|---|---|
| DR-01 | Technische Rollen-IDs | deutsches ASCII-kebab-case (`dorfbewohner`, `werwolf`, `das-orakel`) | §1 bis §11 (Überschriften) |
| DR-02 | gleichzeitige Siege, niemand lebt | Spielleiter entscheidet; niemand lebt → kein automatischer Gewinner | G-SIEG-5 |
| DR-03 | Nominierung | pro Tag, nur Lebende, je einmal nominieren und nominiert werden; Hinrichtung nur nach Nominierung, sonst Übersteuerung | G-TAG-2, G-TAG-4 |
| DR-04 | öffentliche Todesinformation | Name öffentlich; Rolle nach Setup-Option `reveal_role_on_death`; Ursache privat | G-TOD-5 |
| DR-05 | Schutzengel | andere lebende Person; nur diese Nacht gegen Wolfsangriff; Anwendung in der Morgenauflösung; Ende bei Tagesbeginn | §3 |
| DR-06 | Waldhexe | je ein Heil- und Gifttrank, beide in einer Nacht erlaubt; Gift sofort; Name vor Entscheidung, Rolle nach Rettung | §6 |
| DR-07 | Orakel | Sonderwölfe erscheinen als `werwolf`; Selbstprüfung verboten | §4 |
| DR-08 | Trugbilderwolf | Spielleiter wählt die Scheinrolle beim Spielaufbau; kein Zufall; Änderung nur per bestätigter Korrektur | §5, G-RNG-1, G-GM-3 |
| DR-09 | Sensenträger | freiwillig; Tag sofort, Nacht in der Morgenauflösung | §7, G-TOD-4 |
| DR-10 | Wolfskind | keine Selbstwahl; nach Verwandlung Rudel ab folgender Nacht | §8 |
| DR-11 | Lehrling | drei verdeckt gebundene Rollen; Erbe bei Tod der Person; Reset; aktiv ab folgender Nacht; Wolfskind mit neuem Vorbild | §9 |
| DR-12 | Manipulator | genau drei Lebende | §10 |
| DR-13 | Spiegelwolf ohne Nominierung | keine Spiegelung, normaler Tod | §11 |
| DR-14 | Siegprüfung und Reaktionen | nach jedem Tod vorläufig; Reaktionen vollständig abarbeiten; danach verbindlich prüfen; dann Spielleiterbestätigung | G-SIEG-6 |

Fragen, Optionen und Antwortbogen: `decision-request.md`.
