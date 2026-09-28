# 03 · Analyse der 61 fehlenden Rollen

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse, keine Regel entschieden

Dieses Dokument fasst je fehlender Rolle die belegten Kernaussagen zusammen. Die vollständige Detailanalyse mit Quelltextstellen, wörtlichen Texten, Schritt-für-Schritt-Legacy-Verhalten, React-Befund, Prüfung der bisherigen Dokumentation, Bugs und Testfällen steht im verlinkten **Belegdossier** (Abschnitt mit der Rollen-ID). Widersprüche tragen IDs `RM-C-###` ([`04`](04-rule-conflicts.md)), Entscheidungen `RM-DR-###` ([`08`](08-decision-request.md)).

Unterschieden wird wie im Auftrag gefordert: **Rollentext behauptet** (Dossier „Text DE/EN“), **Legacy-Code tut** (Dossier „Legacy-Codeverhalten“), **React-Version tut** (Dossier „React-Version“; für keine der 61 Rollen eigenes Regelverhalten), **Dokumentation empfiehlt** (Dossier „Bisherige Doku“), **neuer Godot-Kern tut** (für alle 61: nichts, keine Rolle ist im RoleCatalog), **noch unentschieden** (Entscheidungen unten).

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist umgesetzt (später weitere Rollen, siehe `11`); sein Abschnitt steht jetzt in [`02`](02-implemented-roles-audit.md) §4.12, der aktuelle Prüfstatus aller Rollen in [`11-role-audit-status.md`](11-role-audit-status.md). Diese Datei behandelt damit 60 fehlende Rollen; umgesetzte Rollen sind inzwischen entfernt (Stand 28.09.2026: 4 verbleibend; `hades` und `grabraeuber` jetzt in [`02`](02-implemented-roles-audit.md) §4.67 und §4.68).

**Lesehilfe:** In übernommenen Zellen bezeichnen `01` bis `07` ohne Pfad die älteren Dokumente unter `docs/godot-migration/`; Pfadkürzel wie in [`04`](04-rule-conflicts.md) §3.

**Konsolidierung 2026-09-27:** Der Status jeder Entscheidung steht in [`08`](08-decision-request.md) und [`decision-status.csv`](decision-status.csv); die Spalten „Charge“ und „1.0“ sind Planung, keine Freigabe.

## 1. Übersicht

| ID | Fraktion | Godot | Legacy | Auto | Mechanik (primär) | sekundär | Größe / Risiko | Charge | 1.0 |
|---|---|---|---|---|---|---|---|---|---|
| [`rachsuechtiger-wolf`](#rachsuechtiger-wolf) | Wölfe | `decision-required` | `legacy-contradictory` | `assisted` | Tötung | Einzelsieg, Wolfsangriff-Modifikation | M / hoch | K11 | – |
| [`schicksalswolf`](#schicksalswolf) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Tötung | mehrstufige Nachtfähigkeit, Einmalfähigkeit | M / mittel | K11 | – |
| [`kartenschlucker`](#kartenschlucker) | Einzelsieg | `decision-required` | `legacy-contradictory` | `assisted` | Totenkarten-Interaktion | Einzelsieg, Tötung, Schutz | L / hoch | K15 | – |
| [`zeitwaechter`](#zeitwaechter) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | globale Regeländerung | Einmalfähigkeit | XL / kritisch | K16 | – |

**Mechanikfamilien:** Jede Rolle hat genau eine primäre Familie, nach der sie einer Charge zugeordnet ist. Wo die technische Charge von der primären Familie abweicht (z. B. `detektiv`: Informationsrolle, aber Charge Sitznachbarschaft), bestimmt die überwiegend neu zu bauende Kernfunktion die Charge.

**Automation:** Der Wert ist das Ziel nach Klärung der Entscheidungen. `assisted` heißt: App führt, rechnet und protokolliert, eine Spielleitereingabe bleibt Teil der Regel (z. B. Tischfrage, freie Zahl). `manual-only` heißt: bis zur Regelfestlegung nur Notiz und Hinweis.

## 2. Rollen im Einzelnen

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
