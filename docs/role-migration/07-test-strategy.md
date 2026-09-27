# 07 · Teststrategie

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · Planung, keine Tests geschrieben

## 1. Grundsätze

- **Tests zuerst.** Wie bei allen bisherigen Rollen: fehlschlagende headless Tests unter `godot/tests/unit/test_<rolle>.gd`, dann Umsetzung. Runner und Muster: [`../../godot/README.md`](../../godot/README.md) „Tests ausführen“.
- **Bekannte Legacy-Bugs werden als korrigierte Abweichung getestet** (Masterplan Phase 3), nie als Referenz. Jeder Bug aus [`04`](04-rule-conflicts.md) §4 mit Regressionstest wird zu einem Godot-Test, sobald die Rolle umgesetzt wird.
- **Golden Tests gegen Legacy nur für `legacy-verified`-Verhalten**, und nur deterministisch (kein `Math.random`).
- **Jede Charge hält alle bestehenden Tests grün** (Stand am Basiscommit: 351).
- **Keine Stimmfelder** in Zustand und Ereignissen (AS-C11) für alle neuen Rollen.

## 2. Testgruppen

| Gruppe | Prüft |
|---|---|
| Normalfall | Kernregel mit gültiger Eingabe |
| ungültiges Ziel | abgelehnte Eingabe ändert weder Zustand noch Ereignisse |
| tote Person | tote Handelnde, tote Ziele, Tod vor dem eigenen Schritt (`StepDropped`) |
| Selbstwahl | erlaubt oder abgelehnt laut Regel |
| mehrere Kopien | je Person getrennt, Reihenfolge nach Personen-ID; bleibt auch bei einer Setup-Obergrenze nötig, weil Lehrling-Erbe und `set_role` weitere Personen mit derselben Rolle erzeugen (RM-DR-016) |
| Wiederbelebung | Zustand und Einsätze nach `revive` laut RM-DR-011 |
| Rollenwechsel | Lehrling-Erbe, `set_role`, später Seelentauscher; frische Einsätze (RM-DR-001) |
| Save/Load | an jeder Prompt-Stufe und nach jeder Wirkung, fachlicher Hash gleich |
| Replay | gleiche Befehle, gleicher Seed → bytegleiche Ereignisse |
| SL-Korrektur | jede neue Korrekturart mit altem und neuem Wert, Abbruch offener Prompts |
| Sichtbarkeit | Actor- und Public-Leak-Tests: keine fremden Rollen, Ziele, Ursachen |
| Schutz | Wechselwirkung mit Schutzengel, Waldhexenrettung und neuen Abfangregeln |
| Todesreaktionen | Reihenfolge mit Sensenträger, Wolfskind-Verwandlung, Lehrling-Erbe |
| Siegprüfung | vorläufig nach jedem Tod, verbindlich nach allen Reaktionen (DR-14), Kandidatenmenge |
| beschädigter Spielstand | manipulierte oder widersprüchliche Rollenfelder werden beim Laden abgelehnt |

## 3. Wiederkehrende Tests je neuer Rolle

Jede neue Rolle braucht zusätzlich zu ihren eigenen Tests diese Querschnittsfälle, weil die 11 umgesetzten Rollen sie sonst ungeprüft berühren:

| Nr. | Test | Grund |
|---|---|---|
| W-1 | Lehrling erbt die Rolle (sofortige passive Wirkung, aktive ab folgender Nacht, frische Einsätze) | DR-11 und Korrekturrunde; `test_lehrling.gd` prüft jede Slice-Rolle |
| W-2 | Orakel prüft die Rolle (ermittelt, gezeigt, Erscheinung) | DR-07; zentrale Informationsregel |
| W-3 | Waldhexe rettet oder vergiftet die Rolle (Offenlegung zeigt `role_id`) | DR-06 |
| W-4 | Sensenträger verflucht die Rolle; die Rolle stirbt als Rudelopfer, durch Hinrichtung, durch Gift | Todesfolgen und Ursachen |
| W-5 | Rolle ist Vorbild eines Wolfskinds | Verwandlung vor Reaktionen |
| W-6 | Rolle nominiert den Spiegelwolf oder wird zusammen mit dem Manipulator geprüft | Hinrichtungs- und Siegregeln |
| W-7 | Nachtplan: Priorität relativ zu Wolfskind 9, Lehrling 11, Schutzengel 13, Rudel 20, Waldhexe 34, Orakel 46 | Reihenfolge nach Personen-ID bei Gleichstand |
| W-8 | Save/Load und Replay über eine vollständige Nacht mit der Rolle | Masterplan-Gate |
| W-9 | Leak-Test aller neuen Ereignisse | DECISION-LOG „Öffentliche Projektion erhält niemals geheime Daten“ |
| W-10 | Korrektur während eines offenen Prompts der Rolle | DECISION-LOG Korrekturrunde 5 |

## 4. Kombinationsmatrix konfliktträchtiger Rollen

Zeilen und Spalten sind Rollen oder Kernmechaniken. „K“ = eigener Kombinationstest nötig, mit der Frage, die er beantwortet. Leere Zellen: kein bekannter Konflikt. Grundlage sind die Wechselwirkungen in den Dossiers und die Querschnittswidersprüche in [`04`](04-rule-conflicts.md) §2.

| Kombination | Frage des Tests | Charge | Entscheidung |
|---|---|---|---|
| `schutzengel` × `dorfwache` × Rudelangriff | genau ein `KillPrevented` mit allen Quellen, keine doppelte Wirkung | K5 | RM-DR-004 |
| `schutzengel` × `seuchenwolf` / `rudelvater`-Zusatzopfer | welche Abfangregeln `pierces` durchdringt | K11 | RM-DR-005 |
| `waldhexe` × `der-weise` | Rettung und Einmalrettung auf demselben Opfer, was wird verbraucht | K8 | RM-DR-114 |
| `waldhexe` Gift × `cerberus` | wehrt Cerberus Gift ab, wird der Trank verbraucht | K4 | RM-DR-135 |
| `spiegelwolf` × `wahnsinniger-kutscher` | Reihenfolge der Hinrichtungsregeln; sterben Nachbarn des Spiegelziels oder des Kutschers | K3 | RM-DR-116 |
| `spiegelwolf` × `cerberus` / `fenrir` | Abwehr vor oder nach Spiegelung; gilt die Hinrichtung als erfolgt | K4 | RM-DR-135, RM-DR-125 |
| `manipulator` × `korrupter-richter` | Richter-Nominierung tötet den Manipulator | K14 | RM-DR-012 |
| `selbstmoerder` × `spiegelwolf` / `henker` | welche Hinrichtung gewinnt | K1/K4 | RM-DR-138 |
| `doppelspion` × `manipulator` × Parität | mehrere Einzelsiegkandidaten, Dorfkandidat unterdrückt oder nicht | K1 | RM-DR-155, RM-DR-007 |
| `siegreicher-wolf` × `lehrling` / `wolfskind` | Gewicht nach Erbe; Parität nach Verwandlung | K1 | – |
| `loki` × `sensentraeger` | Liebeskummer vor oder nach Fluch-Reaktion; Kette über zwei Reaktionen | K6 | RM-DR-009 |
| `loki` × `wolfskind` / `lehrling` | Tod durch Kette löst Verwandlung und Erbe aus | K6 | RM-DR-009 |
| `loki` × Wiederbelebung | stirbt ein wiederbelebter Liebender erneut | K6 | RM-DR-011 |
| `ritter` × `trugbilderwolf` / verwandeltes `wolfskind` | trifft die Vergeltung Wölfe nach `counts_as_wolf`, nicht nach Erscheinung | K3 | RM-DR-002 |
| `ritter` × Sitztausch | nächster Wolf nach neuer Sitzfolge | K3 | RM-DR-003 |
| `schattenhund` × `lehrling` / `wolfskind` | wird ein Auswahlschritt blockiert; bleibt er für die nächste Nacht offen | K8 | RM-DR-010, RM-DR-123 |
| `schattenhund` × `waldhexe` | blockierte Waldhexe: Trank nicht verbraucht, Rettung entfällt | K8 | RM-DR-010 |
| `albtraumwolf` × Rudelangriff auf dasselbe Ziel | Blockade rettet nicht (Legacy-Bug F3) | K8 | RM-DR-134 |
| `kopfgeldjaeger` × `trugbilderwolf` / Dämonen-Fluch | zählt Erscheinung oder Wahrheit | K7 | RM-DR-002, RM-DR-139 |
| `rattenfaenger` × Tod des letzten Unverzauberten | Sieg ohne eigene Aktion (Legacy-Bug) | K9 | RM-DR-103 |
| `waechter-am-tor` × `wolfskind` / `lehrling` / `koenig-lykaon` | jede Verwandlung in einen Wolf blockiert | K12 | RM-DR-149 |
| `seelentauscher` × `werwolf` | genau ein Wolf nach Tausch (Legacy-Bug F4) | K12 | RM-DR-127 |
| `zeitwaechter` × alle Sofort-Tode | welche Wirkungen die eingefrorene Nacht zurücknimmt | K16 | RM-DR-150 |
| `schattenwanderer` × Hinrichtung | wird eine Hinrichtung umgelenkt; zählt sie als erfolgt | K6 | RM-DR-110 |
| `voodoo-priester` × `waldhexe` Gift | Umlenkung verbraucht den Trank (Legacy verbraucht nicht) | K10 | RM-DR-132 |
| `nekromant` × `rudelvater` / `seuchenwolf` | Schild gegen durchdringende Angriffe | K15 | RM-DR-005, RM-DR-142 |

## 5. Spätere Golden-Szenarien

Nur mit deterministischem, `legacy-verified` oder ausdrücklich entschiedenem Verhalten. Format: `godot/tests/scenarios/*.json` (README „Szenarioformat“).

| ID | Szenario | Rollen | Voraussetzung |
|---|---|---|---|
| G-RM-01 | Siegreicher Wolf entscheidet die Parität einen Tag früher | `siegreicher-wolf`, `werwolf`, `dorfbewohner` | K1 |
| G-RM-02 | Doppelspion überlebt den letzten Wolf | `doppelspion`, `werwolf`, `dorfbewohner`, `sensentraeger` | K1, RM-DR-155 |
| G-RM-03 | Selbstmörder wird nach fünf Toten hingerichtet | `selbstmoerder`, `werwolf`, `waldhexe` | K1, RM-DR-138 |
| G-RM-04 | Informationsnacht mit Orakel, Waldläufer, Doktor | K2-Rollen, `trugbilderwolf` | K2 |
| G-RM-05 | Wahnsinniger Kutscher nach Sitztausch | `wahnsinniger-kutscher`, `spiegelwolf` | K3, RM-DR-003 |
| G-RM-06 | Ritter-Vergeltung am Morgen | `ritter`, `werwolf`, `siegreicher-wolf` | K3 |
| G-RM-07 | Liebespaar mit Sensenträger-Kette | `loki`, `sensentraeger` | K6 |
| G-RM-08 | Schattenhund blockiert Schutzengel, Rudel trifft | `schattenhund`, `schutzengel` | K8 |
| G-RM-09 | Vollständige Option-B-Runde bis Sieg | alle 25 | Option B |
| G-RM-10 | Akt-I-Runde (Option C) | 15 Akt-I-Rollen | Option C |

## 6. Testgruppen je Rolle

Legende: ● = relevant, konkreter Testfall im Dossier („Relevante Testgruppen“); – = ausdrücklich nicht relevant, Begründung im Dossier. Für die 11 umgesetzten Rollen: ✓ = durch vorhandene Tests abgedeckt laut [`02`](02-implemented-roles-audit.md).

Spaltenkürzel: Norm = Normalfall, Ziel = ungültiges Ziel, tot = tote Person, selbst = Selbstwahl, Kopien = mehrere Kopien, Wiederb. = Wiederbelebung, Wechsel = Rollenwechsel, S/L = Save/Load, Replay = Replay, Korr. = SL-Korrektur, Sicht = Sichtbarkeit, Schutz = Schutz, Reakt. = Todesreaktionen, Sieg = Siegprüfung, beschäd. = beschädigter Spielstand.

| ID | Charge | Norm | Ziel | tot | selbst | Kopien | Wiederb. | Wechsel | S/L | Replay | Korr. | Sicht | Schutz | Reakt. | Sieg | beschäd. | Fälle |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `loki` | K6 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-1.md#loki) |
| `nachtwaechter` | K3 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-1.md#nachtwaechter) |
| `die-gebundenen` | K2 | ● | – | ● | – | ● | – | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-1.md#die-gebundenen) |
| `rattenfaenger` | K9 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/solos-a.md#rattenfaenger) |
| `die-ewigen` | K9 | ● | ● | ● | ● | – | – | ● | ● | ● | ● | ● | – | – | ● | ● | [Dossier](dossiers/village-1.md#die-ewigen) |
| `spuerhund` | K7 | ● | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-1.md#spuerhund) |
| `rachsuechtiger-wolf` | K11 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-a.md#rachsuechtiger-wolf) |
| `koenig-lykaon` | K12 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | – | ● | ● | [Dossier](dossiers/wolves-a.md#koenig-lykaon) |
| `siegreicher-wolf` | K1 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | – | – | – | ● | – | [Dossier](dossiers/wolves-a.md#siegreicher-wolf) |
| `seuchenwolf` | K11 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | – | – | ● | [Dossier](dossiers/wolves-a.md#seuchenwolf) |
| `schicksalswolf` | K11 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-a.md#schicksalswolf) |
| `schattenwanderer` | K6 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-a.md#schattenwanderer) |
| `giftwolf` | K11 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-a.md#giftwolf) |
| `rudelvater` | K11 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-a.md#rudelvater) |
| `schwarze-witwe` | K6 | ● | ● | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-b.md#schwarze-witwe) |
| `der-weise` | K8 | ● | – | – | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-1.md#der-weise) |
| `verdammniswaechter` | K11 | ● | ● | ● | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-1.md#verdammniswaechter) |
| `wahnsinniger-kutscher` | K3 | ● | – | ● | – | – | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-1.md#wahnsinniger-kutscher) |
| `korrupter-richter` | K14 | ● | ● | ● | ● | ● | – | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/village-2.md#korrupter-richter) |
| `maertyrerin` | K5 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-2.md#maertyrerin) |
| `dorfwache` | K5 | ● | – | ● | – | ● | ● | ● | – | ● | ● | ● | ● | – | ● | – | [Dossier](dossiers/village-2.md#dorfwache) |
| `pestbringerin` | K9 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | – | ● | ● | [Dossier](dossiers/solos-a.md#pestbringerin) |
| `prophet-des-untergangs` | K9 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-a.md#prophet-des-untergangs) |
| `daemonischer-wolf` | K12 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-b.md#daemonischer-wolf) |
| `schattenhund` | K8 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | ● | [Dossier](dossiers/wolves-b.md#schattenhund) |
| `besessener-wolf` | K4 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-b.md#besessener-wolf) |
| `fenrir` | K4 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-b.md#fenrir) |
| `kutscher` | K13 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/village-2.md#kutscher) |
| `seelentauscher` | K12 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/village-2.md#seelentauscher) |
| `blutpriester` | K7 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-2.md#blutpriester) |
| `traumdeuter` | K7 | ● | – | ● | ● | ● | – | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-2.md#traumdeuter) |
| `henker` | K4 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-2.md#henker) |
| `feuerteufel` | K9 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-a.md#feuerteufel) |
| `voodoo-priester` | K10 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-a.md#voodoo-priester) |
| `blutwolf` | K14 | ● | – | ● | – | ● | ● | ● | – | – | ● | ● | – | – | – | ● | [Dossier](dossiers/wolves-b.md#blutwolf) |
| `albtraumwolf` | K8 | ● | ● | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | – | ● | [Dossier](dossiers/wolves-b.md#albtraumwolf) |
| `cerberus` | K4 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/wolves-b.md#cerberus) |
| `ritter` | K3 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-3.md#ritter) |
| `rotkaeppchen` | K10 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-3.md#rotkaeppchen) |
| `selbstmoerder` | K1 | ● | ● | – | – | ● | ● | ● | – | ● | ● | ● | – | ● | ● | – | [Dossier](dossiers/solos-a.md#selbstmoerder) |
| `kopfgeldjaeger` | K7 | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | – | ● | ● | [Dossier](dossiers/village-3.md#kopfgeldjaeger) |
| `koenig` | K7 | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-3.md#koenig) |
| `dr-victor-frankenstein` | K13 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/village-3.md#dr-victor-frankenstein) |
| `nekromant` | K15 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-b.md#nekromant) |
| `kartenschlucker` | K15 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-b.md#kartenschlucker) |
| `hades` | K15 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-b.md#hades) |
| `doktor` | K2 | ● | ● | ● | ● | ● | – | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-3.md#doktor) |
| `faehrtenleser` | K3 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-3.md#faehrtenleser) |
| `waldlaeufer` | K2 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | – | – | – | – | [Dossier](dossiers/village-3.md#waldlaeufer) |
| `schutzgeist` | K5 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | – | ● | [Dossier](dossiers/village-4.md#schutzgeist) |
| `dorfchronistin` | K2 | ● | – | ● | – | ● | – | ● | ● | ● | ● | ● | – | – | – | ● | [Dossier](dossiers/village-4.md#dorfchronistin) |
| `waechter-am-tor` | K12 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/village-4.md#waechter-am-tor) |
| `zeitwaechter` | K16 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-4.md#zeitwaechter) |
| `amalia` | K14 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-4.md#amalia) |
| `kriegerin-des-lichts` | K7 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-4.md#kriegerin-des-lichts) |
| `detektiv` | K3 | ● | – | ● | – | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/village-4.md#detektiv) |
| `dorfschmied` | K5 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/village-4.md#dorfschmied) |
| `doppelspion` | K1 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | – | ● | ● | ● | [Dossier](dossiers/solos-a.md#doppelspion) |
| `grabraeuber` | K15 | ● | ● | ● | – | ● | ● | – | ● | ● | ● | ● | – | – | ● | ● | [Dossier](dossiers/solos-b.md#grabraeuber) |
| `parasit` | K10 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-b.md#parasit) |
| `todesprediger` | K15 | ● | ● | ● | – | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | [Dossier](dossiers/solos-b.md#todesprediger) |

Summe: 784 relevante und 131 ausdrücklich nicht relevante Testgruppen über 61 Rollen. Die Gruppe „mehrere Kopien“ bleibt auch bei einer Setup-Obergrenze nötig, weil Lehrling-Erbe und Spielleiterkorrekturen mehrere Personen mit derselben Rolle erzeugen können (RM-DR-016, korrigiert am 2026-09-27).

## 7. Umgesetzte Rollen

Die 11 umgesetzten Rollen sind durch vorhandene Tests abgedeckt ([`02`](02-implemented-roles-audit.md) §3). Offen sind für alle: Undo/Redo-Tests (erst mit B-12), Checkpoint-Tests auf Datenträger (B-13), Projektionstests (B-18) und Gerätetests. Mit jeder neuen Charge kommen für sie die wiederkehrenden Fälle W-1 bis W-6 aus §3 hinzu.

## 8. Aussagekraft bestehender Prüfungen

`npm test` (`tests/smoke.js`) prüft nur Textvorkommen, `tools/compare-i18n.js` nur Schlüsselgleichheit im Legacy-i18n. Beide sagen nichts über Rollenverhalten. Belastbar sind nur die headless Godot-Tests. Die Konsistenzprüfung `tools/role-migration/check-role-docs.js` prüft ausschließlich diese Dokumente.
