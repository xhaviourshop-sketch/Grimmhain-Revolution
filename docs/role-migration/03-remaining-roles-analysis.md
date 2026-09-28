# 03 · Analyse der 61 fehlenden Rollen

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse, keine Regel entschieden

Dieses Dokument fasst je fehlender Rolle die belegten Kernaussagen zusammen. Die vollständige Detailanalyse mit Quelltextstellen, wörtlichen Texten, Schritt-für-Schritt-Legacy-Verhalten, React-Befund, Prüfung der bisherigen Dokumentation, Bugs und Testfällen steht im verlinkten **Belegdossier** (Abschnitt mit der Rollen-ID). Widersprüche tragen IDs `RM-C-###` ([`04`](04-rule-conflicts.md)), Entscheidungen `RM-DR-###` ([`08`](08-decision-request.md)).

Unterschieden wird wie im Auftrag gefordert: **Rollentext behauptet** (Dossier „Text DE/EN“), **Legacy-Code tut** (Dossier „Legacy-Codeverhalten“), **React-Version tut** (Dossier „React-Version“; für keine der 61 Rollen eigenes Regelverhalten), **Dokumentation empfiehlt** (Dossier „Bisherige Doku“), **neuer Godot-Kern tut** (für alle 61: nichts, keine Rolle ist im RoleCatalog), **noch unentschieden** (Entscheidungen unten).

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist umgesetzt (später weitere Rollen, siehe `11`); sein Abschnitt steht jetzt in [`02`](02-implemented-roles-audit.md) §4.12, der aktuelle Prüfstatus aller Rollen in [`11-role-audit-status.md`](11-role-audit-status.md). Diese Datei behandelt damit 60 fehlende Rollen; umgesetzte Rollen sind inzwischen entfernt (Stand 28.09.2026: 1 verbleibend, `kartenschlucker`; zuletzt umgesetzt `hades`, `grabraeuber`, `schicksalswolf`, `rachsuechtiger-wolf`, `zeitwaechter`, siehe [`02`](02-implemented-roles-audit.md) §4.67 bis §4.71).

**Lesehilfe:** In übernommenen Zellen bezeichnen `01` bis `07` ohne Pfad die älteren Dokumente unter `docs/godot-migration/`; Pfadkürzel wie in [`04`](04-rule-conflicts.md) §3.

**Konsolidierung 2026-09-27:** Der Status jeder Entscheidung steht in [`08`](08-decision-request.md) und [`decision-status.csv`](decision-status.csv); die Spalten „Charge“ und „1.0“ sind Planung, keine Freigabe.

## 1. Übersicht

| ID | Fraktion | Godot | Legacy | Auto | Mechanik (primär) | sekundär | Größe / Risiko | Charge | 1.0 |
|---|---|---|---|---|---|---|---|---|---|
| [`kartenschlucker`](#kartenschlucker) | Einzelsieg | `decision-required` | `legacy-contradictory` | `assisted` | Totenkarten-Interaktion | Einzelsieg, Tötung, Schutz | L / hoch | K15 | – |

**Mechanikfamilien:** Jede Rolle hat genau eine primäre Familie, nach der sie einer Charge zugeordnet ist. Wo die technische Charge von der primären Familie abweicht (z. B. `detektiv`: Informationsrolle, aber Charge Sitznachbarschaft), bestimmt die überwiegend neu zu bauende Kernfunktion die Charge.

**Automation:** Der Wert ist das Ziel nach Klärung der Entscheidungen. `assisted` heißt: App führt, rechnet und protokolliert, eine Spielleitereingabe bleibt Teil der Regel (z. B. Tischfrage, freie Zahl). `manual-only` heißt: bis zur Regelfestlegung nur Notiz und Hinweis.

## 2. Rollen im Einzelnen

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
