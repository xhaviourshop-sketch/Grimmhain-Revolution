# Vertical Slice · Regelregister

**Stand:** 2026-09-26 · **Status:** Produktentscheidungen DR-01 bis DR-14 sind verbindlich eingetragen.
**Rollenauswahl:** `role-selection.md` · **Entscheidungsvorlage:** `decision-request.md`

Pfade relativ zu `docs/specs/vertical-slice/`. Zeilennummern (Commit `c5a9e98`) nur als Suchhilfe, maßgeblich ist der Symbolname.

## Lesehilfe

- **Regeltext DE** ist der verbindliche Text. **Regeltext EN** beschreibt dasselbe Verhalten und wird bei jeder Änderung mitgeführt.
- Die Tabellen „Entscheidungsgrundlage“ dokumentieren frühere Konflikte zwischen Text und Legacy-Code. Verbindlich sind der aktuelle Regeltext und `../../masterplan/DECISION-LOG.md`.
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
| G-RNG-1 | Jede Zufallsentscheidung (Rollenverteilung, Scheinrolle des Trugbilderwolfs) läuft über den gespeicherten Seed. Seed und Ziehposition sind Teil des Spielstands. | Masterplan §4 Regel 4 |

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
| G-TAG-4 | Eine normale Hinrichtung ist nur für eine an diesem Tag nominierte Person zulässig. Eine andere Person kann ausschließlich über eine Spielleiter-Übersteuerung mit Warnung, Begründung und Protokolleintrag hingerichtet werden. | DR-03, G-GM-1 |

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
| Nachtpriorität | 2.0 (Rudelschritt). Der Schritt existiert nach G-PH-6, solange irgendein Wolf lebt. Es wachen alle lebenden Personen mit `counts_as_wolf` = ja, im Slice: `werwolf`, `trugbilderwolf`, `spiegelwolf` und ein verwandeltes `wolfskind`. |
| Gültige Ziele | jede lebende Person, auch ein Wolf (Code: Filter `!x.flags.dead`) |
| Dauer | Zielwahl gilt bis zur Morgenauflösung dieser Nacht |
| Auflösung | Morgenauflösung: Schutz prüfen (siehe `schutzengel`, `waldhexe`), sonst Tod mit Ursache `NIGHT_KILL`, Quelle = Rudel |
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
| Gültige Ziele | jede lebende Person außer sich selbst. Dieselbe Person in aufeinanderfolgenden Nächten ist erlaubt (Code: keine Sperre; Text schweigt). |
| Dauer | Wahl bis zum Beginn des folgenden Tages |
| Auflösung | Morgenauflösung: Ist das Wolfsopfer geschützt, stirbt es nicht; Ereignis `KillPrevented{by: schutzengel}` nur für den Spielleiter sichtbar |
| Konflikte | DR-05 (unten) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | Schutz nachträglich setzen oder entfernen (Warnung, Protokoll) |
| Legacy-Beleg | `Schutzengel`-Handler (`protectedCount`, Filter `role!=="Schutzengel"`) und `Werwolf`-Handler in `abilities-roles-chunk.js`; Rücksetzen `flags.protected` in `onNightStart`, `night.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-05 Schutzengel**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · Dauer | „schütze diesen vor dem **nächsten** Werwolfangriff" (`roles.js`) | Schutz wird zu Beginn jeder Nacht zurückgesetzt, gilt also nur in der Nacht der Wahl (`onNightStart`) | Code: gilt nur in dieser Nacht (`04` A-11 formuliert ebenso) |
| b · Verbrauch | schweigt | Wolfs-Zielwahl auf geschützte Person verbraucht den Schutz sofort und setzt kein Ziel (`Werwolf`-Handler) | Verbrauch erst in der Morgenauflösung (`07` Q1 Tabelle; G-PH-4) |
| c · Sicht der Waldhexe | schweigt | Folge von b: Die Hexe sieht bei geschütztem Ziel „Kein Opfer gesetzt" und erfährt so vom Schutz | Folgt aus b: Die Hexe sieht das gewählte Opfer, unabhängig vom Schutz |

## 4. `das-orakel` · Das Orakel / The Oracle

| Feld | Inhalt |
|---|---|
| Regeltext DE | Jede Nacht wählt das Orakel eine andere lebende Person und erfährt deren Rolle. Zählt die Person als Wolf, lautet das Ergebnis „Werwolf“. Beim Trugbilderwolf gilt stattdessen dessen vom Spielleiter festgelegte Täuschung. |
| Regeltext EN | Each night the Oracle chooses another living person and learns their role. If that person counts as a wolf, the result is "Werewolf". For the Decoy Wolf, the game master's chosen deception applies instead. |
| Fraktion | Dorf |
| Nachtpriorität | 4.6 |
| Gültige Ziele | jede andere lebende Person; Selbstwahl ist verboten |
| Dauer | sofort, keine Zustandsänderung |
| Auflösung | im Schritt: Wahrheit = aktuelle `role_id`; ermitteltes Ergebnis nach DR-07 und `trugbilderwolf`; gezeigtes Ergebnis nach Bestätigung „Gezeigt" (G-INF-1). Ereignis `InfoRevealed` mit Sichtbarkeit „nur handelnde Person" |
| Konflikte | Verwandeltes `wolfskind` und `lehrling` mit geerbter Rolle werden nach aktuellem Zustand ermittelt (Code: `isWolf`, `seat.role`) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | gezeigte Information abweichend setzen (Warnung, Protokoll mit ermitteltem und gezeigtem Wert) |
| Legacy-Beleg | `"Das Orakel"`-Handler in `abilities-roles-chunk.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-07 Orakel**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · Ergebnis bei Wölfen | „erfahre die Rolle eines Spielers" | Jeder Wolf außer Trugbilderwolf erscheint als „Werwolf" | Code (`04` A-8 als verifiziert eingestuft; schützt Sonderwölfe vor Enttarnung ihrer Fähigkeit) |
| b · Ergebnis bei Nicht-Wölfen | tatsächliche Rolle | tatsächliche Rolle | keine Abweichung |
| c · sich selbst wählen | schweigt | erlaubt (Filter nur `!dead` über `startPick`) | ausschließen, weil ergebnislos |

## 5. `trugbilderwolf` · Trugbilderwolf / Decoy Wolf

| Feld | Inhalt |
|---|---|
| Regeltext DE | Der Trugbilderwolf gehört zu den Wölfen und wacht mit dem Rudel. Der Spielleiter legt seine Scheinrolle fest. Prüft ihn das Orakel, erhält es diese Scheinrolle statt „Werwolf“. |
| Regeltext EN | The Decoy Wolf belongs to the wolves and wakes with the pack. The game master defines their decoy role. When the Oracle checks them, it receives that decoy role instead of "Werewolf". |
| Fraktion | Werwölfe. `counts_as_wolf` = ja. `appears_as` = Scheinrolle (nur gegenüber Informationsrollen) |
| Nachtpriorität | keine eigene; Teil des Rudelschritts 2.0 |
| Gültige Ziele | wie `werwolf` im Rudelschritt |
| Dauer | Die gewählte Scheinrolle bleibt bestehen, bis der Spielleiter sie regelkonform ändert. |
| Auflösung | im Orakel-Schritt ohne Zufallsziehung. Ermitteltes Ergebnis = Scheinrolle; Wahrheit = `trugbilderwolf` |
| Konflikte | Scheinrolle kann eine Rolle sein, die im Spiel lebend existiert (beabsichtigt, Code) |
| Siegbezug | G-SIEG-2 |
| Manuelle Übersteuerung | gezeigte Scheinrolle abweichend setzen (G-INF-2) |
| Legacy-Beleg | Beschreibung `"Trugbilderwolf"` in `roles.js`; Zufallsziehung `pool[Math.floor(Math.random()*pool.length)]` im `"Das Orakel"`-Handler, `abilities-roles-chunk.js`; `WOLF_ROLES_SET` und `WOLF_KILL_ROLES` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-08 Trugbilderwolf**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| Ziehungszeitpunkt | „zufällige Nicht-Wolf-Rolle" | bei jeder Prüfung neu (`Math.random`) | einmal pro Partie ziehen und beibehalten; ist die Scheinrolle bei einer späteren Prüfung nicht mehr gültig, neu ziehen. Sonst verrät eine zweite Prüfung mit anderem Ergebnis die Täuschung |

## 6. `waldhexe` · Waldhexe / Witch of the Woods

| Feld | Inhalt |
|---|---|
| Regeltext DE | Jede Nacht erfährt die Waldhexe den Namen des Wolfsopfers. Einmal pro Partie darf sie dieses Opfer retten und einmal pro Partie eine lebende Person vergiften; beides ist in derselben Nacht erlaubt. Rettet sie das Opfer, erfährt sie zusätzlich dessen Rolle. Das gerettete Opfer stirbt in dieser Nacht nicht durch den Wolfsangriff. Das Giftziel stirbt sofort. |
| Regeltext EN | Each night the Witch of the Woods learns the wolf victim's name. Once per game she may save that victim and once per game poison a living person; both may be used in the same night. If she saves the victim, she additionally learns their role. The saved victim does not die from the wolf attack that night. The poisoned target dies immediately. |
| Fraktion | Dorf |
| Nachtpriorität | 3.4 (nach dem Rudel, vor dem Orakel) |
| Gültige Ziele | Rettung: nur das aktuelle Wolfsopfer dieser Nacht, auch sie selbst (Code). Gift: jede lebende Person, auch sie selbst und das Wolfsopfer (Code: Filter `!x.flags.dead`) |
| Dauer | Rettung gilt für den Wolfsangriff dieser Nacht. Einmal-Nutzungen gelten pro Person und Fähigkeit für die ganze Partie (G-ID-3) |
| Auflösung | Mehrstufiger Prompt, **eine** Prompt-Kette (03 §5.5): 1 Opfer anzeigen → 2 retten ja/nein (nur wenn Opfer vorhanden und Rettung verfügbar) → 3 vergiften ja/nein (nur wenn Gift verfügbar) → 4 Giftziel wählen → 5 bestätigen. Erst Schritt 5 erzeugt Ereignisse. Abbruch löscht den Prompt ohne Teilwirkung |
| Konflikte | Rettung eines geschützten Opfers: siehe DR-05c. Gift und Wolfsopfer auf derselben Person: eine Person stirbt nur einmal; die erste angewandte Ursache gilt (G-TOD-1). Gift auf Sensenträger: löst dessen Reaktion aus (G-TOD-4) |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | Nutzungen zurücksetzen oder als verbraucht markieren; Giftopfer per Korrektur wiederbeleben (Warnung, Protokoll) |
| Legacy-Beleg | `Waldhexe`-Handler (`WaldhexeL`, `WaldhexeD`, Anzeige `v.role`) in `abilities-roles-chunk.js`; `hexeAskDeath` und `witchDeadlyFatePick` (`applyKill(s,"WITCH_POISON")` sofort) in `../../../js/core/abilities-helpers.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-06 Waldhexe**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · Anzahl Tränke | DE: „Einmalig kannst du diesen … bewahren **oder** einen anderen Spieler in eine tödliche Zukunft weisen." EN: „once per game you can spare them **or** doom another player" | zwei getrennte Einmal-Fähigkeiten (`WaldhexeL`, `WaldhexeD`) | Code: je einmal retten und einmal vergiften; Text anpassen |
| b · beides in einer Nacht | schweigt | erlaubt (nach Rettung folgt `hexeAskDeath`) | Code: erlaubt |
| c · Todeszeitpunkt Gift | schweigt | sofort in der Nacht; spätere Nachtschritte der vergifteten Person entfallen | sofort (Code), Folgereaktionen nach DR-09 |
| d · Was die Hexe sieht | „Sieht jede Nacht die Zukunft des Opfers" | Spielleiterdialog zeigt die **Rolle** des Opfers | Der Spielleiter sieht Name und Rolle; der Hexe wird nur die Person gezeigt. Die Rolle des Opfers ist keine Hexeninformation |

## 7. `sensentraeger` · Sensenträger / Reaper

| Feld | Inhalt |
|---|---|
| Regeltext DE | Stirbt der Sensenträger, darf er eine lebende Person wählen oder verzichten. Die gewählte Person stirbt durch seinen Fluch. Nach einem Tod in der Nacht erfolgt die Reaktion in der Morgenauflösung, nach einem Tod am Tag sofort. |
| Regeltext EN | When the Reaper dies, they may choose one living person or decline. The chosen person dies from their curse. After a death at night the reaction happens during dawn resolution; after a death during the day it happens immediately. |
| Fraktion | Dorf |
| Nachtpriorität | keine; Reaktion (`reaction_queue`) |
| Gültige Ziele | jede lebende Person (Code: `!x.flags.dead && x!==h`) |
| Dauer | Reaktion bleibt offen und persistent, bis sie beantwortet oder bewusst übersprungen ist |
| Auflösung | Tod des Sensenträgers → Reaktion einreihen → Prompt „verfluchen? → Ziel → bestätigen" → Tod mit Ursache `HUNTER_SHOT`, Quelle = Sensenträger. Einmal pro Person (Code: `meta.hunterShot`) |
| Konflikte | Schutzengel schützt nicht (nur Wolfsangriff). Wird ein weiterer Sensenträger getroffen, entsteht eine weitere Reaktion. Siegprüfung vor/nach Reaktion: DR-14 |
| Siegbezug | Dorf |
| Manuelle Übersteuerung | Reaktion überspringen oder nachträglich auslösen (Warnung, Protokoll) |
| Legacy-Beleg | `window.__queueHunterOnDeath`, `processQueue` (`if(state.dark) return;`), Schlüssel `hunterCurseQueuedAsk` in `../../../game.html`; Einreihung in `postDeathHooks`, `js/ui/core.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-09 Sensenträger**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · Pflicht oder freiwillig | „erntet eine letzte Seele seiner Wahl" | freiwillig (Knopf „Überspringen") | Code: freiwillig |
| b · Zeitpunkt nach Tod am Tag | „Beim Tod" | Warteschlange wird nur am Tag verarbeitet; nach Tageslynch in der Praxis erst nach der nächsten Nacht (`04` A-6) | sofort nach der Hinrichtung (`07` Q1 Tabelle) |
| c · Zeitpunkt nach Tod in der Nacht | „Beim Tod" | am folgenden Morgen | Morgenauflösung (`07` Q1: „alle Reaktionen am Morgen") |

## 8. `wolfskind` · Wolfskind / Wolf Child

| Feld | Inhalt |
|---|---|
| Regeltext DE | In der ersten Nacht wählt das Wolfskind eine andere lebende Person als Vorbild. Stirbt das Vorbild, während das Wolfskind lebt, zählt das Wolfskind ab sofort als Wolf und gewinnt mit den Werwölfen. Seine Rolle bleibt Wolfskind. Ab der folgenden Nacht wacht es mit dem Rudel. |
| Regeltext EN | In the first night the Wolf Child chooses another living person as their role model. If that role model dies while the Wolf Child lives, the Wolf Child counts as a wolf and wins with the werewolves. Their role remains Wolf Child. From the following night onward they wake with the pack. |
| Fraktion | Dorf; nach Verwandlung Werwölfe. `counts_as_wolf` = nein, danach ja. `appears_as` folgt `counts_as_wolf` (Orakel: „Werwolf" nach Verwandlung, Code `isWolf`) |
| Nachtpriorität | 0.9, nur Nacht 1, einmalig |
| Gültige Ziele | jede andere lebende Person; Selbstwahl ist verboten |
| Dauer | Vorbildbindung für die ganze Partie; Verwandlung dauerhaft |
| Auflösung | Tod des Vorbilds (jede Ursache) → in derselben Pipeline-Ausführung `RoleChanged`/Fraktionswechsel-Ereignis, nur für den Spielleiter sichtbar; danach Siegprüfung |
| Konflikte | Stirbt das Vorbild, während das Wolfskind tot ist: keine Verwandlung (Code: `mogli` nur lebend). Wächter am Tor nicht im Slice |
| Siegbezug | vor Verwandlung Dorf, danach G-SIEG-2 |
| Manuelle Übersteuerung | Vorbild nachträglich setzen, Verwandlung auslösen oder rückgängig machen (Warnung, Protokoll) |
| Legacy-Beleg | `Wolfskind`-Handler (`MogliVorbildId`, Filter `!x.flags.dead`) in `abilities-roles-chunk.js`; Verwandlung `mogli.flags.werewolf=true` in `postDeathHooks`, `js/ui/core.js`; Beschreibung `"Wolfskind"` in `roles.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-10 Wolfskind**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · sich selbst wählen | DE „einen Feind", EN „an enemy" | erlaubt (Filter nur `!dead`); Prompt nennt es „Vorbild" | ausschließen; Begriff „Vorbild" in beiden Sprachen vereinheitlichen |
| b · Rudelteilnahme | „zählst fortan als Wolf" | nur `flags.werewolf`; `wolfskind` fehlt in `WOLF_KILL_ROLES` | wacht ab der folgenden Nacht mit dem Rudel und wählt mit |

## 9. `lehrling` · Lehrling / Apprentice

| Feld | Inhalt |
|---|---|
| Regeltext DE | Beim Nachtschritt des Lehrlings wählt der Spielleiter drei geeignete lebende Personen aus. Die App zeigt dem Lehrling nur deren drei Rollen, nicht die Personen. Der Lehrling wählt eine Rolle; die zugehörige Person wird verdeckt als Meister gespeichert. Stirbt der Meister, während der Lehrling lebt, erbt der Lehrling dessen Rolle mit vollständig zurückgesetzten Fähigkeiten. Die geerbte Rolle wirkt ab der folgenden Nacht. Erbt er Wolfskind, wählt er bei seinem nächsten Nachtschritt ein neues Vorbild und verwandelt sich erst nach dessen Tod. |
| Regeltext EN | During the Apprentice's night step, the game master selects three eligible living people. The app shows the Apprentice only their three roles, not the people. The Apprentice chooses a role; the linked person is stored secretly as their master. If the master dies while the Apprentice lives, the Apprentice inherits that role with all ability uses reset. The inherited role becomes active from the following night. If they inherit Wolf Child, they choose a new role model on their next night step and transform only after that role model dies. |
| Fraktion | Dorf; nach Erbe die Fraktion der geerbten Rolle |
| Nachtpriorität | 1.1, nur Nacht 1, einmalig |
| Gültige Ziele | drei vom Spielleiter ausgewählte geeignete lebende Personen; angezeigt werden ausschließlich deren Rollen. Die gewählte Option bindet den Lehrling verdeckt an die zugehörige Person. |
| Dauer | Mentorbindung für die ganze Partie; Rollenwechsel dauerhaft |
| Auflösung | Tod des Mentors → `RoleChanged{from: lehrling, to: <Rolle>, by: mentor_death}` (nur Spielleiter), `original_role_id` bleibt `lehrling`, danach Siegprüfung |
| Konflikte | Erbt der Lehrling `manipulator`, gilt dessen Status „nie nominiert" für die Person des Lehrlings. Erbt er `wolfskind`, übernimmt er keinen bestehenden Wolfsstatus, sondern wählt ein neues Vorbild. Doppelte angezeigte Rollen müssen im Setup eindeutig als getrennte verdeckte Optionen behandelt werden. |
| Siegbezug | Fraktion der aktuellen Rolle |
| Manuelle Übersteuerung | Mentor setzen, Erbe auslösen oder rückgängig machen (Warnung, Protokoll) |
| Legacy-Beleg | `Lehrling`-Handler (Filter `!x.flags.dead&&!isWolf(x)`, Prompt „wähle Mentor (Dorfbewohner)") in `abilities-roles-chunk.js`; Erbe und `resetOnceForInheritedRole` in `postDeathHooks`, `js/ui/core.js` |

**ENTSCHEIDUNGSGRUNDLAGE · DR-11 Lehrling**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · erlaubte Mentoren | „Wählt einen Mentor" | Filter: lebend und kein Wolf (Einzelsiegrollen und sich selbst erlaubt); Prompt-Text sagt „Dorfbewohner" | eine andere lebende Person, die kein Wolf ist (Filter, ohne Selbstwahl) |
| b · Nutzungen der geerbten Rolle | schweigt | Einmal-Flags werden zurückgesetzt, Fähigkeiten also frisch | Code: frisch, weil Nutzungen pro Person gezählt werden (G-ID-3) |
| c · Wirkungsbeginn | schweigt | sofort; `rebuildOrder` nimmt die Rolle in die laufende Nacht auf | ab der nächsten Nacht; verhindert doppelte Nachtaktion derselben Rolle in einer Nacht |
| d · Mentor ist verwandeltes Wolfskind | schweigt | Lehrling wird `wolfskind` und Wolf | Code übernehmen; im Slice als Randfall testen |
| – · toter Lehrling erbt | „übernimmt die Rolle" | erbt auch tot (Bug F5) | bereits entschieden: behoben (07-T2) |

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
| Konflikte | Gleichzeitig mit Wolfsparität oder Dorfsieg: DR-02. Hinrichtung ohne Nominierung (falls DR-03 sie erlaubt) löst keinen Manipulator-Tod aus, weil keine Nominierung vorliegt |
| Siegbezug | eigener Siegkandidat; zählt als Nicht-Wolf in G-SIEG-2 |
| Manuelle Übersteuerung | Nominierung zurücknehmen = Undo des Befehls; Status „nie nominiert" korrigieren (Warnung, Protokoll) |
| Legacy-Beleg | `openPop` in `../../../game.html` (Chip `nominated`, `ManipulatorWasNominated`, `applyKill(currentSeat,"MANIPULATOR_NOMINATED")`); `checkWinConditions` (`alive.length===3`) in `js/ui/core.js`; `isWolf` Ausschlussliste |

**ENTSCHEIDUNGSGRUNDLAGE · DR-12 Manipulator**

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| a · „Final 3" | „bis in die Final 3 schafft" | genau 3 Lebende; springt die Zahl von 4 auf 2, gewinnt er nie | höchstens drei Lebende |
| b · Vorrang vor Werwölfen | schweigt | Wolfsparität wird vor dem Manipulator geprüft; Dorfsieg ebenfalls | siehe DR-02 |

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

| Punkt | Text sagt | Code tut | Empfehlung |
|---|---|---|---|
| fehlende Nominierung | „auf den Spieler, der ihn nominiert hat" | Nominierende werden nicht gespeichert; der Spielleiter wählt bei der Hinrichtung frei eine lebende Person | Nur relevant, wenn DR-03 Hinrichtungen ohne Nominierung erlaubt. Dann fragt die App die nominierende Person als Pflichtschritt ab und speichert sie nachträglich |

---

## 12. Zusammenfassung der entschiedenen Konflikte

| ID | Thema | Text | Code | Empfehlung |
|---|---|---|---|---|
| DR-01 | Technische Rollen-IDs | `../../masterplan/RULE-MIGRATION-MATRIX.md`: `villager`, `werewolf` | `03` §5.1 und `04`: `dorfbewohner`, `werwolf`; Legacy nutzt deutsche Anzeigenamen als ID | deutsches ASCII-kebab-case nach `03` §5.1 |
| DR-02 | Siegpriorität und „niemand lebt" | `07` Q4 schlug eine feste Priorität vor | Legacy-Prüfer widersprechen sich | Bei Gleichzeitigkeit entscheidet der Spielleiter; niemand lebt → kein automatischer Sieger |
| DR-03 | Nominierungsregeln | DL: jede Person nominiert standardmäßig einmal und wird einmal nominiert | nur Chip `nominated` ohne Nominierende, Rücksetzen bei Nachtbeginn (`onNightStart`) | pro Tag; nur Lebende nominieren und werden nominiert; Hinrichtung nur für an diesem Tag nominierte Personen, sonst Übersteuerung |
| DR-04 | Öffentliche Todesinformation | DL: „Tagsüber werden nur öffentliche Informationen gezeigt" | Todes-Overlay zeigt Name und Ursache (`_renderDeathGroups`, `_deathLabel` in `../../../js/ui/ui.js`) | Name öffentlich; Rolle gemäß Setup-Option; Ursache intern |
| DR-14 | Siegprüfung und offene Reaktionen | schweigt | Legacy löst Sieg nach jedem Tod sofort aus | nach Tod vorläufig prüfen, Reaktionen abarbeiten, danach final prüfen |

Details, Optionen und Auswirkungen: `decision-request.md`.
