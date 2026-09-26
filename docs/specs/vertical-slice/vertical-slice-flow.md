# Vertical Slice · Ablauf einer Partie

**Stand:** 2026-09-26 · **Status:** Entwurf, abhängig von `decision-request.md`
**Regeln:** `rules-register.md` · **Rollen:** `role-selection.md` · **Architektur:** `../../godot-migration/03-godot-architecture.md`

Pfade relativ zu `docs/specs/vertical-slice/`.

## 0. Leitplanken

1. Das Tablet ist die **einzige Zustandsautorität**. Kein anderer Client verändert den Spielstand.
2. Nur bestätigte Befehle verändern den Zustand. Jeder bestätigte Befehl erzeugt Ereignisse und einen persistenten Checkpoint (Masterplan Phase 2: „Checkpoint nach jeder bestätigten Aktion").
3. Zustand hängt an der stabilen Personen-ID, nie am Sitzplatz.
4. **Keine digitale Stimmabgabe und keine Stimmzählung.** Gespeichert werden Nominierende, Nominierte und die bestätigte Todesaktion.
5. Wahrheit, ermittelte und gezeigte Information sind getrennte gespeicherte Werte (`rules-register.md` G-INF-1).
6. Jede Zufallsentscheidung nutzt den gespeicherten Seed.
7. Offene mehrstufige Aktionen und Reaktionen sind Teil des Spielstands und überleben einen Neustart.

### 0.1 Befehle

Grundlage ist die Befehlsliste in `03` §5.6: `StartGame`, `StartNight`, `BeginStep`, `AnswerPrompt`, `SkipStep`, `CancelPrompt`, `EndNight`, `Nominate`, `DecideExecution`, `EndDay`, `GmCorrection`.

Für den Slice zusätzlich nötig (Vorschlag, noch nicht in `03`):

| Befehl | Zweck |
|---|---|
| `ConfirmRoleShown(person)` | protokolliert, dass eine Person ihre Rolle gesehen hat; macht die Rollenanzeige nach Abbruch fortsetzbar |
| `ReorderSeats(order)` | ändert nur die Sitzreihenfolge (Drag-and-drop); Personenzustand bleibt unverändert |
| `ConfirmWin(candidate_id)` / `RejectWin(candidate_id, reason)` | Spielleiterbestätigung eines Siegkandidaten (`rules-register.md` G-SIEG-3) |
| `BeginDay` | schließt den Morgenbericht und startet die Tagesphase |

### 0.2 Sichtbarkeit

| Kanal | Inhalt |
|---|---|
| **Spielleiter** (Cockpit) | vollständiger Zustand, alle Ereignisse |
| **Handelnde Person** (gesicherte Tablet-Karte) | genau die Information oder Auswahl dieses Schritts |
| **Öffentlich** (vorlesen, später öffentliche Anzeige) | Phase, Nummer, lebend/tot, Namen, Nominierungen, öffentliche Ansagen; Umfang bei Toden nach DR-04 |

---

## 1. Setup

| Schritt | Spielleiter tut | App tut | Gespeichert |
|---|---|---|---|
| 1.1 | Namen erfassen (6 bis 24) | vergibt je Person eine stabile ID; prüft Anzahl | Personenliste |
| 1.2 | Sitzreihenfolge per Drag-and-drop festlegen | – | `seat_order` |
| 1.3 | Rollen zusammenstellen (Slice-Pool aus `role-selection.md`) | prüft: Rollenanzahl = Personenzahl, Obergrenzen je Rolle nur, wo die Rolle eine eigene festlegt (`dorfbewohner` und `werwolf` haben keine, damit 6 bis 24 Personen allein mit ihnen spielbar sind; `DECISION-LOG.md` 26.09.2026; die Legacy-Grenzen aus `setup.html` gelten nicht), je mindestens eine Rolle aus Dorf, Werwölfe und Einzelsieg (`DECISION-LOG.md`: „Jede Partie enthält Dorf, Werwölfe und Einzelsiegrollen"). Abweichung nur per Übersteuerung mit Warnung | Rollenpool |
| 1.4 | Verteilung wählen: zufällig oder manuell | zufällig: Ziehung über `SeededRng` | Seed, Zuordnung Person → Rolle |
| 1.5 | Setup bestätigen → `StartGame` | friert `rules_version` ein, legt ersten Checkpoint an | vollständiger Anfangszustand |

Gleicher Seed, gleiche Personenliste und gleicher Rollenpool erzeugen dieselbe Zuordnung.

## 2. Rollenanzeige

| Schritt | Ablauf |
|---|---|
| 2.1 | Die App zeigt eine neutrale Karte „Gib das Tablet an: *Name*". |
| 2.2 | Die Person öffnet die Karte mit einer bewussten Aktion, die nicht versehentlich ausgelöst werden kann (Geste wird in Phase 2 festgelegt), und sieht nur Name, Rolle und Kurztext ihrer Rolle. |
| 2.3 | Schließen führt zurück zur neutralen Karte; `ConfirmRoleShown(person)` wird gespeichert. |
| 2.4 | Nach einem Abbruch setzt die App bei der ersten Person ohne Bestätigung fort. |

Keine Rolle erscheint im Cockpit, solange eine Spieleransicht aktiv ist. Wölfe erkennen einander physisch in Nacht 1 (Rudelschritt), nicht über die Rollenkarte.

## 3. Erste Nacht

`StartNight` setzt Phase NIGHT, Nachtzähler 1 und berechnet den Nachtplan aus den lebenden Rolleninhabern.

| Nr. | Priorität | Schritt | Prompt | Wirkung beim Bestätigen |
|---|---|---|---|---|
| 1 | 0.9 | `wolfskind` (nur Nacht 1) | Vorbild wählen | Bindung Wolfskind → Vorbild |
| 2 | 1.1 | `lehrling` (nur Nacht 1) | Mentor wählen | Bindung Lehrling → Mentor |
| 3 | 1.3 | `schutzengel` | 1 Person wählen | Schutz-Effekt mit Quelle und Dauer (DR-05) |
| 4 | 2.0 | Rudel (`werwolf`, `trugbilderwolf`, `spiegelwolf`, ggf. verwandeltes `wolfskind`) | 1 Opfer oder „kein Opfer" | Wolfsziel für die Morgenauflösung |
| 5 | 3.4 | `waldhexe` | Kette: Opfer sehen → retten? → vergiften? → Ziel → bestätigen | Rettung und/oder Gift (DR-06) |
| 6 | 4.6 | `das-orakel` | 1 Person wählen → Ergebnis → „Gezeigt" | nur Information (Wahrheit, ermittelt, gezeigt) |

Regeln des Ablaufs:

- Immer genau ein aktiver Schritt. Der Spielleiter kann einen Schritt mit Grund überspringen (`SkipStep`), das Ergebnis ist „keine Wirkung".
- Ein Schritt eines inzwischen toten Rolleninhabers hat keine Wirkung und wird mit Grund „tot" angezeigt.
- Ein offener Prompt (auch mitten in der Hexenkette) blockiert `EndNight` und wird bei jedem Checkpoint mit allen Teilantworten gespeichert.
- `CancelPrompt` stellt den Zustand vor dem Prompt exakt wieder her (gleicher fachlicher Hash).
- Das Gift der Waldhexe wirkt nach DR-06c sofort oder am Morgen.
- Nach Schritt 6 bietet die App `EndNight` an, mit Hinweis auf übersprungene Schritte.

## 4. Morgenauflösung und Morgenbericht

`EndNight` setzt Phase DAWN_RESOLUTION. Die Auflösung läuft deterministisch in dieser Reihenfolge:

1. Wolfsziel prüfen: Rettung durch Waldhexe oder Schutz durch Schutzengel verhindert den Tod (`KillPrevented`, nur Spielleiter).
2. Tod des Wolfsopfers mit Ursache `NIGHT_KILL` anwenden, sonst nichts.
3. Hexengift anwenden, falls DR-06c „am Morgen" entscheidet.
4. Unmittelbare Todesfolgen ohne Entscheidung: Verwandlung `wolfskind`, Rollenwechsel `lehrling`.
5. Reaktionen mit Entscheidung nacheinander abfragen (Sensenträger), jeweils mit Grund. Jede Reaktion kann weitere Tode und Folgen auslösen; die Schleife endet, wenn die Warteschlange leer ist.
6. Siegprüfung (Zeitpunkt nach DR-14). Bei einem Kandidaten siehe Abschnitt 9.
7. Morgenbericht anzeigen:

| Teil | Inhalt |
|---|---|
| Öffentlich vorlesen | Namen der in der Nacht Gestorbenen oder „Niemand ist gestorben"; weitere Angaben nach DR-04 |
| Nur für den Spielleiter | wer wen geschützt oder gerettet hat, wer vergiftet wurde, Ursachen, Verwandlungen, Rollenwechsel, Informationsergebnisse der Nacht |

8. `BeginDay` setzt Phase DAY (Unterzustand DISCUSSION) und den Tageszähler.

## 5. Tag

| Unterzustand | Inhalt |
|---|---|
| DISCUSSION | Timer (Start/Pause/+30 s) ist Anzeige, kein Regelzustand (`03` §6.3). Sitztausch per `ReorderSeats` jederzeit möglich. |
| NOMINATION | Nominierungen nach Abschnitt 6 |
| EXECUTION_DECIDED | Todesaktion bestätigt oder „keine Hinrichtung" |
| AFTERMATH | Reaktionen, Siegprüfung, danach `EndDay` |

## 6. Physische Nominierung und Abstimmung

| Schritt | Spielleiter tut | App tut | Gespeichert |
|---|---|---|---|
| 6.1 | tippt nominierende Person, dann nominierte Person | prüft nach DR-03 (Standard: jede Person nominiert einmal und wird einmal nominiert) | `Nomination{nominator_id, nominee_id, day}` |
| 6.2 | – | Ist die nominierte Person der Manipulator, stirbt er sofort (`MANIPULATOR_NOMINATED`, Quelle = nominierende Person); Folgen und Reaktionen laufen sofort | Tod mit Ursache, Quelle, Zeitpunkt |
| 6.3 | Diskussion und Abstimmung finden am Tisch statt; der Spielleiter zählt physisch | **nichts**: kein Stimmfeld, keine Zählung, keine Mehrheitsberechnung | nichts |
| 6.4 | Nominierung versehentlich erfasst | Undo des Befehls `Nominate` | – |

## 7. Spielleiter bestätigt Lynch/Kill

| Schritt | Ablauf |
|---|---|
| 7.1 | Der Spielleiter wählt die betroffene Person und die Todesaktion „Hinrichtung" (`DecideExecution(person)`) oder „Keine Hinrichtung heute" (`DecideExecution(none)`). |
| 7.2 | Die App zeigt die Vorschau der Folge (z. B. „Spiegelwolf: stattdessen stirbt *Nominierende Person*") und verlangt Bestätigung. |
| 7.3 | Bei Bestätigung läuft die Tötungs-Pipeline: Spiegelung (`spiegelwolf`), sonst Tod mit Ursache `LYNCH`, Quelle = Dorf/Hinrichtung. |
| 7.4 | Folgen ohne Entscheidung (Wolfskind, Lehrling), dann Reaktionen (Sensenträger nach DR-09b). |
| 7.5 | Siegprüfung (Abschnitt 9). |
| 7.6 | Eine Hinrichtung einer nicht nominierten Person ist nach DR-03 entweder gesperrt oder nur per Übersteuerung mit Warnung möglich. |

Gespeichert werden ausschließlich die bestätigte Todesaktion (Person, Aktion, Ursache, Quelle, Zeitpunkt) und ihre Folgeereignisse. Andere Todesarten am Tag laufen als `GmCorrection` mit ausdrücklicher Ursache.

## 8. Nächste Nacht

`EndDay` ist nur möglich, wenn kein Prompt und keine Reaktion offen ist. `StartNight` erhöht den Nachtzähler, lässt nachtgebundene Effekte auslaufen (Schutz nach DR-05a) und berechnet den Nachtplan neu:

- Einmalschritte (`wolfskind`, `lehrling`) entfallen ab Nacht 2.
- Ein verwandeltes Wolfskind nimmt nach DR-10b am Rudelschritt teil.
- Ein Lehrling mit geerbter Rolle erhält deren Nachtschritt nach DR-11c.
- Lebt kein `werwolf`, aber ein anderer Wolf, bleibt der Rudelschritt bestehen (`rules-register.md` G-PH-6).

## 9. Möglicher Sieg

| Schritt | Ablauf |
|---|---|
| 9.1 | Nach jedem zustandsändernden Befehl berechnet die eine Siegprüfung höchstens einen Kandidaten (Priorität nach DR-02, Zeitpunkt nach DR-14). |
| 9.2 | Die App zeigt den Kandidaten mit Auslöser, z. B. „Wolfsparität: 2 Wölfe gegen 2 Nicht-Wölfe" oder „Manipulator lebt, 3 Lebende, nie nominiert". |
| 9.3 | `ConfirmWin` setzt Phase GAME_OVER und speichert Sieger, Grund und Befehlsindex. |
| 9.4 | `RejectWin(reason)` protokolliert die Ablehnung; die Partie läuft weiter. Derselbe Kandidat wird erst nach einer weiteren Zustandsänderung erneut angeboten. |
| 9.5 | Undo hinter `ConfirmWin` ist erlaubt (Korrektur, `03` §6.3). |
| 9.6 | Der Spielleiter kann jederzeit per Übersteuerung einen Sieger erklären (Warnung, Protokoll). |

## 10. Unterbrechung und Wiederaufnahme

| Ereignis | Verhalten |
|---|---|
| App-Abbruch, Absturz, Akku leer | Beim Start wird der letzte gültige Checkpoint geladen; die App zeigt Phase, letzten bestätigten Schritt und einen offenen Prompt mit Teilantworten. Nichts Unbestätigtes ist angewandt. |
| Beschädigter Spielstand | wird erkannt, nicht überschrieben, gemeldet; Rückfall auf vorherigen Checkpoint (`03` §6.4). |
| Undo | macht genau einen Befehl rückgängig, auch über Neustart hinweg; Redo stellt ihn wieder her. |
| Wechsel in eine Spieleransicht | Rückkehr ins Cockpit nur über bewusste Geste; nach App-Wechsel erscheint der Schutzschirm (`../../godot-migration/02-product-and-ux-spec.md` §8). |
