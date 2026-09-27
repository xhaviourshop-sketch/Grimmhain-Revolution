# 03 · Analyse der 61 fehlenden Rollen

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse, keine Regel entschieden

Dieses Dokument fasst je fehlender Rolle die belegten Kernaussagen zusammen. Die vollständige Detailanalyse mit Quelltextstellen, wörtlichen Texten, Schritt-für-Schritt-Legacy-Verhalten, React-Befund, Prüfung der bisherigen Dokumentation, Bugs und Testfällen steht im verlinkten **Belegdossier** (Abschnitt mit der Rollen-ID). Widersprüche tragen IDs `RM-C-###` ([`04`](04-rule-conflicts.md)), Entscheidungen `RM-DR-###` ([`08`](08-decision-request.md)).

Unterschieden wird wie im Auftrag gefordert: **Rollentext behauptet** (Dossier „Text DE/EN“), **Legacy-Code tut** (Dossier „Legacy-Codeverhalten“), **React-Version tut** (Dossier „React-Version“; für keine der 61 Rollen eigenes Regelverhalten), **Dokumentation empfiehlt** (Dossier „Bisherige Doku“), **neuer Godot-Kern tut** (für alle 61: nichts, keine Rolle ist im RoleCatalog), **noch unentschieden** (Entscheidungen unten).

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist umgesetzt (später weitere Rollen, siehe `11`); sein Abschnitt steht jetzt in [`02`](02-implemented-roles-audit.md) §4.12, der aktuelle Prüfstatus aller Rollen in [`11-role-audit-status.md`](11-role-audit-status.md). Diese Datei behandelt damit 60 fehlende Rollen.

**Lesehilfe:** In übernommenen Zellen bezeichnen `01` bis `07` ohne Pfad die älteren Dokumente unter `docs/godot-migration/`; Pfadkürzel wie in [`04`](04-rule-conflicts.md) §3.

**Konsolidierung 2026-09-27:** Der Status jeder Entscheidung steht in [`08`](08-decision-request.md) und [`decision-status.csv`](decision-status.csv); die Spalten „Charge“ und „1.0“ sind Planung, keine Freigabe.

## 1. Übersicht

| ID | Fraktion | Godot | Legacy | Auto | Mechanik (primär) | sekundär | Größe / Risiko | Charge | 1.0 |
|---|---|---|---|---|---|---|---|---|---|
| [`loki`](#loki) | Dorf | `decision-required` | `legacy-contradictory` | `automatic` | Verknüpfte Personen | Einmalfähigkeit, Todesreaktion | M / mittel | K6 | B |
| [`rattenfaenger`](#rattenfaenger) | Einzelsieg | `decision-required` | `legacy-broken` | `automatic` | Einzelsieg | mehrstufige Nachtfähigkeit | M / mittel | K9 | B |
| [`die-ewigen`](#die-ewigen) | Dorf | `decision-required` | `not-found` | `assisted` | Informationsrolle | Einzelsieg | M / mittel | K9 | – |
| [`spuerhund`](#spuerhund) | Dorf | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | Fehlinformation, Zufallsmechanik | M / mittel | K7 | – |
| [`rachsuechtiger-wolf`](#rachsuechtiger-wolf) | Wölfe | `decision-required` | `legacy-contradictory` | `assisted` | Tötung | Einzelsieg, Wolfsangriff-Modifikation | M / hoch | K11 | – |
| [`koenig-lykaon`](#koenig-lykaon) | Wölfe | `decision-required` | `legacy-verified` | `automatic` | Rollenwechsel | Fraktionswechsel, Einmalfähigkeit, mehrstufige Nachtfähigkeit | M / mittel | K12 | C |
| [`seuchenwolf`](#seuchenwolf) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Wolfsangriff-Modifikation | Todesreaktion, globale Regeländerung | M / mittel | K11 | – |
| [`schicksalswolf`](#schicksalswolf) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Tötung | mehrstufige Nachtfähigkeit, Einmalfähigkeit | M / mittel | K11 | – |
| [`schattenwanderer`](#schattenwanderer) | Wölfe | `decision-required` | `legacy-verified` | `automatic` | Verknüpfte Personen | Zielumleitung, Einmalfähigkeit | M / hoch | K6 | – |
| [`giftwolf`](#giftwolf) | Wölfe | `decision-required` | `legacy-verified` | `automatic` | Tötung | Einmalfähigkeit, sonstige Spezialmechanik | M / mittel | K11 | – |
| [`rudelvater`](#rudelvater) | Wölfe | `decision-required` | `legacy-verified` | `automatic` | Wolfsangriff-Modifikation | Hinrichtungsreaktion, Schutz, Einmalfähigkeit | M / mittel | K11 | – |
| [`schwarze-witwe`](#schwarze-witwe) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Verknüpfte Personen | Tötung | M / mittel | K6 | – |
| [`der-weise`](#der-weise) | Dorf | `decision-required` | `legacy-broken` | `automatic` | Wolfsangriff-Modifikation | Hinrichtungsreaktion, globale Regeländerung | M / hoch | K8 | C |
| [`verdammniswaechter`](#verdammniswaechter) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | Zielumleitung | Tötung, Zufallsmechanik | M / hoch | K11 | – |
| [`maertyrerin`](#maertyrerin) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | Schutz | Einmalfähigkeit | M / mittel | K5 | – |
| [`pestbringerin`](#pestbringerin) | Einzelsieg | `decision-required` | `legacy-contradictory` | `automatic` | Einzelsieg | Sitzpositionsmechanik, Zufallsmechanik | M / mittel | K9 | – |
| [`prophet-des-untergangs`](#prophet-des-untergangs) | Einzelsieg | `decision-required` | `not-found` | `assisted` | Tötung | Einzelsieg, Einmalfähigkeit | M / mittel | K9 | – |
| [`daemonischer-wolf`](#daemonischer-wolf) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Todesreaktion | Fehlinformation, Fraktionswechsel | M / hoch | K12 | – |
| [`schattenhund`](#schattenhund) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | globale Regeländerung | Einmalfähigkeit | S / mittel | K8 | B |
| [`fenrir`](#fenrir) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Hinrichtungsreaktion | sonstige Spezialmechanik, Einmalfähigkeit | M / mittel | K4 | – |
| [`kutscher`](#kutscher) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | Wiederbelebung | Rollenwechsel, Zufallsmechanik | L / hoch | K13 | – |
| [`seelentauscher`](#seelentauscher) | Dorf | `decision-required` | `legacy-broken` | `assisted` | Rollenwechsel | Einmalfähigkeit, Fraktionswechsel | L / kritisch | K12 | – |
| [`blutpriester`](#blutpriester) | Dorf | `decision-required` | `legacy-verified` | `assisted` | Informationsrolle | Tötung, Einmalfähigkeit, Zufallsmechanik | M / mittel | K7 | – |
| [`traumdeuter`](#traumdeuter) | Dorf | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | Zufallsmechanik | S / niedrig | K7 | – |
| [`henker`](#henker) | Dorf | `decision-required` | `legacy-verified` | `automatic` | Hinrichtungsreaktion | Tötung | M / mittel | K4 | – |
| [`feuerteufel`](#feuerteufel) | Einzelsieg | `decision-required` | `legacy-broken` | `automatic` | Todesreaktion | Sitzpositionsmechanik, Hinrichtungsreaktion | M / hoch | K9 | – |
| [`voodoo-priester`](#voodoo-priester) | Einzelsieg | `decision-required` | `legacy-contradictory` | `automatic` | Zielumleitung | Verknüpfte Personen, Hinrichtungsreaktion | L / hoch | K10 | – |
| [`albtraumwolf`](#albtraumwolf) | Wölfe | `decision-required` | `legacy-broken` | `automatic` | sonstige Spezialmechanik | globale Regeländerung | S / mittel | K8 | – |
| [`cerberus`](#cerberus) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Hinrichtungsreaktion | sonstige Spezialmechanik | S / mittel | K4 | B |
| [`rotkaeppchen`](#rotkaeppchen) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | Verknüpfte Personen | Todesreaktion, mehrstufige Nachtfähigkeit, sonstige Spezialmechanik | L / hoch | K10 | – |
| [`kopfgeldjaeger`](#kopfgeldjaeger) | Dorf | `decision-required` | `legacy-verified` | `automatic` | Informationsrolle | Hinrichtungsreaktion, Zufallsmechanik | M / mittel | K7 | B |
| [`koenig`](#koenig) | Dorf | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | Zufallsmechanik | S / mittel | K7 | – |
| [`dr-victor-frankenstein`](#dr-victor-frankenstein) | Dorf | `decision-required` | `legacy-broken` | `assisted` | Wiederbelebung | Rollenwechsel, Einmalfähigkeit, mehrstufige Nachtfähigkeit, Totenkarten-Interaktion | L / hoch | K13 | – |
| [`nekromant`](#nekromant) | Einzelsieg | `decision-required` | `legacy-contradictory` | `assisted` | Schutz | Zielumleitung, Einzelsieg, Tagfähigkeit | L / hoch | K15 | – |
| [`kartenschlucker`](#kartenschlucker) | Einzelsieg | `decision-required` | `legacy-contradictory` | `assisted` | Totenkarten-Interaktion | Einzelsieg, Tötung, Schutz | L / hoch | K15 | – |
| [`hades`](#hades) | Einzelsieg | `decision-required` | `legacy-verified` | `assisted` | Einzelsieg | Tötung, Schutz, sonstige Spezialmechanik | M / mittel | K15 | – |
| [`schutzgeist`](#schutzgeist) | Dorf | `decision-required` | `legacy-broken` | `automatic` | Schutz | Todesreaktion, Informationsrolle | M / mittel | K5 | – |
| [`zeitwaechter`](#zeitwaechter) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | globale Regeländerung | Einmalfähigkeit | XL / kritisch | K16 | – |
| [`amalia`](#amalia) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | Informationsrolle | Einmalfähigkeit, Tagfähigkeit | M / mittel | K14 | – |
| [`kriegerin-des-lichts`](#kriegerin-des-lichts) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | Informationsrolle | Einmalfähigkeit, Tötung | S / mittel | K7 | – |
| [`detektiv`](#detektiv) | Dorf | `decision-required` | `legacy-broken` | `automatic` | Informationsrolle | Todesreaktion, Sitzpositionsmechanik, Zufallsmechanik | M / hoch | K3 | – |
| [`dorfschmied`](#dorfschmied) | Dorf | `decision-required` | `legacy-verified` | `automatic` | Wolfsangriff-Modifikation | Schutz, Tötung, Zufallsmechanik | M / mittel | K5 | – |
| [`grabraeuber`](#grabraeuber) | Einzelsieg | `decision-required` | `not-found` | `manual-only` | Einmalfähigkeit | Einzelsieg, sonstige Spezialmechanik | XL / hoch | K15 | – |
| [`parasit`](#parasit) | Einzelsieg | `decision-required` | `legacy-verified` | `automatic` | Verknüpfte Personen | Schutz, Todesreaktion, Einzelsieg | M / mittel | K10 | C |
| [`todesprediger`](#todesprediger) | Einzelsieg | `decision-required` | `legacy-broken` | `automatic` | Einzelsieg | Einmalfähigkeit | M / mittel | K15 | – |

**Mechanikfamilien:** Jede Rolle hat genau eine primäre Familie, nach der sie einer Charge zugeordnet ist. Wo die technische Charge von der primären Familie abweicht (z. B. `detektiv`: Informationsrolle, aber Charge Sitznachbarschaft), bestimmt die überwiegend neu zu bauende Kernfunktion die Charge.

**Automation:** Der Wert ist das Ziel nach Klärung der Entscheidungen. `assisted` heißt: App führt, rechnet und protokolliert, eine Spielleitereingabe bleibt Teil der Regel (z. B. Tischfrage, freie Zahl). `manual-only` heißt: bis zur Regelfestlegung nur Notiz und Hinweis.

## 2. Rollen im Einzelnen

### `loki`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Loki / Loki |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / I, II, III, IV / 0.1 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Liebeskette funktioniert wie beschrieben; die Rivalen-Option verspricht einen Fluch ohne eigene Wirkung (Text/Code-Lücke, kein Defekt). |
| DE/EN-Vergleich | JA. "einmalig" = "Once per game"; Ziele je zwei; Rivalen als Fluch in beiden. EN lässt nur den Flavor-Satz "Eros und Eris leihen dir ihre Kraft" weg. |
| Automationsziel | `automatic`: Wahl wird vom SL eingegeben, Bindung und Liebeskummer-Kette sind deterministisch. |
| Mechanik | primär: Verknüpfte Personen; sekundär: Einmalfähigkeit, Todesreaktion |
| Größe / Risiko | M / mittel. Kettenfixpunkt und Wiederbelebung sind die Fehlerquellen. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (Modus + 2 Ziele, abbrechbar), KillPipeline (Folgetod als Kette), Reaktionswarteschlange, Ereignis-Sichtbarkeit (gm), StateCodec, Replay, GmCorrections. |
| Neue Systeme | Liebes-/Bindungsmodell (Paar-Bindung mit Typ love/rival, analog WolfChildBond/ApprenticeBond, inkl. Verhalten bei Wiederbelebung); dauerhafte Statusmarker für Rivalen. |
| Abhängigkeiten | Schwarze Witwe (Pflichtpaar, liest Bindung), Dr. Victor Frankenstein/Kutscher (Wiederbelebung), Lehrling (Erbe), Nekromant/Kartenschlucker/Hades (Schilde in `applyKill`). |
| Widersprüche | RM-C-082 Rivalen-Wirkung; RM-C-083 Nacht-1 vs. einmal |
| Entscheidungen | RM-DR-101 (Rolle); übergreifend RM-DR-009, RM-DR-011, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K6 / ab Option B |
| Belegsicherheit | hoch für Code; nicht im Browser verifiziert, ob React-Overlay-Spiegelung den Dialog vollständig bedient. |
| Detail | [Dossier](dossiers/village-1.md#loki) |

### `rattenfaenger`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Rattenfänger / Pied Piper |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / I / 4.2 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Die Siegbedingung („Sobald ...") ist die Kernfunktion und wird bei Toden belegbar nicht ausgewertet (Bug 1). |
| DE/EN-Vergleich | NEIN. EN nennt keine Anzahl (DE: 1 oder 2), EN „Wins when" ohne „Sobald"-Betonung (gleichwertig), beide sagen „alle lebenden Spieler" (wörtlich inklusive des Rattenfängers selbst; Code schließt ihn aus). |
| Automationsziel | `automatic`: Regeln sind klar, Ziele deterministisch, Sieg als WinCandidate. |
| Mechanik | primär: Einzelsieg; sekundär: mehrstufige Nachtfähigkeit |
| Größe / Risiko | M / mittel. Einfacher Marker, aber Siegzeitpunkt und Konkurrenz mit Parität. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (mehrstufig, abbrechbar), WinRules/WinCandidate, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit (gm). |
| Neue Systeme | dauerhafte Statusmarker (Verzauberung), zusätzliche Siegbedingungen (Rattenfänger-Kandidat). |
| Abhängigkeiten | Voodoo-Priester (hebt Verzauberung auf), Lehrling/Seelentauscher (Rollenwechsel), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (Doppelaktion), Die Ewigen (Solo-Erkennung), Wölfe/Dorf (konkurrierender Sieg). |
| Widersprüche | RM-C-040 Siegzeitpunkt; RM-C-041 Zählt er selbst; RM-C-042 Anzahl pro Nacht; RM-C-043 Verzauberung durch Puppe aufgehoben |
| Entscheidungen | RM-DR-103 (Rolle); übergreifend RM-DR-007; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K9 / ab Option B |
| Belegsicherheit | hoch. Nicht zur Laufzeit getestet; alle Aussagen aus Code-Lektüre. |
| Detail | [Dossier](dossiers/solos-a.md#rattenfaenger) |

### `die-ewigen`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Die Ewigen / The Eternal Ones |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 4.8 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `not-found`. Die Prüfung existiert, aber die definierende Mechanik "gewinnen gemeinsam" existiert im Code nicht. |
| DE/EN-Vergleich | JA. Häufigkeit (jede Nacht), Ziel (ein Spieler), Mitsieg in beiden. |
| Automationsziel | `assisted`: Info automatisch; Mitsieg erst nach PO-Regel, bis dahin SL bestätigt. |
| Mechanik | primär: Informationsrolle; sekundär: Einzelsieg |
| Größe / Risiko | M / mittel. Info trivial, Mitsieg berührt WinRules. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt, InfoRecord, WinRules/WinCandidate, Ereignis-Sichtbarkeit, StateCodec, Replay. |
| Neue Systeme | zusätzliche Siegbedingungen (Mitsieg-Kandidaten); Besuchs-/Zielhistorie (welche Solos wurden gefunden), falls der Mitsieg an einen gefundenen Solo gebunden wird. |
| Abhängigkeiten | alle 14 Solo-Rollen (`roles:399-403`), insbesondere solche ohne Siegcode (Prophet, Feuerteufel, Voodoo, Grabräuber: 07 Q4); Lehrling/Seelentauscher (Solo-Rolle wechselt Person). |
| Widersprüche | RM-C-087 Mitsieg; RM-C-088 Info-Umfang; RM-C-089 Siegseite der Ewigen |
| Entscheidungen | RM-DR-104 (Rolle); übergreifend RM-DR-002, RM-DR-006; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K9 / in keiner Option |
| Belegsicherheit | hoch für Code; Mitsieg-Regel nicht bestimmbar. |
| Detail | [Dossier](dossiers/village-1.md#die-ewigen) |

### `spuerhund`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Spürhund / Scent Hound |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / I / 6.8 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Normalfall setzt den Text um; die Wolf-Definition weicht vom autoritativen `isWolf` ab und die Markierungsregel ist offen (DE/EN verschieden). |
| DE/EN-Vergleich | NEIN (gering). EN sagt "a random player", DE nur "ein Spieler" (Auswahlverfahren offen, z.B. SL-Wahl). Sonst gleich (3 Ziele, Kriterien, geheim). |
| Automationsziel | `automatic`: (mit SeededRng). |
| Mechanik | primär: Informationsrolle; sekundär: Fehlinformation, Zufallsmechanik |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (3 Ziele), SeededRng, InfoRecord, appears_as (falls Erscheinung zählen soll), StateCodec, Replay. |
| Neue Systeme | dauerhafte Statusmarker (falsche Spur, pro Person, Quelle Spürhund). |
| Abhängigkeiten | Wolfskind, Dämonischer Wolf (Fluch), Trugbilderwolf (Wolfsrolle), alle Solos, Lehrling/Seelentauscher (Rollenname wechselt). |
| Widersprüche | RM-C-090 Wer wird falsche Spur; RM-C-091 Was ist "Wolf" |
| Entscheidungen | RM-DR-105 (Rolle); übergreifend RM-DR-002, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K7 / in keiner Option |
| Belegsicherheit | hoch für Handler; Anzeige der Markierung im Pixi-Feld nicht verifiziert. |
| Detail | [Dossier](dossiers/village-1.md#spuerhund) |

### `rachsuechtiger-wolf`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Rachsüchtiger Wolf / Lone Wolf |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / I, II, III, IV / 2.2 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Mechanik (Zusatzkill mit Abklingzeit) funktioniert, aber Siegziel des Textes fehlt im Code, EN-Text lässt es weg, Rhythmus weicht ab. |
| DE/EN-Vergleich | NEIN. EN fehlt der Satz "Du willst alleine gewinnen" (Siegziel fehlt komplett). Rest (jede dritte Nacht, anderer Werwolf, zusätzlich) gleich. |
| Automationsziel | `assisted`: Schritt, Zielfilter und Zähler sind automatisierbar; Sieglogik hängt an PO-Entscheidung. |
| Mechanik | primär: Tötung; sekundär: Einzelsieg, Wolfsangriff-Modifikation |
| Größe / Risiko | M / hoch |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (Ja/Nein + Ziel, abbrechbar), KillPipeline (NIGHT_KILL-artige Ursache mit eigener Quelle), Protections (ob Schutzengel greift: festlegen), WinRules/WinCandidate, Ereignis-Sichtbarkeit. |
| Neue Systeme | Abklingzeit-Zähler pro Person (Einsatzhistorie mit Nachtnummer); zusätzliche Siegbedingung (Einzelsieg eines Wolfsfraktionsmitglieds), falls Text gilt. |
| Abhängigkeiten | Werwolf (Rudel, synthetische Zeile), Doppelspion (Zielausschluss, Textbezug), Dämonischer Wolf (verfluchte Ziele), Schutzengel/Dorfwache, Seuchenwolf, Waldhexe, Verdammniswächter, Die Ewigen, Nachtwächter (Wolf-Erkennung). |
| Widersprüche | RM-C-001 Siegziel; RM-C-002 Rhythmus; RM-C-003 Zeitpunkt der ersten Nutzung |
| Entscheidungen | RM-DR-106 (Rolle); übergreifend RM-DR-002, RM-DR-004, RM-DR-006; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K11 / in keiner Option |
| Belegsicherheit | hoch für Code; nicht im Browser ausgeführt. |
| Detail | [Dossier](dossiers/wolves-a.md#rachsuechtiger-wolf) |

### `koenig-lykaon`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | König Lykaon / King Lycaon |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / I / 2.4 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Der Code setzt Zeitpunkt, Verbündeten-Gate und Verwandlung nachvollziehbar um; Lücken betreffen nicht beschriebene Details (Scheinrolle, Solo-Ziele). |
| DE/EN-Vergleich | JA, semantisch gleich (Zeitpunkt erste Nacht, 1 Verbündeter, 1 Dorfbewohner, Ergebnis Trugbilderwolf/Decoy Wolf). |
| Automationsziel | `automatic`: (mit PendingPrompt zweistufig), Scheinrolle assisted durch SL-Bestätigung. |
| Mechanik | primär: Rollenwechsel; sekundär: Fraktionswechsel, Einmalfähigkeit, mehrstufige Nachtfähigkeit |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (mehrstufig, abbrechbar), RoleTransition (mit Schnappschuss), appears_as, InfoRecord (Orakel), GmCorrections, WinRules. |
| Neue Systeme | Wächter-am-Tor-Blockade als zentrale Regel in RoleTransition (für alle Verwandlungswege); optional "Scheinschritt" (Tarnzeile für verschwundene Rolle) in der Nachtplanung. |
| Abhängigkeiten | Trugbilderwolf, Wächter am Tor, Orakel, Lehrling (Erbe), Werwolf (synthetische Rudelzeile), Totenkarte wende_11. |
| Widersprüche | RM-C-004 Scheinrolle des erzeugten Trugbilderwolfs; RM-C-005 "Dorfbewohner" |
| Entscheidungen | RM-DR-107 (Rolle); übergreifend RM-DR-002, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K12 / ab Option C |
| Belegsicherheit | hoch; nicht verifiziert: Laufzeitverhalten der hartkodierten Prompts in EN. |
| Detail | [Dossier](dossiers/wolves-a.md#koenig-lykaon) |

### `seuchenwolf`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Seuchenwolf / Blight Wolf |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / IV / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Kernidee funktioniert, aber der Umfang ("alle Schutzeffekte") und der Verbrauch weichen vom Text ab, und der Code behandelt zwei "ignoriert Schutz"-Regeln (Seuchenwolf, Rudelvater) unterschiedlich. |
| DE/EN-Vergleich | JA, semantisch gleich. |
| Automationsziel | `automatic`: (nach Festlegung der Liste). |
| Mechanik | primär: Wolfsangriff-Modifikation; sekundär: Todesreaktion, globale Regeländerung |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | KillPipeline (Abfangstufe mit Filter), Protections (derzeit nur Schutzengel gegen Rudel-NIGHT_KILL), Reaktionswarteschlange nicht nötig (passiver Effekt). |
| Neue Systeme | globaler Modifikator "nächster Rudelangriff durchdringt" (persistiert, mit Verbrauchsregel); Attribut `pierces` pro Angriff. |
| Abhängigkeiten | Werwolf, Schutzengel, Schutzgeist, Dorfwache, Der Weise, Waldhexe, Nekromant, Kartenschlucker, Hades, Dorfschmied, Märtyrerin, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (gemeinsames Durchdringungskonzept). |
| Widersprüche | RM-C-006 Umfang "alle Schutzeffekte"; RM-C-007 Verbrauch; RM-C-008 Welche Angriffe |
| Entscheidungen | RM-DR-108 (Rolle); übergreifend RM-DR-004, RM-DR-005, RM-DR-009, RM-DR-011; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K11 / in keiner Option |
| Belegsicherheit | hoch. |
| Detail | [Dossier](dossiers/wolves-a.md#seuchenwolf) |

### `schicksalswolf`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Schicksalswolf / Fate Wolf |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / IV / 2.5 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. "in Nacht 4" vs. "ab Nacht 4"; Schutzbehandlung nicht wie Wolfsangriff |
| DE/EN-Vergleich | NEIN (gering). EN "a kill ability" lässt "zusätzlichen" (additional zum Rudelopfer) weg; Zählung pro Markiertem und Zeitpunkt Nacht 4 gleich. |
| Automationsziel | `automatic`: (Markieren, Zählen, Bonus-Schritt), mit SL-Korrektur. |
| Mechanik | primär: Tötung; sekundär: mehrstufige Nachtfähigkeit, Einmalfähigkeit |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue (bedingter Schritt nach Nachtnummer), PendingPrompt (Mehrfachwahl), KillPipeline, Protections, GmCorrections, StateCodec. |
| Neue Systeme | dauerhafte Statusmarker (Markierungen, nur SL sichtbar); Todesreihenfolge-Historie (erste drei Tote, persistiert); Zusatzopfer-Liste für die Morgenauflösung. |
| Abhängigkeiten | Werwolf (Rudelopfer, Deduplizierung), Schutzengel, Dorfwache, Der Weise, Märtyrerin, Zeitwächter (eingefrorene Nacht zählt nicht, `night:323-331` erhöht `nightCount` nicht), Frankenstein/Kutscher (Wiederbelebung), Seuchenwolf (NIGHT_KILL verbraucht Durchdringung). |
| Widersprüche | RM-C-009 Zeitfenster; RM-C-010 Schutz gegen Zusatzopfer; RM-C-011 Zählung der ersten drei Toten |
| Entscheidungen | RM-DR-109 (Rolle); übergreifend RM-DR-004, RM-DR-005, RM-DR-011, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K11 / in keiner Option |
| Belegsicherheit | hoch; nicht verifiziert: Laufzeit der `startMulti`-Abbruchpfade. |
| Detail | [Dossier](dossiers/wolves-a.md#schicksalswolf) |

### `schattenwanderer`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Schattenwanderer / Shadowwalker |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / II / 2.6 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Kernumlenkung entspricht dem Text innerhalb einer Partie; der Rundenwechsel-Bug liegt außerhalb der Partie |
| DE/EN-Vergleich | JA, semantisch gleich. |
| Automationsziel | `automatic` |
| Mechanik | primär: Verknüpfte Personen; sekundär: Zielumleitung, Einmalfähigkeit |
| Größe / Risiko | M / hoch |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt, KillPipeline (Umlenkungsstufe vor Schilden), Ereignis-Sichtbarkeit, StateCodec, GmCorrections. |
| Neue Systeme | Bindungsmodell (Paar mit Richtung, Aktivstatus, Partie-gebunden); Umlenkungsregel mit eigener Ursache/Quelle. |
| Abhängigkeiten | Rudelvater (Reihenfolge), Parasit, Nekromant/Kartenschlucker/Hades (Schilde beim Partner), Werwolf, Lynch/ExecutionRules, Frankenstein/Kutscher (Wiederbelebung), Dämonischer Wolf, Kopfgeldjäger, Henker. |
| Widersprüche | keine belegten Text-/Code-Widersprüche |
| Entscheidungen | RM-DR-110 (Rolle); übergreifend RM-DR-009, RM-DR-011, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K6 / in keiner Option |
| Belegsicherheit | hoch. |
| Detail | [Dossier](dossiers/wolves-a.md#schattenwanderer) |

### `giftwolf`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Giftwolf / Poison Wolf |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / II / 2.7 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Text wird umgesetzt; offene Punkte sind Regelpräzisierungen, die Bugs betreffen den Rundenwechsel |
| DE/EN-Vergleich | JA, semantisch gleich. |
| Automationsziel | `automatic`: für Termin und Tod; assisted für "Ziel erfährt davon" (Actor-Information). |
| Mechanik | primär: Tötung; sekundär: Einmalfähigkeit, sonstige Spezialmechanik |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt, KillPipeline (Ursache mit Attribut wolf_ability, dawn), Ereignis-Sichtbarkeit (actor-Ereignis an Ziel), InfoRecord, StateCodec, Reaktionswarteschlange (Folgen am Morgen). |
| Neue Systeme | zeitlich verzögerte Effekte (Termin an Tages-/Morgenzähler, persistiert, partiegebunden); dauerhafte Statusmarker (vergiftet); Ladungszähler pro Person. |
| Abhängigkeiten | Rudelvater (keine Rettung), Ritter (Vergeltung), Schattenwanderer, Nekromant/Kartenschlucker/Hades (Schilde), Zeitwächter (Morgenzähler), Frankenstein/Kutscher (Wiederbelebung), Orakel (sieht "Werwolf"). |
| Widersprüche | RM-C-012 Zwei Ladungen in einer Nacht; RM-C-013 "erfährt davon"; RM-C-014 Zeitpunkt "zwei Tage später" |
| Entscheidungen | RM-DR-111 (Rolle); übergreifend RM-DR-004, RM-DR-011; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K11 / in keiner Option |
| Belegsicherheit | hoch. |
| Detail | [Dossier](dossiers/wolves-a.md#giftwolf) |

### `rudelvater`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Rudelvater / Packfather |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / II / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Rettung mit Ursachenfilter und Zusatzopfer nach Lynch sind umgesetzt; Abweichungen betreffen Ablaufdetails und Begriffsabgrenzung |
| DE/EN-Vergleich | JA, semantisch gleich ("zusätzliches Opfer" = "second target", "alle Schutzfähigkeiten" = "all protection"). |
| Automationsziel | `automatic`: für Rettung; assisted für Zusatzopfer (Rudel-Prompt mit SL-Bestätigung). |
| Mechanik | primär: Wolfsangriff-Modifikation; sekundär: Hinrichtungsreaktion, Schutz, Einmalfähigkeit |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | KillPipeline (Einmal-Schild mit Ursachenfilter, Durchdringung), ExecutionRules (Hook bei Hinrichtung), StepQueue/PendingPrompt (zweiter Rudelschritt), Protections, Ereignis-Sichtbarkeit. |
| Neue Systeme | zeitlich verzögerter Effekt "nächste Nacht zusätzliches Rudelopfer" (persistiert); Ursachen-Taxonomie (wolf_attack, execution) als Attribute; Einmal-Schild pro Person (mehrere Leben light). |
| Abhängigkeiten | Werwolf (Rudel), Seuchenwolf (gemeinsame Durchdringung), Giftwolf, Schattenwanderer, Nekromant/Kartenschlucker/Hades, Dorfwache, Der Weise, Dorfschmied, Voodoo-Priester, Märtyrerin, Albtraumwolf, Sensenträger, Ritter. |
| Widersprüche | RM-C-015 Was ist "Wolfsangriff"; RM-C-016 Was ist "Lynch"; RM-C-017 "alle Schutzfähigkeiten"; RM-C-018 Wer wählt wann |
| Entscheidungen | RM-DR-112 (Rolle); übergreifend RM-DR-004, RM-DR-005; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K11 / in keiner Option |
| Belegsicherheit | hoch; nicht verifiziert: EN-Laufzeitdarstellung des hartkodierten Prompts. --- ## Gruppenübergreifende Beobachtungen 1. F2 bestätigt und in Tragweite größer als in `01:263` beschrieben: 6 der 8 Rollen (Siegreicher Wolf, Seuchenwolf, Schicksalswolf, … |
| Detail | [Dossier](dossiers/wolves-a.md#rudelvater) |

### `schwarze-witwe`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Schwarze Witwe / Black Widow |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / IV / 2.8 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Kernmechanik (Paar finden, beide sterben am Morgen) ist nachvollziehbar umgesetzt; Text verspricht automatische Loki-Wahl, Code verlangt Pflichtwahl; EN-Text ohne Zeitpunkt. Die Bugs betreffen Randpfade (Rundenwechsel) bzw. die allgemeine Werwolf-Zeile. |
| DE/EN-Vergleich | NEIN. EN fehlt der Zeitpunkt "am folgenden Tag" (EN lässt offen, ob sofort oder später gestorben wird). Übrige Teile (automatische Loki-Wahl, jede Nacht ein Spieler, Verliebter oder Verhasster, beide sterben) gleich. |
| Automationsziel | `automatic`: Ziel wählt der SL per Prompt, Paarprüfung und Morgen-Tod sind deterministisch. |
| Mechanik | primär: Verknüpfte Personen; sekundär: Tötung |
| Größe / Risiko | M / mittel. Braucht Bindungsmodell und verzögerten Tod; Reihenfolge im Morgen muss mit Zeitwächter, Märtyrerin, Schutz sauber definiert sein. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt, KillPipeline (Ursache `BLACK_WIDOW`, zeitlich DAWN), InfoRecord (SL-Info "Paar gefunden/kein Paar"), Ereignis-Sichtbarkeit (gm), Reaktionswarteschlange (Ritter-Vergeltung als Folge), StateCodec, Replay, WinRules. |
| Neue Systeme | Liebes-/Bindungsmodell (Loki-Paare Liebe/Rivalen als persistente Bindung, nicht nur Flags); zeitlich verzögerte Effekte (Tod zum nächsten Morgen, persistiert). |
| Abhängigkeiten | Loki (Pflicht, liefert Paare), Zeitwächter (Reihenfolge), Ritter (Vergeltung bei `BLACK_WIDOW`), Rudelvater/Nekromant/Kartenschlucker/Hades/Schattenwanderer/Parasit (Schilde in `applyKill`), Besessener Wolf (siehe Gruppenbeobachtung zur Morgen-Drain-Kollision). |
| Widersprüche | RM-C-019 Loki "automatisch gewählt"; RM-C-020 Todeszeitpunkt; RM-C-021 Zeitwächter-Einfrieren |
| Entscheidungen | RM-DR-113 (Rolle); übergreifend RM-DR-004; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K6 / in keiner Option |
| Belegsicherheit | hoch für Handler, Morgenreihenfolge, Setup-Pflicht, `loverId`-Lücke. Nicht verifiziert: tatsächliches Laufzeitverhalten (nicht ausgeführt); ob Nutzer `clearRolesNewRound` in der Praxis vor einer neuen Runde verwenden. --- |
| Detail | [Dossier](dossiers/wolves-b.md#schwarze-witwe) |

### `der-weise`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Der Weise / The Elder |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / I, II, III, IV / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Ein belegter Codefehler (Doppelschutz über `flags.protected`, in React immer aktiv; dazu Schutz-Persistenz) verfälscht die Kernfunktion "überlebt den ersten Werwolfangriff". |
| DE/EN-Vergleich | JA. Erster Werwolfangriff, Lynch durch Dorf, 1-3 Nächte und Tage, "diese"/"they" = das Dorf. |
| Automationsziel | `automatic`: (Rettung und Debuff-Zähler); Dauerwahl als SL-Prompt. |
| Mechanik | primär: Wolfsangriff-Modifikation; sekundär: Hinrichtungsreaktion, globale Regeländerung |
| Größe / Risiko | M / hoch. Viele Interaktionen, Legacy-Verhalten hängt vom Vergabeweg ab. |
| Vorhandene Godot-Systeme | Protections (Filter: nur Rudel-NIGHT_KILL, einmalig), KillPipeline, ExecutionRules (Hinrichtungsreaktion), PendingPrompt (1-3), StepQueue (Schritte überspringen mit Grund), Ereignis-Sichtbarkeit, GmCorrections, StateCodec, Replay. |
| Neue Systeme | Rollenblockierung (Fraktionsfilter), zeitlich verzögerte Effekte / globale Modifikatoren (Zähler über n Nächte/Tage); ggf. Tagesaktionswarteschlange mit Blockprüfung, falls "Tage" gelten. |
| Abhängigkeiten | Werwolf, Rachsüchtiger Wolf, Schicksalswolf, Seuchenwolf, Rudelvater (Durchschlag), Schutzengel/Schutzgeist (Stapelung), Albtraumwolf (Blockade entfernt Ziel), Märtyrerin, Verdammniswächter (umgeht Rettung), Waldhexe; Debuff betrifft alle Nicht-Wolf-Rollen. |
| Widersprüche | RM-C-092 Anzahl Rettungen; RM-C-093 Wer verliert Fähigkeiten; RM-C-094 Dauer "Nächte und Tage"; RM-C-095 Wer wählt 1-3; RM-C-096 Durchschlag; RM-C-097 Passive Fähigkeiten im Debuff |
| Entscheidungen | RM-DR-114 (Rolle); übergreifend RM-DR-002, RM-DR-004, RM-DR-005, RM-DR-010; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K8 / ab Option C |
| Belegsicherheit | hoch. Nicht im Browser verifiziert, ob React-Pfad heute alle Spielstarts über `startGame` führt. |
| Detail | [Dossier](dossiers/village-1.md#der-weise) |

### `verdammniswaechter`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Verdammniswächter / Doom Warden |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II, IV / 2.3 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code funktioniert als Zwei-Knopf-Urteil, widerspricht aber Text (Schutzumfang, Zeitpunkt, Kandidatenmenge) ohne offensichtlichen Defekt. |
| DE/EN-Vergleich | JA (geringfügig). DE "anderer Spieler", EN "a randomly offered player ... instead" (das "anderer" steckt in "instead"). DE Imperativ, EN dritte Person: ohne Bedeutungsunterschied. |
| Automationsziel | `assisted`: bis Q1 entschieden ist; danach automatic mit SeededRng. |
| Mechanik | primär: Zielumleitung; sekundär: Tötung, Zufallsmechanik |
| Größe / Risiko | M / hoch. Zeitpunkt- und Schutzfragen verändern viele andere Rollen. |
| Vorhandene Godot-Systeme | StepQueue (nach Rudel), PendingPrompt (2 Optionen, abbrechbar), SeededRng, KillPipeline, Protections, Reaktionswarteschlange, InfoRecord, StateCodec, Replay, GmCorrections. |
| Neue Systeme | keines zwingend; KillPipeline braucht eine Option "ignoriert alle Schutzeffekte und Schilde" und ggf. zeitlich verzögerte Effekte, falls der Tod am Morgen erfolgt. |
| Abhängigkeiten | Werwolf/Rudel (liefert Nachtopfer), Rachsüchtiger Wolf (Zusatzziel), Schutzengel/Dorfwache, Der Weise, Märtyrerin, Waldhexe, Voodoo-Priester, Nekromant, Kartenschlucker, Hades, Rudelvater, Ritter, Seuchenwolf. |
| Widersprüche | RM-C-098 "umgeht alle Schutzfähigkeiten"; RM-C-099 Todeszeitpunkt; RM-C-100 Zufallskandidat; RM-C-101 role-abilities-Text; RM-C-102 Fraktion vs. Phase |
| Entscheidungen | RM-DR-115 (Rolle); übergreifend RM-DR-002, RM-DR-005, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K11 / in keiner Option |
| Belegsicherheit | hoch. |
| Detail | [Dossier](dossiers/village-1.md#verdammniswaechter) |

### `maertyrerin`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Märtyrerin / Martyr |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 9.0 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Kernfunktion (einmaliges Ersatzopfer am Morgen) funktioniert; DE und EN widersprechen sich, Zeitwächter-Reihenfolge ist fehlerhaft, verfälscht die Kernfunktion aber nur im Randfall. |
| DE/EN-Vergleich | semantisch gleich NEIN. DE nennt den Zweck (Nachtopfer retten), aber keinen Zeitpunkt. EN nennt einen Zeitpunkt ("before the night victim is announced"), aber nicht, dass das Opfer gerettet wird. Beide nennen keine Einmaligkeit. |
| Automationsziel | `assisted`: Die App erkennt Todeskandidaten und bietet das Opfer an; die Entscheidung trifft die Märtyrerin (Ja/Nein am Tablet). |
| Mechanik | primär: Schutz; sekundär: Einmalfähigkeit |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | KillPipeline (Abfangstatus in `kill_event`), PendingPrompt (Ja/Nein + ggf. Opferwahl), Reaktionswarteschlange bzw. Morgenauflösung (`DAWN_RESOLUTION`), `ability_uses`, WinRules, StateCodec, Replay, Ereignis-Sichtbarkeit. |
| Neue Systeme | Ersatzopfer-Abfangregel in der Morgenauflösung (vor der Todesverarbeitung, nach Schutz/Zeitwächter). Keine weiteren. |
| Abhängigkeiten | Werwolf/Rudel, Rudelvater (Extraopfer), Schicksalswolf, Dorfwache, Voodoo-Priester, Zeitwächter, Der Weise, Dorfschmied, Albtraumwolf, Nekromant (Schild), Schutzengel. |
| Widersprüche | RM-C-108 Rettung vs. Zeitpunkt; RM-C-109 Welches Opfer bei mehreren; RM-C-110 Einmaligkeit; RM-C-111 Blockaden |
| Entscheidungen | RM-DR-118 (Rolle); übergreifend RM-DR-004; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K5 / in keiner Option |
| Belegsicherheit | hoch (Code vollständig gelesen); Recap-Lücke aus Bericht nicht erneut geprüft. |
| Detail | [Dossier](dossiers/village-2.md#maertyrerin) |

### `pestbringerin`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Pestbringerin / Plague Bringer |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / II / 7.2 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code ist in sich schlüssig und lauffähig, widerspricht aber Rollentext (tötet nie, 2 Einsätze) und React-Legende. |
| DE/EN-Vergleich | JA, semantisch gleich (jede Nacht, tödlich, breitet sich aus). Beide nennen keine Siegbedingung und keine Begrenzung. |
| Automationsziel | `automatic`: sofern PO die Code-Mechanik bestätigt (Ausbreitung per SeededRng, Sieg als WinCandidate). |
| Mechanik | primär: Einzelsieg; sekundär: Sitzpositionsmechanik, Zufallsmechanik |
| Größe / Risiko | M / mittel. Zufall und Sitznachbarschaft müssen deterministisch replaybar sein. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt, SeededRng, WinRules/WinCandidate, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit. |
| Neue Systeme | dauerhafte Statusmarker (Seuche), Sitznachbarschaft (Nachbarberechnung, lebend/direkt), zeitlich verzögerte Effekte (Ausbreitung bei Morgenauflösung), zusätzliche Siegbedingungen; bei Interpretation B zusätzlich verzögerte Tode. |
| Abhängigkeiten | Zeitwächter (friert Ausbreitung ein), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (zweiter Einsatz pro Nacht), Die Ewigen, Wolfsparität (konkurrierender Sieg). |
| Widersprüche | RM-C-044 Tödlichkeit; RM-C-045 Häufigkeit; RM-C-046 Siegbedingung; RM-C-047 Ausbreitung |
| Entscheidungen | RM-DR-120 (Rolle); übergreifend RM-DR-003, RM-DR-006, RM-DR-007, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K9 / in keiner Option |
| Belegsicherheit | hoch für Code; Zufallsverteilung nicht zur Laufzeit geprüft. |
| Detail | [Dossier](dossiers/solos-a.md#pestbringerin) |

### `prophet-des-untergangs`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Prophet des Untergangs / Prophet of Doom |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / III, IV / 8.6 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `not-found`. Der Text verspricht einen Einzelsieg, der im Code nicht existiert. Markieren und Töten sind implementiert und funktionieren; der Status bezieht sich auf die fehlende Siegmechanik. |
| DE/EN-Vergleich | JA, semantisch gleich (3 Markierungen, Freischaltung bei Tod aller drei, jede Nacht töten, Einzelsieg ohne Bedingung). |
| Automationsziel | `assisted`: Markieren und Töten automatisch; Sieg mangels Regel als SL-bestätigter Kandidat bzw. „Sieg erklären". |
| Mechanik | primär: Tötung; sekundär: Einzelsieg, Einmalfähigkeit |
| Größe / Risiko | M / mittel. Mechanik klar, Sieg undefiniert. |
| Vorhandene Godot-Systeme | StepQueue (bedingter Schritt), PendingPrompt, KillPipeline (`PROPHET_KILL`, sofort), Reaktionswarteschlange, WinRules/WinCandidate, GmCorrections (`declare_winner`), StateCodec, Replay, Ereignis-Sichtbarkeit. |
| Neue Systeme | dauerhafte Statusmarker (unheilig, Markierungsliste pro Prophet), zusätzliche Siegbedingungen. |
| Abhängigkeiten | alle Tötungsrollen (Freischaltung), Kutscher/Frankenstein (Wiederbelebung), Lehrling/Seelentauscher (Erbe des globalen Zustands), Rotkäppchen (zwei Tötungen), Schilde (Nekromant, Hades, Kartenschlucker, Rudelvater), Die Ewigen. |
| Widersprüche | RM-C-048 Einzelsieg; RM-C-049 Freischaltung dauerhaft; RM-C-050 Selbstmarkierung |
| Entscheidungen | RM-DR-121 (Rolle); übergreifend RM-DR-006, RM-DR-007, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K9 / in keiner Option |
| Belegsicherheit | hoch; Sieg-Abwesenheit per `rg` über `js/`, `game.html`, `app/src` belegt. |
| Detail | [Dossier](dossiers/solos-a.md#prophet-des-untergangs) |

### `daemonischer-wolf`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Dämonischer Wolf / Demonic Wolf |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / II / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code ist in sich nachvollziehbar (Todesfluch mit Wolfswertung), widerspricht aber Text (Opfer, nur Erscheinung) und der eigenen Code-Absicht (`ab:75`). |
| DE/EN-Vergleich | JA, semantisch gleich (verfluchen, Opfer/victims, erscheinen/gesehen als Werwolf). Nuance: DE "Opfer" ist grammatisch Singular oder Plural, EN "victims" nur Plural; beide nennen keinen Zeitpunkt und keine Häufigkeit. |
| Automationsziel | `automatic`: (Reaktion mit Pflicht-Prompt), sobald PO Auslöser und Wirkung entschieden hat. |
| Mechanik | primär: Todesreaktion; sekundär: Fehlinformation, Fraktionswechsel |
| Größe / Risiko | M / hoch. Reaktion ist einfach, aber die Trennung Erscheinung vs. Zählung berührt alle Informationsrollen und die Siegprüfung. |
| Vorhandene Godot-Systeme | Reaktionswarteschlange (neue Reaktionsart "curse_appearance"), PendingPrompt, appears_as, KillPipeline (Auslöser nach echtem Tod), InfoRecord (Wahrheit vs. gezeigt), GmCorrections (Fluch entfernen), StateCodec, Replay, WinRules (unverändert, falls nur Erscheinung). |
| Neue Systeme | dauerhafte Statusmarker (Fluch als persistenter Marker mit Quelle), falls nicht vollständig über `appears_as` abbildbar. |
| Abhängigkeiten | Orakel, Blutpriester, Waldläufer, Doktor, Detektiv, Kopfgeldjäger, Ritter, Dorfschmied, Traumdeuter (alle `isWolf`-Leser); Seelentauscher und Wächter am Tor (löschen Fluch); Nekromant (F14-Fall). |
| Widersprüche | RM-C-022 Auslöser; RM-C-023 Wirkung des Fluchs; RM-C-024 Todespfade |
| Entscheidungen | RM-DR-122 (Rolle); übergreifend RM-DR-002, RM-DR-009; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K12 / in keiner Option |
| Belegsicherheit | hoch für Auslösepfade und `isWolf`-Nutzung. Nicht verifiziert: Laufzeitverhalten des Abbruchs (nur aus Code abgeleitet); Godot-Reaktionsarten (nur Doku gelesen). --- |
| Detail | [Dossier](dossiers/wolves-b.md#daemonischer-wolf) |

### `schattenhund`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Schattenhund / Shadow Hound |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / III / 0.7 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Kernfunktion (einmalige Blockade einer Nacht) funktioniert; Zielgruppe (Solo) und Nacht-1-Sperre weichen vom Text ab. |
| DE/EN-Vergleich | JA, semantisch gleich (einmalig/once, alle Dorf-Fähigkeiten/all village abilities, eine Nacht/one night). |
| Automationsziel | `automatic` |
| Mechanik | primär: globale Regeländerung; sekundär: Einmalfähigkeit |
| Größe / Risiko | S / mittel. Einfache Flag-Logik; Risiko in der genauen Abgrenzung, welche Effekte blockiert sind. |
| Vorhandene Godot-Systeme | StepQueue (Schritt-Status "blockiert mit Grund", 04 B-6), PendingPrompt (Ja/Nein), `ability_uses`, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections. |
| Neue Systeme | Rollenblockierung (globaler Nacht-Modifikator mit Fraktionsfilter und Ablauf bei Nachtende). |
| Abhängigkeiten | alle Dorf-Nachtrollen; Wolfskind und Lehrling (Begründung der Nacht-1-Sperre); Albtraumwolf, Zeitwächter, Der Weise (gleiche Blockadefamilie). |
| Widersprüche | RM-C-025 Betroffene Rollen; RM-C-026 Nacht 1; RM-C-027 Nicht-Nachtschritt-Effekte |
| Entscheidungen | RM-DR-123 (Rolle); übergreifend RM-DR-010, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K8 / ab Option B |
| Belegsicherheit | hoch. --- |
| Detail | [Dossier](dossiers/wolves-b.md#schattenhund) |

### `fenrir`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Fenrir / Fenrir |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / IV / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Der Code ist nicht offensichtlich defekt, setzt aber eine deutlich engere Regel um (nur Lynch, Zählung bei Nachtbeginn, zusätzliche Ritter-Immunität); F15 ist ein Nebenfehler. |
| DE/EN-Vergleich | JA, semantisch gleich (überlebte Nacht, Stufe 3, einmalig, jeder Tod). |
| Automationsziel | `automatic`: (nach PO-Entscheidung). |
| Mechanik | primär: Hinrichtungsreaktion; sekundär: sonstige Spezialmechanik, Einmalfähigkeit |
| Größe / Risiko | M / mittel. Eine Abfangregel plus Zähler; Risiko in der Reihenfolge mit anderen Schilden. |
| Vorhandene Godot-Systeme | KillPipeline (Abfangregel mit Verbrauch), ExecutionRules (falls nur Lynch), Reaktionswarteschlange (Ritter-Zielauswahl), InfoRecord/Ereignis (gm), StateCodec, Replay, GmCorrections (Stufe setzen). |
| Neue Systeme | mehrere Leben / Einmal-Überleben als persistenter Marker; Nachtzähler pro Person (Stufe). |
| Abhängigkeiten | Ritter, Henker (LynchCount), Feuerteufel (Brand), Lehrling/Seelentauscher/Frankenstein (Rollenerwerb mit alter Stufe), alle Tötungsrollen. |
| Widersprüche | RM-C-029 Umfang des Überlebens; RM-C-030 Zählung; RM-C-031 Ritter; RM-C-032 Stufe pro Rolle vs. global |
| Entscheidungen | RM-DR-125 (Rolle); übergreifend RM-DR-011; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K4 / in keiner Option |
| Belegsicherheit | hoch. --- |
| Detail | [Dossier](dossiers/wolves-b.md#fenrir) |

### `kutscher`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Kutscher / Coachman |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 3.8 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code ist funktional (keine Fehlfunktion der Kernmechanik gefunden), weicht aber in Rollenvergabe und Auswahlverfahren vom Text ab; 04 "verifiziert" ist zu optimistisch. |
| DE/EN-Vergleich | semantisch gleich NEIN (geringfügig). DE "kann" = optional; EN "revives" klingt verpflichtend/automatisch. Schwelle (10), Anzahl (3) und Wolf (1) gleich. Beide sagen nichts über Einmaligkeit, Auswahl der Toten oder neue Rollen. |
| Automationsziel | `assisted`: Bedingung und Verbrauch automatisch; Auswahl/Rollen hängen an PO-Entscheidung, Ergebnis braucht SL-Bestätigung wegen großer Wirkung. |
| Mechanik | primär: Wiederbelebung; sekundär: Rollenwechsel, Zufallsmechanik |
| Größe / Risiko | L / hoch |
| Vorhandene Godot-Systeme | StepQueue (bedingter Schritt), PendingPrompt, SeededRng, RoleTransition (Rollenzuweisung mit Schnappschuss, Wächter-am-Tor-Umleitung), WinRules/WinCandidate, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit. |
| Neue Systeme | Wiederbelebungsmodell (Tod aufheben, Status/Bindungen zurücksetzen, Totenkarten-Status, Ereignis `REVIVE`), Rollenpool-Regel (Akt/Fraktion) für neu vergebene Rollen, Totenkarten-Effektmodell für die revive-gebundenen Karten. |
| Abhängigkeiten | Wächter am Tor, Werwolf/Rudel, alle Rollen im Pool, Totenkarten (4 revive-Karten), Prophet des Untergangs (Ziele), Schicksalswolf (`FirstThreeDeadIds`), Seelentauscher/Lehrling (Rollenerbe). |
| Widersprüche | RM-C-114 Rollen der Wiederbelebten; RM-C-115 Wer wählt die Toten; RM-C-116 Optional; RM-C-117 Einmaligkeit |
| Entscheidungen | RM-DR-126 (Rolle); übergreifend RM-DR-011, RM-DR-013, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K13 / in keiner Option |
| Belegsicherheit | hoch für Code; mittel für Totenkarten-Wirkung (Karteninhalte nicht im Detail geprüft). |
| Detail | [Dossier](dossiers/village-2.md#kutscher) |

### `seelentauscher`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Seelentauscher / Soul Swapper |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 8.0 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Der belegte Fehler F4 verfälscht die Kernfunktion (Rollentausch mit Wolfsrolle erzeugt einen zusätzlichen Wolf). |
| DE/EN-Vergleich | semantisch gleich JA. |
| Automationsziel | `assisted`: Tausch automatisch über RoleTransition; SL bestätigt, Betroffene werden informiert. |
| Mechanik | primär: Rollenwechsel; sekundär: Einmalfähigkeit, Fraktionswechsel |
| Größe / Risiko | L / kritisch |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (Mehrfachwahl 2, abbrechbar), RoleTransition (Schnappschuss, Wächter-Umleitung), InfoRecord (Mitteilung an Betroffene), WinRules, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit, WolfChildBond/ApprenticeBond (Bindungen bei Rollenwechsel). |
| Neue Systeme | Regel "Rollenzustand wandert mit" (Verbrauchszähler/Bindungen je Rolle vs. je Person) als Teil von RoleTransition; kein eigenes neues System, sofern RoleTransition zwei gleichzeitige Wechsel atomar kann (nicht verifiziert). |
| Abhängigkeiten | alle Rollen (tauschbar), insbesondere Wolfsrollen, Wächter am Tor, Wolfskind/Lehrling (Bindungen), Loki/Rotkäppchen/Parasit (Sitz-Bindungen), Dorfwache/Märtyrerin (Rollenprüfung am Morgen), Kutscher/Blutpriester (Einmaligkeit). |
| Widersprüche | RM-C-118 Wolfsstatus nach Tausch; RM-C-119 Was wandert mit; RM-C-120 Toter erhält Wolfsrolle; RM-C-121 Information der Betroffenen |
| Entscheidungen | RM-DR-127 (Rolle); übergreifend RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K12 / in keiner Option |
| Belegsicherheit | hoch für F4 und Einmaligkeitslogik (Code vollständig verfolgt); Querbezüge zu Wolfskind/Lehrling nur gelesen, nicht durchgespielt. |
| Detail | [Dossier](dossiers/village-2.md#seelentauscher) |

### `blutpriester`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Blutpriester / Blood Priest |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 8.2 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Opfer und Aufdeckung von 0 bis 3 Wölfen sind nachvollziehbar umgesetzt; offene Punkte sind Regelpräzisierungen. |
| DE/EN-Vergleich | semantisch gleich JA. |
| Automationsziel | `assisted`: Tod automatisch; Anzahl durch SL, Auswahl per SeededRng, Ergebnis als InfoRecord. |
| Mechanik | primär: Informationsrolle; sekundär: Tötung, Einmalfähigkeit, Zufallsmechanik |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (Ziel, dann Anzahl), KillPipeline (Sofort-Tod in der Nacht), SeededRng, InfoRecord (Wahrheit/ermittelt/gezeigt), Ereignis-Sichtbarkeit, `ability_uses`, WinRules, StateCodec, Replay. |
| Neue Systeme | keine nachweislich (Sofort-Tod in der Nacht und Reaktionszeitpunkt sind Teil von KillPipeline/Reaktionswarteschlange, 04 B-10). |
| Abhängigkeiten | Rudelvater, Nekromant, Hades, Kartenschlucker, Parasit, Schattenwanderer (Todesabfang), Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Doppelspion (nicht Wolf), Sensenträger (Reaktion auf Opfer), Seelentauscher (Einmaligkeit). |
| Widersprüche | RM-C-122 Anzahl 0–3; RM-C-123 Wer sieht das Ergebnis; RM-C-124 Opfer: Pflicht? |
| Entscheidungen | RM-DR-128 (Rolle); übergreifend RM-DR-002, RM-DR-014, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K7 / in keiner Option |
| Belegsicherheit | hoch für Code; Overlay-Überschreibung aus Codefluss abgeleitet, nicht im Browser beobachtet. |
| Detail | [Dossier](dossiers/village-2.md#blutpriester) |

### `traumdeuter`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Traumdeuter / Dreamer |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / III / 7.0 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Der Text ist vage, der Code liefert eine konkrete, andere Mechanik (Wolf unter drei); 04 "unklar" ist inhaltlich gleichbedeutend. |
| DE/EN-Vergleich | semantisch gleich JA. |
| Automationsziel | `automatic`: (bei Übernahme des Codes: Auswahl per SeededRng, Anzeige an Traumdeuter); sonst unknown. |
| Mechanik | primär: Informationsrolle; sekundär: Zufallsmechanik |
| Größe / Risiko | S / niedrig |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (Anzeige/Bestätigung "gezeigt"), SeededRng, InfoRecord, appears_as/InformationRules, Ereignis-Sichtbarkeit (actor), StateCodec, Replay. |
| Neue Systeme | keine. |
| Abhängigkeiten | alle Wolfsrollen, Dämonischer Wolf (Fluch), Trugbilderwolf (Erscheinung), Doppelspion, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise (Blockaden). |
| Widersprüche | RM-C-125 Inhalt der Vision; RM-C-126 Selbst in der Vision; RM-C-127 Verfluchte als Wolf |
| Entscheidungen | RM-DR-129 (Rolle); übergreifend RM-DR-002, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K7 / in keiner Option |
| Belegsicherheit | hoch. |
| Detail | [Dossier](dossiers/village-2.md#traumdeuter) |

### `henker`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Henker / Executioner |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / III / 7.8 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Aktivierung nach 3 Lynchungen, nächtliche Markierung und Zusatztod beim nächsten Lynch sind nachvollziehbar umgesetzt; F15 ist ein Randfall mit offener Regel. |
| DE/EN-Vergleich | semantisch gleich NEIN (geringfügig). EN präzisiert "after the next lynch"; DE sagt nur "nach Lynchung" (offen, ob nächste oder irgendeine). Aktivierung (3 Lynchungen) und Häufigkeit (jede Nacht) gleich. |
| Automationsziel | `automatic`: Markierung per Prompt, Vollstreckung automatisch in ExecutionRules. |
| Mechanik | primär: Hinrichtungsreaktion; sekundär: Tötung |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue (bedingter Schritt), PendingPrompt, ExecutionRules (Folgetod nach Hinrichtung), KillPipeline, Reaktionswarteschlange (Folgereaktionen des Markierten), WinRules, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit. |
| Neue Systeme | dauerhafter Statusmarker mit Besitzer (Henker-Markierung bis zum nächsten Lynch), Lynch-Zähler im Spielstand (zeitlich verzögerter Effekt an Hinrichtung gekoppelt). |
| Abhängigkeiten | alle Lynch-Sonderzweige (Wahnsinniger Kutscher, Voodoo, Der Weise, Selbstmörder, Spiegelwolf, Dämonischer Wolf, Fenrir, Cerberus, Rudelvater), Rudelvater/Nekromant/Hades/Kartenschlucker/Parasit (Todesabfang). |
| Widersprüche | RM-C-128 Welcher Lynch; RM-C-129 Blockierter Lynch (Fenrir/Cerberus); RM-C-130 Zählbasis; RM-C-131 Henker tot |
| Entscheidungen | RM-DR-130 (Rolle); Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K4 / in keiner Option |
| Belegsicherheit | hoch. ## Gruppenübergreifende Beobachtungen 1. Globale Einmaligkeit statt pro Person: `markOnceUsed`/`isOnceUsed` (`night:3-5`) speichert den Verbrauch pro Rollenname (`once.Used.role_<Name>`); Märtyrerin (`MaertyUsed`) und Kutscher (`KutscherUsed`) nutzen … |
| Detail | [Dossier](dossiers/village-2.md#henker) |

### `feuerteufel`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Feuerteufel / Pyromaniac |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / IV / 7.6 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Die Kernfunktion „beim Tod des Ziels" wird durch belegte Fehler verfälscht (Brand ohne Tod, kein Brand bei Tod durch andere Ursachen). |
| DE/EN-Vergleich | JA, semantisch gleich. Beide ohne Häufigkeit, Dauer, Nachbardefinition, Siegbedingung. |
| Automationsziel | `automatic`: nach Regelfestlegung; der Brand ist eine deterministische Todesreaktion. |
| Mechanik | primär: Todesreaktion; sekundär: Sitzpositionsmechanik, Hinrichtungsreaktion |
| Größe / Risiko | M / hoch. Viele Wechselwirkungen in Nachtauflösung und Hinrichtung. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt, KillPipeline (Kettenschritt), Reaktionswarteschlange, ExecutionRules, WinRules, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit. |
| Neue Systeme | Sitznachbarschaft, dauerhafte Statusmarker (Brandmarke mit Ablauf), ggf. zusätzliche Siegbedingungen. |
| Abhängigkeiten | Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Albtraumwolf (Blockade), Der Weise, Dorfschmied, Nekromant, Waldhexe, Märtyrerin, Voodoo-Priester, Dorfwache (Überleben/Entfernen aus Zielen), Fenrir, Cerberus, Spiegelwolf, Wahnsinniger Kutscher (Lynch-Zweige), Ritter (Vergeltung bei … |
| Widersprüche | RM-C-051 Auslöser; RM-C-052 Dauer der Markierung; RM-C-053 Nachbarn; RM-C-054 Feuerteufel als Nachbar; RM-C-055 Siegbedingung |
| Entscheidungen | RM-DR-131 (Rolle); übergreifend RM-DR-003, RM-DR-006, RM-DR-007, RM-DR-009; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K9 / in keiner Option |
| Belegsicherheit | hoch für Code-Pfade; nicht zur Laufzeit geprüft. |
| Detail | [Dossier](dossiers/solos-a.md#feuerteufel) |

### `voodoo-priester`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Voodoo-Priester / Voodoo Priest |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / II / 8.4 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Die Umlenkung funktioniert für die Hauptursachen, widerspricht aber dem allgemeinen Text („bei seinem Tod") und enthält eine undokumentierte Abklingzeit; die belegten Bugs betreffen Nebenpfade. |
| DE/EN-Vergleich | JA mit Nuance. EN „If he would die" macht das Überleben des Priesters ausdrücklich; DE „Solange eine Puppe aktiv ist" fehlt in EN. Keine Unterschiede bei Zeitpunkt, Häufigkeit, Zahlen; beide schweigen zu Abklingzeit, Ursachen und Häufigkeit des Vergebens. |
| Automationsziel | `automatic`: Umlenkung ist eine deterministische Abfangregel in der KillPipeline, sobald der Ursachenfilter feststeht. |
| Mechanik | primär: Zielumleitung; sekundär: Verknüpfte Personen, Hinrichtungsreaktion |
| Größe / Risiko | L / hoch. Abfangreihenfolge, Ursachenfilter, Abklingzeit und Hinrichtungspfad. |
| Vorhandene Godot-Systeme | KillPipeline (Abfangregel/Umlenkung), ExecutionRules (Hinrichtungsumlenkung, analog Spiegelwolf-Umlenkung), StepQueue, PendingPrompt, Protections (Abgrenzung), StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit. |
| Neue Systeme | Liebes-/Bindungsmodell (Priester-Puppe-Bindung), dauerhafte Statusmarker (Puppe), zeitlich verzögerte Effekte (Abklingzeit), ggf. zusätzliche Siegbedingungen. |
| Abhängigkeiten | Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Waldhexe (Gift), Märtyrerin, Der Weise, Dorfschmied, Nekromant (Reihenfolge der Abfangregeln), Rattenfänger (Verzauberung), Feuerteufel (Brand entfällt bei Umlenkung), Hades/Kartenschlucker/Nekromant/Rudelvater (Schilde der Puppe), Henker. |
| Widersprüche | RM-C-056 Ursachen der Umlenkung; RM-C-057 Abklingzeit; RM-C-058 Verzauberung löschen; RM-C-059 Siegbedingung; RM-C-060 Bezeichnung |
| Entscheidungen | RM-DR-132 (Rolle); übergreifend RM-DR-006, RM-DR-007; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K10 / in keiner Option |
| Belegsicherheit | hoch; Ursachenliste per `rg "VOODOO_PUPPET"` vollständig (`night:255,442`, `help:265`, `gh:2426`, `ui:407`). |
| Detail | [Dossier](dossiers/solos-a.md#voodoo-priester) |

### `albtraumwolf`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Albtraumwolf / Nightmare Wolf |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / III, IV / 2.1 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. F3 verfälscht die Kernwirkung: die Blockade wird zum Schutz gegen das eigene Rudel. |
| DE/EN-Vergleich | JA, semantisch gleich (jede Nacht, eine Person, Dorfbewohner/villager). |
| Automationsziel | `automatic` |
| Mechanik | primär: sonstige Spezialmechanik; sekundär: globale Regeländerung |
| Größe / Risiko | S / mittel |
| Vorhandene Godot-Systeme | StepQueue (Schritt-Status `blocked(reason)`), PendingPrompt, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections. |
| Neue Systeme | Rollenblockierung (pro Person, mit Ablauf zum Nachtende). |
| Abhängigkeiten | alle Nicht-Wolf-Nachtrollen mit tier > 2.1; Schattenhund/Zeitwächter/Der Weise (gleiche Blockadefamilie); Dämonischer Wolf (Verfluchte nicht wählbar); Rudel (F3). |
| Widersprüche | RM-C-033 Ziele; RM-C-034 Umfang; RM-C-035 Anzahl pro Nacht; RM-C-036 Späte Wirkung |
| Entscheidungen | RM-DR-134 (Rolle); übergreifend RM-DR-010; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K8 / in keiner Option |
| Belegsicherheit | hoch. --- |
| Detail | [Dossier](dossiers/wolves-b.md#albtraumwolf) |

### `cerberus`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Cerberus / Cerberus |
| Fraktion / Akte / Legacy-Nachtpriorität | Wölfe / IV / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Kopfaufbau und Lynch-Abwehr funktionieren, aber Wahlfreiheit ("kann"), Zusatzwirkung gegen Hexe und F15 weichen vom Text ab; 04 "verifiziert" ist zu optimistisch. |
| DE/EN-Vergleich | JA, semantisch gleich (bis 3 Köpfe, bei 3 eine Lynchung abwehren, "kann"/"can"). |
| Automationsziel | `automatic`: (mit optionalem Bestätigungsprompt, falls "kann" als Wahl gilt). |
| Mechanik | primär: Hinrichtungsreaktion; sekundär: sonstige Spezialmechanik |
| Größe / Risiko | S / mittel |
| Vorhandene Godot-Systeme | ExecutionRules (Abfangregel vor Hinrichtung), Nominations/Execution-Ereignisse, PendingPrompt (falls Wahl), StateCodec, Replay, GmCorrections (Köpfe setzen), Ereignis-Sichtbarkeit. |
| Neue Systeme | dauerhafte Statusmarker bzw. Zähler pro Person (Köpfe, mit Aufladung bei Phasenwechsel). |
| Abhängigkeiten | Waldhexe (Trank), Henker (LynchCount), Feuerteufel (Brand beim Lynch), Kopfgeldjäger (Lynch eines Wolfs), Spiegelwolf/Voodoo/Der Weise (Reihenfolge der Lynch-Sonderzweige `night:425-501`). |
| Widersprüche | RM-C-037 Wahl oder Automatik; RM-C-038 Hexengift; RM-C-039 Aufbau |
| Entscheidungen | RM-DR-135 (Rolle); Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K4 / ab Option B |
| Belegsicherheit | hoch. --- ## Gruppenübergreifende Beobachtungen 1. **Nur drei der acht Rollen haben einen Nachtschritt** (Schattenhund 0.7 once, Albtraumwolf 2.1, Schwarze Witwe 2.8). Dämonischer Wolf und Besessener Wolf sind reine Todesreaktionen, Fenrir und Cerberus reine … |
| Detail | [Dossier](dossiers/wolves-b.md#cerberus) |

### `rotkaeppchen`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Rotkäppchen / Little Red Riding Hood |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / III / 7.4 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Kette und Zuflucht funktionieren; der Apfel wirkt nur für einen Teil der Rollen, und Zielbeschränkung/Dauer weichen vom Text ab bzw. sind dort nicht geregelt. |
| DE/EN-Vergleich | JA. Beide lassen gleichermaßen offen, ob die Todeskette nur bei gewährter Zuflucht entsteht ("Außerdem"/"also"), wie lange sie gilt und ob "anderen Spieler" "nicht sie selbst" oder "jede Nacht ein anderer" bedeutet. |
| Automationsziel | `assisted`: Zuflucht und Zustimmung sind Entscheidungen am Tisch (SL tippt), Kette und Apfel-Verfall kann der Kern automatisch führen. |
| Mechanik | primär: Verknüpfte Personen; sekundär: Todesreaktion, mehrstufige Nachtfähigkeit, sonstige Spezialmechanik |
| Größe / Risiko | L / hoch. Zwei gekoppelte Mechaniken (Kette + Apfel), Apfel berührt jede Nachtfähigkeit, Kettenrekursion in der KillPipeline. |
| Vorhandene Godot-Systeme | PendingPrompt (Ziel → Zustimmung → Bestätigung), StepQueue, KillPipeline (Folgetod mit eigener Ursache, `03` Zeile 230), Reaktionswarteschlange, RoleTransition (Kette bei Rollenwechsel), StateCodec, Replay, Ereignis-Sichtbarkeit, GmCorrections. |
| Neue Systeme | Bindungsmodell (Paarbindung mit Gültigkeit, analog Liebespaar), dauerhafter Statusmarker "Apfel" mit Verbrauchsregel, "repeat step"/Doppel-Ausführung in StepQueue, ggf. Zielhistorie. |
| Abhängigkeiten | alle Rollen mit Nachtfähigkeit (Apfel), König/Frankenstein/Dorfschmied/Pestbringerin/Prophet (`APPLE_RESET_FLAGS`), Seelentauscher, Parasit, Kartenschlucker/Hades/Nekromant (Schilde), Ritter (Kettentod löst keine Vergeltung aus), Loki (zweites Bindungssystem). |
| Widersprüche | RM-C-135 Wölfe als Zuflucht; RM-C-136 Apfel-Wirkung; RM-C-137 Dauer der Kette; RM-C-138 Ablehnung; RM-C-139 Mehrfache Zuflucht beim Selben |
| Entscheidungen | RM-DR-137 (Rolle); übergreifend RM-DR-009, RM-DR-011; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K10 / in keiner Option |
| Belegsicherheit | hoch für Kette und Apfel-Mechanik (statisch belegt). Nicht zur Laufzeit geprüft: Zusammenspiel `startConfirm`-Overlay mit gleichzeitigem `center` anderer Rollen. --- |
| Detail | [Dossier](dossiers/village-3.md#rotkaeppchen) |

### `kopfgeldjaeger`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Kopfgeldjäger / Bounty Hunter |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / IV / 3.2 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Kernfunktion (nach Wolfs-Lynch in der Folgenacht drei Namen, genau ein Wolf) ist nachvollziehbar umgesetzt; Abweichungen betreffen Randfälle (Selbstanzeige, Zähler, Erbe). |
| DE/EN-Vergleich | NEIN (Nuance). DE "Sobald ... gelyncht wird" liest sich als Auslöser je Lynch; EN "Once a werewolf has been lynched" kann auch "ab dem ersten Wolfs-Lynch (danach dauerhaft)" bedeuten. Sonst gleich: drei Spieler/Namen, einer davon Werwolf; beide lassen offen, ob "genau einer". |
| Automationsziel | `automatic`: Keine Spielerentscheidung; Auswahl über SeededRng, SL sieht das Ergebnis vor dem Zeigen (InfoRecord). |
| Mechanik | primär: Informationsrolle; sekundär: Hinrichtungsreaktion, Zufallsmechanik |
| Größe / Risiko | M / mittel. Zufall muss seed-stabil sein, Auslöser hängt an allen Hinrichtungszweigen. |
| Vorhandene Godot-Systeme | ExecutionRules (Auslöser nach Hinrichtung), StepQueue (bedingter Schritt), SeededRng, InfoRecord (Wahrheit/ermittelt/gezeigt), Ereignis-Sichtbarkeit, StateCodec, Replay, RoleTransition. |
| Neue Systeme | Aktivierungszähler pro Person/Rolle (Erweiterung `ability_uses` oder Rollenzustand), bedingte Schrittverfügbarkeit ("nur wenn aktiv") in StepQueue; InfoRecord für Namenslisten statt einer Rolle. |
| Abhängigkeiten | alle Wolfsrollen, Dämonischer Wolf (Verfluchte), Spiegelwolf/Fenrir/Cerberus (kein Tod beim Lynch), Der Weise, Lehrling/Seelentauscher, Schattenhund/Albtraumwolf/Zeitwächter (Blockade), Doppelspion (zählt als Nicht-Wolf). |
| Widersprüche | RM-C-140 Wiederholung; RM-C-141 Selbst unter den drei; RM-C-142 Aktivierung durch Erbe; RM-C-143 Verfluchter als "Werwolf" |
| Entscheidungen | RM-DR-139 (Rolle); übergreifend RM-DR-002, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K7 / ab Option B |
| Belegsicherheit | hoch. Nicht verifiziert: ob der Der-Weise-Zweig praktisch je einen Wolf trifft (nur bei verfluchtem Weisen). --- |
| Detail | [Dossier](dossiers/village-3.md#kopfgeldjaeger) |

### `koenig`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | König / King |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / III, IV / 4.4 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code (jede Nacht) und Text (DE einmalig "in dieser Nacht") widersprechen sich, 04/07 führen es bereits als offene Regel. |
| DE/EN-Vergleich | NEIN. (1) Häufigkeit: DE "Sobald ... in dieser Nacht" legt ein einmaliges Ereignis in der Nacht des Umschlagens nahe; EN "When ..." kann "jedes Mal, wenn" bedeuten. (2) EN sagt ausdrücklich "living", DE nicht. (3) DE "einen Dorfbewohner (und dessen Rolle)" nennt Rolle ausdrücklich; EN "identity" … |
| Automationsziel | `automatic`: Bedingung und Auswahl sind ohne Spielerentscheidung berechenbar (SeededRng), Ergebnis als InfoRecord. |
| Mechanik | primär: Informationsrolle; sekundär: Zufallsmechanik |
| Größe / Risiko | S / mittel. Einfache Berechnung, aber Fraktionsdefinition und Häufigkeit müssen entschieden sein. |
| Vorhandene Godot-Systeme | StepQueue (bedingter Schritt, StepDropped), SeededRng, InfoRecord, Ereignis-Sichtbarkeit, StateCodec, Replay. |
| Neue Systeme | bedingte Schrittverfügbarkeit nach Zählbedingung (Tote > Lebende), ggf. Einsatzzähler; InfoRecord-Variante "Person + Rolle". |
| Abhängigkeiten | Wolfskind, Lehrling, Dämonischer Wolf (Verfluchte), Seelentauscher, Rotkäppchen (Apfel), Frankenstein/Kutscher (Wiederbelebung verändert Tote/Lebende). |
| Widersprüche | RM-C-144 Häufigkeit; RM-C-145 Wer wird gezeigt; RM-C-146 Umfang der Info |
| Entscheidungen | RM-DR-140 (Rolle); übergreifend RM-DR-002, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K7 / in keiner Option |
| Belegsicherheit | hoch. --- |
| Detail | [Dossier](dossiers/village-3.md#koenig) |

### `dr-victor-frankenstein`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Dr. Victor Frankenstein / Dr. Victor Frankenstein |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 3.6 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. In der React-Oberfläche verfälscht der fehlende Dropdown die Kernfunktion (Rolle wird nicht gewählt), in `game.html` ist die Aktion nicht atomar (Teilzustand bei fehlenden Rollen) und der Apfel-Pfad verliert die Rollenvergabe. Der Normalfall in `game.html` funktioniert. |
| DE/EN-Vergleich | JA mit Nuance. Häufigkeit (einmal), Ziel (ein Toter), Wirkung (neue Rolle) gleich. DE "Kann" macht die Nutzung ausdrücklich freiwillig, EN nicht ausdrücklich. "brand new role" könnte als "Rolle, die noch nicht im Spiel ist" gelesen werden (entspricht zufällig `chunk:64`), DE "neue Rolle" nur als … |
| Automationsziel | `assisted`: Spieler entscheidet (ob, wen, welche Rolle), der Kern führt die Prompt-Kette und wendet atomar an. |
| Mechanik | primär: Wiederbelebung; sekundär: Rollenwechsel, Einmalfähigkeit, mehrstufige Nachtfähigkeit, Totenkarten-Interaktion |
| Größe / Risiko | L / hoch. Mehrstufiger Prompt, Rollenwechsel mit Fraktionswechsel, Siegprüfung, viele Seiteneffekte auf Bindungen. |
| Vorhandene Godot-Systeme | PendingPrompt (Ja/Nein → Toter → Rolle → Bestätigung, abbrechbar), RoleTransition (Rolle, Fraktion, `counts_as_wolf`, frische Einsätze, Schnappschuss), StepQueue, WinRules/WinCandidate, GmCorrections (`revive`, `set_role` existieren), StateCodec, Replay, Ereignis-Sichtbarkeit. |
| Neue Systeme | Wiederbelebungsmodell im Kern (Reset-Liste für Marker/Bindungen, Totenkarten-Status), Totenkarten-Effektmodell (Tag-Aktivierung), Regel "Wächter am Tor blockiert neue Wölfe" als Prüfung in RoleTransition, Neuberechnung des Nachtplans nach Rollenwechsel in der Nacht (Nachtplan ist heute Snapshot, `godot/README.md` Wolfskind-Abschnitt). |
| Abhängigkeiten | Wächter am Tor, Loki (Liebende), Rotkäppchen (Apfel/Kette), Sensenträger (`hunterShot`/`hunterQueued`), Ritter, Lehrling/Seelentauscher (Erbe), Kutscher (zweite Wiederbelebungsrolle), Totenkarten `segen_08`, `wende_04`, `wende_07`, `loki_10`, Hades (Lichter zählen Tode), alle Rollen als mögliche neue Rolle. |
| Widersprüche | RM-C-147 Rollenpool; RM-C-148 Zustand des Wiederbelebten; RM-C-149 Einmaligkeit bei Erbe; RM-C-150 Totenkarten-Aktivierung nach Verbrauch |
| Entscheidungen | RM-DR-141 (Rolle); übergreifend RM-DR-011, RM-DR-013; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K13 / in keiner Option |
| Belegsicherheit | hoch für `game.html`-Pfad; React-Verhalten (erste Rolle) aus Code und SPECIAL-ROLE-FLOW-REPORT abgeleitet, nicht selbst ausgeführt. --- |
| Detail | [Dossier](dossiers/village-3.md#dr-victor-frankenstein) |

### `nekromant`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Nekromant / Necromancer |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / II / 3.0 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Schild, Umlenkung und Sieg sind implementiert und funktionieren im Normalfall; Text und Code widersprechen sich in Optionalität der Umlenkung, Reichweite des Schildes, Ressourcenmodell und Versuchsgrenze. Der Abbruch-Bug betrifft nur den Nebenpfad. |
| DE/EN-Vergleich | semantisch gleich NEIN (geringe, aber reale Unterschiede): (1) DE "die nächste Tötung (beliebig)" vs EN "the next death of any kind": DE spricht von Tötung, EN von Tod; beide lassen offen, ob der Schild nur den Nekromanten oder jede Person schützt. (2) DE "drei Tote wählen" vs EN "sacrifice three … |
| Automationsziel | `assisted`: Schild, Verfall, Umlenkungsangebot und Wolfsprüfung sind deterministisch automatisierbar; Benennung am Tag braucht einen SL-Befehl, Sieg per WinCandidate mit SL-Bestätigung. |
| Mechanik | primär: Schutz; sekundär: Zielumleitung, Einzelsieg, Tagfähigkeit |
| Größe / Risiko | L / hoch. Globaler Schild im Kill-Pfad, mehrstufiger Pflicht-/Optionalprompt in der Morgenauflösung, zwei Ressourcenlisten, Tages-Siegbefehl. |
| Vorhandene Godot-Systeme | KillPipeline (Abfangstufe für globalen Schild), StepQueue (Nachtschritt), PendingPrompt (Auswahl 3 Tote, Umlenkziel, abbrechbar), WinRules/WinCandidate, InfoRecord (Benennungsergebnis), GmCorrections, StateCodec, Replay, Ereignis-Sichtbarkeit. |
| Neue Systeme | dauerhafte Statusmarker an toten Personen (Stimme geopfert), globale Modifikatoren (Schild bis Beginn nächster Nacht, zeitlich verzögerter Verfall), Zielumleitung für Nacht-Rudelangriff (vorhanden nur für Hinrichtung, Spiegelwolf), Tagesaktionswarteschlange (Benennung), zusätzliche Siegbedingung. |
| Abhängigkeiten | Werwolf-Rudel (Angriff als Auslöser), Schicksalswolf/Rudelvater (Zusatzziele, `PACKFATHER_KILL` durchbricht Schild), Dämonischer Wolf (`cursedWolfAura` zählt bei Benennung als Wolf, Nekromant selbst kann verflucht werden), Doppelspion (zählt nicht als Wolf), Parasit/Rudelvater/Schattenwanderer (vor dem Schild … |
| Widersprüche | RM-C-066 Wen schützt der Schild; RM-C-067 Umlenkung optional oder Pflicht; RM-C-068 Ressource der Toten; RM-C-069 Siegversuche; RM-C-070 Übungs-Enthüllung |
| Entscheidungen | RM-DR-142 (Rolle); übergreifend RM-DR-002, RM-DR-005, RM-DR-007, RM-DR-008; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K15 / in keiner Option |
| Belegsicherheit | hoch für Schild, Verfall, Umlenkung, Sieg. Nicht verifiziert: tatsächliches Verhalten im Browser beim Abbruch (nur Codelesung); ob `center()`-Meldungen die Pick-Leiste verdecken. --- |
| Detail | [Dossier](dossiers/solos-b.md#nekromant) |

### `kartenschlucker`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Kartenschlucker / The Collector |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / III, IV / 4.0 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Textmechanik (Stapel pro Tausch, Sieg bei 10) ist korrekt umgesetzt; der Code enthält drei wesentliche, im Text fehlende Kräfte. |
| DE/EN-Vergleich | semantisch gleich JA im Kern (Auslöser Tausch, +1, Sieg bei 10 sofort). Unterschied nur Numerus: DE "seine Karte" (eine), EN "their cards" (Plural); inhaltlich ohne Folge, da jeder Tote eine Karte hat. EN-Name "The Collector" ist keine Übersetzung von "Kartenschlucker". |
| Automationsziel | `assisted`: Stapelzählung und Sieg sind automatisierbar, setzen aber einen Totenkarten-Assistenten mit Tauschbefehl voraus (Q3); Kill-Ziel und Tauschentscheidung sind Eingaben. |
| Mechanik | primär: Totenkarten-Interaktion; sekundär: Einzelsieg, Tötung, Schutz |
| Größe / Risiko | L / hoch. Abhängig von einem in Godot nicht existierenden Totenkarten-System; Zusatzkräfte mit Schneeballeffekt; Siegprüfung an mehreren Stellen. |
| Vorhandene Godot-Systeme | KillPipeline (Kill, Schild als Abfangstufe), StepQueue, PendingPrompt, SeededRng (Ersatzkarte), WinRules/WinCandidate, Ereignis-Sichtbarkeit (öffentliche Ansage), StateCodec, Replay, GmCorrections. |
| Neue Systeme | Totenkarten-Effektmodell (mindestens Ziehen, Tauschen, Ausspielen, Zustand je Toter), Ressourcenzähler als dauerhafter Statusmarker, zusätzliche Siegbedingung; bei Beibehaltung der Code-Kräfte: persönlicher, jede Nacht erneuerter Schild. |
| Abhängigkeiten | alle Rollen, die Tote erzeugen (mehr Tote = mehr Tauschgelegenheiten), Totenkarten-System (`cards`), Frankenstein/Kutscher (Wiederbelebung ermöglicht erneuten Tausch), Nekromant/Hades/Parasit/Rudelvater (Abfangregeln in `applyKill` vor bzw. nach dem Schild), Albtraumwolf/Schattenhund/Zeitwächter (blockieren den … |
| Widersprüche | RM-C-071 Zusatzkräfte Kill/Schild/Ansage; RM-C-072 Wer darf tauschen |
| Entscheidungen | RM-DR-143 (Rolle); übergreifend RM-DR-005, RM-DR-007, RM-DR-013; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K15 / in keiner Option |
| Belegsicherheit | hoch. Nicht verifiziert: ob die Ansage (`center`) und der gleichzeitig geöffnete Kill-Pick im Browser kollidieren (Code öffnet beide synchron, `chunk:227,234`). --- |
| Detail | [Dossier](dossiers/solos-b.md#kartenschlucker) |

### `hades`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Hades / Hades |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / IV / 9.9 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Der knappe Text (Lichter von Toten, Fähigkeiten kaufen, Sieg bei 10) ist nachvollziehbar umgesetzt; Preise und Fähigkeiten sind nur im Code definiert. Der wirkungslose Stimmbonus und der doppelte Siegpfad sind Nebenfunktionen, nicht die Kernfunktion. |
| DE/EN-Vergleich | semantisch gleich JA (geprüft: Quelle "von Toten"/"from the dead", "Kauft Fähigkeiten"/"Buys abilities", Zahl 10). Beide nennen weder Preise noch Fähigkeiten. |
| Automationsziel | `assisted`: Lichter, Kill, Barriere und Sieg automatisch; Stimmbonus nur als Hinweis (Stimmen physisch laut DECISION-LOG). |
| Mechanik | primär: Einzelsieg; sekundär: Tötung, Schutz, sonstige Spezialmechanik |
| Größe / Risiko | M / mittel. Klare Ökonomie, aber globaler Todeszähler und Wechselwirkung mit allen Abfangregeln. |
| Vorhandene Godot-Systeme | KillPipeline (Tod-Ereignis als Lichterquelle, Barriere als Abfangstufe, `HADES_KILL`), StepQueue, PendingPrompt (mehrstufiges Kaufmenü, abbrechbar), WinRules/WinCandidate, Reaktionswarteschlange (Folgen des Sofort-Kills), StateCodec, Replay, GmCorrections. |
| Neue Systeme | Ressourcenzähler als dauerhafter Statusmarker, persönlicher Schild mit Kaufbedingung, dauerhafter Statusmarker "Stimme x3" (Anzeige, kein Stimmsystem), zusätzliche Siegbedingung. |
| Abhängigkeiten | jede tötende Rolle (Lichterquelle), Nekromant (Schild fängt Hades-Kill ab, Lichter trotzdem weg), Rudelvater (`PACKFATHER_KILL` durchbricht Barriere), Ritter (Vergeltung bei `HADES_KILL`, `core:431`), Kutscher/Frankenstein (Rollenvergabe), Totenkarten mit Stimmbezug. |
| Widersprüche | RM-C-073 Sieg automatisch oder eingelöst; RM-C-074 Zählen eigene Kills; RM-C-075 Stimme x3 |
| Entscheidungen | RM-DR-144 (Rolle); übergreifend RM-DR-005, RM-DR-007, RM-DR-008; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K15 / in keiner Option |
| Belegsicherheit | hoch. Nicht verifiziert: ob irgendwo außerhalb von `js/`, `game.html`, `app/` Stimmen gewichtet werden (rg über das ganze Repo fand nur die Definition `ui:18`). --- |
| Detail | [Dossier](dossiers/solos-b.md#hades) |

### `schutzgeist`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Schutzgeist / Guardian Spirit |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / II / 5.6 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Code für die Fähigkeit existiert, aber F1 verhindert die Auslösung vollständig, und die Wirkung wäre wegen Reihenfolge/Reset null. |
| DE/EN-Vergleich | JA. Nur Pronomenwechsel "their"/"she" im EN. Die in GRIMMHAIN_ANALYSE_2026-06-12.md:219 (E3) gemeldete fehlende Wolf-Offenbarung im EN ist inzwischen behoben (roles:272 enthält sie). |
| Automationsziel | `automatic`: Klarer Auslöser (eigener Tod), ein Ziel, deterministische Wirkung nach PO-Entscheidung. |
| Mechanik | primär: Schutz; sekundär: Todesreaktion, Informationsrolle |
| Größe / Risiko | M / mittel. Einfacher Handler, aber Schrittfreigabe für Tote und Schilddauer sind neu. |
| Vorhandene Godot-Systeme | StepQueue (Schritt für toten Akteur), PendingPrompt, Protections (neue Quelle), Reaktionswarteschlange oder Todes-Hook zum Freischalten, InfoRecord + Ereignis-Sichtbarkeit (public), appears_as (falls Meldung nach Erscheinung), StateCodec, Replay, GmCorrections. |
| Neue Systeme | dauerhafte Statusmarker (Schild mit Lebensdauer "bis zum nächsten Wolfsangriff", falls Interpretation A); Protections muss mehrere Quellen und Lebensdauer kennen. |
| Abhängigkeiten | Werwolf/Rudel (Angriff), Rachsüchtiger Wolf (Zusatzangriff), Seuchenwolf (Durchbohren ignoriert Schutz beim Pick, chunk:162) und Rudelvater (Zusatzopfer am Morgen ohne Schutzprüfung, night:269-280), Dämonischer Wolf (verfluchter Sitz löst Wolfsmeldung aus), Dr. Victor Frankenstein (Wiederbelebung), Seelentauscher … |
| Widersprüche | RM-C-159 Dauer/Wirkung des Schilds; RM-C-160 Schutzart; RM-C-161 Zeitpunkt; RM-C-162 Wolf-Meldung |
| Entscheidungen | RM-DR-148 (Rolle); übergreifend RM-DR-002, RM-DR-004, RM-DR-009; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K5 / in keiner Option |
| Belegsicherheit | hoch. Nicht verifiziert: Verhalten, falls ein SL den Schritt über einen anderen Weg (Konsole) auslöst. --- |
| Detail | [Dossier](dossiers/village-4.md#schutzgeist) |

### `zeitwaechter`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Zeitwächter / Time Warden |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / III / 9.5 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code ist in sich lauffähig, setzt aber nur einen Teil des Textes um. |
| DE/EN-Vergleich | JA, semantisch gleich ("einmalig" = "Once per game"; "dieser Nacht" im EN implizit). |
| Automationsziel | `assisted`: Nach PO-Entscheidung automatisierbar, aber ein Nacht-Rollback berührt jede Rolle; SL-Bestätigung sinnvoll. |
| Mechanik | primär: globale Regeländerung; sekundär: Einmalfähigkeit |
| Größe / Risiko | XL / kritisch. Berührt Nachtablauf, alle Sofort-Tode, Zähler und Reaktionen. |
| Vorhandene Godot-Systeme | StepQueue (Schrittstatus blocked), PendingPrompt, KillPipeline (Tode der Nacht zurückhalten oder verwerfen), Reaktionswarteschlange (Reaktionen nicht auslösen), StateCodec, Replay, InfoRecord/Sichtbarkeit (public Meldung "Nacht eingefroren"), GmCorrections. |
| Neue Systeme | globale Modifikatoren (Nacht eingefroren), Rollenblockierung (alle folgenden Schritte), Nacht-Transaktionsbegriff mit Schnappschuss und Zähler-Rücknahme (zeitlich verzögerte Effekte müssen ebenfalls verworfen werden: Witwe, Giftwolf). |
| Abhängigkeiten | praktisch alle Nachtrollen; besonders Schwarze Witwe, Giftwolf, Märtyrerin, Voodoo-Priester, Rudelvater, Seuchenwolf, Waldhexe, Hades, Amalia, Kriegerin, Dorfschmied, Der Weise, Fenrir, Cerberus, Todesprediger, Schattenhund/Albtraumwolf/Der Weise (blockieren den Zeitwächter selbst). |
| Widersprüche | RM-C-164 Umfang des Abbruchs; RM-C-165 Zeitpunkt der Entscheidung; RM-C-166 Zähler; RM-C-167 Wolfsrollen |
| Entscheidungen | RM-DR-150 (Rolle); übergreifend RM-DR-010; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K16 / in keiner Option |
| Belegsicherheit | hoch für die Codeanalyse. Nicht verifiziert: Sichtbarkeit/Anklickbarkeit der Nachtliste am Tag (CSS/Layout nicht im Browser geprüft). --- |
| Detail | [Dossier](dossiers/village-4.md#zeitwaechter) |

### `amalia`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Amalia / Amalia |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / IV / 5.8 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Das Opfer funktioniert, die öffentliche Frage ist nicht modelliert und als Nachtschritt zeitlich widersprüchlich. |
| DE/EN-Vergleich | JA, semantisch gleich (Schwelle "mehr als zwei" = "more than two", Opfer, öffentliche Ja/Nein-Frage). |
| Automationsziel | `assisted`: Die Frage ist sozial; App erfasst Opfer, Frage und SL-Antwort. |
| Mechanik | primär: Informationsrolle; sekundär: Einmalfähigkeit, Tagfähigkeit |
| Größe / Risiko | M / mittel. Einfacher Tod, aber neue Tagesaktion und Freitext. |
| Vorhandene Godot-Systeme | PendingPrompt (Bestätigung, Frage, Antwort, abbrechbar), KillPipeline (Ursache Opfer), Reaktionswarteschlange, WinRules/WinCandidate, InfoRecord + Ereignis-Sichtbarkeit (public), StateCodec, Replay, GmCorrections. |
| Neue Systeme | Tagesaktionswarteschlange (falls Tagesaktion); Freitext-Eingabe im Prompt. |
| Abhängigkeiten | alle Wolfsrollen (Schwelle), Dämonischer Wolf (Verfluchte zählen im Code mit), Doppelspion (zählt nicht), Nekromant (Globalschild verhindert Opfer), Zeitwächter (Opfer bleibt trotz Einfrieren). |
| Widersprüche | RM-C-168 Zeitpunkt; RM-C-169 Frage und Antwort; RM-C-170 Schwelle |
| Entscheidungen | RM-DR-151 (Rolle); übergreifend RM-DR-002; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K14 / in keiner Option |
| Belegsicherheit | hoch für Code; mittel für Zweck der verwaisten Schlüssel (Historie nicht verfügbar). --- |
| Detail | [Dossier](dossiers/village-4.md#amalia) |

### `kriegerin-des-lichts`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Kriegerin des Lichts / Warrior of Light |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / IV / 6.0 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-contradictory`. Code ist lauffähig; Text ("greift an"), Code (kein Treffer-Tod) und Doku 04 ("er stirbt") widersprechen sich. |
| DE/EN-Vergleich | weitgehend JA. Nuance: "sagt" (DE, Empfänger offen) vs. "reveals" (EN, legt eher öffentliche Offenlegung nahe). Sonst gleich (einmalig, nachts, ein Spieler, Selbsttod bei Nicht-Wolf). |
| Automationsziel | `assisted`: Zielwahl und Fraktionsprüfung automatisch, Ergebnis mit SL-Bestätigung bis zur Entscheidung über Wahrheit/Erscheinung. |
| Mechanik | primär: Informationsrolle; sekundär: Einmalfähigkeit, Tötung |
| Größe / Risiko | S / mittel. Einfacher Ablauf, aber Regelentscheidung mit großer Balancewirkung. |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (zweistufig: Ziel, Ergebnis), InfoRecord (Wahrheit/ermittelt/gezeigt), appears_as, KillPipeline (WARRIOR_WRONG, ggf. Treffer), Reaktionswarteschlange, WinRules/WinCandidate, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections. |
| Neue Systeme | keine. |
| Abhängigkeiten | alle Wolfsrollen, Dämonischer Wolf (verfluchter Sitz: Wolf oder nicht?), Trugbilderwolf/Erscheinungsrollen, Doppelspion, Rudelvater (erste Sonderfähigkeitstötung überlebt, falls Treffer tötet), Nekromant-Globalschild. |
| Widersprüche | RM-C-171 Stirbt ein getroffener Wolf?; RM-C-172 Wahrheitsquelle; RM-C-173 Öffentlichkeit |
| Entscheidungen | RM-DR-152 (Rolle); übergreifend RM-DR-002, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K7 / in keiner Option |
| Belegsicherheit | hoch. --- |
| Detail | [Dossier](dossiers/village-4.md#kriegerin-des-lichts) |

### `detektiv`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Detektiv / Detective |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / III / – |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Der Hinweis wird ausgelöst, ist aber durch den Platzhalterfehler inhaltsleer bzw. beim Paritätsfall möglicherweise falsch. |
| DE/EN-Vergleich | JA, semantisch gleich. |
| Automationsziel | `automatic`: Auslöser und Hinweis sind aus dem Zustand berechenbar (mit SeededRng). |
| Mechanik | primär: Informationsrolle; sekundär: Todesreaktion, Sitzpositionsmechanik, Zufallsmechanik |
| Größe / Risiko | M / hoch. Öffentliche Information mit Zufall und Sitzlogik; Fehler erzeugen öffentliche Falschinformation. |
| Vorhandene Godot-Systeme | Reaktionswarteschlange (auf Wolfstod), SeededRng, InfoRecord (Wahrheit/gezeigt), Ereignis-Sichtbarkeit (public), KillPipeline-Ereignisse, appears_as (Abgrenzung Fluch), StateCodec, Replay, GmCorrections. |
| Neue Systeme | Sitznachbarschaft (einheitliche Links/Rechts-Konvention, lebend/tot überspringen). |
| Abhängigkeiten | alle Wolfsrollen, Dämonischer Wolf (Verfluchte lösen aus), Wolfskind/Lehrling (verwandelte Wölfe), Doppelspion (ausgenommen), Dorfschmied (Wolfstod durch Waffe), Fährtenleser (Richtungskonvention). |
| Widersprüche | RM-C-174 Muss der Detektiv leben?; RM-C-175 Mindestens 2 lebende Wölfe; RM-C-176 Hinweisinhalt; RM-C-177 Richtung links/rechts |
| Entscheidungen | RM-DR-153 (Rolle); übergreifend RM-DR-002, RM-DR-003, RM-DR-009, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K3 / in keiner Option |
| Belegsicherheit | hoch. Nicht verifiziert: tatsächliche Darstellung, wenn Nacht-Todesübersicht (ui:470-477) und Center-Modal gleichzeitig offen sind (nur Code gelesen). --- |
| Detail | [Dossier](dossiers/village-4.md#detektiv) |

### `dorfschmied`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Dorfschmied / Village Blacksmith |
| Fraktion / Akte / Legacy-Nachtpriorität | Dorf / IV / 1.7 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Kernfunktion (Schmieden, Vergabe, Abwehr, zufälliger Wolfstod) funktioniert; Randfälle betreffen Meldung und Zählerstart. |
| DE/EN-Vergleich | JA, semantisch gleich (5 Nächte, sechste Nacht, ein Spieler, ein Angriff, zufälliger Wolf). |
| Automationsziel | `automatic`: Zähler, Vergabe und Abwehr sind zustandsbasiert; Zufall über SeededRng. |
| Mechanik | primär: Wolfsangriff-Modifikation; sekundär: Schutz, Tötung, Zufallsmechanik |
| Größe / Risiko | M / mittel. Mehrere Interaktionen in der Kill-Pipeline und Zufall. |
| Vorhandene Godot-Systeme | StepQueue (Schritt mit Freigabebedingung), PendingPrompt, KillPipeline (Abfangregel vor NIGHT_KILL mit Filter Wolfsangriff), Protections (Reihenfolge zu Schutzengel), SeededRng, Reaktionswarteschlange (Tod des zufälligen Wolfs), WinRules, InfoRecord/Sichtbarkeit (gm, ggf. public), StateCodec, Replay, GmCorrections. |
| Neue Systeme | dauerhafte Statusmarker (Waffe am Sitz über Nächte), Zähler für zeitlich verzögerte Freischaltung (Schmiedezähler). |
| Abhängigkeiten | Werwolf/Rudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater, Seuchenwolf, Schutzengel, Der Weise, Nekromant, Rudelvater (Erstrettung), Dämonischer Wolf, Detektiv (Hinweis bei Waffentod), Zeitwächter, Verdammniswächter (umgeht Waffe), Rotkäppchen (Apfel: zweite Waffe). |
| Widersprüche | RM-C-178 Welche Nächte zählen; RM-C-179 Nur Nacht 6 oder ab Nacht 6; RM-C-180 Welche Angriffe |
| Entscheidungen | RM-DR-154 (Rolle); übergreifend RM-DR-002, RM-DR-004, RM-DR-005, RM-DR-015; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K5 / in keiner Option |
| Belegsicherheit | hoch für Code; mittel für den Nacht-1-Startweg (nicht im Browser geprüft). --- ## Gruppenübergreifende Beobachtungen 1. Globale Einmal-Flags statt sitzbezogener Zustände: Zeitwächter, Kriegerin (`Used["role_..."]`), Dorfchronistin (`ChroniclerShown`), … |
| Detail | [Dossier](dossiers/village-4.md#dorfschmied) |

### `grabraeuber`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Grabräuber / Grave Robber |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / II / 6.4 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `not-found`. Der Text verspricht das Stehlen einer Fähigkeit und einen Solo-Sieg; der Code speichert nur den Rollennamen, überträgt keine Fähigkeit und enthält keinen Siegcode. |
| DE/EN-Vergleich | semantisch gleich JA (einmalig/once, Fähigkeit eines toten Spielers, gewinnt alleine). Beide nennen keine Siegbedingung. |
| Automationsziel | `manual-only`: (bis zur PO-Festlegung). Danach je nach Regel assisted. |
| Mechanik | primär: Einmalfähigkeit; sekundär: Einzelsieg, sonstige Spezialmechanik |
| Größe / Risiko | XL / hoch. kritisch (automatisch, da Wechselwirkung mit allen Rollen). |
| Vorhandene Godot-Systeme | StepQueue (einmaliger Schritt), PendingPrompt (tote Ziele), Player `ability_uses` (Einmalnutzung), InfoRecord (gestohlene Rolle), GmCorrections, StateCodec, Replay. |
| Neue Systeme | Fähigkeitsübertragung/-kopie (Rolle bleibt, Fähigkeit wird zusätzlich ausgeführt; kein Punkt der Vorgabeliste, daher "sonstige"), zusätzliche Siegbedingung; ggf. zusätzlicher Nachtschritt für geerbte Fähigkeit. |
| Abhängigkeiten | potenziell jede Rolle mit Nachtfähigkeit (Ziel des Diebstahls); Einmalrollen (bereits verbraucht?); Totenkarte `solo_05` (ähnliche Vererbung). |
| Widersprüche | RM-C-076 Was bedeutet "Fähigkeit stehlen"; RM-C-077 Siegbedingung |
| Entscheidungen | RM-DR-156 (Rolle); übergreifend RM-DR-006, RM-DR-007, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K15 / in keiner Option |
| Belegsicherheit | hoch (Fehlen per rg über gesamtes Repo ohne Markdown und node_modules bestätigt). --- |
| Detail | [Dossier](dossiers/solos-b.md#grabraeuber) |

### `parasit`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Parasit / Parasite |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / III / 6.2 |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-verified`. Wirtwahl, Immunität, Kettentod und Sieg bei drei Lebenden setzen den Text nachvollziehbar um; Lücken betreffen Randfälle (Lynch-Protokoll, Siegpriorität). |
| DE/EN-Vergleich | semantisch gleich JA (geprüft: jede Nacht, optional "kann/may", lebender Spieler, stirbt nur mit Wirt, Final 3). Keiner der Texte sagt "alleine". |
| Automationsziel | `automatic`: (Wirtwahl als Eingabe, Immunität, Kettentod und Siegkandidat vollautomatisch mit SL-Bestätigung). |
| Mechanik | primär: Verknüpfte Personen; sekundär: Schutz, Todesreaktion, Einzelsieg |
| Größe / Risiko | M / mittel. Einfache Bindung, aber Eingriff an der ersten Stelle der Kill-Pipeline und Siegpriorität. |
| Vorhandene Godot-Systeme | KillPipeline (Immunitätsstufe, Kettentod als Folgetod), StepQueue, PendingPrompt, Reaktionswarteschlange (Kettentod), WinRules/WinCandidate, ExecutionRules (Hinrichtung ohne Wirkung), StateCodec, Replay, Ereignis-Sichtbarkeit. |
| Neue Systeme | Bindungsmodell Parasit-Wirt (Verknüpfte Personen, pro Nacht änderbar), zusätzliche Siegbedingung (Final 3). |
| Abhängigkeiten | jede tötende Rolle (Immunität), Rudelvater (`PACKFATHER_KILL` durchbricht Immunität NICHT, da Parasit-Prüfung zuerst), Nekromant-Schild (kann den Kettentod abfangen), Manipulator (gleichzeitiger Final-3-Sieg), Henker (`finalizeLynch`), Rotkäppchen/Schattenwanderer (weitere Ketten). |
| Widersprüche | RM-C-078 "Final 3" und Siegvorrang |
| Entscheidungen | RM-DR-157 (Rolle); übergreifend RM-DR-007, RM-DR-009, RM-DR-011; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K10 / ab Option C |
| Belegsicherheit | hoch. Nicht verifiziert: Verhalten von `clearRolesNewRound` für `meta.parasiteHostId` im Browser (Code `gh:517` überschreibt `meta` per `Object.assign` mit Teilobjekt, das `parasiteHostId` nicht enthält, das Feld bleibt also erhalten; ohne Rolle Parasit aber … |
| Detail | [Dossier](dossiers/solos-b.md#parasit) |

### `todesprediger`

| Feld | Inhalt |
|---|---|
| Legacy-Name / EN | Todesprediger / Death Prophet |
| Fraktion / Akte / Legacy-Nachtpriorität | Einzelsieg / II / 6.6 (once) |
| Migrationsstatus | `decision-required` |
| Legacy-Befund | `legacy-broken`. Die Kernfunktion (Sieg bei korrekt vorhergesagtem Todeszeitpunkt) wird für Tagesvorhersagen durch die überlappende Zählung und den Versatz zur angezeigten Tagesnummer verfälscht (Bugs 1 und 2, beide mit Zeilenbeleg). Nachtvorhersagen funktionieren. |
| DE/EN-Vergleich | semantisch gleich NEIN (leichte Unterschiede): (1) DE "Kündigt an" kann eine öffentliche Ankündigung bedeuten, EN "Predicts" ist neutral. (2) EN betont "exact", DE nicht. Beide nennen keinen Zeitpunkt der Vorhersage (Nacht 1?) und keine Zählbasis. Siegteil gleich. |
| Automationsziel | `automatic`: (nach PO-Festlegung der Zählbasis): Vorhersage als Eingabe, Treffer beim Todesereignis deterministisch, WinCandidate mit SL-Bestätigung. |
| Mechanik | primär: Einzelsieg; sekundär: Einmalfähigkeit |
| Größe / Risiko | M / mittel |
| Vorhandene Godot-Systeme | StepQueue, PendingPrompt (Eingabe Phase + Zahl, abbrechbar), KillPipeline (Todesereignis mit Phase), WinRules/WinCandidate, Ereignis-Sichtbarkeit, InfoRecord, StateCodec, Replay, GmCorrections. |
| Neue Systeme | zusätzliche Siegbedingung; dauerhafter Statusmarker (gespeicherte Vorhersage). Voraussetzung: eindeutige Phasenzuordnung jedes Todes (Teil des Phasenmodells, B-9). |
| Abhängigkeiten | alle tötenden Rollen; Zeitwächter (Frost, Nachtzählung), Lynch/Hinrichtung, Parasit-ähnliche Immunitäten und Schilde (verschieben Todeszeitpunkt), Frankenstein/Kutscher (Wiederbelebung und erneuter Tod). |
| Widersprüche | RM-C-079 Öffentlich oder geheim; RM-C-080 Zeitpunkt der Vorhersage; RM-C-081 Zählbasis Tag/Nacht |
| Entscheidungen | RM-DR-158 (Rolle); übergreifend RM-DR-007, RM-DR-011, RM-DR-014; Rahmen: RM-DR-001 (entschieden, G-ID-3) |
| Charge / Option (nicht freigegeben) | K15 / in keiner Option |
| Belegsicherheit | hoch für Zählerpositionen und Vergleich. Mittel für die angezeigte Tagesnummer: der Phasenzähler liest `window.state` (F8) und zeigt im Normalbetrieb vermutlich dauerhaft "Tag 1"; die Protokoll-Labels (`gamelog.js`) sind die belastbare Anzeigequelle. --- ## … |
| Detail | [Dossier](dossiers/solos-b.md#todesprediger) |
