# 03 · Analyse der 61 fehlenden Rollen

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse, keine Regel entschieden

Dieses Dokument fasst je fehlender Rolle die belegten Kernaussagen zusammen. Die vollständige Detailanalyse mit Quelltextstellen, wörtlichen Texten, Schritt-für-Schritt-Legacy-Verhalten, React-Befund, Prüfung der bisherigen Dokumentation, Bugs und Testfällen steht im verlinkten **Belegdossier** (Abschnitt mit der Rollen-ID). Widersprüche tragen IDs `RM-C-###` ([`04`](04-rule-conflicts.md)), Entscheidungen `RM-DR-###` ([`08`](08-decision-request.md)).

Unterschieden wird wie im Auftrag gefordert: **Rollentext behauptet** (Dossier „Text DE/EN“), **Legacy-Code tut** (Dossier „Legacy-Codeverhalten“), **React-Version tut** (Dossier „React-Version“; für keine der 61 Rollen eigenes Regelverhalten), **Dokumentation empfiehlt** (Dossier „Bisherige Doku“), **neuer Godot-Kern tut** (für alle 61: nichts, keine Rolle ist im RoleCatalog), **noch unentschieden** (Entscheidungen unten).

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist umgesetzt (später weitere Rollen, siehe `11`); sein Abschnitt steht jetzt in [`02`](02-implemented-roles-audit.md) §4.12, der aktuelle Prüfstatus aller Rollen in [`11-role-audit-status.md`](11-role-audit-status.md). Diese Datei behandelt damit 60 fehlende Rollen; umgesetzte Rollen sind inzwischen entfernt (Stand 01.10.2026: keine verbleibend, zuletzt `kartenschlucker`; davor `hades`, `grabraeuber`, `schicksalswolf`, `rachsuechtiger-wolf`, `zeitwaechter`, siehe [`02`](02-implemented-roles-audit.md) §4.67 bis §4.71).

**Lesehilfe:** In übernommenen Zellen bezeichnen `01` bis `07` ohne Pfad die älteren Dokumente unter `docs/godot-migration/`; Pfadkürzel wie in [`04`](04-rule-conflicts.md) §3.

**Konsolidierung 2026-09-27:** Der Status jeder Entscheidung steht in [`08`](08-decision-request.md) und [`decision-status.csv`](decision-status.csv); die Spalten „Charge“ und „1.0“ sind Planung, keine Freigabe.

## 1. Übersicht

| ID | Fraktion | Godot | Legacy | Auto | Mechanik (primär) | sekundär | Größe / Risiko | Charge | 1.0 |
|---|---|---|---|---|---|---|---|---|---|
| – | – | – | – | – | keine fehlende Rolle mehr | – | – | – | – |

**Mechanikfamilien:** Jede Rolle hat genau eine primäre Familie, nach der sie einer Charge zugeordnet ist. Wo die technische Charge von der primären Familie abweicht (z. B. `detektiv`: Informationsrolle, aber Charge Sitznachbarschaft), bestimmt die überwiegend neu zu bauende Kernfunktion die Charge.

**Automation:** Der Wert ist das Ziel nach Klärung der Entscheidungen. `assisted` heißt: App führt, rechnet und protokolliert, eine Spielleitereingabe bleibt Teil der Regel (z. B. Tischfrage, freie Zahl). `manual-only` heißt: bis zur Regelfestlegung nur Notiz und Hinweis.

## 2. Rollen im Einzelnen

Keine fehlende Rolle. Der Kartenschlucker ist umgesetzt, siehe [`02`](02-implemented-roles-audit.md) §4.72.
