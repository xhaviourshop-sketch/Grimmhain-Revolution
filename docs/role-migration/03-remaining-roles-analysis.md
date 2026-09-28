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
| [`rachsuechtiger-wolf`](#rachsuechtiger-wolf) | Wölfe | `decision-required` | `legacy-contradictory` | `assisted` | Tötung | Einzelsieg, Wolfsangriff-Modifikation | M / hoch | K11 | – |
| [`schicksalswolf`](#schicksalswolf) | Wölfe | `decision-required` | `legacy-contradictory` | `automatic` | Tötung | mehrstufige Nachtfähigkeit, Einmalfähigkeit | M / mittel | K11 | – |
| [`feuerteufel`](#feuerteufel) | Einzelsieg | `decision-required` | `legacy-broken` | `automatic` | Todesreaktion | Sitzpositionsmechanik, Hinrichtungsreaktion | M / hoch | K9 | – |
| [`voodoo-priester`](#voodoo-priester) | Einzelsieg | `decision-required` | `legacy-contradictory` | `automatic` | Zielumleitung | Verknüpfte Personen, Hinrichtungsreaktion | L / hoch | K10 | – |
| [`nekromant`](#nekromant) | Einzelsieg | `decision-required` | `legacy-contradictory` | `assisted` | Schutz | Zielumleitung, Einzelsieg, Tagfähigkeit | L / hoch | K15 | – |
| [`kartenschlucker`](#kartenschlucker) | Einzelsieg | `decision-required` | `legacy-contradictory` | `assisted` | Totenkarten-Interaktion | Einzelsieg, Tötung, Schutz | L / hoch | K15 | – |
| [`hades`](#hades) | Einzelsieg | `decision-required` | `legacy-verified` | `assisted` | Einzelsieg | Tötung, Schutz, sonstige Spezialmechanik | M / mittel | K15 | – |
| [`zeitwaechter`](#zeitwaechter) | Dorf | `decision-required` | `legacy-contradictory` | `assisted` | globale Regeländerung | Einmalfähigkeit | XL / kritisch | K16 | – |
| [`grabraeuber`](#grabraeuber) | Einzelsieg | `decision-required` | `not-found` | `manual-only` | Einmalfähigkeit | Einzelsieg, sonstige Spezialmechanik | XL / hoch | K15 | – |

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
