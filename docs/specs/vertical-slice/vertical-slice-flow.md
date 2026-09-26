# Vertical Slice · Ablauf einer Partie

**Stand:** 2026-09-26 · **Status:** abgeglichen mit DR-01 bis DR-14 (`../../masterplan/DECISION-LOG.md`)
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
| **Öffentlich** (vorlesen, später öffentliche Anzeige) | Phase, Nummer, lebend/tot, Namen, Nominierungen, öffentliche Ansagen. Bei einem Tod: Name immer; Rolle nur, wenn im Setup `reveal_role_on_death` = Ja; Ursache nie (DR-04) |

---

## 1. Setup

| Schritt | Spielleiter tut | App tut | Gespeichert |
|---|---|---|---|
| 1.1 | Namen erfassen (6 bis 24) | vergibt je Person eine stabile ID; prüft Anzahl | Personenliste |
| 1.2 | Sitzreihenfolge per Drag-and-drop festlegen | – | `seat_order` |
| 1.3 | Rollen zusammenstellen (Slice-Pool aus `role-selection.md`) | prüft: Rollenanzahl = Personenzahl, Obergrenzen je Rolle nur, wo die Rolle eine eigene festlegt (`dorfbewohner` und `werwolf` haben keine, damit 6 bis 24 Personen allein mit ihnen spielbar sind; `../../masterplan/DECISION-LOG.md` 26.09.2026; die Legacy-Grenzen aus `setup.html` gelten nicht), je mindestens eine Rolle aus Dorf, Werwölfe und Einzelsieg (`DECISION-LOG.md`: „Jede Partie enthält Dorf, Werwölfe und Einzelsiegrollen"; der Core-Slice ohne Einzelsiegrolle verlangt nur Dorf und Werwölfe). Abweichung nur per Übersteuerung mit Warnung | Rollenpool |
| 1.4 | Verteilung wählen: zufällig oder manuell | zufällig: Ziehung über `SeededRng` | Seed, Zuordnung Person → Rolle |
| 1.5a | Ist `trugbilderwolf` im Rollenpool: Scheinrolle festlegen (DR-08) | bietet nur Rollen an, die nicht als Wolf zählen; die Scheinrolle ändert sich danach nur per bestätigter Spielleiterkorrektur | Scheinrolle |
| 1.5 | Option `Rolle beim Tod aufdecken: Ja/Nein` wählen (DR-04) | speichert die Option als Teil des Setups; sie gilt für die ganze Partie | `reveal_role_on_death` |
| 1.6 | Setup bestätigen → `StartGame` | friert `rules_version` ein, legt ersten Checkpoint an | vollständiger Anfangszustand |

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

`StartNight` setzt Phase NIGHT, Nachtzähler 1 und berechnet den Nachtplan aus den lebenden Rolleninhabern. Der Nachtplan ist ein Snapshot: Rollenwechsel und wieder verfügbar gemachte Fähigkeiten während der Nacht fügen keine Schritte hinzu, sie gelten ab der nächsten Nacht.

| Nr. | Priorität | Schritt | Prompt | Wirkung beim Bestätigen |
|---|---|---|---|---|
| 1 | 0.9 | `wolfskind` (Nacht 1) | Vorbild wählen (andere lebende Person, nicht sich selbst) | Bindung Wolfskind → Vorbild |
| 2 | 1.1 | `lehrling` (Nacht 1) | a) nur Cockpit: Spielleiter wählt drei geeignete lebende Personen außer dem Lehrling → b) gesicherte Karte: Lehrling sieht **nur drei Rollen**, keine Namen, und wählt eine → c) bestätigen | verdeckte Bindung Lehrling → Person der gewählten Rolle (nur Spielleiter sichtbar) |
| 3 | 1.3 | `schutzengel` | 1 andere lebende Person wählen | Schutz nur für diese Nacht gegen Wolfsangriff; angewandt in der Morgenauflösung (DR-05) |
| 4 | 2.0 | Rudel (alle, die zu Beginn der Nacht als Wolf zählen) | 1 Opfer oder „kein Opfer" | Wolfsziel für die Morgenauflösung |
| 5 | 3.4 | `waldhexe` | Kette: Name des Opfers sehen → retten? (bei Ja zusätzlich Rolle des Opfers sehen) → vergiften? → Ziel → bestätigen | Rettung und/oder Gift, beide in derselben Nacht erlaubt (DR-06) |
| 6 | 4.6 | `das-orakel` | 1 andere lebende Person wählen → Ergebnis → „Gezeigt" | nur Information (Wahrheit, ermittelt, gezeigt); Sonderwölfe erscheinen als `werwolf`, Trugbilderwolf mit der beim Spielaufbau gespeicherten Scheinrolle (DR-07, DR-08) |

Regeln des Ablaufs:

- Immer genau ein aktiver Schritt. Der Spielleiter kann den Rudelschritt mit Grund überspringen (`SkipStep`), das Ergebnis ist „kein Angriff". Schutzengel-, Waldhexen- und Orakelschritt sind nie überspringbar; vor der Bestätigung können sie abgebrochen und erneut angeboten werden. Die Waldhexe verzichtet ausdrücklich in ihrem Prompt.
- Ein geplanter persönlicher Schritt entfällt automatisch mit Protokolleintrag (`StepDropped`), wenn seine Person inzwischen tot ist (Grund „tot") oder nicht mehr die geplante Rolle hat (Grund „Rolle gewechselt"); die Fähigkeit einer verlorenen Rolle wird nie ausgeführt. Ebenso entfällt ein Waldhexenschritt ohne mögliche Entscheidung; sind beide Tränke verbraucht, erscheint er gar nicht im Nachtplan.
- Ein offener Prompt (auch mitten in der Hexen- oder Lehrlingskette) blockiert `EndNight` und wird bei jedem Checkpoint mit allen Teilantworten gespeichert.
- `CancelPrompt` stellt den Zustand vor dem Prompt exakt wieder her (gleicher fachlicher Hash).
- Das Gift der Waldhexe tötet sofort (DR-06). Spätere Nachtschritte der vergifteten Person entfallen; ihre Todesreaktionen werden in der Morgenauflösung abgearbeitet (DR-09).
- Die gesicherte Karte des Lehrlings und alle Ereignisse mit Sichtbarkeit „handelnde Person" enthalten nur Rollen-IDs und Optionsnummern, niemals Personen-IDs, Namen oder Sitzplätze der drei Personen (`rules-register.md` §9).
- Nach Schritt 6 bietet die App `EndNight` an, mit Hinweis auf übersprungene Schritte.

## 4. Morgenauflösung und Morgenbericht

`EndNight` setzt Phase DAWN_RESOLUTION. Die Auflösung läuft deterministisch in dieser Reihenfolge:

1. Wolfsziel prüfen: Rettung durch Waldhexe oder Schutz durch Schutzengel verhindert den Tod (`KillPrevented`, nur Spielleiter). Der Schutz endet danach (DR-05).
2. Tod des Wolfsopfers mit Ursache `NIGHT_KILL` anwenden, sonst nichts. Ist das bestätigte Opfer bereits tot (z. B. durch eine Spielleiterkorrektur in der Nacht), findet kein Angriff statt und die Rudelwahl wird nicht erneut geöffnet. Nach jedem Tod: vorläufiger Siegstatus (DR-14).
3. Unmittelbare Todesfolgen ohne Entscheidung, jeweils direkt beim Tod in der Pipeline: Verwandlung `wolfskind`, Erbe des `lehrling` (auch für Tode in der Nacht, z. B. durch Gift).
4. Reaktionen mit Entscheidung nacheinander abfragen (Sensenträger, auch nach Gifttod in der Nacht), jeweils freiwillig (DR-09). Jede Reaktion kann weitere Tode und Folgen auslösen; die Schleife endet, wenn die Warteschlange leer ist.
5. Verbindliche Siegprüfung erst jetzt, wenn keine Reaktion und kein Prompt mehr offen ist (DR-14). Kandidaten siehe Abschnitt 9.
6. Morgenbericht anzeigen:

| Teil | Inhalt |
|---|---|
| Öffentlich vorlesen | Namen der in der Nacht Gestorbenen oder „Niemand ist gestorben"; Rolle der Gestorbenen nur bei `reveal_role_on_death` = Ja; keine Ursache (DR-04) |
| Nur für den Spielleiter | wer wen geschützt oder gerettet hat, wer vergiftet wurde, Ursachen, Verwandlungen, Lehrling-Bindung und -Erbe, Informationsergebnisse der Nacht |

7. `BeginDay` setzt Phase DAY (Unterzustand DISCUSSION) und den Tageszähler.

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
| 6.1 | tippt nominierende Person, dann nominierte Person | prüft nach DR-03: beide leben; jede Person nominiert pro Tag einmal und wird pro Tag einmal nominiert; Abweichung nur als Übersteuerung mit Warnung, Begründung und Protokoll | `Nomination{nominator_id, nominee_id, day}` |
| 6.2 | – | Ist die nominierte Person der Manipulator, stirbt er sofort (`MANIPULATOR_NOMINATED`, Quelle = nominierende Person); Folgen und Reaktionen laufen sofort | Tod mit Ursache, Quelle, Zeitpunkt |
| 6.3 | Diskussion und Abstimmung finden am Tisch statt; der Spielleiter zählt physisch | **nichts**: kein Stimmfeld, keine Zählung, keine Mehrheitsberechnung | nichts |
| 6.4 | Nominierung versehentlich erfasst | Undo des Befehls `Nominate` | – |

## 7. Spielleiter bestätigt Lynch/Kill

| Schritt | Ablauf |
|---|---|
| 7.1 | Der Spielleiter wählt die betroffene Person und die Todesaktion „Hinrichtung" (`DecideExecution(person)`) oder „Keine Hinrichtung heute" (`DecideExecution(none)`). |
| 7.2 | Die App zeigt dem Spielleiter die Vorschau der Folge (z. B. „Spiegelwolf: stattdessen stirbt *Nominierende Person*") und verlangt Bestätigung. |
| 7.3 | Bei Bestätigung läuft die Tötungs-Pipeline: Spiegelung (`spiegelwolf`, erste Hinrichtung, nur mit gespeicherter Nominierung), sonst Tod mit Ursache `LYNCH`, Quelle = Dorf/Hinrichtung. |
| 7.4 | Folgen ohne Entscheidung (Wolfskind, Lehrling), dann Reaktionen sofort (Sensenträger, DR-09). |
| 7.5 | Vorläufiger Siegstatus nach jedem Tod, verbindliche Prüfung nach allen Reaktionen (DR-14, Abschnitt 9). |
| 7.6 | Eine Hinrichtung einer an diesem Tag nicht nominierten Person ist nur per Übersteuerung mit Warnung, Begründung und Protokoll möglich (DR-03, `GmCorrection execute`, Ursache `LYNCH`, Reaktionen und Siegprüfung normal). Trifft sie den Spiegelwolf, gibt es keine Spiegelung; er stirbt normal (DR-13). |

Gespeichert werden ausschließlich die bestätigte Todesaktion (Person, Aktion, Ursache, Quelle, Zeitpunkt) und ihre Folgeereignisse. Andere Todesarten am Tag laufen als `GmCorrection` mit ausdrücklicher Ursache.

## 8. Nächste Nacht

`EndDay` ist nur möglich, wenn kein Prompt und keine Reaktion offen ist. `StartNight` erhöht den Nachtzähler und berechnet den Nachtplan neu. Der Schutz der Vornacht ist bereits bei Tagesbeginn erloschen (DR-05).

- Einmalschritte (`wolfskind`, `lehrling`) der ersten Nacht entfallen ab Nacht 2.
- Ein verwandeltes Wolfskind nimmt ab der Nacht nach seiner Verwandlung am Rudelschritt teil (DR-10).
- Hat der Lehrling seit der letzten Nacht eine Rolle geerbt, sind deren aktiv auszuführende Nachtfähigkeiten ab diesem `StartNight` erstmals verfügbar (DR-11): Er erhält die Nachtschritte mit zurückgesetzten Einsätzen; eine geerbte Wolfsrolle wacht mit dem Rudel. Rolle, Fraktion, passive Eigenschaften, Siegbedingungen und Todesreaktionen galten bereits ab dem Erbe.
- Hat der Lehrling `wolfskind` geerbt, erhält er in dieser Nacht den Wolfskind-Schritt (0.9) und wählt ein neues Vorbild; er bleibt unverwandelt, bis dieses Vorbild stirbt.
- Lebt kein `werwolf`, aber ein anderer Wolf, bleibt der Rudelschritt bestehen (`rules-register.md` G-PH-6).

## 9. Möglicher Sieg

| Schritt | Ablauf |
|---|---|
| 9.1 | Nach jedem Tod berechnet die eine Siegprüfung einen vorläufigen Siegstatus. Offene Reaktionen und Fähigkeiten werden zuerst vollständig abgearbeitet; danach wird verbindlich geprüft (DR-14). Jede erfüllte Siegbedingung wird ein Kandidat. Sind mehrere gleichzeitig erfüllt, gibt es keine feste Priorität: Der Spielleiter bestätigt genau einen oder lehnt alle ab (DR-02). Lebt niemand mehr, entsteht kein Kandidat; der Spielleiter erklärt das Ergebnis nach 9.6. |
| 9.2 | Die App zeigt jeden Kandidaten mit Auslöser, z. B. „Wolfsparität: 2 Wölfe gegen 2 Nicht-Wölfe" oder „Manipulator lebt, genau 3 Lebende, nie nominiert" (DR-12). |
| 9.3 | `ConfirmWin` setzt Phase GAME_OVER und speichert Sieger, Grund und Befehlsindex. |
| 9.4 | `RejectWin(reason)` protokolliert die Ablehnung; die Partie läuft weiter. Ein Kandidat wird erst nach einem weiteren Tod erneut berechnet und angeboten. |
| 9.5 | Undo hinter `ConfirmWin` ist erlaubt (Korrektur, `03` §6.3). |
| 9.6 | Der Spielleiter kann per Übersteuerung einen Sieger erklären (Warnung, Protokoll), sofern kein Prompt und keine Reaktion offen ist. |
| 9.7 | Jede Spielleiterkorrektur am Zustand einer Person bricht einen offenen Prompt mit Grund `state_changed_by_gm_correction` ab; der Schritt kann danach neu begonnen werden. Ein Siegkandidat entsteht nie neben einem offenen Prompt oder einer offenen Reaktion (`rules-register.md` G-GM-3). |

## 10. Unterbrechung und Wiederaufnahme

| Ereignis | Verhalten |
|---|---|
| App-Abbruch, Absturz, Akku leer | Beim Start wird der letzte gültige Checkpoint geladen; die App zeigt Phase, letzten bestätigten Schritt und einen offenen Prompt mit Teilantworten. Nichts Unbestätigtes ist angewandt. |
| Beschädigter Spielstand | wird erkannt, nicht überschrieben, gemeldet; Rückfall auf vorherigen Checkpoint (`03` §6.4). |
| Undo | macht genau einen Befehl rückgängig, auch über Neustart hinweg; Redo stellt ihn wieder her. |
| Wechsel in eine Spieleransicht | Rückkehr ins Cockpit nur über bewusste Geste; nach App-Wechsel erscheint der Schutzschirm (`../../godot-migration/02-product-and-ux-spec.md` §8). |
